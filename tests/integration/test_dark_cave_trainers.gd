extends GutTest
## Dresseurs et objets de la Grotte Sombre (jalon 18 T20, jalon-18.md §4 ; dossier 21 §5.5, §5.7,
## §15.5) : `data/npcs/dark_cave_*.json` aux cases, orientations et portées des grilles
## `tools/plans/grotte_sombre_*.txt`, Dresseurs de `data/trainers/dark_cave.json`, répliques avant /
## défaite / après (T-51 à T-55), puis les chemins sur les vraies cartes avec leurs PNJ : G-1 Roger
## (1F nord) et G-4 Marcel (B1F, passage étroit) inévitables ; G-2 Simon, G-3 Elsa et G-5 Yanis
## évitables, même ensemble. Objets visibles (Corde Sortie, Antidote, Super Potion).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const INF := 1 << 30

## Étage → [scène, grille, taille, départ du chemin principal, arrivées (portes)].
const FLOORS: Dictionary[StringName, Array] = {
	&"dark_cave_1f": ["res://game/world/maps/dark_cave_1f.tscn",
		"res://tools/plans/grotte_sombre_1f.txt", Vector2i(56, 49)],
	&"dark_cave_b1f": ["res://game/world/maps/dark_cave_b1f.tscn",
		"res://tools/plans/grotte_sombre_b1f.txt", Vector2i(48, 38)],
}
## Trajets du chemin principal : [étage, départs, arrivées].
const ROUTES: Array = [
	[&"dark_cave_1f", [Vector2i(27, 1), Vector2i(28, 1)], [Vector2i(44, 2)]],
	[&"dark_cave_b1f", [Vector2i(44, 3)], [Vector2i(44, 34)]],
	[&"dark_cave_1f", [Vector2i(43, 34)], [Vector2i(8, 48), Vector2i(9, 48)]],
]
## Clé du fichier de PNJ → [étage, position de la grille, Dresseur, apparence, inévitable].
const TRAINERS: Dictionary[StringName, Array] = {
	&"g1_roger": [&"dark_cave_1f", "g1_roger", &"dark_cave_roger", &"hiker", true],
	&"g2_simon": [&"dark_cave_1f", "g2_simon", &"dark_cave_simon", &"pokemaniac", false],
	&"g5_yanis": [&"dark_cave_1f", "g5_yanis", &"dark_cave_yanis", &"pokemaniac", false],
	&"g3_elsa": [&"dark_cave_b1f", "g3_elsa", &"dark_cave_elsa", &"lass", false],
	&"g4_marcel": [&"dark_cave_b1f", "g4_marcel", &"dark_cave_marcel", &"hiker", true],
}
const ITEMS: Dictionary[StringName, Array] = {
	&"dark_cave_1f_item_1": [&"dark_cave_1f", &"escape_rope"],
	&"dark_cave_1f_item_2": [&"dark_cave_1f", &"antidote"],
	&"dark_cave_b1f_item_1": [&"dark_cave_b1f", &"super_potion"],
}

var _plans: Dictionary = {}
var _rosters: Dictionary = {}
var _maps: Dictionary = {}
var _terrain: Dictionary = {}
var _dialogues := DialogueLibrary.new()
var _trainers: TrainerLibrary


