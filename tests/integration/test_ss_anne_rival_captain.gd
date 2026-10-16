extends GutTest
## Rival n° 4 et capitaine du S.S. Anne (jalon 16 T13, jalon-16.md §2.7, §2.8 ; dossier 19 §5,
## §6, textes validés §0.5 n° 16 à 24), avec la vraie scène Boot, les vraies cartes du couloir et
## de la cabine, les vraies scènes `ss_anne_rival` / `ss_anne_captain`, l'autoload SceneRouter
## (fondus raccourcis), le combat instantané et une sauvegarde en mémoire :
## - équipe selon le starter (Roucoups 17, Rattatac 15, Kadabra 16 Choc Mental + Rafale Psy,
##   starter évolué 18 avec l'avantage ; contre Bulbizarre 16 / 14 / 15 / 16 ; décision de
##   Kevin du 2026-10-16), IA `smart` avec `switch`, 35 ₽ × niveau, Grand moment
##   à la victoire ;
## - vue sur les 3 cases de la colonne 7, inévitable ; défaite → réveil au dernier Centre sans
##   perte d'argent, rival toujours là ; reprise sans introduction ; victoire → n° 19, départ vers
##   la sortie, **un seul** Grand moment, absent ensuite ;
## - capitaine : CAP-01, frottement du dos, CAP-02, CAP-03 et la CS01 **une fois**, `got_hm01`,
##   puis CAP-04 ; objectifs ;
## - arrêt brutal (Boot libéré, relancé sur la même sauvegarde) au milieu de chaque scène : rien
##   n'a été écrit pendant la scène, elle se rejoue entière, jamais d'objet doublé ; rattrapage
##   d'une sauvegarde incohérente (CS01 sans drapeau, drapeau sans CS01).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/ss_anne_rival.json"
const WEAK_START := "res://tools/debug_start/ss_anne_rival_weak.json"
const CAPTAIN_START := "res://tools/debug_start/ss_anne_captain.json"
const SAVE_PATH := "user://test_ss_anne_rival_captain_save.json"
const DATE := "2026-10-16T18:00:00"
const FADE := 0.05
const TIMEOUT_MS := 8000
const SCENE_TIMEOUT_MS := 120000
const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
const CORRIDOR := &"ss_anne_captain_corridor"
const ROOM := &"ss_anne_captain_room"
const ENTRANCE := Vector2i(2, 4)
const TRIGGER_COLUMN := 7
const CAPTAIN_DOOR := Vector2i(15, 1)
const TALK_CELL := Vector2i(8, 4)
const RIVAL_ID := &"rival_ss_anne"
const CAPTAIN_ID := &"ss_anne_captain"
const INTRO: Array[String] = [
	"Tiens. Toi aussi, tu as un billet.",
	"Le capitaine ? Il a le mal de mer. Il ne quitte plus sa cabine.",
	"Moi, j'ai déjà fait le tour du navire. Voyons si tu as avancé, toi aussi.",
]
const LOST_LINES: Array[String] = [
	"Tu vois ? Toujours une longueur d'avance.", "Va te soigner à Carmin. Je ne bouge pas.",
]
const RESUME: Array[String] = ["Déjà de retour ?", "Bien. Cette fois, ne me déçois pas."]
const WIN_LINES: Array[String] = [
	"…D'accord. Cette fois, je l'admets.", "Tu avances vite. Trop vite.",
	"Va voir ton capitaine. Moi, j'ai mieux à faire.",
]
const CAPTAIN_LINES: Array[String] = [
	"Ooh… ce roulis…", "Le capitaine qui a le mal de mer… C'est le comble.",
	"Tu lui frottes doucement le dos.", "Ah… merci. Ça va beaucoup mieux.",
	"Tiens, prends ça. C'est la CS01, Coupe.",
	"Avec elle, un Pokémon de ton équipe peut tailler les petits arbres. Il faut le Badge "
		+ "Cascade, par contre.",
	"Tu peux aussi la lui apprendre, comme une CT.",
]
const THANKS: Array[String] = ["Merci encore !", "Profite bien de la traversée."]

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []
var _toasts: Array[String] = []
var _rival_cell_at_first_page := Vector2i(-1, -1)
var _player_cell_at_first_page := Vector2i(-1, -1)


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_reset_capture()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)
	Input.action_release(&"interact")
	if is_instance_valid(_boot):
		_boot.free()


