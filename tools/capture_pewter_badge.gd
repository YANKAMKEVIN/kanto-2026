extends SceneTree
## Captures du badge en jeu (jalon 10 T19) dans la vraie scène `game/boot.tscn` (HUD, lumière,
## PNJ peints) sur une partie de test « Badge Roche obtenu » (Carapuce N13, Grand moment du badge
## enregistré comme par la vraie scène) :
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_pewter_badge.gd -- \
##     --shot=garde --out=build/captures/j10_t19
##
## `--shot=` :
## - `garde` : le joueur franchit le verrou (48, 26) → `garde_replique.png` (« Badge Roche
##   confirmé. »), `garde_apres.png` (le garde décalé en (48, 23), le joueur libre) ;
## - `est` : garde déjà décalé, le joueur marche vers l'est → `est.png` (« ROUTE 3 — À venir ») ;
## - `dresseur` : menu Dresseur ouvert → `dresseur.png` (Badge Roche), `dresseur_bas.png` (frise).
## La partie est écrite dans `user://t19_capture_start.json` et forcée dans Boot.

const START_PATH: String = "user://t19_capture_start.json"
const FLAGS: Array = ["mom_greeted", "rival_met", "oak_met", "oak_lab_reunion", "starter_offered",
	"starter_chosen", "taken_squirtle", "rival_lab_won", "rival_challenged", "rival_battle_done",
	"rival_left_lab", "viridian_arrived", "got_oak_parcel", "pokedex_activated",
	"poison_unlocked", "beaten_forest_scout_theo", "pewter_arrived", "beaten_pewter_gym_liam",
	"brock_met", "badge_boulder"]
const PARTY: Array = [{"species": "squirtle", "level": 13}, {"species": "pidgey", "level": 11}]
const TIMEOUT_MS: int = 60000

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
	var shot := String(_args.get("shot", "garde"))
	_out = String(_args.get("out", "build/captures/j10_t19"))
	DirAccess.make_dir_recursive_absolute(_out)
	var flags: Array = FLAGS.duplicate()
	if shot == "est":
		flags.append("route_3_guard_cleared")
	var file := FileAccess.open(START_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"map": "pewter_city", "spawn": "from_gym", "facing": "down",
		"flags": flags, "party": PARTY, "bag": {"potion": 3}, "money": 4300}))
	file.close()
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"debug_start_path", START_PATH)
	_boot.set(&"force_debug_start", true)
	root.add_child(_boot)
	await _frames(60)
	_player = _boot.call(&"get_player")
	var state: Node = root.get_node(^"GameState")
	state.call(&"record_moment", BadgeMoment.TYPE, &"pewter_gym",
		BadgeMoment.details(&"boulder", state.get(&"party")))
	var map: Node = _boot.call(&"get_map")
	var cell := Vector2i(47, 26) if shot != "est" else Vector2i(48, 26)
	map.call(&"spawn_player_at", _player, cell, Vector2i.RIGHT)
	await _frames(30)
	print("capture_pewter_badge : %s, carte %s, joueur %s, vue %s" % [shot,
		map.get(&"map_id"), _player.call(&"get_cell"), root.get_visible_rect().size])
	match shot:
		"garde":
			await _garde()
		"est":
			await _est()
		"dresseur":
			await _dresseur()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(START_PATH))
	quit()


func _garde() -> void:
	var box: Node = _boot.call(&"get_dialogue_box")
	Input.action_press(&"move_right")
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while not bool(box.call(&"is_open")) and Time.get_ticks_msec() < deadline:
		await process_frame
	Input.action_release(&"move_right")
	await _frames(150)
	await _shot("garde_replique")
	var director: Node = _boot.call(&"get_cutscene_director")
	deadline = Time.get_ticks_msec() + TIMEOUT_MS
	while bool(director.call(&"is_running")) and Time.get_ticks_msec() < deadline:
		if bool(box.call(&"is_open")):
			await _frames(20)
			box.emit_signal(&"advance_requested")
		await process_frame
	await _frames(40)
	await _shot("garde_apres")


func _est() -> void:
	var soon: Node = _boot.call(&"get_coming_soon_screen")
	Input.action_press(&"move_right")
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while not bool(soon.call(&"is_showing")) and Time.get_ticks_msec() < deadline:
		await process_frame
	Input.action_release(&"move_right")
	await _frames(60)
	await _shot("est")


func _dresseur() -> void:
	var menu: Node = _boot.call(&"get_menu_director")
	menu.call(&"open", MenuRoute.trainer())
	await _frames(90)
	await _shot("dresseur")
	var scroll: ScrollContainer = (_boot.call(&"get_trainer_menu") as TrainerMenu) \
		.get_trainer().get_scroll()
	scroll.scroll_vertical = 100000
	await _frames(30)
	await _shot("dresseur_bas")


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [_out, name]
	root.get_texture().get_image().save_png(path)
	print("image : ", path)
