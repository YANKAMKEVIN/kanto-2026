extends SceneTree
## Rend une bande du bord d'une carte, retournée en miroir, pour prolonger le décor de quelques
## pixels hors des limites (`tools/decor_hors_limites.py`). Sans enregistrer la scène.
##
##   godot --path . -s res://tools/capture_bord_carte.gd -- --map=route_34 --axis=x --thickness=64
##
## `--axis=x` écrit `<map>_west.png` et `<map>_east.png`, `--axis=y` `<map>_north.png` et
## `<map>_south.png`, dans `assets/world/maps/bords/`. Les PNJ ne sont pas rendus.

const OUT_DIR := "res://assets/world/maps/bords/"
const TILE := 96
const WAIT_FRAMES := 12


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var options := {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var parts := arg.trim_prefix("--").split("=")
			options[parts[0]] = parts[1]
	var map_id: String = options["map"]
	var thickness := int(options.get("thickness", "64"))
	var horizontal: bool = options.get("axis", "x") == "x"
	PaintedGround.auto_bake = false  # sol dessiné en direct, entier dès la première image
	var map := (load("res://game/world/maps/%s.tscn" % map_id) as PackedScene).instantiate()
	root.add_child(map)
	var size := Vector2i(map.get(&"size")) * TILE
	for child: Node in map.get_node(^"Entities").get_children():
		if child is Npc:
			(child as Node2D).visible = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var rects: Dictionary
	if horizontal:
		rects = {
			"west": Rect2i(0, 0, thickness, size.y),
			"east": Rect2i(size.x - thickness, 0, thickness, size.y),
		}
	else:
		rects = {
			"north": Rect2i(0, 0, size.x, thickness),
			"south": Rect2i(0, size.y - thickness, size.x, thickness),
		}
	var views: Dictionary = {}
	for side: String in rects:
		var rect: Rect2i = rects[side]
		var view := SubViewport.new()
		view.size = rect.size
		view.world_2d = root.world_2d
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(view)
		var camera := Camera2D.new()
		camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
		camera.position = Vector2(rect.position)
		view.add_child(camera)
		camera.make_current()
		views[side] = view
	for i: int in WAIT_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	for side: String in views:
		var image: Image = (views[side] as SubViewport).get_texture().get_image()
		image.convert(Image.FORMAT_RGB8)
		if horizontal:
			image.flip_x()
		else:
			image.flip_y()
		image.save_png(OUT_DIR + "%s_%s.png" % [map_id, side])
	quit()
