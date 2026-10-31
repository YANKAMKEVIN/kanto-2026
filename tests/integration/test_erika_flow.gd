extends GutTest
## Erika de bout en bout (jalon 20 T17, jalon-20.md §2.8 ; dossier 23 §11, §20.5 et annexe A.7 :
## textes n° 34 à 38 et 126 à 129) avec la vraie scène Boot, la vraie carte `celadon_gym` et ses
## PNJ, la vraie scène `celadon_gym_erika`, les vraies données (Dresseuse, carte, badge, CT21),
## les vraies entrées (`move_*`, `interact`), l'autoload SceneRouter (fondus raccourcis), le combat
## instantané et une sauvegarde en mémoire :
## - données : équipe retenue par Kevin (E-1 : Saquedeneu N24, Empiflor N27, Rafflesia N29),
##   IA `smart` avec changement de Pokémon, 2 871 ₽, carte « ERIKA » ;
## - victoire : introduction (34) → carte → combat → n° 35 → « BADGE PRISME » (une vibration
##   légère) → n° 36 → CT21 (n° 37, toast « CT21 — Méga-Sangsue / obtenue ») ; drapeaux `erika_met`,
##   `badge_rainbow`, `tm21_received`, 2 871 ₽, Grand moment « badge », sauvegarde ; ensuite n° 38 ;
## - défaite : n° 127, réveil au Centre de Céladopole (aucun argent perdu), Dresseuses battues
##   gardées ; nouvel essai : n° 128 sans introduction ni carte, puis la victoire ;
## - partie badgée sans CT : rattrapage (n° 129 puis 37), une seule fois.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/celadon_gym.json"
const SAVE_PATH := "user://test_erika_flow_save.json"
const GYM := &"celadon_gym"
const DATE := "2026-10-20T18:00:00"
const FADE := 0.05
const TIMEOUT_MS := 12000
const SCENE_TIMEOUT_MS := 120000
const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
const ENTRANCE := Vector2i(8, 14)
const ERIKA_CELL := Vector2i(8, 2)
const TALK_CELL := Vector2i(8, 3)
## Textes validés : dossier 23 §20.5 (n° 34 à 38) et annexe A.7 du plan (n° 126 à 129).
const INTRO: Array[String] = [
	"Oh… Bonjour. Je crois que je m'étais assoupie.",
	"Je suis Erika. Les plantes m'apprennent la patience.", "Voyons ce que tu as appris, toi.",
]
const LOST_LINES: Array[String] = ["Les plantes repoussent toujours.", "Reviens quand tu seras prêt."]
const RESUME: Array[String] = ["Te revoilà.", "Reprenons, sans nous presser."]
const WON := "Tu as gagné. Avec beaucoup d'élégance."
const BADGE_LINE := "Kevin reçoit le Badge Prisme !"
const TM_GIVE := "Prends aussi ceci."
const TM_USE: Array[String] = ["Kevin reçoit la CT21 Méga-Sangsue !",
	"Elle reprend des forces à l'adversaire."]
const TM_LATE := "Attends. J'ai oublié de te donner ceci."
const AFTER := "Reviens quand tu veux. Les fleurs changent à chaque saison."
const CARD := "card:ERIKA/Championne d'Arène de Céladopole"
const TRAINER_FLAGS: Array[StringName] = [
	&"beaten_celadon_gym_lass_lila", &"beaten_celadon_gym_lass_capucine",
	&"beaten_celadon_gym_beauty_violette", &"beaten_celadon_gym_jr_trainer_apolline",
	&"beaten_celadon_gym_cooltrainer_camelia",
]

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
## Ce qui s'est passé, dans l'ordre : « page:<texte> », « card:<nom>/<titre> », « battle »,
## « caption:<texte> », « toast:<titre> / <détail> ».
var _events: Array[String] = []
var _vibrations: Array[int] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_events.clear()
	_vibrations.clear()
	Haptics.sink = func(ms: int) -> void: _vibrations.append(ms)


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Haptics.reset()
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)
	Input.action_release(&"interact")


