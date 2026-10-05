extends GutTest
## WorldLighting (docs/tech/jalon-07.md §6.7, T3) : profil appliqué aux « global uniform »,
## profil vide = calque caché et aucun effet, ombres orientées ; sol peint (masque, bordures).

const SCENES := "res://game/world/props/painted/"

var _library: LightingLibrary
var _golden: LightProfile
var _interior: LightProfile


func before_all() -> void:
	_library = LightingLibrary.new()
	assert_true(_library.load_file(), "data/world/lighting.json")
	_golden = _library.get_profile(&"golden_hour")
	_interior = _library.get_profile(&"interior_warm")


func after_all() -> void:
	# Les « global uniform » sont globaux : on rend le monde neutre aux tests suivants.
	var lighting := WorldLighting.new()
	lighting.apply(null)
	lighting.free()


func _parse(entry: Dictionary) -> LightProfile:
	var errors := PackedStringArray()
	var profile := LightingLibrary.parse_profile(entry, errors)
	assert_eq(errors, PackedStringArray(), "profil d'essai valide")
	return profile


func _lighting() -> WorldLighting:
	var lighting := WorldLighting.new()
	add_child_autofree(lighting)
	return lighting


## Petite carte : un arbre et un bâtiment peints dans Entities.
func _map() -> Node2D:
	var map := Node2D.new()
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	map.add_child(entities)
	for id: String in ["tree_a_01", "bldg_centre_01"]:
		var prop := (load(SCENES + id + ".tscn") as PackedScene).instantiate() as Node2D
		prop.position = Vector2(480, 960)
		entities.add_child(prop)
	add_child_autofree(map)
	return map


func test_layer_between_the_world_and_the_hud() -> void:
	var lighting := _lighting()
	assert_eq(lighting.layer, UiTokens.LAYER_WORLD_GRADE)
	assert_gt(lighting.layer, UiTokens.LAYER_BATTLE_STAGE)
	assert_lt(lighting.layer, UiTokens.LAYER_HUD)
	assert_false(lighting.is_grade_visible(), "rien avant le premier profil")


func test_golden_hour_globals() -> void:
	var values := WorldLighting.global_values(_golden)
	assert_eq(values[WorldLighting.GRADE_SHADOWS], Vector3(1.16, 1.07, 0.97))
	assert_eq(values[WorldLighting.GRADE_MIDTONES], Vector3(1.06, 1.01, 0.91))
	assert_eq(values[WorldLighting.GRADE_HIGHLIGHTS], Vector3(1.01, 0.97, 0.85))
	assert_eq(values[WorldLighting.GRADE_STRENGTH], 1.0)
	assert_eq(values[WorldLighting.SUN_DIR], Vector2(-0.7, -0.7))
	assert_eq(values[WorldLighting.RIM_COLOR], Color("#ffd17a"))
	assert_eq(values[WorldLighting.RIM_STRENGTH], 1.0)
	assert_eq(values[WorldLighting.RIM_WIDTH], 5.0)
	assert_eq(values[WorldLighting.WIND], 5.0)
	var cast: Color = values[WorldLighting.CAST_SHADOW_COLOR]
	assert_eq(Color(cast, 1.0), Color("#1a1738"))
	assert_almost_eq(cast.a, 0.34, 0.001)
	var contact: Color = values[WorldLighting.CONTACT_COLOR]
	assert_eq(Color(contact, 1.0), Color("#1f1a33"))
	assert_almost_eq(contact.a, 0.62, 0.001)


func test_empty_profile_has_no_effect() -> void:
	for profile: LightProfile in [null, LightProfile.new()]:
		var values := WorldLighting.global_values(profile)
		assert_eq(values[WorldLighting.GRADE_STRENGTH], 0.0)
		for key: StringName in [WorldLighting.GRADE_SHADOWS, WorldLighting.GRADE_MIDTONES,
				WorldLighting.GRADE_HIGHLIGHTS]:
			assert_eq(values[key], Vector3.ONE, String(key))
		assert_eq(values[WorldLighting.RIM_STRENGTH], 0.0)
		assert_eq(values[WorldLighting.RIM_WIDTH], 0.0)
		assert_eq(values[WorldLighting.WIND], 0.0)
		assert_eq((values[WorldLighting.CAST_SHADOW_COLOR] as Color).a, 0.0)
		assert_eq((values[WorldLighting.CONTACT_COLOR] as Color).a, 0.0)


