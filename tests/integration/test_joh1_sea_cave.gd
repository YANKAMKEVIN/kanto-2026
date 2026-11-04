extends GutTest
## La grotte marine et la bouche de Bourg Palette (jalon JOH1, `jalon-joh1.md` §2.1 à §2.3) sur
## les vraies scènes : grille de la scène = grille du plan, eau surfable, courant permanent de la
## salle 1, [CurrentGate] du chenal de la salle 2 (actif tant que `johto_team_returned` est bas,
## calme ensuite), passages et arrivées des deux côtés de chaque raccord, déclencheurs (ombre de
## Lugia, courant du retour), ombre de Lugia (porte de drapeaux animée par la scène), objets,
## rencontres d'eau, zone, lumière ; Bourg Palette : mer surfable, bouche gardée par la lettre.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const WALKABLE: String = ".gwd>vE"
const WATER: String = "wd>v"
const PLANS: Dictionary = {&"sea_cave_1": "res://tools/plans/grotte_marine_1.txt",
	&"sea_cave_2": "res://tools/plans/grotte_marine_2.txt"}
const MOUTH: Array[Vector2i] = [Vector2i(22, 33), Vector2i(23, 33), Vector2i(24, 33),
	Vector2i(25, 33)]

var _maps: Dictionary = {}
var _plans: Dictionary = {}
var _pallet: GameMap
var _olivine: GameMap


func before_all() -> void:
	for map_id: StringName in PLANS:
		var plan := PlanGrid.new()
		assert_true(plan.load_file(PLANS[map_id]), plan.error)
		_plans[map_id] = plan
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[map_id] = map
	_pallet = (load(MapCatalog.scene_path(&"pallet_town")) as PackedScene).instantiate() as GameMap
	add_child(_pallet)
	_olivine = (load(MapCatalog.scene_path(&"olivine_city")) as PackedScene).instantiate() as GameMap
	add_child(_olivine)


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()
	_pallet.free()
	_olivine.free()


func _warp_at(map: GameMap, cell: Vector2i) -> Warp:
	var warps := map.get_warps().get_at(cell)
	return warps[0] if not warps.is_empty() else null


func _flags(raised: Array[StringName]) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in raised:
		flags.set_flag(flag)
	return flags


## Cases atteignables à pied et en Surf depuis [param from] sur la grille de [param map], un
## courant ne laissant passer que dans son sens (même règle que `plan_check_joh1.py`).
func _reachable(map: GameMap, from: Array[Vector2i]) -> Dictionary:
	var grid := map.get_grid()
	var seen: Dictionary = {}
	var queue: Array[Vector2i] = []
	for cell: Vector2i in from:
		seen[cell] = true
		queue.append(cell)
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		var current := grid.get_current(cell)
		var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		if current != Vector2i.ZERO:
			directions = [current]
		for direction: Vector2i in directions:
			var next := cell + direction
			if not grid.is_in_bounds(next) or grid.is_solid(next) or seen.has(next):
				continue
			seen[next] = true
			queue.append(next)
	return seen


func test_metadata_and_light() -> void:
	for map_id: StringName in PLANS:
		var map: GameMap = _maps[map_id]
		assert_eq(map.map_id, map_id)
		assert_eq(map.display_name, "Grotte marine")
		assert_eq(map.size, Vector2i(30, 40))
		assert_false(map.interior)
		assert_true(map.no_fly, "pas de Vol depuis la grotte [D]")
		assert_eq(map.light_profile, &"sea_cave")
	var lights := LightingLibrary.new()
	assert_true(lights.load_file())
	assert_not_null(lights.get_profile(&"sea_cave"), "profil sea_cave")
	assert_eq(lights.get_map_profile(&"sea_cave_1"), &"sea_cave")
	assert_eq(lights.get_map_profile(&"sea_cave_2"), &"sea_cave")


