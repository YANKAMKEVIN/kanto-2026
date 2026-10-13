extends GutTest
## Rival n° 3 sur la Route 24 (jalon 13 T19, jalon-13.md §2.7, §2.8 ; dossier 16 §7, §19 ; textes
## n° 28 à 32), avec la vraie scène Boot, la vraie carte, la vraie scène `route_24_rival`, l'autoload
## SceneRouter (fondus raccourcis), le combat instantané et une sauvegarde en mémoire :
## - la vue est inévitable (aucun chemin du couloir d'Azuria à la place du pont hors de ses cases) ;
## - l'équipe selon le starter (Roucoups 18, Rattata 15, évolution 17), IA `smart` avec `switch`,
##   595 ₽, `moment: "win"` ;
## - première rencontre : « ! », il vient au joueur, n° 28 puis combat ; défaite → n° 29, réveil au
##   dernier Centre, rival toujours là, aucun argent perdu ; retour → n° 30 sans introduction ;
##   deuxième défaite puis retour → n° 31 ; victoire → n° 32, départ, absent au rechargement ;
##   **exactement un** Grand moment « rival », issue « win ».

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/rival_cerulean.json"
const WEAK_START := "res://tools/debug_start/rival_cerulean_weak.json"
const SAVE_PATH := "user://test_rival_cerulean_save.json"
const DATE := "2026-10-13T18:00:00"
const FADE := 0.05
const TIMEOUT_MS := 8000
const SCENE_TIMEOUT_MS := 120000
const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
const FOOT := Vector2i(32, 61)
const ROW_BELOW := Vector2i(32, 56)
const TRIGGER_ROW := 55
const MAP_SIZE := Vector2i(56, 62)
const BRIDGE_HEAD := Vector2i(32, 44)
const INTRO: Array[String] = [
	"Te voilà.", "Le pont ? Déjà fait. Cinq combats, cinq victoires.",
	"Mais toi, tu ne passeras pas sans me battre.", "Montre-moi ce que la montagne t'a appris.",
]
const LOST_LINES: Array[String] = ["Pas encore assez.", "Va te soigner. Je ne bouge pas d'ici."]
const RESUME: Array[String] = ["Te revoilà.", "Allez. On recommence."]
const RESUME_AGAIN: Array[String] = [
	"Encore toi.", "Tant mieux. J'aime pas gagner trop facilement.",
]
const WIN_LINES: Array[String] = [
	"…Encore.", "Tu me rattrapes, hein.",
	"Profite. La prochaine fois, tu ne me trouveras pas sur ton chemin… tu me trouveras devant.",
]
const RIVAL_ID := &"rival_cerulean"

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []
var _emotes: Array[StringName] = []
var _rival_cell_at_first_page := Vector2i(-1, -1)
var _player_cell_at_first_page := Vector2i(-1, -1)


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_pages.clear()
	_emotes.clear()
	_rival_cell_at_first_page = Vector2i(-1, -1)
	_player_cell_at_first_page = Vector2i(-1, -1)


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)


## Boot (sauvegarde en mémoire), partie de [param start_path], puis arrivée sur la Route 24 au
## bas du couloir (comme Boot). [param strong] : starter remplacé par un Salamèche Nv. 60.
func _start(start_path: String, strong: bool = false) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"cerulean_city"
	_boot.start_spawn = &"from_route_24_c"
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(start_path, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	GameState.rng = GameRng.new(7)
	if strong:
		_make_strong()
	await wait_process_frames(2)
	await SceneRouter.change_map(&"route_24", &"from_cerulean_c", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	assert_eq(_boot.get_map().map_id, &"route_24")
	assert_eq(_player.get_cell(), FOOT)


func _make_strong() -> void:
	var champion := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 60,
		GameState.rng)
	champion.moves.clear()
	champion.moves.append(MoveSlot.new(&"ember", 25))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(champion)


func _make_weak() -> void:
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 5,
		GameState.rng))


