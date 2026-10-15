extends GutTest
## Cartes de QA du jalon 16 (`jalon-16.md` §2.14, T16) : quai, navire et Arène d'essai, leurs
## données `qa_*` et les départs de débogage (Coupe, sortie du navire, puzzle). Tout est retiré
## au T20.

const DOCK := &"qa_dock_j16"
const SHIP := &"qa_ship_j16"
const GYM := &"qa_gym_j16"
const STARTS: Array[String] = ["cut_no_hm", "cut_no_badge", "cut_no_pokemon", "cut_ready",
	"ss_anne_free_exit", "ss_anne_exit", "vermilion_gym"]
## État de Coupe attendu par départ (devant l'arbuste).
const CUT_STATES := {
	"cut_no_hm": FieldMoves.State.NO_HM, "cut_no_badge": FieldMoves.State.NO_BADGE,
	"cut_no_pokemon": FieldMoves.State.NO_POKEMON, "cut_ready": FieldMoves.State.READY,
}

const GameStateScript := preload("res://game/autoload/game_state.gd")

var _data: PokemonData
var _items: ItemLibrary
var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()


func _map(map_id: StringName) -> GameMap:
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func _start(start_name: String) -> DebugStart:
	var start := DebugStart.new()
	assert_true(start.load_file("res://tools/debug_start/%s.json" % start_name, _data, _items),
		"%s : %s" % [start_name, "\n".join(start.get_errors())])
	return start


func test_maps_are_qa_maps_and_nothing_in_the_game_leads_here() -> void:
	for map_id: StringName in [DOCK, SHIP, GYM]:
		assert_true(MapCatalog.is_qa_map(map_id))
		assert_true(MapCatalog.has_map(map_id))
	for file: String in DirAccess.get_files_at(MapCatalog.MAPS_DIR):
		if not file.ends_with(".tscn") or file.begins_with("qa_"):
			continue
		var map := (load(MapCatalog.MAPS_DIR + file) as PackedScene).instantiate() as GameMap
		for warp: Warp in map.get_warps().get_all():
			assert_false(MapCatalog.is_qa_map(warp.target_map), file)
		map.free()


func test_every_warp_lands_on_a_free_spawn() -> void:
	for map_id: StringName in [DOCK, SHIP, GYM]:
		var map := _map(map_id)
		for warp: Warp in map.get_warps().get_all():
			if MapCatalog.is_qa_map(warp.target_map):
				var target := _map(warp.target_map)
				assert_true(target.has_spawn(warp.target_spawn), "%s → %s:%s" % [map_id,
					warp.target_map, warp.target_spawn])
				assert_true(target.get_grid().is_free(target.get_spawn_cell(warp.target_spawn)))


func test_dock_bush_blocks_the_gym_corridor() -> void:
	var map := _map(DOCK)
	var grid := map.get_grid()
	var tree := map.get_npc(&"qa_tree")
	assert_not_null(tree)
	assert_eq(tree.get_cell(), Vector2i(20, 9))
	assert_eq(tree.get_spec().unless_flags, [&"cut_qa_tree"] as Array[StringName])
	for cell: Vector2i in [Vector2i(19, 9), Vector2i(21, 9), Vector2i(19, 8), Vector2i(21, 8)]:
		assert_true(grid.is_solid(cell), "couloir fermé en %s" % cell)
	assert_eq(map.get_spawn_cell(&"cut_start"), Vector2i(20, 10), "face à l'arbuste")
	var door := map.get_warps().find_on_step(Vector2i(20, 6), Vector2i.UP)
	assert_not_null(door)
	assert_eq(door.target_map, GYM)


func test_dock_ship_is_a_flag_gate_and_the_gangway_closes_after_departure() -> void:
	var map := _map(DOCK)
	var ship := map.get_node_or_null(^"Ship") as FlagGate
	assert_not_null(ship, "nœud « Ship » (étape animate)")
	assert_eq(ship.unless_flags, [&"ss_anne_departed"] as Array[StringName])
	var departed := StoryFlags.new()
	departed.set_flag(&"ss_anne_departed")
	assert_false(ship.is_open(departed))
	assert_true(ship.is_open(StoryFlags.new()))
	for x: int in [11, 12]:
		var warp := map.get_warps().find_on_step(Vector2i(x, 5), Vector2i.UP)
		assert_not_null(warp)
		assert_eq([warp.target_map, warp.target_spawn], [SHIP, &"from_dock"])
	var roster := NpcRoster.load_for_map(DOCK)
	assert_eq(roster.get_errors().size(), 0, "\n".join(roster.get_errors()))
	for id: StringName in [&"qa_gangway_w", &"qa_gangway_e"]:
		var spec := roster.get_spec(id)
		assert_false(spec.is_present(StoryFlags.new()), "%s absent avant le départ" % id)
		assert_true(spec.is_present(departed), "%s présent après" % id)


func test_ship_exit_triggers_the_confirmation_on_both_cells() -> void:
	var map := _map(SHIP)
	for x: int in [5, 6]:
		var triggers := map.get_triggers().get_at(Vector2i(x, 8))
		assert_eq(triggers.size(), 1)
		assert_eq(triggers[0].cutscene_id, &"qa_ship_exit")
		var warp := map.get_warps().find_on_push(Vector2i(x, 8), Vector2i.DOWN)
		assert_not_null(warp)
		assert_eq([warp.target_map, warp.target_spawn], [DOCK, &"from_ss_anne"])
	# Seules les cases de sortie mènent à la rangée 8.
	for x: int in 12:
		if x != 5 and x != 6:
			assert_true(map.get_grid().is_solid(Vector2i(x, 8)))


