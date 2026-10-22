extends GutTest
## Tour 2F-7F sur A17 (J21, QA de nuit : 35-41 i/s, cause = calques plein écran) : le sol peint
## et les couches immobiles au-dessus (rebords, escaliers, ombrage, lumière de sol) sont cuits
## une fois ; la brume est dessinée dans la passe du sol ; l'étalonnage de la Tour est à plat.

const FLOORS := [2, 3, 4, 5, 6, 7]


func after_each() -> void:
	MistLayer.set_reduce_motion(false)


func _floor(number: int) -> GameMap:
	var map: Node = (load("res://game/world/maps/pokemon_tower_%df.tscn" % number) as PackedScene).instantiate()
	add_child_autofree(map)
	return map as GameMap


func _baked_ground(number: int) -> PaintedGround:
	var ground := _floor(number).get_node(^"PaintedGround") as PaintedGround
	ground.bake()
	await wait_until(ground.is_baked, 2.0, "cuisson")
	return ground


func test_every_floor_bakes_its_ground_and_static_cave_layers() -> void:
	for number: int in FLOORS:
		var ground := _floor(number).get_node(^"PaintedGround") as PaintedGround
		assert_true(ground.can_bake(), "%dF : sol sans rivage, 20 × 18 cases" % number)
		var names: Array = ground.stack_layers().map(func(n: Node) -> StringName: return n.name)
		assert_eq(names, [&"GroundDecals", &"CaveShade", &"CaveFloorLight"], "%dF" % number)


func test_bake_hides_the_baked_layers_and_keeps_the_rest() -> void:
	var ground: PaintedGround = await _baked_ground(6)
	var map := ground.get_parent()
	for name: String in ["GroundDecals", "CaveShade", "CaveFloorLight"]:
		assert_false((map.get_node(name) as CanvasItem).visible, name + " cuit")
	for name: String in ["Entities", "Glows"]:
		assert_true((map.get_node(name) as CanvasItem).visible, name + " vivant")
	assert_eq(ground.material.shader, PaintedGround.SHADER, "matériau source inchangé")


func test_6f_mist_is_drawn_by_the_ground_and_follows_its_gate() -> void:
	var ground: PaintedGround = await _baked_ground(6)
	var map := ground.get_parent()
	var dense := map.get_node(^"MistDenseGate/Mist") as MistLayer
	var light := map.get_node(^"MistLightGate/MistLight") as MistLayer
	assert_true(dense.is_merged())
	assert_true(light.is_merged())
	assert_true(dense.is_misting(), "toujours l'autorité logique")
	(map.get_node(^"MistLightGate") as CanvasItem).visible = false
	ground.refresh_mist()
	assert_almost_eq(ground.get_merged_mist_alpha(), 0.18, 0.0001, "brume dense")
	(map.get_node(^"MistDenseGate") as CanvasItem).visible = false
	(map.get_node(^"MistLightGate") as CanvasItem).visible = true
	assert_almost_eq(ground.get_merged_mist_alpha(), 0.072, 0.0001, "brume levée, plus légère")
	MistLayer.set_reduce_motion(true)
	assert_eq(ground.get_merged_mist_alpha(), 0.0, "Réduire les animations : aucune brume")


func test_unbaked_ground_leaves_the_mist_layer_drawing_itself() -> void:
	var map := _floor(7)
	var mist: MistLayer = map.find_children("*", "Sprite2D", true, false).filter(
		func(n: Node) -> bool: return n is MistLayer)[0]
	assert_false((map.get_node(^"PaintedGround") as PaintedGround).is_baked())
	assert_false(mist.is_merged(), "sous GUT (headless) rien n'est cuit d'office")


func test_ground_bake_rules() -> void:
	assert_true(PaintedGround.bake_allowed(Vector2i(20, 18), false))
	assert_false(PaintedGround.bake_allowed(Vector2i(20, 18), true), "rivage : l'eau ondule")
	assert_false(PaintedGround.bake_allowed(Vector2i(60, 60), false), "trop grand")
	assert_false(PaintedGround.bake_allowed(Vector2i(50, 4), false), "côté > 4096 px")
	assert_false(PaintedGround.bake_allowed(Vector2i.ZERO, false))


func test_static_layer_rules() -> void:
	var plain := Node2D.new()
	plain.add_child(Sprite2D.new())
	plain.add_child(Polygon2D.new())
	assert_true(PaintedGround.is_static_layer(plain))
	var animated := AnimatedSprite2D.new()
	plain.add_child(animated)
	assert_false(PaintedGround.is_static_layer(plain), "une animation ne se cuit pas")
	animated.free()
	var gate := FlagGate.new()
	plain.add_child(gate)
	assert_false(PaintedGround.is_static_layer(plain), "porte de drapeaux : change en jeu")
	gate.free()
	var hidden := Sprite2D.new()
	hidden.visible = false
	assert_false(PaintedGround.is_static_layer(hidden), "caché : peut apparaître")
	plain.free()
	hidden.free()
