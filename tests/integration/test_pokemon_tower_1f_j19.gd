extends GutTest
## Rez-de-chaussée de la Tour Pokémon, côté jalon 19 (T16 ; `jalon-19.md` §2.1, §2.7 ; dossier 22
## §15.1) sur la vraie scène Boot : premier pas depuis l'entrée → scène de la gardienne (§15.1.1
## à 4) → elle se range en (18, 3), `tower_stairs_open` ; escalier 1F ↔ 2F ; après rechargement
## elle dit §15.1.5 ; Corde Sortie des étages (devant la porte, tourné vers le bas ; refusée au
## rez-de-chaussée ; le rival non battu attend) ; compagnon (bâtiment au 1F, grotte ailleurs).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START_1F := "res://tools/debug_start/pokemon_tower_1f.json"
const START_6F := "res://tools/debug_start/tower_6f_block.json"
const ACCESS := Vector2i(17, 3)
const STAIRS := Vector2i(17, 2)
const ROPE := &"escape_rope"
const FADE := 0.05
const TIMEOUT := 12.0
## Dossier 22 §15.1 (retours à la ligne des pages du jeu).
const WORRIED: Array[String] = [
	"Ah… C'est vous.\nPardonnez-moi, je priais.",
	"Les esprits sont agités, ces derniers\njours. Même ici, on ne trouve plus le calme.",
	"M. Fuji est monté il y a plusieurs\njours. Il n'est jamais redescendu.",
	"Si vous montez…\nrestez près de vos Pokémon.",
]
const AFTER := "Je prie pour ceux qui reposent ici…\net pour ceux qui sont montés."
const DOSSIER := "res://docs/design/dossier-22-tour-pokemon.md"
const FLOORS: Array[StringName] = [&"pokemon_tower_2f", &"pokemon_tower_3f", &"pokemon_tower_4f",
	&"pokemon_tower_5f", &"pokemon_tower_6f"]

var _boot: Boot
var _fades: Array[float] = []
var _pages: Array[String] = []
var _scenes: Array[StringName] = []
var _titles: Array[String] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-19T14:03:05")
	_pages.clear()
	_scenes.clear()
	_titles.clear()


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


## Boot sur la carte du départ de débogage [param start_path] (ses drapeaux et son Sac), puis
## [param flags] de plus levés avant le chargement de la carte.
func _start(start_path: String, flags: Array[StringName] = []) -> void:
	var start: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(start_path))
	for flag: StringName in flags:
		if not (start["flags"] as Array).has(String(flag)):
			(start["flags"] as Array).append(String(flag))
	var path := "user://test_pokemon_tower_1f_j19_start.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(start))
	file.close()
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), "user://test_pokemon_tower_1f_j19.json")
	_boot.force_debug_start = true
	_boot.debug_start_path = path
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_dialogue_runner().page_started.connect(_on_page_started)
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _scenes.append(id))
	_boot.zone_announced.connect(func(zone: String, region: String) -> void:
		_titles.append("%s / %s" % [zone, region]))
	await wait_process_frames(3)
	await _settle()
	DirAccess.remove_absolute(path)


func _on_page_started(_index: int) -> void:
	_pages.append(_boot.get_dialogue_runner().get_session().get_text())


func _settle() -> void:
	await wait_until(func() -> bool:
		return _boot.is_stable() or _boot.get_dialogue_runner().is_running(), TIMEOUT)
	await wait_process_frames(2)


func _finish_scene() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)  # temps réel : délai de garde
	while (director.is_running() or runner.is_running()) \
			and Time.get_ticks_msec() < deadline:  # temps réel : délai de garde
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "scène finie")
	await wait_process_frames(5)


## Un pas de [param direction] ; attend la fin du mouvement.
func _step(direction: Vector2i) -> void:
	var player := _boot.get_player()
	assert_true(player.script_step(direction), "pas %s" % direction)
	await wait_until(func() -> bool: return not player.is_moving(), TIMEOUT)


