extends SceneTree
## Lot DAF.10c (`tools/art/daf10c.py`, fiche `docs/design/fiches-assets/daf-10c/fiche.md`, RP-275) :
## repeint les cinq étages des Îles Écume (`seafoam_1f` à `_b4f`, J24), écrits en tuiles provisoires
## par `build_j24_seafoam.gd`, en grotte glacée.
##
## Seconde passe d'image (gel du J33), sur le modèle de `build_daf4_caves.gd` ; idempotente (elle
## retire d'abord ses propres nœuds). **La logique ne change pas** : `EtatEtage` (niveaux de sol,
## courants), `Boulders`, trous, rochers tombés, échelles, passages, panneaux et objets cachés sont
## gardés ; les couches de tuiles sont seulement masquées. L'image vient de `tools/cave_map_kit.gd`
## (une racine de kit jetable, dont on adopte les nœuds, préfixe `Daf10c`) :
## - sol peint : sol bas = base (roche gelée), sol haut `:` et escaliers `=` = canal R (glace,
##   nettement plus claire), parois `#` et arêtes `|` = canal G (masse givrée) ; parois glacées en
##   modules sur `#` ;
## - arêtes `|` (bloquées, entre deux niveaux) : rebord peint au sud, bords latéraux à l'est et à
##   l'ouest ; rebords au sud et sur les côtés du sol haut, escaliers `=` peints ;
## - eau `w s ^ v < > ~` (et points de chute `F` dans l'eau, B3F et B4F) : bandes d'eau froide
##   (`ground_eau_grotte_01`) ; les courants actifs sont dessinés par `EtatEtage` (jeu) ;
## - petits rochers fixes `o` et indices `x` : rochers peints sur leurs cases (déjà bloquées) ;
## - dessins provisoires (`Dessin`) des échelles, trous, rochers tombés et panneaux remplacés par
##   des images peintes.
##
##   godot --headless --path . -s res://tools/build_daf10c_seafoam.gd   (code 2 : masques écrits,
##   godot --headless --path . --import                                importer puis relancer)

