extends SceneTree
## Capture du Stockage avec recherche et tri actifs (jalon 32, T7) : départ `storage_qa.json`,
## recherche « ra » et tri par niveau.
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_storage_query.gd -- --out=build/captures/j32_t7

const START := "res://tools/debug_start/storage_qa.json"
## StorageRules.Place.
const PARTY := 0
const STORAGE := 1

var _out_dir: String = "build/captures/j32_t7"
var _boot: Node
var _menu: Node
var _screen: Node
var _frame: int = 0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"viridian_center")
	_boot.set(&"start_spawn", &"terminal")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	var data: Object = _boot.call(&"get_pokemon_data")
	var start: Object = load("res://game/systems/debug/debug_start.gd").new()
	if not start.call(&"load_file", START, data, _boot.call(&"get_item_library")):
		push_error("capture_storage : départ illisible")
	start.call(&"apply", root.get_node(^"/root/GameState"), data)
	_menu = _boot.call(&"get_menu_director")
	_screen = _boot.call(&"get_trainer_menu")
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	match _frame:
		60:
			_menu.call(&"open", load("res://game/systems/menu/menu_route.gd").call(&"storage"), true)
		100:
			_shot("storage_q0_open")
			_screen.emit_signal(&"storage_query_changed", "ra", 3)
		130:
			_shot("storage_q1_filtered_level")
			_screen.emit_signal(&"storage_query_changed", "", 1)
		160:
			_shot("storage_q2_species")
			quit()


func _shot(capture_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var path := _out_dir.path_join(capture_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("  -> %s" % path)
