extends GutTest
## Arc des Pierres, JOHP3 : les trois cartes construites depuis leurs grilles
## (`tools/build_johp3_maps.gd`) et les intérieurs (`build_painted_interiors.gd --blackthorn`) :
## grille = plan, bassins sans Surf, raccords, arrivées, l'Antre sans sortie à pied d'Ébènelle.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const PLANS: Array[StringName] = [&"blackthorn_city", &"dragons_den_1f", &"dragons_den_sanctuary"]
const LIGHTS: Dictionary = {&"blackthorn_city": &"johto_auto", &"dragons_den_1f": &"cave_1f",
	&"dragons_den_sanctuary": &"cave_b1f"}
const INTERIORS: Array[StringName] = [&"blackthorn_center", &"blackthorn_elder_house",
	&"blackthorn_house_1"]
const NPC_KINDS: Array[String] = ["dresseur", "pnj", "objet_visible", "pokemon"]

var _cache: Dictionary = {}
var _plans: Dictionary = {}


func after_all() -> void:
	for map: Variant in _cache.values():
		(map as Node).free()
	_cache.clear()


func _map(id: StringName) -> GameMap:
	if not _cache.has(id):
		var path := "res://game/world/maps/%s.tscn" % id
		assert_true(ResourceLoader.exists(path), path)
		var map := (load(path) as PackedScene).instantiate() as GameMap
		_cache[id] = map
		map.get_grid()
	return _cache[id]


func _plan(id: StringName) -> PlanGrid:
	if not _plans.has(id):
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/%s.txt" % id), plan.error)
		_plans[id] = plan
	return _plans[id]


func test_maps_exist_with_their_ids_and_profiles() -> void:
	for id: StringName in PLANS:
		var map := _map(id)
		assert_eq(map.map_id, id)
		assert_false(map.interior, String(id))
		assert_eq(map.size, Vector2i(_plan(id).width, _plan(id).height), String(id))
		assert_eq(map.light_profile, LIGHTS[id], String(id))
	for id: StringName in INTERIORS:
		var map := _map(id)
		assert_true(map.interior, String(id))
		assert_eq(map.light_profile, &"interior_warm", String(id))
	assert_eq(_map(&"blackthorn_city").display_name, "Ébènelle")
	assert_eq(_map(&"dragons_den_1f").display_name, "Antre du Dragon")


## La grille fait foi ; les bassins ne se surfent pas (A-6 : aucune CS dans l'arc).
func test_scene_grid_equals_the_plan() -> void:
	for id: StringName in PLANS:
		var map := _map(id)
		var plan := _plan(id)
		var grid := map.get_grid()
		var blocking: Dictionary = {}
		for position: String in plan.positions:
			var entry: Dictionary = plan.positions[position]
			if entry["blocks"] and not NPC_KINDS.has(entry["kind"]):
				for cell: Vector2i in entry["cells"]:
					blocking[cell] = true
		var mismatches: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				var expected_free := plan.is_walkable(cell) and not blocking.has(cell)
				if expected_free == grid.is_solid(cell):
					mismatches.append(cell)
				assert_false(grid.is_surfable(cell), "%s %s : pas de Surf" % [id, cell])
		assert_eq(mismatches, [] as Array[Vector2i], "%s : cases en désaccord avec la grille" % id)


func test_warps_link_the_three_maps() -> void:
	assert_true(_warp_to(&"blackthorn_city", &"dragons_den_1f"), "bouche de l'Antre")
	assert_true(_warp_to(&"dragons_den_1f", &"blackthorn_city"), "sortie")
	assert_true(_warp_to(&"dragons_den_1f", &"dragons_den_sanctuary"), "descente")
	assert_true(_warp_to(&"dragons_den_sanctuary", &"dragons_den_1f"), "remontée")
	for id: StringName in INTERIORS:
		assert_true(_warp_to(&"blackthorn_city", id), String(id))
		assert_true(_warp_to(id, &"blackthorn_city"), String(id))


## §4.1 : aucune sortie à pied d'Ébènelle, seulement l'Antre et les intérieurs.
func test_blackthorn_has_no_way_out_on_foot() -> void:
	var allowed: Array[StringName] = [&"dragons_den_1f"]
	allowed.append_array(INTERIORS)
	for warp: Node in _map(&"blackthorn_city").get_node(^"Warps").get_children():
		assert_true(allowed.has(warp.get(&"target_map")), String(warp.name))


## Les rangées des deux barrières sont ouvertes : prises de côté, elles tiennent aussi.
func test_barriers_hold_from_every_side() -> void:
	for pair: Array in [[&"blackthorn_city", "BarriereAntre"], [&"dragons_den_1f", "BarriereSanctuaire"]]:
		var trigger := _map(pair[0]).get_node("Triggers/%s" % pair[1])
		assert_eq(trigger.get(&"direction"), Vector2i.ZERO, String(pair[0]))


func test_den_is_painted_with_its_altar_and_stairs() -> void:
	var one := _map(&"dragons_den_1f")
	assert_not_null(one.get_node_or_null(^"PaintedGround"))
	assert_false(one.get_node(^"Ground").visible, "tuiles masquées")
	var two := _map(&"dragons_den_sanctuary")
	assert_not_null(two.get_node_or_null(^"PaintedGround"))
	assert_not_null(two.get_node_or_null(^"Entities/JohAmbCaveAutelPeint"))
	assert_eq(two.get_node(^"Decor").get_child_count(), 0, "plus d'aplat provisoire")


func _warp_to(from: StringName, target: StringName) -> bool:
	for warp: Node in _map(from).get_node(^"Warps").get_children():
		if warp.get(&"target_map") == target:
			return true
	return false
