extends GutTest
## Jalon 22 (T12, T16) : cases pêchables des cartes livrées (`data/world/fishable.json`, §0.4 n° 2)
## et Piste Cyclable en partie (`GameMap.cycling_road_cells`).

## La Route 25 figure au dossier (M-8) mais sa grille n'a aucune eau qui borde une case
## praticable : `fishable.json` lui donne une liste vide (contrôle de T6).
const DELIVERED: Array[StringName] = [&"vermilion_city", &"cerulean_city", &"route_6",
	&"route_11", &"route_24"]


func test_fishable_json_covers_the_six_delivered_maps() -> void:
	for id: StringName in DELIVERED:
		assert_gt(GameMap.fishable_rects_for(id).size(), 0, String(id))
	assert_eq(GameMap.fishable_rects_for(&"route_25").size(), 0, "aucune berge (T6)")
	assert_eq(GameMap.fishable_rects_for(&"pallet_town").size(), 0, "carte sans entrée")


func test_delivered_fishable_cells_are_water_on_the_real_maps() -> void:
	for id: StringName in DELIVERED:
		var path := "res://game/world/maps/%s.tscn" % id
		if not ResourceLoader.exists(path):
			fail_test("carte absente : %s" % path)
			continue
		var map := (load(path) as PackedScene).instantiate() as GameMap
		add_child_autofree(map)
		var cells := map.fishable_set()
		assert_gt(cells.size(), 0, String(id))
		var bad: Array[Vector2i] = []
		var shore := 0
		for cell: Vector2i in cells:
			if not map.get_grid().is_water(cell):
				bad.append(cell)
			for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var stand := cell + side
				if map.get_grid().is_in_bounds(stand) and not map.get_grid().is_solid(stand) \
						and not map.get_grid().is_water(stand):
					shore += 1
					break
		assert_eq(bad, [] as Array[Vector2i], "%s : cases pêchables hors de l'eau" % id)
		assert_gt(shore, 0, "%s : au moins une case pêchable depuis la berge" % id)


func test_cycling_road_cells_make_the_road_partial() -> void:
	var map := GameMap.new()
	map.cycling_road_cells = [Vector2i(2, 3)] as Array[Vector2i]
	assert_true(map.is_cycling_road_at(Vector2i(2, 3)))
	assert_false(map.is_cycling_road_at(Vector2i(3, 3)))
	assert_true(map.mount_traits_at(Vector2i(2, 3)).cycling_road)
	assert_false(map.mount_traits_at(Vector2i(3, 3)).cycling_road)
	map.cycling_road = true
	assert_true(map.is_cycling_road_at(Vector2i(9, 9)), "toute la carte")
	map.free()
