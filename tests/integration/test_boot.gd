extends GutTest
## Boot (jalon 2 §2.1) : démarre dans la chambre du joueur, au spawn « start » face au sud,
## sans titre de zone ni écran titre ; caméra encadrée selon CameraFraming ; câblage du
## routeur de scènes (autoload) et du rideau.

const START_CELL := Vector2i(3, 4)
const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right", &"run", &"interact",
]

var _boot: Boot


func before_each() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	add_child_autofree(_boot)


func after_each() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)


func test_main_scene_is_boot() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://game/boot.tscn")


func test_scene_router_is_autoload() -> void:
	assert_eq(ProjectSettings.get_setting("autoload/SceneRouter"),
		"*res://game/autoload/scene_router.gd")
	assert_not_null(get_tree().root.get_node_or_null(^"SceneRouter"))


func test_starts_in_bedroom_at_start_facing_south() -> void:
	var map := _boot.get_map()
	assert_not_null(map)
	assert_eq(map.map_id, &"player_house_2f")
	assert_true(map.interior)
	assert_eq(map.get_parent(), _boot.get_node(^"%World"))
	var player := _boot.get_player()
	assert_not_null(player)
	assert_eq(player.get_parent(), map.get_entities())
	assert_eq(player.get_cell(), START_CELL)
	assert_eq(map.get_spawn_cell(&"start"), START_CELL)
	assert_eq(player.get_facing(), Vector2i.DOWN)
	assert_eq(player.position, Grid.cell_to_world(START_CELL))
	assert_true(player.is_input_enabled())


func test_no_zone_title_at_start() -> void:
	var hud := _boot.get_hud()
	assert_not_null(hud)
	assert_false(hud.get_zone_title().is_showing(), "aucun titre dans la chambre")


func test_camera_framed_by_camera_framing() -> void:
	var player := _boot.get_player()
	var camera := player.get_camera()
	assert_eq(camera.zoom, Vector2.ONE)
	var expected := CameraFraming.limits_for(
		_boot.get_map().get_pixel_rect(), player.get_viewport_rect().size)
	assert_eq(
		Rect2i(camera.limit_left, camera.limit_top,
			camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top),
		expected
	)


func test_router_wired_to_boot() -> void:
	assert_eq(SceneRouter.get_player(), _boot.get_player())
	assert_eq(SceneRouter.get_current_map(), _boot.get_map())
	assert_false(SceneRouter.is_transitioning())
	var fade := _boot.get_fade()
	assert_not_null(fade)
	assert_eq(fade.layer, UiTokens.LAYER_TRANSITION)
	assert_false(fade.is_opaque())


func test_start_settings_choose_map_and_spawn() -> void:
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	boot.start_map = &"pallet_town"
	boot.start_spawn = &"start"
	add_child_autofree(boot)
	assert_eq(boot.get_map().map_id, &"pallet_town")
	assert_eq(boot.get_player().get_cell(), Vector2i(36, 10))
	# Zone extérieure au démarrage : le titre s'affiche.
	assert_true(boot.get_hud().get_zone_title().is_showing())


func test_no_title_screen() -> void:
	for child: Node in _boot.get_children():
		assert_false(child is Control, "pas d'écran titre : %s" % child.name)


# --- Jalon 3A (T3) : dialogues et interactions ------------------------------------------

func test_game_state_is_empty_at_start() -> void:
	assert_eq(GameState.flags.size(), 0, "nouvelle partie : aucun drapeau")


func test_game_state_is_reset_by_a_new_boot() -> void:
	GameState.flags.set_flag(&"mom_greeted")
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	add_child_autofree(boot)
	assert_false(GameState.flags.has_flag(&"mom_greeted"))


func test_dialogue_library_loaded_without_error() -> void:
	var library := _boot.get_dialogue_library()
	assert_gt(library.size(), 0, "dialogues de data/dialogues/ chargés")
	assert_eq(library.get_errors().size(), 0)
	assert_true(library.has_dialogue(&"mom"))


func test_dialogue_nodes_are_wired() -> void:
	assert_eq(_boot.get_dialogue_box().layer, UiTokens.LAYER_DIALOG)
	assert_not_null(_boot.get_dialogue_runner())
	assert_not_null(_boot.get_interaction_controller())
	assert_true(SceneRouter.map_changed.is_connected(_boot._on_map_changed))
	assert_false(SceneRouter.map_changed.is_connected(
		_boot.get_interaction_controller().set_map), "3B : la carte passe par Boot")
	assert_true(SceneRouter.map_entered.is_connected(
		_boot.get_interaction_controller().on_map_entered))


func test_no_dialogue_in_the_bedroom() -> void:
	await wait_seconds(0.5)
	assert_false(_boot.get_dialogue_runner().is_running())
	assert_false(_boot.get_dialogue_box().is_open())
	assert_true(_boot.get_player().is_input_enabled())
	assert_true(_boot.get_hud().are_controls_visible())


func test_router_signals_disconnected_when_boot_leaves() -> void:
	var controller := _boot.get_interaction_controller()
	var on_map_changed := _boot._on_map_changed
	remove_child(_boot)
	assert_false(SceneRouter.map_changed.is_connected(controller.set_map))
	assert_false(SceneRouter.map_changed.is_connected(on_map_changed))
	assert_false(SceneRouter.map_entered.is_connected(controller.on_map_entered))
	add_child(_boot)


# --- Jalon 3B (T2) : scènes scriptées -------------------------------------------------

