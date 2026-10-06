extends GutTest
## PokedexScene (refonte T4, essai de décor du portrait) : le décor suit le PREMIER habitat
## observé, sinon le décor par défaut ; chaque décor de la table existe.


func _habitats(zones: Array[StringName]) -> Array[PokedexHabitatView]:
	var views: Array[PokedexHabitatView] = []
	for zone: StringName in zones:
		views.append(PokedexHabitatView.new(zone, String(zone)))
	return views


func test_first_habitat_chooses_the_scene() -> void:
	assert_eq(PokedexScene.scene_for(_habitats([&"route_1", &"pallet_town"])), "prairie")
	assert_eq(PokedexScene.scene_for(_habitats([&"pallet_town", &"route_1"])), "village")
	assert_eq(PokedexScene.scene_for(_habitats([&"viridian_city"])), "village")
	assert_eq(PokedexScene.scene_for(_habitats([&"route_22"])), "prairie")


func test_no_habitat_or_unknown_zone_gives_the_default() -> void:
	var fallback := PokedexScene.default_scene()
	assert_false(fallback.is_empty())
	assert_eq(PokedexScene.scene_for(_habitats([])), fallback)
	assert_eq(PokedexScene.scene_for(_habitats([&"zone_inexistante", &"route_1"])), fallback,
		"seule la première zone compte")


func test_every_scene_exists_and_every_zone_is_known() -> void:
	for scene: String in PokedexScene.all_scenes():
		var path := PokedexScene.path_of(scene)
		assert_true(ResourceLoader.exists(path), path)
		var texture := load(path) as Texture2D
		assert_eq(texture.get_size(), Vector2(512, 512), path)
	var zones := ZoneLibrary.new()
	zones.load_file()
	var table: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(
		PokedexScene.TABLE_PATH)) as Dictionary)["zones"]
	for zone: String in table.keys():
		assert_true(zones.has_zone(StringName(zone)), "zone %s connue" % zone)
	assert_not_null(PokedexScene.texture_for(_habitats([&"route_1"])))
