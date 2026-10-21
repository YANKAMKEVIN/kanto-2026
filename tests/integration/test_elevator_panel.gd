extends GutTest
## Écran du panneau d'étages (jalon 20 T14, `jalon-20.md` §2.3.4) : cartes, étage courant grisé,
## signaux, cibles tactiles, marges, ouverture animée (temps simulé) et « Réduire les animations ».

const TweenClock := preload("res://tests/helpers/tween_clock.gd")

var _library: ElevatorLibrary
var _chosen: Array[StringName] = []
var _closed: int = 0


func before_all() -> void:
	_library = ElevatorLibrary.new()
	_library.load_file(ElevatorLibrary.DATA_PATH)


func _panel(reduce: bool = true) -> ElevatorPanel:
	_chosen.clear()
	_closed = 0
	var panel := ElevatorPanel.new()
	panel.reduce_motion = reduce
	add_child_autofree(panel)
	panel.floor_chosen.connect(func(id: StringName) -> void: _chosen.append(id))
	panel.closed.connect(func() -> void: _closed += 1)
	return panel


func _view(count: int, current: int) -> ElevatorPanelView:
	var view := ElevatorPanelView.new()
	for i: int in count:
		view.floors.append({"id": StringName("f%d" % i), "label": "E%d" % i,
			"current": i == current})
	return view


func test_current_floor_is_disabled_and_inert() -> void:
	var panel := _panel()
	panel.open(ElevatorPanelView.build(_library.get_elevator(&"celadon_dept"), &"3f"))
	assert_true(panel.is_open())
	assert_eq(panel.get_title_label().text, "Quel étage ?")
	assert_eq(panel.get_close_button().text, "FERMER")
	assert_true(panel.get_floor_button(&"3f").disabled, "étage courant grisé")
	assert_false(panel.get_floor_button(&"gf").disabled)
	panel.get_floor_button(&"2f").pressed.emit()
	assert_eq(_chosen, [&"2f"] as Array[StringName])
	panel.get_close_button().pressed.emit()
	assert_eq(_closed, 1)


func test_columns_follow_floor_count() -> void:
	var panel := _panel()
	panel.open(_view(3, 1))
	assert_eq(panel.get_columns(), 1, "repaire : une colonne")
	panel.open(_view(6, 0))
	assert_eq(panel.get_columns(), 2, "magasin à 6 étages : deux colonnes")


func test_touch_targets_and_safe_margins_at_both_widths() -> void:
	for width: int in [1920, 2340]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(width, 1080)
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child_autofree(viewport)
		var panel := ElevatorPanel.new()
		panel.reduce_motion = true
		viewport.add_child(panel)
		panel.open(_view(6, 4))
		await wait_frames(3)
		var buttons: Array[Button] = [panel.get_close_button()]
		for i: int in 6:
			buttons.append(panel.get_floor_button(StringName("f%d" % i)))
		for button: Button in buttons:
			var rect := button.get_global_rect()
			assert_gte(rect.size.y, float(UiTokens.TOUCH_MIN) - 0.5, "%s : hauteur" % button.name)
			assert_gte(rect.size.x, float(UiTokens.TOUCH_MIN), "%s : largeur" % button.name)
			assert_gte(rect.position.x, float(UiTokens.SAFE_MARGIN))
			assert_gte(rect.position.y, float(UiTokens.SAFE_MARGIN))
			assert_lte(rect.end.x, float(width - UiTokens.SAFE_MARGIN))
			assert_lte(rect.end.y, float(1080 - UiTokens.SAFE_MARGIN))


func test_open_and_close_are_animated_in_simulated_time() -> void:
	var clock := TweenClock.new(get_tree())
	var panel := _panel(false)
	panel.open(_view(3, 0))
	var root := panel.get_node("Root") as Control
	assert_eq(root.modulate.a, 0.0, "départ transparent")
	clock.step()
	assert_gt(root.modulate.a, 0.0)
	assert_lt(root.modulate.a, 1.0, "ouverture en cours")
	clock.run_until(func() -> bool: return root.modulate.a >= 1.0)
	assert_eq(root.modulate.a, 1.0)
	panel.close()
	assert_false(panel.is_open())
	assert_true(panel.visible, "fondu de fermeture en cours")
	clock.run_until(func() -> bool: return not panel.visible)
	assert_false(panel.visible)
	clock.release()


func test_reduced_motion_is_instant() -> void:
	var panel := _panel(true)
	panel.open(_view(3, 0))
	assert_eq((panel.get_node("Root") as Control).modulate.a, 1.0)
	panel.close()
	assert_false(panel.visible, "fermeture immédiate")
