extends SceneTree
## Décors du portrait du Pokédex (refonte T4, essai de « décor du portrait ») : des vues des
## cartes peintes du jeu (et de la toile de fond du Plateau Indigo), recadrées puis **floutées**
## (réduction puis agrandissement), enregistrées en WebP dans assets/ui/pokedex/scenes/.
## Aucune image générée : uniquement des captures du jeu et des décors existants.
##
##   godot --path . --resolution 1600x1600 -s res://tools/build_pokedex_scenes.gd
##   (--raw : garde aussi la capture nette dans build/scenes_raw/ pour choisir le cadrage)
## puis `godot --headless --path . --import`.

const OUT_DIR := "res://assets/ui/pokedex/scenes/"
const RAW_DIR := "build/scenes_raw/"
## Côté de l'image enregistrée (floue : elle est agrandie à l'écran sans perte visible).
const OUT_SIDE := 512
## Le flou est calculé sur une image réduite (BLUR_SIDE, rapide), puis agrandie à OUT_SIDE :
## trois flous en boîte de BLUR_RADIUS ≈ un flou gaussien.
const BLUR_SIDE := 128
const BLUR_RADIUS := 2
const BLUR_PASSES := 3
const QUALITY := 0.85

## Une vue : carte, centre (pixels monde), zoom de la caméra, fichier.
const SHOTS: Array[Dictionary] = [
	{"map": "res://game/world/maps/viridian_city.tscn", "at": Vector2(1250, 1350),
		"zoom": 0.8, "file": "village"},
	{"map": "res://game/world/maps/route_22.tscn", "at": Vector2(2700, 1350),
		"zoom": 0.8, "file": "prairie"},
]
const BACKDROP := "res://assets/world/backdrops/backdrop_plateau_indigo_01.png"
## Région de la toile de fond gardée (le plateau, le lac et la forêt).
const BACKDROP_REGION := Rect2i(331, 150, 874, 874)

var _raw: bool = false
var _only: String = ""


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--raw":
			_raw = true
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	DirAccess.make_dir_recursive_absolute(RAW_DIR)
	for shot: Dictionary in SHOTS:
		if not _only.is_empty() and shot["file"] != _only:
			continue
		var map := (load(shot["map"]) as PackedScene).instantiate()
		root.add_child(map)
		var camera := Camera2D.new()
		camera.position = shot["at"]
		camera.zoom = Vector2.ONE * float(shot["zoom"])
		root.add_child(camera)
		camera.make_current()
		for _i: int in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		_save(image, shot["file"])
		camera.queue_free()
		map.queue_free()
		await process_frame
	if _only.is_empty() or _only == "plateau":
		var backdrop := Image.load_from_file(ProjectSettings.globalize_path(BACKDROP))
		_save(backdrop.get_region(BACKDROP_REGION), "plateau")
	quit()


func _save(image: Image, file: String) -> void:
	image.convert(Image.FORMAT_RGB8)
	var side := mini(image.get_width(), image.get_height())
	var square := image.get_region(Rect2i((image.get_width() - side) / 2,
		(image.get_height() - side) / 2, side, side))
	if _raw:
		square.save_png(RAW_DIR + file + ".png")
	square.resize(BLUR_SIDE, BLUR_SIDE, Image.INTERPOLATE_LANCZOS)
	for _i: int in BLUR_PASSES:
		_box_blur(square, BLUR_RADIUS)
	square.resize(OUT_SIDE, OUT_SIDE, Image.INTERPOLATE_CUBIC)
	var path := ProjectSettings.globalize_path(OUT_DIR + file + ".webp")
	square.save_webp(path, true, QUALITY)
	print("décor : ", path)


## Flou en boîte séparable (sommes glissantes), sur place.
func _box_blur(image: Image, radius: int) -> void:
	var w := image.get_width()
	var h := image.get_height()
	var data := image.get_data()
	var out := PackedByteArray()
	out.resize(data.size())
	for horizontal: bool in [true, false]:
		var lines := h if horizontal else w
		var length := w if horizontal else h
		for line: int in lines:
			for c: int in 3:
				var sum := 0
				var count := 0
				for k: int in range(0, mini(radius, length - 1) + 1):
					sum += data[_index(horizontal, line, k, w) + c]
					count += 1
				for i: int in length:
					out[_index(horizontal, line, i, w) + c] = int(round(float(sum) / count))
					var add := i + radius + 1
					if add < length:
						sum += data[_index(horizontal, line, add, w) + c]
						count += 1
					var drop := i - radius
					if drop >= 0:
						sum -= data[_index(horizontal, line, drop, w) + c]
						count -= 1
		data = out.duplicate()
	image.set_data(w, h, false, Image.FORMAT_RGB8, data)


func _index(horizontal: bool, line: int, i: int, width: int) -> int:
	return ((line * width + i) if horizontal else (i * width + line)) * 3
