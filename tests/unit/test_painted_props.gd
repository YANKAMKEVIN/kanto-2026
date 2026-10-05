extends GutTest
## Objets peints (docs/tech/jalon-07.md §6.6, T3) : une scène WorldProp par objet du
## catalogue, emprise sur la grille de 96 px (règles du prototype), ombres pré-floutées, relief
## dans la couche du sol.

const CATALOGUE := "res://assets/world/catalogue.json"
const MANIFEST := "res://tools/art/manifeste.json"
const SCENES := "res://game/world/props/painted/"
## Les seuls objets peints qu'on traverse (jalon-07.md §6.6).
## Série 07 : murs de soutènement et escaliers de ville (la carte bloque la rangée du mur).
const TRAVERSABLE: Array[StringName] = [&"relief_escalier_01", &"ground_hautes_herbes_01",
	&"relief_muret_01", &"relief_escalier_ville_01"]
const GROUND_LAYER: Array[StringName] = [
	&"relief_falaise_01", &"relief_escalier_01", &"prop_massif_01", &"relief_muret_01",
	&"relief_escalier_ville_01",
]

var _objects: Dictionary = {}


func before_all() -> void:
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	_objects = catalogue["objets"]


func _scene(id: String) -> WorldProp:
	var packed := load(SCENES + id + ".tscn") as PackedScene
	if packed == null:
		return null
	var prop := packed.instantiate() as WorldProp
	autofree(prop)
	return prop


func test_every_catalogue_object_has_a_rule_and_a_scene() -> void:
	assert_gt(_objects.size(), 20)
	for id: String in _objects:
		assert_true(PaintedPropRules.has_rule(StringName(id)), "règle pour %s" % id)
		assert_true(ResourceLoader.exists(SCENES + id + ".tscn"), "scène pour %s" % id)
	for id: StringName in PaintedPropRules.get_ids():
		assert_true(_objects.has(String(id)), "%s est au catalogue" % id)


func test_every_prop_has_a_footprint_except_the_traversable_ones() -> void:
	for id: String in _objects:
		var prop := _scene(id)
		assert_not_null(prop, id)
		if prop == null:
			continue
		var expected := PaintedPropRules.footprint(StringName(id))
		assert_eq(prop.get_footprint(), expected, "%s : emprise de la règle" % id)
		if TRAVERSABLE.has(StringName(id)):
			assert_true(prop.get_footprint().is_empty(), "%s se traverse" % id)
		else:
			assert_false(prop.get_footprint().is_empty(), "%s a une emprise" % id)
	for id: StringName in TRAVERSABLE:
		assert_true(PaintedPropRules.is_traversable(id), String(id))


func test_sprite_foot_is_the_origin() -> void:
	for id: String in _objects:
		var prop := _scene(id)
		if prop == null:
			continue
		var sprite := prop.get_node(^"%Sprite") as Sprite2D
		var size := Vector2(_objects[id]["taille"][0], _objects[id]["taille"][1])
		assert_eq(sprite.texture.get_size(), size, "%s : image à 1:1" % id)
		assert_false(sprite.centered)
		assert_eq(sprite.offset, -PaintedPropRules.origin(StringName(id), size), id)
		assert_eq(prop.position, Vector2.ZERO)
	# Le massif est posé par le trou où sort le tronc de l'arbre central.
	assert_eq(PaintedPropRules.origin(&"prop_massif_01", Vector2(384, 232)), Vector2(182, 109))
	assert_eq(PaintedPropRules.origin(&"tree_a_01", Vector2(267, 384)), Vector2(133.5, 384))


