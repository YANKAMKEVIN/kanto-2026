extends SceneTree
## Captures de la Boutique d'Azuria et de la vente de la Pépite (jalon 13 T17), vraie scène Boot,
## partie du départ `cerulean_city` + une Pépite au Sac :
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_cerulean_shop.gd -- --out=build/captures/j13_t17
##
## Écrit shop_00_counter (devant la caisse), shop_01_buy (ACHETER : le stock), shop_02_sell
## (VENDRE : la Pépite à 5 000 ₽), shop_03_sold (après la vente).

const START := "res://tools/debug_start/cerulean_city.json"

var _out_dir: String = "build/captures/j13_t17"
var _boot: Node
var _player: Node2D
var _box: Node
var _menu: Node
var _screen: Node
var _frame: int = 0
var _step: int = 0
var _wait: int = 0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"cerulean_mart")
	_boot.set(&"start_spawn", &"entrance")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	var data: Object = _boot.call(&"get_pokemon_data")
	var start: Object = load("res://game/systems/debug/debug_start.gd").new()
	if not start.call(&"load_file", START, data, _boot.call(&"get_item_library")):
		push_error("capture_cerulean_shop : départ illisible")
	var state: Node = root.get_node(^"/root/GameState")
	start.call(&"apply", state, data)
	state.get(&"bag").call(&"add", &"nugget", 1)
	_player = _boot.call(&"get_player")
	_box = _boot.call(&"get_dialogue_box")
	_menu = _boot.call(&"get_menu_director")
	_screen = _boot.call(&"get_trainer_menu")
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	_wait += 1
	match _step:
		0:
			if _frame == 20:
				var map: Node = _boot.call(&"get_map")
				map.call(&"spawn_player_at", _player, Vector2i(7, 5), Vector2i.UP)
			elif _frame == 50:
				_shot("shop_00_counter")
				Input.action_press(&"interact")
			elif _frame == 52:
				Input.action_release(&"interact")
				_next()
		1:
			if _box.call(&"is_open") and _wait % 20 == 0:
				_box.emit_signal(&"advance_requested")
			if _menu.call(&"is_open") and _wait >= 60:
				_shot("shop_01_buy")
				_screen.emit_signal(&"shop_mode_changed", &"sell")
				_next()
		2:
			if _wait == 30:
				_shot("shop_02_sell")
				_screen.emit_signal(&"shop_sell_requested", &"nugget", 1, false)
				_next()
		3:
			if _wait == 40:
				_shot("shop_03_sold")
				quit()


func _next() -> void:
	_step += 1
	_wait = 0


func _shot(capture_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var path := _out_dir.path_join(capture_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("  -> %s" % path)
