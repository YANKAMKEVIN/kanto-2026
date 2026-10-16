extends RefCounted
## Boîte à outils des cartes de **grotte** peintes (jalon 12 T7, docs/tech/jalon-12.md §2.1,
## §2.2, §2.4) : `tools/build_mt_moon.gd` (T9) s'en sert pour les trois étages du Mont Sélénite.
## Même méthode que `tools/pewter_map_kit.gd` (deux passes masque / scène, grille lue telle
## quelle, graines fixes) ; ce qui change pour une grotte :
## - **source logique `Ground`** (invisible), un caractère par case : `.` `j` `E` `U` `V` → sol
##   calme (praticable, aucune donnée), `g` → gravats (`OverworldTiles.Kind.RUBBLE`, donnée
##   `rubble`, lue par le moteur au T20), tout le reste → solide ;
## - **sol peint** à trois textures ([member PaintedGround.base_texture] = sol calme, canal R =
##   gravats, canal G = dessus des masses `#`), bande de frontière ardoise au lieu de la terre ;
## - **échelles** : `WarpPoint` `STEP_ON` sans direction (« escalier », aucun code nouveau), vers
##   le point d'apparition de même `paire=` sur l'autre étage, arrivée tournée à l'opposé de
##   l'échelle ([method ladder_links], [method arrival_facing]) ;
## - **halos** [LightGlow] (lampes, puits de jour, éclats, projecteurs) dans `Glows`, au plus
##   `LightGlowLibrary.MAX_PER_MAP` par carte ([method add_glow]) ;
## - racine `GameMap` **extérieure** (`interior = false`) : la catégorie « grotte » est dans
##   `data/world/caves.json`, jamais dans la scène (§2.3).
##
## **La grille fait foi** : toute case non praticable est solide dans `Ground` ; les emprises des
## objets peints ne tombent jamais sur une case praticable ([method add_prop_at] : erreur sinon).
## Les textures de la série 14 (T6) doivent exister avant la construction ([method add_ground]
## échoue sinon, l'erreur dit laquelle manque).
##
## Utilisé par `load("res://tools/cave_map_kit.gd").new(...)` (les outils ne lisent pas les
## `class_name` du jeu ; ce script non plus : tout passe par `load()` et `call()`).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const PROPS: String = "res://game/world/props/painted/"
const TILE: int = 96
const PUSH: int = 1
const STEP_ON: int = 0
## `WorldLighting.Z_GROUND_DECALS`.
const Z_DECALS: int = -1
## Cases praticables des grilles de grotte (ligne `PRATICABLES` des plans du Mont Sélénite).
const WALKABLE: String = ".gjUVE"
## Cases praticables des grilles de la **Grotte Sombre** (J18 T11) : celles du Mont Sélénite plus
## `e`, la sortie sud vers la Route 10 (bord de carte, praticable comme `E`). `WALKABLE` ne change
## pas : les grilles du Mont Sélénite déclarent toujours `.gjUVE` ; la Grotte Sombre passe
## [constant DARK_CAVE_WALKABLE] au constructeur.
const DARK_CAVE_WALKABLE: String = ".gjUVEe"
const RUBBLE_MARK: String = "g"
const MASS_MARK: String = "#"
## Cases de **paroi** (T9) : la masse `#` et les éclats `*` incrustés dans la roche (texture de
## la masse sous eux, faces et bords posés autour). Les autres repères bloqués (`K` `o` `L` `R`
## `F` `S` `w` `x`) sont posés sur le sol de la galerie : les parois se dessinent autour d'eux.
const WALL_MARKS: String = "#*"
## Modules de paroi de la série 14 (fiche `serie-14-mont-selenite.md`) : faces (bord sud d'une
## masse, 3 × 2 avec la bande du dessus), bord latéral (1 × 3), lèvre nord (3 × 1).
const WALL_FACES: Array[String] = ["relief_paroi_grotte_01", "relief_paroi_grotte_02"]
const WALL_SIDE: String = "relief_paroi_grotte_05"
const WALL_LIP: String = "relief_paroi_grotte_06"
## Largeur d'un module de face ou de lèvre (cases) ; hauteur d'un tronçon de bord latéral.
const WALL_SPAN: int = 3
## Face d'une paroi d'une seule case d'épaisseur (galerie au nord et au sud) : on ne garde que
## le bas du module (pixels), la bande du dessus déborderait sur la galerie du nord.
const THIN_FACE_HEIGHT: int = 104
## Tranches du bord latéral.
const SIDE_TOP: int = 0
const SIDE_MIDDLE: int = 1
const SIDE_BOTTOM: int = 2
## Variation de valeur des modules (± part), graine de la carte.
const WALL_VALUE_JITTER: float = 0.04
## Sols de la grotte (série 14, T6) : sol calme (fond), gravats (canal R), masse rocheuse
## (canal G). Même taille pour les trois (uniform `texture_size` du shader).
const FLOOR_TEXTURE: String = "res://assets/world/ground/ground_grotte_01.png"
const RUBBLE_TEXTURE: String = "res://assets/world/ground/ground_gravats_01.png"
const MASS_TEXTURE: String = "res://assets/world/ground/ground_masse_roche_01.png"
## Frontière bruitée entre deux sols : ardoise sombre au lieu de la terre des cartes
## extérieures [D, T7 ; à régler sur capture au T9].
const BORDER_COLOR: Color = Color(0.20, 0.22, 0.27)
## Densité des gravats et de la masse : celle du sol calme (les pavés extérieurs sont à 0,7).
const LAYER_SCALE: float = 1.0
## Voile de pénombre : pixels par case de son image, matériau (multiplication).
const SHADE_PX_PER_CELL: int = 8
const SHADE_MATERIAL: String = "res://game/world/lighting/materials/cave_shade.tres"
## Lumière ajoutée au sol autour des sources (addition, sous `Entities`).
const FLOOR_LIGHT_MATERIAL: String = "res://game/world/lighting/materials/cave_floor_light.tres"
## Grilles des cartes reliées par les échelles du Mont Sélénite (carte → grille).
const PLANS: Dictionary[StringName, String] = {
	&"mt_moon_1f": "res://tools/plans/mont_selenite_1f.txt",
	&"mt_moon_b1f": "res://tools/plans/mont_selenite_b1f.txt",
	&"mt_moon_b2f": "res://tools/plans/mont_selenite_b2f.txt",
	&"route_4": "res://tools/plans/route_4_sas.txt",
	# Grotte Sombre (J18 T11) : échelles A et B (`ladder_links`).
	&"dark_cave_1f": "res://tools/plans/grotte_sombre_1f.txt",
	&"dark_cave_b1f": "res://tools/plans/grotte_sombre_b1f.txt",
}

