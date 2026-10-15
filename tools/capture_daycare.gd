extends SceneTree
## Captures de l'écran de la Pension (J15 T5) avec le vrai Boot (Centre de Jadielle en décor) :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 3000 \
##     -s res://tools/capture_daycare.gd -- --out=build/captures/j15_t5
## Images : daycare_pick (choix ouvert, une raison de refus visible), daycare_pick_t5 (refus
## touché : T-5 en titre), daycare_learn (« veut apprendre » pendant un retrait),
## daycare_forget (panneau d'oubli, quatre capacités connues).

var _out_dir: String = "build/captures/j15_t5"
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
	_boot.set(&"start_spawn", &"heal")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(40)
	_state = root.get_node("GameState")
	_state.call(&"new_game", 15)
	_boot.call(&"get_hud").call(&"set_controls_visible", false)
	await _pick()
	await _learn()
	print("CAPTURE_DAYCARE terminé")
	quit()


func _mon(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_boot.call(&"get_pokemon_data"), species, level, GameRng.new(level))


func _pick() -> void:
	var party: Party = _state.get("party")
	var rattata := _mon(&"rattata", 7)
	var pidgey := _mon(&"pidgey", 5)
	pidgey.hp = 0
	var charmander := _mon(&"charmander", 9)
	charmander.hp = 0
	party.add(rattata)
	party.add(pidgey)
	party.add(charmander)
	var runner: DialogueRunner = _boot.call(&"get_dialogue_runner")
	runner.play(DaycareLines.KEEPER, null, _boot.call(&"get_map"))
	var box: Node = _boot.call(&"get_dialogue_box")
	var overlay: DaycareOverlay = _boot.call(&"get_daycare_overlay")
	await _drive(func() -> bool: return overlay.is_picking(), true)
	await _frames(30)
	await _shot("daycare_pick")
	overlay.get_picker().get_card(0).tapped.emit()
	await _frames(6)
	await _shot("daycare_pick_t5")
	overlay.get_picker().get_cancel_button().pressed.emit()
	await _drive(func() -> bool: return not runner.is_running(), false)


func _learn() -> void:
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	_state = root.get_node("GameState")
	_state.call(&"new_game", 15)
	_state.set(&"money", 5000)
	var charmander := _mon(&"charmander", 8)
	for move_id: StringName in [&"tackle", &"tail_whip"]:
		charmander.learn_move(move_id, data)
	charmander.ensure_uid()
	var daycare: Daycare = _state.get("daycare")
	daycare.put(charmander, data)
	daycare.pending_exp = ExpCurve.exp_for_level(data.get_species(&"charmander").growth_rate, 16) \
		- charmander.experience
	_state.get("party").add(_mon(&"rattata", 5))
	var runner: DialogueRunner = _boot.call(&"get_dialogue_runner")
	runner.play(DaycareLines.KEEPER, null, _boot.call(&"get_map"))
	var overlay: DaycareOverlay = _boot.call(&"get_daycare_overlay")
	var banner := overlay.get_message_banner()
	await _drive(func() -> bool: return overlay.is_open() and banner.is_waiting(), true)
	await _frames(20)
	await _shot("daycare_learn")
	var prompt: MoveLearnPrompt = _boot.call(&"get_battle_director").call(&"get_move_learn_prompt")
	for i: int in 200:
		banner.skip() if banner.is_waiting() else null
		var panel := prompt.get_forget_panel()
		if panel != null and panel.is_visible_in_tree() and panel.is_shown() \
				and not panel.is_sliding():
			break
		await process_frame
	await _frames(20)
	await _shot("daycare_forget")


## Fait avancer le dialogue (OUI aux choix) jusqu'à [param done].
func _drive(done: Callable, yes: bool) -> void:
	var runner: DialogueRunner = _boot.call(&"get_dialogue_runner")
	var box: Node = _boot.call(&"get_dialogue_box")
	for i: int in 900:
		if done.call():
			return
		if box.call(&"is_choice_showing"):
			var cards: Node = box.call(&"get_choice_cards")
			(cards.call(&"get_confirm_button") if yes else cards.call(&"get_cancel_button")) \
				.emit_signal(&"pressed")
		elif box.call(&"is_open") and not runner.is_awaiting_choice():
			box.emit_signal(&"advance_requested")
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var path := _out_dir.path_join(name + ".png")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s viewport=%s" % [path, root.get_visible_rect().size])


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