func test_ship_exit_variants_and_departure_order() -> void:
	var exit := _cutscenes.get_cutscene(&"qa_ship_exit")
	assert_not_null(exit)
	var flags := StoryFlags.new()
	assert_same(exit.pick(flags), exit.variants[1], "avant la CS01 : sortie libre, TXT-03")
	flags.set_flag(&"ss_anne_exit_told")
	assert_null(exit.pick(flags), "TXT-03 une seule fois")
	flags.set_flag(&"got_hm01")
	assert_same(exit.pick(flags), exit.variants[0], "après la CS01 : confirmation")
	flags.set_flag(&"ss_anne_departed")
	assert_null(exit.pick(flags), "après le départ : rien")
	var kinds: Array = []
	for step: CutsceneStep in exit.variants[0].steps:
		kinds.append(step.kind)
	var change := kinds.find(CutsceneStep.Kind.CHANGE_MAP)
	var set_departed := kinds.find(CutsceneStep.Kind.SET_FLAGS)
	var save := kinds.find(CutsceneStep.Kind.SAVE)
	var animate := kinds.find(CutsceneStep.Kind.ANIMATE)
	assert_true(change < set_departed and set_departed < save and save < animate,
		"change_map, set, save, puis le spectacle (jalon-16.md §2.4)")
	assert_eq(exit.variants[0].steps[set_departed].flags, [&"ss_anne_departed"] as Array[StringName])
	var confirm := _dialogues.get_dialogue(&"qa_ship_exit_confirm").variants[0].choice
	assert_eq([confirm.confirm_label, confirm.cancel_label], ["PARTIR", "PAS ENCORE"])
	assert_eq(confirm.confirm_set, [&"ss_anne_departure_chosen"] as Array[StringName])


func test_gym_has_fifteen_puzzle_bins_and_a_barrier() -> void:
	var map := _map(GYM)
	var slots: Array[int] = []
	var index := 0
	for y: int in [7, 9, 11]:
		for x: int in [2, 5, 8, 11, 14]:
			index += 1
			var cell := Vector2i(x, y)
			assert_true(map.get_grid().is_solid(cell), "objet à fouiller en %s" % cell)
			var found := map.get_interactions().get_at(cell)
			assert_eq(found.size(), 1)
			assert_eq(found[0].puzzle, &"qa_vermilion_gym")
			assert_true(found[0].is_puzzle_slot())
			slots.append(found[0].puzzle_slot)
			assert_eq(found[0].puzzle_slot, index, "index ligne par ligne (grille validée)")
	assert_eq(slots.size(), 15)
	for x: int in [7, 8, 9]:
		var barrier := map.get_npc(StringName("qa_barrier_%d" % (x - 6)))
		assert_not_null(barrier)
		assert_eq(barrier.get_cell(), Vector2i(x, 5))
	var surge := map.get_npc(&"qa_surge")
	assert_eq(surge.get_spec().trainer_id, &"vermilion_gym_surge")


func test_puzzle_rule_points_to_existing_dialogues_and_scene() -> void:
	var library := SwitchPuzzleLibrary.new()
	assert_true(library.load_file(), "\n".join(library.get_errors()))
	var spec := library.get_spec(&"qa_vermilion_gym")
	assert_not_null(spec)
	assert_eq([spec.columns, spec.rows], [5, 3])
	for id: StringName in [spec.nothing, spec.first, spec.reset]:
		assert_true(_dialogues.has_dialogue(id), String(id))
	var open := _cutscenes.get_cutscene(spec.solved_cutscene)
	assert_not_null(open)
	var steps := open.variants[0].steps
	assert_eq(steps[-1].flags, [spec.solved_flag] as Array[StringName], "drapeau en dernier")
	var despawned: Array = []
	for step: CutsceneStep in steps:
		if step.kind == CutsceneStep.Kind.DESPAWN:
			despawned.append(step.actor)
	assert_eq(despawned, [&"qa_barrier_1", &"qa_barrier_2", &"qa_barrier_3"])


func test_cut_dialogue_has_the_four_states() -> void:
	var tree := _dialogues.get_dialogue(&"qa_cut_tree")
	var fields: Array = []
	for variant: DialogueVariant in tree.variants:
		fields.append(variant.field)
	assert_eq(fields, ["cut:no_hm", "cut:no_badge", "cut:no_pokemon", "cut:ready"])
	assert_eq(tree.variants[3].choice.confirm_cutscene, &"qa_cut_tree")
	var steps := _cutscenes.get_cutscene(&"qa_cut_tree").variants[0].steps
	assert_eq(steps[0].kind, CutsceneStep.Kind.FIELD_MOVE)
	assert_eq(steps[0].actor, &"qa_tree")
	assert_eq(steps[-1].flags, [&"cut_qa_tree"] as Array[StringName])


func test_debug_starts_load_and_land_on_free_spawns() -> void:
	for start_name: String in STARTS:
		var start := _start(start_name)
		var map := _map(start.map)
		assert_true(map.has_spawn(start.spawn), start_name)
		assert_true(map.get_grid().is_free(map.get_spawn_cell(start.spawn)), start_name)


func test_cut_starts_give_the_expected_field_state() -> void:
	var rules := FieldMoves.new()
	assert_true(rules.load_file())
	for start_name: String in CUT_STATES:
		var state: Node = autofree(GameStateScript.new())
		_start(start_name).apply(state, _data)
		var result := rules.check(&"cut", state.party, state.bag, state.flags, _items, _data,
			state.get_companion())
		assert_eq(result.state, CUT_STATES[start_name], start_name)
		if start_name == "cut_ready":
			assert_eq(result.pokemon_index, 1, "Pikachu (compagnon) incompatible : Sabelette")


func test_only_the_departure_start_writes_the_save() -> void:
	for start_name: String in STARTS:
		assert_eq(_start(start_name).autosave, start_name == "ss_anne_exit", start_name)
