extends GutTest
## Données du jalon 20 (T7 ; docs/tech/jalon-20.md §2.10) : 13 espèces (dossier 23 §15.1), dont
## Caninos et Goupix, ceux du J17 (`kanto_j17.json`, ancienneté : le J20 leur ajoute seulement la
## Pierre Feu), évolutions par pierre, 9 capacités (Méga-Sangsue et capacités d'apprentissage ;
## Bélier et Hurlement sont ceux du J17, `moves/j17.json`), objets
## (Super Ball, pierres, boissons, CT13, CT21, Clé Ascenseur, Scope Sylphe), objets du moteur du
## T11 (Rappel, Poupée Poké, objets X, prix de la CT01), boutiques du grand magasin, rencontres
## des Routes 7 et 8, Dresseurs (Route 8, Arène, Casino, repaire, Erika, Giovanni) avec les
## remplacements d'espèces du plan, entrées du Pokédex. Fichier séparé des tests partagés que
## d'autres jalons modifient en parallèle (modèle : test_vermilion_data.gd).
##
## Textes : l'annexe A du plan est **en brouillon** (Q-1). Les données n'ont pas de clé « draft »
## (les tests partagés n'en admettent aucune : `test_no_draft_in_data`, Pokédex, capacités) ;
## [constant ANNEX_TEXTS] relie chaque numéro de l'annexe à son emplacement dans les données, et
## [method test_annex_a_texts_are_copied_word_for_word] compare la donnée à l'annexe : quand
## Kevin aura corrigé un numéro, ce test montre la donnée à remplacer.

const PLAN := "res://docs/tech/jalon-20.md"
## Espèces créées par le J17 (plus ancien, ses données gagnent) : le J20 n'en garde pas de copie.
const FROM_J17: Array[StringName] = [&"growlithe", &"vulpix"]

