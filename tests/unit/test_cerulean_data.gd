extends GutTest
## Données du jalon 13 (jalon-13.md T11, §2.15 ; dossier 16 §3, §7, §9, §11, §13, §15 ; textes
## de l'annexe A, validés par Kevin le 2026-10-11) : 9 espèces, capacités, Pokédex, CT11, Pépite,
## Dresseurs, tables de rencontres, zone de la Route 24.

## [dex, nom, types, PV, Atq, Déf, AtqS, DéfS, Vit, XP de base, part de mâles, croissance,
## taux de capture] (PokeAPI, valeurs actuelles, comme les espèces précédentes).
const SPECIES := {
	&"oddish": [43, "Mystherbe", [&"grass", &"poison"], 45, 50, 55, 75, 65, 30, 64, 0.5,
		ExpCurve.Rate.MEDIUM_SLOW, 255],
	&"gloom": [44, "Ortide", [&"grass", &"poison"], 60, 65, 70, 85, 75, 40, 138, 0.5,
		ExpCurve.Rate.MEDIUM_SLOW, 120],
	&"bellsprout": [69, "Chétiflor", [&"grass", &"poison"], 50, 75, 35, 70, 30, 40, 60, 0.5,
		ExpCurve.Rate.MEDIUM_SLOW, 255],
	&"weepinbell": [70, "Boustiflor", [&"grass", &"poison"], 65, 90, 50, 85, 45, 55, 137, 0.5,
		ExpCurve.Rate.MEDIUM_SLOW, 120],
	&"shellder": [90, "Kokiyas", [&"water"], 30, 65, 100, 45, 25, 40, 61, 0.5,
		ExpCurve.Rate.SLOW, 190],
	&"horsea": [116, "Hypotrempe", [&"water"], 30, 40, 70, 70, 25, 60, 59, 0.5,
		ExpCurve.Rate.MEDIUM_FAST, 225],
	&"goldeen": [118, "Poissirène", [&"water"], 45, 67, 60, 35, 50, 63, 64, 0.5,
		ExpCurve.Rate.MEDIUM_FAST, 225],
	&"staryu": [120, "Stari", [&"water"], 30, 45, 55, 70, 55, 85, 68, -1.0,
		ExpCurve.Rate.SLOW, 225],
	&"starmie": [121, "Staross", [&"water", &"psychic"], 60, 75, 85, 100, 85, 115, 182, -1.0,
		ExpCurve.Rate.SLOW, 60],
}

## Textes de l'annexe A (A.2) et du §21 (n° 59), mot pour mot.
const MOVE_TEXTS := {
	&"bubble_beam": ["Bulles d'O", "Projette des bulles avec force. Peut baisser la Vitesse."],
	&"absorb": ["Vol-Vie",
		"Aspire l'énergie de la cible. Le lanceur récupère la moitié des dégâts infligés."],
	&"recover": ["Soin",
		"Le lanceur récupère la moitié de ses PV. Sans effet dans le moteur actuel."],
	&"clamp": ["Claquoir", "La cible est prise entre deux coquilles pendant quelques tours."],
	&"aurora_beam": ["Onde Boréale",
		"Un rayon aux couleurs de l'aurore frappe la cible. Peut baisser son Attaque."],
	&"ice_beam": ["Laser Glace", "Un rayon glacé frappe la cible. Peut la geler."],
	&"waterfall": ["Cascade",
		"Le lanceur fonce sur la cible dans une gerbe d'eau. Peut l'apeurer."],
	&"petal_dance": ["Danse Fleur",
		"Le lanceur attaque dans une pluie de pétales. Sans effet dans le moteur actuel."],
}

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))


# --- Espèces -------------------------------------------------------------------------------

func test_species_values() -> void:
	for id: StringName in SPECIES:
		var v: Array = SPECIES[id]
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species == null:
			continue
		var types: Array[StringName] = []
		types.assign(v[2])
		assert_eq([species.dex, species.name, species.types], [v[0], v[1], types], String(id))
		assert_eq(species.base_stats, {&"hp": v[3], &"atk": v[4], &"def": v[5], &"spa": v[6],
			&"spd": v[7], &"spe": v[8]} as Dictionary[StringName, int], String(id))
		assert_eq([species.base_exp, species.male_ratio, species.growth_rate,
			species.catch_rate], [v[9], v[10], v[11], v[12]], String(id))


