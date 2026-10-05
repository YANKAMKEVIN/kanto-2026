extends GutTest
## FaceoffScale (prototype du combat face à face) : présence selon la taille réelle,
## compressée et bornée ; l'adversaire plus petit ; boîtes maximales respectées.

const BOX := Vector2(400.0, 420.0)


func test_reference_height_gives_reference_presence() -> void:
	assert_almost_eq(FaceoffScale.presence(FaceoffScale.REFERENCE_HEIGHT_M, true),
		FaceoffScale.REFERENCE_PRESENCE, 0.01)


func test_presence_grows_with_height_but_compressed() -> void:
	var small := FaceoffScale.presence(0.3, true)
	var mid := FaceoffScale.presence(0.6, true)
	var big := FaceoffScale.presence(2.0, true)
	assert_lt(small, mid)
	assert_lt(mid, big)
	# 2 m contre 0,6 m : plus de trois fois plus grand en réel, bien moins à l'écran.
	assert_lt(big / mid, 2.0 / 0.6)


func test_presence_is_bounded() -> void:
	assert_eq(FaceoffScale.presence(8.8, true), FaceoffScale.MAX_PRESENCE)
	assert_eq(FaceoffScale.presence(0.1, true), FaceoffScale.MIN_PRESENCE)


func test_foe_is_smaller_by_depth() -> void:
	assert_almost_eq(FaceoffScale.presence(0.6, false),
		FaceoffScale.presence(0.6, true) * FaceoffScale.FOE_DEPTH, 0.01)


func test_scale_respects_max_boxes() -> void:
	for is_player: bool in [true, false]:
		var limit: Vector2 = FaceoffScale.PLAYER_MAX_BOX if is_player \
			else FaceoffScale.FOE_MAX_BOX
		var scale := FaceoffScale.sprite_scale(BOX, 8.8, is_player)
		assert_lte(BOX.x * scale, limit.x + 0.01)
		assert_lte(BOX.y * scale, limit.y + 0.01)


func test_long_morphology_uses_area_not_height() -> void:
	# Même taille réelle, artwork long et bas contre artwork carré : même présence (aire).
	var wide := Vector2(430.0, 200.0)
	var square := Vector2(293.0, 293.0)
	var a := FaceoffScale.sprite_scale(wide, 0.6, true)
	var b := FaceoffScale.sprite_scale(square, 0.6, true)
	assert_almost_eq(sqrt(wide.x * wide.y) * a, sqrt(square.x * square.y) * b, 0.5)


func test_scale_follows_view_height() -> void:
	var base := FaceoffScale.sprite_scale(BOX, 0.6, true, 1080.0)
	assert_almost_eq(FaceoffScale.sprite_scale(BOX, 0.6, true, 540.0), base / 2.0, 0.0001)


func test_empty_box_is_safe() -> void:
	assert_eq(FaceoffScale.sprite_scale(Vector2.ZERO, 0.6, true), 1.0)
