extends GutTest
## Compagnon dans la grotte (jalon 12, T20 ; dossier 15 §13, `jalon-12.md` §2.2, §2.3, §0.4
## n° 5–6) sur le vrai Boot et les vrais étages : visible dans les galeries (catégorie « grotte » =
## `interior` faux), phrase « grotte » (§20 n° 40), **jamais posé sur une échelle** à l'arrivée
## (il sort au premier pas, sur la case quittée), rentré au Centre du Mont Sélénite, ne déclenche
## aucune rencontre de gravats ; « Réduire les animations » coupe le vacillement des halos
## ([method LightGlow.set_reduce_motion], branché dans les réglages de Boot).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SAVE_PATH := "user://test_companion_cave_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _boot: Boot
var _fades: Array[float] = []
var _companion: CompanionController


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-13T10:00:00")


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact", &"run"]:
		Input.action_release(action)
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	LightGlow.set_reduce_motion(false)


func _start(map: StringName, spawn: StringName, facing: Vector2i) -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_companion = _boot.get_companion_controller()
	GameState.flags.set_flag(&"starter_chosen")
	var lead := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 15, GameRng.new(7))
	GameState.party.add(lead)
	GameState.set_companion(lead)
	_companion.refresh()


func _step(direction: Vector2i) -> bool:
	var player := _boot.get_player()
	if not player.script_step(direction):
		return false
	await wait_until(func() -> bool: return not player.is_moving() \
		and not _companion.get_node_2d().is_moving(), TIMEOUT)
	await wait_process_frames(2)
	return true


func _put_player(cell: Vector2i, facing: Vector2i) -> void:
	var map := _boot.get_map()
	_boot.get_player().enter_map(map.get_grid(), cell, facing, map.get_pixel_rect())
	_companion.on_cutscene_started()
	_companion.on_cutscene_finished()


func _close_dialogue() -> void:
	var runner := _boot.get_dialogue_runner()
	for i: int in 10:
		await wait_process_frames(3)
		if not runner.is_running():
			return
		Input.action_press(&"interact")
		await wait_process_frames(2)
		Input.action_release(&"interact")


## Premier pas libre (ni gravats, ni passage) depuis la position du joueur.
func _free_calm_step() -> Vector2i:
	var map := _boot.get_map()
	var grid := map.get_grid()
	var cell := _boot.get_player().get_cell()
	for direction: Vector2i in DIRECTIONS:
		var next := cell + direction
		if grid.is_free(next) and not grid.is_rubble(next) \
				and map.get_warps().get_at(next).is_empty():
			return direction
	return Vector2i.ZERO


# --- Visible, phrase « grotte » -----------------------------------------------------------------

func test_visible_in_the_galleries_with_the_cave_line() -> void:
	await _start(&"mt_moon_1f", &"arrivee_a", Vector2i.DOWN)
	assert_false(_boot.get_map().interior, "grotte : ni bâtiment ni intérieur")
	assert_true(_boot.get_caves().is_cave(&"mt_moon_1f"))
	var direction := _free_calm_step()
	assert_ne(direction, Vector2i.ZERO, "un pas libre depuis l'arrivée")
	assert_true(await _step(direction))
	await wait_until(func() -> bool: return _companion.is_shown(), TIMEOUT)
	assert_true(_companion.is_shown(), "il suit dans la grotte")
	assert_eq(_companion.talk(), CompanionRules.CONTEXT_LINES[&"cave"], "phrase « grotte »")
	assert_eq(CompanionRules.CONTEXT_LINES[&"cave"], &"companion_cave")
	var line := _boot.get_dialogue_library().get_dialogue(&"companion_cave")
	assert_eq(line.variants[0].pages[0].text, "{pokemon} écoute l'écho de ses pas.",
		"dossier 15 §20 n° 40")
	await _close_dialogue()
	var catalog := CompanionCatalog.new()
	assert_true(catalog.load_file(), "\n".join(catalog.get_errors()))
	for map_id: StringName in [&"mt_moon_1f", &"mt_moon_b1f", &"mt_moon_b2f"]:
		assert_eq(catalog.context_of(map_id), &"cave", "%s : contexte grotte" % map_id)


# --- Échelles ------------------------------------------------------------------------------------

