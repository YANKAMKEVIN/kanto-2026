extends GutTest
## Anti-blocage (jalon 17, T7 ; `jalon-17.md` §2.12.1) : une espèce compatible CS05 se capture
## avant la Cave Taupiqueur, quel que soit le starter (aucun des trois n'apprend Flash) : d'après
## les vraies tables de rencontres, sur les cartes que l'on traverse avant la Route 11.

## Cartes à rencontres avant la Cave (Route 11 comprise : on y entre par elle).
const BEFORE_THE_CAVE: Array[StringName] = [&"route_1", &"route_22", &"route_2",
	&"viridian_forest", &"route_2_north", &"route_3", &"mt_moon_1f", &"mt_moon_b1f",
	&"mt_moon_b2f", &"route_4", &"route_24", &"route_25", &"route_5", &"route_6", &"route_11"]

var _data: PokemonData
var _encounters: EncounterLibrary


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))
	_encounters = EncounterLibrary.new(_data)
	assert_true(_encounters.load_dir(), "\n".join(_encounters.get_errors()))


func _flash_species_by_map() -> Dictionary[StringName, Array]:
	var found: Dictionary[StringName, Array] = {}
	for map_id: StringName in BEFORE_THE_CAVE:
		for terrain: StringName in EncounterTable.TERRAINS:
			var table := _encounters.get_table(map_id, terrain)
			if table == null:
				continue
			for slot: EncounterSlot in table.slots:
				if _data.can_learn_hm(slot.species, 5) and table.chance_of(slot.species) > 0.0:
					found.get_or_add(map_id, []).append(slot.species)
	return found


func test_no_starter_learns_flash() -> void:
	for starter: StringName in [&"bulbasaur", &"charmander", &"squirtle"]:
		assert_false(_data.can_learn_hm(starter, 5), String(starter))


func test_a_flash_user_is_catchable_before_the_cave() -> void:
	var found := _flash_species_by_map()
	assert_gt(found.size(), 0, "au moins une carte avant la Cave")
	assert_has(found.get(&"viridian_forest", []), &"pikachu", "Pikachu, Forêt de Jade")
	assert_has(found.get(&"mt_moon_1f", []), &"clefairy", "Mélofée, Mont Sélénite")
	assert_has(found.get(&"route_3", []), &"jigglypuff", "Rondoudou, Route 3")
	assert_gt(found.size(), 2, "plusieurs cartes, pas une seule chance : %s" % found)
