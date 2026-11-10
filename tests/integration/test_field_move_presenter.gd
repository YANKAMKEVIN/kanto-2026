extends GutTest
## Coupe visible sur la vraie carte de Carmin (jalon 16, `jalon-16.md` §2.3, dossier 19 §7) :
## vrai Boot, départ `cut_ready`, vraie scène `cut_tree_vermilion_gym` jouée par l'arbuste.
## - compagnon dehors et compatible : il reste dehors, marche à côté du joueur, coupe, y reste ;
## - compagnon incompatible : il rentre comme pour toute scène ; le premier compatible de
##   l'équipe apparaît (éclat de Ball) à côté du joueur, puis rentre ;
## - espèce sans planche d'exploration peinte (Sabelette) : l'effet seul ;
## - « Réduire les animations » : le fondu seul ;
## - durée en temps simulé : ≤ 2 s.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/cut_ready.json"
const SAVE_PATH := "user://test_field_move_presenter_save.json"
const TIMEOUT := 12.0
const SCENE_TIMEOUT_MS := 30000
const CUT := &"cut_vermilion_gym_bush"
const UNDER_TREE := Vector2i(49, 11)
const BESIDE := Vector2i(50, 11)
## Équipe du départ : Pikachu (compagnon, incompatible), Sabelette, Mystherbe, Reptincel.
const CHARMELEON := 3

var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _stages: Array[StringName] = []
## Relevés au début de l'effet : Pokémon montré (espèce, case, visible), compagnon montré.
var _at_slash: Dictionary = {}


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = 0.05
	SceneRouter.fade_in_duration = 0.05
	_stages.clear()
	_at_slash = {}


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	Input.action_release(&"interact")


func _start() -> void:
	var start := DebugStart.new()
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	assert_true(start.load_file(START, data, items), "\n".join(start.get_errors()))
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = start.map
	_boot.start_spawn = start.spawn
	_boot.start_facing = start.facing
	add_child_autofree(_boot)
	_player = _boot.get_player()
	await wait_until(func() -> bool:
		return is_instance_valid(_boot.get_map()) and not SceneRouter.is_transitioning(),
		TIMEOUT)
	start.apply(GameState, _boot.get_pokemon_data())
	_boot.get_map().refresh_npcs(GameState.flags)
	_boot.get_map().apply_flag_gates(GameState.flags)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_field_move_presenter().stage_started.connect(_on_stage)
	await wait_process_frames(3)
	assert_eq(_player.get_cell(), UNDER_TREE)


## Compagnon [param index] dans l'équipe (−1 : aucun), montré s'il le peut.
func _set_companion(index: int) -> void:
	GameState.set_companion(GameState.party.get_at(index) if index >= 0 else null)
	var controller := _boot.get_companion_controller()
	controller.refresh()
	await wait_until(func() -> bool:
		return not controller.get_node_2d().is_moving(), TIMEOUT)
	await wait_seconds(Companion.BURST + 0.1)


func _on_stage(stage: StringName) -> void:
	_stages.append(stage)
	if stage != FieldMoveStage.SLASH:
		return
	var shown := _boot.get_field_move_presenter().get_shown()
	_at_slash = {
		"species": shown.get_species() if shown != null else &"",
		"cell": shown.get_cell() if shown != null else FieldMoveStage.NONE,
		"visible": shown != null and shown.visible and shown.is_inside_tree(),
		"companion": _boot.get_companion_controller().is_shown(),
		"slash": _boot.get_field_move_presenter().get_slash() == null,
	}


## Examine l'arbuste et répond COUPER ; joue tout jusqu'à la fin de la scène.
func _cut() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running()) and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_choice_showing():
			box.get_choice_cards().get_confirm_button().pressed.emit()
		elif box.is_open() and not runner.is_awaiting_choice():
			box.advance_requested.emit()
	await wait_process_frames(3)
	assert_true(GameState.flags.has_flag(CUT), "arbuste coupé")
	assert_false((_boot.get_map().get_node(^"Entities/GymTree") as Node2D).visible)


