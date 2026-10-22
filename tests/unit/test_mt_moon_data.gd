extends GutTest
## Données du jalon 12 (Route 3 et Mont Sélénite, T12 ; docs/tech/jalon-12.md §2.10, §2.19) :
## espèces, capacités, objets, Pokédex, Dresseurs, rencontres, CT. Textes recopiés mot pour mot de
## l'annexe A de jalon-12.md (validée par Kevin le 2026-10-11) et du dossier 15 §20.
## Fichier séparé des tests partagés : seuls leurs listes exhaustives y ont été mises à jour.

const PLAN := "res://docs/tech/jalon-12.md"
const DOSSIER_15 := "res://docs/design/dossier-15-route-3-mont-selenite.md"

## PokeAPI, statistiques, taux et rendement d'XP actuels, types modernes (Fée) :
## [dex, nom, types, PV, Att, Déf, Att. Spé., Déf. Spé., Vit., base_exp, male_ratio, croissance,
## taux de capture].
const SPECIES := {
	&"ekans": [23, "Abo", [&"poison"], 35, 60, 44, 40, 54, 55, 58, 0.5,
		ExpCurve.Rate.MEDIUM_FAST, 255],
	&"arbok": [24, "Arbok", [&"poison"], 60, 95, 69, 65, 79, 80, 157, 0.5,
		ExpCurve.Rate.MEDIUM_FAST, 90],
	&"clefairy": [35, "Mélofée", [&"fairy"], 70, 45, 48, 60, 65, 35, 113, 0.25,
		ExpCurve.Rate.FAST, 150],
	&"clefable": [36, "Mélodelfe", [&"fairy"], 95, 70, 73, 95, 90, 60, 217, 0.25,
		ExpCurve.Rate.FAST, 25],
	&"jigglypuff": [39, "Rondoudou", [&"normal", &"fairy"], 115, 45, 20, 45, 25, 20, 95, 0.25,
		ExpCurve.Rate.FAST, 170],
	&"wigglytuff": [40, "Grodoudou", [&"normal", &"fairy"], 140, 70, 45, 85, 50, 45, 196, 0.25,
		ExpCurve.Rate.FAST, 50],
	&"zubat": [41, "Nosferapti", [&"poison", &"flying"], 40, 45, 35, 30, 40, 55, 49, 0.5,
		ExpCurve.Rate.MEDIUM_FAST, 255],
	&"golbat": [42, "Nosferalto", [&"poison", &"flying"], 75, 80, 70, 65, 75, 90, 159, 0.5,
		ExpCurve.Rate.MEDIUM_FAST, 90],
	&"paras": [46, "Paras", [&"bug", &"grass"], 35, 70, 55, 45, 55, 25, 57, 0.5,
		ExpCurve.Rate.MEDIUM_FAST, 190],
	&"parasect": [47, "Parasect", [&"bug", &"grass"], 60, 95, 80, 60, 80, 30, 142, 0.5,
		ExpCurve.Rate.MEDIUM_FAST, 75],
	&"voltorb": [100, "Voltorbe", [&"electric"], 40, 30, 50, 55, 55, 100, 66, -1.0,
		ExpCurve.Rate.MEDIUM_FAST, 190],
	&"koffing": [109, "Smogo", [&"poison"], 40, 65, 95, 60, 45, 35, 68, 0.5,
		ExpCurve.Rate.MEDIUM_FAST, 190],
}
## Capacités du J12 : [type, catégorie, puissance, précision, PP, effets en attente].
## Activés au T13 (genres drain, trap, disable, rest, fixed_damage « value ») : plus rien en
## attente. Reportés (mention « Sans effet dans le moteur actuel. ») : metronome, haze,
## light_screen, recoil_damage.
const MOVES := {
	&"leech_life": [&"bug", MoveData.Category.PHYSICAL, 20, 100, 15, []],
	&"wrap": [&"normal", MoveData.Category.PHYSICAL, 15, 90, 20, []],
	&"disable": [&"normal", MoveData.Category.STATUS, 0, 100, 20, []],
	&"rest": [&"psychic", MoveData.Category.STATUS, 0, 0, 5, []],
	&"sing": [&"normal", MoveData.Category.STATUS, 0, 55, 15, []],
	&"spore": [&"grass", MoveData.Category.STATUS, 0, 100, 15, []],
	&"confuse_ray": [&"ghost", MoveData.Category.STATUS, 0, 100, 10, []],
	&"glare": [&"normal", MoveData.Category.STATUS, 0, 100, 30, []],
	&"double_slap": [&"normal", MoveData.Category.PHYSICAL, 15, 85, 10, []],
	&"pound": [&"normal", MoveData.Category.PHYSICAL, 40, 100, 35, []],
	&"smog": [&"poison", MoveData.Category.SPECIAL, 30, 70, 20, []],
	&"sludge": [&"poison", MoveData.Category.SPECIAL, 65, 100, 20, []],
	&"acid": [&"poison", MoveData.Category.SPECIAL, 40, 100, 30, []],
	&"smokescreen": [&"normal", MoveData.Category.STATUS, 0, 100, 20, []],
	&"minimize": [&"normal", MoveData.Category.STATUS, 0, 0, 10, []],
	&"mega_punch": [&"normal", MoveData.Category.PHYSICAL, 80, 85, 20, []],
	&"sonic_boom": [&"normal", MoveData.Category.STATUS, 0, 90, 20, []],
	&"metronome": [&"normal", MoveData.Category.STATUS, 0, 0, 10, ["metronome"]],
	&"haze": [&"ice", MoveData.Category.STATUS, 0, 0, 30, []],
	&"light_screen": [&"psychic", MoveData.Category.STATUS, 0, 0, 30, []],
	&"double_edge": [&"normal", MoveData.Category.PHYSICAL, 120, 100, 15, []],
}
## Descriptions du dossier 15 §20 (n° 41 à 45) ; les autres sont dans l'annexe A.2.
const DOSSIER_DESCRIPTIONS := {
	&"leech_life": "41. Vampirisme", &"wrap": "42. Ligotage", &"disable": "43. Entrave",
	&"rest": "44. Repos", &"self_destruct": "45. Destruction",
}