func test_shadow_textures_exist_and_are_drawn_under_everything() -> void:
	for id: String in _objects:
		var prop := _scene(id)
		if prop == null:
			continue
		var entry: Dictionary = _objects[id]
		for pair: Array in [["ombre", "CastShadow", WorldLighting.GROUP_CAST_SHADOWS],
				["contact", "ContactShadow", WorldLighting.GROUP_CONTACT_SHADOWS]]:
			var node := prop.get_node_or_null(NodePath(pair[1])) as Sprite2D
			if not entry.has(pair[0]):
				assert_null(node, "%s : pas de %s" % [id, pair[1]])
				continue
			var shadow: Dictionary = entry[pair[0]]
			assert_true(ResourceLoader.exists(shadow["fichier"]), shadow["fichier"])
			assert_not_null(node, "%s : %s" % [id, pair[1]])
			if node == null:
				continue
			assert_eq(node.texture.resource_path, shadow["fichier"])
			assert_true(node.is_in_group(pair[2]), "%s : groupe %s" % [id, pair[2]])
			assert_false(node.z_as_relative, "%s : z absolu" % id)
			assert_eq(node.z_index, WorldLighting.Z_SHADOWS)
			assert_eq(node.scale, Vector2(2, 2), "demi-résolution affichée à l'échelle 2")
			# Coin haut gauche à « decalage » (pixels de jeu) du milieu du bas de l'image.
			var size := Vector2(entry["taille"][0], entry["taille"][1])
			var image_foot := Vector2(size.x / 2.0, size.y) \
				- PaintedPropRules.origin(StringName(id), size)
			assert_eq(node.offset * 2.0,
				Vector2(shadow["decalage"][0], shadow["decalage"][1]) + image_foot, id)
	# Bâtiments et arbres ont les deux ombres.
	for id: String in ["bldg_centre_01", "tree_central_01", "prop_banc_01"]:
		assert_true(_objects[id].has("ombre") and _objects[id].has("contact"), id)


func test_materials_shared_by_family() -> void:
	var still := load("res://game/world/lighting/materials/world_object.tres")
	var wind := load("res://game/world/lighting/materials/world_object_wind.tres")
	for id: String in _objects:
		var prop := _scene(id)
		if prop == null:
			continue
		var sprite := prop.get_node(^"%Sprite") as Sprite2D
		if not PaintedPropRules.uses_material(StringName(id)):
			assert_null(sprite.material, id)
		elif PaintedPropRules.has_wind(StringName(id)):
			assert_eq(sprite.material, wind, "%s : feuillage au vent" % id)
		else:
			assert_eq(sprite.material, still, id)
	for id: StringName in [&"tree_a_01", &"tree_b_01", &"tree_central_01"]:
		assert_true(PaintedPropRules.has_wind(id), String(id))
		assert_true(PaintedPropRules.fades(id), "%s : la cime devient transparente" % id)
	for id: StringName in [&"bldg_centre_01", &"bldg_arene_01", &"bldg_maison_a_01"]:
		assert_true(_scene(String(id)).fade_when_covering, "%s : le toit" % id)


func test_footprints_of_the_prototype() -> void:
	# Centre 8 × 4, porte (2 cases du bas) libre pour le passage de la carte.
	var centre := PaintedPropRules.footprint(&"bldg_centre_01")
	assert_eq(centre.size(), 8 * 4 - 2)
	for cell: Vector2i in [Vector2i(-4, -3), Vector2i(3, -3), Vector2i(-4, 0), Vector2i(3, 0)]:
		assert_true(centre.has(cell), "coin %s" % cell)
	for door: Vector2i in PaintedPropRules.open_cells(&"bldg_centre_01"):
		assert_false(centre.has(door), "porte %s libre" % door)
	assert_eq(PaintedPropRules.open_cells(&"bldg_centre_01"), [Vector2i(-1, 0), Vector2i(0, 0)])
	# Arène 10 × 4 fermée (« La porte est verrouillée. ») : rien de libre.
	assert_eq(PaintedPropRules.footprint(&"bldg_arene_01").size(), 40)
	# Maisons, largeur impaire centrée.
	var house_b := PaintedPropRules.footprint(&"bldg_maison_b_01")
	assert_eq(house_b.size(), 15)
	assert_true(house_b.has(Vector2i(-2, -2)) and house_b.has(Vector2i(2, 0)))
	# Arche nord : seulement les deux piliers.
	assert_eq(PaintedPropRules.footprint(&"prop_porte_nord_01"),
		[Vector2i(-2, 0), Vector2i(2, 0)])
	# Banc 2 × 1 posé sur un bord de case.
	assert_eq(PaintedPropRules.footprint(&"prop_banc_01"), [Vector2i(-1, 0), Vector2i(0, 0)])
	assert_eq(PaintedPropRules.footprint(&"tree_a_01"), [Vector2i.ZERO])
	assert_eq(PaintedPropRules.footprint(&"relief_falaise_01").size(), 4)
	assert_eq(PaintedPropRules.footprint(&"prop_massif_01").size(), 12)


