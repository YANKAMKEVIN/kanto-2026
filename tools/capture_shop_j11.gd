extends SceneTree
## Capture de la Boutique de Jadielle avec les remèdes du J11 (T8) : écran Boutique seul,
## ACHETER, 5 cartes (la liste défile), puis la dernière carte (Anti-Brûle) sélectionnée.
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_shop_j11.gd -- --out=build/captures/jalon11_t8

const GameStateScript := preload("res://game/autoload/game_state.gd")
const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"

var _out_dir: String = "build/captures/jalon11_t8"
var _menu: TrainerMenu
var _frame: int = 0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	var items := ItemLibrary.new()
	items.load_dir()
	var shops := ShopLibrary.new()
	shops.load_dir()
	var state: Node = GameStateScript.new()
	state.new_game(7)
	state.money = 3000
	state.bag.add(&"potion", 4)
	state.bag.add(&"poke_ball", 3)
	_menu = (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	root.add_child(_menu)
	_menu.show_shop(ShopViews.build(state, shops.get_shop(&"viridian_mart"), items,
		ShopViews.MODE_BUY))
	_menu.open_animated()
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	if _frame == 40:
		_shot("shop_00_buy")
		var screen := _menu.get_shop()
		var last: Control = screen.get_cards()[-1]
		last.emit_signal(&"tapped")
		screen.get_scroll().ensure_control_visible(last)
	elif _frame == 70:
		_shot("shop_01_last")
		quit()


func _shot(name: String) -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var path := _out_dir.path_join(name + ".png")
	root.get_texture().get_image().save_png(path)
	print("capture : ", path)
