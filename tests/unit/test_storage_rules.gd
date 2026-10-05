extends GutTest
## StorageRules : règles métier du Stockage Pokémon V1 (dossier 09 §8, §19 ; jalon-07.md §3.5 ;
## Q-7 : « au moins un Pokémon en état de combattre »).

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")

const PARTY := StorageRules.Place.PARTY
const STORAGE := StorageRules.Place.STORAGE

var _data: PokemonData
var _rng: GameRng
var _party: Party
var _storage: PokemonStorage


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_rng = GameRng.new(11)
	_party = Party.new()
	_storage = PokemonStorage.new()


func _mon(species: StringName = &"pidgey", level: int = 5) -> Pokemon:
	return PokemonFactory.create(_data, species, level, _rng)


func _fill_party(count: int) -> Array[Pokemon]:
	var added: Array[Pokemon] = []
	for i: int in count:
		var pokemon := _mon(&"rattata", 3 + i)
		_party.add(pokemon)
		added.append(pokemon)
	return added


func _faint(pokemon: Pokemon) -> void:
	pokemon.take_damage(pokemon.hp)


# --- Déposer ---------------------------------------------------------------------------------

func test_deposit_moves_the_same_instance_to_the_end_of_the_storage() -> void:
	var members := _fill_party(3)
	_storage.add(_mon(&"pidgey"))
	var result := StorageRules.deposit(_party, _storage, 1)
	assert_true(result.is_ok())
	assert_eq(result.status, StorageRules.Status.OK)
	assert_same(result.pokemon, members[1])
	assert_eq(_party.get_all(), [members[0], members[2]] as Array[Pokemon])
	assert_same(_storage.get_at(1), members[1], "ordre d'arrivée : à la fin")
	assert_true(result.selection.equals(StorageSelection.new(STORAGE, 1)),
		"la sélection suit le Pokémon déposé")


func test_deposit_the_only_pokemon_is_refused_and_nothing_changes() -> void:
	var members := _fill_party(1)
	assert_eq(StorageRules.can_deposit(_party, 0), StorageRules.Status.LAST_POKEMON)
	var result := StorageRules.deposit(_party, _storage, 0)
	assert_eq(result.status, StorageRules.Status.LAST_POKEMON)
	assert_same(result.pokemon, members[0])
	assert_true(result.selection.equals(StorageSelection.new(PARTY, 0)), "la carte refusée")
	assert_eq(_party.size(), 1)
	assert_true(_storage.is_empty())


func test_deposit_the_last_able_pokemon_is_refused_q7() -> void:
	var members := _fill_party(2)
	_faint(members[1])
	assert_eq(StorageRules.can_deposit(_party, 0), StorageRules.Status.LAST_ABLE,
		"il ne resterait qu'un K.O. : raison distincte de l'équipe vide")
	assert_eq(StorageRules.can_deposit(_party, 1), StorageRules.Status.OK,
		"déposer le K.O. laisse un Pokémon valide")
	assert_true(StorageRules.deposit(_party, _storage, 1).is_ok())
	assert_eq(_party.get_all(), [members[0]] as Array[Pokemon])


func test_deposit_a_fainted_pokemon_when_no_able_one_would_remain_is_refused() -> void:
	var members := _fill_party(2)
	_faint(members[0])
	_faint(members[1])
	assert_eq(StorageRules.can_deposit(_party, 1), StorageRules.Status.LAST_ABLE)
	var result := StorageRules.deposit(_party, _storage, 1)
	assert_eq(result.status, StorageRules.Status.LAST_ABLE)
	assert_eq(result.action, StorageRules.Action.NONE, "un refus n'a pas d'action")
	assert_eq(_party.size(), 2)
	assert_true(_storage.is_empty())


func test_deposit_a_lone_fainted_pokemon_would_empty_the_party() -> void:
	var members := _fill_party(1)
	_faint(members[0])
	assert_eq(StorageRules.can_deposit(_party, 0), StorageRules.Status.LAST_POKEMON,
		"l'équipe serait vide : la raison « vide » l'emporte")


