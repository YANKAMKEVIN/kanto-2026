extends GutTest
## Arc des Pierres, JOHP3 (`docs/tech/jalon-joh-pierres.md` §5) : données générées depuis les
## grilles (`tools/gen_johp3_data.py`) : textes du dossier JOH-11 §17 mot pour mot, Dresseurs §10,
## rencontres §11, objets §12, enchaînement de l'autel, départs de débogage. Les grands registres
## écartent les fichiers `johp3_*` (préfixe dans `j22_ids.gd`).

const J22Ids := preload("res://tests/helpers/j22_ids.gd")

const PREFIX := "johp3_"
const DOSSIER := "res://docs/design/dossier-joh-11-arc-pierres.md"
## Dossier §10 : Dresseur → (nom, équipe).
const TRAINERS: Dictionary = {
	&"blackthorn_apprentice_nolwenn": ["Apprentie Nolwenn", [[&"dratini", 36], [&"seadra", 36]]],
	&"blackthorn_apprentice_malo": ["Apprenti Malo", [[&"dragonair", 37], [&"gyarados", 36]]],
	&"blackthorn_hiker_herve": ["Montagnard Hervé", [[&"graveler", 37], [&"onix", 37]]],
	&"den_grunt_ab": ["Sbire Rocket", [[&"houndoom", 37], [&"weezing", 37]]],
	&"den_grunt_ac": ["Sbire Rocket", [[&"raticate", 38], [&"noctowl", 38]]],
	&"den_guardian_water": ["Gardienne de l'Eau", [[&"seadra", 38], [&"dewgong", 38],
		[&"dragonair", 39]]],
	&"den_guardian_stone": ["Gardien de la Pierre", [[&"golem", 39], [&"onix", 39],
		[&"dragonair", 39]]],
	&"den_guardian_sky": ["Gardien du Ciel", [[&"fearow", 40], [&"noctowl", 40],
		[&"dragonair", 40]]],
	&"den_ysolde": ["Ysolde", [[&"gyarados", 42], [&"dragonair", 42], [&"dragonair", 43],
		[&"kingdra", 43], [&"dragonite", 45]]],
	# Farfuret d'abord [D] : « Recommence, Farfuret » (P-32).
	&"den_cenere": ["Cenere", [[&"sneasel", 61], [&"weezing", 59], [&"wobbuffet", 59],
		[&"noctowl", 60]]],
}
## Dossier §11 : table → (moments, terrain, niveaux, poids par espèce).
const TABLES: Dictionary = {
	&"blackthorn_city_grass_day": [[&"morning", &"day"], &"grass", [33, 37], {&"machoke": 25,
		&"graveler": 25, &"fearow": 25, &"marill": 25}],
	&"blackthorn_city_grass_night": [[&"night"], &"grass", [33, 37], {&"noctowl": 35,
		&"graveler": 30, &"golbat": 35}],
	&"dragons_den_rubble": [[], &"rubble", [34, 38], {&"dratini": 45, &"dragonair": 10,
		&"magikarp": 25, &"horsea": 20}],
}
## Dossier §12 : scène → (objet, drapeau).
const GIFTS: Dictionary = {
	&"den_item_1": [&"tm13", &"got_den_item_1"],
	&"den_hidden_1": [&"rare_candy", &"got_den_hidden_1"],
	&"blackthorn_house_item": [&"max_repel", &"got_blackthorn_house_item"],
}
const DEBUG_STARTS: Array[String] = ["johto_rosalia_corentin", "johto_blackthorn", "johto_den_1f",
	"johto_den_sanctuary", "johto_den_altar", "johto_den_cenere"]

var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary
var _pokemon: PokemonData
var _items: ItemLibrary
var _trainers: TrainerLibrary
var _encounters: EncounterLibrary


func before_all() -> void:
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_pokemon = PokemonData.new()
	_pokemon.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()
	_trainers = TrainerLibrary.new(_pokemon)
	_trainers.load_dir()
	_encounters = EncounterLibrary.new(_pokemon)
	_encounters.load_dir()


func _ids() -> Array[StringName]:
	var library := DialogueLibrary.new()
	assert_true(library.load_file("res://data/dialogues/%sblackthorn.json" % PREFIX))
	return library.get_ids()


