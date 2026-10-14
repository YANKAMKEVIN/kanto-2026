extends GutTest
## La vie de la Route 3 et du Centre du Mont Sélénite (jalon 12 T18, jalon-12.md §1.3, §2.7,
## §2.14, §2.16 ; dossier 15 §3.4, §4, §15, §20) avec la vraie scène Boot, la vraie carte et une
## sauvegarde en mémoire :
## - objets visibles O1–O3 (modèle J8) : PRENDRE → Sac + 1, journal, drapeau, retiré tout de
##   suite et au rechargement, toast seul ;
## - panneaux (§20 n° 3, 4) lus de face ; voyageur et randonneuse (§20 n° 1, 2) ;
## - premier pas sur la Route 3 → `route_3_entered` (silencieux) → objectif « traverser le Mont
##   Sélénite. » ;
## - Piafabec d'ambiance (Rondoudou : pas de planche peinte, non posé) ;
## - Centre : infirmière, terminal de Stockage, soin → toast « Point de repos enregistré — Mont
##   Sélénite », point de repos enregistré.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/route_3.json"
const CENTER_START := "res://tools/debug_start/mt_moon_center.json"
const PLAN_PATH := "res://tools/plans/route_3.txt"
const SAVE_PATH := "user://test_route_3_life_save.json"
const MAP_ID := "route_3"
const FADE := 0.05
const TIMEOUT := 12.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _plan: PlanGrid
var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _toasts: Array[PackedStringArray] = []
var _events: Array[String] = []
var _pages: Array[String] = []
var _speakers: Array[String] = []
var _saved_router: Array = []


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-13T15:00:00")
	_fs = MemoryFs.new()
	_toasts.clear()
	_events.clear()
	_pages.clear()
	_speakers.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot sur [param map] / [param spawn] ; [param fresh] applique [param start] (sinon : la partie
## relue de la sauvegarde) ; le joueur est ensuite posé sur [param cell] s'il est donné.
func _start(cell: Variant, facing: Vector2i, fresh: bool, map: StringName = &"route_3",
		spawn: StringName = &"from_pewter_c", start_path: String = START) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		var start := DebugStart.new()
		assert_true(start.load_file(start_path, _boot.get_pokemon_data(),
			_boot.get_item_library()), "\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_events.append("toast")
			_toasts.append(PackedStringArray([title, detail])))
	_runner.page_started.connect(func(_index: int) -> void:
		_events.append("page")
		_pages.append(_runner.get_session().get_text())
		_speakers.append(_runner.get_session().get_speaker()))
	_runner.choice_requested.connect(_on_choice_requested)
	await wait_process_frames(3)
	if cell is Vector2i:
		_boot.get_map().spawn_player_at(_player, cell, facing)
		await wait_process_frames(3)


## Le soin du Centre : SOIGNER.
func _on_choice_requested(_view: ChoiceView) -> void:
	await wait_process_frames(3)
	_boot.get_dialogue_box().get_choice_cards().get_confirm_button().pressed.emit()


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


func _finish_scene() -> void:
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (director.is_running() or _runner.is_running()) \
			and Time.get_ticks_msec() < deadline:
		if box.is_open() and not _runner.is_awaiting_choice():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "scène finie")
	assert_false(_runner.is_running(), "dialogue fini")
	await wait_process_frames(5)


