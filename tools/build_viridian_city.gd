extends SceneTree
## Construit game/world/maps/viridian_city.tscn (Jadielle, 40 × 28 cases) et son masque de sol
## assets/world/maps/viridian_city_ground.png (docs/tech/jalon-07.md §8 T4, §6.6).
##
##   godot --headless --path . -s res://tools/build_viridian_city.gd
##   godot --headless --path . --import
##   (la première fois, ou si le masque change : relancer l'outil après l'import, pour que la
##   scène référence le masque importé)
##
## Conception : docs/design/dossier-09-jadielle.md §1 à §3, §11, §19 ; plan du prototype
## (`proto/da-jadielle:proto/da_jadielle/proto_ville.gd`, 40 × 28, Q-5) ajusté au jeu :
## - **arrivée depuis la Route 1** au sud : la rue sud (x 21–23) est courte et bordée de haies,
##   la place centrale s'ouvre tout de suite devant le joueur, entre le Centre (ouest) et la
##   Boutique (est) dont les façades sont visibles dès l'entrée (la micro-scène d'arrivée se
##   joue deux cases après l'entrée, Roucool sur l'auvent de la Boutique compris) ;
## - l'**arbre central** et son massif entre les deux bâtiments, passage de part et d'autre
##   vers la place nord ;
## - l'**Arène fermée** à l'ouest (porte examinable), son parvis mène à la **Route 22** (bord
##   ouest, warp vers `route_22` / `from_viridian`) ;
## - la **sortie nord** sous l'arche : « ROUTE 2 — À venir » (Warp.coming_soon) ;
## - quartiers nord (maisons, pelouses), parc à l'est, forêt tout autour (cases bloquées,
##   arbres peints posés avec une graine fixe).
## Sol : `PaintedGround` + masque (R pavés, G chemin de terre) ; aucun `TileMapLayer` (Jadielle
## n'a ni herbes hautes ni rebords) : la forêt et l'arrière des bâtiments sont des
## `blocked_cells`, les objets peints marquent leur emprise. Les habitants sont dans
## data/npcs/viridian_city.json, leurs répliques dans data/dialogues/viridian_city.json, la
## micro-scène dans data/cutscenes/viridian_city.json.

const OUT_PATH := "res://game/world/maps/viridian_city.tscn"
const MASK_PATH := "res://assets/world/maps/viridian_city_ground.png"
const PROPS_DIR := "res://game/world/props/painted/"
const RULES_SCRIPT := "res://game/world/props/painted_prop_rules.gd"
const SIZE := Vector2i(40, 28)
const TILE := 96
## Graines fixes : forêt, décalcomanies du bord des pavés.
const FOREST_SEED := 2026
const DECALS_SEED := 7
## WorldLighting.Z_GROUND_DECALS (les outils ne voient pas les class_name avant import).
const Z_GROUND_DECALS := -1

## Nature d'une case (peinte dans l'ordre de REGIONS) : forêt (bloquée, arbres), jardin
## (bloqué, sans arbre : derrière les bâtiments, sous les toits), pelouse, pavés, chemin.
enum Cell { FOREST, GARDEN, LAWN, PAVING, PATH }

## [nature, rectangle en cases], peints dans l'ordre (le suivant écrase le précédent).
const REGIONS: Array = [
	# Pelouses : quartiers nord-ouest et nord-est, parc à l'est, sud-ouest et sud-est, ouest
	# (entre le parvis de l'Arène et le sud-ouest), bords de la rue sud.
	[Cell.LAWN, Rect2i(9, 3, 12, 7)],
	[Cell.LAWN, Rect2i(24, 3, 15, 7)],
	[Cell.LAWN, Rect2i(33, 10, 6, 13)],
	[Cell.LAWN, Rect2i(1, 18, 10, 3)],
	[Cell.LAWN, Rect2i(1, 21, 9, 6)],
	[Cell.LAWN, Rect2i(35, 21, 5, 6)],
	[Cell.LAWN, Rect2i(10, 26, 3, 1)],
	[Cell.LAWN, Rect2i(32, 26, 3, 1)],
	# Jardins sous les toits (arrière du Centre, de la Boutique, de l'Arène) et rangée du bas
	# (clôtures) : bloqués, sans arbre.
	[Cell.GARDEN, Rect2i(12, 14, 8, 3)],
	[Cell.GARDEN, Rect2i(26, 14, 8, 3)],
	[Cell.GARDEN, Rect2i(1, 10, 10, 2)],
	[Cell.GARDEN, Rect2i(0, 27, 40, 1)],
	# Sous les haies de la rue sud (sans arbre : les haies seules bordent l'arrivée).
	[Cell.GARDEN, Rect2i(13, 26, 8, 1)],
	[Cell.GARDEN, Rect2i(24, 26, 8, 1)],
	# Pavés : rue nord, place nord, allée entre l'Arène et le Centre, parvis de l'Arène,
	# passage central, place centrale, rue sud.
	[Cell.PAVING, Rect2i(21, 0, 3, 10)],
	[Cell.PAVING, Rect2i(11, 10, 22, 4)],
	[Cell.PAVING, Rect2i(11, 14, 1, 2)],
	[Cell.PAVING, Rect2i(10, 16, 2, 5)],
	[Cell.PAVING, Rect2i(1, 16, 10, 2)],
	[Cell.PAVING, Rect2i(20, 14, 6, 7)],
	[Cell.PAVING, Rect2i(10, 21, 25, 5)],
	[Cell.PAVING, Rect2i(21, 26, 3, 2)],
	# Portes du Centre et de la Boutique (cases libres du bas de leur emprise, sous l'image).
	[Cell.PAVING, Rect2i(15, 20, 2, 1)],
	[Cell.PAVING, Rect2i(29, 20, 2, 1)],
	# Chemin de terre vers la Route 22 (bord ouest).
	[Cell.PATH, Rect2i(0, 16, 3, 2)],
]

