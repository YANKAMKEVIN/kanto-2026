extends SceneTree
## Captures du Sac « CT » (jalon 11, T12), vrai Boot sur la Route 1 :
##   tm_bag (onglet CT, CT34 sélectionnée, détail), tm_targets (COMPATIBLE / INCOMPATIBLE /
##   DÉJÀ CONNUE), tm_learned (voile : « Salamèche apprend Patience ! »).
##   godot --path . --resolution 2340x1080 -s res://tools/capture_tm_j11.gd \
##     -- --out=build/captures/jalon11_t12

var _boot: Node
var _out_dir: String = "build/captures/jalon11_t12"


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
	print("CAPTURE ", name)


func _start() -> void:
	var state: Node = root.get_node("GameState")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(30)
	state.call(&"new_game", 5)
	state.get(&"flags").call(&"set_flag", &"starter_chosen")
	state.set(&"starter_species", &"charmander")
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var party: Party = state.get(&"party")
	for spec: Array in [[&"charmander", 12], [&"caterpie", 7], [&"pidgey", 9]]:
		party.add(PokemonFactory.create(data, spec[0], spec[1], GameRng.new(7)))
	party.get_at(2).learn_move(&"bide", data)
	var bag: Bag = state.get(&"bag")
	bag.add(&"potion", 3)
	bag.add(&"tm34", 1)
	var menu: MenuDirector = _boot.call(&"get_menu_director")
	var screen: TrainerMenu = _boot.call(&"get_trainer_menu")
	menu.open(MenuRoute.bag())
	await _frames(20)
	var bag_screen := screen.get_bag()
	bag_screen.open_category(&"tm")
	bag_screen.select_item(&"tm34")
	await _frames(20)
	await _shot("tm_bag")
	bag_screen.get_action_button().pressed.emit()
	await _frames(20)
	await _shot("tm_targets")
	menu.use_item_on(&"tm34", 0)
	await _frames(20)
	await _shot("tm_learned")
	_boot.call(&"get_tm_learn_overlay").get_message_banner().skip()
	await _frames(20)
	await _shot("tm_after")
	print("CAPTURE_TM_J11 terminé")
	quit()
