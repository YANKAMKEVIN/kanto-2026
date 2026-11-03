extends GutTest
## SafeArea (portage iOS) : retraits de la zone sûre convertis en unités de canevas, et
## application à un Control plein écran avec compensation des enfants qui couvrent tout.

const CANVAS := Vector2(2340, 1080)


func test_no_cutout_means_no_insets() -> void:
	var window := Rect2i(0, 0, 2340, 1080)
	assert_eq(SafeArea.insets_for(window, window, CANVAS), Vector4.ZERO)


func test_iphone_landscape_notch_left_and_home_bar() -> void:
	# iPhone 16 Pro en paysage, encoche à gauche (177 px) et barre d'accueil en bas (63 px),
	# fenêtre 2622×1206 pour un canevas 2344×1080 (rapport ≈ 0,8955).
	var window := Rect2i(0, 0, 2622, 1206)
	var safe := Rect2i(177, 0, 2622 - 177, 1206 - 63)
	var insets := SafeArea.insets_for(safe, window, Vector2(2344, 1080))
	assert_almost_eq(insets.x, 177 * 2344.0 / 2622.0, 0.01, "gauche = encoche")
	assert_eq(insets.y, 0.0, "haut libre")
	assert_eq(insets.z, 0.0, "droite libre")
	assert_almost_eq(insets.w, 63 * 1080.0 / 1206.0, 0.01, "bas = barre d'accueil")


func test_window_offset_is_taken_into_account() -> void:
	# Fenêtre qui ne commence pas en 0,0 (bureau) : les retraits se mesurent à la fenêtre.
	var window := Rect2i(100, 50, 1920, 1080)
	var safe := Rect2i(0, 0, 1920 + 100, 1080 + 50)
	assert_eq(SafeArea.insets_for(safe, window, Vector2(1920, 1080)), Vector4.ZERO)
	var safe_cut := Rect2i(0, 0, 2020 - 40, 1130 - 20)
	assert_eq(SafeArea.insets_for(safe_cut, window, Vector2(1920, 1080)), Vector4(0, 0, 40, 20))


func test_degenerate_rects_give_zero() -> void:
	assert_eq(SafeArea.insets_for(Rect2i(), Rect2i(0, 0, 100, 100), CANVAS), Vector4.ZERO)
	assert_eq(SafeArea.insets_for(Rect2i(0, 0, 100, 100), Rect2i(), CANVAS), Vector4.ZERO)


func test_apply_shrinks_root_and_compensates_children() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(flash)
	add_child_autofree(root)
	SafeArea.apply(root, Vector4(150, 0, 10, 56), [flash] as Array[Control])
	assert_eq(root.offset_left, 150.0)
	assert_eq(root.offset_top, 0.0)
	assert_eq(root.offset_right, -10.0)
	assert_eq(root.offset_bottom, -56.0)
	assert_eq(flash.offset_left, -150.0)
	assert_eq(flash.offset_right, 10.0)
	assert_eq(flash.offset_bottom, 56.0)
