extends SceneTree
## Lot DAF.4 (`tools/art/daf4.py`, fiche `docs/design/fiches-assets/daf-4/fiche.md`) : repeint la
## Route Victoire (`victory_road_1f` à `_3f`, J29) et la Grotte Azurée (`cerulean_cave_1f`, `_2f`,
## `_b1f`, J31), écrites en tuiles provisoires par `build_j29.gd` et `build_cerulean_cave.gd`.
##
## Passe APRÈS ces deux outils, sur le modèle de `build_route_22_west.gd` ; idempotente (elle retire
## d'abord ses propres nœuds). **La logique ne change pas** : la couche `Ground` (source logique,
## niveaux de sol), `blocked_cells`, les passages, les portes, les rochers, les interrupteurs et
## les barrières (leurs [FlagGate]) sont gardés ; les couches de tuiles sont seulement masquées.
## L'image vient de `tools/cave_map_kit.gd` (une racine de kit jetable, dont on adopte les nœuds) :
## - sol peint : sol bas = base, sol haut `:` et escaliers `=` = canal R (texture nettement plus
##   claire, RP-133), parois `#` (et indices `x`) = canal G ; parois du Mont Sélénite ([method
##   place_walls]) ;
## - rebords peints au sud et sur les côtés du sol haut, escaliers `=` peints ;
## - eau `w` (Grotte Azurée) : bandes d'eau de grotte peintes (`ground_eau_grotte_01`) ;
## - dessins provisoires (`Dessin`) des échelles, interrupteurs, barrières et indices remplacés par
##   des images peintes (échelles du Mont Sélénite, planche de la Route Victoire).
##
##   godot --headless --path . -s res://tools/build_j29.gd
##   godot --headless --path . -s res://tools/build_cerulean_cave.gd
##   godot --headless --path . -s res://tools/build_daf4_caves.gd   (code 2 : masques écrits,
##   godot --headless --path . --import                            importer puis relancer)