var _data: PokemonData
var _plan: String
var _dossier: String


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_plan = FileAccess.get_file_as_string(PLAN)
	_dossier = FileAccess.get_file_as_string(DOSSIER_15)


# --- Espèces ----------------------------------------------------------------------------

func test_species_values() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))
	assert_eq(_data.get_species_ids().size(), 108,
		"38 + 12 + 9 (jalon 13) + 3 (jalon 14) + 2 (jalon 15) + 8 (jalon 17) + 6 (jalon 19) "
		+ "+ 11 (jalon 20 : Caninos et Goupix sont ceux du J17) + 13 (jalon 22) + 2 (Ptitard et Tentacool, copie du J21) + 4 (jalon 23)")
	for id: StringName in SPECIES:
		var v: Array = SPECIES[id]
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species == null:
			continue
		assert_eq(species.source, "res://data/pokemon/species/kanto_mt_moon.json", String(id))
		assert_eq([species.dex, species.name], [v[0], v[1]], String(id))
		var types: Array[StringName] = []
		types.assign(v[2])
		assert_eq(species.types, types, String(id))
		assert_eq(species.base_stats, {&"hp": v[3], &"atk": v[4], &"def": v[5], &"spa": v[6],
			&"spd": v[7], &"spe": v[8]} as Dictionary[StringName, int], String(id))
		assert_eq([species.base_exp, species.male_ratio, species.growth_rate, species.catch_rate],
			[v[9], v[10], v[11], v[12]], String(id))


func test_evolutions() -> void:
	var by_level := {&"ekans": [&"arbok", 22], &"zubat": [&"golbat", 22],
		&"paras": [&"parasect", 24]}
	for id: StringName in by_level:
		var rule: EvolutionRule = _data.get_species(id).evolutions[0]
		assert_eq([rule.method, rule.into, rule.level],
			[EvolutionRule.Method.LEVEL, by_level[id][0], by_level[id][1]], String(id))
	for pair: Array in [[&"clefairy", &"clefable"], [&"jigglypuff", &"wigglytuff"],
			[&"nidorina", &"nidoqueen"], [&"nidorino", &"nidoking"]]:
		var rule: EvolutionRule = _data.get_species(pair[0]).evolutions[0]
		assert_eq([rule.method, rule.into, rule.item],
			[EvolutionRule.Method.ITEM, pair[1], &"moon_stone"], String(pair[0]))
	for id: StringName in [&"arbok", &"golbat", &"parasect", &"clefable", &"wigglytuff",
			&"voltorb", &"koffing"]:
		assert_eq(_data.get_species(id).evolutions.size(), 0, "%s : pas d'évolution" % id)


