extends GutTest
## Arc des Pierres, JOHP2 (`docs/tech/jalon-joh-pierres.md` §4) : données générées depuis les grilles
## (`tools/gen_johp2_data.py`) : textes du dossier JOH-11 §17 mot pour mot, Dresseurs §10, rencontres
## §11, objets §12, Goulven (P-11, P-12, P-55, sens de la traversée), vannes, scène du socle,
## registres du monde, départs de débogage. Les grands registres écartent les fichiers `johp2_*`
## (préfixe dans `j22_ids.gd`).

const J22Ids := preload("res://tests/helpers/j22_ids.gd")

const PREFIX := "johp2_"
const DOSSIER := "res://docs/design/dossier-joh-11-arc-pierres.md"
const MAPS: Array[StringName] = [&"goeland_deck", &"cianwood_city", &"tide_cave_1f", &"tide_cave_b1f",
	&"cianwood_center", &"cianwood_goulven_house", &"cianwood_house_1", &"olivine_city"]
## Lignes mécaniques, hors du dossier [D] (la tournure du don est celle de T-31).
const MECHANICAL: Array[String] = ["{player} reçoit 3 Ultra Balls !"]
## Dossier §10 : Dresseur → (nom, équipe).
const TRAINERS: Dictionary = {
	&"goeland_sailor_yvon": ["Marin Yvon", [[&"machoke", 33], [&"tentacruel", 33]]],
	&"cianwood_fisher_ronan": ["Pêcheur Ronan", [[&"seadra", 34], [&"tentacruel", 34]]],
	&"cianwood_blackbelt_tanguy": ["Karatéka Tanguy", [[&"machoke", 34], [&"hitmonlee", 34]]],
	&"cianwood_cooltrainer_maelle": ["Topdresseuse Maëlle", [[&"starmie", 35], [&"goldeen", 34]]],
	&"tide_grunt_y": ["Sbire Rocket", [[&"golbat", 34], [&"weezing", 34]]],
	&"tide_grunt_z": ["Sbire Rocket", [[&"raticate", 35], [&"arbok", 35]]],
	&"tide_grunt_aa": ["Sbire Rocket", [[&"houndoom", 36], [&"murkrow", 36]]],
	&"tide_scientist": ["Scientifique Rocket", [[&"electrode", 36], [&"magneton", 36],
		[&"porygon", 35]]],
	&"tide_hold_chief": ["Chef de cale", [[&"muk", 37], [&"noctowl", 37], [&"houndoom", 38]]],
}
const DEBUG_STARTS: Array[String] = ["johto_johp2_olivine_stranger", "johto_johp2_olivine",
	"johto_johp2_deck", "johto_johp2_cianwood", "johto_johp2_cianwood_autosave",
	"johto_johp2_cianwood_night", "johto_johp2_tide_1f", "johto_johp2_tide_b1f", "johto_johp2_chief",
	"johto_johp2_socle", "johto_johp2_return", "johto_johp2_rosalia", "johto_johp2_south_sea"]

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


func _texts(id: StringName, raised: Array[StringName] = []) -> Array[String]:
	var variant := _dialogues.get_dialogue(id).pick(_flags(raised))
	var out: Array[String] = []
	for page: DialoguePage in variant.pages:
		out.append(J22Ids.flat_text(page.text))
	return out


func test_libraries_load_without_error() -> void:
	assert_eq(_dialogues.get_errors(), PackedStringArray())
	assert_eq(_cutscenes.get_errors(), PackedStringArray())
	assert_eq(_trainers.get_errors(), PackedStringArray())
	assert_eq(_encounters.get_errors(), PackedStringArray())
	assert_gt(_ids("res://data/dialogues/").size(), 40)


