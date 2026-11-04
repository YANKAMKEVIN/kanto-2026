extends GutTest
## Chapitre Johto, JOH2 (`docs/tech/jalon-joh2.md`) : données générées depuis les grilles
## (`tools/gen_joh2_data.py`) : textes du dossier joh-03 §13 mot pour mot, Dresseurs §6, objets §7,
## PNJ de la semaine §8 (horloge injectée), rencontres par moment §5, drapeaux §9, départs de
## débogage. Les grands registres écartent les fichiers `joh2_*` (préfixe dans `j22_ids.gd`).

const J22Ids := preload("res://tests/helpers/j22_ids.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")

const PREFIX := "joh2_"
const DOSSIER := "res://docs/design/dossier-joh-03-rosalia.md"
const MAPS: Array[StringName] = [&"route_39", &"route_38", &"ecruteak_city", &"ecruteak_center",
	&"ecruteak_mart", &"ecruteak_elders_house", &"ecruteak_house_1", &"ecruteak_house_2"]
const OLIVINE_NPCS := "res://data/npcs/olivine_city.json"
## Dossier §6 : Dresseur → (classe et prénom, équipe).
const TRAINERS: Dictionary = {
	&"route_39_youngster_hugo": ["Gamin Hugo", [[&"rattata", 6], [&"sentret", 7]]],
	&"route_39_schoolgirl_lina": ["Écolière Lina", [[&"mareep", 8]]],
	&"route_38_birdkeeper_paul": ["Ornithologue Paul", [[&"pidgey", 9], [&"hoothoot", 10]]],
	&"route_38_trainer_ines": ["Dresseuse Inès", [[&"meowth", 10], [&"oddish", 10], [&"mareep", 11]]],
	&"route_38_picnicker_theo": ["Pique-niqueur Théo", [[&"sentret", 11], [&"rattata", 11]]],
}
## Dossier §7 et §8 : scène → (objet, nombre, trouvé dans le monde, drapeau).
const GIFTS: Dictionary = {
	&"route_39_item_1": [&"potion", 1, true, &"got_route_39_item_1"],
	&"route_38_item_1": [&"poke_ball", 2, true, &"got_route_38_item_1"],
	&"route_38_hidden_1": [&"super_potion", 1, true, &"got_route_38_hidden_1"],
	&"ecruteak_house_1_antidote": [&"antidote", 2, false, &"got_ecruteak_house_1_antidote"],
	&"week_monday_gift": [&"super_potion", 3, false, &"week_monday_gift"],
	&"week_tuesday_gift": [&"revive", 2, false, &"week_tuesday_gift"],
}
## Dossier §5 : table → (moments, taux, niveaux, poids par espèce).
const TABLES: Dictionary = {
	&"route_39_grass_day": [[&"morning", &"day"], 25, [4, 7],
		{&"sentret": 30, &"mareep": 30, &"rattata": 18, &"pidgey": 18, &"miltank": 4}],
	&"route_39_grass_night": [[&"night"], 25, [4, 7], {&"hoothoot": 40, &"rattata": 30, &"oddish": 30}],
	&"route_38_grass_day": [[&"morning", &"day"], 25, [7, 11],
		{&"sentret": 30, &"mareep": 25, &"pidgey": 20, &"rattata": 12, &"meowth": 9, &"miltank": 4}],
	&"route_38_grass_night": [[&"night"], 25, [7, 11],
		{&"hoothoot": 40, &"rattata": 30, &"meowth": 20, &"oddish": 10}],
	&"ecruteak_towers_night": [[&"night"], 3, [10, 12], {&"murkrow": 50, &"hoothoot": 50}],
}
const DEBUG_STARTS: Array[String] = ["johto_route_39", "johto_route_39_night", "johto_route_38", "johto_rosalia",
	"johto_rosalia_night", "johto_rosalia_tuesday"]

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


func _step_kinds(steps: Array[CutsceneStep]) -> Array[int]:
	var kinds: Array[int] = []
	for step: CutsceneStep in steps:
		kinds.append(step.kind)
	return kinds


func test_libraries_load_without_error() -> void:
	assert_eq(_dialogues.get_errors(), PackedStringArray())
	assert_eq(_cutscenes.get_errors(), PackedStringArray())
	assert_eq(_trainers.get_errors(), PackedStringArray())
	assert_eq(_encounters.get_errors(), PackedStringArray())
	assert_gt(_ids("res://data/dialogues/").size(), 30)
	assert_eq(_ids("res://data/cutscenes/").size(), 9)