## Cases du chemin au bord de la carte, bloquées sans rien de visible : la tête du joueur
## reste à l'écran (comme la Route 1).
const BLOCKED_EDGE: Array[Vector2i] = [Vector2i(21, 0), Vector2i(22, 0), Vector2i(23, 0)]

## Objets peints : [identifiant, case d'ancrage, nom du nœud]. Pied posé par
## PaintedPropRules.foot_position (bord ou milieu de case selon la largeur).
const PROPS: Array = [
	[&"bldg_centre_01", Vector2i(16, 20), "PokemonCenter"],
	[&"bldg_boutique_01", Vector2i(30, 20), "PokeMart"],
	[&"bldg_arene_01", Vector2i(6, 15), "Gym"],
	[&"tree_central_01", Vector2i(23, 19), "CentralTree"],
	[&"prop_porte_nord_01", Vector2i(22, 2), "NorthGate"],
	[&"bldg_maison_a_01", Vector2i(15, 8), "HouseNorthWest"],
	[&"bldg_maison_b_01", Vector2i(35, 8), "HouseNorthEast"],
	[&"bldg_maison_a_01", Vector2i(6, 25), "HouseSouthWest"],
	[&"bldg_maison_b_01", Vector2i(37, 25), "HouseSouthEast"],
	# Haies : la rue sud (arrivée entretenue), le bas de la rue nord.
	[&"prop_haie_01", Vector2i(15, 26), "HedgeSouthW1"],
	[&"prop_haie_01", Vector2i(19, 26), "HedgeSouthW2"],
	[&"prop_haie_01", Vector2i(26, 26), "HedgeSouthE1"],
	[&"prop_haie_01", Vector2i(30, 26), "HedgeSouthE2"],
	[&"prop_haie_01", Vector2i(19, 9), "HedgeNorthW"],
	[&"prop_haie_01", Vector2i(26, 9), "HedgeNorthE"],
	# Clôtures du bas de la carte (rangée bloquée).
	[&"prop_cloture_01", Vector2i(11, 27), "FenceSouth1"],
	[&"prop_cloture_01", Vector2i(15, 27), "FenceSouth2"],
	[&"prop_cloture_01", Vector2i(19, 27), "FenceSouth3"],
	[&"prop_cloture_01", Vector2i(26, 27), "FenceSouth4"],
	[&"prop_cloture_01", Vector2i(30, 27), "FenceSouth5"],
	[&"prop_cloture_01", Vector2i(34, 27), "FenceSouth6"],
	# Lampadaires : entrée sud, place nord, place centrale.
	[&"prop_lampadaire_01", Vector2i(20, 25), "LampSouthW"],
	[&"prop_lampadaire_01", Vector2i(24, 25), "LampSouthE"],
	[&"prop_lampadaire_01", Vector2i(19, 13), "LampNorthW"],
	[&"prop_lampadaire_01", Vector2i(26, 13), "LampNorthE"],
	[&"prop_lampadaire_01", Vector2i(32, 24), "LampSquareE"],
	[&"prop_lampadaire_01", Vector2i(34, 21), "LampParkS"],
	# Bancs : place centrale (la Dresseuse), parc.
	[&"prop_banc_01", Vector2i(14, 22), "BenchSquare"],
	[&"prop_banc_01", Vector2i(36, 15), "BenchPark"],
	# Panneau de la ville (décor : pas de texte validé au J7, plan §12).
	[&"prop_panneau_01", Vector2i(19, 25), "SignViridian"],
	# Arbres des pelouses (parc, quartiers nord).
	[&"tree_a_01", Vector2i(36, 12), "TreePark1"],
	[&"tree_b_01", Vector2i(37, 19), "TreePark2"],
	[&"tree_b_01", Vector2i(10, 4), "TreeNorthW"],
	[&"tree_a_01", Vector2i(29, 5), "TreeNorthE"],
	[&"tree_a_01", Vector2i(2, 19), "TreeWest"],
	[&"prop_rocher_01", Vector2i(3, 22), "RockSouthWest"],
]
## Relief posé au sol (GroundDecals, sous les personnages) : le massif de l'arbre central.
const GROUND_PROPS: Array = [
	[&"prop_massif_01", Vector2i(23, 19), "CentralBed"],
]