## [dex, nom, types, PV, Att, Déf, Att. Spé., Déf. Spé., Vit., base_exp, capture, mâles,
## croissance] : valeurs actuelles de PokeAPI (convention des espèces existantes).
const SPECIES := {
	&"growlithe": [58, "Caninos", [&"fire"], 55, 70, 45, 70, 50, 60, 70, 190, 0.75,
		ExpCurve.Rate.SLOW],
	&"arcanine": [59, "Arcanin", [&"fire"], 90, 110, 80, 100, 80, 95, 194, 75, 0.75,
		ExpCurve.Rate.SLOW],
	&"vulpix": [37, "Goupix", [&"fire"], 38, 41, 40, 50, 65, 65, 60, 190, 0.25,
		ExpCurve.Rate.MEDIUM_FAST],
	&"ninetales": [38, "Feunard", [&"fire"], 73, 76, 75, 81, 100, 100, 177, 75, 0.25,
		ExpCurve.Rate.MEDIUM_FAST],
	&"eevee": [133, "Évoli", [&"normal"], 55, 55, 50, 45, 65, 55, 65, 45, 0.875,
		ExpCurve.Rate.MEDIUM_FAST],
	&"vaporeon": [134, "Aquali", [&"water"], 130, 65, 60, 110, 95, 65, 184, 45, 0.875,
		ExpCurve.Rate.MEDIUM_FAST],
	&"jolteon": [135, "Voltali", [&"electric"], 65, 65, 60, 110, 95, 130, 184, 45, 0.875,
		ExpCurve.Rate.MEDIUM_FAST],
	&"flareon": [136, "Pyroli", [&"fire"], 65, 130, 60, 95, 110, 65, 184, 45, 0.875,
		ExpCurve.Rate.MEDIUM_FAST],
	&"victreebel": [71, "Empiflor", [&"grass", &"poison"], 80, 105, 65, 100, 70, 70, 221, 45,
		0.5, ExpCurve.Rate.MEDIUM_SLOW],
	&"tangela": [114, "Saquedeneu", [&"grass"], 65, 55, 115, 100, 40, 60, 87, 45, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"vileplume": [45, "Rafflesia", [&"grass", &"poison"], 75, 80, 85, 110, 90, 50, 221, 45,
		0.5, ExpCurve.Rate.MEDIUM_SLOW],
	&"rhyhorn": [111, "Rhinocorne", [&"ground", &"rock"], 80, 85, 95, 30, 30, 25, 69, 120, 0.5,
		ExpCurve.Rate.SLOW],
	&"kangaskhan": [115, "Kangourex", [&"normal"], 105, 95, 80, 40, 80, 90, 172, 45, 0.0,
		ExpCurve.Rate.MEDIUM_FAST],
}
## Apprentissages Rouge/Bleu (PokeAPI, groupe red-blue ; plan §2.10.1).
const LEARNSETS := {
	&"growlithe": [[1, "bite"], [1, "roar"], [18, "ember"], [23, "leer"], [30, "take_down"],
		[39, "agility"], [50, "flamethrower"]],
	&"arcanine": [[1, "roar"], [1, "ember"], [1, "leer"], [1, "take_down"]],
	&"vulpix": [[1, "ember"], [1, "tail_whip"], [16, "quick_attack"], [21, "roar"],
		[28, "confuse_ray"], [35, "flamethrower"], [42, "fire_spin"]],
	&"ninetales": [[1, "ember"], [1, "tail_whip"], [1, "quick_attack"], [1, "roar"]],
	&"eevee": [[1, "tackle"], [1, "sand_attack"], [27, "quick_attack"], [31, "tail_whip"],
		[37, "bite"], [45, "take_down"]],
	&"vaporeon": [[1, "tackle"], [1, "sand_attack"], [1, "quick_attack"], [1, "water_gun"],
		[27, "quick_attack"], [31, "water_gun"], [37, "tail_whip"], [40, "bite"],
		[42, "acid_armor"], [44, "haze"], [48, "mist"], [54, "hydro_pump"]],
	&"jolteon": [[1, "tackle"], [1, "sand_attack"], [1, "quick_attack"], [1, "thunder_shock"],
		[27, "quick_attack"], [31, "thunder_shock"], [37, "tail_whip"], [40, "thunder_wave"],
		[42, "double_kick"], [44, "agility"], [48, "pin_missile"], [54, "thunder"]],
	&"flareon": [[1, "tackle"], [1, "sand_attack"], [1, "quick_attack"], [1, "ember"],
		[27, "quick_attack"], [31, "ember"], [37, "tail_whip"], [40, "bite"], [42, "leer"],
		[44, "fire_spin"], [48, "rage"], [54, "flamethrower"]],
	&"victreebel": [[1, "sleep_powder"], [1, "stun_spore"], [1, "acid"], [1, "razor_leaf"],
		[13, "wrap"], [15, "poison_powder"], [18, "sleep_powder"]],
	&"tangela": [[1, "constrict"], [1, "bind"], [29, "absorb"], [32, "poison_powder"],
		[36, "stun_spore"], [39, "sleep_powder"], [45, "slam"], [49, "growth"]],
	&"vileplume": [[1, "stun_spore"], [1, "sleep_powder"], [1, "acid"], [1, "petal_dance"],
		[15, "poison_powder"], [17, "stun_spore"], [19, "sleep_powder"]],
	&"rhyhorn": [[1, "horn_attack"], [30, "stomp"], [35, "tail_whip"], [40, "fury_attack"],
		[45, "horn_drill"], [50, "leer"], [55, "take_down"]],
	&"kangaskhan": [[1, "comet_punch"], [1, "rage"], [26, "bite"], [31, "tail_whip"],
		[36, "mega_punch"], [41, "leer"], [46, "dizzy_punch"]],
}
## Pierre → { espèce : évolution } (plan §2.10.1 ; Pikachu → Raichu existait déjà).
const STONES := {
	&"fire_stone": {&"growlithe": &"arcanine", &"vulpix": &"ninetales", &"eevee": &"flareon"},
	&"water_stone": {&"eevee": &"vaporeon", &"staryu": &"starmie"},
	&"thunder_stone": {&"eevee": &"jolteon", &"pikachu": &"raichu"},
	&"leaf_stone": {&"gloom": &"vileplume", &"weepinbell": &"victreebel"},
}
## [nom, type, catégorie, puissance, précision, PP, effets en attente] (valeurs actuelles).
const MOVES := {
	&"mega_drain": ["Méga-Sangsue", &"grass", MoveData.Category.SPECIAL, 40, 100, 15, []],
	&"constrict": ["Constriction", &"normal", MoveData.Category.PHYSICAL, 10, 100, 35, []],
	&"comet_punch": ["Poing Comète", &"normal", MoveData.Category.PHYSICAL, 18, 85, 15, []],
	&"stomp": ["Écrasement", &"normal", MoveData.Category.PHYSICAL, 65, 100, 20, []],
	&"dizzy_punch": ["Uppercut", &"normal", MoveData.Category.PHYSICAL, 70, 100, 10, []],
	&"acid_armor": ["Acidarmure", &"poison", MoveData.Category.STATUS, 0, 0, 20, []],
	&"mist": ["Brume", &"ice", MoveData.Category.STATUS, 0, 0, 30, ["mist"]],
	# Bélier et Hurlement : ceux du J17, joués par le moteur depuis le J19 (effets de capacités).
	&"take_down": ["Bélier", &"normal", MoveData.Category.PHYSICAL, 90, 85, 20, []],
	&"roar": ["Hurlement", &"normal", MoveData.Category.STATUS, 0, 0, 20, []],
}
## Dresseurs (plan §2.10.6) : [nom, IA, équipe [espèce, niveau]…, récompense, base RB].
const TRAINERS := {
	&"route_8_nerd_anatole": ["Intello Anatole", &"random",
		[[&"voltorb", 20], [&"koffing", 20], [&"voltorb", 20], [&"voltorb", 20]], 500, 25],
	&"route_8_gambler_rene": ["Joueur René", &"random",
		[[&"horsea", 22], [&"horsea", 22], [&"goldeen", 22]], 1540, 70],
	&"route_8_nerd_firmin": ["Intello Firmin", &"random",
		[[&"koffing", 22], [&"arbok", 22], [&"koffing", 22]], 550, 25],
	&"route_8_lass_iris": ["Fillette Iris", &"random",
		[[&"nidoran_f", 23], [&"nidorina", 23]], 345, 15],
	&"route_8_lass_margot": ["Fillette Margot", &"random",
		[[&"meowth", 24], [&"meowth", 24], [&"meowth", 24]], 360, 15],
	&"route_8_gambler_fernand": ["Joueur Fernand", &"random",
		[[&"growlithe", 24], [&"vulpix", 24]], 1680, 70],
	&"route_8_lass_nina": ["Fillette Nina", &"random",
		[[&"clefairy", 22], [&"clefairy", 22]], 330, 15],
	&"celadon_gym_lass_lila": ["Fillette Lila", &"random",
		[[&"bellsprout", 23], [&"weepinbell", 23]], 345, 15],
	&"celadon_gym_lass_capucine": ["Fillette Capucine", &"random",
		[[&"oddish", 23], [&"gloom", 23]], 345, 15],
	&"celadon_gym_beauty_violette": ["Beauté Violette", &"random",
		[[&"bellsprout", 24], [&"bellsprout", 24]], 1680, 70],
	&"celadon_gym_jr_trainer_apolline": ["Jeune Dresseuse Apolline", &"random",
		[[&"bulbasaur", 24], [&"ivysaur", 24]], 480, 20],
	&"celadon_gym_cooltrainer_camelia": ["Topdresseuse Camélia", &"smart",
		[[&"weepinbell", 24], [&"gloom", 24], [&"ivysaur", 24]], 840, 35],
	&"celadon_gym_erika": ["Erika", &"smart",
		[[&"tangela", 24], [&"victreebel", 27], [&"vileplume", 29]], 2871, 99],
	&"celadon_game_corner_rocket": ["Sbire Rocket", &"random",
		[[&"raticate", 20], [&"zubat", 20]], 600, 30],
	&"rocket_hideout_b1f_1": ["Sbire Rocket", &"random",
		[[&"kadabra", 21], [&"machop", 21]], 630, 30],
	&"rocket_hideout_b1f_2": ["Sbire Rocket", &"random",
		[[&"raticate", 21], [&"raticate", 21]], 630, 30],
	&"rocket_hideout_b1f_3": ["Sbire Rocket", &"random",
		[[&"ekans", 20], [&"koffing", 20], [&"koffing", 20]], 600, 30],
	&"rocket_hideout_b2f_1": ["Sbire Rocket", &"random",
		[[&"zubat", 17], [&"koffing", 17], [&"ekans", 17], [&"zubat", 17], [&"raticate", 17]],
		510, 30],
	&"rocket_hideout_b3f_1": ["Sbire Rocket", &"random",
		[[&"rattata", 20], [&"raticate", 20], [&"kadabra", 20]], 600, 30],
	&"rocket_hideout_b3f_2": ["Sbire Rocket", &"random",
		[[&"machop", 21], [&"machop", 21]], 630, 30],
	&"rocket_hideout_b4f_key": ["Sbire Rocket", &"random",
		[[&"koffing", 21], [&"zubat", 21]], 630, 30],
	&"rocket_hideout_b4f_guard_1": ["Sbire Rocket", &"random",
		[[&"sandshrew", 23], [&"ekans", 23], [&"sandslash", 23]], 690, 30],
	&"rocket_hideout_b4f_guard_2": ["Sbire Rocket", &"random",
		[[&"ekans", 23], [&"sandshrew", 23], [&"arbok", 23]], 690, 30],
	&"giovanni_hideout": ["Giovanni", &"smart",
		[[&"onix", 23], [&"rhyhorn", 22], [&"kangaskhan", 25]], 2475, 99],
}
## Numéro de l'annexe A → [genre de donnée, identifiant, quel texte « … » de la ligne (−1 =
## le dernier)]. Brouillon tant que Kevin n'a pas validé l'annexe (Q-1).
const ANNEX_TEXTS := {
	126: ["trainer_card", &"celadon_gym_erika", -1],
	154: ["trainer_card", &"giovanni_hideout", -1],
	173: ["item", &"great_ball", -1], 174: ["item", &"revive", -1],
	175: ["item", &"poke_doll", -1], 176: ["item", &"fire_stone", -1],
	177: ["item", &"water_stone", -1], 178: ["item", &"thunder_stone", -1],
	179: ["item", &"leaf_stone", -1], 180: ["item", &"fresh_water", -1],
	181: ["item", &"soda_pop", -1], 182: ["item", &"lemonade", -1],
	183: ["item", &"x_attack", -1], 184: ["item", &"x_defend", -1],
	185: ["item", &"x_speed", -1], 186: ["item", &"x_special", -1],
	187: ["item", &"x_accuracy", -1], 188: ["item", &"dire_hit", -1],
	189: ["item", &"lift_key", -1],
	# 191 (Caninos) et 193 (Goupix) : fiches du J17 gardées (fusion de main, 2026-10-19).
	192: ["dex", &"arcanine", -1],
	194: ["dex", &"ninetales", -1], 195: ["dex", &"eevee", -1], 196: ["dex", &"vaporeon", -1],
	197: ["dex", &"jolteon", -1], 198: ["dex", &"flareon", -1],
	199: ["dex", &"victreebel", -1], 200: ["dex", &"tangela", -1],
	201: ["dex", &"vileplume", -1], 202: ["dex", &"rhyhorn", -1],
	203: ["dex", &"kangaskhan", -1],
	204: ["dex", &"cubone", -1],
	205: ["move", &"mega_drain", -1], 206: ["move", &"constrict", -1],
	207: ["move", &"comet_punch", -1], 208: ["move", &"stomp", -1],
	209: ["move", &"dizzy_punch", -1], 210: ["move", &"acid_armor", -1],
	212: ["move", &"mist", -1],
}

var _data: PokemonData
var _items: ItemLibrary
var _trainers: TrainerLibrary
var _plan: String


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()
	_trainers = TrainerLibrary.new(_data)
	_trainers.load_dir()
	_plan = FileAccess.get_file_as_string(PLAN)


# --- Espèces ----------------------------------------------------------------------------

func test_species_values_are_the_current_ones() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))
	for id: StringName in SPECIES:
		var v: Array = SPECIES[id]
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species == null:
			continue
		var file := "kanto_j17" if FROM_J17.has(id) else "kanto_celadon"
		assert_eq(species.source, "res://data/pokemon/species/%s.json" % file, String(id))
		assert_eq([species.dex, species.name], [v[0], v[1]], String(id))
		var types: Array[StringName] = []
		types.assign(v[2])
		assert_eq(species.types, types, String(id))
		assert_eq(species.base_stats, {&"hp": v[3], &"atk": v[4], &"def": v[5], &"spa": v[6],
			&"spd": v[7], &"spe": v[8]} as Dictionary[StringName, int], String(id))
		assert_eq([species.base_exp, species.catch_rate, species.growth_rate],
			[v[9], v[10], v[12]], String(id))
		assert_almost_eq(species.male_ratio, float(v[11]), 0.0001, String(id))


