extends SceneTree
## Lot DAF.4, dernier morceau (fiche `docs/design/fiches-assets/daf-4/fiche.md`) : repeint le sol
## de la Route 23 (`route_23`) et du Plateau Indigo (`indigo_plateau`), écrits en tuiles provisoires
## par `build_j29.gd`. Aucune image nouvelle : textures communes (herbe, chemin, eau des canaux),
## paroi de montagne de la série 12 (`relief_paroi_01..04`), rochers (`prop_grande_pierre_01`,
## `prop_rocher_01`, `prop_rocher_mer_01` dans l'eau), berges naturelles de la Route 6
## (`relief_berge_*`), hautes herbes peintes.
##
## Passe APRÈS `build_daf4_facades.gd` (la façade de la Ligue reste en place), sur le modèle de
## `build_daf4_caves.gd` ; idempotente (elle retire d'abord ses propres nœuds). **La logique ne
## change pas** : la couche `Ground` (source logique : solide, eau, hautes herbes), `blocked_cells`,
## `surf_cells`, les passages, les contrôles de Badge, les PNJ et les nœuds de `Entities` sont
## gardés ; les couches de tuiles sont seulement masquées. L'image vient de
## `tools/cerulean_map_kit.gd` (une racine de kit jetable, dont on adopte les nœuds) :
## - falaises `#` : composantes de la grille ; les saillies d'une ou deux cases de large sur une
##   rangée et les petits blocs deviennent des rochers, le reste de la paroi en modules ;
## - eau `w` : eau des canaux à angles droits, berges sur toute frontière eau / sol ;
## - Plateau Indigo : chemin de terre au milieu (colonnes 9..10) [D], pas de paroi sous la façade.
##
##   godot --headless --path . -s res://tools/build_daf4_exterieurs.gd   (code 2 : masques écrits,
##   godot --headless --path . --import                                 importer puis relancer)

