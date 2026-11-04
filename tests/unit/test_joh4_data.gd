extends GutTest
## Chapitre Johto, JOH4 (`docs/tech/jalon-joh4.md`) : données générées depuis les grilles
## (`tools/gen_joh4_data.py`) : textes du dossier joh-05 §14 mot pour mot, Dresseurs §6 et Brace,
## objets §7 et objets clés §8, Vincent le vendredi §9 (horloge injectée), rencontres par moment
## §5, ordre Fargas → Brace → papiers → Roche Royale (§4), départs de débogage. Les grands
## registres écartent les fichiers `joh4_*` (préfixe dans `j22_ids.gd`).

const J22Ids := preload("res://tests/helpers/j22_ids.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")

const PREFIX := "joh4_"
const DOSSIER := "res://docs/design/dossier-joh-05-ecorcia.md"
const MAPS: Array[StringName] = [&"route_34", &"ilex_forest", &"azalea_town", &"slowpoke_well_b1f",
	&"slowpoke_well_b2f", &"azalea_center", &"azalea_mart", &"azalea_kurt_house", &"azalea_house_1",
	&"route_34_house"]
## Dossier §6 : Dresseur → (nom, équipe).
const TRAINERS: Dictionary = {
	&"route_34_picnicker_sophie": ["Pique-niqueuse Sophie", [[&"marill", 18], [&"nidoran_f", 18]]],
	&"route_34_pokemaniac_bruno": ["Pokémaniac Bruno", [[&"ditto", 19], [&"slowpoke", 19]]],
	&"route_34_juggler_felix": ["Jongleur Félix", [[&"abra", 18], [&"kadabra", 20]]],
	&"ilex_forest_scout_tom": ["Scout Tom", [[&"paras", 19], [&"caterpie", 18], [&"metapod", 19]]],
	&"ilex_forest_lass_celine": ["Dresseuse Céline", [[&"hoothoot", 20], [&"teddiursa", 20]]],
	&"slowpoke_well_grunt_e": ["Sbire", [[&"raticate", 20], [&"ekans", 20]]],
	&"slowpoke_well_grunt_f": ["Sbire", [[&"koffing", 21], [&"zubat", 20]]],
	&"slowpoke_well_grunt_g": ["Sbire", [[&"houndour", 21], [&"murkrow", 21]]],
}
const BRACE := &"slowpoke_well_admin_brace"
## Dossier §7 et §9 : scène → (objet, nombre, trouvé dans le monde, drapeau).
const GIFTS: Dictionary = {
	&"route_34_item_1": [&"super_potion", 1, true, &"got_route_34_item_1"],
	&"ilex_item_1": [&"repel", 2, true, &"got_ilex_item_1"],
	&"ilex_hidden_1": [&"rare_candy", 1, true, &"got_ilex_hidden_1"],
	&"well_b1f_item_1": [&"great_ball", 2, true, &"got_well_b1f_item_1"],
	&"well_b2f_item_1": [&"escape_rope", 1, true, &"got_well_b2f_item_1"],
	&"slowpoke_well_kings_rock": [&"kings_rock", 1, false, &"johto_slowpoke_well_cleared"],
	&"week_friday_gift": [&"super_repel", 2, false, &"week_friday_gift"],
}
## Dossier §5 : table → (moments, terrain, niveaux, poids par espèce).
const TABLES: Dictionary = {
	&"route_34_grass_day": [[&"morning", &"day"], &"grass", [16, 19], {&"sentret": 25, &"abra": 20,
		&"nidoran_f": 15, &"nidoran_m": 15, &"raticate": 15, &"ditto": 10}],
	&"route_34_grass_night": [[&"night"], &"grass", [16, 19], {&"hoothoot": 35, &"raticate": 25,
		&"ditto": 15, &"nidoran_f": 12, &"nidoran_m": 13}],
	&"ilex_forest_grass_morning": [[&"morning"], &"grass", [17, 20], {&"teddiursa": 25, &"paras": 25,
		&"caterpie": 15, &"weedle": 15, &"heracross": 5, &"oddish": 15}],
	&"ilex_forest_grass_day": [[&"day"], &"grass", [17, 20], {&"paras": 30, &"caterpie": 20,
		&"weedle": 20, &"oddish": 20, &"sentret": 10}],
	&"ilex_forest_grass_night": [[&"night"], &"grass", [17, 20], {&"murkrow": 30, &"noctowl": 15,
		&"hoothoot": 25, &"oddish": 20, &"paras": 10}],
	&"slowpoke_well_rubble": [[], &"rubble", [18, 22], {&"slowpoke": 45, &"zubat": 45, &"geodude": 10}],
	&"slowpoke_well_water": [[], &"water", [18, 22], {&"slowpoke": 70, &"poliwag": 30}],
}
const DEBUG_STARTS: Array[String] = ["johto_route_34", "johto_ilex_morning", "johto_ilex_night",
	"johto_azalea", "johto_kurt_house", "johto_slowpoke_well", "johto_brace", "johto_azalea_after", "johto_azalea_friday"]

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