## Boot (sauvegarde en mémoire) dans l'Arène, à l'entrée, partie de [param start_path].
## [param strong] : starter remplacé par un Salamèche Nv. 60 (Flammèche).
func _start(start_path: String, strong: bool = false) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = GYM
	_boot.start_spawn = &"entrance"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(start_path, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	GameState.rng = GameRng.new(7)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_director().battle_started.connect(func(_id: StringName) -> void:
		_events.append("battle"))
	if strong:
		_make_strong()
	await wait_process_frames(2)
	# Les PNJ sont posés selon les drapeaux au chargement de la carte : on la recharge.
	await SceneRouter.change_map(GYM, &"entrance", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	assert_eq(_boot.get_map().map_id, GYM)
	assert_eq(_player.get_cell(), ENTRANCE)


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


## Les cinq Dresseuses de l'Arène battues : aucun défi ne coupe la marche (ils ont leurs propres
## tests).
func _beat_the_trainers() -> void:
	for flag: StringName in TRAINER_FLAGS:
		GameState.flags.set_flag(flag)


## Marche jusqu'à la case devant Erika par le chemin le plus court de la vraie grille.
func _walk_to_erika() -> void:
	var path := _boot.get_map().get_grid().find_path(_player.get_cell(), TALK_CELL, _player)
	assert_false(path.is_empty(), "un chemin mène devant Erika")
	var cell := _player.get_cell()
	for direction: Vector2i in path:
		cell += direction
		await _walk_to(cell)
	assert_eq(_player.get_cell(), TALK_CELL, "devant Erika")


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


## Lui parle (bouton d'interaction, tournée ↑) et déroule tout : pages, carte, combat piloté, légende,
## toast, réveil éventuel. Vrai si un combat a eu lieu.
func _talk_to_erika() -> bool:
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


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


func _objective() -> String:
	var objectives := ObjectiveLibrary.new()
	objectives.load_file()
	return objectives.current(GameState.flags)


## Dialogue d'Erika : le premier mot (et la parole d'une conversation sans scène).
func _say_again() -> void:
	_events.clear()
	_player.face(Vector2i.UP)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_process_frames(2)


# --- Données ----------------------------------------------------------------------------------

func test_erika_data_and_texts_match_the_validated_lot() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var trainer := library.get_trainer(&"celadon_gym_erika")
	assert_eq(trainer.ai, BattleAI.SMART)
	assert_true(trainer.can_switch, "elle change de Pokémon")
	assert_eq(trainer.prize_money, 2871, "99 × niveau final (29)")
	assert_eq([trainer.card_name, trainer.card_title], ["ERIKA", "Championne d'Arène de Céladopole"])
	var team := library.build_team(&"celadon_gym_erika", &"charmander", GameRng.new(1))
	assert_eq(team.get_all().map(func(p: Pokemon) -> Array: return [p.species_id, p.level]),
		[[&"tangela", 24], [&"victreebel", 27], [&"vileplume", 29]],
		"Saquedeneu 24 en tête, Empiflor 27, Rafflesia 29 (E-1)")
	var rafflesia: Pokemon = team.get_all()[2]
	assert_true(rafflesia.moves.any(func(m: MoveSlot) -> bool: return m.move_id == &"mega_drain"),
		"Méga-Sangsue sur Rafflesia")
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), "\n".join(dialogues.get_errors()))
	var expected: Dictionary[StringName, Array] = {
		&"celadon_gym_erika_intro": INTRO,
		&"celadon_gym_erika_lost": LOST_LINES,
		&"celadon_gym_erika_resume": RESUME,
		&"celadon_gym_erika_won": [WON],
		&"celadon_gym_erika_badge": ["{player} reçoit le Badge Prisme !"],
		&"celadon_gym_erika_tm": [TM_GIVE],
		&"celadon_gym_erika_tm_use": ["{player} reçoit la CT21 Méga-Sangsue !", TM_USE[1]],
		&"celadon_gym_erika_tm_late": [TM_LATE],
	}
	for id: StringName in expected:
		var dialogue := dialogues.get_dialogue(id)
		assert_not_null(dialogue, String(id))
		if dialogue == null:
			continue
		var texts: Array = []
		for page: DialoguePage in dialogue.variants[0].pages:
			texts.append(DialogueTokens.apply_agreements(page.text, {}).replace("\n", " "))
		assert_eq(texts, expected[id], "texte validé : %s" % id)
		assert_eq(dialogue.speaker, "Erika")