## Chaque réplique non marquée « draft » est dans le dossier JOH-11 §17, mot pour mot.
func test_every_validated_line_is_in_dossier_joh_11() -> void:
	var dossier := J22Ids.flat_text(FileAccess.get_file_as_string(DOSSIER))
	dossier = dossier.replace("{joueur}", "{player}").replace("*", "")
	var checked := 0
	for id: StringName in _ids("res://data/dialogues/"):
		var dialogue := _dialogues.get_dialogue(id)
		if dialogue.draft:
			continue
		for variant: DialogueVariant in dialogue.variants:
			if variant.draft:
				continue
			for page: DialoguePage in variant.pages:
				if MECHANICAL.has(page.text):
					continue
				checked += 1
				assert_true(dossier.contains(J22Ids.flat_text(page.text)),
					"%s : « %s » (dossier JOH-11 §17)" % [id, page.text])
	assert_gt(checked, 60)


func test_every_scene_is_launched_and_every_dialogue_used() -> void:
	var launched: Dictionary = {}
	var used: Dictionary = {}
	for id: StringName in _dialogues.get_ids():
		for variant: DialogueVariant in _dialogues.get_dialogue(id).variants:
			if not variant.cutscene.is_empty():
				launched[variant.cutscene] = true
			if variant.choice != null and not variant.choice.confirm_cutscene.is_empty():
				launched[variant.choice.confirm_cutscene] = true
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
	used[&"ecruteak_corentin"] = true # Rosalia : hors de MAPS, ouvre la scène du JOHP3
	for id: StringName in _ids("res://data/cutscenes/"):
		assert_true(launched.has(id), "scène « %s » lancée" % id)
	for id: StringName in _ids("res://data/dialogues/"):
		assert_true(used.has(id), "dialogue « %s » utilisé" % id)


func test_trainers_follow_dossier_10() -> void:
	for id: StringName in TRAINERS:
		var trainer := _trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		var expected: Array = TRAINERS[id]
		assert_eq(trainer.name, expected[0], String(id))
		var team: Array = []
		for member: Variant in trainer.team:
			team.append([member.species, member.level])
		assert_eq(team, expected[1], "%s : équipe" % id)


func test_encounter_tables_of_dossier_11() -> void:
	for period: StringName in [&"morning", &"day"]:
		var day := _encounters.get_table(&"cianwood_city", &"grass", period)
		assert_not_null(day, "herbes d'Irisia, %s" % period)
		if day != null:
			assert_eq(day.slots.size(), 4)
			assert_eq(day.slots[0].species, &"pidgeotto")
	var night := _encounters.get_table(&"cianwood_city", &"grass", &"night")
	assert_not_null(night)
	if night != null:
		assert_eq(night.slots[0].species, &"noctowl")
	for map_id: StringName in [&"tide_cave_1f", &"tide_cave_b1f"]:
		assert_not_null(_encounters.get_table(map_id, &"rubble", &"day"), "%s : gravats" % map_id)


func test_goulven_at_olivine_follows_the_story() -> void:
	var dialogue := _dialogues.get_dialogue(&"olivine_goulven")
	assert_eq(_texts(&"olivine_goulven", [&"johto_stones_quest"]),
		["Le Goéland reste à quai.", "Je ne fais pas la traversée pour un inconnu."] as Array[String],
		"P-11 sans la Pierre Mémoire")
	var first := dialogue.pick(_flags([&"johto_stone_memory"]))
	assert_eq(first.cutscene, &"olivine_goulven_depart", "P-12 et le don, une fois")
	var after := dialogue.pick(_flags([&"johto_stone_memory", &"johto_ferry_open"]))
	assert_eq(_texts(&"olivine_goulven", [&"johto_stone_memory", &"johto_ferry_open"]),
		["Irisia ? Toujours.", "La mer ne change pas d'avis, et moi non plus."] as Array[String], "P-55")
	assert_not_null(after.choice, "le joueur peut rester à quai (§6 étape 9)")
	assert_eq(after.choice.confirm_cutscene, &"goeland_board_outbound")


