extends GutTest
## Chapitre Johto, JOH3 (`docs/tech/jalon-joh3.md`) : données générées depuis les grilles
## (`tools/gen_joh3_data.py`) : textes D-1 à D-38 du dossier joh-04 §16 mot pour mot, Dresseurs
## §6 (Sbires de nuit, chef obligatoire), objets §11, œuf §7, Grand Magasin §8, maison du lien
## §9, PNJ de la semaine §10 (horloge injectée), rencontres par moment §5, drapeaux §12. Les
## grands registres écartent les fichiers `joh3_*` (préfixe dans `j22_ids.gd`).

const J22Ids := preload("res://tests/helpers/j22_ids.gd")

const PREFIX := "joh3_"
const DOSSIER := "res://docs/design/dossier-joh-04-doublonville.md"
## Répliques de vendeur et de distributeur reprises des dossiers de Kanto (déjà validées).
const KANTO_DOSSIERS: Array[String] = ["res://docs/design/dossier-09-jadielle.md",
	"res://docs/design/dossier-23-celadopole.md", "res://docs/tech/jalon-20.md"]
const MAPS: Array[StringName] = [&"route_37", &"route_36", &"route_35", &"goldenrod_city",
	&"goldenrod_underground", &"goldenrod_center", &"goldenrod_dept_store_1f",
	&"goldenrod_dept_store_2f", &"goldenrod_dept_store_3f", &"goldenrod_dept_store_roof",
	&"goldenrod_bond_house", &"goldenrod_house_1", &"goldenrod_house_2"]
## Dossier §6 : Dresseur → (nom, équipe).
const TRAINERS: Dictionary = {
	&"route_37_birdkeeper_lise": ["Ornithologue Lise", [[&"pidgey", 14], [&"hoothoot", 15]]],
	&"route_37_grunt_a": ["Sbire Rocket", [[&"houndour", 15], [&"rattata", 14]]],
	&"route_37_grunt_b": ["Sbire Rocket", [[&"murkrow", 15], [&"ekans", 15]]],
	&"route_36_scout_max": ["Scout Max", [[&"growlithe", 15], [&"nidoran_m", 14]]],
	&"route_36_medium_ernest": ["Médium Ernest", [[&"abra", 16]]],
	&"route_35_fisher_gaston": ["Pêcheur Gaston", [[&"magikarp", 13], [&"magikarp", 13],
		[&"poliwag", 15]]],
	&"route_35_camper_anna": ["Campeuse Anna", [[&"nidoran_f", 15], [&"ponyta", 16]]],
	&"route_35_gentleman_armand": ["Gentleman Armand", [[&"growlithe", 17]]],
	&"goldenrod_underground_grunt_c": ["Sbire Rocket", [[&"rattata", 15], [&"ekans", 16]]],
	&"goldenrod_underground_grunt_d": ["Sbire Rocket", [[&"murkrow", 16], [&"houndour", 16]]],
	&"goldenrod_underground_boss": ["Chef de bande", [[&"houndour", 17], [&"murkrow", 17],
		[&"koffing", 18]]],
}
## Dossier §11 et §10 : scène → (objet, nombre, drapeau).
const GIFTS: Dictionary = {
	&"route_37_item_1": [&"super_potion", 1, &"got_route_37_item_1"],
	&"route_36_item_1": [&"revive", 1, &"got_route_36_item_1"],
	&"route_35_hidden_1": [&"great_ball", 2, &"got_route_35_hidden_1"],
	&"goldenrod_underground_item_1": [&"repel", 2, &"got_goldenrod_underground_item_1"],
	&"goldenrod_underground_hidden_1": [&"pearl", 1, &"got_goldenrod_underground_hidden_1"],
	&"goldenrod_dept_roof_upgrade": [&"up_grade", 1, &"goldenrod_upgrade_taken"],
	&"week_wednesday_gift": [&"great_ball", 3, &"week_wednesday_gift"],
	&"week_thursday_gift": [&"fresh_water", 3, &"week_thursday_gift"],
}
## Dossier §5 : table → (moments, niveaux, poids par espèce).
const TABLES: Dictionary = {
	&"route_37_grass_day": [[&"morning", &"day"], [13, 16], {&"furret": 25, &"growlithe": 25,
		&"pidgey": 20, &"ponyta": 15, &"rattata": 15}],
	&"route_37_grass_night": [[&"night"], [13, 16], {&"hoothoot": 35, &"houndour": 30,
		&"oddish": 20, &"raticate": 15}],
	&"route_36_grass_morning": [[&"morning"], [12, 15], {&"sentret": 30, &"growlithe": 20,
		&"nidoran_f": 15, &"nidoran_m": 15, &"pidgey": 10, &"caterpie": 10}],
	&"route_36_grass_day": [[&"day"], [12, 15], {&"sentret": 40, &"growlithe": 20,
		&"nidoran_f": 15, &"nidoran_m": 15, &"pidgey": 10}],
	&"route_36_grass_night": [[&"night"], [12, 15], {&"hoothoot": 40, &"nidoran_f": 15,
		&"nidoran_m": 15, &"oddish": 20, &"rattata": 10}],
	&"route_35_grass_day": [[&"morning", &"day"], [13, 16], {&"nidoran_f": 15, &"nidoran_m": 15,
		&"pidgey": 20, &"marill": 20, &"abra": 15, &"sentret": 15}],
	&"route_35_grass_night": [[&"night"], [13, 16], {&"hoothoot": 30, &"nidoran_f": 15,
		&"nidoran_m": 15, &"oddish": 20, &"marill": 20}],
	&"route_35_surf": [[], [13, 17], {&"poliwag": 60, &"marill": 40}],
}