func test_learnsets_are_red_blue_at_all_levels() -> void:
	# Convention du J12 : apprentissages de Rouge/Bleu (PokeAPI, groupe red-blue), tous niveaux.
	var expected := {
		&"staryu": [[1, &"tackle"], [17, &"water_gun"], [22, &"harden"], [27, &"recover"],
			[32, &"swift"], [37, &"minimize"], [42, &"light_screen"], [47, &"hydro_pump"]],
		&"starmie": [[1, &"tackle"], [1, &"water_gun"], [1, &"harden"]],
		&"horsea": [[1, &"bubble"], [19, &"smokescreen"], [24, &"leer"], [30, &"water_gun"],
			[37, &"agility"], [45, &"hydro_pump"]],
		&"shellder": [[1, &"tackle"], [1, &"withdraw"], [18, &"supersonic"], [23, &"clamp"],
			[30, &"aurora_beam"], [39, &"leer"], [50, &"ice_beam"]],
		&"goldeen": [[1, &"peck"], [1, &"tail_whip"], [19, &"supersonic"],
			[24, &"horn_attack"], [30, &"fury_attack"], [37, &"waterfall"],
			[45, &"horn_drill"], [54, &"agility"]],
		&"oddish": [[1, &"absorb"], [15, &"poison_powder"], [17, &"stun_spore"],
			[19, &"sleep_powder"], [24, &"acid"], [33, &"petal_dance"], [46, &"solar_beam"]],
		&"bellsprout": [[1, &"vine_whip"], [1, &"growth"], [13, &"wrap"],
			[15, &"poison_powder"], [18, &"sleep_powder"], [21, &"stun_spore"], [26, &"acid"],
			[33, &"razor_leaf"], [42, &"slam"]],
	}
	for id: StringName in expected:
		assert_eq(_data.get_species(id).learnset, expected[id], String(id))
	# Ce que savent les Pokémon des Dresseurs du J13 (capacités apprises au niveau).
	assert_eq(_data.get_species(&"staryu").moves_at(18), [&"tackle", &"water_gun"]
		as Array[StringName])
	assert_eq(_data.get_species(&"horsea").moves_at(16), [&"bubble"] as Array[StringName])
	assert_eq(_data.get_species(&"shellder").moves_at(16), [&"tackle", &"withdraw"]
		as Array[StringName])
	assert_eq(_data.get_species(&"goldeen").moves_at(19),
		[&"peck", &"tail_whip", &"supersonic"] as Array[StringName])
	assert_eq(_data.get_species(&"oddish").moves_at(12), [&"absorb"] as Array[StringName])
	assert_eq(_data.get_species(&"bellsprout").moves_at(12), [&"vine_whip", &"growth"]
		as Array[StringName])


func test_evolutions_by_level_only() -> void:
	# §2.15 : Mystherbe → Ortide et Chétiflor → Boustiflor au niveau 21 ; aucune évolution vers
	# une espèce absente ni par pierre (Pierre Plante, Pierre Eau : pas d'objet au J13).
	for pair: Array in [[&"oddish", &"gloom"], [&"bellsprout", &"weepinbell"]]:
		var rules := _data.get_species(pair[0]).evolutions
		assert_eq(rules.size(), 1, String(pair[0]))
		assert_eq([rules[0].into, rules[0].method, rules[0].level],
			[pair[1], EvolutionRule.Method.LEVEL, 21], String(pair[0]))
	for id: StringName in [&"gloom", &"weepinbell", &"staryu", &"starmie", &"horsea",
			&"shellder", &"goldeen"]:
		assert_eq(_data.get_species(id).evolutions.size(), 0, String(id))


# --- Capacités -----------------------------------------------------------------------------

func test_new_moves_values_and_texts() -> void:
	# [type, catégorie, puissance, précision, PP] : valeurs actuelles.
	var expected := {
		&"bubble_beam": [&"water", MoveData.Category.SPECIAL, 65, 100, 20],
		&"absorb": [&"grass", MoveData.Category.SPECIAL, 20, 100, 25],
		&"recover": [&"normal", MoveData.Category.STATUS, 0, 0, 5],
		&"clamp": [&"water", MoveData.Category.PHYSICAL, 35, 85, 15],
		&"aurora_beam": [&"ice", MoveData.Category.SPECIAL, 65, 100, 20],
		&"ice_beam": [&"ice", MoveData.Category.SPECIAL, 90, 100, 10],
		&"waterfall": [&"water", MoveData.Category.PHYSICAL, 80, 100, 15],
		&"petal_dance": [&"grass", MoveData.Category.SPECIAL, 120, 100, 10],
		&"acid": [&"poison", MoveData.Category.SPECIAL, 40, 100, 30],
		&"wrap": [&"normal", MoveData.Category.PHYSICAL, 15, 90, 20],
		&"smokescreen": [&"normal", MoveData.Category.STATUS, 0, 100, 20],
		&"minimize": [&"normal", MoveData.Category.STATUS, 0, 0, 10],
		&"light_screen": [&"psychic", MoveData.Category.STATUS, 0, 0, 30],
	}
	for id: StringName in expected:
		var move := _data.get_move(id)
		assert_not_null(move, String(id))
		if move == null:
			continue
		assert_eq([move.type, move.category, move.power, move.accuracy, move.pp], expected[id],
			String(id))
	for id: StringName in MOVE_TEXTS:
		assert_eq([_data.get_move(id).name, _data.get_move(id).description], MOVE_TEXTS[id],
			String(id))
	# Acide : version du J12 (Déf. Spé. −1, texte validé de l'annexe A du J12).
	assert_eq(_data.get_move(&"acid").description,
		"Asperge la cible d'acide. Peut baisser sa Défense Spéciale.")


