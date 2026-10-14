extends SceneTree
## Rendu du **sol peint seul** (`PaintedGround`) des cartes peintes, pour prouver qu'un
## changement de `painted_ground.gd` / `ground_blend.gdshader` ne modifie aucun pixel
## (jalon 12 T7 : textures réglables, défauts = herbe, pavés, chemin).
##
##   godot --path . -s res://tools/capture_painted_ground.gd -- --out=build/pg_avant
##   godot --path . -s res://tools/capture_painted_ground.gd -- --out=build/pg_apres \
##     --reference=build/pg_avant
##
## Pas en `--headless` (il faut un rendu). Par carte : la carte entière réduite (mipmaps) et un
## détail 1:1 au centre. `--reference=<dossier>` : compare chaque image à celle du dossier,
## affiche l'écart maximal par canal (0 = identique au pixel près) et quitte avec le code 1 si
## une image diffère. `--fresh` : sol **reconstruit** comme le fait un outil de construction
## (`PaintedGround.new()`, même taille et même masque, textures par défaut) au lieu du nœud
## enregistré dans la scène. Bourg Palette est exclu : sa mer ondule (`TIME`).

const MAPS: Array[StringName] = [
	&"viridian_city", &"pewter_city", &"route_2", &"route_2_north", &"viridian_forest",
	&"route_22", &"route_1",
]
const VIEW := Vector2i(1170, 540)

var _out: String = "build/pg"
var _reference: String = ""
var _fresh: bool = false


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.get_slice("=", 1)
		elif arg.begins_with("--reference="):
			_reference = arg.get_slice("=", 1)
		elif arg == "--fresh":
			_fresh = true
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + _out))
	var different := 0
	for map_id: StringName in MAPS:
		for detail: bool in [false, true]:
			var image := await _render(map_id, detail)
			if image == null:
				print("%s : pas de PaintedGround" % map_id)
				different += 1
				continue
			var file := "%s_%s.png" % [map_id, "detail" if detail else "carte"]
			image.save_png("res://%s/%s" % [_out, file])
			if not _reference.is_empty():
				var delta := _compare(image, "res://%s/%s" % [_reference, file])
				print("%-28s écart max %d / 255" % [file, delta])
				if delta != 0:
					different += 1
	if not _reference.is_empty():
		print("images différentes : %d" % different)
	quit(1 if different > 0 else 0)


func _render(map_id: StringName, detail: bool) -> Image:
	var map := (load("res://game/world/maps/%s.tscn" % map_id) as PackedScene).instantiate()
	var ground := map.get_node_or_null(^"PaintedGround") as Node2D
	if ground == null:
		map.free()
		return null
	map.remove_child(ground)
	map.free()
	if _fresh:
		var rebuilt := (load("res://game/world/ground/painted_ground.gd") as GDScript).new() \
			as Node2D
		rebuilt.set(&"size", ground.get(&"size"))
		rebuilt.set(&"mask", ground.get(&"mask"))
		ground.free()
		ground = rebuilt
	var viewport := SubViewport.new()
	viewport.size = VIEW
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	viewport.add_child(ground)
	var pixels := Vector2(ground.get(&"size")) * 96.0
	if detail:
		viewport.canvas_transform = Transform2D(0.0, -(pixels / 2.0 - Vector2(VIEW) / 2.0).round())
	else:
		var scale := minf(VIEW.x / pixels.x, VIEW.y / pixels.y)
		viewport.canvas_transform = Transform2D(0.0, Vector2(scale, scale), 0.0, Vector2.ZERO)
	for i: int in 4:
		await process_frame
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	await process_frame
	return image


func _compare(image: Image, path: String) -> int:
	var reference := Image.load_from_file(ProjectSettings.globalize_path(path))
	if reference == null or reference.get_size() != image.get_size():
		return 255
	reference.convert(image.get_format())
	var a := image.get_data()
	var b := reference.get_data()
	var worst := 0
	for i: int in a.size():
		worst = maxi(worst, absi(a[i] - b[i]))
	return worst
