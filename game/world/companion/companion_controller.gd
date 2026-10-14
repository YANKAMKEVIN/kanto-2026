class_name CompanionController
extends Node
## Le compagnon dans la partie (jalon 11, dossier 14 §8 ; `docs/tech/jalon-11-compagnon.md`
## §2.5 et §2.6). Seul à connaître le jeu autour du compagnon : Boot lui relaie les événements
## (carte, transition, scène, combat, menu, évolution) ; les décisions viennent de
## [CompanionRules] et [CompanionTrail], l'affichage du nœud [Companion].
##
## - **Choix** : [member GameState.companion_uid] ; effacé seulement par RAPPELER, un départ de
##   l'équipe ou une évolution en espèce non éligible ([method refresh], A-11, en silence).
## - **Visible** sur une carte d'extérieur, hors scène, hors combat (caché, D-1), hors transition,
##   pas K.O., avec une case ; rentre au début d'une scène et ressort à la fin (D-2) ; aux portes,
##   rentre pendant le fondu et ressort derrière le joueur à l'arrivée (ou au premier pas).
## - **Suit** chaque pas du joueur ([signal Player.step_started]) et tient doucement sa case
##   d'arrivée (les routines de PNJ l'attendent) ; n'occupe rien d'autre.
## - **Réactions** : curiosité ([method get_interaction_at] → l'appui du joueur → bulle et phrase,
##   [signal line_requested]) ; repos (joueur immobile [constant REST_DELAY] s : regards à gauche,
##   à droite, vers le joueur, toutes les [constant REST_PERIOD] s) ; enthousiasme en attente
##   ([method note_joy] : victoire contre un Dresseur, capture, niveau du compagnon, soin au
##   Centre), joué une fois à son retour sur une carte d'extérieur (petit saut + « ♪ »).

## Le joueur a parlé au compagnon : Boot joue la phrase [param dialogue_id] (jeton
## « {pokemon} » = son nom, [constant DialogueTokens.POKEMON]).
signal line_requested(dialogue_id: StringName)

## Repos [D-5] : délai avant le premier regard, période, durée d'un regard (s).
const REST_DELAY: float = 8.0
const REST_PERIOD: float = 6.0
const REST_LOOK: float = 0.6
## Dialogue « factice » de l'interaction (l'appui est intercepté, aucun dialogue de ce nom).
const TALK_DIALOGUE: StringName = &"companion"
## Variante au féminin d'une phrase accordée (n° 55).
const FEMININE_SUFFIX: String = "_f"
const FEMININE_LINES: Array[StringName] = [CompanionRules.LINE_TIRED]

var _state: Node
var _catalog: CompanionCatalog
var _data: PokemonData
var _player: Player
var _map: GameMap
var _node: Companion
var _trail := CompanionTrail.new()
var _in_cutscene: bool = false
var _in_battle: bool = false
var _in_transition: bool = false
var _joy_pending: bool = false
var _level_before_battle: int = -1
var _last_line: StringName = &""
var _idle: float = 0.0
var _rest_phase: int = -1
var _interaction: Interaction
## Tirage des phrases génériques, hors GameRng (comme les identifiants).
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	name = "CompanionController"
	_rng.randomize()
	_node = Companion.new()


## Le nœud n'est sous aucune carte (aucun compagnon encore montré) : libéré avec le contrôleur.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(_node) and _node.get_parent() == null:
		_node.free()


## Branche le contrôleur (Boot). [param state] : l'autoload GameState (une instance neuve en
## test).
func setup(state: Node, catalog: CompanionCatalog, data: PokemonData, player: Player) -> void:
	_state = state
	_catalog = catalog
	_data = data
	if _player != null and _player.step_started.is_connected(_on_player_step):
		_player.step_started.disconnect(_on_player_step)
	_player = player
	if _player != null:
		_player.step_started.connect(_on_player_step)
	_interaction = Interaction.new(Interaction.Kind.TALK, Vector2i.ZERO, TALK_DIALOGUE,
		Vector2i.ZERO, self)
	set_process(true)


## Le nœud du compagnon (tests, captures).
func get_node_2d() -> Companion:
	return _node


func get_trail() -> CompanionTrail:
	return _trail


## « Réduire les animations » : éclat de Ball réduit.
func set_reduce_motion(reduce: bool) -> void:
	_node.reduce_motion = reduce


## Le Pokémon choisi, s'il l'est encore (null sinon).
func get_chosen() -> Pokemon:
	return _state.call(&"get_companion") as Pokemon if _state != null else null


## Vrai si le compagnon est montré sur la carte.
func is_shown() -> bool:
	return _node != null and _node.visible and _node.is_inside_tree()


# --- Événements relayés par Boot -------------------------------------------------------------

## Transition commencée (porte, téléportation, réveil) : il rentre pendant le fondu.
func on_transition_started() -> void:
	_in_transition = true
	_hide(true)


