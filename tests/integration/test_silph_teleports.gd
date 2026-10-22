extends GutTest
## Téléporteurs de la Sylphe SARL et contrôle de bout en bout (jalon 26, T7 et T10 ;
## `docs/tech/jalon-26.md` §2.2, §5 ; `docs/tech/systemes-2.md` §2.9), sur les vraies scènes :
## - chaque téléporteur des 11 étages mène à son point d'apparition, posé SUR la dalle d'en face,
##   qui ramène au départ (paires RB, aucune boucle sur place) ;
## - même étage → `SceneRouter.relocate` (pas de rechargement), autre étage → `change_map` ;
##   arriver sur une dalle ne la déclenche pas ;
## - graphe des passages (escaliers et téléporteurs, sans l'ascenseur) : avec la Carte, tous les
##   étages et la salle de Giovanni (11F) sont atteints depuis l'entrée ; sans la Carte, la salle
##   de Giovanni ne l'est pas ;
## - **T10 : parcours 1F → 11F joué** dans une vraie Boot (vraies entrées, portes ouvertes, Carte
##   dans le Sac), étape par étape le long du plus court chemin du graphe.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const START := "res://tools/debug_start/silph_1f.json"
const SAVE_PATH := "user://test_silph_teleports.json"
const CAR := &"silph_co_elevator"
const ENTRY := &"silph_co_1f"
const TOP := &"silph_co_11f"
## Case de déclenchement de Giovanni (grille du 11F, repère « but »).
const GOAL := Vector2i(7, 12)
const FADE := 0.05
const TIMEOUT := 15.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _play: HideoutPlay
var _teleport_fade: float


static func floor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for n: int in range(1, 12):
		ids.append(StringName("silph_co_%df" % n))
	return ids


func before_each() -> void:
	_teleport_fade = SceneRouter.teleport_fade_duration
	SceneRouter.teleport_fade_duration = FADE
	_play = HideoutPlay.new(self, SAVE_PATH)
	_play.setup()


func after_each() -> void:
	_play.teardown()
	SceneRouter.teleport_fade_duration = _teleport_fade


# --- Scènes ----------------------------------------------------------------------------------

func _load_maps(open_doors: bool) -> Dictionary[StringName, GameMap]:
	var maps: Dictionary[StringName, GameMap] = {}
	var flags := StoryFlags.new()
	for map_id: StringName in floor_ids():
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
		add_child_autofree(map)
		if open_doors:
			for door: Node in map.find_children("*", "KeyDoor", true, false):
				flags.set_flag((door as KeyDoor).get_open_flag())
		map.apply_flag_gates(flags)
		maps[map_id] = map
	return maps


func test_every_teleporter_leads_onto_the_facing_tile_and_back() -> void:
	var maps := _load_maps(false)
	var count := 0
	var same_floor := 0
	for map_id: StringName in maps:
		for warp: Warp in maps[map_id].get_warps().get_all():
			if not warp.is_teleport():
				continue
			count += 1
			var label := "%s %s → %s:%s" % [map_id, warp.cell, warp.target_map, warp.target_spawn]
			assert_true(maps.has(warp.target_map), label)
			var target: GameMap = maps.get(warp.target_map)
			if target == null:
				continue
			assert_true(target.has_spawn(warp.target_spawn), label)
			var arrival := target.get_spawn_cell(warp.target_spawn)
			assert_false(target == maps[map_id] and arrival == warp.cell, "%s : boucle" % label)
			var under := target.get_warps().get_at(arrival)
			assert_eq(under.size(), 1, "%s : arrivée sur une dalle" % label)
			if under.size() != 1:
				continue
			assert_true(under[0].is_teleport(), label)
			assert_eq(under[0].target_map, map_id, "%s : la dalle d'en face ramène" % label)
			assert_eq(maps[map_id].get_spawn_cell(under[0].target_spawn), warp.cell,
				"%s : retour sur la dalle de départ" % label)
			if warp.target_map == map_id:
				same_floor += 1
	assert_eq(count, 34, "17 paires de téléporteurs (RB)")
	assert_gt(same_floor, 0, "des téléporteurs sur le même étage (relocate)")


func test_graph_reaches_every_floor_and_giovanni_with_the_card_only() -> void:
	var open := _route(_load_maps(true))
	assert_false(open.is_empty(), "avec la Carte : la salle de Giovanni est atteinte")
	var reached := _reached_floors(_load_maps(true))
	assert_eq(reached.size(), 11, "avec la Carte : tous les étages, sans l'ascenseur (%s)"
		% ", ".join(reached))
	assert_true(_route(_load_maps(false)).is_empty(),
		"sans la Carte : la salle de Giovanni est fermée")


# --- Boot ------------------------------------------------------------------------------------

