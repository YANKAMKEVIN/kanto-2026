extends GutTest
## Don de Pokémon, logique pure (jalon 20, T6 ; jalon-20.md §2.5.1 ; dossier 23 §10, §19).
## Évoli n'est pas encore dans les données de main : Pikachu N25 le remplace ici (la logique ne
## dépend d'aucune espèce).

const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const DATE := "2026-10-15T10:00:00"
const SPECIES: StringName = &"pikachu"
const LEVEL: int = 25
const MAP: StringName = &"celadon_mansion_roof_house"
const FLAG: StringName = &"eevee_received"

var _data: PokemonData
var _state: Node


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_state = load("res://game/autoload/game_state.gd").new()
	_state.new_game(20)
	_state.clock = FixedClock.new(DATE)
	_state.player_name = "Kevin"


func after_each() -> void:
	_state.free()


## Équipe de [param count] Rattata.
func _fill_party(count: int) -> void:
	for i: int in count:
		_state.party.add(PokemonFactory.create(_data, &"rattata", 5, _state.rng))


func _give(flag: StringName = FLAG) -> GiftResult:
	return PokemonGift.give(_state, _data, SPECIES, LEVEL, MAP, flag)


func test_party_of_five_joins() -> void:
	_fill_party(5)
	var result := _give()
	assert_eq(result.status, PokemonGift.Status.JOINED)
	assert_true(result.is_given())
	assert_false(result.is_stored())
	assert_eq(_state.party.size(), 6)
	assert_same(_state.party.get_at(5), result.pokemon)
	assert_eq(_state.storage.size(), 0)
	assert_false(result.pokemon.uid.is_empty(), "identifiant attribué par l'équipe")


func test_full_party_goes_to_storage() -> void:
	_fill_party(6)
	var result := _give()
	assert_eq(result.status, PokemonGift.Status.STORED)
	assert_true(result.is_given())
	assert_true(result.is_stored())
	assert_eq(_state.party.size(), 6)
	assert_eq(_state.storage.size(), 1)
	assert_same(_state.storage.get_at(0), result.pokemon)
	assert_false(result.pokemon.uid.is_empty(), "identifiant attribué par le Stockage")


func test_flag_is_set_with_the_gift() -> void:
	_fill_party(1)
	assert_false(_state.flags.has_flag(FLAG))
	_give()
	assert_true(_state.flags.has_flag(FLAG))


func test_second_gift_is_refused_and_changes_nothing() -> void:
	_fill_party(1)
	_give()
	var before: Dictionary = _state.to_dict()
	var result := _give()
	assert_eq(result.status, PokemonGift.Status.ALREADY_RECEIVED)
	assert_false(result.is_given())
	assert_null(result.pokemon)
	assert_eq(_state.party.size(), 2)
	assert_eq(_state.storage.size(), 0)
	assert_eq(_state.pokedex.times_caught(SPECIES), 1)
	assert_eq(_state.to_dict(), before, "rien ne change, pas même l'aléatoire")


func test_flag_already_set_refuses_even_first_time() -> void:
	_fill_party(1)
	_state.flags.set_flag(FLAG)
	var result := _give()
	assert_eq(result.status, PokemonGift.Status.ALREADY_RECEIVED)
	assert_eq(_state.party.size(), 1)
	assert_false(_state.pokedex.is_seen(SPECIES))


func test_other_flag_gives_again() -> void:
	_fill_party(1)
	_give()
	var result := _give(&"other_gift_received")
	assert_eq(result.status, PokemonGift.Status.JOINED, "unicité par drapeau, pas par espèce")
	assert_eq(_state.party.size(), 3)


func test_pokedex_seen_and_caught_dated() -> void:
	_fill_party(1)
	_give()
	assert_true(_state.pokedex.is_seen(SPECIES))
	assert_true(_state.pokedex.is_caught(SPECIES))
	var entry: PokedexEntry = _state.pokedex.get_entry(SPECIES)
	assert_eq(entry.first_caught_map, MAP)
	assert_eq(entry.first_caught_date, DATE)
	assert_eq(entry.first_seen_map, MAP)


