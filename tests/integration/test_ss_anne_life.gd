extends GutTest
## La vie du navire jouée sur la **vraie scène Boot** (jalon 16 T12 ; `jalon-16.md` §4 « 16A »,
## « 16B » ; dossier 19 §0.5, §4) :
## - Gentleman Armand (pont principal) repère le joueur, réplique « avant », combat, réplique
##   « vaincu », récompense de 760 ₽, `beaten_…` ; ensuite il ne défie plus et dit sa réplique
##   « après » ; Marin Paul, battu d'avance, dit la sienne ;
## - la Potion du pont principal se ramasse **une fois** (Sac + 1, journal, drapeau) et reste
##   absente après un rechargement ;
## - l'Éveil de l'armoire de la cabine B : cible EXAMINER de face seulement, ramassé une fois,
##   plus de cible après un rechargement ;
## - le marin de la passerelle dit TXT-03 avant la CS01, « Prends ton temps… » après.
## Équipe pilotée : un Persan N70 qui ne connaît que Jackpot (comme `test_route_6_trainers`).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_ss_anne_life_save.json"
const DEBUG_START := "res://tools/debug_start/ss_anne.json"
const FADE := 0.05
const TIMEOUT := 20.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const ARMAND_CELL := Vector2i(7, 6)

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _pages: Array[String] = []
var _spotted: Array[StringName] = []
var _battles: Array[StringName] = []
var _toasts: Array[PackedStringArray] = []
var _saved_router: Array = []
var _dialogues := DialogueLibrary.new()


func before_all() -> void:
	_dialogues.load_dir()


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-16T14:00:00")
	_fs = MemoryFs.new()
	_pages.clear()
	_spotted.clear()
	_battles.clear()
	_toasts.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot sur [param map] / [param spawn] ; [param fresh] applique le départ de débogage et
## l'équipe pilotée (sinon : la partie relue de la sauvegarde).
func _start(map: StringName, spawn: StringName, flags: Array[StringName] = [],
		fresh: bool = true) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		var start := DebugStart.new()
		assert_true(start.load_file(DEBUG_START, _boot.get_pokemon_data(),
			_boot.get_item_library()), "\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
		for flag: StringName in flags:
			GameState.flags.set_flag(flag)
		GameState.rng = GameRng.new(11)
		var persian := PokemonFactory.create(_boot.get_pokemon_data(), &"persian", 70,
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
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_toasts.append(PackedStringArray([title, detail])))
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


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


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


## Une réplique a été dite depuis [param pages_before], ou une scène tourne.
func _scene_started(pages_before: int) -> bool:
	return _runner.is_running() or _pages.size() > pages_before \
		or _boot.get_cutscene_director().is_running()


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
	var pages_before := _pages.size()
	await _press_interact()
	await wait_until(func() -> bool: return _scene_started(pages_before), TIMEOUT)
	await _play_through()


func _line(id: StringName) -> Array[String]:
	var lines: Array[String] = []
	for page: DialoguePage in _dialogues.get_dialogue(id).variants[0].pages:
		lines.append(page.text)
	return lines


func test_armand_spots_fights_pays_then_says_his_after_line() -> void:
	await _start(&"ss_anne_main_deck", &"from_ss_anne_w")
	var money := GameState.money
	_boot.get_map().spawn_player_at(_player, ARMAND_CELL + Vector2i(0, 4), Vector2i.UP)
	await wait_process_frames(3)
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return not _spotted.is_empty(), TIMEOUT)
	Input.action_release(&"move_up")
	assert_eq(_spotted, [&"armand"] as Array[StringName], "Armand voit le joueur")
	await _play_through()
	assert_eq(_battles, [&"ss_anne_gentleman_armand"] as Array[StringName], "un combat")
	assert_true(GameState.flags.has_flag(&"beaten_ss_anne_gentleman_armand"), "battu")
	assert_eq(_pages, _line(&"ss_anne_armand_before") + _line(&"ss_anne_armand_defeated"),
		"répliques « avant » puis « vaincu »")
	var gained := GameState.money - money
	assert_gte(gained, 760, "récompense 760 ₽ (+ les pièces du Jackpot)")
	assert_eq((gained - 760) % (2 * 70), 0, "le reste = pièces de Jackpot")
	# Battu (il s'est avancé d'une case ou deux) : il ne défie plus et dit sa réplique « après ».
	_spotted.clear()
	_pages.clear()
	_boot.get_map().spawn_player_at(_player, ARMAND_CELL + Vector2i(0, 4), Vector2i.UP)
	await wait_process_frames(3)
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return _player.get_cell().y <= ARMAND_CELL.y + 3, TIMEOUT)
	Input.action_release(&"move_up")
	await wait_process_frames(20)
	assert_eq(_spotted, [] as Array[StringName], "ne défie plus")
	await _talk_to(&"armand")
	assert_eq(_pages, _line(&"ss_anne_armand_after"), "réplique « après »")
	assert_push_error_count(0)