func test_learnsets_are_red_blue() -> void:
	# Dossier 15 §16.2 : niveaux de Rouge/Bleu.
	var expected := {
		&"zubat": [[1, &"leech_life"], [10, &"supersonic"], [15, &"bite"],
			[21, &"confuse_ray"], [28, &"wing_attack"], [36, &"haze"]],
		&"paras": [[1, &"scratch"], [13, &"stun_spore"], [20, &"leech_life"], [27, &"spore"],
			[34, &"slash"], [41, &"growth"]],
		&"jigglypuff": [[1, &"sing"], [9, &"pound"], [14, &"disable"], [19, &"defense_curl"],
			[24, &"double_slap"], [29, &"rest"], [34, &"body_slam"], [39, &"double_edge"]],
		&"clefairy": [[1, &"pound"], [1, &"growl"], [13, &"sing"], [18, &"double_slap"],
			[24, &"minimize"], [31, &"metronome"], [39, &"defense_curl"], [48, &"light_screen"]],
		&"ekans": [[1, &"wrap"], [1, &"leer"], [10, &"poison_sting"], [17, &"bite"],
			[24, &"glare"], [31, &"screech"], [38, &"acid"]],
	}
	for id: StringName in expected:
		assert_eq(_data.get_species(id).learnset, expected[id], String(id))
	assert_eq(_data.get_species(&"arbok").learnset[5], [27, &"glare"])
	# Le chercheur (N12 depuis le T26) : Charge, Grincement et Purédpois seulement (§16.2).
	assert_eq(_data.get_species(&"voltorb").moves_at(12), [&"tackle", &"screech"]
		as Array[StringName])
	assert_eq(_data.get_species(&"koffing").moves_at(12), [&"tackle", &"smog"]
		as Array[StringName])


# --- Capacités --------------------------------------------------------------------------

func test_moves_values_and_pending_effects() -> void:
	for id: StringName in MOVES:
		var row: Array = MOVES[id]
		var move := _data.get_move(id)
		assert_not_null(move, String(id))
		if move == null:
			continue
		assert_eq(move.source, "res://data/pokemon/moves/mt_moon.json", String(id))
		assert_eq([move.type, move.category, move.power, move.accuracy, move.pp],
			row.slice(0, 5), String(id))
		assert_eq(move.pending_effects, PackedStringArray(row[5]), String(id))
		assert_false(move.draft, String(id))


func test_moves_reuse_the_j11_effect_kinds() -> void:
	var status := {&"sing": &"sleep", &"spore": &"sleep", &"glare": &"paralysis",
		&"smog": &"poison", &"sludge": &"poison"}
	var chance := {&"sing": 100, &"spore": 100, &"glare": 100, &"smog": 40, &"sludge": 30}
	for id: StringName in status:
		var effect: MoveEffect = _data.get_move(id).effects[0]
		assert_eq([effect.kind, effect.status, effect.chance],
			[MoveEffect.Kind.STATUS, status[id], chance[id]], String(id))
	assert_eq(_data.get_move(&"confuse_ray").effects[0].kind, MoveEffect.Kind.CONFUSION)
	var slap: MoveEffect = _data.get_move(&"double_slap").effects[0]
	assert_eq([slap.kind, slap.min_hits, slap.max_hits], [MoveEffect.Kind.HITS, 2, 5])
	var acid: MoveEffect = _data.get_move(&"acid").effects[0]
	assert_eq([acid.stat, acid.stages, acid.target, acid.chance],
		[&"spd", -1, MoveEffect.Target.FOE, 10])
	var smoke: MoveEffect = _data.get_move(&"smokescreen").effects[0]
	assert_eq([smoke.stat, smoke.stages, smoke.target], [&"acc", -1, MoveEffect.Target.FOE])
	var mini: MoveEffect = _data.get_move(&"minimize").effects[0]
	assert_eq([mini.stat, mini.stages, mini.target], [&"eva", 1, MoveEffect.Target.SELF])
	for id: StringName in [&"metronome", &"pound", &"mega_punch"]:
		assert_eq(_data.get_move(id).effects.size(), 0, "%s : rien de codé" % id)
	# Passe systèmes 2 : Buée Noire et Mur Lumière (tests/unit/test_battle_lot_s2g.gd).
	assert_eq(_data.get_move(&"haze").effects[0].kind, MoveEffect.Kind.HAZE)
	assert_eq(_data.get_move(&"light_screen").effects[0].screen, &"light_screen")
	# Damoclès : contrecoup joué depuis le jalon 19 (tests/unit/test_moves_j19_effects.gd).
	var recoil := _data.get_move(&"double_edge").effect_of(MoveEffect.Kind.RECOIL_DAMAGE)
	assert_not_null(recoil, "Damoclès : contrecoup")
	# Activées au T13 (genres du J12) : un seul effet chacune, plus rien en attente.
	var kinds := {&"leech_life": MoveEffect.Kind.DRAIN, &"wrap": MoveEffect.Kind.TRAP,
		&"bind": MoveEffect.Kind.TRAP, &"fire_spin": MoveEffect.Kind.TRAP,
		&"disable": MoveEffect.Kind.DISABLE, &"rest": MoveEffect.Kind.REST,
		&"self_destruct": MoveEffect.Kind.SELF_KO, &"explosion": MoveEffect.Kind.SELF_KO,
		&"sonic_boom": MoveEffect.Kind.FIXED_DAMAGE}
	for id: StringName in kinds:
		var move := _data.get_move(id)
		assert_eq(move.effects.size(), 1, String(id))
		assert_eq(move.effects[0].kind, kinds[id], String(id))
		assert_eq(move.pending_effects.size(), 0, String(id))