const Kit := preload("res://tools/cave_map_kit.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const MASK_PATH: String = "res://assets/world/maps/%s_ground.png"
const GROUND: String = "res://assets/world/ground/%s.png"
const INTERIORS: String = "res://assets/world/interiors/"
const PROPS: String = "res://assets/world/props/"
const TILE: int = 96
## Nœuds posés à la racine ; `Daf10cSol` tient les décalcomanies du kit (les étages n'ont pas de
## `GroundDecals` : un nœud préfixé `Daf` laisse `dump_map_nodes.gd` identique).
const OWN_ROOT: Array[String] = ["PaintedGround", "Eau", "Daf10cSol"]
const OWN_PREFIX: String = "Daf10c"
## Carte → graine.
const MAPS: Dictionary = {&"seafoam_1f": 2401, &"seafoam_b1f": 2411, &"seafoam_b2f": 2421,
	&"seafoam_b3f": 2431, &"seafoam_b4f": 2441}
## Étages où les points de chute `F` sont dans l'eau (grille : `sol=eau`).
const WATER_FALLS: Array[StringName] = [&"seafoam_b3f", &"seafoam_b4f"]
const FLOOR_LOW: String = "ground_ecume_bas_01"
const FLOOR_HIGH: String = "ground_glace_01"
const MASS: String = "ground_masse_glace_01"
const WATER: String = "ground_eau_grotte_01"
const WATER_MARKS: String = "ws^v<>~"
const HIGH_MARKS: String = ":="
const WALL_MARKS: String = "#|"
const RIDGE: String = "|"
const LADDERS: String = "UV"
## Frontière bruitée entre deux sols [D].
const BORDER := Color(0.26, 0.32, 0.42)
const FACE: String = "relief_rebord_ecume_01"
const SIDE: String = "relief_rebord_ecume_cote_01"
const STAIRS: String = "relief_escalier_ecume_01"
## Repères bloqués posés sur le sol : caractère → objet peint.
const MARK_PROPS: Dictionary = {"o": "prop_rocher_glace_01", "x": "prop_rocher_grotte_02"}
## Dessins provisoires remplacés : préfixe du nœud → image peinte (pied au bas de la case).
const SWAPS: Dictionary = {
	"TrouOuvert": "decal_trou_ecume_01", "TrouBouche": "decal_trou_ecume_bouche_01",
	"RocherTombe_": "prop_rocher_force_eau_01", "Panneau_": "prop_panneau_01",
}
const SIGN_SCALE: float = 0.58
const LADDER_UP: String = "prop_echelle_monte_01"
const LADDER_DOWN: String = "prop_echelle_descend_01"

var _errors: int = 0
var _masks: int = 0


func _init() -> void:
	var only := OS.get_cmdline_user_args()
	for map_id: StringName in MAPS:
		if only.is_empty() or String(map_id) in only:
			_build(map_id)
	if _errors > 0:
		quit(1)
	elif _masks > 0:
		print("build_daf10c_seafoam : %d masque(s) écrit(s) ; importer (--import) puis relancer" % _masks)
		quit(2)
	else:
		quit(0)


func _build(map_id: StringName) -> void:
	var seed_value: int = MAPS[map_id]
	var plan_path := "res://tools/plans/%s.txt" % map_id
	var plan := PlanGrid.new()
	if not plan.load_file(plan_path):
		push_error("%s : %s" % [map_id, plan.error])
		_errors += 1
		return
	var size := Vector2i(plan.width, plan.height)
	var kit: Object = Kit.new(plan_path, size, seed_value, seed_value + 1, plan.walkable)
	kit.set(&"floor_texture_path", GROUND % FLOOR_LOW)
	kit.set(&"rubble_texture_path", GROUND % FLOOR_HIGH)
	kit.set(&"mass_texture_path", GROUND % MASS)
	kit.set(&"border_color", BORDER)
	kit.set(&"rubble_mark", ":")
	kit.set(&"rubble_is_logic", false)
	kit.set(&"wall_marks", WALL_MARKS)
	kit.set(&"wall_faces", ["relief_paroi_glace_01", "relief_paroi_glace_02"] as Array[String])
	kit.set(&"wall_side", "relief_paroi_glace_05")
	kit.set(&"wall_lip", "relief_paroi_glace_06")
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
	kit.call(&"place_walls", seed_value + 2)
	var marks := _place_levels(kit, plan, map_id)
	var props := _place_marks(kit, plan)
	if not (kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("%s :\n%s" % [map_id, "\n".join(kit.get(&"errors"))])
		_errors += 1
		kit.call(&"discard")
		return
	var path := MAPS_DIR + "%s.tscn" % map_id
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean(root)
	var decals := Node2D.new()
	decals.name = "Daf10cSol"
	decals.z_index = Kit.Z_DECALS
	root.add_child(decals)
	decals.owner = root
	root.move_child(decals, root.get_node(^"Entities").get_index())
	for layer_name: String in ["Ground", "Detail", "Obstacles"]:
		var layer := root.get_node_or_null(NodePath(layer_name)) as TileMapLayer
		if layer != null:
			layer.visible = false
	var painted: Node = kit_root.get_node(^"PaintedGround")
	_adopt(painted, root, root, kit_root)
	root.move_child(painted, root.get_node(^"Obstacles").get_index() + 1)
	var water := _water(root, plan, map_id in WATER_FALLS)
	if water != null:
		root.move_child(water, painted.get_index() + 1)
	for pair: Array in [[kit_root.get_node(^"GroundDecals"), decals],
			[kit_root.get_node(^"Entities"), root.get_node(^"Entities")]]:
		for child: Node in (pair[0] as Node).get_children():
			child.name = OWN_PREFIX + String(child.name)
			_adopt(child, pair[1], root, kit_root)
	var swapped := _swap_drawings(root, plan)
	kit.call(&"discard")
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s : %s (%d rebords et escaliers, %d rochers, %d dessins remplacés)" % [map_id,
		error_string(err), marks, props, swapped])
	if err != OK:
		_errors += 1
	root.free()


## Retire ce que cette passe a posé (relance).
func _clean(root: Node) -> void:
	for node_name: String in OWN_ROOT:
		var old := root.get_node_or_null(NodePath(node_name))
		if old != null:
			root.remove_child(old)
			old.free()
	for parent_name: String in ["Entities"]:
		var parent := root.get_node(NodePath(parent_name))
		for child: Node in parent.get_children():
			if String(child.name).begins_with(OWN_PREFIX):
				parent.remove_child(child)
				child.free()


## Déplace [param node] du kit jetable vers [param parent] de la carte (voir `build_daf4_caves.gd`).
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


## Rebords (face au sud, bords latéraux) du sol haut et des arêtes `|`, escaliers peints, au sol.
## Renvoie le nombre d'objets.
func _place_levels(kit: Object, plan: PlanGrid, map_id: StringName) -> int:
	var count := 0
	var water_falls := map_id in WATER_FALLS
	for cell: Vector2i in plan.cells_of(HIGH_MARKS + RIDGE):
		var mark := plan.at(cell)
		if mark == "=":
			kit.call(&"add_floor_prop", STAIRS, cell, "Stairs%03d" % count)
			count += 1
			continue
		# Sol haut : rebord vers le sol bas ; arête : rebord vers tout sol (bas ou haut).
		var edge := _is_low if mark == ":" else _is_ground
		if edge.call(plan, cell + Vector2i.DOWN, water_falls):
			kit.call(&"add_floor_prop", FACE, cell, "Ledge%03d" % count)
			count += 1
		for dx: int in [-1, 1]:
			if edge.call(plan, cell + Vector2i(dx, 0), water_falls):
				var prop: Node2D = kit.call(&"add_floor_prop", SIDE, cell, "Side%03d" % count)
				prop.position.x += dx * (TILE / 2.0 - 12.0)
				count += 1
	return count


