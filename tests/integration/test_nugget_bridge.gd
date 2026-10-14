extends GutTest
## Le Pont Pépite (jalon 13 T22, jalon-13.md §2.12 ; dossier 16 §11, §19 ; textes n° 42 à 47) avec la
## vraie scène Boot, la vraie carte `route_24`, les vrais Dresseurs et le combat instantané :
## - cinq Dresseurs posés aux cases et aux vues de la grille, chacun avec ses deux répliques ;
## - du pied du pont au recruteur, on les rencontre **dans l'ordre P1 → P5** (aucun contournement) et
##   le recruteur ne se déclenche qu'une fois P5 battu ;
## - défaite au milieu : réveil au Centre d'Azuria, les battus restent battus, les autres attendent.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/nugget_bridge.json"
const SAVE_PATH := "user://test_nugget_bridge_save.json"
const FADE := 0.05
const SCENE_TIMEOUT_MS := 120000
const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
## [identifiant Dresseur, case, vue, avant, après (battu)] : P1 à P5 (textes n° 43 à 47).
const BRIDGE: Array = [
	[&"route_24_timeo", Vector2i(32, 41), "Bienvenue au Pont Pépite ! Je suis le premier des cinq !",
		"Le premier… et le premier battu."],
	[&"route_24_alice", Vector2i(33, 37), "Deuxième ! Tu n'as encore rien vu.",
		"Bon. Va voir le troisième."],
	[&"route_24_malo", Vector2i(32, 33), "Troisième ! Tu fatigues déjà ?", "…Non, visiblement."],
	[&"route_24_romane", Vector2i(33, 29), "Quatrième ! Plus qu'un après moi.",
		"Plus qu'un, alors."],
	[&"route_24_ethan", Vector2i(32, 25), "Dernier ! Si tu me bats, la récompense est à toi !",
		"Elle est à toi. Va la chercher."],
]
const NEAR_TOP := Vector2i(33, 24)

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []
var _started: Array[StringName] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-14T11:00:00")
	_fs = MemoryFs.new()
	_pages.clear()
	_started.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)


func _start(strong: bool) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"cerulean_city"
	_boot.start_spawn = &"from_route_24_c"
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	GameState.rng = GameRng.new(7)
	GameState.heal_map = &"cerulean_center"
	GameState.heal_spawn = &"heal"
	_set_team(strong)
	await wait_process_frames(2)
	await SceneRouter.change_map(&"route_24", &"bridge_foot", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _started.append(id))
	assert_eq(_boot.get_map().map_id, &"route_24")
	assert_eq(_player.get_cell(), Vector2i(32, 46), "pied du pont")


func _set_team(strong: bool) -> void:
	var lead := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander",
		60 if strong else 2, GameState.rng)
	lead.moves.clear()
	lead.moves.append(MoveSlot.new(&"ember", 25))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(lead)


func _busy() -> bool:
	return _boot.get_cutscene_director().is_running() \
			or _boot.get_dialogue_runner().is_running() or SceneRouter.is_transitioning()


## Marche vers [param goal] case par case (chemin de la grille réelle, occupants compris) ; rend la
## main dès qu'une scène démarre. Vrai si le but est atteint.
## Distances à pied depuis [param goal] (la case du joueur ne le bloque pas).
func _distances(grid: GridWorld, goal: Vector2i) -> Dictionary:
	var dist: Dictionary = {goal: 0}
	var queue: Array[Vector2i] = [goal]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for direction: Vector2i in DIRECTIONS:
			var next := cell + direction
			if not dist.has(next) and grid.get_step_target(next, -direction, _player) == cell:
				dist[next] = int(dist[cell]) + 1
				queue.append(next)
	return dist


func _goto(goal: Vector2i) -> bool:
	var deadline := Time.get_ticks_msec() + 60000
	while Time.get_ticks_msec() < deadline:
		if _busy():
			return false
		var cell := _player.get_cell()
		if cell == goal and not _player.is_moving():
			return true
		var grid := _boot.get_map().get_grid()
		var dist := _distances(grid, goal)
		var step := Vector2i.ZERO
		for direction: Vector2i in DIRECTIONS:
			var next := cell + direction
			if dist.has(next) and int(dist[next]) < int(dist.get(cell, 1 << 30)) \
					and grid.get_step_target(cell, direction) == next:
				step = direction
				break
		if step == Vector2i.ZERO:
			assert_true(false, "aucun chemin de %s vers %s" % [cell, goal])
			return false
		var action: StringName = DIRECTIONS[step]
		Input.action_press(action)
		var target := cell + step
		var step_deadline := Time.get_ticks_msec() + 8000
		while _player.get_cell() != target and not _busy() and Time.get_ticks_msec() < step_deadline:
			await wait_process_frames(1)
		Input.action_release(action)
		await wait_until(func() -> bool: return not _player.is_moving() or _busy(), 3.0)
	return false


