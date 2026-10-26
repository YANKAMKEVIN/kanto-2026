extends GutTest
## Giovanni Champion de l'Arène de Jadielle de bout en bout (jalon 28, `docs/tech/jalon-28.md` §2.2,
## §3, §5 ; modèle : `test_erika_flow.gd`) avec la vraie scène Boot, la vraie carte `viridian_gym`
## et ses PNJ, la vraie scène `viridian_gym_giovanni`, les vraies données (Dresseur, carte, badge,
## CT27), les vraies entrées, l'autoload SceneRouter (fondus raccourcis), le combat instantané :
## - données : équipe RB 45 / 42 / 44 / 45 / 50, IA `smart`, 4 950 ₽, carte « GIOVANNI », Rhinoféros
##   avec Abîme, textes T28-04 à T28-08 et T28-35, T28-36 ;
## - victoire : introduction (T28-04) → carte → combat → T28-06 → « BADGE TERRE » → badge → T28-07
##   → CT27 → départ (T28-08) ; drapeaux, CT27 au Sac, argent, Giovanni retiré (aussi après
##   rechargement de la carte), aucune scène de la Route 22 ni changement de carte ;
## - défaite : réveil au Centre de Jadielle, `giovanni_gym_met` posé, pas de badge ; retour, reprise
##   (T28-05) sans introduction ni carte, puis la victoire ;
## - partie avec le Badge Terre mais sans CT27 : rattrapage (`viridian_gym_giovanni_tm_late`).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/viridian_gym_giovanni.json"
const SAVE_PATH := "user://test_giovanni_gym_save.json"
const GYM := &"viridian_gym"
const DATE := "2026-10-22T18:00:00"
const FADE := 0.05
const SCENE_TIMEOUT_MS := 120000
const TALK_CELL := Vector2i(4, 4)
const GIOVANNI_CELL := Vector2i(4, 3)
const INTRO: Array[String] = ["Te voilà.", "C'est ici que tout a commencé pour moi.",
	"Ici, je ne suis pas le chef de la Team Rocket. Je suis le Champion de Jadielle."]
const RESUME: Array[String] = ["Encore toi.",
	"Montre-moi que la première fois n'était pas un hasard."]
const LOST_LINES: Array[String] = ["Tu n'es pas encore à la hauteur.", "Reviens quand tu le seras."]
const WON: Array[String] = ["… Ta force est réelle.", "Ce Badge Terre te revient."]
const BADGE_LINE := "Kevin reçoit le Badge Terre !"
const TM_LINES: Array[String] = ["Prends aussi la CT27, Abîme.",
	"Une fissure dans le sol, et le combat est fini."]
const TM_GOT := "Kevin reçoit la CT27 Abîme !"
const DEPARTURE: Array[String] = ["La Team Rocket, c'est terminé. Je pars m'entraîner seul.",
	"Un jour, peut-être, nos chemins se croiseront encore."]
const CARD := "card:GIOVANNI/Champion d'Arène de Jadielle"

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
## Ce qui s'est passé, dans l'ordre : « page:<texte> », « card:<nom>/<titre> », « battle »,
## « caption:<texte> », « toast:<titre> / <détail> ».
var _events: Array[String] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_events.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"interact"]:
		Input.action_release(action)


## Boot dans l'Arène, devant Giovanni (spawn `before_giovanni`, tourné ↑), partie du départ
## `viridian_gym_giovanni` sans `giovanni_gym_met` (première rencontre) ; [param strong] : Tortank
## Nv. 100 qui ne connaît que Surf.
func _start(strong: bool = false) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = GYM
	_boot.start_spawn = &"before_giovanni"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	GameState.player_name = "Kevin"
	GameState.flags.set_flag(&"giovanni_gym_met", false)
	GameState.rng = GameRng.new(7)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_director().battle_started.connect(func(_id: StringName) -> void:
		_events.append("battle"))
	if strong:
		_make_strong()
	await wait_process_frames(2)
	# Les PNJ sont posés selon les drapeaux au chargement de la carte : on la recharge.
	await SceneRouter.change_map(GYM, &"before_giovanni", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	assert_eq(_boot.get_map().map_id, GYM)
	assert_eq(_player.get_cell(), TALK_CELL)
	assert_not_null(_boot.get_map().get_npc(&"giovanni"), "Giovanni est là")


func _make_strong() -> void:
	var champion := PokemonFactory.create(_boot.get_pokemon_data(), &"blastoise", 100,
		GameState.rng)
	champion.moves.clear()
	champion.moves.append(MoveSlot.new(&"surf", 15))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(champion)


func _make_weak() -> void:
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 5,
		GameState.rng))


