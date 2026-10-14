extends GutTest
## SceneRouter (jalon 2 §2.2, T5) sur une instance fraîche du routeur, jamais l'autoload :
## deux mini-cartes fabriquées en code (A : porte STEP_ON UP ; B : tapis PUSH DOWN) et un
## ScreenFade aux durées courtes.

const ROUTER_SCRIPT := preload("res://game/autoload/scene_router.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const FADE_SCENE := preload("res://game/ui/components/screen_fade.tscn")
const FRAME := 1.0 / 60.0
const FADE_TIME := 0.05
const TIMEOUT := 3.0
const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right", &"run",
]
## Carte A (8 × 6) : départ (3, 4), porte (3, 1) ouverte au nord (case (3, 0) libre).
const A_START := Vector2i(3, 4)
const A_DOOR := Vector2i(3, 1)
## Carte B (6 × 5) : tapis de sortie (2, 4) sur la dernière rangée.
const B_MAT := Vector2i(2, 4)
## Carte C (8 × 6) : deux destinations « à venir » au nord (cases (2, 1) et (5, 1)).
const C_START := Vector2i(2, 3)

var _router: Node
var _world: Node2D
var _player: Player
var _fade: ScreenFade
## Cartes fabriquées, par identifiant (la dernière instance).
var _made: Dictionary[StringName, GameMap] = {}
var _events: Array[String] = []
## Rideau opaque à chaque appel du présentateur « à venir » ([method _install_presenter]).
var _opaque_when_shown: Array[bool] = []


func before_each() -> void:
	_chain_dir = CHAIN_DIR
	_made.clear()
	_events.clear()
	_opaque_when_shown.clear()
	_router = ROUTER_SCRIPT.new()
	add_child_autofree(_router)
	_router.map_factory = _make_map
	_router.fade_out_duration = FADE_TIME
	_router.fade_in_duration = FADE_TIME
	_world = Node2D.new()
	add_child_autofree(_world)
	_fade = FADE_SCENE.instantiate() as ScreenFade
	add_child_autofree(_fade)
	_player = PLAYER_SCENE.instantiate() as Player
	autofree(_player)
	_router.setup(_world, _player, _fade)
	_router.transition_started.connect(func(id: StringName) -> void:
		_events.append("transition_started:%s" % id))
	_router.map_changed.connect(func(map: GameMap) -> void:
		_events.append("map_changed:%s" % map.map_id))
	_router.map_entered.connect(func(map: GameMap) -> void:
		_events.append("map_entered:%s" % map.map_id))
	watch_signals(_router)


func after_each() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)


# --- Mini-cartes --------------------------------------------------------------------

func _make_map(map_id: StringName) -> GameMap:
	var map: GameMap
	match map_id:
		&"a":
			map = _base_map(map_id, Vector2i(8, 6))
			_spawn(map, &"start", A_START)
			_spawn(map, &"door", A_DOOR)
			_warp(map, A_DOOR, Warp.Trigger.STEP_ON, Vector2i.UP, &"b", &"entrance")
		&"b":
			map = _base_map(map_id, Vector2i(6, 5))
			_spawn(map, &"entrance", B_MAT)
			_warp(map, B_MAT, Warp.Trigger.PUSH, Vector2i.DOWN, &"a", &"door")
		&"c":
			# Fixture « à venir » : deux destinations, déclarées par données seulement.
			map = _base_map(map_id, Vector2i(8, 6))
			map.blocked_cells = [Vector2i(2, 0), Vector2i(5, 0)] as Array[Vector2i]
			_spawn(map, &"start", C_START)
			_spawn(map, &"soon_a", Vector2i(2, 2))
			_spawn(map, &"soon_b", Vector2i(5, 2))
			_soon(map, Vector2i(2, 1), "Route 2", &"soon_a")
			_soon(map, Vector2i(5, 1), "Jadielle", &"soon_b")
		_:
			return null
	_made[map_id] = map
	return map


