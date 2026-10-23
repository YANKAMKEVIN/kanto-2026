extends GutTest
## Données du jalon 25 (T6 à T9 ; docs/tech/jalon-25.md §2.8, dossier 28 §4.6 à §4.8, §8.3, §8.4,
## §9, §10, §16) : espèces, capacités, objets, Dresseurs du Manoir et de l'Arène, rencontres du
## Manoir, Vieil Ambre → Ptéra, reprises du J22. Fichier séparé des tests partagés.

## [dex, nom, types, PV, Att, Déf, Att. Spé., Déf. Spé., Vit., base_exp, capture, male_ratio, croissance]
const SPECIES := {
	&"ponyta": [77, "Ponyta", [&"fire"], 50, 85, 55, 65, 65, 90, 82, 190, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"rapidash": [78, "Galopa", [&"fire"], 65, 100, 70, 80, 80, 105, 175, 60, 0.5,
		ExpCurve.Rate.MEDIUM_FAST],
	&"magmar": [126, "Magmar", [&"fire"], 65, 95, 57, 100, 85, 93, 167, 45, 0.75,
		ExpCurve.Rate.MEDIUM_FAST],
	&"aerodactyl": [142, "Ptéra", [&"rock", &"flying"], 80, 105, 65, 60, 75, 130, 180, 45,
		0.875, ExpCurve.Rate.SLOW],
}
## Espèces du J22 utilisées par le J25 (Manoir) : les reprises de `kanto_j25_reprises.json`,
## identiques, ont été retirées à la fusion de `main` (J22 dans `main`).
const REPRISES := {
	&"grimer": [88, "Tadmorv", 190], &"muk": [89, "Grotadmorv", 75],
	&"weezing": [110, "Smogogo", 60], &"electrode": [101, "Électrode", 60],
}
const MANSION_TRAINERS := {
	&"mansion_scientist_1": ["Scientifique Aurélien", 1450, [[&"electrode", 29], [&"weezing", 29]]],
	&"mansion_burglar_1": ["Pillard Gégé", 3060, [[&"charmander", 34], [&"charmeleon", 34]]],
	&"mansion_burglar_2": ["Pillard Lulu", 3420, [[&"ninetales", 38]]],
	&"mansion_scientist_2": ["Scientifique Clothilde", 1650,
		[[&"magnemite", 33], [&"magneton", 33], [&"voltorb", 33]]],
	&"mansion_burglar_3": ["Pillard Tito", 3060, [[&"growlithe", 34], [&"ponyta", 34]]],
	&"mansion_scientist_3": ["Scientifique Prosper", 1700, [[&"magnemite", 34], [&"electrode", 34]]],
}
## Niveaux de Rouge/Bleu + 4 (E-1, Kevin 2026-10-19) ; récompenses du dossier 28 §8.3 (inchangées).
const GYM_TRAINERS := {
	&"cinnabar_gym_1": ["Intello Paulin", 900, [[&"vulpix", 40], [&"vulpix", 40], [&"ninetales", 40]]],
	&"cinnabar_gym_2": ["Pillard Rico", 3240, [[&"growlithe", 40], [&"vulpix", 40], [&"ninetales", 40]]],
	&"cinnabar_gym_3": ["Intello Léopold", 850, [[&"ponyta", 38], [&"charmander", 38],
		[&"vulpix", 38], [&"growlithe", 38]]],
	&"cinnabar_gym_4": ["Pillard Fred", 3690, [[&"ponyta", 45]]],
	&"cinnabar_gym_5": ["Intello Octave", 1025, [[&"rapidash", 45]]],
	&"cinnabar_gym_6": ["Pillard Jojo", 3330, [[&"vulpix", 41], [&"growlithe", 41]]],
	&"cinnabar_gym_7": ["Intello Marius", 925, [[&"growlithe", 41], [&"vulpix", 41]]],
}
## carte → [taux, { espèce: [poids, niveau min, niveau max] }] : union Rouge + Bleu (annexe RB
## §1.8), poids sur 256 (moyenne des deux tables, demi-unités arrondies alternativement).
const MANSION := {
	&"pokemon_mansion_1f": [{ &"ponyta": [102, 28, 34], &"koffing": [58, 30, 32],
		&"grimer": [57, 30, 32], &"weezing": [7, 37, 39], &"muk": [7, 37, 39],
		&"growlithe": [13, 34, 34], &"vulpix": [12, 34, 34] }],
	&"pokemon_mansion_2f": [{ &"ponyta": [63, 28, 32], &"koffing": [64, 30, 34],
		&"grimer": [64, 30, 34], &"weezing": [7, 37, 39], &"muk": [7, 37, 39],
		&"growlithe": [26, 32, 32], &"vulpix": [25, 32, 32] }],
	&"pokemon_mansion_3f": [{ &"ponyta": [49, 32, 36], &"koffing": [51, 31, 35],
		&"grimer": [52, 31, 35], &"weezing": [20, 38, 42], &"muk": [21, 38, 42],
		&"growlithe": [25, 33, 33], &"vulpix": [26, 33, 33], &"magmar": [12, 34, 34] }],
	&"pokemon_mansion_b1f": [{ &"ponyta": [38, 32, 34], &"koffing": [70, 31, 35],
		&"grimer": [70, 31, 35], &"weezing": [20, 40, 42], &"muk": [14, 40, 42],
		&"growlithe": [19, 35, 35], &"vulpix": [20, 35, 35], &"magmar": [5, 38, 38] }],
}
## Capacités dont l'effet manque au moteur et que l'on peut rencontrer chez les sauvages du
## Manoir (comme aux jalons précédents) ; chez les Dresseurs, remplacées explicitement.
const PENDING_MOVES: Array[StringName] = [&"rage", &"mirror_move", &"recover", &"whirlwind"]

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


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
		assert_eq(species.source, "res://data/pokemon/species/kanto_j25.json", String(id))


func test_evolutions_and_learnsets_are_red_blue() -> void:
	var rule: EvolutionRule = _data.get_species(&"ponyta").evolutions[0]
	assert_eq([rule.into, rule.method, rule.level], [&"rapidash", EvolutionRule.Method.LEVEL, 40])
	assert_eq(_data.get_species(&"rapidash").evolutions.size(), 0)
	assert_eq(_data.get_species(&"aerodactyl").moves_at(30), [&"wing_attack", &"agility"]
		as Array[StringName], "Ptéra N30 (résurrection de l'ambre)")
	assert_eq(_data.get_species(&"magmar").moves_at(36), [&"ember", &"leer"]
		as Array[StringName])
	assert_eq(_data.get_species(&"ponyta").moves_at(43), [&"stomp", &"growl",
		&"fire_spin", &"take_down"] as Array[StringName])


func test_species_of_jalon_22_used_by_jalon_25_come_from_its_file() -> void:
	for id: StringName in REPRISES:
		var v: Array = REPRISES[id]
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species == null:
			continue
		assert_eq([species.dex, species.name, species.catch_rate], v, String(id))
		assert_eq(species.source, "res://data/pokemon/species/kanto_j22.json")


func test_every_new_species_has_battle_sprites_and_a_pokedex_entry() -> void:
	var dex := PokedexLibrary.new()
	assert_true(dex.load_file(), "\n".join(dex.get_errors()))
	var all: Array[StringName] = []
	all.assign(SPECIES.keys())
	all.append_array(REPRISES.keys())
	for id: StringName in all:
		for back: bool in [false, true]:
			assert_true(ResourceLoader.exists(BattleArt.placeholder_path(id, back)), String(id))
		assert_true(dex.has_species(id), String(id))
	assert_eq(dex.get_notes(&"ponyta").size(), 1)
	assert_eq(dex.get_notes(&"magmar").size(), 1)


func test_tm_compatibility_regenerated() -> void:
	assert_eq(_data.tm_move(38), &"fire_blast")
	assert_eq(_data.tm_move(14), &"blizzard")
	assert_eq(_data.tm_move(22), &"solar_beam")
	for id: StringName in [&"ponyta", &"rapidash", &"magmar", &"aerodactyl", &"grimer"]:
		assert_true(_data.can_learn_tm(id, 38), "%s : CT38 Déflagration" % id)
	assert_false(_data.can_learn_tm(&"ponyta", 14))
	assert_true(_data.can_learn_tm(&"magmar", 35), "Métronome")


# --- Capacités --------------------------------------------------------------------------

func test_new_moves() -> void:
	var blast := _data.get_move(&"fire_blast")
	assert_eq([blast.type, blast.category, blast.power, blast.accuracy, blast.pp],
		[&"fire", MoveData.Category.SPECIAL, 110, 85, 5])
	var burn := blast.effect_of(MoveEffect.Kind.STATUS)
	assert_eq([burn.status, burn.chance], [&"burn", 10])
	var punch := _data.get_move(&"fire_punch")
	assert_eq([punch.type, punch.category, punch.power, punch.accuracy, punch.pp],
		[&"fire", MoveData.Category.PHYSICAL, 75, 100, 15])
	for id: StringName in [&"fire_blast", &"fire_punch"]:
		assert_eq(_data.get_move(id).source, "res://data/pokemon/moves/j25.json")
		assert_eq(_data.get_move(id).pending_effects.size(), 0)


func test_take_down_recoil_is_effective_e3() -> void:
	# E-3 (Kevin, 2026-10-19) : le contrecoup de Bélier est réel (¼), plus de « pending ».
	var move := _data.get_move(&"take_down")
	assert_eq(move.effect_of(MoveEffect.Kind.RECOIL_DAMAGE).fraction, 0.25)
	assert_eq(move.pending_effects.size(), 0)
	assert_eq(move.source, "res://data/pokemon/moves/j17.json")


func test_stomp_blizzard_and_solar_beam_exist_for_the_tms() -> void:
	assert_eq(_data.get_move(&"stomp").source, "res://data/pokemon/moves/celadon.json")
	assert_not_null(_data.get_move(&"blizzard").effect_of(MoveEffect.Kind.STATUS))
	assert_not_null(_data.get_move(&"solar_beam").effect_of(MoveEffect.Kind.CHARGE),
		"Lance-Soleil : charge en deux tours")


# --- Objets -----------------------------------------------------------------------------

func test_new_items() -> void:
	for id: StringName in [&"secret_key", &"old_amber"]:
		assert_eq(_items.get_item(id).category, ItemData.Category.KEY, String(id))
	assert_eq(_items.get_item(&"secret_key").name, "Clé Secrète")
	assert_eq(_items.get_item(&"old_amber").name, "Vieil Ambre")
	assert_eq(_items.get_item(&"old_amber").description,
		"Un morceau d'ambre ancien. Il contiendrait l'ADN d'un Pokémon.")
	var potion := _items.get_item(&"max_potion")
	assert_eq([potion.name, potion.category, potion.heal_amount, potion.price],
		["Potion Max", ItemData.Category.HEAL, 999, 2500])
	var revive := _items.get_item(&"max_revive")
	assert_eq([revive.name, revive.revive], ["Rappel Max", 1.0])
	assert_eq(_items.get_item(&"revive").revive, 0.5, "le Rappel du J20 inchangé")
	for row: Array in [[&"tm38", 38, &"fire_blast"], [&"tm14", 14, &"blizzard"],
			[&"tm22", 22, &"solar_beam"]]:
		var tm := _items.get_item(row[0])
		assert_eq([tm.category, tm.tm_number, tm.teaches], [ItemData.Category.TM, row[1], row[2]],
			String(row[0]))
	for id: StringName in [&"secret_key", &"old_amber", &"tm38", &"max_potion", &"max_revive",
			&"tm14", &"tm22"]:
		assert_eq(_items.get_item(id).source, "res://data/items/items_j25.json", String(id))
		assert_false(_items.get_item(id).draft, String(id))


# --- Fossiles ---------------------------------------------------------------------------

func test_old_amber_is_in_the_fossil_list() -> void:
	var lab := FossilLab.new()
	assert_true(lab.load_file())
	assert_eq(lab.species_of(&"old_amber"), &"aerodactyl")
	assert_eq(lab.level_of(&"old_amber"), 30)
	assert_eq(lab.flag_of(&"old_amber"), &"fossil_reviving_aerodactyl")
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), "\n".join(dialogues.get_errors()))
	for id: StringName in [&"cinnabar_fossil_ready_aerodactyl", &"cinnabar_fossil_received_aerodactyl",
			&"cinnabar_fossil_stored_aerodactyl"]:
		assert_true(dialogues.has_dialogue(id), String(id))
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir(), "\n".join(cutscenes.get_errors()))
	assert_true(cutscenes.has_cutscene(&"cinnabar_fossil_take_aerodactyl"))
	assert_true(cutscenes.has_cutscene(&"cinnabar_fossil_give_aerodactyl"))


