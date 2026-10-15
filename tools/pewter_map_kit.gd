extends RefCounted
## Boîte à outils commune aux deux cartes peintes du jalon 10 (T11, docs/tech/jalon-10.md §2.1) :
## `tools/build_route_2_north.gd` et `tools/build_pewter_city.gd`. Même méthode que
## `tools/build_route_2.gd` et `tools/build_viridian_forest.gd` (deux passes masque / scène, grille
## lue telle quelle, graines fixes) ; ce fichier ne fait que mettre en commun ce que les deux
## cartes partagent : source logique `Ground` (un caractère par case), masque du sol peint,
## sous-bois, passages, points d'examen, déclencheurs, objets peints, forêt serrée (dégagée autour
## des PNJ, cime réduite au-dessus des cases praticables, tri de visibilité, un `Sprite2D` par
## arbre), hautes herbes, paroi de montagne en modules, décalcomanies.
##
## **La grille fait foi** : toute case non praticable de la grille est solide dans `Ground`
## (forêt, paroi, bâtiments, rochers, buissons, bancs) ; les emprises des objets peints ne
## tombent jamais sur une case praticable ([method add_prop_at] le vérifie : erreur sinon).
##
## Utilisé par `load("res://tools/pewter_map_kit.gd").new(...)` (les outils ne lisent pas les
## `class_name` du jeu ; ce script non plus : tout passe par `load()` et `call()`).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const PROPS: String = "res://game/world/props/painted/"
const WIND_MATERIAL: String = "res://game/world/lighting/materials/world_object_wind.tres"
const TALL_GRASS_ID: String = "ground_hautes_herbes_jaune_01"
const GRASS_FRONT: String = "res://assets/world/ground/ground_hautes_herbes_jaune_01_bas.png"
const FLOWER_DECAL: String = "res://assets/world/ground/decals/decal_fleur_%d.png"
const TUFT_DECAL: String = "res://assets/world/ground/decals/decal_touffe_%d.png"
const TILE: int = 96
const PUSH: int = 1
const STEP_ON: int = 0
## `WorldLighting.Z_GROUND_DECALS`.
const Z_DECALS: int = -1
## Cases praticables des grilles du jalon 10 (`plan_grille.py` : `. = h v D p`).
const WALKABLE: String = ".=hvDp"

## Paroi de montagne (série 12, quatre modules d'≈ 5 × 3 cases, couche du sol) : faces au pied
## de la paroi, masse rocheuse au-dessus, pente aux extrémités qui touchent une case praticable.
const PAROI_FACES: Array[String] = ["relief_paroi_01", "relief_paroi_02"]
const PAROI_MASS: String = "relief_paroi_04"
const PAROI_SLOPE: String = "relief_paroi_03"
## Pas entre deux modules d'une rangée (cases ; les modules font ≈ 4,9–5,3 cases : ils se
## chevauchent d'≈ 1 case, consigne du T10) et entre deux rangées de modules (cases ; image de
## 3 cases : chevauchement d'une case).
const PAROI_STEP: int = 4
const PAROI_ROWS: int = 2
## Largeur d'un module pour le choix de sa position (cases).
const PAROI_WIDTH: int = 5
## Assombrissement des rangées hautes de la paroi (plus loin du sol, dans l'ombre des reliefs).
const PAROI_BACK_VALUE: float = 0.9

## Forêt serrée : dégagement autour des PNJ et des objets au sol, cime au-dessus d'une case
## praticable (voir `tools/build_route_2.gd`).
const NPC_TREE_CLEAR_X: float = 2.2
const NPC_TREE_CLEAR_Y: float = 3.0
const BALL_CLEAR_X: float = 0.9
const WALK_OVERLAP_MAX: float = 0.35
const TREE_HALF_WIDTH: float = 0.8
const MIN_FIT_SCALE: float = 0.8