var plan: Object
var size: Vector2i
var root: Node2D
var entities: Node2D
var decals: Node2D
var glows: Node2D
var rules: GDScript
var tiles: GDScript
var rng := RandomNumberGenerator.new()
var decor_rng := RandomNumberGenerator.new()
## Cases par nature (Vector2i → vrai), dans l'ordre des rangées.
var floor_cells: Dictionary = {}
var rubble_cells: Dictionary = {}
var mass_cells: Dictionary = {}
## Erreurs de construction (grille, emprise sur une case praticable, texture absente, budget
## de halos…) : l'outil échoue s'il y en a.
var errors: PackedStringArray = []

## Réglages d'une carte **sans grotte** bâtie sur ce kit (souterrain du J15 T18) ; défauts = la
## grotte. Cases praticables, sols (base, canal R, canal G), couleur de la frontière bruitée, et
## nature du canal R : gravats logiques ([code]true[/code]) ou simple décor (traces, sol seul).
var walkable_marks: String = WALKABLE
var floor_texture_path: String = FLOOR_TEXTURE
var rubble_texture_path: String = RUBBLE_TEXTURE
var mass_texture_path: String = MASS_TEXTURE
var border_color: Color = BORDER_COLOR
## Parois (J18 T11, la Tour a ses murs `K` et ses modules `relief_mur_tour_*`, la Grotte Sombre ses
## modules propres) : caractères de masse, caractère qui reçoit un module, identifiants des modules
## (faces, bord latéral, lèvre). Défauts = ceux du Mont Sélénite : cartes existantes inchangées.
var wall_marks: String = WALL_MARKS
var mass_mark: String = MASS_MARK
var wall_faces: Array[String] = WALL_FACES.duplicate()
var wall_side: String = WALL_SIDE
var wall_lip: String = WALL_LIP
var rubble_mark: String = RUBBLE_MARK
var rubble_is_logic: bool = true
## Modules de paroi (faces, bord latéral, lèvre) : ceux de la série 14 par défaut ; la Cave
## Taupiqueur (série 19, J17 T15) pose les parois de grès.
var wall_faces: Array[String] = WALL_FACES.duplicate()
var wall_side: String = WALL_SIDE
var wall_lip: String = WALL_LIP

## Halos posés ([method add_glow]) : { "type": StringName, "center": Vector2 } (voile, [method
## add_shade]).
var glow_sources: Array[Dictionary] = []
## Voile de pénombre calculé ([method add_shade]), null avant.
var shade: Object

var _scenes: Dictionary = {}
var _glow_count: int = 0


## Lit la grille [param plan_path] ; [member errors] non vide si elle est illisible, n'a pas la
## taille [param map_size] ou n'a pas les praticables d'une grotte ([constant WALKABLE]).
func _init(plan_path: String, map_size: Vector2i, seed_value: int, decor_seed: int,
		walkable_chars: String = WALKABLE) -> void:
	walkable_marks = walkable_chars
	size = map_size
	plan = PlanGrid.new()
	if not plan.call(&"load_file", plan_path):
		errors.append("grille illisible : %s" % plan.get(&"error"))
		return
	if plan.get(&"walkable") != walkable_marks:
		errors.append("praticables « %s » au lieu de « %s »" % [plan.get(&"walkable"),
			walkable_marks])
	if Vector2i(plan.get(&"width"), plan.get(&"height")) != size:
		errors.append("la grille n'est pas de %s cases" % size)
	tiles = load("res://game/world/overworld_tiles.gd")
	rules = load("res://game/world/props/painted_prop_rules.gd")
	rng.seed = seed_value
	decor_rng.seed = decor_seed


