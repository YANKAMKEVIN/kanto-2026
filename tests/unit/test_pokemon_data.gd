extends GutTest
## PokemonData : types, espèces et capacités de data/pokemon/, validation stricte et
## références croisées (jalon 4 §2.1, §3.2 et décisions de Kevin du §8).

const FIXTURES := "res://tests/fixtures/pokemon/"

var _data: PokemonData


func before_each() -> void:
	_data = PokemonData.new()


func _errors() -> String:
	return "\n".join(_data.get_errors())


# --- Vraies données ---------------------------------------------------------------------

func test_real_data_loads_without_error() -> void:
	assert_true(_data.load_dir())
	assert_eq(_data.get_errors().size(), 0, _errors())
	assert_eq(_data.get_type_chart().get_type_ids().size(), 18)
	assert_eq(_data.get_species_ids(), [&"bulbasaur", &"ivysaur", &"venusaur", &"charmander",
		&"charmeleon", &"charizard", &"squirtle", &"wartortle", &"blastoise",
		&"pidgey", &"pidgeotto", &"pidgeot", &"rattata", &"raticate"]
		as Array[StringName])
	assert_eq(_data.get_move_ids().size(), 34)
	assert_true(_data.has_move(&"struggle"))


func test_real_species_values() -> void:
	_data.load_dir()
	var charmander := _data.get_species(&"charmander")
	assert_eq(charmander.dex, 4)
	assert_eq(charmander.name, "Salamèche")
	assert_eq(charmander.types, [&"fire"] as Array[StringName])
	assert_eq(charmander.base_stats, {&"hp": 39, &"atk": 52, &"def": 43, &"spa": 60,
		&"spd": 50, &"spe": 65} as Dictionary[StringName, int])
	assert_eq(charmander.male_ratio, 0.875)
	assert_eq(charmander.growth_rate, ExpCurve.Rate.MEDIUM_SLOW)
	assert_eq(charmander.base_exp, 62)
	# Rendement d'XP moderne des formes finales (décision de Kevin n° 15, jalon 4 §8).
	var base_exp: Dictionary[StringName, int] = {
		&"bulbasaur": 64, &"ivysaur": 142, &"venusaur": 263,
		&"charmander": 62, &"charmeleon": 142, &"charizard": 267,
		&"squirtle": 63, &"wartortle": 142, &"blastoise": 265,
	}
	for id: StringName in base_exp:
		assert_eq(_data.get_species(id).base_exp, base_exp[id], String(id))
	assert_eq(_data.get_species(&"charizard").types, [&"fire", &"flying"] as Array[StringName])
	assert_eq(_data.get_species(&"bulbasaur").types, [&"grass", &"poison"] as Array[StringName])
	# Les neuf starters : croissance lente, 7/8 mâles, dex 1..9 contigus (les espèces de la
	# Route 1, ajoutées au jalon 5, ont d'autres valeurs — voir test_route_1_species_and_lines).
	for id: StringName in base_exp:
		var species := _data.get_species(id)
		assert_eq(species.growth_rate, ExpCurve.Rate.MEDIUM_SLOW, String(id))
		assert_eq(species.male_ratio, 0.875, String(id))
		assert_eq(species.dex, _data.get_species_ids().find(id) + 1, String(id))


func test_real_evolution_chains() -> void:
	_data.load_dir()
	var expected := {
		&"bulbasaur": [&"ivysaur", 16], &"ivysaur": [&"venusaur", 32],
		&"charmander": [&"charmeleon", 16], &"charmeleon": [&"charizard", 36],
		&"squirtle": [&"wartortle", 16], &"wartortle": [&"blastoise", 36],
		&"pidgey": [&"pidgeotto", 18], &"pidgeotto": [&"pidgeot", 36],
		&"rattata": [&"raticate", 20],
	}
	for id: StringName in _data.get_species_ids():
		var rules := _data.get_species(id).evolutions
		if not expected.has(id):
			assert_eq(rules.size(), 0, "%s : forme finale" % id)
			continue
		assert_eq(rules.size(), 1, String(id))
		assert_eq(rules[0].method, EvolutionRule.Method.LEVEL, String(id))
		assert_eq(rules[0].into, expected[id][0], String(id))
		assert_eq(rules[0].level, expected[id][1], String(id))