## Chaque réplique non marquée « draft » est dans le dossier joh-03 §13, mot pour mot.
func test_every_validated_line_is_in_dossier_joh_03() -> void:
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
					"%s : « %s » (dossier joh-03 §13)" % [id, page.text])
	assert_gt(checked, 45)


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
	# Lucien (lundi) : PNJ de la carte d'Oliville, posée par le JOH1 (plan §2.6).
	if ResourceLoader.exists(OLIVINE_NPCS) or FileAccess.file_exists(OLIVINE_NPCS):
		var found := false
		for spec: NpcSpec in NpcRoster.load_for_map(&"olivine_city").get_all():
			if spec.dialogue == &"week_monday_lucien":
				found = true
				assert_eq(spec.if_weekdays, [&"monday"] as Array[StringName], "Lucien le lundi")
		assert_true(found, "Lucien, marin du lundi, posé à Oliville (JOH1)")
	used[&"week_monday_lucien"] = true
	for id: StringName in _ids("res://data/cutscenes/"):
		assert_true(launched.has(id), "scène « %s » lancée" % id)
	for id: StringName in _ids("res://data/dialogues/"):
		assert_true(used.has(id) or launched.has(id), "dialogue « %s » utilisé" % id)


func test_five_trainers_follow_dossier_6() -> void:
	var placed: Dictionary = {}
	for map_id: StringName in [&"route_39", &"route_38"]:
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			if not spec.trainer_id.is_empty():
				placed[spec.trainer_id] = spec
	assert_eq(placed.size(), 5)
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
		assert_true(_dialogues.has_dialogue(id + "_before"))
		assert_true(_dialogues.has_dialogue(id + "_defeated"))
		assert_true(_dialogues.has_dialogue(id + "_after"))
	# Inès garde le passage d'une case de la barrière d'arbres (inévitable, grille).
	var ines: NpcSpec = placed[&"route_38_trainer_ines"]
	assert_eq([ines.cell, ines.facing, ines.sight], [Vector2i(42, 14), Vector2i.DOWN, 1])


func test_encounter_tables_by_period() -> void:
	for id: StringName in TABLES:
		var table := _encounters.get_table_by_id(id)
		assert_not_null(table, String(id))
		if table == null:
			continue
		assert_eq(table.periods, TABLES[id][0] as Array[StringName], String(id))
		assert_eq(table.rate, TABLES[id][1], String(id))
		var weights: Dictionary = TABLES[id][3]
		assert_eq(table.total_weight(), 100, String(id))
		var seen: Dictionary = {}
		for slot: EncounterSlot in table.slots:
			assert_true(weights.has(slot.species), "%s : %s" % [id, slot.species])
			assert_eq(slot.weight, weights.get(slot.species, 0), "%s : %s" % [id, slot.species])
			assert_eq([slot.min_level, slot.max_level], TABLES[id][2], "%s : %s" % [id, slot.species])
			seen[slot.species] = true
		assert_eq(seen.size(), weights.size(), String(id))
	# La table du moment (JOH0 §2.5) ; Rosalia n'a rien le matin ni le jour (dossier §5).
	assert_eq(_encounters.get_table(&"route_39", &"grass", &"morning").id, &"route_39_grass_day")
	assert_eq(_encounters.get_table(&"route_39", &"grass", &"day").id, &"route_39_grass_day")
	assert_eq(_encounters.get_table(&"route_39", &"grass", &"night").id, &"route_39_grass_night")
	assert_eq(_encounters.get_table(&"route_38", &"grass", &"night").id, &"route_38_grass_night")
	assert_eq(_encounters.get_table(&"ecruteak_city", &"grass", &"night").id, &"ecruteak_towers_night")
	assert_false(_encounters.has_table(&"ecruteak_city", &"grass", &"day"), "herbe des tours de jour")
	assert_false(_encounters.has_table(&"ecruteak_city", &"grass", &"morning"))
	assert_false(_encounters.has_table(&"ecruteak_city", &"grass"), "aucune table de toute la journée")
	# Chaque espèce sauvage a un sprite de combat (provisoire, `gen_placeholder_battlers_johto.py`).
	for id: StringName in TABLES:
		for slot: EncounterSlot in _encounters.get_table_by_id(id).slots:
			assert_true(_pokemon.has_species(slot.species), String(slot.species))
			for back: bool in [false, true]:
				assert_true(ResourceLoader.exists(BattleArt.placeholder_path(slot.species, back)),
					"%s : sprite %s" % [slot.species, "dos" if back else "face"])