func test_same_floor_teleporter_relocates_without_reloading() -> void:
	await _play.start(START)
	await SceneRouter.change_map(&"silph_co_8f", &"from_elevator", Vector2i.DOWN)
	await wait_until(func() -> bool: return _play.boot.is_stable(), TIMEOUT)
	var map := _play.boot.get_map()
	var pad: Warp = null
	for warp: Warp in _flood(map, _play.player.get_cell())["warps"]:
		if warp.is_teleport() and warp.target_map == map.map_id:
			pad = warp
			break
	assert_not_null(pad, "téléporteur du même étage au 8F, atteint depuis l'ascenseur")
	if pad == null:
		return
	var relocated: Array[GameMap] = []
	var on_relocated := func(m: GameMap) -> void: relocated.append(m)
	SceneRouter.relocated.connect(on_relocated)
	await _play.walk_to(pad.cell)
	await wait_until(func() -> bool:
		return not SceneRouter.is_transitioning() and _play.boot.is_stable(), TIMEOUT)
	SceneRouter.relocated.disconnect(on_relocated)
	assert_eq(_play.boot.get_map(), map, "même carte, pas de rechargement")
	assert_eq(relocated.size(), 1, "relocate")
	var arrival := map.get_spawn_cell(pad.target_spawn)
	assert_eq(_play.player.get_cell(), arrival, "sur la dalle d'en face")
	await wait_process_frames(30)
	assert_eq(_play.player.get_cell(), arrival, "arriver sur la dalle ne la déclenche pas")
	assert_false(SceneRouter.is_transitioning())
	assert_true(_play.player.is_input_enabled())
	assert_push_error_count(0)


func test_other_floor_teleporter_changes_map_and_the_arrival_tile_stays_quiet() -> void:
	await _play.start(START)
	await SceneRouter.change_map(&"silph_co_5f", &"from_elevator", Vector2i.DOWN)
	await wait_until(func() -> bool: return _play.boot.is_stable(), TIMEOUT)
	var pad := _play.boot.get_map().get_warps().get_at(Vector2i(27, 3))
	assert_eq(pad.size(), 1)
	assert_eq([pad[0].target_map, pad[0].target_spawn], [&"silph_co_7f", &"tp_6"])
	await _play.walk_to(Vector2i(27, 3))
	assert_eq(_play.map_id(), &"silph_co_7f")
	assert_eq(_play.player.get_cell(), Vector2i(21, 15))
	await wait_process_frames(30)
	assert_eq(_play.map_id(), &"silph_co_7f", "arriver sur la dalle ne la déclenche pas")
	assert_eq(_play.player.get_cell(), Vector2i(21, 15))
	# Un pas de côté puis de nouveau sur la dalle : retour au 5F, sur la dalle de départ.
	var side := _free_neighbour(_play.boot.get_map(), Vector2i(21, 15))
	await _play.step(side)
	await _play.step(-side)
	assert_eq(_play.map_id(), &"silph_co_5f")
	assert_eq(_play.player.get_cell(), Vector2i(27, 3))
	assert_push_error_count(0)


## T10 : de l'entrée du 1F à la salle de Giovanni (11F), à pied, par les escaliers et les
## téléporteurs (sans l'ascenseur), portes ouvertes et Carte dans le Sac. Les Dresseurs des
## grilles sont marqués battus (le T9 les pose ; le rival et Giovanni ont leurs propres tests).
func test_route_from_the_entrance_to_giovanni_is_played() -> void:
	var hops := _route(_load_maps(true))
	assert_false(hops.is_empty(), "un chemin existe")
	if hops.is_empty():
		return
	await _play_route(hops)
	assert_eq(_play.map_id(), TOP)
	await _play.walk_to(GOAL)
	assert_eq(_play.player.get_cell(), GOAL, "salle de Giovanni atteinte")
	assert_push_error_count(0)


## T10 : les onze étages un à un, par les seuls escaliers, de l'entrée au 11F.
func test_climb_by_the_stairs_floor_by_floor_is_played() -> void:
	var hops := _route(_load_maps(true), true)
	assert_eq(hops.size(), 10, "dix escaliers du 1F au 11F")
	if hops.is_empty():
		return
	await _play_route(hops)
	assert_eq(_play.map_id(), TOP, "11F atteint par les escaliers")
	assert_push_error_count(0)


## Joue [param hops] depuis l'entrée du 1F (Carte dans le Sac, portes ouvertes, Dresseurs des
## grilles battus) ; s'arrête au premier écart.
func _play_route(hops: Array[Dictionary]) -> void:
	await _play.start(START, func() -> void:
		GameState.bag.add(&"card_key")
		for map_id: StringName in floor_ids():
			var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate()
			for door: Node in map.find_children("*", "KeyDoor", true, false):
				GameState.flags.set_flag((door as KeyDoor).get_open_flag())
			map.free()
		for trainer: StringName in _grid_trainers():
			GameState.flags.set_flag(StringName("beaten_%s" % trainer)))
	assert_eq(_play.map_id(), ENTRY)
	var floors_seen: Array[StringName] = [ENTRY]
	for hop: Dictionary in hops:
		assert_eq(_play.map_id(), hop["map"], "étape %s" % hop)
		if _play.map_id() != hop["map"]:
			return
		await _play.walk_to(hop["cell"])
		assert_eq(_play.map_id(), hop["to_map"], "passage %s" % hop)
		assert_eq(_play.player.get_cell(), hop["to_cell"], "arrivée %s" % hop)
		if _play.map_id() != hop["to_map"] or _play.player.get_cell() != hop["to_cell"]:
			return
		if not floors_seen.has(_play.map_id()):
			floors_seen.append(_play.map_id())
	gut.p("parcours joué : %d passages, étages %s" % [hops.size(), ", ".join(floors_seen)])