func test_starters_know_red_blue_moves_at_level_5() -> void:
	_data.load_dir()
	assert_eq(_data.get_species(&"bulbasaur").moves_at(5), [&"tackle", &"growl"]
		as Array[StringName])
	assert_eq(_data.get_species(&"charmander").moves_at(5), [&"scratch", &"growl"]
		as Array[StringName])
	assert_eq(_data.get_species(&"squirtle").moves_at(5), [&"tackle", &"tail_whip"]
		as Array[StringName])


func test_starting_moves_are_fully_handled_by_the_engine() -> void:
	_data.load_dir()
	for id: StringName in [&"bulbasaur", &"charmander", &"squirtle"]:
		for move_id: StringName in _data.get_species(id).moves_at(5):
			var move := _data.get_move(move_id)
			assert_eq(move.pending_effects.size(), 0, "%s : aucun effet en attente" % move_id)
			assert_gt(move.pp, 0, String(move_id))


func test_real_move_values() -> void:
	_data.load_dir()
	var tackle := _data.get_move(&"tackle")
	assert_eq([tackle.name, tackle.type, tackle.category, tackle.power, tackle.accuracy,
		tackle.pp], ["Charge", &"normal", MoveData.Category.PHYSICAL, 40, 100, 35])
	var growl := _data.get_move(&"growl")
	assert_eq(growl.category, MoveData.Category.STATUS)
	assert_eq(growl.effects.size(), 1)
	assert_eq(growl.effects[0].kind, MoveEffect.Kind.STAT_STAGE)
	assert_eq([growl.effects[0].stat, growl.effects[0].stages, growl.effects[0].target,
		growl.effects[0].chance], [&"atk", -1, MoveEffect.Target.FOE, 100])
	assert_eq(_data.get_move(&"razor_leaf").crit_stage, 1, "critique élevé")
	assert_eq(_data.get_move(&"slash").crit_stage, 1, "critique élevé")
	assert_eq(_data.get_move(&"tackle").crit_stage, 0)
	assert_eq(_data.get_move(&"bite").type, &"dark", "Morsure est Ténèbres")
	assert_eq(_data.get_move(&"bubble").category, MoveData.Category.SPECIAL)
	assert_eq(_data.get_move(&"bubble").effects[0].chance, 10)
	var growth := _data.get_move(&"growth")
	assert_eq(growth.effects.size(), 2)
	assert_eq(growth.effects[1].stat, &"spa")
	assert_eq(growth.effects[1].target, MoveEffect.Target.SELF)
	assert_true(growth.never_misses())
	var struggle := _data.get_move(&"struggle")
	assert_true(struggle.typeless)
	assert_true(struggle.never_misses())
	assert_eq(struggle.effects[0].kind, MoveEffect.Kind.RECOIL)
	assert_eq(struggle.effects[0].fraction, 0.25)
	assert_eq(_data.get_move(&"ember").pending_effects, PackedStringArray(["burn_10"]))


func test_every_real_move_has_a_draft_description() -> void:
	_data.load_dir()
	for id: StringName in _data.get_move_ids():
		var move := _data.get_move(id)
		assert_false(move.description.is_empty(), String(id))
		assert_true(move.draft, "%s : description à relire par Kevin" % id)


# --- Fixture valide ---------------------------------------------------------------------

func test_valid_fixture_fields_and_defaults() -> void:
	assert_true(_data.load_dir(FIXTURES + "valid/"))
	assert_eq(_data.get_errors().size(), 0, _errors())
	assert_eq(_data.get_species_ids(), [&"sprout", &"tree", &"flower", &"vine", &"wisp"]
		as Array[StringName], "par numéro, fichiers non JSON ignorés")
	assert_eq(_data.get_species(&"sprout").source, FIXTURES + "valid/species/starters.json")
	var wisp := _data.get_species(&"wisp")
	assert_true(wisp.is_genderless())
	assert_eq(wisp.growth_rate, ExpCurve.Rate.MEDIUM_FAST)
	assert_false(_data.get_species(&"sprout").is_genderless())
	assert_eq(_data.get_species(&"flower").male_ratio, 0.0, "entier 0 accepté")
	var leaf := _data.get_move(&"razor_leaf")
	assert_eq([leaf.priority, leaf.crit_stage, leaf.crit_denominator()], [1, 1, 8])
	var tackle := _data.get_move(&"tackle")
	assert_eq([tackle.priority, tackle.crit_stage, tackle.crit_denominator()], [0, 0, 24])
	assert_false(tackle.draft)
	assert_false(tackle.typeless)
	assert_eq(tackle.effects.size(), 0)
	assert_true(_data.get_move(&"growl").draft)
	assert_null(_data.get_species(&"nobody"))
	assert_null(_data.get_move(&"nothing"))


