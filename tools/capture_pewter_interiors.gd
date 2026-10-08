extends SceneTree
## Captures des intérieurs d'Argenta (jalon 10 T13) dans la vraie scène `game/boot.tscn` (HUD,
## lumière `interior_warm`, PNJ peints) :
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_pewter_interiors.gd -- \
##     --room=arene --out=build/captures/j10_t13 [--cell=7,6] [--facing=up] [--walk=up:3]
##
## `--room=` : centre, boutique, musee, science, tailleur, chercheuse, arene (départ de la
## pièce, joueur sur son point d'entrée, construit ici dans `user://t13_capture_start.json`,
## forcé dans Boot comme `capture_bourg_interiors.gd`). `--cell` / `--facing` replacent le
## joueur ; `--walk=<direction>:<cases>` maintient l'action `move_<direction>` jusqu'à ce que le
## joueur ait avancé de ce nombre de cases (garde de 10 s) puis écrit aussi
## `<out>/<room>_apres.png` (capture avant / après d'un déplacement). Écrit `<out>/<room>.png`.

const START_PATH: String = "user://t13_capture_start.json"
## Drapeaux de la fin du J9 (départ `pewter` du T8) + arrivée à Argenta.
const FLAGS: Array = ["pokedex_activated", "poison_unlocked", "beaten_forest_scout_theo",
	"pewter_arrived"]
const ROOMS: Dictionary = {
	"centre": ["pewter_center", "entrance"],
	"boutique": ["pewter_mart", "entrance"],
	"musee": ["pewter_museum", "entrance"],
	"science": ["pewter_museum_science", "from_hall"],
	"tailleur": ["pewter_house_mason", "entrance"],
	"chercheuse": ["pewter_house_researcher", "entrance"],
	"arene": ["pewter_gym", "entrance"],
}

var _args: Dictionary = {}


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	var room := String(_args.get("room", "arene"))
	var out := String(_args.get("out", "build/captures/j10_t13"))
	DirAccess.make_dir_recursive_absolute(out)
	var start: Array = ROOMS[room]
	var file := FileAccess.open(START_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"map": start[0], "spawn": start[1], "facing": "up",
		"flags": FLAGS, "party": [{"species": "charmander", "level": 11}]}))
	file.close()
	var boot: Node = (load("res://game/boot.tscn") as PackedScene).instantiate()
	boot.set(&"debug_start_path", START_PATH)
	boot.set(&"force_debug_start", true)
	root.add_child(boot)
	for i in 60:
		await process_frame
	var map: Node = boot.call(&"get_map")
	var player: Node = boot.call(&"get_player")
	if _args.has("cell"):
		var parts: PackedStringArray = String(_args["cell"]).split(",")
		map.call(&"spawn_player_at", player, Vector2i(int(parts[0]), int(parts[1])),
			_direction(String(_args.get("facing", "up"))))
	print("capture_pewter_interiors : %s, carte %s, joueur %s, vue %s" % [room,
		map.get(&"map_id"), player.call(&"get_cell"), root.get_visible_rect().size])
	for i in 30:
		await process_frame
	await _shot("%s/%s.png" % [out, room])
	if _args.has("walk"):
		var walk: PackedStringArray = String(_args["walk"]).split(":")
		var from: Vector2i = player.call(&"get_cell")
		var action := StringName("move_" + walk[0])
		var steps := int(walk[1])
		var deadline := Time.get_ticks_msec() + 10000
		Input.action_press(action)
		while (player.call(&"get_cell") - from).length() < steps \
				and Time.get_ticks_msec() < deadline:
			await process_frame
		Input.action_release(action)
		for i in 30:
			await process_frame
		print("déplacement %s : %s → %s" % [action, from, player.call(&"get_cell")])
		await _shot("%s/%s_apres.png" % [out, room])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(START_PATH))
	quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("image : ", path)


func _direction(name: String) -> Vector2i:
	match name:
		"down":
			return Vector2i.DOWN
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
	return Vector2i.UP
