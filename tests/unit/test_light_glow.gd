extends GutTest
## Halos de lumière légers (jalon 12 T7, docs/tech/jalon-12.md §2.4) : types en données
## ([LightGlowLibrary]), sprite additif généré ([LightGlow]), vacillement coupé par « Réduire
## les animations », aucune `Light2D`.


func after_each() -> void:
	LightGlow.set_reduce_motion(false)


func _glow(type: StringName) -> LightGlow:
	var glow := LightGlow.new()
	glow.glow_type = type
	add_child_autofree(glow)
	return glow


func _type(color: Variant = "#ffffff", radius: Variant = 2.0, alpha: Variant = 0.2,
		flicker: Variant = 0.0) -> Dictionary:
	return {"color": color, "radius": radius, "alpha": alpha, "flicker": flicker}


# --- Données ---------------------------------------------------------------------------

func test_real_data_has_the_five_types_within_bounds() -> void:
	var library := LightGlowLibrary.new()
	assert_true(library.load_file(), "data/world/light_glows.json valide")
	assert_eq(library.get_errors().size(), 0)
	assert_eq(library.get_ids(), [&"lamp", &"shaft", &"shard", &"projector", &"beam", &"hint",
		&"sconce", &"candle", &"purified", &"neon"] as Array[StringName],
		"« hint » du jalon 14, « sconce » du J15, « candle » du J18, « purified » du J19, « neon » (Casino) du J20 en fin")
	# Passe « lumière rare » : le puits de jour a sa colonne de lumière douce.
	assert_eq(library.get_type(&"beam").shape, LightGlowLibrary.SHAPE_COLUMN)
	assert_gt(library.get_type(&"beam").height, 1.0)
	for id: StringName in [&"lamp", &"shaft", &"shard", &"projector", &"hint", &"sconce",
			&"candle", &"purified", &"neon"]:
		assert_eq(library.get_type(id).shape, LightGlowLibrary.SHAPE_RADIAL, String(id))
	for id: StringName in library.get_ids():
		var type := library.get_type(id)
		assert_gt(type.alpha, 0.0)
		var cap := LightGlowLibrary.ALPHA_MAX_MIX if type.blend == LightGlowLibrary.BLEND_MIX \
			else LightGlowLibrary.ALPHA_MAX
		assert_lte(type.alpha, cap, "%s : alpha ≤ plafond de sa fusion" % id)
		assert_gt(type.radius, 0.0)
	# Seules les lampes de chantier vacillent (plan §2.4), et la lueur d'aide du J14 (§2.8).
	assert_gt(library.get_type(&"lamp").flicker, 0.0)
	var hint := library.get_type(&"hint")
	assert_eq(hint.color, Color.html("#3cb4ff"))
	assert_almost_eq(hint.radius, 1.5, 0.001)
	assert_almost_eq(hint.alpha, 0.65, 0.001)
	assert_almost_eq(hint.flicker, 0.25, 0.001)
	assert_eq(hint.blend, LightGlowLibrary.BLEND_MIX, "teinte posée : l'additif se perd sur le bois")
	for id: StringName in [&"lamp", &"shaft", &"shard", &"projector", &"beam"]:
		assert_eq(library.get_type(id).blend, LightGlowLibrary.BLEND_ADD, String(id))
	for id: StringName in [&"shaft", &"shard", &"projector", &"beam"]:
		assert_eq(library.get_type(id).flicker, 0.0, "%s : fixe" % id)


func test_column_shape_is_parsed() -> void:
	var library := LightGlowLibrary.new()
	var raw := _type("#e2ecff", 0.9, 0.3)
	raw["shape"] = "column"
	raw["height"] = 4.5
	assert_true(library.add_from_dict({"types": {"col": raw, "round": _type()}}))
	assert_eq(library.get_type(&"col").shape, LightGlowLibrary.SHAPE_COLUMN)
	assert_eq(library.get_type(&"col").height, 4.5)
	assert_eq(library.get_type(&"round").shape, LightGlowLibrary.SHAPE_RADIAL, "défaut")
	assert_eq(library.get_type(&"round").height, 0.0)


func test_invalid_column_shapes_are_rejected() -> void:
	var no_height := _type()
	no_height["shape"] = "column"
	var bad_shape := _type()
	bad_shape["shape"] = "cone"
	var bad_height := _type()
	bad_height["shape"] = "column"
	bad_height["height"] = 0
	for raw: Dictionary in [no_height, bad_shape, bad_height]:
		var library := LightGlowLibrary.new()
		assert_false(library.add_from_dict({"types": {"x": raw}}), str(raw))
		assert_false(library.has_type(&"x"))
	assert_push_error_count(3)


