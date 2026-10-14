extends GutTest
## Évolution par pierre (jalon 12, T23 ; `jalon-12.md` §2.9) : [method EvolutionDirector.play_item]
## non annulable (retour Android absorbé sans effet, aucune réponse « annulée » prise),
## [signal EvolutionDirector.evolution_applied] émis une fois, dans l'appel qui applique
## l'évolution, avant la révélation ; jamais pour une évolution annulée ; les évolutions de fin de
## combat restent annulables. Écran réel : pas d'ARRÊTER, retour sans effet pendant la
## transformation.

const GAME_STATE := preload("res://game/autoload/game_state.gd")
const FakeScreen := preload("res://tests/helpers/fake_evolution_screen.gd")
const SCENE := preload("res://game/ui/evolution/evolution_screen.tscn")
const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const STEP := 1.0 / 60.0
const STONE := &"moon_stone"

var _data: PokemonData
var _texts: BattleText
var _state: Node
var _director: EvolutionDirector
var _applied: Array = []


func before_each() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_texts = BattleText.new()
	_texts.load_file()
	_state = GAME_STATE.new()
	add_child_autofree(_state)
	_director = EvolutionDirector.new()
	_director.speed_scale = 0.0
	add_child_autofree(_director)
	_director.setup(_state, _data, _texts, null)
	_applied.clear()


func after_each() -> void:
	Haptics.reset()


func _with_screen() -> FakeScreen:
	var screen := FakeScreen.new()
	screen.back = _director.handle_back
	add_child_autofree(screen)
	_director.set_screen(screen)
	return screen


func _party(species: Array[StringName]) -> Party:
	var party := Party.new()
	for id: StringName in species:
		party.add(PokemonFactory.create(_data, id, 20, GameRng.new(7)))
	return party


func test_back_is_absorbed_and_does_not_stop_a_stone_evolution() -> void:
	var screen := _with_screen()
	screen.cancel = true
	var party := _party([&"pikachu", &"clefairy"] as Array[StringName])
	var finished: Array = []
	_director.evolution_finished.connect(func(i: int, into: StringName, c: bool) -> void:
		finished.append([i, into, c]))
	var candidate := StoneUse.candidate(party, 1, STONE, _data)
	await _director.play_item(candidate, party, STONE)
	assert_eq(screen.back_answers, [true] as Array[bool], "retour consommé…")
	assert_eq(screen.calls, ["open", "present", "transform", "reveal", "close"] as Array[String],
		"…sans effet : jamais revert")
	assert_eq(party.get_at(1).species_id, &"clefable", "évolution faite")
	assert_eq(finished, [[1, &"clefable", false]])
	assert_false(screen.views[0].cancellable, "vue non annulable (pas d'ARRÊTER)")
	assert_eq(screen.views[0].stop_label, "ARRÊTER", "libellé gardé (l'écran ne le montre pas)")
	assert_true(_state.pokedex.is_caught(&"clefable"), "Pokédex : vu et possédé")
	assert_false(_director.is_playing())


func test_play_item_copies_the_candidate_as_not_cancellable() -> void:
	var screen := _with_screen()
	screen.cancel = true
	var party := _party([&"jigglypuff"] as Array[StringName])
	# Même un candidat construit à la main (annulable) est joué sans arrêt possible.
	var candidate := EvolutionCandidate.new(0, &"jigglypuff", &"wigglytuff")
	await _director.play_item(candidate, party, STONE)
	assert_eq(party.get_lead().species_id, &"wigglytuff")
	assert_true(candidate.cancellable, "le candidat de l'appelant n'est pas modifié")


func test_evolution_applied_once_in_the_call_that_applies_it_before_the_reveal() -> void:
	var screen := _with_screen()
	var party := _party([&"nidorina"] as Array[StringName])
	var pokemon := party.get_lead()
	_director.evolution_applied.connect(func(i: int, into: StringName) -> void:
		_applied.append([i, into, pokemon.species_id, screen.calls.duplicate(),
			_state.pokedex.is_caught(&"nidoqueen")]))
	await _director.play_item(StoneUse.candidate(party, 0, STONE, _data), party, STONE)
	assert_eq(_applied.size(), 1, "une seule fois")
	assert_eq(_applied[0], [0, &"nidoqueen", &"nidoqueen",
		["open", "present", "transform"] as Array[String], true],
		"déjà évolué, Pokédex à jour, avant la révélation")


