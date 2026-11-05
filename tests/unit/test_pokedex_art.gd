extends GutTest
## PokedexArt : chemins par numéro, atlas des vignettes, silhouette, halo, réglages d'import
## (docs/tech/pokedex-refonte.md §2, T1).


func test_portrait_paths_by_number() -> void:
	assert_eq(PokedexArt.portrait_path(1), "res://assets/sprites/pokemon/official/001.png")
	assert_eq(PokedexArt.portrait_path(4), "res://assets/sprites/pokemon/official/004.png")
	assert_eq(PokedexArt.portrait_path(151), "res://assets/sprites/pokemon/official/151.png")
	assert_eq(PokedexArt.portrait_path(158), "res://assets/sprites/pokemon/official/158.png",
		"Johto : Kaiminus")
	assert_false(PokedexArt.has_portrait(165), "numéro sans espèce dans les données")
	for number: int in [0, 252, -1]:
		assert_eq(PokedexArt.portrait_path(number), "", str(number))
		assert_false(PokedexArt.has_portrait(number), str(number))
		assert_null(PokedexArt.thumbnail(number), str(number))
		assert_eq(PokedexArt.thumb_region(number), Rect2(), str(number))


func test_every_species_has_its_portrait() -> void:
	for number: int in _species_numbers():
		assert_true(PokedexArt.has_portrait(number), PokedexArt.portrait_path(number))
	var portrait := load(PokedexArt.portrait_path(4)) as Texture2D
	assert_eq(portrait.get_size(), Vector2(475, 475), "sources telles quelles")


func test_atlas_layout() -> void:
	assert_eq(PokedexArt.thumb_pitch(), 132)
	assert_eq(PokedexArt.atlas_size(), Vector2i(1716, 2640))
	assert_eq(PokedexArt.thumb_region(1), Rect2(2, 2, 128, 128))
	assert_eq(PokedexArt.thumb_region(2), Rect2(134, 2, 128, 128))
	assert_eq(PokedexArt.thumb_region(14), Rect2(2, 134, 128, 128), "deuxième rangée")
	assert_eq(PokedexArt.thumb_region(151), Rect2(7 * 132 + 2, 11 * 132 + 2, 128, 128),
		"150 = 11 × 13 + 7")
	assert_eq(PokedexArt.thumb_region(251), Rect2(3 * 132 + 2, 19 * 132 + 2, 128, 128),
		"250 = 19 × 13 + 3")
	assert_true(PokedexArt.ATLAS_COLUMNS * PokedexArt.ATLAS_ROWS >= PokedexArt.COUNT)
	var atlas := load(PokedexArt.ATLAS_PATH) as Texture2D
	assert_eq(Vector2i(atlas.get_size()), PokedexArt.atlas_size())


func test_every_atlas_cell_has_art_and_nothing_leaks_into_the_margins() -> void:
	var image := (load(PokedexArt.ATLAS_PATH) as Texture2D).get_image()
	image.decompress()
	var pitch := PokedexArt.thumb_pitch()
	var inner := Rect2i(Vector2i.ONE * (PokedexArt.THUMB_PAD / 2), Vector2i.ONE * PokedexArt.THUMB)
	var numbers := _species_numbers()
	for number: int in range(1, PokedexArt.COUNT + 1):
		var region := Rect2i(PokedexArt.thumb_region(number))
		var cell := image.get_region(Rect2i(region.position - inner.position, Vector2i.ONE * pitch))
		var used := cell.get_used_rect()
		if not numbers.has(number):
			assert_false(used.has_area(), "n° %d : sans espèce, case vide" % number)
			continue
		assert_true(used.has_area(), "n° %d : vignette vide" % number)
		assert_true(inner.encloses(used), "n° %d : déborde dans la marge (%s)" % [number, used])
	var last := Vector2i(PokedexArt.thumb_region(PokedexArt.COUNT).end) + inner.position
	var tail := image.get_region(Rect2i(last.x, last.y - pitch, image.get_width() - last.x, pitch))
	assert_false(tail.get_used_rect().has_area(), "cases après le n° 251 vides")