## Racine `GameMap` (métadonnées, **extérieure**), couches logiques invisibles (`Ground` rempli
## d'après la grille).
func make_root(node_name: String, map_id: StringName, display_name: String,
		light_profile: StringName) -> Node2D:
	root = Node2D.new()
	root.name = node_name
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", map_id)
	root.set(&"display_name", display_name)
	root.set(&"region", "")
	root.set(&"size", size)
	root.set(&"interior", false)
	root.set(&"light_profile", light_profile)
	var tileset: TileSet = load(tiles.TILESET_PATH)
	var ground := _add_layer("Ground", tileset)
	_add_layer("Detail", tileset)
	_add_layer("Obstacles", tileset)
	_paint_logic(ground)
	return root


## Image du masque du sol peint : R = gravats, G = masse rocheuse, le reste = sol calme.
func build_mask() -> Image:
	var script := load("res://game/world/ground/ground_mask.gd") as GDScript
	return script.call(&"build", size, rubble_cells, mass_cells)


## Sol peint (masque écrit en [param mask_path]), décalcomanies, `Entities`, `Glows`, couche
## haute, groupes. Faux tant que le masque n'est pas importé (relancer l'outil après
## `--import`) ou si une texture de la grotte manque ([member errors]).
func add_ground(mask_path: String) -> bool:
	for path: String in [floor_texture_path, rubble_texture_path, mass_texture_path]:
		if not ResourceLoader.exists(path):
			errors.append("texture de grotte absente (série 14, T6) : %s" % path)
	if not errors.is_empty():
		return false
	var image := build_mask()
	var absolute := ProjectSettings.globalize_path(mask_path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var before := PackedByteArray()
	if FileAccess.file_exists(absolute):
		var old := Image.load_from_file(absolute)
		if old != null:
			old.convert(image.get_format())
			before = old.get_data()
	if before != image.get_data():
		image.save_png(absolute)
		if ResourceLoader.exists(mask_path):
			return false
	if not ResourceLoader.exists(mask_path):
		return false
	var floor_texture: Texture2D = load(floor_texture_path)
	var painted := Node2D.new()
	painted.set_script(load("res://game/world/ground/painted_ground.gd"))
	painted.name = "PaintedGround"
	painted.set(&"size", size)
	painted.set(&"mask", load(mask_path))
	painted.set(&"base_texture", floor_texture)
	painted.set(&"r_texture", load(rubble_texture_path))
	painted.set(&"g_texture", load(mass_texture_path))
	var material := painted.call(&"get_shader_material") as ShaderMaterial
	material.set_shader_parameter(&"texture_size", float(floor_texture.get_width()))
	material.set_shader_parameter(&"paving_scale", LAYER_SCALE)
	material.set_shader_parameter(&"path_scale", LAYER_SCALE)
	material.set_shader_parameter(&"earth_color", border_color)
	attach(root, painted)
	decals = Node2D.new()
	decals.name = "GroundDecals"
	decals.z_index = Z_DECALS
	attach(root, decals)
	entities = Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	attach(root, entities)
	entities.unique_name_in_owner = true
	glows = Node2D.new()
	glows.name = "Glows"
	attach(root, glows)
	var overhead := _add_layer("Overhead", load(tiles.TILESET_PATH))
	overhead.z_index = 10
	for layer: Node in root.get_children():
		if layer is TileMapLayer:
			(layer as TileMapLayer).visible = false
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		attach(root, node)
	return true


# --- Plan logique -------------------------------------------------------------------------


## Type de tuile logique d'un caractère de la grille.
func kind_of(mark: String) -> int:
	if rubble_is_logic and mark == rubble_mark:
		return tiles.Kind.RUBBLE
	if walkable_marks.contains(mark):
		return tiles.Kind.DIRT
	return tiles.Kind.CLIFF


## Une case de `Ground` par caractère de la grille ; classe les cases (sol calme, gravats,
## masse rocheuse) dans l'ordre des rangées.
func _paint_logic(layer: TileMapLayer) -> void:
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var mark: String = plan.call(&"at", cell)
			var kind := kind_of(mark)
			var variant := rng.randi_range(0, tiles.variant_count(kind) - 1)
			layer.set_cell(cell, tiles.SOURCE_ID, tiles.atlas_coords(kind, variant))
			if mark == rubble_mark:
				rubble_cells[cell] = true
			elif wall_marks.contains(mark) or is_embedded(cell):
				mass_cells[cell] = true
			elif walkable_marks.contains(mark):
				floor_cells[cell] = true


func is_walkable(cell: Vector2i) -> bool:
	return plan.call(&"is_walkable", cell)


# --- Points d'apparition, passages, échelles ----------------------------------------------


## Noms des points d'apparition de la position [param id] de la grille, une par case (§1.3 n° 2) :
## une case → l'identifiant ; deux ou trois cases en ligne → suffixes `_w / _e`, `_w / _c / _e`
## (horizontal) ou `_n / _s`, `_n / _c / _s` (vertical) ; au-delà → `_0`, `_1`… Nom → case.
static func spawn_names(id: String, cells: Array[Vector2i]) -> Dictionary:
	var named: Dictionary = {}
	if cells.size() == 1:
		named[id] = cells[0]
		return named
	var horizontal := true
	var vertical := true
	for cell: Vector2i in cells:
		horizontal = horizontal and cell.y == cells[0].y
		vertical = vertical and cell.x == cells[0].x
	var suffixes: Array = []
	if cells.size() == 2 and horizontal:
		suffixes = ["w", "e"]
	elif cells.size() == 3 and horizontal:
		suffixes = ["w", "c", "e"]
	elif cells.size() == 2 and vertical:
		suffixes = ["n", "s"]
	elif cells.size() == 3 and vertical:
		suffixes = ["n", "c", "s"]
	var sorted := cells.duplicate()
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	for i: int in sorted.size():
		var suffix: String = suffixes[i] if i < suffixes.size() else str(i)
		named["%s_%s" % [id, suffix]] = sorted[i]
	return named


## Orientation à l'arrivée par une échelle : à l'opposé de l'échelle (case du point
## d'apparition − case de l'échelle, axe dominant) ; bas si elles se confondent.
static func arrival_facing(spawn_cell: Vector2i, ladder_cell: Vector2i) -> Vector2i:
	var delta := spawn_cell - ladder_cell
	if delta == Vector2i.ZERO:
		return Vector2i.DOWN
	if absi(delta.x) > absi(delta.y):
		return Vector2i(signi(delta.x), 0)
	return Vector2i(0, signi(delta.y))


## Échelles de la grille et leur destination : une entrée par position `echelle` (ordre du
## fichier) : { "id", "cell", "pair", "target_map" (attribut `vers=`), "target_spawn" (point
## d'apparition de même `paire=` dans la grille de la carte cible, [constant PLANS] ou
## [param plans]), "facing" (orientation à l'arrivée, [method arrival_facing] sur la carte
## cible) }. Une paire introuvable est une erreur ([member errors]).
func ladder_links(plans: Dictionary = PLANS) -> Array[Dictionary]:
	var links: Array[Dictionary] = []
	var positions: Dictionary = plan.get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] != "echelle":
			continue
		var pair: String = plan.call(&"attr", id, "paire")
		var target := StringName(plan.call(&"attr", id, "vers"))
		var link := {"id": id, "cell": plan.call(&"cell_of", id), "pair": pair,
			"target_map": target, "target_spawn": &"", "facing": Vector2i.DOWN}
		var other := _plan_of(target, plans)
		if other == null:
			errors.append("échelle %s : grille de « %s » inconnue" % [id, target])
			links.append(link)
			continue
		var spawn_id := _position_with_pair(other, "spawn", pair)
		var ladder_id := _position_with_pair(other, "echelle", pair)
		if spawn_id.is_empty() or ladder_id.is_empty():
			errors.append("échelle %s : paire %s absente de « %s »" % [id, pair, target])
		else:
			link["target_spawn"] = StringName(spawn_id)
			link["facing"] = arrival_facing(other.call(&"cell_of", spawn_id),
				other.call(&"cell_of", ladder_id))
		links.append(link)
	return links


