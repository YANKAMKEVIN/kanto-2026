extends GutTest
## Lokhlass N15 de l'employé du 7F (jalon 26 T11, `jalon-26.md` §2.4, §3 T26-10 à T26-12, §5 ;
## défaut Q26-2 : seulement après la victoire contre le rival), avec la vraie scène Boot, la vraie
## carte `silph_co_7f`, le vrai départ `silph_7f_rival_charmander` et les vraies entrées :
## - avant la victoire contre le rival : réplique d'attente, aucun don ;
## - après : T26-10, puis le don d'un seul bloc (étape « gift_pokemon » du J20 : Pokémon et
##   drapeau `silph_lapras_received` ensemble), T26-11, T26-12 ;
## - équipe pleine → Stockage, avec la réplique du Stockage ;
## - don unique : reparler, recharger ou relancer l'application ne donne jamais un second
##   Lokhlass ; une application coupée avant l'autosave du don ne perd rien (le don est rejoué).

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const START := "res://tools/debug_start/silph_7f_rival_charmander.json"
const MAP := &"silph_co_7f"
const GIVER := &"silph_co_7f_lapras_giver"
const GIVER_CELL := Vector2i(1, 5)
const TALK_CELL := Vector2i(1, 6)
const FLAG := &"silph_lapras_received"
const WON := &"rival_silph_won"
const T26_10: Array[String] = ["Tu as battu ce garçon ?", "Alors tu peux protéger celui-ci.",
	"Les Rocket voulaient l'emporter."]
const T26_11 := "Kevin reçoit Lokhlass !"
const STORED := "Lokhlass a été envoyé au stockage."
const T26_12: Array[String] = ["Prends soin de lui.", "Il sait nager très loin."]
const WAITING: Array[String] = ["Ce garçon bloque le passage depuis tout à l'heure.",
	"On dirait qu'il attend quelqu'un."]

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, "user://test_silph_lapras.json")
	_play.setup()


func after_each() -> void:
	_play.teardown()


func _won(extra: int = 0) -> Callable:
	return func() -> void:
		GameState.flags.set_flag(WON)
		for i: int in extra:
			GameState.party.add(PokemonFactory.create(_play.boot.get_pokemon_data(), &"rattata",
				10, GameState.rng))


func _talk() -> void:
	await _play.walk_to(TALK_CELL)
	assert_eq(_play.player.get_cell(), TALK_CELL)
	_play.events.clear()
	await _play.interact(Vector2i.UP)


func _count_lapras() -> int:
	var count := 0
	for pokemon: Pokemon in GameState.party.get_all() + GameState.storage.get_all():
		if pokemon.species_id == &"lapras":
			count += 1
	return count


func test_giver_data() -> void:
	var spec := NpcRoster.load_for_map(MAP).get_spec(GIVER)
	assert_eq([spec.cell, spec.facing, spec.dialogue], [GIVER_CELL, Vector2i.DOWN, GIVER])
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir())
	var step := cutscenes.get_cutscene(&"silph_co_lapras_gift").variants[0].steps[0]
	assert_eq(step.kind, CutsceneStep.Kind.GIFT_POKEMON)
	assert_eq([step.species, step.level, step.gift_flag], [&"lapras", 15, FLAG],
		"Lokhlass N15 (RB), drapeau posé par le don lui-même")


func test_nothing_before_the_rival_is_beaten() -> void:
	await _play.start(START)
	# Le rival barre (3, 2) / (3, 3) : on rejoint l'employé par une téléportation de test.
	_play.boot.get_map().spawn_player_at(_play.player, TALK_CELL, Vector2i.UP)
	await wait_process_frames(3)
	_play.events.clear()
	await _play.interact(Vector2i.UP)
	assert_eq(_play.pages(), WAITING)
	assert_eq(_count_lapras(), 0)
	assert_false(GameState.flags.has_flag(FLAG))
	assert_push_error_count(0)


func test_after_the_victory_lapras_joins_the_party_once() -> void:
	await _play.start(START, _won())
	var size := GameState.party.size()
	assert_lt(size, 6)
	await _talk()
	assert_eq(_play.pages(), T26_10 + [T26_11] + T26_12, "T26-10, T26-11, T26-12")
	assert_eq(GameState.party.size(), size + 1)
	var lapras: Pokemon = GameState.party.get_at(size)
	assert_eq([lapras.species_id, lapras.level, lapras.origin, lapras.met_map],
		[&"lapras", 15, Pokemon.Origin.GIFT, MAP])
	assert_true(GameState.flags.has_flag(FLAG))
	assert_true(GameState.pokedex.is_caught(&"lapras"))
	# Reparler : T26-12 seulement.
	await _talk()
	assert_eq(_play.pages(), T26_12)
	assert_eq(_count_lapras(), 1, "pas de second Lokhlass")
	assert_push_error_count(0)


func test_a_full_party_sends_lapras_to_the_storage() -> void:
	await _play.start(START, _won(2))
	assert_eq(GameState.party.size(), 6)
	await _talk()
	assert_eq(_play.pages(), T26_10 + [T26_11, STORED] + T26_12)
	assert_eq(GameState.party.size(), 6, "équipe inchangée")
	assert_eq(GameState.storage.size(), 1)
	assert_eq(GameState.storage.get_at(0).species_id, &"lapras")
	assert_true(GameState.flags.has_flag(FLAG))
	assert_push_error_count(0)


func test_a_restart_after_the_gift_neither_loses_nor_duplicates() -> void:
	await _play.start(START, _won())
	# Autosave avant le don (application coupée pendant la scène : on reprend ici).
	_play.boot.request_autosave("test : avant le don")
	await wait_until(func() -> bool: return not _play.saved().is_empty(), 10.0)
	assert_false((_play.saved().get("flags", []) as Array).has(String(FLAG)))
	await _talk()
	assert_eq(_count_lapras(), 1)
	# Autosave du don (« don »), écrit avec le drapeau dans la même sauvegarde.
	await wait_until(func() -> bool:
		return (_play.saved().get("flags", []) as Array).has(String(FLAG)), 10.0)
	var saved := _play.saved()
	assert_true((saved.get("flags", []) as Array).has(String(FLAG)), "drapeau sauvé")
	assert_string_contains(JSON.stringify(saved), "lapras", "Lokhlass sauvé avec lui")
	await _play.resume()
	assert_eq(_play.map_id(), MAP)
	assert_eq(_count_lapras(), 1, "ni perte ni doublon")
	assert_true(GameState.flags.has_flag(FLAG))
	assert_false(_play.boot.get_cutscene_director().play(&"silph_co_lapras_gift"),
		"scène désarmée par le drapeau")
	await wait_until(func() -> bool: return _play.boot.is_stable(), 10.0)
	await _talk()
	assert_eq(_play.pages(), T26_12)
	assert_eq(_count_lapras(), 1)
	assert_push_error_count(0)
