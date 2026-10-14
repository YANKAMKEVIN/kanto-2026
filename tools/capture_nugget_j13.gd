extends SceneTree
## Captures du Pont Pépite et du recruteur Rocket (jalon 13 T22) dans la vraie scène
## `game/boot.tscn` (HUD, lumière, PNJ peints), avec les vrais départs de débogage :
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_nugget_j13.gd -- \
##     --mode=rocket --out=build/captures/j13_t22
##
## `--mode=` :
## - `rocket` : départ `nugget_rocket` (P1 à P5 battus), Salamèche Nv. 60 : le recruteur voit le
##   joueur, félicitations (n° 48), Pépite remise (n° 49, toast), proposition et **choix OUI / NON**
##   (n° 50), OUI (n° 51), combat, n° 53, départ → `rocket_*.png` ;
## - `bridge` : départ `nugget_bridge` : le pied du pont, Timéo (P1) qui voit le joueur (n° 43) →
##   `bridge_*.png`.

const MODES := {
	"rocket": "res://tools/debug_start/nugget_rocket.json",
	"bridge": "res://tools/debug_start/nugget_bridge.json",
}
const PAGE_HOLD := 20
const TIMEOUT_FRAMES := 9000

var _out: String = "build/captures/j13_t22"
var _mode: String = "rocket"
var _boot: Node
var _player: Node
var _done: Dictionary = {}
var _page: String = ""
var _page_frames: int = 0
## Images traitées depuis le début (= numéro de l'image du film en mode Movie Maker).
var _ticks: int = 0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)
	process_frame.connect(func() -> void: _ticks += 1)


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _shot(name: String) -> void:
	if _done.has(name):
		return
	_done[name] = true
	DirAccess.make_dir_recursive_absolute(_out)
	await _frames(2)
	# Mode Movie Maker : l'image de la vue n'est pas relue ; le numéro d'image du film
	# (`f%08d.png`) est imprimé, `tools/capture_nugget_j13.sh` copie ce fichier.
	print("image : %s %d" % [name, _ticks])


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"cerulean_city")
	_boot.set(&"start_spawn", &"from_route_24_c")
	root.add_child(_boot)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var start := DebugStart.new()
	if not start.load_file(MODES[_mode], data, _boot.call(&"get_item_library")):
		push_error("capture_nugget_j13 : départ illisible")
	var state: Node = root.get_node(^"/root/GameState")
	start.apply(state, data)
	state.set(&"rng", GameRng.new(7))
	var champion := PokemonFactory.create(data, &"charmander", 60, state.get(&"rng"))
	champion.moves.clear()
	champion.moves.append(MoveSlot.new(&"ember", 30))
	var party: Party = state.get(&"party")
	while party.size() > 0:
		party.remove_at(0)
	party.add(champion)
	_player = _boot.call(&"get_player")
	(_boot.call(&"get_dialogue_runner") as DialogueRunner).chars_per_second = 0.0
	await _frames(20)
	var router: Node = root.get_node(^"/root/SceneRouter")
	var spawn := &"bridge_top" if _mode == "rocket" else &"bridge_foot"
	await router.call(&"change_map", &"route_24", spawn, Vector2i.UP)
	await _frames(30)
	(_boot.call(&"get_battle_director") as BattleDirector).speed_scale = 1.0
	if _mode == "rocket":
		await _run_rocket()
	else:
		await _run_bridge()
	print("CAPTURE_NUGGET_J13 terminé : ", _mode)
	quit()


func _walk_until_scene(action: StringName) -> void:
	var director: CutsceneDirector = _boot.call(&"get_cutscene_director")
	Input.action_press(action)
	var guard := 0
	while not director.is_running() and guard < 900:
		guard += 1
		await process_frame
	Input.action_release(action)


func _run_bridge() -> void:
	await _shot("bridge_00_pied")
	await _walk_until_scene(&"move_up")
	await _frames(20)
	await _shot("bridge_01_timeo_voit")
	await _drive("bridge", {
		"Bienvenue au Pont Pépite ! Je suis le premier des cinq !": "bridge_02_timeo_avant",
	}, true)
	await _frames(30)
	await _shot("bridge_03_apres_p1")


func _run_rocket() -> void:
	await _shot("rocket_00_pont_haut")
	await _walk_until_scene(&"move_up")
	await _frames(30)
	await _drive("rocket", {
		"Bravo ! Cinq victoires d'affilée.": "rocket_01_felicitations",
		"Voici ta récompense.": "rocket_02_recompense",
		"Nous recrutons. Ça t'intéresse ?": "rocket_04_proposition",
		"Tu crois que c'est si simple ?": "rocket_05_oui",
		"Hm. Tu ferais un excellent…": "rocket_07_battu",
		"Non. Un ennemi. Tu ferais un excellent ennemi.": "rocket_08_battu_suite",
	}, false)
	await _frames(40)
	await _shot("rocket_09_apres")


## Pilote tout ce qui se joue : pages (capture après PAGE_HOLD images, puis avance), choix (capture
## puis OUI), combat (ATTAQUER, 1re capacité), toast ; s'arrête quand plus rien ne joue.
## [param stop_after_battle] : rend la main dès la fin du premier combat.
func _drive(prefix: String, page_shots: Dictionary, stop_after_battle: bool) -> void:
	var director: CutsceneDirector = _boot.call(&"get_cutscene_director")
	var runner: DialogueRunner = _boot.call(&"get_dialogue_runner")
	var box: Node = _boot.call(&"get_dialogue_box")
	var battle_director: BattleDirector = _boot.call(&"get_battle_director")
	var battle_hud: BattleHud = _boot.call(&"get_battle_hud")
	var hud: Node = _boot.call(&"get_hud")
	var router: Node = root.get_node(^"/root/SceneRouter")
	var idle := 0
	var frames := 0
	var fought := false
	while frames < TIMEOUT_FRAMES:
		frames += 1
		if frames % 120 == 0:
			print("frames=%d box=%s dir=%s run=%s battle=%s" % [frames, box.call(&"is_open"),
				director.is_running(), runner.is_running(), battle_director.is_running()])
		var busy: bool = director.is_running() or runner.is_running() \
			or router.call(&"is_transitioning") or battle_director.is_running()
		if busy:
			idle = 0
		else:
			idle += 1
			if idle > 30:
				return
		if battle_director.is_running():
			fought = true
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						if not _done.has("%s_06_combat" % prefix):
							await _frames(30)
							await _shot("%s_06_combat" % prefix)
						battle_hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		elif fought and stop_after_battle:
			return
		var summary := battle_director.get_summary_card()
		if summary != null:
			if summary.is_waiting():
				await _frames(20)
			summary.tap()
		var toast: Node = hud.call(&"get_toast")
		if toast.visible:
			await _frames(8)
			await _shot("%s_03_toast_pepite" % prefix)
		if runner.is_awaiting_choice():
			await _frames(30)
			await _shot("%s_04b_choix" % prefix)
			runner.choose(true)
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
