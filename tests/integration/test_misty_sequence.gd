extends GutTest
## Ondine de bout en bout (jalon 13 T19, jalon-13.md §2.10 ; dossier 16 §9.4, §10 ; textes n° 34 à
## 41) avec la vraie scène Boot, la vraie carte `cerulean_gym` et ses PNJ, la vraie scène
## `cerulean_gym_misty`, les vraies données (Dresseur, carte, badge, CT11), les vraies entrées
## (`move_*`, `interact`), l'autoload SceneRouter (fondus raccourcis), le combat instantané et une
## sauvegarde en mémoire :
## - victoire : introduction (34) → carte « ONDINE » → combat → n° 37 → « BADGE CASCADE » (une
##   vibration légère) → n° 38 → CT11 (n° 39, toast « CT11 — Bulles d'O / obtenue ») ; drapeaux
##   `misty_met`, `badge_cascade`, `tm11_received`, 2 100 ₽, Grand moment « badge », sauvegarde ;
##   ensuite n° 41 selon le recruteur (a / b), plus aucune scène ;
## - défaite : n° 35, réveil au Centre d'Azuria (aucun argent perdu, ni badge ni moment), Dresseurs
##   battus gardés ; retour : n° 36 sans introduction ni carte, puis la victoire ;
## - partie badgée sans CT : rattrapage (n° 40 puis 39), une seule fois ;
## - Ondine absente sans `misty_invited` ; changement de Pokémon actif pour elle.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/cerulean_gym.json"
const NO_TM_START := "res://tools/debug_start/cascade_no_tm.json"
const SAVE_PATH := "user://test_misty_sequence_save.json"
const GYM := &"cerulean_gym"
const DATE := "2026-10-13T18:00:00"
const FADE := 0.05
const TIMEOUT_MS := 12000
const SCENE_TIMEOUT_MS := 120000
const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
const ENTRANCE := Vector2i(8, 11)
const MISTY_CELL := Vector2i(8, 3)
const TALK_CELL := Vector2i(7, 3)
const INTRO: Array[String] = [
	"Te voilà.", "Ici, l'eau ne pardonne pas l'hésitation.", "Voyons si tu tiens le rythme !",
]
const LOST_LINES: Array[String] = ["L'eau t'a emporté, cette fois.", "Reviens quand tu seras prêt."]
const RESUME := "Prêt à replonger ?"
const WON_LINES: Array[String] = ["…Bien joué.", "Tu as gardé la tête hors de l'eau."]
const BADGE_LINES: Array[String] = [
	"Voici le Badge Cascade.", "Il prouve que tu as tenu tête à la Championne d'Azuria.",
]
const TM_GIVE := "Prends aussi ceci."
const TM_USE := "C'est la CT11, Bulles d'O. Un Pokémon qui l'apprend la garde, et tu peux t'en resservir."
const TM_LATE := "J'allais oublier."
const AFTER_A := "Le pont t'a déjà vu passer ?"
const AFTER_B := "Tu as fait le pont ? Alors tu sais ce qu'il vaut."
const CARD := "card:ONDINE/Championne d'Arène d'Azuria"

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


## Les deux Dresseurs de l'Arène battus : aucun défi ne coupe la marche (ils ont leurs propres
## tests).
func _beat_the_trainers() -> void:
	GameState.flags.set_flag(&"beaten_cerulean_gym_lucas")
	GameState.flags.set_flag(&"beaten_cerulean_gym_diane")


## Marche jusqu'à la case devant Ondine par le chemin le plus court de la vraie grille.
func _walk_to_misty() -> void:
	var path := _boot.get_map().get_grid().find_path(_player.get_cell(), TALK_CELL, _player)
	assert_false(path.is_empty(), "un chemin mène devant Ondine")
	var cell := _player.get_cell()
	for direction: Vector2i in path:
		cell += direction
		await _walk_to(cell)
	assert_eq(_player.get_cell(), TALK_CELL, "devant Ondine")


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


## Lui parle (bouton d'interaction) et déroule tout : pages, carte, combat piloté, légende,
## toast, réveil éventuel. Vrai si un combat a eu lieu.
func _talk_to_misty() -> bool:
	_player.face(Vector2i.RIGHT)
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
			var page := "page:" + box.get_text()
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


