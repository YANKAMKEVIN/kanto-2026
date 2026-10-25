extends GutTest
## SeafoamState (jalon 24, T9 ; dossier 27 §7, `jalon-24.md` §2.6) : reconstruction des cinq étages
## depuis les 8 drapeaux, comparée aux résultats du contrôle Python
## (`tests/fixtures/seafoam/seafoam_reference.json`, généré avec `data/world/seafoam.json` par
## `tools/gen_seafoam_data.py` depuis `tools/art/plan_check_j24_seafoam.py`) : les 256 combinaisons,
## l'exploration par poussée de chaque configuration d'étage (mêmes comptes), la solution complète
## rejouée avec BoulderRules, SurfRules et CurrentField.

const SeafoamFloor := preload("res://tests/helpers/seafoam_floor.gd")
const REFERENCE := "res://tests/fixtures/seafoam/seafoam_reference.json"
const FLOORS: Array[StringName] = [
	&"seafoam_1f", &"seafoam_b1f", &"seafoam_b2f", &"seafoam_b3f", &"seafoam_b4f",
]
const DIRS := {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
	"right": Vector2i.RIGHT}

var _state: SeafoamState
var _ref: Dictionary


func before_all() -> void:
	_ref = JSON.parse_string(FileAccess.get_file_as_string(REFERENCE))


func before_each() -> void:
	_state = SeafoamState.new()
	assert_true(_state.load_file(), "data/world/seafoam.json se charge")


func test_data_has_five_floors_and_eight_hole_flags_in_dossier_order() -> void:
	assert_eq(_state.floor_ids(), FLOORS)
	var expected: Array[StringName] = []
	for floor_name: String in ["1f", "b1f", "b2f", "b3f"]:
		for n: int in [1, 2]:
			expected.append(StringName("seafoam_%s_hole_%d_filled" % [floor_name, n]))
	assert_eq(_state.hole_flags(), expected)
	assert_eq(_ref["mask_order"].map(func(f: Variant) -> StringName: return StringName(f)),
		expected, "même ordre que le contrôle Python")


func test_unknown_floor_and_bad_data() -> void:
	assert_null(_state.floor_state(&"route_20", StoryFlags.new()))
	var bad := SeafoamState.new()
	assert_false(bad.add_from_dict({"floors": {"x": {"holes": 3}}, "hole_flags": []}))
	assert_push_error("SeafoamState")
	assert_false(bad.add_from_dict({}))
	assert_push_error("SeafoamState")


func test_no_flag_gives_origin_boulders_and_active_currents() -> void:
	var flags := StoryFlags.new()
	var f1 := _state.floor_state(&"seafoam_1f", flags)
	assert_eq(f1.boulders, [Vector2i(18, 10), Vector2i(26, 7)] as Array[Vector2i])
	assert_eq(f1.open_holes, {Vector2i(17, 6): 1, Vector2i(24, 6): 2})
	assert_true(f1.plugged_holes.is_empty())
	var b1 := _state.floor_state(&"seafoam_b1f", flags)
	assert_true(b1.boulders.is_empty(), "rien n'est tombé du 1F")
	var b3 := _state.floor_state(&"seafoam_b3f", flags)
	assert_eq(b3.boulders.size(), 4)
	assert_true(b3.has_active_current(), "courant 1 actif")
	var b4 := _state.floor_state(&"seafoam_b4f", flags)
	assert_true(b4.has_active_current(), "courant 2 actif")
	assert_eq(b4.surf_forbidden, {Vector2i(7, 11): true}, "T-14 tant que le courant 2 est actif")
	assert_true(b4.forced_surf.has(Vector2i(20, 16)) and b4.forced_surf.has(Vector2i(4, 14)))


func test_designated_boulder_is_removed_whatever_was_pushed() -> void:
	# B3F : trou 1 bouché → le rocher désigné (3, 15) disparaît, (5, 14) reste.
	var flags := StoryFlags.new()
	flags.set_flag(&"seafoam_b3f_hole_1_filled")
	var b3 := _state.floor_state(&"seafoam_b3f", flags)
	assert_false(b3.boulders.has(Vector2i(3, 15)))
	assert_true(b3.boulders.has(Vector2i(5, 14)))
	assert_eq(b3.plugged_holes, {Vector2i(3, 16): 1})
	var b4 := _state.floor_state(&"seafoam_b4f", flags)
	assert_eq(b4.boulders, [Vector2i(4, 15)] as Array[Vector2i], "tombé au B4F, dans l'eau")
	assert_eq(b4.fallen, [Vector2i(4, 15)] as Array[Vector2i])
	assert_true(b4.has_active_current(), "un seul trou du B3F : courant 2 encore actif")
	flags.set_flag(&"seafoam_b3f_hole_2_filled")
	b4 = _state.floor_state(&"seafoam_b4f", flags)
	assert_false(b4.has_active_current(), "deux trous du B3F : courant 2 coupé")
	assert_true(b4.surf_forbidden.is_empty())