func _steps(scene: StringName) -> Array[CutsceneStep]:
	var cutscene := _cutscenes.get_cutscene(scene)
	assert_not_null(cutscene, String(scene))
	if cutscene == null:
		return []
	assert_eq(cutscene.variants.size(), 1, "%s : une variante" % scene)
	return cutscene.variants[0].steps


func test_libraries_load_without_error() -> void:
	assert_eq(_dialogues.get_errors(), PackedStringArray())
	assert_eq(_cutscenes.get_errors(), PackedStringArray())
	assert_eq(_trainers.get_errors(), PackedStringArray())
	assert_eq(_encounters.get_errors(), PackedStringArray())
	assert_eq(_items.get_errors(), PackedStringArray())
	assert_gt(_ids("res://data/dialogues/").size(), 50)
	assert_eq(_ids("res://data/cutscenes/").size(), 12)


## Chaque réplique non marquée « draft » est dans le dossier joh-05 §14, mot pour mot.
func test_every_validated_line_is_in_dossier_joh_05() -> void:
	var dossier := J22Ids.flat_text(FileAccess.get_file_as_string(DOSSIER))
	dossier = dossier.replace("{joueur}", "{player}")
	var checked := 0
	for id: StringName in _ids("res://data/dialogues/"):
		var dialogue := _dialogues.get_dialogue(id)
		if dialogue.draft:
			continue
		for variant: DialogueVariant in dialogue.variants:
			if variant.draft:
				continue
			for page: DialoguePage in variant.pages:
				checked += 1
				assert_true(dossier.contains(J22Ids.flat_text(page.text)),
					"%s : « %s » (dossier joh-05 §14)" % [id, page.text])
	assert_gt(checked, 90)


## E-22 : l'Ordre de mission se lit dans le Sac (sa description, plan §2.7) ; signé « D. » seulement.
func test_key_items_and_the_mission_order_text() -> void:
	var dossier := J22Ids.flat_text(FileAccess.get_file_as_string(DOSSIER))
	for id: StringName in [&"mission_order", &"radio_card"]:
		assert_true(_items.has_item(id), String(id))
		assert_eq(_items.get_item(id).category, ItemData.Category.KEY, "%s : objet clé" % id)
	var order := _items.get_item(&"mission_order")
	assert_eq(order.name, "Ordre de mission")
	for line: String in order.description.split("\n"):
		assert_true(dossier.contains(J22Ids.flat_text(line)), "E-22 : « %s »" % line)
	assert_true(order.description.ends_with("— D."), "signé D.")
	assert_false(order.description.contains("Dante"), "le nom de Dante n'est pas dit (§8)")
	assert_eq(_items.get_item(&"radio_card").name, "Carte d'accès")
	assert_true(_items.get_item(&"radio_card").description.contains("Tour Radio de Doublonville"))


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
	for id: StringName in _ids("res://data/cutscenes/"):
		assert_true(launched.has(id), "scène « %s » lancée" % id)
	for id: StringName in _ids("res://data/dialogues/"):
		assert_true(used.has(id) or launched.has(id), "dialogue « %s » utilisé" % id)