func test_learnsets_are_red_blue() -> void:
	for id: StringName in LEARNSETS:
		var expected: Array = []
		for pair: Array in LEARNSETS[id]:
			expected.append([pair[0], StringName(pair[1])])
		assert_eq(_data.get_species(id).learnset, expected, String(id))


func test_stone_evolutions() -> void:
	for stone: StringName in STONES:
		assert_not_null(_items.get_item(stone), String(stone))
		assert_true(StoneUse.is_stone(_items.get_item(stone)), String(stone))
		for species: StringName in STONES[stone]:
			var mon := _mon(species)
			assert_eq(StoneUse.check(mon, stone, _data), StoneUse.Check.COMPATIBLE,
				"%s + %s" % [species, stone])
			assert_eq(StoneUse.target(mon, stone, _data), STONES[stone][species],
				"%s + %s" % [species, stone])
	# Pierre Plante sur Évoli, Pierre Feu sur Stari : incompatibles.
	assert_eq(StoneUse.check(_mon(&"eevee"), &"leaf_stone", _data),
		StoneUse.Check.INCOMPATIBLE)
	assert_eq(StoneUse.check(_mon(&"staryu"), &"fire_stone", _data),
		StoneUse.Check.INCOMPATIBLE)
	# Les évolutions finales n'évoluent plus ; Mystherbe, Chétiflor : par niveau seulement.
	for id: StringName in [&"arcanine", &"ninetales", &"vaporeon", &"jolteon", &"flareon",
			&"victreebel", &"vileplume", &"tangela", &"kangaskhan"]:
		assert_eq(_data.get_species(id).evolutions.size(), 0, String(id))
	# Jalon 28 (T3) : Rhinocorne évolue en Rhinoféros au N42 (Rouge/Bleu).
	assert_eq(_data.get_species(&"rhyhorn").evolutions.size(), 1, "rhyhorn → rhydon")
	for id: StringName in [&"oddish", &"bellsprout"]:
		assert_eq(StoneUse.check(_mon(id), &"leaf_stone", _data), StoneUse.Check.INCOMPATIBLE)