var plan: Object
var size: Vector2i
var root: Node2D
var entities: Node2D
var decals: Node2D
var rules: GDScript
var tiles: GDScript
var forest_script: GDScript
var shade: Object
var rng := RandomNumberGenerator.new()
var decor_rng := RandomNumberGenerator.new()
## Cases par nature (Vector2i → vrai), dans l'ordre des rangées.
var forest_cells: Dictionary = {}
var path_cells: Dictionary = {}
var paved_cells: Dictionary = {}
var tall_grass_cells: Dictionary = {}
var cliff_cells: Dictionary = {}
## Erreurs de construction (emprise sur une case praticable…) : l'outil échoue s'il y en a.
var errors: PackedStringArray = []
## Réglages de la grille (jalon 12 T8, Route 3 et sas ; défauts = cartes du J10, inchangées) :
## cases praticables, caractères de paroi (modules [method place_paroi]), caractères peints au
## canal rouge du masque (sol rocheux `o` de la Route 3) — [method set_marks] avant
## [method make_root].
var walkable: String = WALKABLE
var cliff_marks: String = "K"
var rock_marks: String = ""
## Cases réservées aux PNJ, Pokémon et objets d'une carte dont le fichier de PNJ n'existe pas
## encore (positions `bloque` de la grille) : la forêt s'en écarte comme pour un PNJ ; objets au
## sol à part (buissons écartés).
var reserved_cells: Array[Vector2i] = []
var reserved_balls: Array[Vector2i] = []

var _scenes: Dictionary = {}
var _models: Dictionary = {}
var _tree_heights: Dictionary = {}
var _npcs_path: String = ""


## Lit la grille [param plan_path] (praticables [constant WALKABLE]) ; [member errors] non vide
## si elle est illisible ou n'a pas la taille [param map_size]. [param plan_variant] : variante
## de la grille (« J14 » : Azuria après le jalon 14), vide = la base.
func _init(plan_path: String, map_size: Vector2i, seed_value: int, decor_seed: int,
		plan_variant: String = "") -> void:
	size = map_size
	plan = PlanGrid.new()
	if not plan.call(&"load_file", plan_path, plan_variant):
		errors.append("grille illisible : %s" % plan.get(&"error"))
		return
	plan.set(&"walkable", walkable)
	if Vector2i(plan.get(&"width"), plan.get(&"height")) != size:
		errors.append("la grille n'est pas de %s cases" % size)
	tiles = load("res://game/world/overworld_tiles.gd")
	rules = load("res://game/world/props/painted_prop_rules.gd")
	forest_script = load("res://game/world/forest/dense_forest.gd")
	rng.seed = seed_value
	decor_rng.seed = decor_seed


## Règle les caractères de la grille (voir [member walkable], [member cliff_marks],
## [member rock_marks]).
func set_marks(walkable_marks: String, cliffs: String, rocks: String) -> void:
	walkable = walkable_marks
	cliff_marks = cliffs
	rock_marks = rocks
	plan.set(&"walkable", walkable)


## Racine `GameMap` (métadonnées), couches logiques invisibles (`Ground` rempli d'après la
## grille), groupes de données. [param npcs_path] : fichier des PNJ de la carte (cases dégagées
## de la forêt).
func make_root(node_name: String, map_id: StringName, display_name: String, region: String,
		light_profile: StringName, npcs_path: String) -> Node2D:
	_npcs_path = npcs_path
	root = Node2D.new()
	root.name = node_name
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", map_id)
	root.set(&"display_name", display_name)
	root.set(&"region", region)
	root.set(&"size", size)
	root.set(&"light_profile", light_profile)
	root.set(&"grass_front", load(GRASS_FRONT))
	var tileset: TileSet = load(tiles.TILESET_PATH)
	var ground := _add_layer("Ground", tileset)
	_add_layer("Detail", tileset)
	_add_layer("Obstacles", tileset)
	_paint_logic(ground)
	return root


