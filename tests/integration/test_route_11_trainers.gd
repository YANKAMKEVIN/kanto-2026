extends GutTest
## Dresseurs, PNJ et Pokémon d'ambiance de la Route 11 (jalon 17 T17, jalon-17.md §1.3 n° 5 ;
## dossier 20 §6, §16 T-18 à T-25) : `data/npcs/route_11.json` aux cases, orientations et portées
## de la grille `tools/plans/route_11.txt`, Dresseurs de `data/trainers/route_11.json` (équipes,
## récompenses du §6), répliques avant / défaite / après, puis le chemin sur la vraie carte avec
## ses PNJ (Victor recalé au Nv. 16 · 800 ₽ par la simulation du T8, plan §2.12.4) : Arthur inévitable, les sept autres évitables un à un et ensemble ; apparences
## (Gamin, Joueur, Ingénieur).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_11.tscn"
const PLAN_PATH := "res://tools/plans/route_11.txt"
const MAP_ID := &"route_11"
const SIZE := Vector2i(76, 36)
const WEST := [Vector2i(0, 11), Vector2i(0, 12), Vector2i(0, 13)]
const MOUTH := [Vector2i(15, 7), Vector2i(16, 7)]
const FRONT := [Vector2i(65, 14), Vector2i(65, 15)]
const INF := 1 << 30

## Clé du fichier de PNJ → [position de la grille, Dresseur, apparence, équipe, récompense].
const TRAINERS: Dictionary[StringName, Array] = {
	&"youngster_lucas": ["lucas", &"route_11_youngster_lucas", &"youngster",
		[[&"ekans", 21]], 315],
	&"youngster_arthur": ["arthur", &"route_11_youngster_arthur", &"youngster",
		[[&"sandshrew", 19], [&"zubat", 19]], 285],
	&"youngster_louis": ["louis", &"route_11_youngster_louis", &"youngster",
		[[&"rattata", 17], [&"rattata", 17], [&"raticate", 17]], 255],
	&"youngster_raphael": ["raphael", &"route_11_youngster_raphael", &"youngster",
		[[&"nidoran_m", 18], [&"nidorino", 18]], 270],
	&"gambler_marcel": ["marcel", &"route_11_gambler_marcel", &"gambler",
		[[&"voltorb", 18], [&"magnemite", 18]], 1260],
	&"gambler_roger": ["roger", &"route_11_gambler_roger", &"gambler",
		[[&"growlithe", 18], [&"vulpix", 18]], 1260],
	&"engineer_bruno": ["bruno", &"route_11_engineer_bruno", &"engineer",
		[[&"magnemite", 21]], 1050],
	&"engineer_victor": ["victor", &"route_11_engineer_victor", &"engineer",
		[[&"magnemite", 16], [&"magnemite", 16], [&"magneton", 16]], 800],  # recalé (T8)
}
const AVOIDABLE: Array[StringName] = [&"youngster_lucas", &"youngster_louis",
	&"youngster_raphael", &"gambler_marcel", &"gambler_roger", &"engineer_bruno",
	&"engineer_victor"]

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
	# Ronflex ferme la route : ses cases sont solides pour les chemins.
	for cell: Vector2i in _plan.cells_at("ronflex"):
		_terrain.set_solid(cell)


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


func _reach(grid: GridWorld, targets: Array) -> int:
	var stops: Dictionary = {}
	for cell: Vector2i in MOUTH:
		stops[cell] = true
	var dist := GridPaths.distances(grid, WEST, stops)
	var best := INF
	for cell: Vector2i in targets:
		best = mini(best, int(dist.get(cell, INF)))
	return best


func test_roster_loads_without_error_and_holds_the_placed_people() -> void:
	assert_eq(_roster.get_errors().size(), 0, str(_roster.get_errors()))
	var keys: Array[StringName] = []
	for spec: NpcSpec in _roster.get_all():
		keys.append(spec.id)
	keys.sort()
	var expected: Array[StringName] = [&"abo_1", &"piafabec_1", &"soporifik_1",
		&"route_11_item_1", &"route_11_item_2"]
	expected.append_array(TRAINERS.keys())
	expected.sort()
	assert_eq(keys, expected, "8 Dresseurs, 3 Pokémon d'ambiance, 2 objets (Ronflex : décor)")