## Retour sur la Route 24 (au bas du couloir) après un réveil.
func _back_to_route() -> void:
	await SceneRouter.change_map(&"route_24", &"from_cerulean_c", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	_pages.clear()
	_emotes.clear()


func _step_into_view() -> void:
	await _walk_to(ROW_BELOW)
	await _walk_to(Vector2i(_player.get_cell().x, TRIGGER_ROW))
	await wait_process_frames(2)


## Déroule la scène (et ce qui s'enchaîne) : pages avancées, combat piloté (ATTAQUER, 1re
## capacité). Vrai si un combat a eu lieu.
func _play_through() -> bool:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var seen_battle := false
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
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
			if _pages.is_empty():
				var rival := _boot.get_map().get_npc(RIVAL_ID)
				if rival != null:
					_rival_cell_at_first_page = rival.get_cell()
				_player_cell_at_first_page = _player.get_cell()
			if _pages.is_empty() or _pages.back() != text:
				_pages.append(text)
			box.advance_requested.emit()
	await wait_process_frames(3)
	return seen_battle


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


func _rival_moments() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for moment: Dictionary in GameState.moments:
		if moment.get("type", "") == String(GameState.MOMENT_RIVAL_BATTLE) \
				and (moment.get("details", {}) as Dictionary).get("trainer") == "rival_cerulean":
			found.append(moment)
	return found


func _assert_lines(lines: Array[String], present: bool, label: String) -> void:
	for line: String in lines:
		assert_eq(_pages.has(line), present, "« %s » %s (%s)" % [
			line, "jouée" if present else "PAS jouée", label])


# --- Données ----------------------------------------------------------------------------------

func test_the_team_follows_the_starter_and_the_trainer_is_smart_with_switch() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var trainer := library.get_trainer(RIVAL_ID)
	assert_not_null(trainer)
	assert_eq(trainer.ai, BattleAI.SMART)
	assert_true(trainer.can_switch, "il change de Pokémon (T12)")
	assert_true(trainer.moment_on_win, "Grand moment à la victoire seulement")
	assert_false(trainer.can_lose)
	assert_eq(trainer.prize_per_level, 35)
	var expected: Dictionary[StringName, StringName] = {
		&"bulbasaur": &"charmeleon", &"charmander": &"wartortle", &"squirtle": &"ivysaur",
	}
	for starter: StringName in expected:
		var team := library.build_team(RIVAL_ID, starter, GameRng.new(1))
		assert_not_null(team, "équipe contre %s" % starter)
		if team == null:
			continue
		var all := team.get_all()
		assert_eq(all.size(), 3, "trois Pokémon, pas d'Abra (D-6)")
		assert_eq([all[0].species_id, all[0].level], [&"pidgeotto", 18])
		assert_eq([all[1].species_id, all[1].level], [&"rattata", 15])
		assert_eq([all[2].species_id, all[2].level], [expected[starter], 17])
		assert_true(all.all(func(p: Pokemon) -> bool: return p.species_id != &"abra"))
		assert_eq(trainer.prize_per_level * all[all.size() - 1].level, 595, "35 × 17")


## Le changement de Pokémon (T12) joué avec les vraies données : Roucoups craint l'Électrik, le
## premier de l'équipe sans faiblesse (Rattata) le remplace avant que les capacités soient jouées.
func test_the_rival_recalls_a_pokemon_weak_to_the_lead_for_the_next_one() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir())
	var items := ItemLibrary.new()
	items.load_dir()
	var trainer := library.get_trainer(RIVAL_ID)
	var rng := GameRng.new(3)
	var lead := PokemonFactory.create(data, &"pikachu", 30, rng)
	lead.moves.clear()
	lead.moves.append(MoveSlot.new(&"thunder_shock", 30))
	var party := Party.new()
	party.add(lead)
	var foes := library.build_team(RIVAL_ID, &"charmander", rng)
	var battle := Battle.new(BattleSide.new(party, true),
		BattleSide.new(foes, false, trainer.name, trainer.make_ai()), data, rng,
		BattleRules.for_trainer(trainer, items))
	battle.start()
	var events := battle.submit(BattleAction.move(0))
	var kinds: Array = events.map(func(e: BattleEvent) -> int: return e.kind)
	var withdrawn := kinds.find(BattleEvent.Kind.WITHDRAWN)
	assert_gt(withdrawn, -1, "il rappelle Roucoups")
	if withdrawn > -1:
		assert_eq(events[withdrawn].side, BattleEvent.SideId.FOE)
		assert_eq(events[withdrawn].pokemon_name, "Roucoups")
		assert_eq(kinds[withdrawn + 1], BattleEvent.Kind.SENT_OUT)
		assert_eq(events[withdrawn + 1].pokemon_name, "Rattata")
	assert_eq(kinds.count(BattleEvent.Kind.WITHDRAWN), 1, "une seule fois")


# --- Vue inévitable ---------------------------------------------------------------------------

func test_the_view_covers_the_whole_corridor_and_no_path_avoids_it() -> void:
	await _start(START)
	var map := _boot.get_map()
	var cells: Array[Vector2i] = []
	for trigger: EventTrigger in map.get_triggers().get_all():
		if trigger.cutscene_id == &"route_24_rival":
			cells.append(trigger.cell)
			assert_eq(trigger.direction, Vector2i.ZERO, "toutes directions")
	cells.sort()
	assert_eq(cells, [Vector2i(31, 55), Vector2i(32, 55), Vector2i(33, 55), Vector2i(34, 55),
		Vector2i(35, 55)] as Array[Vector2i], "la vue du rival (5 cases de la rangée 55)")
	var terrain := GridPaths.relief(map.get_grid(), MAP_SIZE)
	var open := terrain.find_reachable(FOOT)
	assert_true(open.has(Vector2i(32, 56)), "le couloir est ouvert")
	assert_true(open.has(Vector2i(32, 54)), "sans le rival, le pont serait accessible")
	for cell: Vector2i in cells:
		terrain.set_solid(cell)
	open = terrain.find_reachable(FOOT)
	assert_false(open.has(Vector2i(32, 54)), "aucun chemin vers le pont hors de sa vue")
	assert_false(open.has(BRIDGE_HEAD))
	var rival := map.get_npc(RIVAL_ID)
	assert_not_null(rival)
	assert_eq(rival.get_cell(), Vector2i(36, 55))
	assert_eq(map.get_npc(&"misty_bridge").get_cell(), Vector2i(37, 46), "Ondine au-delà")
	assert_push_error_count(0)


