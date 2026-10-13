extends SceneTree
## Captures de la carte de QA du jalon 12 (T15) avec le vrai départ `moves_qa` (Boot), puis un
## vrai combat (directeur, interface) :
##   carte                       (le joueur au départ, le Dresseur d'essai, les hautes herbes)
##   --flow=trainer (défaut)     Racaillou du Dresseur ramené à ¼ de ses PV : « Destruction »
##                               (capture destruction_message, puis destruction_ko)
##   --flow=wild                 Abo sauvage N20 contre Racaillou : « ligoté » (ligote_message)
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 6000 \
##     -s res://tools/capture_qa_moves_j12.gd -- --out=build/captures/jalon12_t15 --flow=trainer
## Retiré au T28 avec la carte.

var _boot: Node
var _out_dir: String = "build/captures/jalon12_t15"
var _flow: String = "trainer"


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--flow="):
			_flow = arg.trim_prefix("--flow=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(shot_name: String) -> void:
	RenderingServer.force_draw(true)
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, shot_name])
	print("capture : ", shot_name)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"force_debug_start", true)
	_boot.set(&"debug_start_path", "res://tools/debug_start/moves_qa.json")
	root.add_child(_boot)
	await _frames(90)
	if _flow == "trainer":
		await _shot("carte")
	var map: GameMap = _boot.call(&"get_map")
	print("carte : ", map.map_id)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var director: BattleDirector = _boot.call(&"get_battle_director")
	var request: BattleRequest
	if _flow == "wild":
		request = BattleRequest.wild(WildEncounter.new(&"ekans", 20), data, GameRng.new(7),
			Vector2i(3, 11), director.get_item_library())
	else:
		var library := TrainerLibrary.new(data)
		library.load_dir()
		var trainer := library.get_trainer(&"qa_moves_smart")
		var foes := Party.new()
		var seed := 3
		for slot: TrainerSlot in trainer.team_for(&""):
			var pokemon := PokemonFactory.create(data, slot.species, slot.level, GameRng.new(seed))
			pokemon.moves.clear()
			for move_id: StringName in slot.moves:
				pokemon.learn_move(move_id, data)
			seed += 1
			foes.add(pokemon)
		request = BattleRequest.trainer_battle(trainer, foes, {}, director.get_item_library())
	await _run(director, request, map)
	print("CAPTURE_QA_MOVES_J12 terminé")
	quit()


func _run(director: BattleDirector, request: BattleRequest, map: GameMap) -> void:
	var hud: BattleHud = _boot.call(&"get_battle_hud")
	var done: Array[bool] = [false]
	var run := func() -> void:
		await director.run_request(request, map)
		done[0] = true
	run.call()
	var step := 0
	var guard := 0
	var lowered := false
	var wanted := "Destruction" if _flow == "trainer" else "ligot"
	while not done[0] and guard < 6000:
		guard += 1
		var battle := director.get_battle()
		var banner := hud.get_message_banner().get_text()
		if step == 0 and banner.contains(wanted):
			await _frames(12)
			await _shot("destruction_message" if _flow == "trainer" else "ligote_message")
			step = 1
			if _flow == "wild":
				break
		elif step == 1 and _flow == "trainer" and banner.contains("K.O."):
			await _frames(12)
			await _shot("destruction_ko")
			break
		elif battle != null and battle.get_state() == Battle.State.CHOOSING:
			if not lowered and _flow == "trainer":
				var foe := battle.get_foe_side().active.pokemon
				foe.hp = maxi(1, foe.max_hp() / 4)
				lowered = true
			match hud.get_zone():
				BattleHud.Zone.ACTIONS:
					hud.action_selected.emit(ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					hud.move_selected.emit(1)
		await _frames(1)
	print("étape finale : ", step)