## Lui parle (bouton d'interaction, tourné ↑) et déroule tout : pages, carte, combat piloté, légende,
## toast, réveil éventuel. Vrai si un combat a eu lieu.
func _talk_to_giovanni() -> bool:
	_player.face(Vector2i.UP)
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var hud := _boot.get_hud()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var toast := hud.get_toast()
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var card_seen := false
	var caption_seen := false
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
		var card := hud.get_champion_card()
		if card.is_showing() and not card_seen:
			_events.append("card:%s/%s" % [card.get_name_text(), card.get_title_text()])
			card.skip_hold()
		card_seen = card.is_showing()
		var caption := hud.get_caption()
		if caption.is_showing() and not caption_seen:
			_events.append("caption:" + caption.text)
		caption_seen = caption.is_showing()
		if toast.visible:
			var shown := "toast:%s / %s" % [toast.get_title_text(), toast.get_detail_text()]
			if _events.is_empty() or _events.back() != shown:
				_events.append(shown)
		await wait_process_frames(1)
		if box.is_open():
			var page := "page:" + box.get_text().replace("\n", " ")
			if _events.is_empty() or _events.back() != page:
				_events.append(page)
			box.advance_requested.emit()
	await wait_process_frames(3)
	return _events.has("battle")


func _index(event: String) -> int:
	return _events.find(event)


func _pages() -> Array[String]:
	var found: Array[String] = []
	for event: String in _events:
		if event.begins_with("page:"):
			found.append(event.trim_prefix("page:"))
	return found


func _badge_moments() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for moment: Dictionary in GameState.moments:
		if moment.get("type", "") == String(BadgeMoment.TYPE):
			found.append(moment)
	return found


# --- Données ----------------------------------------------------------------------------------

func test_giovanni_data_and_texts_match_the_validated_lot() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var trainer := library.get_trainer(&"viridian_gym_giovanni")
	assert_not_null(trainer)
	assert_eq(trainer.ai, BattleAI.SMART)
	assert_true(trainer.can_switch, "il change de Pokémon")
	assert_eq(trainer.prize_money, 4950, "99 × niveau final (50)")
	assert_eq([trainer.card_name, trainer.card_title], ["GIOVANNI", "Champion d'Arène de Jadielle"])
	var team := library.build_team(&"viridian_gym_giovanni", &"charmander", GameRng.new(1))
	assert_eq(team.get_all().map(func(p: Pokemon) -> Array: return [p.species_id, p.level]),
		[[&"rhyhorn", 45], [&"dugtrio", 42], [&"nidoqueen", 44], [&"nidoking", 45],
		[&"rhydon", 50]], "équipe RB : Rhinocorne 45, Triopikeur 42, Nidoqueen 44, Nidoking 45, Rhinoféros 50")
	var rhydon: Pokemon = team.get_all()[4]
	assert_true(rhydon.moves.any(func(m: MoveSlot) -> bool: return m.move_id == &"fissure"),
		"Abîme sur Rhinoféros")
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), "\n".join(dialogues.get_errors()))
	var expected: Dictionary[StringName, Array] = {
		&"viridian_gym_giovanni_intro": INTRO,
		&"viridian_gym_giovanni_resume": RESUME,
		&"viridian_gym_giovanni_lost": LOST_LINES,
		&"viridian_gym_giovanni_won": WON,
		&"viridian_gym_giovanni_badge": ["{player} reçoit le Badge Terre !"],
		&"viridian_gym_giovanni_tm": TM_LINES,
		&"viridian_gym_giovanni_tm_got": ["{player} reçoit la CT27 Abîme !"],
		&"viridian_gym_giovanni_departure": DEPARTURE,
	}
	for id: StringName in expected:
		var dialogue := dialogues.get_dialogue(id)
		assert_not_null(dialogue, String(id))
		if dialogue == null:
			continue
		var texts: Array = []
		for page: DialoguePage in dialogue.variants[0].pages:
			texts.append(page.text.replace("\n", " "))
		assert_eq(texts, expected[id], "texte validé : %s" % id)
		assert_eq(dialogue.speaker, "Giovanni")


func test_giovanni_waits_in_front_of_the_player() -> void:
	await _start()
	var giovanni := _boot.get_map().get_npc(&"giovanni")
	assert_eq(giovanni.get_cell(), GIOVANNI_CELL)
	assert_eq(giovanni.get_spec().sprite, &"giovanni")
	assert_eq(_player.get_facing(), Vector2i.UP)
	assert_false(GameState.flags.has_flag(&"giovanni_gym_met"))


