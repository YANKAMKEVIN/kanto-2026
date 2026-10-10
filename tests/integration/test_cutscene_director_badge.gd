extends GutTest
## CutsceneDirector : étapes « champion_card » et « badge » (jalon-10.md §2.7, §2.8, T9), avec la
## vraie ExplorationHud, les vrais Dresseurs et les vrais badges ; durées au pas près (TweenClock).
## - champion_card : la carte du Dresseur (« PIERRE » / « Champion d'Arène d'Argenta ») est posée
##   et la scène attend sa disparition ; Dresseur sans carte, ou rien de branché : étape sautée ;
## - badge : drapeau du badge, légende « BADGE ROCHE » tenue BADGE_CAPTION_HOLD (2 s), vibration
##   légère demandée une fois, Grand moment « badge » (souvenir de l'équipe, carte courante)
##   enregistré une seule fois par badge ; sans HUD, drapeau et moment quand même.
## Ni joueur ni dialogue : ces étapes n'en ont pas besoin.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const STATE_SCRIPT := preload("res://game/autoload/game_state.gd")
const HUD_SCENE := preload("res://game/ui/hud/exploration_hud.tscn")
const TIMEOUT := 8.0
const SCENES := {
	"card": {"steps": [
		{"set": ["before"]}, {"champion_card": "pewter_gym_brock"}, {"set": ["after"]},
	]},
	"card_missing": {"steps": [{"champion_card": "pewter_gym_liam"}, {"set": ["after"]}]},
	"badge": {"steps": [{"set": ["before"]}, {"badge": "boulder"}, {"set": ["after"]}]},
	"badge_unknown": {"steps": [{"badge": "mystery"}, {"set": ["after"]}]},
}

var _director: CutsceneDirector
var _flags: StoryFlags
var _hud: ExplorationHud
var _state: Node
var _data: PokemonData
var _trainers: TrainerLibrary
var _badges: BadgeLibrary
var _vibrations: Array[int] = []


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_trainers = TrainerLibrary.new(_data)
	_trainers.load_dir()
	_badges = BadgeLibrary.new()
	_badges.load_file()


func before_each() -> void:
	var scenes := CutsceneLibrary.new()
	assert_true(scenes.add_from_dict(SCENES, "test"), str(scenes.get_errors()))
	_flags = StoryFlags.new()
	_director = CutsceneDirector.new()
	add_child_autofree(_director)
	_director.setup(scenes, _flags, null, null, null)
	_hud = HUD_SCENE.instantiate() as ExplorationHud
	add_child_autofree(_hud)
	_state = STATE_SCRIPT.new()
	autofree(_state)
	var rng := GameRng.new(3)
	var charmeleon := PokemonFactory.create(_data, &"charmeleon", 16, rng)
	charmeleon.nickname = "Braise"
	_state.party.add(charmeleon)
	var pidgey := PokemonFactory.create(_data, &"pidgey", 11, rng)
	pidgey.hp = 0
	_state.party.add(pidgey)
	var map := GameMap.new()
	map.map_id = &"pewter_gym"
	autofree(map)
	_director.set_map(map)
	_vibrations.clear()
	Haptics.sink = func(ms: int) -> void: _vibrations.append(ms)
	watch_signals(_hud)
	watch_signals(_hud.get_toast())


func after_each() -> void:
	Haptics.reset()


func _await_scene_end() -> void:
	await wait_until(func() -> bool: return not _director.is_running(), TIMEOUT)


func _caption_total() -> float:
	return 2.0 * UiTokens.CAPTION_FADE + UiTokens.BADGE_CAPTION_HOLD


func _badge_moments() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for moment: Dictionary in _state.moments:
		if moment.get("type") == String(BadgeMoment.TYPE):
			found.append(moment)
	return found


# --- champion_card ------------------------------------------------------------------------