## Dialogue d'Ondine : le premier mot (et la parole d'une conversation sans scène).
func _say_again() -> void:
	_events.clear()
	_player.face(Vector2i.RIGHT)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_process_frames(2)


# --- Données ----------------------------------------------------------------------------------

func test_misty_data_and_texts_match_the_validated_lot() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var trainer := library.get_trainer(&"cerulean_gym_misty")
	assert_eq(trainer.ai, BattleAI.SMART)
	assert_true(trainer.can_switch, "elle change de Pokémon (T12)")
	assert_eq(trainer.prize_money, 2100)
	assert_eq([trainer.card_name, trainer.card_title], ["ONDINE", "Championne d'Arène d'Azuria"])
	var team := library.build_team(&"cerulean_gym_misty", &"charmander", GameRng.new(1))
	assert_eq(team.get_all().map(func(p: Pokemon) -> Array: return [p.species_id, p.level]),
		[[&"staryu", 18], [&"starmie", 21]])
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), "\n".join(dialogues.get_errors()))
	var expected: Dictionary[StringName, Array] = {
		&"cerulean_gym_misty_intro": INTRO,
		&"cerulean_gym_misty_lost": LOST_LINES,
		&"cerulean_gym_misty_resume": [RESUME],
		&"cerulean_gym_misty_won": WON_LINES,
		&"cerulean_gym_misty_badge": BADGE_LINES,
		&"cerulean_gym_misty_tm": [TM_GIVE],
		&"cerulean_gym_misty_tm_use": [TM_USE],
		&"cerulean_gym_misty_tm_late": [TM_LATE],
	}
	for id: StringName in expected:
		var dialogue := dialogues.get_dialogue(id)
		assert_not_null(dialogue, String(id))
		if dialogue == null:
			continue
		var texts: Array = []
		for page: DialoguePage in dialogue.variants[0].pages:
			texts.append(page.text)
		assert_eq(texts, expected[id], "texte validé : %s" % id)
		assert_eq(dialogue.speaker, "Ondine")


func test_misty_is_absent_without_the_invitation_and_present_with_it() -> void:
	await _start("res://tools/debug_start/cerulean_city.json")
	await SceneRouter.change_map(GYM, &"entrance", Vector2i.UP)
	await wait_process_frames(3)
	assert_null(_boot.get_map().get_npc(&"misty"), "sa place est vide avant l'invitation")
	GameState.flags.set_flag(&"misty_invited")
	await SceneRouter.change_map(GYM, &"entrance", Vector2i.UP)
	await wait_process_frames(3)
	var misty := _boot.get_map().get_npc(&"misty")
	assert_not_null(misty, "présente avec l'invitation")
	assert_eq(misty.get_cell(), MISTY_CELL)


func test_misty_switches_a_staryu_in_danger_for_starmie() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir())
	var items := ItemLibrary.new()
	items.load_dir()
	var trainer := library.get_trainer(&"cerulean_gym_misty")
	var rng := GameRng.new(5)
	var lead := PokemonFactory.create(data, &"charmander", 40, rng)
	lead.moves.clear()
	lead.moves.append(MoveSlot.new(&"ember", 25))
	var party := Party.new()
	party.add(lead)
	var foes := library.build_team(&"cerulean_gym_misty", &"charmander", rng)
	foes.get_all()[0].hp = 3
	var battle := Battle.new(BattleSide.new(party, true),
		BattleSide.new(foes, false, trainer.name, trainer.make_ai()), data, rng,
		BattleRules.for_trainer(trainer, items))
	battle.start()
	var events := battle.submit(BattleAction.move(0))
	var kinds: Array = events.map(func(e: BattleEvent) -> int: return e.kind)
	var withdrawn := kinds.find(BattleEvent.Kind.WITHDRAWN)
	assert_gt(withdrawn, -1, "elle rappelle Stari à 25 % des PV")
	if withdrawn > -1:
		assert_eq(events[withdrawn].pokemon_name, "Stari")
		assert_eq(events[withdrawn + 1].pokemon_name, "Staross")


