extends SceneTree
func _init() -> void:
	var boot: Node = (load("res://game/boot.tscn") as PackedScene).instantiate()
	boot.set(&"debug_start_path", "res://tools/debug_start/johto_rosalia_night.json")
	boot.set(&"force_debug_start", true)
	root.add_child(boot)
	for i in 30:
		await process_frame
	var clock: Object = boot.get(&"_world_clock")
	var map: Node = boot.call(&"get_map")
	print("periode : ", clock.call(&"period_name"), " forcée : ", clock.call(&"is_period_forced"), " active : ", clock.call(&"is_active"))
	print("carte : ", map.get(&"map_id"), " profil : ", map.get(&"light_profile"))
	var lighting: Object = boot.get(&"_lighting")
	print("profil appliqué : ", lighting.get(&"_profile").get(&"id") if lighting.get(&"_profile") != null else "null")
	var n := 0
	var vis := 0
	for node: Node in root.get_tree().get_nodes_in_group(&"night_lights"):
		n += 1
		if (node as CanvasItem).visible:
			vis += 1
	print("lampes : ", n, " visibles : ", vis)
	quit()
