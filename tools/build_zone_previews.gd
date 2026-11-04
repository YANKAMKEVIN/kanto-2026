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
##    --only=<zone> ; --all : en plus des vues réglées à la main de [constant SHOTS], toutes les
##    zones de data/world/zones.json qui ont une carte peinte, cadrées automatiquement sur le
##    centre de la couche Ground de leur carte, ou [constant AUTO_MAPS] / [constant AUTO_AT] ;
##    --keep : ne refait pas un aperçu déjà présent)
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

## Chantier « Menu Dresseur peint » (2026-11-01) : carte de la zone quand elle n'a pas de carte du
## même nom (ou quand la première est un Centre). [D] Cap d'Azuria = bout est de la Route 25.
const AUTO_MAPS: Dictionary[String, String] = {
	"mt_moon": "mt_moon_1f", "safari_zone": "safari_zone_center", "cerulean_cape": "route_25",
	"ss_anne": "ss_anne_outer_deck", "seafoam_islands": "seafoam_1f",
	"cerulean_cave": "cerulean_cave_1f", "dark_cave": "dark_cave_1f",
	# JOH1 : la grotte marine (salle 2, eau profonde) ; Oliville a sa propre carte.
	"sea_cave": "sea_cave_2",
	"burned_tower": "burned_tower_1f", "mahogany_hideout": "mahogany_hideout_b2f",
	"goldenrod_radio_tower": "goldenrod_radio_tower_5f",
	"slowpoke_well": "slowpoke_well_b2f",
	# JOH7 : les îles par leur B1F (lac et plate-forme de Suicune).
	"whirl_islands": "whirl_islands_b1f",
}
## Point visé, en fraction du rectangle de la couche Ground (0,5 ; 0,5 = centre), quand le centre
## tombe sur un lieu peu parlant [D].
const AUTO_AT: Dictionary[String, Vector2] = {
	"cerulean_cape": Vector2(0.8, 0.5),
}
## Point visé en pixels monde, pour une carte sans couche Ground ni image d'un seul tenant
## (pont extérieur du S.S. Anne, fait de modules) [D].
const AUTO_POS: Dictionary[String, Vector2] = {
	"ss_anne": Vector2(1000, 540),
}
## Zoom propre à une petite carte (le pont tient alors tout le cadre) [D].
const AUTO_ZOOMS: Dictionary[String, float] = {"ss_anne": 1.0}
const AUTO_ZOOM := 0.62
const ZONES_PATH := "res://data/world/zones.json"
const MAP_DIR := "res://game/world/maps/"
const CELL := 96.0

var _raw: bool = false
var _only: String = ""
var _all: bool = false
var _keep: bool = false


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--raw":
			_raw = true
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
		elif arg == "--all":
			_all = true
		elif arg == "--keep":
			_keep = true
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	DirAccess.make_dir_recursive_absolute(RAW_DIR)
	var shots: Array[Dictionary] = SHOTS.duplicate()
	if _all:
		shots.append_array(_auto_shots())
	for shot: Dictionary in shots:
		if not _only.is_empty() and shot["zone"] != _only:
			continue
		if _keep and FileAccess.file_exists(OUT_DIR + String(shot["zone"]) + ".webp"):
			continue
		var map := (load(shot["map"]) as PackedScene).instantiate()
		root.add_child(map)
		var at: Vector2 = shot.get("at", Vector2.ZERO)
		if shot.has("frac"):
			at = _point_of(map, shot["frac"])
		var camera := Camera2D.new()
		camera.position = at
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


## Vues automatiques : chaque zone de zones.json absente de [constant SHOTS] dont la carte existe.
func _auto_shots() -> Array[Dictionary]:
	var done: Array[String] = []
	for shot: Dictionary in SHOTS:
		done.append(String(shot["zone"]))
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ZONES_PATH))
	var zones: Dictionary = parsed["zones"] if parsed is Dictionary else {}
	var shots: Array[Dictionary] = []
	for zone: String in zones:
		if done.has(zone):
			continue
		var map_id: String = AUTO_MAPS.get(zone, zone)
		var path := MAP_DIR + map_id + ".tscn"
		if not ResourceLoader.exists(path):
			print("pas de carte peinte pour ", zone, " (", path, ")")
			continue
		if AUTO_POS.has(zone):
			shots.append({"zone": zone, "map": path, "at": AUTO_POS[zone],
				"zoom": AUTO_ZOOMS.get(zone, AUTO_ZOOM)})
		else:
			shots.append({"zone": zone, "map": path,
				"frac": AUTO_AT.get(zone, Vector2(0.5, 0.5)), "zoom": AUTO_ZOOM})
	return shots


## Point (pixels monde) à la fraction [param frac] du rectangle utilisé de la couche Ground.
func _point_of(map: Node, frac: Vector2) -> Vector2:
	var ground := map.get_node_or_null(^"Ground") as TileMapLayer
	if ground == null:
		for child: Node in map.get_children():
			if child is TileMapLayer:
				ground = child
				break
	if ground != null and ground.get_used_rect().has_area():
		var used := Rect2(ground.get_used_rect())
		return (used.position + used.size * frac) * CELL
	# Carte peinte d'un seul tenant (S.S. Anne : « Shell ») : le rectangle de la plus grande image.
	var best := Rect2()
	for child: Node in map.get_children():
		var sprite := child as Sprite2D
		if sprite != null and sprite.texture != null:
			var rect := sprite.get_rect()
			rect = Rect2(sprite.global_position + rect.position * sprite.scale,
				rect.size * sprite.scale)
			if rect.get_area() > best.get_area():
				best = rect
	return best.position + best.size * frac


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