func test_apply_to_sets_only_active_currents() -> void:
	var grid := GridWorld.new(Vector2i(30, 18))
	var flags := StoryFlags.new()
	_state.floor_state(&"seafoam_b3f", flags).apply_to(grid)
	assert_eq(grid.get_current(Vector2i(15, 8)), Vector2i.DOWN)
	assert_eq(grid.get_current(Vector2i(19, 7)), Vector2i.LEFT)
	flags.set_flag(&"seafoam_b2f_hole_1_filled")
	flags.set_flag(&"seafoam_b2f_hole_2_filled")
	_state.floor_state(&"seafoam_b3f", flags).apply_to(grid)
	assert_false(grid.is_current(Vector2i(15, 8)), "coupé : eau calme")


## Les 256 combinaisons : chaque étage est valide et identique au contrôle Python.
func test_all_256_flag_combinations_match_python_and_are_valid() -> void:
	var order: Array = _ref["mask_order"]
	var builders: Dictionary = {}
	var mismatches: Array[String] = []
	for mask: int in 256:
		var flags := _flags_for(mask, order)
		var expected: Dictionary = _ref["configurations"][str(mask)]
		for map_id: StringName in FLOORS:
			var floor_state := _state.floor_state(map_id, flags)
			var want: Dictionary = expected[String(map_id)]
			var got_boulders := _sorted_pairs(floor_state.boulders)
			if got_boulders != want["boulders"]:
				mismatches.append("%d %s rochers %s ≠ %s" % [mask, map_id, got_boulders,
					want["boulders"]])
			var plugged: Array = floor_state.plugged_holes.values()
			plugged.sort()
			if plugged != (want["plugged"] as Array).map(func(n: Variant) -> int: return int(n)):
				mismatches.append("%d %s trous %s" % [mask, map_id, plugged])
			if floor_state.has_active_current() != bool(want["current"]):
				mismatches.append("%d %s courant" % [mask, map_id])
			# Validité : rochers distincts, sur du sol bas ou dans l'eau (tombés), jamais sur un
			# trou ouvert ni sur une case bloquée.
			if not builders.has(map_id):
				var b := SeafoamFloor.new()
				b.setup(map_id, _state.floor_state(map_id, StoryFlags.new()))
				builders[map_id] = b
			var grid: GridWorld = (builders[map_id] as SeafoamFloor).grid
			var seen: Dictionary = {}
			for cell: Vector2i in floor_state.boulders:
				var water_ok := floor_state.fallen.has(cell)
				if seen.has(cell) or floor_state.open_holes.has(cell) or grid.is_solid(cell) \
						or (grid.get_level(cell) != GridWorld.Level.LOW) \
						or (grid.is_water(cell) and not water_ok):
					mismatches.append("%d %s rocher invalide %s" % [mask, map_id, cell])
				seen[cell] = true
			if not floor_state.surf_forbidden.is_empty() and not floor_state.has_active_current():
				mismatches.append("%d %s T-14 sans courant" % [mask, map_id])
	assert_eq(mismatches, [] as Array[String], "256 combinaisons × 5 étages")


## Exploration par poussée de chaque configuration d'étage (celles des 256 combinaisons) : mêmes
## départs, même nombre de configurations de rochers et d'états que le contrôle Python, aucune
## impasse, mêmes trous que l'on peut boucher.
func test_push_exploration_matches_python_for_every_floor_configuration() -> void:
	var order: Array = _ref["mask_order"]
	var explorations: Array = _ref["explorations"]
	assert_eq(explorations.size(), 42)
	var total_configs := 0
	for entry: Dictionary in explorations:
		var map_id := StringName(entry["map"])
		var mask := _mask_for(map_id, entry, order)
		assert_ne(mask, -1, "%s : une combinaison donne cette configuration" % map_id)
		if mask < 0:
			continue
		var floor_state := _state.floor_state(map_id, _flags_for(mask, order))
		var storey := SeafoamFloor.new()
		assert_true(storey.setup(map_id, floor_state))
		var starts := storey.starts(floor_state.boulders)
		var label := "%s %s trous %s" % [map_id, entry["boulders"], entry["plugged"]]
		assert_eq(_sorted_pairs(starts), entry["starts"], label + " : départs")
		var ex = storey.explore(floor_state.boulders, starts)
		assert_eq(ex.configs, int(entry["configs"]), label + " : configurations de rochers")
		assert_eq(ex.states, int(entry["states"]), label + " : états")
		assert_eq(ex.impasses, 0, label + " : aucune impasse")
		assert_eq(ex.fillable.map(func(n: int) -> float: return float(n)), entry["fillable"],
			label + " : trous que l'on peut boucher")
		total_configs += ex.configs
	assert_eq(total_configs, 8070, "total du contrôle Python")