func _walk(direction: Vector2i, until: Vector2i) -> void:
	var action: StringName = &"move_right"
	match direction:
		Vector2i.UP:
			action = &"move_up"
		Vector2i.DOWN:
			action = &"move_down"
		Vector2i.LEFT:
			action = &"move_left"
	Input.action_press(action)
	await wait_until(func() -> bool: return _player.get_cell() == until, TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


## Case praticable voisine de [param cell] (hors hautes herbes) et direction vers [param cell].
func _neighbour(cell: Vector2i) -> Array:
	for direction: Vector2i in DIRECTIONS:
		var from := cell + direction
		if _plan.is_walkable(from) and _plan.at(from) != "h":
			return [from, -direction]
	return []


func _found(item: String) -> int:
	var count := 0
	for entry: Dictionary in GameState.found_items:
		if entry["item"] == item and entry["map"] == MAP_ID:
			count += 1
	return count


# --- Objets visibles -----------------------------------------------------------------------

func _check_visible_item(index: int, item: StringName, toast: Array) -> void:
	var id := StringName("route_3_item_%d" % index)
	var cell := _plan.cell_of(String(id))
	assert_eq(StringName(_plan.attr(String(id), "item")), item, "objet de la grille")
	var near := _neighbour(cell)
	assert_false(near.is_empty(), "%s a une case d'accès" % id)
	if near.is_empty():
		return
	await _start(near[0], near[1], true)
	var map := _boot.get_map()
	assert_not_null(map.get_npc(id), "l'objet est au sol")
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target, "cible d'interaction")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.TAKE, "verbe PRENDRE")
	var before := GameState.bag.count_of(item)
	await _press_interact()
	await wait_until(func() -> bool: return map.get_npc(id) == null, TIMEOUT)
	assert_null(map.get_npc(id), "objet retiré tout de suite")
	await _finish_scene()
	assert_eq(GameState.bag.count_of(item), before + 1, "Sac + 1")
	assert_eq(_found(String(item)), 1, "journal des objets trouvés")
	assert_true(GameState.flags.has_flag(StringName("got_" + id)))
	assert_eq(_toasts, [PackedStringArray(toast)] as Array[PackedStringArray])
	assert_eq(_events.count("page"), 0, "aucune bulle")
	_boot.request_autosave("test")
	await wait_process_frames(5)
	var bag_after := GameState.bag.count_of(item)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(near[0], near[1], false)
	assert_null(_boot.get_map().get_npc(id), "absent au rechargement")
	assert_false(_boot.get_map().get_grid().is_occupied(cell))
	assert_eq(GameState.bag.count_of(item), bag_after, "Sac inchangé")
	assert_push_error_count(0)


func test_o1_poke_ball_behind_ines() -> void:
	await _check_visible_item(1, &"poke_ball", ["Poké Ball ×1", "Ajoutée au Sac"])


func test_o2_potion_on_the_center_plateau() -> void:
	await _check_visible_item(2, &"potion", ["Potion ×1", "Ajoutée au Sac"])


func test_o3_paralyze_heal_behind_nolan() -> void:
	await _check_visible_item(3, &"paralyze_heal", ["Anti-Para ×1", "Ajouté au Sac"])


# --- Panneaux et PNJ -------------------------------------------------------------------------

func _read(cell: Vector2i, facing: Vector2i) -> void:
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()


func test_signs_are_read_from_the_front() -> void:
	var west := _plan.cell_of("panneau_ouest")
	var center := _plan.cell_of("panneau_centre")
	await _start(west + Vector2i.DOWN, Vector2i.UP, true)
	await _read(west + Vector2i.DOWN, Vector2i.UP)
	await _read(center + Vector2i.DOWN, Vector2i.UP)
	assert_eq(_pages, ["ROUTE 3\nArgenta ← → Mont Sélénite", "CENTRE POKÉMON\nMont Sélénite"]
		as Array[String], "§20 n° 3 et 4")
	# De côté : rien.
	_boot.get_map().spawn_player_at(_player, west + Vector2i.RIGHT, Vector2i.UP)
	await wait_process_frames(3)
	assert_null(_boot.get_interaction_controller().get_target(), "de côté : rien")


func test_traveler_and_hiker_lines() -> void:
	var traveler := _plan.cell_of("voyageur")
	var hiker := _plan.cell_of("randonneuse")
	await _start(traveler + Vector2i.RIGHT, Vector2i.LEFT, true)
	var map := _boot.get_map()
	assert_eq(map.get_npc(&"traveler").get_cell(), traveler)
	assert_eq(map.get_npc(&"traveler").get_spec().facing, Vector2i.RIGHT, "face à la montagne")
	assert_eq(map.get_npc(&"hiker").get_cell(), hiker)
	await _read(traveler + Vector2i.RIGHT, Vector2i.LEFT)
	await _read(hiker + Vector2i.LEFT, Vector2i.RIGHT)
	assert_eq(_pages, ["Le Mont Sélénite, là-bas.",
		"On dit que des pierres sont tombées\ndu ciel, autrefois.",
		"Je reviens de la grotte.", "Il fait noir, là-dedans.\nGarde tes Potions."]
		as Array[String], "§20 n° 1 et 2")
	assert_eq(_speakers, ["Voyageur", "Voyageur", "Randonneuse", "Randonneuse"]
		as Array[String])