func test_move_texts_are_the_validated_ones() -> void:
	assert_false(_plan.is_empty(), "plan lisible")
	assert_false(_dossier.is_empty(), "dossier lisible")
	for id: StringName in MOVES:
		var move := _data.get_move(id)
		if DOSSIER_DESCRIPTIONS.has(id):
			assert_true(_dossier.contains("%s : « %s »" % [DOSSIER_DESCRIPTIONS[id],
				move.description]), "%s : description (§20)" % id)
		elif id in [&"double_edge", &"haze", &"light_screen"]:
			# Jalon 19 : la mention « Sans effet » de l'annexe A.2 est retirée, le reste est le même.
			assert_true(_plan.contains("%s « %s Sans effet dans le moteur actuel. »"
				% [move.name, move.description]), "%s : description (annexe A.2)" % id)
		else:
			assert_true(_plan.contains("%s « %s »" % [move.name, move.description]),
				"%s : nom et description (annexe A.2)" % id)
	assert_true(_dossier.contains("45. Destruction : « %s »" % _data.get_move(
		&"self_destruct").description), "Destruction : description remplacée (n° 45)")
	# Reportés : la mention, seulement là où l'effet manque pour de bon au J12.
	for id: StringName in [&"metronome"]:
		assert_true(_data.get_move(id).description.ends_with(
			" Sans effet dans le moteur actuel."), String(id))
	for id: StringName in [&"leech_life", &"wrap", &"disable", &"rest", &"sonic_boom",
			&"double_edge", &"haze", &"light_screen"]:
		assert_false(_data.get_move(id).description.contains("Sans effet"), String(id))


func test_every_species_learns_only_known_moves() -> void:
	for id: StringName in SPECIES:
		for move_id: StringName in _data.get_species(id).learnset_moves():
			assert_true(_data.has_move(move_id), "%s : %s" % [id, move_id])


# --- Objets -----------------------------------------------------------------------------

func test_items() -> void:
	var items := ItemLibrary.new()
	assert_true(items.load_dir(), "\n".join(items.get_errors()))
	assert_true(items.check_moves(_data))
	# [nom, pluriel, féminin, catégorie, prix, description]
	var expected := {
		&"escape_rope": ["Corde Sortie", "Cordes Sortie", true, ItemData.Category.FIELD, 550,
			"Ramène à l'entrée de la grotte."],
		&"moon_stone": ["Pierre Lune", "Pierres Lune", true, ItemData.Category.FIELD, 0,
			"Une pierre étrange. Fait évoluer certains Pokémon."],
		&"dome_fossil": ["Fossile Dôme", "Fossiles Dôme", false, ItemData.Category.KEY, 0,
			"Fossile d'un Pokémon ancien à la carapace en dôme."],
		&"helix_fossil": ["Fossile Nautile", "Fossiles Nautile", false, ItemData.Category.KEY, 0,
			"Fossile d'un Pokémon ancien à la coquille en spirale."],
		# Jalon 20 (T11) : prix RB, achetable une fois au grand magasin de Céladopole.
		&"tm01": ["CT01 — Ultimapoing", "CT01 — Ultimapoing", true, ItemData.Category.TM, 3000,
			"Un coup de poing d'une force incroyable."],
	}
	for id: StringName in expected:
		var item := items.get_item(id)
		assert_not_null(item, String(id))
		if item == null:
			continue
		assert_eq([item.name, item.plural, item.feminine, item.category, item.price,
			item.description], expected[id], String(id))
		assert_eq(item.source, "res://data/items/mt_moon.json", String(id))
		if id != &"tm01":
			assert_true(_dossier.contains("— description : « %s »" % item.description),
				"%s : description (§20)" % id)
	var tm := items.get_item(&"tm01")
	assert_eq([tm.tm_number, tm.teaches], [1, &"mega_punch"])
	assert_eq(items.get_tm(1), &"tm01")
	assert_false(items.get_item(&"moon_stone").is_sellable(), "Pierre Lune jamais vendue")
	assert_eq(items.get_item(&"escape_rope").contexts(), [ItemData.CONTEXT_FIELD]
		as Array[StringName], "hors combat")