func test_erika_waits_at_the_end_of_the_garden_and_camelia_guards_the_way() -> void:
	await _start(START)
	var erika := _boot.get_map().get_npc(&"erika")
	assert_not_null(erika)
	assert_eq(erika.get_cell(), ERIKA_CELL)
	assert_eq(erika.get_spec().sprite, &"erika")
	var camelia := _boot.get_map().get_npc(&"camelia").get_spec()
	assert_eq([camelia.cell, camelia.sight], [Vector2i(8, 6), 2])
	assert_eq(camelia.trainer_id, &"celadon_gym_cooltrainer_camelia")


# --- Victoire ---------------------------------------------------------------------------------

func test_victory_badge_tm_moment_objective_and_save() -> void:
	await _start(START, true)
	_beat_the_trainers()
	var money := GameState.money
	assert_eq(_objective(), "explorer Céladopole.")
	await _walk_to_erika()
	assert_true(await _talk_to_erika(), "le combat a eu lieu")
	var pages := _pages()
	for line: String in INTRO + [WON, BADGE_LINE, TM_GIVE] + TM_USE:
		assert_true(pages.has(line), "« %s » jouée" % line)
	for line: String in LOST_LINES + RESUME + [TM_LATE]:
		assert_false(pages.has(line), "« %s » PAS jouée" % line)
	assert_eq(_index("page:" + INTRO[0]), 0, "l'introduction d'abord")
	var card := _index(CARD)
	assert_gt(card, _index("page:" + INTRO[2]), "la carte après l'introduction")
	assert_gt(_index("battle"), card, "la carte avant le combat")
	assert_gt(_index("page:" + WON), _index("battle"))
	assert_gt(_index("caption:BADGE PRISME"), _index("page:" + WON), "légende ensuite")
	assert_gt(_index("page:" + BADGE_LINE), _index("caption:BADGE PRISME"))
	assert_gt(_index("page:" + TM_GIVE), _index("page:" + BADGE_LINE))
	assert_gt(_index("toast:CT21 — Méga-Sangsue / obtenue"), _index("page:" + TM_GIVE), "le toast")
	# Le toast et la page « reçoit la CT21 » arrivent ensemble (ordre de relevé non garanti).
	assert_gt(_index("page:" + TM_USE[0]), _index("page:" + TM_GIVE))
	assert_gt(_index("page:" + TM_USE[1]), _index("page:" + TM_USE[0]))
	assert_true(GameState.flags.has_flag(&"erika_met"))
	assert_true(GameState.flags.has_flag(&"badge_rainbow"))
	assert_true(GameState.flags.has_flag(&"tm21_received"))
	assert_eq(GameState.bag.count_of(&"tm21"), 1, "CT21 au Sac")
	assert_eq(GameState.money, money + 2871)
	assert_eq(_vibrations.count(UiTokens.HAPTIC_BADGE_MS), 1, "vibration légère, une fois")
	assert_eq(_boot.get_map().map_id, GYM, "toujours dans l'Arène")
	var moments := _badge_moments()
	assert_eq(moments.size(), 1, "Grand moment « badge »")
	if moments.size() == 1:
		assert_eq(moments[0]["map"], "celadon_gym")
		var details: Dictionary = moments[0]["details"]
		assert_eq(BadgeMoment.badge_of(details), &"rainbow")
		assert_eq(BadgeMoment.team_of(details).size(), GameState.party.size())
	assert_true(_player.is_input_enabled(), "joueur libre")
	await wait_until(func() -> bool:
		return (_saved().get("flags", []) as Array).has("badge_rainbow"), 5.0)
	var saved := _saved()
	assert_true((saved.get("flags", []) as Array).has("badge_rainbow"), "badge sauvegardé")
	assert_true((saved.get("flags", []) as Array).has("tm21_received"))
	# Lui reparler : n° 38, plus de scène ni de CT.
	await _say_again()
	assert_eq(_boot.get_dialogue_box().get_text().replace("\n", " "), AFTER)
	assert_false(_boot.get_cutscene_director().is_running())
	assert_eq(GameState.bag.count_of(&"tm21"), 1)
	assert_push_error_count(0)


# --- Défaite et reprise -----------------------------------------------------------------------