func _reset_capture() -> void:
	_pages.clear()
	_toasts.clear()
	_rival_cell_at_first_page = Vector2i(-1, -1)
	_player_cell_at_first_page = Vector2i(-1, -1)


# --- Mise en place ----------------------------------------------------------------------------

## Boot (sauvegarde en mémoire) ; [param start_path] vide = reprise de la sauvegarde existante
## (relance de l'appli). Sinon partie de [param start_path], arrivée sur [param map] /
## [param spawn] (autosave d'arrivée, comme en jeu).
func _launch(start_path: String, map: StringName = CORRIDOR, spawn: StringName = &"entrance",
		facing: Vector2i = Vector2i.UP) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"ss_anne_main_deck"
	_boot.start_spawn = &"from_corridor"
	add_child(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_battle_director().speed_scale = 0.0
	if not start_path.is_empty():
		var start := DebugStart.new()
		assert_true(start.load_file(start_path, _boot.get_pokemon_data(),
			_boot.get_item_library()), "\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
		GameState.rng = GameRng.new(7)
		GameState.heal_map = &"vermilion_center"
		GameState.heal_spawn = &"heal"
		await wait_process_frames(2)
		await SceneRouter.change_map(map, spawn, facing)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0


## Arrêt brutal : Boot disparaît sans rien écrire de plus (comme un processus tué).
func _kill() -> void:
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)
	_boot.free()
	_boot = null
	await wait_process_frames(2)


func _make_strong() -> void:
	var champion := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 60,
		GameState.rng)
	champion.moves.clear()
	champion.moves.append(MoveSlot.new(&"ember", 25))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(champion)