func test_items_and_gifts_once() -> void:
	for id: StringName in GIFTS:
		var cutscene := _cutscenes.get_cutscene(id)
		assert_not_null(cutscene, String(id))
		if cutscene == null:
			continue
		var expected: Array = GIFTS[id]
		assert_eq(cutscene.variants.size(), 1, String(id))
		var variant := cutscene.variants[0]
		assert_eq(variant.unless_flags, [expected[3]] as Array[StringName], "%s : une fois" % id)
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


func test_rockets_flee_without_a_battle() -> void:
	var steps := _steps(&"ecruteak_rockets")
	assert_eq(_cutscenes.get_cutscene(&"ecruteak_rockets").variants[0].unless_flags,
		[&"johto_rosalia_rockets_seen"] as Array[StringName])
	assert_gt(steps.size(), 8)
	if steps.size() < 9:
		return
	assert_eq(steps[0].kind, CutsceneStep.Kind.SET_FLAGS, "drapeau posé en tête (scène interrompue)")
	assert_eq(steps[0].flags, [&"johto_rosalia_rockets_seen"] as Array[StringName])
	var said: Array[StringName] = []
	var moved: Array = []
	var despawned: Array[StringName] = []
	for step: CutsceneStep in steps:
		assert_ne(step.kind, CutsceneStep.Kind.BATTLE, "sans combat")
		assert_ne(step.kind, CutsceneStep.Kind.WILD_BATTLE, "sans combat")
		if step.kind == CutsceneStep.Kind.DIALOGUE:
			said.append(step.dialogue_id)
		if step.kind == CutsceneStep.Kind.MOVE:
			moved.append([step.actor, step.cell])
		if step.kind == CutsceneStep.Kind.DESPAWN:
			despawned.append(step.actor)
	assert_eq(said, [&"ecruteak_rocket_1", &"ecruteak_sage_refuses", &"ecruteak_rocket_2"]
		as Array[StringName], "R-12, R-13, R-14")
	assert_eq(moved, [[&"sbire_1", Vector2i(24, 15)], [&"sbire_2", Vector2i(24, 16)]],
		"fuite vers l'est par l'avenue")
	assert_eq(despawned, [&"sbire_1", &"sbire_2"] as Array[StringName])
	# Les Sbires sont des PNJ de la carte, absents une fois vus ; le sage dit R-15 ensuite.
	var roster := NpcRoster.load_for_map(&"ecruteak_city")
	for id: StringName in [&"sbire_1", &"sbire_2"]:
		assert_eq(roster.get_spec(id).unless_flags, [&"johto_rosalia_rockets_seen"] as Array[StringName])
	var sage := _dialogues.get_dialogue(&"ecruteak_city_sage_tour")
	assert_eq(sage.pick(_flags()).pages[0].text, "Vous n'obtiendrez rien de moi.")
	assert_eq(sage.pick(_flags([&"johto_rosalia_rockets_seen"])).pages[1].text,
		"Va voir notre doyen,\ndans la maison au toit rouge.")


func test_elder_tells_the_legend_once_then_names_ho_oh() -> void:
	var doyen := _dialogues.get_dialogue(&"ecruteak_elders_house_doyen")
	assert_not_null(doyen)
	var first := doyen.pick(_flags())
	assert_eq(first.pages.size(), 8, "R-16 (5 bulles) et R-17 (3 bulles)")
	assert_eq(first.set_flags, [&"johto_tower_legend_heard"] as Array[StringName])
	assert_true(first.pages[0].text.begins_with("Il y a cent cinquante ans"))
	var after := doyen.pick(_flags([&"johto_tower_legend_heard"]))
	assert_eq(after.pages.size(), 2, "R-18")
	assert_true(after.pages[0].text.contains("Ho-Oh"))
	assert_eq(after.set_flags, [] as Array[StringName])