## Passages. [nœud, case, déclencheur (0 STEP_ON, 1 PUSH), direction, carte, spawn,
## orientation à l'arrivée].
const STEP_ON := 0
const PUSH := 1
const WARPS: Array = [
	# Sud : vers la Route 1 (bord nord de la Route 1, spawns from_viridian_*).
	["Route1W", Vector2i(21, 27), PUSH, Vector2i.DOWN, &"route_1", &"from_viridian_w",
		Vector2i.DOWN],
	["Route1C", Vector2i(22, 27), PUSH, Vector2i.DOWN, &"route_1", &"from_viridian_w",
		Vector2i.DOWN],
	["Route1E", Vector2i(23, 27), PUSH, Vector2i.DOWN, &"route_1", &"from_viridian_e",
		Vector2i.DOWN],
	# Portes du Centre et de la Boutique : les deux cases libres du bas de leur emprise.
	["DoorCenterW", Vector2i(15, 20), STEP_ON, Vector2i.UP, &"viridian_center", &"entrance",
		Vector2i.ZERO],
	["DoorCenterE", Vector2i(16, 20), STEP_ON, Vector2i.UP, &"viridian_center", &"entrance",
		Vector2i.ZERO],
	["DoorMartW", Vector2i(29, 20), STEP_ON, Vector2i.UP, &"viridian_mart", &"entrance",
		Vector2i.ZERO],
	["DoorMartE", Vector2i(30, 20), STEP_ON, Vector2i.UP, &"viridian_mart", &"entrance",
		Vector2i.ZERO],
	# Ouest : la Route 22 (carte de l'autre tâche, T22 ; contrat : spawn « from_viridian »).
	["Route22N", Vector2i(0, 16), PUSH, Vector2i.LEFT, &"route_22", &"from_viridian",
		Vector2i.LEFT],
	["Route22S", Vector2i(0, 17), PUSH, Vector2i.LEFT, &"route_22", &"from_viridian",
		Vector2i.LEFT],
]
## Sortie nord « à venir » (build de développement, dossier 09 §11) : [nœud, case, spawn de
## retour]. Le libellé est COMING_SOON_LABEL.
const COMING_SOON_LABEL := "Route 2"
const SOON_WARPS: Array = [
	["Route2SoonW", Vector2i(21, 1), &"route_2_soon_w"],
	["Route2SoonC", Vector2i(22, 1), &"route_2_soon_c"],
	["Route2SoonE", Vector2i(23, 1), &"route_2_soon_e"],
]
## Points d'apparition.
const SPAWNS: Dictionary = {
	"from_route_1_w": Vector2i(22, 27),
	"from_route_1_e": Vector2i(23, 27),
	"from_center": Vector2i(15, 20),
	"from_mart": Vector2i(30, 20),
	"from_route_22": Vector2i(0, 16),
	# Retour de l'écran « ROUTE 2 — À venir » : devant l'arche, tourné vers le sud.
	"route_2_soon_w": Vector2i(21, 3),
	"route_2_soon_c": Vector2i(22, 3),
	"route_2_soon_e": Vector2i(23, 3),
}
## Points d'examen : [nœud, ancre (bas-gauche), taille, orientation exigée, dialogue].
## La porte de l'Arène (deux cases du bas de son emprise, au milieu).
const INTERACTABLES: Array = [
	["GymDoor", Vector2i(5, 15), Vector2i(2, 1), Vector2i.UP, &"viridian_gym_door"],
]
## Déclencheurs : [nœud, ancre, taille, direction, scène]. Micro-scène d'arrivée : deux cases
## après l'entrée sud (plan §13), seul passage vers le nord (haies de part et d'autre).
const TRIGGERS: Array = [
	["ViridianArrival", Vector2i(21, 25), Vector2i(3, 1), Vector2i.UP, &"viridian_arrival"],
]