func before_all() -> void:
	_dialogues.load_dir()
	var data := PokemonData.new()
	data.load_dir()
	_trainers = TrainerLibrary.new(data)
	_trainers.load_dir()
	for map_id: StringName in FLOORS:
		var info: Array = FLOORS[map_id]
		var plan := PlanGrid.new()
		assert_true(plan.load_file(info[1]), plan.error)
		_plans[map_id] = plan
		_rosters[map_id] = NpcRoster.load_for_map(map_id)
		var map := (load(info[0]) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[map_id] = map
		_terrain[map_id] = GridPaths.relief(map.get_grid(), info[2])


func after_all() -> void:
	for map: Node in _maps.values():
		map.free()


func _sight(map_id: StringName, spec: NpcSpec) -> Array[Vector2i]:
	var terrain: GridWorld = _terrain[map_id]
	var cells: Array[Vector2i] = []
	for k: int in range(1, spec.sight + 1):
		var cell := spec.cell + spec.facing * k
		if not terrain.is_in_bounds(cell) or terrain.is_solid(cell):
			break
		cells.append(cell)
	return cells


func _with_npcs(map_id: StringName, extra: Array = []) -> GridWorld:
	var grid := GridPaths.relief(_terrain[map_id], FLOORS[map_id][2])
	for spec: NpcSpec in (_rosters[map_id] as NpcRoster).get_all():
		# Marcel quitte le passage étroit après sa défaite (« leave ») : il ne le barre pas.
		if not spec.leaves:
			grid.set_solid(spec.cell)
	for cell: Vector2i in extra:
		grid.set_solid(cell)
	return grid


func _reach(map_id: StringName, grid: GridWorld, starts: Array, goals: Array) -> int:
	var stops: Dictionary = {}
	for cell: Vector2i in goals:
		stops[cell] = true
	var dist := GridPaths.distances(grid, starts, stops)
	var best := INF
	for cell: Vector2i in goals:
		best = mini(best, int(dist.get(cell, INF)))
	return best


func test_rosters_hold_exactly_the_placed_people() -> void:
	var expected := {
		&"dark_cave_1f": [&"dark_cave_1f_item_1", &"dark_cave_1f_item_2", &"g1_roger",
			&"g2_simon", &"g5_yanis"],
		&"dark_cave_b1f": [&"dark_cave_b1f_item_1", &"g3_elsa", &"g4_marcel"],
	}
	for map_id: StringName in FLOORS:
		var roster: NpcRoster = _rosters[map_id]
		assert_eq(roster.get_errors().size(), 0, str(roster.get_errors()))
		var keys: Array[StringName] = []
		for spec: NpcSpec in roster.get_all():
			keys.append(spec.id)
		keys.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
		assert_eq(keys, expected[map_id] as Array, "%s : 5 Dresseurs et 3 objets en tout" % map_id)


func test_trainers_follow_the_grids_and_the_texts() -> void:
	for key: StringName in TRAINERS:
		var info: Array = TRAINERS[key]
		var map_id: StringName = info[0]
		var plan: PlanGrid = _plans[map_id]
		var spec := (_rosters[map_id] as NpcRoster).get_spec(key)
		assert_not_null(spec, String(key))
		if spec == null:
			continue
		assert_true(spec.is_trainer(), String(key))
		assert_eq(spec.cell, plan.cell_of(info[1]), "%s : case" % key)
		assert_eq(spec.facing, Grid.direction_from_name(plan.attr(info[1], "facing")), key)
		assert_eq(spec.sight, int(plan.attr(info[1], "sight")), "%s : portée" % key)
		assert_eq(spec.trainer_id, info[2], key)
		assert_eq(plan.attr(info[1], "trainer"), String(info[2]), "%s : grille" % key)
		assert_eq(spec.sprite, info[3], "%s : apparence" % key)
		assert_true(Npc.has_frames(spec.sprite), "%s : planche" % key)
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


## Tableau du dossier 21 §5.5 : équipes et récompenses.
func test_teams_and_prizes() -> void:
	var expected := {
		&"dark_cave_roger": [665, [[&"geodude", 19], [&"machop", 19], [&"geodude", 19],
			[&"geodude", 19]]],
		&"dark_cave_simon": [1150, [[&"jigglypuff", 23], [&"koffing", 23]]],
		&"dark_cave_elsa": [380, [[&"pidgey", 19], [&"rattata", 19], [&"rattata", 19],
			[&"bellsprout", 19]]],
		&"dark_cave_marcel": [700, [[&"onix", 20], [&"onix", 20], [&"geodude", 20]]],
		&"dark_cave_yanis": [1050, [[&"charmander", 21], [&"nidorino", 21]]],
	}
	for id: StringName in expected:
		var trainer := _trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		var team: Array = []
		for member: Variant in trainer.team:
			team.append([member.species, member.level])
		assert_eq([trainer.prize_money, team], expected[id], String(id))
		for member: Variant in trainer.team:
			assert_ne(member.species, &"cubone", "pas d'Osselait (I-14)")
			assert_ne(member.species, &"marowak", "pas d'Ossatueur (I-14)")


func test_trainers_stand_on_their_cell_in_the_real_scene() -> void:
	for key: StringName in TRAINERS:
		var map_id: StringName = TRAINERS[key][0]
		var npc := (_maps[map_id] as GameMap).get_npc(key)
		assert_not_null(npc, "%s posé sur la carte" % key)
		if npc != null:
			assert_true((_maps[map_id] as GameMap).get_grid().is_occupied(npc.get_cell()),
				"%s occupe sa case" % key)


func test_roger_and_marcel_see_every_way_through() -> void:
	for key: StringName in TRAINERS:
		var info: Array = TRAINERS[key]
		if not info[4]:
			continue
		var map_id: StringName = info[0]
		var spec := (_rosters[map_id] as NpcRoster).get_spec(key)
		var sight := _sight(map_id, spec)
		assert_eq(sight.size(), spec.sight, "%s : vue dégagée" % key)
		var route := _route_of(map_id, spec.cell)
		assert_lt(_reach(map_id, _with_npcs(map_id), route[1], route[2]), INF,
			"%s : chemin principal atteignable avec les PNJ" % key)
		assert_eq(_reach(map_id, _with_npcs(map_id, sight), route[1], route[2]), INF,
			"%s inévitable" % key)


## Trajet du chemin principal que le Dresseur en [param cell] garde.
func _route_of(map_id: StringName, cell: Vector2i) -> Array:
	for route: Array in ROUTES:
		if route[0] != map_id:
			continue
		var grid := _with_npcs(map_id)
		grid.set_solid(cell, false)
		var dist := GridPaths.distances(grid, route[1])
		if dist.has(cell) or dist.has(cell + Vector2i.LEFT) or dist.has(cell + Vector2i.RIGHT):
			return route
	return ROUTES[0]


func test_simon_elsa_and_yanis_can_be_avoided_even_together() -> void:
	for route: Array in ROUTES:
		var map_id: StringName = route[0]
		var all_seen: Array[Vector2i] = []
		for key: StringName in TRAINERS:
			var info: Array = TRAINERS[key]
			if info[0] != map_id or info[4]:
				continue
			var sight := _sight(map_id, (_rosters[map_id] as NpcRoster).get_spec(key))
			assert_gt(sight.size(), 0, "%s voit devant lui" % key)
			assert_lt(_reach(map_id, _with_npcs(map_id, sight), route[1], route[2]), INF,
				"%s évitable" % key)
			all_seen.append_array(sight)
		assert_lt(_reach(map_id, _with_npcs(map_id, all_seen), route[1], route[2]), INF,
			"%s : évitables ensemble" % map_id)


func test_visible_items_on_the_grid() -> void:
	for key: StringName in ITEMS:
		var info: Array = ITEMS[key]
		var map_id: StringName = info[0]
		var plan: PlanGrid = _plans[map_id]
		var spec := (_rosters[map_id] as NpcRoster).get_spec(key)
		assert_not_null(spec, String(key))
		if spec == null:
			continue
		assert_eq(spec.cell, plan.cell_of(String(key)), "%s : case" % key)
		assert_eq(plan.attr(String(key), "item"), String(info[1]), "%s : objet de la grille" % key)
		assert_eq(spec.unless_flags, [StringName("got_" + String(key))] as Array[StringName])
		assert_not_null(_dialogues.get_dialogue(spec.dialogue), String(key))


func test_visible_items_hold_the_dossier_objects() -> void:
	var data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/cutscenes/dark_cave.json"))
	for key: StringName in ITEMS:
		var gives: Array[StringName] = []
		for variant: Dictionary in data[String(key)]["variants"]:
			for step: Dictionary in variant["steps"]:
				if step.has("give"):
					gives.append(StringName(step["give"]))
		assert_eq(gives, [ITEMS[key][1]] as Array[StringName], String(key))


## Marcel garde le passage étroit (1 case de large) : après sa défaite il s'éloigne vers l'est
## par le passage puis s'efface, sinon il barrerait la grotte pour toujours.
func test_marcel_leaves_the_narrow_passage_free() -> void:
	var spec := (_rosters[&"dark_cave_b1f"] as NpcRoster).get_spec(&"g4_marcel")
	assert_true(spec.leaves)
	var plan: PlanGrid = _plans[&"dark_cave_b1f"]
	for cell: Vector2i in spec.get_leave_path_cells():
		assert_true(plan.is_walkable(cell), "%s praticable" % cell)


## G-4 (T-53, T-54) : la réplique de défaite de Marcel enchaîne « Passe, alors. » puis « La sortie
## n'est plus très loin… », dites avant son départ (la réplique « après » n'est plus jamais
## entendue : il s'efface).
func test_marcel_says_t53_then_t54_before_leaving() -> void:
	var spec := (_rosters[&"dark_cave_b1f"] as NpcRoster).get_spec(&"g4_marcel")
	var lines: Array = []
	var file := FileAccess.open("res://data/dialogues/dark_cave.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	lines = data[String(spec.defeated_dialogue)]["pages"]
	assert_eq(lines.size(), 2)
	assert_eq(lines[0], "Passe, alors.")
	assert_eq(lines[1], "La sortie n'est plus très loin.\nTu sentiras l'air frais.")
	assert_true(spec.leaves)
