extends GutTest
## Scène d'Ondine au pont, enchaînée à la victoire contre le rival n° 3 (jalon 13 T19,
## jalon-13.md §2.9 ; dossier 16 §8, §19 ; texte n° 33), avec la vraie scène Boot, la vraie carte
## `route_24`, les vraies scènes `route_24_rival` puis `route_24_misty` (clé `next`), le combat
## instantané et une sauvegarde en mémoire :
## - enchaînement direct : victoire du rival → Ondine s'approche, 4 pages, part vers la ville,
##   `misty_invited` ; rien d'écrit pendant la scène d'Ondine, une écriture entre les deux ;
## - reprise : la sauvegarde d'entre-scènes rechargée (rival absent, Ondine présente) rejoue la
##   scène au premier pas sur la place ; idem en lui parlant ; puis Ondine absente, scène désarmée ;
## - jamais avant la victoire du rival.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/rival_cerulean.json"
const PENDING_START := "res://tools/debug_start/misty_pending.json"
const SAVE_PATH := "user://test_route_24_misty_save.json"
const DATE := "2026-10-13T18:00:00"
const FADE := 0.05
const TIMEOUT_MS := 8000
const SCENE_TIMEOUT_MS := 120000
const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
const FOOT := Vector2i(32, 61)
const MISTY_HOME := Vector2i(37, 46)
const SQUARE_ENTRY := Vector2i(32, 53)
const INVITE: Array[String] = [
	"Joli combat.", "Tu ne l'as pas lâché, même quand il a pris l'avantage.",
	"Je suis Ondine, la Championne d'Azuria.",
	"Viens me voir à l'Arène. Je veux voir ça de plus près.",
]

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []
var _started: Array[StringName] = []
## Relevé au début de chaque scène : sauvegarde écrite, nombre d'écritures.
var _saved_at_start: Array[Dictionary] = []
var _writes_at_start: Array[int] = []
var _misty_cell_at_first_invite_page := Vector2i(-1, -1)
var _writes_at_invite_page := -1


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_pages.clear()
	_started.clear()
	_saved_at_start.clear()
	_writes_at_start.clear()
	_misty_cell_at_first_invite_page = Vector2i(-1, -1)
	_writes_at_invite_page = -1


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)
	Input.action_release(&"interact")


## Boot sur [param fs] (sauvegarde en mémoire). Avec [param start_path] : départ de débogage
## (puis Route 24 au bas du couloir) ; sans : reprise de la sauvegarde déjà dans [param fs].
func _start(fs: MemoryFs, start_path: String = "", strong: bool = false) -> void:
	_fs = fs
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"cerulean_city"
	_boot.start_spawn = &"from_route_24_c"
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	if not start_path.is_empty():
		var start := DebugStart.new()
		assert_true(start.load_file(start_path, _boot.get_pokemon_data(),
			_boot.get_item_library()), "\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
		GameState.rng = GameRng.new(7)
		if strong:
			var champion := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 60,
				GameState.rng)
			champion.moves.clear()
			champion.moves.append(MoveSlot.new(&"ember", 25))
			while GameState.party.size() > 0:
				GameState.party.remove_at(0)
			GameState.party.add(champion)
		await wait_process_frames(2)
		await SceneRouter.change_map(&"route_24", &"from_cerulean_c", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_cutscene_director().cutscene_started.connect(_on_cutscene_started)
	assert_eq(_boot.get_map().map_id, &"route_24")


func _on_cutscene_started(cutscene_id: StringName) -> void:
	_started.append(cutscene_id)
	_saved_at_start.append(_saved())
	_writes_at_start.append(_writes())


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


func _saved_flags(content: Dictionary) -> Array:
	return JsonFields.get_array(content, "flags")


## Déroule tout ce qui est en cours (scène, enchaînement, combat piloté, pages avancées).
func _play_through() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
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
			var text := box.get_text()
			if text == INVITE[0] and (_pages.is_empty() or _pages.back() != text):
				var misty := _boot.get_map().get_npc(&"misty_bridge")
				if misty != null:
					_misty_cell_at_first_invite_page = misty.get_cell()
				_writes_at_invite_page = _writes()
			if _pages.is_empty() or _pages.back() != text:
				_pages.append(text)
			box.advance_requested.emit()
	await wait_process_frames(3)


func _walk_to(goal: Vector2i) -> void:
	var delta := goal - _player.get_cell()
	if delta == Vector2i.ZERO:
		return
	var direction := Vector2i(signi(delta.x), signi(delta.y))
	var action: StringName = DIRECTIONS[direction]
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	Input.action_press(action)
	while Time.get_ticks_msec() < deadline:
		var cell := _player.get_cell()
		if _player.is_moving() and cell + direction == goal:
			Input.action_release(action)
		if cell == goal and not _player.is_moving():
			break
		if not _player.is_input_enabled():
			break
		await wait_process_frames(1)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), 2.0)


func _assert_invitation_done() -> void:
	assert_true(GameState.flags.has_flag(&"misty_invited"))
	assert_null(_boot.get_map().get_npc(&"misty_bridge"), "Ondine est partie")
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_false(_boot.get_cutscene_director().is_running())


# --- Enchaînement direct ----------------------------------------------------------------------

