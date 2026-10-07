extends GutTest
## EvolutionDirector (jalon-09.md §2.3, T8) : ordre du contrat avec l'écran (faux écran qui
## note les appels), évolution appliquée seulement après une transformation menée à son terme,
## annulation par le retour Android, Pokédex, textes du lot verrouillé (bloc B) mot pour mot,
## capacités de la nouvelle espèce par le MoveLearnPrompt (apprise, ou offre d'oubli), et sans
## écran : évolution immédiate.

const GAME_STATE := preload("res://game/autoload/game_state.gd")
const BANNER_SCENE := preload("res://game/ui/battle/battle_message_banner.tscn")
const FakeScreen := preload("res://tests/helpers/fake_evolution_screen.gd")


var _data: PokemonData
var _texts: BattleText
var _state: Node
var _learn: MoveLearnPrompt
var _director: EvolutionDirector
var _screen: FakeScreen
var _messages: Array[String] = []


func before_each() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_texts = BattleText.new()
	_texts.load_file()
	_state = GAME_STATE.new()
	add_child_autofree(_state)
	_learn = MoveLearnPrompt.new()
	_learn.speed_scale = 0.0
	_learn.haptics_enabled = false
	add_child_autofree(_learn)
	_learn.setup(_data, _texts)
	_director = EvolutionDirector.new()
	_director.speed_scale = 0.0
	add_child_autofree(_director)
	_director.setup(_state, _data, _texts, _learn)
	_messages.clear()


## Un faux écran branché, avec un vrai bandeau et un parent plein écran pour les panneaux.
func _with_screen() -> FakeScreen:
	_screen = FakeScreen.new()
	_screen.back = _director.handle_back
	add_child_autofree(_screen)
	_screen.host = Control.new()
	_screen.host.size = Vector2(1920, 1080)
	_screen.add_child(_screen.host)
	_screen.banner = BANNER_SCENE.instantiate() as BattleMessageBanner
	_screen.host.add_child(_screen.banner)
	_screen.banner.speed_scale = 0.0
	_screen.banner.message_shown.connect(func(text: String, _wait: bool) -> void:
		_messages.append(text))
	_director.set_screen(_screen)
	return _screen


func _party(members: Array) -> Party:
	var party := Party.new()
	for m: Array in members:
		party.add(PokemonFactory.create(_data, m[0], m[1], GameRng.new(7)))
	return party


func _candidates(party: Party, indices: Array) -> Array[EvolutionCandidate]:
	var leveled: Array[int] = []
	leveled.assign(indices)
	return Evolution.candidates(party, leveled, _data)


func test_without_a_screen_the_evolution_happens_at_once() -> void:
	var party := _party([[&"caterpie", 7]])
	var started: Array = []
	var finished: Array = []
	_director.evolution_started.connect(func(i: int, into: StringName) -> void:
		started.append([i, into]))
	_director.evolution_finished.connect(func(i: int, into: StringName, c: bool) -> void:
		finished.append([i, into, c]))
	await _director.play(_candidates(party, [0]), party)
	var pokemon := party.get_lead()
	assert_eq(pokemon.species_id, &"metapod")
	assert_true(pokemon.knows_move(&"harden"), "Armure apprise (place libre)")
	assert_true(_state.pokedex.is_caught(&"metapod"), "Pokédex : possédé")
	assert_eq(_state.pokedex.times_caught(&"metapod"), 0, "pas une capture")
	assert_eq(started, [[0, &"metapod"]])
	assert_eq(finished, [[0, &"metapod", false]])
	assert_false(_director.is_playing())
	assert_false(_director.handle_back(), "hors évolution, le retour ne sert pas")


func test_the_screen_contract_order_and_the_evolution_applied_after_the_transformation() -> void:
	var screen := _with_screen()
	var party := _party([[&"caterpie", 7]])
	var pokemon := party.get_lead()
	var during: Array = []
	screen.probe = func() -> void:
		during.append([pokemon.species_id, _state.pokedex.is_seen(&"metapod"),
			_director.is_playing()])
	await _director.play(_candidates(party, [0]), party)
	assert_eq(screen.calls, ["open", "present", "transform", "reveal", "close"] as Array[String])
	assert_eq(during, [[&"caterpie", false, true]], "rien ne change pendant la transformation")
	assert_eq(pokemon.species_id, &"metapod")
	assert_eq(screen.speed_scale, 0.0, "durées relayées à l'écran")
	assert_eq(_messages, ["Chrysacier apprend Armure !"] as Array[String],
		"capacité dans le bandeau de l'écran, avec le nouveau nom")
	assert_true(pokemon.knows_move(&"harden"))
	assert_push_error_count(0)


