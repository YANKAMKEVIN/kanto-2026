extends GutTest
## Le recruteur Rocket, le choix et la Pépite (jalon 13 T22, jalon-13.md §2.13 ; dossier 16 §12,
## §19 ; textes n° 48 à 55) avec la vraie scène Boot, la vraie carte `route_24` (départ
## `nugget_rocket` : les cinq Dresseurs du pont battus) et le combat instantané :
## - OUI et NON : réplique propre (n° 51 / n° 52), puis le **même** combat ; la Pépite est au Sac
##   **avant** le combat, une seule fois ; `nugget_rocket_yes` n'a aucune autre conséquence ;
## - victoire : n° 53, départ, drapeau `beaten_nugget_rocket`, absent au rechargement ;
## - défaite : n° 54, réveil au Centre d'Azuria, Pépite gardée ; retour : n° 55, **sans** proposition
##   ni choix, jamais une seconde Pépite, même combat.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/nugget_rocket.json"
const SAVE_PATH := "user://test_nugget_rocket_save.json"
const FADE := 0.05
const SCENE_TIMEOUT_MS := 120000
const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
const TOP := Vector2i(33, 26)
const TRIGGER := Vector2i(33, 23)
const RECRUITER := &"nugget_rocket"
const WELCOME: Array[String] = ["Bravo ! Cinq victoires d'affilée.", "Voici ta récompense."]
const OFFER: Array[String] = [
	"Dis-moi…", "Quelqu'un avec ton talent perd son temps à collectionner des badges.",
	"Nous recrutons. Ça t'intéresse ?",
]
const YES: Array[String] = ["Tu crois que c'est si simple ?",
	"Montre-moi d'abord ce que tu vaux vraiment."]
const NO: Array[String] = ["Dommage.", "Alors je vais devoir te convaincre autrement."]
const BEATEN: Array[String] = ["Hm. Tu ferais un excellent…",
	"Non. Un ennemi. Tu ferais un excellent ennemi."]
const LOST: Array[String] = ["Réfléchis bien. L'offre tient toujours."]
const RESUME: Array[String] = ["Alors ? Tu as changé d'avis ?"]

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []
var _started: Array[StringName] = []
## Pépites au Sac relevées à chaque page (avant le combat : la Pépite est remise d'abord).
var _nuggets_at_page: Dictionary[String, int] = {}
var _battle_seen_with_nuggets := -1
var _asked_choice := 0
var _answer := true


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-14T11:00:00")
	_fs = MemoryFs.new()
	_reset_log()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)


func _reset_log() -> void:
	_pages.clear()
	_started.clear()
	_nuggets_at_page.clear()
	_battle_seen_with_nuggets = -1
	_asked_choice = 0


func _start(fs: MemoryFs, strong: bool, fresh: bool = true) -> void:
	_fs = fs
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"cerulean_city"
	_boot.start_spawn = &"from_route_24_c"
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	if fresh:
		var start := DebugStart.new()
		assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
		GameState.rng = GameRng.new(7)
		GameState.heal_map = &"cerulean_center"
		GameState.heal_spawn = &"heal"
		_set_team(strong)
		await wait_process_frames(2)
		await SceneRouter.change_map(&"route_24", &"bridge_top", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _started.append(id))
	_boot.get_battle_director().battle_started.connect(func(_trainer: StringName) -> void:
		_battle_seen_with_nuggets = GameState.bag.count_of(&"nugget"))
	assert_eq(_boot.get_map().map_id, &"route_24")


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


func _goto(goal: Vector2i) -> void:
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline and not _busy():
		var cell := _player.get_cell()
		if cell == goal and not _player.is_moving():
			return
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
			return
		var action: StringName = DIRECTIONS[step]
		Input.action_press(action)
		var target := cell + step
		var step_deadline := Time.get_ticks_msec() + 8000
		while _player.get_cell() != target and not _busy() and Time.get_ticks_msec() < step_deadline:
			await wait_process_frames(1)
		Input.action_release(action)
		await wait_until(func() -> bool: return not _player.is_moving() or _busy(), 3.0)


func _play_through() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()
			or battle_director.is_running()) and Time.get_ticks_msec() < deadline:
		if battle_director.is_running():
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						battle_hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		await wait_process_frames(1)
		if runner.is_awaiting_choice():
			_asked_choice += 1
			runner.choose(_answer)
		elif box.is_open():
			var text := box.get_text()
			if _pages.is_empty() or _pages.back() != text:
				_pages.append(text)
				_nuggets_at_page[text] = GameState.bag.count_of(&"nugget")
			box.advance_requested.emit()
	await wait_process_frames(3)


func _has_all(lines: Array[String]) -> bool:
	for line: String in lines:
		if not _pages.has(line):
			return false
	return true


func _meet(answer: bool) -> void:
	_answer = answer
	await _goto(TRIGGER)
	assert_eq(_boot.get_cutscene_director().get_cutscene_id(), &"route_24_rocket",
		"le déclencheur lance la scène")
	await _play_through()