func test_trainers_follow_the_grid_and_the_dossier() -> void:
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
		assert_eq(String(spec.trainer_id), _plan.attr(plan_id, "trainer"), "%s : id de la grille" % key)
		assert_eq(spec.trainer_id, info[1], key)
		assert_eq(spec.sprite, info[2], "%s : apparence" % key)
		assert_true(Npc.has_frames(spec.sprite), "%s : planche" % key)
		assert_false(spec.has_route(), "%s : immobile" % key)
		var trainer := _trainers.get_trainer(spec.trainer_id)
		assert_not_null(trainer, String(spec.trainer_id))
		if trainer == null:
			continue
		var team: Array = []
		for member: Variant in trainer.team:
			team.append([member.species, member.level])
		assert_eq(team, info[3], "%s : équipe" % key)
		assert_eq(trainer.prize_for(int((info[3] as Array)[-1][1])), info[4],
			"%s : récompense du §6" % key)
		assert_eq(spec.before_dialogue, StringName(String(spec.trainer_id) + "_before"))
		assert_eq(spec.defeated_dialogue, StringName(String(spec.trainer_id) + "_defeated"))
		assert_eq(spec.dialogue, StringName(String(spec.trainer_id) + "_after"))
		for line: StringName in [spec.before_dialogue, spec.defeated_dialogue, spec.dialogue]:
			var dialogue := _dialogues.get_dialogue(line)
			assert_not_null(dialogue, String(line))
			if dialogue != null:
				assert_eq(dialogue.speaker, trainer.name, "%s : locuteur" % line)


func test_louis_is_on_the_north_route_and_stays_level_17() -> void:
	# Écart de la vue générale (dossier 20) : Louis n'est pas près de la Cave. Décision de Kevin :
	# il reste au Nv. 17.
	var spec := _roster.get_spec(&"youngster_louis")
	assert_eq(spec.cell, Vector2i(31, 7))
	assert_gt(spec.cell.x, 28, "loin de la clairière de la Cave")
	for member: Variant in _trainers.get_trainer(&"route_11_youngster_louis").team:
		assert_eq(member.level, 17)


func test_trainers_stand_on_their_grid_cell_in_the_real_scene() -> void:
	for key: StringName in TRAINERS:
		var npc := _map.get_npc(key)
		assert_not_null(npc, "%s posé sur la carte" % key)
		if npc != null:
			assert_true(_map.get_grid().is_occupied(npc.get_cell()), "%s occupe sa case" % key)


func test_arthur_cannot_be_avoided_on_the_real_map() -> void:
	var spec := _roster.get_spec(&"youngster_arthur")
	var sight := _sight(spec)
	assert_eq(sight.size(), spec.sight, "vue dégagée")
	for targets: Array in [MOUTH, FRONT]:
		assert_lt(_reach(_with_npcs(), targets), INF, "atteignable avec les PNJ")
		assert_eq(_reach(_with_npcs(sight), targets), INF, "Arthur inévitable")


func test_the_seven_others_can_be_avoided_alone_and_together() -> void:
	var seen: Array[Vector2i] = []
	for key: StringName in AVOIDABLE:
		var sight := _sight(_roster.get_spec(key))
		assert_gt(sight.size(), 0, "%s voit devant lui" % key)
		for targets: Array in [MOUTH, FRONT]:
			assert_lt(_reach(_with_npcs(sight), targets), INF, "%s évitable" % key)
		seen.append_array(sight)
	for targets: Array in [MOUTH, FRONT]:
		assert_lt(_reach(_with_npcs(seen), targets), INF, "évitables ensemble")


func test_ambient_pokemon_follow_the_grid() -> void:
	var expected := {&"piafabec_1": &"fly", &"soporifik_1": &"notice", &"abo_1": &"flee"}
	for key: StringName in expected:
		var spec := _roster.get_spec(key)
		assert_eq(spec.cell, _plan.cell_of(String(key)), key)
		assert_eq(spec.shy_action, expected[key], "%s : réaction" % key)
		assert_false(spec.is_interactive(), key)
		assert_true(Npc.has_frames(spec.sprite), "%s : planche" % key)
