extends GutTest
## PokedexUpdates : un toast par observation, le plus parlant ; aucun pour une capture ;
## aucun tant que le Pokédex n'est pas visible (jalon-06.md §3.5, §4).

const Kind := PokedexUpdates.Kind

var _data: PokemonData
var _zones: ZoneLibrary
var _dex: Pokedex
## Derniers arguments de Pokedex.recorded.
var _last: Array = []


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	_zones.load_file()


func before_each() -> void:
	_dex = Pokedex.new()
	_dex.recorded.connect(func(species: StringName, map: StringName, first_seen: bool,
			new_map: bool, caught: bool) -> void:
		_last = [species, map, first_seen, new_map, caught])


func _classify(new_note: bool = false) -> Kind:
	return PokedexUpdates.classify(_dex, _data, _zones, _last[0], _last[1], _last[2],
		_last[3], _last[4], new_note)


func test_first_sighting_is_a_new_species() -> void:
	_dex.mark_seen(&"pidgey", &"route_1")
	assert_eq(_classify(), Kind.NEW_SPECIES)
	assert_eq(PokedexUpdates.message(Kind.NEW_SPECIES, "Roucool", true),
		PackedStringArray(["Pokédex mis à jour", "Roucool"]))


func test_a_new_zone_is_a_new_habitat_but_not_a_new_map_of_the_same_zone() -> void:
	_dex.mark_seen(&"pidgey", &"pallet_town")
	_dex.mark_seen(&"pidgey", &"oak_lab")
	assert_eq(_classify(), Kind.NONE, "le labo est à Bourg Palette : même habitat")
	_dex.mark_seen(&"pidgey", &"route_1")
	assert_eq(_classify(), Kind.NEW_HABITAT)
	_dex.mark_seen(&"pidgey", &"route_1")
	assert_eq(_classify(), Kind.NONE, "déjà vu ici")
	assert_eq(PokedexUpdates.message(Kind.NEW_HABITAT, "Roucool", true)[0],
		"Nouvel habitat observé")


func test_a_map_outside_any_zone_is_not_a_habitat() -> void:
	_dex.mark_seen(&"pidgey", &"route_1")
	_dex.mark_seen(&"pidgey", &"nowhere")
	assert_eq(_classify(), Kind.NONE)


func test_a_new_note_alone() -> void:
	_dex.mark_seen(&"pidgey", &"route_1")
	_dex.mark_seen(&"pidgey", &"route_1")
	assert_eq(_classify(true), Kind.NEW_NOTE)
	_dex.mark_seen(&"rattata", &"route_1")
	assert_eq(_classify(true), Kind.NEW_SPECIES, "une seule notification : la plus parlante")


func test_a_new_species_of_a_known_family_is_an_evolution_discovered() -> void:
	_dex.mark_caught(&"pidgey", &"route_1")
	_dex.mark_seen(&"pidgeotto", &"route_1")
	assert_eq(_classify(), Kind.EVOLUTION_DISCOVERED)
	assert_eq(PokedexUpdates.message(Kind.EVOLUTION_DISCOVERED, "Roucoups", true),
		PackedStringArray(["Évolution découverte", "Roucoups"]))
	_dex.mark_seen(&"rattata", &"route_1")
	assert_eq(_classify(), Kind.NEW_SPECIES, "lignée inconnue")


func test_a_capture_never_has_a_toast() -> void:
	_dex.mark_caught(&"rattata", &"route_1")
	assert_true(_last[2], "première observation")
	assert_true(_last[4], "capture")
	assert_eq(_classify(true), Kind.NONE, "la carte de capture le dit déjà")


func test_nothing_is_said_while_the_pokedex_is_not_visible() -> void:
	for kind: Kind in [Kind.NEW_SPECIES, Kind.NEW_HABITAT, Kind.NEW_NOTE,
			Kind.EVOLUTION_DISCOVERED]:
		assert_eq(PokedexUpdates.message(kind, "Roucool", false).size(), 0)
		assert_eq(PokedexUpdates.message(kind, "Roucool", true).size(), 2)
	assert_eq(PokedexUpdates.message(Kind.NONE, "Roucool", true).size(), 0)
	assert_eq(PokedexUpdates.message(Kind.NEW_SPECIES, "", true).size(), 0)


func test_without_zones_or_data() -> void:
	_dex.mark_seen(&"pidgey", &"route_1")
	_dex.mark_seen(&"pidgey", &"pallet_town")
	assert_eq(PokedexUpdates.classify(_dex, _data, null, &"pidgey", &"pallet_town", false,
		true, false), Kind.NONE)
	_dex.mark_seen(&"pidgeotto")
	assert_eq(PokedexUpdates.classify(_dex, null, null, &"pidgeotto", &"", true, false,
		false), Kind.NEW_SPECIES)
