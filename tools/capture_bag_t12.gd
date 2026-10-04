extends SceneTree
## Captures du Sac jouable (jalon 6, T12), vrai Boot sur la Route 1 :
##   menu_bag, menu_bag_targets, menu_bag_result  (menu → Sac → UTILISER → Pokémon → résultat)
##   bag_battle, bag_battle_target                (combat sauvage : Sac ouvert sur SOINS, choix)
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 3000 \
##     -s res://tools/capture_bag_t12.gd -- --out=build/captures/jalon06_t12

var _boot: Node
var _out_dir: String = "build/captures/jalon06_t12"


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])


func _start() -> void:
	var state: Node = root.get_node("GameState")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(60)
	state.call(&"new_game", 5)
	state.get(&"flags").call(&"set_flag", &"starter_chosen")
	state.set(&"starter_species", &"charmander")
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var party: Party = state.get(&"party")
	for spec: Array in [[&"charmander", 12], [&"pidgey", 9], [&"rattata", 8]]:
		party.add(PokemonFactory.create(data, spec[0], spec[1], GameRng.new(7)))
	party.get_at(0).hp = 9
	party.get_at(1).hp = 0
	var bag: Bag = state.get(&"bag")
	bag.add(&"potion", 3)
	bag.add(&"poke_ball", 5)
	await _menu_flow(party)
	await _battle_flow(state, data)
	print("CAPTURE_BAG_T12 terminé")
	quit()


func _menu_flow(party: Party) -> void:
	var menu: MenuDirector = _boot.call(&"get_menu_director")
	var screen: TrainerMenu = _boot.call(&"get_trainer_menu")
	menu.open(MenuRoute.bag())
	await _frames(40)
	await _shot("menu_bag")
	screen.get_bag().get_action_button().pressed.emit()
	await _frames(40)
	await _shot("menu_bag_targets")
	menu.use_item_on(&"potion", 0)
	await _frames(40)
	await _shot("menu_bag_result")
	menu.close()
	await _frames(40)
	party.heal_all()
	party.get_at(0).hp = 9
	party.get_at(1).hp = 0


func _battle_flow(state: Node, data: PokemonData) -> void:
	var director: BattleDirector = _boot.call(&"get_battle_director")
	var hud: BattleHud = _boot.call(&"get_battle_hud")
	var items: ItemLibrary = director.get_item_library()
	var enc := WildEncounter.new(&"rattata", 3, &"route_1_grass")
	var request := BattleRequest.wild(enc, data, state.get(&"rng") as GameRng, Vector2i(5, 4),
		items)
	var map: GameMap = _boot.call(&"get_map")
	var done: Array[bool] = [false]
	var run := func() -> void:
		await director.run_request(request, map)
		done[0] = true
	run.call()
	var stage := 0
	var guard := 0
	while not done[0] and guard < 3000:
		guard += 1
		var panel := director.get_bag_panel()
		var picker := director.get_party_picker()
		var battle := director.get_battle()
		if picker != null and picker.is_shown() and stage == 2:
			await _frames(30)
			await _shot("bag_battle_target")
			picker.cancel()
			stage = 3
		elif panel != null and panel.is_shown() and not panel.is_answered() and stage == 1:
			panel.open_category(&"heal")
			panel.select_item(&"potion")
			await _frames(30)
			await _shot("bag_battle")
			panel.get_action_button().pressed.emit()
			stage = 2
		elif panel != null and panel.is_shown() and not panel.is_answered() and stage == 3:
			panel.get_back_button().back_requested.emit()
			stage = 4
		elif battle != null and battle.get_state() == Battle.State.CHOOSING \
				and hud.get_zone() == BattleHud.Zone.ACTIONS:
			if stage == 0:
				stage = 1
				hud.action_selected.emit(ActionGrid.BAG)
			else:
				hud.action_selected.emit(ActionGrid.RUN)
		await _frames(1)
