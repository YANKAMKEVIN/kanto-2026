extends GutTest
## Le passage souterrain (jalon 15 T18, docs/tech/jalon-15.md §2.3, §3 ; dossier 18 §5, §13.1)
## sur la **vraie scène** : métadonnées (ni grotte ni intérieur, profil `underground`), grille de la
## scène = grille du plan case par case, trajet de 41 pas avec deux coudes, trois alcôves, aucune
## herbe, aucune rencontre, aucun Dresseur, escaliers vers les deux bâtiments d'entrée, six
## appliques `sconce` dans le budget de halos, budget de nœuds, Corde Sortie refusée, zone et aire
## de la Carte, objet caché (T19) et passant (T-18).
##
## Les bâtiments d'entrée : `route_6_underground_gate` (T14, intégré) est vérifié (carte et
## arrivées) ; `route_5_underground_gate` est posé par le T13 en parallèle : sa carte et ses
## arrivées ne sont pas vérifiées ici. EXCEPTION levée à l'intégration du T13 : [constant
## GATES_PENDING].

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const PLAN_PATH := "res://tools/plans/underground_path.txt"
const AREAS_PATH := "res://assets/ui/map/kanto_placeholder_areas.json"
const SIZE := Vector2i(26, 30)
const NODE_BUDGET: int = 3000
const WALKABLE: String = ".=E"
## Escaliers → bâtiment d'entrée et arrivée.
const STAIRS: Dictionary = {
	Vector2i(3, 1): [&"route_5_underground_gate", &"from_underground_w"],
	Vector2i(4, 1): [&"route_5_underground_gate", &"from_underground_e"],
	Vector2i(19, 28): [&"route_6_underground_gate", &"from_underground_w"],
	Vector2i(20, 28): [&"route_6_underground_gate", &"from_underground_e"],
}
## Bâtiments pas encore construits (T13 en parallèle) : carte et arrivée non vérifiées.
## EXCEPTION levée à l'intégration du T13 : retirer cette ligne.
const GATES_PENDING: Array[StringName] = [&"route_5_underground_gate"]

var _plan: PlanGrid
var _map: GameMap


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	var scene := load(MapCatalog.scene_path(&"underground_path")) as PackedScene
	assert_not_null(scene, "underground_path.tscn")
	_map = scene.instantiate() as GameMap
	add_child(_map)
	_map.rebuild_grid()


func after_all() -> void:
	_map.free()


func _count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count(child)
	return total


func _find_all(node: Node, out: Array[Node], test: Callable) -> void:
	if test.call(node):
		out.append(node)
	for child: Node in node.get_children():
		_find_all(child, out, test)


func _bfs(from: Vector2i, to: Vector2i) -> int:
	var grid := _map.get_grid()
	var dist: Dictionary = {from: 0}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell == to:
			return dist[cell]
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := cell + step
			if not dist.has(next) and grid.is_in_bounds(next) and not grid.is_solid(next):
				dist[next] = dist[cell] + 1
				queue.append(next)
	return -1


# --- Catégorie et lumière ---------------------------------------------------------------------


func test_metadata_neither_cave_nor_interior() -> void:
	assert_eq(_map.map_id, &"underground_path")
	assert_eq(_map.display_name, "Passage souterrain")
	assert_eq(_map.size, SIZE)
	assert_false(_map.interior, "compagnon visible : ni intérieur ni grotte")
	assert_eq(_map.light_profile, &"underground")
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	assert_false(caves.is_cave(&"underground_path"), "hors caves.json")
	assert_false(MapCatalog.load_interiors().has(&"underground_path"), "hors interiors.json")


func test_escape_rope_refused_here() -> void:
	var items := ItemLibrary.new()
	assert_true(items.load_dir(), "\n".join(items.get_errors()))
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	assert_eq(FieldItemRules.check(items.get_item(&"escape_rope"), &"underground_path", caves),
		FieldItemRules.Check.NOT_HERE, "pas de Corde Sortie")


func test_profile_is_dark_and_warm_without_sun() -> void:
	var library := LightingLibrary.new()
	assert_true(library.load_file())
	assert_eq(library.get_map_profile(&"underground_path"), &"underground")
	var profile := library.get_profile(&"underground")
	assert_not_null(profile)
	assert_false(profile.has_cast_shadow(), "aucune ombre portée")
	assert_false(profile.has_wind(), "aucun vent")
	assert_true(profile.has_contact_shadow())
	assert_gt(profile.grade_midtones.x, profile.grade_midtones.z, "étalonnage chaud")


