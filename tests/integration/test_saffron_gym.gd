extends GutTest
## Arène de Morgane (jalon 27, T6 à T8 ; `docs/tech/jalon-27.md` §2.1, §2.2, §5) :
## - carte `saffron_gym` = grille `tools/plans/safrania_arene.txt` (cases bloquées, sortie,
##   arrivée) ; Dojo `fighting_dojo` = `safrania_dojo.txt` ;
## - les 30 tapis : chacun mène SUR le tapis d'en face (même carte → relocate), qui ramène au
##   départ ; aucune boucle sur place ; la salle de Morgane n'a qu'un tapis d'entrée ;
## - parcours joué dans une vraie Boot de l'entrée jusqu'à Morgane par le plus court chemin des
##   tapis (Dresseurs battus) ; arriver sur un tapis ne le déclenche pas ; retour possible ;
## - Morgane : défaite → pas de Badge, réveil, rejouable ; victoire → Badge Marais et CT46 une
##   fois ; Badge sans CT46 (Sac plein en RB) → CT46 à la visite suivante, une seule fois ;
## - Safrania : sbire devant l'Arène pendant l'occupation, porte libre après.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const START := "res://tools/debug_start/saffron_gym.json"
const SABRINA := "res://tools/debug_start/sabrina.json"
const SAVE_PATH := "user://test_saffron_gym.json"
const MAP := &"saffron_gym"
## Case d'où l'on parle à Morgane (9, 8) (repère « but » de la grille).
const GOAL := Vector2i(9, 9)
const MORGANE_ROOM := Rect2i(7, 7, 6, 5)
const TIMEOUT := 15.0
const FADE := 0.05
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _play: HideoutPlay
var _teleport_fade: float


func before_each() -> void:
	_teleport_fade = SceneRouter.teleport_fade_duration
	SceneRouter.teleport_fade_duration = FADE
	_play = HideoutPlay.new(self, SAVE_PATH)
	_play.setup()


func after_each() -> void:
	_play.teardown()
	SceneRouter.teleport_fade_duration = _teleport_fade


func _map(map_id: StringName) -> GameMap:
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func test_maps_match_their_grids() -> void:
	for entry: Array in [[MAP, "safrania_arene", &"from_gym"],
			[&"fighting_dojo", "safrania_dojo", &"from_dojo"]]:
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/%s.txt" % entry[1]), plan.error)
		var map := _map(entry[0])
		assert_eq(map.size, Vector2i(plan.width, plan.height), entry[0])
		assert_true(map.interior, "%s : intérieur" % entry[0])
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				assert_eq(map.blocked_cells.has(cell), not plan.is_walkable(cell),
					"%s %s" % [entry[0], cell])
		assert_true(map.has_spawn(&"entrance"), "%s : arrivée de Safrania" % entry[0])
		var exits := 0
		for warp: Warp in map.get_warps().get_all():
			if warp.target_map == &"saffron_city":
				exits += 1
				assert_eq(warp.target_spawn, entry[2], "%s : sortie" % entry[0])
		assert_eq(exits, 2, "%s : sortie sur deux cases (RB)" % entry[0])


func test_every_pad_leads_onto_the_facing_pad_and_back() -> void:
	var map := _map(MAP)
	var count := 0
	var into_room: Array[Vector2i] = []
	for warp: Warp in map.get_warps().get_all():
		if not warp.is_teleport():
			continue
		count += 1
		assert_eq(warp.target_map, MAP, "même carte (relocate)")
		var arrival := map.get_spawn_cell(warp.target_spawn)
		assert_ne(arrival, warp.cell, "%s : pas de boucle sur place" % warp.cell)
		var under := map.get_warps().get_at(arrival)
		assert_eq(under.size(), 1, "%s : arrivée sur un tapis" % warp.cell)
		if under.size() == 1:
			assert_eq(map.get_spawn_cell(under[0].target_spawn), warp.cell,
				"%s : le tapis d'en face ramène" % warp.cell)
		if MORGANE_ROOM.has_point(arrival) and not MORGANE_ROOM.has_point(warp.cell):
			into_room.append(warp.cell)
	assert_eq(count, 30, "15 paires de tapis (RB)")
	assert_eq(into_room, [Vector2i(1, 5)] as Array[Vector2i], "un seul tapis vers Morgane")


## De l'entrée à Morgane, à pied et par les tapis (plus court chemin), Dresseurs battus.
func test_route_from_the_entrance_to_sabrina_is_played() -> void:
	var hops := _route(_map(MAP))
	assert_eq(hops.size(), 5, "cinq tapis (plan_check_j27.py)")
	await _play.start(START, _beat_gym_trainers)
	assert_eq(_play.map_id(), MAP)
	var relocated: Array[GameMap] = []
	var on_relocated := func(m: GameMap) -> void: relocated.append(m)
	SceneRouter.relocated.connect(on_relocated)
	for hop: Array in hops:
		await _play.walk_to(hop[0])
		await wait_until(func() -> bool:
			return not SceneRouter.is_transitioning() and _play.boot.is_stable(), TIMEOUT)
		assert_eq(_play.player.get_cell(), hop[1], "tapis %s → %s" % [hop[0], hop[1]])
		await wait_process_frames(20)
		assert_eq(_play.player.get_cell(), hop[1], "arriver sur %s ne le déclenche pas" % hop[1])
	SceneRouter.relocated.disconnect(on_relocated)
	assert_eq(relocated.size(), hops.size(), "relocate, sans rechargement")
	await _play.walk_to(GOAL)
	assert_eq(_play.player.get_cell(), GOAL, "devant Morgane")
	# Retour : un pas de côté puis sur le tapis du centre → salle nord-ouest.
	await _play.walk_to(Vector2i(11, 11))
	await wait_until(func() -> bool:
		return not SceneRouter.is_transitioning() and _play.boot.is_stable(), TIMEOUT)
	assert_eq(_play.player.get_cell(), Vector2i(1, 5), "retour possible")
	assert_push_error_count(0)