func test_yes_gives_the_nugget_before_the_fight_then_the_same_fight_and_he_leaves() -> void:
	await _start(MemoryFs.new(), true)
	var map := _boot.get_map()
	var recruiter := map.get_npc(RECRUITER)
	assert_not_null(recruiter, "le recruteur est là")
	assert_eq(GameState.bag.count_of(&"nugget"), 0)
	await _meet(true)
	assert_true(_has_all(WELCOME), "n° 48")
	assert_true(_pages.has("%s reçoit une PÉPITE !" % GameState.player_name), "n° 49 : %s" % [_pages])
	assert_true(_has_all(OFFER), "n° 50")
	assert_eq(_asked_choice, 1, "un choix OUI / NON")
	assert_true(_has_all(YES), "n° 51 (OUI)")
	assert_false(_pages.has(NO[0]), "pas n° 52")
	assert_eq(_battle_seen_with_nuggets, 1, "la Pépite est au Sac avant le combat")
	assert_eq(_nuggets_at_page[WELCOME[1]], 0, "avant la remise : rien au Sac")
	assert_true(GameState.flags.has_flag(&"got_nugget"))
	assert_true(GameState.flags.has_flag(&"nugget_rocket_yes"))
	assert_true(GameState.flags.has_flag(&"beaten_nugget_rocket"), "victoire")
	assert_true(_has_all(BEATEN), "n° 53")
	assert_false(_pages.has(LOST[0]))
	assert_eq(GameState.bag.count_of(&"nugget"), 1, "une seule Pépite")
	assert_null(_boot.get_map().get_npc(RECRUITER), "il est parti")
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_gt(_pages.find(OFFER[0]), _pages.find(WELCOME[0]), "ordre des répliques")
	assert_lt(_pages.find(OFFER[2]), _pages.find(YES[0]))
	assert_lt(_pages.find(YES[1]), _pages.find(BEATEN[0]))
	# Rechargé : absent, plus de scène, une seule Pépite.
	await SceneRouter.change_map(&"route_24", &"bridge_top", Vector2i.UP)
	await wait_process_frames(3)
	assert_null(_boot.get_map().get_npc(RECRUITER), "absent au rechargement")
	_reset_log()
	await _goto(Vector2i(33, 18))
	assert_false(_boot.get_cutscene_director().is_running(), "la voie nord est ouverte")
	assert_eq(_player.get_cell(), Vector2i(33, 18))
	assert_eq(_started.size(), 0)
	assert_eq(GameState.bag.count_of(&"nugget"), 1)
	assert_push_error_count(0)


func test_no_leads_to_the_same_fight_with_its_own_line_and_no_consequence() -> void:
	await _start(MemoryFs.new(), true)
	await _meet(false)
	assert_true(_has_all(OFFER))
	assert_eq(_asked_choice, 1)
	assert_true(_has_all(NO), "n° 52 (NON)")
	assert_false(_pages.has(YES[0]), "pas n° 51")
	assert_false(GameState.flags.has_flag(&"nugget_rocket_yes"), "NON ne lève rien")
	assert_eq(_battle_seen_with_nuggets, 1, "la Pépite est au Sac avant le combat")
	assert_true(GameState.flags.has_flag(&"beaten_nugget_rocket"), "même combat, même issue")
	assert_true(_has_all(BEATEN))
	assert_eq(GameState.bag.count_of(&"nugget"), 1)
	assert_push_error_count(0)


func test_a_defeat_keeps_the_nugget_and_the_return_has_no_offer_nor_second_nugget() -> void:
	await _start(MemoryFs.new(), false)
	await _meet(true)
	assert_true(_has_all(LOST), "n° 54")
	assert_false(GameState.flags.has_flag(&"beaten_nugget_rocket"))
	assert_true(GameState.flags.has_flag(&"got_nugget"))
	assert_eq(GameState.bag.count_of(&"nugget"), 1, "Pépite gardée, jamais reprise")
	assert_eq(_boot.get_map().map_id, &"cerulean_center", "réveil au Centre d'Azuria")
	# Retour, plus fort : n° 55, ni remise, ni proposition, ni choix.
	_set_team(true)
	_reset_log()
	await SceneRouter.change_map(&"route_24", &"bridge_top", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	assert_not_null(_boot.get_map().get_npc(RECRUITER), "il attend toujours")
	await _meet(false)
	assert_true(_has_all(RESUME), "n° 55")
	assert_false(_pages.has(WELCOME[0]), "pas de félicitations")
	assert_false(_pages.has(OFFER[0]), "pas de proposition")
	assert_eq(_asked_choice, 0, "aucun choix")
	assert_eq(GameState.bag.count_of(&"nugget"), 1, "jamais deux Pépites")
	assert_true(GameState.flags.has_flag(&"beaten_nugget_rocket"), "même combat, victoire")
	assert_true(_has_all(BEATEN))
	assert_null(_boot.get_map().get_npc(RECRUITER))
	assert_push_error_count(0)


func test_talking_to_him_replays_the_scene_only_while_he_is_there() -> void:
	await _start(MemoryFs.new(), true)
	var recruiter := _boot.get_map().get_npc(RECRUITER)
	var spec := recruiter.get_spec()
	assert_eq(spec.dialogue, &"nugget_rocket")
	assert_true(spec.unless_flags.has(&"beaten_nugget_rocket"), "absent une fois battu")
	assert_eq(spec.facing, Vector2i.DOWN)
	assert_false(spec.trainer_id != &"", "ce n'est pas un Dresseur de vue : la scène le mène")
