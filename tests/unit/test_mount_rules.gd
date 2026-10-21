extends GutTest
## Mount, MapTraits, MountRules (passe systèmes 2, `docs/tech/systemes-2.md` §2.2) : une seule
## monture pour le Vélo et le Surf, monture à l'arrivée sur une carte, durée d'un pas.

const NONE := Mount.Kind.NONE
const BIKE := Mount.Kind.BIKE
const SURF := Mount.Kind.SURF

var _grid: GridWorld


func before_each() -> void:
	# 4 × 1 : terre en x 0 et 1, eau surfable en x 2 et 3.
	_grid = GridWorld.new(Vector2i(4, 1))
	_grid.set_surfable(Vector2i(2, 0))
	_grid.set_surfable(Vector2i(3, 0))


func _outdoor() -> MapTraits:
	return MapTraits.new()


func test_saved_names_round_trip() -> void:
	for kind: Mount.Kind in [NONE, BIKE, SURF]:
		assert_eq(Mount.from_name(Mount.to_name(kind)), kind)
	assert_eq(Mount.to_name(NONE), &"", "à pied : champ vide")
	assert_eq(Mount.to_name(BIKE), &"bike")
	assert_eq(Mount.to_name(SURF), &"surf")


func test_unknown_or_missing_name_is_on_foot() -> void:
	assert_eq(Mount.from_name(&""), NONE)
	assert_eq(Mount.from_name(&"horse"), NONE)


func test_arriving_on_surfable_water_surfs() -> void:
	for kind: Mount.Kind in [NONE, BIKE, SURF]:
		assert_eq(MountRules.on_map_entered(kind, _outdoor(), Vector2i(2, 0), _grid, true), SURF)


func test_forced_surf_cell_surfs_even_on_land() -> void:
	var map := _outdoor()
	map.forced_surf_cells[Vector2i(1, 0)] = true
	assert_eq(MountRules.on_map_entered(NONE, map, Vector2i(1, 0), _grid, false), SURF)
	assert_eq(MountRules.on_map_entered(NONE, map, Vector2i(0, 0), _grid, false), NONE)


func test_land_ends_the_surf() -> void:
	assert_eq(MountRules.on_map_entered(SURF, _outdoor(), Vector2i(0, 0), _grid, true), NONE)


func test_bike_is_kept_outdoors_and_in_caves() -> void:
	assert_eq(MountRules.on_map_entered(BIKE, _outdoor(), Vector2i(0, 0), _grid, true), BIKE)


func test_indoors_dismounts_the_bike() -> void:
	var house := MapTraits.new(true)
	assert_false(house.allows_bike())
	assert_eq(MountRules.on_map_entered(BIKE, house, Vector2i(0, 0), _grid, true), NONE)
	var no_bike := _outdoor()
	no_bike.no_bike = true
	assert_eq(MountRules.on_map_entered(BIKE, no_bike, Vector2i(0, 0), _grid, true), NONE)


func test_cycling_road_mounts_the_bike_if_owned() -> void:
	var road := MapTraits.new(false, true)
	assert_eq(MountRules.on_map_entered(NONE, road, Vector2i(0, 0), _grid, true), BIKE)
	assert_eq(MountRules.on_map_entered(NONE, road, Vector2i(0, 0), _grid, false), NONE,
		"sans Bicyclette : le garde de l'entrée refuse (donnée du J22)")
	assert_eq(MountRules.on_map_entered(SURF, road, Vector2i(0, 0), _grid, true), BIKE,
		"descente de Surf sur la Piste : en selle")


func test_on_foot_stays_on_foot_elsewhere() -> void:
	assert_eq(MountRules.on_map_entered(NONE, _outdoor(), Vector2i(0, 0), _grid, true), NONE)


func test_matches_bike_rules_on_map_entered() -> void:
	# Façade conservée : mêmes réponses que BikeRules (J22) pour le Vélo.
	for interior: bool in [false, true]:
		for road: bool in [false, true]:
			for riding: bool in [false, true]:
				var map := MapTraits.new(interior, road)
				var expected := BikeRules.on_map_entered(riding, interior, road, true)
				var kind := MountRules.on_map_entered(BIKE if riding else NONE, map,
					Vector2i(0, 0), _grid, true)
				match expected:
					BikeRules.ENTER_MOUNT:
						assert_eq(kind, BIKE)
					BikeRules.ENTER_DISMOUNT:
						assert_eq(kind, NONE)
					_:
						assert_eq(kind, BIKE if riding else NONE)


func test_step_durations() -> void:
	assert_eq(MountRules.step_duration(NONE, false), Grid.WALK_STEP_DURATION)
	assert_eq(MountRules.step_duration(NONE, true), Grid.RUN_STEP_DURATION)
	assert_eq(MountRules.step_duration(BIKE, false), BikeRules.BIKE_STEP_DURATION)
	assert_eq(MountRules.step_duration(BIKE, true), BikeRules.BIKE_STEP_DURATION,
		"la course est ignorée à Vélo")
	assert_almost_eq(MountRules.step_duration(SURF, true), Grid.WALK_STEP_DURATION / 1.15, 0.0001,
		"Surf : marche × 1,15, course ignorée")
	assert_lt(MountRules.step_duration(BIKE, false), Grid.RUN_STEP_DURATION)
	assert_lt(MountRules.step_duration(SURF, false), Grid.WALK_STEP_DURATION)