const Kit := preload("res://tools/cerulean_map_kit.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const MASK_PATH: String = "res://assets/world/maps/%s_ground.png"
## Nœuds posés par cette passe (racine) et préfixe des nœuds posés dans `Entities` / `GroundDecals`
## (« Daf4Facade » appartient à `build_daf4_facades.gd`).
const OWN_ROOT: Array[String] = ["PaintedGround", "ForestFloor"]
const OWN_PREFIX: String = "Daf4Ext"
## Carte → [grille, graine, cases de chemin, cases sans paroi (bâtiment peint)].
const MAPS: Dictionary = {
	&"route_23": ["route_23", 2301, Rect2i(), Rect2i()],
	&"indigo_plateau": ["plateau_indigo", 2311, Rect2i(9, 6, 2, 12), Rect2i(6, 0, 8, 6)],
}
## Praticables pour le placement des modules (l'eau compte : aucun module de paroi dessus) et pour
## les berges (posées dans l'eau).
const WALKABLE_PAROI: String = ".hw"
const WALKABLE_BANKS: String = ".h"
## Saillie : étendue de falaise d'au plus tant de cases sur sa rangée → rochers.
const PROTRUSION_MAX: int = 2
## Bloc de falaise de moins de tant de cases → rochers.
const BLOCK_MIN: int = 8
const MEADOW_PER_CELL: float = 0.35
const MEADOW_FLOWER_CHANCE: float = 0.25
const FLOWERS: Array[int] = [1, 3, 5]
## Berges naturelles (série 15, comme la Route 6) contre tout sol de la carte.
const BANK_MARKS: Array[String] = [".", "h", "#"]
const BANKS: Dictionary[StringName, Dictionary] = {
	&"n": {"ids": ["relief_berge_01", "relief_berge_02"], "flip_h": false, "flip_v": false},
	&"s": {"ids": ["relief_berge_03"], "flip_h": false, "flip_v": false},
	&"w": {"ids": ["relief_berge_04"], "flip_h": false, "flip_v": false},
	&"e": {"ids": ["relief_berge_04"], "flip_h": true, "flip_v": false},
	&"nw": {"ids": ["relief_berge_05"], "flip_h": false, "flip_v": false},
	&"ne": {"ids": ["relief_berge_05"], "flip_h": true, "flip_v": false},
	&"sw": {"ids": ["relief_berge_05"], "flip_h": false, "flip_v": true},
	&"se": {"ids": ["relief_berge_05"], "flip_h": true, "flip_v": true},
}
## Montagne hors carte : largeur réservée (cases), recouvrement du bord (pixels), assombrissement.
const MARGIN_WIDTH: int = 5
const MARGIN_OVERLAP: float = 24.0
const MARGIN_VALUE: float = 0.8
const SIDES: Array[Vector2i] =[Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _errors: int = 0
var _masks: int = 0


func _init() -> void:
	for map_id: StringName in MAPS:
		_build(map_id)
	if _errors > 0:
		quit(1)
	elif _masks > 0:
		print("build_daf4_exterieurs : %d masque(s) écrit(s) ; importer (--import) puis relancer"
			% _masks)
		quit(2)
	else:
		quit(0)


func _build(map_id: StringName) -> void:
	var spec: Array = MAPS[map_id]
	var plan_path := "res://tools/plans/%s.txt" % spec[0]
	var plan := PlanGrid.new()
	if not plan.load_file(plan_path):
		push_error("%s : %s" % [map_id, plan.error])
		_errors += 1
		return
	var size := Vector2i(plan.width, plan.height)
	var seed_value: int = spec[1]
	var kit: Object = Kit.new(plan_path, size, seed_value, seed_value + 1, seed_value + 2)
	# La grille déclare l'eau praticable (Surf) ; ici l'eau est peinte, pas marchée.
	kit.set(&"errors", PackedStringArray())
	kit.call(&"set_marks", WALKABLE_PAROI, "#", "")
	var kit_root: Node2D = kit.call(&"make_root", "Kit", map_id, "", "", &"golden_hour", "")
	var cliffs: Dictionary = kit.get(&"cliff_cells")
	var building: Rect2i = spec[3]
	for cell: Vector2i in cliffs.keys():
		if building.has_point(cell):
			cliffs.erase(cell)
	var path_rect: Rect2i = spec[2]
	var paths: Dictionary = kit.get(&"path_cells")
	for y: int in range(path_rect.position.y, path_rect.end.y):
		for x: int in range(path_rect.position.x, path_rect.end.x):
			if plan.at(Vector2i(x, y)) == ".":
				paths[Vector2i(x, y)] = true
	var outcrops := _split_outcrops(cliffs, size)
	var undergrowth: Dictionary = {}
	for cell: Vector2i in cliffs:
		undergrowth[cell] = 1.0
	if not kit.call(&"add_ground", MASK_PATH % map_id, undergrowth):
		if (kit.get(&"errors") as PackedStringArray).is_empty():
			_masks += 1
		else:
			push_error("%s :\n%s" % [map_id, "\n".join(kit.get(&"errors"))])
			_errors += 1
		kit.call(&"discard")
		return
	kit.call(&"place_border_decals", seed_value)
	kit.call(&"place_meadow", int(size.x * size.y * MEADOW_PER_CELL), MEADOW_FLOWER_CHANCE, FLOWERS)
	var sets: Dictionary = {}
	for mark: String in BANK_MARKS:
		sets[mark] = BANKS
	kit.set(&"quay_sets", sets)
	(kit.get(&"plan") as Object).set(&"walkable", WALKABLE_BANKS)
	var banks: int = kit.call(&"place_quays")
	(kit.get(&"plan") as Object).set(&"walkable", WALKABLE_PAROI)
	_place_margins(kit, size, seed_value + 4)
	var modules: int = kit.call(&"place_paroi", seed_value + 3)
	var rocks := _place_boulders(kit, outcrops)
	kit.call(&"place_tall_grass")
	var errors: PackedStringArray = kit.get(&"errors")
	if not errors.is_empty():
		push_error("%s :\n%s" % [map_id, "\n".join(errors)])
		_errors += 1
		kit.call(&"discard")
		return

	var path := MAPS_DIR + "%s.tscn" % map_id
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
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
		err = ResourceSaver.save(packed, path)
	print("%s : %s (%d modules de paroi, %d berges, %d rochers)" % [map_id, error_string(err),
		modules, banks, rocks])
	if err != OK:
		_errors += 1
	root.free()


## Montagne hors de la carte, à l'ouest et à l'est (cartes de 20 cases, plus étroites que l'écran :
## sans elle, des bandes noires) : une colonne de modules de paroi assombris contre chaque bord,
## du haut vers le bas (la rangée du bas passe devant), sous la paroi de la carte.
func _place_margins(kit: Object, size: Vector2i, seed_value: int) -> void:
	var margin_rng := RandomNumberGenerator.new()
	margin_rng.seed = seed_value
	var ids: Array[String] = [Kit.PAROI_MASS, Kit.PAROI_MASS, Kit.PAROI_FACES[0],
		Kit.PAROI_FACES[1]]
	var decals: Node2D = kit.get(&"decals")
	var index := 0
	var row := -1 + (size.y + 2) % Kit.PAROI_ROWS
	while row <= size.y + 1:
		for left: int in [-MARGIN_WIDTH, size.x]:
			var id: String = ids[margin_rng.randi_range(0, ids.size() - 1)]
			var model := (kit.call(&"scene", id) as PackedScene).instantiate()
			var width := float((model.get_node(^"Sprite") as Sprite2D).texture.get_width())
			model.free()
			# Collé au bord de la carte (le module déborde un peu sur la paroi de la carte).
			var x := -width / 2.0 + MARGIN_OVERLAP if left < 0 \
				else float(size.x * Kit.TILE) + width / 2.0 - MARGIN_OVERLAP
			var prop: Node2D = kit.call(&"add_prop", decals, id,
				Vector2(x, float((row + 1) * Kit.TILE)), "Marge%03d" % index)
			kit.call(&"flip", prop, margin_rng.randf() < 0.5)
			prop.modulate = Color(MARGIN_VALUE, MARGIN_VALUE, MARGIN_VALUE)
			index += 1
		row += Kit.PAROI_ROWS


## Retire de [param cliffs] les saillies (étendue d'au plus [constant PROTRUSION_MAX] cases sur sa
## rangée) puis les blocs de moins de [constant BLOCK_MIN] cases ; renvoie ces composantes
## (rochers, [method _place_boulders]).
func _split_outcrops(cliffs: Dictionary, size: Vector2i) -> Array[Array]:
	var loose: Dictionary = {}
	for y: int in size.y:
		var start := -1
		for x: int in size.x + 1:
			var on := x < size.x and cliffs.has(Vector2i(x, y))
			if on and start < 0:
				start = x
			elif not on and start >= 0:
				if x - start <= PROTRUSION_MAX:
					for k: int in range(start, x):
						loose[Vector2i(k, y)] = true
				start = -1
	for cell: Vector2i in loose:
		cliffs.erase(cell)
	for component: Array[Vector2i] in _components(cliffs):
		if component.size() < BLOCK_MIN:
			for cell: Vector2i in component:
				cliffs.erase(cell)
				loose[cell] = true
	return _components(loose)


func _components(cells: Dictionary) -> Array[Array]:
	var left := cells.duplicate()
	var out: Array[Array] = []
	var keys: Array = left.keys()
	keys.sort()
	for start: Vector2i in keys:
		if not left.has(start):
			continue
		left.erase(start)
		var component: Array[Vector2i] = [start]
		var stack: Array[Vector2i] = [start]
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			for side: Vector2i in SIDES:
				if left.has(cell + side):
					left.erase(cell + side)
					component.append(cell + side)
					stack.append(cell + side)
		component.sort()
		out.append(component)
	return out


## Rochers sur les saillies et petits blocs (comme la Route 9) : grande pierre (3 × 2) là où elle
## tient, sinon rochers (2 × 1), sinon un rocher réduit sur sa case ; rocher de mer quand la case
## touche l'eau. Renvoie leur nombre.
func _place_boulders(kit: Object, outcrops: Array[Array]) -> int:
	var rules: GDScript = kit.get(&"rules")
	var decor: RandomNumberGenerator = kit.get(&"decor_rng")
	var water: Dictionary = kit.get(&"water_cells")
	var entities: Node2D = kit.get(&"entities")
	var index := 0
	for component: Array in outcrops:
		var free: Dictionary = {}
		var wet := false
		for cell: Vector2i in component:
			free[cell] = true
			for side: Vector2i in SIDES:
				wet = wet or water.has(cell + side)
		var order: Array = component.duplicate()
		order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.y > b.y or (a.y == b.y and a.x < b.x))
		var ids: Array[String] = ["prop_grande_pierre_01", "prop_rocher_01"]
		if wet:
			ids = ["prop_rocher_mer_01"]
		for cell: Vector2i in order:
			if not free.has(cell):
				continue
			var placed := false
			for id: String in ids:
				var footprint: Array[Vector2i] = rules.call(&"footprint", StringName(id))
				for align: Vector2i in footprint:
					var anchor := cell - align
					var fits := true
					for offset: Vector2i in footprint:
						fits = fits and free.has(anchor + offset)
					if not fits:
						continue
					var rock: Node2D = kit.call(&"add_prop_at", entities, id, anchor,
						"Rock%02d" % index)
					_style_rock(kit, rock, decor, 0.9 if id == "prop_grande_pierre_01" else 1.0)
					for offset: Vector2i in footprint:
						free.erase(anchor + offset)
					placed = true
					break
				if placed:
					break
			if not placed:
				var foot := Vector2(cell.x + decor.randf_range(0.4, 0.6),
					cell.y + decor.randf_range(0.88, 0.98))
				var small: Node2D = kit.call(&"add_prop", entities, ids[-1], foot * Kit.TILE,
					"Rock%02d" % index)
				kit.call(&"clear_footprint", small)
				_style_rock(kit, small, decor, 0.7)
				free.erase(cell)
			index += 1
	return index


func _style_rock(kit: Object, rock: Node2D, decor: RandomNumberGenerator, scale: float) -> void:
	var s := scale * decor.randf_range(0.92, 1.08)
	rock.scale = Vector2(s, s)
	kit.call(&"flip", rock, decor.randf() < 0.5)
	var value := decor.randf_range(0.9, 1.0)
	rock.modulate = Color(value, value, value)


## Retire ce que cette passe a posé (relance).
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


## Déplace [param node] du kit jetable vers [param parent] de la carte ; les nœuds possédés par la
## racine du kit passent à la carte (l'intérieur des instances garde son propriétaire).
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
