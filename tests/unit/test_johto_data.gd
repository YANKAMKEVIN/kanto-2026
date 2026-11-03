extends GutTest
## Données du Chapitre Johto (JOH0 T6, `docs/tech/jalon-joh0.md` §2.8 et §2.11) : 51 espèces,
## attaques d'Or/Argent, familles d'effets visuels, fiches du Pokédex et 4 objets d'évolution.

const JOHTO_DEX: Dictionary[StringName, int] = {
	&"chikorita": 152, &"bayleef": 153, &"meganium": 154, &"cyndaquil": 155, &"quilava": 156,
	&"typhlosion": 157, &"totodile": 158, &"croconaw": 159, &"feraligatr": 160, &"sentret": 161,
	&"furret": 162, &"hoothoot": 163, &"noctowl": 164, &"crobat": 169, &"togepi": 175,
	&"togetic": 176, &"mareep": 179, &"flaaffy": 180, &"ampharos": 181, &"marill": 183,
	&"azumarill": 184, &"politoed": 186, &"espeon": 196, &"umbreon": 197, &"murkrow": 198,
	&"slowking": 199, &"wobbuffet": 202, &"steelix": 208, &"scizor": 212, &"heracross": 214,
	&"sneasel": 215, &"teddiursa": 216, &"ursaring": 217, &"skarmory": 227, &"houndour": 228,
	&"houndoom": 229, &"kingdra": 230, &"phanpy": 231, &"donphan": 232, &"porygon2": 233,
	&"miltank": 241, &"blissey": 242, &"raikou": 243, &"entei": 244, &"suicune": 245,
	&"larvitar": 246, &"pupitar": 247, &"tyranitar": 248, &"lugia": 249, &"ho_oh": 250,
	&"celebi": 251,
}
const NEW_ITEMS: Array[StringName] = [&"metal_coat", &"kings_rock", &"dragon_scale", &"up_grade"]
const MOVES_FILE: String = "res://data/pokemon/moves/johto.json"
const FX_FILE: String = "res://data/battle/move_fx/johto.json"
const POKEDEX_FILE: String = "res://data/pokedex/johto.json"

var _data: PokemonData


func before_each() -> void:
	_data = PokemonData.new()


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, path)
	return parsed if parsed is Dictionary else {}


func test_real_data_loads_without_error() -> void:
	assert_true(_data.load_dir())
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))


func test_the_51_species_are_there_with_their_national_number() -> void:
	assert_eq(JOHTO_DEX.size(), 51)
	_data.load_dir()
	for id: StringName in JOHTO_DEX:
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species != null:
			assert_eq(species.dex, JOHTO_DEX[id], String(id))
			assert_true(species.source.ends_with("johto.json"), String(id))
	assert_eq(_data.get_species(&"ho_oh").name, "Ho-Oh")
	assert_eq(_data.get_species(&"kingdra").name, "Hyporoi")


func test_johto_learnsets_start_at_level_one_and_use_known_moves() -> void:
	_data.load_dir()
	for id: StringName in JOHTO_DEX:
		var species := _data.get_species(id)
		assert_false(species.learnset.is_empty(), String(id))
		for move_id: StringName in species.learnset_moves():
			assert_not_null(_data.get_move(move_id), "%s : %s" % [id, move_id])
	assert_eq(_data.get_species(&"chikorita").moves_at(5), [&"tackle", &"growl"] as Array[StringName])