## Forêt : distance minimale entre deux arbres (cases) et décalage aléatoire du pied (px).
const TREE_SPACING := 1.9
const TREE_JITTER := Vector2(22.0, 16.0)

var _rules: Script
var _cells: Array[int] = []
var _rng := RandomNumberGenerator.new()
var _scenes: Dictionary = {}


func _init() -> void:
	_rules = load(RULES_SCRIPT)
	_paint_cells()
	var mask_changed := _write_mask()
	if mask_changed or not ResourceLoader.exists(MASK_PATH):
		print("viridian_city : masque écrit (%s) ; lancer « godot --headless --path . --import »"
			% MASK_PATH + " puis relancer l'outil.")
		if not ResourceLoader.exists(MASK_PATH):
			quit(0)
			return
	var root := _build()
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("viridian_city : %s (%d entités, %d cases bloquées)" % [error_string(err),
		root.get_node(^"Entities").get_child_count(),
		(root.get(&"blocked_cells") as Array).size()])
	root.free()
	quit(0 if err == OK else 1)


func _paint_cells() -> void:
	_cells.resize(SIZE.x * SIZE.y)
	_cells.fill(Cell.FOREST)
	for region: Array in REGIONS:
		var rect: Rect2i = region[1]
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				_cells[y * SIZE.x + x] = region[0]


func _cell(c: Vector2i) -> int:
	return _cells[c.y * SIZE.x + c.x]


## Écrit le masque (R pavés, G chemin). Vrai s'il a changé.
func _write_mask() -> bool:
	var image := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGB8)
	for y in SIZE.y:
		for x in SIZE.x:
			match _cell(Vector2i(x, y)):
				Cell.PAVING:
					image.set_pixel(x, y, Color(1, 0, 0))
				Cell.PATH:
					image.set_pixel(x, y, Color(0, 1, 0))
	var path := ProjectSettings.globalize_path(MASK_PATH)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var before := PackedByteArray()
	if FileAccess.file_exists(path):
		var old := Image.load_from_file(path)
		if old != null:
			old.convert(Image.FORMAT_RGB8)
			before = old.get_data()
	if before == image.get_data():
		return false
	image.save_png(path)
	return true


func _build() -> Node2D:
	_rng.seed = FOREST_SEED
	var root := Node2D.new()
	root.name = "ViridianCity"
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", &"viridian_city")
	root.set(&"display_name", "Jadielle")
	root.set(&"region", "")
	root.set(&"size", SIZE)
	root.set(&"light_profile", &"golden_hour")
	root.set(&"blocked_cells", _blocked_cells())
	var ground: Node2D = (load("res://game/world/ground/painted_ground.gd") as Script).new()
	ground.name = "PaintedGround"
	ground.set(&"size", SIZE)
	ground.set(&"mask", load(MASK_PATH))
	_attach(root, root, ground)
	var decals := Node2D.new()
	decals.name = "GroundDecals"
	decals.z_index = Z_GROUND_DECALS
	_attach(root, root, decals)
	var border := load("res://game/world/ground/border_decals.gd") as Script
	var plan: Array[Dictionary] = border.call(&"plan", _edge_cells(), SIZE, DECALS_SEED)
	border.call(&"place", plan, decals, root)
	for entry: Array in GROUND_PROPS:
		_add_prop(root, decals, entry[0], entry[1], entry[2])
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, root, entities)
	entities.unique_name_in_owner = true
	for entry: Array in PROPS:
		_add_prop(root, entities, entry[0], entry[1], entry[2])
	_plant_forest(root, entities)
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(root, root, node)
	_add_spawns(root)
	_add_warps(root)
	_add_interactables(root)
	_add_triggers(root)
	return root


## Forêt, jardins et bord du chemin.
func _blocked_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in SIZE.y:
		for x in SIZE.x:
			var kind := _cell(Vector2i(x, y))
			if kind == Cell.FOREST or kind == Cell.GARDEN:
				cells.append(Vector2i(x, y))
	for cell: Vector2i in BLOCKED_EDGE:
		if not cells.has(cell):
			cells.append(cell)
	return cells