func _variant_steps(scene: StringName, index: int) -> Array[CutsceneStep]:
	return _cutscenes.get_cutscene(scene).variants[index].steps


func _kinds(steps: Array[CutsceneStep]) -> Array:
	var kinds: Array = []
	for step: CutsceneStep in steps:
		kinds.append(step.kind)
	return kinds


func test_libraries_load_without_error() -> void:
	assert_eq(_dialogues.get_errors(), PackedStringArray())
	assert_eq(_cutscenes.get_errors(), PackedStringArray())
	assert_eq(_trainers.get_errors(), PackedStringArray())


func test_every_validated_line_is_in_dossier_joh_11() -> void:
	var corpus := J22Ids.flat_text(FileAccess.get_file_as_string(DOSSIER))
	var checked := 0
	for id: StringName in _ids():
		var dialogue := _dialogues.get_dialogue(id)
		for variant: DialogueVariant in dialogue.variants:
			if variant.draft:
				continue
			for page: DialoguePage in variant.pages:
				var text := page.text.replace("{player}", "{joueur}") \
					.replace("{returning_pokemon}", "{pokemon}") \
					.replace("{lead_pokemon}", "{pokemon}")
				checked += 1
				assert_true(corpus.contains(J22Ids.flat_text(text)),
					"%s : « %s » dans le dossier" % [id, text])
	assert_gt(checked, 60, "textes P-20 à P-56")


func test_trainers_follow_dossier_10() -> void:
	for id: StringName in TRAINERS:
		var trainer := _trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq(trainer.name, TRAINERS[id][0], String(id))
		var team: Array = []
		for member: Variant in trainer.team:
			team.append([member.species, member.level])
		assert_eq(team, TRAINERS[id][1], "%s : équipe du §10" % id)


## Décision de Kevin du 2026-11-05 : attaques et niveaux [D] contre l'équipe mixte (plan §5.5).
func test_act_2_bosses_gain_moves_and_levels() -> void:
	for id: StringName in [&"mahogany_hideout_b3f_brace", &"whirl_islands_cenere"]:
		var trainer := _trainers.get_trainer(id)
		assert_true(trainer.can_switch, String(id))
		var with_moves := 0
		for member: Variant in trainer.team:
			if not member.moves.is_empty():
				with_moves += 1
		assert_gte(with_moves, 3, String(id))
	var levels: Array = []
	for member: Variant in _trainers.get_trainer(&"whirl_islands_cenere").team:
		levels.append(member.level)
	assert_eq(levels, [64, 64, 64, 65, 66], "en dessous de Dante (1)")
	levels.clear()
	for member: Variant in _trainers.get_trainer(&"mahogany_hideout_b3f_brace").team:
		levels.append(member.level)
	assert_eq(levels, [63, 63, 64, 65])


func test_encounter_tables_follow_dossier_11() -> void:
	for id: StringName in TABLES:
		var table := _encounters.get_table_by_id(id)
		assert_not_null(table, String(id))
		if table == null:
			continue
		assert_eq(table.periods, TABLES[id][0] as Array[StringName], String(id))
		assert_eq(table.terrain, TABLES[id][1], String(id))
		var weights: Dictionary = TABLES[id][3]
		assert_eq(table.total_weight(), 100, String(id))
		assert_eq(table.slots.size(), weights.size(), String(id))
		for slot: EncounterSlot in table.slots:
			assert_eq(slot.weight, weights.get(slot.species, 0), "%s : %s" % [id, slot.species])
			assert_eq([slot.min_level, slot.max_level], TABLES[id][2], "%s : %s" % [id, slot.species])
	assert_null(_encounters.get_table(&"dragons_den_sanctuary", &"rubble", &"day"),
		"pas de rencontre au Sanctuaire")


func test_items_of_dossier_12_are_given_once() -> void:
	for scene: StringName in GIFTS:
		var variant := _cutscenes.get_cutscene(scene).variants[0]
		assert_true(variant.unless_flags.has(GIFTS[scene][1]), "%s : une seule fois" % scene)
		var given := false
		for step: CutsceneStep in variant.steps:
			if step.kind == CutsceneStep.Kind.GIVE:
				given = step.item_id == GIFTS[scene][0]
		assert_true(given, "%s : %s" % [scene, GIFTS[scene][0]])