func test_trainers_follow_dossier_6() -> void:
	var placed: Dictionary = {}
	for map_id: StringName in [&"route_34", &"ilex_forest", &"slowpoke_well_b1f"]:
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			if not spec.trainer_id.is_empty():
				placed[spec.trainer_id] = spec
	assert_eq(placed.size(), 8)
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
		for suffix: String in ["_before", "_defeated", "_after"]:
			assert_true(_dialogues.has_dialogue(StringName(id + suffix)), id + suffix)
	# Félix garde le passage de la clôture (10, 40) ; le Sbire E, le goulet (15, 4).
	var felix: NpcSpec = placed[&"route_34_juggler_felix"]
	assert_eq([felix.cell, felix.facing, felix.sight], [Vector2i(11, 40), Vector2i.LEFT, 1])
	var grunt_e: NpcSpec = placed[&"slowpoke_well_grunt_e"]
	assert_eq([grunt_e.cell, grunt_e.facing, grunt_e.sight], [Vector2i(15, 3), Vector2i.DOWN, 2])
	# Brace : grand combat lancé par la scène (pas par sa vue) ; niveaux [D] réglés par simulation
	# (24, 24, 26 du dossier → 21, 21, 23 : plan §2.3).
	assert_true(_trainers.has_trainer(BRACE))
	var brace := _trainers.get_trainer(BRACE)
	assert_eq(brace.name, "Brace")
	var team: Array = []
	for member: Variant in brace.team:
		team.append([member.species, member.level])
	assert_eq(team, [[&"murkrow", 21], [&"koffing", 21], [&"houndoom", 23]])
	var spec := NpcRoster.load_for_map(&"slowpoke_well_b2f").get_spec(&"brace")
	assert_not_null(spec)
	if spec != null:
		assert_eq(spec.trainer_id, &"", "Brace n'engage pas par sa vue")
		assert_eq(spec.unless_flags, [&"johto_brace_defeated"] as Array[StringName])


func test_encounter_tables_by_period() -> void:
	for id: StringName in TABLES:
		var table := _encounters.get_table_by_id(id)
		assert_not_null(table, String(id))
		if table == null:
			continue
		assert_eq(table.periods, TABLES[id][0] as Array[StringName], String(id))
		assert_eq(table.terrain, TABLES[id][1], String(id))
		var weights: Dictionary = TABLES[id][3]
		assert_eq(table.total_weight(), 100, String(id))
		for slot: EncounterSlot in table.slots:
			assert_eq(slot.weight, weights.get(slot.species, 0), "%s : %s" % [id, slot.species])
			assert_eq([slot.min_level, slot.max_level], TABLES[id][2], "%s : %s" % [id, slot.species])
		assert_eq(table.slots.size(), weights.size(), String(id))
	# Le matin du Bois (dossier §12) : Teddiursa et Scarhino ; la nuit : Cornèbre et Noarfang.
	assert_eq(_encounters.get_table(&"ilex_forest", &"grass", &"morning").id, &"ilex_forest_grass_morning")
	assert_eq(_encounters.get_table(&"ilex_forest", &"grass", &"day").id, &"ilex_forest_grass_day")
	assert_eq(_encounters.get_table(&"ilex_forest", &"grass", &"night").id, &"ilex_forest_grass_night")
	assert_eq(_encounters.get_table(&"route_34", &"grass", &"morning").id, &"route_34_grass_day")
	assert_eq(_encounters.get_table(&"route_34", &"grass", &"night").id, &"route_34_grass_night")
	# Le puits : toute la journée, sur les gravats et dans l'eau, aux deux niveaux ; Ramoloss
	# capturable (JH-38).
	for map_id: StringName in [&"slowpoke_well_b1f", &"slowpoke_well_b2f"]:
		for period: StringName in [&"morning", &"day", &"night"]:
			assert_eq(_encounters.get_table(map_id, &"rubble", period).id, &"slowpoke_well_rubble")
			assert_eq(_encounters.get_table(map_id, &"water", period).id, &"slowpoke_well_water")
	for id: StringName in TABLES:
		for slot: EncounterSlot in _encounters.get_table_by_id(id).slots:
			assert_true(_pokemon.has_species(slot.species), String(slot.species))