# --- Victoire ---------------------------------------------------------------------------------

func test_victory_badge_tm_moment_objective_and_save() -> void:
	await _start(START, true)
	_beat_the_trainers()
	var money := GameState.money
	var toast_before := _boot.get_hud().get_toast()
	assert_not_null(toast_before)
	assert_eq(_objective(), "obtenir le Badge Cascade.")
	await _walk_to_misty()
	assert_true(await _talk_to_misty(), "le combat a eu lieu")
	var pages := _pages()
	for line: String in INTRO + WON_LINES + BADGE_LINES + [TM_GIVE, TM_USE]:
		assert_true(pages.has(line), "« %s » jouée" % line)
	for line: String in LOST_LINES + [RESUME, TM_LATE]:
		assert_false(pages.has(line), "« %s » PAS jouée" % line)
	assert_eq(_index("page:" + INTRO[0]), 0, "l'introduction d'abord")
	var card := _index(CARD)
	assert_gt(card, _index("page:" + INTRO[2]), "la carte après l'introduction")
	assert_gt(_index("battle"), card, "la carte avant le combat")
	assert_gt(_index("page:" + WON_LINES[0]), _index("battle"))
	assert_gt(_index("caption:BADGE CASCADE"), _index("page:" + WON_LINES[1]), "légende ensuite")
	assert_gt(_index("page:" + BADGE_LINES[0]), _index("caption:BADGE CASCADE"))
	assert_gt(_index("page:" + TM_GIVE), _index("page:" + BADGE_LINES[1]))
	assert_gt(_index("toast:CT11 — Bulles d'O / obtenue"), _index("page:" + TM_GIVE), "le toast")
	assert_gt(_index("page:" + TM_USE), _index("page:" + TM_GIVE), "puis l'explication de la CT")
	assert_true(GameState.flags.has_flag(&"misty_met"))
	assert_true(GameState.flags.has_flag(&"badge_cascade"))
	assert_true(GameState.flags.has_flag(&"tm11_received"))
	assert_eq(GameState.bag.count_of(&"tm11"), 1, "CT11 au Sac")
	assert_eq(GameState.money, money + 2100)
	assert_eq(_vibrations.count(UiTokens.HAPTIC_BADGE_MS), 1, "vibration légère, une fois")
	assert_eq(_boot.get_map().map_id, GYM, "toujours dans l'Arène")
	var moments := _badge_moments()
	assert_eq(moments.size(), 1, "Grand moment « badge »")
	if moments.size() == 1:
		assert_eq(moments[0]["map"], "cerulean_gym")
		var details: Dictionary = moments[0]["details"]
		assert_eq(BadgeMoment.badge_of(details), &"cascade")
		assert_eq(BadgeMoment.team_of(details).size(), GameState.party.size())
	assert_eq(_objective(), "traverser le Pont Pépite.", "objectif en silence")
	assert_true(_player.is_input_enabled(), "joueur libre")
	await wait_until(func() -> bool:
		return (_saved().get("flags", []) as Array).has("badge_cascade"), 5.0)
	var saved := _saved()
	assert_true((saved.get("flags", []) as Array).has("badge_cascade"), "badge sauvegardé")
	assert_true((saved.get("flags", []) as Array).has("tm11_received"))
	# Lui reparler : n° 41 a (pont pas fait), plus de scène ni de CT.
	await _say_again()
	assert_eq(_boot.get_dialogue_box().get_text(), AFTER_A)
	assert_false(_boot.get_cutscene_director().is_running())
	assert_eq(GameState.bag.count_of(&"tm11"), 1)
	_boot.get_dialogue_box().advance_requested.emit()
	await wait_process_frames(30)
	# Recruteur battu : n° 41 b.
	GameState.flags.set_flag(&"beaten_nugget_rocket")
	await _say_again()
	assert_eq(_boot.get_dialogue_box().get_text(), AFTER_B)
	assert_push_error_count(0)


# --- Défaite et reprise -----------------------------------------------------------------------