## Dossier §13, §14 : Cenere frappe, le Réveil écrit, puis Cenere et le retour, une écriture.
func test_altar_scene_order() -> void:
	var altar := _cutscenes.get_cutscene(&"dragons_den_altar")
	assert_eq(altar.variants.size(), 3, "première fois, reprise à Cenere, reprise au retour")
	var first := _kinds(_variant_steps(&"dragons_den_altar", 0))
	var awaken := first.find(CutsceneStep.Kind.STONES_AWAKEN)
	var battle := first.find(CutsceneStep.Kind.BATTLE)
	var back := first.find(CutsceneStep.Kind.RETURN_TEAM)
	var save := first.find(CutsceneStep.Kind.SAVE)
	assert_gt(awaken, -1, "le Réveil")
	assert_gt(battle, awaken, "Cenere se bat après le Réveil (JH-74)")
	assert_gt(back, battle, "la mallette après Cenere")
	assert_gt(save, back, "écriture après le retour")
	assert_eq(first.count(CutsceneStep.Kind.SAVE), 1, "une seule écriture du retour")
	var resume := _kinds(_variant_steps(&"dragons_den_altar", 1))
	assert_eq(resume.find(CutsceneStep.Kind.STONES_AWAKEN), -1, "pas de second Réveil")
	assert_gt(resume.find(CutsceneStep.Kind.BATTLE), -1)
	var last := _kinds(_variant_steps(&"dragons_den_altar", 2))
	assert_eq(last.find(CutsceneStep.Kind.BATTLE), -1, "Cenere déjà battue")
	assert_gt(last.find(CutsceneStep.Kind.RETURN_TEAM), -1)


func test_flight_scenes_keep_the_arc_flags_in_order() -> void:
	var flags := StoryFlags.new()
	var bag := Bag.new()
	var out := _cutscenes.get_cutscene(&"johto_corentin_flight")
	assert_same(out.pick(flags, bag), out.variants[1], "premier vol : P-20, P-21")
	flags.set_flag(&"johto_clan_called")
	assert_same(out.pick(flags, bag), out.variants[2], "ensuite : P-56")
	flags.set_flag(&"johto_team_returned")
	assert_same(out.pick(flags, bag), out.variants[0], "rentré par son Vol : `johto_act2` ici aussi")
	var back := _cutscenes.get_cutscene(&"blackthorn_corentin_back")
	assert_same(back.pick(flags, bag), back.variants[0], "P-52, P-38")
	flags.set_flag(&"johto_act2")
	assert_same(back.pick(flags, bag), back.variants[1], "JH-79 : le vol reste ouvert")


func test_elder_speaks_of_the_stones_during_the_arc_only() -> void:
	var doyen := _dialogues.get_dialogue(&"ecruteak_elders_house_doyen")
	var flags := StoryFlags.new()
	flags.set_flag(&"johto_tower_legend_heard")
	flags.set_flag(&"johto_stones_quest")
	assert_eq(doyen.pick(flags).pages[0].text, "Les pierres ? Une vieille histoire.", "P-54")
	flags.set_flag(&"johto_act2")
	assert_ne(doyen.pick(flags).pages[0].text, "Les pierres ? Une vieille histoire.")


func test_debug_starts_load() -> void:
	for name: String in DEBUG_STARTS:
		var start := DebugStart.new()
		assert_true(start.load_file("res://tools/debug_start/%s.json" % name, _pokemon, _items),
			"%s : %s" % [name, "\n".join(start.get_errors())])


func test_zone_texts_and_world_data() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.get_zone(&"blackthorn_city").description,
		"Un village perché, au pays des dragons.", "P-40")
	assert_eq(zones.get_zone(&"dragons_den").description,
		"Là où le clan des dragons met ses enfants à l'épreuve.", "P-40")
	var rest := JSON.parse_string(FileAccess.get_file_as_string("res://data/world/rest_points.json")) as Dictionary
	assert_true((rest["points"] as Dictionary).has("blackthorn_center"), "point de repos « Ébènelle »")
	var fly := FileAccess.get_file_as_string("res://data/world/fly_points.json")
	assert_true(fly.contains("\"spawn\": \"from_dragon\""), "point de Vol (JH-76)")