## Sol peint (masque écrit en [param mask_path] : R = pavés, G = chemin, sentiers fermés et pied
## de paroi), sous-bois [param undergrowth] (case → valeur), décalcomanies, `Entities`, couche
## haute, groupes. Faux tant que le masque n'est pas importé (relancer l'outil après
## `--import`).
## [param mask_hook] (facultatif, `func(image: Image) -> void`) retouche le masque avant
## l'écriture (Route 3 : valeurs du sol rocheux variées pour casser la répétition).
func add_ground(mask_path: String, undergrowth: Dictionary,
		mask_hook: Callable = Callable()) -> bool:
	var script := load("res://game/world/ground/ground_mask.gd") as GDScript
	var image: Image = script.call(&"build", size, paved_cells, path_cells)
	if mask_hook.is_valid():
		mask_hook.call(image)
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
	add_ground_with(load(mask_path), undergrowth)
	return true


## Ce que fait [method add_ground] une fois le masque prêt : sol peint au masque [param mask]
## (fichier importé, ou image en mémoire pour une carte d'essai), sous-bois, décalcomanies,
## `Entities`, couche haute, groupes. Renvoie le sol peint.
func add_ground_with(mask: Texture2D, undergrowth: Dictionary) -> Node2D:
	var painted := Node2D.new()
	painted.set_script(load("res://game/world/ground/painted_ground.gd"))
	painted.name = "PaintedGround"
	painted.set(&"size", size)
	painted.set(&"mask", mask)
	attach(root, painted)
	var floor_script := load("res://game/world/ground/forest_floor.gd") as GDScript
	attach(root, floor_script.call(&"create", size, undergrowth) as Node)
	decals = Node2D.new()
	decals.name = "GroundDecals"
	decals.z_index = Z_DECALS
	attach(root, decals)
	entities = Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	attach(root, entities)
	entities.unique_name_in_owner = true
	var overhead := _add_layer("Overhead", load(tiles.TILESET_PATH))
	overhead.z_index = 10
	for layer: Node in root.get_children():
		if layer is TileMapLayer:
			(layer as TileMapLayer).visible = false
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		attach(root, node)
	return painted


## Sous-bois par défaut : forêt pleine, et sous la paroi (les jours entre les modules de rochers
## se lisent comme de la végétation, pas comme une bande de terre).
func forest_undergrowth() -> Dictionary:
	var values: Dictionary = {}
	for cell: Vector2i in forest_cells:
		values[cell] = 1.0
	for cell: Vector2i in cliff_cells:
		values[cell] = 1.0
	return values


# --- Plan logique -------------------------------------------------------------------------


func _kind_of(mark: String) -> int:
	if walkable.contains(mark):
		match mark:
			"=", "D", "Q":
				return tiles.Kind.DIRT
			"p":
				return tiles.Kind.COBBLE
			"h":
				return tiles.Kind.TALL_GRASS
			"v":
				return tiles.Kind.LEDGE_DOWN
		return tiles.Kind.GRASS
	if cliff_marks.contains(mark):
		return tiles.Kind.CLIFF
	return tiles.Kind.FOREST


## Une case de `Ground` par caractère de la grille ; classe les cases (forêt, chemin, pavés,
## hautes herbes, paroi) dans l'ordre des rangées.
func _paint_logic(layer: TileMapLayer) -> void:
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var mark: String = plan.call(&"at", cell)
			var kind := _kind_of(mark)
			var variant := rng.randi_range(0, tiles.variant_count(kind) - 1)
			layer.set_cell(cell, tiles.SOURCE_ID, tiles.atlas_coords(kind, variant))
			match mark:
				"T":
					forest_cells[cell] = true
				"h":
					tall_grass_cells[cell] = true
				"=", "D", "e", "Q":
					path_cells[cell] = true
				"p":
					paved_cells[cell] = true
			if cliff_marks.contains(mark):
				cliff_cells[cell] = true
			if not rock_marks.is_empty() and rock_marks.contains(mark):
				paved_cells[cell] = true
	# Un banc (`n`) posé sur la place garde les pavés sous lui (au moins trois voisines pavées).
	for cell: Vector2i in plan.call(&"cells_of", "n"):
		var paved := 0
		for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if plan.call(&"at", cell + side) == "p":
				paved += 1
		if paved >= 3:
			paved_cells[cell] = true


func is_walkable(cell: Vector2i) -> bool:
	return plan.call(&"is_walkable", cell)


# --- Données de carte ---------------------------------------------------------------------


