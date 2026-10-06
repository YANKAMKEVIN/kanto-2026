extends GutTest
## Routines retenues tant qu'aucun joueur n'est sur la carte (DA.2) : [method
## Npc.set_routine_held] fige la boucle (temps simulé), le relâchement la relance après la pause
## habituelle ; [GameMap] retient les routines de ses PNJ et les relâche à l'arrivée du joueur.

const FrameSim := preload("res://tests/helpers/frame_sim.gd")
const NPC_SCENE := "res://game/world/npc/npc.tscn"
const CELL := Vector2i(3, 3)


func _walker(grid: GridWorld) -> Npc:
	var spec := NpcSpec.new()
	spec.id = &"walker"
	spec.cell = CELL
	spec.sprite = &"villager"
	spec.route_cells = [CELL, CELL + Vector2i.RIGHT] as Array[Vector2i]
	spec.route_pause = 0.1
	var npc := (load(NPC_SCENE) as PackedScene).instantiate() as Npc
	npc.setup(spec)
	npc.set_routine_held(true)
	add_child_autofree(npc)
	assert_true(npc.enter_grid(grid))
	return npc


func test_held_routine_does_not_move_then_resumes_when_released() -> void:
	var npc := _walker(GridWorld.new(Vector2i(8, 8)))
	var sim := FrameSim.new(get_tree(), [npc])
	for i in 60:
		await sim.frame()
	assert_eq(npc.get_cell(), CELL, "retenu : immobile une seconde (simulée)")
	assert_false(npc.is_moving())
	npc.set_routine_held(false)
	var moved := false
	for i in 60:
		await sim.frame()
		if npc.is_moving() or npc.get_cell() != CELL:
			moved = true
			break
	sim.finish()
	assert_true(moved, "relâché : la boucle reprend")


func test_map_releases_routines_when_the_player_arrives() -> void:
	var map := (load("res://game/world/maps/pallet_town.tscn") as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(map)
	var haru := map.get_npc(&"haru")
	assert_true(haru.is_routine_held(), "sans joueur")
	var player := (load("res://game/player/player.tscn") as PackedScene).instantiate() as Player
	map.spawn_player(player, &"start", Vector2i.DOWN)
	assert_false(haru.is_routine_held(), "joueur arrivé")
	assert_false(map.get_npc(&"aoki_pidgey_1").is_routine_held(), "sans routine : rien à retenir")