func test_defeat_wakes_at_the_center_then_retry_without_introduction_nor_card() -> void:
	await _start(START)
	_beat_the_trainers()
	_make_weak()
	GameState.heal_map = &"celadon_center"
	GameState.heal_spawn = &"heal"
	var money := GameState.money
	await _walk_to_erika()
	assert_true(await _talk_to_erika(), "le combat a eu lieu")
	var pages := _pages()
	for line: String in INTRO + LOST_LINES:
		assert_true(pages.has(line), "« %s » jouée" % line)
	assert_gt(_index("page:" + LOST_LINES[0]), _index("battle"), "défaite après le combat")
	assert_gt(_index(CARD), -1, "carte à la première rencontre")
	for line: String in [WON, BADGE_LINE]:
		assert_false(pages.has(line), "« %s » PAS jouée" % line)
	assert_eq(_index("caption:BADGE PRISME"), -1, "pas de badge")
	assert_true(GameState.flags.has_flag(&"erika_met"), "première rencontre mémorisée")
	assert_false(GameState.flags.has_flag(&"badge_rainbow"))
	assert_true(_badge_moments().is_empty())
	assert_eq(GameState.money, money, "aucun argent perdu")
	assert_eq(_boot.get_map().map_id, &"celadon_center", "réveil au Centre de Céladopole")
	var lead := GameState.party.get_lead()
	assert_eq(lead.hp, lead.max_hp(), "soigné")
	for flag: StringName in TRAINER_FLAGS:
		assert_true(GameState.flags.has_flag(flag), "%s : Dresseuse battue gardée" % flag)
	# Retour, mieux préparé : n° 128, pas d'introduction, pas de carte, la victoire.
	await SceneRouter.change_map(GYM, &"entrance", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	_make_strong()
	_events.clear()
	await _walk_to_erika()
	assert_true(await _talk_to_erika(), "second combat")
	pages = _pages()
	assert_eq(_index("page:" + RESUME[0]), 0, "reprise courte")
	for line: String in INTRO:
		assert_false(pages.has(line), "« %s » PAS rejouée" % line)
	assert_eq(_index(CARD), -1, "pas de carte aux reprises")
	assert_gt(_index("caption:BADGE PRISME"), _index("battle"))
	assert_true(GameState.flags.has_flag(&"badge_rainbow"))
	assert_eq(_badge_moments().size(), 1)
	assert_eq(_vibrations.count(UiTokens.HAPTIC_BADGE_MS), 1)
	assert_eq(GameState.bag.count_of(&"tm21"), 1)
	assert_push_error_count(0)


# --- Rattrapage -------------------------------------------------------------------------------

func test_a_badged_game_without_the_tm_gets_it_once_by_talking_again() -> void:
	await _start(START)
	GameState.flags.set_flag(&"erika_met")
	GameState.flags.set_flag(&"badge_rainbow")
	assert_false(GameState.flags.has_flag(&"tm21_received"))
	_beat_the_trainers()
	await _walk_to_erika()
	_player.face(Vector2i.UP)
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var toast := _boot.get_hud().get_toast()
	var toasts: Array[String] = []
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	assert_eq(director.get_cutscene_id(), &"celadon_gym_erika_tm_late")
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while director.is_running() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_open():
			var page := "page:" + box.get_text().replace("\n", " ")
			if _events.is_empty() or _events.back() != page:
				_events.append(page)
			box.advance_requested.emit()
		var shown := "%s / %s" % [toast.get_title_text(), toast.get_detail_text()]
		if toast.visible and not toasts.has(shown):
			toasts.append(shown)
	await wait_process_frames(3)
	assert_eq(_events, ["page:" + TM_LATE, "page:" + TM_GIVE, "page:" + TM_USE[0],
		"page:" + TM_USE[1]] as Array[String])
	assert_eq(GameState.bag.count_of(&"tm21"), 1)
	assert_true(GameState.flags.has_flag(&"tm21_received"))
	assert_eq(toasts, ["CT21 — Méga-Sangsue / obtenue"])
	await _say_again()
	assert_eq(box.get_text().replace("\n", " "), AFTER, "plus de remise, la parole d'après")
	assert_false(director.is_running())
	assert_eq(GameState.bag.count_of(&"tm21"), 1, "une seule CT21")
	assert_push_error_count(0)
