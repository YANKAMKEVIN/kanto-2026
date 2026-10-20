extends GutTest
## Ascenseur du repaire (jalon 20 T21, `jalon-20.md` §2.3, §2.7 ; dossier 23 §13.2, §13.4, §20.7
## n° 50) avec la vraie scène Boot, les vraies cartes et les vraies entrées :
## - le panneau ne propose que B1F, B2F et B4F (RB), clé `lift_key` ;
## - sans la Clé : n° 50, aucun panneau ; avec la Clé : B1F → B4F, sortie dans la moitié est ;
## - **le B4F est n'est atteint que par l'ascenseur** : tout escalier qui mène au B4F arrive dans
##   la moitié ouest, d'où l'on n'atteint ni Giovanni, ni les gardes, ni la porte de la cabine.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const START := "res://tools/debug_start/rocket_hideout_lift.json"
const CABIN := &"rocket_hideout_elevator"
const B4F := &"rocket_hideout_b4f"
const KEY := &"lift_key"
const LOCKED := "Le panneau ne répond pas. Il faut une clé."
const MAPS: Array[StringName] = [&"celadon_game_corner", &"rocket_hideout_b1f",
	&"rocket_hideout_b2f", &"rocket_hideout_b3f", &"rocket_hideout_b4f", CABIN]
## Cases de la moitié est du B4F (grille `repaire_b4f.txt`).
const GIOVANNI := Vector2i(25, 3)
const GUARDS: Array[Vector2i] = [Vector2i(23, 12), Vector2i(26, 12)]
const ELEVATOR_DOORS: Array[Vector2i] = [Vector2i(24, 15), Vector2i(25, 15)]

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, "user://test_hideout_elevator.json")
	_play.setup()


func after_each() -> void:
	_play.teardown()


func test_the_hideout_lift_serves_b1f_b2f_and_b4f_with_the_key() -> void:
	var library := ElevatorLibrary.new()
	assert_true(library.load_file())
	var spec := library.get_elevator(&"rocket_hideout")
	assert_not_null(spec)
	if spec == null:
		return
	assert_eq(spec.key, KEY)
	assert_eq(spec.car, CABIN)
	var labels: Array = spec.floors.map(func(f: Dictionary) -> String: return f["label"])
	assert_eq(labels, ["B1F", "B2F", "B4F"], "B3F n'est pas desservi (RB)")


func test_without_the_key_the_panel_refuses_then_with_it_the_ride_reaches_b4f() -> void:
	await _play.start(START, func() -> void: GameState.bag.remove(KEY, 1))
	var director := _play.boot.get_elevator_director()
	assert_eq(GameState.bag.count_of(KEY), 0)
	assert_eq(_play.map_id(), &"rocket_hideout_b1f")
	await _play.step(Vector2i.DOWN)
	assert_eq(_play.map_id(), CABIN, "dans la cabine")
	assert_eq(director.get_current_floor(), &"b1f")
	await _go_to_the_panel()
	await _play.interact(Vector2i.UP)
	assert_eq(_play.pages(), [LOCKED] as Array[String], "n° 50")
	assert_false(director.is_panel_open(), "aucun panneau sans la Clé")
	# Avec la Clé.
	GameState.bag.add(KEY)
	_play.events.clear()
	await _play.interact(Vector2i.UP)
	await wait_until(func() -> bool: return director.is_panel_open(), 5.0)
	assert_true(director.is_panel_open(), "panneau ouvert")
	var view := director.panel_view()
	assert_eq(view.floors.map(func(f: Dictionary) -> String: return f["label"]),
		["B1F", "B2F", "B4F"])
	assert_eq(view.current_floor(), &"b1f")
	director.get_panel().floor_chosen.emit(&"b4f")
	await wait_until(func() -> bool: return _play.boot.is_stable(), 15.0)
	assert_eq(director.get_current_floor(), &"b4f")
	await _play.walk_to(_door_cell())
	assert_eq(_play.map_id(), B4F, "sortie au B4F")
	assert_eq(_play.player.get_cell(), Vector2i(25, 14), "devant la porte de l'ascenseur, moitié est")
	var reachable := _play.boot.get_map().get_grid().find_reachable(_play.player.get_cell(),
		_play.player)
	assert_true(reachable.has(GIOVANNI + Vector2i.LEFT) or reachable.has(Vector2i(25, 12)),
		"la porte du bureau et Giovanni sont de ce côté")
	assert_push_error_count(0)


func test_b4f_east_is_reached_only_by_the_lift() -> void:
	# Tout passage qui mène au B4F, hors cabine, arrive dans la moitié ouest.
	var arrivals: Array[StringName] = []
	for id: StringName in MAPS:
		var map := (load(MapCatalog.scene_path(id)) as PackedScene).instantiate() as GameMap
		add_child_autofree(map)
		for warp: Warp in map.get_warps().get_all():
			if warp.target_map == B4F:
				assert_ne(id, CABIN, "la cabine sort au B1F (réorientée par l'ascenseur)")
				arrivals.append(warp.target_spawn)
	assert_eq(arrivals, [&"from_b3f"] as Array[StringName], "un seul escalier, depuis le B3F")
	var b4f := (load(MapCatalog.scene_path(B4F)) as PackedScene).instantiate() as GameMap
	add_child_autofree(b4f)
	var size := b4f.get_grid().get_size()
	# Porte du bureau ouverte (pire cas) : relief seul, sans les occupants.
	var grid := GridPaths.relief(b4f.get_grid(), size)
	var west := GridPaths.distances(grid, [b4f.get_spawn_cell(&"from_b3f")])
	for cell: Vector2i in [GIOVANNI + Vector2i.LEFT, b4f.get_spawn_cell(&"from_elevator")] \
			+ GUARDS + ELEVATOR_DOORS:
		assert_false(west.has(cell), "%s inatteignable depuis l'escalier du B3F" % cell)
	var east := GridPaths.distances(grid, [b4f.get_spawn_cell(&"from_elevator")])
	assert_true(east.has(GIOVANNI + Vector2i.LEFT), "Giovanni atteint depuis l'ascenseur")
	var library := ElevatorLibrary.new()
	assert_true(library.load_file())
	for floor: Dictionary in library.get_elevator(&"rocket_hideout").floors:
		if floor["map"] == String(B4F):
			assert_eq(floor["spawn"], "from_elevator", "l'ascenseur sort dans la moitié est")


## La cabine : de l'entrée jusqu'à la case sous le panneau (1, 1), tourné ↑.
func _go_to_the_panel() -> void:
	await _play.walk_to(Vector2i(1, 2))
	assert_eq(_play.player.get_cell(), Vector2i(1, 2), "sous le panneau")


func _door_cell() -> Vector2i:
	var warps := _play.boot.get_map().get_warps().get_all()
	return warps[0].cell