# --- Pokédex ----------------------------------------------------------------------------

func test_pokedex_entries_are_the_validated_lot() -> void:
	var dex := PokedexLibrary.new()
	assert_true(dex.load_file(), "\n".join(dex.get_errors()))
	assert_true(dex.check_references(_data), "\n".join(dex.get_errors()))
	var official := {
		&"jigglypuff": [0.5, 5.5], &"wigglytuff": [1.0, 12.0], &"ekans": [2.0, 6.9],
		&"arbok": [3.5, 65.0], &"zubat": [0.8, 7.5], &"golbat": [1.6, 55.0],
		&"paras": [0.3, 5.4], &"parasect": [1.0, 29.5], &"clefairy": [0.6, 7.5],
		&"clefable": [1.3, 40.0], &"voltorb": [0.5, 10.4], &"koffing": [0.6, 1.0],
	}
	var note_ids: Array[StringName] = []
	for id: StringName in official:
		var info := dex.get_species(id)
		assert_not_null(info, String(id))
		if info == null:
			continue
		assert_almost_eq(info.height, float(official[id][0]), 0.001, String(id))
		assert_almost_eq(info.weight, float(official[id][1]), 0.001, String(id))
		var row := "| %s | %s m / %s kg | « %s » |" % [_data.get_species(id).name,
			_fr(official[id][0]), _fr(official[id][1]), info.description]
		assert_true(_plan.contains(row), "%s : ligne de l'annexe A.1" % id)
		for note: PokedexNoteData in info.notes:
			assert_true(_plan.contains("« %s » | « %s » |" % [info.description, note.text]),
				"%s : note" % note.id)
			assert_eq(note.seen, 1, String(note.id))
			note_ids.append(note.id)
	assert_eq(note_ids, [&"jigglypuff_balloon", &"ekans_sunbath", &"zubat_ceiling",
		&"paras_dig", &"clefairy_shards", &"voltorb_machines", &"koffing_air"]
		as Array[StringName], "7 notes des formes de base")