# --- Victoire ---------------------------------------------------------------------------------

func test_victory_badge_tm_departure_and_giovanni_gone() -> void:
	await _start(true)
	var money := GameState.money
	assert_eq(GameState.bag.count_of(&"tm27"), 0)
	assert_true(await _talk_to_giovanni(), "le combat a eu lieu")
	var pages := _pages()
	for line: String in INTRO + WON + TM_LINES + DEPARTURE + [BADGE_LINE, TM_GOT]:
		assert_true(pages.has(line), "« %s » jouée" % line)
	for line: String in LOST_LINES + RESUME:
		assert_false(pages.has(line), "« %s » PAS jouée" % line)
	assert_eq(_index("page:" + INTRO[0]), 0, "l'introduction d'abord")
	var card := _index(CARD)
	assert_gt(card, _index("page:" + INTRO[2]), "la carte après l'introduction")
	assert_gt(_index("battle"), card, "la carte avant le combat")
	assert_gt(_index("page:" + WON[0]), _index("battle"), "T28-06 après le combat")
	assert_gt(_index("caption:BADGE TERRE"), _index("page:" + WON[1]), "légende ensuite")
	assert_gt(_index("page:" + BADGE_LINE), _index("caption:BADGE TERRE"))
	assert_gt(_index("page:" + TM_LINES[0]), _index("page:" + BADGE_LINE), "T28-07 ensuite")
	assert_gt(_index("page:" + TM_GOT), _index("page:" + TM_LINES[1]))
	assert_gt(_index("page:" + DEPARTURE[0]), _index("page:" + TM_GOT), "départ T28-08")
	assert_gt(_index("page:" + DEPARTURE[1]), _index("page:" + DEPARTURE[0]))
	assert_gt(_index("toast:CT27 — Abîme / obtenue"), _index("page:" + TM_LINES[1]), "le toast")
	assert_true(GameState.flags.has_flag(&"giovanni_gym_met"))
	assert_true(GameState.flags.has_flag(&"badge_earth"))
	assert_true(GameState.flags.has_flag(&"tm27_received"))
	assert_eq(GameState.bag.count_of(&"tm27"), 1, "CT27 au Sac")
	assert_eq(GameState.money, money + 4950)
	assert_null(_boot.get_map().get_npc(&"giovanni"), "Giovanni a quitté l'Arène")
	assert_eq(_badge_moments().size(), 1, "Grand moment « badge »")
	assert_eq(_boot.get_map().map_id, GYM, "aucun changement de carte automatique")
	assert_false(_boot.get_cutscene_director().is_running(), "aucune scène en cours")
	assert_true(_player.is_input_enabled(), "joueur libre")
	# Rechargement de la carte : Giovanni reste absent (seul `tm27_received` le retire).
	await SceneRouter.change_map(GYM, &"entrance", Vector2i.UP)
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, GYM)
	assert_null(_boot.get_map().get_npc(&"giovanni"), "toujours absent après rechargement")
	assert_eq(GameState.bag.count_of(&"tm27"), 1)
	assert_false(_boot.get_cutscene_director().is_running(), "aucune scène de la Route 22")
	assert_push_error_count(0)


## Point non vu en QA téléphone (2026-10-25) : Giovanni absent quand on REVIENT dans l'Arène,
## c'est-à-dire après en être sorti vers Jadielle (porte de la ville, `from_gym`) puis être rentré
## par la porte (`entrance`) : l'Arène est vide, sans scène, et le drapeau est dans la sauvegarde.
func test_giovanni_stays_gone_after_going_out_to_viridian_and_back_in() -> void:
	await _start(true)
	assert_true(await _talk_to_giovanni(), "le combat a eu lieu")
	assert_true(GameState.flags.has_flag(&"tm27_received"))
	await SceneRouter.change_map(&"viridian_city", &"from_gym", Vector2i.DOWN)
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, &"viridian_city", "sorti à Jadielle")
	await SceneRouter.change_map(GYM, &"entrance", Vector2i.UP)
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, GYM, "revenu dans l'Arène")
	assert_null(_boot.get_map().get_npc(&"giovanni"), "Giovanni absent au retour")
	assert_false(_boot.get_cutscene_director().is_running(), "aucune scène au retour")
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_true(JSON.stringify(GameState.to_dict()).contains("tm27_received"), "drapeau sauvegardé")
	assert_push_error_count(0)


# --- Défaite et reprise -----------------------------------------------------------------------