func test_valid_type_is_parsed() -> void:
	var library := LightGlowLibrary.new()
	assert_true(library.add_from_dict({"types": {"x": _type("#ff8000", 3, 0.35, 0.1)}}))
	var type := library.get_type(&"x")
	assert_eq(type.id, &"x")
	assert_eq(type.color, Color.html("#ff8000"))
	assert_eq(type.radius, 3.0)
	assert_eq(type.alpha, 0.35)
	assert_eq(type.flicker, 0.1)
	assert_null(library.get_type(&"y"))


func test_invalid_types_are_rejected() -> void:
	var cases: Array = [
		_type("rouge"), _type("#ff80"), _type("#ff8000", 0), _type("#ff8000", 9.0),
		_type("#ff8000", 2, 0.0), _type("#ff8000", 2, 0.5), _type("#ff8000", 2, 0.2, -0.1),
		_type("#ff8000", 2, 0.2, 0.6), _type("#ff8000", "grand"), {"color": "#ffffff"},
		"texte",
	]
	for raw: Variant in cases:
		var library := LightGlowLibrary.new()
		assert_false(library.add_from_dict({"types": {"x": raw}}), "type %s" % [raw])
		assert_false(library.has_type(&"x"))
	assert_push_error_count(cases.size() + 2, "le type incomplet signale trois clés manquantes")


func test_unknown_keys_are_errors() -> void:
	var library := LightGlowLibrary.new()
	var raw := _type()
	raw["ombre"] = true
	assert_false(library.add_from_dict({"types": {"x": raw}, "autre": 1}))
	assert_eq(library.get_errors().size(), 2)
	assert_push_error_count(2)


func test_missing_file() -> void:
	var library := LightGlowLibrary.new()
	assert_false(library.load_file("res://does/not/exist.json"))
	assert_push_error_count(1)


# --- Nœud -----------------------------------------------------------------------------

func test_glow_is_additive_generated_sprite_above_characters() -> void:
	var glow := _glow(&"shaft")
	var type := LightGlow.library().get_type(&"shaft")
	assert_true(glow.is_lit())
	assert_true(glow.texture is GradientTexture2D, "dégradé généré, aucun asset")
	assert_eq(glow.texture.get_width(), LightGlow.TEXTURE_SIZE)
	assert_almost_eq(glow.scale.x, type.radius * 2.0 * 96.0 / LightGlow.TEXTURE_SIZE, 0.0001)
	assert_eq(glow.self_modulate, Color(type.color, type.alpha))
	var material := glow.material as CanvasItemMaterial
	assert_not_null(material, "halo fixe : matériau additif simple")
	assert_eq(material.blend_mode, CanvasItemMaterial.BLEND_MODE_ADD)
	assert_false(glow.z_as_relative)
	assert_gt(glow.z_index, 0, "au-dessus de Entities (z 0)")
	assert_lt(glow.z_index, 10, "sous la couche haute")


func test_same_type_shares_texture_and_material() -> void:
	var a := _glow(&"lamp")
	var b := _glow(&"lamp")
	var c := _glow(&"shard")
	var d := _glow(&"projector")
	assert_same(a.material, b.material, "un matériau par type qui vacille")
	assert_same(a.texture, c.texture, "une seule texture de dégradé")
	assert_same(c.material, d.material, "un seul matériau pour les halos fixes")
	assert_true(a.material is ShaderMaterial)


func test_candle_beats_slowly_and_purified_is_steady() -> void:
	var library := LightGlowLibrary.new()
	library.load_file()
	var candle := library.get_type(&"candle")
	assert_almost_eq(candle.flicker, 0.06, 0.001, "battement lent (plan du J18)")
	assert_lt(candle.flicker, library.get_type(&"lamp").flicker, "plus calme qu'une lampe")
	assert_lt(candle.alpha, library.get_type(&"lamp").alpha, "plus pâle qu'une lampe")
	var purified := library.get_type(&"purified")
	assert_eq(purified.flicker, 0.0, "zone purifiée : fixe")
	assert_eq(purified.blend, LightGlowLibrary.BLEND_ADD)
	assert_gt(purified.color.b, purified.color.r, "blanc doux, légèrement froid")
	var halo := _glow(&"purified")
	assert_true(halo.is_lit())
	assert_false(halo.material is ShaderMaterial, "matériau fixe partagé, sans shader")
	assert_eq(LightGlow.flicker_amplitude(&"purified"), 0.0)
	assert_true(_glow(&"candle").material is ShaderMaterial, "la bougie bat")


