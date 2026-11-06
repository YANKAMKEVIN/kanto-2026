extends SceneTree
## Peinture des Ruines d'Alpha, dernière passe (JOHP1, demande de Kevin du 2026-11-06). Ordre :
##   godot --headless --path . -s res://tools/build_johp1_maps.gd
##   godot --headless --path . -s res://tools/build_joh_ambiance.gd -- --maps=ruins_of_alph,route_36
##   godot --headless --path . -s res://tools/build_joh_ambiance_caves.gd -- --maps=alph_gallery,alph_chamber
##   godot --headless --path . -s res://tools/build_joh_ambiance_alpha.gd
##
## **Tente** (`alph_tent`) : fond peint de la pièce, caisses, tapis et table, d'après la vue générale.
## **Galerie** et **Chambre** : ce que `build_joh_ambiance_caves.gd` ne pose pas : dalles sous les
## signes, escaliers, porte du fond, bâche, frise, socle, Pierre Mémoire. Les murs passent de
## `Entities` à la couche du sol : `Decor`, où sont gravés les signes des parois, reste au-dessus.
## **La logique ne change pas** : `Sprite2D` seuls, sans emprise. Les [FlagGate] gardent leurs
## conditions ; seuls leurs dessins provisoires sont remplacés. Idempotente (préfixe `JohAmbAlpha`).
## Contrôle : `tools/dump_map_logic.gd` et `tools/dump_map_nodes.gd` identiques avant / après.

const MAPS_DIR: String = "res://game/world/maps/"
const PROPS: String = "res://assets/world/props/%s.png"
const RELIEF: String = "res://assets/world/relief/%s.png"
const INT: String = "res://assets/world/interiors/%s.png"
const PROP_MATERIAL: String = "res://game/world/lighting/materials/world_object.tres"
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const OWN_PREFIX: String = "JohAmbAlpha"
const CAVE_FLOOR: NodePath = ^"JohAmbCaveSol"
const CAVE_ENTITIES_PREFIX: String = "JohAmbCave"
const TILE: int = 96
## Modules de mur à descendre sur la couche du sol.
const WALL_PREFIXES: Array[String] = ["Face", "Side"]
const LADDER_PREFIX: String = "Ladder"
## Pierre usée des escaliers, de la Galerie à la Chambre [D].
const STONE_TINT := Color(0.8, 0.84, 0.96)
const SLAB_TINT := Color(0.86, 0.88, 0.92)
## Dalle d'un signe : case marquée `t`, un peu plus petite que la case.
const TILE_MARK: String = "t"
## Tapis de la vue, sous la table (cases) [D].
const RUG_CENTRE := Vector2(3.0, 3.6)
const CRATES_FOOT := Vector2(4.5, 2.0)
const TABLE_FOOT := Vector2(3.0, 4.0)
## Escaliers : [image, centre (cases), rotation].
const GALLERY_STAIRS: Array = [[Vector2(5.0, 12.25), 0.0], [Vector2(17.0, 2.25), 0.0]]
const CHAMBER_STAIRS: Array = [[Vector2(7.0, 10.75), PI]]
const WALL_3_CELL := Vector2i(16, 15)
const GALLERY_CAMP_FOOT := Vector2(5.0, 3.0)
const FRIEZE_FOOT := Vector2(7.0, 2.0)
const PLINTH_CENTRE := Vector2(7.0, 3.55)
const DOOR_TOP: float = -144.0
const STONE_FOOT_Y: float = -58.0

var _errors: int = 0