# --- Graphe ----------------------------------------------------------------------------------

## Plus court chemin (en passages) de l'entrée du 1F à [constant GOAL] du 11F : liste d'étapes
## { map, cell (case du passage), to_map, to_cell } ; vide si inatteignable. L'ascenseur et la
## sortie vers Safrania sont écartés.
## [param stairs_only] : sans téléporteur, le but est la seule arrivée au 11F.
func _route(maps: Dictionary[StringName, GameMap], stairs_only: bool = false) -> Array[Dictionary]:
	var start := [ENTRY, maps[ENTRY].get_spawn_cell(&"from_city")]
	var parents: Dictionary = {start: null}
	var queue: Array = [start]
	while not queue.is_empty():
		var node: Array = queue.pop_front()
		var map: GameMap = maps[node[0]]
		var flood := _flood(map, node[1])
		if node[0] == TOP and (stairs_only or flood["cells"].has(GOAL)):
			var hops: Array[Dictionary] = []
			var cursor: Variant = node
			while parents[cursor] != null:
				var link: Array = parents[cursor]
				hops.push_front({"map": link[0][0], "cell": link[1], "to_map": cursor[0],
					"to_cell": cursor[1]})
				cursor = link[0]
			return hops
		for warp: Warp in flood["warps"]:
			var target: GameMap = maps.get(warp.target_map)
			if target == null or (stairs_only and warp.is_teleport()):
				continue
			var next := [warp.target_map, target.get_spawn_cell(warp.target_spawn)]
			if parents.has(next):
				continue
			parents[next] = [node, warp.cell]
			queue.append(next)
	return [] as Array[Dictionary]


func _reached_floors(maps: Dictionary[StringName, GameMap]) -> Array[StringName]:
	var start := [ENTRY, maps[ENTRY].get_spawn_cell(&"from_city")]
	var seen: Dictionary = {start: true}
	var queue: Array = [start]
	var floors: Array[StringName] = []
	while not queue.is_empty():
		var node: Array = queue.pop_front()
		if not floors.has(node[0]):
			floors.append(node[0])
		for warp: Warp in _flood(maps[node[0]], node[1])["warps"]:
			var target: GameMap = maps.get(warp.target_map)
			if target == null:
				continue
			var next := [warp.target_map, target.get_spawn_cell(warp.target_spawn)]
			if not seen.has(next):
				seen[next] = true
				queue.append(next)
	return floors


## Cases atteintes à pied depuis [param from] sans emprunter de passage, et passages STEP_ON
## (hors ascenseur) dans lesquels on peut entrer : { cells: Dictionary, warps: Array[Warp] }.
func _flood(map: GameMap, from: Vector2i) -> Dictionary:
	var grid := map.get_grid()
	var cells: Dictionary = {from: true}
	var warps: Array[Warp] = []
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for direction: Vector2i in DIRECTIONS:
			var next := cell + direction
			if cells.has(next) or not grid.is_in_bounds(next) or grid.is_solid(next) \
					or grid.is_occupied(next):
				continue
			var on_step := map.get_warps().find_on_step(next, direction)
			if on_step != null:
				cells[next] = true
				if on_step.target_map != CAR and not warps.has(on_step):
					warps.append(on_step)
				continue
			cells[next] = true
			queue.append(next)
	return {"cells": cells, "warps": warps}


func _free_neighbour(map: GameMap, cell: Vector2i) -> Vector2i:
	for direction: Vector2i in DIRECTIONS:
		var next := cell + direction
		if map.get_grid().is_in_bounds(next) and not map.get_grid().is_solid(next) \
				and not map.get_grid().is_occupied(next) and map.get_warps().get_at(next).is_empty():
			return direction
	return Vector2i.ZERO


## Identifiants `trainer=` des grilles des 11 étages (rival et Giovanni compris).
static func _grid_trainers() -> Array[StringName]:
	var ids: Array[StringName] = []
	for n: int in range(1, 12):
		var plan := PlanGrid.new()
		plan.load_file("res://tools/plans/sylphe_%df.txt" % n)
		for id: String in plan.positions:
			var trainer := plan.attr(id, "trainer")
			if not trainer.is_empty():
				ids.append(StringName(trainer))
	return ids
