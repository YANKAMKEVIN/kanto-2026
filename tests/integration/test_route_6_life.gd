extends GutTest
## Vie de la Route 6 (jalon 15 T14, jalon-15.md §2.4, §2.7.7–§2.7.9, §2.8 ; dossier 18 §6, §15) :
## `data/npcs/route_6.json` aux cases, orientations et portées de la grille
## `tools/plans/route_6.txt` (prénoms Gabin et Basile : §0.2 n° 9), Dresseurs de
## `data/trainers/route_6.json` et leurs répliques, garde (T-17), pêcheur sans canne (T-23),
## promeneur (A.4), Poké Ball, Pokémon d'ambiance, rencontres (T16), décor de combat ; puis, sur la
## vraie carte avec ses PNJ, Chloé inévitable et les cinq autres évitables.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_6.tscn"
const PLAN_PATH := "res://tools/plans/route_6.txt"
const MAP_ID := &"route_6"
const SIZE := Vector2i(42, 56)
const ARRIVAL := Vector2i(7, 5)
const SOUTH := [Vector2i(25, 55), Vector2i(26, 55), Vector2i(27, 55)]
const INF := 1 << 30

## Clé du fichier de PNJ → position de la grille, Dresseur, apparence.
const TRAINERS: Dictionary[StringName, Array] = {
	&"lass_chloe": ["chloe", &"route_6_lass_chloe", &"lass"],
	&"camper_gabin": ["lucas", &"route_6_camper_gabin", &"camper"],
	&"scout_axel": ["axel", &"route_6_scout_axel", &"scout"],
	&"camper_mathis": ["mathis", &"route_6_camper_mathis", &"camper"],
	&"lass_manon": ["manon", &"route_6_lass_manon", &"lass"],
	&"scout_basile": ["timeo", &"route_6_scout_basile", &"scout"],
}

var _plan := PlanGrid.new()
var _roster: NpcRoster
var _dialogues := DialogueLibrary.new()
var _trainers: TrainerLibrary
var _map: GameMap
var _terrain: GridWorld


func before_all() -> void:
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_roster = NpcRoster.load_for_map(MAP_ID)
	_dialogues.load_dir()
	var data := PokemonData.new()
	data.load_dir()
	_trainers = TrainerLibrary.new(data)
	_trainers.load_dir()
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	var grid := _map.get_grid()
	_terrain = GridPaths.relief(grid, SIZE)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if grid.is_water(Vector2i(x, y)):
				_terrain.set_solid(Vector2i(x, y))


func after_all() -> void:
	_map.free()


func _sight(spec: NpcSpec) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for k: int in range(1, spec.sight + 1):
		var cell := spec.cell + spec.facing * k
		if not _terrain.is_in_bounds(cell) or _terrain.is_solid(cell):
			break
		cells.append(cell)
	return cells


func _with_npcs(extra: Array = []) -> GridWorld:
	var grid := GridPaths.relief(_terrain, SIZE)
	for spec: NpcSpec in _roster.get_all():
		grid.set_solid(spec.cell)
	for cell: Vector2i in extra:
		grid.set_solid(cell)
	return grid


func _reach(grid: GridWorld) -> int:
	var dist := GridPaths.distances(grid, [ARRIVAL])
	var best := INF
	for cell: Vector2i in SOUTH:
		best = mini(best, int(dist.get(cell, INF)))
	return best


func test_roster_holds_the_placed_people() -> void:
	assert_eq(_roster.get_errors().size(), 0, str(_roster.get_errors()))
	var keys: Array[StringName] = []
	for spec: NpcSpec in _roster.get_all():
		keys.append(spec.id)
	keys.sort()
	var expected: Array[StringName] = [&"camper_gabin", &"camper_mathis", &"lass_chloe",
		&"lass_manon", &"pond_fisher", &"rattata_1", &"roucool_1", &"route_6_item_1",
		&"saffron_guard", &"scout_axel", &"scout_basile", &"walker"]
	expected.sort()
	assert_eq(keys, expected, "6 Dresseurs, garde, pêcheur, promeneur, Poké Ball, 2 Pokémon")


func test_grid_names_gabin_and_basile() -> void:
	assert_eq(_plan.attr("lucas", "trainer"), "route_6_camper_gabin")
	assert_eq(_plan.attr("timeo", "trainer"), "route_6_scout_basile")