func test_scene_grid_matches_the_plan() -> void:
	for map_id: StringName in PLANS:
		var map: GameMap = _maps[map_id]
		var plan: PlanGrid = _plans[map_id]
		var grid := map.get_grid()
		var wrong: Array[String] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				var c := plan.at(cell)
				var solid := not WALKABLE.contains(c)
				if grid.is_solid(cell) != solid:
					wrong.append("%s solide=%s" % [cell, grid.is_solid(cell)])
				var water := WATER.contains(c)
				if grid.is_water(cell) != water or grid.is_surfable(cell) != water:
					wrong.append("%s eau=%s" % [cell, water])
		assert_eq(wrong, [] as Array[String], String(map_id))


func test_room_1_current_is_permanent_and_room_2_channel_follows_the_act() -> void:
	var one: GameMap = _maps[&"sea_cave_1"]
	for cell: Vector2i in (_plans[&"sea_cave_1"] as PlanGrid).cells_of(">"):
		assert_eq(one.get_grid().get_current(cell), Vector2i.RIGHT, str(cell))
	var two: GameMap = _maps[&"sea_cave_2"]
	var gate := two.get_node(^"Entities/CourantChenal") as CurrentGate
	assert_not_null(gate, "porte de courant du chenal")
	var channel: Array[Vector2i] = (_plans[&"sea_cave_2"] as PlanGrid).cells_of("v")
	assert_eq(channel.size(), 15, "6..8 × 30..34")
	assert_eq(gate.cells.keys().size(), channel.size())
	assert_eq(gate.unless_flags, [&"johto_team_returned"] as Array[StringName])
	assert_eq(two.current_cells.size(), 0, "aucun courant permanent en salle 2")
	# Acte 1 : actif vers le sud.
	two.apply_flag_gates(_flags([]))
	for cell: Vector2i in channel:
		assert_eq(two.get_grid().get_current(cell), Vector2i.DOWN, str(cell))
	assert_eq(gate.active_cells().size(), channel.size())
	# Acte 2 : calme.
	two.apply_flag_gates(_flags([&"johto_team_returned"]))
	for cell: Vector2i in channel:
		assert_eq(two.get_grid().get_current(cell), Vector2i.ZERO, str(cell))
	assert_eq(gate.active_cells().size(), 0)
	two.apply_flag_gates(_flags([]))


func test_act_1_goes_one_way_and_act_2_both_ways() -> void:
	var one: GameMap = _maps[&"sea_cave_1"]
	var from_pallet := _reachable(one, [Vector2i(12, 0)])
	assert_true(from_pallet.has(Vector2i(20, 39)), "salle 1 : sortie sud atteinte")
	assert_true(from_pallet.has(Vector2i(7, 10)), "salle 1 : îlot de la Perle atteint")
	var two: GameMap = _maps[&"sea_cave_2"]
	two.apply_flag_gates(_flags([]))
	var from_north := _reachable(two, [Vector2i(20, 0)])
	assert_true(from_north.has(Vector2i(3, 39)), "acte 1 : la plage est atteinte")
	assert_true(from_north.has(Vector2i(23, 24)), "acte 1 : le Rappel Max est atteint")
	assert_true(from_north.has(Vector2i(9, 17)), "acte 1 : la rangée de l'ombre")
	var back := _reachable(two, [Vector2i(3, 38)])
	assert_false(back.has(Vector2i(20, 0)), "acte 1 : impossible de remonter")
	two.apply_flag_gates(_flags([&"johto_team_returned"]))
	var back_2 := _reachable(two, [Vector2i(3, 38)])
	assert_true(back_2.has(Vector2i(20, 0)), "acte 2 : la grotte se traverse dans les deux sens")
	two.apply_flag_gates(_flags([]))


