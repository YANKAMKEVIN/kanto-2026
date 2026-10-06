extends GutTest
## PokemonData : types, espèces et capacités de data/pokemon/, validation stricte et
## références croisées (jalon 4 §2.1, §3.2 et décisions de Kevin du §8).

const FIXTURES := "res://tests/fixtures/pokemon/"

## Valeurs de Rouge/Bleu (PokeAPI, groupe de versions red-blue), statistiques et rendement
## d'XP modernes comme les espèces déjà présentes : [dex, nom, types, PV, Att, Déf, Att. Spé.,
## Déf. Spé., Vit., base_exp, male_ratio, croissance].
const ROUTE_22_SPECIES := {
	&"spearow": [21, "Piafabec", [&"normal", &"flying"], 40, 60, 30, 31, 31, 70, 52, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"fearow": [22, "Rapasdepic", [&"normal", &"flying"], 65, 90, 65, 61, 61, 100, 155, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"nidoran_f": [29, "Nidoran♀", [&"poison"], 55, 47, 52, 40, 40, 41, 55, 0.0,
		ExpCurve.Rate.MEDIUM_SLOW],
	&"nidorina": [30, "Nidorina", [&"poison"], 70, 62, 67, 55, 55, 56, 128, 0.0,
		ExpCurve.Rate.MEDIUM_SLOW],
	&"nidoqueen": [31, "Nidoqueen", [&"poison", &"ground"], 90, 92, 87, 75, 85, 76, 227, 0.0,
		ExpCurve.Rate.MEDIUM_SLOW],
	&"nidoran_m": [32, "Nidoran♂", [&"poison"], 46, 57, 40, 40, 40, 50, 55, 1.0,
		ExpCurve.Rate.MEDIUM_SLOW],
	&"nidorino": [33, "Nidorino", [&"poison"], 61, 72, 57, 55, 55, 65, 128, 1.0,
		ExpCurve.Rate.MEDIUM_SLOW],
	&"nidoking": [34, "Nidoking", [&"poison", &"ground"], 81, 102, 77, 85, 75, 85, 227, 1.0,
		ExpCurve.Rate.MEDIUM_SLOW],
	&"mankey": [56, "Férosinge", [&"fighting"], 40, 80, 35, 35, 45, 70, 61, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"primeape": [57, "Colossinge", [&"fighting"], 65, 105, 60, 60, 70, 95, 159, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
}

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
		&"pidgey", &"pidgeotto", &"pidgeot", &"rattata", &"raticate", &"spearow", &"fearow",
		&"nidoran_f", &"nidorina", &"nidoqueen", &"nidoran_m", &"nidorino", &"nidoking",
		&"mankey", &"primeape"] as Array[StringName])
	assert_eq(_data.get_move_ids().size(), 47)
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
		# Route 22 (jalon 7, T21) : Rouge/Bleu ; Nidorina et Nidorino par la Pierre Lune.
		&"spearow": [&"fearow", 20], &"mankey": [&"primeape", 28],
		&"nidoran_f": [&"nidorina", 16], &"nidorina": [&"nidoqueen", &"moon_stone"],
		&"nidoran_m": [&"nidorino", 16], &"nidorino": [&"nidoking", &"moon_stone"],
	}
	for id: StringName in _data.get_species_ids():
		var rules := _data.get_species(id).evolutions
		if not expected.has(id):
			assert_eq(rules.size(), 0, "%s : forme finale" % id)
			continue
		assert_eq(rules.size(), 1, String(id))
		assert_eq(rules[0].into, expected[id][0], String(id))
		if expected[id][1] is int:
			assert_eq(rules[0].method, EvolutionRule.Method.LEVEL, String(id))
			assert_eq(rules[0].level, expected[id][1], String(id))
		else:
			assert_eq(rules[0].method, EvolutionRule.Method.ITEM, String(id))
			assert_eq(rules[0].item, expected[id][1], String(id))


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


func test_every_real_move_has_a_validated_description() -> void:
	_data.load_dir()
	for id: StringName in _data.get_move_ids():
		var move := _data.get_move(id)
		assert_false(move.description.is_empty(), String(id))
		assert_false(move.draft, "%s : description validé par Kevin le 2026-10-06" % id)


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
	assert_push_error_count(25, "12 capacités + 13 espèces")
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
	assert_push_error_count(25, "12 capacités + 13 espèces")
	var errors := _errors()
	for expected: String in [
		"« bad_catch_rate » catch_rate : entier de 1 à 255 attendu",
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


# --- Taux de capture (jalon 5D §2.4) ----------------------------------------------------

func test_real_catch_rates_are_the_official_ones() -> void:
	_data.load_dir()
	var expected: Dictionary[StringName, int] = {
		&"bulbasaur": 45, &"ivysaur": 45, &"venusaur": 45,
		&"charmander": 45, &"charmeleon": 45, &"charizard": 45,
		&"squirtle": 45, &"wartortle": 45, &"blastoise": 45,
		&"pidgey": 255, &"pidgeotto": 120, &"pidgeot": 45,
		&"rattata": 255, &"raticate": 127,
		&"spearow": 255, &"fearow": 90, &"mankey": 190, &"primeape": 75,
		&"nidoran_f": 235, &"nidorina": 120, &"nidoqueen": 45,
		&"nidoran_m": 235, &"nidorino": 120, &"nidoking": 45,
	}
	assert_eq(_data.get_species_ids().size(), expected.size(), "toutes les espèces")
	for id: StringName in _data.get_species_ids():
		assert_eq(_data.get_species(id).catch_rate, expected.get(id, -1), String(id))


func test_valid_fixture_reads_the_catch_rate() -> void:
	_data.load_dir(FIXTURES + "valid/")
	assert_eq(_data.get_species(&"wisp").catch_rate, 190)
	assert_eq(_data.get_species(&"sprout").catch_rate, 45)


func test_catch_rate_is_required_and_bounded() -> void:
	var species := {
		"dex": 1, "name": "Test", "types": ["normal"],
		"base_stats": { "hp": 45, "atk": 49, "def": 49, "spa": 65, "spd": 65, "spe": 45 },
		"male_ratio": 0.5, "growth_rate": "fast", "base_exp": 64, "learnset": [[1, "tackle"]],
	}
	assert_false(_data.add_species_from_dict({"missing": species}, "a"))
	assert_string_contains(_errors(), "a espèce « missing » : « catch_rate » est obligatoire")
	for value: Variant in [0, 256, 12.5, "255"]:
		var entry := species.duplicate()
		entry["catch_rate"] = value
		var data := PokemonData.new()
		assert_false(data.add_species_from_dict({"bad": entry}, "b"), str(value))
		assert_string_contains("\n".join(data.get_errors()), "catch_rate : entier de 1 à 255")
	var good := species.duplicate()
	good["catch_rate"] = 3
	var data := PokemonData.new()
	assert_true(data.add_species_from_dict({"good": good}, "c"))
	assert_eq(data.get_species(&"good").catch_rate, 3)
	assert_push_error_count(5)


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


func test_leech_seed_is_coded() -> void:
	# Jalon 5 Q28 : Vampigraine a un effet « seed » (⅛, Plante immunisé), plus en attente.
	_data.load_dir()
	var seed := _data.get_move(&"leech_seed")
	assert_eq(seed.pending_effects.size(), 0)
	assert_eq(seed.effects.size(), 1)
	assert_eq(seed.effects[0].kind, MoveEffect.Kind.SEED)
	assert_almost_eq(seed.effects[0].fraction, 0.125, 0.0001)
	assert_eq(seed.effects[0].immune_types, [&"grass"] as Array[StringName])


## Capacité « seedy » de statut avec le seul effet [param effect].
func _seed_move(effect: Dictionary) -> Dictionary:
	return { "seedy": { "name": "Graine", "type": "grass", "category": "status",
		"accuracy": 90, "pp": 10, "description": "…", "effects": [effect] } }


func test_invalid_seed_effects_are_rejected() -> void:
	assert_true(PokemonData.new().add_moves_from_dict(_seed_move({ "kind": "seed",
		"fraction": 0.125 }), "ok"), "immune_types facultatif")
	var cases: Dictionary = {
		"a": [{ "kind": "seed" }, "« fraction » est obligatoire"],
		"b": [{ "kind": "seed", "fraction": 0, "immune_types": ["grass"] },
			"« fraction » doit être un nombre de 0 (exclu) à 1"],
		"c": [{ "kind": "seed", "fraction": 0.125, "immune_types": "grass" },
			"immune_types : une liste d'identifiants de types est attendue"],
		"d": [{ "kind": "seed", "fraction": 0.125, "stat": "atk" }, "clé inconnue « stat »"],
		"e": [{ "kind": "leech" }, "« kind » vaut stat_stage, recoil, seed"],
	}
	for source: String in cases:
		var data := PokemonData.new()
		assert_false(data.add_moves_from_dict(_seed_move(cases[source][0]), source), source)
		assert_string_contains("\n".join(data.get_errors()),
			"%s capacité « seedy » effet 1" % source)
		assert_string_contains("\n".join(data.get_errors()), cases[source][1])
	assert_push_error_count(5)


func test_unknown_immune_type_is_a_broken_reference() -> void:
	_data.add_types_from_dict({"types": {"grass": {"name": "Plante"}}}, "t")
	_data.add_moves_from_dict(_seed_move({ "kind": "seed", "fraction": 0.125,
		"immune_types": ["wood"] }), "m")
	assert_false(_data.check_references())
	assert_string_contains(_errors(), "capacité « seedy » : type immunisé inconnu « wood »")
	assert_false(_data.has_move(&"seedy"))
	assert_push_error_count(1)


func test_low_level_wild_moves_have_no_pending_effects() -> void:
	# Invariant de jouabilité (§3.2) : aux niveaux des rencontres (Roucool 2..5, Rattata
	# 2..4), toute capacité connue est pleinement codée.
	_data.load_dir()
	# Route 22 (jalon 7) : Rattata 2..4, Piafabec 3..5, Férosinge 3..5, Nidoran ♀ ♂ 3..4.
	for pair: Array in [[&"pidgey", 5], [&"rattata", 4], [&"spearow", 5], [&"mankey", 5],
			[&"nidoran_f", 4], [&"nidoran_m", 4]]:
		var species := _data.get_species(pair[0])
		for move_id: StringName in species.moves_at(pair[1]):
			var move := _data.get_move(move_id)
			assert_eq(move.pending_effects.size(), 0,
				"%s à Nv.%d connaît %s (effet non codé)" % [pair[0], pair[1], move_id])


# --- Espèces et capacités du jalon 7 (Route 22, T21) ------------------------------------

func test_route_22_species_values() -> void:
	_data.load_dir()
	assert_eq(_data.get_errors().size(), 0, _errors())
	for id: StringName in ROUTE_22_SPECIES:
		var v: Array = ROUTE_22_SPECIES[id]
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species == null:
			continue
		assert_eq([species.dex, species.name], [v[0], v[1]], String(id))
		var types: Array[StringName] = []
		types.assign(v[2])
		assert_eq(species.types, types, String(id))
		assert_eq(species.base_stats, {&"hp": v[3], &"atk": v[4], &"def": v[5], &"spa": v[6],
			&"spd": v[7], &"spe": v[8]} as Dictionary[StringName, int], String(id))
		assert_eq(species.base_exp, v[9], String(id))
		assert_eq(species.male_ratio, v[10], String(id))
		assert_eq(species.growth_rate, v[11], String(id))


func test_route_22_species_know_red_blue_moves_at_route_levels() -> void:
	# Niveaux 2 à 5 de la Route 22 : capacités de départ de Rouge/Bleu ; aucune capacité de
	# poison (dossier 09 §12).
	_data.load_dir()
	var expected := {
		&"spearow": [&"peck", &"growl"], &"mankey": [&"scratch", &"leer"],
		&"nidoran_f": [&"growl", &"tackle"], &"nidoran_m": [&"leer", &"tackle"],
	}
	for id: StringName in expected:
		var moves: Array[StringName] = []
		moves.assign(expected[id])
		for level: int in range(2, 6):
			assert_eq(_data.get_species(id).moves_at(level), moves, "%s Nv. %d" % [id, level])
		for move_id: StringName in moves:
			assert_ne(_data.get_move(move_id).type, &"poison", String(move_id))
	# Premières capacités apprises en montant : Rouge/Bleu.
	assert_eq(_data.get_species(&"nidoran_f").moves_at(8), [&"growl", &"tackle", &"scratch"]
		as Array[StringName])
	assert_eq(_data.get_species(&"nidoran_m").moves_at(8),
		[&"leer", &"tackle", &"horn_attack"] as Array[StringName])
	assert_eq(_data.get_species(&"spearow").moves_at(9), [&"peck", &"growl", &"leer"]
		as Array[StringName])
	# Rattata (aussi sur la Route 22) : Croc Fatal au Nv. 34 en Rouge/Bleu (30 avant T21).
	assert_eq(_data.get_species(&"rattata").learnset.back(), [34, &"super_fang"])


func test_route_22_moves_values() -> void:
	_data.load_dir()
	# [type, catégorie, puissance, précision, PP] : valeurs modernes, comme les autres.
	var expected := {
		&"peck": [&"flying", MoveData.Category.PHYSICAL, 35, 100, 35],
		&"fury_attack": [&"normal", MoveData.Category.PHYSICAL, 15, 85, 20],
		&"drill_peck": [&"flying", MoveData.Category.PHYSICAL, 80, 100, 20],
		&"karate_chop": [&"fighting", MoveData.Category.PHYSICAL, 50, 100, 25],
		&"fury_swipes": [&"normal", MoveData.Category.PHYSICAL, 18, 80, 15],
		&"thrash": [&"normal", MoveData.Category.PHYSICAL, 120, 100, 10],
		&"screech": [&"normal", MoveData.Category.STATUS, 0, 85, 40],
		&"poison_sting": [&"poison", MoveData.Category.PHYSICAL, 15, 100, 35],
		&"double_kick": [&"fighting", MoveData.Category.PHYSICAL, 30, 100, 30],
		&"horn_attack": [&"normal", MoveData.Category.PHYSICAL, 65, 100, 25],
		&"body_slam": [&"normal", MoveData.Category.PHYSICAL, 85, 100, 15],
		# Dégâts fixes et K.O. en un coup : comme Croc Fatal, statut sans effet (en attente).
		&"seismic_toss": [&"fighting", MoveData.Category.STATUS, 0, 100, 20],
		&"horn_drill": [&"normal", MoveData.Category.STATUS, 0, 30, 5],
	}
	for id: StringName in expected:
		var move := _data.get_move(id)
		assert_not_null(move, String(id))
		if move == null:
			continue
		assert_eq([move.type, move.category, move.power, move.accuracy, move.pp], expected[id],
			String(id))
	assert_eq(_data.get_move(&"karate_chop").crit_stage, 1, "critique élevé")
	var screech := _data.get_move(&"screech")
	assert_eq([screech.effects[0].stat, screech.effects[0].stages, screech.effects[0].target],
		[&"def", -2, MoveEffect.Target.FOE])
	# Mécaniques absentes du moteur (jalon-07.md §3.7) : la capacité frappe une fois, sans effet.
	var pending := {
		&"fury_attack": ["multi_hit"], &"fury_swipes": ["multi_hit"],
		&"double_kick": ["hits_2"], &"poison_sting": ["poison_30"],
		&"thrash": ["rampage"], &"body_slam": ["paralysis_30"],
		&"seismic_toss": ["level_damage"], &"horn_drill": ["ohko"],
	}
	for id: StringName in pending:
		assert_eq(_data.get_move(id).pending_effects, PackedStringArray(pending[id]),
			String(id))
