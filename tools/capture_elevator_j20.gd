extends SceneTree
## Captures du panneau d'étages (T14, `jalon-20.md` §2.3.4) sur la vraie scène Boot (Route 1 en
## fond ; les cartes de Céladopole ne sont pas encore fusionnées) :
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_elevator_j20.gd -- --out=build/captures/jalon20_t14
##
##   elevator_dept_5     données réelles du magasin (RdC, 2e à 5e), 3e courant
##   elevator_dept_6     vue fabriquée à 6 étages (RdC, 1er à 5e), 4e courant
##   elevator_hideout    repaire (B1F, B2F, B4F), B2F courant
##   elevator_dept_6_big même vue en texte « Grand » (UiPrefs)

var _out_dir: String = "build/captures/jalon20_t14"
var _boot: Node
var _prefix: String = ""


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(capture_name: String) -> void:
	await _frames(3)
	var path := "%s/%s%s.png" % [_out_dir, _prefix, capture_name]
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s" % path)


func _view(labels: Array, current: int) -> ElevatorPanelView:
	var view := ElevatorPanelView.new()
	for i: int in labels.size():
		view.floors.append({"id": StringName("f%d" % i), "label": labels[i],
			"current": i == current})
	return view


func _start() -> void:
	_prefix = "%d_" % int(root.get_visible_rect().size.x)
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	root.add_child(_boot)
	await _frames(60)
	root.get_node("GameState").call(&"new_game", 5)
	var panel: ElevatorPanel = _boot.get(&"_elevator_panel")
	var library := ElevatorLibrary.new()
	library.load_file(ElevatorLibrary.DATA_PATH)
	panel.open(ElevatorPanelView.build(library.get_elevator(&"celadon_dept"), &"3f"))
	await _frames(40)
	await _shot("elevator_dept_5")
	panel.close()
	await _frames(20)
	panel.open(_view(["RdC", "1er", "2e", "3e", "4e", "5e"], 4))
	await _frames(40)
	await _shot("elevator_dept_6")
	panel.close()
	await _frames(20)
	panel.open(ElevatorPanelView.build(library.get_elevator(&"rocket_hideout"), &"b2f"))
	await _frames(40)
	await _shot("elevator_hideout")
	panel.close()
	await _frames(20)
	UiPrefs.text_scale = UiTokens.TEXT_SCALE_LARGE
	panel.open(_view(["RdC", "1er", "2e", "3e", "4e", "5e"], 4))
	await _frames(40)
	await _shot("elevator_dept_6_big")
	print("CAPTURE_ELEVATOR_J20 terminé")
	quit()