func test_valid_fixture_evolution_methods() -> void:
	_data.load_dir(FIXTURES + "valid/")
	var rules := _data.get_species(&"sprout").evolutions
	assert_eq(rules.size(), 3)
	assert_eq([rules[0].method, rules[0].into, rules[0].level],
		[EvolutionRule.Method.LEVEL, &"tree", 16])
	assert_eq([rules[1].method, rules[1].into, rules[1].item],
		[EvolutionRule.Method.ITEM, &"flower", &"leaf_stone"])
	assert_eq([rules[2].method, rules[2].into], [EvolutionRule.Method.TRADE, &"vine"])


# --- Erreurs ----------------------------------------------------------------------------

func test_missing_folders_are_errors() -> void:
	assert_false(_data.load_dir(FIXTURES + "nowhere/"))
	assert_push_error_count(3, "types, capacités, espèces")
	assert_string_contains(_errors(), "fichier introuvable")
	assert_string_contains(_errors(), "dossier introuvable")


func test_broken_json_reports_file_and_line() -> void:
	assert_false(_data.load_dir(FIXTURES + "bad_json/"))
	assert_push_error("broken.json, ligne 6")
	assert_eq(_data.get_errors().size(), 1, _errors())
	assert_true(_data.has_move(&"tackle"), "les autres fichiers sont lus")


func test_duplicate_ids_and_dex_numbers_are_rejected() -> void:
	assert_false(_data.load_dir(FIXTURES + "duplicate/"))
	assert_push_error_count(3)
	var errors := _errors()
	assert_string_contains(errors, "capacité « tackle » : identifiant déjà défini dans")
	assert_string_contains(errors, "espèce « sprout » : identifiant déjà défini dans")
	assert_string_contains(errors, "espèce « copycat » : numéro 1 déjà pris par « sprout »")
	assert_eq(_data.get_move(&"tackle").power, 40, "la première est gardée")
	assert_eq(_data.get_species(&"sprout").name, "Pousse")
	assert_false(_data.has_species(&"copycat"))


func test_broken_cross_references_are_rejected() -> void:
	assert_false(_data.load_dir(FIXTURES + "bad_refs/"))
	assert_push_error_count(6)
	var errors := _errors()
	assert_string_contains(errors, "capacité « thunder_shock » : type inconnu « electric »")
	assert_string_contains(errors, "espèce « mouse » : type inconnu « electric »")
	assert_string_contains(errors, "« sparky » : capacité inconnue « thunder_shock »")
	assert_string_contains(errors, "« typo » : capacité inconnue « tackel »")
	assert_string_contains(errors, "« stray » : évolution vers une espèce inconnue « nobody »")
	assert_string_contains(errors, "« chain » : évolution vers une espèce inconnue « stray »")
	assert_eq(_data.get_species_ids(), [&"good"] as Array[StringName])


func test_invalid_move_fields_are_rejected() -> void:
	assert_false(_data.load_dir(FIXTURES + "bad_fields/"))
	assert_push_error_count(24, "12 capacités + 12 espèces")
	var errors := _errors()
	for expected: String in [
		"« typo_key » : clé inconnue « powr »",
		"« no_pp » : « pp » est obligatoire",
		"« bad_category » : « category » vaut physical, special ou status",
		"« too_accurate » accuracy : entier de 0 à 100 attendu",
		"« weak_attack » : « power » ≥ 1 attendu",
		"« strong_status » : une capacité de statut n'a pas de « power »",
		"« bad_effect » effet 1 : « stat » vaut atk, def, spa, spd, spe, acc, eva",
		"« bad_effect » effet 1 : « stages » de −6 à +6, jamais 0",
		"« bad_effect » effet 1 : « target » vaut self ou foe",
		"« bad_recoil » effet 1 : clé inconnue « stat »",
		"« bad_recoil » effet 1 : « fraction » doit être un nombre",
		"« bad_pending » : « pending_effects » doit être une liste de textes",
	]:
		assert_string_contains(errors, expected)
	assert_eq(_data.get_move_ids(), [&"growl", &"struggle", &"tackle"] as Array[StringName])


