extends SceneTree
## Captures du T18b (jalon 14 : Super Bonbon dans le Sac), vrai Boot sur le départ
## `rare_candy_qa` (maison de Léo), à vitesse réelle :
##   01_bag_candy          Sac → AVENTURE, Super Bonbon sélectionné (UTILISER)
##   02_candy_targets      UTILISER : l'équipe, « Sans effet » (N100), « Ce Pokémon est K.O. »
##   03_candy_refused      toucher Roucarnage N100 : refus dans le bandeau, rien consommé
##   04_candy_level        Abra : voile au-dessus du Sac, « Abra monte au niveau 16 ! »
##   05_evolution_present  « Quoi ? Abra évolue ! » (menu fermé)
##   06_evolution_stop     transformation **avec ARRÊTER** (évolution par niveau)
##   07_evolution_end      Kadabra révélé
##   08_forget_offer       Papilusion → N21 : « veut apprendre Ultrason »
##   09_forget_panel       écran « oublier une capacité »
##   10_back_to_bag        après l'oubli : retour au Sac, Papilusion N21, 3 bonbons
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_rare_candy_t18b.gd -- --out=build/captures/jalon14_t18b

const FPS := 30.0
const START := "res://tools/debug_start/rare_candy_qa.json"
const CANDY := &"rare_candy"

var _boot: Node
var _out_dir: String = "build/captures/jalon14_t18b"


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _seconds(seconds: float) -> void:
	await _frames(roundi(seconds * FPS))


func _shot(name: String) -> void:
	await _frames(2)
	var path := _out_dir.path_join(name + ".png")
	root.get_texture().get_image().save_png(path)
	print("CAPTURE ", path)


func _touch_at(point: Vector2) -> void:
	for pressed: bool in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.pressed = pressed
		touch.position = point
		root.push_input(touch, true)


func _until(predicate: Callable, max_frames: int = 900) -> void:
	var guard := 0
	while not predicate.call() and guard < max_frames:
		await process_frame
		guard += 1


func _start() -> void:
	var state: Node = root.get_node("GameState")
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(START))
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", StringName(json["map"]))
	_boot.set(&"start_spawn", StringName(json["spawn"]))
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(30)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var start := DebugStart.new()
	if not start.load_file(START, data, _boot.call(&"get_item_library")):
		push_error("\n".join(start.get_errors()))
		quit(1)
		return
	start.apply(state, data)
	_boot.call(&"get_map").call(&"refresh_npcs", state.get(&"flags"))
	await _frames(30)
	var party: Party = state.get(&"party")
	var bag: Bag = state.get(&"bag")
	var menu: MenuDirector = _boot.call(&"get_menu_director")
	var screen: TrainerMenu = _boot.call(&"get_trainer_menu")
	var overlay_of := func() -> TmLearnOverlay: return _boot.call(&"get_tm_learn_overlay")
	menu.open(MenuRoute.bag())
	await _frames(20)
	var bag_screen := screen.get_bag()
	bag_screen.open_category(&"field")
	bag_screen.select_item(CANDY)
	await _frames(20)
	await _shot("01_bag_candy")
	bag_screen.get_action_button().pressed.emit()
	await _frames(20)
	await _shot("02_candy_targets")
	bag_screen.get_picker().call(&"_on_card_tapped", 2)
	await _frames(20)
	await _shot("03_candy_refused")
	print("BONBONS APRÈS REFUS ", bag.count_of(CANDY))
	# Abra : niveau, puis évolution annulable.
	menu.use_item_on(CANDY, 0)
	var overlay: TmLearnOverlay = overlay_of.call()
	await _until(func() -> bool: return overlay.get_message_banner().is_waiting())
	await _seconds(0.3)
	await _shot("04_candy_level")
	overlay.get_message_banner().skip()
	var evolutions: EvolutionDirector = _boot.call(&"get_evolution_director")
	var evo_screen := evolutions.get_screen()
	await _until(func() -> bool: return evolutions.is_playing())
	await _seconds(1.4)
	await _shot("05_evolution_present")
	await _until(func() -> bool: return evo_screen.is_transforming())
	await _seconds(1.0)
	print("ARRÊTER actif ", evo_screen.is_stop_active())
	await _shot("06_evolution_stop")
	await _until(func() -> bool: return evo_screen.is_waiting_touch())
	await _seconds(0.6)
	await _shot("07_evolution_end")
	var guard := 0
	while evolutions.is_playing() and guard < 900:
		if guard % 20 == 0:
			_touch_at(root.get_visible_rect().size * Vector2(0.5, 0.3))
		await process_frame
		guard += 1
	await _until(func() -> bool: return not _boot.call(&"is_rare_candy_running"))
	await _seconds(1.0)
	print("ABRA → ", party.get_at(0).species_id, " N", party.get_at(0).level, " BONBONS ",
		bag.count_of(CANDY))
	# Papilusion : quatre capacités, écran « oublier ».
	menu.open(MenuRoute.bag())
	await _frames(20)
	bag_screen.open_category(&"field")
	bag_screen.select_item(CANDY)
	await _frames(10)
	bag_screen.get_action_button().pressed.emit()
	await _frames(20)
	menu.use_item_on(CANDY, 1)
	overlay = overlay_of.call()
	await _until(func() -> bool: return overlay.get_message_banner().is_waiting())
	overlay.get_message_banner().skip()
	await _until(func() -> bool: return overlay.get_message_banner().is_waiting() \
		or _forget_panel() != null)
	await _seconds(0.3)
	await _shot("08_forget_offer")
	await _until(func() -> bool: return _forget_panel() != null \
		and _forget_panel().is_visible_in_tree())
	await _seconds(0.8)
	await _shot("09_forget_panel")
	_forget_panel().forget_chosen.emit(0)
	await _until(func() -> bool: return overlay.get_message_banner().is_waiting())
	overlay.get_message_banner().skip()
	await _until(func() -> bool: return not _boot.call(&"is_rare_candy_running"))
	await _seconds(0.8)
	await _shot("10_back_to_bag")
	print("PAPILUSION N", party.get_at(1).level, " BONBONS ", bag.count_of(CANDY))
	print("CAPTURE_T18B terminé")
	quit()


func _forget_panel() -> MoveForgetPanel:
	var battle: BattleDirector = _boot.call(&"get_battle_director")
	return battle.get_move_learn_prompt().get_forget_panel()
