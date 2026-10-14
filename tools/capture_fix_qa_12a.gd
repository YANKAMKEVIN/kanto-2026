extends SceneTree
## Captures du correctif QA 12A (`docs/tech/etat-projet.md`, J12) :
##   godot --path . --resolution 2340x1080 --fixed-fps 60 -s res://tools/capture_fix_qa_12a.gd \
##     -- --out=build/qa/fix_12a
## Images : center_exit_0 / _1 / _2 (sortie du Centre du Mont Sélénite après le soin, Reptincel
## compagnon : la porte derrière le joueur, puis deux pas enchaînés sans s'arrêter, il sort et
## suit) ; battle_charmeleon (combat sauvage sur la Route 3, Reptincel de dos côté joueur).

var _boot: Node
var _router: Node
var _state: Node
var _out_dir: String = "build/qa/fix_12a"


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


func _player() -> Player:
	return _boot.call(&"get_player")


func _map() -> GameMap:
	return _boot.call(&"get_map")


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"mt_moon_center")
	_boot.set(&"start_spawn", &"entrance")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(30)
	_router = root.get_node(^"SceneRouter")
	_state = root.get_node(^"GameState")
	(_state.get(&"flags") as StoryFlags).set_flag(&"starter_chosen")
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var party: Party = _state.get(&"party")
	party.add(PokemonFactory.create(data, &"charmeleon", 17, GameRng.new(7)))
	_state.call(&"set_companion", party.get_at(0))
	var companion: CompanionController = _boot.call(&"get_companion_controller")
	companion.refresh()
	companion.note_joy()
	_router.call(&"change_map", &"route_3", &"from_center_e", Vector2i.DOWN)
	while _map().map_id != &"route_3" or bool(_router.call(&"is_transitioning")):
		await process_frame
	await _frames(20)
	await _shot("center_exit_0")
	# Deux pas vers le bas sans s'arrêter (le bug : le compagnon restait invisible).
	var steps := [0]
	_player().moved.connect(func(_cell: Vector2i) -> void: steps[0] += 1)
	Input.action_press(&"move_down")
	while steps[0] < 1:
		await process_frame
	await _frames(4)
	await _shot("center_exit_1")
	while steps[0] < 2:
		await process_frame
	Input.action_release(&"move_down")
	await _frames(30)
	await _shot("center_exit_2")
	print("compagnon montré : ", companion.is_shown())
	await _battle(data)
	quit()


func _battle(data: PokemonData) -> void:
	var director: BattleDirector = _boot.call(&"get_battle_director")
	var enc := WildEncounter.new(&"ekans", 8, &"route_3_grass")
	var request := BattleRequest.wild(enc, data, GameRng.new(3), _player().get_cell(),
		director.get_item_library())
	director.run_request(request, _map())
	await _frames(300)
	await _shot("battle_charmeleon")