func test_every_new_species_has_its_placeholder_battle_art() -> void:
	for id: StringName in SPECIES:
		for back: bool in [false, true]:
			assert_true(ResourceLoader.exists(BattleArt.placeholder_path(id, back)), String(id))


# --- Capacités et CT ------------------------------------------------------------------------

func test_moves_values() -> void:
	for id: StringName in MOVES:
		var row: Array = MOVES[id]
		var move := _data.get_move(id)
		assert_not_null(move, String(id))
		if move == null:
			continue
		assert_eq([move.name, move.type, move.category, move.power, move.accuracy, move.pp],
			row.slice(0, 6), String(id))
		assert_eq(move.pending_effects, PackedStringArray(row[6]), String(id))
		if not row[6].is_empty():
			assert_string_contains(move.description, "Sans effet dans le moteur actuel")


func test_moves_effects_are_played() -> void:
	var drain := _data.get_move(&"mega_drain").effect_of(MoveEffect.Kind.DRAIN)
	assert_not_null(drain)
	if drain != null:
		assert_almost_eq(drain.fraction, 0.5, 0.0001)
	var slow := _data.get_move(&"constrict").effect_of(MoveEffect.Kind.STAT_STAGE)
	assert_eq([slow.stat, slow.stages, slow.target, slow.chance],
		[&"spe", -1, MoveEffect.Target.FOE, 10])
	var hits := _data.get_move(&"comet_punch").effect_of(MoveEffect.Kind.HITS)
	assert_eq([hits.min_hits, hits.max_hits], [2, 5])
	assert_eq(_data.get_move(&"stomp").effect_of(MoveEffect.Kind.FLINCH).chance, 30)
	assert_eq(_data.get_move(&"dizzy_punch").effect_of(MoveEffect.Kind.CONFUSION).chance, 20)
	var armor := _data.get_move(&"acid_armor").effect_of(MoveEffect.Kind.STAT_STAGE)
	assert_eq([armor.stat, armor.stages, armor.target], [&"def", 2, MoveEffect.Target.SELF])