# --- Dresseurs --------------------------------------------------------------------------

func _check_trainers(rows: Dictionary, file: String, ai: StringName) -> void:
	var trainers := TrainerLibrary.new(_data)
	assert_true(trainers.load_dir(), "\n".join(trainers.get_errors()))
	for id: StringName in rows:
		var row: Array = rows[id]
		var trainer := trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq(trainer.source, file, String(id))
		assert_eq([trainer.name, trainer.ai, trainer.can_lose, trainer.heal_after,
			trainer.gives_exp, trainer.prize_for(0)], [row[0], ai, false, false, true, row[1]],
			String(id))
		var team: Array = []
		for slot: TrainerSlot in trainer.team:
			team.append([slot.species, slot.level])
			var known: Array[StringName] = slot.moves
			if known.is_empty():
				known = _data.get_species(slot.species).moves_at(slot.level)
			for move_id: StringName in known:
				assert_true(_data.has_move(move_id), "%s : %s" % [id, move_id])
				assert_eq(_data.get_move(move_id).pending_effects.size(), 0,
					"%s : %s sans effet" % [id, move_id])
		assert_eq(team, row[2], String(id))


func test_mansion_trainers() -> void:
	_check_trainers(MANSION_TRAINERS, "res://data/trainers/pokemon_mansion.json", &"random")
	var burglar := TrainerLibrary.new(_data)
	burglar.load_dir()
	assert_eq(burglar.get_trainer(&"mansion_burglar_1").team[0].moves,
		[&"growl", &"ember", &"leer", &"slash"] as Array[StringName], "Salamèche N34 sans Frénésie")


