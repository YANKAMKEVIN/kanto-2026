extends GutTest
## Données du jalon 15 (T12 ; docs/tech/jalon-15.md §2.7) : Miaouss et Persan, Jackpot (donnée
## seulement, effet en attente du T17), Super Potion et Guérison, Boutique de Carmin (sans Corde
## Sortie, ajoutée au T16), six Dresseurs de la Route 6 et leurs répliques. Textes recopiés mot
## pour mot du lot validé par Kevin le 2026-10-12 (dossier 18 §15). Fichier séparé des tests
## partagés que d'autres jalons modifient en parallèle.

const DOSSIER := "res://docs/design/dossier-18-carmin-sur-mer.md"
const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]

## [dex, nom, PV, Att, Déf, Att. Spé., Déf. Spé., Vit., base_exp, capture] (PokeAPI, convention
## des espèces existantes ; dossier 18 §10.1).
const SPECIES := {
	&"meowth": [52, "Miaouss", 40, 45, 35, 40, 40, 90, 58, 255],
	&"persian": [53, "Persan", 65, 70, 60, 65, 65, 115, 154, 90],
}
## Dresseurs de la Route 6 (§6.2 ; prénoms du plan §0.2 n° 9) : [ligne T-24 du dossier, nom,
## équipe [espèce, niveau]…, récompense, base de la classe].
const TRAINERS := {
	&"route_6_lass_chloe": ["T-24a", "Jeune Dresseuse Chloé",
		[[&"pidgey", 16], [&"pidgey", 16], [&"pidgey", 16]], 320, 20],
	&"route_6_camper_gabin": ["T-24b", "Campeur Gabin",
		[[&"spearow", 16], [&"raticate", 16]], 320, 20],
	&"route_6_scout_axel": ["T-24c", "Scout Axel",
		[[&"weedle", 16], [&"caterpie", 16], [&"weedle", 16]], 192, 12],
	&"route_6_camper_mathis": ["T-24d", "Campeur Mathis", [[&"squirtle", 20]], 400, 20],
	&"route_6_lass_manon": ["T-24e", "Jeune Dresseuse Manon",
		[[&"rattata", 16], [&"pikachu", 16]], 320, 20],
	&"route_6_scout_basile": ["T-24f", "Scout Basile", [[&"butterfree", 20]], 240, 12],
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

func test_species_values_are_the_official_ones() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))
	for id: StringName in SPECIES:
		var v: Array = SPECIES[id]
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species == null:
			continue
		assert_eq([species.dex, species.name], [v[0], v[1]], String(id))
		assert_eq(species.types, [&"normal"] as Array[StringName], String(id))
		assert_eq(species.base_stats, {&"hp": v[2], &"atk": v[3], &"def": v[4], &"spa": v[5],
			&"spd": v[6], &"spe": v[7]} as Dictionary[StringName, int], String(id))
		assert_eq([species.base_exp, species.catch_rate, species.male_ratio,
			species.growth_rate], [v[8], v[9], 0.5, ExpCurve.Rate.MEDIUM_FAST], String(id))
		assert_eq(species.source, "res://data/pokemon/species/kanto_vermilion.json")


func test_learnsets_are_red_blue() -> void:
	assert_eq(_data.get_species(&"meowth").learnset, [[1, &"scratch"], [1, &"growl"],
		[12, &"bite"], [17, &"pay_day"], [24, &"screech"], [33, &"fury_swipes"],
		[44, &"slash"]])
	assert_eq(_data.get_species(&"persian").learnset, [[1, &"scratch"], [1, &"growl"],
		[1, &"bite"], [1, &"screech"], [12, &"bite"], [17, &"pay_day"], [24, &"screech"],
		[37, &"fury_swipes"], [51, &"slash"]])


func test_meowth_evolves_into_persian_at_level_28() -> void:
	var rules := _data.get_species(&"meowth").evolutions
	assert_eq(rules.size(), 1)
	assert_eq([rules[0].into, rules[0].method, rules[0].level],
		[&"persian", EvolutionRule.Method.LEVEL, 28])
	assert_eq(_data.get_species(&"persian").evolutions.size(), 0)


func test_tm_compatibility_was_regenerated() -> void:
	# tools/gen_tm_compatibility.py relancé sur tous les fichiers d'espèces (jamais à la main).
	assert_true(_data.can_learn_tm(&"meowth", 34), "CT34 : Miaouss (Rouge/Bleu)")
	assert_true(_data.can_learn_tm(&"persian", 34), "CT34 : Persan (Rouge/Bleu)")
	assert_false(_data.can_learn_tm(&"meowth", 15), "CT15 (Ultralaser) : Persan seulement")
	assert_true(_data.can_learn_tm(&"persian", 15))


