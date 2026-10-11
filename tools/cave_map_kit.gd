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
const RUBBLE_MARK: String = "g"
const MASS_MARK: String = "#"
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
## Grilles des cartes reliées par les échelles du Mont Sélénite (carte → grille).
const PLANS: Dictionary[StringName, String] = {
	&"mt_moon_1f": "res://tools/plans/mont_selenite_1f.txt",
	&"mt_moon_b1f": "res://tools/plans/mont_selenite_b1f.txt",
	&"mt_moon_b2f": "res://tools/plans/mont_selenite_b2f.txt",
	&"route_4": "res://tools/plans/route_4_sas.txt",
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

var _scenes: Dictionary = {}
var _glow_count: int = 0


## Lit la grille [param plan_path] ; [member errors] non vide si elle est illisible, n'a pas la
## taille [param map_size] ou n'a pas les praticables d'une grotte ([constant WALKABLE]).
func _init(plan_path: String, map_size: Vector2i, seed_value: int, decor_seed: int) -> void:
	size = map_size
	plan = PlanGrid.new()
	if not plan.call(&"load_file", plan_path):
		errors.append("grille illisible : %s" % plan.get(&"error"))
		return
	if plan.get(&"walkable") != WALKABLE:
		errors.append("praticables « %s » au lieu de « %s »" % [plan.get(&"walkable"), WALKABLE])
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
	for path: String in [FLOOR_TEXTURE, RUBBLE_TEXTURE, MASS_TEXTURE]:
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
	var floor_texture: Texture2D = load(FLOOR_TEXTURE)
	var painted := Node2D.new()
	painted.set_script(load("res://game/world/ground/painted_ground.gd"))
	painted.name = "PaintedGround"
	painted.set(&"size", size)
	painted.set(&"mask", load(mask_path))
	painted.set(&"base_texture", floor_texture)
	painted.set(&"r_texture", load(RUBBLE_TEXTURE))
	painted.set(&"g_texture", load(MASS_TEXTURE))
	var material := painted.call(&"get_shader_material") as ShaderMaterial
	material.set_shader_parameter(&"texture_size", float(floor_texture.get_width()))
	material.set_shader_parameter(&"paving_scale", LAYER_SCALE)
	material.set_shader_parameter(&"path_scale", LAYER_SCALE)
	material.set_shader_parameter(&"earth_color", BORDER_COLOR)
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
	if mark == RUBBLE_MARK:
		return tiles.Kind.RUBBLE
	if WALKABLE.contains(mark):
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
			if mark == RUBBLE_MARK:
				rubble_cells[cell] = true
			elif mark == MASS_MARK:
				mass_cells[cell] = true
			elif WALKABLE.contains(mark):
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
	return glow


## Centre (pixels du monde) de la case [param cell].
func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)


func glow_count() -> int:
	return _glow_count


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


## Décor posé **sur une case praticable** (échelle, puits de jour) : sans emprise, la case
## reste praticable (couche du sol, sous les personnages).
func add_floor_prop(id: String, cell: Vector2i, node_name: String) -> Node2D:
	var prop := add_prop(decals, id, rules.call(&"foot_position", StringName(id), cell),
		node_name)
	prop.set(&"footprint", [] as Array[Vector2i])
	return prop


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