func test_thumbnail_is_cached_and_points_into_the_atlas() -> void:
	var thumb := PokedexArt.thumbnail(4)
	assert_not_null(thumb)
	assert_same(PokedexArt.thumbnail(4), thumb, "même AtlasTexture")
	assert_eq(thumb.region, PokedexArt.thumb_region(4))
	assert_eq(thumb.atlas.resource_path, PokedexArt.ATLAS_PATH)
	assert_same(PokedexArt.thumbnail(150).atlas, thumb.atlas, "un seul atlas chargé")


func test_silhouette_material_is_shared() -> void:
	var material := PokedexArt.silhouette_material()
	assert_not_null(material)
	assert_same(PokedexArt.silhouette_material(), material)
	assert_eq(material.shader.resource_path, PokedexArt.SILHOUETTE_SHADER_PATH)
	assert_eq(material.get_shader_parameter(&"tint"), UiTokens.DEX_SILHOUETTE)
	assert_string_contains(material.shader.code, "texture(TEXTURE, UV).a")


func test_halo_is_shared_and_fades_out() -> void:
	var halo := PokedexArt.halo_texture() as GradientTexture2D
	assert_not_null(halo)
	assert_same(PokedexArt.halo_texture(), halo)
	assert_eq(halo.fill, GradientTexture2D.FILL_RADIAL)
	assert_eq(halo.gradient.get_color(0), UiTokens.DEX_HALO_CENTER)
	assert_eq(halo.gradient.get_color(1).a, 0.0)


func test_import_settings_keep_the_apk_small() -> void:
	for number: int in _species_numbers():
		var config := _import_config(PokedexArt.portrait_path(number))
		assert_eq(config.get_value("params", "compress/mode"), 1, "%03d : Lossy" % number)
		assert_almost_eq(float(config.get_value("params", "compress/lossy_quality")), 0.9,
			0.001, "%03d : qualité 0,9" % number)
		assert_false(config.get_value("params", "mipmaps/generate"), "%03d : mipmaps" % number)
	var atlas := _import_config(PokedexArt.ATLAS_PATH)
	assert_eq(atlas.get_value("params", "compress/mode"), 0, "atlas : Lossless")
	assert_false(atlas.get_value("params", "mipmaps/generate"), "atlas : mipmaps")


func _import_config(path: String) -> ConfigFile:
	var config := ConfigFile.new()
	assert_eq(config.load(path + ".import"), OK, path)
	return config


func test_portrait_is_cropped_on_its_useful_frame() -> void:
	for number: int in _species_numbers():
		var crop := PokedexArt.portrait_crop(number)
		assert_true(crop.has_area(), "cadre de %d" % number)
		assert_true(Rect2(0, 0, 475, 475).encloses(crop), "cadre de %d dans la source" % number)
	var portrait := PokedexArt.portrait(4)
	assert_true(portrait is AtlasTexture)
	assert_eq((portrait as AtlasTexture).atlas.resource_path, PokedexArt.portrait_path(4))
	assert_eq((portrait as AtlasTexture).region, PokedexArt.portrait_crop(4))
	assert_lt(portrait.get_size().x, 475.0, "plus serré que la source")
	assert_null(PokedexArt.portrait(0))
	assert_eq(PokedexArt.portrait_crop(165), Rect2(), "numéro sans espèce")
	assert_eq(PokedexArt.portrait_crop(252), Rect2())


## Régression (T4) : dans fragment(), COLOR vaut déjà « modulate × texture » ; multiplier par
## lui faisait réapparaître couleurs et traits de l'artwork dans la silhouette.
func test_silhouette_shader_never_reuses_the_texture_color() -> void:
	var code := (PokedexArt.silhouette_material().shader as Shader).code
	var fragment := code.substr(code.find("void fragment()"))
	assert_false(fragment.contains("* COLOR"), "la couleur de la texture ne revient jamais")
	assert_true(fragment.contains("texture(TEXTURE, UV).a"), "seul l'alpha est lu")


## Numéros nationaux des espèces des données (Kanto et Johto).
func _species_numbers() -> Array[int]:
	var data := PokemonData.new()
	data.load_dir()
	var numbers: Array[int] = []
	for species_id: StringName in data.get_species_ids():
		numbers.append(data.get_species(species_id).dex)
	numbers.sort()
	assert_eq(numbers.size(), 202, "151 de Kanto et 51 de Johto")
	return numbers
