extends SceneTree
## Captures du lot 32P, vrai Boot sur la Route 1 :
##   pp_targets (choix du Pokémon pour un PP Plus), pp_choice (panneau de choix de la capacité),
##   pp_result (résultat dans le Sac), vitamin_result (Carbone donné).
##   godot --path . --resolution 2340x1080 -s res://tools/capture_lot_32p.gd \
##     -- --out=build/captures/lot_32p

var _boot: Node
var _out_dir: String = "build/captures/lot_32p"


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
	for spec: Array in [[&"charmander", 22], [&"pidgey", 9]]:
		party.add(PokemonFactory.create(data, spec[0], spec[1], GameRng.new(7)))
	var bag: Bag = state.get(&"bag")
	bag.add(&"pp_up", 2)
	bag.add(&"carbos", 1)
	var menu: MenuDirector = _boot.call(&"get_menu_director")
	var screen: TrainerMenu = _boot.call(&"get_trainer_menu")
	menu.open(MenuRoute.bag())
	await _frames(20)
	var bag_screen := screen.get_bag()
	bag_screen.open_category(&"field")
	bag_screen.select_item(&"pp_up")
	await _frames(20)
	bag_screen.get_action_button().pressed.emit()
	await _frames(20)
	await _shot("pp_targets")
	menu.use_item_on(&"pp_up", 0)
	await _frames(40)
	await _shot("pp_choice")
	var prompt: MoveLearnPrompt = _boot.call(&"get_battle_director").get_move_learn_prompt()
	var panel := prompt.get_forget_panel()
	panel.select(0)
	panel.get_confirm_button().pressed.emit()
	await _frames(40)
	await _shot("pp_result")
	menu.use_item_on(&"carbos", 0)
	await _frames(20)
	await _shot("vitamin_result")
	print("CAPTURE_LOT_32P terminé")
	quit()
