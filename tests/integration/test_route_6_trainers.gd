extends GutTest
## Les Dresseurs de la Route 6 joués sur la vraie scène Boot (jalon 15 T15, jalon-15.md §2.7.7,
## §4 « 15B » ; dossier 18 §6.2, §15.5) :
## - Chloé repère le joueur dans le goulet (colonne 16), réplique « avant », combat, réplique
##   « défaite », récompense du §6.2 (320 ₽), `beaten_route_6_lass_chloe` ; ensuite elle ne
##   défie plus et dit sa réplique « après » ;
## - le Jackpot (T17) dans ce vrai combat : les pièces s'ajoutent à la récompense (2 × niveau par
##   utilisation) ;
## - battus, les six disent leur réplique « après » (données du lot validé).
## Équipe pilotée : un Persan N70 (aucune capacité à apprendre ni évolution d'ici le N71) qui ne
## connaît que Jackpot.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_route_6_trainers_save.json"
const FADE := 0.05
const TIMEOUT := 20.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const CHLOE_FILE := Vector2i(16, 9)
const LEVEL := 70
## Clé du PNJ → Dresseur, récompense (dossier 18 §6.2).
const TRAINERS: Dictionary[StringName, Array] = {
	&"lass_chloe": [&"route_6_lass_chloe", 320],
	&"camper_gabin": [&"route_6_camper_gabin", 320],
	&"scout_axel": [&"route_6_scout_axel", 192],
	&"camper_mathis": [&"route_6_camper_mathis", 400],
	&"lass_manon": [&"route_6_lass_manon", 320],
	&"scout_basile": [&"route_6_scout_basile", 240],
}

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _pages: Array[String] = []
var _spotted: Array[StringName] = []
var _battles: Array[StringName] = []
var _saved_router: Array = []
var _dialogues := DialogueLibrary.new()


func before_all() -> void:
	_dialogues.load_dir()


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-15T14:00:00")
	_fs = MemoryFs.new()
	_pages.clear()
	_spotted.clear()
	_battles.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


func _start(flags: Array[StringName] = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"route_6"
	_boot.start_spawn = &"from_underground"
	_boot.start_facing = Vector2i.DOWN
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file("res://tools/debug_start/route_6.json",
		_boot.get_pokemon_data(), _boot.get_item_library()), "\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	for flag: StringName in flags:
		GameState.flags.set_flag(flag)
	GameState.rng = GameRng.new(11)
	var persian := PokemonFactory.create(_boot.get_pokemon_data(), &"persian", LEVEL,
		GameState.rng)
	persian.moves.clear()
	persian.moves.append(MoveSlot.new(&"pay_day", 20))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(persian)
	GameState.ensure_unique_uids()
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_director().battle_started.connect(func(id: StringName) -> void:
		_battles.append(id))
	_boot.get_trainer_watcher().trainer_spotted.connect(
		func(npc_id: StringName, _trainer: StringName) -> void: _spotted.append(npc_id))
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## Déroule la scène en cours (pages, combat piloté : ATTAQUE puis la seule capacité).
func _play_through() -> void:
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (director.is_running() or _runner.is_running() or battle_director.is_running()
			or SceneRouter.is_transitioning()) and Time.get_ticks_msec() < deadline:
		if battle_director.is_running():
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						battle_hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		await wait_process_frames(1)
		if box.is_open():
			box.advance_requested.emit()
	assert_false(director.is_running(), "scène finie")
	await wait_process_frames(5)


func _talk_to(npc_id: StringName) -> void:
	var map := _boot.get_map()
	var npc := map.get_npc(npc_id)
	assert_not_null(npc, "%s posé" % npc_id)
	if npc == null:
		return
	for other: Npc in map.get_npcs():
		other.set_routine_held(true)
	for direction: Vector2i in DIRECTIONS:
		var from := npc.get_cell() + direction
		if map.get_grid().is_free(from):
			map.spawn_player_at(_player, from, -direction)
			break
	await wait_process_frames(3)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _play_through()


func _line(id: StringName) -> Array[String]:
	var lines: Array[String] = []
	for page: Variant in _dialogues.get_dialogue(id).variants[0].pages:
		lines.append(page.text)
	return lines


func test_chloe_spots_fights_pays_with_pay_day_then_says_her_after_line() -> void:
	await _start()
	var money := GameState.money
	_boot.get_map().spawn_player_at(_player, CHLOE_FILE + Vector2i.LEFT * 2, Vector2i.RIGHT)
	await wait_process_frames(3)
	Input.action_press(&"move_right")
	await wait_until(func() -> bool: return not _spotted.is_empty(), TIMEOUT)
	Input.action_release(&"move_right")
	assert_eq(_spotted, [&"lass_chloe"] as Array[StringName], "Chloé voit le joueur")
	await _play_through()
	assert_eq(_battles, [&"route_6_lass_chloe"] as Array[StringName], "un combat")
	assert_true(GameState.flags.has_flag(&"beaten_route_6_lass_chloe"), "battue")
	var before := _line(&"route_6_lass_chloe_before")
	var defeated := _line(&"route_6_lass_chloe_defeated")
	assert_eq(_pages, before + defeated, "répliques « avant » puis « défaite » (§15.5)")
	var gained := GameState.money - money
	var coins := gained - 320
	assert_gt(coins, 0, "Jackpot : des pièces en plus de la récompense")
	assert_eq(coins % (2 * LEVEL), 0, "2 × niveau par utilisation")
	assert_true(coins >= 3 * 2 * LEVEL, "au moins une utilisation par Roucool")
	# Battue : elle ne défie plus, et dit sa réplique « après ».
	# On isole Chloé : Gabin peut légitimement défier le joueur juste après elle.
	# Les six répliques des Dresseurs sont vérifiées séparément dans le test suivant.
	for key: StringName in TRAINERS:
		if key != &"lass_chloe":
			GameState.flags.set_flag(StringName("beaten_" + String(TRAINERS[key][0])))
	_spotted.clear()
	_pages.clear()
	_boot.get_map().spawn_player_at(_player, CHLOE_FILE + Vector2i.LEFT, Vector2i.RIGHT)
	await wait_process_frames(3)
	Input.action_press(&"move_right")
	await wait_until(func() -> bool: return _player.get_cell().x >= CHLOE_FILE.x + 1, TIMEOUT)
	Input.action_release(&"move_right")
	await wait_process_frames(20)
	assert_eq(_spotted, [] as Array[StringName], "ne défie plus")
	await _talk_to(&"lass_chloe")
	assert_eq(_pages, _line(&"route_6_lass_chloe_after"), "réplique « après »")
	assert_push_error_count(0)


func test_the_six_beaten_trainers_say_their_after_lines() -> void:
	var beaten: Array[StringName] = []
	for key: StringName in TRAINERS:
		beaten.append(StringName("beaten_" + String(TRAINERS[key][0])))
	await _start(beaten)
	var trainers := _boot.get_trainer_library()
	for key: StringName in TRAINERS:
		var info: Array = TRAINERS[key]
		assert_eq(trainers.get_trainer(info[0]).prize_money, info[1], "%s : récompense" % key)
		_pages.clear()
		await _talk_to(key)
		assert_eq(_pages, _line(StringName(String(info[0]) + "_after")), "%s : « après »" % key)
	assert_eq(_battles, [] as Array[StringName], "aucun combat")
	assert_push_error_count(0)

