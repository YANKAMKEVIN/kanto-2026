extends GutTest
## Rivage **sans sable** (jalon 13 T6, canaux d'Azuria, rivière de la Route 24) :
## [method GroundMask.build_water] ne met que de l'eau (canal vert), jamais de sable.


func test_water_mask_has_no_sand() -> void:
	var size := Vector2i(6, 5)
	var water: Dictionary = {Vector2i(2, 0): true, Vector2i(2, 1): true, Vector2i(3, 1): true,
		Vector2i(9, 9): true}
	var mask := GroundMask.build_water(size, water)
	assert_eq(mask.get_size(), size)
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var pixel := mask.get_pixelv(cell)
			assert_eq(pixel.r, 0.0, "%s : aucun sable" % cell)
			var expected := GroundMask.Kind.WATER if water.has(cell) else GroundMask.Kind.GRASS
			assert_eq(GroundMask.shore_at(mask, cell), expected, "%s" % cell)


func test_water_mask_equals_a_shore_without_sand() -> void:
	var water: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]
	var size := Vector2i(3, 3)
	assert_eq(GroundMask.build_water(size, water).get_data(),
		GroundMask.build_shore(size, [], water).get_data())


func test_empty_water_mask_is_all_grass() -> void:
	var mask := GroundMask.build_water(Vector2i(2, 2), [])
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(1, 1)]:
		assert_eq(GroundMask.shore_at(mask, cell), GroundMask.Kind.GRASS)
