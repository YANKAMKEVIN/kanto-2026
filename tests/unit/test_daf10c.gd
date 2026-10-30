extends GutTest
## Lot DAF.10c (J33, RP-275, RP-276) : Îles Écume en grotte glacée peinte, Centrale en usine peinte.
## Art seul (gel du J33) : tuiles masquées sous le sol peint, nœuds ajoutés préfixés `Daf10c` et sans
## emprise ; rochers de Force et courants peints restent lisibles.

const MAPS: Array[StringName] = [&"seafoam_1f", &"seafoam_b1f", &"seafoam_b2f", &"seafoam_b3f",
	&"seafoam_b4f", &"power_plant"]


func _map(id: StringName) -> Node:
	return autofree((load("res://game/world/maps/%s.tscn" % id) as PackedScene).instantiate())


func test_maps_are_painted_over_hidden_tiles() -> void:
	for id: StringName in MAPS:
		var map := _map(id)
		assert_true(map.has_node(^"PaintedGround"), String(id))
		assert_true(map.has_node(^"Daf10cSol"), String(id))
		for layer: String in ["Ground", "Obstacles"]:
			assert_false((map.get_node(NodePath(layer)) as TileMapLayer).visible, "%s %s" % [id, layer])


func test_painted_nodes_have_no_footprint() -> void:
	for id: StringName in MAPS:
		var map := _map(id)
		for body: Node in map.find_children("*", "CollisionObject2D", true, false):
			assert_false(String(map.get_path_to(body)).contains("Daf10c"), String(id))


func test_seafoam_water_and_drawings_are_painted() -> void:
	for id: StringName in [&"seafoam_b3f", &"seafoam_b4f"]:
		assert_true(_map(id).has_node(^"Eau"), String(id))
	var map := _map(&"seafoam_b3f")
	for gate: String in ["TrouOuvert1", "TrouBouche1", "RocherTombe_18_6", "Panneau_4_12",
			"EchelleDessin_5_12"]:
		var node := map.get_node("Entities/" + gate)
		assert_eq(node.find_children("*", "Polygon2D", false, false).size(), 0, gate)
		assert_true(node.has_node(^"Peint0"), gate)


func test_boulder_and_current_use_painted_images() -> void:
	assert_true(ResourceLoader.exists(Boulder.IMAGE.resource_path))
	assert_eq(Boulder.IMAGE.get_size(), Vector2(96, 90))
	assert_eq(SeafoamFloorGate.CURRENT_IMAGE.get_size(), Vector2(384, 384))
