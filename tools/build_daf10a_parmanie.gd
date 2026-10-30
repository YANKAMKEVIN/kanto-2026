extends SceneTree
## Lot DAF.10a (`tools/art/daf10a.py`, fiche `docs/design/fiches-assets/daf-10a/fiche.md`, RP-269) :
## repeint Parmanie (`fuchsia_city`), écrite en tuiles provisoires par le J22 (grille
## `tools/plans/parmanie.txt`). Même méthode que `build_daf9_ile.gd` et `build_daf4_exterieurs.gd` :
## **la logique ne change pas** (gel du J33) ; les couches de tuiles (`Ground` = source logique,
## `Detail`, `Obstacles`) sont seulement masquées, portes, panneaux, apparitions et Pokémon des
## enclos restent tels quels. Les bâtiments sont des objets peints à l'emprise **déjà solide** dans la
## grille (portes libres) ; les clôtures sont des images découpées à la longueur de la rangée.
## Contrôle : `tools/dump_map_logic.gd` et `tools/dump_map_nodes.gd` identiques avant / après.
##
## Passe idempotente (elle retire d'abord ses propres nœuds).
##   godot --headless --path . -s res://tools/build_daf10a_parmanie.gd   (code 2 : masque écrit,
##   godot --headless --path . --import                                  importer puis relancer)