func test_gym_trainers_are_red_blue_plus_four() -> void:
	_check_trainers(GYM_TRAINERS, "res://data/trainers/cinnabar_gym.json", &"random")
	var trainers := TrainerLibrary.new(_data)
	trainers.load_dir()
	var lowest := 99
	var highest := 0
	for id: StringName in GYM_TRAINERS:
		for slot: TrainerSlot in trainers.get_trainer(id).team:
			lowest = mini(lowest, slot.level)
			highest = maxi(highest, slot.level)
	assert_eq([lowest, highest], [38, 45], "E-1 : N34–41 + 4")


func test_auguste() -> void:
	var trainers := TrainerLibrary.new(_data)
	trainers.load_dir()
	var blaine := trainers.get_trainer(&"cinnabar_gym_blaine")
	assert_not_null(blaine)
	assert_eq([blaine.name, blaine.ai, blaine.prize_for(0), blaine.can_switch, blaine.has_card(),
		blaine.card_name, blaine.card_title], ["Auguste", &"smart", 4653, true, true, "AUGUSTE",
		"Champion d'Arène de Cramois'Île"])
	var expected := [
		[&"growlithe", 42, [&"ember", &"leer", &"take_down", &"agility"]],
		[&"ponyta", 40, [&"tail_whip", &"stomp", &"growl", &"fire_spin"]],
		[&"rapidash", 42, [&"tail_whip", &"stomp", &"growl", &"fire_spin"]],
		[&"arcanine", 47, [&"leer", &"ember", &"fire_blast", &"take_down"]],
	]
	assert_eq(blaine.team.size(), 4)
	for i: int in expected.size():
		assert_eq([blaine.team[i].species, blaine.team[i].level],
			[expected[i][0], expected[i][1]])
		assert_eq(blaine.team[i].moves, Array(expected[i][2], TYPE_STRING_NAME, &"", null))
	assert_eq(blaine.source, "res://data/trainers/cinnabar_gym.json")


