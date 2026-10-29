extends SceneTree
## Lot DAF.9 (`tools/art/daf9.py`, fiche `docs/design/fiches-assets/daf-9/fiche.md`, RP-024) :
## repeint Cramois'Île (`cinnabar_island`), écrite en tuiles provisoires par `build_j24_sea.gd`
## (J24) avec des façades en aplats.
##
## Passe APRÈS cet outil, sur le modèle de `build_daf4_exterieurs.gd` et `build_daf4_facades.gd` ;
## idempotente (elle retire d'abord ses propres nœuds). **La logique ne change pas** (gel du J33) :
## les couches de tuiles (dont `Ground`, source logique) sont seulement masquées ; portes,
## apparitions, panneaux, déclencheurs et [FlagGate] restent tels quels, seuls leurs dessins
## provisoires (`Polygon2D`) sont retirés. Les façades sont des objets peints (`WorldProp`) dont
## l'emprise est exactement celle des cases du bâtiment (portes libres) : la grille ne change pas.
## Contrôle : `tools/dump_map_logic.gd` et `tools/dump_map_nodes.gd` identiques avant / après.
##
## - sol peint : terre volcanique (base), sable noir de la plage `y` (canal R), roche volcanique des
##   récifs `R` (canal G), mer `w` (rivage naturel, écume) ;
## - façades : Manoir en ruine, Arène, Labo (neuves, 9 × 6), Centre et Boutique (existantes) ;
## - panneaux peints (images accrochées aux panneaux existants).
##
##   godot --headless --path . -s res://tools/build_daf9_ile.gd   (code 2 : masque écrit,
##   godot --headless --path . --import                          importer puis relancer)

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAP_ID: StringName = &"cinnabar_island"
const MAP_PATH: String = "res://game/world/maps/cinnabar_island.tscn"
const PLAN_PATH: String = "res://tools/plans/cinnabar_island.txt"
const MASK_PATH: String = "res://assets/world/maps/cinnabar_island_ground.png"
const GROUND: String = "res://assets/world/ground/%s.png"
const PROPS: String = "res://game/world/props/painted/%s.tscn"
const TILE: int = 96
const OWN_ROOT: Array[String] = ["PaintedGround"]
const OWN_PREFIX: String = "Daf9"
const SAND_MARK: String = "y"
const REEF_MARK: String = "R"
const WATER_MARK: String = "w"
## Bâtiment de la grille → [objet peint, pied (cases : x au milieu de l'emprise, y = bas)].
const FACADES: Dictionary = {
	"M": ["bldg_manoir_ruine_01", Vector2(10.5, 6.0)],
	"Z": ["bldg_arene_cramois_01", Vector2(25.5, 6.0)],
	"L": ["bldg_labo_cramois_01", Vector2(10.5, 15.0)],
	"C": ["bldg_centre_01", Vector2(20.0, 18.0)],
	"O": ["bldg_boutique_01", Vector2(29.0, 18.0)],
}
const EARTH := Color(0.36, 0.30, 0.25)


func _init() -> void:
	quit(_build())