func add_spawn(spawn_name: String, cell: Vector2i) -> void:
	var marker := Marker2D.new()
	marker.name = spawn_name
	marker.position = world(cell)
	attach(root.get_node(^"Spawns"), marker)


## Passage : [param coming_soon] non vide = destination « à venir » (build de développement),
## retour sur [param target_spawn] de cette carte.
func add_warp(node_name: String, cell: Vector2i, trigger: int, direction: Vector2i,
		target_map: StringName, target_spawn: StringName, arrival_facing_value: Vector2i,
		coming_soon: String = "") -> Node2D:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = node_name
	point.position = world(cell)
	point.set(&"trigger", trigger)
	point.set(&"direction", direction)
	point.set(&"target_map", target_map if coming_soon.is_empty() else &"")
	point.set(&"target_spawn", target_spawn)
	point.set(&"arrival_facing", arrival_facing_value)
	point.set(&"coming_soon", coming_soon)
	attach(root.get_node(^"Warps"), point)
	return point


## Échelle : passage `STEP_ON` **sans direction** (escalier, fondu comme une porte) vers
## [member ladder_links] (`target_map`, `target_spawn`, `facing`).
func add_ladder(node_name: String, link: Dictionary) -> Node2D:
	return add_warp(node_name, link["cell"], STEP_ON, Vector2i.ZERO, link["target_map"],
		link["target_spawn"], link["facing"])


