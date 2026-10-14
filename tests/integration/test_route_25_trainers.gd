extends GutTest
## Dresseurs, PNJ et Pokémon d'ambiance de la Route 25 (jalon 14 T16, jalon-14.md §2.11 ;
## dossier 17 §9) : `data/npcs/route_25.json` aux cases, orientations et portées de la grille
## `tools/plans/route_25.txt`, Dresseurs de `data/trainers/route_25.json`, répliques avant /
## défaite / après, puis le chemin sur la vraie carte avec ses PNJ : D1 et D2 inévitables,
## D3 à D6 évitables. D5 et D6 (Abo, J12 T12) posés à l'alignement (T23 du J14) ; apparences
## par défaut : Campeur pour le Jeune Dresseur Adam, Gamin pour Yanis.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_25.tscn"
const PLAN_PATH := "res://tools/plans/route_25.txt"
const MAP_ID := &"route_25"
const SIZE := Vector2i(80, 28)
const WEST := [Vector2i(0, 13), Vector2i(0, 14), Vector2i(0, 15)]
const DOORS := [Vector2i(71, 11), Vector2i(72, 11)]
const INF := 1 << 30

## Clé du fichier de PNJ → position de la grille, Dresseur, apparence.
const TRAINERS: Dictionary[StringName, Array] = {
	&"youngster_jules": ["d1", &"route_25_youngster_jules", &"youngster"],
	&"hiker_gaston": ["d2", &"route_25_hiker_gaston", &"hiker"],
	&"lass_zoe": ["d3", &"route_25_lass_zoe", &"lass_young"],
	&"hiker_bernard": ["d4", &"route_25_hiker_bernard", &"mountaineer"],
	&"jr_trainer_adam": ["d5", &"route_25_jr_trainer_adam", &"camper"],
	&"youngster_yanis": ["d6", &"route_25_youngster_yanis", &"youngster"],
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
	_terrain = GridPaths.relief(_map.get_grid(), SIZE)


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


## Terrain + toutes les cases occupées par un PNJ, Pokémon ou objet du fichier.
func _with_npcs(extra: Array = []) -> GridWorld:
	var grid := GridPaths.relief(_terrain, SIZE)
	for spec: NpcSpec in _roster.get_all():
		grid.set_solid(spec.cell)
	for cell: Vector2i in extra:
		grid.set_solid(cell)
	return grid


func _reach(grid: GridWorld) -> int:
	var stops: Dictionary = {}
	for cell: Vector2i in DOORS:
		stops[cell] = true
	var dist := GridPaths.distances(grid, WEST, stops)
	var best := INF
	for cell: Vector2i in DOORS:
		best = mini(best, int(dist.get(cell, INF)))
	return best


func test_roster_loads_without_error_and_holds_the_placed_people() -> void:
	assert_eq(_roster.get_errors().size(), 0, str(_roster.get_errors()))
	var keys: Array[StringName] = []
	for spec: NpcSpec in _roster.get_all():
		keys.append(spec.id)
	keys.sort()
	var expected: Array[StringName] = [&"hiker_bernard", &"hiker_gaston", &"jr_trainer_adam",
		&"lass_zoe", &"old_man", &"roucool_1", &"roucool_2", &"route_25_item_1",
		&"route_25_item_2", &"route_25_item_3", &"traveler", &"youngster_jules",
		&"youngster_yanis"]
	expected.sort()
	assert_eq(keys, expected, "6 Dresseurs, 2 PNJ, 2 Roucool, 3 objets")


## D5 et D6 (dossier 17 §9) : équipes et récompenses du tableau.
func test_d5_and_d6_teams_with_ekans() -> void:
	var expected := {
		&"route_25_jr_trainer_adam": ["Jeune Dresseur Adam", 280,
			[[&"rattata", 14], [&"ekans", 14]]],
		&"route_25_youngster_yanis": ["Gamin Yanis", 210, [[&"ekans", 14], [&"sandshrew", 14]]],
	}
	for id: StringName in expected:
		var trainer := _trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq([trainer.name, trainer.prize_money], expected[id].slice(0, 2), String(id))
		var team: Array = []
		for member: Variant in trainer.team:
			team.append([member.species, member.level])
		assert_eq(team, expected[id][2], "%s : équipe" % id)


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
		assert_eq(spec.sprite, info[2], "%s : apparence" % key)
		assert_false(spec.has_route(), "%s : immobile" % key)
		var trainer := _trainers.get_trainer(spec.trainer_id)
		assert_not_null(trainer, String(spec.trainer_id))
		assert_eq(spec.before_dialogue, StringName(String(spec.trainer_id) + "_before"))
		assert_eq(spec.defeated_dialogue, StringName(String(spec.trainer_id) + "_defeated"))
		assert_eq(spec.dialogue, StringName(String(spec.trainer_id) + "_after"))
		for line: StringName in [spec.before_dialogue, spec.defeated_dialogue, spec.dialogue]:
			var dialogue := _dialogues.get_dialogue(line)
			assert_not_null(dialogue, String(line))
			if dialogue != null:
				assert_eq(dialogue.speaker, trainer.name, "%s : locuteur" % line)


func test_trainers_stand_on_their_grid_cell_in_the_real_scene() -> void:
	for key: StringName in TRAINERS:
		var npc := _map.get_npc(key)
		assert_not_null(npc, "%s posé sur la carte" % key)
		if npc != null:
			assert_true(_map.get_grid().is_occupied(npc.get_cell()), "%s occupe sa case" % key)


func test_d1_and_d2_see_every_way_through() -> void:
	for key: StringName in [&"youngster_jules", &"hiker_gaston"]:
		var spec := _roster.get_spec(key)
		var sight := _sight(spec)
		assert_eq(sight.size(), spec.sight, "%s : vue dégagée" % key)
		assert_lt(_reach(_with_npcs()), INF, "porte atteignable avec les PNJ")
		assert_eq(_reach(_with_npcs(sight)), INF, "%s inévitable" % key)


func test_d3_to_d6_can_be_avoided_even_together() -> void:
	var seen: Array[Vector2i] = []
	for key: StringName in [&"lass_zoe", &"hiker_bernard", &"jr_trainer_adam",
			&"youngster_yanis"]:
		var sight := _sight(_roster.get_spec(key))
		assert_gt(sight.size(), 0, "%s voit devant lui" % key)
		assert_lt(_reach(_with_npcs(sight)), INF, "%s évitable" % key)
		seen.append_array(sight)
	assert_lt(_reach(_with_npcs(seen)), INF, "D3 à D6 évitables ensemble")


func test_d4_does_not_see_the_path() -> void:
	var spec := _roster.get_spec(&"hiker_bernard")
	for cell: Vector2i in _sight(spec):
		assert_ne(_plan.at(cell), "=", "Bernard ne voit pas le chemin (%s)" % cell)


func test_people_and_ambient_pokemon_follow_the_grid() -> void:
	var expected: Dictionary[StringName, Array] = {
		&"traveler": ["promeneur", &"traveler", &"route_25_traveler"],
		&"old_man": ["pecheur", &"old_man", &"route_25_old_man"],
	}
	for key: StringName in expected:
		var spec := _roster.get_spec(key)
		var info: Array = expected[key]
		assert_eq(spec.cell, _plan.cell_of(info[0]), key)
		assert_eq(spec.facing, Grid.direction_from_name(_plan.attr(info[0], "facing")), key)
		assert_eq([spec.sprite, spec.dialogue], [info[1], info[2]], key)
		assert_not_null(_dialogues.get_dialogue(spec.dialogue), key)
		assert_true(Npc.has_frames(spec.sprite), "%s : planche" % key)
	for key: StringName in [&"roucool_1", &"roucool_2"]:
		var spec := _roster.get_spec(key)
		assert_eq(spec.cell, _plan.cell_of(String(key)), key)
		assert_eq(spec.shy_action, &"fly", "%s : s'envole" % key)
		assert_false(spec.is_interactive(), key)
		assert_true(Npc.has_frames(spec.sprite), "%s : planche" % key)
