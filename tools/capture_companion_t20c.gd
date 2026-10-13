extends SceneTree
## Captures du compagnon branché au jeu (jalon 11, T20c), vrai Boot sur la Route 1 :
##   xvfb-run -a -s "-screen 0 2340x1080x24" godot --path . --rendering-driver opengl3 \
##     --resolution 2340x1080 --fixed-fps 30 -s res://tools/capture_companion_t20c.gd \
##     -- --out=build/captures/jalon11_t20c
## Images : team_send_out (Équipe, FAIRE SORTIR), team_recall (RAPPELER, aspect activé),
## team_none (Chenipan : aucun bouton), world_out (sortie de Ball à la fermeture du menu),
## world_follow (deux pas : il suit), world_talk (curiosité : bulle et phrase).

var _boot: Node
var _out_dir: String = "build/captures/jalon11_t20c"


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
	await _frames(2)
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
	print("CAPTURE ", name)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(30)
	var state: Node = root.get_node(^"GameState")
	(state.get(&"flags") as StoryFlags).set_flag(&"starter_chosen")
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var party: Party = state.get(&"party")
	party.add(PokemonFactory.create(data, &"charmander", 9, GameRng.new(7)))
	party.add(PokemonFactory.create(data, &"caterpie", 4, GameRng.new(7)))
	var player: Player = _boot.call(&"get_player")
	var menu: Node = _boot.call(&"get_menu_director")
	menu.call(&"open", MenuRoute.team(0))
	await _frames(30)
	await _shot("team_send_out")
	menu.call(&"toggle_companion", 0)
	await _frames(5)
	await _shot("team_recall")
	(_boot.call(&"get_trainer_menu") as Node).call(&"get_team").call(&"_select", 1)
	await _frames(10)
	await _shot("team_none")
	menu.call(&"close")
	# Le joueur avance de deux cases : le compagnon sort au premier pas (case derrière prise ou
	# hors carte au point d'arrivée) ou tout de suite.
	await _frames(6)
	await _shot("world_out")
	for i: int in 2:
		player.script_step(Vector2i.UP)
		while player.is_moving():
			await process_frame
	await _frames(20)
	await _shot("world_follow")
	player.face(Vector2i.DOWN)
	await _frames(4)
	Input.action_press(&"interact")
	await _frames(2)
	Input.action_release(&"interact")
	await _frames(15)
	await _shot("world_talk")
	print("CAPTURE_COMPANION_T20C terminé")
	quit()
