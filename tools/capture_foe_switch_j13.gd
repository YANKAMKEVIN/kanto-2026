extends SceneTree
## Captures du rappel adverse (jalon 13 T13, dossier 16 §14), vrai Boot sur la Route 1, combat
## de Dresseur d'essai « switch » (Salamèche craint Carapuce, Roucool en forme) :
##   rappel_message   (« Ondine rappelle Salamèche ! »)
##   rappel_NN        (le rappel en cours, quelques images)
##   envoi            (« Ondine envoie Roucool ! »)
##   apres_changement (carte et sprite du nouveau, choix du joueur)
## « --reduce » : même chose avec « Réduire les animations » (préfixe reduit_).
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 6000 \
##     -s res://tools/capture_foe_switch_j13.gd -- --out=build/captures/jalon13_t13

var _boot: Node
var _out_dir: String = "build/captures/jalon13_t13"
var _prefix: String = ""
var _reduce: bool = false


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg == "--reduce":
			_reduce = true
			_prefix = "reduit_"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(name: String) -> void:
	RenderingServer.force_draw(true)
	root.get_texture().get_image().save_png("%s/%s%s.png" % [_out_dir, _prefix, name])
	print("capture : ", _prefix, name)


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
	state.set(&"starter_species", &"squirtle")
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var party: Party = state.get(&"party")
	party.add(PokemonFactory.create(data, &"squirtle", 12, GameRng.new(7)))
	var stage: BattleStage = _boot.call(&"get_battle_stage") \
		if _boot.has_method(&"get_battle_stage") else null
	if _reduce and stage != null:
		stage.reduce_motion = true
	await _flow(data)
	print("CAPTURE_FOE_SWITCH_J13 terminé")
	quit()


func _flow(data: PokemonData) -> void:
	var director: BattleDirector = _boot.call(&"get_battle_director")
	var hud: BattleHud = _boot.call(&"get_battle_hud")
	var map: GameMap = _boot.call(&"get_map")
	var trainer := TrainerData.new()
	trainer.id = &"qa_capture_switch"
	trainer.name = "Ondine"
	trainer.ai = BattleAI.SMART
	trainer.can_switch = true
	trainer.gives_exp = false
	var foes := Party.new()
	foes.add(PokemonFactory.create(data, &"charmander", 9, GameRng.new(3)))
	foes.add(PokemonFactory.create(data, &"pidgey", 9, GameRng.new(4)))
	var request := BattleRequest.trainer_battle(trainer, foes, {}, director.get_item_library())
	var done: Array[bool] = [false]
	var run := func() -> void:
		await director.run_request(request, map)
		done[0] = true
	run.call()
	var step := 0
	var guard := 0
	while not done[0] and guard < 4000:
		guard += 1
		var battle := director.get_battle()
		var banner := hud.get_message_banner().get_text()
		if step == 0 and banner.contains("rappelle"):
			await _frames(10)
			await _shot("rappel_message")
			step = 1
			# Le rappel suit la phrase : quelques images pendant qu'il se joue.
			for i: int in 24:
				await _frames(2)
				await _shot("rappel_%02d" % i)
		elif step == 1 and banner.contains("envoie"):
			await _frames(14)
			await _shot("envoi")
			step = 2
		elif battle != null and battle.get_state() == Battle.State.CHOOSING:
			match hud.get_zone():
				BattleHud.Zone.ACTIONS:
					if step == 2:
						await _frames(30)
						await _shot("apres_changement")
						step = 3
					hud.action_selected.emit(ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					hud.move_selected.emit(0)
		await _frames(1)
	await _frames(30)