func test_warps_and_spawns_match_on_both_sides() -> void:
	var one: GameMap = _maps[&"sea_cave_1"]
	var two: GameMap = _maps[&"sea_cave_2"]
	# Bourg Palette ↔ salle 1.
	for i: int in 4:
		var warp := _warp_at(_pallet, MOUTH[i])
		assert_not_null(warp, "bouche %d" % i)
		assert_eq(warp.trigger, Warp.Trigger.PUSH)
		assert_eq(warp.direction, Vector2i.DOWN)
		assert_eq(warp.target_map, &"sea_cave_1")
		var spawn := StringName("from_pallet_town" if i == 0 else "from_pallet_town_%d" % i)
		assert_eq(warp.target_spawn, spawn)
		assert_eq(warp.if_flags, [&"johto_letter_read"] as Array[StringName], "fermée avant la lettre")
		assert_true(one.has_spawn(spawn), String(spawn))
		assert_eq(one.get_spawn_cell(spawn), Vector2i(12 + i, 0))
		var back := _warp_at(one, Vector2i(12 + i, 0))
		assert_not_null(back)
		assert_eq(back.trigger, Warp.Trigger.PUSH)
		assert_eq(back.direction, Vector2i.UP)
		assert_eq(back.target_map, &"pallet_town")
		var pallet_spawn := StringName("from_sea_cave" if i == 0 else "from_sea_cave_%d" % i)
		assert_eq(back.target_spawn, pallet_spawn)
		assert_true(_pallet.has_spawn(pallet_spawn), String(pallet_spawn))
		assert_eq(_pallet.get_spawn_cell(pallet_spawn), MOUTH[i])
		assert_true(_pallet.forced_surf_cells.has(MOUTH[i]), "arrivée en Surf")
	# Salle 1 ↔ salle 2.
	for i: int in 2:
		var down := _warp_at(one, Vector2i(20 + i, 39))
		assert_eq(down.target_map, &"sea_cave_2")
		assert_eq(down.trigger, Warp.Trigger.PUSH)
		var spawn := StringName("from_sea_cave_1" if i == 0 else "from_sea_cave_1_%d" % i)
		assert_eq(down.target_spawn, spawn)
		assert_eq(two.get_spawn_cell(spawn), Vector2i(20 + i, 0))
		var up := _warp_at(two, Vector2i(20 + i, 0))
		assert_eq(up.target_map, &"sea_cave_1")
		var spawn_up := StringName("from_sea_cave_2" if i == 0 else "from_sea_cave_2_%d" % i)
		assert_eq(up.target_spawn, spawn_up)
		assert_eq(one.get_spawn_cell(spawn_up), Vector2i(20 + i, 39))
	assert_true(two.forced_surf_cells.has(Vector2i(20, 0)))
	assert_true(one.forced_surf_cells.has(Vector2i(21, 39)))
	# Salle 2 ↔ Oliville.
	for i: int in 2:
		var exit := _warp_at(two, Vector2i(3 + i, 39))
		assert_eq(exit.trigger, Warp.Trigger.STEP_ON)
		assert_eq(exit.direction, Vector2i.DOWN)
		assert_eq(exit.target_map, &"olivine_city")
		var spawn := StringName("from_sea_cave" if i == 0 else "from_sea_cave_%d" % i)
		assert_eq(exit.target_spawn, spawn)
		assert_eq(exit.facing, Vector2i.RIGHT)
		assert_eq(_olivine.get_spawn_cell(spawn), Vector2i(11, 31 + i))
		var back := _warp_at(_olivine, Vector2i(10, 31 + i))
		assert_not_null(back, "bouche de la grotte côté Oliville")
		assert_eq(back.target_map, &"sea_cave_2")
		var spawn_back := StringName("from_olivine_city" if i == 0 else "from_olivine_city_%d" % i)
		assert_eq(back.target_spawn, spawn_back)
		assert_eq(two.get_spawn_cell(spawn_back), Vector2i(3 + i, 38))
	assert_true(two.has_spawn(&"lugia_front"), "arrivée de débogage")