func test_keep_status_distinguishes_empty_and_all_fainted() -> void:
	var members := _fill_party(3)
	assert_eq(StorageRules.keep_status(_party, 0), StorageRules.Status.OK)
	_faint(members[1])
	_faint(members[2])
	assert_eq(StorageRules.keep_status(_party, 0), StorageRules.Status.LAST_ABLE)
	assert_eq(StorageRules.keep_status(_party, 1), StorageRules.Status.OK)
	var lone := Party.new()
	lone.add(_mon())
	assert_eq(StorageRules.keep_status(lone, 0), StorageRules.Status.LAST_POKEMON)


func test_each_success_carries_its_action() -> void:
	_fill_party(3)
	_storage.add(_mon())
	assert_eq(StorageRules.deposit(_party, _storage, 0).action, StorageRules.Action.DEPOSIT)
	assert_eq(StorageRules.withdraw(_party, _storage, 0).action, StorageRules.Action.WITHDRAW)
	assert_eq(StorageRules.toggle_favorite(_party, _storage, PARTY, 0).action,
		StorageRules.Action.FAVORITE)
	assert_eq(StorageRules.release(_party, _storage, STORAGE, 0).action,
		StorageRules.Action.RELEASE)
	assert_eq(StorageRules.release(_party, _storage, STORAGE, 9).action,
		StorageRules.Action.NONE, "refus : aucune action")


func test_deposit_an_unknown_place_is_not_found() -> void:
	_fill_party(2)
	assert_eq(StorageRules.can_deposit(_party, 5), StorageRules.Status.NOT_FOUND)
	assert_eq(StorageRules.can_deposit(_party, -1), StorageRules.Status.NOT_FOUND)
	var result := StorageRules.deposit(_party, _storage, 5)
	assert_eq(result.status, StorageRules.Status.NOT_FOUND)
	assert_null(result.pokemon)
	assert_eq(_party.size(), 2)


# --- Reprendre -------------------------------------------------------------------------------

func test_withdraw_moves_the_same_instance_to_the_end_of_the_party() -> void:
	var members := _fill_party(2)
	var first := _mon(&"pidgey")
	var second := _mon(&"rattata")
	_storage.add(first)
	_storage.add(second)
	var result := StorageRules.withdraw(_party, _storage, 0)
	assert_true(result.is_ok())
	assert_eq(_party.get_all(), [members[0], members[1], first] as Array[Pokemon])
	assert_eq(_storage.get_all(), [second] as Array[Pokemon], "les autres gardent leur ordre")
	assert_true(result.selection.equals(StorageSelection.new(PARTY, 2)))


func test_withdraw_with_a_full_party_is_refused_and_nothing_changes() -> void:
	_fill_party(Party.MAX_SIZE)
	var stored := _mon(&"pidgey")
	_storage.add(stored)
	assert_eq(StorageRules.can_withdraw(_party, _storage, 0), StorageRules.Status.PARTY_FULL)
	var result := StorageRules.withdraw(_party, _storage, 0)
	assert_eq(result.status, StorageRules.Status.PARTY_FULL)
	assert_same(result.pokemon, stored)
	assert_true(result.selection.equals(StorageSelection.new(STORAGE, 0)))
	assert_eq(_party.size(), Party.MAX_SIZE)
	assert_same(_storage.get_at(0), stored)


func test_withdraw_a_fainted_pokemon_is_allowed() -> void:
	_fill_party(1)
	var stored := _mon(&"pidgey")
	_faint(stored)
	_storage.add(stored)
	assert_true(StorageRules.withdraw(_party, _storage, 0).is_ok())
	assert_eq(_party.size(), 2)


func test_withdraw_an_unknown_index_is_not_found() -> void:
	_fill_party(1)
	assert_eq(StorageRules.can_withdraw(_party, _storage, 0), StorageRules.Status.NOT_FOUND)
	assert_eq(StorageRules.withdraw(_party, _storage, 3).status, StorageRules.Status.NOT_FOUND)


func test_moved_instance_keeps_hp_pp_favorite_and_history() -> void:
	_fill_party(1)
	var traveler := _mon(&"charmander", 7)
	traveler.take_damage(4)
	traveler.moves[0].pp = 3
	traveler.favorite = true
	traveler.nickname = "Flammèche"
	traveler.record_meeting(Pokemon.Origin.CAPTURE, &"route_1", "2026-10-02T20:51:16", "Kevin")
	var before := traveler.to_dict()
	_party.add(traveler)
	assert_true(StorageRules.deposit(_party, _storage, 1).is_ok())
	assert_same(_storage.get_at(0), traveler)
	assert_eq(traveler.to_dict(), before, "rien ne change en entrant au stockage")
	assert_true(StorageRules.withdraw(_party, _storage, 0).is_ok())
	assert_same(_party.get_at(1), traveler)
	assert_eq(traveler.to_dict(), before, "rien ne change en revenant dans l'équipe")