func add_interactable(node_name: String, anchor: Vector2i, cells: Vector2i, facing: Vector2i,
		dialogue: StringName) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = node_name
	point.position = world(anchor)
	point.set(&"size", cells)
	point.set(&"facing", facing)
	point.set(&"dialogue_id", dialogue)
	attach(root.get_node(^"Interactables"), point)


func add_trigger(node_name: String, anchor: Vector2i, cells: Vector2i, direction: Vector2i,
		cutscene: StringName) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/triggers/event_trigger_point.gd"))
	point.name = node_name
	point.position = world(anchor)
	point.set(&"size", cells)
	point.set(&"direction", direction)
	point.set(&"cutscene_id", cutscene)
	attach(root.get_node(^"Triggers"), point)


# --- Halos --------------------------------------------------------------------------------


## Halo [param glow_type] (`data/world/light_glows.json`) centré sur [param center] (pixels du
## monde). Au-delà de `LightGlowLibrary.MAX_PER_MAP` halos : erreur (budget du §2.4).
func add_glow(glow_type: StringName, center: Vector2, node_name: String = "") -> Node2D:
	var library: Object = load("res://game/world/lighting/light_glow.gd").call(&"library")
	if not library.call(&"has_type", glow_type):
		errors.append("halo : type inconnu « %s »" % glow_type)
	var limit: int = load("res://game/world/lighting/light_glow_library.gd").MAX_PER_MAP
	_glow_count += 1
	if _glow_count > limit:
		errors.append("halos : %d sur la carte (au plus %d)" % [_glow_count, limit])
	var glow := Sprite2D.new()
	glow.set_script(load("res://game/world/lighting/light_glow.gd"))
	glow.name = node_name if not node_name.is_empty() else "Glow%02d" % (_glow_count - 1)
	glow.set(&"glow_type", glow_type)
	glow.position = center.round()
	attach(glows, glow)
	glow_sources.append({"type": glow_type, "center": glow.position})
	return glow


## Source de lumière **du voile seul** (aucun halo, hors budget) : la pénombre se lève autour
## de [param center] selon le type [param source_type] des réglages de [method add_shade].
func add_shade_source(source_type: StringName, center: Vector2) -> void:
	glow_sources.append({"type": source_type, "center": center.round()})


## Centre (pixels du monde) de la case [param cell].
func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)


func glow_count() -> int:
	return _glow_count


# --- Voile de pénombre (passe « lumière rare ») --------------------------------------------


## Voile de pénombre (`tools/cave_shade.gd`) : image écrite en [param shade_path] (comme le
## masque : faux tant qu'elle n'est pas importée, relancer l'outil après `--import`), posée en
## multiplication juste au-dessus de `GroundDecals` (même `z`, après lui), sous `Entities`.
## [param params] : réglages de l'étage (`CaveShade.PARAM_KEYS`) ; [param lights] : type de
## halo → { "radius" (cases), "strength", "offset" (Vector2, pixels : du centre du halo au
## centre de la flaque au sol) } ; les halos d'un type absent n'éclairent pas le sol. Les
## modules de paroi (faces, bords, lèvres) prennent une part [param wall_follow] de la valeur du
## sol devant eux (une lampe éclaire aussi sa paroi, la pénombre l'assombrit).
func add_shade(shade_path: String, params: Dictionary, lights: Dictionary,
		wall_follow: float) -> bool:
	var shade_script: GDScript = load("res://tools/cave_shade.gd")
	for message: String in shade_script.call(&"check_params", params):
		errors.append(message)
	if not errors.is_empty():
		return false
	var open: Dictionary = {}
	for y: int in size.y:
		for x: int in size.x:
			if not mass_cells.has(Vector2i(x, y)):
				open[Vector2i(x, y)] = true
	shade = shade_script.new(size, open, params, SHADE_PX_PER_CELL)
	var sources: Array = []
	for glow: Dictionary in glow_sources:
		if not lights.has(glow["type"]):
			continue
		var light: Dictionary = lights[glow["type"]]
		sources.append({"center": (glow["center"] as Vector2) + (light["offset"] as Vector2),
			"radius": float(light["radius"]) * TILE, "strength": float(light["strength"]),
			"add": float(light.get("add", 0.0)), "color": light.get("color", Color.WHITE)})
	shade.call(&"compute", sources)
	var light_path := shade_path.replace("_shade.png", "_floor_light.png")
	var shade_ready := _write_png(shade.call(&"to_image"), shade_path)
	var light_ready := _write_png(shade.call(&"glow_image"), light_path)
	if not shade_ready or not light_ready:
		return false
	var at := decals.get_index() + 1
	for entry: Array in [["CaveShade", shade_path, SHADE_MATERIAL],
			["CaveFloorLight", light_path, FLOOR_LIGHT_MATERIAL]]:
		var sprite := Sprite2D.new()
		sprite.name = entry[0]
		sprite.texture = load(entry[1])
		sprite.centered = false
		sprite.scale = Vector2.ONE * (float(TILE) / SHADE_PX_PER_CELL)
		sprite.z_index = Z_DECALS
		sprite.material = load(entry[2])
		attach(root, sprite)
		root.move_child(sprite, at)
		at += 1
	_shade_walls(wall_follow)
	return true


