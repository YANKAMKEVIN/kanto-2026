extends Node
## Autoload « SceneRouter » : changement de carte (portes, tapis, escaliers).
##
## Un seul rôle : charger la carte cible, y placer le joueur, gérer le fondu et bloquer les
## entrées pendant la transition (docs/tech/jalon-02.md §2.2). Il ne décide rien : quand le
## joueur termine un pas ([signal Player.moved]) ou pousse ([signal Player.bumped]), il
## interroge la [WarpTable] de la carte courante.
## Sans [code]class_name[/code] (le nom est pris par l'autoload) : les tests instancient
## [code]preload("res://game/autoload/scene_router.gd").new()[/code], jamais l'instance globale.

## Début d'une transition (entrées déjà bloquées) : masquer le titre de zone.
signal transition_started(target_map: StringName)
## Nouvelle carte en place, joueur placé ; écran encore noir (musique, GameState plus tard).
signal map_changed(map: GameMap)
## Écran visible, joueur libre (émis aussi par start()). Titre de zone.
signal map_entered(map: GameMap)
## Écran provisoire « <libellé> — À venir » sur le point d'être montré (rideau baissé) : le
## joueur est encore sur le bord de la carte. Ni [signal map_changed] ni [signal map_entered]
## ne suivent : aucune carte ne change.
signal coming_soon_shown(label: String)

## Dossier des cartes (MapCatalog.MAPS_DIR) ; les tests peuvent le changer.
var maps_dir: String = MapCatalog.MAPS_DIR
## Tests : fabrique func(map_id: StringName) -> GameMap utilisée à la place du chargement.
var map_factory: Callable = Callable()
## Durées du fondu (secondes) ; les tests les raccourcissent.
var fade_out_duration: float = UiTokens.ANIM_FADE_OUT
var fade_in_duration: float = UiTokens.ANIM_FADE_IN
## Destinations « à venir » ([member Warp.coming_soon]) actives : build de développement
## seulement (dossier-07 §12). En release, ces passages sont inertes (le bord reste bloqué).
var coming_soon_enabled: bool = OS.is_debug_build()
## Coroutine func(label: String) -> void qui montre l'écran « à venir » et rend la main quand
## il est fini ([ComingSoonScreen.present], branchée par Boot). Vide : aucun écran n'est montré
## (tests, outils) et le retour est immédiat. Remise à vide par [method setup].
var coming_soon_presenter: Callable = Callable()
## Durée du dernier changement de carte (instanciation + placement), en millisecondes.
var last_change_ms: float = 0.0

var _world: Node2D
var _player: Player
var _fade: ScreenFade
var _current_map: GameMap
var _busy: bool = false
## Incrémenté à chaque setup() : une transition lancée avant est abandonnée à sa reprise.
var _session: int = 0
## Scènes de cartes déjà chargées (chemin → PackedScene).
var _scenes: Dictionary[String, PackedScene] = {}
## Chargements en arrière-plan demandés (chemin → vrai) : cartes voisines de la courante.
var _prefetching: Dictionary[String, bool] = {}


func _exit_tree() -> void:
	# Récupère les chargements en arrière-plan encore en attente (sinon fuite à la sortie).
	for path: String in _prefetching:
		ResourceLoader.load_threaded_get(path)
	_prefetching.clear()
	_scenes.clear()


## Branche le routeur sur le monde, le joueur et le rideau ([param fade] null = transitions
## instantanées). Peut être rappelé : l'ancien joueur est débranché, l'état remis à zéro.
func setup(world: Node2D, player: Player, fade: ScreenFade = null) -> void:
	_disconnect_player()
	_session += 1
	_world = world
	_player = player
	_fade = fade
	_current_map = null
	_busy = false
	coming_soon_presenter = Callable()
	if _player != null:
		_player.moved.connect(_on_player_moved)
		_player.bumped.connect(_on_player_bumped)


## Premier placement, synchrone et sans fondu : carte ajoutée au monde, joueur au spawn,
## puis [signal map_changed] et [signal map_entered]. Renvoie la carte (null si échec).
func start(map_id: StringName, spawn: StringName, facing: Vector2i) -> GameMap:
	var map := _instantiate(map_id)
	if map == null:
		push_error("SceneRouter : carte inconnue « %s »" % map_id)
		return null
	if not map.has_spawn(spawn):
		push_error("SceneRouter : spawn inconnu « %s » sur %s" % [spawn, map_id])
		map.free()
		return null
	var old: GameMap = _current_map if is_instance_valid(_current_map) else null
	_world.add_child(map)
	map.spawn_player(_player, spawn, facing)
	_finish_start(map, old)
	return map


