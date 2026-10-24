class_name MountDirector
extends Node
## Monture du joueur dans la partie (passe systèmes 2, `docs/tech/systemes-2.md` §2.2 à §2.4).
## Enfant de [Boot], comme [FlashDirector]. **Aucune règle ici** : l'arrivée vient de
## [method MountRules.on_map_entered], monter et descendre de [BikeRules].
##
## - **Arrivée** ([method on_map_changed], écran noir, joueur déjà posé) : la monture sauvegardée
##   ([member GameState.player_mount]) est gardée, retirée (intérieur, terre ferme) ou posée
##   d'office (Piste Cyclable avec la Bicyclette), sans mise en scène.
## - **Vélo** ([method toggle_bike] : bouton du HUD, Sac, touche B) : monte ou descend ; un refus
##   joue son texte (dossier 25 §16.1 : intérieur, Piste).
## - **État** : [member GameState.player_mount] suit [signal Player.mount_changed] ;
##   [member GameState.last_land_cell] suit chaque pas à terre.
## - **Bouton du HUD** ([method ExplorationHud.set_bike_button]) : visible avec la Bicyclette,
##   grisé là où il refuse ; tenu à jour à chaque image (lecture du Sac, sans coût notable).
##   Action clavier `bike` (touche B) pour les tests desktop.
## - **Surf** (S2C, §2.5) : face à une eau surfable, [method surf_target] propose au bouton
##   contextuel SURFER (capacité prête) ou EXAMINER (`surf_water`, variantes `surf:<état>`) ;
##   [method start_surf] monte : le Vélo est rangé, le joueur saute sur l'eau (le pas est un saut,
##   [method MountRules.is_surf_hop]), texte T-3 la première fois. En mer, un pas vers la terre
##   est la descente : le joueur repasse à pied à l'arrivée ([method _on_player_moved]).
## - **Reprise** ([method resume_cell], branchée sur [member SceneRouter.arrival_resolver]) : en
##   Surf, [method SurfRules.resume] choisit la case (eau si les conditions tiennent, sinon la
##   dernière terre, sinon l'arrivée de la carte).
## Le compagnon rentre et ressort seul ([CompanionController], [signal Player.mount_changed]).

## Refus du Vélo (texte joué) : [param check] = [enum BikeRules.Check].
signal bike_refused(check: BikeRules.Check)
## Le joueur vient de monter en Surf (fin du saut) ou d'en descendre (arrivé sur la rive).
signal surf_mounted
signal surf_dismounted

## Objet clé de la Bicyclette (même identifiant que le J22).
const BICYCLE: StringName = &"bicycle"
## Refus (dossier 25 §16.1.3 et §16.1.4, validés ; `data/dialogues/mount.json`).
const INDOORS_DIALOGUE: StringName = &"bike_indoors"
const CYCLING_ROAD_DIALOGUE: StringName = &"bike_cycling_road_walk"
## Surf (dossier 27 T-1, T-2, T-3, validés) : `data/dialogues/mount.json`.
const SURF_WATER_DIALOGUE: StringName = &"surf_water"
const SURF_FIRST_DIALOGUE: StringName = &"surf_first_ride"
## Drapeau posé après le texte T-3 (« première fois seulement ») [D].
const SURF_FIRST_FLAG: StringName = &"surf_first_ride_seen"
## Capacité de terrain du Surf ([FieldMoves]).
const SURF_MOVE: StringName = &"surf"
## Point d'arrivée de repli d'une reprise sans case sûre ([method resume_cell]) [D].
const FALLBACK_SPAWN: StringName = &"depart"

## Action d'entrée du Vélo (clavier, tests desktop).
const ACTION: StringName = &"bike"

## Rappel () -> bool : vrai quand le joueur peut monter ou descendre (partie stable).
var can_toggle: Callable
## Rappel () -> FieldMoves.State : état du Surf hors combat (CS03, Badge Âme, Pokémon). Non
## valide : NO_HM (jamais SURFER).
var surf_state: Callable