func test_view_texts_are_the_locked_ones_word_for_word() -> void:
	var screen := _with_screen()
	var party := _party([[&"caterpie", 7], [&"charmander", 16]])
	party.get_at(1).nickname = "Flammy"
	await _director.play(_candidates(party, [0, 1]), party)
	assert_eq(screen.views.size(), 2)
	var first := screen.views[0]
	assert_eq(first.started_text, "Quoi ? Chenipan évolue !")
	assert_eq(first.finished_text, "Félicitations ! Chenipan a évolué en Chrysacier !")
	assert_eq(first.cancelled_text, "Hein ? Chenipan n'évolue plus.")
	assert_eq(first.stop_label, "ARRÊTER")
	assert_eq(first.continue_text, "Touchez l'écran pour continuer")
	assert_eq([first.party_index, first.pokemon_name, first.from_name, first.into_name],
		[0, "Chenipan", "Chenipan", "Chrysacier"])
	assert_eq([first.from_species, first.into_species, first.from_dex, first.into_dex],
		[&"caterpie", &"metapod", 10, 11])
	var second := screen.views[1]
	assert_eq(second.finished_text, "Félicitations ! Flammy a évolué en Reptincel !")
	assert_eq(second.started_text, "Quoi ? Flammy évolue !")
	assert_eq(screen.calls, ["open", "present", "transform", "reveal", "present", "transform",
		"reveal", "close"] as Array[String], "l'écran ouvert une seule fois pour deux évolutions")


func test_back_during_the_transformation_cancels_and_nothing_changes() -> void:
	var screen := _with_screen()
	screen.cancel = true
	var party := _party([[&"caterpie", 7]])
	var pokemon := party.get_lead()
	var max_hp := pokemon.max_hp()
	var finished: Array = []
	_director.evolution_finished.connect(func(i: int, into: StringName, c: bool) -> void:
		finished.append([i, into, c]))
	await _director.play(_candidates(party, [0]), party)
	assert_eq(screen.back_answers, [true] as Array[bool], "le retour est consommé")
	assert_eq(screen.calls, ["open", "present", "transform", "revert", "close"] as Array[String])
	assert_eq(pokemon.species_id, &"caterpie", "annulée : même espèce")
	assert_eq(pokemon.max_hp(), max_hp)
	assert_false(pokemon.knows_move(&"harden"), "aucune capacité")
	assert_false(_state.pokedex.is_seen(&"metapod"), "Pokédex inchangé")
	assert_eq(_messages, [] as Array[String])
	assert_eq(finished, [[0, &"metapod", true]])
	# Reproposée au prochain niveau gagné (aucun état gardé) : cette fois, elle se fait.
	pokemon.gain_exp(ExpCurve.exp_for_level(_data.get_species(&"caterpie").growth_rate, 8)
		- pokemon.experience, _data)
	screen.cancel = false
	await _director.play(_candidates(party, [0]), party)
	assert_eq(pokemon.species_id, &"metapod")
	assert_true(pokemon.knows_move(&"harden"), "Armure quand même au niveau 8 (Q-5)")


func test_a_full_moveset_opens_the_forget_offer_in_the_screen() -> void:
	var screen := _with_screen()
	var party := _party([[&"caterpie", 7]])
	var pokemon := party.get_lead()
	for move_id: StringName in [&"growl", &"scratch"]:
		pokemon.learn_move(move_id, _data)
	assert_eq(pokemon.moves.size(), 4)
	var seen: Dictionary = {}
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await _director.play(_candidates(party, [0]), party)
		done[0] = true
	runner.call()
	var deadline := Time.get_ticks_msec() + 10000
	while not done[0] and Time.get_ticks_msec() < deadline:
		var panel := _learn.get_forget_panel()
		if panel != null and panel.is_shown() and not panel.is_answered():
			seen["parent"] = panel.get_parent() == screen.host
			seen["banner_out"] = not screen.banner.is_shown()
			seen["new"] = panel.get_new_card().get_view().display_name
			await wait_process_frames(2)
			panel.get_skip_button().pressed.emit()
		await wait_process_frames(1)
	assert_true(done[0], "les évolutions se sont terminées")
	assert_true(seen.get("parent", false), "panneau dans l'écran d'évolution")
	assert_true(seen.get("banner_out", false), "le bandeau sort avant le panneau")
	assert_eq(seen.get("new"), "Armure")
	assert_eq(_messages, ["Chrysacier veut apprendre Armure, mais connaît déjà quatre capacités.",
		"Chrysacier n'apprend pas Armure."] as Array[String], "offre puis refus")
	assert_eq(pokemon.species_id, &"metapod")
	assert_false(pokemon.knows_move(&"harden"))
	assert_null(_learn.get_forget_panel(), "panneau libéré à la fermeture")


func test_an_impossible_candidate_is_skipped_with_an_error() -> void:
	var party := _party([[&"caterpie", 7]])
	var stale := EvolutionCandidate.new(0, &"weedle", &"kakuna")
	await _director.play([stale] as Array[EvolutionCandidate], party)
	assert_push_error("évolution impossible")
	assert_eq(party.get_lead().species_id, &"caterpie")
	assert_false(_director.is_playing())
