extends GutTest
## Jalon 25 de bout en bout, dans la vraie scène Boot et sur les vraies cartes : statue du Manoir
## (interrupteur et grilles), machine de quiz (bonne réponse), échange fixe du Labo (Hector :
## Raichu → Électrode « Kourjus »), Vieil Ambre de la réserve du Musée, porte de l'Arène avec la
## Clé Secrète.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_j25_flow_save.json"
const FADE := 0.05
const TIMEOUT := 15.0

var _boot: Boot
var _fs: MemoryFs
var _saved_router: Array = []
var _pages: Array[String] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-22T03:00:00")
	_fs = MemoryFs.new()
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"interact", &"move_up"]:
		Input.action_release(action)


func test_mansion_statue_toggles_the_switch_and_the_gates() -> void:
	await _start(&"pokemon_mansion_1f", Vector2i(2, 6), Vector2i.UP)
	var gate_a := Vector2i(16, 6)
	assert_true(_boot.get_map().get_grid().is_occupied(gate_a), "grille A fermée sur ARRÊT")
	await _interact([true])
	assert_true(GameState.flags.has_flag(&"mansion_switch_on"), "MARCHE")
	assert_has(_pages, "Qui ne le ferait pas ?")
	assert_false(_boot.get_map().get_grid().is_occupied(gate_a), "grille A ouverte")
	await _interact([true])
	assert_false(GameState.flags.has_flag(&"mansion_switch_on"), "ARRÊT")
	assert_true(_boot.get_map().get_grid().is_occupied(gate_a), "grille A refermée")
	_pages.clear()
	await _interact([false])
	assert_false(GameState.flags.has_flag(&"mansion_switch_on"), "NON : rien ne change")
	assert_has(_pages, "Pas encore.")


func test_quiz_right_answer_opens_the_gate() -> void:
	await _start(&"cinnabar_gym", Vector2i(15, 8), Vector2i.UP)
	assert_true(_boot.get_map().get_grid().is_occupied(Vector2i(18, 7)), "herse 1 fermée")
	await _interact([true])
	assert_true(GameState.flags.has_flag(&"cinnabar_gym_gate_1"), "Chenipan → Papilusion : OUI")
	assert_has(_pages, "Exact ! Tu peux passer !")
	assert_false(_boot.get_map().get_grid().is_occupied(Vector2i(18, 7)), "herse 1 ouverte")
	assert_false(GameState.flags.has_flag(&"cinnabar_gym_quiz_yes"), "drapeau de travail baissé")
	_pages.clear()
	await _interact([])
	assert_eq(_pages, ["Porte ouverte."] as Array[String], "la machine ne repose plus la question")


func test_hector_trades_his_electrode_for_a_raichu() -> void:
	await _start(&"cinnabar_lab_meeting", Vector2i(3, 5), Vector2i.LEFT, [&"pikachu", &"raichu"])
	await _interact([true], 1)
	var received: Pokemon = GameState.party.get_at(1)
	assert_eq([received.species_id, received.nickname, received.level], [&"electrode", "Kourjus", 30])
	assert_eq([received.origin, received.original_trainer], [Pokemon.Origin.TRADE, "Hector"])
	assert_eq(GameState.party.get_at(0).species_id, &"pikachu", "le reste de l'équipe ne bouge pas")
	assert_true(GameState.flags.has_flag(&"cinnabar_trade_electrode_done"))
	assert_true(GameState.pokedex.is_caught(&"electrode"))
	assert_has(_pages, "Merci !")
	_pages.clear()
	await _interact([])
	assert_eq(_pages, ["Ton Raichu se porte à merveille !"] as Array[String], "une seule fois")
	assert_eq(GameState.party.size(), 2)


func test_hector_without_a_raichu() -> void:
	await _start(&"cinnabar_lab_meeting", Vector2i(3, 5), Vector2i.LEFT, [&"pikachu"])
	await _interact([true])
	assert_has(_pages, "Hmm ? Ce n'est pas un Raichu.\nPense à moi si tu en as un.")
	assert_false(GameState.flags.has_flag(&"cinnabar_trade_electrode_done"))
	assert_eq(GameState.party.get_at(0).species_id, &"pikachu")


func test_museum_scientist_gives_the_old_amber_once() -> void:
	await _start(&"pewter_museum_reserve", Vector2i(11, 4), Vector2i.RIGHT)
	await _interact([])
	assert_eq(GameState.bag.count_of(&"old_amber"), 1, "Vieil Ambre reçu")
	assert_true(GameState.flags.has_flag(&"pewter_museum_got_old_amber"))
	await _interact([])
	assert_eq(GameState.bag.count_of(&"old_amber"), 1, "une seule fois")
	assert_has(_pages, "Chut ! Fais examiner le Vieil Ambre !")


func test_the_secret_key_opens_the_gym_for_good() -> void:
	await _start(&"cinnabar_island", Vector2i(25, 6), Vector2i.UP, [],
		[&"got_pokemon_mansion_b1f_item_5"])
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"cinnabar_gym", TIMEOUT)
	Input.action_release(&"move_up")
	await _drain([])
	assert_eq(_boot.get_map().map_id, &"cinnabar_gym", "entré dans l'Arène")
	assert_true(GameState.flags.has_flag(&"cinnabar_gym_unlocked"))
	assert_has(_pages, "La porte de l'Arène est ouverte !")


# --- Outils -----------------------------------------------------------------------------------

func _start(map_id: StringName, cell: Vector2i, facing: Vector2i,
		species: Array[StringName] = [&"blastoise"], flags: Array[StringName] = []) -> void:
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	var spawn := map.get_node(^"Spawns").get_child(0).name
	map.free()
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map_id
	_boot.start_spawn = StringName(spawn)
	_boot.start_facing = facing
	add_child_autofree(_boot)
	var runner := _boot.get_dialogue_runner()
	runner.chars_per_second = 0.0
	runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	GameState.new_game(7)
	GameState.player_name = "Kevin"
	for id: StringName in species:
		GameState.party.add(PokemonFactory.create(_boot.get_pokemon_data(), id, 30,
			GameState.rng))
	for flag: StringName in flags:
		GameState.flags.set_flag(flag)
	_boot.get_map().apply_flag_gates(GameState.flags)
	_boot.get_map().spawn_player_at(_boot.get_player(), cell, facing)
	await wait_process_frames(3)


## Action devant soi ; [param answers] : réponses aux choix dans l'ordre ; [param pick] : place
## choisie dans le sélecteur d'échange.
func _interact(answers: Array, pick: int = 0) -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await _drain(answers, pick)


func _drain(answers: Array, pick: int = 0) -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var trade := _boot.get_trade_overlay()
	var queue := answers.duplicate()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	await wait_process_frames(2)
	while (director.is_running() or runner.is_running()) and Time.get_ticks_msec() < deadline:
		if trade.is_picking():
			trade.get_picker().target_chosen.emit(pick)
		elif runner.is_awaiting_choice():
			runner.choose(queue.pop_front() if not queue.is_empty() else false)
		elif box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