func test_defeat_wakes_at_the_center_then_retry_without_introduction_nor_card() -> void:
	await _start()
	_make_weak()
	GameState.heal_map = &"viridian_center"
	GameState.heal_spawn = &"heal"
	var money := GameState.money
	assert_true(await _talk_to_giovanni(), "le combat a eu lieu")
	var pages := _pages()
	for line: String in INTRO + LOST_LINES:
		assert_true(pages.has(line), "« %s » jouée" % line)
	assert_gt(_index("page:" + LOST_LINES[0]), _index("battle"), "défaite après le combat")
	assert_gt(_index(CARD), -1, "carte à la première rencontre")
	for line: String in WON + [BADGE_LINE]:
		assert_false(pages.has(line), "« %s » PAS jouée" % line)
	assert_eq(_index("caption:BADGE TERRE"), -1, "pas de badge")
	assert_true(GameState.flags.has_flag(&"giovanni_gym_met"), "première rencontre mémorisée")
	assert_false(GameState.flags.has_flag(&"badge_earth"))
	assert_false(GameState.flags.has_flag(&"tm27_received"))
	assert_eq(GameState.bag.count_of(&"tm27"), 0)
	assert_true(_badge_moments().is_empty())
	assert_eq(GameState.money, money, "aucun argent perdu")
	assert_eq(_boot.get_map().map_id, &"viridian_center", "réveil au Centre de Jadielle")
	var lead := GameState.party.get_lead()
	assert_eq(lead.hp, lead.max_hp(), "soigné")
	# Retour, mieux préparé : T28-05, pas d'introduction, pas de carte, la victoire.
	await SceneRouter.change_map(GYM, &"before_giovanni", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	assert_not_null(_boot.get_map().get_npc(&"giovanni"), "Giovanni toujours là")
	_make_strong()
	_events.clear()
	assert_true(await _talk_to_giovanni(), "second combat")
	pages = _pages()
	assert_eq(pages.slice(0, 2), RESUME, "reprise courte (T28-05) en premier")
	for line: String in INTRO:
		assert_false(pages.has(line), "« %s » PAS rejouée" % line)
	assert_eq(_index(CARD), -1, "pas de carte aux reprises")
	assert_gt(_index("caption:BADGE TERRE"), _index("battle"))
	assert_true(GameState.flags.has_flag(&"badge_earth"))
	assert_true(GameState.flags.has_flag(&"tm27_received"))
	assert_eq(_badge_moments().size(), 1)
	assert_eq(GameState.bag.count_of(&"tm27"), 1)
	assert_eq(GameState.money, money + 4950)
	assert_null(_boot.get_map().get_npc(&"giovanni"))
	assert_push_error_count(0)


# --- Rattrapage -------------------------------------------------------------------------------

func test_a_badged_game_without_the_tm_gets_it_once_then_giovanni_leaves() -> void:
	await _start()
	GameState.flags.set_flag(&"giovanni_gym_met")
	GameState.flags.set_flag(&"badge_earth")
	assert_false(GameState.flags.has_flag(&"tm27_received"))
	# Giovanni est encore là : seul `tm27_received` le retire.
	await SceneRouter.change_map(GYM, &"before_giovanni", Vector2i.UP)
	await wait_process_frames(3)
	assert_not_null(_boot.get_map().get_npc(&"giovanni"), "Giovanni présent sans la CT27")
	_player.face(Vector2i.UP)
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	assert_eq(director.get_cutscene_id(), &"viridian_gym_giovanni_tm_late")
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while director.is_running() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_open():
			var page := "page:" + box.get_text().replace("\n", " ")
			if _events.is_empty() or _events.back() != page:
				_events.append(page)
			box.advance_requested.emit()
	await wait_process_frames(3)
	assert_eq(_events, ["page:" + TM_LINES[0], "page:" + TM_LINES[1], "page:" + TM_GOT,
		"page:" + DEPARTURE[0], "page:" + DEPARTURE[1]] as Array[String])
	assert_eq(GameState.bag.count_of(&"tm27"), 1)
	assert_true(GameState.flags.has_flag(&"tm27_received"))
	assert_null(_boot.get_map().get_npc(&"giovanni"), "il part")
	assert_false(director.is_running())
	assert_eq(_boot.get_map().map_id, GYM)
	await SceneRouter.change_map(GYM, &"entrance", Vector2i.UP)
	await wait_process_frames(3)
	assert_null(_boot.get_map().get_npc(&"giovanni"), "absent après rechargement")
	assert_eq(GameState.bag.count_of(&"tm27"), 1, "une seule CT27")
	assert_push_error_count(0)
