extends GutTest
## La vie de la Forêt de Jade (jalon 9 T21, jalon-09.md §2.4, §2.7.6, §2.7.7 ; dossier 10 §7 à
## §10) avec la vraie scène Boot, la vraie carte et une sauvegarde en mémoire :
## - objets visibles O1, O2, O5 : PRENDRE → Sac + 1, journal des objets trouvés, drapeau, PNJ
##   retiré tout de suite et au rechargement, toast, aucune bulle ;
## - objets cachés O3, O4, O6 : narration (texte verrouillé) puis toast standard, une seule fois ;
## - Dresseurs : la défaite du Dresseur est mémorisée (drapeau sauvegardé) : au rechargement il ne
##   défie plus à la vue et sa réplique « après » est sa réplique permanente ; non battu (Théo),
##   il voit le joueur et lance sa scène ;
## - naturaliste et randonneuse : « première fois » puis « ensuite » (drapeaux) ;
## - Aspicot d'ambiance : se rétracte (retiré) quand le joueur arrive à une case ;
## - rais de lumière : au plus 12 grains par rai, 2 ou 3 rais en portent.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/viridian_forest.json"
const PLAN_PATH := "res://tools/plans/viridian_forest.txt"
const SAVE_PATH := "user://test_viridian_forest_life_save.json"
const MAP_ID := "viridian_forest"
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
var _scenes: Array[StringName] = []
var _saved_router: Array = []


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-08T14:03:05")
	_fs = MemoryFs.new()
	_toasts.clear()
	_events.clear()
	_pages.clear()
	_speakers.clear()
	_scenes.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot sur la forêt, le joueur posé sur [param cell] ; [param fresh] applique le départ de
## débogage (sinon : la partie en cours, relue de la sauvegarde en mémoire, comme au
## rechargement). [param flags] : drapeaux levés en plus.
func _start(cell: Vector2i, facing: Vector2i, fresh: bool,
		flags: Array[StringName] = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = StringName(MAP_ID)
	_boot.start_spawn = &"from_gate_south"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		var start := DebugStart.new()
		assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
		for flag: StringName in flags:
			GameState.flags.set_flag(flag)
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_events.append("toast")
			_toasts.append(PackedStringArray([title, detail])))
	_runner.page_started.connect(func(_index: int) -> void:
		_events.append("page")
		_pages.append(_runner.get_session().get_text())
		_speakers.append(_runner.get_session().get_speaker()))
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _scenes.append(id))
	await wait_process_frames(3)
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


## Déroule la scène ou le dialogue en cours : avance les pages jusqu'à la fin.
func _finish_scene() -> void:
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (director.is_running() or _runner.is_running()) \
			and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "scène finie")
	await wait_process_frames(5)