func test_invalid_species_fields_are_rejected() -> void:
	_data.load_dir(FIXTURES + "bad_fields/")
	assert_push_error_count(24, "12 capacités + 12 espèces")
	var errors := _errors()
	for expected: String in [
		"« no_learnset » : « learnset » est obligatoire",
		"« three_types » : « types » doit être une liste de 1 ou 2 types",
		"« bad_stats » base_stats : clé inconnue « speed »",
		"« bad_stats » base_stats : « spe » manquant",
		"« bad_stats » base_stats hp : entier de 1 à 255 attendu",
		"« bad_ratio_and_curve » : « male_ratio » vaut −1 (asexué) ou un nombre de 0 à 1",
		"« bad_ratio_and_curve » : « growth_rate » vaut erratic, fast, medium_fast",
		"« unsorted » learnset 2 : les niveaux doivent être croissants",
		"« bad_evolutions » évolution 1 : « level » est obligatoire",
		"« bad_evolutions » évolution 2 : clé inconnue « level »",
		"« bad_evolutions » évolution 3 : « method » vaut level, item, trade",
		"« good » : évolution vers une espèce inconnue « no_learnset »",
	]:
		assert_string_contains(errors, expected)
	assert_eq(_data.get_species_ids().size(), 0)


func test_non_object_entries_and_empty_ids_are_rejected() -> void:
	_data.add_types_from_dict({"types": {"normal": {"name": "Normal"}}}, "t")
	assert_false(_data.add_species_from_dict({"": {}, "x": 3}, "s"))
	assert_false(_data.add_moves_from_dict({"y": []}, "m"))
	assert_push_error_count(3)
	assert_string_contains(_errors(), "s : identifiant vide")
	assert_string_contains(_errors(), "s espèce « x » : un objet est attendu")
	assert_string_contains(_errors(), "m capacité « y » : un objet est attendu")


# --- Espèces et capacités du jalon 5 (Route 1) ------------------------------------------

func test_route_1_species_and_lines() -> void:
	_data.load_dir()
	assert_eq(_data.get_errors().size(), 0, _errors())
	var pidgey := _data.get_species(&"pidgey")
	assert_eq(pidgey.dex, 16)
	assert_eq(pidgey.name, "Roucool")
	assert_eq(pidgey.types, [&"normal", &"flying"] as Array[StringName])
	assert_eq(pidgey.base_stats, {&"hp": 40, &"atk": 45, &"def": 40, &"spa": 35, &"spd": 35,
		&"spe": 56} as Dictionary[StringName, int])
	assert_eq(pidgey.base_exp, 50)
	assert_eq(pidgey.male_ratio, 0.5)
	var rattata := _data.get_species(&"rattata")
	assert_eq(rattata.dex, 19)
	assert_eq(rattata.name, "Rattata")
	assert_eq(rattata.base_exp, 51)
	# Lignées complètes présentes (les évolutions résolvent).
	for id: StringName in [&"pidgeotto", &"pidgeot", &"raticate"]:
		assert_true(_data.has_species(id), String(id))
	assert_eq(pidgey.evolutions[0].into, &"pidgeotto")
	assert_eq(rattata.evolutions[0].into, &"raticate")


func test_route_1_moves_exist_and_are_typed() -> void:
	_data.load_dir()
	var gust := _data.get_move(&"gust")
	assert_eq(gust.type, &"flying")
	assert_eq(gust.power, 40)
	assert_true(gust.is_damaging())
	var sand := _data.get_move(&"sand_attack")
	assert_eq(sand.type, &"ground")
	assert_false(sand.is_damaging(), "Jet de Sable est une capacité de statut")
	assert_eq(sand.effects.size(), 1, "baisse de Précision codée (sans pending_effects)")
	assert_eq(sand.pending_effects.size(), 0)
	assert_eq(_data.get_move(&"quick_attack").priority, 1)


func test_low_level_wild_moves_have_no_pending_effects() -> void:
	# Invariant de jouabilité (§3.2) : aux niveaux des rencontres (Roucool 2..5, Rattata
	# 2..4), toute capacité connue est pleinement codée.
	_data.load_dir()
	for pair: Array in [[&"pidgey", 5], [&"rattata", 4]]:
		var species := _data.get_species(pair[0])
		for move_id: StringName in species.moves_at(pair[1]):
			var move := _data.get_move(move_id)
			assert_eq(move.pending_effects.size(), 0,
				"%s à Nv.%d connaît %s (effet non codé)" % [pair[0], pair[1], move_id])
