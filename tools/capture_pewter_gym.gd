extends SceneTree
## Captures de l'Arène d'Argenta en jeu (jalon 10 T17) dans la vraie scène `game/boot.tscn`
## (HUD, lumière `interior_warm`, PNJ peints, combat réel à vitesse normale) :
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_pewter_gym.gd -- \
##     --shot=liam --out=build/captures/j10_t17
##
## `--shot=` :
## - `entree` : le joueur à l'entrée, Pierre visible au fond ;
## - `liam` : le joueur monte par x = 7, Liam le repère (« ! ») → `liam.png`, puis son approche
##   → `liam_approche.png` ;
## - `carte` : Liam battu, on parle à Pierre ; l'introduction défile, puis la carte « PIERRE »
##   → `carte.png` ;
## - `onix` : même départ (Carapuce N12, Écume), le combat est piloté jusqu'à Onix → `onix.png` ;
## - `badge` : même départ, combat gagné → « BADGE ROCHE » → `badge.png` ;
## - `apres` : badge obtenu, on parle au guide → `apres.png` (réaction du guide).
## La partie est écrite dans `user://t17_capture_start.json` et forcée dans Boot.

const START_PATH: String = "user://t17_capture_start.json"
const FLAGS: Array = ["pokedex_activated", "poison_unlocked", "beaten_forest_scout_theo",
	"pewter_arrived", "taken_squirtle"]
## Départ « Carapuce » du T16 (brock_squirtle) : Écume = 3e capacité.
const PARTY: Array = [{"species": "squirtle", "level": 12}, {"species": "pidgey", "level": 10}]
const BUBBLE: int = 2
const TIMEOUT_MS: int = 120000

var _args: Dictionary = {}
var _boot: Node
var _player: Node
var _out: String = ""


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	var shot := String(_args.get("shot", "entree"))
	_out = String(_args.get("out", "build/captures/j10_t17"))
	DirAccess.make_dir_recursive_absolute(_out)
	var flags: Array = FLAGS.duplicate()
	if shot in ["carte", "onix", "badge", "apres"]:
		flags.append("beaten_pewter_gym_liam")
	if shot == "apres":
		flags.append_array(["brock_met", "badge_boulder"])
	# « badge » : la victoire doit être sûre (combat réel, aléatoire non fixé) → Carapuce N25.
	var party: Array = PARTY if shot != "badge" else [{"species": "squirtle", "level": 25,
		"moves": ["tackle", "tail_whip", "bubble"]}]
	var file := FileAccess.open(START_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"map": "pewter_gym", "spawn": "entrance", "facing": "up",
		"flags": flags, "party": party, "bag": {"potion": 3}, "money": 3000}))
	file.close()
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"debug_start_path", START_PATH)
	_boot.set(&"force_debug_start", true)
	root.add_child(_boot)
	await _frames(60)
	_player = _boot.call(&"get_player")
	print("capture_pewter_gym : %s, carte %s, joueur %s, vue %s" % [shot,
		_boot.call(&"get_map").get(&"map_id"), _player.call(&"get_cell"),
		root.get_visible_rect().size])
	match shot:
		"entree":
			await _frames(20)
			await _shot("entree")
		"liam":
			await _liam()
		"carte", "onix", "badge":
			await _brock(shot)
		"apres":
			await _guide_after()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(START_PATH))
	quit()


func _liam() -> void:
	var watcher: Node = _boot.call(&"get_trainer_watcher")
	var spotted := [false]
	watcher.connect(&"trainer_spotted", func(_n: StringName, _t: StringName) -> void:
		spotted[0] = true)
	Input.action_press(&"move_up")
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while not spotted[0] and Time.get_ticks_msec() < deadline:
		await process_frame
	Input.action_release(&"move_up")
	await _frames(12)
	await _shot("liam")
	await _frames(160)
	await _shot("liam_approche")


## Monte jusqu'à Pierre (Liam battu), lui parle et déroule jusqu'à l'image voulue.
func _brock(shot: String) -> void:
	await _walk_up_to(Vector2i(7, 3))
	Input.action_press(&"interact")
	await _frames(2)
	Input.action_release(&"interact")
	var box: Node = _boot.call(&"get_dialogue_box")
	var hud: Node = _boot.call(&"get_hud")
	var card: Node = hud.call(&"get_champion_card")
	var caption: Node = hud.call(&"get_caption")
	var battles: Node = _boot.call(&"get_battle_director")
	var battle_hud: Node = _boot.call(&"get_battle_hud")
	var director: Node = _boot.call(&"get_cutscene_director")
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	var page_frames := 0
	var onix_frames := -1
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if bool(card.call(&"is_showing")):
			if shot == "carte":
				await _frames(40)
				await _shot("carte")
				return
			card.call(&"skip_hold")
		if bool(caption.call(&"is_showing")) and shot == "badge":
			await _frames(45)
			await _shot("badge")
			return
		var summary: Variant = battles.call(&"get_summary_card")
		if summary != null and bool((summary as Object).call(&"is_waiting")):
			(summary as Object).call(&"tap")
		if bool(battles.call(&"is_running")):
			var battle: Variant = battles.call(&"get_battle")
			if battle != null:
				# Onix à l'écran (carte de l'adversaire), puis le premier message où il agit.
				var foe_card: Node = battle_hud.call(&"get_card", BattleHud.Side.FOE)
				var banner: Node = battle_hud.call(&"get_message_banner")
				if shot == "onix" and String(foe_card.call(&"get_name_text")) == "ONIX":
					onix_frames = 0 if onix_frames < 0 else onix_frames + 1
					if String(banner.call(&"get_text")).begins_with("Onix") \
							or onix_frames == 600:
						await _frames(25)
						await _shot("onix")
						return
				if int((battle as Object).call(&"get_state")) == Battle.State.CHOOSING:
					match int(battle_hud.call(&"get_zone")):
						BattleHud.Zone.ACTIONS:
							battle_hud.emit_signal(&"action_selected", ActionGrid.ATTACK)
						BattleHud.Zone.MOVES:
							battle_hud.emit_signal(&"move_selected", BUBBLE)
		if bool(box.call(&"is_open")):
			page_frames += 1
			if page_frames >= 45:
				page_frames = 0
				box.emit_signal(&"advance_requested")
		else:
			page_frames = 0
		if not bool(director.call(&"is_running")) and not bool(battles.call(&"is_running")) \
				and not bool(box.call(&"is_open")):
			break
	var state: Node = root.get_node(^"GameState")
	push_error("capture_pewter_gym : image « %s » jamais atteinte (carte %s, badge %s)" % [shot,
		_boot.call(&"get_map").get(&"map_id"),
		state.get(&"flags").call(&"has_flag", &"badge_boulder")])


func _guide_after() -> void:
	# Guide en (5, 8) : le joueur posé à sa droite, tourné vers lui.
	_boot.call(&"get_map").call(&"spawn_player_at", _player, Vector2i(6, 8), Vector2i.LEFT)
	await _frames(20)
	Input.action_press(&"interact")
	await _frames(2)
	Input.action_release(&"interact")
	await _frames(180)
	await _shot("apres")


## Monte jusqu'à [param cell] (s'arrête devant Pierre, qui bloque la case suivante).
func _walk_up_to(cell: Vector2i) -> void:
	Input.action_press(&"move_up")
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while _player.call(&"get_cell") != cell and Time.get_ticks_msec() < deadline:
		await process_frame
	Input.action_release(&"move_up")
	await _frames(20)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [_out, name]
	root.get_texture().get_image().save_png(path)
	print("image : ", path)