func test_apply_shows_then_hides_the_grade_layer() -> void:
	var lighting := _lighting()
	lighting.apply(_golden)
	assert_true(lighting.is_grade_visible())
	assert_eq(lighting.get_applied_globals(), WorldLighting.global_values(_golden))
	assert_eq(lighting.get_profile(), _golden)
	lighting.apply(null)
	assert_false(lighting.is_grade_visible(), "profil vide : calque caché")
	assert_eq(lighting.get_applied_globals()[WorldLighting.GRADE_STRENGTH], 0.0)
	lighting.apply(_interior)
	assert_true(lighting.is_grade_visible(), "intérieur : étalonnage léger")
	assert_eq(lighting.get_applied_globals()[WorldLighting.RIM_STRENGTH], 0.0, "sans liseré")


func test_reduced_effects_cut_wind_and_rim_but_keep_grade_and_shadows() -> void:
	var lighting := _lighting()
	lighting.apply(_golden)
	lighting.set_reduced_effects(true)
	var values := lighting.get_applied_globals()
	assert_eq(values[WorldLighting.WIND], 0.0)
	assert_eq(values[WorldLighting.RIM_STRENGTH], 0.0)
	assert_eq(values[WorldLighting.GRADE_STRENGTH], 1.0)
	assert_gt((values[WorldLighting.CAST_SHADOW_COLOR] as Color).a, 0.0)
	assert_true(lighting.is_grade_visible())
	lighting.set_reduced_effects(false)
	assert_eq(lighting.get_applied_globals()[WorldLighting.WIND], 5.0)


func test_golden_hour_keeps_the_baked_shadow() -> void:
	var basis := WorldLighting.shadow_transform(_golden)
	assert_almost_eq(basis.x, Vector2(2, 0), Vector2.ONE * 0.0001)
	assert_almost_eq(basis.y, Vector2(0, 2), Vector2.ONE * 0.0001,
		"le profil du prototype = l'ombre préparée (0,26, 45°)")
	var none := WorldLighting.shadow_transform(null)
	assert_almost_eq(none.y, Vector2(0, 2), Vector2.ONE * 0.0001)


func test_shadow_follows_the_profile_length_and_skew() -> void:
	var profile := _parse({
		"grade": {"shadows": [1, 1, 1], "midtones": [1, 1, 1], "highlights": [1, 1, 1],
			"strength": 1.0},
		"sun_direction": [-0.7, -0.7],
		"cast_shadow": {"color": "#000000", "alpha": 0.5, "length": 0.5, "skew_deg": 0.0},
	})
	assert_not_null(profile)
	if profile == null:
		return
	var basis := WorldLighting.shadow_transform(profile)
	# Un point de la silhouette à la hauteur h est préparé en (kx0·h, ky0·h) ; il doit
	# tomber droit sous le pied, à 0,5·h (soleil au zénith côté sud, ombre deux fois plus
	# longue). Coordonnées de texture = pixels de jeu / 2.
	var h := 100.0
	var angle := deg_to_rad(WorldLighting.BAKED_SHADOW_ANGLE_DEG)
	var baked := Vector2(sin(angle), cos(angle)) * WorldLighting.BAKED_SHADOW_LENGTH * h
	var shown := basis * (baked / 2.0)
	assert_almost_eq(shown, Vector2(0.0, 0.5 * h), Vector2.ONE * 0.001)
	# Le pied ne bouge pas.
	assert_eq(basis * Vector2.ZERO, Vector2.ZERO)


func test_shadows_oriented_shown_and_hidden_by_profile() -> void:
	var map := _map()
	var lighting := _lighting()
	var long_profile := _parse({
		"grade": {"shadows": [1, 1, 1], "midtones": [1, 1, 1], "highlights": [1, 1, 1],
			"strength": 1.0},
		"sun_direction": [-0.7, -0.7],
		"cast_shadow": {"color": "#000000", "alpha": 0.5, "length": 0.52, "skew_deg": -45.0},
		"contact": {"color": "#000000", "alpha": 0.5},
	})
	lighting.apply(long_profile, map)
	var casts := get_tree().get_nodes_in_group(WorldLighting.GROUP_CAST_SHADOWS)
	var contacts := get_tree().get_nodes_in_group(WorldLighting.GROUP_CONTACT_SHADOWS)
	assert_eq(casts.size(), 2, "arbre et Centre")
	assert_eq(contacts.size(), 2)
	for node: Node in casts:
		var shadow := node as Node2D
		assert_true(shadow.visible)
		assert_almost_eq(shadow.transform.y, Vector2(2, 4), Vector2.ONE * 0.001,
			"deux fois plus longue, même inclinaison")
		assert_eq(shadow.position, Vector2.ZERO, "au pied")
	lighting.apply(_interior, map)
	for node: Node in casts:
		assert_false((node as CanvasItem).visible, "intérieur : pas d'ombre portée")
	for node: Node in contacts:
		assert_true((node as CanvasItem).visible, "intérieur : ombre de contact gardée")
	lighting.apply(null, map)
	for node: Node in casts + contacts:
		assert_false((node as CanvasItem).visible, "profil vide : aucune ombre")
	lighting.apply(_golden, map)
	for node: Node in casts:
		assert_true((node as CanvasItem).visible)
		assert_almost_eq((node as Node2D).transform.y, Vector2(0, 2), Vector2.ONE * 0.001)