func test_companion_out_and_compatible_cuts_and_stays_out() -> void:
	await _start()
	await _set_companion(CHARMELEON)
	var controller := _boot.get_companion_controller()
	assert_true(controller.is_shown(), "Reptincel dehors")
	await _cut()
	assert_eq(_stages, [FieldMoveStage.APPEAR, FieldMoveStage.SLASH, FieldMoveStage.CLEAR]
		as Array[StringName], "le compagnon ne rentre pas")
	assert_eq([_at_slash.get("species"), _at_slash.get("cell"), _at_slash.get("visible")],
		[&"charmeleon", BESIDE, true], "à côté du joueur pendant la coupe")
	assert_true(_at_slash.get("companion"), "resté dehors pendant la scène")
	assert_true(controller.is_shown(), "toujours dehors après la scène")
	assert_eq(controller.get_node_2d().get_cell(), BESIDE)
	assert_null(_boot.get_map().get_entities().get_node_or_null(^"FieldMovePokemon"))
	# Il reprend le suivi au premier pas du joueur.
	_player.step_started.connect(func(_f: Vector2i, _t: Vector2i, _k: StringName) -> void:
		Input.action_release(&"move_up")
		_player.set_input_enabled(false, &"test_one_step"), CONNECT_ONE_SHOT)
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return not _player.is_input_enabled(), TIMEOUT)
	await wait_until(func() -> bool:
		return not _player.is_moving() and not controller.get_node_2d().is_moving(), TIMEOUT)
	_player.set_input_enabled(true, &"test_one_step")
	assert_eq(_player.get_cell(), UNDER_TREE + Vector2i.UP, "un pas")
	assert_eq(controller.get_node_2d().get_cell(), UNDER_TREE, "il suit le joueur")
	assert_push_error_count(0)


func test_team_pokemon_appears_then_withdraws() -> void:
	await _start()
	GameState.party.move(CHARMELEON, 1)
	await _set_companion(0)
	var controller := _boot.get_companion_controller()
	assert_true(controller.is_shown(), "Pikachu dehors")
	await _cut()
	assert_eq(_stages, [FieldMoveStage.APPEAR, FieldMoveStage.SLASH, FieldMoveStage.CLEAR,
		FieldMoveStage.WITHDRAW] as Array[StringName])
	assert_eq([_at_slash.get("species"), _at_slash.get("cell"), _at_slash.get("visible")],
		[&"charmeleon", BESIDE, true], "Reptincel apparu à côté du joueur")
	assert_false(_at_slash.get("companion"), "Pikachu (incompatible) rentré pour la scène")
	await wait_process_frames(2)
	assert_null(_boot.get_map().get_entities().get_node_or_null(^"FieldMovePokemon"),
		"rentré et retiré")
	await wait_seconds(Companion.BURST + 0.1)
	assert_true(controller.is_shown(), "Pikachu ressort après la scène")
	assert_push_error_count(0)


func test_unpainted_species_cuts_with_the_effect_only() -> void:
	await _start()
	await _set_companion(-1)
	await _cut()
	assert_eq(_stages, [FieldMoveStage.SLASH, FieldMoveStage.CLEAR] as Array[StringName],
		"Sabelette : aucune planche d'exploration")
	assert_eq(_at_slash.get("species"), &"")
	assert_push_error_count(0)


func test_reduce_motion_fades_the_tree_only() -> void:
	await _start()
	_boot.get_field_move_presenter().reduce_motion = true
	await _set_companion(CHARMELEON)
	await _cut()
	assert_eq(_stages, [FieldMoveStage.CLEAR] as Array[StringName])
	assert_push_error_count(0)


## Durée en temps simulé (Pokémon de l'équipe : le plus long, éclat à l'aller et au retour).
func test_team_pokemon_cut_lasts_at_most_two_seconds() -> void:
	await _start()
	GameState.party.move(CHARMELEON, 1)
	await _set_companion(-1)
	var presenter := _boot.get_field_move_presenter()
	var tree := _boot.get_map().get_node(^"Entities/GymTree") as Node2D
	var state := {"done": false}
	var clock := TweenClock.new(get_tree())
	var run := func() -> void:
		await presenter.perform(&"cut", tree)
		state["done"] = true
	run.call()
	var steps := clock.run_until(func() -> bool: return state["done"], 5.0)
	clock.release()
	var expected := Companion.BURST * 2.0 + FieldMoveStage.SLASH_DURATION \
		+ FieldMoveStage.CLEAR_FADE
	assert_true(state["done"])
	assert_eq(_stages.size(), 4)
	assert_gte(steps, roundi(expected * 60.0) - 1, "pas fini avant la durée")
	assert_lte(steps, roundi(expected * 60.0) + 6, "au plus un pas de plus par enchaînement")
	assert_lte(steps * TweenClock.STEP, FieldMoveStage.MAX_DURATION, "≤ 2 s")
	assert_eq(tree.modulate.a, 0.0, "arbuste effacé")
	assert_push_error_count(0)