func test_never_placed_on_a_ladder_when_arriving() -> void:
	await _start(&"mt_moon_1f", &"arrivee_a", Vector2i.DOWN)
	var direction := _free_calm_step()
	assert_true(await _step(direction))
	await wait_until(func() -> bool: return _companion.is_shown(), TIMEOUT)
	for target: Array in [[&"mt_moon_b1f", &"arrivee_a"], [&"mt_moon_1f", &"arrivee_b"],
			[&"mt_moon_b2f", &"arrivee_d"]]:
		var spawn: StringName = target[1]
		var map := (load(MapCatalog.scene_path(target[0])) as PackedScene).instantiate() as GameMap
		var spawn_cell := map.get_spawn_cell(spawn)
		map.free()
		# Orientation d'arrivée : à l'opposé de l'échelle voisine (la case derrière le joueur).
		SceneRouter.change_map(target[0], spawn)
		await wait_until(func() -> bool: return _boot.get_map().map_id == target[0] \
			and _boot.is_stable(), TIMEOUT)
		await wait_process_frames(2)
		var here := _boot.get_map()
		var player := _boot.get_player()
		assert_eq(player.get_cell(), spawn_cell)
		var behind := player.get_cell() - player.get_facing()
		var on_ladder := not here.get_warps().get_at(behind).is_empty()
		if _companion.is_shown():
			var cell := _companion.get_node_2d().get_cell()
			assert_true(here.get_warps().get_at(cell).is_empty(),
				"%s : jamais sur une échelle (%s)" % [target[0], cell])
		else:
			assert_true(on_ladder, "%s : masqué parce que derrière lui, l'échelle" % target[0])
		# Premier pas : il sort sur la case quittée (jamais l'échelle).
		var step := _free_calm_step()
		assert_ne(step, Vector2i.ZERO, "%s : un pas libre" % target[0])
		var from := player.get_cell()
		assert_true(await _step(step))
		await wait_until(func() -> bool: return _companion.is_shown(), TIMEOUT)
		assert_true(_companion.is_shown(), "%s : de retour au premier pas" % target[0])
		var now := _companion.get_node_2d().get_cell()
		assert_true(here.get_warps().get_at(now).is_empty(), "%s : hors échelle" % target[0])
		if on_ladder:
			assert_eq(now, from, "%s : sur la case quittée" % target[0])


func test_withdrawn_in_the_mt_moon_center() -> void:
	await _start(&"route_3", &"from_center_w", Vector2i.DOWN)
	assert_true(await _step(Vector2i.DOWN))
	await wait_until(func() -> bool: return _companion.is_shown(), TIMEOUT)
	assert_true(_companion.is_shown(), "visible sur la Route 3")
	SceneRouter.change_map(&"mt_moon_center", &"entrance")
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"mt_moon_center" \
		and _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)
	assert_false(_companion.is_shown(), "rentré au Centre (bâtiment)")


# --- Rencontres ----------------------------------------------------------------------------------

func test_the_companion_never_triggers_a_rubble_encounter() -> void:
	await _start(&"mt_moon_1f", &"arrivee_a", Vector2i.DOWN)
	# Gravats forcés presque certains : tout tirage lancerait une rencontre.
	assert_true(_boot.get_encounter_library().override_table(&"mt_moon_1f", &"rubble",
		{"rate": 255, "slots": [{"species": "zubat", "levels": [9, 9], "weight": 1}]}, "test"))
	var map := _boot.get_map()
	var grid := map.get_grid()
	var size := grid.get_size()
	var start := Vector2i(-1, -1)
	var away := Vector2i.ZERO
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			if not grid.is_rubble(cell) or start.x >= 0:
				continue
			for direction: Vector2i in DIRECTIONS:
				var next := cell + direction
				var back := cell - direction
				if grid.is_free(next) and not grid.is_rubble(next) and grid.is_free(back) \
						and map.get_warps().get_at(next).is_empty():
					start = cell
					away = direction
					break
	assert_gt(start.x, -1, "une case de gravats au bord d'un couloir calme")
	_put_player(start, away)
	var director := _boot.get_encounter_director()
	assert_true(await _step(away), "le joueur quitte les gravats pour le sol calme")
	await wait_until(func() -> bool: return _companion.is_shown(), TIMEOUT)
	assert_eq(_companion.get_node_2d().get_cell(), start, "le compagnon est sur les gravats")
	await wait_process_frames(5)
	assert_false(director.is_running(), "aucune rencontre")
	assert_eq(director.get_quiet_steps(), 0, "aucun tirage")
	assert_false(_boot.get_battle_director().is_running())


# --- Réduire les animations ----------------------------------------------------------------------

func test_reduce_motion_freezes_the_glows() -> void:
	await _start(&"mt_moon_1f", &"arrivee_a", Vector2i.DOWN)
	var menu := _boot.get_menu_director()
	assert_false(LightGlow.is_reduce_motion())
	assert_true(menu.change_setting(GameSettings.REDUCE_MOTION, true))
	assert_true(LightGlow.is_reduce_motion(), "vacillement coupé")
	assert_true(menu.change_setting(GameSettings.REDUCE_MOTION, false))
	assert_false(LightGlow.is_reduce_motion(), "vacillement rendu")