func test_lamp_flickers_unless_animations_are_reduced() -> void:
	var lamp := _glow(&"lamp")
	var material := lamp.material as ShaderMaterial
	var flicker := LightGlow.library().get_type(&"lamp").flicker
	assert_gt(flicker, 0.0)
	assert_eq(material.get_shader_parameter(&"amplitude"), flicker)
	assert_eq(LightGlow.flicker_amplitude(&"lamp"), flicker)
	LightGlow.set_reduce_motion(true)
	assert_true(LightGlow.is_reduce_motion())
	assert_eq(material.get_shader_parameter(&"amplitude"), 0.0, "vacillement coupé")
	assert_eq(LightGlow.flicker_amplitude(&"lamp"), 0.0)
	assert_true(lamp.is_lit(), "le halo reste allumé")
	LightGlow.set_reduce_motion(false)
	assert_eq(material.get_shader_parameter(&"amplitude"), flicker, "vacillement rendu")


func test_glow_created_while_reduced_does_not_flicker() -> void:
	LightGlow.set_reduce_motion(true)
	var lamp := _glow(&"lamp")
	assert_eq((lamp.material as ShaderMaterial).get_shader_parameter(&"amplitude"), 0.0)


func test_column_glow_stands_on_its_foot() -> void:
	var beam := _glow(&"beam")
	var type := LightGlow.library().get_type(&"beam")
	assert_true(beam.is_lit())
	assert_false(beam.centered, "posée à son pied")
	assert_eq(beam.offset, Vector2(-LightGlow.COLUMN_WIDTH / 2.0, -LightGlow.COLUMN_HEIGHT))
	assert_almost_eq(beam.scale.x * LightGlow.COLUMN_WIDTH, type.radius * 2.0 * 96.0, 0.01)
	assert_almost_eq(beam.scale.y * LightGlow.COLUMN_HEIGHT, type.height * 96.0, 0.01)
	assert_eq((beam.material as CanvasItemMaterial).blend_mode,
		CanvasItemMaterial.BLEND_MODE_ADD)
	var image := beam.texture.get_image()
	var foot := image.get_pixel(LightGlow.COLUMN_WIDTH / 2, LightGlow.COLUMN_HEIGHT - 1).a
	var top := image.get_pixel(LightGlow.COLUMN_WIDTH / 2, 0).a
	var side := image.get_pixel(0, LightGlow.COLUMN_HEIGHT * 3 / 4).a
	var body := image.get_pixel(LightGlow.COLUMN_WIDTH / 2, LightGlow.COLUMN_HEIGHT * 3 / 4).a
	assert_lt(foot, 0.05, "aucun bord net au pied")
	assert_lt(top, 0.05, "nulle en haut")
	assert_lt(side, 0.05, "bords latéraux adoucis")
	assert_gt(body, 0.5)
	# Un halo radial redevient centré si on change son type.
	beam.glow_type = &"shard"
	assert_true(beam.centered)
	assert_eq(beam.offset, Vector2.ZERO)


func test_steady_types_never_flicker() -> void:
	for id: StringName in [&"shaft", &"shard", &"projector", &"beam"]:
		assert_eq(LightGlow.flicker_amplitude(id), 0.0, "%s" % id)
		assert_false(_glow(id).material is ShaderMaterial, "%s : sans shader" % id)


func test_unknown_type_is_hidden_and_reported() -> void:
	var glow := _glow(&"soleil")
	assert_false(glow.is_lit())
	assert_false(glow.visible)
	assert_push_error_count(1)


func test_changing_type_after_ready_updates_the_glow() -> void:
	var glow := _glow(&"shard")
	glow.glow_type = &"projector"
	var type := LightGlow.library().get_type(&"projector")
	assert_eq(glow.self_modulate, Color(type.color, type.alpha))
	assert_almost_eq(glow.scale.x, LightGlow.scale_for(type.radius), 0.0001)


