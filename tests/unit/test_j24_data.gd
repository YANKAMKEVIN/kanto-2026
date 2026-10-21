extends GutTest
## Données du jalon 24 (T4 ; docs/tech/jalon-24.md, dossier 27 §9.4, §10.3, §11, §14) : espèces,
## capacités, objets, Boutique de Cramois'Île, Dresseurs des Routes 19 à 21 et leurs répliques
## (mot pour mot du lot §15.4 validé par Kevin le 2026-10-16), rencontres (eau, herbe de la
## Route 21, sol des Îles Écume). Fichier séparé des tests partagés que d'autres jalons modifient.

const DOSSIER := "res://docs/design/dossier-27-iles-ecume.md"
const PENDING_DIR := "res://data/j24_pending/"

## [dex, nom, types, PV, Att, Déf, Att. Spé., Déf. Spé., Vit., base_exp, capture, male_ratio,
## croissance] : statistiques et rendement d'XP de PokeAPI (convention des espèces existantes),
## taux de capture et croissance de Rouge/Bleu.
const SPECIES := {
	&"psyduck": [54, "Psykokwak", [&"water"], 50, 52, 48, 65, 50, 55, 64, 190, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"golduck": [55, "Akwakwak", [&"water"], 80, 82, 78, 95, 80, 85, 175, 75, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"poliwhirl": [61, "Têtarte", [&"water"], 65, 65, 65, 50, 50, 90, 135, 120, 0.5,
		ExpCurve.Rate.MEDIUM_SLOW],
	&"poliwrath": [62, "Tartard", [&"water", &"fighting"], 90, 95, 95, 70, 90, 70, 230, 45,
		0.5, ExpCurve.Rate.MEDIUM_SLOW],
	&"tentacruel": [73, "Tentacruel", [&"water", &"poison"], 80, 70, 65, 80, 120, 100, 180, 60,
		0.5, ExpCurve.Rate.SLOW],
	&"slowpoke": [79, "Ramoloss", [&"water", &"psychic"], 90, 65, 65, 40, 40, 15, 63, 190, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"slowbro": [80, "Flagadoss", [&"water", &"psychic"], 95, 75, 110, 100, 80, 30, 172, 75,
		0.5, ExpCurve.Rate.MEDIUM_FAST],
	&"seel": [86, "Otaria", [&"water"], 65, 45, 55, 45, 70, 45, 65, 190, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"dewgong": [87, "Lamantine", [&"water", &"ice"], 90, 70, 80, 70, 95, 70, 166, 75, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"cloyster": [91, "Crustabri", [&"water", &"ice"], 50, 95, 180, 85, 45, 70, 184, 60, 0.5,
		ExpCurve.Rate.SLOW],
	&"krabby": [98, "Krabby", [&"water"], 30, 105, 90, 25, 25, 50, 65, 225, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"kingler": [99, "Krabboss", [&"water"], 55, 130, 115, 50, 50, 75, 166, 60, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"seadra": [117, "Hypocéan", [&"water"], 55, 65, 95, 95, 45, 85, 154, 75, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"seaking": [119, "Poissoroy", [&"water"], 80, 92, 65, 65, 80, 68, 158, 60, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"magikarp": [129, "Magicarpe", [&"water"], 20, 10, 55, 15, 20, 80, 40, 255, 0.5,
		ExpCurve.Rate.SLOW],
	&"omanyte": [138, "Amonita", [&"rock", &"water"], 35, 40, 100, 90, 55, 35, 71, 45, 0.875,
		ExpCurve.Rate.MEDIUM_FAST],
	&"omastar": [139, "Amonistar", [&"rock", &"water"], 70, 60, 125, 115, 70, 55, 173, 45,
		0.875, ExpCurve.Rate.MEDIUM_FAST],
	&"kabuto": [140, "Kabuto", [&"rock", &"water"], 30, 80, 90, 55, 45, 55, 71, 45, 0.875,
		ExpCurve.Rate.MEDIUM_FAST],
	&"kabutops": [141, "Kabutops", [&"rock", &"water"], 60, 115, 105, 65, 70, 80, 173, 45,
		0.875, ExpCurve.Rate.MEDIUM_FAST],
	&"articuno": [144, "Artikodin", [&"ice", &"flying"], 90, 85, 100, 95, 125, 85, 261, 3, -1.0,
		ExpCurve.Rate.SLOW],
}
## Reprises à l'identique de branches plus anciennes (règle d'ancienneté, jalon-24.md §0.1) :
## espèce → [fichier de reprise, branche d'origine].
const SPECIES_REPRISES := {
	&"poliwag": "j21-t5-donnees", &"tentacool": "j21-t5-donnees",
}
const MOVE_REPRISES := {
	&"amnesia": "jalon-21", &"barrier": "j21-t5-donnees",
}
## Reprises retirées à la fusion de systemes-2 (2026-10-21) : leur jalon est dans `main`.
const MERGED_REPRISES := {
	&"tangela": "res://data/pokemon/species/kanto_celadon.json",
	&"gyarados": "res://data/pokemon/species/kanto_tower.json",
	&"dragon_rage": "res://data/pokemon/moves/tower.json",
	&"hyper_beam": "res://data/pokemon/moves/tower.json",
	&"constrict": "res://data/pokemon/moves/celadon.json",
	&"stomp": "res://data/pokemon/moves/celadon.json",
	&"mist": "res://data/pokemon/moves/celadon.json",
}
## Base d'argent de la classe de Rouge/Bleu (pic_pointers_money.asm) : Nageur 5, Canon (les
## Nageuses du §9.4) 70, Jeune Dresseuse 20, Ornithologue 25, Pêcheur 35, Boule (Nageur Dylan) 25.
## [route, nom, base RB, niveau, équipe].
const TRAINERS := {
	&"route_19_cooltrainer_hugo": [19, "Topdresseur Hugo", 5, 30, [&"tentacool", &"shellder"]],
	&"route_19_cooltrainer_malo": [19, "Topdresseur Malo", 5, 29,
		[&"goldeen", &"horsea", &"staryu"]],
	&"route_19_swimmer_yann": [19, "Nageur Yann", 5, 30, [&"poliwag", &"poliwhirl"]],
	&"route_19_swimmer_erwan": [19, "Nageur Erwan", 5, 27,
		[&"horsea", &"tentacool", &"tentacool", &"goldeen"]],
	&"route_19_swimmer_loic": [19, "Nageur Loïc", 5, 29, [&"goldeen", &"shellder", &"seaking"]],
	&"route_19_swimmer_tanguy": [19, "Nageur Tanguy", 5, 30, [&"horsea", &"horsea"]],
	&"route_19_swimmer_maelle": [19, "Nageuse Maëlle", 70, 27,
		[&"poliwag", &"goldeen", &"seaking", &"goldeen", &"poliwag"]],
	&"route_19_swimmer_anais": [19, "Nageuse Anaïs", 70, 30, [&"goldeen", &"seaking"]],
	&"route_19_swimmer_gwen": [19, "Nageur Gwen", 5, 27,
		[&"tentacool", &"tentacool", &"staryu", &"horsea", &"tentacruel"]],
	&"route_19_swimmer_lena": [19, "Nageuse Léna", 70, 29, [&"staryu", &"staryu", &"staryu"]],
	&"route_20_swimmer_ronan": [20, "Nageur Ronan", 5, 31, [&"shellder", &"cloyster"]],
	&"route_20_swimmer_solene": [20, "Nageuse Solène", 70, 30,
		[&"seadra", &"horsea", &"seadra"]],
	&"route_20_swimmer_iris": [20, "Nageuse Iris", 70, 35, [&"seaking"]],
	&"route_20_swimmer_lou": [20, "Nageuse Lou", 20, 30, [&"tentacool", &"horsea", &"seel"]],
	&"route_20_swimmer_mathis": [20, "Nageur Mathis", 5, 35, [&"staryu"]],
	&"route_20_swimmer_kilian": [20, "Nageur Kilian", 5, 28,
		[&"horsea", &"horsea", &"seadra", &"horsea"]],
	&"route_20_bird_keeper_bastien": [20, "Ornithologue Bastien", 25, 30,
		[&"fearow", &"fearow", &"pidgeotto"]],
	&"route_20_swimmer_clara": [20, "Nageuse Clara", 70, 30,
		[&"shellder", &"shellder", &"cloyster"]],
	&"route_20_swimmer_nina": [20, "Nageuse Nina", 20, 31, [&"goldeen", &"seaking"]],
	&"route_20_swimmer_elsa": [20, "Nageuse Elsa", 70, 31, [&"poliwag", &"seaking"]],
	&"route_21_fisher_gilles": [21, "Pêcheur Gilles", 35, 28,
		[&"seaking", &"goldeen", &"seaking", &"seaking"]],
	&"route_21_fisher_marcel": [21, "Pêcheur Marcel", 35, 27,
		[&"magikarp", &"magikarp", &"magikarp", &"magikarp", &"magikarp", &"magikarp"]],
	&"route_21_swimmer_thibault": [21, "Nageur Thibault", 5, 33, [&"seadra", &"tentacruel"]],
	&"route_21_swimmer_dylan": [21, "Nageur Dylan", 25, 31,
		[&"tentacool", &"tentacool", &"tentacruel"]],
	&"route_21_swimmer_simon": [21, "Nageur Simon", 5, 37, [&"starmie"]],
	&"route_21_swimmer_arthur": [21, "Nageur Arthur", 5, 33, [&"staryu", &"wartortle"]],
	&"route_21_swimmer_noe": [21, "Nageur Noé", 5, 32, [&"poliwhirl", &"tentacool", &"seadra"]],
	&"route_21_fisher_rene": [21, "Pêcheur René", 35, 31, [&"shellder", &"cloyster"]],
	&"route_21_fisher_yves": [21, "Pêcheur Yves", 35, 33, [&"seaking", &"goldeen"]],
}
## Capacités dont l'effet manque au moteur (pending_effects) et que l'on rencontre au J24 : chez
## les sauvages, elles restent (Guillotine de Krabby et Krabboss, Soin de Stari, Cyclone de
## Roucoups, comme aux jalons précédents) ; chez les Dresseurs, remplacement explicite par les
## capacités de Rouge/Bleu au niveau sans elles (règle de Major Bob, dossier 27 §14.2).
const PENDING_MOVES: Array[StringName] = [&"guillotine", &"mirror_move", &"recover", &"whirlwind"]
## Tables des Îles Écume : union de Rouge et de Bleu ; poids = moyenne des deux tables sur 256
## (créneaux de Rouge/Bleu 51, 51, 39, 25, 25, 25, 13, 13, 11, 3 ; les demi-unités arrondies
## alternativement vers le haut et vers le bas) ; niveaux de Rouge/Bleu.
## carte → [taux, { espèce: [poids, niveau min, niveau max] }].
const SEAFOAM := {
	&"seafoam_1f": [15, {
		&"seel": [51, 30, 30], &"slowpoke": [32, 28, 30], &"psyduck": [32, 28, 30],
		&"shellder": [25, 28, 30], &"horsea": [25, 28, 30], &"zubat": [25, 21, 21],
		&"staryu": [25, 28, 30], &"krabby": [25, 28, 30], &"golbat": [13, 29, 29],
		&"golduck": [2, 38, 38], &"slowbro": [1, 38, 38],
	}],
	&"seafoam_b1f": [10, {
		&"staryu": [45, 30, 32], &"shellder": [45, 30, 32], &"horsea": [38, 30, 32],
		&"seel": [38, 28, 30], &"krabby": [38, 30, 32], &"slowpoke": [19, 28, 30],
		&"psyduck": [19, 28, 30], &"dewgong": [11, 38, 38], &"seadra": [2, 37, 37],
		&"kingler": [1, 37, 37],
	}],
	&"seafoam_b2f": [10, {
		&"seel": [90, 30, 32], &"slowpoke": [38, 30, 32], &"psyduck": [38, 30, 32],
		&"horsea": [19, 28, 30], &"staryu": [19, 28, 30], &"shellder": [19, 28, 30],
		&"krabby": [19, 28, 30], &"golbat": [11, 30, 30], &"slowbro": [2, 37, 37],
		&"golduck": [1, 37, 37],
	}],
	&"seafoam_b3f": [10, {
		&"seel": [76, 31, 33], &"slowpoke": [45, 31, 33], &"psyduck": [45, 31, 33],
		&"horsea": [19, 29, 31], &"shellder": [19, 29, 31], &"krabby": [19, 29, 31],
		&"staryu": [19, 29, 31], &"seadra": [6, 39, 39], &"kingler": [5, 39, 39],
		&"dewgong": [3, 37, 37],
	}],
	&"seafoam_b4f": [10, {
		&"horsea": [45, 31, 33], &"krabby": [45, 31, 33], &"shellder": [38, 31, 33],
		&"seel": [38, 29, 31], &"staryu": [38, 31, 33], &"slowpoke": [19, 29, 31],
		&"psyduck": [19, 29, 31], &"slowbro": [6, 39, 39], &"golduck": [5, 39, 39],
		&"golbat": [3, 32, 32],
	}],
}

var _data: PokemonData
var _items: ItemLibrary
var _dossier: String


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()
	_dossier = FileAccess.get_file_as_string(DOSSIER)


# --- Espèces ----------------------------------------------------------------------------

func test_new_species_values() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))
	for id: StringName in SPECIES:
		var v: Array = SPECIES[id]
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species == null:
			continue
		assert_eq([species.dex, species.name], [v[0], v[1]], String(id))
		assert_eq(species.types, Array(v[2], TYPE_STRING_NAME, &"", null), String(id))
		assert_eq(species.base_stats, {&"hp": v[3], &"atk": v[4], &"def": v[5], &"spa": v[6],
			&"spd": v[7], &"spe": v[8]} as Dictionary[StringName, int], String(id))
		assert_eq([species.base_exp, species.catch_rate, species.male_ratio,
			species.growth_rate], [v[9], v[10], v[11], v[12]], String(id))
		assert_eq(species.source, "res://data/pokemon/species/kanto_j24.json", String(id))


func test_reprises_come_from_their_own_file() -> void:
	for id: StringName in SPECIES_REPRISES:
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species != null:
			assert_eq(species.source, "res://data/pokemon/species/kanto_j24_reprises.json")
	for id: StringName in MOVE_REPRISES:
		var move := _data.get_move(id)
		assert_not_null(move, String(id))
		if move != null:
			assert_eq(move.source, "res://data/pokemon/moves/j24_reprises.json")
	for id: StringName in MERGED_REPRISES:
		var source: String = _data.get_species(id).source if _data.has_species(id) \
			else _data.get_move(id).source
		assert_eq(source, MERGED_REPRISES[id], String(id))
	assert_eq(_items.get_item(&"great_ball").source, "res://data/items/items_j20.json")


func test_learnsets_are_red_blue() -> void:
	assert_eq(_data.get_species(&"tentacruel").learnset, [[1, &"acid"], [1, &"supersonic"],
		[1, &"wrap"], [7, &"supersonic"], [13, &"wrap"], [18, &"poison_sting"],
		[22, &"water_gun"], [27, &"constrict"], [35, &"barrier"], [43, &"screech"],
		[50, &"hydro_pump"]])
	assert_eq(_data.get_species(&"krabby").learnset, [[1, &"bubble"], [1, &"leer"],
		[20, &"vise_grip"], [25, &"guillotine"], [30, &"stomp"], [35, &"crabhammer"],
		[40, &"harden"]])
	assert_eq(_data.get_species(&"magikarp").learnset, [[1, &"splash"], [15, &"tackle"]])
	assert_eq(_data.get_species(&"slowbro").moves_at(37), [&"headbutt", &"growl",
		&"water_gun", &"withdraw"] as Array[StringName])


func test_articuno_level_50_peck_and_ice_beam() -> void:
	var articuno := _data.get_species(&"articuno")
	assert_eq(articuno.moves_at(50), [&"peck", &"ice_beam"] as Array[StringName])
	assert_eq(articuno.catch_rate, 3)
	assert_eq(articuno.evolutions.size(), 0)


func test_fossils_at_level_30() -> void:
	# Résurrection (dossier 27 §10.5) : Kabuto et Amonita N30, évolution au N40 (Rouge/Bleu).
	assert_eq(_data.get_species(&"kabuto").moves_at(30), [&"scratch", &"harden"]
		as Array[StringName])
	assert_eq(_data.get_species(&"omanyte").moves_at(30), [&"water_gun", &"withdraw"]
		as Array[StringName])


func test_every_new_species_has_battle_sprites_and_a_pokedex_entry() -> void:
	var dex := PokedexLibrary.new()
	assert_true(dex.load_file(), "\n".join(dex.get_errors()))
	var all: Array[StringName] = []
	all.assign(SPECIES.keys())
	all.append_array(SPECIES_REPRISES.keys())
	for id: StringName in all:
		for back: bool in [false, true]:
			assert_true(ResourceLoader.exists(BattleArt.placeholder_path(id, back)), String(id))
		assert_true(dex.has_species(id), String(id))


# --- Capacités --------------------------------------------------------------------------

func test_new_moves_values() -> void:
	# Valeurs modernes (convention des capacités existantes) ; « [type, catégorie, puissance,
	# précision, PP, critique] ».
	var expected := {
		&"vise_grip": [&"normal", MoveData.Category.PHYSICAL, 55, 100, 30, 0],
		&"guillotine": [&"normal", MoveData.Category.STATUS, 0, 30, 5, 0],
		&"crabhammer": [&"water", MoveData.Category.PHYSICAL, 100, 90, 10, 1],
		&"spike_cannon": [&"normal", MoveData.Category.PHYSICAL, 20, 100, 15, 0],
		&"blizzard": [&"ice", MoveData.Category.SPECIAL, 110, 70, 5, 0],
		&"splash": [&"normal", MoveData.Category.STATUS, 0, 0, 40, 0],
	}
	for id: StringName in expected:
		var move := _data.get_move(id)
		assert_not_null(move, String(id))
		if move == null:
			continue
		assert_eq([move.type, move.category, move.power, move.accuracy, move.pp,
			move.crit_stage], expected[id], String(id))
		assert_eq(move.source, "res://data/pokemon/moves/j24.json", String(id))
	assert_eq(_data.get_move(&"guillotine").pending_effects, PackedStringArray(["ohko"]))
	var cannon := _data.get_move(&"spike_cannon").effect_of(MoveEffect.Kind.HITS)
	assert_eq([cannon.min_hits, cannon.max_hits], [2, 5])
	var blizzard := _data.get_move(&"blizzard").effect_of(MoveEffect.Kind.STATUS)
	assert_eq([blizzard.status, blizzard.chance], [&"freeze", 10])
	# Surf et Force viennent de la passe systèmes 2 (S2C, S2D) ; Métronome est codé (T13, test_metronome).
	assert_true(_data.has_move(&"surf"))
	assert_true(_data.has_move(&"strength"))
	assert_eq(_data.get_move(&"metronome").pending_effects, PackedStringArray(),
		"Métronome codé au T13")


func test_pending_effects_met_in_the_jalon_are_the_known_ones() -> void:
	# Toutes les capacités connues au niveau par les sauvages et les Dresseurs du J24 existent ;
	# celles dont l'effet manque sont celles de la liste (rapport du T4).
	var met: Array[StringName] = []
	var trainers := TrainerLibrary.new(_data)
	trainers.load_dir()
	for id: StringName in TRAINERS:
		for slot: TrainerSlot in trainers.get_trainer(id).team:
			var known: Array[StringName] = slot.moves
			if known.is_empty():
				known = _data.get_species(slot.species).moves_at(slot.level)
			for move_id: StringName in known:
				assert_true(_data.has_move(move_id), "%s : %s" % [id, move_id])
				var move := _data.get_move(move_id)
				assert_true(move == null or move.pending_effects.is_empty(),
					"%s : %s sans effet, à remplacer" % [id, move_id])
	var lib := EncounterLibrary.new(_data)
	lib.load_dir()
	var tables: Array[EncounterTable] = [lib.get_table(&"route_21", &"grass"),
		lib.get_table(&"route_19", &"water")]
	for map: StringName in SEAFOAM:
		tables.append(lib.get_table(map, &"floor"))
	for table: EncounterTable in tables:
		for slot: EncounterSlot in table.slots:
			for level: int in range(slot.min_level, slot.max_level + 1):
				for move_id: StringName in _data.get_species(slot.species).moves_at(level):
					if not _data.get_move(move_id).pending_effects.is_empty() \
							and not met.has(move_id):
						met.append(move_id)
	for move_id: StringName in met:
		assert_true(PENDING_MOVES.has(move_id), String(move_id))


# --- Dresseurs --------------------------------------------------------------------------

func test_routes_19_to_21_trainers() -> void:
	var trainers := TrainerLibrary.new(_data)
	assert_true(trainers.load_dir(), "\n".join(trainers.get_errors()))
	assert_eq(TRAINERS.size(), 29, "les 29 Dresseurs de Rouge/Bleu (P-13)")
	for id: StringName in TRAINERS:
		var row: Array = TRAINERS[id]
		var trainer := trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq(trainer.source, "res://data/trainers/route_%d.json" % row[0], String(id))
		assert_eq([trainer.name, trainer.ai, trainer.can_lose, trainer.heal_after,
			trainer.gives_exp], [row[1], &"random", false, false, true], String(id))
		var team: Array[StringName] = []
		for slot: TrainerSlot in trainer.team:
			team.append(slot.species)
			assert_eq(slot.level, row[3], String(id))
		assert_eq(team, Array(row[4], TYPE_STRING_NAME, &"", null), String(id))
		assert_eq(trainer.prize_for(0), int(row[2]) * int(row[3]),
			"%s : base de la classe × niveau du dernier" % id)
	for route: int in [19, 20, 21]:
		var count := 0
		for id: StringName in trainers.get_ids():
			if String(id).begins_with("route_%d_" % route):
				count += 1
		assert_eq(count, [10, 10, 9][route - 19], "Route %d" % route)


func test_explicit_replacements_follow_red_blue() -> void:
	var trainers := TrainerLibrary.new(_data)
	trainers.load_dir()
	var bastien := trainers.get_trainer(&"route_20_bird_keeper_bastien").team
	assert_eq(bastien[0].moves, [&"peck", &"growl", &"leer", &"fury_attack"]
		as Array[StringName], "Rapasdepic N30 sans Mimique")
	assert_eq(bastien[2].moves, [&"gust", &"sand_attack", &"quick_attack"]
		as Array[StringName], "Roucoups N30 sans Cyclone")
	assert_eq(trainers.get_trainer(&"route_19_swimmer_lena").team[0].moves,
		[&"tackle", &"water_gun", &"harden"] as Array[StringName], "Stari N29 sans Soin")
	assert_eq(trainers.get_trainer(&"route_21_swimmer_simon").team[0].moves.size(), 0,
		"Staross N37 : capacités au niveau")


func test_trainer_lines_are_the_validated_lot() -> void:
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), "\n".join(dialogues.get_errors()))
	for id: StringName in TRAINERS:
		var row: Array = TRAINERS[id]
		var quotes := _validated(row[1])
		assert_eq(quotes.size(), 3, "%s : avant, défaite, après" % row[1])
		var moments := ["before", "defeated", "after"]
		for i: int in moments.size():
			var dialogue_id := StringName("%s_%s" % [id, moments[i]])
			var dialogue := dialogues.get_dialogue(dialogue_id)
			assert_not_null(dialogue, String(dialogue_id))
			if dialogue == null or quotes.size() != 3:
				continue
			assert_eq(dialogue.source,
				"res://data/dialogues/route_%d_trainers.json" % row[0])
			assert_eq(dialogue.speaker, row[1], String(dialogue_id))
			assert_false(dialogue.draft, String(dialogue_id))
			assert_eq(dialogue.variants.size(), 1, String(dialogue_id))
			var texts: Array[String] = []
			for page: DialoguePage in dialogue.variants[0].pages:
				assert_lte(page.text.split("\n").size(), 2, "bulle de deux lignes au plus")
				for line: String in page.text.split("\n"):
					assert_lte(line.length(), 34, "%s : « %s »" % [dialogue_id, line])
				texts.append(page.text.replace("\n", " "))
			assert_eq(" ".join(texts), quotes[i], String(dialogue_id))


# --- Rencontres -------------------------------------------------------------------------

func test_water_and_floor_terrains_are_known() -> void:
	assert_true(EncounterTable.TERRAINS.has(&"water"), "eau surfable (J24, T8)")
	assert_true(EncounterTable.TERRAINS.has(&"floor"), "sol (J19), repris à l'identique")


func test_sea_tables_are_tentacool_only() -> void:
	# P-11 : Tentacool seul, taux 5 (Rouge/Bleu), niveaux resserrés N25–35 [D].
	var lib := EncounterLibrary.new(_data)
	assert_true(lib.load_dir(), "\n".join(lib.get_errors()))
	for map: StringName in [&"route_19", &"route_20", &"route_21", &"cinnabar_island"]:
		var table := lib.get_table(map, &"water")
		assert_not_null(table, String(map))
		if table == null:
			continue
		assert_eq(table.maps, [map] as Array[StringName])
		assert_eq(table.rate, 5, String(map))
		assert_false(table.has_ramp(), "%s : pas de rampe sur l'eau [D]" % map)
		assert_eq(table.slots.size(), 1)
		assert_eq([table.slots[0].species, table.slots[0].min_level,
			table.slots[0].max_level], [&"tentacool", 25, 35], String(map))
		assert_false(lib.has_table(map, &"grass") and map != &"route_21", String(map))


func test_route_21_meadow_is_red_blue() -> void:
	var lib := EncounterLibrary.new(_data)
	lib.load_dir()
	var table := lib.get_table(&"route_21", &"grass")
	assert_not_null(table)
	if table == null:
		return
	assert_eq(table.rate, 25)
	assert_eq([table.ramp_from, table.ramp_max], [15, 20], "rampe des autres herbes")
	assert_eq(table.total_weight(), 256)
	var expected := {
		&"rattata": [76, 21, 23], &"pidgey": [76, 21, 23], &"raticate": [39, 30, 30],
		&"pidgeotto": [38, 30, 32], &"tangela": [27, 28, 32],
	}
	assert_eq(table.slots.size(), expected.size())
	for slot: EncounterSlot in table.slots:
		assert_eq([slot.weight, slot.min_level, slot.max_level], expected.get(slot.species),
			String(slot.species))


func test_seafoam_floors_are_the_union_of_red_and_blue() -> void:
	var lib := EncounterLibrary.new(_data)
	lib.load_dir()
	for map: StringName in SEAFOAM:
		var row: Array = SEAFOAM[map]
		var table := lib.get_table(map, &"floor")
		assert_not_null(table, String(map))
		if table == null:
			continue
		assert_eq(table.rate, row[0], String(map))
		assert_false(table.has_ramp(), String(map))
		assert_eq(table.total_weight(), 256, String(map))
		assert_false(lib.has_table(map, &"water"), "%s : aucune rencontre en Surf (P-12)" % map)
		var expected: Dictionary = row[1]
		assert_eq(table.slots.size(), expected.size(), String(map))
		for slot: EncounterSlot in table.slots:
			assert_eq([slot.weight, slot.min_level, slot.max_level],
				expected.get(slot.species), "%s %s" % [map, slot.species])


# --- Objets et Boutique -----------------------------------------------------------------

func test_new_items() -> void:
	assert_eq(_items.get_errors().size(), 0, "\n".join(_items.get_errors()))
	var ultra := _items.get_item(&"ultra_ball")
	assert_eq([ultra.name, ultra.category, ultra.catch_bonus, ultra.price],
		["Hyper Ball", ItemData.Category.BALL, 2.0, 1200])
	var great := _items.get_item(&"great_ball")
	assert_eq([great.name, great.category, great.catch_bonus, great.price],
		["Super Ball", ItemData.Category.BALL, 1.5, 600])
	var hyper := _items.get_item(&"hyper_potion")
	assert_eq([hyper.name, hyper.category, hyper.heal_amount, hyper.price],
		["Hyper Potion", ItemData.Category.HEAL, 200, 1500])
	var full := _items.get_item(&"full_heal")
	assert_eq([full.name, full.category, full.heal_amount, full.price],
		["Total Soin", ItemData.Category.HEAL, 0, 600])
	assert_eq(full.cures, StatusRules.KNOWN, "les cinq statuts")
	var tm := _items.get_item(&"tm35")
	assert_eq([tm.name, tm.category, tm.tm_number, tm.teaches],
		["CT35 — Métronome", ItemData.Category.TM, 35, &"metronome"])
	assert_eq(_items.get_tm(35), &"tm35")
	assert_true(_items.has_item(&"nugget"), "la Pépite existe depuis le J13")


func test_items_without_engine_support_wait_outside_the_libraries() -> void:
	# Max Repousse et Max Élixir : data/j24_pending/, lu par aucune bibliothèque. Le Rappel
	# (clé « revive ») est lu depuis le T11 du J20 (items_j20.json).
	var pending: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(PENDING_DIR + "items.json"))
	assert_eq((pending["items"] as Dictionary).keys(), ["max_repel", "max_elixir"])
	for id: StringName in [&"max_repel", &"max_elixir"]:
		assert_false(_items.has_item(id), String(id))
	assert_eq(_items.get_item(&"revive").source, "res://data/items/items_j20.json")


func test_cinnabar_mart_stock() -> void:
	var shops := ShopLibrary.new()
	assert_true(shops.load_dir(), "\n".join(shops.get_errors()))
	assert_true(shops.check_references(_items), "\n".join(shops.get_errors()))
	var shop := shops.get_shop(&"cinnabar_mart")
	assert_not_null(shop)
	if shop == null:
		return
	# Ordre de Rouge/Bleu (marts.asm) sans Max Repousse, en attente (§10.3) ; le Rappel est lu
	# depuis le J20 (fusion de systemes-2, 2026-10-21).
	assert_eq(shop.item_ids(), [&"ultra_ball", &"great_ball", &"hyper_potion", &"escape_rope",
		&"full_heal", &"revive"] as Array[StringName])
	var pending: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(PENDING_DIR + "shops.json"))
	var full: Array = []
	for entry: Dictionary in pending["shops"]["cinnabar_mart"]["stock"]:
		full.append(entry["item"])
	assert_eq(full, ["ultra_ball", "great_ball", "hyper_potion", "max_repel", "escape_rope",
		"full_heal", "revive"], "inventaire complet de Rouge/Bleu")


# --- Outils -----------------------------------------------------------------------------

## Répliques « … » (avant, défaite, après) du Dresseur [param name] (dossier §15.4).
func _validated(name: String) -> Array[String]:
	var found: Array[String] = []
	var regex := RegEx.create_from_string("« (.+?) »")
	for line: String in _dossier.split("\n"):
		if line.begins_with("| %s |" % name):
			for m: RegExMatch in regex.search_all(line):
				found.append(m.get_string(1))
	return found