func test_trainer_names_are_not_taken_elsewhere() -> void:
	# Prénoms vérifiés libres sur les branches (Armand, Odile, Ernest, Gustave étaient pris).
	var trainers := TrainerLibrary.new(_data)
	trainers.load_dir()
	var mine := {}
	for id: StringName in MANSION_TRAINERS:
		mine[MANSION_TRAINERS[id][0]] = id
	for id: StringName in GYM_TRAINERS:
		mine[GYM_TRAINERS[id][0]] = id
	for id: StringName in trainers.get_ids():
		var name := trainers.get_trainer(id).name
		if mine.has(name):
			assert_eq(id, mine[name], "« %s » aussi porté par %s" % [name, id])
		for own: String in mine:
			assert_ne(name.split(" ")[-1], own.split(" ")[-1] if mine[own] != id else "",
				"%s : prénom de %s" % [id, own])


func test_trainer_lines() -> void:
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), "\n".join(dialogues.get_errors()))
	var names := {}
	for id: StringName in MANSION_TRAINERS:
		names[id] = MANSION_TRAINERS[id][0]
	for id: StringName in GYM_TRAINERS:
		names[id] = GYM_TRAINERS[id][0]
	for id: StringName in names:
		# Chaque Dresseur : avant, défaite, après.
		for moment: String in ["before", "defeated", "after"]:
			var dialogue_id := StringName("%s_%s" % [id, moment])
			var dialogue := dialogues.get_dialogue(dialogue_id)
			assert_not_null(dialogue, String(dialogue_id))
			if dialogue == null:
				continue
			assert_eq(dialogue.speaker, names[id], String(dialogue_id))
			assert_false(dialogue.draft, String(dialogue_id))
	for id: StringName in [&"cinnabar_blaine_before", &"cinnabar_blaine_defeated",
			&"cinnabar_blaine_badge", &"cinnabar_blaine_tm38", &"cinnabar_blaine_after"]:
		assert_eq(dialogues.get_dialogue(id).speaker, "Auguste", String(id))


