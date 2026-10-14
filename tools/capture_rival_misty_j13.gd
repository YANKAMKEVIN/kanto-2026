extends SceneTree
## Captures du rival n° 3, d'Ondine au pont, de l'Arène et du badge (jalon 13 T19) dans la vraie
## scène `game/boot.tscn` (HUD, lumière, PNJ peints), avec les vrais départs de débogage :
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_rival_misty_j13.gd -- \
##     --mode=rival --out=build/captures/j13_t19
##
## `--mode=` :
## - `rival` : départ `rival_cerulean`, Pikachu Nv. 60 (Éclair) en tête : le rival n° 3 voit le joueur
##   (« ! »), s'approche, n° 28, combat avec **changement de Pokémon** (« rappelle Roucoups »),
##   n° 32, départ, puis la scène d'Ondine au pont (n° 33) → `rival_*.png`, `misty_*.png` ;
## - `gym` : départ `cerulean_gym`, Salamèche Nv. 60 : Ondine au fond, n° 34, carte de Championne,
##   combat, « BADGE CASCADE », remise de la CT11 → `gym_*.png`.

const MODES := {
	"rival": "res://tools/debug_start/rival_cerulean.json",
	"gym": "res://tools/debug_start/cerulean_gym.json",
}
const PAGE_HOLD := 45
const TIMEOUT_FRAMES := 9000

var _out: String = "build/captures/j13_t19"
var _mode: String = "rival"
var _boot: Node
var _player: Node
var _done: Dictionary = {}
var _page: String = ""
var _page_frames: int = 0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _shot(name: String) -> void:
	if _done.has(name):
		return
	_done[name] = true
	DirAccess.make_dir_recursive_absolute(_out)
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [_out, name]
	root.get_texture().get_image().save_png(path)
	print("image : ", path)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"cerulean_city")
	_boot.set(&"start_spawn", &"from_route_24_c")
	root.add_child(_boot)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var start := DebugStart.new()
	if not start.load_file(MODES[_mode], data, _boot.call(&"get_item_library")):
		push_error("capture_rival_misty_j13 : départ illisible")
	var state: Node = root.get_node(^"/root/GameState")
	start.apply(state, data)
	state.set(&"rng", GameRng.new(7))
	var lead_species := &"pikachu" if _mode == "rival" else &"charmander"
	var lead_move := &"thunder_shock" if _mode == "rival" else &"ember"
	var champion := PokemonFactory.create(data, lead_species, 60, state.get(&"rng"))
	champion.moves.clear()
	champion.moves.append(MoveSlot.new(lead_move, 30))
	var party: Party = state.get(&"party")
	while party.size() > 0:
		party.remove_at(0)
	party.add(champion)
	_player = _boot.call(&"get_player")
	# Texte écrit en entier d'emblée (la capture ne dépend pas de la machine à écrire).
	(_boot.call(&"get_dialogue_runner") as DialogueRunner).chars_per_second = 0.0
	await _frames(20)
	var router: Node = root.get_node(^"/root/SceneRouter")
	if _mode == "rival":
		await router.call(&"change_map", &"route_24", &"from_cerulean_c", Vector2i.UP)
	else:
		await router.call(&"change_map", &"cerulean_gym", &"entrance", Vector2i.UP)
	await _frames(30)
	(_boot.call(&"get_battle_director") as BattleDirector).speed_scale = 1.0
	if _mode == "rival":
		await _run_rival()
	else:
		await _run_gym()
	print("CAPTURE_RIVAL_MISTY_J13 terminé : ", _mode)
	quit()


# --- Rival et Ondine au pont ------------------------------------------------------------------

func _run_rival() -> void:
	# Vue d'ensemble du couloir avant la rencontre : le rival dans sa niche, Ondine au loin.
	await _shot("rival_00_couloir")
	Input.action_press(&"move_up")
	var director: CutsceneDirector = _boot.call(&"get_cutscene_director")
	var guard := 0
	while not director.is_running() and guard < 600:
		guard += 1
		await process_frame
	Input.action_release(&"move_up")
	await _frames(14)
	await _shot("rival_01_emote")
	await _frames(40)
	await _shot("rival_02_approche")
	await _drive("rival", {
		"Te voilà.": "rival_03_introduction",
		"…Encore.": "rival_06_victoire",
		"Joli combat.": "misty_01_arrivee",
		"Je suis Ondine, la Championne d'Azuria.": "misty_02_presentation",
		"Viens me voir à l'Arène. Je veux voir ça de plus près.": "misty_03_invitation",
	})
	await _frames(40)
	await _shot("misty_04_apres")


# --- Arène ------------------------------------------------------------------------------------

