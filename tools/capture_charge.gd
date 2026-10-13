extends SceneTree
## Capture du J14 T9 (Movie Maker) : Tunnel puis Téléport, d'un vrai combat sauvage.
## Usage : godot --path . --resolution 2340x1080 --write-movie build/cap_charge/f.png
##   --fixed-fps 60 -s res://tools/capture_charge.gd -- dig|teleport
## Affiche « [cap] <événement> <numéro d'image> » à chaque événement joué.

var _mode: String = "dig"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_mode = args[0]
	root.size = Vector2i(2340, 1080)
	var start := Engine.get_frames_drawn()
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	var data := PokemonData.new()
	data.load_dir()
	(load("res://tests/helpers/j14_moves.gd") as GDScript).call("ensure", data)
	var trainers := TrainerLibrary.new(data)
	trainers.load_dir()
	var texts := BattleText.new()
	texts.load_file()
	var items := ItemLibrary.new()
	items.load_dir()
	var state: Node = (load("res://game/autoload/game_state.gd") as GDScript).new()
	root.add_child(state)
	var world := Node2D.new()
	root.add_child(world)
	var map := GameMap.new()
	map.map_id = &"route_1"
	map.npcs_dir = "res://tests/fixtures/npcs/"
	map.size = Vector2i(20, 18)
	for group: String in ["Entities", "Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		map.add_child(node)
	world.add_child(map)
	var player := (load("res://game/player/player.tscn") as PackedScene).instantiate() as Player
	map.get_entities().add_child(player)
	player.enter_map(map.get_grid(), Vector2i(11, 7), Vector2i.LEFT, map.get_pixel_rect())
	player.get_camera().make_current()
	var stage := (load("res://game/battle/battle_stage.tscn") as PackedScene).instantiate()
	root.add_child(stage)
	var hud := (load("res://game/ui/battle/battle_hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	var director := BattleDirector.new()
	root.add_child(director)
	director.haptics_enabled = false
	hud.haptics_enabled = false
	director.setup(data, trainers, texts, stage, hud, player, state, items)
	await process_frame
	var party := Party.new()
	party.add(_mon(data, &"charmander", 8, [&"dig", &"scratch"]))
	state.party = party
	state.starter_species = &"charmander"
	state.rng = GameRng.new(3)
	var request := BattleRequest.new()
	request.intro = BattleRequest.Intro.WILD
	request.foe_party = Party.new()
	if _mode == "dig":
		request.foe_party.add(_mon(data, &"geodude", 3, [&"tackle"]))
	else:
		request.foe_party.add(_mon(data, &"pidgey", 5, [&"teleport"]))
	request.rules = BattleRules.for_wild(items)
	request.origin_cell = Vector2i(5, 4)
	director.event_played.connect(func(e: BattleEvent) -> void:
		print("[cap] ", BattleEvent.Kind.find_key(e.kind), " ", Engine.get_frames_drawn()))
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await director.run_request(request, map)
		done[0] = true
	runner.call()
	var guard := 0
	while not done[0] and guard < 700:
		var battle := director.get_battle()
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			match hud.get_zone():
				BattleHud.Zone.ACTIONS:
					hud.action_selected.emit(ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					hud.move_selected.emit(0)
		await process_frame
		guard += 1
	print("[cap] fin ", Engine.get_frames_drawn())
	quit()


func _mon(data: PokemonData, species: StringName, level: int, ids: Array[StringName]) -> Pokemon:
	var pokemon := PokemonFactory.create(data, species, level, GameRng.new(7))
	pokemon.moves.clear()
	for id: StringName in ids:
		pokemon.moves.append(MoveSlot.new(id, data.get_move(id).pp))
	return pokemon
