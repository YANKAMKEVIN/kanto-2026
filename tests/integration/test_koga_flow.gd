extends GutTest
## Koga de bout en bout (jalon 23 T19, `jalon-23.md` §2.13 ; dossier 26 §8 textes 38 à 44,
## §10.3) avec la vraie scène Boot, la vraie carte `fuchsia_gym` et ses PNJ, la vraie scène
## `fuchsia_gym_koga`, les vraies données (Koga, carte, Badge Âme, CT06), les vraies entrées, le
## combat instantané et une sauvegarde en mémoire (modèle : `test_erika_flow.gd`) :
## - victoire : textes 38 et 39 → carte « KOGA » → combat → 40 → « BADGE ÂME » (41, une vibration
##   légère) → 42 et CT06 (toast) ; `koga_met`, `badge_soul`, `tm06_received`, 4 257 ₽, Grand
##   moment « badge », sauvegarde ; ensuite 44, plus de scène ni de CT ;
## - défaite : réveil au Centre de Parmanie, sans argent perdu ; Koga rejouable, sans
##   introduction ni carte ;
## - partie badgée sans CT : rattrapage (43 puis 42), une seule fois.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/koga_qa.json"
const SAVE_PATH := "user://test_koga_flow_save.json"
const GYM := &"fuchsia_gym"
const DATE := "2026-10-22T18:00:00"
const FADE := 0.05
const TIMEOUT_MS := 12000
const SCENE_TIMEOUT_MS := 120000
const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
const ENTRANCE := Vector2i(6, 17)
const KOGA_CELL := Vector2i(6, 11)
const TALK_CELL := Vector2i(6, 12)
## Textes validés : dossier 26 §8 (38 à 44) ; reprise et défaite [R] (rapport du T19).
const INTRO: Array[String] = [
	"Fwahahaha ! Un enfant ose me défier ?", "Je suis Koga, maître ninja des poisons.",
	"Le poison et le sommeil", "feront sombrer tes Pokémon.",
]
const LOST_LINES: Array[String] = ["Le poison a fait son œuvre.", "Reviens quand tu seras prêt."]
const RESUME := "Fwahahaha ! Tu reviens ?"
const WON: Array[String] = ["Hmm ! Tu as prouvé ta valeur.", "Voici le Badge Âme."]
const TM: Array[String] = ["Prends aussi la CT06, Toxik.", "Son poison empire à chaque tour."]
const TM_LATE := "J'allais oublier."
const AFTER := "Le ninja se fond dans l'ombre."
const CARD := "card:KOGA/Champion d'Arène de Parmanie"
const CAPTION := "caption:BADGE ÂME"
const TOAST := "toast:CT06 — Toxik / obtenue"
const TRAINER_FLAGS: Array[StringName] = [
	&"beaten_fuchsia_gym_juggler_1", &"beaten_fuchsia_gym_juggler_2",
	&"beaten_fuchsia_gym_juggler_3", &"beaten_fuchsia_gym_tamer_1",
	&"beaten_fuchsia_gym_tamer_2", &"beaten_fuchsia_gym_juggler_4",
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
## [param strong] : équipe remplacée par un Kadabra Nv. 90 (Psyko).
func _start(start_path: String, strong: bool = false) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = GYM
	_boot.start_spawn = &"entree"
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
	await SceneRouter.change_map(GYM, &"entree", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	assert_eq(_boot.get_map().map_id, GYM)
	assert_eq(_player.get_cell(), ENTRANCE)


func _make_strong() -> void:
	# Kadabra Nv. 90, Psyko (super efficace sur le Poison) : la victoire ne dépend pas des tirages.
	var champion := PokemonFactory.create(_boot.get_pokemon_data(), &"kadabra", 90,
		GameState.rng)
	champion.moves.clear()
	champion.moves.append(MoveSlot.new(&"psychic", 10))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(champion)


func _make_weak() -> void:
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 5,
		GameState.rng))


## Les six Dresseurs de l'Arène battus : aucun défi ne coupe la marche (ils ont leurs propres
## tests).
func _beat_the_trainers() -> void:
	for flag: StringName in TRAINER_FLAGS:
		GameState.flags.set_flag(flag)


## Marche jusqu'à la case devant Koga par le chemin le plus court de la vraie grille.
func _walk_to_koga() -> void:
	var path := _boot.get_map().get_grid().find_path(_player.get_cell(), TALK_CELL, _player)
	assert_false(path.is_empty(), "un chemin mène devant Koga")
	var cell := _player.get_cell()
	for direction: Vector2i in path:
		cell += direction
		await _walk_to(cell)
	assert_eq(_player.get_cell(), TALK_CELL, "devant Koga")


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
func _talk_to_koga() -> bool:
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


## Dialogue de Koga : le premier mot (et la parole d'une conversation sans scène).
func _say_again() -> void:
	_events.clear()
	_player.face(Vector2i.UP)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_process_frames(2)


# --- Victoire ---------------------------------------------------------------------------------