func test_deck_says_p13_only_on_the_first_crossing_and_goes_the_right_way() -> void:
	var dialogue := _dialogues.get_dialogue(&"goeland_goulven")
	var first := dialogue.pick(_flags([&"johto_goeland_outbound"]))
	assert_eq(first.cutscene, &"goeland_to_cianwood")
	assert_eq(first.pages.size(), 3, "P-13")
	var later := dialogue.pick(_flags([&"johto_goeland_outbound",
		&"johto_cianwood_arrived"]))
	assert_eq(later.cutscene, &"goeland_to_cianwood")
	assert_eq(later.pages.size(), 0)
	assert_eq(dialogue.pick(_flags([&"johto_cianwood_arrived"])).cutscene,
		&"goeland_to_olivine", "retour : le drapeau de sens est baissé à Irisia")


func test_valves_raise_their_flag_and_tell_p48() -> void:
	var expected: Array[String] = ["{player} tourne la vanne.", "On entend l'eau bouger, plus bas."]
	assert_eq(_texts(&"tide_cave_b1f_vanne_1"), expected)
	assert_eq(_texts(&"tide_cave_b1f_vanne_2"), expected)
	assert_eq(_dialogues.get_dialogue(&"tide_cave_b1f_vanne_1").pick(_flags()).set_flags,
		[&"johto_tide_valve_1"] as Array[StringName])
	assert_eq(_dialogues.get_dialogue(&"tide_cave_b1f_vanne_2").pick(_flags()).set_flags,
		[&"johto_tide_valves_done"] as Array[StringName])


func test_the_tide_stone_never_enters_the_bag() -> void:
	var cutscene := _cutscenes.get_cutscene(&"tide_cave_socle")
	assert_not_null(cutscene)
	for step: CutsceneStep in cutscene.variants[0].steps:
		assert_ne(step.kind, CutsceneStep.Kind.GIVE, "JH-62 : Cenere la garde")
	assert_eq(cutscene.variants[0].steps[-1].flags, [&"johto_stone_tide_lost"] as Array[StringName],
		"drapeau en dernier : scène interrompue = rejouée")


func test_items_of_dossier_12() -> void:
	var one: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/npcs/tide_cave_1f.json"))
	var b1f: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/npcs/tide_cave_b1f.json"))
	assert_true(one.has("tide_item_1"))
	assert_true(b1f.has("tide_item_2"))
	var potion := _cutscenes.get_cutscene(&"tide_item_1").variants[0].steps
	var candy := _cutscenes.get_cutscene(&"tide_item_2").variants[0].steps
	assert_eq(potion[1].item_id, &"hyper_potion")
	assert_eq(candy[1].item_id, &"rare_candy")
	var depart := _cutscenes.get_cutscene(&"olivine_goulven_depart").variants[0].steps
	assert_eq(depart[1].item_id, &"ultra_ball", "Ultra Ball ×3 à la première traversée")
	assert_eq(depart[1].count, 3)


func test_debug_starts_load() -> void:
	for name: String in DEBUG_STARTS:
		var start := DebugStart.new()
		assert_true(start.load_file("res://tools/debug_start/%s.json" % name, _pokemon, _items),
			"%s : %s" % [name, "\n".join(start.get_errors())])


func test_zone_texts_and_world_data() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.get_zone(&"cianwood_city").description, "Une île de pêcheurs, au bout de la mer.")
	assert_eq(zones.get_zone(&"tide_cave").description,
		"Une grotte que la mer visite deux fois par jour.")
	for id: StringName in [&"goeland_deck", &"cianwood_city", &"cianwood_center", &"tide_cave_b1f"]:
		assert_eq(zones.region_of(id), ZoneData.REGION_JOHTO, String(id))
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	var exit := caves.escape_target(&"tide_cave_b1f")
	assert_not_null(exit, "Corde Sortie permise dans la grotte")
	if exit != null:
		assert_eq([exit.map, exit.spawn], [&"cianwood_city", &"retour_grotte"])
	var rest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/world/rest_points.json"))
	assert_true((rest["points"] as Dictionary).has("cianwood_center"), "point de repos « Irisia »")
	var shops := ShopLibrary.new()
	shops.load_dir()
	assert_true(shops.has_shop(&"cianwood_center"), "le Centre vend le minimum (grille)")
