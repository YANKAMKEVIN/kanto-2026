extends GutTest
## GridWorld, ajouts du jalon 24 (T6, `jalon-24.md` §2.1) : eau surfable, mode du déplaceur
## (WALK, SURF), courants, niveaux de sol. **À pied, rien ne change** : les tests historiques
## (`test_grid_world.gd`) passent sans modification ; ceux-ci le vérifient aussi sur l'eau
## surfable.

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]


## Déplaceur d'essai qui expose son mode, comme le fera le joueur (T7).
class Surfer:
	extends RefCounted
	var mode: GridWorld.MoveMode = GridWorld.MoveMode.SURF

	func get_move_mode() -> GridWorld.MoveMode:
		return mode


var _world: GridWorld


func before_each() -> void:
	# Rangée 2 : terre (x 0..2), eau surfable (x 3..6), terre (x 7..9).
	_world = GridWorld.new(Vector2i(10, 5))
	for x: int in range(3, 7):
		_world.set_surfable(Vector2i(x, 2))


# --- Drapeaux -------------------------------------------------------------------

func test_surfable_is_always_water() -> void:
	assert_true(_world.is_surfable(Vector2i(4, 2)))
	assert_true(_world.is_water(Vector2i(4, 2)), "posée avec l'eau")
	assert_false(_world.is_surfable(Vector2i(1, 2)))
	assert_false(_world.set_surfable(Vector2i(-1, 0)), "hors carte")
	_world.set_surfable(Vector2i(4, 2), false)
	assert_false(_world.is_surfable(Vector2i(4, 2)))
	assert_true(_world.is_water(Vector2i(4, 2)), "l'eau reste, décor")


func test_clearing_the_water_clears_surfable_reading() -> void:
	_world.set_water(Vector2i(5, 2), false)
	assert_false(_world.is_surfable(Vector2i(5, 2)), "plus d'eau : plus surfable")


func test_current_flag_and_direction() -> void:
	for direction: Vector2i in DIRECTIONS:
		assert_true(_world.set_current(Vector2i(4, 2), direction))
		assert_eq(_world.get_current(Vector2i(4, 2)), direction)
		assert_true(_world.is_current(Vector2i(4, 2)))
	assert_false(_world.set_current(Vector2i(4, 2), Vector2i(1, 1)), "non cardinal")
	assert_true(_world.set_current(Vector2i(4, 2), Vector2i.ZERO))
	assert_false(_world.is_current(Vector2i(4, 2)))
	assert_eq(_world.get_current(Vector2i(40, 2)), Vector2i.ZERO, "hors carte")


func test_current_and_level_do_not_disturb_other_flags() -> void:
	_world.set_ledge(Vector2i(4, 2), GridWorld.Ledge.LEFT)
	_world.set_current(Vector2i(4, 2), Vector2i.RIGHT)
	_world.set_level(Vector2i(4, 2), GridWorld.Level.HIGH)
	assert_true(_world.is_surfable(Vector2i(4, 2)))
	assert_eq(_world.get_ledge(Vector2i(4, 2)), GridWorld.Ledge.LEFT)
	assert_eq(_world.get_current(Vector2i(4, 2)), Vector2i.RIGHT)
	assert_eq(_world.get_level(Vector2i(4, 2)), GridWorld.Level.HIGH)


func test_levels_default_to_any() -> void:
	assert_eq(_world.get_level(Vector2i(0, 0)), GridWorld.Level.ANY)
	assert_eq(_world.get_level(Vector2i(-3, 0)), GridWorld.Level.ANY)
	assert_true(GridWorld.levels_compatible(GridWorld.Level.LOW, GridWorld.Level.STAIRS))
	assert_true(GridWorld.levels_compatible(GridWorld.Level.HIGH, GridWorld.Level.ANY))
	assert_false(GridWorld.levels_compatible(GridWorld.Level.LOW, GridWorld.Level.HIGH))


# --- À pied : rien ne change ---------------------------------------------------

func test_walk_refuses_surfable_water_like_any_water() -> void:
	for x: int in range(3, 7):
		for direction: Vector2i in DIRECTIONS:
			assert_false(_world.can_enter(Vector2i(x, 2), direction))
	assert_eq(_world.get_step_target(Vector2i(2, 2), Vector2i.RIGHT), Vector2i(2, 2))
	assert_false(_world.is_free(Vector2i(4, 2)))


func test_walk_reachable_ignores_the_sea() -> void:
	var reached := _world.find_reachable(Vector2i(0, 0))
	assert_false(reached.has(Vector2i(4, 2)))
	assert_eq(reached.size(), 50 - 4)


func test_mover_without_get_move_mode_walks() -> void:
	var npc := RefCounted.new()
	assert_eq(GridWorld.move_mode_of(npc), GridWorld.MoveMode.WALK)
	assert_eq(GridWorld.move_mode_of(null), GridWorld.MoveMode.WALK)
	assert_false(_world.can_enter(Vector2i(3, 2), Vector2i.RIGHT, npc))


func test_currents_are_ignored_by_access_rules() -> void:
	_world.set_current(Vector2i(1, 1), Vector2i.LEFT)
	assert_true(_world.can_enter(Vector2i(1, 1), Vector2i.RIGHT))


# --- Surf ------------------------------------------------------------------------