func test_triggers_and_the_shadow_of_lugia() -> void:
	var two: GameMap = _maps[&"sea_cave_2"]
	for x: int in range(9, 21):
		var trigger := two.get_triggers().find_on_step(Vector2i(x, 17), Vector2i.DOWN)
		assert_not_null(trigger, "ombre en (%d, 17)" % x)
		assert_eq(trigger.cutscene_id, &"sea_cave_lugia_shadow")
	for x: int in range(6, 9):
		var up := two.get_triggers().find_on_step(Vector2i(x, 35), Vector2i.UP)
		assert_not_null(up, "retour en (%d, 35)" % x)
		assert_eq(up.cutscene_id, &"sea_cave_current_back")
		assert_null(two.get_triggers().find_on_step(Vector2i(x, 35), Vector2i.DOWN),
			"seulement en montant")
	var shadow := two.get_node(^"LugiaShadow") as FlagGate
	assert_not_null(shadow)
	assert_eq(shadow.if_flags, [&"johto_lugia_passing"] as Array[StringName])
	shadow.apply(_flags([]))
	assert_false(shadow.visible, "cachée tant que la scène ne la montre pas")
	shadow.apply(_flags([&"johto_lugia_passing"]))
	assert_true(shadow.visible)
	assert_true(shadow.get_index() < two.get_node(^"Entities").get_index(), "sous le joueur")
	assert_not_null((shadow.get_node(^"Ombre") as Sprite2D).texture)
	assert_eq(Grid.world_to_cell(shadow.position), Vector2i(9, 17))


func test_items_encounters_and_zone() -> void:
	var roster_1 := NpcRoster.load_for_map(&"sea_cave_1")
	assert_eq(roster_1.get_all().size(), 1)
	assert_eq(roster_1.get_all()[0].cell, Vector2i(7, 10), "Perle sur l'îlot")
	var roster_2 := NpcRoster.load_for_map(&"sea_cave_2")
	assert_eq(roster_2.get_all().size(), 1)
	assert_eq(roster_2.get_all()[0].cell, Vector2i(23, 24), "Rappel Max sur l'îlot")
	var items := ItemLibrary.new()
	items.load_dir()
	assert_true(items.has_item(&"pearl"), "la Perle existe")
	assert_true(items.has_item(&"max_repel"))
	var data := PokemonData.new()
	data.load_dir()
	var encounters := EncounterLibrary.new(data)
	assert_true(encounters.load_dir())
	for map_id: StringName in PLANS:
		var table := encounters.get_table(map_id, &"water")
		assert_not_null(table, "%s : table d'eau" % map_id)
		assert_null(encounters.get_table(map_id, &"grass"), "%s : pas d'herbes" % map_id)
		var species: Array[StringName] = []
		for slot: Variant in table.slots:
			species.append(slot.species)
		assert_eq(species, [&"tentacool", &"shellder", &"staryu"] as Array[StringName])
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	var zone := zones.get_zone(&"sea_cave")
	assert_not_null(zone)
	assert_eq(zone.name, "Grotte marine")
	assert_eq(zone.region, &"johto")
	assert_eq(zone.description, "Un passage sous la mer, entre Kanto et Johto.")
	assert_eq(zones.zone_of(&"sea_cave_1"), &"sea_cave")
	assert_eq(zones.zone_of(&"sea_cave_2"), &"sea_cave")


func test_pallet_town_sea_is_surfable_and_the_mouth_is_gated() -> void:
	var grid := _pallet.get_grid()
	for cell: Vector2i in MOUTH:
		assert_true(grid.is_surfable(cell), str(cell))
	assert_true(grid.is_surfable(Vector2i(5, 32)), "plage : départ du Surf")
	assert_false(grid.is_surfable(Vector2i(9, 32)), "le ponton n'est pas de l'eau")
	var examine := _pallet.get_interactions().get_at(MOUTH[0])
	assert_eq(examine.size(), 1, "point d'examen de la bouche")
	assert_eq(examine[0].dialogue_id, &"pallet_cave_mouth")
	assert_eq(examine[0].if_flags, [&"johto_letter_read"] as Array[StringName])
	var open := _pallet.get_node(^"Entities/Joh1GrotteOuverte") as FlagGate
	var closed := _pallet.get_node(^"Entities/Joh1GrotteFermee") as FlagGate
	assert_false(open.is_open(_flags([])))
	assert_true(closed.is_open(_flags([])))
	assert_true(open.is_open(_flags([&"johto_letter_read"])))
	assert_false(closed.is_open(_flags([&"johto_letter_read"])))