## Petits rochers fixes et indices, sur leurs cases bloquées.
func _place_marks(kit: Object, plan: PlanGrid) -> int:
	var count := 0
	for mark: String in MARK_PROPS:
		for cell: Vector2i in plan.cells_of(mark):
			kit.call(&"add_prop_at", kit.get(&"entities"), MARK_PROPS[mark], cell, "Rocher%03d" % count)
			count += 1
	return count


func _in(plan: PlanGrid, cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < plan.width and cell.y < plan.height


func _is_water(plan: PlanGrid, cell: Vector2i, water_falls: bool) -> bool:
	var mark := plan.at(cell)
	return WATER_MARKS.contains(mark) or (water_falls and mark == "F")


## Case de sol bas (praticable, ni sol haut ni escalier ni eau ; une échelle `U V` prend le
## niveau de ses voisines : pas de rebord autour d'elle).
func _is_low(plan: PlanGrid, cell: Vector2i, water_falls: bool) -> bool:
	if not _in(plan, cell):
		return false
	var mark := plan.at(cell)
	return plan.walkable.contains(mark) and not (HIGH_MARKS + LADDERS).contains(mark) \
		and not _is_water(plan, cell, water_falls)


## Case de sol praticable, bas ou haut (pas l'eau).
func _is_ground(plan: PlanGrid, cell: Vector2i, water_falls: bool) -> bool:
	if not _in(plan, cell):
		return false
	return plan.walkable.contains(plan.at(cell)) and not _is_water(plan, cell, water_falls)


## Eau : une bande peinte (texture répétée, coordonnées du monde) par suite horizontale de cases
## d'eau ; entre le sol et les décalcomanies. Null s'il n'y a pas d'eau.
func _water(root: Node, plan: PlanGrid, water_falls: bool) -> Node2D:
	var holder := Node2D.new()
	holder.name = "Eau"
	holder.z_index = -2
	var texture: Texture2D = load(GROUND % WATER)
	var runs := 0
	for y: int in plan.height:
		var x := 0
		while x < plan.width:
			if not _is_water(plan, Vector2i(x, y), water_falls):
				x += 1
				continue
			var start := x
			while x < plan.width and _is_water(plan, Vector2i(x, y), water_falls):
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
			runs += 1
	if runs == 0:
		holder.free()
		return null
	root.add_child(holder)
	holder.owner = root
	for child: Node in holder.get_children():
		child.owner = root
	return holder


## Remplace les `Dessin` (Polygon2D) des nœuds connus par l'image peinte, pied au bas de la case.
## Échelles : montante ou descendante selon la grille (`sens=`). Renvoie le nombre de nœuds repeints.
func _swap_drawings(root: Node, plan: PlanGrid) -> int:
	var ladders := _ladder_images(plan)
	var count := 0
	for gate: Node in root.get_node(^"Entities").get_children():
		var gate_name := String(gate.name)
		var image := ""
		if gate_name.begins_with("EchelleDessin_"):
			var xy := gate_name.trim_prefix("EchelleDessin_").split("_")
			image = ladders.get(Vector2i(int(xy[0]), int(xy[1])), LADDER_UP)
		else:
			for prefix: String in SWAPS:
				if gate_name.begins_with(prefix):
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
		var sprite := Sprite2D.new()
		sprite.name = "Peint0"
		sprite.texture = load((INTERIORS if image.begins_with("decal_") else PROPS) + image + ".png")
		sprite.centered = false
		var size := sprite.texture.get_size()
		sprite.position = Vector2(-size.x / 2.0, -size.y)
		if image.begins_with("decal_"):
			sprite.position = Vector2(-size.x / 2.0, -TILE)
			sprite.z_index = -1
		elif image == SWAPS["Panneau_"]:
			# Le panneau de bois des routes (≈ 1,8 case) ramené à une case [D].
			sprite.scale = Vector2.ONE * SIGN_SCALE
			sprite.position = Vector2(-size.x / 2.0, -size.y) * SIGN_SCALE
		elif image == LADDER_DOWN or image == LADDER_UP:
			sprite.position = Vector2(-size.x / 2.0, -minf(size.y, TILE * 2.0))
		gate.add_child(sprite)
		sprite.owner = root
		count += 1
	return count


## Case d'échelle → image (montante ou descendante), d'après les positions `echelle` de la grille.
func _ladder_images(plan: PlanGrid) -> Dictionary:
	var images: Dictionary = {}
	for id: String in plan.positions:
		if not id.begins_with("echelle_"):
			continue
		var image := LADDER_DOWN if plan.attr(id, "sens") == "descend" else LADDER_UP
		for cell: Vector2i in plan.cells_at(id):
			images[cell] = image
	return images