## Les modules de paroi suivent la lumière du sol devant eux (part [param follow]) : faces (sol
## au sud), bords (meilleur des deux côtés), lèvres (sol au nord).
func _shade_walls(follow: float) -> void:
	for parent: Node in [entities, decals]:
		for child: Node in parent.get_children():
			var sprite := child as Sprite2D
			if sprite == null:
				continue
			var label := String(sprite.name)
			var rect := sprite.get_rect()
			var foot := sprite.position + Vector2(rect.position.x + rect.size.x / 2.0,
				rect.end.y)
			var value := 1.0
			if label.begins_with("Face"):
				value = shade.call(&"sample", foot + Vector2(0.0, TILE * 0.5))
			elif label.begins_with("Side"):
				var middle := foot - Vector2(0.0, TILE * 0.5)
				value = maxf(shade.call(&"sample", middle + Vector2(TILE, 0.0)),
					shade.call(&"sample", middle - Vector2(TILE, 0.0)))
			elif label.begins_with("Lip"):
				value = shade.call(&"sample", foot - Vector2(0.0, rect.size.y + TILE * 0.5))
			else:
				continue
			var k := lerpf(1.0, value, follow)
			sprite.modulate = Color(sprite.modulate.r * k, sprite.modulate.g * k,
				sprite.modulate.b * k)


## Écrit [param image] en PNG si elle a changé ; vrai si la ressource importée est à jour.
func _write_png(image: Image, path: String) -> bool:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var before := PackedByteArray()
	if FileAccess.file_exists(absolute):
		var old := Image.load_from_file(absolute)
		if old != null:
			old.convert(image.get_format())
			before = old.get_data()
	if before != image.get_data():
		image.save_png(absolute)
		return false
	return ResourceLoader.exists(path)


# --- Objets peints ------------------------------------------------------------------------


func scene(id: String) -> PackedScene:
	if not _scenes.has(id):
		_scenes[id] = load(PROPS + id + ".tscn")
	return _scenes[id]


## Objet peint au pied [param foot] (pixels).
func add_prop(parent: Node, id: String, foot: Vector2, node_name: String) -> Node2D:
	var prop := scene(id).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	prop.position = foot.round()
	attach(parent, prop)
	return prop


## Objet peint ancré sur la case [param cell] (`PaintedPropRules.foot_position`) ; son emprise
## doit tomber sur des cases non praticables de la grille (ou des positions `bloque`).
func add_prop_at(parent: Node, id: String, cell: Vector2i, node_name: String) -> Node2D:
	var foot: Vector2 = rules.call(&"foot_position", StringName(id), cell)
	var blocking: Array = plan.call(&"blocking_cells")
	for offset: Vector2i in rules.call(&"footprint", StringName(id)):
		if is_walkable(cell + offset) and not blocking.has(cell + offset):
			errors.append("%s (%s) : emprise sur la case praticable %s" % [node_name, id,
				cell + offset])
	return add_prop(parent, id, foot, node_name)


## `Sprite2D` seul (un nœud, pas une instance) à l'image et au matériau de l'objet peint
## [param id], pied en [param foot] : ses réglages propres (découpe, miroir, décalage) sont
## enregistrés avec la carte (ceux d'un enfant d'instance seraient perdus).
func add_sprite(parent: Node, id: String, foot: Vector2, node_name: String) -> Sprite2D:
	var model := scene(id).instantiate()
	var sprite := (model.get_node(^"Sprite") as Sprite2D).duplicate() as Sprite2D
	model.free()
	sprite.name = node_name
	sprite.unique_name_in_owner = false
	sprite.position = (foot + sprite.position).round()
	attach(parent, sprite)
	return sprite


## Décor posé **sur une case praticable** (échelle, puits de jour) : sans emprise, la case
## reste praticable (couche du sol, sous les personnages).
func add_floor_prop(id: String, cell: Vector2i, node_name: String) -> Node2D:
	var prop := add_prop(decals, id, rules.call(&"foot_position", StringName(id), cell),
		node_name)
	prop.set(&"footprint", [] as Array[Vector2i])
	return prop


# --- Parois (T9) --------------------------------------------------------------------------


## Vrai si [param cell] est de la paroi ([constant WALL_MARKS]) ou un repère **pris dans la
## paroi** ([method is_embedded]) ; hors de la carte = paroi.
func is_wall(cell: Vector2i) -> bool:
	if not _in_bounds(cell):
		return true
	return is_mass(cell) or is_embedded(cell)


## Masse rocheuse (`#`, éclats `*`) : la seule paroi qui reçoit des modules.
func is_mass(cell: Vector2i) -> bool:
	return not _in_bounds(cell) or wall_marks.contains(plan.call(&"at", cell))


