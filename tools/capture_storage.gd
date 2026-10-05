extends SceneTree
## Captures du Stockage jouable (jalon 7 T16) avec la vraie scène Boot et la partie du départ
## `tools/debug_start/storage_qa.json` (6 en équipe dont un K.O., 10 au stockage dont un favori,
## devant le terminal du Centre) appliquée au démarrage :
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_storage.gd -- --out=build/captures/jalon07_t16
##
## Déroulé : storage_00_terminal (le joueur devant le terminal, tourné vers lui) ; EXAMINER ;
## storage_01_open (écran seul, tête sélectionnée) ; storage_02_full (REPRENDRE refusé, équipe
## pleine) ; storage_03_deposit (la tête déposée, sélectionnée à la fin du stockage) ;
## storage_04_favorite (LIBÉRER le favori refusé, sans confirmation) ; storage_05_confirm
## (« Libérer Roucool ? ») ; storage_06_released ; storage_07_last (dernier Pokémon refusé) ;
## storage_08_team (l'Équipe au Centre, bouton STOCKAGE).

const START := "res://tools/debug_start/storage_qa.json"
## StorageRules.Place.
const PARTY := 0
const STORAGE := 1

var _out_dir: String = "build/captures/jalon07_t16"
var _boot: Node
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


func _storage() -> Node:
	return _screen.call(&"get_storage")


func _on_frame() -> void:
	_frame += 1
	_wait += 1
	match _step:
		0:
			if _frame == 60:
				_shot("storage_00_terminal")
				Input.action_press(&"interact")
			elif _frame == 62:
				Input.action_release(&"interact")
			elif _frame > 62 and _menu.call(&"is_open"):
				_next()
		1:
			if _wait == 40:
				_shot("storage_01_open")
				_screen.emit_signal(&"storage_selected", STORAGE, 0)
			elif _wait == 45:
				_screen.emit_signal(&"storage_withdraw_requested", 0)
			elif _wait == 55:
				_shot("storage_02_full")
				_screen.emit_signal(&"storage_selected", PARTY, 0)
			elif _wait == 60:
				_screen.emit_signal(&"storage_deposit_requested", 0)
			elif _wait == 90:
				_shot("storage_03_deposit")
				_next()
		2:
			if _wait == 5:
				_screen.emit_signal(&"storage_selected", STORAGE, 2)
			elif _wait == 10:
				_screen.emit_signal(&"storage_release_requested", STORAGE, 2)
			elif _wait == 20:
				_shot("storage_04_favorite")
				_screen.emit_signal(&"storage_selected", STORAGE, 0)
			elif _wait == 25:
				_screen.emit_signal(&"storage_release_requested", STORAGE, 0)
			elif _wait == 55:
				_shot("storage_05_confirm")
				var choice: Object = _storage().call(&"get_choice")
				(choice.call(&"get_confirm_button") as Button).pressed.emit()
			elif _wait == 85:
				_shot("storage_06_released")
				_next()
		3:
			if _wait <= 5:
				_screen.emit_signal(&"storage_deposit_requested", 0)
			elif _wait == 10:
				_screen.emit_signal(&"storage_selected", PARTY, 0)
			elif _wait == 15:
				_screen.emit_signal(&"storage_deposit_requested", 0)
			elif _wait == 25:
				_shot("storage_07_last")
				_menu.call(&"close")
			elif _wait == 45:
				_menu.call(&"open", load("res://game/systems/menu/menu_route.gd").call(&"team"))
			elif _wait == 85:
				_shot("storage_08_team")
				quit()


func _next() -> void:
	_step += 1
	_wait = 0


func _shot(capture_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var path := _out_dir.path_join(capture_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("  -> %s" % path)