func test_champion_card_shows_the_trainer_card_and_the_scene_waits_for_it() -> void:
	_director.set_hud(_hud)
	_director.set_trainers(_trainers)
	var clock := TweenClock.new(get_tree())
	assert_true(_director.play(&"card"))
	var card := _hud.get_champion_card()
	assert_true(_flags.has_flag(&"before"))
	assert_true(card.is_showing(), "carte posée dans l'appel")
	assert_eq([card.get_name_text(), card.get_title_text()],
		["PIERRE", "Champion d'Arène d'Argenta"])
	var total := UiTokens.CHAMPION_CARD_SLIDE_IN + UiTokens.CHAMPION_CARD_HOLD \
		+ UiTokens.CHAMPION_CARD_SLIDE_OUT
	clock.run_until(func() -> bool: return card.get_phase() == ChampionCard.Phase.SLIDING_OUT,
		total)
	assert_true(_director.is_running(), "la scène attend la sortie de la carte")
	assert_false(_flags.has_flag(&"after"))
	var steps := clock.run_until(func() -> bool: return not _director.is_running(), 2.0)
	assert_lte(steps * TweenClock.STEP, UiTokens.CHAMPION_CARD_SLIDE_OUT + 2 * TweenClock.STEP)
	clock.release()
	assert_true(_flags.has_flag(&"after"), "reprise après la carte")
	assert_signal_emit_count(_hud, "champion_card_hidden", 1)
	assert_push_error_count(0)


func test_a_touch_shortens_the_card_and_the_scene_goes_on() -> void:
	_director.set_hud(_hud)
	_director.set_trainers(_trainers)
	var clock := TweenClock.new(get_tree())
	_director.play(&"card")
	var card := _hud.get_champion_card()
	clock.run_until(func() -> bool: return card.get_phase() == ChampionCard.Phase.HOLDING, 2.0)
	card.skip_hold()
	var steps := clock.run_until(func() -> bool: return not _director.is_running(), 2.0)
	clock.release()
	assert_lte(steps * TweenClock.STEP, UiTokens.CHAMPION_CARD_SLIDE_OUT + 2 * TweenClock.STEP)
	assert_true(_flags.has_flag(&"after"))


func test_trainer_without_card_or_nothing_wired_is_skipped_with_error() -> void:
	_director.set_hud(_hud)
	_director.set_trainers(_trainers)
	_director.play(&"card_missing")
	await _await_scene_end()
	assert_push_error("aucune carte de présentation pour « pewter_gym_liam »")
	assert_true(_flags.has_flag(&"after"))
	assert_false(_hud.get_champion_card().is_showing())
	_director.set_trainers(null)
	_flags.set_flag(&"after", false)
	_director.play(&"card")
	await _await_scene_end()
	assert_push_error("aucune carte de présentation pour « pewter_gym_brock »")
	assert_true(_flags.has_flag(&"after"))
	_director.set_hud(null)
	_director.set_trainers(_trainers)
	_director.play(&"card")
	await _await_scene_end()
	assert_push_error("pas de HUD pour la carte")
	assert_push_error_count(3)


# --- badge --------------------------------------------------------------------------------

func test_badge_raises_its_flag_records_the_moment_and_shows_badge_roche() -> void:
	_director.set_hud(_hud)
	_director.set_badges(_badges, _state)
	assert_true(_director.play(&"badge"))
	assert_true(_flags.has_flag(&"badge_boulder"), "drapeau levé dans l'appel")
	assert_eq(_hud.get_caption().text, "BADGE ROCHE")
	assert_true(_hud.get_caption().is_showing())
	assert_eq(_vibrations, [UiTokens.HAPTIC_BADGE_MS] as Array[int], "vibration légère, une fois")
	assert_eq(UiTokens.HAPTIC_BADGE_MS, 40)
	var moments := _badge_moments()
	assert_eq(moments.size(), 1, "Grand moment « badge »")
	if moments.size() == 1:
		assert_eq(moments[0]["map"], "pewter_gym", "carte courante")
		var details: Dictionary = moments[0]["details"]
		assert_eq(BadgeMoment.badge_of(details), &"boulder")
		assert_eq(BadgeMoment.team_of(details), [
			{"species": &"charmeleon", "level": 16, "nickname": "Braise"},
			{"species": &"pidgey", "level": 11, "nickname": ""},
		] as Array[Dictionary], "souvenir de l'équipe, ordre, K.O. compris")
	assert_true(_director.is_running(), "la scène attend la légende")
	assert_false(_flags.has_flag(&"after"))
	await _await_scene_end()
	assert_true(_flags.has_flag(&"after"))
	assert_signal_emit_count(_hud, "caption_hidden", 1)
	assert_eq(_vibrations.size(), 1)
	assert_signal_not_emitted(_hud.get_toast(), "toast_shown", "aucun toast")
	assert_push_error_count(0)


