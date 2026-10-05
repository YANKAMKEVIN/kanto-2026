extends SceneTree
## Captures de la Boutique de Jadielle (jalon 7 T12) avec la vraie scène Boot et la partie du
## départ `tools/debug_start/shop_qa.json` (6 000 ₽, Potions favorites, devant la Boutique)
## appliquée au démarrage :
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_mart.gd -- --out=build/captures/jalon07_t12
##
## Déroulé : mart_00_door (devant la porte) ; un pas en bas, puis vers le haut jusqu'à la scène ;
## mart_01_hello (« Bonjour ! Première fois à Jadielle ? ») ; mart_02_counter (à la caisse,
## réplique du colis) ; mart_03_toast (« COLIS POUR CHEN — ajouté aux objets clés ») ;
## mart_04_objective (tableau de bord : l'objectif du colis) ; mart_05_greeting (visite
## suivante) ; mart_06_shop (la Boutique, écran seul, ACHETER) ; mart_07_bought (« Merci ! ») ;
## mart_08_confirm (vendre une Potion favorite : VENDRE / ANNULER) ; mart_09_depth (le joueur
## derrière le présentoir ouest, tri par les pieds).

const START := "res://tools/debug_start/shop_qa.json"

var _out_dir: String = "build/captures/jalon07_t12"
var _boot: Node
var _player: Node2D
var _runner: Node
var _box: Node
var _menu: Node
var _screen: Node
var _cutscenes: Node
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
	_boot.set(&"start_map", &"viridian_city")
	_boot.set(&"start_spawn", &"from_mart")
	_boot.set(&"start_facing", Vector2i.DOWN)
	root.add_child(_boot)
	var data: Object = _boot.call(&"get_pokemon_data")
	var start: Object = load("res://game/systems/debug/debug_start.gd").new()
	if not start.call(&"load_file", START, data, _boot.call(&"get_item_library")):
		push_error("capture_mart : départ illisible")
	start.call(&"apply", root.get_node(^"/root/GameState"), data)
	_player = _boot.call(&"get_player")
	_runner = _boot.call(&"get_dialogue_runner")
	_box = _boot.call(&"get_dialogue_box")
	_menu = _boot.call(&"get_menu_director")
	_screen = _boot.call(&"get_trainer_menu")
	_cutscenes = _boot.call(&"get_cutscene_director")
	process_frame.connect(_on_frame)


func _map_id() -> StringName:
	return (_boot.call(&"get_map") as Node).get(&"map_id")


func _on_frame() -> void:
	_frame += 1
	_wait += 1
	match _step:
		0:
			if _frame == 45:
				_shot("mart_00_door")
				Input.action_press(&"move_down")
				_next()
		1:
			if _player.call(&"get_cell") == Vector2i(30, 21):
				Input.action_release(&"move_down")
				_next()
		2:
			if not _player.call(&"is_moving") and _wait >= 5:
				Input.action_press(&"move_up")
				_next()
		3:
			if _cutscenes.call(&"is_running"):
				Input.action_release(&"move_up")
				_next()
		4:
			if _box.call(&"is_open") and _wait >= 45:
				_shot("mart_01_hello")
				_box.emit_signal(&"advance_requested")
				_next()
		5:
			if _player.call(&"get_cell") == Vector2i(7, 5) and _box.call(&"is_open"):
				if _wait >= 400:
					_shot("mart_02_counter")
					_next()
			elif _wait % 15 == 0 and _box.call(&"is_open"):
				_box.emit_signal(&"advance_requested")
				_wait = 300
		6:
			if _wait % 6 == 0:
				_box.emit_signal(&"advance_requested")
			if not _cutscenes.call(&"is_running"):
				_next()
		7:
			if _wait == 8:
				_shot("mart_03_toast")
			elif _wait == 120:
				_menu.call(&"open")
			elif _wait == 150:
				_shot("mart_04_objective")
				_menu.call(&"close")
				_next()
		8:
			if _wait == 30:
				Input.action_press(&"interact")
			elif _wait == 32:
				Input.action_release(&"interact")
			elif _wait > 32 and _box.call(&"is_open") and _wait >= 50:
				_shot("mart_05_greeting")
				_box.emit_signal(&"advance_requested")
				_next()
		9:
			if not _menu.call(&"is_open") and _wait % 15 == 0 and _box.call(&"is_open"):
				_box.emit_signal(&"advance_requested")
			if _menu.call(&"is_open") and _wait >= 60:
				_shot("mart_06_shop")
				_screen.emit_signal(&"shop_buy_requested", &"poke_ball", 2)
				_next()
		10:
			if _wait == 10:
				_shot("mart_07_bought")
				_screen.emit_signal(&"shop_mode_changed", &"sell")
			elif _wait == 20:
				_screen.emit_signal(&"shop_sell_requested", &"potion", 1, false)
			elif _wait == 40:
				_shot("mart_08_confirm")
				_screen.call(&"shop_back")
				_menu.call(&"close")
				_next()
		11:
			if _wait == 20:
				var map: Node = _boot.call(&"get_map")
				map.call(&"spawn_player_at", _player, Vector2i(3, 6), Vector2i.DOWN)
			elif _wait == 40:
				_shot("mart_09_depth")
				quit()


func _next() -> void:
	_step += 1
	_wait = 0


func _shot(capture_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var path := _out_dir.path_join(capture_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("  -> %s" % path)