func test_level_and_moves_of_the_level() -> void:
	_fill_party(1)
	var pokemon := _give().pokemon
	assert_eq(pokemon.species_id, SPECIES)
	assert_eq(pokemon.level, LEVEL)
	var expected: Array[StringName] = _data.get_species(SPECIES).moves_at(LEVEL)
	var known: Array[StringName] = []
	for slot: MoveSlot in pokemon.moves:
		known.append(slot.move_id)
	assert_eq(known, expected, "capacités apprises au niveau du don")
	assert_eq(pokemon.hp, pokemon.max_hp(), "PV pleins")


func test_meeting_is_stamped() -> void:
	_fill_party(1)
	var pokemon := _give().pokemon
	assert_eq(pokemon.origin, PokemonGift.ORIGIN)
	assert_eq(pokemon.met_map, MAP)
	assert_eq(pokemon.met_level, LEVEL)
	assert_eq(pokemon.met_date, DATE)
	assert_eq(pokemon.original_trainer, "Kevin")
	assert_eq(pokemon.nickname, "", "aucun surnom")


func test_no_moment_recorded() -> void:
	_fill_party(1)
	_give()
	assert_eq(_state.moments.size(), 0, "le don n'est pas une première capture")


func test_unknown_species_changes_nothing() -> void:
	_fill_party(1)
	var before: Dictionary = _state.to_dict()
	var result := PokemonGift.give(_state, _data, &"missingno", LEVEL, MAP, FLAG)
	assert_eq(result.status, PokemonGift.Status.UNKNOWN_SPECIES)
	assert_null(result.pokemon)
	assert_eq(_state.to_dict(), before)


func test_invalid_calls_change_nothing() -> void:
	_fill_party(1)
	var before: Dictionary = _state.to_dict()
	assert_eq(PokemonGift.give(null, _data, SPECIES, LEVEL, MAP, FLAG).status,
		PokemonGift.Status.INVALID)
	assert_eq(PokemonGift.give(_state, null, SPECIES, LEVEL, MAP, FLAG).status,
		PokemonGift.Status.INVALID)
	assert_eq(_give(&"").status, PokemonGift.Status.INVALID)
	assert_eq(PokemonGift.give(_state, _data, SPECIES, 0, MAP, FLAG).status,
		PokemonGift.Status.INVALID)
	assert_eq(_state.to_dict(), before)


## Atomicité vis-à-vis de la sauvegarde : juste après le don, l'état sauvé contient à la fois
## le Pokémon (avec son identifiant et sa rencontre) et le drapeau ; rechargé, un second don
## est refusé.
func test_save_round_trip_keeps_gift_and_flag() -> void:
	_fill_party(6)
	var given := _give().pokemon
	var dict: Dictionary = JSON.parse_string(JSON.stringify(_state.to_dict()))
	var loaded: Node = load("res://game/autoload/game_state.gd").new()
	assert_true(loaded.load_dict(dict, _data))
	assert_true(loaded.flags.has_flag(FLAG))
	assert_eq(loaded.storage.size(), 1)
	var back: Pokemon = loaded.storage.get_at(0)
	assert_eq(back.uid, given.uid)
	assert_eq(back.species_id, SPECIES)
	assert_eq(back.origin, PokemonGift.ORIGIN)
	assert_eq(back.met_map, MAP)
	assert_true(loaded.pokedex.is_caught(SPECIES))
	var again := PokemonGift.give(loaded, _data, SPECIES, LEVEL, MAP, FLAG)
	assert_eq(again.status, PokemonGift.Status.ALREADY_RECEIVED)
	assert_eq(loaded.storage.size(), 1)
	loaded.free()
