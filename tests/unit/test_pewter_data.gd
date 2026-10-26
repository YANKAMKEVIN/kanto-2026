extends GutTest
## Données du jalon 10 (Argenta, T8 ; docs/tech/jalon-10.md §2.3, §2.5, §2.13, §2.14) : espèces,
## capacités, Pokédex, Dresseurs de l'Arène, Boutique, rencontres de la Route 2 nord, zones,
## départs de débogage. Textes recopiés mot pour mot du lot validé par Kevin le 2026-10-08
## (docs/design/textes/textes-brouillon-j10.md) et du dossier 12 (« Textes verrouillés »).
## Fichier séparé des tests partagés (test_pokemon_data, test_pokedex_library…) que d'autres
## chantiers modifient : seuls leurs listes exhaustives y ont été mises à jour.

const LOT := "res://docs/design/textes/textes-brouillon-j10.md"
const DOSSIER_12 := "res://docs/design/dossier-12-argenta.md"
const TOOL_STARTS := "res://tools/debug_start/"
const GameStateScript := preload("res://game/autoload/game_state.gd")

## PokeAPI, statistiques, taux et rendement d'XP actuels (convention des espèces existantes) :
## [dex, nom, types, PV, Att, Déf, Att. Spé., Déf. Spé., Vit., base_exp, male_ratio, croissance].
const ARGENTA_SPECIES := {
	&"sandshrew": [27, "Sabelette", [&"ground"], 50, 75, 85, 20, 30, 40, 60, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"sandslash": [28, "Sablaireau", [&"ground"], 75, 100, 110, 45, 55, 65, 158, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"geodude": [74, "Racaillou", [&"rock", &"ground"], 40, 80, 100, 30, 30, 20, 60, 0.5,
		ExpCurve.Rate.MEDIUM_SLOW],
	&"graveler": [75, "Gravalanch", [&"rock", &"ground"], 55, 95, 115, 45, 45, 35, 137, 0.5,
		ExpCurve.Rate.MEDIUM_SLOW],
	&"golem": [76, "Grolem", [&"rock", &"ground"], 80, 120, 130, 55, 65, 45, 223, 0.5,
		ExpCurve.Rate.MEDIUM_SLOW],
	&"onix": [95, "Onix", [&"rock", &"ground"], 35, 45, 160, 30, 45, 70, 77, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
}
## Capacités nouvelles du J10 : [type, catégorie, puissance, précision, PP, effets en attente].
const ARGENTA_MOVES := {
	&"rock_throw": [&"rock", MoveData.Category.PHYSICAL, 50, 90, 15, []],
	&"defense_curl": [&"normal", MoveData.Category.STATUS, 0, 0, 40, []],
	&"self_destruct": [&"normal", MoveData.Category.PHYSICAL, 200, 100, 5, []],
	&"earthquake": [&"ground", MoveData.Category.PHYSICAL, 100, 100, 10, []],
	&"explosion": [&"normal", MoveData.Category.PHYSICAL, 250, 100, 5, []],
	&"bind": [&"normal", MoveData.Category.PHYSICAL, 15, 85, 20, []],
	&"slam": [&"normal", MoveData.Category.PHYSICAL, 80, 75, 20, []],
}
## Drapeaux de la fin du J9 portés par les départs du J10.
const J9_FLAGS: Array[StringName] = [&"pokedex_activated", &"poison_unlocked",
	&"beaten_forest_scout_theo"]

var _data: PokemonData
var _items: ItemLibrary
var _lot: String


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()
	_lot = FileAccess.get_file_as_string(LOT)


# --- Espèces ----------------------------------------------------------------------------

func test_species_values_are_the_official_ones() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))
	for id: StringName in ARGENTA_SPECIES:
		var v: Array = ARGENTA_SPECIES[id]
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
		assert_eq([species.base_exp, species.male_ratio, species.growth_rate],
			[v[9], v[10], v[11]], String(id))


func test_learnsets_are_red_blue() -> void:
	var expected := {
		&"geodude": [[1, &"tackle"], [11, &"defense_curl"], [16, &"rock_throw"],
			[21, &"self_destruct"], [26, &"harden"], [31, &"earthquake"], [36, &"explosion"]],
		&"graveler": [[1, &"tackle"], [1, &"defense_curl"], [11, &"defense_curl"],
			[16, &"rock_throw"], [21, &"self_destruct"], [29, &"harden"], [36, &"earthquake"],
			[43, &"explosion"]],
		&"onix": [[1, &"tackle"], [1, &"screech"], [15, &"bind"], [19, &"rock_throw"],
			[25, &"rage"], [33, &"slam"], [43, &"harden"]],
		&"sandshrew": [[1, &"scratch"], [10, &"sand_attack"], [17, &"slash"],
			[24, &"poison_sting"], [31, &"swift"], [38, &"fury_swipes"]],
		&"sandslash": [[1, &"scratch"], [1, &"sand_attack"], [10, &"sand_attack"],
			[17, &"slash"], [27, &"poison_sting"], [36, &"swift"], [47, &"fury_swipes"]],
	}
	for id: StringName in expected:
		assert_eq(_data.get_species(id).learnset, expected[id], String(id))
	assert_eq(_data.get_species(&"golem").learnset, _data.get_species(&"graveler").learnset,
		"Grolem apprend comme Gravalanch (Rouge/Bleu)")


func test_liam_pokemon_know_only_engine_moves() -> void:
	# Liam (Racaillou 10, Sabelette 10) : capacités de Rouge/Bleu au niveau, toutes jouées.
	assert_eq(_data.get_species(&"geodude").moves_at(10), [&"tackle"] as Array[StringName])
	assert_eq(_data.get_species(&"sandshrew").moves_at(10), [&"scratch", &"sand_attack"]
		as Array[StringName])
	for id: StringName in [&"tackle", &"scratch", &"sand_attack", &"defense_curl", &"screech",
			&"harden", &"rock_throw"]:
		assert_eq(_data.get_move(id).pending_effects.size(), 0, String(id))


# --- Capacités --------------------------------------------------------------------------

func test_new_moves_values() -> void:
	for id: StringName in ARGENTA_MOVES:
		var row: Array = ARGENTA_MOVES[id]
		var move := _data.get_move(id)
		assert_not_null(move, String(id))
		if move == null:
			continue
		assert_eq([move.type, move.category, move.power, move.accuracy, move.pp],
			row.slice(0, 5), String(id))
		assert_eq(move.pending_effects, PackedStringArray(row[5]), String(id))
	var curl := _data.get_move(&"defense_curl")
	assert_eq([curl.effects.size(), curl.effects[0].stat, curl.effects[0].stages,
		curl.effects[0].target], [1, &"def", 1, MoveEffect.Target.SELF])
	assert_true(curl.never_misses())


func test_new_move_texts_are_the_validated_lot() -> void:
	assert_false(_lot.is_empty(), "lot de textes lisible")
	var names := {
		&"rock_throw": "Jet-Pierres", &"defense_curl": "Boul'Armure",
		&"self_destruct": "Destruction", &"earthquake": "Séisme", &"explosion": "Explosion",
		&"bind": "Étreinte", &"slam": "Souplesse",
	}
	for id: StringName in names:
		var move := _data.get_move(id)
		assert_eq(move.name, names[id], String(id))
		assert_true(_lot.contains("`%s` · `name` | " % id), String(id))
		assert_true(_lot.contains("| « %s » |" % move.name), "%s : nom" % id)
		if id == &"self_destruct":
			# Jalon 12 (T12) : description remplacée par le texte validé du dossier 15 §20 n° 45.
			assert_eq(move.description, "Inflige de gros dégâts. Le lanceur est mis K.O.")
			continue
		assert_true(_lot.contains("| « %s » |" % move.description), "%s : description" % id)
		assert_false(move.draft, String(id))
	# Note A1 : ni « Ligotage », ni « Autodestruction » au J10. « Patience » (bide) arrive au J11
	# avec la CT34 (dossier 14 §6.3) ; Ligotage au J12 (Abo, data/pokemon/moves/mt_moon.json).
	assert_eq(_data.get_move(&"wrap").source, "res://data/pokemon/moves/mt_moon.json")
	# Ligotage existe donc (Abo, Chétiflor au J13), mais jamais chez Onix (Étreinte).
	for entry: Array in _data.get_species(&"onix").learnset:
		assert_ne(entry[1], &"wrap", "Onix : Étreinte, pas Ligotage")
	assert_eq(_data.get_move(&"bide").name, "Patience")


# --- Pokédex ----------------------------------------------------------------------------

func test_pokedex_entries_are_the_validated_lot() -> void:
	var dex := PokedexLibrary.new()
	assert_true(dex.load_file(), "\n".join(dex.get_errors()))
	var official := {
		&"geodude": [0.4, 20.0], &"graveler": [1.0, 105.0], &"golem": [1.4, 300.0],
		&"onix": [8.8, 210.0], &"sandshrew": [0.6, 12.0], &"sandslash": [1.0, 29.5],
	}
	for id: StringName in official:
		var info := dex.get_species(id)
		assert_not_null(info, String(id))
		if info == null:
			continue
		assert_almost_eq(info.height, float(official[id][0]), 0.001, String(id))
		assert_almost_eq(info.weight, float(official[id][1]), 0.001, String(id))
		assert_true(_lot.contains("| « %s » |" % info.description), "%s : description" % id)
		for note: PokedexNoteData in info.notes:
			assert_true(_lot.contains("| « %s » |" % note.text), "%s : note" % note.id)
	# Les formes de base ont une note (première rencontre), pas les évolutions.
	var note_ids: Array[StringName] = []
	for id: StringName in official:
		for note: PokedexNoteData in dex.get_notes(id):
			note_ids.append(note.id)
			assert_eq(note.seen, 1, String(note.id))
	assert_eq(note_ids, [&"geodude_sun", &"onix_rumble", &"sandshrew_burrow"]
		as Array[StringName])


# --- Dresseurs de l'Arène ---------------------------------------------------------------

func test_camper_liam() -> void:
	var trainers := TrainerLibrary.new(_data)
	assert_true(trainers.load_dir(), "\n".join(trainers.get_errors()))
	var liam := trainers.get_trainer(&"pewter_gym_liam")
	assert_not_null(liam)
	if liam == null:
		return
	assert_eq([liam.name, liam.ai, liam.prize_money, liam.can_lose, liam.heal_after,
		liam.gives_exp], ["Campeur Liam", BattleAI.RANDOM, 200, false, false, true])
	assert_eq([liam.start_message, liam.end_message, liam.allow_bag], [true, true, true])
	var team: Array = []
	for slot: TrainerSlot in liam.team:
		team.append([slot.species, slot.level, slot.moves.size()])
	assert_eq(team, [[&"geodude", 10, 0], [&"sandshrew", 10, 0]], "capacités de Rouge/Bleu")


func test_brock_team_with_chosen_moves() -> void:
	var trainers := TrainerLibrary.new(_data)
	trainers.load_dir()
	var brock := trainers.get_trainer(&"pewter_gym_brock")
	assert_not_null(brock)
	if brock == null:
		return
	assert_eq([brock.name, brock.ai, brock.prize_money, brock.prize_per_level],
		["Pierre", BattleAI.SMART, 1300, 0])
	assert_eq([brock.can_lose, brock.heal_after, brock.gives_exp], [false, false, true])
	assert_eq([brock.start_message, brock.end_message, brock.allow_bag], [false, true, true],
		"la carte et l'introduction remplacent le message de début ; SAC permis")
	var party := trainers.build_team(&"pewter_gym_brock", &"charmander", GameRng.new(7))
	var built: Array = []
	for pokemon: Pokemon in party.get_all():
		var moves: Array[StringName] = []
		for slot: MoveSlot in pokemon.moves:
			moves.append(slot.move_id)
			assert_eq(slot.pp, _data.get_move(slot.move_id).pp, "PP pleins")
		built.append([pokemon.species_id, pokemon.level, moves])
	assert_eq(built, [
		[&"geodude", 12, [&"tackle", &"defense_curl"] as Array[StringName]],
		[&"onix", 14, [&"tackle", &"screech", &"harden", &"rock_throw"] as Array[StringName]],
	])
	# Une seule attaque Roche, portée par Onix (arbitrage 1).
	var rock := 0
	for slot: TrainerSlot in brock.team:
		for move_id: StringName in slot.moves:
			if _data.get_move(move_id).type == &"rock":
				rock += 1
	assert_eq(rock, 1)


# --- Boutique, rencontres, zones --------------------------------------------------------

func test_pewter_mart_stock() -> void:
	var shops := ShopLibrary.new()
	assert_true(shops.load_dir(), "\n".join(shops.get_errors()))
	assert_true(shops.check_references(_items), "\n".join(shops.get_errors()))
	var mart := shops.get_shop(&"pewter_mart")
	assert_not_null(mart)
	if mart == null:
		return
	assert_eq(mart.item_ids(), [&"poke_ball", &"potion", &"antidote", &"paralyze_heal",
		&"awakening", &"burn_heal", &"escape_rope"] as Array[StringName],
		"dossier 12 §8, remèdes du J11 (dossier 14 §3.4), Corde Sortie (dossier 15 §11)")
	assert_eq(ShopRules.stock(mart, StoryFlags.new()), mart.item_ids(), "sans condition")
	var prices: Array[int] = []
	for item_id: StringName in mart.item_ids():
		prices.append(_items.get_item(item_id).price)
	assert_eq(prices, [200, 300, 100, 200, 250, 250, 550] as Array[int],
		"dossier 12 §8, dossier 14 §3.4, dossier 15 §11 (550 ₽)")


func test_route_2_north_table_is_route_2_one_level_higher() -> void:
	var lib := EncounterLibrary.new(_data)
	assert_true(lib.load_dir(), "\n".join(lib.get_errors()))
	var north := lib.get_table(&"route_2_north", &"grass")
	var south := lib.get_table(&"route_2", &"grass")
	assert_not_null(north)
	if north == null or south == null:
		return
	assert_eq(north.maps, [&"route_2_north"] as Array[StringName])
	assert_eq([north.rate, north.ramp_from, north.ramp_max], [25, 15, 20])
	assert_eq(north.total_weight(), 100)
	assert_eq(north.slots.size(), south.slots.size())
	for i: int in north.slots.size():
		var n := north.slots[i]
		var s := south.slots[i]
		assert_eq([n.species, n.weight], [s.species, s.weight], "même famille, même ordre")
		assert_eq([n.min_level, n.max_level], [s.min_level + 1, s.max_level + 1],
			"%s : un niveau plus haut" % n.species)
	for slot: EncounterSlot in north.slots:
		assert_true(ResourceLoader.exists(BattleArt.placeholder_path(slot.species, true)),
			String(slot.species))


func test_zones_of_route_2_north_and_pewter() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file(), "\n".join(zones.get_errors()))
	# Q-3 (Kevin, 2026-10-08) : la Route 2 nord est la 2e carte de la zone Route 2, dont les
	# textes ne changent pas (lot validé : « Route 2 sur la Carte : rien ne change »).
	var route_2 := zones.get_zone(&"route_2")
	assert_eq(route_2.maps, [&"route_2", &"route_2_north", &"route_2_east",
		&"route_2_east_gate"] as Array[StringName], "J17 T19 : le couloir est et son poste")
	assert_eq(route_2.subtitle, "Jadielle — Forêt de Jade")
	assert_eq(zones.zone_of(&"route_2_north"), &"route_2")
	var pewter := zones.get_zone(&"pewter_city")
	assert_eq(pewter.maps, [&"pewter_city", &"pewter_center", &"pewter_mart",
		&"pewter_museum", &"pewter_museum_science", &"pewter_gym", &"pewter_house_mason",
		&"pewter_house_researcher", &"pewter_museum_reserve"] as Array[StringName])
	assert_eq(pewter.subtitle, "", "titre « ARGENTA » seul (arbitrage 10)")
	assert_eq(pewter.description,
		"Une ville entre pierre et montagne, au pied des reliefs de l'est.")
	var dossier := FileAccess.get_file_as_string(DOSSIER_12)
	assert_true(dossier.contains("« %s »" % pewter.description), "texte verrouillé")
	var found: Dictionary = {}
	for service: ZoneService in pewter.services:
		found[service.id] = service.found_on
	assert_eq(found, {&"pokemon_center": &"pewter_center", &"poke_mart": &"pewter_mart",
		&"gym": &"pewter_gym"})


