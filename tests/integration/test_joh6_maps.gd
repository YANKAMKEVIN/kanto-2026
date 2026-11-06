extends GutTest
## Chapitre Johto, JOH6 : les cartes construites depuis leurs grilles (`tools/build_joh6_maps.gd`)
## et les intérieurs d'Acajou (`build_painted_interiors.gd --acajou`) : grille = plan, raccords,
## trous, dalles, portes à drapeau, déclencheurs, Dresseurs inévitables
## (`docs/tech/jalon-joh6.md` §2.1, §2.2).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

## Carte → [grille, lumière, intérieur].
const MAPS: Dictionary = {
	&"burned_tower_1f": ["burned_tower_1f", &"johto_auto", false],
	&"burned_tower_b1f": ["burned_tower_b1f", &"cave_b1f", false],
	&"route_42": ["route_42", &"johto_auto", false],
	&"mahogany_town": ["mahogany_town", &"johto_auto", false],
	&"mahogany_souvenir_shop": ["mahogany_souvenir_shop", &"interior_warm", true],
	&"route_43": ["route_43", &"johto_auto", false],
	&"lake_of_rage": ["lake_of_rage", &"johto_auto", false],
	&"mahogany_hideout_b1f": ["mahogany_hideout_b1f", &"hideout", false],
	&"mahogany_hideout_b2f": ["mahogany_hideout_b2f", &"hideout", false],
	&"mahogany_hideout_b3f": ["mahogany_hideout_b3f", &"hideout", false],
}
const INTERIORS: Array[StringName] = [&"mahogany_center", &"mahogany_house_1",
	&"mahogany_house_2", &"dante_flashback_hq"]
## Positions qui entrent au chargement (PNJ, objets, Pokémon) : pas dans la grille de la scène.
const NPC_KINDS: Array[String] = ["dresseur", "pnj", "objet_visible", "pokemon"]
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
## Déclencheurs posés : (carte, nœud) → scène.
const TRIGGERS: Dictionary = {
	[&"burned_tower_1f", "PlancherEffondre"]: &"burned_tower_floor",
	[&"burned_tower_b1f", "SceneChiens"]: &"burned_tower_beasts",
	[&"mahogany_souvenir_shop", "SceneEscalier"]: &"souvenir_shop_stairs",
	[&"mahogany_hideout_b1f", "Alarme1"]: &"hideout_alarm_1",
	[&"mahogany_hideout_b1f", "Alarme2"]: &"hideout_alarm_2",
	[&"mahogany_hideout_b1f", "Alarme3"]: &"hideout_alarm_3",
	[&"mahogany_hideout_b3f", "SceneBrace"]: &"hideout_brace",
	[&"lake_of_rage", "BarriereSentier"]: &"lake_trail_guard",
	[&"ecruteak_city", "SceneDoyenPlan"]: &"ecruteak_dante_plan",
}
## Portes à drapeau : (carte, nœud) → [drapeau d'ouverture, cases occupées].
const GATES: Dictionary = {
	[&"mahogany_souvenir_shop", "EtagereCachee"]: [&"johto_hideout_found", [Vector2i(12, 3)]],
	[&"mahogany_hideout_b2f", "PortePorteMdp"]: [&"johto_password_said", [Vector2i(3, 3)]],
	[&"mahogany_hideout_b2f", "PortePorteCellule"]: [&"johto_cell_opened", [Vector2i(7, 16)]],
	[&"mahogany_hideout_b3f", "CageAOndes"]: [&"johto_generator_off", [Vector2i(17, 10)]],
}

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
		assert_true(plan.load_file("res://tools/plans/%s.txt" % MAPS[id][0]), plan.error)
		_plans[id] = plan
	return _plans[id]


