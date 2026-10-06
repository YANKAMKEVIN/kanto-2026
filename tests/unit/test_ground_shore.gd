extends GutTest
## Rivage du sol peint (DA.2) : masque R = sable, G = eau ([method GroundMask.build_shore]),
## lu par [method GroundMask.shore_at] ; [PaintedGround] ne charge sable et mer que s'il en a un.


func test_shore_mask_channels() -> void:
	var sand: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	var water: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 1)]
	var shore := GroundMask.build_shore(Vector2i(3, 2), sand, water)
	assert_eq(shore.get_size(), Vector2i(3, 2))
	assert_eq(GroundMask.shore_at(shore, Vector2i(0, 0)), GroundMask.Kind.SAND)
	assert_eq(GroundMask.shore_at(shore, Vector2i(1, 0)), GroundMask.Kind.WATER, "eau gagne")
	assert_gt(shore.get_pixelv(Vector2i(1, 0)).r, 0.5, "sable sous l'eau gardé")
	assert_eq(GroundMask.shore_at(shore, Vector2i(2, 1)), GroundMask.Kind.WATER)
	assert_eq(GroundMask.shore_at(shore, Vector2i(0, 1)), GroundMask.Kind.GRASS)
	assert_eq(GroundMask.shore_at(shore, Vector2i(9, 9)), GroundMask.Kind.GRASS, "hors masque")
	assert_eq(GroundMask.shore_at(null, Vector2i.ZERO), GroundMask.Kind.GRASS)


func test_painted_ground_without_shore_loads_neither_sand_nor_water() -> void:
	var ground := PaintedGround.new()
	ground.size = Vector2i(4, 4)
	ground.mask = ImageTexture.create_from_image(GroundMask.build(Vector2i(4, 4), {}))
	var material := ground.get_shader_material()
	assert_false(material.get_shader_parameter(&"has_shore"))
	assert_null(material.get_shader_parameter(&"water_texture"))
	ground.shore_mask = ImageTexture.create_from_image(
		GroundMask.build_shore(Vector2i(4, 4), [Vector2i(0, 3)], [Vector2i(0, 3)]))
	assert_true(material.get_shader_parameter(&"has_shore"))
	assert_not_null(material.get_shader_parameter(&"sand_texture"))
	assert_not_null(material.get_shader_parameter(&"water_texture"))
	ground.free()