func test_new_evolution_rules() -> void:
	_data.load_dir()
	assert_eq(_evolution(&"togepi", &"togetic").method, EvolutionRule.Method.BOND)
	for pair: Array in [[&"chansey", &"blissey"], [&"golbat", &"crobat"]]:
		assert_eq(_evolution(pair[0], pair[1]).method, EvolutionRule.Method.BOND, String(pair[0]))
	var espeon := _evolution(&"eevee", &"espeon")
	assert_eq(espeon.method, EvolutionRule.Method.BOND)
	assert_eq(espeon.periods, [&"morning", &"day"] as Array[StringName])
	assert_eq(_evolution(&"eevee", &"umbreon").periods, [&"night"] as Array[StringName])
	for stone: StringName in [&"vaporeon", &"jolteon", &"flareon"]:
		assert_eq(_evolution(&"eevee", stone).method, EvolutionRule.Method.ITEM, "Évoli garde ses pierres")
	for trade: Array in [[&"onix", &"steelix", &"metal_coat"], [&"scyther", &"scizor", &"metal_coat"],
			[&"slowpoke", &"slowking", &"kings_rock"], [&"poliwhirl", &"politoed", &"kings_rock"],
			[&"seadra", &"kingdra", &"dragon_scale"], [&"porygon", &"porygon2", &"up_grade"]]:
		var rule := _evolution(trade[0], trade[1])
		assert_eq(rule.method, EvolutionRule.Method.TRADE, String(trade[0]))
		assert_eq(rule.item, trade[2], String(trade[0]))
	assert_eq(_evolution(&"slowpoke", &"slowbro").method, EvolutionRule.Method.LEVEL)
	assert_eq(_evolution(&"poliwhirl", &"poliwrath").method, EvolutionRule.Method.ITEM)
	assert_eq(_evolution(&"larvitar", &"pupitar").level, 30)
	assert_eq(_evolution(&"pupitar", &"tyranitar").level, 55)


func _evolution(from: StringName, into: StringName) -> EvolutionRule:
	for rule: EvolutionRule in _data.get_species(from).evolutions:
		if rule.into == into:
			return rule
	fail_test("%s → %s : aucune règle" % [from, into])
	return EvolutionRule.new()


func test_every_new_move_has_a_visual_family() -> void:
	_data.load_dir()
	var moves := _json(MOVES_FILE)
	var catalog := MoveFxCatalog.load_dir()
	assert_eq(catalog.get_errors().size(), 0, "\n".join(catalog.get_errors()))
	assert_gte(moves.size(), 40)
	var families := catalog.family_ids()
	for key: String in moves:
		var id := StringName(key)
		assert_not_null(_data.get_move(id), key)
		assert_true(catalog.has_entry(id), "%s : famille d'effets visuels" % key)
		assert_true(families.has(catalog.entry(id).family), "%s : famille connue" % key)
		assert_true(catalog.entry(id).source == "johto.json", "%s : dans johto.json" % key)
	for key: String in _json(FX_FILE).get("moves", {}):
		assert_true(moves.has(key), "%s : attaque de johto.json" % key)


func test_pending_effects_are_flagged_in_the_description() -> void:
	_data.load_dir()
	for key: String in _json(MOVES_FILE):
		var move := _data.get_move(StringName(key))
		if not move.pending_effects.is_empty():
			assert_true(move.description.contains("moteur actuel"), key)
		if move.category == MoveData.Category.STATUS and move.effects.is_empty():
			assert_false(move.pending_effects.is_empty(), "%s : statut sans effet ni attente" % key)


func test_new_items() -> void:
	var library := ItemLibrary.new()
	assert_true(library.load_dir())
	assert_eq(library.get_errors().size(), 0, "\n".join(library.get_errors()))
	for id: StringName in NEW_ITEMS:
		assert_true(library.has_item(id), String(id))
		var item := library.get_item(id)
		assert_eq(item.category, ItemData.Category.FIELD, String(id))
		assert_eq(item.price, 0, String(id))
		assert_true(item.description.contains("terminal d'échange"), String(id))
	assert_eq(library.get_item(&"metal_coat").name, "Peau Métal")
	assert_true(library.get_item(&"up_grade").feminine == false)


func test_pokedex_johto_file_is_valid() -> void:
	var dex := _json(POKEDEX_FILE)
	assert_eq(int(dex.get("size", 0)), 51)
	var species: Dictionary = dex.get("species", {})
	assert_eq(species.size(), 51)
	for id: StringName in JOHTO_DEX:
		assert_true(species.has(String(id)), String(id))
		var entry: Dictionary = species.get(String(id), {})
		assert_gt(float(entry.get("height", 0.0)), 0.0, String(id))
		assert_gt(float(entry.get("weight", 0.0)), 0.0, String(id))
		assert_false(str(entry.get("description", "")).is_empty(), String(id))
		assert_true(entry.get("draft", false), "%s : draft" % id)