func _run_gym() -> void:
	_set_beaten()
	await _frames(20)
	await _shot("gym_00_arene")
	var map: GameMap = _boot.call(&"get_map")
	var player := _player as Player
	var path := map.get_grid().find_path(player.get_cell(), Vector2i(7, 3), player)
	var cell := player.get_cell()
	for direction: Vector2i in path:
		cell += direction
		var action: StringName = {Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
			Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right"}[direction]
		Input.action_press(action)
		var guard := 0
		while guard < 300 and not (player.get_cell() == cell and not player.is_moving()):
			guard += 1
			if player.is_moving() and player.get_cell() + direction == cell:
				Input.action_release(action)
			await process_frame
		Input.action_release(action)
	await _frames(40)
	await _shot("gym_01_ondine")
	(_player as Player).face(Vector2i.RIGHT)
	var press := InputEventAction.new()
	press.action = &"interact"
	press.pressed = true
	Input.parse_input_event(press)
	await _frames(6)
	var release := InputEventAction.new()
	release.action = &"interact"
	release.pressed = false
	Input.parse_input_event(release)
	await _frames(10)
	print("après interact : dir=%s cell=%s facing=%s box=%s" % [
		(_boot.call(&"get_cutscene_director") as CutsceneDirector).get_cutscene_id(),
		player.get_cell(), player.get_facing(), _boot.call(&"get_dialogue_box").call(&"is_open")])
	await _drive("gym", {
		"Te voilà.": "gym_02_introduction",
		"…Bien joué.": "gym_06_victoire",
		"Voici le Badge Cascade.": "gym_08_badge_replique",
		"Prends aussi ceci.": "gym_09_ct_replique",
		"C'est la CT11, Bulles d'O. Un Pokémon qui l'apprend la garde, et tu peux t'en resservir.":
			"gym_11_ct_explication",
	})
	await _frames(40)
	await _shot("gym_12_apres")


func _set_beaten() -> void:
	var state: Node = root.get_node(^"/root/GameState")
	var flags: Object = state.get(&"flags")
	flags.call(&"set_flag", &"beaten_cerulean_gym_lucas")
	flags.call(&"set_flag", &"beaten_cerulean_gym_diane")


## Pilote tout ce qui se joue : pages (capture après PAGE_HOLD images, puis avance), carte de
## Championne, combat (ATTAQUER, 1re capacité), légende, toast ; s'arrête quand plus rien ne joue.
func _drive(prefix: String, page_shots: Dictionary) -> void:
	var director: CutsceneDirector = _boot.call(&"get_cutscene_director")
	var runner: Node = _boot.call(&"get_dialogue_runner")
	var box: Node = _boot.call(&"get_dialogue_box")
	var battle_director: BattleDirector = _boot.call(&"get_battle_director")
	var battle_hud: BattleHud = _boot.call(&"get_battle_hud")
	var hud: Node = _boot.call(&"get_hud")
	var router: Node = root.get_node(^"/root/SceneRouter")
	var idle := 0
	var frames := 0
	var battle_shot := false
	while frames < TIMEOUT_FRAMES:
		frames += 1
		if frames % 200 == 0:
			var battle_now := battle_director.get_battle()
			print("frames=%d box=%s battle=%s state=%s zone=%s banner=%s" % [frames,
				box.call(&"is_open"), battle_director.is_running(),
				battle_now.get_state() if battle_now != null else -1, battle_hud.get_zone(),
				battle_hud.get_message_banner().get_text()])
		var busy: bool = director.is_running() or runner.call(&"is_running") \
			or router.call(&"is_transitioning") or battle_director.is_running()
		if busy:
			idle = 0
		else:
			idle += 1
			if idle > 30:
				print("drive fini : frames=%d" % frames)
				return
		if battle_director.is_running():
			var banner: String = battle_hud.get_message_banner().get_text()
			if banner.contains("rappelle"):
				await _frames(14)
				await _shot("%s_04_rappel" % prefix)
				await _frames(8)
				await _shot("%s_04b_rappel_suite" % prefix)
			elif banner.contains("envoie"):
				await _frames(14)
				await _shot("%s_05_envoi" % prefix)
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						if not battle_shot:
							battle_shot = true
							await _frames(30)
							await _shot("%s_05_combat" % prefix)
						battle_hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		var summary := battle_director.get_summary_card()
		if summary != null:
			if summary.is_waiting():
				await _frames(20)
				await _shot("%s_06_bilan" % prefix)
			summary.tap()
		var card: Node = hud.call(&"get_champion_card")
		if card.call(&"is_showing"):
			await _frames(25)
			await _shot("%s_03_carte" % prefix)
			card.call(&"skip_hold")
		var caption: Node = hud.call(&"get_caption")
		if caption.call(&"is_showing"):
			await _frames(25)
			await _shot("%s_07_badge_legende" % prefix)
		var toast: Node = hud.call(&"get_toast")
		if toast.visible:
			await _frames(8)
			await _shot("%s_10_ct_toast" % prefix)
		await process_frame
		if box.call(&"is_open"):
			var text: String = box.call(&"get_text")
			if text != _page:
				_page = text
				_page_frames = 0
			_page_frames += 1
			if _page_frames == PAGE_HOLD:
				if page_shots.has(text):
					await _shot(page_shots[text])
				box.emit_signal(&"advance_requested")