func _go_to_map(map_id: StringName) -> void:
	await wait_until(func() -> bool: return _boot.get_map().map_id == map_id \
		and not SceneRouter.is_transitioning() and _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


func _guardian() -> Npc:
	return _boot.get_map().get_npc(&"exorciste_gardienne")


# --- Gardienne ---------------------------------------------------------------------------------

func test_the_texts_are_the_dossier_texts() -> void:
	var dossier := FileAccess.get_file_as_string(DOSSIER)
	var start := dossier.find("### 15.1 Rez-de-chaussée")
	var section := dossier.substr(start, dossier.find("### 15.2", start) - start)
	var quotes: Array[String] = []
	for line: String in section.split("\n"):
		var open := line.find("« ")
		var close := line.rfind(" »")
		if open >= 0 and close > open:
			quotes.append(line.substr(open + 2, close - open - 2))
	assert_eq(quotes.size(), 5)
	var spoken: Array[String] = WORRIED.duplicate()
	spoken.append(AFTER)
	for i: int in quotes.size():
		assert_eq(spoken[i].replace("\n", " "), quotes[i], "§15.1.%d" % (i + 1))
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	var worried := dialogues.get_dialogue(&"tower_guardian_worried")
	var said: Array[String] = []
	for page: DialoguePage in worried.variants[0].pages:
		said.append(page.text)
	assert_eq(said.size(), 4)
	assert_eq(said[0], WORRIED[0])
	assert_eq(" ".join(said).replace("\n", " "), " ".join(quotes.slice(0, 4)),
		"§15.1.1 à 4, mot pour mot")
	var after := dialogues.get_dialogue(&"pokemon_tower_exorcist").variants[0]
	assert_eq(after.pages[0].text.replace("\n", " "), quotes[4], "§15.1.5")


func test_first_step_plays_the_scene_then_the_guardian_steps_aside() -> void:
	await _start(START_1F)
	assert_eq(_boot.get_map().map_id, &"pokemon_tower_1f")
	assert_eq(_boot.get_player().get_cell(), Vector2i(9, 16))
	assert_eq(_guardian().get_cell(), ACCESS)
	assert_false(GameState.flags.has_flag(&"tower_stairs_open"))
	assert_eq(_scenes.size(), 0, "rien avant le premier pas")
	await _step(Vector2i.UP)
	assert_eq(_boot.get_player().get_cell(), Vector2i(9, 15))
	await wait_until(func() -> bool: return not _scenes.is_empty(), TIMEOUT)
	await _finish_scene()
	assert_eq(_scenes, [&"tower_guardian"] as Array[StringName])
	assert_eq(_pages, WORRIED, "§15.1.1 à 4")
	assert_eq(_guardian().get_cell(), Vector2i(18, 3))
	assert_eq(_guardian().get_facing(), Vector2i.LEFT)
	assert_true(GameState.flags.has_flag(&"tower_stairs_open"))
	assert_false(_boot.get_map().get_grid().is_occupied(ACCESS))
	# Un second passage ne rejoue rien.
	_scenes.clear()
	await _step(Vector2i.DOWN)
	await _step(Vector2i.UP)
	await wait_process_frames(10)
	assert_eq(_scenes.size(), 0, "une seule fois")


func test_the_stairs_are_walkable_to_the_2f_and_back_to_17_3() -> void:
	await _start(START_1F, [&"tower_stairs_open"])
	var map := _boot.get_map()
	var titles := _titles.size()
	map.refresh_npcs(GameState.flags)
	await wait_process_frames(3)
	assert_eq(_guardian().get_cell(), Vector2i(18, 3))
	assert_true(map.get_grid().find_reachable(_boot.get_player().get_cell(),
		_boot.get_player()).has(STAIRS), "l'escalier est praticable")
	map.spawn_player_at(_boot.get_player(), ACCESS, Vector2i.UP)
	await wait_process_frames(3)
	await _step(Vector2i.UP)
	await _go_to_map(&"pokemon_tower_2f")
	var two := _boot.get_map()
	assert_eq(_boot.get_player().get_cell(), two.get_spawn_cell(&"arrivee_T12"))
	assert_eq(_boot.get_player().get_cell(), Vector2i(17, 9))
	assert_eq(_boot.get_player().get_facing(), Vector2i.LEFT)
	# Le titre « Tour Pokémon » s'annonce une fois à la première montée (le 1F, bâtiment, est
	# silencieux, comme la Grotte Sombre depuis la Route 10), jamais en changeant d'étage.
	assert_eq(_titles.size(), titles + 1, "une seule légende, à la montée")
	assert_eq(_titles[-1].split(" / ")[0], "Tour Pokémon")
	titles = _titles.size()
	await _step(Vector2i.RIGHT)
	await _go_to_map(&"pokemon_tower_1f")
	assert_eq(_boot.get_player().get_cell(), ACCESS, "retour en (17, 3)")
	assert_eq(_boot.get_player().get_facing(), Vector2i.DOWN)
	assert_eq(_titles.size(), titles, "ni au retour")


func test_after_a_reload_she_is_in_18_3_and_says_the_after_text() -> void:
	await _start(START_1F)
	GameState.flags.set_flag(&"tower_stairs_open")
	SceneRouter.change_map(&"pokemon_tower_1f", &"entrance", Vector2i.UP)
	await wait_process_frames(10)
	await _go_to_map(&"pokemon_tower_1f")
	var guardian := _guardian()
	assert_eq(guardian.get_cell(), Vector2i(18, 3), "rechargement : (18, 3)")
	assert_eq(guardian.get_facing(), Vector2i.LEFT)
	_boot.get_map().spawn_player_at(_boot.get_player(), ACCESS, Vector2i.RIGHT)
	await wait_process_frames(3)
	_pages.clear()
	_scenes.clear()
	await _press_interact()
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	await _finish_scene()
	assert_eq(_pages, [AFTER] as Array[String], "§15.1.5")
	assert_eq(_scenes.size(), 0, "aucune scène")


func test_talking_to_her_before_the_flag_plays_the_scene() -> void:
	await _start(START_1F)
	_boot.get_map().spawn_player_at(_boot.get_player(), Vector2i(17, 4), Vector2i.UP)
	await wait_process_frames(3)
	await _press_interact()
	await wait_until(func() -> bool: return not _scenes.is_empty(), TIMEOUT)
	await _finish_scene()
	assert_eq(_scenes, [&"tower_guardian"] as Array[StringName])
	assert_eq(_pages, WORRIED)
	assert_eq(_guardian().get_cell(), Vector2i(18, 3))
	assert_true(GameState.flags.has_flag(&"tower_stairs_open"))


func test_without_the_flag_the_stairs_stay_out_of_reach() -> void:
	await _start(START_1F)
	var map := _boot.get_map()
	var reached := map.get_grid().find_reachable(Vector2i(9, 16), _boot.get_player())
	assert_false(reached.has(STAIRS), "escalier inatteignable sans le drapeau")
	assert_false(reached.has(ACCESS))


# --- Données et cartes -------------------------------------------------------------------------

func test_data_floors_are_chained_and_in_the_lavender_zone() -> void:
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir(), "\n".join(cutscenes.get_errors()))
	assert_not_null(cutscenes.get_cutscene(&"tower_guardian"))
	var zones := ZoneLibrary.new()
	zones.load_file()
	var one := (load("res://game/world/maps/pokemon_tower_1f.tscn") as PackedScene).instantiate()
	var triggers := one.get_node(^"Triggers").get_children()
	assert_eq(triggers.size(), 2)
	for trigger: Node in triggers:
		assert_eq(trigger.get(&"cutscene_id"), &"tower_guardian")
		assert_eq(trigger.get(&"direction"), Vector2i.UP)
		# Position = pied de la case : (case + 1) × 96 en y.
		assert_eq(int((trigger as Node2D).position.y / 96.0) - 1, 15, "rangée 15")
	var cells: Array[int] = []
	for trigger: Node in triggers:
		cells.append(int((trigger as Node2D).position.x / 96.0))
	cells.sort()
	assert_eq(cells, [9, 10] as Array[int])
	one.free()
	for map_id: StringName in [&"pokemon_tower_1f"] + FLOORS:
		assert_eq(zones.zone_of(map_id), &"lavender_town", String(map_id))
	assert_eq(zones.zone_of(&"pokemon_tower_6f"), zones.zone_of(&"lavender_town"))