var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary
var _pokemon: PokemonData
var _trainers: TrainerLibrary
var _encounters: EncounterLibrary


func before_all() -> void:
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_pokemon = PokemonData.new()
	_pokemon.load_dir()
	_trainers = TrainerLibrary.new(_pokemon)
	_trainers.load_dir()
	_encounters = EncounterLibrary.new(_pokemon)
	_encounters.load_dir()


func _ids(dir: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(J22Ids.in_dir(dir, PREFIX).keys())
	ids.sort()
	return ids


func _flags(raised: Array[StringName] = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in raised:
		flags.set_flag(flag)
	return flags


func _pick(id: StringName, flags: StoryFlags, weekday: StringName = &"",
		lead: int = BondReader.NONE) -> DialogueVariant:
	return _dialogues.get_dialogue(id).pick(flags, null, 0, Callable(), Callable(), Callable(),
		&"day" if not weekday.is_empty() else &"", weekday, 0, lead)


## Accords de la joueuse (JR-7) ramenés à leur forme masculine, celle du dossier.
func _masculine(text: String) -> String:
	var regex := RegEx.create_from_string("\\{g:([^|}]*)\\|[^}]*\\}")
	return regex.sub(text, "$1", true)


func test_libraries_load_without_error() -> void:
	assert_eq(_dialogues.get_errors(), PackedStringArray())
	assert_eq(_cutscenes.get_errors(), PackedStringArray())
	assert_eq(_trainers.get_errors(), PackedStringArray())
	assert_eq(_encounters.get_errors(), PackedStringArray())
	assert_gt(_ids("res://data/dialogues/").size(), 50)


## Chaque réplique non marquée « draft » est dans le dossier joh-04 §16, mot pour mot (le panneau
## de la promotion, à jeton {article}, est vérifié à part).
func test_every_validated_line_is_in_dossier_joh_04() -> void:
	var dossier := J22Ids.flat_text(FileAccess.get_file_as_string(DOSSIER))
	dossier = dossier.replace("{joueur}", "{player}")
	for path: String in KANTO_DOSSIERS:
		dossier += " " + J22Ids.flat_text(FileAccess.get_file_as_string(path))
	var checked := 0
	for id: StringName in _ids("res://data/dialogues/"):
		if id == &"goldenrod_dept_board":
			continue
		var dialogue := _dialogues.get_dialogue(id)
		if dialogue.draft:
			continue
		for variant: DialogueVariant in dialogue.variants:
			if variant.draft:
				continue
			for page: DialoguePage in variant.pages:
				checked += 1
				assert_true(dossier.contains(J22Ids.flat_text(_masculine(page.text))),
					"%s : « %s » (dossier joh-04 §16)" % [id, page.text])
	assert_gt(checked, 100)


## D-21 : un article par jour (§8.2), le même que la promotion de la Boutique.
func test_the_promotion_board_follows_the_day() -> void:
	var expected := {&"monday": "Poké Ball", &"tuesday": "Potion et Super Potion",
		&"wednesday": "Super Ball", &"thursday": "Repousse et Super Repousse",
		&"friday": "Rappel", &"saturday": "Total Soin", &"sunday": "boissons du toit"}
	for day: StringName in expected:
		var text := J22Ids.flat_text(_pick(&"goldenrod_dept_board", _flags(), day).pages[0].text)
		assert_eq(text, "PROMOTION DU JOUR Aujourd'hui, %s à moitié prix !" % expected[day],
			String(day))


func test_every_scene_is_launched_and_every_dialogue_used() -> void:
	var launched: Dictionary = {}
	var used: Dictionary = {}
	for id: StringName in _dialogues.get_ids():
		for variant: DialogueVariant in _dialogues.get_dialogue(id).variants:
			if not variant.cutscene.is_empty():
				launched[variant.cutscene] = true
	for id: StringName in _cutscenes.get_dialogue_ids():
		used[id] = true
	for map_id: StringName in MAPS:
		var map := (load("res://game/world/maps/%s.tscn" % map_id) as PackedScene).instantiate()
		for point: Node in map.get_node(^"Triggers").get_children():
			launched[(point as EventTriggerPoint).cutscene_id] = true
		for point: Node in map.get_node(^"Interactables").get_children():
			var dialogue: StringName = point.get(&"dialogue_id")
			used[dialogue] = true
			assert_true(_dialogues.has_dialogue(dialogue), "%s : %s" % [map_id, dialogue])
		map.free()
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			if not spec.dialogue.is_empty():
				used[spec.dialogue] = true
				assert_true(_dialogues.has_dialogue(spec.dialogue), "%s : %s" % [map_id,
					spec.dialogue])
			if not spec.trainer_id.is_empty():
				used[spec.before_dialogue] = true
				used[spec.defeated_dialogue] = true
	# D-18, D-19 : joués par le hall de la Tour Radio (JOH5).
	used[&"goldenrod_radio_tower_impostor_closed"] = true
	used[&"goldenrod_radio_tower_elevator_closed"] = true
	for id: StringName in _ids("res://data/cutscenes/"):
		assert_true(launched.has(id), "scène « %s » lancée" % id)
	for id: StringName in _ids("res://data/dialogues/"):
		assert_true(used.has(id) or launched.has(id), "dialogue « %s » utilisé" % id)


func test_trainers_follow_dossier_6() -> void:
	var placed: Dictionary = {}
	for map_id: StringName in [&"route_37", &"route_36", &"route_35", &"goldenrod_underground"]:
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			if not spec.trainer_id.is_empty():
				placed[spec.trainer_id] = spec
	assert_eq(placed.size(), TRAINERS.size())
	for id: StringName in TRAINERS:
		assert_true(placed.has(id), String(id))
		assert_true(_trainers.has_trainer(id), String(id))
		if not _trainers.has_trainer(id):
			continue
		var trainer := _trainers.get_trainer(id)
		assert_eq(trainer.name, TRAINERS[id][0])
		var team: Array = []
		for member: Variant in trainer.team:
			team.append([member.species, member.level])
		assert_eq(team, TRAINERS[id][1], String(id))
	# Sbires de la Route 37 : la nuit seulement (JH-31) ; les autres à toute heure.
	for id: StringName in placed:
		var spec: NpcSpec = placed[id]
		var night := id == &"route_37_grunt_a" or id == &"route_37_grunt_b"
		assert_eq(spec.if_periods, ([&"night"] if night else []) as Array[StringName], String(id))
	# Anna garde le passage du poste (inévitable, grille).
	var anna: NpcSpec = placed[&"route_35_camper_anna"]
	assert_eq([anna.cell, anna.facing, anna.sight], [Vector2i(12, 38), Vector2i.LEFT, 1])


## JH-31 : l'indice vient du chef, après le combat, chaque fois qu'on lui parle ; l'agent de la
## sortie sud se range ensuite.
func test_the_clue_opens_the_south_exit() -> void:
	var clue := _pick(&"goldenrod_underground_boss_after", _flags())
	assert_eq(clue.set_flags, [&"johto_azalea_clue"] as Array[StringName])
	assert_eq(clue.pages.size(), 4)
	assert_string_contains(_pick(&"goldenrod_city_agent", _flags()).pages[0].text, "Pas aujourd'hui")
	assert_string_contains(_pick(&"goldenrod_city_agent", _flags([&"johto_azalea_clue"])).pages[1].text,
		"La route du sud est ouverte")
	var roster := NpcRoster.load_for_map(&"goldenrod_city")
	assert_eq(roster.get_spec(&"agent_sud").unless_flags, [&"johto_azalea_clue"] as Array[StringName])
	assert_eq(roster.get_spec(&"agent_range").if_flags, [&"johto_azalea_clue"] as Array[StringName])
	assert_eq(roster.get_spec(&"agent_range").cell, Vector2i(33, 55))
	var guard := _cutscenes.get_cutscene(&"goldenrod_south_guard")
	assert_eq(guard.variants[0].unless_flags, [&"johto_azalea_clue"] as Array[StringName])


func test_orme_gives_the_egg_or_keeps_it() -> void:
	var first := _pick(&"goldenrod_orme", _flags())
	assert_eq(first.cutscene, &"goldenrod_orme_egg")
	assert_eq(first.set_flags, [&"johto_goldenrod_orme_met"] as Array[StringName])
	var again := _pick(&"goldenrod_orme", _flags([&"johto_goldenrod_orme_met"]))
	assert_eq(again.cutscene, &"goldenrod_orme_egg", "équipe pleine : il le redonne")
	var after := _pick(&"goldenrod_orme", _flags([&"johto_goldenrod_orme_met",
		&"johto_egg_received"]))
	assert_string_contains(after.pages[0].text, "Fais attention à toi")
	var egg: CutsceneStep = null
	for step: CutsceneStep in _cutscenes.get_cutscene(&"goldenrod_orme_egg").variants[0].steps:
		if step.kind == CutsceneStep.Kind.GIVE_EGG:
			egg = step
	assert_not_null(egg)
	if egg != null:
		assert_eq([egg.species, egg.count, egg.gift_flag, egg.dialogue_stored],
			[&"togepi", 2000, &"johto_egg_received", &"goldenrod_orme_full"])


func test_clemence_reads_the_lead_bond() -> void:
	assert_string_contains(_pick(&"goldenrod_bond_house_clemence", _flags(), &"",
		BondReader.EGG).pages[0].text, "Un œuf")
	var lines := ["Il ne te connaît pas encore", "Il commence à t'apprécier",
		"Il t'aime beaucoup", "Je n'ai jamais vu un lien pareil"]
	for tier: int in 4:
		var variant := _pick(&"goldenrod_bond_house_clemence", _flags(), &"", tier)
		assert_eq(variant.pages.size(), 6, "D-24, palier, D-26")
		assert_string_contains(variant.pages[3].text, lines[tier])


func test_items_and_gifts_once() -> void:
	for id: StringName in GIFTS:
		var cutscene := _cutscenes.get_cutscene(id)
		assert_not_null(cutscene, String(id))
		if cutscene == null:
			continue
		var variant: CutsceneVariant = cutscene.variants[0]
		assert_eq(variant.unless_flags, [GIFTS[id][2]] as Array[StringName], String(id))
		var gave := false
		for step: CutsceneStep in variant.steps:
			if step.kind == CutsceneStep.Kind.GIVE:
				gave = true
				assert_eq([step.item_id, step.count], [GIFTS[id][0], GIFTS[id][1]], String(id))
		assert_true(gave, String(id))
	# PNJ de la semaine : leur jour seulement (NpcSpec.if_weekdays).
	var mercedes := NpcRoster.load_for_map(&"route_36").get_spec(&"mercedes")
	assert_eq(mercedes.if_weekdays, [&"wednesday"] as Array[StringName])
	var jerome := NpcRoster.load_for_map(&"goldenrod_city").get_spec(&"jerome")
	assert_eq(jerome.if_weekdays, [&"thursday"] as Array[StringName])


func test_encounter_tables_by_period() -> void:
	for id: StringName in TABLES:
		var table := _encounters.get_table_by_id(id)
		assert_not_null(table, String(id))
		if table == null:
			continue
		assert_eq(table.periods, TABLES[id][0] as Array[StringName], String(id))
		var weights: Dictionary = TABLES[id][2]
		assert_eq(table.total_weight(), 100, String(id))
		for slot: EncounterSlot in table.slots:
			assert_eq(slot.weight, weights.get(slot.species, 0), "%s : %s" % [id, slot.species])
			assert_eq([slot.min_level, slot.max_level], TABLES[id][1], "%s : %s" % [id, slot.species])
		assert_eq(table.slots.size(), weights.size(), String(id))
	assert_eq(_encounters.get_table(&"route_36", &"grass", &"morning").id, &"route_36_grass_morning")
	assert_eq(_encounters.get_table(&"route_36", &"grass", &"day").id, &"route_36_grass_day")
	assert_eq(_encounters.get_table(&"route_37", &"grass", &"night").id, &"route_37_grass_night")
	assert_eq(_encounters.get_table(&"route_35", &"water", &"night").id, &"route_35_surf",
		"étang : toute la journée")
	var rods := WaterRodTables.new(_pokemon)
	assert_true(rods.load_game_files(), str(rods.get_errors()))
	var super_rod := rods.get_table(&"super_rod", &"route_35")
	var species: Array = []
	for slot: EncounterSlot in super_rod.slots:
		species.append(slot.species)
	assert_eq(species, [&"poliwag", &"goldeen"], "Super Canne : Ptitard, Poissirène")