func add_spawn(spawn_name: String, cell: Vector2i) -> void:
	var marker := Marker2D.new()
	marker.name = spawn_name
	marker.position = world(cell)
	attach(root.get_node(^"Spawns"), marker)


## Passage : [param coming_soon] non vide = destination « à venir » (build de développement),
## retour sur [param target_spawn] de cette carte.
func add_warp(node_name: String, cell: Vector2i, trigger: int, direction: Vector2i,
		target_map: StringName, target_spawn: StringName, arrival_facing: Vector2i,
		coming_soon: String = "") -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = node_name
	point.position = world(cell)
	point.set(&"trigger", trigger)
	point.set(&"direction", direction)
	point.set(&"target_map", target_map if coming_soon.is_empty() else &"")
	point.set(&"target_spawn", target_spawn)
	point.set(&"arrival_facing", arrival_facing)
	point.set(&"coming_soon", coming_soon)
	attach(root.get_node(^"Warps"), point)


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
## doit tomber sur des cases non praticables de la grille.
func add_prop_at(parent: Node, id: String, cell: Vector2i, node_name: String) -> Node2D:
	var foot: Vector2 = rules.call(&"foot_position", StringName(id), cell)
	for offset: Vector2i in rules.call(&"footprint", StringName(id)):
		if is_walkable(cell + offset) and not _is_blocking_position(cell + offset):
			errors.append("%s (%s) : emprise sur la case praticable %s" % [node_name, id,
				cell + offset])
	return add_prop(parent, id, foot, node_name)


## Vrai si [param cell] est une position `bloque` de la grille (panneau…).
func _is_blocking_position(cell: Vector2i) -> bool:
	return (plan.call(&"blocking_cells") as Array).has(cell)


## `Sprite2D` seul (un nœud) à l'image et au matériau de l'objet peint [param id].
func add_sprite(parent: Node, id: String, foot: Vector2, node_name: String) -> Sprite2D:
	if not _models.has(id):
		_models[id] = forest_script.call(&"painted_sprite_model", StringName(id))
	var sprite := (_models[id] as Sprite2D).duplicate() as Sprite2D
	sprite.name = node_name
	sprite.position = foot.round()
	attach(parent, sprite)
	return sprite


func flip(prop: Node2D, value: bool) -> void:
	var sprite := prop.get_node_or_null(^"Sprite") as Sprite2D
	if sprite != null:
		sprite.flip_h = value


## Sans emprise propre : les cases sont bloquées par la grille (objets réduits, décor posé sur
## une case de forêt ou de buisson).
func clear_footprint(prop: Node2D) -> void:
	prop.set(&"footprint", [] as Array[Vector2i])