func test_items_and_gifts_once() -> void:
	for id: StringName in GIFTS:
		var cutscene := _cutscenes.get_cutscene(id)
		assert_not_null(cutscene, String(id))
		if cutscene == null:
			continue
		var expected: Array = GIFTS[id]
		var variant := cutscene.variants[0]
		assert_true(variant.unless_flags.has(expected[3]), "%s : une fois" % id)
		var gives := 0
		var sets := false
		for step: CutsceneStep in variant.steps:
			if step.kind == CutsceneStep.Kind.GIVE:
				gives += 1
				assert_eq([step.item_id, step.count, step.found], expected.slice(0, 3), String(id))
				assert_true(_items.has_item(step.item_id), String(step.item_id))
			if step.kind == CutsceneStep.Kind.SET_FLAGS:
				sets = sets or step.flags.has(expected[3])
		assert_eq(gives, 1, String(id))
		assert_true(sets, "%s : drapeau posé" % id)


## Étapes 4 et 5 (dossier §4) : le récit de Fargas (E-11 à E-13), le drapeau avant le changement
## de carte, puis E-14 devant le puits : le Sbire et Fargas descendent.
func test_kurt_tells_the_story_then_goes_down_the_well() -> void:
	var said: Array[StringName] = []
	var despawned: Array[StringName] = []
	var set_index := -1
	var change_index := -1
	var steps := _steps(&"azalea_kurt_story")
	assert_eq(_cutscenes.get_cutscene(&"azalea_kurt_story").variants[0].unless_flags,
		[&"johto_kurt_told"] as Array[StringName])
	for i: int in steps.size():
		var step := steps[i]
		assert_ne(step.kind, CutsceneStep.Kind.BATTLE, "sans combat")
		if step.kind == CutsceneStep.Kind.DIALOGUE:
			said.append(step.dialogue_id)
		if step.kind == CutsceneStep.Kind.DESPAWN:
			despawned.append(step.actor)
		if step.kind == CutsceneStep.Kind.SET_FLAGS and step.flags.has(&"johto_kurt_told"):
			set_index = i
		if step.kind == CutsceneStep.Kind.CHANGE_MAP:
			change_index = i
			assert_eq([step.map_id, step.spawn], [&"azalea_town", &"kurt_scene"])
	assert_eq(said, [&"azalea_kurt_greeting", &"azalea_kurt_story", &"azalea_kurt_leaves",
		&"azalea_well_grunt_flees"] as Array[StringName], "E-11, E-12, E-13, E-14")
	assert_true(set_index >= 0 and set_index < change_index, "drapeau posé avant le changement de carte")
	assert_eq(despawned, [&"sbire_scene", &"fargas_scene"] as Array[StringName])
	# La barrière tombe avec le drapeau ; le Sbire de la ville aussi.
	var guard := _cutscenes.get_cutscene(&"azalea_well_guard")
	assert_eq(guard.variants[0].unless_flags, [&"johto_kurt_told"] as Array[StringName])
	var grunt := NpcRoster.load_for_map(&"azalea_town").get_spec(&"sbire_puits")
	assert_eq(grunt.unless_flags, [&"johto_kurt_told"] as Array[StringName])
	# Fargas : chez lui avant, au B1F pendant, au B2F après Brace, chez lui à la fin.
	var house := NpcRoster.load_for_map(&"azalea_kurt_house")
	assert_eq(house.get_spec(&"fargas").unless_flags, [&"johto_kurt_told"] as Array[StringName])
	assert_eq(house.get_spec(&"fargas_home").if_flags,
		[&"johto_slowpoke_well_cleared"] as Array[StringName])
	var b1f := NpcRoster.load_for_map(&"slowpoke_well_b1f").get_spec(&"fargas_b1f")
	assert_eq([b1f.if_flags, b1f.unless_flags], [[&"johto_kurt_told"] as Array[StringName],
		[&"johto_slowpoke_well_cleared"] as Array[StringName]])
	var after := _dialogues.get_dialogue(&"azalea_kurt_house_fargas_home").pick(_flags(
		[&"johto_slowpoke_well_cleared"]))
	assert_true(after.pages[1].text.contains("Tour Radio"), "E-25")