# --- Jackpot ---------------------------------------------------------------------------

func test_pay_day_carries_its_coins_effect() -> void:
	var move := _data.get_move(&"pay_day")
	assert_not_null(move)
	if move == null:
		return
	assert_eq([move.name, move.type, move.category, move.power, move.accuracy, move.pp],
		["Jackpot", &"normal", MoveData.Category.PHYSICAL, 40, 100, 20])
	# T17 : l'effet { kind: coins, per_level: 2 } remplace pending_effects.
	assert_eq(move.pending_effects, PackedStringArray())
	var coins := move.effect_of(MoveEffect.Kind.COINS)
	assert_not_null(coins, "effet COINS")
	if coins != null:
		assert_eq(coins.per_level, PayDayPurse.RB_PER_LEVEL, "2 × niveau (Rouge/Bleu)")
	assert_true(_validated("T-39").has(move.description), "description T-39")


# --- Pokédex ----------------------------------------------------------------------------

func test_pokedex_entries_are_the_validated_lot() -> void:
	var dex := PokedexLibrary.new()
	assert_true(dex.load_file(), "\n".join(dex.get_errors()))
	assert_true(dex.check_references(_data), "\n".join(dex.get_errors()))
	var official := {&"meowth": [0.4, 4.2, "T-40"], &"persian": [1.0, 32.0, "T-41"]}
	for id: StringName in official:
		var info := dex.get_species(id)
		assert_not_null(info, String(id))
		if info == null:
			continue
		assert_almost_eq(info.height, float(official[id][0]), 0.001, String(id))
		assert_almost_eq(info.weight, float(official[id][1]), 0.001, String(id))
		assert_eq(_validated(official[id][2]), [info.description] as Array[String], String(id))
		# Note de la forme de base seulement (annexe A.5, texte vérifié par test_annex_a_texts).
		assert_eq(info.notes.size(), 1 if id == &"meowth" else 0, String(id))


# --- Objets -----------------------------------------------------------------------------

func test_new_items() -> void:
	assert_eq(_items.get_errors().size(), 0, "\n".join(_items.get_errors()))
	var potion := _items.get_item(&"super_potion")
	assert_eq([potion.name, potion.plural, potion.feminine, potion.category,
		potion.heal_amount, potion.price], ["Super Potion", "Super Potions", true,
		ItemData.Category.HEAL, 50, 700])
	assert_eq(potion.cures.size(), 0)
	assert_eq(_validated("T-37"), [potion.description] as Array[String])
	var full := _items.get_item(&"full_restore")
	assert_eq([full.name, full.plural, full.feminine, full.category, full.price],
		["Guérison", "Guérisons", true, ItemData.Category.HEAL, 3000])
	assert_eq(full.cures, StatusRules.KNOWN, "les cinq statuts")
	assert_eq(_validated("T-38"), [full.description] as Array[String])


func test_full_restore_heals_everything() -> void:
	var full := _items.get_item(&"full_restore")
	for status: StringName in StatusRules.KNOWN:
		var mon := PokemonFactory.create(_data, &"meowth", 100, ScriptedRng.new(IV_0))
		assert_gt(mon.max_hp(), 1)
		assert_lt(mon.max_hp(), full.heal_amount, "999 dépasse tout PV max")
		mon.hp = 1
		mon.status = status
		ItemUse.restore(full, mon)
		assert_eq(ItemUse.cure(full, mon), status, String(status))
		assert_eq([mon.hp, mon.status], [mon.max_hp(), StatusRules.NONE], String(status))


# --- Boutique de Carmin -----------------------------------------------------------------

func test_vermilion_mart_stock() -> void:
	var shops := ShopLibrary.new()
	assert_true(shops.load_dir(), "\n".join(shops.get_errors()))
	assert_true(shops.check_references(_items), "\n".join(shops.get_errors()))
	var shop := shops.get_shop(&"vermilion_mart")
	assert_not_null(shop)
	if shop == null:
		return
	# Stock d'Azuria (plan J13 §2.5) + Super Potion (F-14) ; Corde Sortie en fin (T16, comme
	# Azuria).
	assert_eq(shop.item_ids(), [&"poke_ball", &"potion", &"super_potion", &"antidote",
		&"paralyze_heal", &"awakening", &"ice_heal", &"burn_heal", &"escape_rope",
		&"repel"]  # lot 32P : la Repousse de Rouge/Bleu
		as Array[StringName])
	for entry: Dictionary in shop.stock:
		assert_eq(entry.get("if", []).size() + entry.get("unless", []).size(), 0,
			"aucune condition : %s" % entry)
	assert_false(shop.item_ids().has(&"full_restore"), "Guérison non vendue")


