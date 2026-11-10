extends SceneTree
## Balaie des cartes à la taille d'écran donnée et compte les pixels du fond (noir) visibles, comme
## le ferait la caméra du jeu ([CameraFraming]). Rien n'est enregistré dans les scènes.
##
##   godot --path . -s res://tools/audit_bords_noirs.gd -- --view=2340x1080 --maps=route_1,route_2
##   (sans --maps : toutes les cartes qui ne sont pas des intérieurs ou des grottes)
##
## Une ligne par carte : `AUDIT <carte> <pire pourcentage> <position du pire cadrage>`.

const TILE := 96
const STEP_CELLS := 9
const TOLERANCE := 4
const SETTLE_FRAMES := 3
## Profils de lumière d'intérieurs et de souterrains : le noir autour y est voulu.
const CLOSED_PROFILES: Array[String] = ["interior_warm", "office", "tower", "tower_cold", "cave_1f",
	"cave_b1f", "hideout", "greenhouse", "sea_cave", "underground", "whirl_islands_b2f"]

var _view := Vector2i(2340, 1080)


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var names: PackedStringArray = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--view="):
			var parts := arg.trim_prefix("--view=").split("x")
			_view = Vector2i(int(parts[0]), int(parts[1]))
		elif arg.begins_with("--maps="):
			names = arg.trim_prefix("--maps=").split(",")
	if names.is_empty():
		for file: String in DirAccess.get_files_at("res://game/world/maps/"):
			if file.ends_with(".tscn"):
				names.append(file.trim_suffix(".tscn"))
	PaintedGround.auto_bake = false  # sol dessiné en direct, entier dès la première image
	var viewport := SubViewport.new()
	viewport.size = _view
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var camera := Camera2D.new()
	viewport.add_child(camera)
	camera.make_current()
	var background: Color = ProjectSettings.get_setting(
		"rendering/environment/defaults/default_clear_color")
	var key := Color8(background.r8, background.g8, background.b8)
	for map_id: String in names:
		var map := (load("res://game/world/maps/%s.tscn" % map_id) as PackedScene).instantiate()
		if not map is GameMap or (not "--maps=" in " ".join(OS.get_cmdline_user_args())
				and String(map.get(&"light_profile")) in CLOSED_PROFILES):
			map.free()
			continue
		viewport.add_child(map)
		var size: Vector2i = Vector2i(map.get(&"size")) * TILE
		var limits := CameraFraming.limits_for(Rect2i(Vector2i.ZERO, size), Vector2(_view))
		var worst := 0.0
		var where := Vector2.ZERO
		for y: int in _stops(limits.position.y, limits.end.y, _view.y):
			for x: int in _stops(limits.position.x, limits.end.x, _view.x):
				camera.position = Vector2(x, y)
				for i: int in SETTLE_FRAMES:
					await process_frame
				await RenderingServer.frame_post_draw
				var share := _black_share(viewport.get_texture().get_image(), key)
				if share > worst:
					worst = share
					where = Vector2(x, y)
		print("AUDIT %s %.2f %s" % [map_id, worst, where])
		map.queue_free()
		await process_frame
	quit()


## Centres de caméra qui couvrent [first, end] pour une vue de [view] pixels.
func _stops(first: int, end: int, view: int) -> Array[int]:
	var stops: Array[int] = []
	var center := first + view / 2
	var last := end - view / 2
	if last <= center:
		return [(first + end) / 2]
	while center < last:
		stops.append(center)
		center += STEP_CELLS * TILE
	stops.append(last)
	return stops


func _black_share(image: Image, key: Color) -> float:
	var found := 0
	var total := 0
	var limit := float(TOLERANCE) / 255.0
	for y: int in range(0, image.get_height(), 3):
		for x: int in range(0, image.get_width(), 3):
			total += 1
			var c := image.get_pixel(x, y)
			if absf(c.r - key.r) <= limit and absf(c.g - key.g) <= limit and absf(c.b - key.b) <= limit:
				found += 1
	return 100.0 * found / total