func test_defeat_wakes_at_the_center_then_resume_without_introduction_nor_card() -> void:
	await _start(START)
	_beat_the_trainers()
	_make_weak()
	GameState.heal_map = &"cerulean_center"
	GameState.heal_spawn = &"heal"
	var money := GameState.money
	await _walk_to_misty()
	assert_true(await _talk_to_misty(), "le combat a eu lieu")
	var pages := _pages()
	for line: String in INTRO + LOST_LINES:
		assert_true(pages.has(line), "« %s » jouée" % line)
	assert_gt(_index("page:" + LOST_LINES[0]), _index("battle"), "défaite après le combat")
	assert_gt(_index(CARD), -1, "carte à la première rencontre")
	for line: String in WON_LINES + BADGE_LINES:
		assert_false(pages.has(line), "« %s » PAS jouée" % line)
	assert_eq(_index("caption:BADGE CASCADE"), -1, "pas de badge")
	assert_true(GameState.flags.has_flag(&"misty_met"), "première rencontre mémorisée")
	assert_false(GameState.flags.has_flag(&"badge_cascade"))
	assert_true(_badge_moments().is_empty())
	assert_eq(GameState.money, money, "aucun argent perdu")
	assert_eq(_boot.get_map().map_id, &"cerulean_center", "réveil au Centre d'Azuria")
	var lead := GameState.party.get_lead()
	assert_eq(lead.hp, lead.max_hp(), "soigné")
	assert_true(GameState.flags.has_flag(&"beaten_cerulean_gym_lucas"), "Lucas reste battu")
	assert_true(GameState.flags.has_flag(&"beaten_cerulean_gym_diane"), "Diane reste battue")
	assert_eq(_objective(), "obtenir le Badge Cascade.", "objectif inchangé")
	# Retour, mieux préparé : n° 36, pas d'introduction, pas de carte, la victoire.
	await SceneRouter.change_map(GYM, &"entrance", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	_make_strong()
	_events.clear()
	await _walk_to_misty()
	assert_true(await _talk_to_misty(), "second combat")
	pages = _pages()
	assert_eq(_index("page:" + RESUME), 0, "reprise courte")
	for line: String in INTRO:
		assert_false(pages.has(line), "« %s » PAS rejouée" % line)
	assert_eq(_index(CARD), -1, "pas de carte aux reprises")
	assert_gt(_index("caption:BADGE CASCADE"), _index("battle"))
	assert_true(GameState.flags.has_flag(&"badge_cascade"))
	assert_eq(_badge_moments().size(), 1)
	assert_eq(_vibrations.count(UiTokens.HAPTIC_BADGE_MS), 1)
	assert_eq(GameState.bag.count_of(&"tm11"), 1)
	assert_push_error_count(0)


# --- Rattrapage -------------------------------------------------------------------------------

func test_a_badged_game_without_the_tm_gets_it_once_by_talking_again() -> void:
	await _start(NO_TM_START)
	assert_false(GameState.flags.has_flag(&"tm11_received"))
	_beat_the_trainers()
	await _walk_to_misty()
	_player.face(Vector2i.RIGHT)
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var toast := _boot.get_hud().get_toast()
	var toasts: Array[String] = []
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	assert_eq(director.get_cutscene_id(), &"cerulean_gym_misty_tm_late")
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while director.is_running() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_open():
			var page := "page:" + box.get_text()
			if _events.is_empty() or _events.back() != page:
				_events.append(page)
			box.advance_requested.emit()
		var shown := "%s / %s" % [toast.get_title_text(), toast.get_detail_text()]
		if toast.visible and not toasts.has(shown):
			toasts.append(shown)
	await wait_process_frames(3)
	assert_eq(_events, ["page:" + TM_LATE, "page:" + TM_GIVE, "page:" + TM_USE])
	assert_eq(GameState.bag.count_of(&"tm11"), 1)
	assert_true(GameState.flags.has_flag(&"tm11_received"))
	assert_eq(toasts, ["CT11 — Bulles d'O / obtenue"])
	await _say_again()
	assert_eq(box.get_text(), AFTER_A, "plus de remise, la parole d'après")
	assert_false(director.is_running())
	assert_eq(GameState.bag.count_of(&"tm11"), 1, "une seule CT11")
	assert_push_error_count(0)