# --- Libérer ---------------------------------------------------------------------------------

func test_release_from_the_storage_removes_it_for_good() -> void:
	_fill_party(1)
	var first := _mon(&"pidgey")
	var second := _mon(&"rattata")
	_storage.add(first)
	_storage.add(second)
	var result := StorageRules.release(_party, _storage, STORAGE, 0)
	assert_true(result.is_ok())
	assert_same(result.pokemon, first)
	assert_eq(_storage.get_all(), [second] as Array[Pokemon])
	assert_eq(_storage.index_of(first), -1)
	assert_true(result.selection.equals(StorageSelection.new(STORAGE, 0)),
		"le suivant prend la place sélectionnée")


func test_release_from_the_party() -> void:
	var members := _fill_party(3)
	var result := StorageRules.release(_party, _storage, PARTY, 2)
	assert_true(result.is_ok())
	assert_eq(_party.get_all(), [members[0], members[1]] as Array[Pokemon])
	assert_true(result.selection.equals(StorageSelection.new(PARTY, 1)), "index borné")


func test_release_the_last_storage_pokemon_selects_the_lead() -> void:
	_fill_party(2)
	_storage.add(_mon())
	var result := StorageRules.release(_party, _storage, STORAGE, 0)
	assert_true(result.is_ok())
	assert_true(result.selection.equals(StorageSelection.new(PARTY, 0)))


func test_release_a_favorite_is_refused_without_bypass() -> void:
	_fill_party(1)
	var favorite := _mon(&"pidgey")
	favorite.favorite = true
	_storage.add(favorite)
	assert_eq(StorageRules.can_release(_party, _storage, STORAGE, 0),
		StorageRules.Status.FAVORITE)
	var result := StorageRules.release(_party, _storage, STORAGE, 0)
	assert_eq(result.status, StorageRules.Status.FAVORITE)
	assert_same(_storage.get_at(0), favorite, "toujours là")
	assert_true(favorite.favorite, "le favori n'est jamais retiré par la règle")
	assert_true(StorageRules.toggle_favorite(_party, _storage, STORAGE, 0).is_ok())
	assert_true(StorageRules.release(_party, _storage, STORAGE, 0).is_ok(),
		"libérable une fois le favori retiré volontairement")


func test_release_a_favorite_from_the_party_is_refused() -> void:
	var members := _fill_party(2)
	members[1].favorite = true
	assert_eq(StorageRules.release(_party, _storage, PARTY, 1).status,
		StorageRules.Status.FAVORITE)
	assert_eq(_party.size(), 2)


func test_release_the_last_pokemon_is_refused() -> void:
	var members := _fill_party(1)
	assert_eq(StorageRules.release(_party, _storage, PARTY, 0).status,
		StorageRules.Status.LAST_POKEMON)
	assert_same(_party.get_at(0), members[0])


func test_release_the_last_able_pokemon_is_refused_q7() -> void:
	var members := _fill_party(2)
	_faint(members[1])
	assert_eq(StorageRules.can_release(_party, _storage, PARTY, 0),
		StorageRules.Status.LAST_ABLE)
	assert_eq(StorageRules.can_release(_party, _storage, PARTY, 1), StorageRules.Status.OK)


func test_last_able_comes_before_favorite() -> void:
	var members := _fill_party(2)
	_faint(members[1])
	members[0].favorite = true
	assert_eq(StorageRules.can_release(_party, _storage, PARTY, 0),
		StorageRules.Status.LAST_ABLE, "retirer le favori n'aiderait pas")


func test_last_pokemon_comes_before_favorite() -> void:
	var members := _fill_party(1)
	members[0].favorite = true
	assert_eq(StorageRules.can_release(_party, _storage, PARTY, 0),
		StorageRules.Status.LAST_POKEMON, "retirer le favori n'aiderait pas")


