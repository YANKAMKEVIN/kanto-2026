extends RefCounted
## Banc de Force (passe systèmes 2, S2D) sans Boot : routeur frais (jamais l'autoload), joueur,
## rideau, [StrengthDirector] et mini-cartes en code, câblés comme dans [Boot] (Force retombe à
## chaque carte ; les [FlagGate] suivent chaque drapeau posé ; le routeur lit les drapeaux).
##
## Carte « s » (12 × 8) :
## - départ (2, 4) tourné à droite ; rocher A (3, 4) ; trou n° 1 (6, 4), drapeau
##   [constant HOLE_FLAG], chute (Warp FALL) vers « d » / `chute_joueur` sauf ce drapeau ;
##   dessins « trou ouvert » / « trou bouché » ([FlagGate] visuels) ;
## - rocher B (9, 6) cerné : mur (10, 6), eau (9, 7), rocher C (9, 5), case interdite (8, 6) ;
## - rocher D (2, 6), interrupteur (3, 6) [constant SWITCH_FLAG], barrière (5, 6) (FlagGate
##   `blocking_cells`, sauf ce drapeau) ;
## - porte (10, 1) vers « d » / `chute_joueur`, sauf [constant DOOR_FLAG] (`unless_flags` d'un
##   passage ordinaire).
## Carte « d » (6 × 5) : `chute_joueur` (2, 2) ; rocher tombé du trou n° 1 en (2, 1) ([FlagGate]
## bloquant **si** [constant HOLE_FLAG] : il n'apparaît qu'une fois le trou bouché ; ancien étage
## `qa_strength_b1` de la carte de QA retirée en S2Z).