## Premier placement sur une **case** plutôt qu'un point d'apparition (reprise d'une
## sauvegarde, jalon 5C.5) : comme [method start], mais le joueur est posé sur [param cell],
## ou sur la case libre la plus proche ([method GameMap.find_standing_cell]) si un PNJ ou un
## décor l'occupe désormais. Null (rien n'est changé, avertissement) si la carte est inconnue
## ou n'a aucune case libre : l'appelant choisit alors un autre départ.
func start_at(map_id: StringName, cell: Vector2i, facing: Vector2i) -> GameMap:
	var map := _instantiate(map_id)
	if map == null:
		push_warning("SceneRouter : reprise impossible, carte inconnue « %s »" % map_id)
		return null
	var old: GameMap = _current_map if is_instance_valid(_current_map) else null
	_world.add_child(map)
	var target := map.find_standing_cell(cell, _player)
	if target == Vector2i(-1, -1):
		push_warning("SceneRouter : reprise impossible, aucune case libre sur %s" % map_id)
		_world.remove_child(map)
		map.free()
		return null
	if target != cell:
		print("SceneRouter : case %s prise sur %s, reprise en %s" % [cell, map_id, target])
	map.spawn_player_at(_player, target, facing if facing != Vector2i.ZERO else Vector2i.DOWN)
	_finish_start(map, old)
	return map


## Passe sur [param map_id] au spawn [param spawn] (coroutine, fondu si un rideau est
## branché). [param facing] ZERO = garder l'orientation du joueur. Ignoré si une
## transition est déjà en cours. En cas d'échec, le joueur reste sur la carte courante.
func change_map(map_id: StringName, spawn: StringName, facing: Vector2i = Vector2i.ZERO) -> void:
	if _busy or _player == null:
		return
	var session := _session
	_busy = true
	# Synchrone, avant tout await : on est peut-être dans step_finished du joueur, le
	# verrou empêche le pas qui s'enchaînerait (GridMover.set_locked).
	_player.set_input_enabled(false)
	transition_started.emit(map_id)
	if _fade != null:
		await _fade.fade_out(fade_out_duration)
		if session != _session:
			return
	var arrived := _swap_map(map_id, spawn, facing)
	if arrived:
		map_changed.emit(_current_map)
	if _fade != null:
		await _fade.fade_in(fade_in_duration)
		if session != _session:
			return
	_player.set_input_enabled(true)
	_busy = false
	if arrived:
		map_entered.emit(_current_map)
		_prefetch_neighbors(_current_map)


## Destination « à venir » (jalon 5, dossier-07 §12) : rideau, écran « <libellé> — À venir »
## ([member coming_soon_presenter]), puis le joueur reprend sur [param return_spawn], un point
## d'apparition **de la carte courante** (orientation [param facing], ZERO = inchangée), rideau
## levé. Aucune carte n'est chargée ni signalée ([signal map_entered] n'est pas émis : pas de
## titre de zone, pas de zone découverte, pas d'autosave demandé) ; pendant toute la durée,
## [method is_transitioning] est vrai, donc rien n'est sauvegardé « dans » l'écran provisoire.
## Sans effet si [member coming_soon_enabled] est faux, pendant une transition, ou sans
## joueur ni carte.
func show_coming_soon(label: String, return_spawn: StringName,
		facing: Vector2i = Vector2i.ZERO) -> void:
	if _busy or _player == null or not coming_soon_enabled \
			or not is_instance_valid(_current_map):
		return
	var session := _session
	_busy = true
	_player.set_input_enabled(false)
	transition_started.emit(&"")
	if _fade != null:
		await _fade.fade_out(fade_out_duration)
		if session != _session:
			return
	coming_soon_shown.emit(label)
	if coming_soon_presenter.is_valid():
		await coming_soon_presenter.call(label)
		if session != _session:
			return
	if _current_map.has_spawn(return_spawn):
		_current_map.spawn_player(_player, return_spawn,
			facing if facing != Vector2i.ZERO else _player.get_facing())
	else:
		push_error("SceneRouter : spawn de retour inconnu « %s » sur %s" % [return_spawn,
			_current_map.map_id])
	if _fade != null:
		await _fade.fade_in(fade_in_duration)
		if session != _session:
			return
	_player.set_input_enabled(true)
	_busy = false


func is_transitioning() -> bool:
	return _busy


func get_current_map() -> GameMap:
	return _current_map


