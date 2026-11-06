extends GutTest
## Chapitre Johto, JOH8 : les quatre cartes construites depuis leurs grilles
## (`tools/build_joh8_maps.gd`) : grille = plan, raccords et escaliers, planches qui cèdent (chute
## au 1F, jamais au sommet ni hors de la carte, dossier §12), chemin sans chute au 2F, Sbire V
## inévitable, cage de feu (FlagGate), long escalier en scène, Corde Sortie.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const MAPS: Array[StringName] = [&"bell_tower_woods", &"bell_tower_1f", &"bell_tower_2f",
	&"bell_tower_roof"]
## Positions qui ne sont pas dans la grille logique de la scène (PNJ et objets : au chargement) ;
## la cage est une FlagGate (occupée à l'exécution).
const NPC_KINDS: Array[String] = ["dresseur", "pnj", "objet_visible", "pokemon"]
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const FALL: int = 2

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


func _cells(id: StringName, position: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.assign((_plan(id).positions[position] as Dictionary)["cells"])
	return cells


func _falls(id: StringName) -> Dictionary:
	var falls: Dictionary = {}
	for warp: Warp in _map(id).get_warps().get_all():
		if int(warp.trigger) == FALL:
			falls[warp.cell] = warp
	return falls


func _reachable(map: GameMap, from: Array[Vector2i], banned: Dictionary = {}) -> Dictionary:
	var grid := map.get_grid()
	var seen: Dictionary = {}
	var queue: Array[Vector2i] = []
	for cell: Vector2i in from:
		if not grid.is_solid(cell) and not banned.has(cell):
			seen[cell] = true
			queue.append(cell)
	var head := 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		for direction: Vector2i in DIRS:
			var next := current + direction
			if seen.has(next) or not grid.is_in_bounds(next) or grid.is_solid(next) \
					or banned.has(next):
				continue
			seen[next] = true
			queue.append(next)
	return seen


func test_maps_exist_with_their_ids_and_profiles() -> void:
	var profiles: Dictionary = {&"bell_tower_woods": &"johto_auto", &"bell_tower_1f": &"tower",
		&"bell_tower_2f": &"tower", &"bell_tower_roof": &"johto_auto"}
	for id: StringName in MAPS:
		var map := _map(id)
		assert_eq(map.map_id, id)
		assert_false(map.interior, String(id))
		assert_eq(map.light_profile, profiles[id], String(id))
		assert_eq(map.size, Vector2i(_plan(id).width, _plan(id).height), String(id))
	assert_eq(_map(&"bell_tower_woods").display_name, "Bois de la Tour")
	assert_eq(_map(&"bell_tower_roof").display_name, "Tour Carillon")


## La grille fait foi (la cage de feu exceptée : ses barreaux sont tenus par sa FlagGate).
func test_scene_grid_equals_the_plan() -> void:
	for id: StringName in MAPS:
		var map := _map(id)
		var plan := _plan(id)
		var grid := map.get_grid()
		var blocking: Dictionary = {}
		for position: String in plan.positions:
			var entry: Dictionary = plan.positions[position]
			if entry["blocks"] and not NPC_KINDS.has(entry["kind"]) and position != "cage_feu":
				for cell: Vector2i in entry["cells"]:
					blocking[cell] = true
		var mismatches: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				if plan.at(cell) == "c":
					continue
				var expected_free := plan.is_walkable(cell) and not blocking.has(cell)
				if expected_free == grid.is_solid(cell):
					mismatches.append(cell)
		assert_eq(mismatches, [] as Array[Vector2i], "%s : cases en désaccord avec la grille" % id)


func test_links_woods_tower_and_stairs() -> void:
	var links: Array = [
		[&"bell_tower_woods", &"bell_tower_1f", 2], [&"bell_tower_1f", &"bell_tower_woods", 2],
		[&"bell_tower_1f", &"bell_tower_2f", 1], [&"bell_tower_2f", &"bell_tower_1f", 1],
		[&"bell_tower_roof", &"bell_tower_2f", 1],
	]
	for link: Array in links:
		var count := 0
		for warp: Warp in _map(link[0]).get_warps().get_all():
			if warp.target_map == link[1] and int(warp.trigger) != FALL:
				count += 1
				var target := _map(link[1])
				assert_true(target.has_spawn(warp.target_spawn), "%s → %s / %s" % [link[0],
					link[1], warp.target_spawn])
				assert_false(target.get_grid().is_solid(target.get_spawn_cell(warp.target_spawn)))
		assert_eq(count, link[2], "%s → %s" % [link[0], link[1]])
	# Le 2F ne mène au sommet que par la scène du long escalier (H-12), jamais par un warp.
	for warp: Warp in _map(&"bell_tower_2f").get_warps().get_all():
		assert_ne(warp.target_map, &"bell_tower_roof")
	var climb := _trigger(&"bell_tower_2f", &"bell_tower_climb")
	assert_not_null(climb, "déclencheur du long escalier")
	if climb != null:
		assert_eq(climb.get_cells(), [Vector2i(3, 0)] as Array[Vector2i])
	# Raccord sud du Bois vers Rosalia (« À venir » tant que la carte du JOH2 manque).
	var south := 0
	for warp: Warp in _map(&"bell_tower_woods").get_warps().get_all():
		if _cells(&"bell_tower_woods", "warp_sud").has(warp.cell):
			south += 1
			assert_eq(int(warp.trigger), 1, "PUSH")
			if ResourceLoader.exists("res://game/world/maps/ecruteak_city.tscn"):
				assert_eq(warp.target_map, &"ecruteak_city")
				assert_true(String(warp.target_spawn).begins_with("from_bois"))
	assert_eq(south, 2)


func _trigger(id: StringName, scene: StringName) -> EventTriggerPoint:
	for point: Node in _map(id).get_node(^"Triggers").get_children():
		if (point as EventTriggerPoint).cutscene_id == scene:
			return point
	return null


## Planches qui cèdent : chaque case `O` tombe à l'arrivée `chute` du 1F, case praticable ;
## aucune ne mène au sommet ni hors de la carte (dossier §12).
func test_collapsing_planks_drop_to_the_first_floor_only() -> void:
	var plan := _plan(&"bell_tower_2f")
	var falls := _falls(&"bell_tower_2f")
	var planks: Array[Vector2i] = []
	for y: int in plan.height:
		for x: int in plan.width:
			if plan.at(Vector2i(x, y)) == "O":
				planks.append(Vector2i(x, y))
	assert_eq(falls.size(), planks.size())
	var first := _map(&"bell_tower_1f")
	for cell: Vector2i in planks:
		assert_true(falls.has(cell), "planche %s" % cell)
		if not falls.has(cell):
			continue
		var warp: Warp = falls[cell]
		assert_eq([warp.target_map, warp.target_spawn], [&"bell_tower_1f", &"chute"], str(cell))
	assert_true(first.has_spawn(&"chute"))
	assert_false(first.get_grid().is_solid(first.get_spawn_cell(&"chute")))
	assert_eq(first.get_spawn_cell(&"chute"), Vector2i(12, 12))
	for id: StringName in [&"bell_tower_woods", &"bell_tower_1f", &"bell_tower_roof"]:
		assert_eq(_falls(id).size(), 0, "%s : aucune chute" % id)


## Un chemin sans chute mène de l'escalier du 1F à celui du sommet (grille §2F).
func test_second_floor_has_a_path_without_falling() -> void:
	var map := _map(&"bell_tower_2f")
	var reached := _reachable(map, _cells(&"bell_tower_2f", "from_1f"), _falls(&"bell_tower_2f"))
	assert_true(reached.has(Vector2i(3, 0)), "escalier du sommet sans planche")
	assert_true(reached.has(Vector2i(3, 9)), "Hiroshi (3, 8) abordable")
	assert_true(reached.has(Vector2i(12, 10)), "PP Plus (12, 9) abordable par le bas")


## Sbire V voit (20, 4), seul accès à la niche de l'escalier du 1F : inévitable.
func test_first_floor_stairs_only_through_the_grunt_sight() -> void:
	var map := _map(&"bell_tower_1f")
	var banned := {Vector2i(20, 4): true, Vector2i(21, 4): true}
	var reached := _reachable(map, _cells(&"bell_tower_1f", "from_woods"), banned)
	assert_false(reached.has(Vector2i(20, 0)), "l'escalier ne s'atteint que par (20, 4)")
	var free := _reachable(map, _cells(&"bell_tower_1f", "from_woods"), {Vector2i(21, 4): true})
	assert_true(free.has(Vector2i(20, 0)))


func test_fire_cage_is_a_blocking_gate_until_ho_oh() -> void:
	var gate := _map(&"bell_tower_roof").find_child("CageDeFeu", true, false) as FlagGate
	assert_not_null(gate)
	if gate == null:
		return
	assert_eq(gate.unless_flags, [&"johto_ho_oh_seen"] as Array[StringName])
	var bars: Array[Vector2i] = []
	for cell: Vector2i in _cells(&"bell_tower_roof", "cage_feu"):
		if _plan(&"bell_tower_roof").at(cell) == "c":
			bars.append(cell)
	assert_eq(gate.blocking_cells, bars)
	# La scène du palier est sur la seule sortie (3, 3).
	var summit := _trigger(&"bell_tower_roof", &"bell_tower_summit")
	assert_not_null(summit)
	var banned := {Vector2i(3, 3): true}
	var reached := _reachable(_map(&"bell_tower_roof"), _cells(&"bell_tower_roof", "from_2f"), banned)
	assert_false(reached.has(Vector2i(9, 7)), "le palier ne s'ouvre que par (3, 3)")


func test_escape_rope_in_the_tower_returns_before_the_door() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	for id: StringName in [&"bell_tower_1f", &"bell_tower_2f"]:
		var exit := caves.escape_target(id)
		assert_not_null(exit, String(id))
		if exit != null:
			assert_eq([exit.map, exit.spawn], [&"bell_tower_woods", &"retour_tour"])
	# Sommet : à ciel ouvert, la Corde Sortie y est refusée [D] (dossier §12).
	assert_false(caves.is_cave(&"bell_tower_roof"))
	assert_false(caves.is_cave(&"bell_tower_woods"))
	assert_true(_map(&"bell_tower_woods").has_spawn(&"retour_tour"))


## Peinture (`tools/build_joh_ambiance_carillon.gd`) : couches de tuiles masquées, aucun aplat
## provisoire, la cage garde son image dans sa [FlagGate], le sommet a son décor de combat.
func test_cartes_peintes_sans_provisoires() -> void:
	for id: StringName in MAPS:
		var map := _map(id)
		assert_false((map.get_node(^"Ground") as TileMapLayer).visible, "%s : tuiles masquées" % id)
		assert_eq(map.find_children("*", "Polygon2D", true, false).size(), 0, "%s : aplats" % id)
		assert_eq(map.find_children("*", "Line2D", true, false).size(), 0, "%s : liserés" % id)
	var cage := _map(&"bell_tower_roof").get_node(^"Entities/CageDeFeu")
	assert_not_null(cage.get_node_or_null(^"JohAmbCarillonBarreaux"), "image de la cage")


func test_decor_de_combat_du_sommet() -> void:
	var decors: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/battle/decors.json"))
	assert_eq(String((decors["places"]["bell_tower_roof"] as Array)[0]["decor"]), "bell_tower_sommet")
	assert_true(ResourceLoader.exists(String(decors["decors"]["bell_tower_sommet"]["back"])), "image")
