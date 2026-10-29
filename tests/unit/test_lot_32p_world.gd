extends GutTest
## Lot 32P (données du monde) : objets de Rouge/Bleu remis à leur place (Max Éther de l'Écume B3F,
## Max Repousse de la Route 21), boutiques de Repousses et de vitamines, assistants de Chen du
## Cherch'Objet (Route 12, 30 espèces) et du Multi Exp (Route 15, 50 espèces).

var _cutscenes: CutsceneLibrary
var _dialogues: DialogueLibrary
var _shops: ShopLibrary


func before_all() -> void:
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()
	_shops = ShopLibrary.new()
	_shops.load_dir()


func _given(scene: StringName) -> Array[StringName]:
	var given: Array[StringName] = []
	for step: CutsceneStep in _cutscenes.get_cutscene(scene).variants[0].steps:
		if step.kind == CutsceneStep.Kind.GIVE:
			given.append(step.item_id)
	return given


func test_placed_items_give_the_red_blue_object_once() -> void:
	for pair: Array in [[&"seafoam_b3f_hidden_1", &"max_ether"], [&"route_21_item_2", &"max_repel"]]:
		var cutscene := _cutscenes.get_cutscene(pair[0])
		assert_not_null(cutscene, String(pair[0]))
		assert_eq(_given(pair[0]), [pair[1]] as Array[StringName], String(pair[0]))
		assert_eq(cutscene.variants[0].unless_flags,
			[StringName("got_" + String(pair[0]))] as Array[StringName])


func test_undone_fallbacks_give_the_red_blue_object() -> void:
	for pair: Array in [[&"silph_co_5f_item_7", &"protein"], [&"silph_co_5f_hidden_1", &"elixir"],
			[&"silph_co_7f_item_10", &"calcium"], [&"rocket_hideout_b1f_item_2", &"hyper_potion"],
			[&"rocket_hideout_b1f_hidden_1", &"pp_up"], [&"rocket_hideout_b4f_item_2", &"hp_up"],
			[&"rocket_hideout_b4f_item_3", &"iron"], [&"pokemon_mansion_1f_item_2", &"carbos"],
			[&"pokemon_mansion_2f_item_1", &"calcium"], [&"pokemon_mansion_3f_item_2", &"iron"],
			[&"safari_zone_east_carbone", &"carbos"], [&"safari_zone_north_proteine", &"protein"],
			[&"tower_4f_objet_2", &"elixir"], [&"tower_5f_cache_1", &"elixir"],
			[&"celadon_hidden_1", &"pp_up"]]:
		assert_eq(_given(pair[0]), [pair[1]] as Array[StringName], String(pair[0]))


func test_repel_and_vitamin_shops() -> void:
	var expected := {&"cerulean_mart": &"repel", &"vermilion_mart": &"repel",
		&"lavender_mart": &"super_repel", &"celadon_dept_2f": &"super_repel",
		&"saffron_mart": &"max_repel", &"fuchsia_mart": &"max_repel",
		&"cinnabar_mart": &"max_repel", &"indigo_plateau_lobby": &"max_repel"}
	for shop_id: StringName in expected:
		assert_true(_shops.get_shop(shop_id).item_ids().has(expected[shop_id]), String(shop_id))
	var floor5 := _shops.get_shop(&"celadon_dept_5f").item_ids()
	for id: StringName in [&"hp_up", &"protein", &"iron", &"carbos", &"calcium"]:
		assert_true(floor5.has(id), "Céladopole 5F : %s" % id)


func _assistant(dialogue: StringName, threshold: int, scene: StringName, item: StringName,
		flag: StringName) -> void:
	var variants := _dialogues.get_dialogue(dialogue).variants
	var gives: DialogueVariant = null
	for variant: DialogueVariant in variants:
		if variant.caught_at_least == threshold and variant.cutscene == scene:
			gives = variant
	assert_not_null(gives, "%s : variante du don à %d espèces" % [dialogue, threshold])
	assert_eq(_given(scene), [item] as Array[StringName])
	var steps := _cutscenes.get_cutscene(scene).variants[0].steps
	var sets_flag := false
	for step: CutsceneStep in steps:
		if step.kind == CutsceneStep.Kind.SET_FLAGS and step.flags.has(flag):
			sets_flag = true
	assert_true(sets_flag, "%s lève %s" % [scene, flag])


func test_chen_assistants_give_at_30_and_50_species() -> void:
	_assistant(&"route_12_gate_2f_assistant", 30, &"route_12_gate_2f_give_itemfinder",
		&"itemfinder", &"got_itemfinder")
	_assistant(&"route_15_gate_2f_assistant", 50, &"route_15_gate_2f_give_exp_all",
		&"exp_all", &"got_exp_all")