func test_six_sconces_within_budget_and_no_light2d() -> void:
	var glows: Array[Node] = []
	_find_all(_map, glows, func(n: Node) -> bool: return n is LightGlow)
	assert_eq(glows.size(), 6, "six appliques")
	assert_lte(glows.size(), LightGlowLibrary.MAX_PER_MAP)
	for glow: Node in glows:
		assert_eq((glow as LightGlow).glow_type, &"sconce")
	var lights: Array[Node] = []
	_find_all(_map, lights, func(n: Node) -> bool: return n is Light2D)
	assert_eq(lights.size(), 0, "aucune Light2D")
	assert_true(LightGlow.library().has_type(&"sconce"))
	var sprites: Array[Node] = []
	_find_all(_map, sprites, func(n: Node) -> bool: return String(n.name).begins_with("Sconce"))
	assert_eq(sprites.size(), 6, "six appliques posées")


func test_node_budget() -> void:
	assert_lte(_count(_map), NODE_BUDGET)


# --- Grille ------------------------------------------------------------------------------------


func test_scene_grid_is_the_plan_grid() -> void:
	var grid := _map.get_grid()
	assert_eq(grid.get_size(), SIZE)
	var blocked := _plan.blocking_cells()
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if cell == Vector2i(11, 14):
				continue  # le passant : occupation, pas une case solide
			var open := WALKABLE.contains(_plan.at(cell)) and not blocked.has(cell)
			assert_eq(not grid.is_solid(cell), open, "case %s « %s »" % [cell, _plan.at(cell)])
			assert_false(grid.is_tall_grass(cell), "aucune herbe %s" % cell)
			assert_false(grid.is_rubble(cell), "aucun gravat %s" % cell)
			assert_false(grid.is_water(cell), "aucune eau %s" % cell)


func test_path_of_41_steps_with_two_corners() -> void:
	var from := _map.get_spawn_cell(&"from_route_5_w")
	var to := _map.get_spawn_cell(&"from_route_6_e")
	assert_eq(from, Vector2i(3, 2))
	assert_eq(to, Vector2i(20, 27))
	assert_eq(_bfs(Vector2i(3, 2), Vector2i(19, 27)), 41, "41 pas (≤ 50)")
	assert_eq(_bfs(_map.get_spawn_cell(&"from_route_5_e"),
		_map.get_spawn_cell(&"from_route_6_w")), 40, "voie la plus courte (files intérieures)")
	# Trois segments de deux cases de large, deux coudes à angle droit.
	for cell: Vector2i in [Vector2i(3, 2), Vector2i(4, 13), Vector2i(3, 12), Vector2i(19, 12),
			Vector2i(20, 13), Vector2i(19, 27), Vector2i(20, 27)]:
		assert_false(_map.get_grid().is_solid(cell), "galerie %s" % cell)


func test_three_alcoves_and_the_widening() -> void:
	var grid := _map.get_grid()
	for rect: Rect2i in [Rect2i(5, 5, 3, 3), Rect2i(10, 9, 3, 3), Rect2i(21, 19, 3, 3)]:
		var open := 0
		for cell: Vector2i in _cells_of(rect):
			if not grid.is_solid(cell):
				open += 1
		assert_gte(open, 6, "alcôve %s : au moins 6 cases libres sur 9" % rect)
	for x: int in range(8, 15):
		assert_false(grid.is_solid(Vector2i(x, 14)), "renflement (%d, 14)" % x)
	for cell: Vector2i in [Vector2i(7, 6), Vector2i(23, 20), Vector2i(11, 9)]:
		assert_true(grid.is_solid(cell), "stèle, banc, pierre : bloqués %s" % cell)


func _cells_of(rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, y))
	return cells


# --- Passages ----------------------------------------------------------------------------------


func test_stairs_lead_to_the_two_entrance_buildings() -> void:
	var warps := _map.get_warps().get_all()
	assert_eq(warps.size(), 4, "quatre cases d'escalier")
	for warp: Warp in warps:
		assert_true(STAIRS.has(warp.cell), "escalier en %s" % warp.cell)
		if not STAIRS.has(warp.cell):
			continue
		assert_eq(warp.target_map, STAIRS[warp.cell][0])
		assert_eq(warp.target_spawn, STAIRS[warp.cell][1])
		assert_false(warp.is_coming_soon())
		assert_eq(warp.trigger, Warp.Trigger.STEP_ON)
		assert_eq(warp.direction, Vector2i.ZERO, "escalier sans direction")
		if GATES_PENDING.has(warp.target_map):
			continue
		assert_true(MapCatalog.has_map(warp.target_map), String(warp.target_map))
		var gate := (load(MapCatalog.scene_path(warp.target_map)) as PackedScene) \
				.instantiate() as GameMap
		assert_true(gate.has_spawn(warp.target_spawn), "%s/%s" % [warp.target_map,
			warp.target_spawn])
		gate.free()


