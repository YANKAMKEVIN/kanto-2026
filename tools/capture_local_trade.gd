extends SceneTree
## Captures du terminal d'échange local (jalon 32, T5) avec le vrai Boot (Centre de Jadielle) :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 3000 \
##     -s res://tools/capture_local_trade.gd -- --out=build/captures/j32_t5
## Images : trade_room (le joueur devant le terminal, bouton EXAMINER), trade_pick (choix,
## places refusées avec leur raison), trade_confirm (« Échanger … ? »), trade_evolution (écran
## d'évolution), trade_done (Alakazam dans l'équipe, Menu Dresseur).

var _out_dir: String = "build/captures/j32_t5"
var _boot: Node
var _state: Node


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"viridian_center")
	_boot.set(&"start_spawn", &"trade_terminal")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(40)
	_state = root.get_node("GameState")
	_state.call(&"new_game", 32)
	var party: Party = _state.get("party")
	for row: Array in [[&"kadabra", 30], [&"machoke", 32], [&"graveler", 30], [&"haunter", 28],
			[&"pikachu", 25], [&"pidgeotto", 25]]:
		party.add(_mon(row[0], row[1]))
	_state.call(&"ensure_unique_uids")
	await _frames(30)
	await _shot("trade_room")
	_boot.call(&"get_hud").call(&"set_controls_visible", false)
	var runner: DialogueRunner = _boot.call(&"get_dialogue_runner")
	runner.play(&"trade_terminal", null, _boot.call(&"get_map"))
	var overlay: TradeOverlay = _boot.call(&"get_trade_overlay")
	await _drive(func() -> bool: return overlay.is_picking())
	await _frames(30)
	await _shot("trade_pick")
	overlay.get_picker().get_card(0).tapped.emit()
	var box: DialogueBox = _boot.call(&"get_dialogue_box")
	await _drive(func() -> bool: return box.is_choice_showing())
	await _frames(20)
	await _shot("trade_confirm")
	box.get_choice_cards().get_confirm_button().pressed.emit()
	var evolutions: EvolutionDirector = _boot.call(&"get_evolution_director")
	await _wait(func() -> bool: return evolutions.is_playing())
	await _frames(150)
	await _shot("trade_evolution")
	var trade: LocalTradeDirector = _boot.call(&"get_local_trade_director")
	for i: int in 1500:
		if not trade.is_running():
			break
		var banner := evolutions.get_screen().get_message_banner()
		if banner != null and banner.is_waiting():
			banner.skip()
		var prompt: MoveLearnPrompt = _boot.call(&"get_battle_director").call(
			&"get_move_learn_prompt")
		var panel := prompt.get_forget_panel()
		if panel != null and panel.is_visible_in_tree() and panel.is_shown() \
				and not panel.is_sliding() and not panel.is_answered():
			panel.get_skip_button().pressed.emit()
		await process_frame
	print("CAPTURE_LOCAL_TRADE équipe : %s" % [party.get_all().map(
		func(p: Pokemon) -> String: return String(p.species_id))])
	await _frames(30)
	await _shot("trade_done")
	print("CAPTURE_LOCAL_TRADE terminé")
	quit()


func _mon(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_boot.call(&"get_pokemon_data"), species, level, GameRng.new(level))


## Fait avancer le dialogue jusqu'à [param done].
func _drive(done: Callable) -> void:
	var runner: DialogueRunner = _boot.call(&"get_dialogue_runner")
	var box: Node = _boot.call(&"get_dialogue_box")
	for i: int in 900:
		if done.call():
			return
		if box.call(&"is_open") and not runner.is_awaiting_choice() \
				and not box.call(&"is_choice_showing"):
			box.emit_signal(&"advance_requested")
		await process_frame


func _wait(done: Callable) -> void:
	for i: int in 900:
		if done.call():
			return
		await process_frame


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var path := _out_dir.path_join(name + ".png")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s viewport=%s" % [path, root.get_visible_rect().size])