func test_tms_of_the_milestone() -> void:
	var tm13 := _items.get_item(&"tm13")
	var tm21 := _items.get_item(&"tm21")
	assert_eq([tm13.tm_number, tm13.teaches], [13, &"ice_beam"])
	assert_eq([tm21.tm_number, tm21.teaches], [21, &"mega_drain"])
	assert_eq(tm13.description, _data.get_move(&"ice_beam").description, "texte n° 214")
	assert_eq(tm21.description, _data.get_move(&"mega_drain").description, "texte n° 205")
	assert_true(_items.check_moves(_data), "\n".join(_items.get_errors()))
	assert_eq(_data.tm_move(21), &"mega_drain")
	# Compatibilités régénérées (tools/gen_tm_compatibility.py, jamais à la main).
	for id: StringName in [&"vileplume", &"victreebel", &"tangela", &"bulbasaur", &"oddish"]:
		assert_true(_data.can_learn_tm(id, 21), "CT21 : %s" % id)
	for id: StringName in [&"eevee", &"growlithe", &"charmander", &"rhyhorn"]:
		assert_false(_data.can_learn_tm(id, 21), "CT21 : %s" % id)
	assert_true(_data.can_learn_tm(&"vaporeon", 13), "CT13 : Aquali")
	assert_true(_data.can_learn_tm(&"kangaskhan", 13), "CT13 : Kangourex")
	assert_false(_data.can_learn_tm(&"flareon", 13), "CT13 : Pyroli")
	for id: StringName in SPECIES:
		var count := 0
		for number: int in range(1, 51):
			count += 1 if _data.can_learn_tm(id, number) else 0
		assert_gt(count, 0, "%s : présente dans la table générée" % id)


