extends GutTest
## Transparence des props hauts (feuillages, toits) quand le joueur passe derrière.

const TREE_SCENE := "res://game/world/props/tree_oak_a.tscn"
const FENCE_SCENE := "res://game/world/props/fence_picket.tscn"
const PLAYER_SCENE := "res://game/player/player.tscn"

var _player: Player


func before_each() -> void:
	_player = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	add_child_autofree(_player)


func _tree_at(cell: Vector2i) -> WorldProp:
	var tree := (load(TREE_SCENE) as PackedScene).instantiate() as WorldProp
	tree.position = Grid.cell_to_world(cell)
	add_child_autofree(tree)
	return tree


func _sprite_alpha(prop: WorldProp) -> float:
	return (prop.get_node(^"%Sprite") as Sprite2D).modulate.a


func _run(prop: WorldProp, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		prop._process(1.0 / 60.0)
		t += 1.0 / 60.0


func test_covers_requires_body_behind_and_overlap() -> void:
	var sprite := Rect2(0, 0, 288, 384)
	assert_true(WorldProp.covers(sprite, 384.0, Rect2(100, 200, 64, 128)))
	assert_false(WorldProp.covers(sprite, 384.0, Rect2(100, 300, 64, 128)), "devant")
	assert_false(WorldProp.covers(sprite, 384.0, Rect2(400, 200, 64, 128)), "à côté")


func test_tree_fades_when_player_behind_then_restores() -> void:
	var tree := _tree_at(Vector2i(5, 5))
	_player.position = Grid.cell_to_world(Vector2i(5, 4))
	_run(tree, 0.5)
	assert_almost_eq(_sprite_alpha(tree), WorldProp.COVERED_ALPHA, 0.001)
	_player.position = Grid.cell_to_world(Vector2i(5, 6))
	_run(tree, 0.5)
	assert_almost_eq(_sprite_alpha(tree), 1.0, 0.001)


func test_tree_stays_opaque_when_player_far() -> void:
	var tree := _tree_at(Vector2i(5, 5))
	_player.position = Grid.cell_to_world(Vector2i(12, 4))
	_run(tree, 0.5)
	assert_eq(_sprite_alpha(tree), 1.0)


func test_fences_do_not_fade() -> void:
	var fence := (load(FENCE_SCENE) as PackedScene).instantiate() as WorldProp
	add_child_autofree(fence)
	assert_false(fence.fade_when_covering)
	assert_false(fence.is_processing())


func test_interior_plant_fades_when_player_behind() -> void:
	var plant := (load("res://game/world/props/interior/plant.tscn") as PackedScene).instantiate() as WorldProp
	plant.position = Grid.cell_to_world(Vector2i(4, 9))
	add_child_autofree(plant)
	assert_true(plant.fade_when_covering)
	_player.position = Grid.cell_to_world(Vector2i(4, 8))
	_run(plant, 0.5)
	assert_almost_eq(_sprite_alpha(plant), WorldProp.COVERED_ALPHA, 0.001)


## QA T5 (Jadielle) : un mur de soutènement sépare deux niveaux ; la rangée du mur (escalier)
## appartient au niveau du haut.
func test_same_level_is_split_by_walls() -> void:
	var walls: Array[int] = [12, 24]
	assert_true(WorldProp.same_level(13, 23, walls), "même terrasse")
	assert_false(WorldProp.same_level(23, 28, walls), "rue au-dessus d'un toit du bas")
	assert_true(WorldProp.same_level(24, 23, walls), "escalier = niveau du haut")
	assert_false(WorldProp.same_level(24, 25, walls))
	assert_true(WorldProp.same_level(3, 40, [] as Array[int]), "un seul niveau")


func test_tree_below_a_wall_stays_opaque_for_a_player_above() -> void:
	var tree := _tree_at(Vector2i(5, 5))
	tree.level_rows = [4] as Array[int]
	_player.position = Grid.cell_to_world(Vector2i(5, 3))
	_run(tree, 0.5)
	assert_eq(_sprite_alpha(tree), 1.0, "joueur sur la terrasse du dessus")
	tree.level_rows = [] as Array[int]
	_run(tree, 0.5)
	assert_almost_eq(_sprite_alpha(tree), WorldProp.COVERED_ALPHA, 0.001, "sans mur : effacé")
