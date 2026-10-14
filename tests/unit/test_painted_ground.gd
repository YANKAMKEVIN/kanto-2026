extends GutTest
## Sol peint à textures réglables (jalon 12 T7) : défauts = herbe, pavés, chemin, identiques à
## ceux d'avant le J12 ; une carte construite sans réglage n'enregistre aucune propriété
## nouvelle (scènes des outils inchangées) ; les cartes peintes existantes dessinent toujours les
## mêmes textures. Preuve au pixel près : `tools/capture_painted_ground.gd` (rendu comparé).

const PAINTED_MAPS: Array[StringName] = [
	&"pallet_town", &"route_1", &"viridian_city", &"route_22", &"route_2", &"viridian_forest",
	&"route_2_north", &"pewter_city",
]
const SEA := Vector2i(4, 4)
const NEW_PROPERTIES: Array[StringName] = [&"base_texture", &"r_texture", &"g_texture",
	&"water_texture", &"foam_strength", &"square_shore"]
## Uniforms de l'eau ajoutés au J13 (T6) : jamais réglés dans le matériau aux défauts.
const WATER_UNIFORMS: Array[StringName] = [&"foam_strength", &"square_shore",
	&"water_texture_size"]


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
				if property == &"foam_strength":
					assert_eq(ground.foam_strength, PaintedGround.DEFAULT_FOAM_STRENGTH, map_id)
				elif property == &"square_shore":
					assert_false(ground.square_shore, map_id)
				else:
					assert_null(ground.get(property), "%s : %s non réglée" % [map_id, property])
			assert_eq(_paths(ground), _default_paths(), "%s : herbe, pavés, chemin" % map_id)
		map.free()
		# Le fichier de la scène ne mentionne aucune propriété nouvelle.
		var text := FileAccess.get_file_as_string(path)
		for property: StringName in NEW_PROPERTIES:
			assert_false(text.contains("\n%s = " % property), "%s : %s absente" % [map_id,
				property])


# --- Eau réglable (jalon 13 T6) ---------------------------------------------------------


func _shore_ground() -> PaintedGround:
	var ground := PaintedGround.new()
	ground.size = SEA
	ground.mask = ImageTexture.create_from_image(GroundMask.build(SEA, {}))
	ground.shore_mask = ImageTexture.create_from_image(
		GroundMask.build_shore(SEA, [Vector2i(0, 3)], [Vector2i(1, 3)]))
	return ground


func test_water_defaults_are_the_sea_of_pallet_town() -> void:
	var ground := _shore_ground()
	assert_null(ground.water_texture)
	assert_eq(ground.foam_strength, PaintedGround.DEFAULT_FOAM_STRENGTH)
	assert_false(ground.square_shore)
	var material := ground.get_shader_material()
	assert_eq((material.get_shader_parameter(&"water_texture") as Texture2D).resource_path,
		PaintedGround.WATER_TEXTURE)
	for uniform: StringName in WATER_UNIFORMS:
		assert_null(material.get_shader_parameter(uniform), "%s non réglé" % uniform)
	ground.free()


func test_default_foam_is_the_shader_default() -> void:
	# Le shader garde la valeur codée en dur avant le J13 (0,8) : défaut = rendu d'avant (le
	# rendu sans écran de GUT ne donne pas les défauts des uniforms : lus dans le code).
	var code := PaintedGround.SHADER.code
	assert_string_contains(code, "uniform float foam_strength = %s;"
		% String.num(PaintedGround.DEFAULT_FOAM_STRENGTH))
	assert_string_contains(code, "uniform bool square_shore = false;")
	assert_string_contains(code, "foam * foam_strength")


func test_canal_water_settings_reach_the_shader() -> void:
	var ground := _shore_ground()
	var canal: Texture2D = load(PaintedGround.SAND_TEXTURE)
	ground.water_texture = canal
	ground.foam_strength = 0.0
	ground.square_shore = true
	var material := ground.get_shader_material()
	assert_eq(material.get_shader_parameter(&"water_texture"), canal)
	assert_eq(material.get_shader_parameter(&"foam_strength"), 0.0)
	assert_eq(material.get_shader_parameter(&"square_shore"), true)
	assert_eq(material.get_shader_parameter(&"water_texture_size"), float(canal.get_width()),
		"l'eau garde sa propre échelle")
	# Retour aux défauts : plus rien de réglé, la mer revient.
	ground.water_texture = null
	ground.foam_strength = PaintedGround.DEFAULT_FOAM_STRENGTH
	ground.square_shore = false
	assert_eq((material.get_shader_parameter(&"water_texture") as Texture2D).resource_path,
		PaintedGround.WATER_TEXTURE)
	for uniform: StringName in WATER_UNIFORMS:
		assert_null(material.get_shader_parameter(uniform), "%s non réglé" % uniform)
	ground.free()


func test_water_texture_set_before_the_shore_is_kept() -> void:
	# Ordre d'une scène chargée : les propriétés arrivent dans n'importe quel ordre.
	var ground := PaintedGround.new()
	var canal: Texture2D = load(PaintedGround.SAND_TEXTURE)
	ground.water_texture = canal
	assert_null(ground.get_shader_material().get_shader_parameter(&"water_texture"),
		"sans rivage, aucune eau chargée")
	ground.shore_mask = ImageTexture.create_from_image(
		GroundMask.build_water(SEA, [Vector2i(1, 1)]))
	assert_eq(ground.get_shader_material().get_shader_parameter(&"water_texture"), canal)
	ground.free()


func test_canal_settings_are_saved_and_reloaded() -> void:
	var root := Node2D.new()
	var ground := _shore_ground()
	ground.name = "PaintedGround"
	ground.water_texture = load(PaintedGround.SAND_TEXTURE)
	ground.foam_strength = 0.0
	ground.square_shore = true
	root.add_child(ground)
	ground.owner = root
	var packed := PackedScene.new()
	assert_eq(packed.pack(root), OK)
	root.free()
	var copy := packed.instantiate()
	var reloaded := copy.get_node(^"PaintedGround") as PaintedGround
	assert_eq(reloaded.water_texture.resource_path, PaintedGround.SAND_TEXTURE)
	assert_eq(reloaded.foam_strength, 0.0)
	assert_true(reloaded.square_shore)
	assert_eq(reloaded.get_shader_material().get_shader_parameter(&"foam_strength"), 0.0)
	copy.free()


func test_pallet_town_sea_is_unchanged() -> void:
	var path := MapCatalog.scene_path(&"pallet_town")
	var map := (load(path) as PackedScene).instantiate()
	var ground := map.get_node(^"PaintedGround") as PaintedGround
	assert_not_null(ground.shore_mask, "Bourg Palette a son rivage")
	assert_null(ground.water_texture)
	assert_eq(ground.foam_strength, PaintedGround.DEFAULT_FOAM_STRENGTH)
	assert_false(ground.square_shore)
	var material := ground.get_shader_material()
	assert_eq((material.get_shader_parameter(&"water_texture") as Texture2D).resource_path,
		PaintedGround.WATER_TEXTURE)
	for uniform: StringName in WATER_UNIFORMS:
		assert_null(material.get_shader_parameter(uniform), "%s non réglé" % uniform)
	map.free()