const ROUTER_SCRIPT := preload("res://game/autoload/scene_router.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const FADE_SCENE := preload("res://game/ui/components/screen_fade.tscn")
const FADE_TIME := 0.05

const START := Vector2i(2, 4)
const A := Vector2i(3, 4)
const HOLE := Vector2i(6, 4)
const B := Vector2i(9, 6)
const C := Vector2i(9, 5)
const WALL := Vector2i(10, 6)
const WATER := Vector2i(9, 7)
const NO_PUSH := Vector2i(8, 6)
const D := Vector2i(2, 6)
const SWITCH := Vector2i(3, 6)
const BARRIER := Vector2i(5, 6)
const DOOR := Vector2i(10, 1)
const LANDING := Vector2i(2, 2)
const FALLEN := Vector2i(2, 1)
const HOLE_FLAG: StringName = &"test_s2d_hole_1"
const SWITCH_FLAG: StringName = &"test_s2d_switch_1"
const DOOR_FLAG: StringName = &"test_s2d_door_closed"

var router: Node
var world: Node2D
var player: Player
var fade: ScreenFade
var director: StrengthDirector
var flags := StoryFlags.new()
## Sauvegardes forcées demandées (raisons).
var saves: Array[String] = []


## Crée et câble les nœuds sous [param test] (libérés à la fin du test).
func build(test: GutTest) -> void:
	router = ROUTER_SCRIPT.new()
	test.add_child_autofree(router)
	router.map_factory = make_map
	router.fade_out_duration = FADE_TIME
	router.fade_in_duration = FADE_TIME
	router.teleport_fade_duration = FADE_TIME
	world = Node2D.new()
	test.add_child_autofree(world)
	fade = FADE_SCENE.instantiate() as ScreenFade
	test.add_child_autofree(fade)
	player = PLAYER_SCENE.instantiate() as Player
	test.autofree(player)
	router.setup(world, player, fade)
	router.arrival_flags = func() -> StoryFlags: return flags
	director = StrengthDirector.new()
	test.add_child_autofree(director)
	director.setup(flags, player, null, null)
	director.save_handler = func(reason: String) -> Error:
		saves.append(reason)
		return OK
	router.map_changed.connect(director.on_map_changed)
	flags.flag_changed.connect(func(_flag: StringName, _value: bool) -> void:
		var map: GameMap = router.get_current_map()
		if is_instance_valid(map):
			map.apply_flag_gates(flags))


## Coupe les rappels qui retiennent le banc (à appeler dans after_each).
func release() -> void:
	for connection: Dictionary in flags.flag_changed.get_connections():
		flags.flag_changed.disconnect(connection["callable"])
	if is_instance_valid(director):
		director.save_handler = Callable()
	if is_instance_valid(router):
		router.arrival_flags = Callable()
		router.map_factory = Callable()


## Démarre sur « s », au départ, tourné à droite.
func start() -> GameMap:
	return router.start(&"s", &"start", Vector2i.RIGHT)


func map() -> GameMap:
	return router.get_current_map()


## Place le joueur sur [param cell], tourné vers [param facing] (carte courante).
func put_player(cell: Vector2i, facing: Vector2i) -> void:
	map().spawn_player_at(player, cell, facing)


func make_map(map_id: StringName) -> GameMap:
	match map_id:
		&"s":
			var map := _base_map(map_id, Vector2i(12, 8))
			map.blocked_cells = [WALL] as Array[Vector2i]
			map.surf_cells = [WATER] as Array[Vector2i]
			_spawn(map, &"start", START)
			var setup := BoulderSetup.new()
			setup.name = String(BoulderSetup.NODE_NAME)
			setup.boulder_cells = [A, B, C, D] as Array[Vector2i]
			setup.boulder_holes = [0, 0, 0, 0] as Array[int]
			setup.hole_cells = [HOLE] as Array[Vector2i]
			setup.hole_numbers = [1] as Array[int]
			setup.hole_flags = [HOLE_FLAG] as Array[StringName]
			setup.switch_cells = [SWITCH] as Array[Vector2i]
			setup.switch_ids = [&"sw1"] as Array[StringName]
			setup.switch_flags = [SWITCH_FLAG] as Array[StringName]
			setup.no_push_cells = [NO_PUSH] as Array[Vector2i]
			map.add_child(setup)
			_gate(map, "HoleOpen", [], [HOLE_FLAG], [])
			_gate(map, "HoleFilled", [HOLE_FLAG], [], [])
			_gate(map, "Barrier", [], [SWITCH_FLAG], [BARRIER])
			_gate(map, "SwitchPressed", [SWITCH_FLAG], [], [])
			_warp(map, HOLE, Warp.Trigger.FALL, [HOLE_FLAG])
			_warp(map, DOOR, Warp.Trigger.STEP_ON, [DOOR_FLAG])
			return map
		&"d":
			var map := _base_map(map_id, Vector2i(6, 5))
			_spawn(map, &"chute_joueur", LANDING)
			_gate(map, "FallenBoulder", [HOLE_FLAG], [], [FALLEN])
			return map
	return null


func _base_map(map_id: StringName, map_size: Vector2i) -> GameMap:
	var map := GameMap.new()
	map.name = String(map_id).to_upper()
	map.map_id = map_id
	map.size = map_size
	map.npcs_dir = "res://tests/fixtures/none"
	for group: String in ["Entities", "Spawns", "Warps"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		map.add_child(node)
	return map


func _spawn(map: GameMap, spawn_name: StringName, cell: Vector2i) -> void:
	var marker := Marker2D.new()
	marker.name = spawn_name
	marker.position = Grid.cell_to_world(cell)
	map.get_node(^"Spawns").add_child(marker)


func _gate(map: GameMap, gate_name: String, if_flags: Array, unless_flags: Array,
		blocking: Array) -> void:
	var gate := FlagGate.new()
	gate.name = gate_name
	gate.if_flags.assign(if_flags)
	gate.unless_flags.assign(unless_flags)
	gate.blocking_cells.assign(blocking)
	map.get_node(^"Entities").add_child(gate)


func _warp(map: GameMap, cell: Vector2i, trigger: Warp.Trigger, unless: Array) -> void:
	var point := WarpPoint.new()
	point.name = "Warp%d_%d" % [cell.x, cell.y]
	point.position = Grid.cell_to_world(cell)
	point.trigger = trigger
	point.target_map = &"d"
	point.target_spawn = &"chute_joueur"
	point.unless_flags.assign(unless)
	map.get_node(^"Warps").add_child(point)
