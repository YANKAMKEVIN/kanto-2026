extends GutTest
## Sauvegarde du jalon 20 (`jalon-20.md` §2.13) : **aucune nouvelle version** (v7). T12 : le
## Pokémon donné garde son origine « gift » (valeur nouvelle d'un champ texte), son identifiant,
## sa place (équipe ou Stockage) ; une origine inconnue d'une build plus ancienne se relit en
## « unknown » (rien n'est perdu).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save_j20.json"
const FLAG := &"eevee_received"
const MAP := &"celadon_mansion_roof_house"

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon")


func test_version_stays_seven() -> void:
	assert_eq(SaveSystem.VERSION, 7, "le J20 n'ajoute aucune version")


func test_gift_origin_round_trip_in_the_party_and_the_storage() -> void:
	for party_size: int in [5, 6]:
		var state := _new_state()
		for i: int in party_size:
			state.party.add(PokemonFactory.create(_data, &"rattata", 10, state.rng))
		var result := PokemonGift.give(state, _data, &"eevee", 25, MAP, FLAG)
		assert_true(result.is_given(), "don (%d)" % party_size)
		var save := SaveSystem.new(MemoryFs.new(), PATH)
		assert_eq(save.write(state.to_dict()), OK)
		var raw := JSON.stringify(save.read())
		assert_string_contains(raw, "\"origin\":\"gift\"", "origine écrite en texte")
		var loaded: Node = autofree(GameStateScript.new())
		assert_true(loaded.load_dict(save.read(), _data))
		var holder: Variant = loaded.storage if result.is_stored() else loaded.party
		var back: Pokemon = holder.get_all().filter(
			func(p: Pokemon) -> bool: return p.species_id == &"eevee")[0]
		assert_eq(back.origin, Pokemon.Origin.GIFT, "origine relue (%d)" % party_size)
		assert_eq(back.uid, result.pokemon.uid, "identifiant gardé")
		assert_eq(back.met_map, MAP)
		assert_true((loaded.flags as StoryFlags).has_flag(FLAG))
		assert_true(loaded.pokedex.is_caught(&"eevee"))
		assert_eq(PokemonGift.give(loaded, _data, &"eevee", 25, MAP, FLAG).status,
			PokemonGift.Status.ALREADY_RECEIVED, "pas de second don après rechargement")
		state.free()


func test_unknown_origin_text_reads_as_unknown() -> void:
	var pokemon := PokemonFactory.create(_data, &"eevee", 25, GameRng.new(1))
	var dict := pokemon.to_dict()
	(dict["met"] as Dictionary)["origin"] = "trade"
	var back := Pokemon.from_dict(dict, _data)
	assert_not_null(back)
	if back != null:
		assert_eq(back.origin, Pokemon.Origin.UNKNOWN, "valeur inconnue : « Rencontré à »")


func _new_state() -> Node:
	var state: Node = GameStateScript.new()
	state.clock = FixedClock.new("2026-10-20T10:00:00")
	state.new_game(7)
	state.player_name = "Kevin"
	return state