func decal(parent: Node, texture: String, foot: Vector2, scale: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(texture)
	sprite.position = foot
	sprite.scale = Vector2.ONE * scale * decor_rng.randf_range(0.85, 1.15)
	sprite.flip_h = decor_rng.randf() < 0.5
	attach(parent, sprite)
	return sprite


# --- Décor du sol -------------------------------------------------------------------------


## Décalcomanies du bord des chemins et des pavés (terre, pavés déchaussés près des pavés,
## touffes), sauf sur la forêt et la paroi. [param keep] : part gardée (budget de nœuds).
func place_border_decals(seed_value: int, keep: float = 1.0) -> void:
	var script := load("res://game/world/ground/border_decals.gd") as GDScript
	var cells: Dictionary = paved_cells.duplicate()
	for cell: Vector2i in path_cells:
		cells[cell] = true
	var raw: Array = script.call(&"plan", cells, size, seed_value)
	var kept: Array[Dictionary] = []
	for entry: Dictionary in raw:
		var cell := Vector2i((entry["position"] as Vector2) / TILE)
		if _skips_border_decal(cell):
			continue
		if String(entry["texture"]).contains("decal_pave") \
				and (paved_cells.is_empty() or not rock_marks.is_empty()):
			continue
		if decor_rng.randf() >= keep:
			continue
		kept.append(entry)
	script.call(&"place", kept, decals, root)


## Vrai si aucune décalcomanie de bordure ne va sur [param cell] (forêt, paroi ; une boîte à
## outils dérivée en ajoute : eau et ponts, `tools/cerulean_map_kit.gd`).
func _skips_border_decal(cell: Vector2i) -> bool:
	return forest_cells.has(cell) or cliff_cells.has(cell)


## Touffes et fleurs sur l'herbe rase (`.`) : [param attempts] tirages, fleurs rares et
## seulement [param flowers] (« touches discrètes », dossier 12 §17).
func place_meadow(attempts: int, flower_chance: float, flowers: Array[int]) -> void:
	for attempt in attempts:
		var p := Vector2(decor_rng.randf_range(0.5, size.x - 0.5),
			decor_rng.randf_range(0.5, size.y - 0.5))
		if plan.call(&"at", Vector2i(p)) != ".":
			continue
		if decor_rng.randf() < flower_chance:
			var flower: int = flowers[decor_rng.randi_range(0, flowers.size() - 1)]
			decal(decals, FLOWER_DECAL % flower, p * TILE, 1.0)
		else:
			decal(decals, TUFT_DECAL % decor_rng.randi_range(1, 4), p * TILE, 0.9)


## Deux touffes jaune-vert par case de hautes herbes (un `Sprite2D` chacune, vent), comme la
## Route 2 sud (« même famille »). Non solides ; la donnée `tall_grass` est dans `Ground`.
func place_tall_grass() -> void:
	var wind: Material = load(WIND_MATERIAL)
	var index := 0
	for cell: Vector2i in tall_grass_cells:
		for k: int in 2:
			var foot := Vector2(cell) + Vector2(decor_rng.randf_range(0.25, 0.75),
				0.55 + 0.45 * k)
			var tuft := add_sprite(entities, TALL_GRASS_ID, foot * TILE, "Tuft%03d" % index)
			index += 1
			var scale := decor_rng.randf_range(1.0, 1.3)
			tuft.scale = Vector2(scale, scale)
			tuft.material = wind
			tuft.flip_h = decor_rng.randf() < 0.5


# --- Paroi --------------------------------------------------------------------------------


## Paroi de montagne sur les cases `K` (couche du sol, sous les personnages) : des rangées de
## modules de bas en haut, pied de chaque rangée tous les [constant PAROI_ROWS] cases depuis le
## pied de la paroi, modules tous les [constant PAROI_STEP] cases (rangées décalées de moitié).
## Chaque module est posé là où il couvre le moins de cases praticables (il peut déborder sur la
## forêt ou hors de la carte, jamais sur une case où l'on marche). Dessinés du fond vers l'avant.
## Renvoie le nombre de modules.
## [param style] (facultatif, jalon 12 : ardoise vers l'est) : `func(column: float) -> Dictionary`
## { "faces": Array[String], "mass": String, "slope": String, "tint": Color } d'après la colonne
## du milieu du module ; sans lui, la paroi de la série 12 partout (cartes du J10 inchangées).
func place_paroi(seed_value: int, style: Callable = Callable()) -> int:
	var paroi_rng := RandomNumberGenerator.new()
	paroi_rng.seed = seed_value
	var placed: Array[Dictionary] = []
	var covered: Dictionary = {}
	var max_y := -1
	for cell: Vector2i in cliff_cells:
		max_y = maxi(max_y, cell.y)
	var row := max_y
	var band := 0
	# Une rangée de plus au-dessus du bord haut de la carte : aucun jour en haut de l'écran.
	while row >= -1:
		# Cases de la paroi à couvrir sur cette rangée (pied d'un module) : celles dont le pied de
		# paroi est sur cette rangée ou plus haut, pas encore couvertes.
		var runs := _runs(row, covered)
		for run: Vector2i in runs:
			var front := _is_foot_run(run, row)
			var stagger := (PAROI_STEP / 2) * (band % 2)
			var lefts: Array[int] = []
			var left := run.x - stagger
			while left + PAROI_WIDTH <= run.y + 1:
				lefts.append(left)
				left += PAROI_STEP
			# Le dernier module touche la fin de l'étendue ; il la dépasse d'une case quand rien
			# n'est praticable au-delà (bord de carte, forêt) : aucun jour sur le bord.
			var end := run.y + 1 if is_walkable(Vector2i(run.y + 1, row)) else run.y + 2
			if lefts.is_empty() or lefts[-1] + PAROI_WIDTH < end:
				lefts.append(end - PAROI_WIDTH)
			for i: int in lefts.size():
				var best := _best_left(lefts[i], row)
				# Face seulement là où le module est vraiment au pied de la paroi (pas de
				# bandes de faces répétées au-dessus des bâtiments : masse rocheuse).
				front = _is_foot_run(Vector2i(maxi(best, run.x), mini(best + PAROI_WIDTH - 1,
					run.y)), row)
				var id: String
				var faces: Array[String] = PAROI_FACES.duplicate()
				var mass: String = PAROI_MASS
				var slope: String = PAROI_SLOPE
				var tint := Color.WHITE
				if style.is_valid():
					var look: Dictionary = style.call(best + PAROI_WIDTH / 2.0)
					faces.assign(look["faces"])
					mass = look["mass"]
					slope = look["slope"]
					tint = look["tint"]
				var mirrored := paroi_rng.randf() < 0.5
				var open_left := is_walkable(Vector2i(run.x - 1, row))
				var open_right := is_walkable(Vector2i(run.y + 1, row))
				if i == 0 and open_left and front:
					id = slope
					mirrored = false
				elif i == lefts.size() - 1 and open_right and front:
					id = slope
					mirrored = true
				elif front:
					id = faces[paroi_rng.randi_range(0, faces.size() - 1)]
				else:
					id = mass if paroi_rng.randf() < 0.6 \
						else faces[paroi_rng.randi_range(0, faces.size() - 1)]
				placed.append({"id": id, "left": best, "row": row, "flip": mirrored,
					"front": front, "tint": tint})
				for x: int in range(best, best + PAROI_WIDTH):
					for y: int in range(row - PAROI_ROWS + 1, row + 1):
						covered[Vector2i(x, y)] = true
		row -= PAROI_ROWS
		band += 1
	# Du fond (rangées hautes) vers l'avant : la rangée du pied passe devant.
	placed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["row"]) < int(b["row"]) or (int(a["row"]) == int(b["row"])
			and int(a["left"]) < int(b["left"])))
	var index := 0
	for entry: Dictionary in placed:
		var model := scene(String(entry["id"])).instantiate()
		var width := float((model.get_node(^"Sprite") as Sprite2D).texture.get_width())
		model.free()
		var foot := Vector2(float(entry["left"]) * TILE + width / 2.0,
			float(int(entry["row"]) + 1) * TILE)
		var prop := add_prop(decals, String(entry["id"]), foot, "Paroi%02d" % index)
		flip(prop, entry["flip"])
		var tint: Color = entry["tint"]
		if not entry["front"]:
			prop.modulate = Color(PAROI_BACK_VALUE, PAROI_BACK_VALUE, PAROI_BACK_VALUE) * tint
		elif tint != Color.WHITE:
			prop.modulate = tint
		index += 1
	return placed.size()


