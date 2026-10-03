extends SceneTree
## Captures du Pokédex jouable (jalon 6, T16), vrai Boot à Bourg Palette, drapeau de débogage :
##   dex_observe_toast (toast après avoir observé le Roucool de Mme Aoki), dex_grid, dex_sheet
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 3000 \
##     -s res://tools/capture_pokedex_t16.gd -- --out=build/captures/jalon06_t16

var _boot: Node
var _out_dir: String = "build/captures/jalon06_t16"


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
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"force_debug_start", false)
	_boot.set(&"force_debug_unlocks", true)
	_boot.set(&"debug_unlocks_path", "res://tests/fixtures/debug_unlocks/pokedex.json")
	_boot.set(&"start_map", &"pallet_town")
	_boot.set(&"start_spawn", &"start")
	root.add_child(_boot)
	await _frames(90)
	var state: Node = root.get_node("GameState")
	state.call(&"new_game", 5)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var party: Party = state.get(&"party")
	party.add(PokemonFactory.create(data, &"charmander", 8, GameRng.new(7)))
	state.call(&"record_caught", &"charmander", &"oak_lab")
	var router: Node = root.get_node("SceneRouter")
	router.call(&"start_at", &"pallet_town", Vector2i(26, 13), Vector2i.RIGHT)
	await _frames(60)
	var player: Player = _boot.call(&"get_player")
	player.face(Vector2i.RIGHT)
	Input.action_press(&"interact")
	await _frames(20)
	Input.action_release(&"interact")
	var runner: DialogueRunner = _boot.call(&"get_dialogue_runner")
	var box: DialogueBox = _boot.call(&"get_dialogue_box")
	for i: int in 400:
		if not runner.is_running():
			break
		if box.is_open():
			box.advance_requested.emit()
		await _frames(2)
	await _frames(40)
	await _shot("dex_observe_toast")
	await _frames(120)
	var menu: MenuDirector = _boot.call(&"get_menu_director")
	menu.open(MenuRoute.pokedex())
	await _frames(40)
	await _shot("dex_sheet")
	var screen: TrainerMenu = _boot.call(&"get_trainer_menu")
	screen.pokedex_back()
	await _frames(30)
	await _shot("dex_grid")
	print("CAPTURE_DEX_T16 terminé")
	quit()
