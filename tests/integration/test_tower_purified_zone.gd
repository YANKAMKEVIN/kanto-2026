extends GutTest
## Zone purifiée du 5F de la Tour Pokémon et Exorciste calme (jalon 19, T18 ; `jalon-19.md`
## §2.8 ; dossier 22 §15.4 et §15.5) sur le vrai Boot et la vraie carte :
## - entrer par chacune des cinq entrées praticables → éclair, soin complet (PV, PP, statut),
##   §15.5.1 puis §15.5.2 mot pour mot ; se déplacer dans la zone → rien ;
## - sortir et rentrer cinq fois de suite → soin à chaque passage ;
## - aucune rencontre en 1 000 pas simulés dans la zone et sur ses abords (taux forcé à 255) ;
## - aucun Dresseur ne voit une case de la zone ni ses abords (vraie scène) ;
## - `heal_map` et `heal_spawn` inchangés : pas un point de repos, une défaite mène au Centre ;
## - l'Exorciste calme, en (12, 8), dit §15.4.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/tower_5f_zone.json"
const MAP_ID := &"pokemon_tower_5f"
const FADE := 0.05
const TIMEOUT := 12.0
const ZONE: Array[Vector2i] = [Vector2i(10, 8), Vector2i(11, 8), Vector2i(10, 9),
	Vector2i(11, 9)]
## Entrées praticables : [case de la zone, pas, case de départ] (§2.8). L'entrée (11, 8) ← vient
## de (12, 8), occupée par l'Exorciste calme : elle n'est pas praticable.
const ENTRIES: Array = [
	[Vector2i(10, 8), Vector2i.RIGHT, Vector2i(9, 8)],
	[Vector2i(10, 9), Vector2i.RIGHT, Vector2i(9, 9)],
	[Vector2i(10, 9), Vector2i.UP, Vector2i(10, 10)],
	[Vector2i(11, 9), Vector2i.LEFT, Vector2i(12, 9)],
	[Vector2i(11, 9), Vector2i.UP, Vector2i(11, 10)],
]
const HEAL_PAGE := "Une lumière douce vous enveloppe.\nCette zone est purifiée et protégée."
const DONE_PAGE := "Votre équipe est entièrement soignée."
const CALM_LINE := "Cette dalle a été bénie. Les esprits ne la franchissent pas. Reposez-vous."
const DOSSIER := "res://docs/design/dossier-22-tour-pokemon.md"
const STEPS := 1000

var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _saved_router: Array = []
var _scenes: Array[StringName] = []
var _flashes: int = 0
var _pages: Array[String] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-19T14:00:00")
	_scenes.clear()
	_pages.clear()
	_flashes = 0
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), "user://test_tower_purified_zone.json")
	_boot.start_map = MAP_ID
	_boot.start_spawn = &"arrivee_T45"
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	var data := DebugStart.new()
	assert_true(data.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(data.get_errors()))
	data.apply(GameState, _boot.get_pokemon_data())
	_boot.get_map().refresh_npcs(GameState.flags)
	_boot.get_companion_controller().refresh()
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _scenes.append(id))
	_boot.get_cutscene_director().flash_started.connect(
		func(_count: int) -> void: _flashes += 1)
	_runner.page_started.connect(func(_i: int) -> void:
		_pages.append(_runner.get_session().get_text()))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


func _put(cell: Vector2i, facing: Vector2i) -> void:
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


func _step(direction: Vector2i) -> void:
	assert_true(_player.script_step(direction), "pas %s" % direction)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


func _finish_scene() -> void:
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)  # temps réel : délai de garde
	while (director.is_running() or _runner.is_running()) \
			and Time.get_ticks_msec() < deadline:  # temps réel : délai de garde
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "scène finie")
	await wait_process_frames(5)


## Blesse toute l'équipe : 1 PV, un seul PP, empoisonnée.
func _wound_party() -> void:
	for pokemon: Pokemon in GameState.party.get_all():
		pokemon.hp = 1
		pokemon.status = StatusRules.POISON
		for slot: MoveSlot in pokemon.moves:
			slot.pp = 0