func test_beaten_paul_and_the_ambient_crew_speak() -> void:
	await _start(&"ss_anne_main_deck", &"from_ss_anne_w",
		[&"beaten_ss_anne_sailor_paul"] as Array[StringName])
	await _talk_to(&"paul")
	assert_eq(_pages, _line(&"ss_anne_paul_after"), "Marin Paul : « après »")
	for key: StringName in [&"hotesse", &"passager_1"]:
		_pages.clear()
		await _talk_to(key)
		assert_eq(_pages.size(), 1, "%s : une bulle" % key)
	assert_eq(_battles, [] as Array[StringName], "aucun combat")
	assert_push_error_count(0)


func test_gangway_sailor_changes_his_line_after_the_cut_hm() -> void:
	await _start(&"ss_anne_main_deck", &"from_ss_anne_w")
	await _talk_to(&"marin_passerelle")
	assert_eq(_pages, ["Tu redescends à terre ? Le navire reste à quai pour l'instant."],
		"TXT-03 avant la CS01")
	_pages.clear()
	GameState.flags.set_flag(&"got_hm01")
	await _talk_to(&"marin_passerelle")
	assert_eq(_pages, ["Prends ton temps. On ne part pas sans toi."], "après la CS01")
	assert_push_error_count(0)


func test_visible_potion_is_taken_once_and_stays_gone_after_reload() -> void:
	await _start(&"ss_anne_main_deck", &"from_ss_anne_w")
	var before := GameState.bag.count_of(&"potion")
	await _talk_to(&"ss_anne_item_01")
	assert_eq(GameState.bag.count_of(&"potion"), before + 1, "Sac + 1")
	assert_true(GameState.flags.has_flag(&"got_ss_anne_item_01"), "drapeau")
	assert_null(_boot.get_map().get_npc(&"ss_anne_item_01"), "plus d'objet à terre")
	assert_eq(GameState.found_items.size(), 1, "journal des objets trouvés")
	_boot.request_autosave("test")
	await wait_process_frames(5)
	var bag_after := GameState.bag.count_of(&"potion")
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(&"ss_anne_main_deck", &"from_ss_anne_w", [] as Array[StringName], false)
	assert_true(GameState.flags.has_flag(&"got_ss_anne_item_01"), "drapeau relu")
	assert_null(_boot.get_map().get_npc(&"ss_anne_item_01"), "rechargé : toujours absent")
	assert_eq(GameState.bag.count_of(&"potion"), bag_after)
	assert_push_error_count(0)


func test_hidden_awakening_in_the_cabin_b_wardrobe_is_found_once() -> void:
	await _start(&"ss_anne_cabin_b", &"entrance", [&"beaten_ss_anne_scout_basile"] as Array[StringName])
	var clue := Vector2i(10, 6)
	var from := Vector2i(9, 6)
	var map := _boot.get_map()
	var controller := _boot.get_interaction_controller()
	assert_true(map.get_grid().is_solid(clue), "l'armoire est bloquée")
	map.spawn_player_at(_player, from, Vector2i.UP)
	await wait_process_frames(3)
	assert_null(controller.get_target(), "de côté : rien")
	map.spawn_player_at(_player, from, Vector2i.RIGHT)
	await wait_process_frames(3)
	var target := controller.get_target()
	assert_not_null(target, "face à l'armoire : une cible")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.EXAMINE, "verbe EXAMINER")
	var before := GameState.bag.count_of(&"awakening")
	await _press_interact()
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"got_ss_anne_hidden_1"),
		TIMEOUT)
	await _play_through()
	assert_eq(GameState.bag.count_of(&"awakening"), before + 1, "Sac + 1")
	assert_eq(_toasts, [PackedStringArray(["Réveil ×1", "Ajouté au Sac"])] as Array[PackedStringArray])
	assert_null(controller.get_target(), "plus de cible une fois trouvé")
	_boot.request_autosave("test")
	await wait_process_frames(5)
	var bag_after := GameState.bag.count_of(&"awakening")
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(&"ss_anne_cabin_b", &"entrance", [] as Array[StringName], false)
	_boot.get_map().spawn_player_at(_player, from, Vector2i.RIGHT)
	await wait_process_frames(3)
	assert_null(_boot.get_interaction_controller().get_target(), "rechargé : plus de cible")
	assert_eq(GameState.bag.count_of(&"awakening"), bag_after)
	assert_push_error_count(0)
