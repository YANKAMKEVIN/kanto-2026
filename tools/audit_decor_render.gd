extends SceneTree
## Audit décor / collisions, étape 1 : rend chaque carte extérieure en entier (sans joueur ni
## lumière du monde) et écrit sa vraie grille à côté. L'étape 2 est tools/audit_decor_compare.py.
##
##   godot --path . --resolution 320x180 -s res://tools/audit_decor_render.gd -- [--only=a,b]
##
## Sortie : build/audit_decor/<carte>.png (32 px par case) et <carte>.grid.txt (une ligne par
## rangée : « # » solide, « ~ » eau, « g » hautes herbes, « . » libre). Lit les cartes sans
## jamais les réenregistrer.
const MAPS_DIR: String = "res://game/world/maps"
const OUT_DIR: String = "res://build/audit_decor"
const CELL_PX: int = 96
const AUDIT_PX: int = 32
const SETTLE_FRAMES: int = 6


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var only := PackedStringArray()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=").split(",")
	var names := DirAccess.get_files_at(MAPS_DIR)
	names.sort()
	var count := 0
	for file: String in names:
		if not file.ends_with(".tscn"):
			continue
		var id := file.get_basename()
		if not only.is_empty() and not only.has(id):
			continue
		if await _render(id):
			count += 1
	print("AUDIT rendu : %d cartes" % count)
	quit()


func _render(id: String) -> bool:
	var scene := load("%s/%s.tscn" % [MAPS_DIR, id]) as PackedScene
	if scene == null:
		print("AUDIT ignorée (chargement) : ", id)
		return false
	var map: Node2D = scene.instantiate() as Node2D
	if map == null or not map.has_method(&"get_grid") or bool(map.get(&"interior")):
		if map != null:
			map.free()
		return false
	var viewport := SubViewport.new()
	var size: Vector2i = map.get(&"size")
	viewport.size = size * AUDIT_PX
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	root.add_child(viewport)
	viewport.add_child(map)
	var camera := Camera2D.new()
	camera.zoom = Vector2.ONE * (float(AUDIT_PX) / CELL_PX)
	camera.position = Vector2(size * CELL_PX) * 0.5
	map.add_child(camera)
	camera.make_current()
	for i: int in SETTLE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.save_png("%s/%s.png" % [OUT_DIR, id])
	_write_grid(id, map.call(&"get_grid"), size)
	viewport.queue_free()
	await process_frame
	print("AUDIT rendue : %s %dx%d" % [id, size.x, size.y])
	return true


func _write_grid(id: String, grid: Object, size: Vector2i) -> void:
	var lines := PackedStringArray()
	for y: int in size.y:
		var row := ""
		for x: int in size.x:
			var cell := Vector2i(x, y)
			if grid.call(&"is_water", cell):
				row += "~"
			elif grid.call(&"is_solid", cell):
				row += "#"
			elif grid.call(&"is_tall_grass", cell):
				row += "g"
			else:
				row += "."
		lines.append(row)
	var file := FileAccess.open("%s/%s.grid.txt" % [OUT_DIR, id], FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
