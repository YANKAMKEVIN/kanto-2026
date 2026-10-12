extends SceneTree
## Captures de la carte de QA du jalon 13 (T14) avec le vrai départ `switch_qa` (Boot) :
##   carte            (le joueur au départ, trois Dresseurs d'essai, hautes herbes)
##   carte_rival      (au pied du couloir du Rival d'essai)
##   rappel_message / envoi / apres_changement : combat réel contre « Rival d'essai »
##                    (Carapuce en tête : Salamèche craint l'eau → rappel, envoi de Roucool)
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 6000 \
##     -s res://tools/capture_qa_switch_j13.gd -- --out=build/captures/jalon13_t14

var _boot: Node
var _out_dir: String = "build/captures/jalon13_t14"


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
	RenderingServer.force_draw(true)
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
	print("capture : ", name)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"force_debug_start", true)
	_boot.set(&"debug_start_path", "res://tools/debug_start/switch_qa.json")
	root.add_child(_boot)
	await _frames(90)
	await _shot("carte")
	var map: GameMap = _boot.call(&"get_map")
	print("carte : ", map.map_id)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var library := TrainerLibrary.new(data)
	library.load_dir()
	await _flow(data, library.get_trainer(&"qa_switch_rival"), map)
	print("CAPTURE_QA_SWITCH_J13 terminé")
	quit()


func _flow(data: PokemonData, trainer: TrainerData, map: GameMap) -> void:
	var director: BattleDirector = _boot.call(&"get_battle_director")
	var hud: BattleHud = _boot.call(&"get_battle_hud")
	var foes := Party.new()
	var seed := 3
	for slot: TrainerSlot in trainer.team_for(&""):
		var pokemon := PokemonFactory.create(data, slot.species, slot.level, GameRng.new(seed))
		seed += 1
		foes.add(pokemon)
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
						break
					hud.action_selected.emit(ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					hud.move_selected.emit(0)
		await _frames(1)
	print("étape finale : ", step)