func test_badge_caption_holds_two_seconds_to_the_step() -> void:
	_director.set_hud(_hud)
	_director.set_badges(_badges, _state)
	var clock := TweenClock.new(get_tree())
	_director.play(&"badge")
	var caption := _hud.get_caption()
	var before_end := int(_caption_total() / TweenClock.STEP) - 2
	for i: int in before_end:
		clock.step()
	assert_true(caption.is_showing(), "encore là juste avant la fin")
	assert_true(_director.is_running())
	var more := clock.run_until(func() -> bool: return not _director.is_running(), 2.0)
	clock.release()
	var total := (before_end + more) * TweenClock.STEP
	assert_between(total, _caption_total() - 0.0001, _caption_total() + 3 * TweenClock.STEP,
		"fondu + 2 s + fondu (%d pas)" % (before_end + more))
	assert_lt(_caption_total(), UiTokens.CAPTION_HOLD + 2.0 * UiTokens.CAPTION_FADE,
		"plus courte que « POKÉDEX ACTIVÉ »")
	assert_true(_flags.has_flag(&"after"))


func test_the_badge_moment_is_recorded_once_per_badge() -> void:
	_director.set_hud(_hud)
	_director.set_badges(_badges, _state)
	_director.play(&"badge")
	await _await_scene_end()
	_director.play(&"badge")
	await _await_scene_end()
	assert_eq(_badge_moments().size(), 1, "un seul moment par badge")
	assert_eq(_vibrations.size(), 2, "la légende, elle, est rejouée")


func test_the_default_caption_hold_is_unchanged() -> void:
	var clock := TweenClock.new(get_tree())
	_hud.show_caption("POKÉDEX ACTIVÉ")
	var steps := clock.run_until(func() -> bool:
		return get_signal_emit_count(_hud, "caption_hidden") > 0, 6.0)
	clock.release()
	var expected := UiTokens.CAPTION_HOLD + 2.0 * UiTokens.CAPTION_FADE
	assert_between(steps * TweenClock.STEP, expected - 0.0001,
		expected + 3 * TweenClock.STEP, "tenue par défaut : CAPTION_HOLD")


func test_without_hud_the_flag_and_the_moment_are_still_recorded() -> void:
	_director.set_badges(_badges, _state)
	_director.play(&"badge")
	await _await_scene_end()
	assert_push_error("pas de HUD pour la légende du badge « boulder »")
	assert_true(_flags.has_flag(&"badge_boulder"))
	assert_eq(_badge_moments().size(), 1)
	assert_true(_vibrations.is_empty(), "pas de légende, pas de vibration")
	assert_true(_flags.has_flag(&"after"))


func test_unknown_badge_or_no_badges_is_skipped_with_error() -> void:
	_director.set_hud(_hud)
	_director.set_badges(_badges, _state)
	_director.play(&"badge_unknown")
	await _await_scene_end()
	assert_push_error("badge inconnu « mystery »")
	assert_true(_flags.has_flag(&"after"))
	_director.set_badges(null, null)
	_director.play(&"badge")
	await _await_scene_end()
	assert_push_error("badge inconnu « boulder »")
	assert_false(_flags.has_flag(&"badge_boulder"))
	assert_true(_badge_moments().is_empty())
	assert_true(_vibrations.is_empty())
	assert_push_error_count(2)


func test_without_state_no_moment_but_the_caption_plays() -> void:
	_director.set_hud(_hud)
	_director.set_badges(_badges, null)
	_director.play(&"badge")
	assert_eq(_hud.get_caption().text, "BADGE ROCHE")
	await _await_scene_end()
	assert_true(_flags.has_flag(&"badge_boulder"))
	assert_true(_badge_moments().is_empty())
	assert_push_error_count(0)