# --- Objets -----------------------------------------------------------------------------

func test_new_items() -> void:
	assert_eq(_items.get_errors().size(), 0, "\n".join(_items.get_errors()))
	var ball := _items.get_item(&"great_ball")
	assert_eq([ball.category, ball.catch_bonus, ball.price], [ItemData.Category.BALL, 1.5, 600])
	for stone: StringName in STONES:
		var item := _items.get_item(stone)
		assert_eq([item.category, item.field_use, item.price],
			[ItemData.Category.FIELD, ItemData.FIELD_USE_EVOLUTION_STONE, 2100], String(stone))
	for row: Array in [[&"fresh_water", 50, 200], [&"soda_pop", 60, 300],
			[&"lemonade", 80, 350]]:
		var drink := _items.get_item(row[0])
		assert_eq([drink.category, drink.heal_amount, drink.price, drink.cures.size()],
			[ItemData.Category.HEAL, row[1], row[2], 0], String(row[0]))
	var key := _items.get_item(&"lift_key")
	var scope := _items.get_item(&"silph_scope")
	assert_eq([key.category, key.obtained, key.price], [ItemData.Category.KEY, false, 0])
	assert_eq([scope.category, scope.obtained, scope.price], [ItemData.Category.KEY, true, 0])
	# T-55, deuxième ligne (lot validé) : pas de brouillon.
	assert_eq(scope.description, "Il permet de voir ce que l'œil seul ne voit pas.")
	assert_false(scope.draft)


func test_engine_items_of_t11() -> void:
	# Objets du T11 (§2.9.3, §2.9.4), chargés depuis que le moteur lit leurs clés.
	var expected := {&"revive": [ItemData.Category.HEAL, 1500],
		&"poke_doll": [ItemData.Category.BATTLE, 1000],
		&"x_attack": [ItemData.Category.BATTLE, 500], &"x_defend": [ItemData.Category.BATTLE, 550],
		&"x_speed": [ItemData.Category.BATTLE, 350], &"x_special": [ItemData.Category.BATTLE, 350],
		&"x_accuracy": [ItemData.Category.BATTLE, 950],
		&"dire_hit": [ItemData.Category.BATTLE, 650]}
	for id: StringName in expected:
		var item := _items.get_item(id)
		assert_not_null(item, String(id))
		if item != null:
			assert_eq([item.category, item.price], expected[id], String(id))
	assert_almost_eq(_items.get_item(&"revive").revive, 0.5, 0.0001)
	assert_eq(_items.get_item(&"poke_doll").battle_use, ItemData.BATTLE_USE_ESCAPE)
	assert_eq(_items.get_item(&"dire_hit").battle_use, ItemData.BATTLE_USE_CRIT_UP)
	for row: Array in [[&"x_attack", &"atk"], [&"x_defend", &"def"], [&"x_speed", &"spe"],
			[&"x_special", &"spa"], [&"x_accuracy", &"acc"]]:
		var item := _items.get_item(row[0])
		assert_eq([item.battle_use, item.battle_stat, item.battle_stages],
			[ItemData.BATTLE_USE_STAT_STAGE, row[1], 1], String(row[0]))
	# CT01 : prix RB (achetable une fois au 2e, jamais revendue).
	assert_eq(_items.get_item(&"tm01").price, 3000)
	assert_false(_items.get_item(&"tm01").is_sellable())


# --- Boutiques ----------------------------------------------------------------------------

func test_department_store_shops() -> void:
	var shops := ShopLibrary.new()
	assert_true(shops.load_dir(), "\n".join(shops.get_errors()))
	assert_true(shops.check_references(_items), "\n".join(shops.get_errors()))
	var loaded := {
		&"celadon_dept_4f_stones": [&"fire_stone", &"water_stone", &"thunder_stone",
			&"leaf_stone"],
		&"celadon_dept_roof_water": [&"fresh_water"],
		&"celadon_dept_roof_soda": [&"soda_pop"],
		&"celadon_dept_roof_lemonade": [&"lemonade"],
	}
	for id: StringName in loaded:
		var shop := shops.get_shop(id)
		assert_not_null(shop, String(id))
		if shop != null:
			var ids: Array[StringName] = []
			ids.assign(loaded[id])
			assert_eq(shop.item_ids(), ids, String(id))
	# Boutiques du T11 : 2e (deux vendeurs), 4e, 5e.
	var engine := {
		&"celadon_dept_2f": [&"great_ball", &"super_potion", &"revive", &"antidote",
			&"burn_heal", &"ice_heal", &"awakening", &"paralyze_heal"],
		# Q-2, option A (Kevin, 2026-10-16) : la CT01 seule.
		&"celadon_dept_2f_tm": [&"tm01"],
		&"celadon_dept_4f": [&"poke_doll"],
		&"celadon_dept_5f": [&"x_attack", &"x_defend", &"x_speed", &"x_special", &"x_accuracy",
			&"dire_hit"],
	}
	for id: StringName in engine:
		var shop := shops.get_shop(id)
		assert_not_null(shop, String(id))
		if shop != null:
			var ids: Array[StringName] = []
			ids.assign(engine[id])
			assert_eq(shop.item_ids(), ids, String(id))