## Étape 7 (dossier §4) : Brace (E-17), combat, puis E-18 à E-20 et fuite si victoire ; réveil au
## Centre sinon. Les papiers donnent les deux objets clés (E-21) ; Fargas la Roche Royale.
func test_brace_scene_then_papers_then_kings_rock() -> void:
	var steps := _steps(&"slowpoke_well_brace")
	assert_eq(_cutscenes.get_cutscene(&"slowpoke_well_brace").variants[0].unless_flags,
		[&"johto_brace_defeated"] as Array[StringName])
	var order: Array = []
	for step: CutsceneStep in steps:
		match step.kind:
			CutsceneStep.Kind.DIALOGUE:
				order.append(step.dialogue_id)
			CutsceneStep.Kind.BATTLE:
				order.append(&"battle")
				assert_eq(step.trainer_id, BRACE)
				assert_eq(step.win_flags, [&"johto_brace_defeated"] as Array[StringName])
			CutsceneStep.Kind.WAKE_UP:
				order.append(&"wake_up")
				assert_eq(step.unless_flags, [&"johto_brace_defeated"] as Array[StringName])
			CutsceneStep.Kind.SPAWN:
				order.append(step.actor)
	assert_eq(order, [&"slowpoke_well_brace_before", &"battle", &"slowpoke_well_brace_defeated",
		&"slowpoke_well_brace_after", &"slowpoke_well_brace_flees", &"wake_up", &"papiers",
		&"fargas_b2f"])
	var gives: Array = []
	for step: CutsceneStep in _steps(&"slowpoke_well_papers"):
		if step.kind == CutsceneStep.Kind.GIVE:
			gives.append(step.item_id)
	assert_eq(gives, [&"mission_order", &"radio_card"])
	assert_eq(_cutscenes.get_cutscene(&"slowpoke_well_papers").variants[0].unless_flags,
		[&"johto_radio_pass"] as Array[StringName])
	var papers := NpcRoster.load_for_map(&"slowpoke_well_b2f").get_spec(&"papiers")
	assert_eq([papers.if_flags, papers.unless_flags], [[&"johto_brace_defeated"] as Array[StringName],
		[&"johto_radio_pass"] as Array[StringName]])
	# Les Ramoloss sans queue partent, ceux d'Écorcia reviennent avec le même drapeau.
	for spec: NpcSpec in NpcRoster.load_for_map(&"slowpoke_well_b2f").get_all():
		if String(spec.id).begins_with("ramoloss"):
			assert_eq(spec.unless_flags, [&"johto_slowpoke_well_cleared"] as Array[StringName])
	var town := 0
	for spec: NpcSpec in NpcRoster.load_for_map(&"azalea_town").get_all():
		if String(spec.id).begins_with("ramoloss"):
			town += 1
			assert_eq(spec.if_flags, [&"johto_slowpoke_well_cleared"] as Array[StringName])
	assert_eq(town, 4, "trois Ramoloss dans les rues et un sur la margelle")
	var townswoman := _dialogues.get_dialogue(&"azalea_town_habitante")
	assert_true(townswoman.pick(_flags()).pages[0].text.begins_with("Tu vois des Ramoloss"), "E-10")
	assert_true(townswoman.pick(_flags([&"johto_slowpoke_well_cleared"])).pages[0].text
		.begins_with("Les Ramoloss sont revenus"), "E-26")