func _assert_party_healed(where: String) -> void:
	for pokemon: Pokemon in GameState.party.get_all():
		assert_eq(pokemon.hp, pokemon.max_hp(), "%s : PV pleins" % where)
		assert_eq(pokemon.status, StatusRules.NONE, "%s : statut effacé" % where)
		for slot: MoveSlot in pokemon.moves:
			assert_eq(slot.pp, slot.max_pp, "%s : PP pleins" % where)


func _assert_party_wounded(where: String) -> void:
	for pokemon: Pokemon in GameState.party.get_all():
		assert_eq(pokemon.hp, 1, "%s : toujours blessé" % where)


func _enter(entry: Array) -> void:
	_wound_party()
	_scenes.clear()
	_pages.clear()
	_flashes = 0
	await _put(entry[2], entry[1])
	await _step(entry[1])
	await wait_until(func() -> bool: return _boot.get_cutscene_director().is_running() \
		or not _scenes.is_empty(), TIMEOUT)
	await _finish_scene()


func test_the_texts_are_the_dossier_texts() -> void:
	var dossier := FileAccess.get_file_as_string(DOSSIER)
	var start := dossier.find("### 15.5 Zone purifiée")
	var section := dossier.substr(start, dossier.find("### 15.6", start) - start)
	assert_true(section.contains("« Une lumière douce vous enveloppe. Cette zone est purifiée et "
		+ "protégée. »"))
	assert_true(section.contains("« Votre équipe est entièrement soignée. »"))
	assert_true(dossier.replace("\n", " ").contains("« " + CALM_LINE + " »"))
	var library := _boot.get_dialogue_library()
	var heal := library.get_dialogue(&"tower_purified_zone_heal")
	var done := library.get_dialogue(&"tower_purified_zone_done")
	assert_eq(heal.variants[0].pages[0].text.replace("\n", " "), HEAL_PAGE.replace("\n", " "))
	assert_eq(heal.variants[0].action, &"heal", "le soin part à la fin du premier")
	assert_eq(done.variants[0].pages[0].text.replace("\n", " "), DONE_PAGE)
	assert_eq(done.variants[0].action, &"", "aucun soin sur le second")


func test_each_of_the_five_entries_flashes_then_heals_fully() -> void:
	var triggers := _boot.get_map().get_triggers()
	for entry: Array in ENTRIES:
		var trigger := triggers.get_at(entry[0])
		assert_false(trigger.is_empty(), "déclencheur en %s" % entry[0])
		await _enter(entry)
		assert_eq(_scenes, [&"tower_purified_zone"] as Array[StringName],
			"entrée %s %s : la scène" % [entry[2], entry[1]])
		assert_eq(_flashes, 1, "entrée %s : un éclair" % entry[2])
		assert_eq(_pages.size(), 2, "entrée %s : deux pages" % entry[2])
		if _pages.size() == 2:
			assert_eq(_pages[0].replace("\n", " "), HEAL_PAGE.replace("\n", " "), "§15.5.1")
			assert_eq(_pages[1].replace("\n", " "), DONE_PAGE, "§15.5.2")
		_assert_party_healed("entrée %s %s" % [entry[2], entry[1]])
		assert_eq(_player.get_cell(), entry[0], "le joueur est dans la zone")


func test_the_exorcist_blocks_the_sixth_entry() -> void:
	var calm := _boot.get_map().get_npc(&"exorciste_calme")
	assert_not_null(calm, "Exorciste calme posée")
	assert_eq(calm.get_cell(), Vector2i(12, 8))
	assert_true(_boot.get_map().get_grid().is_occupied(Vector2i(12, 8)), "case occupée")


func test_moving_inside_the_zone_does_nothing() -> void:
	await _enter(ENTRIES[0])
	_wound_party()
	_scenes.clear()
	_flashes = 0
	for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP,
			Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT]:
		await _step(direction)
		assert_true(ZONE.has(_player.get_cell()), "reste dans la zone")
	await wait_process_frames(5)
	assert_eq(_scenes, [] as Array[StringName], "aucune scène")
	assert_eq(_flashes, 0, "aucun éclair")
	_assert_party_wounded("dans la zone")


