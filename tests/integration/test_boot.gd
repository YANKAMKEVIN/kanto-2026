extends GutTest
## Boot : démarre directement dans Bourg Palette, joueur au spawn face au sud.

var _boot: Boot


func before_each() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	add_child_autofree(_boot)


func test_main_scene_is_boot() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://game/boot.tscn")


func test_player_spawns_at_start_facing_south() -> void:
	var player := _boot.get_player()
	assert_not_null(player)
	assert_eq(player.get_parent(), _boot.get_map().get_entities())
	assert_eq(player.get_cell(), Vector2i(36, 10))
	assert_eq(player.get_facing(), Vector2i.DOWN)
	assert_eq(player.position, Grid.cell_to_world(Vector2i(36, 10)))


func test_camera_bounded_to_map() -> void:
	var camera := _boot.get_player().get_camera()
	assert_eq(camera.zoom, Vector2.ONE)
	assert_eq(
		Rect2i(camera.limit_left, camera.limit_top,
			camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top),
		_boot.get_map().get_pixel_rect()
	)


func test_no_title_screen() -> void:
	for child: Node in _boot.get_children():
		assert_false(child is Control, "pas d'écran titre : %s" % child.name)