func _build() -> int:
	var plan := PlanGrid.new()
	if not plan.load_file(PLAN_PATH):
		push_error(plan.error)
		return 1
	var size := Vector2i(plan.width, plan.height)
	var mask := Image.create(size.x, size.y, false, Image.FORMAT_RG8)
	for cell: Vector2i in plan.cells_of(SAND_MARK):
		mask.set_pixelv(cell, Color(1.0, 0.0, 0.0))
	for cell: Vector2i in plan.cells_of(REEF_MARK):
		mask.set_pixelv(cell, Color(0.0, 1.0, 0.0))
	if not _write_image(mask, MASK_PATH):
		print("build_daf9_ile : masque écrit ; importer (--import) puis relancer")
		return 2
	var water: Dictionary = {}
	for cell: Vector2i in plan.cells_of(WATER_MARK):
		water[cell] = true
	var shore: Image = (load("res://game/world/ground/ground_mask.gd") as GDScript).call(
		&"build_water", size, water)
	var root := (load(MAP_PATH) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean(root)
	for layer: Node in root.get_children():
		if layer is TileMapLayer:
			(layer as TileMapLayer).visible = false
	var base: Texture2D = load(GROUND % "ground_volcanique_01")
	var painted := Node2D.new()
	painted.set_script(load("res://game/world/ground/painted_ground.gd"))
	painted.name = "PaintedGround"
	painted.set(&"size", size)
	painted.set(&"mask", load(MASK_PATH))
	painted.set(&"base_texture", base)
	painted.set(&"r_texture", load(GROUND % "ground_sable_noir_01"))
	painted.set(&"g_texture", load(GROUND % "ground_roche_volcanique_01"))
	painted.set(&"shore_mask", ImageTexture.create_from_image(shore))
	painted.set(&"water_texture", load(GROUND % "ground_eau_01"))
	var material := painted.call(&"get_shader_material") as ShaderMaterial
	material.set_shader_parameter(&"texture_size", float(base.get_width()))
	material.set_shader_parameter(&"paving_scale", 1.0)
	material.set_shader_parameter(&"path_scale", 1.0)
	material.set_shader_parameter(&"earth_color", EARTH)
	root.add_child(painted)
	painted.owner = root
	root.move_child(painted, root.get_node(^"Obstacles").get_index() + 1)
	var entities := root.get_node(^"Entities")
	var removed := 0
	for child: Node in entities.get_children():
		var n := String(child.name)
		if n.begins_with("Batiment_") or n.begins_with("Porte_") or n.begins_with("Panneau_"):
			for drawing: Node in child.get_children():
				if drawing is Polygon2D:
					child.remove_child(drawing)
					drawing.free()
					removed += 1
	for mark: String in FACADES:
		var spec: Array = FACADES[mark]
		_prop(root, entities, "%sFacade_%s" % [OWN_PREFIX, mark], spec[0], (spec[1] as Vector2) * TILE)
	# Panneaux : image seule accrochée au [FlagGate] du panneau (sa case est déjà bloquée par lui ;
	# un `WorldProp` ajouterait une emprise à la grille statique).
	var sign: Texture2D = load("res://assets/world/props/prop_panneau_01.png")
	for child: Node in entities.get_children():
		if String(child.name).begins_with("Panneau_"):
			var s := Sprite2D.new()
			s.name = OWN_PREFIX + "Panneau"
			s.texture = sign
			s.centered = false
			s.offset = Vector2(-sign.get_width() / 2.0, -sign.get_height())
			child.add_child(s)
			s.owner = root
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, MAP_PATH)
	print("%s : %s (%d dessins retirés)" % [MAP_ID, error_string(err), removed])
	root.free()
	return 0 if err == OK else 1


func _prop(root: Node, parent: Node, node_name: String, id: String, foot: Vector2) -> void:
	var prop := (load(PROPS % id) as PackedScene).instantiate(
		PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	prop.position = foot
	parent.add_child(prop)
	prop.owner = root


func _write_image(image: Image, path: String) -> bool:
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute):
		var old := Image.load_from_file(absolute)
		if old != null:
			old.convert(image.get_format())
			if old.get_data() == image.get_data() and ResourceLoader.exists(path):
				return true
	image.save_png(absolute)
	return false


func _clean(root: Node) -> void:
	for node_name: String in OWN_ROOT:
		var old := root.get_node_or_null(NodePath(node_name))
		if old != null:
			root.remove_child(old)
			old.free()
	var entities := root.get_node(^"Entities")
	for child: Node in entities.get_children():
		if String(child.name).begins_with(OWN_PREFIX):
			entities.remove_child(child)
			child.free()
			continue
		for sprite: Node in child.get_children():
			if String(sprite.name).begins_with(OWN_PREFIX):
				child.remove_child(sprite)
				sprite.free()