# --- Rencontres ---------------------------------------------------------------------------

func test_routes_7_and_8_encounters() -> void:
	var lib := EncounterLibrary.new(_data)
	assert_true(lib.load_dir(), "\n".join(lib.get_errors()))
	var tables := {
		&"route_8": [[&"pidgey", 18, 20, 30], [&"mankey", 18, 20, 15], [&"meowth", 18, 20, 15],
			[&"ekans", 17, 19, 10], [&"sandshrew", 17, 19, 10], [&"growlithe", 15, 18, 10],
			[&"vulpix", 15, 18, 10]],
		&"route_7": [[&"pidgey", 19, 22, 30], [&"oddish", 19, 22, 15],
			[&"bellsprout", 19, 22, 15], [&"mankey", 17, 20, 10], [&"meowth", 17, 20, 10],
			[&"growlithe", 18, 20, 10], [&"vulpix", 18, 20, 10]],
	}
	for map_id: StringName in tables:
		var table := lib.get_table(map_id, &"grass")
		assert_not_null(table, String(map_id))
		if table == null:
			continue
		assert_eq([table.rate, table.ramp_from, table.ramp_max], [25, 15, 20], String(map_id))
		var slots: Array = []
		for slot: EncounterSlot in table.slots:
			slots.append([slot.species, slot.min_level, slot.max_level, slot.weight])
		assert_eq(slots, tables[map_id], String(map_id))
		assert_eq(table.total_weight(), 100, String(map_id))


# --- Dresseurs ----------------------------------------------------------------------------

func test_trainers() -> void:
	assert_eq(_trainers.get_errors().size(), 0, "\n".join(_trainers.get_errors()))
	for id: StringName in TRAINERS:
		var row: Array = TRAINERS[id]
		var trainer := _trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq([trainer.name, trainer.ai, trainer.can_lose, trainer.heal_after,
			trainer.gives_exp], [row[0], row[1], false, false, true], String(id))
		var team: Array = []
		for slot: TrainerSlot in trainer.team:
			team.append([slot.species, slot.level])
		assert_eq(team, row[2], String(id))
		assert_eq(trainer.prize_for(0), row[3], String(id))
		var last_level: int = (row[2] as Array).back()[1]
		assert_eq(row[3], int(row[4]) * last_level, "%s : base × dernier niveau" % id)
	assert_eq(_trainers.get_trainer(&"celadon_gym_erika").source,
		"res://data/trainers/celadon_gym.json")
	assert_eq(_trainers.get_trainer(&"giovanni_hideout").source,
		"res://data/trainers/rocket_hideout.json")


func test_leaders_use_the_champion_model() -> void:
	for id: StringName in [&"celadon_gym_erika", &"giovanni_hideout"]:
		var trainer := _trainers.get_trainer(id)
		assert_eq([trainer.start_message, trainer.end_message, trainer.allow_bag,
			trainer.can_switch, trainer.has_card()], [false, true, true, true, true], String(id))
	assert_eq(_trainers.get_trainer(&"celadon_gym_erika").card_name, "ERIKA")
	assert_eq(_trainers.get_trainer(&"giovanni_hideout").card_name, "GIOVANNI")
	# Rafflesia d'Erika : Méga-Sangsue (Rouge/Bleu), à la place de Danse Fleur (sans effet).
	var team := _trainers.build_team(&"celadon_gym_erika", &"bulbasaur", GameRng.new(3))
	assert_true(_move_ids(team.get_at(2)).has(&"mega_drain"))


func test_no_trainer_uses_a_move_without_engine_effect() -> void:
	# Règle du J12 : jamais de capacité en attente dans une équipe imposée.
	for id: StringName in TRAINERS:
		var team := _trainers.build_team(id, &"bulbasaur", GameRng.new(3))
		for i: int in team.size():
			for move_id: StringName in _move_ids(team.get_at(i)):
				assert_eq(_data.get_move(move_id).pending_effects.size(), 0,
					"%s : %s" % [id, move_id])


