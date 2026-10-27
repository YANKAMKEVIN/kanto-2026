extends GutTest
## Espèces du jalon 23 sans dépendance (plan `jalon-23.md` §2.14, T6 ; dossier 26 §6.4) :
## Leveinard, Insécateur, Scarabrute, Tauros (`data/pokemon/species/kanto_j23.json`). Convention
## du projet : types, statistiques et rendement d'XP modernes (PokeAPI), taux de capture et
## apprentissages de Rouge/Bleu. Mimitoss, Aéromite, Doduo, Dodrio, Tadmorv, Grotadmorv et
## Smogogo sont créés par le J22 (`kanto_j22.json`, session plus ancienne) : repris à la fusion (T9).

## id → [dex, nom, types, PV, Atq, Déf, Atq. Spé., Déf. Spé., Vit., rendement, part de mâles,
## croissance, taux de capture RB].
const SPECIES: Dictionary[StringName, Array] = {
	&"chansey": [113, "Leveinard", [&"normal"], 250, 5, 5, 35, 105, 50, 395, 0.0,
		ExpCurve.Rate.FAST, 30],
	&"scyther": [123, "Insécateur", [&"bug", &"flying"], 70, 110, 80, 55, 80, 105, 100, 0.5,
		ExpCurve.Rate.MEDIUM_FAST, 45],
	&"pinsir": [127, "Scarabrute", [&"bug"], 65, 125, 100, 55, 70, 85, 175, 0.5,
		ExpCurve.Rate.SLOW, 45],
	&"tauros": [128, "Tauros", [&"normal"], 75, 100, 95, 40, 70, 110, 172, 1.0,
		ExpCurve.Rate.SLOW, 45],
}
## Taille (m) et poids (kg) officiels.
const DEX_SIZES: Dictionary[StringName, Array] = {
	&"chansey": [1.1, 34.6], &"scyther": [1.5, 56.0], &"pinsir": [1.5, 55.0],
	&"tauros": [1.4, 88.4],
}
## Niveaux des rencontres du Parc Safari (dossier 26 §6.2 : 22 à 33).
const PARK_LEVELS: Array[int] = [22, 33]

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))


func test_species_values() -> void:
	for id: StringName in SPECIES:
		var v: Array = SPECIES[id]
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species == null:
			continue
		assert_eq(species.dex, v[0], String(id))
		assert_eq(species.name, v[1], String(id))
		assert_eq(species.types, Array(v[2], TYPE_STRING_NAME, &"", null), String(id))
		assert_eq(species.base_stats, {&"hp": v[3], &"atk": v[4], &"def": v[5], &"spa": v[6],
			&"spd": v[7], &"spe": v[8]} as Dictionary[StringName, int], String(id))
		assert_eq(species.base_exp, v[9], String(id))
		assert_eq(species.male_ratio, v[10], String(id))
		assert_eq(species.growth_rate, v[11], String(id))
		assert_eq(species.catch_rate, v[12], "%s : taux de capture RB" % id)
		assert_eq(species.source.get_file(), "kanto_j23.json", String(id))


func test_none_of_them_evolves() -> void:
	for id: StringName in SPECIES:
		assert_eq(_data.get_species(id).evolutions.size(), 0, "%s : forme unique" % id)


func test_learnsets_follow_red_blue() -> void:
	assert_eq(_data.get_species(&"chansey").moves_at(23),
		[&"pound", &"double_slap"] as Array[StringName])
	assert_eq(_data.get_species(&"chansey").moves_at(26),
		[&"pound", &"double_slap", &"sing"] as Array[StringName])
	assert_eq(_data.get_species(&"scyther").moves_at(28),
		[&"quick_attack", &"leer", &"focus_energy", &"double_team"] as Array[StringName])
	assert_eq(_data.get_species(&"pinsir").moves_at(23),
		[&"vise_grip"] as Array[StringName])
	assert_eq(_data.get_species(&"pinsir").moves_at(28),
		[&"vise_grip", &"seismic_toss"] as Array[StringName])
	assert_eq(_data.get_species(&"tauros").moves_at(28),
		[&"tackle", &"stomp", &"tail_whip"] as Array[StringName])


func test_every_move_known_in_the_park_exists() -> void:
	for id: StringName in SPECIES:
		for level: int in range(PARK_LEVELS[0], PARK_LEVELS[1] + 1):
			var moves := _data.get_species(id).moves_at(level)
			assert_gt(moves.size(), 0, "%s N%d" % [id, level])
			for move_id: StringName in moves:
				assert_true(_data.has_move(move_id), "%s N%d : %s existe" % [id, level, move_id])


func test_new_moves_follow_red_blue() -> void:
	var vice := _data.get_move(&"vise_grip") # Force Poigne du J22
	assert_eq([vice.type, vice.power, vice.accuracy, vice.pp], [&"normal", 55, 100, 30])
	var stomp := _data.get_move(&"stomp")
	assert_eq([stomp.type, stomp.power, stomp.accuracy, stomp.pp], [&"normal", 65, 100, 20])
	assert_eq(stomp.effects.size(), 1, "apeurement 30 %")
	var dance := _data.get_move(&"swords_dance")
	assert_eq(dance.pp, 30)
	assert_eq(dance.effects.size(), 1, "Attaque +2 sur soi")
	assert_eq(dance.pending_effects.size(), 0)
	var guillotine := _data.get_move(&"guillotine")
	assert_eq([guillotine.accuracy, guillotine.pp], [30, 5])
	assert_eq(guillotine.pending_effects.size(), 0,
		"K.O. en un coup joué par la passe systèmes 2 (A-33 : mention « Sans effet » retirée)")
	assert_eq(guillotine.effects.size(), 1, "effet ohko, comme Empal'Korne")


func test_pokedex_entries_at_official_size() -> void:
	var lib := PokedexLibrary.new()
	assert_true(lib.load_file(), "\n".join(lib.get_errors()))
	for id: StringName in DEX_SIZES:
		var info := lib.get_species(id)
		assert_not_null(info, String(id))
		if info == null:
			continue
		assert_almost_eq(info.height, float(DEX_SIZES[id][0]), 0.001, String(id))
		assert_almost_eq(info.weight, float(DEX_SIZES[id][1]), 0.001, String(id))
		assert_eq(info.notes.size(), 1, "%s : une note avec la table du Parc (T13, Q-6)" % id)


func test_tm_and_hm_compatibilities_are_generated() -> void:
	assert_true(_data.can_learn_tm(&"chansey", 34), "Leveinard : CT34 Patience")
	assert_true(_data.can_learn_hm(&"scyther", 1), "Insécateur : CS01 Coupe")
	assert_true(_data.can_learn_hm(&"pinsir", 4), "Scarabrute : CS04 Force")
	assert_true(_data.can_learn_hm(&"tauros", 4), "Tauros : CS04 Force")
	assert_false(_data.can_learn_hm(&"tauros", 3), "Tauros n'apprend pas Surf en Rouge/Bleu")