## Vincent (dossier §9), horloge injectée : le vendredi seulement, don une fois.
func test_vincent_on_friday_only() -> void:
	var clock := WorldClock.new()
	var device := FixedClock.new("2026-11-06T15:00:00") # un vendredi
	clock.start_on_device(device)
	assert_eq(clock.weekday_name(), &"friday")
	var vincent := NpcRoster.load_for_map(&"azalea_town").get_spec(&"vincent")
	assert_not_null(vincent)
	assert_eq(vincent.if_weekdays, [&"friday"] as Array[StringName])
	assert_eq(vincent.cell, Vector2i(8, 11))
	assert_true(vincent.is_present(_flags(), clock.period_name(), clock.weekday_name()), "vendredi")
	device.iso = "2026-11-07T15:00:00"
	clock.sync()
	assert_false(vincent.is_present(_flags(), clock.period_name(), clock.weekday_name()), "samedi")
	var dialogue := _dialogues.get_dialogue(&"week_friday_vincent")
	var gift := dialogue.pick(_flags(), null, 0, Callable(), Callable(), Callable(), &"day", &"friday")
	assert_eq(gift.cutscene, &"week_friday_gift")
	var after := dialogue.pick(_flags([&"week_friday_gift"]), null, 0, Callable(), Callable(),
		Callable(), &"day", &"friday")
	assert_eq(after.cutscene, &"")
	assert_eq(after.pages[0].text, "À vendredi !")


func test_debug_starts_load() -> void:
	for name: String in DEBUG_STARTS:
		var start := DebugStart.new()
		assert_true(start.load_file("res://tools/debug_start/%s.json" % name, _pokemon, _items),
			"%s : %s" % [name, "\n".join(start.get_errors())])
	var night := DebugStart.new()
	night.load_file("res://tools/debug_start/johto_ilex_night.json", _pokemon, _items)
	assert_eq(night.period, &"night")
	var friday := DebugStart.new()
	friday.load_file("res://tools/debug_start/johto_azalea_friday.json", _pokemon, _items)
	assert_eq(friday.weekday, &"friday")


func test_zone_texts_and_world_data() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.get_zone(&"route_34").description,
		"Une route le long de la côte, au sud de Doublonville.")
	assert_eq(zones.get_zone(&"ilex_forest").description, "Une forêt ancienne, où le temps semble suspendu.")
	assert_eq(zones.get_zone(&"azalea_town").description, "Une petite ville paisible, au rythme des Ramoloss.")
	assert_eq(zones.get_zone(&"slowpoke_well").description, "Un vieux puits humide, sous la ville.")
	assert_false(zones.get_zone(&"azalea_town").draft, "E-34 validée")
	for id: StringName in [&"route_34", &"ilex_forest", &"azalea_town", &"slowpoke_well_b1f",
			&"slowpoke_well_b2f", &"azalea_kurt_house"]:
		assert_eq(zones.region_of(id), ZoneData.REGION_JOHTO, String(id))
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	var exit := caves.escape_target(&"slowpoke_well_b2f")
	assert_not_null(exit, "Corde Sortie permise au puits")
	if exit != null:
		assert_eq([exit.map, exit.spawn], [&"azalea_town", &"from_well"], "devant le puits (dossier §11)")
	var rest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/world/rest_points.json"))
	assert_true((rest["points"] as Dictionary).has("azalea_center"), "point de repos « Écorcia »")