func test_effects_existing_or_pending() -> void:
	# Effets que le moteur joue déjà (statistiques, gel, apeurement).
	var stat := {&"bubble_beam": [&"spe", -1, MoveEffect.Target.FOE, 10],
		&"aurora_beam": [&"atk", -1, MoveEffect.Target.FOE, 10],
		&"acid": [&"spd", -1, MoveEffect.Target.FOE, 10],
		&"smokescreen": [&"acc", -1, MoveEffect.Target.FOE, 100],
		&"minimize": [&"eva", 1, MoveEffect.Target.SELF, 100]}
	for id: StringName in stat:
		var effect: MoveEffect = _data.get_move(id).effects[0]
		assert_eq([effect.kind, effect.stat, effect.stages, effect.target, effect.chance],
			[MoveEffect.Kind.STAT_STAGE] + stat[id], String(id))
	var ice: MoveEffect = _data.get_move(&"ice_beam").effects[0]
	assert_eq([ice.kind, ice.status, ice.chance], [MoveEffect.Kind.STATUS, &"freeze", 10])
	var fall: MoveEffect = _data.get_move(&"waterfall").effects[0]
	assert_eq([fall.kind, fall.chance], [MoveEffect.Kind.FLINCH, 20])
	# Effets absents du moteur à ce jour (T10 : `drain` et `trap` du J12 pas encore livrés) :
	# en attente, comme Étreinte et Danse Flamme ; à brancher quand le J12 les fournit.
	var pending := {&"absorb": ["drain"], &"clamp": ["trap"], &"wrap": ["trap"],
		&"recover": ["heal_half"], &"petal_dance": ["rampage"],
		&"light_screen": ["light_screen"]}
	for id: StringName in pending:
		assert_eq(_data.get_move(id).pending_effects, PackedStringArray(pending[id]),
			String(id))
		assert_eq(_data.get_move(id).effects.size(), 0, String(id))


# --- Pokédex ---------------------------------------------------------------------------------

func test_pokedex_entries_of_annex_a() -> void:
	var dex := PokedexLibrary.new()
	assert_true(dex.load_file(), "\n".join(dex.get_errors()))
	var official := {&"staryu": [0.8, 34.5], &"starmie": [1.1, 80.0], &"horsea": [0.4, 8.0],
		&"shellder": [0.3, 4.0], &"goldeen": [0.6, 15.0], &"oddish": [0.5, 5.4],
		&"gloom": [0.8, 8.6], &"bellsprout": [0.7, 4.0], &"weepinbell": [1.0, 6.4]}
	for id: StringName in official:
		var info := dex.get_species(id)
		assert_almost_eq(info.height, float(official[id][0]), 0.001, String(id))
		assert_almost_eq(info.weight, float(official[id][1]), 0.001, String(id))
	assert_eq(dex.get_species(&"staryu").description, "Le cœur rouge de son corps brille "
		+ "faiblement dans le noir. Les nuits calmes, on le voit scintiller au bord de l'eau "
		+ "comme une étoile tombée.")
	assert_eq(dex.get_notes(&"oddish")[0].text, "Une touffe de feuilles au milieu du chemin, "
		+ "qui n'y était pas la veille : c'est souvent lui.")
	for id: StringName in [&"starmie", &"gloom", &"weepinbell"]:
		assert_eq(dex.get_notes(id).size(), 0, "%s : forme évoluée, sans note" % id)


# --- CT11, Pépite ------------------------------------------------------------------------------

