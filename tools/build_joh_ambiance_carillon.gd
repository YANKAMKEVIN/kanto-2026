extends SceneTree
## Peinture de la Tour Carillon, dernière passe (JOH8, 2026-11-06), d'après les vues générales
## validées (`tour-carillon-*-vue-generale-v1.png`, `bois-de-la-tour-*`). Ordre :
##   godot --headless --path . -s res://tools/build_joh8_maps.gd
##   godot --headless --path . -s res://tools/build_joh_ambiance.gd -- --maps=bell_tower_woods
##   godot --headless --path . -s res://tools/build_joh_ambiance_caves.gd -- --maps=bell_tower_1f,bell_tower_2f
##   godot --headless --path . -s res://tools/build_joh_ambiance_carillon.gd
##
## **Bois** : retire les dessins provisoires des lanternes (leurs [FlagGate] gardent leurs cases).
## **1F et 2F** : colonnes, autel, brûle-parfums, escaliers, porte ; dessins provisoires retirés.
## **Sommet** (sans le kit des grottes : toit à ciel ouvert) : paysage lointain, dalles, rambarde,
## palier, grande cloche, brûle-parfums, cage de feu, dans sa [FlagGate] `CageDeFeu`.
## **La logique ne change pas** : images et objets sans emprise ; les cases restent celles des
## grilles. Idempotente (préfixe `JohAmbCarillon`). Ne nomme aucun autoload : `godot -s` les
## réenregistrerait dans des cartes dégradées.
## Contrôle : `tools/dump_map_logic.gd` et `tools/dump_map_nodes.gd` identiques avant / après.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const PROP_SCENE: String = "res://game/world/props/painted/%s.tscn"
const PROPS: String = "res://assets/world/props/%s.png"
const RELIEF: String = "res://assets/world/relief/%s.png"
const INT: String = "res://assets/world/interiors/%s.png"
const GROUND: String = "res://assets/world/ground/%s.png"
const BACKDROP: String = "res://assets/world/backdrops/backdrop_vue_carillon_01.png"
const PROP_MATERIAL: String = "res://game/world/lighting/materials/world_object.tres"
const OWN_PREFIX: String = "JohAmbCarillon"
const CAVE_FLOOR: NodePath = ^"JohAmbCaveSol"
const TILE: int = 96
const COLUMN: String = "int_colonne_rouge_01"
const BURNER: String = "int_brule_parfum_01"
const ALTAR: String = "int_autel_carillon_01"
const BELL: String = "int_grande_cloche_01"
const STAIRS: String = "relief_escalier_carillon_01"
const RAIL_H: String = "int_rambarde_rouge_h_01"
const RAIL_V: String = "int_rambarde_rouge_v_01"
const PARTITION: String = "int_cloison_palier_01"
## Pièces de la grille : [case, objet] ; pied au milieu du bas de la case.
const HALL_BURNERS: Array[Vector2i] = [Vector2i(2, 2), Vector2i(2, 21), Vector2i(21, 21)]
const ALTAR_FOOT := Vector2(12.0, 3.0)
const BELL_FOOT := Vector2(10.0, 4.0)
## Sommet : modules de rambarde (cases), trappe du nord laissée libre.
const ROOF_SIZE: int = 20
## Escalier qui descend : le même, plus sombre [D].
const STAIRS_DOWN_TINT := Color(0.62, 0.6, 0.64)
## Lueur d'un brûle-parfum la nuit : décalage de sa tête depuis son pied (pixels) [D].
const BURNER_HEAD := Vector2(0.0, -96.0)
const RAIL_SPAN: int = 4
const HATCH_COLUMN: int = 3
## Le paysage déborde de la carte des deux côtés (S24 : 24,4 cases de large) [D].
const BACKDROP_MARGIN: int = 5 * TILE
## Palier : cloison [pied (cases)], montant [pied (cases)].
const PARTITIONS: Array[Vector2] = [Vector2(2.0, 4.0), Vector2(4.5, 4.0)]
const LANDING_POST := Vector2(5.5, 4.0)
## Cage : pied de l'image, relatif à la carte (cases) ; lueur au sol sous elle, force [D].
const CAGE_FOOT := Vector2(12.5, 9.0)
const CAGE_GLOW_CENTRE := Vector2(12.5, 7.5)
const CAGE_GLOW_ALPHA: float = 0.7
const CAGE_GLOW_SCALE: float = 1.2