## État de la partie (GameState ou un double de test) : Sac, monture, case à terre.
var _state: Node
var _player: Player
var _runner: DialogueRunner
var _map: GameMap
var _hud: ExplorationHud
## Cible de terrain rendue par [method surf_target], gardée tant qu'elle ne change pas (le
## contrôleur compare les instances).
var _surf_target: Interaction
## Vrai entre [method start_surf] et la fin du saut sur l'eau.
var _mounting: bool = false


func _init() -> void:
	name = "MountDirector"


func _process(_delta: float) -> void:
	if _hud != null:
		_hud.set_bike_button(has_bike(), is_bike_blocked())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION) and has_bike():
		toggle_bike()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if SceneRouter.map_changed.is_connected(on_map_changed):
		SceneRouter.map_changed.disconnect(on_map_changed)
	if SceneRouter.arrival_resolver == Callable(self, &"resume_cell"):
		SceneRouter.arrival_resolver = Callable()


## Branche le directeur (rappelable). [param runner] : les refus (null en test : aucun texte) ;
## [param hud] : le bouton Vélo (null : aucun). Se branche sur [signal SceneRouter.map_changed].
func setup(state: Node, player: Player, runner: DialogueRunner,
		hud: ExplorationHud = null) -> void:
	if is_instance_valid(_player) and _player.mount_changed.is_connected(_on_mount_changed):
		_player.mount_changed.disconnect(_on_mount_changed)
		_player.moved.disconnect(_on_player_moved)
	if is_instance_valid(_hud) and _hud.bike_requested.is_connected(_on_bike_requested):
		_hud.bike_requested.disconnect(_on_bike_requested)
	_state = state
	_player = player
	_runner = runner
	_hud = hud
	if _player != null:
		_player.mount_changed.connect(_on_mount_changed)
		_player.moved.connect(_on_player_moved)
	if _hud != null:
		_hud.bike_requested.connect(_on_bike_requested)
	if not SceneRouter.map_changed.is_connected(on_map_changed):
		SceneRouter.map_changed.connect(on_map_changed)
	SceneRouter.arrival_resolver = resume_cell


## Vrai si la Bicyclette est dans le Sac (bouton du HUD visible).
func has_bike() -> bool:
	return _state != null and (_state.get(&"bag") as Bag).has(BICYCLE)


## Vrai si le Vélo ne peut pas être enfourché ou quitté ici (bouton grisé) : intérieur, ou
## descente sur la Piste.
func is_bike_blocked() -> bool:
	if not is_instance_valid(_map) or not is_instance_valid(_player):
		return false
	if _player.get_mount() == Mount.Kind.BIKE:
		return _map.is_cycling_road_at(_player.get_cell())
	if _player.get_mount() == Mount.Kind.SURF:
		return true
	return not _map.mount_traits().allows_bike()


## Nouvelle carte (écran noir, joueur déjà posé) : monture d'arrivée, sans mise en scène.
func on_map_changed(map: GameMap) -> void:
	_map = map
	_mounting = false
	_surf_target = null
	if not is_instance_valid(map) or not is_instance_valid(_player):
		return
	var current := _player.get_mount()
	if _state != null:
		current = _state.get(&"player_mount") as Mount.Kind
	var kind := MountRules.on_map_entered(current, map.mount_traits_at(_player.get_cell()),
		_player.get_cell(),
		map.get_grid(), has_bike())
	_player.set_mount(kind, true)
	_sync_state(kind)
	if kind != Mount.Kind.SURF and _state != null:
		_state.set(&"last_land_cell", _player.get_cell())