func test_saved_glow_keeps_only_its_type() -> void:
	# Ce qu'enregistre un outil de construction (nœud hors de l'arbre) : le type et la
	# position ; texture, échelle et matériau sont reconstruits au chargement.
	var root := Node2D.new()
	var glow := LightGlow.new()
	glow.name = "Glow"
	glow.glow_type = &"shard"
	glow.position = Vector2(48, 48)
	root.add_child(glow)
	glow.owner = root
	var packed := PackedScene.new()
	assert_eq(packed.pack(root), OK)
	root.free()
	var state := packed.get_state()
	var saved: Array[StringName] = []
	for i: int in state.get_node_property_count(1):
		saved.append(state.get_node_property_name(1, i))
	assert_true(saved.has(&"glow_type"), "type différent du défaut (lamp) : enregistré")
	for property: StringName in [&"texture", &"material", &"scale", &"self_modulate"]:
		assert_false(saved.has(property), "%s non enregistrée" % property)
	var copy := packed.instantiate()
	add_child_autofree(copy)
	var reloaded := copy.get_node(^"Glow") as LightGlow
	assert_true(reloaded.is_lit())
	assert_eq(reloaded.glow_type, &"shard")
	assert_true(reloaded.material is CanvasItemMaterial)


func test_no_light2d_in_the_game() -> void:
	# Plan du J12 §2.4 : aucune Light2D (rendu mobile) ; les halos sont des sprites.
	var found: Array[String] = []
	_scan_for_light2d("res://game", found)
	assert_eq(found, [] as Array[String])


func _scan_for_light2d(dir: String, found: Array[String]) -> void:
	for sub: String in DirAccess.get_directories_at(dir):
		_scan_for_light2d(dir.path_join(sub), found)
	for file: String in DirAccess.get_files_at(dir):
		if not (file.ends_with(".gd") or file.ends_with(".tscn")):
			continue
		var text := FileAccess.get_file_as_string(dir.path_join(file))
		for light_class: String in ["PointLight2D", "DirectionalLight2D", "LightOccluder2D"]:
			if text.contains(light_class):
				found.append("%s : %s" % [dir.path_join(file), light_class])


# --- Lueur d'aide (jalon 14) : fusion « mix » ---------------------------------------------

func test_hint_glow_mixes_instead_of_adding_and_covers_the_object() -> void:
	var glow := _glow(&"hint")
	assert_true(glow.is_lit())
	var material := glow.material as ShaderMaterial
	assert_not_null(material, "la lueur d'aide vacille : matériau à shader")
	assert_true(material.shader.code.contains("blend_mix"), "pas additif (invisible sur le bois)")
	assert_false(material.shader.code.contains("blend_add"))
	var mid: float
	if DisplayServer.get_name() == "headless":
		# Le serveur de rendu factice ne fournit pas d'image GPU. On vérifie les
		# paramètres du même dégradé puis sa valeur au même point, côté CPU.
		var texture := glow.texture as GradientTexture2D
		assert_not_null(texture)
		if texture == null:
			return
		assert_eq(texture.fill, GradientTexture2D.FILL_RADIAL)
		assert_eq(texture.fill_from, Vector2(0.5, 0.5))
		assert_eq(texture.fill_to, Vector2(1.0, 0.5))
		assert_eq(texture.width, LightGlow.TEXTURE_SIZE)
		assert_eq(texture.height, LightGlow.TEXTURE_SIZE)
		var pixel := Vector2(LightGlow.TEXTURE_SIZE / 2 + LightGlow.TEXTURE_SIZE / 5,
			LightGlow.TEXTURE_SIZE / 2)
		var distance := (pixel / float(LightGlow.TEXTURE_SIZE)).distance_to(texture.fill_from)
		mid = texture.gradient.sample(distance / texture.fill_from.distance_to(texture.fill_to)).a
	else:
		var image := glow.texture.get_image()
		assert_not_null(image, "image du halo disponible avec le vrai rendu")
		if image == null:
			return
		mid = image.get_pixel(LightGlow.TEXTURE_SIZE / 2 + LightGlow.TEXTURE_SIZE / 5,
			LightGlow.TEXTURE_SIZE / 2).a
	assert_gt(mid, 0.6, "cœur plein : la teinte couvre l'objet, pas seulement son centre")
	LightGlow.set_reduce_motion(true)
	assert_eq(material.get_shader_parameter(&"amplitude"), 0.0, "animations réduites : fixe")


func test_mix_alpha_has_its_own_ceiling() -> void:
	var raw := _type("#3cb4ff", 1.5, 0.6)
	raw["blend"] = "mix"
	var library := LightGlowLibrary.new()
	assert_true(library.add_from_dict({"types": {"m": raw}}))
	var additive := _type("#3cb4ff", 1.5, 0.6)
	assert_false(LightGlowLibrary.new().add_from_dict({"types": {"a": additive}}), "add ≤ 0,35")
	var bad := _type("#3cb4ff", 1.5, 0.2)
	bad["blend"] = "multiply"
	assert_false(LightGlowLibrary.new().add_from_dict({"types": {"b": bad}}))
	assert_push_error_count(2)