## Étendues [début, fin] (colonnes incluses) des cases de paroi de la rangée [param row] qui ne
## sont pas encore couvertes (une case couverte coupe l'étendue).
func _runs(row: int, covered: Dictionary) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var start := -1
	for x: int in size.x + 1:
		var cell := Vector2i(x, row)
		# Au-dessus de la carte : la paroi continue (rangée 0 prolongée).
		var open := x < size.x and cliff_cells.has(Vector2i(x, maxi(row, 0))) \
			and not covered.has(cell)
		if open and start < 0:
			start = x
		elif not open and start >= 0:
			runs.append(Vector2i(start, x - 1))
			start = -1
	return runs


## Vrai si l'étendue est au pied de la paroi (aucune paroi sous l'une de ses cases).
func _is_foot_run(run: Vector2i, row: int) -> bool:
	for x: int in range(run.x, run.y + 1):
		if not cliff_cells.has(Vector2i(x, row + 1)):
			return true
	return false


## Bord gauche (cases) le plus proche de [param left] (± 2) où un module posé au pied
## [param row] couvre le moins de cases praticables (sur ses rangées).
func _best_left(left: int, row: int) -> int:
	var best := left
	var best_cost := 1 << 20
	for delta: int in [0, -1, 1, -2, 2]:
		var cost := 0
		for x: int in range(left + delta, left + delta + PAROI_WIDTH):
			for y: int in range(row - 2, row + 1):
				if is_walkable(Vector2i(x, y)):
					cost += 1
		if cost < best_cost:
			best_cost = cost
			best = left + delta
	return best


