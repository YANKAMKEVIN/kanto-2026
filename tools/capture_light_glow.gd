extends SceneTree
## Planche de contrôle des fondations de grotte du jalon 12 (T7) : les quatre types de halo
## [LightGlow] (`data/world/light_glows.json`) sur un sol sombre provisoire, la tuile
## provisoire `RUBBLE` (gravats) et le héros peint sous la lampe (il prend la lumière : le halo
## est au-dessus des personnages). Rendu à 1:1 (cases de 96 px), pas en `--headless`.
##
##   godot --path . -s res://tools/capture_light_glow.gd -- --out=build/captures/j12_t7
##
## Écrit `halos.png` (vacillement actif) et `halos_reduit.png` (« Réduire les animations »).

const CELLS := Vector2i(20, 8)
const FLOOR := Color("#2b2f37")
const GLOWS: Array = [
	[&"lamp", Vector2i(3, 3)], [&"shaft", Vector2i(8, 3)], [&"shard", Vector2i(12, 3)],
	[&"projector", Vector2i(16, 4)],
]
const RUBBLE_PATCH := Rect2i(6, 5, 5, 2)
const PLAYER_CELL := Vector2i(3, 3)

var _out: String = "build/captures/j12_t7"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.get_slice("=", 1)
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + _out))
	var glow_script: GDScript = load("res://game/world/lighting/light_glow.gd")
	for reduced: bool in [false, true]:
		glow_script.call(&"set_reduce_motion", reduced)
		var image := await _render(glow_script)
		image.save_png("res://%s/%s.png" % [_out, "halos_reduit" if reduced else "halos"])
	glow_script.call(&"set_reduce_motion", false)
	print("captures : %s" % _out)
	quit()


func _render(glow_script: GDScript) -> Image:
	var viewport := SubViewport.new()
	viewport.size = CELLS * 96
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var floor_rect := ColorRect.new()
	floor_rect.color = FLOOR
	floor_rect.size = Vector2(CELLS * 96)
	floor_rect.z_index = -3
	viewport.add_child(floor_rect)
	var tiles: GDScript = load("res://game/world/overworld_tiles.gd")
	var layer := TileMapLayer.new()
	layer.tile_set = load(tiles.TILESET_PATH)
	layer.z_index = -2
	for y: int in range(RUBBLE_PATCH.position.y, RUBBLE_PATCH.end.y):
		for x: int in range(RUBBLE_PATCH.position.x, RUBBLE_PATCH.end.x):
			layer.set_cell(Vector2i(x, y), tiles.SOURCE_ID,
				tiles.atlas_coords(tiles.Kind.RUBBLE, (x + y) % 2))
	viewport.add_child(layer)
	var hero := AnimatedSprite2D.new()
	hero.sprite_frames = load("res://assets/sprites/characters/painted/player_frames.tres")
	hero.animation = &"idle_down"
	hero.centered = false
	hero.offset = Vector2(-hero.sprite_frames.get_frame_texture(&"idle_down", 0).get_width()
		/ 2.0, -hero.sprite_frames.get_frame_texture(&"idle_down", 0).get_height())
	hero.position = Vector2(PLAYER_CELL.x * 96 + 48, (PLAYER_CELL.y + 1) * 96)
	viewport.add_child(hero)
	for entry: Array in GLOWS:
		var glow := Sprite2D.new()
		glow.set_script(glow_script)
		glow.set(&"glow_type", entry[0])
		var cell: Vector2i = entry[1]
		glow.position = Vector2(cell.x * 96 + 48, cell.y * 96 + 48)
		viewport.add_child(glow)
		var label := Label.new()
		label.text = String(entry[0])
		label.position = Vector2(cell.x * 96, 8)
		label.add_theme_font_size_override(&"font_size", 28)
		viewport.add_child(label)
	for i: int in 6:
		await process_frame
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	await process_frame
	return image