## PNJ de la semaine (dossier §8) avec une horloge injectée : Margot le mardi à Rosalia, Lucien le
## lundi (textes et scène ici, PNJ posé par le JOH1), don une seule fois.
func test_week_npcs_with_an_injected_clock() -> void:
	var clock := WorldClock.new()
	var device := FixedClock.new("2026-11-03T15:00:00") # un mardi
	clock.start_on_device(device)
	assert_eq(clock.weekday_name(), &"tuesday")
	var margot := NpcRoster.load_for_map(&"ecruteak_city").get_spec(&"margot")
	assert_not_null(margot)
	assert_eq(margot.if_weekdays, [&"tuesday"] as Array[StringName])
	assert_eq(margot.dialogue, &"week_tuesday_margot")
	assert_true(margot.is_present(_flags(), clock.period_name(), clock.weekday_name()), "mardi")
	assert_false(margot.is_present(_flags(), &"day", &""), "sans heure (Kanto) : absente")
	device.iso = "2026-11-02T15:00:00" # lundi
	clock.sync()
	assert_eq(clock.weekday_name(), &"monday")
	assert_false(margot.is_present(_flags(), clock.period_name(), clock.weekday_name()), "lundi")
	# Minuit qui passe pendant la partie (dossier §10) : l'horloge suit l'appareil.
	device.iso = "2026-11-02T23:59:50"
	clock.sync()
	assert_eq(clock.weekday_name(), &"monday")
	device.iso = "2026-11-03T00:00:10"
	clock.sync()
	assert_eq(clock.weekday_name(), &"tuesday")
	for entry: Array in [[&"week_tuesday_margot", &"week_tuesday_gift", &"tuesday",
			"Reviens un mardi,\nj'en connais d'autres."],
			[&"week_monday_lucien", &"week_monday_gift", &"monday", "À lundi prochain, peut-être !"]]:
		var dialogue := _dialogues.get_dialogue(entry[0])
		var gift := dialogue.pick(_flags(), null, 0, Callable(), Callable(), Callable(),
			&"day", entry[2])
		assert_eq(gift.cutscene, entry[1], "%s : don" % entry[0])
		assert_eq(gift.pages.size(), 2)
		var after := dialogue.pick(_flags([entry[1]]), null, 0, Callable(), Callable(),
			Callable(), &"day", entry[2])
		assert_eq(after.cutscene, &"", "%s : plus de don" % entry[0])
		assert_eq(after.pages[0].text, entry[3])
	var received := _dialogues.get_dialogue(&"week_tuesday_received").variants[0].pages[0].text
	assert_eq(DialogueTokens.tokens_in(received), [DialogueTokens.PLAYER] as Array[StringName])


func test_forced_weekday_and_debug_starts() -> void:
	var clock := WorldClock.new()
	clock.start_on_device(FixedClock.new("2026-11-04T10:00:00")) # mercredi
	assert_eq(clock.weekday_name(), &"wednesday")
	clock.force_weekday(1)
	assert_eq(clock.weekday_name(), &"tuesday")
	assert_true(clock.is_weekday_forced())
	clock.sync()
	assert_eq(clock.weekday_name(), &"tuesday", "la relecture de l'appareil ne défait pas le jour imposé")
	clock.release_weekday()
	assert_eq(clock.weekday_name(), &"wednesday")
	clock.force_weekday(6)
	clock.stop()
	assert_false(clock.is_weekday_forced(), "l'arrêt libère le jour")
	for name: String in DEBUG_STARTS:
		var start := DebugStart.new()
		assert_true(start.load_file("res://tools/debug_start/%s.json" % name, _pokemon, _items),
			"%s : %s" % [name, "\n".join(start.get_errors())])
		assert_true(start.map in [&"route_39", &"route_38", &"ecruteak_city"], name)
	var tuesday := DebugStart.new()
	tuesday.load_file("res://tools/debug_start/johto_rosalia_tuesday.json", _pokemon, _items)
	assert_eq(tuesday.weekday, &"tuesday")
	var night := DebugStart.new()
	night.load_file("res://tools/debug_start/johto_rosalia_night.json", _pokemon, _items)
	assert_eq(night.period, &"night")
	assert_eq(night.weekday, &"")


func test_zone_texts_and_world_data() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.get_zone(&"route_39").description,
		"Une route de campagne, entre la mer et les prés de la ferme.")
	assert_eq(zones.get_zone(&"route_38").description,
		"Un chemin entre les prés, vers la vieille ville de Rosalia.")
	assert_eq(zones.get_zone(&"ecruteak_city").description, "Une ville ancienne, gardée par deux tours.")
	assert_false(zones.get_zone(&"ecruteak_city").draft, "R-25 validée")
	for id: StringName in [&"route_39", &"route_38", &"ecruteak_city"]:
		assert_eq(zones.region_of(id), ZoneData.REGION_JOHTO, String(id))
	assert_eq(zones.get_zone(&"ecruteak_city").maps.size(), 6)
	var shop: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/shops/ecruteak_mart.json"))
	var stock: Array = shop["ecruteak_mart"]["stock"]
	assert_eq((stock[0] as Dictionary)["item"], "poke_ball", "la Boutique vend des Poké Balls (dossier §10)")
	var rest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/world/rest_points.json"))
	assert_true((rest["points"] as Dictionary).has("ecruteak_center"), "point de repos « Rosalia »")
	var fly: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/world/fly_points.json"))
	var found := false
	for point: Dictionary in fly["points"]:
		if point["zone"] == "ecruteak_city":
			found = true
			assert_eq([point["map"], point["spawn"]], ["ecruteak_city", "from_center"])
	assert_true(found, "point de Vol Rosalia")
