extends GutTest
## Les trois cartes du J17 raccordées (intégration de `jalon-17`, dossier 20 §7, §13), avec la vraie
## scène Boot, les vraies cartes et les vraies entrées (`move_*`, `interact`) :
## - traversée complète Carmin → Route 11 → Cave Taupiqueur → Route 2 est → (arbuste **coupé en
##   jeu**, T23 : CS01, Badge Cascade, Salamèche ; COUPER) → Route 2 par la barrière de FUTUR B,
##   ouverte depuis l'est → Jadielle, puis le retour complet par la Cave jusqu'à Carmin ;
## - Corde Sortie au sol dans le renfoncement R1 de la Cave (2, 44) : ramassée une seule fois,
##   absente après rechargement.
## Les rencontres sauvages sont coupées et les Dresseurs de la Route 11 battus (drapeaux) : le test
## vérifie les raccords, pas les combats. Chemins : parcours en largeur sur la grille de la carte
## courante (occupants compris), recalculés à chaque segment (PNJ qui marchent).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/route_11.json"
const SAVE_PATH := "user://test_j17_crossing_save.json"
const TIMEOUT := 12.0
const FADE := 0.05
const WALK_STOP := &"test_walk_stop"
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const ROUTE_11_TRAINERS: Array[StringName] = [&"route_11_youngster_arthur",
	&"route_11_youngster_lucas", &"route_11_youngster_louis", &"route_11_youngster_raphael",
	&"route_11_gambler_marcel", &"route_11_gambler_roger", &"route_11_engineer_bruno",
	&"route_11_engineer_victor"]
const BUSH_FLAG := &"cut_route_2_east_bush"
const GATE_FLAG := &"route_2_east_gate_open"
const ROPE_NPC := &"digletts_cave_item_1"
const ROPE_FLAG := &"got_digletts_cave_item_1"
const ROPE_CELL := Vector2i(2, 44)
const T8: Array[String] = ["La barrière s'ouvre de ce côté.", "Le sentier rejoint la Route 2."]
const NORTH_OF_BUSH := Vector2i(6, 20)
const CUT: Array[String] = ["Salamèche peut couper cet arbuste.", "Utiliser Coupe ?",
	"Salamèche utilise Coupe !"]

var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _stop_at := Vector2i(-1, -1)
var _held: StringName = &""
## Cartes traversées, dans l'ordre (une entrée par arrivée).
var _visited: Array[StringName] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-16T10:00:00")
	_visited.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact", &"run"]:
		Input.action_release(action)