func test_evolution_applied_without_a_screen() -> void:
	var party := _party([&"nidorino"] as Array[StringName])
	_director.evolution_applied.connect(func(i: int, into: StringName) -> void:
		_applied.append([i, into]))
	await _director.play_item(StoneUse.candidate(party, 0, STONE, _data), party, STONE)
	assert_eq(_applied, [[0, &"nidoking"]])
	assert_eq(party.get_lead().species_id, &"nidoking")


func test_null_candidate_does_nothing() -> void:
	var party := _party([&"clefairy"] as Array[StringName])
	await _director.play_item(null, party, STONE)
	assert_false(_director.is_playing())
	assert_eq(party.get_lead().species_id, &"clefairy")


func test_battle_evolutions_stay_cancellable_and_cancelled_is_never_applied() -> void:
	var screen := _with_screen()
	screen.cancel = true
	var party := Party.new()
	party.add(PokemonFactory.create(_data, &"caterpie", 7, GameRng.new(7)))
	_director.evolution_applied.connect(func(i: int, into: StringName) -> void:
		_applied.append([i, into]))
	var leveled: Array[int] = [0]
	await _director.play(Evolution.candidates(party, leveled, _data), party)
	assert_true(screen.views[0].cancellable, "fin de combat : ARRÊTER")
	assert_eq(screen.calls, ["open", "present", "transform", "revert", "close"] as Array[String])
	assert_eq(party.get_lead().species_id, &"caterpie", "annulée")
	assert_eq(_applied, [], "rien d'appliqué")
	# Et sans annulation : appliquée, signal émis.
	screen.cancel = false
	await _director.play(Evolution.candidates(party, leveled, _data), party)
	assert_eq(_applied, [[0, &"metapod"]])


# --- Écran réel ---------------------------------------------------------------------------

func _view(cancellable: bool) -> EvolutionView:
	var view := EvolutionView.new()
	view.party_index = 0
	view.pokemon_name = "Mélofée"
	view.from_species = &"clefairy"
	view.into_species = &"clefable"
	view.from_name = "Mélofée"
	view.into_name = "Mélodelfe"
	view.from_dex = 35
	view.into_dex = 36
	view.started_text = "Quoi ? Mélofée évolue !"
	view.finished_text = "Félicitations ! Mélofée a évolué en Mélodelfe !"
	view.cancelled_text = "Hein ? Mélofée n'évolue plus."
	view.stop_label = "ARRÊTER"
	view.continue_text = "Touchez l'écran pour continuer"
	view.cancellable = cancellable
	return view


func _start(call: Callable) -> Array:
	var box: Array = [false, null]
	var runner := func() -> void:
		box[1] = await call.call()
		box[0] = true
	runner.call()
	return box


func test_real_screen_has_no_stop_and_ignores_back_for_a_stone() -> void:
	Haptics.sink = func(_ms: int) -> void: pass
	var screen := SCENE.instantiate() as EvolutionScreen
	add_child_autofree(screen)
	var clock := TweenClock.new(get_tree())
	var opening := _start(screen.open)
	clock.call(&"run_until", func() -> bool: return opening[0], 5.0)
	var presenting := _start(screen.present.bind(_view(false)))
	clock.call(&"run_until", func() -> bool: return presenting[0], 5.0)
	assert_false(screen.is_cancellable())
	var transforming := _start(screen.transform)
	assert_true(screen.is_transforming())
	assert_false(screen.is_stop_active(), "pas d'ARRÊTER")
	assert_false(screen.get_stop_button().visible, "bouton caché")
	for i: int in roundi(1.5 / STEP):
		clock.call(&"step")
	assert_true(screen.handle_back(), "retour consommé…")
	assert_false(transforming[0], "…sans effet : la transformation continue")
	clock.call(&"run_until", func() -> bool: return transforming[0], 20.0)
	assert_true(transforming[0])
	assert_false(transforming[1], "menée à son terme")
	assert_true(screen.is_showing_new_form())
	clock.release()


func test_real_screen_still_offers_stop_for_a_battle_evolution() -> void:
	var screen := SCENE.instantiate() as EvolutionScreen
	add_child_autofree(screen)
	var clock := TweenClock.new(get_tree())
	var opening := _start(screen.open)
	clock.call(&"run_until", func() -> bool: return opening[0], 5.0)
	var presenting := _start(screen.present.bind(_view(true)))
	clock.call(&"run_until", func() -> bool: return presenting[0], 5.0)
	var transforming := _start(screen.transform)
	assert_true(screen.is_stop_active(), "ARRÊTER visible et actif")
	assert_true(screen.handle_back())
	assert_true(transforming[0], "annulée aussitôt")
	assert_true(transforming[1])
	clock.release()
