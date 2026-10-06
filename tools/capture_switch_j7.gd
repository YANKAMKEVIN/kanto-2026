extends SceneTree
## Captures du changement de Pokémon en combat (jalon 7, jalon-07.md §15.23), vrai Boot sur la
## Route 1, combats sauvages :
##   equipe_panneau, equipe_refus  (ÉQUIPE ouvert ; toucher un K.O. : la raison)
##   rappel, envoi, apres_changement (« Reviens », « En avant », la carte du nouveau)
##   ko_choix, ko_apres              (K.O. : choix forcé sans « ‹ », puis la carte du remplaçant)
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 6000 \
##     -s res://tools/capture_switch_j7.gd -- --out=build/captures/jalon07_changement

var _boot: Node
var _out_dir: String = "build/captures/jalon07_changement"


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
	RenderingServer.force_draw(true)
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
	print("capture : ", name)


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
	party.get_at(0).hp = 21
	party.get_at(1).hp = 0
	await _switch_flow(state, data)
	party.heal_all()
	party.get_at(0).hp = 1
	party.get_at(1).hp = 0
	await _knock_out_flow(state, data)
	print("CAPTURE_SWITCH_J7 terminé")
	quit()


func _request(state: Node, data: PokemonData, level: int, move: StringName) -> BattleRequest:
	var director: BattleDirector = _boot.call(&"get_battle_director")
	var enc := WildEncounter.new(&"rattata", level, &"route_1_grass")
	var request := BattleRequest.wild(enc, data, state.get(&"rng") as GameRng, Vector2i(5, 4),
		director.get_item_library())
	var foe := request.foe_party.get_lead()
	foe.moves.clear()
	foe.learn_move(move, data)
	return request


func _run(request: BattleRequest) -> Array[bool]:
	var director: BattleDirector = _boot.call(&"get_battle_director")
	var map: GameMap = _boot.call(&"get_map")
	var done: Array[bool] = [false]
	var run := func() -> void:
		await director.run_request(request, map)
		done[0] = true
	run.call()
	return done


func _switch_flow(state: Node, data: PokemonData) -> void:
	var director: BattleDirector = _boot.call(&"get_battle_director")
	var hud: BattleHud = _boot.call(&"get_battle_hud")
	var done := _run(_request(state, data, 6, &"tail_whip"))
	var stage := 0
	var guard := 0
	while not done[0] and guard < 3000:
		guard += 1
		var panel := director.get_party_panel()
		var battle := director.get_battle()
		var banner := hud.get_message_banner().get_text()
		var choosing := battle != null and battle.get_state() == Battle.State.CHOOSING \
			and hud.get_zone() == BattleHud.Zone.ACTIONS
		if stage == 1 and panel != null and panel.is_shown() and not panel.is_answered() \
				and not panel.is_sliding():
			await _frames(20)
			await _shot("equipe_panneau")
			panel.get_card(1).tapped.emit()
			await _frames(10)
			await _shot("equipe_refus")
			panel.select(2)
			await _frames(5)
			panel.get_send_button().pressed.emit()
			stage = 2
		elif stage == 2 and banner.begins_with("Reviens"):
			await _frames(12)
			await _shot("rappel")
			stage = 3
		elif stage == 3 and banner.begins_with("En avant"):
			await _frames(14)
			await _shot("envoi")
			stage = 4
		elif choosing:
			if stage == 0:
				stage = 1
				hud.action_selected.emit(ActionGrid.TEAM)
			elif stage == 4:
				await _frames(45)
				var card := hud.get_card(BattleHud.Side.PLAYER)
				print("carte joueur : affichée=%s alpha=%.2f" % [card.is_shown(), card.modulate.a])
				await _shot("apres_changement")
				stage = 5
				hud.action_selected.emit(ActionGrid.RUN)
			else:
				hud.action_selected.emit(ActionGrid.RUN)
		await _frames(1)
	await _frames(60)


func _knock_out_flow(state: Node, data: PokemonData) -> void:
	var director: BattleDirector = _boot.call(&"get_battle_director")
	var hud: BattleHud = _boot.call(&"get_battle_hud")
	var done := _run(_request(state, data, 8, &"tackle"))
	var stage := 0
	var guard := 0
	while not done[0] and guard < 3000:
		guard += 1
		var panel := director.get_party_panel()
		var battle := director.get_battle()
		if stage == 0 and panel != null and panel.is_shown() and not panel.is_answered() \
				and not panel.is_sliding():
			await _frames(20)
			await _shot("ko_choix")
			panel.get_send_button().pressed.emit()
			stage = 1
		elif battle != null and battle.get_state() == Battle.State.CHOOSING:
			match hud.get_zone():
				BattleHud.Zone.ACTIONS:
					if stage == 1:
						await _frames(20)
						await _shot("ko_apres")
						stage = 2
					hud.action_selected.emit(ActionGrid.RUN if stage >= 1 else ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					hud.move_selected.emit(0)
		await _frames(1)
	await _frames(60)