func test_species_replacements_of_the_plan() -> void:
	# Plan §2.10.6 : Magnéti, Soporifik, Ptitard, Têtarte, Tadmorv et Grotadmorv absents.
	for id: StringName in TRAINERS:
		for pair: Array in TRAINERS[id][2]:
			assert_true(_data.has_species(pair[0]), "%s : %s" % [id, pair[0]])
			assert_false(pair[0] in [&"magnemite", &"drowzee", &"poliwag", &"poliwhirl",
				&"grimer", &"muk"], "%s : %s remplacé" % [id, pair[0]])


func test_trainer_first_names_are_new() -> void:
	var seen := {}
	for id: StringName in _trainers.get_ids():
		var trainer := _trainers.get_trainer(id)
		if TRAINERS.has(id) or trainer.name.begins_with("Sbire"):
			continue
		seen[trainer.name.get_slice(" ", trainer.name.get_slice_count(" ") - 1)] = id
	for id: StringName in TRAINERS:
		var name: String = TRAINERS[id][0]
		if name.begins_with("Sbire") or name in ["Erika", "Giovanni"]:
			continue
		var first := name.get_slice(" ", name.get_slice_count(" ") - 1)
		assert_false(seen.has(first), "%s : prénom déjà pris par %s" % [name, seen.get(first)])


# --- Pokédex ------------------------------------------------------------------------------

func test_pokedex_entries() -> void:
	var dex := PokedexLibrary.new()
	assert_true(dex.load_file(), "\n".join(dex.get_errors()))
	assert_true(dex.check_references(_data), "\n".join(dex.get_errors()))
	var sizes := {&"growlithe": [0.7, 19.0], &"arcanine": [1.9, 155.0], &"vulpix": [0.6, 9.9],
		&"ninetales": [1.1, 19.9], &"eevee": [0.3, 6.5], &"vaporeon": [1.0, 29.0],
		&"jolteon": [0.8, 24.5], &"flareon": [0.9, 25.0], &"victreebel": [1.7, 15.5],
		&"tangela": [1.0, 35.0], &"vileplume": [1.2, 18.6], &"rhyhorn": [1.0, 115.0],
		&"kangaskhan": [2.2, 80.0],
		# Osselait : espèce du J19, fiche du J20 (passation J19 §9.3, annexe A n° 204).
		&"cubone": [0.4, 6.5]}
	for id: StringName in sizes:
		var info := dex.get_species(id)
		assert_not_null(info, String(id))
		if info == null:
			continue
		assert_almost_eq(info.height, float(sizes[id][0]), 0.001, String(id))
		assert_almost_eq(info.weight, float(sizes[id][1]), 0.001, String(id))


# --- Textes de l'annexe A (brouillon) -------------------------------------------------------

func test_annex_a_texts_are_copied_word_for_word() -> void:
	var dex := PokedexLibrary.new()
	dex.load_file()
	for number: int in ANNEX_TEXTS:
		var row: Array = ANNEX_TEXTS[number]
		var quotes := _annex(number)
		assert_gt(quotes.size(), 0, "n° %d dans l'annexe A" % number)
		if quotes.is_empty():
			continue
		var expected: String = quotes[int(row[2])] if int(row[2]) >= 0 else quotes.back()
		var id: StringName = row[1]
		var actual := ""
		match row[0]:
			"item":
				actual = _items.get_item(id).description
			"dex":
				actual = dex.get_species(id).description
			"move":
				actual = _data.get_move(id).description
			"trainer_card":
				actual = _trainers.get_trainer(id).card_title
		assert_eq(actual, expected, "texte n° %d (%s)" % [number, id])


# --- Outils -------------------------------------------------------------------------------

func _mon(species: StringName, level: int = 30) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(7))


func _move_ids(pokemon: Pokemon) -> Array[StringName]:
	var ids: Array[StringName] = []
	for slot: MoveSlot in pokemon.moves:
		ids.append(slot.move_id)
	return ids


## Textes « … » du numéro [param number] de l'annexe A du plan (lignes de suite comprises).
func _annex(number: int) -> Array[String]:
	var start := _plan.find("## Annexe A")
	var lines := _plan.substr(start).split("\n")
	var text := ""
	var inside := false
	for line: String in lines:
		if line.begins_with("%d. " % number):
			inside = true
			text = line
			continue
		if inside:
			if line.begins_with("    ") or line.begins_with("     "):
				text += " " + line.strip_edges()
			else:
				break
	var found: Array[String] = []
	var regex := RegEx.create_from_string("« (.+?) »")
	for m: RegExMatch in regex.search_all(text):
		found.append(m.get_string(1))
	return found
