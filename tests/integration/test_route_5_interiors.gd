extends GutTest
## Intérieurs de la Route 5 (jalon 15 T13, docs/tech/jalon-15.md §2.2, §2.4 ; dossier 18 §4.1,
## §7) sur les vraies scènes : Pension (gardien `old_man` derrière le comptoir, parlé par-dessus,
## dialogue `daycare_keeper`), poste nord (garde devant l'ouverture, déclencheur du recul,
## Safrania atteinte seulement une fois le garde écarté, J26 T6), bâtiment d'entrée du souterrain (escalier `STEP_ON` sans
## direction vers `underground_path` / `from_route_5_w|e` ; panneau T-14). Catégorie : intérieurs (`interiors.json`), titre « Route 5 » (zone).

const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const ROOMS: Array[StringName] = [&"route_5_daycare", &"route_5_gate",
	&"route_5_underground_gate"]

var _maps: Dictionary = {}


func before_all() -> void:
	for id: StringName in ROOMS:
		var map := (load(MapCatalog.scene_path(id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[id] = map


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()


func _npc(map: GameMap, id: StringName) -> Npc:
	for npc: Npc in map.get_npcs():
		if npc.get_id() == id:
			return npc
	return null


func test_rooms_are_interiors_of_the_route_5_zone() -> void:
	var interiors := MapCatalog.load_interiors()
	var zones := ZoneLibrary.new()
	zones.load_file()
	for id: StringName in ROOMS:
		var map: GameMap = _maps[id]
		assert_true(map.interior, "%s : intérieur" % id)
		assert_true(interiors.has(id), "%s dans interiors.json" % id)
		assert_eq(map.display_name, "Route 5")
		assert_eq(map.light_profile, &"interior_warm")
		assert_eq(zones.zone_of(id), &"route_5")


func test_daycare_keeper_stands_behind_the_counter() -> void:
	var map: GameMap = _maps[&"route_5_daycare"]
	var keeper := _npc(map, &"keeper")
	assert_not_null(keeper, "gardien")
	if keeper != null:
		assert_eq(keeper.get_cell(), Vector2i(7, 3))
		assert_eq(keeper.get_spec().sprite, &"old_man", "décision de Kevin (2026-10-14)")
		assert_eq(keeper.get_spec().dialogue, &"daycare_keeper")
	var grid := map.get_grid()
	for cell: Vector2i in [Vector2i(6, 3), Vector2i(8, 3), Vector2i(6, 4), Vector2i(7, 4),
			Vector2i(8, 4)]:
		assert_true(grid.is_solid(cell), "comptoir et ses côtés fermés (%s)" % cell)
	var talk := map.get_interactions().find(Vector2i(7, 4), Vector2i.UP)
	assert_not_null(talk, "on parle au gardien par-dessus le comptoir")
	if talk != null:
		assert_eq(talk.dialogue_id, &"daycare_keeper")
	var reach := GridPaths.distances(grid, [map.get_spawn_cell(&"entrance")])
	assert_true(reach.has(Vector2i(7, 5)), "devant le comptoir depuis le paillasson")
	for warp: Warp in map.get_warps().get_all():
		assert_eq([warp.target_map, warp.target_spawn], [&"route_5", &"from_daycare"])


func test_gate_guard_blocks_the_north_opening() -> void:
	var map: GameMap = _maps[&"route_5_gate"]
	var guard := _npc(map, &"route_5_guard")
	assert_not_null(guard)
	if guard != null:
		assert_eq(guard.get_cell(), Vector2i(4, 2))
		assert_eq(guard.get_spec().sprite, &"guard")
	assert_true(map.get_grid().is_solid(Vector2i(5, 2)), "meuble bas devant (5, 2)")
	var reach := GridPaths.distances(map.get_grid(), [map.get_spawn_cell(&"from_route_5")])
	for cell: Vector2i in [Vector2i(4, 1), Vector2i(5, 1)]:
		assert_false(reach.has(cell), "ouverture nord %s inatteignable" % cell)
		var warp := map.get_warps().find_on_step(cell, Vector2i.UP)
		assert_not_null(warp)
		# Jalon 26 (T6) : Safrania existe, l'ouverture y mène (atteinte une fois le garde écarté).
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"saffron_city", &"from_gate_r5", Vector2i.DOWN])
	assert_eq(map.get_spawn_cell(&"from_saffron"), Vector2i(4, 2), "arrivée depuis la ville")
	for cell: Vector2i in [Vector2i(4, 3), Vector2i(5, 3)]:
		var trigger := map.get_triggers().find_on_step(cell, Vector2i.UP)
		assert_not_null(trigger, "déclencheur en %s, pas vers le nord" % cell)
		if trigger != null:
			assert_eq(trigger.cutscene_id, &"route_5_gate_rule")
		assert_null(map.get_triggers().find_on_step(cell, Vector2i.RIGHT), "de côté : rien")


func test_underground_gate_stairs_and_sign() -> void:
	var map: GameMap = _maps[&"route_5_underground_gate"]
	for i: int in 2:
		var cell := Vector2i(4 + i, 2)
		var suffix: String = ["w", "e"][i]
		assert_false(map.get_grid().is_solid(cell), "escalier %s praticable" % cell)
		var warp := map.get_warps().find_on_step(cell, Vector2i.UP)
		assert_not_null(warp, "escalier STEP_ON en %s" % cell)
		if warp == null:
			continue
		assert_eq(warp.direction, Vector2i.ZERO, "sans direction (échelles du J12)")
		assert_false(warp.is_coming_soon(), "escalier %s raccordé" % cell)
		assert_eq([warp.target_map, warp.target_spawn], [&"underground_path",
			StringName("from_route_5_" + suffix)])
		assert_eq(map.get_spawn_cell(StringName("from_underground_" + suffix)),
			cell + Vector2i.DOWN, "arrivée du souterrain devant l'escalier")
	var sign := map.get_interactions().find(Vector2i(7, 1), Vector2i.UP)
	assert_not_null(sign, "panneau T-14 au mur")
	if sign != null:
		assert_eq(sign.dialogue_id, &"route_5_underground_sign")