func _play_through() -> bool:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var seen_battle := false
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()
			or battle_director.is_running()) and Time.get_ticks_msec() < deadline:
		if battle_director.is_running():
			seen_battle = true
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						battle_hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		await wait_process_frames(1)
		if box.is_open():
			var text := box.get_text()
			if _pages.is_empty() or _pages.back() != text:
				_pages.append(text)
			box.advance_requested.emit()
	await wait_process_frames(3)
	return seen_battle


func _beaten(id: StringName) -> bool:
	return GameState.flags.has_flag(StringName("beaten_%s" % id))


func _beaten_ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for row: Array in BRIDGE:
		if _beaten(row[0]):
			found.append(row[0])
	return found


func test_five_trainers_stand_where_the_grid_says_with_their_two_lines() -> void:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/route_24.txt"), plan.error)
	var plan_ids := ["p1_timeo", "p2_alice", "p3_malo", "p4_romane", "p5_ethan"]
	await _start(true)
	var map := _boot.get_map()
	var library := DialogueLibrary.new()
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	for i: int in BRIDGE.size():
		var row: Array = BRIDGE[i]
		var npc := map.get_npc(row[0])
		assert_not_null(npc, "%s posé" % row[0])
		if npc == null:
			continue
		assert_eq(npc.get_cell(), row[1])
		assert_eq(npc.get_cell(), plan.cell_of(plan_ids[i]), "case de la grille")
		assert_eq(npc.get_spec().trainer_id, row[0])
		assert_eq(npc.get_spec().sight, 3, "vue de 3 cases (la grille)")
		assert_eq(npc.get_spec().facing, Vector2i.DOWN)
		var before := library.get_dialogue(npc.get_spec().before_dialogue)
		var after := library.get_dialogue(npc.get_spec().dialogue)
		assert_eq(before.variants[0].pages[0].text, row[2], "avant : %s" % row[0])
		assert_eq(after.variants[0].pages[0].text, row[3], "après : %s" % row[0])
	assert_not_null(map.get_npc(&"nugget_rocket"), "le recruteur attend au bout du pont")
	assert_eq(map.get_npc(&"nugget_rocket").get_cell(), Vector2i(33, 21))
	assert_push_error_count(0)


func test_the_bridge_is_crossed_in_order_p1_to_p5_then_the_recruiter() -> void:
	await _start(true)
	var order: Array[StringName] = []
	var steps := 0
	while steps < 12:
		steps += 1
		var arrived := await _goto(NEAR_TOP)
		if arrived:
			break
		var scene: StringName = _started.back() if not _started.is_empty() else &""
		var fights_before := _beaten_ids().size()
		assert_true(await _play_through() or scene == &"route_24_rocket", "scène ou combat")
		for id: StringName in _beaten_ids():
			if not order.has(id):
				order.append(id)
		if scene == &"route_24_rocket":
			break
		assert_eq(_beaten_ids().size(), fights_before + 1, "un seul Dresseur à la fois")
	assert_eq(order, [&"route_24_timeo", &"route_24_alice", &"route_24_malo",
		&"route_24_romane", &"route_24_ethan"] as Array[StringName], "P1 → P5, dans l'ordre")
	assert_false(_beaten(&"nugget_rocket"), "le recruteur n'est pas encore battu")
	# Chaque Dresseur a dit sa réplique « avant ».
	for row: Array in BRIDGE:
		assert_true(_pages.has(row[2]), "« %s »" % row[2])
	assert_push_error_count(0)


func test_a_defeat_in_the_middle_keeps_the_beaten_and_the_others_wait() -> void:
	await _start(true)
	var fights := 0
	while fights < 2:
		var arrived := await _goto(NEAR_TOP)
		assert_false(arrived, "il y a quelqu'un avant le haut du pont")
		assert_true(await _play_through(), "combat")
		fights += 1
	assert_eq(_beaten_ids(), [&"route_24_timeo", &"route_24_alice"] as Array[StringName])
	# Le troisième nous bat.
	_set_team(false)
	var money := GameState.money
	await _goto(NEAR_TOP)
	assert_true(await _play_through(), "combat perdu")
	assert_eq(_boot.get_map().map_id, &"cerulean_center", "réveil au Centre d'Azuria")
	assert_eq(_beaten_ids(), [&"route_24_timeo", &"route_24_alice"] as Array[StringName],
		"les deux battus restent battus, Malo non")
	assert_false(_beaten(&"route_24_malo"))
	assert_eq(GameState.money, money, "aucun argent perdu")
	# Retour : P1 et P2 ne se déclenchent plus, P3 attend.
	_set_team(true)
	await SceneRouter.change_map(&"route_24", &"bridge_foot", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	var met := 0
	var steps := 0
	while steps < 8:
		steps += 1
		if await _goto(NEAR_TOP):
			break
		var before := _beaten_ids().size()
		await _play_through()
		if _beaten_ids().size() > before:
			met += 1
		if _started.back() == &"route_24_rocket":
			break
	assert_eq(met, 3, "Malo, Romane, Ethan : trois nouveaux combats seulement")
	assert_eq(_beaten_ids().size(), 5)
	assert_push_error_count(0)