## Solution toujours possible : de chaque combinaison atteignable du contrôle Python, les trous
## suivants se bouchent aussi avec les règles du jeu (exploration locale depuis les arrivées).
func test_every_reachable_combination_can_still_be_completed() -> void:
	var order: Array = _ref["mask_order"]
	var masks: Array = _ref["reachable_masks"]
	assert_eq(masks.size(), 64)
	assert_true(masks.has(255.0), "les 8 trous peuvent être bouchés")
	var fillable_cache: Dictionary = {}
	for mask_value: Variant in masks:
		var mask := int(mask_value)
		var successors: Array = _ref["successors"].get(str(mask), [])
		if mask != 255:
			assert_false(successors.is_empty(), "%d : au moins une chute possible" % mask)
		for succ: Array in successors:
			var map_id := StringName(succ[0])
			var floor_state := _state.floor_state(map_id, _flags_for(mask, order))
			var key := "%s %s %s" % [map_id, _sorted_pairs(floor_state.boulders),
				floor_state.plugged_holes.values()]
			if not fillable_cache.has(key):
				var storey := SeafoamFloor.new()
				storey.setup(map_id, floor_state)
				fillable_cache[key] = storey.explore(floor_state.boulders,
					storey.starts(floor_state.boulders)).fillable
			assert_true((fillable_cache[key] as Array).has(int(succ[1])),
				"%d : %s trou %d" % [mask, map_id, int(succ[1])])


## La solution du contrôle (8 chutes), rejouée poussée par poussée.
func test_python_solution_replays_with_game_rules() -> void:
	var order: Array = _ref["mask_order"]
	var flags := StoryFlags.new()
	var mask := 0
	for step: Dictionary in _ref["solution"]:
		var map_id := StringName(step["map"])
		assert_eq(int(step["mask_before"]), mask)
		var floor_state := _state.floor_state(map_id, flags)
		var storey := SeafoamFloor.new()
		storey.setup(map_id, floor_state)
		var boulders: Array = floor_state.boulders.duplicate()
		var start: Vector2i = storey.starts(boulders)[0]
		var player := start
		var pushes: Array = step["pushes"]
		for i: int in pushes.size():
			var push_data: Dictionary = pushes[i]
			var boulder := Vector2i(int(push_data["boulder"][0]), int(push_data["boulder"][1]))
			var dir: Vector2i = DIRS[push_data["dir"]]
			assert_true(boulders.has(boulder), "%s : rocher en %s" % [map_id, boulder])
			var reached := storey.reachable(boulders, player)
			var exits_or_starts := reached.has(boulder - dir)
			if not exits_or_starts:
				# Le joueur a pu passer par une autre arrivée de l'étage (échelle).
				for s: Vector2i in storey.starts(boulders):
					if storey.reachable(boulders, s).has(boulder - dir):
						exits_or_starts = true
						break
			assert_true(exits_or_starts, "%s : le joueur rejoint %s" % [map_id, boulder - dir])
			storey.place_boulders(boulders)
			var push := BoulderRules.push(storey.grid, boulder, dir, storey.open_holes,
				storey.no_push)
			storey.place_boulders([])
			boulders.erase(boulder)
			if i == pushes.size() - 1:
				assert_eq(push.outcome, BoulderRules.Outcome.FELL, "dernière poussée : chute")
				assert_eq(push.hole, int(step["hole"]))
			else:
				assert_eq(push.outcome, BoulderRules.Outcome.MOVED, "%s %s" % [boulder, dir])
				boulders.append(push.target)
			player = boulder
		var flag := StringName("seafoam_%s_hole_%d_filled"
			% [String(map_id).trim_prefix("seafoam_"), int(step["hole"])])
		flags.set_flag(flag)
		mask |= 1 << order.find(String(flag))
	assert_eq(mask, 255, "les 8 trous bouchés")
	assert_false(_state.floor_state(&"seafoam_b3f", flags).has_active_current())
	assert_false(_state.floor_state(&"seafoam_b4f", flags).has_active_current())


func _flags_for(mask: int, order: Array) -> StoryFlags:
	var flags := StoryFlags.new()
	for k: int in order.size():
		if mask >> k & 1:
			flags.set_flag(StringName(order[k]))
	return flags


## Une combinaison qui donne la configuration [param entry] à l'étage [param map_id].
func _mask_for(map_id: StringName, entry: Dictionary, order: Array) -> int:
	for mask: int in 256:
		var want: Dictionary = _ref["configurations"][str(mask)][String(map_id)]
		if want["boulders"] == entry["boulders"] and want["plugged"] == entry["plugged"] \
				and bool(want["current"]) == bool(entry["current"]):
			return mask
	return -1


## [[x, y], …] triés comme le contrôle Python (par (x, y)), en flottants (JSON).
func _sorted_pairs(cells: Array) -> Array:
	var copy := cells.duplicate()
	copy.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x < b.x or (a.x == b.x and a.y < b.y))
	return copy.map(func(c: Vector2i) -> Array: return [float(c.x), float(c.y)])
