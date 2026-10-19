extends SceneTree
## Captures du rival n° 4 et du capitaine du S.S. Anne (jalon 16 T13) dans la vraie scène
## `game/boot.tscn` (HUD, lumière, PNJ), avec les vrais départs de débogage :
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_rival_captain_j16.gd -- \
##     --mode=rival --out=build/captures/j16_t13
##
## `--mode=` :
## - `rival` : départ `ss_anne_rival`, Salamèche Nv. 60 (Flammèche) : le joueur entre dans la vue
##   (colonne 7), « ! », recentrage, approche, introduction n° 16, combat, n° 19, départ du rival
##   vers la sortie → `rival_*.png` ;
## - `captain` : départ `ss_anne_captain` (rival battu) : la cabine, le capitaine malade (dos),
##   CAP-01, narration, CAP-02, CAP-03, toast de la CS01, CAP-04 → `captain_*.png`.

const MODES := {
	"rival": "res://tools/debug_start/ss_anne_rival.json",
	"captain": "res://tools/debug_start/ss_anne_captain.json",
}
const PAGE_HOLD := 45
const TIMEOUT_FRAMES := 9000
const ACTIONS := {Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right"}

var _out: String = "build/captures/j16_t13"
var _mode: String = "rival"
var _boot: Node
var _player: Player
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
	_boot.set(&"start_map", &"ss_anne_main_deck")
	_boot.set(&"start_spawn", &"from_corridor")
	root.add_child(_boot)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var start := DebugStart.new()
	if not start.load_file(MODES[_mode], data, _boot.call(&"get_item_library")):
		push_error("capture_rival_captain_j16 : départ illisible")
	var state: Node = root.get_node(^"/root/GameState")
	start.apply(state, data)
	state.set(&"rng", GameRng.new(7))
	if _mode == "rival":
		var champion := PokemonFactory.create(data, &"charmander", 60, state.get(&"rng"))
		champion.moves.clear()
		champion.moves.append(MoveSlot.new(&"ember", 30))
		var party: Party = state.get(&"party")
		while party.size() > 0:
			party.remove_at(0)
		party.add(champion)
	_player = _boot.call(&"get_player") as Player
	(_boot.call(&"get_dialogue_runner") as DialogueRunner).chars_per_second = 0.0
	await _frames(20)
	var router: Node = root.get_node(^"/root/SceneRouter")
	if _mode == "rival":
		await router.call(&"change_map", &"ss_anne_captain_corridor", &"entrance", Vector2i.UP)
	else:
		await router.call(&"change_map", &"ss_anne_captain_room", &"entrance", Vector2i.UP)
	await _frames(30)
	(_boot.call(&"get_battle_director") as BattleDirector).speed_scale = 1.0
	if _mode == "rival":
		await _run_rival()
	else:
		await _run_captain()
	print("CAPTURE_RIVAL_CAPTAIN_J16 terminé : ", _mode)
	quit()


# --- Rival ------------------------------------------------------------------------------------

func _run_rival() -> void:
	await _shot("rival_00_couloir")
	await _walk_path([Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4)])
	await _shot("rival_00b_avant_la_vue")
	Input.action_press(&"move_right")
	var director: CutsceneDirector = _boot.call(&"get_cutscene_director")
	var guard := 0
	while not director.is_running() and guard < 600:
		guard += 1
		await process_frame
	Input.action_release(&"move_right")
	await _frames(14)
	await _shot("rival_01_emote")
	await _frames(60)
	await _shot("rival_02_approche")
	await _drive("rival", {
		"Tiens. Toi aussi, tu as un billet.": "rival_03_introduction",
		"…D'accord. Cette fois, je l'admets.": "rival_06_victoire",
		"Va voir ton capitaine. Moi, j'ai mieux à faire.": "rival_07_victoire_fin",
	})
	await _frames(40)
	await _shot("rival_08_apres")


# --- Capitaine --------------------------------------------------------------------------------

func _run_captain() -> void:
	await _shot("captain_00_cabine")
	await _walk_path([Vector2i(6, 6), Vector2i(6, 5), Vector2i(6, 4), Vector2i(7, 4),
		Vector2i(8, 4)])
	_player.face(Vector2i.UP)
	await _frames(20)
	await _shot("captain_01_devant")
	await _interact()
	await _drive("captain", {
		"Ooh… ce roulis…": "captain_02_cap01",
		"Tu lui frottes doucement le dos.": "captain_03_narration",
		"Ah… merci. Ça va beaucoup mieux.": "captain_04_cap02",
		"Tiens, prends ça. C'est la CS01, Coupe.": "captain_05_cap03",
		"Tu peux aussi la lui apprendre, comme une CT.": "captain_07_cap03_fin",
	})
	await _frames(40)
	await _shot("captain_08_apres")
	_player.face(Vector2i.UP)
	await _interact()
	await _drive("captain_bis", {"Merci encore !": "captain_09_cap04"})


func _interact() -> void:
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


## Marche case par case sur [param cells] (cases voisines, dans l'ordre).
func _walk_path(cells: Array[Vector2i]) -> void:
	for cell: Vector2i in cells:
		var direction := cell - _player.get_cell()
		var action: StringName = ACTIONS[direction]
		Input.action_press(action)
		var guard := 0
		while guard < 300 and not (_player.get_cell() == cell and not _player.is_moving()):
			guard += 1
			if _player.is_moving() and _player.get_cell() + direction == cell:
				Input.action_release(action)
			await process_frame
		Input.action_release(action)


## Pilote tout ce qui se joue : pages (capture après PAGE_HOLD images, puis avance), combat
## (ATTAQUER, 1re capacité), bilan, toast ; s'arrête quand plus rien ne joue.
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
		var busy: bool = director.is_running() or runner.call(&"is_running") \
			or router.call(&"is_transitioning") or battle_director.is_running()
		if busy:
			idle = 0
		else:
			idle += 1
			if idle > 30:
				return
		if battle_director.is_running():
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
				await _shot("%s_05b_bilan" % prefix)
			summary.tap()
		var toast: Node = hud.call(&"get_toast")
		if toast.visible:
			await _frames(8)
			await _shot("%s_06_toast" % prefix)
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