func test_escape_rope_rules_cover_floors_2f_to_6f_only() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	var items := ItemLibrary.new()
	items.load_dir()
	var rope := items.get_item(ROPE)
	for map_id: StringName in FLOORS:
		assert_eq(FieldItemRules.check(rope, map_id, caves), FieldItemRules.Check.OK,
			String(map_id))
		var exit := FieldItemRules.escape_target(map_id, caves)
		assert_not_null(exit, String(map_id))
		if exit != null:
			assert_eq([exit.map, exit.spawn, exit.facing],
				[&"lavender_town", &"retour_tour", Vector2i.DOWN], String(map_id))
	assert_eq(FieldItemRules.check(rope, &"pokemon_tower_1f", caves),
		FieldItemRules.Check.NOT_HERE, "refusée au rez-de-chaussée")
	assert_null(FieldItemRules.escape_target(&"pokemon_tower_1f", caves))
	# Le spawn d'arrivée existe devant la porte de la Tour (Lavanville).
	var town := (load("res://game/world/maps/lavender_town.tscn") as PackedScene).instantiate()
	assert_true((town as GameMap).has_spawn(&"retour_tour"))
	town.free()


func test_companion_hidden_in_the_building_and_visible_on_the_floors() -> void:
	var one := (load("res://game/world/maps/pokemon_tower_1f.tscn") as PackedScene).instantiate()
	assert_true((one as GameMap).interior, "1F : bâtiment, compagnon caché")
	one.free()
	for map_id: StringName in FLOORS:
		var map := (load("res://game/world/maps/%s.tscn" % map_id) as PackedScene).instantiate()
		assert_false((map as GameMap).interior, "%s : grotte, compagnon visible" % map_id)
		map.free()