func _start(map_id: StringName, spawn: StringName, facing: Vector2i,
		extra_flags: Array[StringName] = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = map_id
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	for flag: StringName in extra_flags:
		GameState.flags.set_flag(flag)
	_boot.get_encounter_director().enabled = false
	_player.moved.connect(_on_player_moved)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	assert_eq(_boot.get_map().map_id, map_id)


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


func _on_player_moved(cell: Vector2i) -> void:
	if cell == _stop_at and not _held.is_empty():
		Input.action_release(_held)
		_held = &""
		_player.set_input_enabled(false, WALK_STOP)


## Plus court chemin (liste de cases d'arrivée) vers [param goal], sans passer par une case de
## passage (porte, bouche, bord) autre que [param goal].
func _path(goal: Vector2i) -> Array[Vector2i]:
	var map := _boot.get_map()
	var grid := map.get_grid()
	var avoid: Dictionary = {}
	for warp: Warp in map.get_warps().get_all():
		if warp.cell != goal:
			avoid[warp.cell] = true
	var from := _player.get_cell()
	var previous: Dictionary = {from: from}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		if cell == goal:
			break
		for direction: Vector2i in DIRECTIONS:
			var next := grid.get_step_target(cell, direction, _player)
			if next == cell or previous.has(next) or avoid.has(next):
				continue
			previous[next] = cell
			queue.append(next)
	var path: Array[Vector2i] = []
	if not previous.has(goal):
		return path
	var back := goal
	while back != from:
		path.push_front(back)
		back = previous[back]
	return path


## Marche jusqu'à [param goal] par segments rectilignes (chemin recalculé après chaque segment).
func _go(goal: Vector2i) -> void:
	for attempt: int in 60:
		if _player.get_cell() == goal:
			return
		var path := _path(goal)
		if path.is_empty():
			break
		var from := _player.get_cell()
		var direction := Grid.dominant_direction(from, path[0])
		var until := path[0]
		for cell: Vector2i in path.slice(1):
			if Grid.dominant_direction(until, cell) != direction:
				break
			until = cell
		await _walk(direction, until, from.distance_to(until))
	assert_eq(_player.get_cell(), goal, "%s : atteint %s" % [_boot.get_map().map_id, goal])


func _walk(direction: Vector2i, until: Vector2i, length: float) -> void:
	_stop_at = until
	_held = _action(direction)
	Input.action_press(&"run")
	Input.action_press(_held)
	await wait_until(func() -> bool:
		return _player.get_cell() == until or not _player.is_input_enabled(), 3.0 + length)
	Input.action_release(&"run")
	await wait_process_frames(1)
	if not _held.is_empty():
		Input.action_release(_held)
		_held = &""
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	_player.set_input_enabled(true, WALK_STOP)


## Prend le passage de la carte courante vers [param target] ([param spawn] : son point
## d'arrivée, ou le plus proche si vide) et vérifie la case d'arrivée.
func _through(target: StringName, spawn: StringName = &"") -> void:
	var map := _boot.get_map()
	var from_id := map.map_id
	var chosen: Warp = null
	var best := 1 << 30
	for warp: Warp in map.get_warps().get_all():
		if warp.target_map != target or (not spawn.is_empty() and warp.target_spawn != spawn):
			continue
		var stand := warp.cell if warp.trigger == Warp.Trigger.PUSH else warp.cell - warp.direction
		var steps := 0 if stand == _player.get_cell() else _path(stand).size()
		if (steps > 0 or stand == _player.get_cell()) and steps < best:
			best = steps
			chosen = warp
	assert_not_null(chosen, "%s : passage vers %s/%s" % [from_id, target, spawn])
	if chosen == null:
		return
	var stand := chosen.cell if chosen.trigger == Warp.Trigger.PUSH \
		else chosen.cell - chosen.direction
	await _go(stand)
	var arrival_spawn := chosen.target_spawn
	var action := _action(chosen.direction)
	Input.action_press(action)
	await wait_until(func() -> bool: return SceneRouter.is_transitioning(), TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool:
		return not SceneRouter.is_transitioning() and _boot.get_map().map_id == target \
			and _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)
	var arrived := _boot.get_map()
	assert_eq(arrived.map_id, target, "%s → %s" % [from_id, target])
	assert_eq(_player.get_cell(), arrived.get_spawn_cell(arrival_spawn),
		"%s → %s/%s : case d'arrivée" % [from_id, target, arrival_spawn])
	assert_false(_boot.get_coming_soon_screen().is_showing(), "aucun écran « à venir »")
	_visited.append(target)


## Interagit avec la case devant le joueur ; renvoie les pages lues. Aux cartes de choix
## (COUPER / LAISSER), confirme.
func _interact(facing: Vector2i) -> Array[String]:
	_player.face(facing)
	var box := _boot.get_dialogue_box()
	var pages: Array[String] = []
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var deadline := Time.get_ticks_msec() + 20000
	while (_boot.get_dialogue_runner().is_running() or box.is_open() \
			or _boot.get_cutscene_director().is_running()) and Time.get_ticks_msec() < deadline:
		if box.is_choice_showing():
			box.get_choice_cards().get_confirm_button().pressed.emit()
		elif box.is_open():
			var text := box.get_text()
			if pages.is_empty() or pages.back() != text:
				pages.append(text)
			if not _boot.get_dialogue_runner().is_awaiting_choice():
				box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_process_frames(3)
	return pages


func _beaten_flags() -> Array[StringName]:
	var flags: Array[StringName] = []
	for id: StringName in ROUTE_11_TRAINERS:
		flags.append(TrainerRules.beaten_flag(id))
	return flags


func test_full_crossing_from_vermilion_to_viridian_and_back_through_the_cave() -> void:
	var flags := _beaten_flags()
	flags.append(&"badge_cascade")
	await _start(&"vermilion_city", &"from_route_11_c", Vector2i.RIGHT, flags)
	GameState.bag.add(&"hm01")
	# Aller : Carmin → Route 11 → Cave (bouche sud) → Route 2 est (bouche nord).
	await _through(&"route_11", &"from_vermilion_c")
	await _through(&"digletts_cave", &"from_route_11_w")
	await _through(&"route_2_east", &"from_cave_w")
	# Couloir : Salamèche coupe l'arbuste (T23, mécanisme du J16), puis le bord ouest.
	await _go(NORTH_OF_BUSH)
	assert_eq(await _interact(Vector2i.DOWN), CUT, "ARB-03, COUPER, ARB-04")
	assert_true(GameState.flags.has_flag(BUSH_FLAG), "arbuste coupé en jeu")
	await _through(&"route_2", &"from_route_2_east_n")
	# Barrière de FUTUR B ouverte depuis l'est (T-8), puis Route 2 sud jusqu'à Jadielle.
	await _go(Vector2i(35, 43))
	assert_eq(await _interact(Vector2i.LEFT), T8, "T-8")
	assert_true(GameState.flags.has_flag(GATE_FLAG), "barrière ouverte")
	await _go(Vector2i(33, 43))
	await _through(&"viridian_city")
	# Retour complet : Jadielle → Route 2 → barrière → couloir → Cave → Route 11 → Carmin.
	await _through(&"route_2")
	await _through(&"route_2_east")
	await _through(&"digletts_cave", &"from_route_2_east_w")
	await _through(&"route_11", &"from_cave_e")
	await _through(&"vermilion_city")
	assert_eq(_visited, [&"route_11", &"digletts_cave", &"route_2_east", &"route_2",
		&"viridian_city", &"route_2", &"route_2_east", &"digletts_cave", &"route_11",
		&"vermilion_city"] as Array[StringName])
	assert_eq(GameState.party.size(), 3, "aucun combat, équipe intacte")
	assert_push_error_count(0)


func test_the_escape_rope_in_the_recess_is_taken_once_and_gone_after_a_reload() -> void:
	await _start(&"digletts_cave", &"from_route_11_w", Vector2i.UP)
	var map := _boot.get_map()
	assert_not_null(map.get_npc(ROPE_NPC), "Corde Sortie visible dans le renfoncement R1")
	assert_true(map.get_grid().is_occupied(ROPE_CELL), "l'objet occupe sa case")
	assert_eq(GameState.bag.count_of(&"escape_rope"), 0)
	await _go(ROPE_CELL + Vector2i.RIGHT)
	await _interact(Vector2i.LEFT)
	assert_eq(GameState.bag.count_of(&"escape_rope"), 1, "Corde Sortie au Sac")
	assert_true(GameState.flags.has_flag(ROPE_FLAG))
	assert_null(map.get_npc(ROPE_NPC), "retirée du sol")
	assert_false(map.get_grid().is_occupied(ROPE_CELL), "case libérée")
	# Redire « prendre » sur la case vide ne donne rien.
	await _interact(Vector2i.LEFT)
	assert_eq(GameState.bag.count_of(&"escape_rope"), 1, "une seule Corde Sortie")
	# Rechargement de la carte avec les drapeaux : la Corde n'y est plus.
	var reloaded := (load(MapCatalog.scene_path(&"digletts_cave")) as PackedScene) \
		.instantiate() as GameMap
	add_child_autofree(reloaded)
	reloaded.refresh_npcs(GameState.flags)
	assert_null(reloaded.get_npc(ROPE_NPC), "absente après rechargement")
	assert_push_error_count(0)
