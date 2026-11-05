extends GutTest
## AwakeningOverlay (JOHP0, `jalon-joh-pierres.md` §2.3 ; dossier JOH-11 §13.2) : ordre du film,
## durée, compteur, paliers, plan large, écran du Réveil, retour avalé. Vitesse 0 : tout est
## instantané, l'ordre des repères se lit sur les signaux.

const STATE_SCRIPT := preload("res://game/autoload/game_state.gd")

var _data: PokemonData
var _overlay: AwakeningOverlay
var _state: Node
var _events: Array[String] = []


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_state = STATE_SCRIPT.new()
	autofree(_state)
	_state.new_game(5)
	_events = []
	_overlay = AwakeningOverlay.new()
	add_child_autofree(_overlay)
	_overlay.setup(_data)
	_overlay.speed_scale = 0.0
	_overlay.silence_requested.connect(func() -> void: _events.append("silence"))
	_overlay.heartbeat.connect(func(_s: float) -> void: _events.append("beat"))
	_overlay.theme_started.connect(func() -> void: _events.append("theme"))
	_overlay.ball_opened.connect(func() -> void: _events.append("ball"))
	_overlay.cry_requested.connect(func(s: StringName) -> void: _events.append("cry %s" % s))
	_overlay.evolved_on_screen.connect(func(s: StringName) -> void: _events.append("into %s" % s))
	_overlay.theme_burst.connect(func() -> void: _events.append("burst"))


func _report(species: Array[StringName], level: int = 40) -> AwakeningReport:
	var team := ConfiscatedTeam.new()
	team.party.append(PokemonFactory.create(_data, &"pidgeot", 58, GameRng.new(1)))
	_state.confiscated = team
	for id: StringName in species:
		_state.party.add(PokemonFactory.create(_data, id, level, GameRng.new(2)))
	return StoneAwakening.awaken(_state, null, _data)


func _result(chain: int) -> AwakeningResult:
	var result := AwakeningResult.new()
	for i: int in chain:
		result.chain.append(&"x")
	return result


func test_the_film_plays_in_the_order_of_the_dossier() -> void:
	var report := _report([&"rattata"])
	await _overlay.film(report, ["ligne 1", "ligne 2"] as Array[String])
	assert_eq(_events.slice(0, 1), ["silence"] as Array[String])
	assert_eq(_events.count("beat"), AwakeningOverlay.BEAT_GAPS.size())
	var theme := _events.find("theme")
	assert_gt(theme, _events.rfind("beat"), "le thème vient après les battements")
	assert_gt(_events.find("ball"), theme, "puis la Ball")
	assert_gt(_events.find("burst"), _events.find("ball"), "le plan large à la fin")
	assert_eq(_overlay.get_phase(), AwakeningOverlay.Phase.LINE_UP)
	assert_true(_overlay.is_open(), "l'image reste pendant l'écriture")


func test_the_film_has_no_question_and_swallows_back() -> void:
	var report := _report([&"rattata"])
	await _overlay.film(report, [] as Array[String])
	assert_true(_overlay.handle_back(), "avalé")
	assert_eq(_overlay.get_phase(), AwakeningOverlay.Phase.LINE_UP, "rien ne passe le film")


func test_a_chain_stops_the_counter_at_each_step() -> void:
	var ticks: Array[int] = []
	_overlay.level_ticked.connect(func(level: int) -> void: ticks.append(level))
	var report := _report([&"caterpie"], 6)
	await _overlay.film(report, [] as Array[String])
	assert_eq(ticks, [7, 10, 58] as Array[int], "vitesse 0 : un cran par tronçon")
	assert_eq(_overlay.get_counter_text(), "Niv. 58")
	assert_true(_events.has("into metapod"))
	assert_true(_events.has("into butterfree"))
	assert_lt(_events.find("into metapod"), _events.find("cry metapod"))
	assert_gt(_events.find("cry butterfree"), _events.find("into metapod"))


func test_each_pokemon_gets_its_plan_in_team_order() -> void:
	var report := _report([&"rattata", &"pidgey"])
	await _overlay.film(report, [] as Array[String])
	assert_eq(_events.count("ball"), 2)
	assert_lt(_events.find("cry rattata"), _events.find("cry pidgey"))


func test_the_line_up_shows_the_whole_team_and_the_lines() -> void:
	_state.party.add(PokemonFactory.create(_data, &"pidgeot", 60, GameRng.new(3)))
	var report := _report([&"rattata"])
	await _overlay.film(report, ["P-31"] as Array[String], "Stockage")
	assert_eq(_overlay.get_line_up_size(), 2, "le Roucarnage déjà au-dessus paraît aussi")
	assert_eq(_overlay.get_line_text(), "Stockage", "dernière ligne lue")


func test_six_pokemon_last_60_to_90_seconds() -> void:
	var report := AwakeningReport.new()
	for i: int in 6:
		report.party.append(_result(1 if i < 2 else 0))
	var seconds := AwakeningOverlay.film_seconds(report)
	assert_between(seconds, 60.0, 90.0, "durée du film : %.1f s" % seconds)
	for i: int in 6:
		var plan := AwakeningOverlay._plan_seconds(report.party[i], 6)
		assert_between(plan, 6.0, 8.0, "un plan : %.1f s" % plan)


func test_chains_of_six_stay_under_90_seconds() -> void:
	var report := AwakeningReport.new()
	for i: int in 6:
		report.party.append(_result(2))
	report.stored.append(_result(0))
	assert_lt(AwakeningOverlay.film_seconds(report), 90.0)


func test_review_lists_each_pokemon_and_continue_closes() -> void:
	var report := _report([&"caterpie", &"rattata"], 20)
	await _overlay.film(report, [] as Array[String])
	var outcome := {}
	var run := func() -> void:
		outcome["learned"] = await _overlay.review(report, null)
	run.call()
	assert_eq(_overlay.get_phase(), AwakeningOverlay.Phase.REVIEW)
	var rows := _overlay.get_row_buttons()
	assert_eq(rows.size(), 2)
	assert_string_contains(rows[0].text, "Chenipan → Papilusion")
	assert_string_contains(rows[0].text, "Niv. 20 → 58")
	assert_string_contains(rows[0].text, "attaques à voir")
	assert_true(_overlay.handle_back())
	assert_eq(_overlay.get_phase(), AwakeningOverlay.Phase.REVIEW, "seul CONTINUER ferme")
	_overlay.get_continue_button().pressed.emit()
	await wait_process_frames(2)
	assert_eq(outcome.get("learned"), false)
	assert_false(_overlay.is_open())
	assert_eq(_overlay.get_phase(), AwakeningOverlay.Phase.IDLE)


func test_row_text_says_nothing_about_moves_when_none_remain() -> void:
	var report := _report([&"rattata"], 57)
	var text := AwakeningOverlay.row_text(report.party[0], _data, 0)
	assert_false(text.contains("attaque"), text)
	assert_string_contains(AwakeningOverlay.row_text(report.party[0], _data, 1), "1 attaque à voir")
