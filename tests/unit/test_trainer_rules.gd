extends GutTest
## TrainerRules (jalon 9, jalon-09.md §2.4.2) : drapeau « battu », vision en ligne droite
## (obstacle, eau, personnage, hautes herbes, rebord, bord de carte, portée) et approche.

const TRAINER := Vector2i(5, 2)


func _grid() -> GridWorld:
	return GridWorld.new(Vector2i(12, 12))


func test_beaten_flag_and_is_beaten() -> void:
	assert_eq(TrainerRules.beaten_flag(&"forest_scout_theo"), &"beaten_forest_scout_theo")
	var flags := StoryFlags.new()
	assert_false(TrainerRules.is_beaten(flags, &"forest_scout_theo"))
	assert_false(TrainerRules.is_beaten(null, &"forest_scout_theo"), "nouvelle partie")
	flags.set_flag(&"beaten_forest_scout_theo")
	assert_true(TrainerRules.is_beaten(flags, &"forest_scout_theo"))
	assert_false(TrainerRules.is_beaten(flags, &"forest_scout_noe"))


func test_sees_the_player_in_a_straight_line_within_range() -> void:
	var grid := _grid()
	for distance: int in range(1, 5):
		assert_eq(TrainerRules.sight_distance(grid, TRAINER, Vector2i.DOWN, 4,
			TRAINER + Vector2i.DOWN * distance), distance, "à %d cases" % distance)
	assert_eq(TrainerRules.sight_distance(grid, TRAINER, Vector2i.DOWN, 4,
		TRAINER + Vector2i.DOWN * 5), TrainerRules.NOT_SEEN, "au-delà de la portée")


func test_only_in_front_of_him() -> void:
	var grid := _grid()
	assert_eq(TrainerRules.sight_distance(grid, TRAINER, Vector2i.DOWN, 4,
		TRAINER + Vector2i.UP), TrainerRules.NOT_SEEN, "derrière")
	assert_eq(TrainerRules.sight_distance(grid, TRAINER, Vector2i.DOWN, 4,
		TRAINER + Vector2i(1, 2)), TrainerRules.NOT_SEEN, "en diagonale")
	assert_eq(TrainerRules.sight_distance(grid, TRAINER, Vector2i.DOWN, 4,
		TRAINER + Vector2i.RIGHT), TrainerRules.NOT_SEEN, "à côté")
	assert_eq(TrainerRules.sight_distance(grid, TRAINER, Vector2i.LEFT, 4,
		TRAINER + Vector2i.LEFT * 3), 3, "tourné vers la gauche")
	assert_eq(TrainerRules.sight_distance(grid, TRAINER, Vector2i.ZERO, 4,
		TRAINER + Vector2i.DOWN), TrainerRules.NOT_SEEN, "sans orientation")


func test_a_solid_cell_or_water_cuts_the_line() -> void:
	var grid := _grid()
	grid.set_solid(TRAINER + Vector2i.DOWN * 2)
	assert_eq(TrainerRules.sight_distance(grid, TRAINER, Vector2i.DOWN, 4,
		TRAINER + Vector2i.DOWN * 3), TrainerRules.NOT_SEEN, "derrière un arbre")
	assert_eq(TrainerRules.sight_distance(grid, TRAINER, Vector2i.DOWN, 4,
		TRAINER + Vector2i.DOWN), 1, "devant l'arbre")
	var wet := _grid()
	wet.set_water(TRAINER + Vector2i.DOWN)
	assert_eq(TrainerRules.sight_distance(wet, TRAINER, Vector2i.DOWN, 4,
		TRAINER + Vector2i.DOWN * 2), TrainerRules.NOT_SEEN, "derrière l'eau")


func test_another_character_cuts_the_line() -> void:
	var grid := _grid()
	var other := RefCounted.new()
	grid.occupy(TRAINER + Vector2i.DOWN, other)
	assert_eq(TrainerRules.sight_distance(grid, TRAINER, Vector2i.DOWN, 4,
		TRAINER + Vector2i.DOWN * 2), TrainerRules.NOT_SEEN, "un PNJ entre eux")
	# Le joueur occupe sa propre case : il est vu.
	var free := _grid()
	var player := RefCounted.new()
	free.occupy(TRAINER + Vector2i.DOWN * 2, player)
	assert_eq(TrainerRules.sight_distance(free, TRAINER, Vector2i.DOWN, 4,
		TRAINER + Vector2i.DOWN * 2), 2)


func test_tall_grass_and_ledges_do_not_cut_the_line() -> void:
	var grid := _grid()
	grid.set_tall_grass(TRAINER + Vector2i.DOWN)
	grid.set_ledge(TRAINER + Vector2i.DOWN * 2, GridWorld.Ledge.DOWN)
	grid.set_tall_grass(TRAINER + Vector2i.DOWN * 3)
	assert_eq(TrainerRules.sight_distance(grid, TRAINER, Vector2i.DOWN, 4,
		TRAINER + Vector2i.DOWN * 3), 3, "dans les hautes herbes, derrière un rebord")


func test_the_edge_of_the_map_cuts_the_line() -> void:
	var grid := _grid()
	assert_eq(TrainerRules.sight_distance(grid, Vector2i(5, 1), Vector2i.UP, 4, Vector2i(5, -1)),
		TrainerRules.NOT_SEEN, "hors carte")
	assert_eq(TrainerRules.sight_distance(grid, Vector2i(5, 1), Vector2i.UP, 4, Vector2i(5, 0)), 1)
	assert_eq(TrainerRules.sight_distance(null, TRAINER, Vector2i.DOWN, 4,
		TRAINER + Vector2i.DOWN), TrainerRules.NOT_SEEN, "sans grille")


func test_approach_stops_next_to_the_player() -> void:
	assert_eq(TrainerRules.approach_path(Vector2i.DOWN, 1), [] as Array[Vector2i], "déjà à côté")
	assert_eq(TrainerRules.approach_path(Vector2i.DOWN, 0), [] as Array[Vector2i])
	assert_eq(TrainerRules.approach_path(Vector2i.DOWN, 4),
		[Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN] as Array[Vector2i])
	assert_eq(TrainerRules.approach_path(Vector2i.LEFT, 2), [Vector2i.LEFT] as Array[Vector2i])
