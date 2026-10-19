extends GutTest
## Cases libérées par un drapeau (jalon-17.md §2.4, T5) : une [FlagGate] à
## [member FlagGate.blocking_cells] (mécanisme du jalon 15, adopté par le J16 pour les arbustes)
## sur une carte de test. Bloc 2 × 2 « Ronflex » qui ferme toute la largeur d'un couloir :
## fermé tant que le drapeau manque, libéré pendant la visite sans changer de carte (appel de
## Boot), libéré après rechargement, y compris **au placement** d'une reprise de sauvegarde
## (SceneRouter.arrival_flags), et `find_reachable` avant / après.

const ROUTER_SCRIPT := preload("res://game/autoload/scene_router.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const AWAKE := &"test_j17_block_awake"
## Couloir 10 × 2 : bloc 2 × 2 sur les colonnes 5..6, départ à l'ouest, cul-de-sac à l'est.
const MAP_SIZE := Vector2i(10, 2)
const BLOCK_CELLS: Array[Vector2i] = [
	Vector2i(5, 0), Vector2i(6, 0), Vector2i(5, 1), Vector2i(6, 1),
]
const WEST := Vector2i(1, 0)
const EAST := Vector2i(9, 1)


## Carte du couloir ; le bloc est un décor de `Entities` (comme le jeune arbre de Carmin).
func _make_map(_map_id: StringName = &"block_map") -> GameMap:
	var map := GameMap.new()
	map.name = "BlockMap"
	map.map_id = &"block_map"
	map.size = MAP_SIZE
	for group: String in ["Entities", "Spawns", "Warps"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		map.add_child(node)
	var marker := Marker2D.new()
	marker.name = "west"
	marker.position = Grid.cell_to_world(WEST)
	map.get_node(^"Spawns").add_child(marker)
	var gate := FlagGate.new()
	gate.name = "Block"
	gate.unless_flags = [AWAKE] as Array[StringName]
	gate.blocking_cells = BLOCK_CELLS.duplicate()
	map.get_entities().add_child(gate)
	return map


func _flags(names: Array[StringName]) -> StoryFlags:
	var flags := StoryFlags.new()
	for name: StringName in names:
		flags.set_flag(name)
	return flags


func _gate(map: GameMap) -> FlagGate:
	return map.get_node(^"Entities/Block") as FlagGate


func _assert_closed(map: GameMap, context: String) -> void:
	var grid := map.get_grid()
	for cell: Vector2i in BLOCK_CELLS:
		assert_eq(grid.get_occupant(cell), _gate(map), "%s : %s bloquée" % [context, cell])
	assert_false(grid.find_reachable(WEST).has(EAST), "%s : l'est est fermé" % context)


func _assert_open(map: GameMap, context: String) -> void:
	var grid := map.get_grid()
	for cell: Vector2i in BLOCK_CELLS:
		assert_false(grid.is_occupied(cell), "%s : %s libre" % [context, cell])
	var reached := grid.find_reachable(WEST)
	assert_true(reached.has(EAST), "%s : l'est est atteignable" % context)
	for cell: Vector2i in BLOCK_CELLS:
		assert_true(reached.has(cell), "%s : %s praticable" % [context, cell])


func test_closed_without_the_flag() -> void:
	var map := _make_map()
	add_child_autofree(map)
	map.refresh_npcs(_flags([]))
	assert_true(_gate(map).visible)
	_assert_closed(map, "nouvelle partie")
	map.refresh_npcs(null)
	_assert_closed(map, "drapeaux absents (null)")
	assert_push_error_count(0)


func test_flag_raised_during_the_visit_frees_the_cells_without_changing_map() -> void:
	var map := _make_map()
	add_child_autofree(map)
	var flags := _flags([])
	map.refresh_npcs(flags)
	var grid := map.get_grid()
	_assert_closed(map, "avant")
	flags.set_flag(AWAKE)
	map.apply_flag_gates(flags)
	assert_same(map.get_grid(), grid, "même grille, aucune reconstruction")
	assert_false(_gate(map).visible, "décor caché")
	_assert_open(map, "pendant la visite")
	map.apply_flag_gates(flags)
	_assert_open(map, "appel répété")


func test_reload_with_the_flag_frees_the_cells() -> void:
	var map := _make_map()
	add_child_autofree(map)
	map.refresh_npcs(_flags([AWAKE]))
	assert_false(_gate(map).visible)
	_assert_open(map, "rechargement")
	map.rebuild_grid()
	_assert_open(map, "grille reconstruite")


func test_a_cell_taken_by_someone_else_is_never_stolen() -> void:
	var map := _make_map()
	add_child_autofree(map)
	var flags := _flags([AWAKE])
	map.refresh_npcs(flags)
	var walker := RefCounted.new()
	assert_true(map.get_grid().occupy(BLOCK_CELLS[0], walker))
	flags.set_flag(AWAKE, false)
	map.apply_flag_gates(flags)
	assert_eq(map.get_grid().get_occupant(BLOCK_CELLS[0]), walker, "l'occupant reste")
	assert_eq(map.get_grid().get_occupant(BLOCK_CELLS[1]), _gate(map))


# --- Reprise d'une sauvegarde : drapeaux appliqués avant le placement ----------------------

func _router_with(arrival: Callable) -> Array:
	var router: Node = ROUTER_SCRIPT.new()
	add_child_autofree(router)
	router.map_factory = _make_map
	var world := Node2D.new()
	add_child_autofree(world)
	var player := PLAYER_SCENE.instantiate() as Player
	autofree(player)
	router.setup(world, player, null)
	router.arrival_flags = arrival
	return [router, player]


func test_save_resumed_on_a_freed_cell_keeps_the_player_there() -> void:
	var flags := _flags([AWAKE])
	var made := _router_with(func() -> StoryFlags: return flags)
	var router: Node = made[0]
	var player: Player = made[1]
	var map: GameMap = router.start_at(&"block_map", BLOCK_CELLS[3], Vector2i.LEFT)
	assert_not_null(map)
	assert_eq(player.get_cell(), BLOCK_CELLS[3], "pas de décalage : la case est libre")
	assert_false(_gate(map).visible)
	assert_push_error_count(0)


func test_save_resumed_on_a_closed_cell_moves_the_player_aside() -> void:
	var flags := _flags([])
	var made := _router_with(func() -> StoryFlags: return flags)
	var player: Player = made[1]
	var map: GameMap = (made[0] as Node).start_at(&"block_map", BLOCK_CELLS[0], Vector2i.UP)
	assert_not_null(map)
	assert_false(BLOCK_CELLS.has(player.get_cell()), "jamais dans le bloc fermé")
	_assert_closed(map, "bloc fermé à la reprise")


func test_setup_clears_the_arrival_flags() -> void:
	var made := _router_with(func() -> StoryFlags: return null)
	var router: Node = made[0]
	assert_true((router.arrival_flags as Callable).is_valid())
	router.setup(Node2D.new(), null, null)
	assert_false((router.arrival_flags as Callable).is_valid())


# --- Boot : crochet de _on_flag_changed et branchement de l'arrivée ------------------------

func test_boot_frees_the_cells_when_the_flag_is_raised_during_the_visit() -> void:
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	add_child_autofree(boot)
	assert_true(SceneRouter.arrival_flags.is_valid(), "Boot branche les drapeaux d'arrivée")
	assert_same(SceneRouter.arrival_flags.call(), GameState.flags)
	GameState.flags.set_flag(AWAKE, false)
	var map := boot.get_map()
	var grid := map.get_grid()
	# Une case libre de la carte de départ, loin du joueur.
	var cell := Vector2i(-1, -1)
	for y: int in map.size.y:
		for x: int in map.size.x:
			var candidate := Vector2i(x, y)
			if cell.x < 0 and grid.is_free(candidate) and not grid.is_occupied(candidate):
				cell = candidate
	assert_ne(cell, Vector2i(-1, -1), "une case libre")
	var gate := FlagGate.new()
	gate.unless_flags = [AWAKE] as Array[StringName]
	gate.blocking_cells = [cell] as Array[Vector2i]
	map.get_entities().add_child(gate)
	map.apply_flag_gates(GameState.flags)
	assert_eq(grid.get_occupant(cell), gate, "bloquée")
	GameState.flags.set_flag(AWAKE)
	assert_false(grid.is_occupied(cell), "libérée sans changement de carte")
	GameState.flags.set_flag(AWAKE, false)
	assert_eq(grid.get_occupant(cell), gate)