# --- Forêt serrée -------------------------------------------------------------------------


## Ombre « plus sèche » de la forêt (jalon-10 §1.4 B) : teinte uniforme sur toute la carte.
func make_shade(value: float, red: float, blue: float) -> void:
	var shade_class: Variant = forest_script.get_script_constant_map()["Shade"]
	shade = shade_class.new()
	shade.set(&"from_row", float(size.y + 200))
	shade.set(&"full_row", float(size.y + 100))
	shade.set(&"value", value)
	shade.set(&"red", red)
	shade.set(&"blue", blue)
	shade.set(&"weights_row", -1000.0)


func forest_tint() -> Color:
	return forest_script.call(&"row_tint", shade, 0.0)


## Forêt serrée sur les cases de forêt (sauf [param taken]) : plan à graine fixe, arbres dégagés
## autour des PNJ et des objets au sol, cime réduite au-dessus des cases praticables, cases
## découvertes garnies de buissons, tri de visibilité, un `Sprite2D` par entrée. Renvoie
## [plan, gardées].
func place_forest(seed_value: int, landmarks: Array[Vector2], taken: Dictionary) -> Vector2i:
	var planted: Dictionary = {}
	for cell: Vector2i in forest_cells:
		if not taken.has(cell):
			planted[cell] = true
	var raw: Array[Dictionary] = forest_script.call(&"plan", planted, size, landmarks,
		seed_value, shade)
	var cleared := _clear_around_npcs(raw, planted, landmarks, seed_value)
	var kept: Array[Dictionary] = forest_script.call(&"cull_hidden", cleared,
		plan.call(&"cells_of", walkable), size)
	forest_script.call(&"place_sprites", kept, entities, root)
	return Vector2i(raw.size(), kept.size())


func _roster() -> Dictionary:
	if _npcs_path.is_empty() or not FileAccess.file_exists(_npcs_path):
		return {}
	return JSON.parse_string(FileAccess.get_file_as_string(_npcs_path))


## Cases des PNJ, Pokémon et objets du fichier de la carte (départ et routines).
func npc_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var roster := _roster()
	for key: String in roster:
		var entry: Dictionary = roster[key]
		cells.append(Vector2i(int(entry["cell"][0]), int(entry["cell"][1])))
		if entry.has("route"):
			for cell: Array in entry["route"]["cells"]:
				cells.append(Vector2i(int(cell[0]), int(cell[1])))
	cells.append_array(reserved_cells)
	return cells


func _ball_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var roster := _roster()
	for key: String in roster:
		var entry: Dictionary = roster[key]
		if entry.get("verb", "") == "take":
			cells.append(Vector2i(int(entry["cell"][0]), int(entry["cell"][1])))
	cells.append_array(reserved_balls)
	return cells


func _hides_ball(foot: Vector2, balls: Array[Vector2i]) -> bool:
	for cell: Vector2i in balls:
		if absf(foot.x - (cell.x + 0.5)) < BALL_CLEAR_X \
				and foot.y > cell.y + 0.5 and foot.y < cell.y + 2.0:
			return true
	return false