# --- Première rencontre, défaites, reprises, victoire -----------------------------------------

func test_first_meeting_defeats_resumes_and_victory_with_a_single_moment() -> void:
	await _start(WEAK_START)
	GameState.heal_map = &"cerulean_center"
	GameState.heal_spawn = &"heal"
	var money := GameState.money
	var map := _boot.get_map()
	assert_not_null(map.get_npc(RIVAL_ID), "rival présent")
	# 1. Première rencontre, défaite.
	await _step_into_view()
	assert_true(_boot.get_cutscene_director().is_running(), "scène lancée par la vue")
	assert_true(await _play_through(), "le combat a eu lieu")
	_assert_lines(INTRO, true, "1re rencontre")
	assert_eq(_pages.find(INTRO[0]), 0, "elle commence par « Te voilà. »")
	_assert_lines(LOST_LINES, true, "défaite")
	_assert_lines(RESUME + RESUME_AGAIN + WIN_LINES, false, "1re rencontre")
	assert_false(GameState.flags.has_flag(&"rival_cerulean_won"))
	assert_true(GameState.flags.has_flag(&"rival_cerulean_lost_once"))
	assert_false(GameState.flags.has_flag(&"rival_cerulean_retried"))
	assert_eq(_boot.get_map().map_id, &"cerulean_center", "réveil au dernier Centre")
	assert_eq(GameState.money, money, "aucun argent perdu")
	for pokemon: Pokemon in GameState.party.get_all():
		assert_eq(pokemon.hp, pokemon.max_hp(), "équipe soignée")
	assert_true(_rival_moments().is_empty(), "aucun Grand moment pour une défaite")
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_false(_boot.get_cutscene_director().is_running(), "pas de suite après un réveil")
	# 2. Retour : il est toujours là, réplique de reprise courte (n° 30), seconde défaite.
	await _back_to_route()
	assert_not_null(_boot.get_map().get_npc(RIVAL_ID), "il reste à sa place")
	await _step_into_view()
	assert_true(await _play_through(), "second combat")
	_assert_lines(RESUME, true, "reprise")
	_assert_lines(INTRO + RESUME_AGAIN + WIN_LINES, false, "reprise")
	assert_eq(_pages.find(RESUME[0]), 0, "sans introduction")
	_assert_lines(LOST_LINES, true, "seconde défaite")
	assert_true(GameState.flags.has_flag(&"rival_cerulean_retried"), "la reprise est mémorisée")
	assert_true(_rival_moments().is_empty())
	# 3. Troisième passage : n° 31 (à partir du deuxième retour), puis victoire.
	await _back_to_route()
	_make_strong()
	await _step_into_view()
	var before := GameState.money
	assert_true(await _play_through(), "troisième combat")
	_assert_lines(RESUME_AGAIN, true, "reprise après une défaite déjà vécue")
	_assert_lines(INTRO + RESUME, false, "reprise après une défaite déjà vécue")
	_assert_lines(WIN_LINES, true, "victoire")
	_assert_lines(LOST_LINES, false, "victoire")
	assert_true(GameState.flags.has_flag(&"rival_cerulean_won"))
	assert_eq(GameState.money, before + 595, "35 × Nv. 17")
	var moments := _rival_moments()
	assert_eq(moments.size(), 1, "exactement un Grand moment")
	if moments.size() == 1:
		assert_eq(moments[0].get("map"), "route_24")
		assert_eq((moments[0].get("details", {}) as Dictionary).get("outcome"), "win")
	map = _boot.get_map()
	assert_eq(map.map_id, &"route_24", "on reste sur la Route 24")
	assert_null(map.get_npc(RIVAL_ID), "il est parti")
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_true((_saved().get("flags", []) as Array).has("rival_cerulean_won"), "sauvegardé")
	# Absent au rechargement, la vue ne lance plus rien.
	await _back_to_route()
	assert_null(_boot.get_map().get_npc(RIVAL_ID), "absent en revenant")
	await _step_into_view()
	assert_false(_boot.get_cutscene_director().is_running(), "aucune scène rejouée")
	assert_eq(_rival_moments().size(), 1)
	assert_push_error_count(0)


func test_the_rival_approaches_with_an_emote_and_leaves_toward_the_city() -> void:
	await _start(START, true)
	var director := _boot.get_cutscene_director()
	await _step_into_view()
	assert_true(director.is_running())
	assert_true(await _play_through())
	assert_eq(_player_cell_at_first_page, Vector2i(32, 55), "le joueur est ramené au centre")
	assert_eq(_rival_cell_at_first_page, Vector2i(33, 55), "il s'est approché, à côté du joueur")
	assert_true(GameState.flags.has_flag(&"rival_cerulean_won"))
	assert_null(_boot.get_map().get_npc(RIVAL_ID), "parti (fondu)")
	assert_push_error_count(0)


# --- Entrées ----------------------------------------------------------------------------------

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