func test_relief_lies_in_the_ground_layer() -> void:
	for id: StringName in PaintedPropRules.get_ids():
		var expected := PaintedPropRules.LAYER_GROUND if GROUND_LAYER.has(id) \
			else PaintedPropRules.LAYER_ENTITIES
		assert_eq(PaintedPropRules.layer(id), expected, String(id))


func test_foot_position_gives_back_the_anchor_cell() -> void:
	var anchor := Vector2i(13, 9)
	for id: StringName in PaintedPropRules.get_ids():
		var foot := PaintedPropRules.foot_position(id, anchor)
		var prop := WorldProp.new()
		autofree(prop)
		prop.position = foot
		assert_eq(prop.get_anchor_cell(), anchor, String(id))
	# Largeur paire : pied sur le bord gauche de la case ; impaire : au milieu.
	assert_eq(PaintedPropRules.foot_position(&"bldg_centre_01", anchor), Vector2(1248, 960))
	assert_eq(PaintedPropRules.foot_position(&"bldg_maison_b_01", anchor), Vector2(1296, 960))
	assert_eq(PaintedPropRules.foot_position(&"tree_central_01", anchor), Vector2(1248, 960))


func test_game_map_marks_props_of_both_layers_solid() -> void:
	var map := GameMap.new()
	map.size = Vector2i(30, 20)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	map.add_child(entities)
	var decals := Node2D.new()
	decals.name = "GroundDecals"
	decals.z_index = WorldLighting.Z_GROUND_DECALS
	map.add_child(decals)
	entities.add_child(_placed(&"bldg_centre_01", Vector2i(10, 8)))
	decals.add_child(_placed(&"relief_falaise_01", Vector2i(20, 4)))
	decals.add_child(_placed(&"relief_escalier_01", Vector2i(23, 4)))
	add_child_autofree(map)
	var grid := map.get_grid()
	assert_true(grid.is_solid(Vector2i(6, 5)), "coin du Centre")
	assert_true(grid.is_solid(Vector2i(13, 8)))
	assert_false(grid.is_solid(Vector2i(9, 8)), "porte du Centre")
	assert_false(grid.is_solid(Vector2i(10, 8)), "porte du Centre")
	assert_false(grid.is_solid(Vector2i(10, 9)), "devant le Centre")
	for x in range(18, 22):
		assert_true(grid.is_solid(Vector2i(x, 4)), "face de la falaise %d" % x)
	assert_false(grid.is_solid(Vector2i(23, 4)), "l'escalier se monte")


## Instance libérée avec la carte (pas d'autofree).
func _placed(id: StringName, anchor: Vector2i) -> WorldProp:
	var prop := (load(SCENES + String(id) + ".tscn") as PackedScene).instantiate() as WorldProp
	prop.position = PaintedPropRules.foot_position(id, anchor)
	return prop


func test_baked_shadow_matches_the_art_manifest() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var cast: Dictionary = manifest["ombre_portee"]
	assert_almost_eq(float(cast["ecrasement"]), WorldLighting.BAKED_SHADOW_LENGTH, 0.0001)
	assert_almost_eq(float(cast["inclinaison_deg"]), WorldLighting.BAKED_SHADOW_ANGLE_DEG,
		0.0001)
	assert_eq(float(cast["reduction"]), WorldLighting.SHADOW_TEXTURE_SCALE)
	assert_eq(float(manifest["ombre_contact"]["reduction"]), WorldLighting.SHADOW_TEXTURE_SCALE)