func _fr(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")


# --- Dresseurs --------------------------------------------------------------------------

func test_trainers() -> void:
	var trainers := TrainerLibrary.new(_data)
	assert_true(trainers.load_dir(), "\n".join(trainers.get_errors()))
	# [nom, IA, ₽, équipe] (dossier 15 §3.2, §8.3, §9 ; Nolan : défaut du 2026-10-11).
	var expected := {
		&"route_3_hugo": ["Gamin Hugo", BattleAI.RANDOM, 150,
			[[&"rattata", 10], [&"ekans", 10]]],
		&"route_3_lea": ["Fillette Léa", BattleAI.RANDOM, 135,
			[[&"pidgey", 9], [&"nidoran_f", 9]]],
		&"route_3_sacha": ["Scout Sacha", BattleAI.RANDOM, 120,
			[[&"caterpie", 10], [&"weedle", 10], [&"metapod", 10]]],
		&"route_3_enzo": ["Gamin Enzo", BattleAI.RANDOM, 210, [[&"spearow", 14]]],
		&"route_3_ines": ["Fillette Inès", BattleAI.RANDOM, 210, [[&"jigglypuff", 14]]],
		&"route_3_nolan": ["Scout Nolan", BattleAI.RANDOM, 108,
			[[&"weedle", 9], [&"kakuna", 9], [&"caterpie", 9]]],
		&"mt_moon_rocket_1": ["Sbire Rocket", BattleAI.RANDOM, 330,
			[[&"rattata", 11], [&"zubat", 11]]],
		&"mt_moon_rocket_2": ["Sbire Rocket", BattleAI.RANDOM, 360,
			[[&"ekans", 12], [&"sandshrew", 12]]],
		# T26 (équilibrage, valeurs [D]) : Rattatac 15 → 13 (390 ₽), Gaspard 13 → 12 (300 ₽).
		&"mt_moon_rocket_3": ["Sbire Rocket", BattleAI.SMART, 390,
			[[&"zubat", 13], [&"ekans", 13], [&"raticate", 13]]],
		&"mt_moon_researcher": ["Chercheur Gaspard", BattleAI.SMART, 300,
			[[&"voltorb", 12], [&"koffing", 12]]],
	}
	for id: StringName in expected:
		var trainer := trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		var team: Array = []
		for slot: TrainerSlot in trainer.team:
			team.append([slot.species, slot.level])
			assert_eq(slot.moves.size(), 0, "%s : capacités apprises au niveau" % id)
		assert_eq([trainer.name, trainer.ai, trainer.prize_money, team], expected[id], String(id))
		assert_eq([trainer.can_lose, trainer.heal_after, trainer.gives_exp], [false, false, true],
			String(id))
		assert_false(trainer.has_card(), String(id))


# --- Rencontres -------------------------------------------------------------------------

func test_encounter_tables_follow_the_dossier() -> void:
	var lib := EncounterLibrary.new(_data)
	assert_true(lib.load_dir(), "\n".join(lib.get_errors()))
	# Dossier 15 §3.3 et §6 : [espèce, min, max, poids].
	var expected := {
		[&"route_3", &"grass"]: [[&"spearow", 8, 10, 35], [&"rattata", 8, 9, 25],
			[&"sandshrew", 8, 10, 15], [&"ekans", 8, 10, 15], [&"jigglypuff", 7, 9, 10]],
		[&"mt_moon_1f", &"rubble"]: [[&"zubat", 8, 10, 55], [&"geodude", 8, 10, 30],
			[&"paras", 8, 10, 13], [&"clefairy", 9, 9, 2]],
		[&"mt_moon_b1f", &"rubble"]: [[&"zubat", 9, 11, 50], [&"geodude", 9, 11, 30],
			[&"paras", 10, 11, 16], [&"clefairy", 10, 10, 4]],
		[&"mt_moon_b2f", &"rubble"]: [[&"zubat", 10, 12, 45], [&"geodude", 10, 12, 30],
			[&"paras", 10, 12, 19], [&"clefairy", 10, 12, 6]],
	}
	for key: Array in expected:
		var table := lib.get_table(key[0], key[1])
		assert_not_null(table, str(key))
		if table == null:
			continue
		var slots: Array = []
		for slot: EncounterSlot in table.slots:
			slots.append([slot.species, slot.min_level, slot.max_level, slot.weight])
			assert_lt(slot.max_level if slot.species == &"geodude" else 0, 21,
				"aucun Racaillou sauvage ≥ Nv. 21")
		assert_eq(slots, expected[key], str(key))
		assert_eq([table.rate, table.ramp_from, table.ramp_max], [25, 15, 20], str(key))
	# Les gravats ne sont pas des herbes : aucune table « grass » dans la grotte.
	for map_id: StringName in [&"mt_moon_1f", &"mt_moon_b1f", &"mt_moon_b2f"]:
		assert_false(lib.has_table(map_id, &"grass"), String(map_id))


# --- CT et sprites ----------------------------------------------------------------------

func test_tm_compatibilities_cover_the_new_species() -> void:
	assert_eq(_data.tm_move(1), &"mega_punch")
	for id: StringName in [&"clefairy", &"clefable", &"jigglypuff", &"wigglytuff"]:
		assert_true(_data.can_learn_tm(id, 1), "%s : CT01" % id)
	for id: StringName in [&"zubat", &"ekans", &"paras", &"voltorb", &"koffing"]:
		assert_false(_data.can_learn_tm(id, 1), "%s : pas de CT01" % id)
		assert_true(_data.can_learn_tm(id, 34), "%s : CT34" % id)


func test_every_new_species_has_battle_sprites() -> void:
	var ids: Array[StringName] = []
	ids.assign(SPECIES.keys())
	ids.append(&"raticate")
	for id: StringName in ids:
		for back: bool in [false, true]:
			var path := BattleStage.sprite_path(id, back)
			assert_true(ResourceLoader.exists(path), path)