func test_trainers_follow_the_grid() -> void:
	for key: StringName in TRAINERS:
		var info: Array = TRAINERS[key]
		var plan_id: String = info[0]
		var spec := _roster.get_spec(key)
		assert_not_null(spec, String(key))
		if spec == null:
			continue
		assert_true(spec.is_trainer(), String(key))
		assert_eq(spec.cell, _plan.cell_of(plan_id), "%s : case" % key)
		assert_eq(spec.facing, Grid.direction_from_name(_plan.attr(plan_id, "facing")), key)
		assert_eq(spec.sight, int(_plan.attr(plan_id, "sight")), "%s : portée" % key)
		assert_eq(spec.trainer_id, info[1], key)
		assert_eq(String(spec.trainer_id), _plan.attr(plan_id, "trainer"), "%s : grille" % key)
		assert_eq(spec.sprite, info[2], "%s : apparence" % key)
		assert_true(Npc.has_frames(spec.sprite), "%s : planche peinte" % key)
		var trainer := _trainers.get_trainer(spec.trainer_id)
		assert_not_null(trainer, String(spec.trainer_id))
		assert_eq(spec.before_dialogue, StringName(String(spec.trainer_id) + "_before"))
		assert_eq(spec.defeated_dialogue, StringName(String(spec.trainer_id) + "_defeated"))
		assert_eq(spec.dialogue, StringName(String(spec.trainer_id) + "_after"))
		for line: StringName in [spec.before_dialogue, spec.defeated_dialogue, spec.dialogue]:
			var dialogue := _dialogues.get_dialogue(line)
			assert_not_null(dialogue, String(line))
			if dialogue != null and trainer != null:
				assert_eq(dialogue.speaker, trainer.name, "%s : locuteur" % line)


func test_trainers_stand_on_their_cell_in_the_real_scene() -> void:
	for key: StringName in TRAINERS:
		var npc := _map.get_npc(key)
		assert_not_null(npc, "%s posé" % key)
		if npc != null:
			assert_true(_map.get_grid().is_occupied(npc.get_cell()), "%s occupe sa case" % key)


func test_chloe_sees_every_way_through_with_the_people() -> void:
	var sight := _sight(_roster.get_spec(&"lass_chloe"))
	assert_eq(sight.size(), 5, "vue dégagée")
	assert_lt(_reach(_with_npcs()), INF, "Carmin atteignable avec les PNJ")
	assert_eq(_reach(_with_npcs(sight)), INF, "Chloé inévitable")


func test_the_five_others_can_be_avoided_with_the_people() -> void:
	var seen: Array[Vector2i] = []
	for key: StringName in [&"camper_gabin", &"scout_axel", &"camper_mathis", &"lass_manon",
			&"scout_basile"]:
		var sight := _sight(_roster.get_spec(key))
		assert_gt(sight.size(), 0, "%s voit devant lui" % key)
		assert_lt(_reach(_with_npcs(sight)), INF, "%s évitable" % key)
		seen.append_array(sight)
	assert_lt(_reach(_with_npcs(seen)), INF, "D2 à D6 évitables ensemble")


func test_people_say_their_validated_lines() -> void:
	var expected: Dictionary[StringName, Array] = {
		&"saffron_guard": ["garde_safrania", &"guard", &"route_6_guard"],
		&"pond_fisher": ["pecheur", &"old_man", &"route_6_fisher"],
		&"walker": ["promeneur", &"traveler", &"route_6_walker"],
	}
	for key: StringName in expected:
		var spec := _roster.get_spec(key)
		var info: Array = expected[key]
		assert_eq(spec.cell, _plan.cell_of(info[0]), key)
		assert_eq(spec.facing, Grid.direction_from_name(_plan.attr(info[0], "facing")), key)
		assert_eq([spec.sprite, spec.dialogue], [info[1], info[2]], key)
		assert_true(Npc.has_frames(spec.sprite), "%s : planche" % key)
	var guard := _dialogues.get_dialogue(&"route_6_guard").variants[0]
	assert_eq(guard.pages.size(), 2, "T-17 en deux bulles")
	assert_eq(guard.pages[1].text, "Ordre de la ville.")
	assert_true(_roster.get_spec(&"saffron_guard").keep_facing, "le garde regarde la route")


func test_poke_ball_and_ambient_pokemon() -> void:
	var ball := _roster.get_spec(&"route_6_item_1")
	assert_eq(ball.cell, _plan.cell_of("route_6_item_1"))
	assert_eq(ball.unless_flags, [&"got_route_6_item_1"] as Array[StringName])
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir())
	for id: StringName in [&"route_6_item_1", &"route_6_hidden_1"]:
		var scene := cutscenes.get_cutscene(id)
		assert_not_null(scene, String(id))
	for key: StringName in [&"roucool_1", &"rattata_1"]:
		var spec := _roster.get_spec(key)
		assert_eq(spec.cell, _plan.cell_of(String(key)), key)
		assert_false(spec.is_interactive(), key)
		assert_true(Npc.has_frames(spec.sprite), "%s : planche" % key)


func test_encounters_and_battle_decor() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var encounters := EncounterLibrary.new(data)
	assert_true(encounters.load_dir())
	var table := encounters.get_table(MAP_ID)
	assert_not_null(table, "hautes herbes de la Route 6")
	if table == null:
		return
	var species: Array[String] = []
	for slot: EncounterSlot in table.slots:
		species.append(String(slot.species))
	species.sort()
	assert_eq(species, ["bellsprout", "mankey", "meowth", "oddish", "pidgey"] as Array[String],
		"table de la Route 6 (T16)")
	var decors: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/battle/decors.json"))
	assert_eq(decors["places"]["route_6"][0]["decor"], "route_5_6_prairie")