func _init() -> void:
	_tent()
	_gallery()
	_chamber()
	print("build_joh_ambiance_alpha : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _open(map_id: String) -> Node2D:
	var root := (load(MAPS_DIR + map_id + ".tscn") as PackedScene).instantiate(
		PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_remove_own(root)
	return root


func _remove_own(root: Node) -> void:
	for parent: Node in [root, root.get_node(^"Entities"), root.get_node_or_null(CAVE_FLOOR)]:
		if parent == null:
			continue
		for child: Node in parent.get_children():
			if String(child.name).begins_with(OWN_PREFIX):
				parent.remove_child(child)
				child.free()


func _save(root: Node2D, map_id: String) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, MAPS_DIR + map_id + ".tscn")
	print("%s : %s" % [map_id, error_string(err)])
	if err != OK:
		_errors += 1
	root.free()


func _sprite(root: Node, parent: Node, path: String, node_name: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = OWN_PREFIX + node_name
	sprite.texture = load(path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(sprite)
	sprite.owner = root
	return sprite


## Image posée par son pied (bas et milieu).
func _standing(root: Node, parent: Node, path: String, foot: Vector2, node_name: String) -> Sprite2D:
	var sprite := _sprite(root, parent, path, node_name)
	var size := sprite.texture.get_size()
	sprite.centered = false
	sprite.offset = Vector2(-size.x / 2.0, -size.y)
	sprite.position = foot * TILE
	sprite.material = load(PROP_MATERIAL)
	return sprite


func _tent() -> void:
	var root := _open("alph_tent")
	for layer: Node in root.get_children():
		if layer is TileMapLayer:
			(layer as TileMapLayer).visible = false
	_clear_polygons(root.get_node(^"Decor"))
	var entities := root.get_node(^"Entities")
	var back := _sprite(root, root, INT % "int_fond_tente_01", "Fond")
	back.centered = false
	root.move_child(back, root.get_node(^"Obstacles").get_index() + 1)
	var rug := _sprite(root, root, INT % "int_tapis_tente_01", "Tapis")
	rug.position = RUG_CENTRE * TILE
	root.move_child(rug, back.get_index() + 1)
	_standing(root, entities, INT % "int_caisses_tente_01", CRATES_FOOT, "Caisses")
	_standing(root, entities, INT % "int_table_tente_01", TABLE_FOOT, "Table")
	_save(root, "alph_tent")


## Murs vers la couche du sol, échelles de la passe des grottes retirées.
func _settle_cave(root: Node) -> Node:
	var floor_layer := root.get_node(CAVE_FLOOR)
	var entities := root.get_node(^"Entities")
	for child: Node in entities.get_children():
		var label := String(child.name)
		if not label.begins_with(CAVE_ENTITIES_PREFIX):
			continue
		var short := label.trim_prefix(CAVE_ENTITIES_PREFIX)
		if short.begins_with(LADDER_PREFIX):
			entities.remove_child(child)
			child.free()
		elif WALL_PREFIXES.any(func(prefix: String) -> bool: return short.begins_with(prefix)):
			entities.remove_child(child)
			floor_layer.add_child(child)
			child.owner = root
	return floor_layer


func _stairs(root: Node, floor_layer: Node, entries: Array) -> void:
	var index := 0
	for entry: Array in entries:
		var flight := _sprite(root, floor_layer, RELIEF % "relief_escalier_galerie_01",
			"Escalier%d" % index)
		flight.position = (entry[0] as Vector2) * TILE
		flight.rotation = entry[1]
		flight.modulate = STONE_TINT
		index += 1


func _gallery() -> void:
	var root := _open("alph_gallery")
	var floor_layer := _settle_cave(root)
	var plan := PlanGrid.new()
	plan.load_file("res://tools/plans/alph_gallery.txt")
	for cell: Vector2i in plan.cells_of(TILE_MARK):
		var slab := _sprite(root, floor_layer, RELIEF % "relief_dalle_glyphe_01",
			"Dalle_%d_%d" % [cell.x, cell.y])
		slab.position = (Vector2(cell) + Vector2(0.5, 0.5)) * TILE
		slab.modulate = SLAB_TINT
	# Le signe du mur sud n'a pas de face où se poser : une dalle dressée sur le chaperon.
	var plaque := _sprite(root, floor_layer, RELIEF % "relief_dalle_glyphe_01", "PlaqueMur3")
	plaque.position = (Vector2(WALL_3_CELL) + Vector2(0.5, 0.5)) * TILE
	plaque.modulate = SLAB_TINT
	_stairs(root, floor_layer, GALLERY_STAIRS)
	_standing(root, floor_layer, PROPS % "prop_camp_alpha_01", GALLERY_CAMP_FOOT, "Camp")
	# Porte du fond : même [FlagGate], l'image remplace l'aplat.
	var door := root.get_node(^"Entities/PorteFond")
	_clear_polygons(door)
	var slab_door := _sprite(root, door, PROPS % "prop_porte_alpha_01", "Image")
	slab_door.centered = false
	slab_door.position = Vector2(-TILE / 2.0, DOOR_TOP)
	_save(root, "alph_gallery")


func _chamber() -> void:
	var root := _open("alph_chamber")
	var floor_layer := _settle_cave(root)
	_stairs(root, floor_layer, CHAMBER_STAIRS)
	_standing(root, floor_layer, RELIEF % "relief_frise_alpha_01", FRIEZE_FOOT, "Frise")
	var plinth := _sprite(root, floor_layer, PROPS % "prop_socle_alpha_01", "Socle")
	plinth.position = PLINTH_CENTRE * TILE
	var stone := root.get_node(^"Decor/PierreMemoire")
	_clear_polygons(stone)
	var image := _sprite(root, stone, PROPS % "prop_pierre_memoire_01", "Image")
	image.position = Vector2(TILE / 2.0, STONE_FOOT_Y)
	_save(root, "alph_chamber")


func _clear_polygons(parent: Node) -> void:
	for child: Node in parent.get_children():
		if child is Polygon2D:
			parent.remove_child(child)
			child.free()