func test_release_a_storage_pokemon_with_a_single_party_member_is_allowed() -> void:
	_fill_party(1)
	_storage.add(_mon())
	assert_eq(StorageRules.can_release(_party, _storage, STORAGE, 0), StorageRules.Status.OK,
		"la règle du dernier Pokémon ne vise que l'équipe")


func test_release_an_unknown_place_is_not_found() -> void:
	_fill_party(1)
	assert_eq(StorageRules.can_release(_party, _storage, STORAGE, 0),
		StorageRules.Status.NOT_FOUND)
	assert_eq(StorageRules.release(_party, _storage, PARTY, 4).status,
		StorageRules.Status.NOT_FOUND)


func test_release_touches_neither_the_pokedex_nor_the_career_captures() -> void:
	var state: Node = GameStateScript.new()
	state.clock = FixedClock.new("2026-10-05T10:00:00")
	state.new_game(3)
	var starter := PokemonFactory.create(_data, &"charmander", 5, state.rng)
	state.party.add(starter)
	state.starter_species = &"charmander"
	state.record_caught(&"charmander", &"oak_lab")
	var caught := PokemonFactory.create(_data, &"pidgey", 3, state.rng)
	state.record_seen(&"pidgey", &"route_1")
	state.record_caught(&"pidgey", &"route_1")
	state.stamp_meeting(caught, Pokemon.Origin.CAPTURE, &"route_1")
	state.storage.add(caught)
	var dex_before: Dictionary = state.pokedex.to_dict()
	var captures_before := TrainerSummary.capture_count(state.pokedex, state.starter_species)
	assert_eq(captures_before, 1)
	assert_true(StorageRules.release(state.party, state.storage, STORAGE, 0).is_ok())
	assert_true(state.storage.is_empty())
	assert_eq(state.pokedex.to_dict(), dex_before, "le Pokédex garde vu et capturé")
	assert_true(state.pokedex.is_caught(&"pidgey"))
	assert_eq(TrainerSummary.capture_count(state.pokedex, state.starter_species),
		captures_before, "la statistique « Captures » ne baisse jamais")
	state.free()


# --- Favori ----------------------------------------------------------------------------------

func test_toggle_favorite_in_both_places() -> void:
	var members := _fill_party(1)
	var stored := _mon()
	_storage.add(stored)
	var result := StorageRules.toggle_favorite(_party, _storage, PARTY, 0)
	assert_true(result.is_ok())
	assert_true(members[0].favorite)
	assert_true(result.selection.equals(StorageSelection.new(PARTY, 0)))
	assert_true(StorageRules.toggle_favorite(_party, _storage, STORAGE, 0).is_ok())
	assert_true(stored.favorite)
	assert_true(StorageRules.toggle_favorite(_party, _storage, STORAGE, 0).is_ok())
	assert_false(stored.favorite)
	assert_eq(StorageRules.toggle_favorite(_party, _storage, STORAGE, 3).status,
		StorageRules.Status.NOT_FOUND)


# --- Capacité --------------------------------------------------------------------------------

func test_the_storage_has_no_limit() -> void:
	_fill_party(2)
	for i: int in 60:
		_storage.add(_mon(&"rattata", 2))
	assert_eq(StorageRules.can_deposit(_party, 1), StorageRules.Status.OK,
		"un stockage unique, sans boîtes ni limite (dossier 09 §8)")
	assert_true(StorageRules.deposit(_party, _storage, 1).is_ok())
	assert_eq(_storage.size(), 61)


# --- Sélection -------------------------------------------------------------------------------

func test_selection_clamped() -> void:
	_fill_party(2)
	assert_true(StorageSelection.new(PARTY, 5).clamped(_party, _storage)
		.equals(StorageSelection.new(PARTY, 1)))
	assert_true(StorageSelection.new(STORAGE, 0).clamped(_party, _storage)
		.equals(StorageSelection.new(PARTY, 0)), "stockage vide → tête de l'équipe")
	assert_true(StorageSelection.new().clamped(_party, _storage).is_empty())
	assert_true(StorageSelection.first(_party, _storage).equals(StorageSelection.new(PARTY, 0)))
	assert_true(StorageSelection.first(Party.new(), PokemonStorage.new()).is_empty())
	_storage.add(_mon())
	assert_true(StorageSelection.first(Party.new(), _storage)
		.equals(StorageSelection.new(STORAGE, 0)))