func test_leaving_and_coming_back_heals_each_time() -> void:
	var heals := 0
	for pass_index: int in 5:
		await _enter(ENTRIES[1])
		_assert_party_healed("passage %d" % (pass_index + 1))
		if _scenes.size() == 1 and _scenes[0] == &"tower_purified_zone":
			heals += 1
		await _step(Vector2i.LEFT)
		assert_eq(_player.get_cell(), Vector2i(9, 9), "sorti")
		await wait_process_frames(3)
	assert_eq(heals, 5, "cinq soins en cinq passages")


func test_no_encounter_in_a_thousand_steps_on_the_zone_and_its_surroundings() -> void:
	var map := _boot.get_map()
	var director := _boot.get_encounter_director()
	var table := _boot.get_encounter_library().get_table(MAP_ID, &"floor")
	assert_not_null(table, "le 5F a une table « floor »")
	table.rate = 255
	var rng := GameRng.new(1931)
	var control := 0
	for i: int in 20:
		if table.roll(rng, 0) != null:
			control += 1
	assert_gt(control, 0, "le taux forcé à 255 déclenche bien des rencontres ailleurs")
	assert_eq(director.terrain_at(Vector2i(6, 6)), &"floor", "témoin : sol de la Tour")
	var cells: Array[Vector2i] = []
	for zone_cell: Vector2i in ZONE:
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				var near := zone_cell + Vector2i(dx, dy)
				if map.get_grid().is_free(near) and not cells.has(near):
					cells.append(near)
	assert_gt(cells.size(), 8, "zone et abords")
	var started: Array[int] = [0]
	director.encounter_started.connect(func(_s: StringName, _l: int) -> void: started[0] += 1)
	var walk := GameRng.new(42)
	for i: int in STEPS:
		var cell := cells[walk.range_int(0, cells.size() - 1)]
		assert_eq(director.terrain_at(cell), &"", "pas %d : case %s calme" % [i, cell])
		director.call(&"_on_player_moved", cell)
	assert_eq(started[0], 0, "aucune rencontre en %d pas" % STEPS)
	assert_false(director.is_running())


func test_no_trainer_sees_the_zone_or_its_surroundings() -> void:
	var map := _boot.get_map()
	var grid := map.get_grid()
	var cells: Array[Vector2i] = []
	for zone_cell: Vector2i in ZONE:
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				var near := zone_cell + Vector2i(dx, dy)
				if not grid.is_solid(near) and not cells.has(near):
					cells.append(near)
	var seen_trainers := 0
	for npc: Npc in map.get_npcs():
		var spec := npc.get_spec()
		if spec.trainer_id.is_empty():
			continue
		seen_trainers += 1
		for cell: Vector2i in cells:
			assert_eq(TrainerRules.sight_distance(grid, npc.get_cell(), npc.get_facing(),
				spec.sight, cell), TrainerRules.NOT_SEEN,
				"%s ne voit pas %s" % [spec.id, cell])
	assert_eq(seen_trainers, 3, "les trois Exorcistes du 5F")


func test_the_zone_is_not_a_rest_point() -> void:
	var map_before := GameState.heal_map
	var spawn_before := GameState.heal_spawn
	await _enter(ENTRIES[0])
	assert_eq(GameState.heal_map, map_before, "heal_map inchangé")
	assert_eq(GameState.heal_spawn, spawn_before, "heal_spawn inchangé")
	assert_ne(GameState.heal_map, MAP_ID)
	var point := _boot.get_defeat_recovery().wakeup_point()
	assert_eq(point.map, GameState.heal_map, "défaite : le point de repos")
	assert_ne(point.map, MAP_ID, "défaite : pas la zone")
	assert_eq(point.map, &"lavender_center", "défaite : le Centre de Lavanville")


func test_the_calm_exorcist_speaks_the_dossier_line() -> void:
	await _put(Vector2i(12, 9), Vector2i.UP)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()
	assert_eq(_pages.size(), 1)
	if _pages.size() == 1:
		assert_eq(_pages[0].replace("\n", " "), CALM_LINE)