func get_player() -> Player:
	return _player


## Fin commune de [method start] et [method start_at] : ancienne carte libérée, joueur
## libre, rideau levé, signaux, préchargement des voisines.
func _finish_start(map: GameMap, old: GameMap) -> void:
	if old != null:
		old.queue_free()
	_current_map = map
	_busy = false
	_player.set_input_enabled(true)
	if _fade != null:
		_fade.set_opaque(false)
	map_changed.emit(map)
	map_entered.emit(map)
	_prefetch_neighbors(map)


## Étapes 4 à 6 : instanciation, contrôle du spawn, placement, libération de l'ancienne
## carte. Faux (erreur signalée, carte courante conservée) si la carte ou le spawn manque.
func _swap_map(map_id: StringName, spawn: StringName, facing: Vector2i) -> bool:
	var started_usec := Time.get_ticks_usec()
	var map := _instantiate(map_id)
	if map == null:
		push_error("SceneRouter : carte inconnue « %s » (spawn « %s »)" % [map_id, spawn])
		return false
	if not map.has_spawn(spawn):
		push_error("SceneRouter : spawn inconnu « %s » sur %s" % [spawn, map_id])
		map.free()
		return false
	var arrival_facing := facing if facing != Vector2i.ZERO else _player.get_facing()
	var old: GameMap = _current_map if is_instance_valid(_current_map) else null
	_world.add_child(map)
	# Retire le joueur de l'ancienne carte (et libère sa case) avant de libérer celle-ci.
	map.spawn_player(_player, spawn, arrival_facing)
	if old != null:
		old.queue_free()
	_current_map = map
	last_change_ms = (Time.get_ticks_usec() - started_usec) / 1000.0
	if OS.is_debug_build():
		print("SceneRouter : %s en %.1f ms" % [map_id, last_change_ms])
	return true


func _instantiate(map_id: StringName) -> GameMap:
	if map_id.is_empty():
		return null
	if map_factory.is_valid():
		return map_factory.call(map_id) as GameMap
	var path := MapCatalog.scene_path(map_id, maps_dir)
	var packed: PackedScene = _scenes.get(path)
	if packed == null and _prefetching.has(path):
		# Déjà en chargement en arrière-plan : on récupère (attente si pas fini).
		_prefetching.erase(path)
		packed = ResourceLoader.load_threaded_get(path) as PackedScene
		if packed != null:
			_scenes[path] = packed
	if packed == null:
		if not ResourceLoader.exists(path):
			return null
		packed = load(path) as PackedScene
		if packed == null:
			return null
		_scenes[path] = packed
	return packed.instantiate() as GameMap


## Lance en arrière-plan le chargement des cartes où mènent les warps de [param map] :
## le changement de carte n'a plus qu'à instancier (pas de lecture disque sous le rideau).
func _prefetch_neighbors(map: GameMap) -> void:
	if map_factory.is_valid() or not is_instance_valid(map):
		return
	for warp: Warp in map.get_warps().get_all():
		if warp.is_coming_soon():
			continue
		var path := MapCatalog.scene_path(warp.target_map, maps_dir)
		if _scenes.has(path) or _prefetching.has(path) or not ResourceLoader.exists(path):
			continue
		if ResourceLoader.load_threaded_request(path, "PackedScene") == OK:
			_prefetching[path] = true


func _disconnect_player() -> void:
	if not is_instance_valid(_player):
		return
	if _player.moved.is_connected(_on_player_moved):
		_player.moved.disconnect(_on_player_moved)
	if _player.bumped.is_connected(_on_player_bumped):
		_player.bumped.disconnect(_on_player_bumped)


func _on_player_moved(cell: Vector2i) -> void:
	if _busy or not is_instance_valid(_current_map):
		return
	if not _player.is_input_enabled():
		return  # pas scripté (scène) : jamais une porte (jalon-03b.md §2.4)
	_follow(_current_map.get_warps().find_on_step(cell, _player.get_facing()))


func _on_player_bumped(direction: Vector2i) -> void:
	if _busy or not is_instance_valid(_current_map):
		return
	_follow(_current_map.get_warps().find_on_push(_player.get_cell(), direction))


func _follow(warp: Warp) -> void:
	if warp == null:
		return
	if warp.is_coming_soon():
		show_coming_soon(warp.coming_soon, warp.target_spawn,
			warp.get_arrival_facing(_player.get_facing()))
	else:
		change_map(warp.target_map, warp.target_spawn,
			warp.get_arrival_facing(_player.get_facing()))