func _base_map(map_id: StringName, map_size: Vector2i) -> GameMap:
	var map := GameMap.new()
	map.name = String(map_id).to_upper()
	map.map_id = map_id
	map.size = map_size
	for group: String in ["Entities", "Spawns", "Warps"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		map.add_child(node)
	return map


func _spawn(map: GameMap, spawn_name: StringName, cell: Vector2i) -> void:
	var marker := Marker2D.new()
	marker.name = spawn_name
	marker.position = Grid.cell_to_world(cell)
	map.get_node(^"Spawns").add_child(marker)


func _warp(
	map: GameMap, cell: Vector2i, trigger: Warp.Trigger, direction: Vector2i,
	to_map: StringName, to_spawn: StringName
) -> void:
	var point := WarpPoint.new()
	point.name = "Warp%d_%d" % [cell.x, cell.y]
	point.position = Grid.cell_to_world(cell)
	point.trigger = trigger
	point.direction = direction
	point.target_map = to_map
	point.target_spawn = to_spawn
	map.get_node(^"Warps").add_child(point)


func _soon(map: GameMap, cell: Vector2i, label: String, return_spawn: StringName) -> void:
	var point := WarpPoint.new()
	point.name = "Soon%d_%d" % [cell.x, cell.y]
	point.position = Grid.cell_to_world(cell)
	point.trigger = Warp.Trigger.PUSH
	point.direction = Vector2i.UP
	point.coming_soon = label
	point.target_spawn = return_spawn
	point.arrival_facing = Vector2i.DOWN
	map.get_node(^"Warps").add_child(point)


# --- Outils -------------------------------------------------------------------------

## Démarre sur A ; les images du joueur sont ensuite simulées à la main.
func _start_on_a() -> GameMap:
	var map: GameMap = _router.start(&"a", &"start", Vector2i.UP)
	_player.set_process(false)
	return map


## Simule des images du joueur jusqu'à [param done] (ou [param max_seconds]).
func _simulate_until(done: Callable, max_seconds: float = 2.0) -> void:
	var frames := roundi(max_seconds / FRAME)
	for i: int in frames:
		_player._process(FRAME)
		if done.call():
			return


func _simulate(seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		_player._process(FRAME)


func _await_idle() -> void:
	await wait_until(func() -> bool: return not _router.is_transitioning(), TIMEOUT)


func _count(prefix: String) -> int:
	var n := 0
	for event: String in _events:
		if event.begins_with(prefix):
			n += 1
	return n


# --- 1. start -------------------------------------------------------------------------

func test_start_places_player_and_emits_changed_then_entered() -> void:
	var map := _start_on_a()
	assert_not_null(map)
	assert_eq(_router.get_current_map(), _made[&"a"])
	assert_eq(map.get_parent(), _world)
	assert_eq(_player.get_parent(), map.get_entities())
	assert_eq(_player.get_cell(), A_START)
	assert_eq(_player.get_facing(), Vector2i.UP)
	assert_eq(_events, ["map_changed:a", "map_entered:a"] as Array[String])
	assert_false(_router.is_transitioning())
	assert_true(_player.is_input_enabled())
	assert_false(_fade.is_opaque())


# --- 2. porte STEP_ON ---------------------------------------------------------------

func test_step_on_door_locks_same_frame_then_arrives_in_b() -> void:
	_start_on_a()
	var map_a := _made[&"a"]
	var player_before := _player
	var moved_cells: Array[Vector2i] = []
	_player.moved.connect(func(cell: Vector2i) -> void: moved_cells.append(cell))
	Input.action_press(&"move_up")
	_simulate_until(func() -> bool: return moved_cells.has(A_DOOR))
	# Même image que le pas terminé sur la porte : entrées déjà bloquées.
	assert_eq(_player.get_cell(), A_DOOR)
	assert_false(_player.is_input_enabled(), "bloqué dans la même image")
	assert_true(_router.is_transitioning())
	assert_signal_emitted_with_parameters(_router, "transition_started", [&"b"])
	Input.action_release(&"move_up")
	await wait_for_signal(_router.map_entered, TIMEOUT)
	assert_eq(_router.get_current_map(), _made[&"b"])
	assert_eq(_player, player_before, "même instance du joueur")
	assert_eq(_player.get_parent(), _made[&"b"].get_entities())
	assert_eq(_player.get_cell(), B_MAT)
	assert_eq(_player.get_facing(), Vector2i.UP, "orientation conservée")
	assert_false(is_instance_valid(map_a), "carte A libérée")
	assert_true(_player.is_input_enabled(), "entrées rétablies")
	assert_false(_router.is_transitioning())


func test_blocked_step_ending_on_the_door_does_not_change_map() -> void:
	_start_on_a()
	_player.enter_map(_made[&"a"].get_grid(), A_DOOR + Vector2i.DOWN, Vector2i.UP,
		_made[&"a"].get_pixel_rect())
	_player.set_input_enabled(false, &"cutscene")
	# Pas scripté (jalon 3B) : il part même bloqué.
	assert_true(_player._mover.start_step(Vector2i.UP))
	_simulate_until(func() -> bool: return not _player.is_moving())
	assert_eq(_player.get_cell(), A_DOOR)
	assert_false(_router.is_transitioning(), "joueur bloqué : pas de porte")
	assert_signal_not_emitted(_router, "transition_started")
	assert_eq(_router.get_current_map(), _made[&"a"])
	_player.set_input_enabled(true, &"cutscene")


# --- 3. tapis PUSH ------------------------------------------------------------------

func test_holding_down_on_mat_returns_to_door_facing_down() -> void:
	_start_on_a()
	_router.change_map(&"b", &"entrance")
	await wait_for_signal(_router.map_entered, TIMEOUT)
	assert_eq(_router.get_current_map(), _made[&"b"])
	_player.set_process(false)
	Input.action_press(&"move_down")
	_simulate_until(func() -> bool: return _router.is_transitioning())
	assert_true(_router.is_transitioning(), "pousser vers le bas déclenche le tapis")
	assert_false(_player.is_input_enabled())
	Input.action_release(&"move_down")
	await wait_for_signal(_router.map_entered, TIMEOUT)
	assert_eq(_router.get_current_map().map_id, &"a")
	assert_eq(_player.get_cell(), A_DOOR, "arrivée sur la case de porte")
	assert_eq(_player.get_facing(), Vector2i.DOWN)


# --- 4. direction tenue pendant le fondu ----------------------------------------------

func test_player_stays_on_door_during_fade_while_direction_held() -> void:
	_start_on_a()
	var grid_a := _made[&"a"].get_grid()
	Input.action_press(&"move_up")
	_simulate_until(func() -> bool: return _router.is_transitioning())
	assert_eq(_player.get_cell(), A_DOOR)
	# Le fondu avance sur les images du moteur ; le joueur, lui, reçoit encore des images.
	for i: int in 3:
		_simulate(0.3)
		await wait_process_frames(1)
		assert_true(_router.is_transitioning())
		if _router.get_current_map() != _made[&"a"]:
			break
		assert_eq(_player.get_cell(), A_DOOR, "reste sur la porte")
		assert_false(_player.is_moving())
		assert_false(grid_a.is_occupied(A_DOOR + Vector2i.UP), "case au-delà libre")
		assert_eq(_player.position, Grid.cell_to_world(A_DOOR))
	await wait_for_signal(_router.map_entered, TIMEOUT)
	assert_eq(_player.get_cell(), B_MAT)


# --- 5. un seul passage à la fois ------------------------------------------------------

func test_second_change_map_during_transition_is_ignored() -> void:
	_start_on_a()
	_events.clear()
	_router.change_map(&"b", &"entrance")
	_router.change_map(&"a", &"start")
	await _await_idle()
	await wait_process_frames(3)
	assert_eq(_count("transition_started"), 1)
	assert_eq(_count("map_entered"), 1)
	assert_eq(_router.get_current_map().map_id, &"b")
	assert_eq(_player.get_cell(), B_MAT)


# --- 6. carte ou spawn inconnus ----------------------------------------------------------

func test_unknown_map_keeps_current_map() -> void:
	_start_on_a()
	var map_a := _made[&"a"]
	_events.clear()
	_router.change_map(&"nowhere", &"entrance")
	await _await_idle()
	assert_push_error("carte inconnue")
	assert_eq(_router.get_current_map(), map_a)
	assert_eq(_player.get_parent(), map_a.get_entities())
	assert_eq(_player.get_cell(), A_START)
	assert_true(_player.is_input_enabled(), "entrées rétablies")
	assert_eq(_count("map_entered"), 0)
	assert_eq(_count("map_changed"), 0)
	assert_false(_fade.is_opaque(), "rideau relevé")


func test_unknown_spawn_keeps_current_map() -> void:
	_start_on_a()
	var map_a := _made[&"a"]
	_events.clear()
	_router.change_map(&"b", &"nowhere")
	await _await_idle()
	assert_push_error("spawn inconnu")
	assert_eq(_router.get_current_map(), map_a)
	assert_eq(_player.get_cell(), A_START)
	assert_true(_player.is_input_enabled())
	assert_eq(_count("map_entered"), 0)
	assert_eq(_world.get_child_count(), 1, "carte B écartée")


# --- 7. rideau opaque pendant le changement ------------------------------------------------

func test_fade_is_opaque_when_map_changes() -> void:
	_start_on_a()
	var opaque_at_change: Array[bool] = []
	_router.map_changed.connect(func(_map: GameMap) -> void:
		opaque_at_change.append(_fade.is_opaque()))
	_router.change_map(&"b", &"entrance")
	await wait_for_signal(_router.map_entered, TIMEOUT)
	assert_eq(opaque_at_change, [true] as Array[bool])
	assert_false(_fade.is_opaque(), "rideau relevé à l'arrivée")
	assert_eq(_events.slice(-3), [
		"transition_started:b", "map_changed:b", "map_entered:b",
	] as Array[String])


# --- Divers --------------------------------------------------------------------------------

func test_without_fade_transition_is_immediate() -> void:
	_router.setup(_world, _player, null)
	_start_on_a()
	_router.change_map(&"b", &"entrance")
	assert_eq(_router.get_current_map(), _made[&"b"])
	assert_false(_router.is_transitioning())
	assert_true(_player.is_input_enabled())


func test_setup_again_disconnects_previous_player() -> void:
	var other := PLAYER_SCENE.instantiate() as Player
	autofree(other)
	_router.setup(_world, other, _fade)
	assert_false(_player.moved.is_connected(_router._on_player_moved))
	assert_true(other.moved.is_connected(_router._on_player_moved))
	assert_eq(_router.get_player(), other)


func test_default_fade_durations_come_from_tokens() -> void:
	var fresh: Node = ROUTER_SCRIPT.new()
	assert_eq(fresh.fade_out_duration, UiTokens.ANIM_FADE_OUT)
	assert_eq(fresh.fade_in_duration, UiTokens.ANIM_FADE_IN)
	assert_eq(fresh.maps_dir, MapCatalog.MAPS_DIR)
	fresh.free()


func test_real_maps_neighbors_prefetched_then_used() -> void:
	# Cartes réelles (sans fabrique) : les cibles des warps se chargent en arrière-plan.
	_router.map_factory = Callable()
	_router.setup(_world, _player, null)
	var map: GameMap = _router.start(&"player_house_1f", &"entrance", Vector2i.UP)
	assert_not_null(map)
	var town := MapCatalog.scene_path(&"pallet_town")
	var bedroom := MapCatalog.scene_path(&"player_house_2f")
	assert_true(_router._prefetching.has(town), "Bourg Palette préchargé")
	assert_true(_router._prefetching.has(bedroom), "chambre préchargée")
	_router.change_map(&"pallet_town", &"player_house_door")
	assert_eq(_router.get_current_map().map_id, &"pallet_town")
	assert_eq(_player.get_cell(), Vector2i(36, 9))
	assert_false(_router._prefetching.has(town), "chargement récupéré")
	assert_true(_router._scenes.has(town), "scène gardée en cache")


# --- Reprise sur une case (jalon 5C.5) -------------------------------------------------

func test_start_at_places_the_player_on_the_cell_and_emits_like_start() -> void:
	var map: GameMap = _router.start_at(&"a", Vector2i(5, 2), Vector2i.LEFT)
	assert_not_null(map)
	assert_eq(_router.get_current_map(), map)
	assert_eq(_player.get_cell(), Vector2i(5, 2), "sur la case sauvegardée")
	assert_eq(_player.get_facing(), Vector2i.LEFT, "orientation sauvegardée")
	assert_true(_player.is_input_enabled())
	assert_false(_router.is_transitioning())
	assert_eq(_events, ["map_changed:a", "map_entered:a"] as Array[String])
	assert_push_error_count(0)


func test_start_at_moves_to_the_nearest_free_cell_when_the_cell_is_taken() -> void:
	# Case (5, 2) devenue solide (décor ajouté depuis la sauvegarde) : case voisine praticable.
	_router.map_factory = func(map_id: StringName) -> GameMap:
		var made := _make_map(map_id)
		if made != null:
			made.blocked_cells = [Vector2i(5, 2)] as Array[Vector2i]
		return made
	var map: GameMap = _router.start_at(&"a", Vector2i(5, 2), Vector2i.UP)
	assert_not_null(map)
	var cell := _player.get_cell()
	assert_ne(cell, Vector2i(5, 2))
	assert_eq(absi(cell.x - 5) + absi(cell.y - 2), 1, "case voisine")
	assert_true(map.get_grid().get_occupant(cell) == _player)
	# Hors carte : ramenée au bord.
	_router.setup(_world, _player, null)
	_router.start_at(&"a", Vector2i(40, -3), Vector2i.DOWN)
	assert_eq(_player.get_cell(), Vector2i(7, 0), "case ramenée dans la carte")
	assert_push_error_count(0)


func test_start_at_an_unknown_map_changes_nothing() -> void:
	_router.start(&"a", &"start", Vector2i.UP)
	_events.clear()
	assert_null(_router.start_at(&"nowhere", Vector2i(1, 1), Vector2i.UP))
	assert_eq(_router.get_current_map().map_id, &"a", "carte courante gardée")
	assert_eq(_player.get_cell(), A_START)
	assert_true(_events.is_empty(), "aucun signal")
	assert_push_error_count(0)


# --- Destinations « à venir » (jalon 5, dossier-07 §12) ----------------------------------

## Présentateur de test : enregistre le libellé et l'état du rideau au moment où l'écran
## est montré (dans [member _opaque_when_shown] : relevé à l'événement lui-même, pas après
## un await dont la reprise dépend de la charge de la machine), puis rend la main après un
## court délai.
func _install_presenter(shown: Array[String]) -> void:
	_router.coming_soon_presenter = func(label: String) -> void:
		shown.append(label)
		_opaque_when_shown.append(_fade.is_opaque())
		await get_tree().create_timer(0.05).timeout


func _start_on_c(spawn: StringName = &"start") -> void:
	_router.start(&"c", spawn, Vector2i.UP)
	_player.set_process(false)


func _push_up_until_transition() -> void:
	Input.action_press(&"move_up")
	_simulate_until(func() -> bool: return _router.is_transitioning(), 3.0)
	Input.action_release(&"move_up")


func test_coming_soon_shows_the_screen_then_returns_without_changing_map() -> void:
	var shown: Array[String] = []
	_install_presenter(shown)
	_start_on_c()
	var map_c := _made[&"c"]
	_events.clear()
	_push_up_until_transition()
	assert_true(_router.is_transitioning(), "pousser vers le haut sur la case déclenche")
	assert_false(_player.is_input_enabled(), "entrées bloquées dans la même image")
	assert_eq(_player.get_cell(), Vector2i(2, 1))
	await _await_idle()
	assert_signal_emit_count(_router, "coming_soon_shown", 1)
	assert_eq(_opaque_when_shown, [true] as Array[bool], "écran montré sous le rideau opaque")
	assert_eq(shown, ["Route 2"] as Array[String])
	assert_eq(_router.get_current_map(), map_c, "aucune carte chargée")
	assert_eq(_player.get_cell(), Vector2i(2, 2), "retour sur le spawn de la carte")
	assert_eq(_player.get_facing(), Vector2i.DOWN, "tourné vers le sud")
	assert_true(_player.is_input_enabled())
	assert_false(_fade.is_opaque())
	assert_eq(_events, ["transition_started:"] as Array[String],
		"ni map_changed ni map_entered : pas de titre de zone, pas de zone découverte")
	# QA finale 12D : la transition ouverte est fermée (le compagnon ressort), carte inchangée.
	assert_signal_emit_count(_router, "coming_soon_finished", 1)
	assert_signal_emitted_with_parameters(_router, "coming_soon_finished", [map_c])
	assert_push_error_count(0)


func test_a_second_destination_is_declared_by_data_only() -> void:
	var shown: Array[String] = []
	_install_presenter(shown)
	_start_on_c()
	_player.enter_map(_made[&"c"].get_grid(), Vector2i(5, 3), Vector2i.UP,
		_made[&"c"].get_pixel_rect())
	_push_up_until_transition()
	await _await_idle()
	assert_eq(shown, ["Jadielle"] as Array[String])
	assert_eq(_player.get_cell(), Vector2i(5, 2))
	assert_eq(_player.get_facing(), Vector2i.DOWN)


func test_coming_soon_is_inert_when_disabled_as_in_a_release_build() -> void:
	var shown: Array[String] = []
	_install_presenter(shown)
	_router.coming_soon_enabled = false
	_start_on_c()
	Input.action_press(&"move_up")
	_simulate(1.0)
	Input.action_release(&"move_up")
	assert_false(_router.is_transitioning())
	assert_true(shown.is_empty())
	assert_eq(_player.get_cell(), Vector2i(2, 1), "le bord reste simplement bloqué")
	assert_true(_player.is_input_enabled())
	assert_signal_not_emitted(_router, "transition_started")


func test_coming_soon_without_presenter_returns_at_once() -> void:
	_start_on_c()
	_push_up_until_transition()
	await _await_idle()
	assert_eq(_player.get_cell(), Vector2i(2, 2))
	assert_true(_player.is_input_enabled())


func test_coming_soon_with_an_unknown_return_spawn_keeps_the_player_in_place() -> void:
	_start_on_c()
	_router.show_coming_soon("Route 2", &"nowhere")
	await _await_idle()
	assert_push_error("spawn de retour inconnu")
	assert_eq(_player.get_cell(), C_START)
	assert_true(_player.is_input_enabled())
	assert_false(_fade.is_opaque())


func test_setup_clears_the_coming_soon_presenter() -> void:
	_install_presenter([] as Array[String])
	_router.setup(_world, _player, _fade)
	assert_false(_router.coming_soon_presenter.is_valid())


# --- Cache borné (jalon 9 T18, jalon-09.md §2.8.6) ---------------------------------------

## Dossier des cartes de la chaîne M1 ↔ M2 ↔ M3 ↔ M4, enregistrées en vraies scènes (le cache
## ne vaut que pour les cartes chargées depuis le disque, pas pour la fabrique).
const CHAIN_DIR := "user://test_scene_router_chain/"
const CHAIN: Array[StringName] = [&"m1", &"m2", &"m3", &"m4"]
## Même chaîne, M2 intérieure (jalon 10) : dossier à part, pour ne jamais relire une scène de
## [constant CHAIN_DIR] restée dans le cache des ressources.
const DOORS_DIR := "user://test_scene_router_doors/"

var _chain_dir: String = CHAIN_DIR


## Enregistre la chaîne : chaque carte a un point « s » et un warp vers chacune de ses
## voisines (STEP_ON vers le haut, une case par voisine).
func _save_chain(interiors: Array[StringName] = []) -> void:
	DirAccess.make_dir_recursive_absolute(_chain_dir)
	for i: int in CHAIN.size():
		var map := _base_map(CHAIN[i], Vector2i(8, 6))
		map.interior = interiors.has(CHAIN[i])
		_spawn(map, &"s", Vector2i(1, 4))
		var column := 2
		for j: int in [i - 1, i + 1]:
			if j < 0 or j >= CHAIN.size():
				continue
			_warp(map, Vector2i(column, 1), Warp.Trigger.STEP_ON, Vector2i.UP, CHAIN[j], &"s")
			column += 2
		for node: Node in map.find_children("*", "", true, false):
			node.owner = map
		var packed := PackedScene.new()
		assert_eq(packed.pack(map), OK)
		assert_eq(ResourceSaver.save(packed, _chain_path(CHAIN[i])), OK)
		map.free()


func _chain_path(map_id: StringName) -> String:
	return MapCatalog.scene_path(map_id, _chain_dir)


func _chain_paths(ids: Array[StringName]) -> PackedStringArray:
	var paths := PackedStringArray()
	for id: StringName in ids:
		paths.append(_chain_path(id))
	paths.sort()
	return paths


## Attend la fin des chargements en arrière-plan du routeur (délai de garde seulement).
func _await_prefetches() -> void:
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000.0)
	for path: String in _router._prefetching.keys():
		while ResourceLoader.load_threaded_get_status(path) \
				== ResourceLoader.THREAD_LOAD_IN_PROGRESS and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame


func _use_chain(interiors: Array[StringName] = []) -> void:
	_save_chain(interiors)
	_router.map_factory = Callable()
	_router.maps_dir = _chain_dir
	_router.interior_maps = interiors
	_router.setup(_world, _player, null)


func after_all() -> void:
	for dir: String in [CHAIN_DIR, DOORS_DIR]:
		for id: StringName in CHAIN:
			DirAccess.remove_absolute(MapCatalog.scene_path(id, dir))
		DirAccess.remove_absolute(dir)


func test_cache_keeps_only_the_current_map_and_its_warp_neighbors() -> void:
	_use_chain()
	_router.start(&"m1", &"s", Vector2i.UP)
	assert_eq(_router.get_cached_paths(), _chain_paths([&"m1", &"m2"]), "M1 et sa voisine")
	_router.change_map(&"m2", &"s")
	_router.change_map(&"m3", &"s")
	assert_eq(_router.get_current_map().map_id, &"m3")
	assert_eq(_router.get_cached_paths(), _chain_paths([&"m2", &"m3", &"m4"]),
		"après M1 → M2 → M3 : M3 et ses voisines seulement")
	assert_false(ResourceLoader.has_cached(_chain_path(&"m1")),
		"la scène de M1 (et ce qu'elle retient) est rendue à la mémoire")
	assert_push_error_count(0)


func test_returning_to_a_neighbor_reads_nothing_from_disk() -> void:
	_use_chain()
	_router.start(&"m1", &"s", Vector2i.UP)
	_router.change_map(&"m2", &"s")
	_router.change_map(&"m3", &"s")
	await _await_prefetches()
	var loads: int = _router.disk_loads
	assert_true(_router._scenes.has(_chain_path(&"m2")), "M2 gardée (voisine de M3)")
	_router.change_map(&"m2", &"s")
	assert_eq(_router.get_current_map().map_id, &"m2")
	assert_eq(_router.disk_loads - loads, 1, "une seule lecture : M1 préchargée en arrière-plan")
	assert_true(_router._prefetching.has(_chain_path(&"m1")), "c'est bien M1")
	await _await_prefetches()
	_router.change_map(&"m1", &"s")
	assert_eq(_router.disk_loads - loads, 1, "M1 prise au préchargement, sans relecture")
	assert_eq(_router.get_cached_paths(), _chain_paths([&"m1", &"m2"]))


func test_trimming_never_frees_a_map_node_in_use() -> void:
	_use_chain()
	var first: GameMap = _router.start(&"m1", &"s", Vector2i.UP)
	# Une instance faite depuis la scène de M1 (comme une scène, un combat ou un menu qui
	# garderait une carte) survit à l'oubli de cette scène par le cache.
	var kept := (_router._scenes[_chain_path(&"m1")] as PackedScene).instantiate() as GameMap
	add_child_autofree(kept)
	var entered: Array[GameMap] = []
	_router.map_entered.connect(func(map: GameMap) -> void: entered.append(map))
	_router.change_map(&"m2", &"s")
	_router.change_map(&"m3", &"s")
	assert_false(_router._scenes.has(_chain_path(&"m1")), "scène de M1 oubliée")
	assert_true(is_instance_valid(kept) and kept.is_inside_tree(), "instance intacte")
	assert_eq(kept.map_id, &"m1")
	assert_eq(kept.get_warps().get_all().size(), 1, "warps et grille utilisables")
	var current: GameMap = _router.get_current_map()
	assert_true(is_instance_valid(current) and current.is_inside_tree(), "carte courante en place")
	assert_same(current, entered[entered.size() - 1], "celle annoncée par map_entered")
	assert_same(_player.get_parent(), current.get_entities(), "le joueur y est")
	await get_tree().process_frame
	assert_false(is_instance_valid(first), "l'ancienne carte part comme avant (queue_free)")


## Un préchargement fini mais devenu inutile n'est lâché que deux images plus tard :
## l'initialisation de ses textures attend encore dans la file du RenderingServer.
func test_an_unused_finished_prefetch_is_released_after_the_next_draw() -> void:
	_use_chain()
	_router.start(&"m2", &"s", Vector2i.UP)
	await _await_prefetches()
	assert_true(_router._prefetching.has(_chain_path(&"m1")), "M1 préchargée (voisine de M2)")
	_router.start(&"m4", &"s", Vector2i.UP)
	assert_eq(_router.get_cached_paths(), _chain_paths([&"m3", &"m4"]))
	assert_eq(_router._retired.size(), 1, "M1 encore retenue")
	await get_tree().process_frame
	assert_eq(_router._retired.size(), 1, "pas avant deux images")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(_router._retired.is_empty(), "puis lâchée")


# --- Intérieurs non préchargés depuis l'extérieur (jalon 10, mémoire d'Argenta) ------------

func test_an_outdoor_map_neither_prefetches_nor_keeps_its_interiors() -> void:
	_chain_dir = DOORS_DIR
	_use_chain([&"m2"])
	_router.start(&"m1", &"s", Vector2i.UP)
	assert_eq(_router.get_cached_paths(), _chain_paths([&"m1"]), "M2 intérieure : pas chargée")
	var loads: int = _router.disk_loads
	_router.change_map(&"m2", &"s")
	assert_eq(_router.get_current_map().map_id, &"m2", "l'intérieur se lit sous le rideau")
	assert_eq(_router.disk_loads - loads, 2, "M2 lue tout de suite, M3 en arrière-plan")
	assert_eq(_router.get_cached_paths(), _chain_paths([&"m1", &"m2", &"m3"]),
		"un intérieur précharge toutes ses voisines")
	await _await_prefetches()
	_router.change_map(&"m3", &"s")
	assert_eq(_router.get_cached_paths(), _chain_paths([&"m3", &"m4"]),
		"de retour dehors, l'intérieur quitte le cache")
	assert_push_error_count(0)


func test_pewter_city_keeps_only_its_route_and_an_interior_keeps_the_city() -> void:
	_router.map_factory = Callable()
	_router.setup(_world, _player, null)
	_router.start(&"pewter_city", &"from_route_2_north_c", Vector2i.UP)
	# Jalon 12 (T8) : la sortie est mène à la Route 3, voisine extérieure préchargée.
	var expected := PackedStringArray([MapCatalog.scene_path(&"pewter_city"),
		MapCatalog.scene_path(&"route_2_north"), MapCatalog.scene_path(&"route_3")])
	expected.sort()
	assert_eq(_router.get_cached_paths(), expected, "ni les sept intérieurs, ni plus")
	# Un chargement encore en cours n'est jamais interrompu : on laisse finir la route.
	await _await_prefetches()
	_router.change_map(&"pewter_center", &"entrance")
	assert_eq(_router.get_current_map().map_id, &"pewter_center")
	expected = PackedStringArray([MapCatalog.scene_path(&"pewter_center"),
		MapCatalog.scene_path(&"pewter_city")])
	expected.sort()
	assert_eq(_router.get_cached_paths(), expected, "le Centre garde Argenta")
	await _await_prefetches()