## Comme la Route 2 sud : retire les arbres dont le feuillage cacherait un PNJ ou un objet au
## sol, réduit ceux dont la cime descendrait sur une case praticable, garnit de buissons les
## cases découvertes.
func _clear_around_npcs(raw: Array[Dictionary], planted: Dictionary,
		landmarks: Array[Vector2], seed_value: int) -> Array[Dictionary]:
	var npcs := npc_cells()
	var balls := _ball_cells()
	var kept: Array[Dictionary] = []
	var trees: Array[Vector2] = landmarks.duplicate()
	for entry: Dictionary in raw:
		if entry["kind"] != &"tree":
			continue
		var foot: Vector2 = entry["foot"]
		var near := false
		for cell: Vector2i in npcs:
			var dx := absf(foot.x - (cell.x + 0.5))
			var dy := foot.y - (cell.y + 1.0)
			if dx < NPC_TREE_CLEAR_X and dy > -0.5 and dy < NPC_TREE_CLEAR_Y:
				near = true
				break
		var fitted := _fit_to_walkable(entry)
		if near or fitted <= 0.0:
			continue
		entry["scale"] = fitted
		kept.append(entry)
		trees.append(foot)
	var bushed: Dictionary = {}
	for entry: Dictionary in raw:
		if entry["kind"] == &"bush" and not _hides_ball(entry["foot"], balls):
			kept.append(entry)
			bushed[Vector2i(floori(entry["foot"].x), floori(entry["foot"].y - 0.95))] = true
	var bush_rng := RandomNumberGenerator.new()
	bush_rng.seed = seed_value + 1
	var constants := forest_script.get_script_constant_map()
	var bush_ids: Array = constants["BUSH_IDS"]
	var reference: Vector2 = constants["CELL_REFERENCE"]
	var drop: float = constants["BUSH_DROP"]
	for cell: Vector2i in planted:
		if bushed.has(cell) or forest_script.call(&"is_covered", cell, trees):
			continue
		var foot := Vector2(cell) + reference + Vector2(bush_rng.randf_range(-0.15, 0.15), drop)
		if _hides_ball(foot, balls):
			continue
		kept.append({"kind": &"bush", "id": bush_ids[bush_rng.randi_range(0, 1)],
			"foot": foot, "position": foot * TILE, "scale": 1.0,
			"flip_h": bush_rng.randf() < 0.5, "tint": forest_tint()})
	return kept


## Échelle d'un arbre pour que sa cime ne descende pas de plus de [constant WALK_OVERLAP_MAX]
## case sur une case praticable au-dessus de lui ; 0 : arbre retiré (voir build_route_2.gd).
func _fit_to_walkable(entry: Dictionary) -> float:
	var foot: Vector2 = entry["foot"]
	var scale: float = entry["scale"]
	var height := tree_height(String(entry["id"]))
	var reach := TREE_HALF_WIDTH * scale
	var lowest_free := -INF
	for x: int in range(floori(foot.x - reach), floori(foot.x + reach) + 1):
		for y: int in range(floori(foot.y - height * scale) - 1, floori(foot.y) + 1):
			if is_walkable(Vector2i(x, y)):
				lowest_free = maxf(lowest_free, float(y + 1))
	if lowest_free == -INF:
		return scale
	var allowed := (foot.y - (lowest_free - WALK_OVERLAP_MAX)) / height
	if allowed >= scale:
		return scale
	return allowed if allowed >= MIN_FIT_SCALE else 0.0


## Hauteur de l'image d'un objet peint, en cases.
func tree_height(id: String) -> float:
	if not _tree_heights.has(id):
		var node := scene(id).instantiate()
		var sprite := node.get_node(^"Sprite") as Sprite2D
		_tree_heights[id] = float(sprite.texture.get_height()) / TILE
		node.free()
	return _tree_heights[id]


# --- Fin ----------------------------------------------------------------------------------


## Enregistre la scène ; libère tout. Renvoie le code d'erreur et le nombre de nœuds.
func save(out_path: String) -> Vector2i:
	var count := _count(root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, out_path)
	root.free()
	for model: Variant in _models.values():
		if model != null:
			(model as Node).free()
	_models.clear()
	return Vector2i(err, count)


## Libère la racine sans l'enregistrer (masque à importer, erreur).
func discard() -> void:
	if root != null:
		root.free()
	for model: Variant in _models.values():
		if model != null:
			(model as Node).free()
	_models.clear()


func world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func attach(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


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