## Nouvelle carte (écran noir) : le nœud passe sous ses `Entities` et se place derrière le joueur.
func on_map_changed(map: GameMap) -> void:
	_map = map
	_hide(true)
	if _node.get_parent() != null:
		_node.get_parent().remove_child(_node)
	if is_instance_valid(map) and map.get_entities() != null:
		map.get_entities().add_child(_node)
		_node.set_grid(map.get_grid())
		_node.set_grass_front(map.grass_front)


## Arrivée sur la carte (fin du fondu) : il ressort derrière le joueur s'il le peut.
func on_map_entered(_map_entered: GameMap) -> void:
	on_transition_finished()


## Transition close sans changement de carte (écran « à venir », [signal
## SceneRouter.coming_soon_finished]) : il ressort derrière le joueur s'il le peut (sinon au
## premier pas), comme à l'arrivée sur une carte.
func on_transition_finished() -> void:
	_in_transition = false
	_place_and_show(true)


func on_cutscene_started() -> void:
	_in_cutscene = true
	_hide(false)


func on_cutscene_finished() -> void:
	_in_cutscene = false
	_place_and_show(true)


## Combat (D-1) : caché pendant tout le combat, sur place.
func on_battle_started() -> void:
	_in_battle = true
	var chosen := get_chosen()
	_level_before_battle = chosen.level if chosen != null else -1
	if _node != null:
		_node.visible = false


## Fin d'un combat (évolutions comprises) : [param trainer_won] = victoire contre un Dresseur.
## Enthousiasme aussi si le compagnon a gagné un niveau ; espèce mise à jour (évolution), choix
## effacé s'il évolue en espèce non éligible (A-11) ; il réapparaît sur place, sans éclat.
func on_battle_finished(trainer_won: bool) -> void:
	_in_battle = false
	var chosen := _update_choice()
	if chosen != null and (trainer_won or chosen.level > _level_before_battle):
		note_joy()
	_level_before_battle = -1
	if chosen != null and _visible_rules(true):
		_show_if_allowed(false)
	else:
		_hide(true)


## Enthousiasme en attente (capture, niveau du compagnon, soin au Centre, victoire) : joué une
## fois à son prochain retour visible.
func note_joy() -> void:
	if get_chosen() != null:
		_joy_pending = true


## Le choix ou l'équipe ont pu changer (menu, Stockage, soin) : efface le choix s'il le faut,
## change d'espèce, sort (avec l'éclat) ou rentre.
func refresh() -> void:
	var chosen := _update_choice()
	if chosen == null or not _visible_rules(false):
		_hide(false)
		return
	if not is_shown():
		_place_and_show(true)


## Efface le choix s'il le faut (A-11 : en silence) et met l'espèce du nœud à jour ; le Pokémon
## choisi ou null.
func _update_choice() -> Pokemon:
	if _state == null:
		return null
	var uid: String = _state.get(&"companion_uid")
	var chosen := get_chosen()
	if CompanionRules.clear_reason(uid, chosen, _catalog) != CompanionRules.Clear.KEEP:
		_state.call(&"set_companion", null)
		chosen = null
	if chosen != null and chosen.species_id != _node.get_species():
		_node.set_species(chosen.species_id, _catalog.sprite_of(chosen.species_id),
			_catalog.is_flying(chosen.species_id))
	return chosen


# --- Interaction (fournisseur de l'InteractionFinder) ---------------------------------------

## Interaction du compagnon s'il est montré, immobile, sur [param cell] ; sinon null.
func get_interaction_at(cell: Vector2i) -> Interaction:
	if not is_shown() or _node.is_moving() or _node.get_cell() != cell:
		return null
	_interaction.cell = cell
	return _interaction


## Le joueur lui parle (curiosité) : il se tourne vers lui, bulle « ♪ » (« … » si PV bas ou
## statut), et la phrase est demandée ([signal line_requested]).
func talk() -> StringName:
	var chosen := get_chosen()
	if chosen == null or not is_shown():
		return &""
	_node.face(Grid.dominant_direction(_node.get_cell(), _player.get_cell()))
	var worried := CompanionRules.is_low_hp(chosen) or chosen.status != StatusRules.NONE
	_node.show_emote(EmoteBubble.DOTS if worried else EmoteBubble.NOTE)
	var line := CompanionRules.curiosity_line(chosen, _near_water(),
		_catalog.context_of(_map.map_id) if is_instance_valid(_map) else &"", _last_line,
		func(n: int) -> int: return _rng.randi_range(0, n - 1))
	_last_line = line
	if FEMININE_LINES.has(line) and chosen.gender == Pokemon.Gender.FEMALE:
		line = StringName(String(line) + FEMININE_SUFFIX)
	_idle = 0.0
	line_requested.emit(line)
	return line


