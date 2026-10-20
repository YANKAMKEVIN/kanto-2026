extends GutTest
## Don d'Évoli dans le moteur (jalon 20 T12, `docs/tech/jalon-20.md` §2.5.2 ; dossier 23 §10, §19).
## Vraie scène Boot sur la carte de QA `qa_gift_j20` (retirée au T24) : la Poké Ball
## `eevee_ball` (données de QA) joue les vrais dialogue et scène (`celadon_eevee_ball`,
## `celadon_eevee_gift`).
## - équipe de 5 → Évoli rejoint l'équipe (T-29), origine « gift », Pokédex vu et capturé ;
## - équipe de 6 → Évoli au Stockage, T-29 puis T-30 ;
## - NON → rien ne change ;
## - la Poké Ball disparaît ; autosave écrit ; rechargement : Poké Ball absente, et rejouer la
##   scène ne donne pas de second Évoli.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_eevee_gift_save.json"
const MAP := &"qa_gift_j20"
const BALL := &"eevee_ball"
const FLAG := &"eevee_received"
const FADE := 0.05
const TIMEOUT := 15.0
const T28: Array[String] = ["Un Pokémon attend dans cette Poké Ball.", "Le prendre ?"]
const T29 := "Kevin reçoit Évoli !"
const T30 := "Évoli a été envoyé au stockage."

var _boot: Boot
var _fs: MemoryFs
var _saved_router: Array = []
var _pages: Array[String] = []
var _gifted: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-20T15:00:00")
	_fs = MemoryFs.new()
	_pages.clear()
	_gifted.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Input.action_release(&"interact")


func test_a_party_of_five_receives_eevee() -> void:
	await _start(5)
	await _take(true)
	assert_eq(_pages, T28 + [T29] as Array[String], "T-28, puis T-29 seul")
	assert_eq(GameState.party.size(), 6, "Évoli rejoint l'équipe")
	var eevee: Pokemon = GameState.party.get_at(5)
	assert_eq([eevee.species_id, eevee.level], [&"eevee", 25])
	assert_eq(eevee.origin, Pokemon.Origin.GIFT)
	assert_eq(eevee.met_map, MAP)
	assert_false(eevee.uid.is_empty(), "identifiant attribué")
	assert_eq(GameState.storage.size(), 0)
	assert_true(GameState.flags.has_flag(FLAG))
	assert_true(GameState.pokedex.is_seen(&"eevee"), "Pokédex : vu")
	assert_true(GameState.pokedex.is_caught(&"eevee"), "Pokédex : capturé")
	assert_eq(_gifted, [[&"eevee", false]], "signal pokemon_gifted")
	assert_null(_boot.get_map().get_npc(BALL), "la Poké Ball disparaît")
	assert_push_error_count(0)


func test_a_full_party_sends_eevee_to_the_storage() -> void:
	await _start(6)
	await _take(true)
	assert_eq(_pages, T28 + [T29, T30] as Array[String], "T-29 puis T-30")
	assert_eq(GameState.party.size(), 6, "équipe inchangée")
	assert_eq(GameState.storage.size(), 1, "Évoli au Stockage")
	var eevee: Pokemon = GameState.storage.get_at(0)
	assert_eq([eevee.species_id, eevee.origin], [&"eevee", Pokemon.Origin.GIFT])
	assert_false(eevee.uid.is_empty(), "identifiant attribué par le Stockage")
	assert_true(GameState.flags.has_flag(FLAG))
	assert_true(GameState.pokedex.is_caught(&"eevee"))
	assert_eq(_gifted, [[&"eevee", true]])
	assert_null(_boot.get_map().get_npc(BALL))
	assert_push_error_count(0)


func test_no_leaves_the_ball() -> void:
	await _start(5)
	await _take(false)
	assert_eq(_pages, T28, "rien après NON")
	assert_eq(GameState.party.size(), 5)
	assert_false(GameState.flags.has_flag(FLAG))
	assert_false(GameState.pokedex.is_seen(&"eevee"))
	assert_not_null(_boot.get_map().get_npc(BALL), "la Poké Ball reste")


func test_after_reload_there_is_no_second_eevee() -> void:
	await _start(5)
	await _take(true)
	# Autosave du don, écrit une fois la scène finie (partie stable).
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while not _fs.read_text(SAVE_PATH).contains("eevee") and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
	var saved := _fs.read_text(SAVE_PATH)
	assert_string_contains(saved, "\"gift\"", "origine « gift » sauvée")
	assert_string_contains(saved, String(FLAG))
	_boot.queue_free()
	await wait_process_frames(2)
	# Nouvelle session sur la même sauvegarde : reprise dans la pièce.
	await _boot_on(_fs)
	assert_eq(_boot.get_map().map_id, MAP, "reprise dans la pièce")
	assert_null(_boot.get_map().get_npc(BALL), "Poké Ball absente au rechargement")
	assert_eq(_count_eevee(), 1)
	var director := _boot.get_cutscene_director()
	assert_false(director.play(&"celadon_eevee_gift"), "scène désarmée par le drapeau")
	# Même étape jouée malgré tout (autre scène) : déjà reçu, rien ne se passe, aucun texte.
	assert_true(_boot.get_cutscene_library().add_from_dict({"qa_gift_again": {"steps": [
		{"gift_pokemon": "eevee", "level": 25, "flag": String(FLAG),
			"say": "celadon_eevee_received"}]}}, "test"))
	_pages.clear()
	assert_true(director.play(&"qa_gift_again"))
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	assert_eq(_pages, [] as Array[String], "aucun texte")
	assert_eq(_count_eevee(), 1, "pas de second Évoli")
	assert_eq(_gifted, [[&"eevee", false]], "aucun second signal")


# --- Outils -----------------------------------------------------------------------------------

## Boot neuve sur la pièce, équipe de [param party_size] Rattata.
func _start(party_size: int) -> void:
	await _boot_on(_fs)
	GameState.new_game(7)
	GameState.player_name = "Kevin"
	for i: int in party_size:
		GameState.party.add(PokemonFactory.create(_boot.get_pokemon_data(), &"rattata", 10,
			GameState.rng))
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _boot_on(fs: MemoryFs) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(fs, SAVE_PATH)
	_boot.start_map = MAP
	_boot.start_spawn = &"start"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	var runner := _boot.get_dialogue_runner()
	runner.chars_per_second = 0.0
	runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	_boot.get_cutscene_director().pokemon_gifted.connect(
		func(pokemon: Pokemon, stored: bool) -> void: _gifted.append([pokemon.species_id, stored]))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## Examine la Poké Ball (devant elle, tourné ↑) ; [param answer] au choix.
func _take(answer: bool) -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	await wait_process_frames(2)
	while (director.is_running() or runner.is_running()) and Time.get_ticks_msec() < deadline:
		if runner.is_awaiting_choice():
			runner.choose(answer)
		elif box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _count_eevee() -> int:
	var count := 0
	for pokemon: Pokemon in GameState.party.get_all() + GameState.storage.get_all():
		if pokemon.species_id == &"eevee":
			count += 1
	return count
