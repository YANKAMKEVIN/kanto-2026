extends SceneTree
## Captures de la scène du rival n° 2 sur la Route 22 (jalon 7 T25) avec la vraie scène Boot et
## un départ de débogage appliqué au démarrage (`route_22` pour gagner, avec un starter renforcé ;
## `rival_2_weak` pour perdre), puis arrivée au pied de l'escalier :
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_rival_route22.gd -- --outcome=win --out=build/captures/jalon07_t25
##
## Déroulé : rival22_<issue>_00_approach (en haut de l'escalier, la scène vue de loin) ; un pas
## vers l'ouest ; 01_sigh (« Sérieusement… ? ») ; 02_hesitates (Pokémon rappelés, « Tu hésites
## trop. ») ; 03_greet (le rival devant le joueur) ; 04_battle (grille d'actions, SAC) ;
## 05_after_battle (première réplique de l'issue) ; 06_end (victoire : le rival et le jeune
## Dresseur partis ; défaite : réveil au point de repos, mot du lieu).

const STARTS := {
	"win": "res://tools/debug_start/route_22.json",
	"lose": "res://tools/debug_start/rival_2_weak.json",
}
const SHOTS := {
	"Sérieusement… ?": "01_sigh",
	"Tu hésites trop.": "02_hesitates",
	"Voyons ce que tu as appris depuis notre premier combat.": "03_greet",
	"…D'accord.": "05_after_battle",
	"Tu t'es amélioré.": "05_after_battle",
	"On verra lequel de nous deux arrive le plus loin.": "05b_last_line",
	"La prochaine fois, ne me laisse pas autant d'avance.": "05b_last_line",
}
const STAIR_TOP := Vector2i(16, 13)
const TRIGGER_CELL := Vector2i(14, 13)
## Images d'attente avant une capture de réplique (texte écrit en entier).
const PAGE_HOLD := 60

var _out_dir: String = "build/captures/jalon07_t25"
var _outcome: String = "win"
var _boot: Node
var _player: Node2D
var _box: Node
var _runner: Node
var _director: Node
var _battle: Node
var _battle_hud: Node
var _router: Node
var _step: int = 0
var _wait: int = 0
var _page: String = ""
var _page_wait: int = 0
var _battle_shot: bool = false
var _ended: int = 0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--outcome="):
			_outcome = arg.trim_prefix("--outcome=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"viridian_city")
	_boot.set(&"start_spawn", &"from_route_22")
	root.add_child(_boot)
	var data: Object = _boot.call(&"get_pokemon_data")
	var start: Object = load("res://game/systems/debug/debug_start.gd").new()
	if not start.call(&"load_file", STARTS[_outcome], data, _boot.call(&"get_item_library")):
		push_error("capture_rival_route22 : départ illisible")
	var state := root.get_node(^"/root/GameState")
	start.call(&"apply", state, data)
	state.set(&"rng", load("res://game/systems/random/game_rng.gd").new(7))
	if _outcome == "win":
		# Starter renforcé (Salamèche Nv. 40, Flammèche) : victoire assurée pour la capture.
		var factory: Script = load("res://game/pokemon/pokemon_factory.gd")
		var champion: Object = factory.call(&"create", data, &"charmander", 40, state.get(&"rng"))
		champion.get(&"moves").clear()
		champion.get(&"moves").append(load("res://game/pokemon/move_slot.gd").new(&"ember", 25))
		var party: Object = state.get(&"party")
		party.call(&"remove_at", 0)
		party.call(&"add", champion)
		party.call(&"move", party.call(&"size") - 1, 0)
	_player = _boot.call(&"get_player")
	_box = _boot.call(&"get_dialogue_box")
	_runner = _boot.call(&"get_dialogue_runner")
	_director = _boot.call(&"get_cutscene_director")
	_battle = _boot.call(&"get_battle_director")
	_battle_hud = _boot.call(&"get_battle_hud")
	_router = root.get_node(^"/root/SceneRouter")
	_router.call(&"change_map", &"route_22", &"stair_foot", Vector2i.UP)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_wait += 1
	match _step:
		0:
			if _wait > 40 and not _router.call(&"is_transitioning"):
				Input.action_press(&"move_up")
				_next()
		1:
			if _player.call(&"get_cell") == STAIR_TOP:
				Input.action_release(&"move_up")
				_next()
		2:
			if _wait == 30:
				_shot("00_approach")
				Input.action_press(&"move_left")
				_next()
		3:
			if _director.call(&"is_running"):
				Input.action_release(&"move_left")
				_next()
			elif _wait > 200:
				Input.action_release(&"move_left")
				push_error("capture_rival_route22 : la scène n'a pas démarré")
				quit(1)
		4:
			_drive_scene()


## Pendant la scène : répliques capturées puis avancées, combat piloté (ATTAQUER, 1re capacité).
func _drive_scene() -> void:
	if _battle.call(&"is_running"):
		var battle: Object = _battle.call(&"get_battle")
		if battle != null and battle.call(&"get_state") == 1:  # Battle.State.CHOOSING
			match int(_battle_hud.call(&"get_zone")):
				1:  # BattleHud.Zone.ACTIONS
					if not _battle_shot:
						_battle_shot = true
						_wait = 0
					if _wait == 20:
						_shot("04_battle")
					if _wait >= 20:
						_battle_hud.emit_signal(&"action_selected", &"attack")
				2:  # BattleHud.Zone.MOVES
					_battle_hud.emit_signal(&"move_selected", 0)
	if _box.call(&"is_open"):
		var text: String = _box.call(&"get_text")
		if text != _page:
			_page = text
			_page_wait = 0
		_page_wait += 1
		# Une page qui commence par un silence (« pause ») s'écrit plus tard : capture à
		# PAGE_HOLD, puis une avance toutes les PAGE_HOLD images jusqu'à la page suivante.
		if _page_wait == PAGE_HOLD:
			if SHOTS.has(text):
				_shot(SHOTS[text])
			elif (_boot.call(&"get_map") as Node).get(&"map_id") != &"route_22":
				_shot("06_wakeup")
		if _page_wait % PAGE_HOLD == 0:
			_box.emit_signal(&"advance_requested")
		return
	var busy: bool = _director.call(&"is_running") or _runner.call(&"is_running") \
		or _router.call(&"is_transitioning")
	if busy:
		_ended = 0
		return
	_ended += 1
	if _ended == 45:
		_shot("06_end")
		quit()


func _next() -> void:
	_step += 1
	_wait = 0


func _shot(capture_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var path := _out_dir.path_join("rival22_%s_%s.png" % [_outcome, capture_name])
	root.get_texture().get_image().save_png(path)
	print("  -> %s" % path)
