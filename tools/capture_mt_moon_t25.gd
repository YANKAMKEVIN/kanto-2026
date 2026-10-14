extends SceneTree
## Captures de l'événement du Mont Sélénite (jalon 12, T25) sur le vrai Boot :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 -s res://tools/capture_mt_moon_t25.gd \
##     -- --out=build/captures/jalon12_t25
## Images : r1_poste (le guetteur dans sa niche entre ses lampes), r1_hey (« Hé, toi ! … »),
## r2_creuse (la fouilleuse qui creuse au bord de la tranchée), r3_bulle_1 / r3_bulle_3 (scène du
## gardien), r3_combat (décor « chambre »), chercheur_meprise (n° 20), chercheur_partage (n° 22),
## dalle (les deux fossiles refaits sur la dalle, joueur derrière), choix_question (OUI / NON),
## toast_fossile, chercheur_choisi (n° 24), dalle_vide, dresseur_frise (Grand moment `fossil`),
## pierre_lune_b1f (Ball de la poche), cache_b2f (éclat isolé, EXAMINER), ct01.

const TIMEOUT_MS := 60000

var _boot: Node
var _out_dir: String = "build/captures/jalon12_t25"


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
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
	print("CAPTURE ", name)


func _player() -> Player:
	return _boot.call(&"get_player")


func _map() -> GameMap:
	return _boot.call(&"get_map")


func _runner() -> DialogueRunner:
	return _boot.call(&"get_dialogue_runner")


func _director() -> CutsceneDirector:
	return _boot.call(&"get_cutscene_director")


func _step(direction: Vector2i) -> void:
	_player().script_step(direction)
	await _frames(1)
	while _player().is_moving():
		await process_frame
	await _frames(10)


func _put(cell: Vector2i, facing: Vector2i) -> void:
	_player().enter_map(_map().get_grid(), cell, facing, _map().get_pixel_rect())
	await _frames(10)


func _interact() -> void:
	# Deux essais : après un dialogue, le contrôleur attend d'abord que la touche soit relâchée.
	for attempt: int in 2:
		Input.action_press(&"interact")
		await _frames(3)
		Input.action_release(&"interact")
		await _frames(30)
		if _runner().is_running() or _director().is_running():
			return


func _advance() -> void:
	var box: DialogueBox = _boot.call(&"get_dialogue_box")
	if box.is_open():
		box.advance_requested.emit()
	await _frames(20)


## Attend que la page affichée soit [param text] (en pilotant le combat et en avançant les autres
## pages), ou la fin de la scène.
func _until_page(text: String) -> void:
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		var session := _runner().get_session()
		if _runner().is_running() and session != null and session.get_text() == text:
			await _frames(20)
			return
		if not _runner().is_running() and not _director().is_running():
			return
		await _pilot()
		var box: DialogueBox = _boot.call(&"get_dialogue_box")
		if box.is_open() and not _runner().is_awaiting_choice():
			box.advance_requested.emit()
		await _frames(4)


## Un tour du combat piloté (première capacité).
func _pilot() -> void:
	var battles: Node = _boot.call(&"get_battle_director")
	if not bool(battles.call(&"is_running")):
		return
	var battle: Battle = battles.call(&"get_battle")
	var hud: BattleHud = _boot.call(&"get_battle_hud")
	if battle != null and battle.get_state() == Battle.State.CHOOSING:
		match hud.get_zone():
			BattleHud.Zone.ACTIONS:
				hud.action_selected.emit(ActionGrid.ATTACK)
			BattleHud.Zone.MOVES:
				hud.move_selected.emit(0)


func _finish() -> void:
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	var router: Node = root.get_node(^"SceneRouter")
	while (_runner().is_running() or _director().is_running()
			or bool(router.call(&"is_transitioning"))) and Time.get_ticks_msec() < deadline:
		await _pilot()
		var box: DialogueBox = _boot.call(&"get_dialogue_box")
		if box.is_open() and not _runner().is_awaiting_choice():
			box.advance_requested.emit()
		await _frames(4)
	await _frames(20)