func test_surfer_enters_free_surfable_water() -> void:
	var surfer := Surfer.new()
	assert_true(_world.can_enter(Vector2i(3, 2), Vector2i.RIGHT, surfer), "monter")
	assert_true(_world.can_enter(Vector2i(4, 2), Vector2i.RIGHT, surfer), "nager")
	assert_eq(_world.get_step_target(Vector2i(4, 2), Vector2i.RIGHT, surfer), Vector2i(5, 2))


func test_surfer_dismounts_on_free_land() -> void:
	var surfer := Surfer.new()
	assert_true(_world.can_enter(Vector2i(7, 2), Vector2i.RIGHT, surfer), "descendre")
	assert_eq(_world.get_step_target(Vector2i(6, 2), Vector2i.RIGHT, surfer), Vector2i(7, 2))


func test_surfer_is_refused_by_decor_water_solid_ledge_and_occupants() -> void:
	var surfer := Surfer.new()
	_world.set_water(Vector2i(4, 1))
	assert_false(_world.can_enter_as(Vector2i(4, 1), Vector2i.UP, GridWorld.MoveMode.SURF),
		"eau décor")
	_world.set_solid(Vector2i(4, 3))
	assert_false(_world.can_enter(Vector2i(4, 3), Vector2i.DOWN, surfer), "solide")
	_world.set_ledge(Vector2i(7, 2), GridWorld.Ledge.RIGHT)
	assert_false(_world.can_enter(Vector2i(7, 2), Vector2i.RIGHT, surfer),
		"pas de saut de rebord en Surf")
	var swimmer := RefCounted.new()
	_world.occupy(Vector2i(5, 2), swimmer)
	assert_false(_world.can_enter(Vector2i(5, 2), Vector2i.RIGHT, surfer), "Nageur")
	assert_true(_world.can_enter_as(Vector2i(5, 2), Vector2i.RIGHT, GridWorld.MoveMode.SURF,
		swimmer), "sa propre case")
	assert_false(_world.can_enter(Vector2i(5, 2), Vector2i.RIGHT, swimmer),
		"un Nageur sans get_move_mode() est à pied pour la grille")


func test_explicit_mode_beats_the_mover() -> void:
	var surfer := Surfer.new()
	assert_false(_world.can_enter_as(Vector2i(4, 2), Vector2i.RIGHT, GridWorld.MoveMode.WALK,
		surfer))
	surfer.mode = GridWorld.MoveMode.WALK
	assert_false(_world.can_enter(Vector2i(4, 2), Vector2i.RIGHT, surfer))


func test_find_reachable_in_surf_mode() -> void:
	var reached := _world.find_reachable(Vector2i(4, 2), null, GridWorld.MoveMode.SURF)
	for x: int in range(3, 7):
		assert_true(reached.has(Vector2i(x, 2)), "eau %d" % x)
	assert_true(reached.has(Vector2i(2, 2)) and reached.has(Vector2i(7, 2)), "rives")
	assert_true(reached.has(Vector2i(4, 1)), "rive nord")
	assert_false(reached.has(Vector2i(0, 0)), "on ne marche pas au-delà de la rive")
	var surfer_reach := _world.find_reachable(Vector2i(4, 2), Surfer.new())
	assert_eq(surfer_reach, reached, "le mode du déplaceur par défaut")


func test_find_path_follows_the_mover_mode() -> void:
	var path := _world.find_path(Vector2i(3, 2), Vector2i(6, 2), Surfer.new())
	assert_eq(path, [Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT] as Array[Vector2i])
	assert_true(_world.find_path(Vector2i(2, 2), Vector2i(7, 2)).size() > 5, "à pied : détour")


# --- Niveaux de sol (Îles Écume) ---------------------------------------------------

func test_low_and_high_ground_only_meet_through_stairs() -> void:
	_world.set_level(Vector2i(0, 0), GridWorld.Level.LOW)
	_world.set_level(Vector2i(1, 0), GridWorld.Level.HIGH)
	_world.set_level(Vector2i(0, 1), GridWorld.Level.STAIRS)
	_world.set_level(Vector2i(1, 1), GridWorld.Level.HIGH)
	assert_false(_world.can_enter(Vector2i(1, 0), Vector2i.RIGHT), "bas → haut")
	assert_false(_world.can_enter(Vector2i(0, 0), Vector2i.LEFT), "haut → bas")
	assert_true(_world.can_enter(Vector2i(0, 1), Vector2i.DOWN), "bas → escalier")
	assert_true(_world.can_enter(Vector2i(1, 1), Vector2i.RIGHT), "escalier → haut")


func test_water_is_low_ground_for_surf() -> void:
	var surfer := Surfer.new()
	_world.set_level(Vector2i(4, 2), GridWorld.Level.LOW)
	_world.set_level(Vector2i(4, 1), GridWorld.Level.HIGH)
	_world.set_level(Vector2i(4, 3), GridWorld.Level.STAIRS)
	assert_false(_world.can_enter(Vector2i(4, 1), Vector2i.UP, surfer), "pas de descente au haut")
	assert_true(_world.can_enter(Vector2i(4, 3), Vector2i.DOWN, surfer), "descente à l'escalier")
	assert_false(_world.can_enter_as(Vector2i(4, 2), Vector2i.DOWN, GridWorld.MoveMode.SURF),
		"pas de montée depuis le sol haut")