## Boot sur Bourg Palette, joueur en (23, 4) tourné vers les hautes herbes.
func _boot_below_the_grass() -> Boot:
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	boot.start_map = &"pallet_town"
	add_child_autofree(boot)
	var map := boot.get_map()
	boot.get_player().enter_map(map.get_grid(), Vector2i(23, 4), Vector2i.UP,
		map.get_pixel_rect())
	return boot


func _finish_dialogue(boot: Boot) -> void:
	var runner := boot.get_dialogue_runner()
	var deadline := Time.get_ticks_msec() + 5000
	while runner.is_running() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		boot.get_dialogue_box().advance_requested.emit()
	assert_false(runner.is_running(), "dialogue terminé")


func test_cutscene_library_loaded_and_director_wired() -> void:
	var library := _boot.get_cutscene_library()
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	assert_true(library.has_cutscene(&"route1_grass"))
	var director := _boot.get_cutscene_director()
	assert_not_null(director)
	assert_false(director.is_running())


func test_controls_hidden_during_the_whole_scene_even_between_dialogues() -> void:
	var boot := _boot_below_the_grass()
	await wait_process_frames(2)
	var hud := boot.get_hud()
	var director := boot.get_cutscene_director()
	var runner := boot.get_dialogue_runner()
	boot.get_cutscene_library().add_from_dict({"test_two": {"steps": [
		{"dialogue": "oak_route1_call"}, {"wait": 0.3}, {"dialogue": "route1_grass_thought"},
	]}}, "test")
	assert_true(hud.are_controls_visible())
	assert_true(director.play(&"test_two"))
	assert_false(hud.are_controls_visible(), "cachés dès le début")
	await wait_until(func() -> bool: return boot.get_dialogue_box().is_open(), 3.0)
	await _finish_dialogue(boot)
	assert_true(director.is_running())
	assert_false(runner.is_running())
	assert_false(hud.are_controls_visible(), "cachés entre deux dialogues")
	await wait_until(func() -> bool: return runner.is_running(), 3.0)
	await wait_until(func() -> bool: return boot.get_dialogue_box().is_open(), 3.0)
	await _finish_dialogue(boot)
	await wait_until(func() -> bool: return not director.is_running(), 3.0)
	assert_true(hud.are_controls_visible(), "rétablis à la fin")
	assert_true(boot.get_player().is_input_enabled())


func test_route1_grass_freezes_the_player_before_the_grass() -> void:
	var boot := _boot_below_the_grass()
	var player := boot.get_player()
	var director := boot.get_cutscene_director()
	var hud := boot.get_hud()
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return director.is_running(), 3.0)
	assert_eq(player.get_cell(), Vector2i(23, 3), "gel sur la case avant les herbes")
	assert_false(hud.are_controls_visible())
	await wait_seconds(0.5)
	assert_eq(player.get_cell(), Vector2i(23, 3), "move_up tenu : aucun pas de plus")
	Input.action_release(&"move_up")
	await wait_until(func() -> bool: return boot.get_dialogue_box().is_open(), 3.0)
	assert_eq(boot.get_dialogue_box().get_speaker_text(), "???")
	assert_eq(boot.get_dialogue_box().get_text(), "Hé ! Attends !")
	await _finish_dialogue(boot)
	# T3 : le joueur se retourne, Chen arrive en courant et s'arrête à côté de lui.
	var runner := boot.get_dialogue_runner()
	await wait_until(func() -> bool: return runner.is_running(), 5.0)
	assert_eq(runner.get_dialogue_id(), &"oak_route1_warning")
	var oak := boot.get_map().get_npc(&"oak")
	assert_not_null(oak, "Chen est apparu")
	if oak == null:
		return
	assert_eq(oak.get_cell(), Vector2i(24, 3), "à côté du joueur, sur l'autre colonne")
	assert_eq(oak.get_facing(), Vector2i.LEFT, "Chen regarde le joueur")
	assert_eq(player.get_facing(), Vector2i.RIGHT, "le joueur regarde Chen")
	assert_false(hud.are_controls_visible())
	await wait_until(func() -> bool: return boot.get_dialogue_box().is_open(), 3.0)
	assert_eq(boot.get_dialogue_box().get_speaker_text(), "Prof. Chen")
	await _finish_dialogue(boot)
	await wait_until(func() -> bool: return not director.is_running(), 3.0)
	assert_eq(player.get_cell(), Vector2i(23, 3), "le joueur n'a pas bougé")
	assert_true(GameState.flags.has_flag(&"oak_met"))
	assert_true(player.is_input_enabled())
	assert_true(hud.are_controls_visible())
	# Remonter : la pensée, en narration sans nom, puis le recul d'un pas.
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return player.get_cell() == Vector2i(23, 4), 3.0)
	Input.action_release(&"move_down")
	await wait_until(func() -> bool: return not player.is_moving(), 3.0)
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return director.is_running(), 3.0)
	Input.action_release(&"move_up")
	assert_eq(player.get_cell(), Vector2i(23, 3))
	await wait_until(func() -> bool: return boot.get_dialogue_box().is_open(), 3.0)
	assert_eq(boot.get_dialogue_box().get_speaker_text(), "")
	assert_true(boot.get_dialogue_box().is_narration())
	assert_eq(boot.get_dialogue_box().get_text(), "Je ne devrais pas aller là sans Pokémon.")
	await _finish_dialogue(boot)
	await wait_until(func() -> bool: return not director.is_running(), 3.0)
	assert_eq(player.get_cell(), Vector2i(23, 4), "recul d'un pas vers le village")
	assert_eq(player.get_facing(), Vector2i.DOWN)
	assert_true(player.is_input_enabled())
