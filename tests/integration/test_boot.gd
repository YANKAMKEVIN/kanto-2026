extends GutTest
## Boot (jalon 2 §2.1) : démarre dans la chambre du joueur, au spawn « start » face au sud,
## sans titre de zone ni écran titre ; caméra encadrée selon CameraFraming ; câblage du
## routeur de scènes (autoload) et du rideau.

const START_CELL := Vector2i(3, 4)

var _boot: Boot


func before_each() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	add_child_autofree(_boot)


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