const Kit := preload("res://tools/cave_map_kit.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const MASK_PATH: String = "res://assets/world/maps/%s_ground.png"
const GROUND: String = "res://assets/world/ground/%s.png"
const INTERIORS: String = "res://assets/world/interiors/"
const PROPS: String = "res://assets/world/props/"
const TILE: int = 96
## Nœuds posés par cette passe (racine) et préfixe des nœuds posés dans `Entities` / `GroundDecals`.
const OWN_ROOT: Array[String] = ["PaintedGround", "Eau"]
const OWN_PREFIX: String = "Daf4"
## Carte → [grille, sol bas, sol haut, caractères de paroi, lieu (modules), graine].
const MAPS: Dictionary = {
	&"victory_road_1f": ["route_victoire_1f", "ground_victoire_bas_01", "ground_victoire_haut_01", "#",
		"victoire", 2901],
	&"victory_road_2f": ["route_victoire_2f", "ground_victoire_bas_01", "ground_victoire_haut_01", "#",
		"victoire", 2911],
	&"victory_road_3f": ["route_victoire_3f", "ground_victoire_bas_01", "ground_victoire_haut_01", "#",
		"victoire", 2921],
	&"cerulean_cave_1f": ["cerulean_cave_1f", "ground_azuree_bas_01", "ground_azuree_haut_01", "#x",
		"azuree", 3101],
	&"cerulean_cave_2f": ["cerulean_cave_2f", "ground_azuree_bas_01", "ground_azuree_haut_01", "#x",
		"azuree", 3111],
	&"cerulean_cave_b1f": ["cerulean_cave_b1f", "ground_azuree_bas_01", "ground_azuree_haut_01", "#x",
		"azuree", 3121],
}
const MASS: String = "ground_masse_roche_01"
const WATER: String = "ground_eau_grotte_01"
## Frontière bruitée entre deux sols, par lieu [D].
const BORDER: Dictionary = {"victoire": Color(0.33, 0.25, 0.18), "azuree": Color(0.24, 0.27, 0.34)}
const HIGH_MARKS: String = ":="
## Dessins provisoires remplacés : préfixe du nœud [FlagGate] → image peinte (pied au bas de la
## case, comme le dessin).
const SWAPS: Dictionary = {
	"EchelleDessin_": "prop_echelle_monte_01", "Echelle": "prop_echelle_monte_01",
	"InterrupteurEnfonce_": "decal_interrupteur_victoire_enfonce_01",
	"InterrupteurReleve_": "decal_interrupteur_victoire_01", "Barriere_": "prop_barriere_victoire_01",
	"Indice_": "prop_rocher_grotte_02", "TrouOuvert": "decal_trou_victoire_01",
	"TrouBouche": "decal_trou_victoire_bouche_01",
}

var _errors: int = 0
var _masks: int = 0


func _init() -> void:
	for map_id: StringName in MAPS:
		_build(map_id)
	if _errors > 0:
		quit(1)
	elif _masks > 0:
		print("build_daf4_caves : %d masque(s) écrit(s) ; importer (--import) puis relancer" % _masks)
		quit(2)
	else:
		quit(0)


func _build(map_id: StringName) -> void:
	var spec: Array = MAPS[map_id]
	var plan := PlanGrid.new()
	if not plan.load_file("res://tools/plans/%s.txt" % spec[0]):
		push_error("%s : %s" % [map_id, plan.error])
		_errors += 1
		return
	var size := Vector2i(plan.width, plan.height)
	var kit: Object = Kit.new("res://tools/plans/%s.txt" % spec[0], size, spec[5], spec[5] + 1,
		plan.walkable)
	kit.set(&"floor_texture_path", GROUND % spec[1])
	kit.set(&"rubble_texture_path", GROUND % spec[2])
	kit.set(&"mass_texture_path", GROUND % MASS)
	kit.set(&"border_color", BORDER[spec[4]])
	kit.set(&"rubble_mark", ":")
	kit.set(&"rubble_is_logic", false)
	kit.set(&"wall_marks", spec[3])
	if not (kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("%s :\n%s" % [map_id, "\n".join(kit.get(&"errors"))])
		_errors += 1
		return
	var kit_root: Node2D = kit.call(&"make_root", "Kit", map_id, "", &"")
	var rubble: Dictionary = kit.get(&"rubble_cells")
	for cell: Vector2i in plan.cells_of("="):
		rubble[cell] = true
	if not kit.call(&"add_ground", MASK_PATH % map_id):
		if (kit.get(&"errors") as PackedStringArray).is_empty():
			_masks += 1
		else:
			push_error("%s :\n%s" % [map_id, "\n".join(kit.get(&"errors"))])
			_errors += 1
		kit.call(&"discard")
		return
	kit.call(&"place_walls", spec[5] + 2)
	var marks := _place_levels(kit, plan, spec[4])
	var path := MAPS_DIR + "%s.tscn" % map_id
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	if root.get_node_or_null(^"GroundDecals") == null:
		# Grotte Azurée : pas de couche de décalcomanies ; même réglage que le kit, sous `Entities`.
		var decals := Node2D.new()
		decals.name = "GroundDecals"
		decals.z_index = Kit.Z_DECALS
		root.add_child(decals)
		decals.owner = root
		root.move_child(decals, root.get_node(^"Entities").get_index())
	_clean(root)
	for layer_name: String in ["Ground", "Detail", "Obstacles"]:
		var layer := root.get_node_or_null(NodePath(layer_name)) as TileMapLayer
		if layer != null:
			layer.visible = false
	var painted: Node = kit_root.get_node(^"PaintedGround")
	_adopt(painted, root, root, kit_root)
	root.move_child(painted, root.get_node(^"Obstacles").get_index() + 1)
	var water := _water(root, plan)
	if water != null:
		root.move_child(water, painted.get_index() + 1)
	for pair: Array in [[kit_root.get_node(^"GroundDecals"), root.get_node(^"GroundDecals")],
			[kit_root.get_node(^"Entities"), root.get_node(^"Entities")]]:
		for child: Node in (pair[0] as Node).get_children():
			child.name = OWN_PREFIX + String(child.name)
			_adopt(child, pair[1], root, kit_root)
	var swapped := _swap_drawings(root)
	kit.call(&"discard")
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s : %s (%d rebords et escaliers, %d dessins remplacés)" % [map_id, error_string(err),
		marks, swapped])
	if err != OK:
		_errors += 1
	root.free()


## Retire ce que cette passe a posé (relance) et les voiles provisoires du sol haut / des escaliers
## (`Dessin` de `GroundDecals`).
func _clean(root: Node) -> void:
	for node_name: String in OWN_ROOT:
		var old := root.get_node_or_null(NodePath(node_name))
		if old != null:
			root.remove_child(old)
			old.free()
	for parent_name: String in ["GroundDecals", "Entities"]:
		var parent := root.get_node(NodePath(parent_name))
		for child: Node in parent.get_children():
			if String(child.name).begins_with(OWN_PREFIX) or (parent_name == "GroundDecals"
					and child is Polygon2D):
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