func test_tm11_and_its_compatibilities() -> void:
	var items := ItemLibrary.new()
	assert_true(items.load_dir(), "\n".join(items.get_errors()))
	assert_true(items.check_moves(_data))
	var tm := items.get_item(&"tm11")
	assert_eq([tm.name, tm.category, tm.tm_number, tm.teaches, tm.price, tm.feminine],
		["CT11 — Bulles d'O", ItemData.Category.TM, 11, &"bubble_beam", 0, true])
	assert_eq(tm.description, "Projette des bulles avec force. Peut baisser la Vitesse.")
	assert_false(tm.is_sellable(), "CT jamais vendue")
	assert_eq(tm.added_text(1), "obtenue", "toast « CT11 — Bulles d'O / obtenue »")
	assert_eq(items.get_tm(11), &"tm11")
	assert_eq(_data.tm_move(11), &"bubble_beam")
	# Table de Rouge/Bleu régénérée (tools/gen_tm_compatibility.py, 47 espèces).
	var compatible: Array[StringName] = []
	for id: StringName in _data.get_species_ids():
		if _data.can_learn_tm(id, 11):
			compatible.append(id)
	assert_eq(compatible, [&"squirtle", &"wartortle", &"blastoise", &"rattata", &"raticate",
		&"nidorina", &"nidoqueen", &"nidorino", &"nidoking", &"shellder", &"horsea",
		&"goldeen", &"staryu", &"starmie"] as Array[StringName])
	var squirtle := PokemonFactory.create(_data, &"squirtle", 20, GameRng.new(3))
	assert_eq(TmTeach.check(squirtle, tm, _data), TmTeach.Check.COMPATIBLE)
	var oddish := PokemonFactory.create(_data, &"oddish", 12, GameRng.new(3))
	assert_eq(TmTeach.check(oddish, tm, _data), TmTeach.Check.INCOMPATIBLE)


func test_nugget() -> void:
	var items := ItemLibrary.new()
	items.load_dir()
	var nugget := items.get_item(&"nugget")
	assert_eq([nugget.name, nugget.plural, nugget.feminine, nugget.category, nugget.price],
		["Pépite", "Pépites", true, ItemData.Category.FIELD, 10000])
	assert_eq(nugget.description,
		"Une pépite d'or pur. Elle ne sert à rien… sauf à être vendue très cher.")
	assert_true(nugget.is_sellable())
	assert_eq(nugget.sell_price(), 5000, "§2.5 : vendue 5 000 ₽")
	assert_false(nugget.targets_pokemon())
	assert_eq(nugget.field_use, &"", "§2.13 : aucun usage")
	assert_false(nugget.usable_in(ItemData.CONTEXT_FIELD), "pas de bouton UTILISER (T16)")
	assert_eq(nugget.quantity_text(1), "Pépite ×1")
	assert_eq(nugget.added_text(1), "Ajoutée au Sac")
	# « Sans UTILISER » (dossier 16 §17) : la condition `field_use` du J12 (T20) n'est pas
	# encore livrée ; jalon-13.md §0.4 (T10).


# --- Dresseurs -----------------------------------------------------------------------------

func _trainers() -> TrainerLibrary:
	var trainers := TrainerLibrary.new(_data)
	assert_true(trainers.load_dir(), "\n".join(trainers.get_errors()))
	return trainers


func _team(slots: Array[TrainerSlot]) -> Array:
	var out: Array = []
	for slot: TrainerSlot in slots:
		out.append([slot.species, slot.level])
	return out


func test_rival_cerulean() -> void:
	var rival := _trainers().get_trainer(&"rival_cerulean")
	assert_not_null(rival)
	assert_eq([rival.name, rival.ai, rival.can_lose, rival.heal_after, rival.gives_exp],
		["{rival}", BattleAI.SMART, false, false, true])
	assert_eq([rival.prize_money, rival.prize_per_level, rival.prize_for(17)], [0, 35, 595])
	assert_eq([rival.start_message, rival.end_message, rival.allow_bag], [true, false, true])
	assert_true(rival.moment_on_win, "§2.8 : Grand moment à la victoire seulement (T16)")
	var expected := {&"bulbasaur": &"charmeleon", &"charmander": &"wartortle",
		&"squirtle": &"ivysaur"}
	for starter: StringName in expected:
		assert_eq(_team(rival.team_for(starter)),
			[[&"pidgeotto", 18], [&"rattata", 15], [expected[starter], 17]], String(starter))
		for slot: TrainerSlot in rival.team_for(starter):
			assert_eq(slot.moves.size(), 0, "capacités apprises au niveau")