func _walk(direction: Vector2i, until: Vector2i) -> void:
	var action := _action(direction)
	Input.action_press(action)
	await wait_until(func() -> bool: return _player.get_cell() == until, TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


## Case praticable voisine de [param cell] (hors hautes herbes), et la direction qui mène de
## cette case à [param cell].
func _neighbour(cell: Vector2i) -> Array:
	for direction: Vector2i in DIRECTIONS:
		var from := cell + direction
		if _plan.is_walkable(from) and _plan.at(from) != "h":
			return [from, -direction]
	return []


## Toast standard : « <Objet> ×1 » / « Ajouté(e) au Sac » ([param title] = « titre|accord »).
func _expected_toast(title: String) -> Array[PackedStringArray]:
	return [PackedStringArray([title.get_slice("|", 0),
		"%s au Sac" % title.get_slice("|", 1)])] as Array[PackedStringArray]


func _bag(item: StringName) -> int:
	return GameState.bag.count_of(item)


func _found(item: String) -> int:
	var count := 0
	for entry: Dictionary in GameState.found_items:
		if entry["item"] == item and entry["map"] == MAP_ID:
			count += 1
	return count


# --- Objets visibles -----------------------------------------------------------------------

func _check_visible_item(index: int, item: StringName, title: String) -> void:
	var id := StringName("viridian_forest_item_%d" % index)
	var cell := _plan.cell_of(String(id))
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
	var before := _bag(item)
	await _press_interact()
	await wait_until(func() -> bool: return map.get_npc(id) == null, TIMEOUT)
	assert_null(map.get_npc(id), "objet retiré tout de suite")
	assert_false(map.get_grid().is_occupied(cell), "case libérée")
	await _finish_scene()
	assert_eq(_bag(item), before + 1, "Sac + 1")
	assert_eq(_found(String(item)), 1, "journal des objets trouvés")
	assert_true(GameState.flags.has_flag(StringName("got_viridian_forest_item_%d" % index)))
	assert_eq(_toasts, _expected_toast(title))
	assert_eq(_events.count("page"), 0, "aucune bulle avant le toast")
	# Rechargement : l'objet ne revient pas, le Sac ne bouge pas.
	_boot.request_autosave("test")
	await wait_process_frames(5)
	var bag_after := _bag(item)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(near[0], near[1], false)
	assert_null(_boot.get_map().get_npc(id), "absent au rechargement")
	assert_false(_boot.get_map().get_grid().is_occupied(cell))
	assert_eq(_bag(item), bag_after, "Sac inchangé")
	assert_eq(_found(String(item)), 1)
	assert_push_error_count(0)


func test_o1_antidote_on_the_ground() -> void:
	await _check_visible_item(1, &"antidote", "Antidote ×1|Ajouté")


func test_o2_poke_ball_in_the_dead_end() -> void:
	await _check_visible_item(2, &"poke_ball", "Poké Ball ×1|Ajoutée")


func test_o5_poke_ball_on_the_climb() -> void:
	await _check_visible_item(5, &"poke_ball", "Poké Ball ×1|Ajoutée")


# --- Objets cachés -------------------------------------------------------------------------

func _check_hidden_item(index: int, item: StringName, title: String, text: String) -> void:
	var cell := _plan.cell_of("viridian_forest_item_%d" % index)
	var near := _neighbour(cell)
	assert_false(near.is_empty(), "O%d a une case d'accès" % index)
	if near.is_empty():
		return
	await _start(near[0], near[1], true)
	var before := _bag(item)
	await _walk(near[1], cell)
	await _finish_scene()
	assert_eq(_events, ["page", "toast"] as Array[String], "narration puis toast")
	assert_eq(_pages, [text] as Array[String], "texte verrouillé")
	assert_eq(_bag(item), before + 1)
	assert_eq(_found(String(item)), 1)
	assert_true(GameState.flags.has_flag(StringName("got_viridian_forest_item_%d" % index)))
	assert_eq(_toasts, _expected_toast(title))
	# On repasse sur la case : rien.
	await _walk(-near[1], near[0])
	await _walk(near[1], cell)
	await wait_process_frames(20)
	assert_false(_boot.get_cutscene_director().is_running(), "aucune scène la seconde fois")
	assert_eq(_events, ["page", "toast"] as Array[String], "rien de nouveau")
	assert_eq(_bag(item), before + 1)
	assert_eq(_found(String(item)), 1)
	assert_push_error_count(0)


func test_o3_potion_under_the_leaves() -> void:
	await _check_hidden_item(3, &"potion", "Potion ×1|Ajoutée",
		"Quelque chose est caché sous les feuilles.")


func test_o4_antidote_between_the_roots() -> void:
	await _check_hidden_item(4, &"antidote", "Antidote ×1|Ajouté",
		"Quelque chose est coincé entre les racines.")


func test_o6_potion_behind_the_stump() -> void:
	await _check_hidden_item(6, &"potion", "Potion ×1|Ajoutée",
		"Quelque chose dépasse derrière cette souche.")


# --- Dresseurs -----------------------------------------------------------------------------

func test_unbeaten_theo_sees_the_player_and_starts_his_scene() -> void:
	var theo := _plan.cell_of("scout_theo")
	await _start(theo + Vector2i(0, 5), Vector2i.UP, true)
	await _walk(Vector2i.UP, theo + Vector2i(0, 4))
	await wait_until(func() -> bool: return not _scenes.is_empty(), TIMEOUT)
	assert_eq(_scenes, [&"trainer_forest_scout_theo"] as Array[StringName], "il a vu le joueur")
	assert_false(GameState.flags.has_flag(&"beaten_forest_scout_theo"), "pas battu")


func test_a_beaten_trainer_is_remembered_after_a_reload() -> void:
	var theo := _plan.cell_of("scout_theo")
	var flag: StringName = &"beaten_forest_scout_theo"
	await _start(theo + Vector2i(0, 5), Vector2i.UP, true, [flag])
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(theo + Vector2i(0, 5), Vector2i.UP, false)
	assert_true(GameState.flags.has_flag(flag), "drapeau relu de la sauvegarde")
	# Il est dans sa vue (4 cases) : plus de défi.
	await _walk(Vector2i.UP, theo + Vector2i(0, 4))
	await wait_process_frames(30)
	assert_eq(_scenes, [] as Array[StringName], "un Dresseur battu ne défie plus")
	# Sa réplique « après » est sa réplique permanente.
	await _walk(Vector2i.UP, theo + Vector2i(0, 2))
	await _press_interact()
	await wait_until(func() -> bool: return not _pages.is_empty(), TIMEOUT)
	await _finish_scene()
	assert_eq(_pages, ["Ton Pokémon est bien entraîné.\nJe dois encore progresser."] as Array[String])
	assert_eq(_speakers, ["Scout Théo"] as Array[String])
	assert_eq(_scenes, [] as Array[StringName], "pas de combat à la parole")


# --- PNJ ---------------------------------------------------------------------------------------

func _talk_to(npc_id: StringName) -> void:
	var npc := _boot.get_map().get_npc(npc_id)
	assert_not_null(npc, "%s posé" % npc_id)
	for npc_any: Npc in _boot.get_map().get_npcs():
		npc_any.set_routine_held(true)
	var cell := npc.get_cell()
	var near := _neighbour(cell)
	_boot.get_map().spawn_player_at(_player, near[0], near[1])
	await wait_process_frames(3)
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()


func _check_two_replies(npc_id: StringName, flag: StringName, first: String,
		later: String) -> void:
	var cell := _plan.cell_of(String(npc_id))
	await _start(_neighbour(cell)[0], _neighbour(cell)[1], true)
	assert_false(GameState.flags.has_flag(flag))
	await _talk_to(npc_id)
	assert_eq(_pages, [first] as Array[String], "première fois")
	assert_true(GameState.flags.has_flag(flag), "drapeau posé")
	await _talk_to(npc_id)
	assert_eq(_pages, [first, later] as Array[String], "ensuite")
	await _talk_to(npc_id)
	assert_eq(_pages, [first, later, later] as Array[String], "puis toujours la même")


func test_naturalist_first_time_then_afterwards() -> void:
	await _check_two_replies(&"naturalist", &"forest_naturalist_talked",
		"Certains Pokémon changent très vite\nquand ils grandissent.",
		"J'aimerais les observer évoluer ici.")


func test_hiker_first_time_then_afterwards() -> void:
	await _check_two_replies(&"hiker", &"forest_hiker_talked",
		"Plus on avance, plus Jadielle\nparaît loin, pas vrai ?",
		"Je garde toujours de quoi soigner\nmon équipe avant de repartir.")


# --- Pokémon d'ambiance --------------------------------------------------------------------

func test_a_weedle_retreats_when_the_player_arrives_one_cell_away() -> void:
	var cell := _plan.cell_of("weedle_1")
	# Une case à deux pas en ligne droite, puis un pas : le joueur arrive à une case.
	var from := Vector2i.ZERO
	var step := Vector2i.ZERO
	for direction: Vector2i in DIRECTIONS:
		if _plan.is_walkable(cell + direction) and _plan.is_walkable(cell + direction * 2):
			from = cell + direction * 2
			step = -direction
	assert_ne(step, Vector2i.ZERO, "un approche en ligne droite existe")
	await _start(from, step, true)
	var map := _boot.get_map()
	assert_not_null(map.get_npc(&"weedle_1"), "l'Aspicot est sur son tronc")
	await wait_process_frames(10)
	assert_not_null(map.get_npc(&"weedle_1"), "il reste tant que le joueur est à 2 cases")
	await _walk(step, from + step)
	await wait_until(func() -> bool: return map.get_npc(&"weedle_1") == null, TIMEOUT)
	assert_null(map.get_npc(&"weedle_1"), "il se rétracte (retiré)")


# --- Rais de lumière ---------------------------------------------------------------------

func test_light_rays_carry_a_few_motes_only() -> void:
	var map := (load("res://game/world/maps/viridian_forest.tscn") as PackedScene).instantiate()
	add_child_autofree(map)
	var rays := map.get_node(^"LightRays")
	var carriers := 0
	for child: Node in rays.get_children():
		if child is CPUParticles2D:
			carriers += 1
			var motes := child as CPUParticles2D
			assert_lte(motes.amount, 12, "%s : au plus 12 grains" % motes.name)
			assert_true(motes.material is CanvasItemMaterial, "additif")
			assert_eq((motes.material as CanvasItemMaterial).blend_mode,
				CanvasItemMaterial.BLEND_MODE_ADD)
			assert_eq(motes.z_index, 5, "au-dessus des cimes, comme le rai")
	assert_between(carriers, 2, 3, "2 ou 3 rais portent des particules")
	var drawn := 0
	for child: Node in rays.get_children():
		if child is Polygon2D:
			drawn += 1
	assert_gte(drawn, carriers, "chaque rai à particules existe")
