extends GutTest
## Ambiance de Johto (2026-11-04, relevé de QA A17 « nuit discrète, lampes peu visibles ») :
## - les lumières de nuit d'Oliville et des cartes du JOH2 sont sur un calque au-dessus de
##   l'étalonnage d'écran (`NightLights`, [constant UiTokens.LAYER_NIGHT_LIGHTS], qui suit la
##   caméra) ;
## - Rosalia : tours et maisons peintes, maisons du kit cachées mais emprises gardées ;
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


func test_joh2_night_lights_sit_on_the_same_layer() -> void:
	for id: String in ["route_39", "route_38", "ecruteak_city"]:
		var map := (load("res://game/world/maps/%s.tscn" % id) as PackedScene).instantiate()
		var layer := map.get_node_or_null(^"NightLights") as CanvasLayer
		assert_not_null(layer, "%s : calque des lumières de nuit" % id)
		if layer != null:
			assert_eq(layer.layer, UiTokens.LAYER_NIGHT_LIGHTS, id)
			assert_true(layer.follow_viewport_enabled, id)
		map.free()


func test_rosalia_paints_its_towers_and_houses_over_the_kit() -> void:
	var map := (load("res://game/world/maps/ecruteak_city.tscn") as PackedScene).instantiate()
	assert_eq(map.get_node(^"Decor").get_child_count(), 0, "tours en aplats retirées")
	var entities := map.get_node(^"Entities")
	for node_name: String in ["TourCendree", "TourCarillon", "MaisonSages", "Maison1", "Maison2"]:
		var painted := entities.get_node_or_null("JohAmb" + node_name) as WorldProp
		assert_not_null(painted, node_name)
		if painted != null:
			assert_true(painted.footprint.is_empty(), "%s : les cases sont celles de la grille"
				% node_name)
	for node_name: String in ["Bat_MaisonSages", "Bat_Maison1", "Bat_Maison2"]:
		var kit_house := entities.get_node(NodePath(node_name)) as WorldProp
		assert_false(kit_house.visible, "%s : image remplacée" % node_name)
		assert_false(kit_house.footprint.is_empty(), "%s : emprise gardée" % node_name)
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