func test_cerulean_gym() -> void:
	var trainers := _trainers()
	var lucas := trainers.get_trainer(&"cerulean_gym_lucas")
	assert_eq([lucas.name, lucas.ai, lucas.prize_money], ["Nageur Lucas", BattleAI.RANDOM, 80])
	assert_eq(_team(lucas.team), [[&"horsea", 16], [&"shellder", 16]])
	var diane := trainers.get_trainer(&"cerulean_gym_diane")
	assert_eq([diane.name, diane.ai, diane.prize_money],
		["Jeune Dresseuse Diane", BattleAI.RANDOM, 285])
	assert_eq(_team(diane.team), [[&"goldeen", 19]])
	var misty := trainers.get_trainer(&"cerulean_gym_misty")
	assert_eq([misty.name, misty.ai, misty.prize_money, misty.card_name, misty.card_title],
		["Ondine", BattleAI.SMART, 2100, "ONDINE", "Championne d'Arène d'Azuria"])
	assert_eq([misty.start_message, misty.end_message, misty.allow_bag], [false, true, true])
	assert_eq(_team(misty.team), [[&"staryu", 18], [&"starmie", 21]])
	assert_eq(misty.team[0].moves, [&"tackle", &"water_gun"] as Array[StringName])
	assert_eq(misty.team[1].moves, [&"tackle", &"water_gun", &"harden", &"bubble_beam"]
		as Array[StringName])


func test_nugget_bridge_trainers() -> void:
	# P3 (Gamin Malo : Sabelette, Abo) attend Abo (J12) : jalon-13.md §0.4.
	var trainers := _trainers()
	var expected := {
		&"route_24_timeo": ["Scout Timéo", 120,
			[[&"caterpie", 10], [&"weedle", 10], [&"metapod", 10], [&"kakuna", 10]]],
		&"route_24_alice": ["Jeune Dresseuse Alice", 180,
			[[&"pidgey", 12], [&"oddish", 12], [&"bellsprout", 12]]],
		&"route_24_romane": ["Jeune Dresseuse Romane", 240,
			[[&"nidoran_f", 16], [&"nidoran_m", 16]]],
		&"route_24_ethan": ["Campeur Ethan", 360, [[&"mankey", 18]]],
	}
	for id: StringName in expected:
		var trainer := trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq([trainer.name, trainer.prize_money, trainer.ai],
			[expected[id][0], expected[id][1], BattleAI.RANDOM], String(id))
		assert_eq(_team(trainer.team), expected[id][2], String(id))
	for pending: StringName in [&"route_24_malo", &"nugget_rocket", &"route_4_clara"]:
		assert_null(trainers.get_trainer(pending), "%s : attend les espèces du J12" % pending)


# --- Rencontres et zone ----------------------------------------------------------------------

func _slots(table: EncounterTable) -> Array:
	var out: Array = []
	for slot: EncounterSlot in table.slots:
		out.append([slot.species, slot.min_level, slot.max_level, slot.weight])
	return out


func test_encounter_tables() -> void:
	var lib := EncounterLibrary.new(_data)
	assert_true(lib.load_dir(), "\n".join(lib.get_errors()))
	var north := lib.get_table(&"route_24")
	assert_eq([north.id, north.rate, north.ramp_from, north.ramp_max],
		[&"route_24_grass", 25, 15, 20])
	assert_eq(_slots(north), [[&"oddish", 12, 14, 25], [&"bellsprout", 12, 14, 25],
		[&"pidgey", 12, 13, 15], [&"caterpie", 7, 8, 10], [&"weedle", 7, 8, 10],
		[&"metapod", 8, 9, 7], [&"kakuna", 8, 9, 8]])
	# Route 4 : Abo (10–12, poids 15) manque tant que le J12 n'a pas livré l'espèce
	# (jalon-13.md §0.4) ; table non branchée (aucune herbe avant la carte du T8).
	var plain := lib.get_table(&"route_4")
	assert_eq([plain.id, plain.rate, plain.ramp_from, plain.ramp_max],
		[&"route_4_grass", 25, 15, 20])
	assert_eq(_slots(plain), [[&"rattata", 8, 12, 30], [&"spearow", 8, 12, 30],
		[&"sandshrew", 10, 12, 15], [&"mankey", 10, 13, 10]])


func test_route_24_zone() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file(), "\n".join(zones.get_errors()))
	var zone := zones.get_zone(&"route_24")
	assert_eq([zone.name, zone.kind, zone.subtitle], ["Route 24", &"route", "Le Pont Pépite"])
	assert_eq(zone.description, "Au nord d'Azuria, un long pont franchit la rivière. Au-delà, "
		+ "une prairie tranquille où l'herbe pousse haut.")
	assert_eq(zones.get_zone(&"cerulean_city").description, "Une ville claire traversée de "
		+ "canaux, entre la montagne et le cap. Partout, on entend l'eau couler.")