var _errors: int = 0


func _init() -> void:
	_woods()
	_hall()
	_upper_floor()
	_roof()
	print("build_joh_ambiance_carillon : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _open(map_id: String) -> Node2D:
	var root := (load(MAPS_DIR + map_id + ".tscn") as PackedScene).instantiate(
		PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	for parent: Node in [root, root.get_node(^"Entities"), root.get_node_or_null(CAVE_FLOOR)]:
		if parent == null:
			continue
		for child: Node in parent.get_children():
			if String(child.name).begins_with(OWN_PREFIX):
				parent.remove_child(child)
				child.free()
	return root


func _save(root: Node2D, map_id: String) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, MAPS_DIR + map_id + ".tscn")
	print("%s : %s" % [map_id, error_string(err)])
	if err != OK:
		_errors += 1
	root.free()


func _plan(map_id: String) -> Object:
	var plan := PlanGrid.new()
	if not plan.load_file("res://tools/plans/%s.txt" % map_id):
		push_error("%s : %s" % [map_id, plan.error])
		_errors += 1
	return plan


## Objet peint du catalogue (ombre et contact), sans emprise : ses cases sont celles de la grille.
func _prop(root: Node, id: String, foot: Vector2, node_name: String) -> Node2D:
	var prop := (load(PROP_SCENE % id) as PackedScene).instantiate(
		PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = OWN_PREFIX + node_name
	prop.position = (foot * TILE).round()
	prop.set(&"footprint", [] as Array[Vector2i])
	root.get_node(^"Entities").add_child(prop)
	prop.owner = root
	return prop


func _sprite(root: Node, parent: Node, path: String, node_name: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = OWN_PREFIX + node_name
	sprite.texture = load(path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(sprite)
	sprite.owner = root
	return sprite


## Image posée par son pied (bas et milieu), en cases.
func _standing(root: Node, parent: Node, path: String, foot: Vector2, node_name: String) -> Sprite2D:
	var sprite := _sprite(root, parent, path, node_name)
	var size := sprite.texture.get_size()
	sprite.centered = false
	sprite.offset = Vector2(-size.x / 2.0, -size.y)
	sprite.position = foot * TILE
	sprite.material = load(PROP_MATERIAL)
	return sprite


## Dessins provisoires de `build_joh8_maps.gd` sous [param parent].
func _clear_drawings(parent: Node) -> void:
	for child: Node in parent.get_children():
		if child is Polygon2D or child is Line2D:
			parent.remove_child(child)
			child.free()


func _clear_gates(root: Node, prefix: String) -> void:
	for child: Node in root.get_node(^"Entities").get_children():
		if String(child.name).begins_with(prefix):
			_clear_drawings(child)


func _woods() -> void:
	var root := _open("bell_tower_woods")
	_clear_gates(root, "Lanterne_")
	_save(root, "bell_tower_woods")


## Colonnes `M` de [param plan], sauf les brûle-parfums de [param burners].
func _columns(root: Node, plan: Object, burners: Array[Vector2i]) -> void:
	for cell: Vector2i in plan.cells_of("M"):
		var foot := Vector2(cell) + Vector2(0.5, 1.0)
		var id := BURNER if burners.has(cell) else COLUMN
		_prop(root, id, foot, "Piece_%d_%d" % [cell.x, cell.y])


## Escalier pris dans le mur du nord : sur la couche du sol, sous les personnages.
func _wall_stairs(root: Node, cell: Vector2i, turned: bool) -> void:
	var flight := _sprite(root, root.get_node(CAVE_FLOOR), RELIEF % STAIRS,
		"Escalier_%d" % cell.x)
	flight.position = (Vector2(cell) + Vector2(0.5, 0.75)) * TILE
	if turned:
		flight.modulate = STAIRS_DOWN_TINT


func _hall() -> void:
	var root := _open("bell_tower_1f")
	var plan := _plan("bell_tower_1f")
	_clear_drawings(root.get_node(^"Decor"))
	_columns(root, plan, HALL_BURNERS)
	_prop(root, ALTAR, ALTAR_FOOT, "Autel")
	_wall_stairs(root, Vector2i(20, 0), false)
	var door := _sprite(root, root.get_node(CAVE_FLOOR), INT % "int_porte_carillon_01", "Porte")
	door.centered = false
	var size := door.texture.get_size()
	door.position = Vector2(12.0 * TILE - size.x / 2.0, 24.0 * TILE - size.y)
	_save(root, "bell_tower_1f")


func _upper_floor() -> void:
	var root := _open("bell_tower_2f")
	var plan := _plan("bell_tower_2f")
	_clear_drawings(root.get_node(^"Decor"))
	_clear_gates(root, "Planche_")
	_columns(root, plan, [] as Array[Vector2i])
	_wall_stairs(root, Vector2i(3, 0), false)
	_wall_stairs(root, Vector2i(20, 0), true)
	_save(root, "bell_tower_2f")


func _roof() -> void:
	var root := _open("bell_tower_roof")
	var plan := _plan("bell_tower_roof")
	_clear_drawings(root.get_node(^"Decor"))
	for layer: Node in root.get_children():
		if layer is TileMapLayer:
			(layer as TileMapLayer).visible = false
	var index := root.get_node(^"Obstacles").get_index() + 1
	var span := ROOF_SIZE * TILE
	var view := _sprite(root, root, BACKDROP, "Paysage")
	view.centered = false
	var view_size := view.texture.get_size()
	var cover := float(span + BACKDROP_MARGIN * 2) / view_size.x
	view.scale = Vector2.ONE * maxf(cover, float(span) / view_size.y)
	view.position = Vector2(-BACKDROP_MARGIN, 0.0)
	view.z_index = -3
	root.move_child(view, index)
	var slabs := _sprite(root, root, GROUND % "ground_dalles_sommet_01", "Dalles")
	slabs.centered = false
	slabs.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	slabs.region_enabled = true
	slabs.region_rect = Rect2(0.0, 0.0, span, span)
	slabs.z_index = -2
	root.move_child(slabs, index + 1)
	var hatch := _sprite(root, root, RELIEF % STAIRS, "Trappe")
	hatch.position = (Vector2(HATCH_COLUMN, 0.0) + Vector2(0.5, 0.75)) * TILE
	hatch.modulate = STAIRS_DOWN_TINT
	hatch.z_index = -1
	root.move_child(hatch, index + 2)
	_rails(root)
	for at: int in PARTITIONS.size():
		_standing(root, root.get_node(^"Entities"), INT % PARTITION, PARTITIONS[at],
			"Cloison%d" % at)
	var post := _standing(root, root.get_node(^"Entities"), INT % RAIL_V, LANDING_POST, "Montant")
	post.region_enabled = true
	post.region_rect = Rect2(0.0, 0.0, 48.0, 288.0)
	post.offset = Vector2(-24.0, -288.0)
	_prop(root, BELL, BELL_FOOT, "Cloche")
	for cell: Vector2i in plan.cells_of("M"):
		_prop(root, BURNER, Vector2(cell) + Vector2(0.5, 1.0), "Brule_%d_%d" % [cell.x, cell.y])
	_cage(root)
	_night_lights(root, plan)
	_save(root, "bell_tower_roof")


## Lueurs des brûle-parfums, sur le calque de nuit des cartes peintes (`build_joh_ambiance.gd`).
func _night_lights(root: Node, plan: Object) -> void:
	var old := root.get_node_or_null(^"NightLights")
	if old != null:
		root.remove_child(old)
		old.free()
	var layer := CanvasLayer.new()
	layer.name = "NightLights"
	layer.layer = UiTokens.LAYER_NIGHT_LIGHTS
	layer.follow_viewport_enabled = true
	root.add_child(layer)
	layer.owner = root
	var index := 0
	for cell: Vector2i in plan.cells_of("M"):
		var glow := Sprite2D.new()
		glow.set_script(load("res://game/world/lighting/light_glow.gd"))
		glow.name = "Lampe%02d" % index
		glow.set(&"glow_type", &"night_lamp")
		glow.position = ((Vector2(cell) + Vector2(0.5, 1.0)) * TILE + BURNER_HEAD).round()
		glow.visible = false  # écrasé par LightGlow._ready : Boot rappelle set_night
		glow.add_to_group(&"night_lights", true)
		layer.add_child(glow)
		glow.owner = root
		index += 1


## Rambarde du tour de la carte, posée sur les cases `r` ; la trappe reste ouverte.
func _rails(root: Node) -> void:
	var entities := root.get_node(^"Entities")
	# Rangée, début, fin (cases) ; le nord s'interrompt à la trappe.
	for run: Vector3i in [Vector3i(0, 0, HATCH_COLUMN), Vector3i(0, HATCH_COLUMN + 1, ROOF_SIZE),
			Vector3i(ROOF_SIZE - 1, 0, ROOF_SIZE)]:
		for x: int in range(run.y, run.z, RAIL_SPAN):
			var width := mini(RAIL_SPAN, run.z - x)
			var rail := _standing(root, entities, INT % RAIL_H,
				Vector2(x + width / 2.0, run.x + 1.0), "RambardeH_%d_%d" % [run.x, x])
			rail.region_enabled = true
			rail.region_rect = Rect2(0.0, 0.0, width * TILE, TILE)
			rail.offset = Vector2(-width * TILE / 2.0, -TILE)
	for column: int in [0, ROOF_SIZE - 1]:
		for y: int in range(1, ROOF_SIZE - 1, RAIL_SPAN):
			var height := mini(RAIL_SPAN, ROOF_SIZE - 1 - y)
			var rail := _standing(root, entities, INT % RAIL_V,
				Vector2(column + 0.5, y + height), "RambardeV_%d_%d" % [column, y])
			rail.region_enabled = true
			rail.region_rect = Rect2(0.0, 0.0, 48.0, height * TILE)
			rail.offset = Vector2(-24.0, -height * TILE)


## Cage de feu : l'image et sa lueur remplacent les aplats, dans la même [FlagGate].
func _cage(root: Node) -> void:
	var gate := root.get_node(^"Entities/CageDeFeu") as Node2D
	_clear_drawings(gate)
	for child: Node in gate.get_children():
		if String(child.name).begins_with(OWN_PREFIX):
			gate.remove_child(child)
			child.free()
	var glow := _sprite(root, gate, PROPS % "prop_lueur_cage_01", "Lueur")
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	glow.position = CAGE_GLOW_CENTRE * TILE - gate.position
	glow.scale = Vector2.ONE * CAGE_GLOW_SCALE
	glow.modulate.a = CAGE_GLOW_ALPHA
	glow.z_index = -1  # au sol : sous Entei, dans la cage
	var bars := _sprite(root, gate, PROPS % "prop_cage_feu_01", "Barreaux")
	var size := bars.texture.get_size()
	bars.centered = false
	bars.offset = Vector2(-size.x / 2.0, -size.y)
	bars.position = CAGE_FOOT * TILE - gate.position