# --- Déclencheur et objectif ----------------------------------------------------------------

func test_first_step_on_route_3_sets_the_objective_silently() -> void:
	await _start(null, Vector2i.RIGHT, true)
	assert_eq(_player.get_cell(), Vector2i(0, 26), "arrivée d'Argenta")
	var objectives := ObjectiveLibrary.new()
	assert_true(objectives.load_file())
	assert_eq(objectives.current(GameState.flags), "continuer vers la Route 3.")
	await _walk(Vector2i.RIGHT, Vector2i(1, 26))
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"route_3_entered"),
		TIMEOUT)
	assert_true(GameState.flags.has_flag(&"route_3_entered"))
	assert_eq(objectives.current(GameState.flags), "traverser le Mont Sélénite.", "§20 n° 38")
	await wait_process_frames(5)
	assert_eq(_events, [] as Array[String], "en silence")
	assert_true(_player.is_input_enabled(), "le joueur garde la main")
	assert_push_error_count(0)


func test_entered_trigger_covers_the_three_west_rows() -> void:
	var map := (load("res://game/world/maps/route_3.tscn") as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(map)
	var points := map.get_node(^"Triggers").get_children()
	assert_eq(points.size(), 1)
	var trigger := points[0] as EventTriggerPoint
	assert_eq(trigger.cutscene_id, &"route_3_entered")
	assert_eq(trigger.get_cells(), [Vector2i(1, 27), Vector2i(1, 26), Vector2i(1, 25)]
		as Array[Vector2i])
	assert_eq(trigger.direction, Vector2i.ZERO, "toute direction")


# --- Pokémon d'ambiance -------------------------------------------------------------------

func test_ambient_spearows_on_their_rocks() -> void:
	await _start(null, Vector2i.RIGHT, true)
	var map := _boot.get_map()
	for id: String in ["piafabec_1", "piafabec_2"]:
		var npc := map.get_npc(StringName("spearow_" + id.get_slice("_", 1)))
		assert_not_null(npc, "%s posé" % id)
		if npc != null:
			assert_eq(npc.get_cell(), _plan.cell_of(id))
			assert_eq(npc.get_spec().sprite, &"pokemon/spearow")
			assert_eq(npc.get_spec().shy_action, &"fly", "s'envole")
	for npc: Npc in map.get_npcs():
		assert_ne(npc.get_spec().sprite, &"pokemon/jigglypuff",
			"Rondoudou : pas de planche peinte au T18")


# --- Centre du Mont Sélénite ------------------------------------------------------------------

func test_center_nurse_heals_and_registers_mont_selenite() -> void:
	await _start(null, Vector2i.UP, true, &"mt_moon_center", &"heal", CENTER_START)
	var map := _boot.get_map()
	assert_eq(map.map_id, &"mt_moon_center")
	var nurse := map.get_npc(&"nurse")
	assert_not_null(nurse, "infirmière")
	if nurse != null:
		assert_eq(nurse.get_cell(), Vector2i(7, 3))
	var terminal := map.get_node_or_null(^"Interactables/StorageTerminalScreen") as InteractPoint
	assert_not_null(terminal, "terminal de Stockage")
	if terminal != null:
		assert_eq(terminal.dialogue_id, &"storage_terminal")
	assert_eq(GameState.party.get_at(1).hp, 0, "un K.O. avant le soin")
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()
	for pokemon: Pokemon in GameState.party.get_all():
		assert_eq(pokemon.hp, pokemon.max_hp(), "%s soigné" % pokemon.species_id)
	assert_eq(GameState.heal_map, &"mt_moon_center", "point de repos")
	assert_eq(_toasts, [PackedStringArray(["Point de repos enregistré", "Mont Sélénite"])]
		as Array[PackedStringArray], "§20 n° 11")
	assert_push_error_count(0)
