extends SceneTree
## Capture « menu_open » (jalon 6, T4) : le vrai Boot sur la Route 1, titre de zone affiché, puis
## ouverture du Menu Dresseur par le directeur ; une image par frame pendant 0,3 s (fond qui se
## floute, titre de zone masqué, jamais d'image noire), puis fermeture.
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 400 \
##     -s res://tools/capture_menu_open.gd -- --out=build/captures/jalon06_t4

var _boot: Node
var _out_dir: String = "build/captures/jalon06_t4"
var _frame: int = 0
var _opened_at: int = -1


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	process_frame.connect(_on_frame)


func _shot(name: String) -> void:
	var image := root.get_texture().get_image()
	image.save_png("%s/%s.png" % [_out_dir, name])


func _on_frame() -> void:
	_frame += 1
	if _opened_at < 0:
		if _frame == 60:
			_shot("00_before")
		if _frame >= 61 and _boot.is_stable():
			print("ouverture : ", _boot.get_menu_director().open())
			_opened_at = _frame
		return
	var n := _frame - _opened_at
	_shot("%02d_open" % n)
	if n == 12:
		_boot.get_menu_director().close()
	if n == 20:
		_shot("99_closed")
		quit()