func _back_to_corridor() -> void:
	await SceneRouter.change_map(CORRIDOR, &"entrance", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	_reset_capture()


## Entre dans la vue du rival : vers l'est sur la rangée 4, jusqu'à la colonne 7.
func _step_into_view() -> void:
	await _walk_to(Vector2i(TRIGGER_COLUMN, ENTRANCE.y))
	await wait_process_frames(2)


## Déroule la scène en cours (pages avancées, combat piloté : ATTAQUER, 1re capacité).
## [param stop] (facultatif) : appelé à chaque image ; vrai = on s'arrête là (scène en cours).
## Vrai si un combat a eu lieu.
func _play_through(stop: Callable = Callable()) -> bool:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var toast := _boot.get_hud().get_toast()
	var seen_battle := false
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		if stop.is_valid() and stop.call():
			return seen_battle
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
		var shown := "%s / %s" % [toast.get_title_text(), toast.get_detail_text()]
		if toast.visible and not _toasts.has(shown):
			_toasts.append(shown)
		if box.is_open():
			var text := box.get_text()
			if _pages.is_empty():
				var rival := _boot.get_map().get_npc(RIVAL_ID)
				if rival != null:
					_rival_cell_at_first_page = rival.get_cell()
				_player_cell_at_first_page = _player.get_cell()
			if _pages.is_empty() or _pages.back() != text:
				_pages.append(text)
			if stop.is_valid() and stop.call():
				return seen_battle
			box.advance_requested.emit()
	await wait_process_frames(3)
	return seen_battle


## Parle au capitaine depuis la case devant lui (tourné ↑) et déroule tout.
func _talk_to_captain(stop: Callable = Callable()) -> void:
	assert_eq(_player.get_cell(), TALK_CELL, "devant le capitaine")
	_player.face(Vector2i.UP)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await _play_through(stop)


## Du seuil de la cabine à la case devant le capitaine.
func _walk_to_captain() -> void:
	await _walk_to(Vector2i(6, TALK_CELL.y))
	await _walk_to(TALK_CELL)


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
				and (moment.get("details", {}) as Dictionary).get("trainer") == "rival_ss_anne":
			found.append(moment)
	return found


func _assert_lines(lines: Array[String], present: bool, label: String) -> void:
	for line: String in lines:
		assert_eq(_pages.has(line), present, "« %s » %s (%s)" % [
			line, "jouée" if present else "PAS jouée", label])


func _objective() -> StringName:
	var library := ObjectiveLibrary.new()
	library.load_file()
	return library.current_id(GameState.flags)


# --- Données ----------------------------------------------------------------------------------

func test_the_team_follows_the_starter_with_kadabra_and_the_reference_levels() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var trainer := library.get_trainer(RIVAL_ID)
	assert_not_null(trainer)
	if trainer == null:
		return
	assert_eq(trainer.ai, BattleAI.SMART)
	assert_true(trainer.can_switch, "switch (R-19, Kevin)")
	assert_true(trainer.moment_on_win, "Grand moment à la victoire seulement")
	assert_false(trainer.can_lose)
	assert_eq(trainer.prize_per_level, 35)
	var expected: Dictionary[StringName, Array] = {
		&"bulbasaur": [&"charmeleon", [&"ember", &"scratch", &"growl"]],
		&"charmander": [&"wartortle", [&"water_gun", &"tackle", &"tail_whip"]],
		&"squirtle": [&"ivysaur", [&"vine_whip", &"tackle", &"growl"]],
	}
	for starter: StringName in expected:
		var team := library.build_team(RIVAL_ID, starter, GameRng.new(1))
		assert_not_null(team, "équipe contre %s" % starter)
		if team == null:
			continue
		var all := team.get_all()
		var species: Array = all.map(func(p: Pokemon) -> Array: return [p.species_id, p.level])
		var levels: Array = [16, 14, 15, 16] if starter == &"bulbasaur" else [17, 15, 16, 18]
		assert_eq(species, [[&"pidgeotto", levels[0]], [&"raticate", levels[1]],
			[&"kadabra", levels[2]], [expected[starter][0], levels[3]]],
			"ordre du dossier §5, niveaux de la décision de Kevin du 2026-10-16")
		var moves: Array = all.map(func(p: Pokemon) -> Array:
			return p.moves.map(func(m: MoveSlot) -> StringName: return m.move_id))
		assert_eq(moves[0], [&"gust", &"quick_attack", &"sand_attack"])
		assert_eq(moves[1], [&"quick_attack", &"bite", &"tail_whip"])
		assert_eq(moves[2], [&"confusion", &"psybeam"], "Kadabra : Choc Mental, Rafale Psy (R-12)")
		assert_eq(moves[3], expected[starter][1])
		for move_list: Array in moves:
			for move: StringName in move_list:
				assert_false([&"teleport", &"disable"].has(move), "Téléport et Entrave exclus")
		assert_eq(trainer.prize_per_level * all.back().level, 35 * levels[3])


# --- Carte : vue inévitable, PNJ --------------------------------------------------------------

func test_the_view_spans_the_corridor_and_the_rival_and_captain_are_placed() -> void:
	await _launch(START)
	var map := _boot.get_map()
	assert_eq(map.map_id, CORRIDOR)
	var cells: Array[Vector2i] = []
	for trigger: EventTrigger in map.get_triggers().get_all():
		if trigger.cutscene_id == &"ss_anne_rival":
			cells.append(trigger.cell)
			assert_eq(trigger.direction, Vector2i.ZERO, "toutes directions")
	cells.sort()
	assert_eq(cells, [Vector2i(7, 2), Vector2i(7, 3), Vector2i(7, 4)] as Array[Vector2i],
		"la colonne 7 entière")
	var terrain := GridPaths.relief(map.get_grid(), Vector2i(18, 7))
	for cell: Vector2i in cells:
		terrain.set_solid(cell)
	var open := terrain.find_reachable(ENTRANCE)
	assert_false(open.has(CAPTAIN_DOOR + Vector2i.DOWN), "aucun chemin vers le capitaine hors vue")
	var rival := map.get_npc(RIVAL_ID)
	assert_not_null(rival)
	if rival != null:
		assert_eq(rival.get_cell(), Vector2i(10, 3))
		assert_eq(rival.get_facing(), Vector2i.LEFT)
	await SceneRouter.change_map(ROOM, &"entrance", Vector2i.UP)
	await wait_process_frames(3)
	var captain := _boot.get_map().get_npc(CAPTAIN_ID)
	assert_not_null(captain, "capitaine malade avant la CS01")
	if captain != null:
		assert_eq(captain.get_cell(), Vector2i(8, 3))
		assert_eq(captain.get_facing(), Vector2i.UP, "penché sur son lavabo")
	assert_null(_boot.get_map().get_npc(&"ss_anne_captain_well"))
	assert_push_error_count(0)


# --- Rival : défaite, reprise, victoire -------------------------------------------------------

func test_defeat_resume_and_victory_with_a_single_moment() -> void:
	await _launch(WEAK_START)
	var money := GameState.money
	assert_not_null(_boot.get_map().get_npc(RIVAL_ID), "rival présent")
	# 1. Première rencontre, défaite.
	await _step_into_view()
	assert_true(_boot.get_cutscene_director().is_running(), "scène lancée par la vue")
	assert_true(await _play_through(), "le combat a eu lieu")
	assert_eq(_pages.find(INTRO[0]), 0, "elle commence par l'introduction")
	_assert_lines(INTRO + LOST_LINES, true, "1re rencontre, défaite")
	_assert_lines(RESUME + WIN_LINES, false, "1re rencontre")
	assert_true(GameState.flags.has_flag(&"rival_ss_anne_lost_once"))
	assert_false(GameState.flags.has_flag(&"rival_ss_anne_won"))
	assert_eq(_boot.get_map().map_id, &"vermilion_center", "réveil au dernier Centre")
	assert_eq(GameState.money, money, "aucun argent perdu")
	for pokemon: Pokemon in GameState.party.get_all():
		assert_eq(pokemon.hp, pokemon.max_hp(), "équipe soignée")
	assert_true(_rival_moments().is_empty(), "aucun Grand moment pour une défaite")
	assert_true(_player.is_input_enabled(), "joueur libre")
	# 2. Retour : il est toujours là ; reprise courte, sans introduction ; seconde défaite.
	await _back_to_corridor()
	assert_not_null(_boot.get_map().get_npc(RIVAL_ID), "il reste à sa place")
	await _step_into_view()
	assert_true(await _play_through(), "second combat")
	assert_eq(_pages.find(RESUME[0]), 0, "sans introduction")
	_assert_lines(RESUME + LOST_LINES, true, "reprise, défaite")
	_assert_lines(INTRO + WIN_LINES, false, "reprise")
	assert_true(_rival_moments().is_empty())
	# 3. Victoire.
	await _back_to_corridor()
	_make_strong()
	await _step_into_view()
	var before := GameState.money
	assert_true(await _play_through(), "troisième combat")
	_assert_lines(RESUME + WIN_LINES, true, "reprise, victoire")
	_assert_lines(INTRO + LOST_LINES, false, "victoire")
	assert_true(GameState.flags.has_flag(&"rival_ss_anne_won"))
	assert_eq(GameState.money, before + 630, "35 × Nv. 18 (décision de Kevin du 2026-10-16)")
	var moments := _rival_moments()
	assert_eq(moments.size(), 1, "exactement un Grand moment")
	if moments.size() == 1:
		assert_eq(moments[0].get("map"), String(CORRIDOR))
		assert_eq((moments[0].get("details", {}) as Dictionary).get("outcome"), "win")
	assert_eq(_boot.get_map().map_id, CORRIDOR, "on reste dans le couloir")
	assert_null(_boot.get_map().get_npc(RIVAL_ID), "il est parti")
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_true((_saved().get("flags", []) as Array).has("rival_ss_anne_won"), "sauvegardé")
	assert_eq(_objective(), &"help_captain", "objectif : aider le capitaine.")
	# Absent en revenant, la vue ne lance plus rien, aucun second Grand moment.
	await _back_to_corridor()
	assert_null(_boot.get_map().get_npc(RIVAL_ID), "absent en revenant")
	await _step_into_view()
	assert_false(_boot.get_cutscene_director().is_running(), "aucune scène rejouée")
	assert_eq(_rival_moments().size(), 1)
	await _walk_to(Vector2i(CAPTAIN_DOOR.x, ENTRANCE.y))
	await _walk_to(CAPTAIN_DOOR + Vector2i.DOWN)
	await _walk_to(CAPTAIN_DOOR)
	await wait_until(func() -> bool: return _boot.get_map().map_id == ROOM, 5.0)
	assert_eq(_boot.get_map().map_id, ROOM, "la cabine du capitaine s'ouvre")
	assert_push_error_count(0)


func test_the_rival_comes_to_the_player_then_leaves_toward_the_exit() -> void:
	await _launch(START)
	_make_strong()
	var rival := _boot.get_map().get_npc(RIVAL_ID)
	var walked: Array[Vector2i] = []
	rival.step_finished.connect(func(cell: Vector2i) -> void: walked.append(cell))
	await _step_into_view()
	assert_true(_boot.get_cutscene_director().is_running())
	assert_true(await _play_through())
	assert_eq(_player_cell_at_first_page, Vector2i(7, 3), "le joueur est ramené au centre")
	assert_eq(_rival_cell_at_first_page, Vector2i(8, 3), "il s'est approché, à côté du joueur")
	assert_true(walked.has(ENTRANCE), "il repart par la sortie du couloir")
	assert_null(_boot.get_map().get_npc(RIVAL_ID), "parti (fondu)")
	assert_push_error_count(0)


# --- Arrêt brutal pendant la scène du rival --------------------------------------------------

func test_closing_the_app_during_the_rival_scene_replays_it_whole() -> void:
	await _launch(START)
	var writes := _writes()
	assert_gt(writes, 0, "autosave d'arrivée dans le couloir")
	await _step_into_view()
	var box := _boot.get_dialogue_box()
	# Coupé à la deuxième page de l'introduction, scène en cours.
	await _play_through(func() -> bool: return box.is_open() and box.get_text() == INTRO[1])
	assert_true(_boot.get_cutscene_director().is_running(), "scène en cours")
	assert_eq(_writes(), writes, "rien n'est écrit pendant la scène")
	await _kill()
	# Relance : la partie reprend dans le couloir, avant la scène.
	await _launch("")
	assert_eq(_boot.get_map().map_id, CORRIDOR)
	assert_eq(_player.get_cell(), ENTRANCE)
	for flag: StringName in [&"rival_ss_anne_lost_once", &"rival_ss_anne_won"]:
		assert_false(GameState.flags.has_flag(flag), "%s jamais écrit" % flag)
	assert_not_null(_boot.get_map().get_npc(RIVAL_ID), "rival à sa place")
	_make_strong()
	await _step_into_view()
	assert_true(await _play_through(), "la scène se rejoue, combat compris")
	assert_eq(_pages.find(INTRO[0]), 0, "introduction rejouée")
	assert_true(GameState.flags.has_flag(&"rival_ss_anne_won"))
	assert_eq(_rival_moments().size(), 1, "un seul Grand moment")
	assert_push_error_count(0)


func test_closing_the_app_after_a_defeat_resumes_with_the_short_line() -> void:
	await _launch(WEAK_START)
	await _step_into_view()
	assert_true(await _play_through())
	assert_eq(_boot.get_map().map_id, &"vermilion_center")
	assert_true((_saved().get("flags", []) as Array).has("rival_ss_anne_lost_once"),
		"la défaite est écrite au réveil")
	await _kill()
	await _launch("")
	assert_eq(_boot.get_map().map_id, &"vermilion_center", "reprise au Centre")
	assert_true(GameState.flags.has_flag(&"rival_ss_anne_lost_once"))
	_make_strong()
	await _back_to_corridor()
	await _step_into_view()
	assert_true(await _play_through())
	assert_eq(_pages.find(RESUME[0]), 0, "reprise courte, sans introduction")
	_assert_lines(INTRO, false, "après la relance")
	assert_true(GameState.flags.has_flag(&"rival_ss_anne_won"))
	assert_push_error_count(0)


# --- Capitaine --------------------------------------------------------------------------------

func test_the_captain_gives_hm01_once_then_thanks() -> void:
	await _launch(CAPTAIN_START, ROOM)
	assert_eq(GameState.bag.count_of(&"hm01"), 0)
	assert_eq(_objective(), &"help_captain")
	await _walk_to_captain()
	await _talk_to_captain()
	assert_eq(_pages, CAPTAIN_LINES, "CAP-01, narration, CAP-02, CAP-03 (dossier §0.5)")
	assert_eq(GameState.bag.count_of(&"hm01"), 1, "une CS01")
	assert_true(GameState.flags.has_flag(&"got_hm01"))
	assert_eq(_toasts, ["CS01 — Coupe / obtenue"])
	var captain := _boot.get_map().get_npc(CAPTAIN_ID)
	assert_eq(captain.get_facing(), Vector2i.DOWN, "soulagé, tourné vers le joueur")
	assert_true((_saved().get("flags", []) as Array).has("got_hm01"), "sauvegardé")
	assert_eq(_objective(), &"go_vermilion_gym", "Badge Cascade déjà là : vers l'Arène")
	GameState.flags.set_flag(&"badge_cascade", false)
	assert_eq(_objective(), &"hm01_cascade_badge", "sans le Badge Cascade")
	GameState.flags.set_flag(&"badge_cascade")
	# Lui reparler : CAP-04, aucune seconde CS01.
	_reset_capture()
	await _talk_to_captain()
	assert_eq(_pages, THANKS)
	assert_false(_boot.get_cutscene_director().is_running())
	assert_eq(GameState.bag.count_of(&"hm01"), 1, "une seule CS01")
	# En revenant : le capitaine guéri se tourne vers le joueur et remercie.
	await SceneRouter.change_map(ROOM, &"entrance", Vector2i.UP)
	await wait_process_frames(3)
	assert_null(_boot.get_map().get_npc(CAPTAIN_ID))
	assert_not_null(_boot.get_map().get_npc(&"ss_anne_captain_well"))
	await _walk_to_captain()
	_reset_capture()
	await _talk_to_captain()
	assert_eq(_pages, THANKS)
	assert_eq(GameState.bag.count_of(&"hm01"), 1)
	assert_push_error_count(0)


func test_closing_the_app_after_the_gift_replays_the_scene_without_a_double() -> void:
	await _launch(CAPTAIN_START, ROOM)
	await _walk_to_captain()
	var writes := _writes()
	# Coupé juste après la remise (CS01 dans le Sac, drapeau pas encore levé).
	await _talk_to_captain(func() -> bool: return GameState.bag.count_of(&"hm01") == 1)
	assert_true(_boot.get_cutscene_director().is_running(), "scène en cours")
	assert_false(GameState.flags.has_flag(&"got_hm01"), "drapeau à la dernière étape")
	assert_eq(_writes(), writes, "rien n'est écrit pendant la scène")
	await _kill()
	await _launch("")
	assert_eq(_boot.get_map().map_id, ROOM)
	assert_eq(GameState.bag.count_of(&"hm01"), 0, "la CS01 n'avait pas été écrite")
	assert_false(GameState.flags.has_flag(&"got_hm01"))
	assert_not_null(_boot.get_map().get_npc(CAPTAIN_ID), "toujours malade")
	if _player.get_cell() != TALK_CELL:
		await _walk_to_captain()
	_reset_capture()
	await _talk_to_captain()
	assert_eq(_pages, CAPTAIN_LINES, "la scène se rejoue entière")
	assert_eq(GameState.bag.count_of(&"hm01"), 1, "une seule CS01")
	assert_true(GameState.flags.has_flag(&"got_hm01"))
	assert_push_error_count(0)


## Rattrapage (dossier §6) : une sauvegarde incohérente est corrigée au chargement, une fois.
func test_an_inconsistent_save_is_repaired_on_load() -> void:
	await _launch(CAPTAIN_START, ROOM)
	await _walk_to_captain()
	await _talk_to_captain()
	assert_true(GameState.flags.has_flag(&"got_hm01"))
	await _kill()
	# CS01 dans le Sac sans le drapeau → drapeau levé ; le capitaine ne redonne rien.
	var saved := _saved()
	var flags: Array = saved["flags"]
	flags.erase("got_hm01")
	_fs.files[SAVE_PATH] = JSON.stringify(saved)
	await _launch("")
	assert_true(GameState.flags.has_flag(&"got_hm01"), "drapeau rattrapé")
	assert_eq(GameState.bag.count_of(&"hm01"), 1)
	assert_not_null(_boot.get_map().get_npc(&"ss_anne_captain_well"), "le capitaine est guéri")
	await _kill()
	# Drapeau sans la CS01 → objet rendu une fois, pas deux.
	saved = _saved()
	var items: Dictionary = (saved["bag"] as Dictionary)["items"]
	items.erase("hm01")
	_fs.files[SAVE_PATH] = JSON.stringify(saved)
	await _launch("")
	assert_eq(GameState.bag.count_of(&"hm01"), 1, "CS01 rendue")
	await _kill()
	await _launch("")
	assert_eq(GameState.bag.count_of(&"hm01"), 1, "toujours une seule")
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
		if not is_instance_valid(_player):
			break
		var cell := _player.get_cell()
		if _player.is_moving() and cell + direction == goal:
			Input.action_release(action)
		if cell == goal and not _player.is_moving():
			break
		if not _player.is_input_enabled():
			break
		await wait_process_frames(1)
	Input.action_release(action)
	await wait_until(func() -> bool:
		return not is_instance_valid(_player) or not _player.is_moving(), 2.0)
