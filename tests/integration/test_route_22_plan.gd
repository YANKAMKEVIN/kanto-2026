extends GutTest
## Relevé de la Route 22 du jalon 7 en grille (jalon 29, T2 ; `docs/tech/jalon-29.md` §0.1) :
## `tools/plans/route_22.txt` et la scène `route_22` coïncident case par case (praticable, hautes
## herbes), et les repères de la grille (points d'apparition, warps, déclencheur du rival n° 2)
## sont ceux de la scène. La carte du J7 garde son comportement ; la grille fige sa logique.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const PLAN_PATH := "res://tools/plans/route_22.txt"
const MAP_PATH := "res://game/world/maps/route_22.tscn"

var _plan: Object
var _map: GameMap
var _grid: GridWorld


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()


func after_all() -> void:
	_map.free()


func test_size_matches() -> void:
	assert_eq(Vector2i(_plan.width, _plan.height), _map.size)


func test_every_cell_matches_the_map() -> void:
	var diffs: Array[String] = []
	for y: int in _plan.height:
		for x: int in _plan.width:
			var cell := Vector2i(x, y)
			var walkable: bool = _plan.is_walkable(cell)
			var grass: bool = _plan.at(cell) == "h"
			if walkable == _grid.is_solid(cell) or grass != _grid.is_tall_grass(cell):
				diffs.append("%s grille « %s »" % [cell, _plan.at(cell)])
	assert_eq(diffs.size(), 0, "cases qui diffèrent : %s" % ", ".join(diffs.slice(0, 12)))


func test_spawns_match() -> void:
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] == "spawn":
			assert_eq(_map.get_spawn_cell(StringName(id)), _plan.cell_of(id), id)


func test_warps_match() -> void:
	var expected := 0
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] != "warp":
			continue
		var target: String = _plan.attr(id, "vers")
		for cell: Vector2i in _plan.cells_at(id):
			expected += 1
			var found: Warp = null
			for warp: Warp in _map.get_warps().get_all():
				if warp.cell == cell:
					found = warp
			assert_not_null(found, "%s : warp en %s" % [id, cell])
			if found != null:
				assert_eq("%s:%s" % [found.target_map, found.target_spawn], target, id)
	assert_eq(_map.get_warps().size(), expected, "aucun autre warp")


func test_rival_2_trigger_matches() -> void:
	var cells: Array[Vector2i] = _plan.cells_at("rival_vista")
	for cell: Vector2i in cells:
		var trigger := _map.get_triggers().find_on_step(cell, Vector2i.LEFT)
		assert_not_null(trigger, "déclencheur en %s" % cell)
		if trigger != null:
			assert_eq(trigger.cutscene_id, StringName(_plan.attr("rival_vista", "scene")))
	assert_eq(_map.get_triggers().size(), cells.size(), "aucun autre déclencheur que celui du rival n° 2")