## Monte ou descend du Vélo. Rend [constant BikeRules.Check.OK] si la monture a changé ; un
## refus d'intérieur ou de Piste joue son texte ([signal bike_refused]). En Surf : BUSY, rien.
func toggle_bike() -> BikeRules.Check:
	if not is_instance_valid(_player) or not is_instance_valid(_map):
		return BikeRules.Check.BUSY
	var busy: bool = _player.is_moving() or (can_toggle.is_valid() and not can_toggle.call()) \
		or _player.get_mount() == Mount.Kind.SURF
	var check: BikeRules.Check
	if _player.get_mount() == Mount.Kind.BIKE:
		check = BikeRules.can_dismount(_map.is_cycling_road_at(_player.get_cell()), busy)
	else:
		check = BikeRules.can_mount(has_bike(), not _map.mount_traits().allows_bike(), busy)
	if check == BikeRules.Check.OK:
		var riding := _player.get_mount() == Mount.Kind.BIKE
		_player.set_mount(Mount.Kind.NONE if riding else Mount.Kind.BIKE)
		return check
	_refuse(check)
	return check


## État du Surf hors combat ([member surf_state]).
func get_surf_state() -> FieldMoves.State:
	if not surf_state.is_valid():
		return FieldMoves.State.NO_HM
	return surf_state.call() as FieldMoves.State


## Cible de terrain du bouton contextuel ([member InteractionController.terrain_target]) pour le
## joueur à pied en [param cell], tourné vers [param facing] : SURFER si l'eau de devant est
## surfable, libre et la capacité prête ; EXAMINER (`surf_water`, ses variantes disent ce qui
## manque) si elle manque ; null sinon (en mer, terre devant, eau occupée ou décor).
func surf_target(cell: Vector2i, facing: Vector2i) -> Interaction:
	if not is_instance_valid(_map) or not is_instance_valid(_player) \
			or _player.get_mount() == Mount.Kind.SURF or _mounting:
		return null
	var check := SurfRules.can_mount(_map.get_grid(), cell, facing, get_surf_state(), false,
		_player)
	var kind := Interaction.Kind.EXAMINE
	var dialogue := SURF_WATER_DIALOGUE
	match check:
		SurfRules.MountCheck.READY:
			kind = Interaction.Kind.SURF
			dialogue = &""
		SurfRules.MountCheck.NO_HM, SurfRules.MountCheck.NO_BADGE, \
				SurfRules.MountCheck.NO_POKEMON:
			pass
		_:
			return null
	var target_cell := cell + facing
	if _surf_target == null or _surf_target.kind != kind or _surf_target.cell != target_cell \
			or _surf_target.dialogue_id != dialogue:
		_surf_target = Interaction.new(kind, target_cell, dialogue)
	return _surf_target


## Monte en Surf vers l'eau de devant (bouton SURFER) : le Vélo est rangé, le joueur saute sur
## l'eau ; T-3 la première fois, à la fin du saut. Rend READY si le saut est parti, sinon la
## raison (BLOCKED aussi quand la partie n'est pas libre).
func start_surf() -> SurfRules.MountCheck:
	if not is_instance_valid(_player) or not is_instance_valid(_map) or _mounting:
		return SurfRules.MountCheck.BLOCKED
	if _player.is_moving() or (can_toggle.is_valid() and not can_toggle.call()):
		return SurfRules.MountCheck.BLOCKED
	var facing := _player.get_facing()
	var check := SurfRules.can_mount(_map.get_grid(), _player.get_cell(), facing,
		get_surf_state(), false, _player)
	if check != SurfRules.MountCheck.READY:
		return check
	var previous := _player.get_mount()
	_player.set_mount(Mount.Kind.SURF)
	if not _player.script_step(facing):
		_player.set_mount(previous)
		return SurfRules.MountCheck.BLOCKED
	_mounting = true
	return check