## Rebords (face au sud du sol haut, bords latéraux à l'est et à l'ouest) et escaliers peints, au
## sol. Renvoie le nombre d'objets.
func _place_levels(kit: Object, plan: PlanGrid, place: String) -> int:
	var count := 0
	var face := "relief_rebord_%s_01" % place
	var side := "relief_rebord_%s_cote_01" % place
	for cell: Vector2i in plan.cells_of(HIGH_MARKS):
		if plan.at(cell) == "=":
			kit.call(&"add_floor_prop", "relief_escalier_%s_01" % place, cell, "Stairs%03d" % count)
			count += 1
			continue
		if _is_low(plan, cell + Vector2i.DOWN):
			kit.call(&"add_floor_prop", face, cell, "Ledge%03d" % count)
			count += 1
		for dx: int in [-1, 1]:
			if _is_low(plan, cell + Vector2i(dx, 0)):
				var prop: Node2D = kit.call(&"add_floor_prop", side, cell, "Side%03d" % count)
				prop.position.x += dx * (TILE / 2.0 - 12.0)
				count += 1
	return count


## Case de sol bas (praticable, ni sol haut ni escalier ni eau).
func _is_low(plan: PlanGrid, cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= plan.width or cell.y >= plan.height:
		return false
	var mark := plan.at(cell)
	return plan.walkable.contains(mark) and not HIGH_MARKS.contains(mark) and mark != "w"


## Eau `w` : une bande peinte (texture répétée, coordonnées du monde) par suite horizontale de
## cases d'eau ; entre le sol et les décalcomanies. Null s'il n'y a pas d'eau.
func _water(root: Node, plan: PlanGrid) -> Node2D:
	var cells: Array[Vector2i] = plan.cells_of("w")
	if cells.is_empty():
		return null
	var holder := Node2D.new()
	holder.name = "Eau"
	holder.z_index = -2
	root.add_child(holder)
	holder.owner = root
	var texture: Texture2D = load(GROUND % WATER)
	var runs := 0
	for y: int in plan.height:
		var x := 0
		while x < plan.width:
			if plan.at(Vector2i(x, y)) != "w":
				x += 1
				continue
			var start := x
			while x < plan.width and plan.at(Vector2i(x, y)) == "w":
				x += 1
			var sprite := Sprite2D.new()
			sprite.name = "Bande%03d" % runs
			sprite.texture = texture
			sprite.centered = false
			sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			sprite.region_enabled = true
			sprite.region_rect = Rect2(start * TILE, y * TILE, (x - start) * TILE, TILE)
			sprite.position = Vector2(start * TILE, y * TILE)
			holder.add_child(sprite)
			sprite.owner = root
			runs += 1
	return holder


## Remplace les `Dessin` (Polygon2D) des [FlagGate] connus par l'image peinte, pied au bas de la
## case du portail. Renvoie le nombre de portails repeints.
func _swap_drawings(root: Node) -> int:
	var count := 0
	for gate: Node in root.get_node(^"Entities").get_children():
		var image := ""
		for prefix: String in SWAPS:
			if String(gate.name).begins_with(prefix):
				image = SWAPS[prefix]
				break
		if image.is_empty():
			continue
		var drawings: Array[Node] = []
		for child: Node in gate.get_children():
			if child is Polygon2D or String(child.name).begins_with("Peint"):
				drawings.append(child)
		if drawings.is_empty():
			continue
		for child: Node in drawings:
			gate.remove_child(child)
			child.free()
		var path := (INTERIORS if image.begins_with("decal_") else PROPS) + image + ".png"
		var cells: Array = gate.get(&"blocking_cells") if &"blocking_cells" in gate else []
		var offsets: Array[Vector2] = [Vector2.ZERO]
		if cells.size() > 1:
			offsets.clear()
			for cell: Vector2i in cells:
				offsets.append(Vector2((cell - (cells[0] as Vector2i)) * TILE))
		for k: int in offsets.size():
			var sprite := Sprite2D.new()
			sprite.name = "Peint%d" % k
			sprite.texture = load(path)
			sprite.centered = false
			var size := sprite.texture.get_size()
			sprite.position = offsets[k] + Vector2(-size.x / 2.0, -size.y)
			if image.begins_with("decal_"):
				sprite.position = offsets[k] + Vector2(-size.x / 2.0, -TILE)
				sprite.z_index = -1
			gate.add_child(sprite)
			sprite.owner = root
		count += 1
	return count
