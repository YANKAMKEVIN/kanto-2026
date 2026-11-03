extends GutTest
## RP-284 : la reprise écarte seulement la case de départ des PNJ présents avec les drapeaux
## (Giovanni du repaire B4F, case (25, 3), parti une fois `giovanni_hideout_won` levé).

const CELL := Vector2i(25, 3)


func _map() -> GameMap:
	var map := (load(MapCatalog.scene_path(&"rocket_hideout_b4f")) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(map)
	return map


func test_hidden_npc_home_cell_is_a_valid_resume_cell() -> void:
	var map := _map()
	var flags := StoryFlags.new()
	flags.set_flag(&"giovanni_hideout_won")
	map.refresh_npcs(flags)
	assert_eq(map.find_standing_cell(CELL), CELL, "Giovanni parti : la case est libre")


func test_present_npc_home_cell_is_still_avoided() -> void:
	var map := _map()
	map.refresh_npcs(StoryFlags.new())
	assert_ne(map.find_standing_cell(CELL), CELL, "Giovanni présent : case voisine")


func test_without_refresh_every_home_counts() -> void:
	assert_ne(_map().find_standing_cell(CELL), CELL)