const Kit := preload("res://tools/pewter_map_kit.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAP_ID: StringName = &"fuchsia_city"
const MAP_PATH: String = "res://game/world/maps/fuchsia_city.tscn"
const PLAN_PATH: String = "res://tools/plans/parmanie.txt"
const MASK_PATH: String = "res://assets/world/maps/fuchsia_city_ground.png"
const OWN_ROOT: Array[String] = ["PaintedGround", "ForestFloor"]
const OWN_PREFIX: String = "Daf10a"
const SEED: int = 5301
const TILE: int = 96
const WATER_MARKS: String = "wf~"
const SAND_MARK: String = "y"
const PEN_FLOOR_MARK: String = "g"
## Bâtiments : [objet peint, case d'ancrage (porte la plus à l'est ; milieu pour une porte d'une case), nœud].
const BUILDINGS: Array = [
	["bldg_boutique_01", Vector2i(8, 19), "Boutique"],
	["bldg_fan_club_01", Vector2i(19, 18), "SalleReunion"],
	["bldg_arene_parmanie_01", Vector2i(8, 40), "Arene"],
	["bldg_maison_pecheur_01", Vector2i(19, 40), "MaisonGrandPere"],
	["bldg_centre_01", Vector2i(35, 40), "Centre"],
	["bldg_maison_pecheur_01", Vector2i(44, 40), "MaisonGardien"],
	["bldg_maison_pecheur_01", Vector2i(53, 40), "MaisonSuperCanne"],
	["bldg_pavillon_safari_01", Vector2i(29, 7), "PavillonSafari"],
]
const PRUNED_ID: String = "prop_buis_taille_01"
const FENCE_H: String = "prop_cloture_01"
const FENCE_V: String = "prop_cloture_v_01"
const MEADOW_PER_CELL: float = 0.35
const MEADOW_FLOWER_CHANCE: float = 0.25
const FLOWERS: Array[int] = [1, 3, 5]
## Décor des enclos (sans emprise : les cases sont déjà solides ; les Pokémon peints les traversent
## à l'image) : [objet, case (x, y), échelle].
const PEN_DECOR: Array = [
	["prop_souche_01", Vector2(5.2, 6.4), 1.0], ["prop_tronc_couche_01", Vector2(7.0, 4.6), 0.9],
	["prop_mangeoire_01", Vector2(8.3, 3.9), 1.0],
	["prop_buisson_a_01_bourg", Vector2(15.0, 4.2), 0.9], ["prop_souche_01", Vector2(16.0, 6.6), 1.0],
	["prop_mangeoire_01", Vector2(41.0, 3.9), 1.0], ["prop_tronc_couche_01", Vector2(44.0, 6.2), 0.9],
	["prop_buisson_a_01_bourg", Vector2(38.6, 6.6), 0.9],
	["prop_souche_01", Vector2(49.0, 4.6), 1.0], ["prop_mangeoire_01", Vector2(54.0, 3.9), 1.0],
	["prop_buisson_a_01_bourg", Vector2(51.0, 7.4), 0.9],
	["prop_mangeoire_01", Vector2(54.0, 15.8), 1.0], ["prop_tronc_couche_01", Vector2(49.0, 16.2), 0.9],
	["prop_souche_01", Vector2(51.0, 14.6), 1.0],
	["prop_nenuphars_01", Vector2(41.0, 15.6), 1.0], ["prop_nenuphars_02", Vector2(43.4, 16.4), 1.0],
	["prop_roseaux_01", Vector2(38.0, 17.0), 1.0],
	["prop_nenuphars_01", Vector2(48.0, 29.6), 1.0], ["prop_nenuphars_02", Vector2(52.5, 30.4), 1.0],
	["prop_roseaux_01", Vector2(45.0, 31.0), 1.0], ["prop_roseaux_01", Vector2(57.0, 31.0), 1.0],
]

var _errors: int = 0


func _init() -> void:
	quit(_build())


func _build() -> int:
	var plan := PlanGrid.new()
	if not plan.load_file(PLAN_PATH):
		push_error(plan.error)
		return 1
	var size := Vector2i(plan.width, plan.height)
	var kit: Object = Kit.new(PLAN_PATH, size, SEED, SEED + 1)
	kit.call(&"set_marks", ".=yD", "", "")
	var kit_root: Node2D = kit.call(&"make_root", "Kit", MAP_ID, "", "", &"golden_hour", "")
	var paved: Dictionary = kit.get(&"paved_cells")
	var path: Dictionary = kit.get(&"path_cells")
	for cell: Vector2i in plan.cells_of(SAND_MARK):
		paved[cell] = true
	for cell: Vector2i in plan.cells_of(PEN_FLOOR_MARK):
		path[cell] = true
	kit.call(&"make_shade", 1.0, 1.0, 1.0)
	if not kit.call(&"add_ground", MASK_PATH, kit.call(&"forest_undergrowth")):
		if (kit.get(&"errors") as PackedStringArray).is_empty():
			print("build_daf10a_parmanie : masque écrit ; importer (--import) puis relancer")
			kit.call(&"discard")
			return 2
		push_error("\n".join(kit.get(&"errors")))
		return 1
	var painted := kit_root.get_node(^"PaintedGround")
	painted.set(&"r_texture", load("res://assets/world/ground/ground_sable_01.png"))
	var water: Dictionary = {}
	for mark: String in WATER_MARKS:
		for cell: Vector2i in plan.cells_of(mark):
			water[cell] = true
	var shore: Image = (load("res://game/world/ground/ground_mask.gd") as GDScript).call(
		&"build_water", size, water)
	painted.set(&"shore_mask", ImageTexture.create_from_image(shore))
	painted.set(&"water_texture", load("res://assets/world/ground/ground_eau_01.png"))

	var entities: Node2D = kit.get(&"entities")
	var decals: Node2D = kit.get(&"decals")
	var taken: Dictionary = {}
	var rules: GDScript = kit.get(&"rules")
	for entry: Array in BUILDINGS:
		kit.call(&"add_prop_at", entities, entry[0], entry[1], "Bat_" + String(entry[2]))
		for offset: Vector2i in rules.call(&"footprint", StringName(entry[0])):
			taken[(entry[1] as Vector2i) + offset] = true
	# Les cases de bâtiment hors emprise (toit) ne portent pas d'arbres.
	for mark: String in "OCFZmS":
		for cell: Vector2i in plan.cells_of(mark):
			taken[cell] = true
	_place_pruned(kit, plan, entities)
	_place_fences(kit, plan, entities)
	_place_pen_decor(kit, entities)
	kit.call(&"place_border_decals", SEED)
	kit.call(&"place_meadow", int(size.x * size.y * MEADOW_PER_CELL), MEADOW_FLOWER_CHANCE,
		FLOWERS)
	kit.call(&"place_forest", SEED + 2, [] as Array[Vector2], taken)
	var errors: PackedStringArray = kit.get(&"errors")
	if not errors.is_empty():
		push_error("\n".join(errors))
		kit.call(&"discard")
		return 1

	var root := (load(MAP_PATH) as PackedScene).instantiate(
		PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean(root)
	for layer_name: String in ["Ground", "Detail", "Obstacles"]:
		(root.get_node(NodePath(layer_name)) as TileMapLayer).visible = false
	var index := root.get_node(^"Obstacles").get_index() + 1
	for node_name: String in OWN_ROOT:
		var node: Node = kit_root.get_node(NodePath(node_name))
		_adopt(node, root, root, kit_root)
		root.move_child(node, index)
		index += 1
	for pair: Array in [[kit_root.get_node(^"GroundDecals"), root.get_node(^"GroundDecals")],
			[kit_root.get_node(^"Entities"), root.get_node(^"Entities")]]:
		for child: Node in (pair[0] as Node).get_children():
			child.name = OWN_PREFIX + String(child.name)
			_adopt(child, pair[1], root, kit_root)
	root.set(&"grass_front", load(Kit.GRASS_FRONT))
	kit.call(&"discard")
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, MAP_PATH)
	print("%s : %s" % [MAP_ID, error_string(err)])
	root.free()
	return 0 if err == OK else 1


## Buissons taillés (`x` de la grille : blocs de trois cases, cases bloquées).
func _place_pruned(kit: Object, plan: Object, entities: Node2D) -> void:
	var index := 0
	for cell: Vector2i in plan.call(&"cells_of", "x"):
		kit.call(&"add_prop_at", entities, PRUNED_ID, cell, "Buis%03d" % index)
		index += 1


## Clôtures des enclos : rangées de `c` (≥ 2) = bande horizontale, colonnes de `c` restantes = bande
## verticale ; l'image est découpée à la longueur exacte. Aucune emprise (cases déjà bloquées).
func _place_fences(kit: Object, plan: Object, entities: Node2D) -> void:
	var fences: Array[Vector2i] = plan.call(&"cells_of", "c")
	var fence: Dictionary = {}
	for cell: Vector2i in fences:
		fence[cell] = true
	var horizontal: Dictionary = {}
	var index := 0
	for cell: Vector2i in fences:
		if not fence.has(cell + Vector2i.LEFT) and fence.has(cell + Vector2i.RIGHT):
			var end := cell.x
			while fence.has(Vector2i(end + 1, cell.y)):
				end += 1
			for x: int in range(cell.x, end + 1):
				horizontal[Vector2i(x, cell.y)] = true
			_fence_piece(kit, entities, FENCE_H, Vector2i(cell.x, cell.y), end - cell.x + 1,
				true, index)
			index += 1
	for cell: Vector2i in fences:
		if horizontal.has(cell) or fence.has(cell + Vector2i.UP) and not horizontal.has(
				cell + Vector2i.UP):
			continue
		var end_y := cell.y
		while fence.has(Vector2i(cell.x, end_y + 1)) \
				and not horizontal.has(Vector2i(cell.x, end_y + 1)):
			end_y += 1
		_fence_piece(kit, entities, FENCE_V, cell, end_y - cell.y + 1, false, index)
		index += 1


## [param start] : case de départ (gauche ou haut) ; [param count] cases ; découpe l'image en
## tronçons de 4 cases au plus.
func _fence_piece(kit: Object, entities: Node2D, id: String, start: Vector2i, count: int,
		horizontal: bool, index: int) -> void:
	var model := (kit.call(&"scene", id) as PackedScene).instantiate()
	var source := model.get_node(^"Sprite") as Sprite2D
	var texture := source.texture
	var material := source.material
	model.free()
	var done := 0
	var part := 0
	while done < count:
		var n := mini(4, count - done)
		var sprite := Sprite2D.new()
		sprite.name = "Fence%03d_%d" % [index, part]
		sprite.texture = texture
		sprite.material = material
		sprite.centered = false
		sprite.region_enabled = true
		if horizontal:
			sprite.region_rect = Rect2(0, 0, n * TILE, texture.get_height())
			sprite.offset = Vector2(0, -texture.get_height())
			sprite.position = Vector2((start.x + done) * TILE, (start.y + 1) * TILE)
		else:
			sprite.region_rect = Rect2(0, texture.get_height() - n * TILE, texture.get_width(),
				n * TILE)
			sprite.offset = Vector2(-texture.get_width() / 2.0, -n * TILE)
			sprite.position = Vector2((start.x + 0.5) * TILE, (start.y + done + n) * TILE)
		entities.add_child(sprite)
		sprite.owner = kit.get(&"root")
		done += n
		part += 1


func _place_pen_decor(kit: Object, entities: Node2D) -> void:
	var index := 0
	for entry: Array in PEN_DECOR:
		var prop: Node2D = kit.call(&"add_prop", entities, entry[0],
			(entry[1] as Vector2) * TILE, "Pen%02d" % index)
		kit.call(&"clear_footprint", prop)
		prop.scale = Vector2.ONE * float(entry[2])
		index += 1


func _clean(root: Node) -> void:
	for node_name: String in OWN_ROOT:
		var old := root.get_node_or_null(NodePath(node_name))
		if old != null:
			root.remove_child(old)
			old.free()
	for parent_name: String in ["GroundDecals", "Entities"]:
		var parent := root.get_node(NodePath(parent_name))
		for child: Node in parent.get_children():
			if String(child.name).begins_with(OWN_PREFIX):
				parent.remove_child(child)
				child.free()


func _adopt(node: Node, parent: Node, root: Node, kit_root: Node) -> void:
	var owned: Array[Node] = []
	_collect(node, kit_root, owned)
	for n: Node in owned:
		n.owner = null
	node.get_parent().remove_child(node)
	parent.add_child(node)
	for n: Node in owned:
		n.owner = root


func _collect(node: Node, kit_root: Node, into: Array[Node]) -> void:
	if node.owner == kit_root:
		into.append(node)
	for child: Node in node.get_children():
		_collect(child, kit_root, into)