# --- Interne ----------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not is_shown() or _player == null or _player.is_moving() \
			or not _player.is_input_enabled() or _node.is_moving():
		_idle = 0.0
		if _rest_phase >= 0:
			_rest_phase = -1
		return
	_idle += delta
	if _idle < REST_DELAY:
		return
	# Repos : gauche, droite, joueur (un regard par REST_LOOK), puis pause jusqu'à REST_PERIOD.
	var t := fmod(_idle - REST_DELAY, REST_PERIOD)
	var phase := int(t / REST_LOOK) if t < REST_LOOK * 3.0 else 3
	if phase == _rest_phase:
		return
	_rest_phase = phase
	match phase:
		0:
			_node.face(Vector2i.LEFT)
		1:
			_node.face(Vector2i.RIGHT)
		2:
			_node.face(Grid.dominant_direction(_node.get_cell(), _player.get_cell()))


func _on_player_step(from: Vector2i, to: Vector2i, kind: StringName) -> void:
	_idle = 0.0
	if not _visible_rules(false) or _node.get_parent() == null:
		return
	var step := _trail.on_player_step(from, to, kind)
	_node.move(step)
	if _map != null:
		_map.get_grid().soft_hold(step.to_cell, _node)
	if step.appear:
		_node.step_finished.connect(_play_joy_if_pending.unbind(1), CONNECT_ONE_SHOT)


## Règles de visibilité sauf la case (le suivi l'attribue) ; [param need_place] : exiger la case.
func _visible_rules(need_place: bool) -> bool:
	var input := CompanionRules.VisibilityInput.new()
	input.chosen = get_chosen()
	input.map_interior = not is_instance_valid(_map) or _map.interior
	input.in_cutscene = _in_cutscene
	input.in_battle = _in_battle
	input.in_transition = _in_transition
	input.placed = _trail.is_placed() or not need_place
	return CompanionRules.is_visible(input, _catalog)


## Place derrière le joueur (si la case est libre) puis sort de sa Ball ; sinon il viendra au
## premier pas. [param burst] : avec l'éclat.
func _place_and_show(burst: bool) -> void:
	if not _visible_rules(false) or _player == null or not is_instance_valid(_map):
		_hide(true)
		return
	_update_choice()
	var grid := _map.get_grid()
	# Jalon 12 (T20) : jamais posé sur un passage où l'on marche (échelle, porte) ; sinon au
	# premier pas. Un bord de carte (PUSH) reste une case ordinaire.
	var warps := _map.get_warps()
	var cell := _trail.place_after_arrival(_player.get_cell(), _player.get_facing(),
		func(c: Vector2i) -> bool: return grid.is_free(c) and not _is_step_passage(warps, c))
	if cell == CompanionTrail.NONE:
		_node.visible = false
		grid.soft_release(_node)
		return
	_node.place(cell, _player.get_facing())
	grid.soft_hold(cell, _node)
	await _node.appear(not burst)
	_play_joy_if_pending()


## Montre de nouveau, sur place (fin d'un combat), s'il le peut.
func _show_if_allowed(burst: bool) -> void:
	if _visible_rules(true) and is_instance_valid(_map):
		await _node.appear(not burst)
		_play_joy_if_pending()


func _hide(instant: bool) -> void:
	if _node == null:
		return
	if is_instance_valid(_map) and _map.get_grid() != null:
		_map.get_grid().soft_release(_node)
	_trail.clear()
	if _node.visible and _node.is_inside_tree():
		_node.withdraw(instant)
	else:
		_node.visible = false


func _play_joy_if_pending() -> void:
	if not _joy_pending or not is_shown():
		return
	_joy_pending = false
	_node.hop()
	_node.show_emote(EmoteBubble.NOTE)


## De l'eau à 2 cases au plus du compagnon.
func _near_water() -> bool:
	if not is_instance_valid(_map):
		return false
	var grid := _map.get_grid()
	var center := _node.get_cell()
	var cells: Array[Vector2i] = []
	for dy: int in range(-CompanionRules.WATER_DISTANCE, CompanionRules.WATER_DISTANCE + 1):
		for dx: int in range(-CompanionRules.WATER_DISTANCE, CompanionRules.WATER_DISTANCE + 1):
			var cell := center + Vector2i(dx, dy)
			if grid.is_in_bounds(cell) and grid.is_water(cell):
				cells.append(cell)
	return CompanionRules.is_near_water(center, cells)


## Jalon 12 (T20) : vrai si [param cell] porte un passage déclenché en y marchant (échelle, porte :
## [constant Warp.Trigger.STEP_ON]) ; le compagnon n'y est jamais posé à l'arrivée.
static func _is_step_passage(warps: WarpTable, cell: Vector2i) -> bool:
	if warps == null:
		return false
	for warp: Warp in warps.get_at(cell):
		if warp.trigger == Warp.Trigger.STEP_ON:
			return true
	return false