func test_arrivals_are_walkable_and_next_to_the_stairs() -> void:
	var expected: Dictionary = {&"from_route_5_w": Vector2i(3, 2),
		&"from_route_5_e": Vector2i(4, 2), &"from_route_6_w": Vector2i(19, 27),
		&"from_route_6_e": Vector2i(20, 27)}
	for spawn: StringName in expected:
		assert_true(_map.has_spawn(spawn), String(spawn))
		var cell := _map.get_spawn_cell(spawn)
		assert_eq(cell, expected[spawn])
		assert_false(_map.get_grid().is_solid(cell))
		assert_false(_map.get_warps().get_at(cell).size() > 0, "l'arrivée n'est pas un escalier")
		var stairs := cell + (Vector2i.UP if cell.y < 10 else Vector2i.DOWN)
		assert_eq(_map.get_warps().get_at(stairs).size(), 1, "escalier voisin de %s" % spawn)


func test_no_trigger_no_wild_encounter_no_trainer() -> void:
	var triggers := _map.get_node(^"Triggers")
	assert_eq(triggers.get_child_count(), 0, "aucun déclencheur")
	var data := PokemonData.new()
	data.load_dir()
	var encounters := EncounterLibrary.new(data)
	assert_true(encounters.load_dir())
	for terrain: StringName in [&"grass", &"rubble", &"water"]:
		assert_false(encounters.has_table(&"underground_path", terrain), "aucune rencontre")
	var file := FileAccess.get_file_as_string("res://data/npcs/underground_path.json")
	var npcs: Dictionary = JSON.parse_string(file)
	for id: String in npcs:
		assert_false((npcs[id] as Dictionary).has("trainer"), "%s : pas de Dresseur" % id)
	assert_eq(npcs.keys(), ["passer"], "le passant seul")


# --- Passant (T-18) et objet caché (T19) ---------------------------------------------------------


func test_passer_stands_in_the_widening() -> void:
	var passer := _map.get_npc(&"passer")
	assert_not_null(passer, "le passant")
	if passer == null:
		return
	assert_eq(passer.get_cell(), Vector2i(11, 14))
	assert_eq(passer.get_facing(), Vector2i.UP)
	assert_false(_map.get_grid().is_solid(Vector2i(11, 13)), "2 cases de large : la galerie reste libre")
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), "\n".join(dialogues.get_errors()))
	var talk := dialogues.get_dialogue(&"underground_passer")
	assert_not_null(talk)
	assert_eq(talk.speaker, "Vieil homme")


func test_hidden_point_is_on_the_loose_stone() -> void:
	var points := _map.get_node(^"Interactables").get_children()
	assert_eq(points.size(), 1, "un seul point d'examen")
	var point := points[0] as InteractPoint
	assert_not_null(point)
	assert_eq(_map.get_grid().is_solid(Vector2i(11, 9)), true)
	assert_eq(point.dialogue_id, &"underground_hidden_1")
	assert_eq(point.unless_flags, [&"got_underground_hidden_1"] as Array[StringName])
	assert_eq(Vector2i(((point.position - Vector2(0.0, 1.0)) / 96.0).floor()), Vector2i(11, 9), "sur la pierre")


# --- Zone et Carte -------------------------------------------------------------------------------


func test_zone_and_map_area() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file(), "\n".join(zones.get_errors()))
	var zone := zones.get_zone(&"underground_path")
	assert_not_null(zone, "zone du souterrain")
	assert_eq(zone.name, "Passage souterrain")
	assert_eq(zone.maps, [&"underground_path"] as Array[StringName])
	assert_eq(zone.subtitle, "Route 5 — Route 6")
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(AREAS_PATH))
	var areas: Dictionary = doc["zones"]
	assert_true(areas.has("underground_path"), "visible sur la Carte")
	var a: Array = areas["underground_path"]["area"]
	var saffron: Array = areas["saffron_city"]["area"]
	assert_gte(int(a[1]), int(saffron[1]) + int(saffron[3]), "sous Safrania")
