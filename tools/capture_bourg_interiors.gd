extends SceneTree
## Captures des intérieurs peints de Bourg Palette (DA.3) dans la vraie scène `game/boot.tscn`
## (HUD, lumière `interior_warm`, PNJ et starters peints), pour Movie Maker ou une image seule :
##
##   godot --path . -s res://tools/capture_bourg_interiors.gd -- --room=labo --out=build/da3 \
##     [--perf] [--cell=7,6] [--facing=up]
##
## `--room=` :
##   chambre — nouvelle partie (réveil dans la chambre) ;
##   rdc     — rez-de-chaussée, joueur au pied de l'escalier, Maman à table ;
##   rival   — maison du rival, joueur à l'entrée, le rival dans sa chambre ;
##   labo    — labo avant le choix du starter : Chen, le rival, les trois starters sur la table.
## Départs construits ici (fichier `user://da3_capture_start.json`, forcé dans Boot comme
## `capture_pallet_town.gd --boot`). `--cell` / `--facing` replacent le joueur ; `--perf`
## écrit les fps, appels de dessin et la mémoire des textures toutes les 30 images pendant
## 6 s. Écrit `<out>/<room>.png` puis quitte.
## 2340 × 1080 : `override.cfg` temporaire à la racine ([display] window/size/
## window_width_override=2340, window_height_override=1080), à retirer après.

const START_PATH: String = "user://da3_capture_start.json"
const STARTS: Dictionary = {
	"rdc": {"map": "player_house_1f", "spawn": "stairs", "facing": "down",
		"flags": ["mom_greeted"], "party": [{"species": "charmander", "level": 5}]},
	"rival": {"map": "rival_house", "spawn": "entrance", "facing": "up",
		"flags": ["mom_greeted", "rival_met"],
		"party": [{"species": "charmander", "level": 5}]},
	"labo": {"map": "oak_lab", "spawn": "entrance", "facing": "up",
		"flags": ["mom_greeted", "rival_met", "oak_met", "oak_lab_reunion", "starter_offered"],
		"party": [{"species": "rattata", "level": 3}]},
}

var _args: Dictionary = {}
var _frame: int = 0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	var room := String(_args.get("room", "chambre"))
	var out := String(_args.get("out", "build/da3"))
	DirAccess.make_dir_recursive_absolute(out)
	var boot: Node = (load("res://game/boot.tscn") as PackedScene).instantiate()
	if STARTS.has(room):
		var file := FileAccess.open(START_PATH, FileAccess.WRITE)
		file.store_string(JSON.stringify(STARTS[room]))
		file.close()
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
	print("capture_bourg_interiors : %s, carte %s, joueur %s, vue %s" % [room,
		map.get(&"map_id"), player.call(&"get_cell"), root.get_visible_rect().size])
	for i in 30:
		await process_frame
	await _shot("%s/%s.png" % [out, room])
	if _args.has("perf"):
		process_frame.connect(_report)
		for i in 360:
			await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(START_PATH))
	quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("image : ", path)


func _report() -> void:
	_frame += 1
	if _frame % 30 != 0:
		return
	print("[perf] image %d : fps=%d draw=%d objets=%d tex=%.1f Mo" % [_frame,
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0])


func _direction(name: String) -> Vector2i:
	match name:
		"down":
			return Vector2i.DOWN
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
	return Vector2i.UP