## Repère bloqué (lampe, indice, caisse…) **pris dans la paroi** : masse au nord et au sud, ou à
## l'est et à l'ouest (lampes du couloir du gardien, indices au fond d'une niche). Compté comme
## paroi pour dessiner les bords autour de lui, sans module sur sa case (le repère s'y voit).
func is_embedded(cell: Vector2i) -> bool:
	if not _in_bounds(cell):
		return false
	var mark: String = plan.call(&"at", cell)
	if walkable_marks.contains(mark) or wall_marks.contains(mark):
		return false
	return (is_mass(cell + Vector2i.UP) and is_mass(cell + Vector2i.DOWN)) \
		or (is_mass(cell + Vector2i.LEFT) and is_mass(cell + Vector2i.RIGHT))


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


## Case de **face** : masse (`#`) dont la voisine sud est une galerie (bord sud d'une masse).
func is_face_cell(cell: Vector2i) -> bool:
	return _takes_module(cell) and not is_wall(cell + Vector2i.DOWN)


## Case de **bord latéral** : masse (pas une face) dont une voisine est ou ouest est une galerie.
func is_side_cell(cell: Vector2i) -> bool:
	return _takes_module(cell) and not is_face_cell(cell) \
		and (not is_wall(cell + Vector2i.LEFT) or not is_wall(cell + Vector2i.RIGHT))


## Case de **lèvre** : masse (pas une face) dont la voisine nord est une galerie.
func is_lip_cell(cell: Vector2i) -> bool:
	return _takes_module(cell) and not is_face_cell(cell) and not is_wall(cell + Vector2i.UP)


## Seules les cases `#` reçoivent un module : les éclats `*` et les repères pris dans la paroi
## laissent une niche (masse peinte) où leur objet se voit.
func _takes_module(cell: Vector2i) -> bool:
	return _in_bounds(cell) and plan.call(&"at", cell) == mass_mark


## Parois en modules d'après la grille (fiche de la série 14) : une **face** sur chaque case de
## paroi au-dessus d'une galerie (débord d'une case vers le haut sur la masse, coupé si la paroi
## n'a qu'une case d'épaisseur), un **bord latéral** le long des galeries à l'est et à l'ouest,
## une **lèvre** au bord nord des masses. Faces et bords dans `Entities` (triés aux pieds : une
## face passe devant un personnage au nord d'elle), lèvres dans la couche du sol. Un module ne
## couvre jamais une case de galerie (découpé par `region_rect` aux bouts des étendues).
## Renvoie (faces, bords, lèvres).
func place_walls(seed_value: int) -> Vector3i:
	var wall_rng := RandomNumberGenerator.new()
	wall_rng.seed = seed_value
	var faces := 0
	var lips := 0
	for y: int in size.y:
		for run: Vector2i in _row_runs(y, is_face_cell):
			for piece: Vector2i in _pieces(run):
				var tall := true
				for x: int in range(piece.x, piece.x + piece.y):
					tall = tall and _takes_module(Vector2i(x, y - 1))
				var id: String = wall_faces[wall_rng.randi_range(0, wall_faces.size() - 1)]
				var foot := Vector2((piece.x + piece.y / 2.0) * TILE, (y + 1) * TILE)
				var prop := _wall_module(entities, id, foot, piece.y * TILE,
					-1 if tall else THIN_FACE_HEIGHT, false, "Face%03d" % faces, wall_rng)
				prop.flip_h = wall_rng.randf() < 0.5
				faces += 1
		for run: Vector2i in _row_runs(y, is_lip_cell):
			for piece: Vector2i in _pieces(run):
				var model_height := _texture_of(wall_lip).get_height()
				var foot := Vector2((piece.x + piece.y / 2.0) * TILE, y * TILE + model_height)
				var prop := _wall_module(decals, wall_lip, foot, piece.y * TILE, -1, false,
					"Lip%03d" % lips, wall_rng)
				prop.flip_h = wall_rng.randf() < 0.5
				lips += 1
	# Bords latéraux : un module par case (tranche de l'image) : le haut de l'étendue garde le
	# chapeau du module, le bas son pied, les cases du milieu une tranche du milieu (bande
	# continue, sans « piliers empilés »).
	var sides := 0
	for x: int in size.x:
		for run: Vector2i in _column_runs(x, is_side_cell):
			for y: int in range(run.x, run.y + 1):
				var cell := Vector2i(x, y)
				var part := SIDE_MIDDLE
				if y == run.y:
					part = SIDE_BOTTOM
				elif y == run.x:
					part = SIDE_TOP
				var prop := _side_slice(cell, part, "Side%03d" % sides, wall_rng)
				var floor_left := not is_wall(cell + Vector2i.LEFT)
				var floor_right := not is_wall(cell + Vector2i.RIGHT)
				prop.flip_h = floor_left and not floor_right
				sides += 1
	return Vector3i(faces, sides, lips)


