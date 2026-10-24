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
## Forêt de Jade (jalon 9, §2.5), même convention : PokeAPI, statistiques et rendement d'XP
## actuels (Pikachu et Raichu : valeurs depuis la 6e génération).
const FOREST_SPECIES := {
	&"caterpie": [10, "Chenipan", [&"bug"], 45, 30, 35, 20, 20, 45, 39, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"metapod": [11, "Chrysacier", [&"bug"], 50, 20, 55, 25, 25, 30, 72, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"butterfree": [12, "Papilusion", [&"bug", &"flying"], 60, 45, 50, 90, 80, 70, 178, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"weedle": [13, "Aspicot", [&"bug", &"poison"], 40, 35, 30, 20, 20, 50, 39, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"kakuna": [14, "Coconfort", [&"bug", &"poison"], 45, 25, 50, 25, 25, 35, 72, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"beedrill": [15, "Dardargnan", [&"bug", &"poison"], 65, 90, 40, 45, 80, 75, 178, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"pikachu": [25, "Pikachu", [&"electric"], 35, 55, 40, 50, 50, 90, 112, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"raichu": [26, "Raichu", [&"electric"], 60, 90, 55, 90, 80, 110, 218, 0.5,
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
	# Ordre du Pokédex ; jalon 20 (T7) : les 11 espèces de kanto_celadon.json.
	assert_eq(_data.get_species_ids(), [&"bulbasaur", &"ivysaur", &"venusaur", &"charmander",
		&"charmeleon", &"charizard", &"squirtle", &"wartortle", &"blastoise",
		&"caterpie", &"metapod", &"butterfree", &"weedle", &"kakuna", &"beedrill",
		&"pidgey", &"pidgeotto", &"pidgeot", &"rattata", &"raticate", &"spearow", &"fearow",
		&"ekans", &"arbok", &"pikachu", &"raichu", &"sandshrew", &"sandslash", &"nidoran_f",
		&"nidorina", &"nidoqueen", &"nidoran_m", &"nidorino", &"nidoking", &"clefairy",
		&"clefable", &"vulpix", &"ninetales", &"jigglypuff", &"wigglytuff", &"zubat", &"golbat",
		&"oddish", &"gloom", &"vileplume", &"paras", &"parasect",
		# Jalon 22 (T4) : Mimitoss, Aéromite, Machopeur, Canarticho, Doduo, Dodrio, Tadmorv,
		# Grotadmorv, Krabby, Électrode, Smogogo, Poissoroy, Magicarpe (kanto_j22.json).
		&"venonat", &"venomoth",
		# Jalon 17 (T7) : Taupiqueur, Triopikeur ; plus loin Goupix, Caninos, Magnéti, Magnéton,
		# Soporifik, Hypno (kanto_j17.json).
		&"diglett", &"dugtrio",
		# Jalon 15 (T12) : Miaouss et Persan (kanto_vermilion.json).
		&"meowth", &"persian",
		# Jalon 24 (T4) : kanto_j24.json (Psykokwak, Akwakwak, Têtarte, Tartard, Tentacruel,
		# Ramoloss, Flagadoss, Otaria, Lamantine, Crustabri, Krabby, Krabboss, Hypocéan,
		# Poissoroy, Magicarpe, fossiles, Artikodin) ; Saquedeneu et Léviator sont ceux des J20
		# et J19. Jalon 21 (T5) : Ptitard, Tentacool, Ronflex (kanto_j21.json).
		&"psyduck", &"golduck",
		&"mankey", &"primeape", &"growlithe", &"arcanine",
		&"poliwag", &"poliwhirl", &"poliwrath",
		&"abra", &"kadabra", &"alakazam", &"machop", &"machoke", &"machamp",
		&"bellsprout", &"weepinbell", &"victreebel", &"tentacool", &"tentacruel",
		&"geodude", &"graveler", &"golem", &"ponyta", &"rapidash", &"slowpoke", &"slowbro", &"magnemite", &"magneton",
		&"farfetchd", &"doduo", &"dodrio", &"seel", &"dewgong", &"grimer", &"muk", &"shellder",
		&"cloyster",
		# Jalon 19 (T3) : Fantominus, Spectrum, Noeunoeuf, Osselait, Ossatueur, Léviator
		# (kanto_tower.json ; Caninos vient du J17).
		&"gastly", &"haunter", &"gengar", &"onix",
		&"drowzee", &"hypno", &"krabby", &"kingler", &"voltorb", &"electrode", &"exeggcute", &"exeggutor",
		&"cubone", &"marowak", &"hitmonlee", &"hitmonchan", &"koffing", &"weezing", &"rhyhorn", &"rhydon", &"tangela", &"kangaskhan",
		&"horsea", &"seadra", &"goldeen", &"seaking", &"staryu", &"starmie", &"jynx", &"magmar", &"magikarp",
		&"gyarados", &"lapras", &"eevee", &"vaporeon", &"jolteon", &"flareon",
		&"omanyte", &"omastar", &"kabuto", &"kabutops", &"aerodactyl", &"snorlax", &"articuno", &"dragonair", &"dragonite"] as Array[StringName])
	# Jalon 25 (T7) : kanto_j25.json (Ponyta, Galopa, Magmar, Ptéra) ; Tadmorv, Grotadmorv,
	# Smogogo et Électrode sont ceux du J22 (kanto_j25_reprises.json retiré à la fusion de main).
	# Jalon 30 (T3) : espèces de la Ligue (kanto_j30.json : Lippoutou, Mackogneur, Ectoplasma,
	# Draco, Dracolosse ; kanto_j30_reprises.json : Kicklee, Tygnon, Lokhlass, Alakazam,
	# Rhinoféros, Noadkoko ; les reprises des J24 et J25 retirées à la fusion de main).
	assert_eq(_data.get_move_ids().size(), 153,
		"47 + 12 de la Forêt de Jade (jalon 9) + 7 d'Argenta (jalon 10) + Patience (J11) "
		+ "+ 21 du Mont Sélénite (jalon 12) + 8 du jalon 13 (les 5 du J12 qu'il reprenait : "
		+ "entrées du J12) + 6 du Cap d'Azuria (jalon 14) + Jackpot (J15) "
		+ "+ Coupe et Tonnerre (jalon 16) + 7 du jalon 17 + 8 de la Tour Pokémon (J19 ; "
		+ "Hypnose, Hurlement et Bélier viennent du J17) + 7 du jalon 20 + Vol (passe systèmes 2, T25) "
		+ "+ Surf (S2C) + Force (S2D) + Amnésie, Bouclier (J21 ; Constriction vient du J20) "
		+ "+ 5 du jalon 22 (Écrasement vient du J20) + 3 du J24 (j24.json : Force Poigne, "
		+ "Pince-Masse et Trempette sont ceux du J22) "
		+ "+ Déflagration et Poing de Feu (J25, j25.json) "
		+ "+ 11 du jalon 30 (Blizzard, Picanon, Déflagration et Poing de Feu sont ceux des J24 et J25)")
	assert_true(_data.has_move(&"struggle"))


func test_fly_move_data() -> void:
	_data.load_dir()
	var fly := _data.get_move(&"fly")
	assert_not_null(fly)
	if fly == null:
		return
	assert_eq([fly.name, fly.type, fly.category, fly.power, fly.accuracy, fly.pp],
		["Vol", &"flying", MoveData.Category.PHYSICAL, 90, 95, 15])
	assert_eq([fly.effects.size(), fly.effects[0].kind, fly.effects[0].texts,
		fly.effects[0].invulnerable], [1, MoveEffect.Kind.CHARGE, &"fly", true],
		"Vol : effet « charge » comme Tunnel (T25)")
	assert_eq(fly.pending_effects.size(), 0)


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
		# Forêt de Jade (jalon 9, dossier 10 §6) ; Raichu par la Pierre Foudre, jamais
		# déclenchée au jalon 9 (l'objet n'existe pas).
		&"caterpie": [&"metapod", 7], &"metapod": [&"butterfree", 10],
		&"weedle": [&"kakuna", 7], &"kakuna": [&"beedrill", 10],
		&"pikachu": [&"raichu", &"thunder_stone"],
		# Argenta (jalon 10, §2.3) : Rouge/Bleu ; Grolem par échange (« ??? » au Pokédex).
		&"sandshrew": [&"sandslash", 22], &"geodude": [&"graveler", 25],
		&"graveler": [&"golem", &""],
		# Route 3 et Mont Sélénite (jalon 12, §2.19) : Rouge/Bleu ; Mélofée et Rondoudou par la
		# Pierre Lune.
		&"ekans": [&"arbok", 22], &"zubat": [&"golbat", 22], &"paras": [&"parasect", 24],
		&"clefairy": [&"clefable", &"moon_stone"], &"jigglypuff": [&"wigglytuff", &"moon_stone"],
		# Azuria (jalon 13, §2.15) : seules les évolutions par niveau vers une espèce présente ;
		# Ortide et Boustiflor (Pierre Plante), Stari (Pierre Eau), Hypotrempe et Poissirène
		# (formes absentes) n'en déclarent pas.
		&"oddish": [&"gloom", 21], &"bellsprout": [&"weepinbell", 21],
		# Cap d'Azuria (jalon 14, §2.13) : Kadabra (Cordon d'échange, sans source) et Machoc
		# (Machopeur absent) n'en déclarent pas.
		&"abra": [&"kadabra", 16],
		# Carmin-sur-Mer (jalon 15, §2.7.1) : Rouge/Bleu.
		&"meowth": [&"persian", 28],
		# Jalon 17 (§2.12.1) : Rouge/Bleu.
		&"diglett": [&"dugtrio", 26], &"drowzee": [&"hypno", 26], &"magnemite": [&"magneton", 30],
		# Céladopole (jalon 20, T7, §2.10.1) : pierres du grand magasin (Ortide, Boustiflor et
		# Stari du J13 compris ; Caninos et Goupix du J17, qui reçoivent leur Pierre Feu) ; Évoli,
		# à trois branches, à part ci-dessous.
		&"gloom": [&"vileplume", &"leaf_stone"], &"weepinbell": [&"victreebel", &"leaf_stone"],
		&"staryu": [&"starmie", &"water_stone"], &"growlithe": [&"arcanine", &"fire_stone"],
		&"vulpix": [&"ninetales", &"fire_stone"],
		# Tour Pokémon (jalon 19, §2.12) : Rouge/Bleu. Spectrum (échange, Ectoplasma absent) et
		# Noeunoeuf (Pierre Plante absente) n'en déclarent pas.
		&"gastly": [&"haunter", 25], &"cubone": [&"marowak", 28],
		# Jalon 22 (§2.12) : Rouge/Bleu entre espèces présentes ; Machopeur (Mackogneur absent)
		# n'en déclare pas ; Magicarpe → Léviator (J19) au N20.
		&"venonat": [&"venomoth", 31], &"doduo": [&"dodrio", 31], &"grimer": [&"muk", 38],
		&"magikarp": [&"gyarados", 20],
		# Jalon 24 (T4, dossier 27 §14.1) : Rouge/Bleu. Ptitard → Têtarte (N25) et Tentacool →
		# Tentacruel (N30) ajoutés dans kanto_j21.json à la fusion de `main` (accord J21 / J24) ;
		# Krabby → Krabboss (N28) rétabli dans kanto_j22.json à la fusion du J24 dans `main`.
		&"poliwag": [&"poliwhirl", 25], &"tentacool": [&"tentacruel", 30],
		&"psyduck": [&"golduck", 33], &"poliwhirl": [&"poliwrath", &"water_stone"],
		&"slowpoke": [&"slowbro", 37], &"seel": [&"dewgong", 34],
		&"shellder": [&"cloyster", &"water_stone"], &"krabby": [&"kingler", 28],
		&"horsea": [&"seadra", 32], &"goldeen": [&"seaking", 33],
		&"omanyte": [&"omastar", 40], &"kabuto": [&"kabutops", 40],
		# Jalon 25 (T7) : Ponyta (Rouge/Bleu) ; Tadmorv → Grotadmorv est celui du J22.
		&"ponyta": [&"rapidash", 40],
		# Ligue (jalon 30, T3) : Rouge/Bleu ; Spectrum → Ectoplasma (échange) n'est pas déclaré
		# (Spectrum vient du J19).
		&"dragonair": [&"dragonite", 55],
	}
	var eevee := _data.get_species(&"eevee").evolutions
	assert_eq(eevee.map(func(r: EvolutionRule) -> Array: return [r.into, r.method, r.item]), [
		[&"vaporeon", EvolutionRule.Method.ITEM, &"water_stone"],
		[&"jolteon", EvolutionRule.Method.ITEM, &"thunder_stone"],
		[&"flareon", EvolutionRule.Method.ITEM, &"fire_stone"]])
	for id: StringName in _data.get_species_ids():
		var rules := _data.get_species(id).evolutions
		if id == &"eevee":
			continue
		if not expected.has(id):
			assert_eq(rules.size(), 0, "%s : forme finale" % id)
			continue
		assert_eq(rules.size(), 1, String(id))
		assert_eq(rules[0].into, expected[id][0], String(id))
		if expected[id][1] is int:
			assert_eq(rules[0].method, EvolutionRule.Method.LEVEL, String(id))
			assert_eq(rules[0].level, expected[id][1], String(id))
		elif expected[id][1] == &"":
			assert_eq(rules[0].method, EvolutionRule.Method.TRADE, String(id))
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
	# Jalon 11 : la brûlure de Flammèche est jouée (10 %).
	var ember := _data.get_move(&"ember")
	assert_eq(ember.pending_effects, PackedStringArray([]))
	assert_eq([ember.effects[0].kind, ember.effects[0].status, ember.effects[0].chance],
		[MoveEffect.Kind.STATUS, &"burn", 10])


## Capacités du J19 nécessaires aux learnsets complets (plan jalon-19 §0.4 n° 1) dont la
## description, hors du lot §15.7 du dossier 22, attend la relecture de Kevin : « draft ».
## Retirer l'identifiant d'ici quand le texte est validé.
const DRAFT_DESCRIPTIONS: Array[StringName] = []


func test_every_real_move_has_a_validated_description() -> void:
	_data.load_dir()
	for id: StringName in _data.get_move_ids():
		var move := _data.get_move(id)
		assert_false(move.description.is_empty(), String(id))
		assert_eq(move.draft, DRAFT_DESCRIPTIONS.has(id),
			"%s : description validée par Kevin (sauf brouillons listés)" % id)


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
		&"caterpie": 255, &"metapod": 120, &"butterfree": 45,
		&"weedle": 255, &"kakuna": 120, &"beedrill": 45, &"pikachu": 190, &"raichu": 75,
		&"sandshrew": 255, &"sandslash": 90, &"geodude": 255, &"graveler": 120, &"golem": 45,
		&"onix": 45,
		# Jalon 12.
		&"ekans": 255, &"arbok": 90, &"clefairy": 150, &"clefable": 25, &"jigglypuff": 170,
		&"wigglytuff": 50, &"zubat": 255, &"golbat": 90, &"paras": 190, &"parasect": 75,
		&"voltorb": 190, &"koffing": 190,
		# Jalon 13 (Azuria).
		&"oddish": 255, &"gloom": 120, &"bellsprout": 255, &"weepinbell": 120,
		&"shellder": 190, &"horsea": 225, &"goldeen": 225, &"staryu": 225, &"starmie": 60,
		# Jalon 14 (Cap d'Azuria).
		&"abra": 200, &"kadabra": 100, &"machop": 180,
		# Jalon 15 (T12).
		&"meowth": 255, &"persian": 90,
		# Jalon 17 (T7).
		&"diglett": 255, &"dugtrio": 50, &"drowzee": 190, &"hypno": 75, &"magnemite": 190,
		&"magneton": 60, &"growlithe": 190, &"vulpix": 190,
		# Jalon 20 (T7).
		&"arcanine": 75, &"ninetales": 75, &"eevee": 45,
		&"vaporeon": 45, &"jolteon": 45, &"flareon": 45, &"victreebel": 45, &"tangela": 45,
		&"vileplume": 45, &"rhyhorn": 120, &"kangaskhan": 45,
		# Jalon 19 (T3, Tour Pokémon ; Caninos vient du J17).
		&"gastly": 190, &"haunter": 90, &"exeggcute": 90, &"cubone": 190,
		&"marowak": 75, &"gyarados": 45,
		# Jalon 22 (T4).
		&"venonat": 190, &"venomoth": 75, &"machoke": 90, &"farfetchd": 45, &"doduo": 190,
		&"dodrio": 45, &"grimer": 190, &"muk": 75, &"krabby": 225, &"electrode": 60,
		&"weezing": 60, &"seaking": 60, &"magikarp": 255,
		# Jalon 24 (T4 ; Krabby, Poissoroy et Magicarpe sont ceux du J22).
		&"psyduck": 190, &"golduck": 75, &"poliwhirl": 120, &"poliwrath": 45,
		&"tentacruel": 60, &"slowpoke": 190, &"slowbro": 75, &"seel": 190,
		&"dewgong": 75, &"cloyster": 60, &"kingler": 60,
		&"seadra": 75, &"omanyte": 45,
		&"omastar": 45, &"kabuto": 45, &"kabutops": 45, &"articuno": 3,
		# Jalon 21 (T5).
		&"poliwag": 255, &"tentacool": 190, &"snorlax": 25,
		# Jalon 25 (T7) ; Tadmorv, Grotadmorv, Smogogo et Électrode sont ceux du J22.
		&"ponyta": 190, &"rapidash": 60, &"magmar": 45, &"aerodactyl": 45,
		# Jalon 30 (T3, Ligue) : reprises des J26 à J29 et espèces nouvelles (Lamantine,
		# Crustabri, Flagadoss : J24 ; Ptéra : J25).
		&"lapras": 45, &"alakazam": 50,
		&"rhydon": 60, &"exeggutor": 45, &"hitmonlee": 45, &"hitmonchan": 45,
		&"jynx": 45, &"machamp": 45, &"gengar": 45, &"dragonair": 45, &"dragonite": 45,
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


func test_poison_moves_are_coded() -> void:
	# Jalon 9 (T4, Q-6) : Poudre Toxik empoisonne toujours, Dard-Venin 30 %, Double-Dard 20 % ;
	# plus aucun poison en attente.
	_data.load_dir()
	var expected := {&"poison_powder": 100, &"poison_sting": 30, &"twineedle": 20}
	for id: StringName in expected:
		var move := _data.get_move(id)
		# Jalon 11 : Double-Dard porte aussi ses deux coups (HITS) avant le poison.
		var status_effect: MoveEffect = move.effects[-1]
		assert_eq(move.effects.size(), 2 if id == &"twineedle" else 1, String(id))
		assert_eq([status_effect.kind, status_effect.status, status_effect.chance],
			[MoveEffect.Kind.STATUS, &"poison", expected[id]], String(id))
	for id: StringName in _data.get_move_ids():
		for tag: String in _data.get_move(id).pending_effects:
			assert_false(tag.begins_with("poison"), "%s : %s" % [id, tag])


func test_invalid_status_effects_are_rejected() -> void:
	assert_true(PokemonData.new().add_moves_from_dict(_seed_move({ "kind": "status",
		"status": "poison" }), "ok"), "chance facultative")
	var cases: Dictionary = {
		"a": [{ "kind": "status" }, "« status » est obligatoire"],
		"b": [{ "kind": "status", "status": "toxic" }, "« status » vaut poison"],
		"c": [{ "kind": "status", "status": "poison", "chance": 0 }, "chance"],
		"d": [{ "kind": "status", "status": "poison", "fraction": 0.5 },
			"clé inconnue « fraction »"],
	}
	for source: String in cases:
		var data := PokemonData.new()
		assert_false(data.add_moves_from_dict(_seed_move(cases[source][0]), source), source)
		assert_string_contains("\n".join(data.get_errors()),
			"%s capacité « seedy » effet 1" % source)
		assert_string_contains("\n".join(data.get_errors()), cases[source][1])
	assert_push_error_count(4)


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
		&"fury_attack": [], &"fury_swipes": [],
		&"double_kick": [], &"poison_sting": [],
		# Jalon 30 (Q30-3) : Mania codée (effet « rampage »).
		&"thrash": [], &"body_slam": [],
		&"seismic_toss": [], &"horn_drill": [],
	}
	for id: StringName in pending:
		assert_eq(_data.get_move(id).pending_effects, PackedStringArray(pending[id]),
			String(id))


# --- Espèces et capacités du jalon 9 (Forêt de Jade, T1) --------------------------------

func test_forest_species_values() -> void:
	_data.load_dir()
	assert_eq(_data.get_errors().size(), 0, _errors())
	for id: StringName in FOREST_SPECIES:
		var v: Array = FOREST_SPECIES[id]
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


func test_forest_learnsets_are_red_blue() -> void:
	# Rouge/Bleu (PokeAPI, groupe red-blue) ; Chrysacier et Coconfort apprennent en plus
	# Armure au niveau 7, celui de leur évolution (Q-5, jalon-09.md §2.5).
	_data.load_dir()
	var expected := {
		&"caterpie": [[1, &"tackle"], [1, &"string_shot"]],
		&"metapod": [[1, &"harden"], [7, &"harden"]],
		&"butterfree": [[1, &"confusion"], [12, &"confusion"], [15, &"poison_powder"],
			[16, &"stun_spore"], [17, &"sleep_powder"], [21, &"supersonic"],
			[26, &"whirlwind"], [32, &"psybeam"]],
		&"weedle": [[1, &"poison_sting"], [1, &"string_shot"]],
		&"kakuna": [[1, &"harden"], [7, &"harden"]],
		&"beedrill": [[1, &"fury_attack"], [12, &"fury_attack"], [16, &"focus_energy"],
			[20, &"twineedle"], [25, &"rage"], [30, &"pin_missile"], [35, &"agility"]],
		&"pikachu": [[1, &"thunder_shock"], [1, &"growl"], [9, &"thunder_wave"],
			[16, &"quick_attack"], [26, &"swift"], [33, &"agility"], [43, &"thunder"]],
		&"raichu": [[1, &"thunder_shock"], [1, &"growl"], [1, &"thunder_wave"]],
	}
	for id: StringName in expected:
		assert_eq(_data.get_species(id).learnset, expected[id], String(id))
	# Ce que sait un Pokémon de la forêt aux niveaux des rencontres et des Dresseurs.
	assert_eq(_data.get_species(&"caterpie").moves_at(5), [&"tackle", &"string_shot"]
		as Array[StringName])
	assert_eq(_data.get_species(&"weedle").moves_at(5), [&"poison_sting", &"string_shot"]
		as Array[StringName])
	assert_eq(_data.get_species(&"metapod").moves_at(6), [&"harden"] as Array[StringName])
	assert_eq(_data.get_species(&"pikachu").moves_at(5), [&"thunder_shock", &"growl"]
		as Array[StringName])
	assert_eq(_data.get_species(&"pikachu").moves_at(9),
		[&"thunder_shock", &"growl", &"thunder_wave"] as Array[StringName])


func test_forest_moves_values() -> void:
	_data.load_dir()
	# [nom, type, catégorie, puissance, précision, PP] : valeurs actuelles, comme les autres.
	var expected := {
		&"string_shot": ["Sécrétion", &"bug", MoveData.Category.STATUS, 0, 95, 40],
		&"harden": ["Armure", &"normal", MoveData.Category.STATUS, 0, 0, 30],
		&"thunder_shock": ["Éclair", &"electric", MoveData.Category.SPECIAL, 40, 100, 30],
		&"thunder_wave": ["Cage-Éclair", &"electric", MoveData.Category.STATUS, 0, 90, 20],
		&"confusion": ["Choc Mental", &"psychic", MoveData.Category.SPECIAL, 50, 100, 25],
		&"stun_spore": ["Para-Spore", &"grass", MoveData.Category.STATUS, 0, 75, 30],
		&"supersonic": ["Ultrason", &"normal", MoveData.Category.STATUS, 0, 55, 20],
		&"psybeam": ["Rafale Psy", &"psychic", MoveData.Category.SPECIAL, 65, 100, 20],
		&"twineedle": ["Double-Dard", &"bug", MoveData.Category.PHYSICAL, 25, 100, 20],
		&"pin_missile": ["Dard-Nuée", &"bug", MoveData.Category.PHYSICAL, 25, 95, 20],
		&"swift": ["Météores", &"normal", MoveData.Category.SPECIAL, 60, 0, 20],
		&"thunder": ["Fatal-Foudre", &"electric", MoveData.Category.SPECIAL, 110, 70, 10],
	}
	for id: StringName in expected:
		var move := _data.get_move(id)
		assert_not_null(move, String(id))
		if move == null:
			continue
		assert_eq([move.name, move.type, move.category, move.power, move.accuracy, move.pp],
			expected[id], String(id))
	var shot := _data.get_move(&"string_shot")
	assert_eq([shot.effects[0].stat, shot.effects[0].stages, shot.effects[0].target],
		[&"spe", -2, MoveEffect.Target.FOE])
	var harden := _data.get_move(&"harden")
	assert_eq([harden.effects[0].stat, harden.effects[0].stages, harden.effects[0].target],
		[&"def", 1, MoveEffect.Target.SELF])
	assert_true(_data.get_move(&"swift").never_misses(), "Météores ne rate jamais")
	# Effets absents du moteur : paralysie et confusion au jalon 11, coups multiples plus
	# tard ; le poison de Double-Dard est réel depuis le T4 (avec Dard-Venin et Poudre Toxik).
	var pending := {
		&"string_shot": [], &"harden": [], &"swift": [],
		&"thunder_shock": [], &"thunder_wave": [],
		&"confusion": [], &"stun_spore": [],
		&"supersonic": [], &"psybeam": [],
		&"twineedle": [], &"pin_missile": [],
		&"thunder": [],
	}
	for id: StringName in pending:
		assert_eq(_data.get_move(id).pending_effects, PackedStringArray(pending[id]),
			String(id))


func test_moves_without_effect_say_so() -> void:
	# Lot de textes du jalon 9 (verrouillé le 2026-10-07) : toute capacité de statut dont
	# l'effet n'est pas joué porte « Sans effet dans le moteur actuel. », Poudre Dodo comprise.
	# Jalon 11 : la mention part avec l'effet (Cage-Éclair, Para-Spore, Poudre Dodo au T4).
	# Jalon 19 : Cyclone (changement forcé, décision de Kevin du 2026-10-16).
	# Passe systèmes 2 : Empal'Korne (K.O. en un coup, test_ohko.gd).
	# Jalon 30 (Q30-3) : Mimique, Frénésie, Mania, Danse Fleur codées (test_league_moves.gd).
	# Jalon 24 (T13) : Métronome codé (MetronomeRules).
	_data.load_dir()
	for id: StringName in [&"mist"]:
		assert_true(_data.get_move(id).description.ends_with(
			" Sans effet dans le moteur actuel."), String(id))
	for id: StringName in [&"thunder_wave", &"stun_spore", &"sleep_powder", &"supersonic",
			&"focus_energy", &"super_fang", &"seismic_toss", &"whirlwind", &"horn_drill",
			&"mirror_move", &"rage", &"thrash", &"petal_dance", &"metronome"]:
		assert_false(_data.get_move(id).description.contains("Sans effet"), String(id))
	assert_eq(_data.get_move(&"sleep_powder").description,
		"Une poudre soporifique qui endort la cible.")


func test_forest_wild_moves_have_all_their_effects() -> void:
	# Invariant de jouabilité adapté à la forêt : aux niveaux des rencontres (§6 du dossier 10)
	# et des Dresseurs, le seul effet encore absent est la paralysie d'Éclair (J11, limite
	# connue) ; le poison de Dard-Venin est joué depuis le T4, les dégâts aussi.
	_data.load_dir()
	# Jalon 11 : la paralysie d'Éclair est jouée ; plus aucun effet absent dans la forêt.
	var allowed: Dictionary = {}
	for pair: Array in [[&"caterpie", 7], [&"weedle", 6], [&"metapod", 7], [&"kakuna", 7],
			[&"pikachu", 5]]:
		for move_id: StringName in _data.get_species(pair[0]).moves_at(pair[1]):
			var move := _data.get_move(move_id)
			if allowed.has(move_id):
				assert_eq(move.pending_effects, PackedStringArray([allowed[move_id]]),
					String(move_id))
			else:
				assert_eq(move.pending_effects.size(), 0,
					"%s à Nv.%d connaît %s (effet non codé)" % [pair[0], pair[1], move_id])


func test_forest_move_texts_are_the_locked_ones() -> void:
	# Lot de textes du jalon 9 (verrouillé par Kevin le 2026-10-07), n° 16 à 39, mot pour mot.
	_data.load_dir()
	var lot := FileAccess.get_file_as_string("res://docs/design/textes/textes-brouillon-j9.md")
	assert_false(lot.is_empty(), "lot de textes lisible")
	for id: StringName in [&"string_shot", &"harden", &"thunder_shock", &"thunder_wave",
			&"confusion", &"stun_spore", &"supersonic", &"psybeam", &"twineedle",
			&"pin_missile", &"swift", &"thunder"]:
		var move := _data.get_move(id)
		assert_true(lot.contains("`%s` · `name` | " % id), String(id))
		assert_true(lot.contains("| « %s » |" % move.name), "%s : nom" % id)
		# Jalon 11 : « Sans effet dans le moteur actuel. » retiré avec l'effet (décision du J9).
		var locked := lot.contains("| « %s » |" % move.description) or lot.contains(
			"| « %s Sans effet dans le moteur actuel. » |" % move.description) or lot.contains(
			"| « %s Un seul coup dans le moteur actuel. » |" % move.description)
		assert_true(locked, "%s : description" % id)


# --- Cap d'Azuria (jalon 14, T5, jalon-14.md §2.13) ---------------------------------------------

func test_j14_species_values_and_red_blue_learnsets() -> void:
	_data.load_dir()
	assert_eq(_data.get_errors().size(), 0, _errors())
	var expected := {
		&"abra": [63, "Abra", [&"psychic"], 25, 20, 15, 105, 55, 90, 62],
		&"kadabra": [64, "Kadabra", [&"psychic"], 40, 35, 30, 120, 70, 105, 140],
		&"machop": [66, "Machoc", [&"fighting"], 70, 80, 50, 35, 35, 35, 61],
	}
	for id: StringName in expected:
		var row: Array = expected[id]
		var species := _data.get_species(id)
		assert_eq(species.source, "res://data/pokemon/species/kanto_j14.json", String(id))
		assert_eq([species.dex, species.name], [row[0], row[1]], String(id))
		assert_eq(species.types, Array(row[2], TYPE_STRING_NAME, "", null), String(id))
		assert_eq([species.base_stats[&"hp"], species.base_stats[&"atk"],
			species.base_stats[&"def"], species.base_stats[&"spa"], species.base_stats[&"spd"],
			species.base_stats[&"spe"]], row.slice(3, 9), String(id))
		assert_eq(species.base_exp, row[9], String(id))
		assert_eq(species.male_ratio, 0.75, String(id))
		assert_eq(species.growth_rate, ExpCurve.Rate.MEDIUM_SLOW, String(id))
	# Rouge/Bleu (pret/pokered) ; Entrave (J12, niveaux 1 et 20) et Soin (J13, niveau 31) dans
	# la table de Kadabra depuis l'alignement (T23).
	assert_eq(_data.get_species(&"abra").moves_at(15), [&"teleport"] as Array[StringName])
	assert_eq(_data.get_species(&"kadabra").moves_at(16), [&"teleport", &"disable", &"confusion"]
		as Array[StringName])
	assert_eq(_data.get_species(&"kadabra").moves_learned_at(20), [&"disable"]
		as Array[StringName])
	assert_eq(_data.get_species(&"kadabra").moves_learned_at(31), [&"recover"]
		as Array[StringName])
	assert_eq(_data.get_species(&"kadabra").moves_learned_at(38), [&"psychic"]
		as Array[StringName])
	assert_eq(_data.get_species(&"machop").moves_at(15), [&"karate_chop"] as Array[StringName],
		"Machoc 15 : Poing Karaté seul (défaut du plan §0.2 n° 4)")
	assert_eq(_data.get_species(&"machop").moves_learned_at(20), [&"low_kick"]
		as Array[StringName])
	assert_eq(_data.get_species(&"machop").moves_learned_at(46), [&"submission"]
		as Array[StringName])


func test_j14_moves() -> void:
	_data.load_dir()
	var rows := {
		&"teleport": ["Téléport", &"psychic", MoveData.Category.STATUS, 0, 0, 20, []],
		&"dig": ["Tunnel", &"ground", MoveData.Category.PHYSICAL, 100, 100, 10, []],
		&"low_kick": ["Balayage", &"fighting", MoveData.Category.PHYSICAL, 50, 90, 20, []],
		&"submission": ["Sacrifice", &"fighting", MoveData.Category.PHYSICAL, 80, 80, 25, []],
		&"psychic": ["Psyko", &"psychic", MoveData.Category.SPECIAL, 90, 100, 10, []],
		&"reflect": ["Protection", &"psychic", MoveData.Category.STATUS, 0, 0, 20, []],
	}
	for id: StringName in rows:
		var row: Array = rows[id]
		var move := _data.get_move(id)
		assert_eq([move.name, move.type, move.category, move.power, move.accuracy, move.pp],
			row.slice(0, 6), String(id))
		assert_eq(move.pending_effects, PackedStringArray(row[6]), String(id))
		assert_eq(move.priority, 0, "%s : priorité 0 (Rouge/Bleu, plan §2.5)" % id)
	assert_eq(_data.get_move(&"dig").description, "Le Pokémon creuse au premier tour et frappe"
		+ " au second. Sous terre, il évite les attaques.", "n° 60")
	var dig := _data.get_move(&"dig").effects
	assert_eq([dig.size(), dig[0].kind, dig[0].texts, dig[0].invulnerable],
		[1, MoveEffect.Kind.CHARGE, &"dig", true], "Tunnel : effet « charge » (T7)")
	var teleport := _data.get_move(&"teleport").effects
	assert_eq([teleport.size(), teleport[0].kind], [1, MoveEffect.Kind.TELEPORT])
	var kick := _data.get_move(&"low_kick").effects
	assert_eq([kick[0].kind, kick[0].chance], [MoveEffect.Kind.FLINCH, 30])
	var psychic := _data.get_move(&"psychic").effects
	assert_eq([psychic[0].kind, psychic[0].stat, psychic[0].stages, psychic[0].target,
		psychic[0].chance], [MoveEffect.Kind.STAT_STAGE, &"spd", -1, MoveEffect.Target.FOE, 10])
