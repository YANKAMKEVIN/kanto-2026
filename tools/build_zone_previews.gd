extends SceneTree
## Aperçus des zones de la Carte du Menu Dresseur (MM.2, docs/tech/menu-maquettes.md) : une vue
## de la carte peinte **extérieure** de chaque zone qui en a une, recadrée en 16:9 puis
## légèrement **floutée** (réduction, flou en boîte, agrandissement : même méthode que les décors
## du Pokédex, tools/build_pokedex_scenes.gd), enregistrée en WebP dans
## assets/ui/map/zones/<zone>.webp. Aucune image générée : uniquement des captures du jeu.
## Une zone sans fichier garde, à l'écran, un recadrage de l'illustration de Kanto (MenuArt).
##
##   godot --path . --resolution 1600x900 -s res://tools/build_zone_previews.gd
##   (--raw : garde aussi la capture nette dans build/zones_raw/ pour choisir le cadrage ;
##    --only=<zone>)
## puis `godot --headless --path . --import`.

const OUT_DIR := "res://assets/ui/map/zones/"
const RAW_DIR := "build/zones_raw/"
## Taille enregistrée (16:9) : le panneau l'affiche au plus à ~900 px de large.
const OUT_SIZE := Vector2i(768, 432)
## Flou léger : on reconnaît le lieu, la capture 1:1 ne se voit pas (personnages, détails).
const BLUR_SIZE := Vector2i(384, 216)
const BLUR_RADIUS := 1
const BLUR_PASSES := 2
const QUALITY := 0.85

## Une vue : zone, carte, centre (pixels monde), zoom de la caméra.
const SHOTS: Array[Dictionary] = [
	{"zone": "pallet_town", "map": "res://game/world/maps/pallet_town.tscn",
		"at": Vector2(2300, 1500), "zoom": 0.62},
	{"zone": "route_1", "map": "res://game/world/maps/route_1.tscn",
		"at": Vector2(2300, 2300), "zoom": 0.62},
	{"zone": "viridian_city", "map": "res://game/world/maps/viridian_city.tscn",
		"at": Vector2(2700, 1500), "zoom": 0.62},
	{"zone": "route_22", "map": "res://game/world/maps/route_22.tscn",
		"at": Vector2(2300, 1300), "zoom": 0.62},
]

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
		if not _only.is_empty() and shot["zone"] != _only:
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
		_save(image, shot["zone"])
		camera.queue_free()
		map.queue_free()
		await process_frame
	quit()


func _save(image: Image, zone: String) -> void:
	image.convert(Image.FORMAT_RGB8)
	var w := image.get_width()
	var h := image.get_height()
	var crop_h := mini(h, w * OUT_SIZE.y / OUT_SIZE.x)
	var crop_w := crop_h * OUT_SIZE.x / OUT_SIZE.y
	var framed := image.get_region(Rect2i((w - crop_w) / 2, (h - crop_h) / 2, crop_w, crop_h))
	if _raw:
		framed.save_png(RAW_DIR + zone + ".png")
	framed.resize(BLUR_SIZE.x, BLUR_SIZE.y, Image.INTERPOLATE_LANCZOS)
	for _i: int in BLUR_PASSES:
		_box_blur(framed, BLUR_RADIUS)
	framed.resize(OUT_SIZE.x, OUT_SIZE.y, Image.INTERPOLATE_CUBIC)
	var path := ProjectSettings.globalize_path(OUT_DIR + zone + ".webp")
	framed.save_webp(path, true, QUALITY)
	print("aperçu : ", path)


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