## Tranche d'une case du bord latéral sur [param cell] : [param part] = haut (chapeau), milieu
## ou bas (pied) de l'image.
func _side_slice(cell: Vector2i, part: int, node_name: String,
		wall_rng: RandomNumberGenerator) -> Sprite2D:
	var foot := Vector2((cell.x + 0.5) * TILE, (cell.y + 1) * TILE)
	var sprite := add_sprite(entities, wall_side, foot, node_name)
	var image_size := sprite.texture.get_size()
	var y0 := 0.0
	if part == SIDE_MIDDLE:
		y0 = floorf((image_size.y - TILE) / 2.0)
	elif part == SIDE_BOTTOM:
		y0 = image_size.y - TILE
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0.0, y0, image_size.x, TILE)
	sprite.offset = Vector2(-image_size.x / 2.0, -TILE)
	var value := 1.0 + wall_rng.randf_range(-WALL_VALUE_JITTER, WALL_VALUE_JITTER)
	sprite.modulate = Color(value, value, value)
	return sprite


## Module de paroi au pied [param foot] : [param width] pixels du milieu de l'image (toute
## l'image si elle n'est pas plus large), [param height] pixels du bas (−1 : toute la hauteur) ou
## du haut ([param from_top]).
func _wall_module(parent: Node, id: String, foot: Vector2, width: int, height: int,
		from_top: bool, node_name: String, wall_rng: RandomNumberGenerator) -> Sprite2D:
	var sprite := add_sprite(parent, id, foot, node_name)
	var image_size := sprite.texture.get_size()
	var w := minf(float(width), image_size.x)
	var h := image_size.y if height < 0 else minf(float(height), image_size.y)
	if w < image_size.x or h < image_size.y:
		sprite.region_enabled = true
		var y0 := 0.0 if from_top else image_size.y - h
		sprite.region_rect = Rect2((image_size.x - w) / 2.0, y0, w, h)
		sprite.offset = Vector2(-w / 2.0, -h)
	var value := 1.0 + wall_rng.randf_range(-WALL_VALUE_JITTER, WALL_VALUE_JITTER)
	sprite.modulate = Color(value, value, value)
	return sprite


func _texture_of(id: String) -> Texture2D:
	var model := scene(id).instantiate()
	var texture := (model.get_node(^"Sprite") as Sprite2D).texture
	model.free()
	return texture


## Étendues [début, fin] (colonnes incluses) de la rangée [param y] où [param test] est vrai.
func _row_runs(y: int, test: Callable) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var start := -1
	for x: int in size.x + 1:
		var inside := x < size.x and bool(test.call(Vector2i(x, y)))
		if inside and start < 0:
			start = x
		elif not inside and start >= 0:
			runs.append(Vector2i(start, x - 1))
			start = -1
	return runs


## Étendues [début, fin] (rangées incluses) de la colonne [param x] où [param test] est vrai.
func _column_runs(x: int, test: Callable) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var start := -1
	for y: int in size.y + 1:
		var inside := y < size.y and bool(test.call(Vector2i(x, y)))
		if inside and start < 0:
			start = y
		elif not inside and start >= 0:
			runs.append(Vector2i(start, y - 1))
			start = -1
	return runs


## Découpe d'une étendue en modules de [constant WALL_SPAN] cases : (début, largeur). Le dernier
## recouvre le précédent pour finir au bout ; une étendue plus courte = un module découpé.
func _pieces(run: Vector2i) -> Array[Vector2i]:
	var pieces: Array[Vector2i] = []
	var length := run.y - run.x + 1
	if length < WALL_SPAN:
		pieces.append(Vector2i(run.x, length))
		return pieces
	var left := run.x
	while left + WALL_SPAN <= run.y + 1:
		pieces.append(Vector2i(left, WALL_SPAN))
		left += WALL_SPAN
	if left <= run.y:
		pieces.append(Vector2i(run.y + 1 - WALL_SPAN, WALL_SPAN))
	return pieces


# --- Fin ----------------------------------------------------------------------------------


## Enregistre la scène ; libère tout. Renvoie le code d'erreur et le nombre de nœuds.
func save(out_path: String) -> Vector2i:
	var count := _count(root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, out_path)
	root.free()
	return Vector2i(err, count)


## Libère la racine sans l'enregistrer (masque à importer, erreur).
func discard() -> void:
	if root != null:
		root.free()
		root = null


## Pied (bas-centre) de la case [param cell], en pixels du monde.
func world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func attach(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


func _plan_of(map_id: StringName, plans: Dictionary) -> Object:
	if not plans.has(map_id):
		return null
	var other: Object = PlanGrid.new()
	if not other.call(&"load_file", plans[map_id]):
		return null
	return other


static func _position_with_pair(grid: Object, kind: String, pair: String) -> String:
	var positions: Dictionary = grid.get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] == kind and grid.call(&"attr", id, "paire") == pair:
			return id
	return ""


func _add_layer(layer_name: String, tileset: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tileset
	attach(root, layer)
	return layer


func _count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count(child)
	return total