func test_losing_to_sabrina_gives_nothing_and_can_be_replayed() -> void:
	await _play.start(SABRINA)
	_play.make_weak()
	await _play.walk_to(GOAL)
	assert_true(await _play.interact(Vector2i.UP), "combat contre Morgane")
	assert_false(GameState.flags.has_flag(&"badge_marsh"), "pas de Badge")
	assert_eq(GameState.bag.count_of(&"tm46"), 0)
	assert_true(GameState.flags.has_flag(&"sabrina_met"))
	assert_true(_play.events.has("card:MORGANE/Championne d'Arène de Safrania"), "carte")
	assert_true(_play.pages().has("C'était écrit."))


func test_beating_sabrina_gives_the_marsh_badge_and_tm46_once() -> void:
	await _play.start(SABRINA)
	_play.make_strong()
	await _play.walk_to(GOAL)
	assert_true(await _play.interact(Vector2i.UP), "combat contre Morgane")
	assert_true(GameState.flags.has_flag(&"badge_marsh"), "Badge Marais")
	assert_true(GameState.flags.has_flag(&"tm46_received"))
	assert_eq(GameState.bag.count_of(&"tm46"), 1, "CT46")
	assert_true(_play.pages().has("Kevin reçoit le Badge Marais !"), "T27-04 et badge")
	_play.events.clear()
	assert_false(await _play.interact(Vector2i.UP), "pas de revanche (Q27-4)")
	assert_eq(_play.pages(), ["L'avenir n'est pas écrit. Tu viens de me le rappeler."] \
		as Array[String], "T27-06")
	assert_eq(GameState.bag.count_of(&"tm46"), 1, "une seule CT46")
	assert_push_error_count(0)


func test_badge_without_tm46_gives_it_on_the_next_visit() -> void:
	await _play.start(SABRINA, func() -> void:
		GameState.flags.set_flag(&"sabrina_met")
		GameState.flags.set_flag(&"badge_marsh"))
	await _play.walk_to(GOAL)
	assert_false(await _play.interact(Vector2i.UP), "aucun combat")
	assert_eq(GameState.bag.count_of(&"tm46"), 1, "CT46 rattrapée")
	assert_true(GameState.flags.has_flag(&"tm46_received"))
	_play.events.clear()
	await _play.interact(Vector2i.UP)
	assert_eq(GameState.bag.count_of(&"tm46"), 1, "une seule fois")
	assert_push_error_count(0)


func test_the_rocket_guards_the_gym_until_giovanni_is_beaten() -> void:
	var roster := NpcRoster.new()
	assert_true(roster.load_file(NpcRoster.DATA_DIR + "saffron_city.json"),
		"\n".join(roster.get_errors()))
	var guard := roster.get_spec(&"garde_arene")
	assert_not_null(guard, "sbire de l'Arène (J26)")
	if guard != null:
		assert_eq(guard.cell, Vector2i(50, 10), "devant la porte de l'Arène")
		assert_eq(guard.unless_flags, [&"silph_giovanni_defeated"] as Array[StringName])
		assert_true(guard.if_flags.is_empty(), "aucune autre condition")


# --- Outils ---------------------------------------------------------------------------------

func _beat_gym_trainers() -> void:
	var plan := PlanGrid.new()
	plan.load_file("res://tools/plans/safrania_arene.txt")
	for id: String in plan.positions:
		if plan.positions[id]["kind"] == "dresseur":
			GameState.flags.set_flag(StringName("beaten_%s" % plan.attr(id, "trainer")))


## Plus court chemin (en tapis) de l'entrée à [constant GOAL] : [case du tapis, case d'arrivée].
func _route(map: GameMap) -> Array[Array]:
	var start := map.get_spawn_cell(&"entrance")
	var parents: Dictionary = {start: null}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var origin: Vector2i = queue.pop_front()
		var flood := _flood(map, origin)
		if flood["cells"].has(GOAL):
			var hops: Array[Array] = []
			var cursor: Vector2i = origin
			while parents[cursor] != null:
				var link: Array = parents[cursor]
				hops.push_front([link[1], cursor])
				cursor = link[0]
			return hops
		for warp: Warp in flood["warps"]:
			var arrival := map.get_spawn_cell(warp.target_spawn)
			if not parents.has(arrival):
				parents[arrival] = [origin, warp.cell]
				queue.append(arrival)
	return [] as Array[Array]


## Cases atteintes à pied depuis [param origin] (sans entrer sur un tapis) et tapis bordés.
func _flood(map: GameMap, origin: Vector2i) -> Dictionary:
	var grid := map.get_grid()
	var seen: Dictionary = {origin: true}
	var warps: Array[Warp] = []
	var queue: Array[Vector2i] = [origin]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for direction: Vector2i in DIRECTIONS:
			var next := cell + direction
			if seen.has(next) or grid.is_solid(next):
				continue
			seen[next] = true
			var here := map.get_warps().get_at(next)
			if not here.is_empty() and here[0].is_teleport():
				warps.append(here[0])
				continue
			if not here.is_empty():
				continue
			queue.append(next)
	return {"cells": seen, "warps": warps}