func _cells(id: StringName, position: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.assign((_plan(id).positions[position] as Dictionary)["cells"])
	return cells


func _reachable(map: GameMap, from: Array[Vector2i], banned: Array[Vector2i] = []) -> Dictionary:
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


func _node(map_id: StringName, node_name: String) -> Node:
	var map := _map(map_id)
	for child: Node in map.find_children(node_name, "", true, false):
		return child
	return null


func test_maps_exist_with_their_ids_profiles_and_sizes() -> void:
	for id: StringName in MAPS:
		var map := _map(id)
		assert_eq(map.map_id, id)
		assert_eq(map.light_profile, MAPS[id][1], String(id))
		assert_eq(map.interior, MAPS[id][2], String(id))
		assert_eq(map.size, Vector2i(_plan(id).width, _plan(id).height), String(id))
	for id: StringName in INTERIORS:
		var map := _map(id)
		assert_eq(map.map_id, id)
		assert_true(map.interior, String(id))
	assert_eq(_map(&"mahogany_town").display_name, "Acajou")
	assert_eq(_map(&"lake_of_rage").display_name, "Lac Colère")


## La grille fait foi : une case est praticable dans la scène si et seulement si elle l'est dans
## la grille et qu'aucune position bloquante (hors PNJ) ne l'occupe.
func test_scene_grid_equals_the_plan() -> void:
	for id: StringName in MAPS:
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
		assert_eq(mismatches, [] as Array[Vector2i], "%s : cases en désaccord avec la grille" % id)


func test_lakes_are_surfable_water() -> void:
	for pair: Array in [[&"route_42", Vector2i(35, 10)], [&"lake_of_rage", Vector2i(27, 30)]]:
		var grid := _map(pair[0]).get_grid()
		assert_true(grid.is_water(pair[1]), "%s : eau en %s" % pair)
		assert_true(grid.is_surfable(pair[1]), "%s : surfable en %s" % pair)
	assert_eq(_map(&"lake_of_rage").surf_cells.size(), _plan(&"lake_of_rage").cells_of("w").size())
	assert_eq(_map(&"lake_of_rage").fishable_cells.size(),
		_plan(&"lake_of_rage").cells_of("w").size(), "pêche sur tout le lac")
	assert_true(_map(&"route_42").fishable_cells.is_empty(), "pas de pêche notée (grille)")
	# Les dalles du repaire ne sont pas de l'eau.
	assert_false(_map(&"mahogany_hideout_b2f").get_grid().is_water(Vector2i(10, 4)))


func test_all_walkable_cells_are_connected() -> void:
	var starts: Dictionary = {
		&"burned_tower_1f": "from_city", &"burned_tower_b1f": "chute", &"route_42": "from_ecruteak",
		&"mahogany_town": "from_route_42", &"mahogany_souvenir_shop": "entrance",
		&"route_43": "from_mahogany", &"lake_of_rage": "from_route_43",
		&"mahogany_hideout_b1f": "from_shop", &"mahogany_hideout_b2f": "from_b1f",
		&"mahogany_hideout_b3f": "from_b2f",
	}
	for id: StringName in starts:
		var map := _map(id)
		var plan := _plan(id)
		var reached := _reachable(map, _cells(id, starts[id]))
		# Cases des PNJ (le vendeur derrière son comptoir) : occupées au chargement.
		for position: String in plan.positions:
			var entry: Dictionary = plan.positions[position]
			if NPC_KINDS.has(entry["kind"]):
				for cell: Vector2i in entry["cells"]:
					reached[cell] = true
		var isolated: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				if not map.get_grid().is_solid(cell) and not reached.has(cell):
					isolated.append(cell)
		assert_eq(isolated, [] as Array[Vector2i], "%s : cases isolées" % id)


func test_every_warp_reaches_a_free_spawn_or_is_coming_soon() -> void:
	var coming_soon := 0
	for id: StringName in MAPS.keys() + [&"mahogany_center", &"mahogany_house_1",
			&"mahogany_house_2", &"dante_flashback_hq", &"ecruteak_city"]:
		for warp: Warp in _map(id).get_warps().get_all():
			if warp.target_map.is_empty():
				coming_soon += 1
				continue
			var target := _map(warp.target_map)
			assert_true(target.has_spawn(warp.target_spawn), "%s → %s / %s" % [id,
				warp.target_map, warp.target_spawn])
			assert_false(target.get_grid().is_solid(target.get_spawn_cell(warp.target_spawn)),
				"%s → %s / %s : arrivée bloquée" % [id, warp.target_map, warp.target_spawn])
	# Tous les raccords sont réels depuis la fusion du JOH9 (sentier du Mont Argenté).
	assert_eq(coming_soon, 0)


func test_links_both_ways_between_the_new_maps() -> void:
	var chain: Array = [[&"ecruteak_city", &"route_42", 3], [&"route_42", &"mahogany_town", 3],
		[&"mahogany_town", &"route_43", 3], [&"route_43", &"lake_of_rage", 3],
		[&"ecruteak_city", &"burned_tower_1f", 2], [&"burned_tower_1f", &"burned_tower_b1f", 1],
		[&"mahogany_town", &"mahogany_souvenir_shop", 2],
		[&"mahogany_souvenir_shop", &"mahogany_hideout_b1f", 1],
		[&"mahogany_hideout_b1f", &"mahogany_hideout_b2f", 1],
		[&"mahogany_hideout_b2f", &"mahogany_hideout_b3f", 1]]
	for link: Array in chain:
		for way: Array in [[link[0], link[1]], [link[1], link[0]]]:
			var count := 0
			for warp: Warp in _map(way[0]).get_warps().get_all():
				if warp.target_map == way[1] and warp.trigger != Warp.Trigger.FALL:
					count += 1
			assert_gte(count, 1, "%s → %s" % way)
		var forward := 0
		for warp: Warp in _map(link[0]).get_warps().get_all():
			if warp.target_map == link[1] and warp.trigger != Warp.Trigger.FALL:
				forward += 1
		assert_eq(forward, link[2], "%s → %s : cases" % [link[0], link[1]])


func test_tower_holes_fall_to_the_basement() -> void:
	var falls := 0
	for warp: Warp in _map(&"burned_tower_1f").get_warps().get_all():
		if warp.trigger == Warp.Trigger.FALL:
			falls += 1
			assert_eq(warp.target_map, &"burned_tower_b1f")
			assert_eq(warp.target_spawn, &"chute")
	assert_eq(falls, _plan(&"burned_tower_1f").cells_of("O").size())
	# Le dallage d'entrée est calme (aucune rencontre des cendres).
	var calm := _map(&"burned_tower_1f").calm_cells
	assert_true(calm.has(Vector2i(13, 20)))
	assert_false(calm.has(Vector2i(13, 16)))


func test_stairs_of_the_shop_and_the_tower_entrance_need_their_flags() -> void:
	for pair: Array in [[&"mahogany_souvenir_shop", &"johto_hideout_found",
			&"mahogany_hideout_b1f"], [&"ecruteak_city", &"johto_burned_tower_open",
			&"burned_tower_1f"]]:
		for warp: Warp in _map(pair[0]).get_warps().get_all():
			if warp.target_map == pair[2]:
				assert_true(warp.if_flags.has(pair[1]), "%s → %s : %s" % [pair[0], pair[2], pair[1]])


func test_flag_gates() -> void:
	for key: Array in GATES:
		var gate := _node(key[0], key[1]) as FlagGate
		assert_not_null(gate, "%s/%s" % key)
		if gate == null:
			continue
		assert_eq(gate.unless_flags, [GATES[key][0]] as Array[StringName], "%s/%s" % key)
		var cells: Array[Vector2i] = []
		cells.assign(GATES[key][1])
		assert_eq(gate.blocking_cells, cells, "%s/%s" % key)


func test_triggers_point_to_their_scenes() -> void:
	for key: Array in TRIGGERS:
		var point := _node(key[0], key[1])
		assert_not_null(point, "%s/%s" % key)
		if point != null:
			assert_eq(point.get(&"cutscene_id"), TRIGGERS[key], "%s/%s" % key)


## Dalles du B2F : chaque dalle de la grille glisse jusqu'à la case d'arrêt annoncée (« arret= »).
func test_spin_tiles_end_where_the_plan_says() -> void:
	var map := _map(&"mahogany_hideout_b2f")
	var field := _node(&"mahogany_hideout_b2f", "SpinTiles") as SpinTileField
	assert_not_null(field)
	if field == null:
		return
	var plan := _plan(&"mahogany_hideout_b2f")
	assert_eq(field.arrows.size(), plan.cells_of("<>^v").size())
	var walkable := func(cell: Vector2i) -> bool: return not map.get_grid().is_solid(cell)
	var checked := 0
	for position: String in plan.positions:
		var entry: Dictionary = plan.positions[position]
		if entry["kind"] != "dalle":
			continue
		var start: Vector2i = entry["cells"][0]
		var stop := PlanGrid.parse_cells(plan.attr(position, "arret"))[0]
		var slide := field.slide_from(start, walkable)
		assert_true(slide.is_ok(), "%s : %s" % [position, slide.status_name()])
		assert_eq(slide.end, stop, position)
		checked += 1
	assert_gt(checked, 40)


## Dresseurs inévitables (dossier §6) : sans la case qu'ils regardent, l'autre côté est
## inaccessible.
func test_unavoidable_trainers_hold_the_only_passage() -> void:
	var cases: Array = [
		[&"route_42", "from_ecruteak", [Vector2i(53, 10)], "from_mahogany"],
		[&"route_43", "from_mahogany", [Vector2i(11, 25)], "from_lake"],
		[&"mahogany_hideout_b2f", "from_b1f", [Vector2i(3, 4)], "from_b3f"],
		[&"mahogany_hideout_b3f", "from_b2f", [Vector2i(9, 8), Vector2i(9, 9)],
			"passage_secret"],
	]
	for row: Array in cases:
		var banned: Array[Vector2i] = []
		banned.assign(row[2])
		var reached := _reachable(_map(row[0]), _cells(row[0], row[1]), banned)
		var target: Vector2i = _cells(row[0], row[3])[0]
		if row[3] == "passage_secret":
			target = Vector2i(17, 11)
		assert_false(reached.has(target), "%s : %s atteint sans passer devant le Dresseur" % [row[0],
			row[3]])
		var open := _reachable(_map(row[0]), _cells(row[0], row[1]))
		assert_true(open.has(target), "%s : %s atteignable" % [row[0], row[3]])


## Passe de peinture (`build_joh_ambiance_caves.gd`, `build_joh6_paint_shop.gd`) : plus d'aplat
## provisoire, sol peint ou enveloppe, portes à drapeau habillées sans changer leurs cases.
func test_interiors_are_painted() -> void:
	for id: StringName in [&"burned_tower_1f", &"burned_tower_b1f", &"mahogany_hideout_b1f",
			&"mahogany_hideout_b2f", &"mahogany_hideout_b3f"]:
		var map := _map(id)
		assert_not_null(map.get_node_or_null(^"PaintedGround"), "%s : sol peint" % id)
		assert_false(map.get_node(^"Ground").visible, "%s : tuiles masquées" % id)
		assert_true(_polygons(map).is_empty(), "%s : aplats provisoires restants" % id)
	var shop := _map(&"mahogany_souvenir_shop")
	assert_not_null(shop.get_node_or_null(^"JohAmbShopShell"), "enveloppe de la boutique")
	assert_true(_polygons(shop).is_empty(), "boutique : aplats provisoires restants")


func test_painted_gates_keep_their_logic() -> void:
	var art: Dictionary = {
		[&"mahogany_souvenir_shop", "Entities/EtagereCachee"]: "JohAmbShopArt",
		[&"mahogany_souvenir_shop", "Decor/EscalierVersB1f"]: "JohAmbShopArt",
		[&"mahogany_hideout_b2f", "Entities/PortePorteMdp"]: "JohAmbCaveDoor",
		[&"mahogany_hideout_b2f", "Entities/PortePorteCellule"]: "JohAmbCaveBars",
		[&"mahogany_hideout_b3f", "Entities/CageAOndes"]: "JohAmbCaveCageOn",
		[&"mahogany_hideout_b1f", "Decor/EscalierVersB2f"]: "JohAmbCaveStairs",
	}
	for key: Array in art:
		var gate := _map(key[0]).get_node_or_null(NodePath(key[1]))
		assert_not_null(gate, "%s / %s" % key)
		if gate == null:
			continue
		assert_not_null(gate.get_node_or_null(NodePath(art[key])), "%s / %s : image" % key)
	# Un drapeau change l'affichage, pas les cases : le rayon se cache avec johto_hideout_found,
	# l'escalier de la boutique n'apparaît qu'avec lui.
	var shop := _map(&"mahogany_souvenir_shop")
	var flags := StoryFlags.new()
	assert_true((shop.get_node(^"Entities/EtagereCachee") as FlagGate).is_open(flags))
	assert_false((shop.get_node(^"Decor/EscalierVersB1f") as FlagGate).is_open(flags))
	flags.set_flag(&"johto_hideout_found")
	assert_false((shop.get_node(^"Entities/EtagereCachee") as FlagGate).is_open(flags))
	assert_true((shop.get_node(^"Decor/EscalierVersB1f") as FlagGate).is_open(flags))


func test_tower_and_hideout_marks_are_images_without_footprint() -> void:
	var tower := _map(&"burned_tower_1f")
	assert_not_null(tower.get_node_or_null(^"JohAmbCaveSol"), "décor du sol")
	assert_gt(_names_with(tower.get_node(^"Entities"), "JohAmbCaveBeam"), 0, "poutres")
	var hideout := _map(&"mahogany_hideout_b1f")
	assert_eq(_names_with(hideout.get_node(^"Entities"), "JohAmbCavePersian"), 3, "statues")
	assert_eq(_names_with(_map(&"mahogany_hideout_b3f").get_node(^"Entities"),
		"JohAmbCaveGenerator"), 1)


func _names_with(parent: Node, prefix: String) -> int:
	var count := 0
	for child: Node in parent.get_children():
		if String(child.name).begins_with(prefix):
			count += 1
	return count


func _polygons(node: Node) -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in node.get_children():
		if child is Polygon2D and child.owner == node.owner:
			found.append(child)
		found.append_array(_polygons(child))
	return found
