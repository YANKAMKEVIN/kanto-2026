extends GutTest
## PokemonStorage, le « système de recherche de Chen » (jalon 5 §2.4, dossier 05 §17, Q38) :
## ajout, ordre, sérialisation, entrées invalides écartées.

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon")


func _mon(species: StringName, level: int, seed_value: int = 1) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(seed_value))


func test_starts_empty() -> void:
	var storage := PokemonStorage.new()
	assert_eq(storage.size(), 0)
	assert_true(storage.is_empty())
	assert_eq(storage.get_all().size(), 0)
	assert_eq(storage.to_array().size(), 0)


func test_add_keeps_the_same_instance_in_order() -> void:
	var storage := PokemonStorage.new()
	var pidgey := _mon(&"pidgey", 3)
	var rattata := _mon(&"rattata", 2)
	pidgey.take_damage(5)
	assert_true(storage.add(pidgey))
	assert_true(storage.add(rattata))
	assert_eq(storage.size(), 2)
	assert_false(storage.is_empty())
	assert_same(storage.get_all()[0], pidgey, "même instance, PV gardés")
	assert_same(storage.get_all()[1], rattata, "ordre d'arrivée")


func test_add_refuses_null_and_duplicates() -> void:
	var storage := PokemonStorage.new()
	var pidgey := _mon(&"pidgey", 3)
	assert_false(storage.add(null))
	assert_true(storage.add(pidgey))
	assert_false(storage.add(pidgey), "déjà rangé")
	assert_eq(storage.size(), 1)


func test_no_size_limit() -> void:
	var storage := PokemonStorage.new()
	for i: int in Party.MAX_SIZE * 3:
		assert_true(storage.add(_mon(&"rattata", 2, i)))
	assert_eq(storage.size(), Party.MAX_SIZE * 3)


func test_get_all_is_a_copy() -> void:
	var storage := PokemonStorage.new()
	storage.add(_mon(&"pidgey", 3))
	storage.get_all().clear()
	assert_eq(storage.size(), 1)


func test_clear() -> void:
	var storage := PokemonStorage.new()
	storage.add(_mon(&"pidgey", 3))
	storage.clear()
	assert_true(storage.is_empty())


func test_round_trip_keeps_every_pokemon() -> void:
	var storage := PokemonStorage.new()
	var pidgey := _mon(&"pidgey", 4)
	pidgey.take_damage(3)
	pidgey.moves[0].use()
	pidgey.record_meeting(Pokemon.Origin.CAPTURE, &"route_1", "2026-10-02T14:03:05", "Kevin")
	storage.add(pidgey)
	storage.add(_mon(&"rattata", 3, 2))
	var saved := storage.to_array()
	var loaded := PokemonStorage.new()
	assert_true(loaded.load_array(JSON.parse_string(JSON.stringify(saved)), _data))
	assert_eq(loaded.size(), 2)
	assert_eq(loaded.to_array(), saved, "même contenu après le JSON")
	var first := loaded.get_all()[0]
	assert_eq([first.species_id, first.level, first.hp], [&"pidgey", 4, pidgey.hp])
	assert_eq(first.moves[0].pp, pidgey.moves[0].pp)
	assert_eq(first.origin, Pokemon.Origin.CAPTURE)


func test_load_array_replaces_the_content_and_discards_invalid_entries() -> void:
	var storage := PokemonStorage.new()
	storage.add(_mon(&"pidgey", 3))
	var entries: Array = [_mon(&"rattata", 2).to_dict(), {"species": "missingno"}, "texte"]
	assert_false(storage.load_array(entries, _data), "une entrée écartée → faux")
	assert_eq(storage.size(), 1, "le contenu précédent est remplacé, le valide gardé")
	assert_eq(storage.get_all()[0].species_id, &"rattata")
	# Espèce inconnue (Pokemon) puis deux entrées écartées (PokemonStorage).
	assert_push_error_count(3)
