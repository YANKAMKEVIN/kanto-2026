extends GutTest
## Sol peint à textures réglables (jalon 12 T7) : défauts = herbe, pavés, chemin, identiques à
## ceux d'avant le J12 ; une carte construite sans réglage n'enregistre aucune propriété
## nouvelle (scènes des outils inchangées) ; les cartes peintes existantes dessinent toujours les
## mêmes textures. Preuve au pixel près : `tools/capture_painted_ground.gd` (rendu comparé).

const PAINTED_MAPS: Array[StringName] = [
	&"pallet_town", &"route_1", &"viridian_city", &"route_22", &"route_2", &"viridian_forest",
	&"route_2_north", &"pewter_city",
]
const NEW_PROPERTIES: Array[StringName] = [&"base_texture", &"r_texture", &"g_texture"]


func _default_paths() -> PackedStringArray:
	return PackedStringArray([PaintedGround.GRASS_TEXTURE, PaintedGround.PAVING_TEXTURE,
		PaintedGround.PATH_TEXTURE])


func _paths(ground: PaintedGround) -> PackedStringArray:
	var paths := PackedStringArray()
	for texture: Texture2D in ground.get_textures():
		paths.append(texture.resource_path if texture != null else "")
	return paths


func test_defaults_are_grass_paving_path() -> void:
	var ground := PaintedGround.new()
	assert_null(ground.base_texture)
	assert_null(ground.r_texture)
	assert_null(ground.g_texture)
	assert_eq(_paths(ground), _default_paths())
	ground.free()


func test_set_textures_reach_the_shader_and_null_restores_defaults() -> void:
	var ground := PaintedGround.new()
	var sand: Texture2D = load(PaintedGround.SAND_TEXTURE)
	var water: Texture2D = load(PaintedGround.WATER_TEXTURE)
	var grass: Texture2D = load(PaintedGround.GRASS_TEXTURE)
	ground.base_texture = sand
	ground.r_texture = water
	ground.g_texture = grass
	var material := ground.get_shader_material()
	assert_eq(material.get_shader_parameter(&"grass_texture"), sand, "fond")
	assert_eq(material.get_shader_parameter(&"paving_texture"), water, "canal rouge")
	assert_eq(material.get_shader_parameter(&"path_texture"), grass, "canal vert")
	ground.base_texture = null
	ground.r_texture = null
	ground.g_texture = null
	assert_eq(_paths(ground), _default_paths())
	ground.free()


func test_textures_survive_mask_and_shore_changes() -> void:
	var ground := PaintedGround.new()
	var sand: Texture2D = load(PaintedGround.SAND_TEXTURE)
	ground.r_texture = sand
	ground.mask = ImageTexture.create_from_image(GroundMask.build(Vector2i(4, 4), {}))
	ground.shore_mask = ImageTexture.create_from_image(
		GroundMask.build_shore(Vector2i(4, 4), [Vector2i(0, 3)]))
	assert_eq(ground.get_shader_material().get_shader_parameter(&"paving_texture"), sand)
	ground.free()


func test_default_ground_saves_no_new_property() -> void:
	# Ce que fait un outil de construction : nœud neuf, taille et masque, sans réglage.
	var root := Node2D.new()
	var ground := PaintedGround.new()
	ground.name = "PaintedGround"
	ground.size = Vector2i(6, 4)
	ground.mask = ImageTexture.create_from_image(GroundMask.build(Vector2i(6, 4), {}))
	root.add_child(ground)
	ground.owner = root
	var packed := PackedScene.new()
	assert_eq(packed.pack(root), OK)
	var state := packed.get_state()
	var saved: Array[StringName] = []
	for i: int in state.get_node_property_count(1):
		saved.append(state.get_node_property_name(1, i))
	for property: StringName in NEW_PROPERTIES:
		assert_false(saved.has(property), "%s non enregistrée" % property)
	assert_true(saved.has(&"size"))
	assert_true(saved.has(&"mask"))
	root.free()


func test_set_texture_is_saved_and_reloaded() -> void:
	var root := Node2D.new()
	var ground := PaintedGround.new()
	ground.name = "PaintedGround"
	ground.r_texture = load(PaintedGround.SAND_TEXTURE)
	root.add_child(ground)
	ground.owner = root
	var packed := PackedScene.new()
	assert_eq(packed.pack(root), OK)
	root.free()
	var copy := packed.instantiate()
	var reloaded := copy.get_node(^"PaintedGround") as PaintedGround
	assert_eq(reloaded.r_texture.resource_path, PaintedGround.SAND_TEXTURE)
	assert_eq(_paths(reloaded), PackedStringArray([PaintedGround.GRASS_TEXTURE,
		PaintedGround.SAND_TEXTURE, PaintedGround.PATH_TEXTURE]))
	copy.free()


func test_existing_painted_maps_keep_their_textures() -> void:
	for map_id: StringName in PAINTED_MAPS:
		var path := MapCatalog.scene_path(map_id)
		var map := (load(path) as PackedScene).instantiate()
		var ground := map.get_node_or_null(^"PaintedGround") as PaintedGround
		assert_not_null(ground, "%s : sol peint" % map_id)
		if ground != null:
			for property: StringName in NEW_PROPERTIES:
				assert_null(ground.get(property), "%s : %s non réglée" % [map_id, property])
			assert_eq(_paths(ground), _default_paths(), "%s : herbe, pavés, chemin" % map_id)
		map.free()
		# Le fichier de la scène ne mentionne aucune propriété nouvelle.
		var text := FileAccess.get_file_as_string(path)
		for property: StringName in NEW_PROPERTIES:
			assert_false(text.contains("\n%s = " % property), "%s : %s absente" % [map_id,
				property])