# --- Dresseurs de la Route 6 ------------------------------------------------------------

func test_route_6_trainers() -> void:
	var trainers := TrainerLibrary.new(_data)
	assert_true(trainers.load_dir(), "\n".join(trainers.get_errors()))
	for id: StringName in TRAINERS:
		var row: Array = TRAINERS[id]
		var trainer := trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq(trainer.source, "res://data/trainers/route_6.json")
		assert_eq([trainer.name, trainer.ai, trainer.can_lose, trainer.heal_after,
			trainer.gives_exp], [row[1], &"random", false, false, true], String(id))
		var team: Array = []
		for slot: TrainerSlot in trainer.team:
			team.append([slot.species, slot.level])
		assert_eq(team, row[2], String(id))
		assert_eq(trainer.prize_for(0), row[3], String(id))
		var last_level: int = (row[2] as Array).back()[1]
		assert_eq(row[3], int(row[4]) * last_level, "%s : base × dernier niveau" % id)
	# Prénoms déjà pris au J13 (Nageur Lucas, Scout Timéo) : remplacés (plan §0.2 n° 9).
	for id: StringName in trainers.get_ids():
		var name := trainers.get_trainer(id).name
		if String(id).begins_with("route_6_"):
			assert_false(name.contains("Lucas") or name.contains("Timéo"), name)


func test_basile_butterfree_knows_the_status_powders() -> void:
	var trainers := TrainerLibrary.new(_data)
	trainers.load_dir()
	var team := trainers.build_team(&"route_6_scout_basile", &"bulbasaur",
		ScriptedRng.new(IV_0))
	assert_eq(team.size(), 1)
	assert_eq(team.get_at(0).moves.map(func(m: MoveSlot) -> StringName: return m.move_id),
		[&"confusion", &"poison_powder", &"stun_spore", &"sleep_powder"])


func test_other_trainers_know_red_blue_moves_at_their_level() -> void:
	# Capacités apprises au niveau : aucune capacité sans effet moteur dans ces équipes.
	for id: StringName in TRAINERS:
		for pair: Array in TRAINERS[id][2]:
			for move_id: StringName in _data.get_species(pair[0]).moves_at(pair[1]):
				assert_true(_data.has_move(move_id), "%s : %s" % [id, move_id])


func test_trainer_lines_are_the_validated_lot() -> void:
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), "\n".join(dialogues.get_errors()))
	for id: StringName in TRAINERS:
		var row: Array = TRAINERS[id]
		var quotes := _validated(row[0])
		assert_eq(quotes.size(), 3, "%s : avant, défaite, après" % row[0])
		var moments := ["before", "defeated", "after"]
		for i: int in moments.size():
			var dialogue_id := StringName("%s_%s" % [id, moments[i]])
			var dialogue := dialogues.get_dialogue(dialogue_id)
			assert_not_null(dialogue, String(dialogue_id))
			if dialogue == null or quotes.size() != 3:
				continue
			assert_eq(dialogue.source, "res://data/dialogues/route_6_trainers.json")
			assert_eq(dialogue.speaker, row[1], String(dialogue_id))
			assert_false(dialogue.draft, String(dialogue_id))
			assert_eq(dialogue.variants.size(), 1, String(dialogue_id))
			var texts: Array[String] = []
			for page: DialoguePage in dialogue.variants[0].pages:
				assert_lte(page.text.split("\n").size(), 2, "bulle de deux lignes au plus")
				texts.append(DialogueTokens.apply_agreements(page.text, {}).replace("\n", " "))
			assert_eq(" ".join(texts), quotes[i], String(dialogue_id))


# --- Outils ---------------------------------------------------------------------------

## Textes « … » de la ligne [param tag] (« T-37 », « T-24a »…) du lot validé (dossier §15).
func _validated(tag: String) -> Array[String]:
	var found: Array[String] = []
	var regex := RegEx.create_from_string("« (.+?) »")
	for line: String in _dossier.split("\n"):
		if line.begins_with("| %s |" % tag):
			for m: RegExMatch in regex.search_all(line):
				found.append(m.get_string(1))
	return found