# --- Départs de débogage (§2.14) --------------------------------------------------------

## [nom, carte, point d'apparition, drapeaux en plus de ceux du J9, drapeaux absents].
const STARTS: Array = [
	["route_2_north", &"route_2_north", &"from_forest_gate", [], [&"pewter_arrived"]],
	["pewter", &"pewter_city", &"from_route_2_north_c", [], [&"pewter_arrived"]],
	["pewter_gym", &"pewter_city", &"from_gym", [&"pewter_arrived"],
		[&"beaten_pewter_gym_liam", &"brock_met", &"badge_boulder"]],
	["brock_weak", &"pewter_city", &"from_center", [&"pewter_arrived",
		&"beaten_pewter_gym_liam"], [&"brock_met", &"badge_boulder"]],
	["badge_after", &"pewter_gym", &"entrance", [&"pewter_arrived", &"beaten_pewter_gym_liam",
		&"brock_met", &"badge_boulder"], [&"route_3_guard_cleared"]],
]


func test_shipped_j10_starts() -> void:
	for row: Array in STARTS:
		var start := DebugStart.new()
		assert_true(start.load_file(TOOL_STARTS + String(row[0]) + ".json", _data, _items),
			"%s : %s" % [row[0], "\n".join(start.get_errors())])
		assert_eq([start.map, start.spawn, start.facing], [row[1], row[2], Vector2i.UP],
			String(row[0]))
		assert_false(start.autosave, "%s : ne touche jamais la sauvegarde" % row[0])
		for flag: StringName in J9_FLAGS + (row[3] as Array):
			assert_true(start.flags.has(flag), "%s : %s" % [row[0], flag])
		for flag: StringName in row[4]:
			assert_false(start.flags.has(flag), "%s : sans %s" % [row[0], flag])
		# Cartes du T11 (Route 2 nord, Argenta) et du T13 (Arène) : point vérifié dès qu'elles
		# existent.
		if MapCatalog.has_map(start.map):
			var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() \
					as GameMap
			assert_true(map.has_spawn(start.spawn), "%s : point d'apparition" % row[0])
			map.free()


func test_brock_weak_is_a_lone_weak_charmander() -> void:
	var start := DebugStart.new()
	start.load_file(TOOL_STARTS + "brock_weak.json", _data, _items)
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	assert_eq(state.party.size(), 1)
	var pokemon: Pokemon = state.party.get_at(0)
	assert_eq([pokemon.species_id, pokemon.level], [&"charmander", 6], "pour perdre contre Pierre")
	assert_true(start.bag.is_empty(), "sans Sac")
