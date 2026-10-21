extends GutTest
## Nageur de `qa_sea` (passe systèmes 2, T16, `systemes-2.md` §2.5.5) : PNJ `move_mode: surf`
## (données), Dresseur qui voit le joueur en Surf sur l'eau, et nage vers lui ; à pied, la même
## ligne reste coupée par l'eau et un PNJ ordinaire n'entre pas dans l'eau.

const FrameSim := preload("res://tests/helpers/frame_sim.gd")
const SWIMMER_CELL := Vector2i(15, 13)

var _map: GameMap
var _swimmer: Npc


func before_each() -> void:
	_map = (load(MapCatalog.scene_path(&"qa_sea")) as PackedScene).instantiate() as GameMap
	add_child_autofree(_map)
	for npc: Npc in _map.get_npcs():
		if npc.get_spec().trainer_id == &"qa_sea_swimmer":
			_swimmer = npc


func test_the_roster_entry_is_a_surfing_trainer_facing_west() -> void:
	assert_not_null(_swimmer, "le Nageur est sur la carte")
	var spec := _swimmer.get_spec()
	assert_eq(spec.cell, SWIMMER_CELL)
	assert_eq(spec.facing, Vector2i.LEFT)
	assert_eq(spec.sight, 4)
	assert_eq(spec.move_mode, GridWorld.MoveMode.SURF)
	assert_true(spec.is_trainer())
	assert_eq(_swimmer.get_cell(), SWIMMER_CELL, "inscrit sur la grille, dans l'eau")
	assert_true(_map.get_grid().is_surfable(SWIMMER_CELL))
	assert_true(_map.get_grid().is_occupied(SWIMMER_CELL))


func test_move_mode_is_read_by_the_grid_and_defaults_to_walk() -> void:
	assert_eq(_swimmer.get_move_mode(), GridWorld.MoveMode.SURF)
	assert_eq(GridWorld.move_mode_of(_swimmer), GridWorld.MoveMode.SURF)
	var plain := NpcRoster.new()
	assert_true(plain.add_from_dict({"a": {"cell": [1, 1], "sprite": "youngster"}}))
	assert_eq(plain.get_spec(&"a").move_mode, GridWorld.MoveMode.WALK)
	var bad := NpcRoster.new()
	assert_false(bad.add_from_dict({"a": {"cell": [1, 1], "sprite": "youngster",
		"move_mode": "fly"}}))
	assert_push_error("move_mode")


func test_the_swimmer_sees_a_surfing_player_along_the_water() -> void:
	var grid := _map.get_grid()
	for distance: int in [1, 2, 3, 4]:
		var target := SWIMMER_CELL + Vector2i.LEFT * distance
		assert_eq(TrainerRules.sight_distance(grid, SWIMMER_CELL, Vector2i.LEFT, 4, target,
			GridWorld.MoveMode.SURF), distance, "vu à %d" % distance)
	assert_eq(TrainerRules.sight_distance(grid, SWIMMER_CELL, Vector2i.LEFT, 4,
		SWIMMER_CELL + Vector2i.LEFT * 5, GridWorld.MoveMode.SURF), TrainerRules.NOT_SEEN,
		"portée 4")
	assert_eq(TrainerRules.sight_distance(grid, SWIMMER_CELL, Vector2i.UP, 4,
		SWIMMER_CELL + Vector2i.UP * 2, GridWorld.MoveMode.SURF), 2)


func test_a_walking_trainer_is_still_blocked_by_water() -> void:
	var grid := _map.get_grid()
	assert_eq(TrainerRules.sight_distance(grid, SWIMMER_CELL, Vector2i.LEFT, 4,
		SWIMMER_CELL + Vector2i.LEFT * 2), TrainerRules.NOT_SEEN)
	# Eau décor : même un Nageur ne voit pas à travers.
	assert_eq(TrainerRules.sight_distance(grid, Vector2i(10, 2), Vector2i.UP, 4,
		Vector2i(10, 0), GridWorld.MoveMode.SURF), TrainerRules.NOT_SEEN)


func test_the_swimmer_swims_to_the_cell_next_to_the_player() -> void:
	var grid := _map.get_grid()
	var player_cell := Vector2i(11, 13)
	var distance := TrainerRules.sight_distance(grid, SWIMMER_CELL, Vector2i.LEFT, 4,
		player_cell, _swimmer.get_move_mode())
	assert_eq(distance, 4)
	var path := TrainerRules.approach_path(Vector2i.LEFT, distance)
	assert_eq(path.size(), 3)
	var sim := FrameSim.new(get_tree(), [_swimmer])
	for direction: Vector2i in path:
		assert_true(_swimmer.step(direction), "pas vers %s" % direction)
		var frames := 0
		while _swimmer.is_moving() and frames < 60:
			await sim.frame()
			frames += 1
		assert_false(_swimmer.is_moving())
	sim.finish()
	assert_eq(_swimmer.get_cell(), Vector2i(12, 13), "voisin du joueur")
	assert_true(grid.is_surfable(_swimmer.get_cell()))
	assert_false(grid.is_occupied(SWIMMER_CELL), "sa case de départ est rendue")


func test_the_swimmer_cannot_land_and_the_path_stays_on_water() -> void:
	var grid := _map.get_grid()
	var water_path := grid.find_path(SWIMMER_CELL, Vector2i(12, 13), _swimmer)
	assert_eq(water_path.size(), 3)
	var cell := SWIMMER_CELL
	for direction: Vector2i in water_path:
		cell += direction
		assert_true(grid.is_surfable(cell), "chemin à la nage en %s" % cell)
	assert_true(grid.can_enter(Vector2i(14, 13), Vector2i.LEFT, _swimmer))
	# Un PNJ à pied ne suit pas ce chemin.
	assert_true(grid.find_path(SWIMMER_CELL, Vector2i(12, 13), null).is_empty())


func test_the_trainer_and_dialogues_exist_in_the_data() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var trainer := library.get_trainer(&"qa_sea_swimmer")
	assert_not_null(trainer)
	assert_eq(trainer.team.size(), 2)
	for member in trainer.team:
		assert_true(data.has_species(member.species), String(member.species))
		assert_between(member.level, 18, 20)
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), "\n".join(dialogues.get_errors()))
	var spec := _swimmer.get_spec()
	for id: StringName in [spec.dialogue, spec.before_dialogue, spec.defeated_dialogue]:
		assert_true(dialogues.has_dialogue(id), String(id))


func test_the_swimmer_refuses_a_step_onto_land() -> void:
	# Îlot (16..18, 8..9) : depuis l'eau en (15, 9), un pas vers l'est est la terre.
	var grid := _map.get_grid()
	var sim := FrameSim.new(get_tree(), [_swimmer])
	for i: int in 4:
		assert_true(_swimmer.step(Vector2i.UP))
		var frames := 0
		while _swimmer.is_moving() and frames < 60:
			await sim.frame()
			frames += 1
	sim.finish()
	assert_eq(_swimmer.get_cell(), Vector2i(15, 9))
	assert_true(grid.is_surfable(Vector2i(15, 9)))
	assert_false(grid.is_water(Vector2i(16, 9)))
	assert_false(_swimmer.step(Vector2i.RIGHT), "la terre est refusée au Nageur")
	assert_eq(_swimmer.get_cell(), Vector2i(15, 9))
	assert_eq(_swimmer.get_facing(), Vector2i.RIGHT, "il se tourne seulement")
	assert_true(_swimmer.step(Vector2i.LEFT), "l'eau est permise")
