extends GutTest
## Ambiance de Johto (2026-11-04, relevé de QA A17 « nuit discrète, lampes peu visibles ») :
## - les lumières de nuit d'Oliville sont sur un calque au-dessus de l'étalonnage d'écran
##   (`NightLights`, [constant UiTokens.LAYER_NIGHT_LIGHTS], qui suit la caméra) ;
## - [method WorldLighting.set_battle_active] les cache pendant un combat et les rend après ;
## - la nuit de Johto assombrit franchement (tons moyens ≤ 0,5 sur le rouge et le vert).

const OLIVINE := preload("res://game/world/maps/olivine_city.tscn")


func test_olivine_night_lights_sit_above_the_grade() -> void:
	var map := OLIVINE.instantiate()
	var layer := map.get_node_or_null(^"NightLights") as CanvasLayer
	assert_not_null(layer, "calque des lumières de nuit")
	if layer != null:
		assert_eq(layer.layer, UiTokens.LAYER_NIGHT_LIGHTS)
		assert_gt(layer.layer, UiTokens.LAYER_WORLD_GRADE, "au-dessus de l'étalonnage")
		assert_lt(layer.layer, UiTokens.LAYER_HUD, "sous le HUD")
		assert_true(layer.follow_viewport_enabled, "suit la caméra")
		var types := {}
		for glow: Node in layer.get_children():
			types[glow.get(&"glow_type")] = true
		assert_true(types.has(&"night_lamp") and types.has(&"night_window"))
	map.free()


func test_battle_hides_then_restores_night_lights() -> void:
	var lighting := WorldLighting.new()
	add_child_autofree(lighting)
	var map := Node2D.new()
	add_child_autofree(map)
	var layer := CanvasLayer.new()
	map.add_child(layer)
	var glow := Sprite2D.new()
	glow.add_to_group(WorldLighting.GROUP_NIGHT_LIGHTS)
	layer.add_child(glow)
	lighting.set_night(true, map)
	assert_true(glow.visible, "nuit : allumée")
	lighting.set_battle_active(true)
	assert_false(glow.visible, "combat : cachée")
	lighting.set_battle_active(false)
	assert_true(glow.visible, "après le combat : rallumée")
	lighting.set_night(false, map)
	assert_false(glow.visible, "jour : éteinte")


func test_johto_night_is_clearly_darker() -> void:
	var library := LightingLibrary.new()
	assert_true(library.load_file())
	var night := library.get_profile(&"johto_night")
	assert_lte(night.grade_midtones.x, 0.5)
	assert_lte(night.grade_midtones.y, 0.5)
	assert_gt(night.grade_midtones.z, night.grade_midtones.x, "nuit bleue")
	var morning := library.get_profile(&"johto_morning")
	assert_lt(morning.grade_midtones.z, morning.grade_midtones.x, "matin chaud, distinct du jour")