func test_shadows_of_a_map_outside_the_tree() -> void:
	var map := Node2D.new()
	autofree(map)
	var prop := (load(SCENES + "tree_b_01.tscn") as PackedScene).instantiate()
	map.add_child(prop)
	var lighting := _lighting()
	lighting.apply(null, map)
	assert_false((prop.get_node(^"CastShadow") as CanvasItem).visible)
	assert_false((prop.get_node(^"ContactShadow") as CanvasItem).visible)


func test_ground_mask_channels() -> void:
	var paving := {Vector2i(1, 1): true, Vector2i(2, 1): true}
	var path: Array[Vector2i] = [Vector2i(0, 2), Vector2i(2, 1), Vector2i(9, 9)]
	var mask := GroundMask.build(Vector2i(4, 3), paving, path)
	assert_eq(mask.get_size(), Vector2i(4, 3), "1 pixel = 1 case")
	assert_eq(GroundMask.kind_at(mask, Vector2i(1, 1)), GroundMask.Kind.PAVING)
	assert_eq(GroundMask.kind_at(mask, Vector2i(2, 1)), GroundMask.Kind.PAVING, "pavé gagne")
	assert_eq(GroundMask.kind_at(mask, Vector2i(0, 2)), GroundMask.Kind.PATH)
	assert_eq(GroundMask.kind_at(mask, Vector2i(3, 0)), GroundMask.Kind.GRASS)
	assert_eq(GroundMask.kind_at(mask, Vector2i(-1, 0)), GroundMask.Kind.GRASS, "hors masque")
	assert_eq(mask.get_pixel(1, 1), Color(1, 0, 0))
	assert_eq(mask.get_pixel(0, 2), Color(0, 1, 0))


func test_painted_ground_draws_under_shadows_and_decals() -> void:
	var ground := PaintedGround.new()
	autofree(ground)
	ground.size = Vector2i(26, 14)
	var mask := ImageTexture.create_from_image(GroundMask.build(Vector2i(26, 14), {}))
	ground.mask = mask
	assert_eq(ground.z_index, WorldLighting.Z_GROUND)
	assert_lt(WorldLighting.Z_GROUND, WorldLighting.Z_SHADOWS)
	assert_lt(WorldLighting.Z_SHADOWS, WorldLighting.Z_GROUND_DECALS)
	assert_lt(WorldLighting.Z_GROUND_DECALS, 0, "sous Entities (personnages, objets)")
	var material := ground.get_shader_material()
	assert_eq(material.get_shader_parameter(&"ground_mask"), mask)
	for param: StringName in [&"grass_texture", &"paving_texture", &"path_texture"]:
		assert_not_null(material.get_shader_parameter(param), String(param))


func test_border_decals_follow_the_paving_edge_with_a_fixed_seed() -> void:
	var paving := {}
	for x in range(2, 6):
		for y in range(2, 4):
			paving[Vector2i(x, y)] = true
	var first := BorderDecals.plan(paving, Vector2i(10, 8), 2026)
	var again := BorderDecals.plan(paving, Vector2i(10, 8), 2026)
	var other := BorderDecals.plan(paving, Vector2i(10, 8), 7)
	assert_eq(first, again, "même graine, mêmes décors")
	assert_ne(first, other)
	# 12 côtés au bord (4 + 4 en haut et en bas, 2 + 2 sur les flancs), 2 tirages chacun,
	# une touffe par tirage au moins.
	assert_gte(first.size(), 24)
	var area := Rect2(Vector2(2, 2) * 96.0, Vector2(4, 2) * 96.0).grow(70.0)
	for decal: Dictionary in first:
		assert_true(ResourceLoader.exists(decal["texture"]), decal["texture"])
		assert_true(area.has_point(decal["position"]), "le long du bord : %s" % decal["position"])
	# Une case pavée au bord de la carte n'a pas de décor côté extérieur.
	var edge := BorderDecals.plan({Vector2i(0, 0): true}, Vector2i(1, 1), 1)
	assert_true(edge.is_empty())