## Cases pavées et du chemin, dans l'ordre de lecture (décalcomanies de leur bord).
func _edge_cells() -> Dictionary:
	var cells := {}
	for y in SIZE.y:
		for x in SIZE.x:
			var kind := _cell(Vector2i(x, y))
			if kind == Cell.PAVING or kind == Cell.PATH:
				cells[Vector2i(x, y)] = true
	return cells


## Arbres peints sur les cases de forêt : tirage à graine fixe, espacement minimal, décalage
## léger (l'ancre reste dans sa case, déjà bloquée). Jamais sous l'image d'un objet déjà posé
## (bâtiments, arche, haies : leurs cases sont aussi « forêt » sous l'emprise).
func _plant_forest(root: Node, entities: Node) -> void:
	var covered: Array[Rect2] = []
	for child: Node in entities.get_children():
		var sprite := child.get_node_or_null(^"Sprite") as Sprite2D
		if sprite != null and sprite.texture != null:
			var rect := Rect2((child as Node2D).position + sprite.offset, sprite.texture.get_size())
			covered.append(rect)
	var feet: Array[Vector2] = []
	var cells: Array[Vector2i] = []
	for y in SIZE.y:
		for x in SIZE.x:
			if _cell(Vector2i(x, y)) != Cell.FOREST:
				continue
			var foot := Vector2((x + 0.5) * TILE, (y + 1) * TILE - 1.0)
			if covered.any(func(r: Rect2) -> bool: return r.has_point(foot)):
				continue
			cells.append(Vector2i(x, y))
	# Ordre mélangé (graine fixe) pour une forêt sans alignement.
	for i in range(cells.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap := cells[i]
		cells[i] = cells[j]
		cells[j] = swap
	var index := 0
	for cell: Vector2i in cells:
		var centre := Vector2(cell.x + 0.5, cell.y + 1.0)
		var near := false
		for other: Vector2 in feet:
			if other.distance_to(centre) < TREE_SPACING:
				near = true
				break
		if near:
			continue
		feet.append(centre)
		var id := &"tree_b_01" if _rng.randf() < 0.5 else &"tree_a_01"
		var prop := _add_prop(root, entities, id, cell, "Forest%03d" % index)
		prop.position += Vector2(_rng.randf_range(-TREE_JITTER.x, TREE_JITTER.x),
			-_rng.randf_range(0.0, TREE_JITTER.y))
		index += 1


func _add_prop(root: Node, parent: Node, id: StringName, anchor: Vector2i,
		node_name: String) -> Node2D:
	if not _scenes.has(id):
		_scenes[id] = load(PROPS_DIR + String(id) + ".tscn")
	var scene: PackedScene = _scenes[id]
	var prop := scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	prop.position = _rules.call(&"foot_position", id, anchor)
	_attach(root, parent, prop)
	return prop


func _add_spawns(root: Node) -> void:
	for spawn_name: String in SPAWNS:
		var marker := Marker2D.new()
		marker.name = spawn_name
		marker.position = _world(SPAWNS[spawn_name])
		_attach(root, root.get_node(^"Spawns"), marker)


func _add_warps(root: Node) -> void:
	var warp_script: GDScript = load("res://game/world/warp_point.gd")
	for entry: Array in WARPS:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"trigger", entry[2])
		point.set(&"direction", entry[3])
		point.set(&"target_map", entry[4])
		point.set(&"target_spawn", entry[5])
		point.set(&"arrival_facing", entry[6])
		_attach(root, root.get_node(^"Warps"), point)
	for entry: Array in SOON_WARPS:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.UP)
		point.set(&"coming_soon", COMING_SOON_LABEL)
		point.set(&"target_spawn", entry[2])
		point.set(&"arrival_facing", Vector2i.DOWN)
		_attach(root, root.get_node(^"Warps"), point)


func _add_interactables(root: Node) -> void:
	var point_script: GDScript = load("res://game/world/interactions/interact_point.gd")
	for entry: Array in INTERACTABLES:
		var point := Marker2D.new()
		point.set_script(point_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"size", entry[2])
		point.set(&"facing", entry[3])
		point.set(&"dialogue_id", entry[4])
		_attach(root, root.get_node(^"Interactables"), point)


func _add_triggers(root: Node) -> void:
	var point_script: GDScript = load("res://game/world/triggers/event_trigger_point.gd")
	for entry: Array in TRIGGERS:
		var point := Marker2D.new()
		point.set_script(point_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"size", entry[2])
		point.set(&"direction", entry[3])
		point.set(&"cutscene_id", entry[4])
		_attach(root, root.get_node(^"Triggers"), point)


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root