func test_victory_badge_tm_moment_and_save() -> void:
	await _start(START, true)
	_beat_the_trainers()
	var money := GameState.money
	var koga := _boot.get_map().get_npc(&"koga")
	assert_not_null(koga)
	assert_eq(koga.get_cell(), KOGA_CELL)
	await _walk_to_koga()
	assert_true(await _talk_to_koga(), "le combat a eu lieu")
	var pages := _pages()
	for line: String in INTRO + WON + TM:
		assert_true(pages.has(line), "« %s » jouée" % line)
	for line: String in LOST_LINES + [RESUME, TM_LATE]:
		assert_false(pages.has(line), "« %s » PAS jouée" % line)
	assert_eq(_index("page:" + INTRO[0]), 0, "l'introduction d'abord")
	var card := _index(CARD)
	assert_gt(card, _index("page:" + INTRO[3]), "la carte après l'introduction")
	assert_gt(_index("battle"), card, "la carte avant le combat")
	assert_gt(_index("page:" + WON[1]), _index("battle"))
	assert_gt(_index(CAPTION), _index("page:" + WON[1]), "légende ensuite")
	assert_gt(_index("page:" + TM[0]), _index(CAPTION))
	# La CT est la dernière étape : son toast reste affiché après la scène.
	var toast := _boot.get_hud().get_toast()
	assert_true(_events.has(TOAST) or "toast:%s / %s" % [toast.get_title_text(),
		toast.get_detail_text()] == TOAST, "toast de la CT06")
	assert_true(GameState.flags.has_flag(&"koga_met"))
	assert_true(GameState.flags.has_flag(&"badge_soul"))
	assert_true(GameState.flags.has_flag(&"tm06_received"))
	assert_eq(GameState.bag.count_of(&"tm06"), 1, "CT06 au Sac")
	assert_eq(GameState.money, money + 4257)
	assert_eq(_vibrations.count(UiTokens.HAPTIC_BADGE_MS), 1, "vibration légère, une fois")
	assert_eq(_boot.get_map().map_id, GYM, "toujours dans l'Arène")
	var moments := _badge_moments()
	assert_eq(moments.size(), 1, "Grand moment « badge »")
	if moments.size() == 1:
		assert_eq(moments[0]["map"], "fuchsia_gym")
		assert_eq(BadgeMoment.badge_of(moments[0]["details"]), &"soul")
	assert_true(_player.is_input_enabled(), "joueur libre, aucune scène après le badge")
	await wait_until(func() -> bool:
		return (_saved().get("flags", []) as Array).has("badge_soul"), 5.0)
	assert_true((_saved().get("flags", []) as Array).has("tm06_received"), "sauvegardé")
	await _say_again()
	assert_eq(_boot.get_dialogue_box().get_text().replace("\n", " "), AFTER, "texte 44")
	assert_false(_boot.get_cutscene_director().is_running())
	assert_eq(GameState.bag.count_of(&"tm06"), 1, "une seule CT06")
	assert_push_error_count(0)


# --- Défaite et reprise -----------------------------------------------------------------------

func test_defeat_wakes_at_the_center_and_koga_can_be_fought_again() -> void:
	await _start(START)
	_beat_the_trainers()
	_make_weak()
	GameState.heal_map = &"fuchsia_center"
	GameState.heal_spawn = &"heal"
	var money := GameState.money
	await _walk_to_koga()
	assert_true(await _talk_to_koga(), "le combat a eu lieu")
	var pages := _pages()
	for line: String in INTRO + LOST_LINES:
		assert_true(pages.has(line), "« %s » jouée" % line)
	assert_eq(_index(CAPTION), -1, "pas de badge")
	assert_true(GameState.flags.has_flag(&"koga_met"))
	assert_false(GameState.flags.has_flag(&"badge_soul"))
	assert_false(GameState.flags.has_flag(&"tm06_received"))
	assert_eq(GameState.bag.count_of(&"tm06"), 0)
	assert_eq(GameState.money, money, "aucun argent perdu")
	assert_eq(_boot.get_map().map_id, &"fuchsia_center", "réveil au Centre de Parmanie")
	for flag: StringName in TRAINER_FLAGS:
		assert_true(GameState.flags.has_flag(flag), "%s gardé" % flag)
	await SceneRouter.change_map(GYM, &"entree", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	_make_strong()
	_events.clear()
	await _walk_to_koga()
	assert_true(await _talk_to_koga(), "second combat")
	pages = _pages()
	assert_eq(_index("page:" + RESUME), 0, "reprise courte")
	assert_false(pages.has(INTRO[0]), "pas d'introduction")
	assert_eq(_index(CARD), -1, "pas de carte aux reprises")
	assert_gt(_index(CAPTION), _index("battle"))
	assert_true(GameState.flags.has_flag(&"badge_soul"))
	assert_eq(GameState.bag.count_of(&"tm06"), 1)
	assert_push_error_count(0)


# --- Rattrapage -------------------------------------------------------------------------------

func test_a_badged_game_without_the_tm_gets_it_once() -> void:
	await _start(START)
	GameState.flags.set_flag(&"koga_met")
	GameState.flags.set_flag(&"badge_soul")
	_beat_the_trainers()
	await _walk_to_koga()
	_player.face(Vector2i.UP)
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	assert_eq(director.get_cutscene_id(), &"fuchsia_gym_koga_tm_late")
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while director.is_running() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_open():
			var page := "page:" + box.get_text().replace("\n", " ")
			if _events.is_empty() or _events.back() != page:
				_events.append(page)
			box.advance_requested.emit()
	await wait_process_frames(3)
	assert_eq(_events, ["page:" + TM_LATE, "page:" + TM[0], "page:" + TM[1]] as Array[String],
		"texte 43 puis 42")
	assert_eq(GameState.bag.count_of(&"tm06"), 1)
	assert_true(GameState.flags.has_flag(&"tm06_received"))
	await _say_again()
	assert_eq(box.get_text().replace("\n", " "), AFTER, "plus de remise")
	assert_eq(GameState.bag.count_of(&"tm06"), 1, "une seule CT06")
	assert_push_error_count(0)
