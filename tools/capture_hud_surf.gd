extends SceneTree
## Capture du HUD avec les deux boutons PÊCHER + SURFER (demande de Kevin, 2026-11-22), sur un
## fond d'eau factice. Rendu réel (pas --headless) :
##   godot --path . --resolution 2340x1080 -s res://tools/capture_hud_surf.gd
## Écrit build/captures/hud_pecher_surfer.png (droitier) et hud_pecher_surfer_gaucher.png.

func _init() -> void:
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var bg := ColorRect.new()
	bg.color = Color(0.28, 0.5, 0.62)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var hud := (load("res://game/ui/hud/exploration_hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	hud.show_interact(&"fish", true)
	hud.set_bike_button(true, false)
	await _frames(30)
	_save("hud_pecher_surfer")
	hud.set_left_handed(true)
	await _frames(10)
	_save("hud_pecher_surfer_gaucher")
	quit()


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _save(name_id: String) -> void:
	var image := root.get_texture().get_image()
	image.save_png("res://build/captures/%s.png" % name_id)
