extends GutTest
## Lots DAF.10d et DAF.2 bis (J33, RP-277, RP-278, RP-279, RP-280, RP-157) : habillage des salles de la
## Ligue, du Panthéon, du Labo de Cramois'Île et de Sylphe 5F ; fonds de combat dédiés. Art seul : les
## nœuds ajoutés n'ont aucune emprise (gel du J33).

const DRESSED: Array[StringName] = [&"league_lorelei", &"league_bruno", &"league_agatha",
	&"league_lance", &"league_champion", &"hall_of_fame", &"cinnabar_lab", &"silph_co_5f"]
const ROOMS: Array[StringName] = [&"league_lorelei", &"league_bruno", &"league_agatha",
	&"league_lance", &"league_champion", &"hall_of_fame"]
const BATTLES: Dictionary = {&"silph_co_1f": &"silph_co_hall", &"fuchsia_gym": &"fuchsia_gym_ninja",
	&"cinnabar_gym": &"arene_cramois", &"power_plant": &"power_plant_centrale",
	&"safari_zone_center": &"safari_zone_savane", &"safari_zone_east": &"safari_zone_savane",
	&"safari_zone_north": &"safari_zone_savane", &"safari_zone_west": &"safari_zone_savane"}


func _map(id: StringName) -> Node:
	return autofree((load("res://game/world/maps/%s.tscn" % id) as PackedScene).instantiate())


func test_rooms_are_dressed_without_footprint() -> void:
	for id: StringName in DRESSED:
		var map := _map(id)
		assert_true(map.has_node(^"Daf10dDecor"), String(id))
		var bodies := map.find_children("*", "CollisionObject2D", true, false)
		for body: Node in bodies:
			assert_false(String(map.get_path_to(body)).contains("Daf10d"), String(id))


func test_league_tiles_are_hidden_under_the_paint() -> void:
	for id: StringName in ROOMS:
		var map := _map(id)
		assert_false((map.get_node(^"Ground") as TileMapLayer).visible, String(id))
		assert_false((map.get_node(^"Obstacles") as TileMapLayer).visible, String(id))
		assert_true(map.get_node(^"Daf10dDecor").has_node(^"Sol"), String(id))


func test_battle_places_use_their_own_backgrounds() -> void:
	var catalog := BattleDecorCatalog.load_file()
	for map_id: StringName in BATTLES:
		var decor := catalog.pick(map_id, Vector2i.ZERO)
		assert_not_null(decor, String(map_id))
		if decor == null:
			continue
		assert_eq(decor.id, BATTLES[map_id], String(map_id))
		assert_true(decor.is_valid(), String(map_id))
		assert_true(ResourceLoader.exists(decor.back_path), String(map_id))
		var texture: Texture2D = load(decor.back_path)
		assert_eq(texture.get_size(), Vector2(2340, 1080), String(map_id))
		assert_false(decor.back_path.contains("vermilion_gym_salle"), String(map_id))