func _change_map(map_id: StringName, spawn: StringName) -> void:
	var router: Node = root.get_node(^"SceneRouter")
	router.call(&"change_map", map_id, spawn, Vector2i.DOWN)
	while _map().map_id != map_id or bool(router.call(&"is_transitioning")):
		await process_frame
	await _frames(20)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"mt_moon_b1f")
	_boot.set(&"start_spawn", &"arrivee_a")
	_boot.set(&"start_facing", Vector2i.DOWN)
	root.add_child(_boot)
	await _frames(30)
	var state: Node = root.get_node(^"GameState")
	var flags := state.get(&"flags") as StoryFlags
	for flag: StringName in [&"starter_chosen", &"pokedex_activated", &"badge_boulder",
			&"route_3_entered"]:
		flags.set_flag(flag)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var mon := PokemonFactory.create(data, &"charmeleon", 40, GameRng.new(7))
	mon.moves.clear()
	mon.moves.append(MoveSlot.new(&"ember", 25))
	(state.get(&"party") as Party).add(mon)
	_runner().chars_per_second = 0.0
	(_boot.call(&"get_battle_director") as Node).set(&"speed_scale", 0.0)
	_map().refresh_npcs(flags)
	# R1 dans sa niche, puis « Hé, toi ! ».
	await _put(Vector2i(11, 5), Vector2i.RIGHT)
	await _frames(20)
	await _shot("r1_poste")
	await _step(Vector2i.RIGHT)
	await _step(Vector2i.RIGHT)
	await _step(Vector2i.RIGHT)
	await _until_page("Hé, toi ! Ce passage est interdit.\nFais demi-tour.")
	await _shot("r1_hey")
	await _finish()
	# R2 qui creuse.
	await _put(Vector2i(11, 18), Vector2i.LEFT)
	await _frames(20)
	await _shot("r2_creuse")
	# Pierre Lune visible de la poche.
	await _put(Vector2i(25, 22), Vector2i.UP)
	await _frames(15)
	await _shot("pierre_lune_b1f")
	# B2F : R3.
	await _change_map(&"mt_moon_b2f", &"arrivee_d")
	await _put(Vector2i(25, 21), Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	await _until_page("Les fossiles sont à nous.")
	await _shot("r3_bulle_1")
	await _advance()
	await _advance()
	await _shot("r3_bulle_3")
	await _advance()
	var battles: Node = _boot.call(&"get_battle_director")
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while not bool(battles.call(&"is_running")) and Time.get_ticks_msec() < deadline:
		await process_frame
	await _frames(3)
	await _shot("r3_combat")
	await _finish()
	# Le chercheur : méprise, combat, partage.
	await _put(Vector2i(25, 26), Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	await _until_page("Encore un de ces voleurs ?!")
	await _shot("chercheur_meprise")
	await _until_page("Un fossile chacun. Choisis.")
	await _shot("chercheur_partage")
	await _finish()
	# La dalle et les deux fossiles ; le joueur derrière (nord), puis le choix.
	await _put(Vector2i(25, 29), Vector2i.DOWN)
	await _step(Vector2i.LEFT)
	_player().script_step(Vector2i.DOWN)
	await _frames(20)
	await _shot("dalle")
	await _interact()
	await _until_page("Prendre le Fossile Dôme ?")
	await _advance()
	await _frames(20)
	await _shot("choix_question")
	_runner().choose(false)
	await _frames(30)
	await _interact()
	await _until_page("Prendre le Fossile Dôme ?")
	await _advance()
	_runner().choose(true)
	await _frames(24)
	await _shot("toast_fossile")
	await _until_page("Alors je garde celui-ci.")
	await _shot("chercheur_choisi")
	await _finish()
	await _shot("dalle_vide")
	# Pierre Lune cachée (B2F) et CT01.
	await _put(Vector2i(34, 12), Vector2i.RIGHT)
	await _step(Vector2i.RIGHT)
	await _frames(15)
	await _shot("cache_b2f")
	await _put(Vector2i(5, 7), Vector2i.UP)
	await _step(Vector2i.UP)
	_player().script_step(Vector2i.LEFT)
	await _frames(15)
	await _shot("ct01")
	# Grand moment dans l'écran Dresseur.
	var menu: Node = _boot.call(&"get_menu_director")
	menu.call(&"open", MenuRoute.trainer())
	await _frames(90)
	var scroll: ScrollContainer = (_boot.call(&"get_trainer_menu") as TrainerMenu) \
		.get_trainer().get_scroll()
	scroll.scroll_vertical = 100000
	await _frames(30)
	await _shot("dresseur_frise")
	print("CAPTURE_MT_MOON_T25 terminé")
	quit()
