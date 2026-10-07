extends GutTest
## Sous-bois de la forêt serrée (ForestFloor) : masque d'une case par pixel, calque posé au-dessus
## du sol peint, masque enregistré dans la scène (aucune image à importer).

const SAVE_PATH := "user://test_forest_floor.tscn"


func after_all() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func test_mask_is_one_pixel_per_cell() -> void:
	var forest := {Vector2i(0, 0): true, Vector2i(3, 2): true, Vector2i(9, 9): true}
	var image := ForestFloor.build_mask(Vector2i(4, 3), forest)
	assert_eq(image.get_size(), Vector2i(4, 3))
	assert_eq(image.get_format(), Image.FORMAT_L8)
	assert_gt(image.get_pixel(0, 0).r, 0.5)
	assert_gt(image.get_pixel(3, 2).r, 0.5)
	assert_lt(image.get_pixel(1, 1).r, 0.5, "hors forêt : noir")
	# Un tableau de cases convient aussi.
	var from_array := ForestFloor.build_mask(Vector2i(4, 3), [Vector2i(1, 1)])
	assert_gt(from_array.get_pixel(1, 1).r, 0.5)


func test_mask_takes_a_value_per_cell() -> void:
	# Jalon 8 §1.2 B : sous-bois partiel (0,45, 0,55) sur l'herbe éloignée du chemin.
	var image := ForestFloor.build_mask(Vector2i(5, 2), {
		Vector2i(0, 0): true, Vector2i(1, 0): 0.45, Vector2i(2, 0): 0.55, Vector2i(3, 0): 1,
		Vector2i(4, 0): false, Vector2i(0, 1): 1.7, Vector2i(1, 1): -0.2,
	})
	assert_eq(image.get_pixel(0, 0).r, 1.0, "vrai : forêt pleine (comportement d'avant)")
	assert_almost_eq(image.get_pixel(1, 0).r, 0.45, 1.0 / 255.0)
	assert_almost_eq(image.get_pixel(2, 0).r, 0.55, 1.0 / 255.0)
	assert_eq(image.get_pixel(3, 0).r, 1.0, "entier 1")
	assert_eq(image.get_pixel(4, 0).r, 0.0, "faux : rien")
	assert_eq(image.get_pixel(0, 1).r, 1.0, "borné à 1")
	assert_eq(image.get_pixel(1, 1).r, 0.0, "borné à 0")
	assert_eq(image.get_pixel(2, 1).r, 0.0, "absente : noir")
	var floor_node := ForestFloor.create(Vector2i(5, 2), {Vector2i(0, 0): true,
		Vector2i(1, 0): 0.45, Vector2i(2, 0): 0.55})
	autofree(floor_node)
	assert_true(floor_node.is_forest(Vector2i(0, 0)))
	assert_false(floor_node.is_forest(Vector2i(1, 0)), "partielle : pas une case de forêt")
	assert_false(floor_node.is_forest(Vector2i(2, 0)), "partielle : pas une case de forêt")


func test_created_layer_sits_on_the_painted_ground() -> void:
	var floor_node := ForestFloor.create(Vector2i(6, 5), {Vector2i(2, 2): true})
	autofree(floor_node)
	assert_eq(String(floor_node.name), "ForestFloor")
	assert_eq(floor_node.z_index, WorldLighting.Z_GROUND)
	assert_eq(floor_node.size, Vector2i(6, 5))
	assert_true(floor_node.is_forest(Vector2i(2, 2)))
	assert_false(floor_node.is_forest(Vector2i(3, 2)))
	assert_false(floor_node.is_forest(Vector2i(-1, 0)))
	var material := floor_node.get_shader_material()
	assert_not_null(material)
	assert_eq(material.shader, ForestFloor.SHADER)
	assert_eq(material.get_shader_parameter(&"forest_mask"), floor_node.mask)


func test_mask_is_saved_inside_the_scene() -> void:
	var root := Node2D.new()
	var floor_node := ForestFloor.create(Vector2i(5, 4), {Vector2i(1, 3): true})
	root.add_child(floor_node)
	floor_node.owner = root
	var packed := PackedScene.new()
	assert_eq(packed.pack(root), OK)
	root.free()
	assert_eq(ResourceSaver.save(packed, SAVE_PATH), OK)
	var loaded := (ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		as PackedScene).instantiate()
	autofree(loaded)
	var restored := loaded.get_node(^"ForestFloor") as ForestFloor
	assert_not_null(restored)
	assert_eq(restored.size, Vector2i(5, 4))
	assert_true(restored.is_forest(Vector2i(1, 3)), "masque relu depuis la scène")
	assert_false(restored.is_forest(Vector2i(0, 0)))
	assert_eq(restored.get_shader_material().get_shader_parameter(&"forest_mask"),
		restored.mask)
