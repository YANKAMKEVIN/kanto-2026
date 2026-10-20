extends GutTest
## Erika et le repaire dans les deux ordres (jalon 20 T21, `jalon-20.md` §5 ; dossier 23 §19) :
## aucun lien entre les deux. Vérifié sur les vraies données :
## - les données de l'Arène (PNJ, dialogues, scènes, arbustes) ne lisent aucun drapeau posé par le
##   Casino ou le repaire, et réciproquement ; les portes de drapeaux (mur coulissant, porte du
##   bureau, arbustes) ne lisent que leur propre drapeau ;
## - l'ascenseur du repaire ne demande que la Clé, pas un badge ;
## - les objectifs : « Erika puis repaire » et « repaire puis Erika » passent par les mêmes étapes
##   du repaire et finissent sur le même objectif, avec ou sans le Badge Prisme.

const GYM_FILES: Array[String] = [
	"res://data/npcs/celadon_gym.json", "res://data/dialogues/celadon_gym.json",
	"res://data/cutscenes/celadon_gym.json",
]
const HIDEOUT_FILES: Array[String] = [
	"res://data/npcs/celadon_game_corner.json", "res://data/npcs/rocket_hideout_b1f.json",
	"res://data/npcs/rocket_hideout_b2f.json", "res://data/npcs/rocket_hideout_b3f.json",
	"res://data/npcs/rocket_hideout_b4f.json", "res://data/dialogues/game_corner.json",
	"res://data/dialogues/rocket_hideout.json", "res://data/cutscenes/game_corner.json",
	"res://data/cutscenes/rocket_hideout.json",
]
const SETTING_KEYS: Array[String] = ["set", "win", "lose", "confirm_set", "cancel_set"]
const READING_KEYS: Array[String] = ["if", "unless"]
const GATE_MAPS: Array[StringName] = [&"celadon_game_corner", &"rocket_hideout_b4f",
	&"celadon_gym", &"celadon_city"]
## Étapes du repaire, dans l'ordre du jeu.
const HIDEOUT_STEPS: Array[StringName] = [&"beaten_celadon_game_corner_rocket",
	&"game_corner_switch", &"rocket_dropped_lift_key", &"got_rocket_hideout_b4f_lift_key",
	&"rocket_hideout_b4f_door_open", &"giovanni_met", &"giovanni_hideout_won",
	&"got_rocket_hideout_b4f_silph_scope"]
const GYM_STEPS: Array[StringName] = [&"cut_celadon_gym_bush", &"cut_celadon_gym_inner_bush",
	&"erika_met", &"badge_rainbow", &"tm21_received"]


func _flags_under(keys: Array[String], files: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for path: String in files:
		_collect(JSON.parse_string(FileAccess.get_file_as_string(path)), keys, out)
	return out


func _collect(value: Variant, keys: Array[String], out: Array[String]) -> void:
	if value is Dictionary:
		for key: Variant in value:
			if keys.has(str(key)) and value[key] is Array:
				for flag: Variant in value[key]:
					if flag is String:
						out.append(flag)
			if str(key) == "trainer" and value[key] is Dictionary and keys == SETTING_KEYS:
				out.append(TrainerRules.BEATEN_PREFIX + str((value[key] as Dictionary)["id"]))
			_collect(value[key], keys, out)
	elif value is Array:
		for entry: Variant in value:
			_collect(entry, keys, out)


func test_the_gym_and_the_hideout_read_nothing_the_other_sets() -> void:
	var gym_sets := _flags_under(SETTING_KEYS, GYM_FILES)
	var hideout_sets := _flags_under(SETTING_KEYS, HIDEOUT_FILES)
	assert_has(gym_sets, "badge_rainbow")
	assert_has(hideout_sets, "giovanni_hideout_won")
	for flag: String in _flags_under(READING_KEYS, HIDEOUT_FILES):
		assert_false(gym_sets.has(flag), "le repaire lit « %s » de l'Arène" % flag)
		assert_false(flag.begins_with("badge_"), "le repaire ne demande aucun badge (%s)" % flag)
	for flag: String in _flags_under(READING_KEYS, GYM_FILES):
		assert_false(hideout_sets.has(flag), "l'Arène lit « %s » du repaire" % flag)


func test_flag_gates_and_the_lift_do_not_cross_the_two_quests() -> void:
	var hideout := HIDEOUT_STEPS.map(func(f: StringName) -> String: return String(f))
	var gym := GYM_STEPS.map(func(f: StringName) -> String: return String(f))
	for map_id: StringName in GATE_MAPS:
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate()
		for node: Node in map.find_children("*", "Node2D", true, false):
			var gate := node as FlagGate
			if gate == null:
				continue
			for flag: StringName in gate.if_flags + gate.unless_flags:
				var crossed: bool = (hideout.has(String(flag)) and map_id in [&"celadon_gym"]) \
					or (gym.has(String(flag)) and String(map_id).begins_with("rocket_hideout"))
				assert_false(crossed, "%s : %s lit %s" % [map_id, gate.name, flag])
		map.free()
	var lifts := ElevatorLibrary.new()
	assert_true(lifts.load_file())
	assert_eq(lifts.get_elevator(&"rocket_hideout").key, &"lift_key", "la Clé, rien d'autre")


func test_both_orders_reach_the_same_objectives() -> void:
	var objectives := ObjectiveLibrary.new()
	assert_true(objectives.load_file())
	var base: Array[StringName] = [&"badge_boulder", &"cerulean_reached", &"badge_cascade",
		&"badge_thunder", &"lavender_reached", &"tower_stairs_open", &"tower_ghost_met",
		&"route_8_reached", &"celadon_reached"]
	# Erika puis repaire.
	var first := StoryFlags.new()
	for flag: StringName in base + GYM_STEPS:
		first.set_flag(flag)
	var trail_a: Array[StringName] = []
	for flag: StringName in HIDEOUT_STEPS:
		first.set_flag(flag)
		trail_a.append(objectives.current_id(first))
	# Repaire puis Erika.
	var second := StoryFlags.new()
	for flag: StringName in base:
		second.set_flag(flag)
	var trail_b: Array[StringName] = []
	for flag: StringName in HIDEOUT_STEPS:
		second.set_flag(flag)
		trail_b.append(objectives.current_id(second))
	assert_eq(trail_a, trail_b, "mêmes étapes du repaire, badge ou pas")
	assert_eq(trail_a.back(), &"back_to_tower")
	for flag: StringName in GYM_STEPS:
		second.set_flag(flag)
	assert_eq(objectives.current_id(second), objectives.current_id(first),
		"même objectif final dans les deux ordres")
	assert_eq(first.to_array().size(), second.to_array().size(), "mêmes drapeaux à la fin")
