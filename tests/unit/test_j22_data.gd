extends GutTest
## Jalon 22 : données générées depuis les grilles (`tools/gen_j22_data.py`) et scènes du jalon
## (`data/dialogues/j22_*.json`, `data/cutscenes/j22_*.json`, `data/npcs/` des cartes du J22,
## Dresseurs, rencontres), à part des grands registres des jalons précédents.

const J22Ids := preload("res://tests/helpers/j22_ids.gd")

const MAPS: Array[StringName] = [&"route_12_south", &"route_13", &"route_14", &"route_15",
	&"route_15_gate", &"route_15_gate_2f", &"route_16_west", &"route_16_gate", &"route_17",
	&"route_18", &"route_18_gate", &"fuchsia_city", &"route_12_rod_house", &"route_16_fly_house",
	&"fuchsia_center",
	&"fuchsia_mart", &"fuchsia_meeting_room", &"fuchsia_grandpa_house",
	&"fuchsia_good_rod_house"]
const TRAINER_FILES: Array[String] = ["route_12_sud", "route_13", "route_14", "route_15",
	"route_16_ouest", "route_17", "route_18"]
## Objets du dossier 25 §11 (CT20 → CT09, T10 [D]).
const ITEMS: Dictionary = {
	&"route_12_item_1": &"nugget", &"route_12_hidden_1": &"hyper_potion",
	&"route_13_hidden_1": &"rare_candy", &"route_13_hidden_2": &"hyper_potion",
	&"route_15_item_1": &"tm09", &"route_16_hidden_1": &"hyper_potion",
	&"route_17_hidden_1": &"rare_candy", &"route_17_hidden_2": &"full_restore",
	&"route_17_hidden_3": &"nugget", &"route_17_hidden_4": &"full_restore",
	&"route_17_hidden_5": &"nugget",
}
## Drapeaux du J22 que lit un poste de Safrania : aucun (contrat, plan §2.13).
const J22_FLAGS: Array[String] = ["got_bike_voucher", "got_bicycle", "got_old_rod",
	"got_good_rod", "got_super_rod", "cycling_gate_16_greeted", "cycling_gate_18_greeted",
	"cut_route_16_tree"]

var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary
var _pokemon: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_pokemon = PokemonData.new()
	_pokemon.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func _j22_dialogues() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(J22Ids.in_dir("res://data/dialogues/").keys())
	return ids


func _j22_cutscenes() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(J22Ids.in_dir("res://data/cutscenes/").keys())
	return ids


func test_libraries_load_without_error() -> void:
	assert_eq(_dialogues.get_errors(), PackedStringArray())
	assert_eq(_cutscenes.get_errors(), PackedStringArray())
	assert_gt(_j22_dialogues().size(), 150)
	assert_gt(_j22_cutscenes().size(), 15)


func test_every_line_is_a_validated_text_of_dossier_25() -> void:
	var dossier := J22Ids.flat_text(FileAccess.get_file_as_string(J22Ids.DOSSIER_25))
	var checked := 0
	for id: StringName in _j22_dialogues():
		var dialogue := _dialogues.get_dialogue(id)
		for variant: DialogueVariant in dialogue.variants:
			var pages: Array[DialoguePage] = variant.pages.duplicate()
			if variant.choice != null:
				pages.append_array(variant.choice.confirm_pages + variant.choice.cancel_pages)
			for page: DialoguePage in pages:
				checked += 1
				assert_true(dossier.contains(J22Ids.flat_text(page.text)),
					"%s : « %s » (dossier 25 §16)" % [id, page.text])
	assert_gt(checked, 150)


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
	for id: StringName in _j22_cutscenes():
		assert_true(launched.has(id), "scène « %s » lancée" % id)
	for id: StringName in _j22_dialogues():
		assert_true(used.has(id) or launched.has(id), "dialogue « %s » utilisé" % id)


func test_items_once_and_found() -> void:
	for id: StringName in ITEMS:
		var cutscene := _cutscenes.get_cutscene(id)
		assert_not_null(cutscene, String(id))
		if cutscene == null:
			continue
		assert_eq(cutscene.variants.size(), 1)
		var flag := StringName("got_" + String(id))
		assert_eq(cutscene.variants[0].unless_flags, [flag] as Array[StringName])
		var gives := cutscene.variants[0].steps.filter(func(s: CutsceneStep) -> bool:
			return s.kind == CutsceneStep.Kind.GIVE)
		assert_eq(gives.size(), 1)
		assert_eq((gives[0] as CutsceneStep).item_id, ITEMS[id], String(id))
		assert_true((gives[0] as CutsceneStep).found, "objet trouvé dans le monde")
		assert_true(_items.has_item(ITEMS[id]), String(ITEMS[id]))
		var flags := StoryFlags.new()
		flags.set_flag(flag)
		assert_null(cutscene.pick(flags), "%s : une fois" % id)


func test_forty_trainers_with_known_species_on_the_maps() -> void:
	var trainers := TrainerLibrary.new(_pokemon)
	assert_true(trainers.load_dir(), "\n".join(trainers.get_errors()))
	var placed: Array[StringName] = []
	for map_id: StringName in MAPS:
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			if not spec.trainer_id.is_empty():
				placed.append(spec.trainer_id)
				assert_true(trainers.has_trainer(spec.trainer_id), String(spec.trainer_id))
				assert_true(_dialogues.has_dialogue(spec.before_dialogue))
				assert_true(_dialogues.has_dialogue(spec.defeated_dialogue))
	assert_eq(placed.size(), 40, "dossier 25 §9")
	var ids: Dictionary = {}
	for file: String in TRAINER_FILES:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
			"res://data/trainers/%s.json" % file))
		for id: String in data:
			ids[StringName(id)] = true
	assert_eq(ids.size(), 40)
	for id: StringName in placed:
		assert_true(ids.has(id), String(id))


func test_grass_tables_use_known_species() -> void:
	var library := EncounterLibrary.new(_pokemon)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	for map_id: StringName in [&"route_12_south", &"route_13", &"route_14", &"route_15",
			&"route_16_west", &"route_17", &"route_18"]:
		assert_not_null(library.get_table(map_id, &"grass"), String(map_id))


func test_system_lines_use_the_player_token_only() -> void:
	for id: StringName in [&"j22_got_bike_voucher", &"j22_got_bicycle", &"j22_got_old_rod",
			&"j22_got_good_rod", &"j22_got_super_rod"]:
		var text := _dialogues.get_dialogue(id).variants[0].pages[0].text
		assert_eq(DialogueTokens.tokens_in(text), [DialogueTokens.PLAYER] as Array[StringName],
			String(id))
	var assistant := _dialogues.get_dialogue(&"route_15_gate_2f_assistant").variants[0]
	assert_eq(DialogueTokens.tokens_in(assistant.pages[0].text),
		[DialogueTokens.CAUGHT] as Array[StringName])


func test_saffron_gates_read_no_j22_flag() -> void:
	for path: String in ["res://data/cutscenes/saffron_gates.json",
			"res://data/dialogues/routes_7_8.json", "res://data/npcs/route_7_gate.json",
			"res://data/npcs/route_8_gate.json", "res://data/npcs/route_5_gate.json",
			"res://data/cutscenes/route_5.json"]:
		if not FileAccess.file_exists(path):
			continue
		var text := FileAccess.get_file_as_string(path)
		for flag: String in J22_FLAGS:
			assert_false(text.contains("\"%s\"" % flag), "%s lit %s" % [path, flag])