# --- Rencontres -------------------------------------------------------------------------

func test_mansion_encounter_tables() -> void:
	var lib := EncounterLibrary.new(_data)
	assert_true(lib.load_dir(), "\n".join(lib.get_errors()))
	for map: StringName in MANSION:
		var table := lib.get_table(map, &"floor")
		assert_not_null(table, String(map))
		if table == null:
			continue
		assert_eq(table.maps, [map] as Array[StringName])
		assert_eq(table.rate, 10, "%s : 10/256 par pas (RB)" % map)
		assert_false(table.has_ramp(), String(map))
		assert_eq(table.total_weight(), 256, "%s : poids sur 256" % map)
		assert_eq(table.ghost_unless_item, &"")
		var rows: Dictionary = MANSION[map][0]
		assert_eq(table.slots.size(), rows.size(), String(map))
		for slot: EncounterSlot in table.slots:
			assert_true(rows.has(slot.species), "%s : %s" % [map, slot.species])
			if rows.has(slot.species):
				assert_eq([slot.weight, slot.min_level, slot.max_level], rows[slot.species],
					"%s : %s" % [map, slot.species])
	assert_false(lib.has_table(&"pokemon_mansion_1f", &"grass"))
	# Magmar : Bleu seulement, 3F et sous-sol.
	for map: StringName in [&"pokemon_mansion_1f", &"pokemon_mansion_2f"]:
		for slot: EncounterSlot in lib.get_table(map, &"floor").slots:
			assert_ne(slot.species, &"magmar")


func test_wild_pending_moves_are_known() -> void:
	var lib := EncounterLibrary.new(_data)
	lib.load_dir()
	var met: Array[StringName] = []
	for map: StringName in MANSION:
		for slot: EncounterSlot in lib.get_table(map, &"floor").slots:
			for level: int in range(slot.min_level, slot.max_level + 1):
				for move_id: StringName in _data.get_species(slot.species).moves_at(level):
					assert_true(_data.has_move(move_id), "%s : %s" % [slot.species, move_id])
					if not _data.get_move(move_id).pending_effects.is_empty() \
							and not met.has(move_id):
						met.append(move_id)
	for move_id: StringName in met:
		assert_true(PENDING_MOVES.has(move_id), String(move_id))


# --- Fonds de combat --------------------------------------------------------------------

func test_battle_backgrounds_are_placeholders() -> void:
	var catalog := BattleDecorCatalog.load_file()
	assert_has(catalog.get_ids(), &"manoir_salle")
	assert_has(catalog.get_ids(), &"arene_cramois")
	for map: StringName in [&"pokemon_mansion_1f", &"pokemon_mansion_2f", &"pokemon_mansion_3f",
			&"pokemon_mansion_b1f"]:
		assert_eq(catalog.pick(map, Vector2i.ZERO).id, &"manoir_salle", String(map))
	assert_eq(catalog.pick(&"cinnabar_gym", Vector2i.ZERO).id, &"arene_cramois")
	for id: StringName in [&"manoir_salle", &"arene_cramois"]:
		assert_true(catalog.get_decor(id).is_valid(), String(id))
		assert_true(ResourceLoader.exists(catalog.get_decor(id).back_path), String(id))