## Case de reprise d'une partie sur [param map] ([member SceneRouter.arrival_resolver]) : en
## Surf, celle de [method SurfRules.resume] (la monture d'arrivée suit la case : eau → Surf, terre
## → à pied, [method on_map_changed]) ; sinon (-1, -1) : le routeur garde sa règle.
func resume_cell(map: GameMap, cell: Vector2i) -> Vector2i:
	if _state == null or not is_instance_valid(map) \
			or (_state.get(&"player_mount") as Mount.Kind) != Mount.Kind.SURF:
		return Vector2i(-1, -1)
	var spawn := map.get_spawn_cell(FALLBACK_SPAWN) if map.has_spawn(FALLBACK_SPAWN) \
		else map.find_standing_cell(cell, _player)
	var result := SurfRules.resume(map.get_grid(), cell, Mount.Kind.SURF,
		_state.get(&"last_land_cell") as Vector2i, spawn, get_surf_state(),
		Callable(), _player)
	if result.reason != SurfRules.ResumeReason.AS_SAVED:
		print("MountDirector : reprise en Surf impossible en %s sur %s, reprise en %s (%s)" % [
			cell, map.map_id, result.cell, SurfRules.ResumeReason.keys()[result.reason]])
	if not result.is_surfing():
		_state.set(&"player_mount", Mount.Kind.NONE)
	return result.cell


func _refuse(check: BikeRules.Check) -> void:
	var dialogue := &""
	match check:
		BikeRules.Check.INDOORS:
			dialogue = INDOORS_DIALOGUE
		BikeRules.Check.ON_CYCLING_ROAD:
			dialogue = CYCLING_ROAD_DIALOGUE
	if dialogue.is_empty():
		return
	bike_refused.emit(check)
	if _runner != null:
		_runner.play(dialogue, null, _map)


func _sync_state(kind: Mount.Kind) -> void:
	if _state != null:
		_state.set(&"player_mount", kind)


func _on_bike_requested() -> void:
	toggle_bike()


func _on_mount_changed(kind: Mount.Kind) -> void:
	_sync_state(kind)


func _on_player_moved(cell: Vector2i) -> void:
	var grid := _map.get_grid() if is_instance_valid(_map) else null
	if _player.get_mount() == Mount.Kind.SURF and grid != null and not grid.is_surfable(cell):
		# Descente : le pas vers la rive vient de finir (un saut, MountRules.is_surf_hop).
		_mounting = false
		_player.set_mount(Mount.Kind.NONE)
		surf_dismounted.emit()
	if _state != null and _player.get_mount() != Mount.Kind.SURF:
		_state.set(&"last_land_cell", cell)
	if _mounting and _player.get_mount() == Mount.Kind.SURF:
		_mounting = false
		surf_mounted.emit()
		var played := _play_first_ride()
		_follow_edge_after_mount(cell, played)


## T-3 « {pokemon} vous porte sur l'eau ! », la première fois seulement.
## Rend vrai si le texte a été lancé.
func _play_first_ride() -> bool:
	var flags: StoryFlags = _state.get(&"flags") as StoryFlags if _state != null else null
	if flags == null or flags.has_flag(SURF_FIRST_FLAG):
		return false
	flags.set_flag(SURF_FIRST_FLAG)
	if _runner != null:
		_runner.play(SURF_FIRST_DIALOGUE, null, _map)
		return true
	return false


## Mise à l'eau sur la dernière case d'un bord (ex. Cramois'Île, colonne 33) : le saut est un pas
## scripté, qui ne déclenche aucun passage (`SceneRouter._on_player_moved`) ; sans ce relais le
## joueur resterait collé au bord jusqu'à une poussée de plus. Si la case porte un passage PUSH
## dans le sens du saut, on le suit comme une poussée (après T-3 quand il vient d'être lancé).
func _follow_edge_after_mount(cell: Vector2i, wait_for_text: bool) -> void:
	if not is_instance_valid(_map) or not is_instance_valid(_player):
		return
	var facing := _player.get_facing()
	if _map.get_warps().find_on_push(cell, facing) == null:
		return
	if wait_for_text and _runner != null:
		await _runner.dialogue_finished
	if not is_instance_valid(_player) or _player.get_mount() != Mount.Kind.SURF \
			or _player.get_cell() != cell:
		return
	SceneRouter.follow_warp_at.call_deferred(cell, facing)
