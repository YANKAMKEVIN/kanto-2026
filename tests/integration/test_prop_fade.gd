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