# --- Corde Sortie ------------------------------------------------------------------------------

func _use_rope() -> void:
	var menu := _boot.get_menu_director()
	assert_true(menu.open(), "le menu s'ouvre")
	menu.request_item_use(ROPE)
	await wait_process_frames(2)
	await _finish_scene()


func _rope_from(map_id: StringName, spawn: StringName) -> void:
	await _start(START_6F)
	SceneRouter.change_map(map_id, spawn, Vector2i.DOWN)
	await _go_to_map(map_id)
	var ropes := GameState.bag.count_of(ROPE)
	assert_gt(ropes, 0)
	await _use_rope()
	await _go_to_map(&"lavender_town")
	assert_eq(_boot.get_player().get_cell(),
		_boot.get_map().get_spawn_cell(&"retour_tour"), "devant la porte")
	assert_eq(_boot.get_player().get_facing(), Vector2i.DOWN)
	assert_eq(GameState.bag.count_of(ROPE), ropes - 1, "une Corde de moins")


func test_escape_rope_from_the_2f_leads_to_the_door_and_the_rival_waits() -> void:
	await _rope_from(&"pokemon_tower_2f", &"devant_rival")
	assert_false(GameState.flags.has_flag(&"rival_tower_won"), "le rival non battu attend")
	# Retour dans la Tour : le déclencheur du rival est toujours là.
	SceneRouter.change_map(&"pokemon_tower_2f", &"arrivee_T12", Vector2i.LEFT)
	await _go_to_map(&"pokemon_tower_2f")
	assert_eq(_boot.get_map().get_node(^"Triggers").get_child_count() >= 2, true)
	assert_false(GameState.flags.has_flag(&"rival_tower_won"))


func test_escape_rope_from_the_6f_leads_to_the_door() -> void:
	await _rope_from(&"pokemon_tower_6f", &"devant_spectre")


func test_escape_rope_is_refused_on_the_ground_floor() -> void:
	await _start(START_1F)
	var ropes := GameState.bag.count_of(ROPE)
	var menu := _boot.get_menu_director()
	assert_true(menu.open())
	menu.request_item_use(ROPE)
	await wait_process_frames(10)
	assert_eq(_boot.get_map().map_id, &"pokemon_tower_1f", "on ne bouge pas")
	assert_eq(GameState.bag.count_of(ROPE), ropes, "la Corde reste dans le Sac")