func test_victory_chains_misty_with_a_save_between_and_no_write_during() -> void:
	await _start(MemoryFs.new(), START, true)
	assert_not_null(_boot.get_map().get_npc(&"misty_bridge"), "Ondine attend au pont")
	assert_eq(_boot.get_map().get_npc(&"misty_bridge").get_cell(), MISTY_HOME)
	await _walk_to(Vector2i(32, 56))
	await _walk_to(Vector2i(32, 55))
	await wait_process_frames(2)
	await _play_through()
	assert_eq(_started, [&"route_24_rival", &"route_24_misty"] as Array[StringName],
		"le rival, puis Ondine")
	var between := _saved_at_start[1]
	var flags := _saved_flags(between)
	assert_true(flags.has("rival_cerulean_won"), "la sauvegarde d'entre-scènes a la victoire")
	assert_false(flags.has("misty_invited"), "et pas encore l'invitation")
	assert_eq(_writes_at_start[1], _writes_at_start[0] + 1,
		"une écriture entre les deux scènes (aucune pendant la première)")
	assert_eq(_writes_at_invite_page, _writes_at_start[1], "rien d'écrit pendant la scène d'Ondine")
	for line: String in INVITE:
		assert_true(_pages.has(line), "« %s » jouée" % line)
	assert_gt(_pages.find(INVITE[0]), _pages.find("…Encore."), "après les mots du rival")
	assert_eq(_misty_cell_at_first_invite_page, Vector2i(32, 54),
		"Ondine s'est approchée, au nord du joueur")
	_assert_invitation_done()
	assert_eq(_player.get_cell(), Vector2i(32, 55), "le joueur n'a pas bougé")
	await wait_until(func() -> bool:
		return _saved_flags(_saved()).has("misty_invited"), 5.0)
	assert_true(_saved_flags(_saved()).has("misty_invited"), "autosave de fin de scène")
	assert_push_error_count(0)


# --- Reprise ----------------------------------------------------------------------------------

func test_a_game_quit_between_the_two_scenes_replays_misty_on_the_square() -> void:
	await _start(MemoryFs.new(), START, true)
	await _walk_to(Vector2i(32, 56))
	await _walk_to(Vector2i(32, 55))
	await _play_through()
	var between: String = JSON.stringify(_saved_at_start[1])
	assert_true(_saved_flags(_saved_at_start[1]).has("rival_cerulean_won"))
	# Fermeture forcée à ce moment : une nouvelle session relit la sauvegarde d'entre-scènes.
	_boot.queue_free()
	await wait_process_frames(2)
	_pages.clear()
	_started.clear()
	_saved_at_start.clear()
	_writes_at_start.clear()
	var fs := MemoryFs.new()
	fs.files[SAVE_PATH] = between
	await _start(fs)
	assert_eq(_player.get_cell(), Vector2i(32, 55), "même case que sauvegardée")
	assert_true(GameState.flags.has_flag(&"rival_cerulean_won"))
	assert_false(GameState.flags.has_flag(&"misty_invited"))
	assert_null(_boot.get_map().get_npc(&"rival_cerulean"), "le rival est absent")
	assert_not_null(_boot.get_map().get_npc(&"misty_bridge"), "Ondine attend toujours")
	await _walk_to(Vector2i(32, 54))
	assert_false(_boot.get_cutscene_director().is_running(), "pas avant la place")
	await _walk_to(SQUARE_ENTRY)
	await wait_process_frames(2)
	await _play_through()
	assert_eq(_started, [&"route_24_misty"] as Array[StringName], "la scène d'Ondine seule")
	for line: String in INVITE:
		assert_true(_pages.has(line), "« %s » jouée" % line)
	_assert_invitation_done()
	# Désarmée : ni scène ni Ondine en revenant sur la place.
	_started.clear()
	await _walk_to(Vector2i(32, 54))
	await _walk_to(SQUARE_ENTRY)
	assert_false(_boot.get_cutscene_director().is_running(), "scène désarmée")
	assert_eq(_started.size(), 0)
	await SceneRouter.change_map(&"route_24", &"from_cerulean_c", Vector2i.UP)
	await wait_process_frames(3)
	assert_null(_boot.get_map().get_npc(&"misty_bridge"), "absente au rechargement")
	assert_push_error_count(0)


func test_talking_to_misty_during_the_resume_plays_the_same_scene() -> void:
	await _start(MemoryFs.new(), PENDING_START)
	assert_null(_boot.get_map().get_npc(&"rival_cerulean"), "rival déjà parti")
	var misty := _boot.get_map().get_npc(&"misty_bridge")
	assert_not_null(misty, "Ondine présente")
	_boot.get_map().spawn_player_at(_player, MISTY_HOME + Vector2i.LEFT, Vector2i.RIGHT)
	await wait_process_frames(3)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	assert_eq(_boot.get_cutscene_director().get_cutscene_id(), &"route_24_misty",
		"lui parler lance la scène")
	await _play_through()
	for line: String in INVITE:
		assert_true(_pages.has(line), "« %s » jouée" % line)
	_assert_invitation_done()
	assert_push_error_count(0)


func test_nothing_happens_on_the_square_before_the_rival_is_beaten() -> void:
	await _start(MemoryFs.new(), START)
	assert_not_null(_boot.get_map().get_npc(&"misty_bridge"))
	# Le rival n'est pas battu : la scène d'Ondine n'a aucune variante, même si on y met le pied
	# (téléportation de test sur le déclencheur de la place).
	_boot.get_map().spawn_player_at(_player, SQUARE_ENTRY + Vector2i.DOWN, Vector2i.UP)
	await wait_process_frames(3)
	await _walk_to(SQUARE_ENTRY)
	await wait_process_frames(2)
	assert_false(_boot.get_cutscene_director().is_running(), "aucune scène sans la victoire")
	assert_false(GameState.flags.has_flag(&"misty_invited"))
	assert_not_null(_boot.get_map().get_npc(&"misty_bridge"), "Ondine reste là")
	assert_push_error_count(0)
