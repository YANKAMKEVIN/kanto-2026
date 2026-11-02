extends SceneTree
## Vidéo de validation de l'entrée des combats de Dresseur (dossier 05 §3, décision de Kevin du
## 2026-11-02) dans la vraie scène `game/boot.tscn`, à vitesse réelle :
##
##   godot --path . --resolution 1170x540 --fixed-fps 30 --write-movie build/intro/ordinary.avi \
##     -s res://tools/capture_trainer_intro.gd -- --battle=ordinary
##
## `--battle=` :
## - `ordinary` : Route 3, Gamin Hugo (Dresseur ordinaire : les deux dresseurs, la rangée de
##   Poké Balls, l'adversaire lance, puis le joueur) ;
## - `grand` : Arène d'Argenta, Pierre (séquence « VS », puis la même entrée).
## Le combat commence ≈ 0,7 s après l'arrivée sur la carte ; l'outil quitte ≈ 1,5 s après
## l'apparition de la grille d'actions. Imprime l'image du début du combat (« [intro] start »)
## pour rogner la vidéo. Aucune entrée n'est simulée pendant l'entrée (jamais sautée).
##
## `--shots=<dossier>` (avec `--fixed-fps 60`) : enregistre aussi les images des moments des
## maquettes (`entree.png` : message « … veut se battre ! » ; `lancer.png` : Ball au
## milieu de son vol ; `vs.png` : emblème posé), pour le comparatif.

const START_PATH: String = "user://trainer_intro_capture_start.json"
const SETUPS := {
	"ordinary": {"map": "route_3", "spawn": "from_pewter_c", "cell": [20, 24], "facing": "up",
		"trainer": "route_3_hugo"},
	"grand": {"map": "pewter_gym", "spawn": "entrance", "cell": [7, 4], "facing": "up",
		"trainer": "pewter_gym_brock"},
}
const PARTY: Array = [{"species": "squirtle", "level": 14}]
const LEAD_FRAMES: int = 20
const TAIL_FRAMES: int = 45
const TIMEOUT_FRAMES: int = 1800

var _args: Dictionary = {}
## Image (Engine.get_process_frames) → nom du cliché à enregistrer.
var _shots: Dictionary = {}


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var setup: Dictionary = SETUPS[String(_args.get("battle", "ordinary"))]
	var file := FileAccess.open(START_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"map": setup["map"], "spawn": setup["spawn"],
		"facing": setup["facing"], "party": PARTY, "seed": 7,
		"flags": ["pokedex_activated", "starter_chosen"]}))
	file.close()
	var boot: Node = (load("res://game/boot.tscn") as PackedScene).instantiate()
	boot.set(&"debug_start_path", START_PATH)
	boot.set(&"force_debug_start", true)
	root.add_child(boot)
	await _frames(40)
	var game_state: Node = root.get_node(^"GameState")
	game_state.set(&"player_name", "Kevin")
	game_state.set(&"rival_name", "Régis")
	var player: Node = boot.call(&"get_player")
	var map: Node = boot.call(&"get_map")
	var cell: Array = setup["cell"]
	player.call(&"enter_map", map.call(&"get_grid"), Vector2i(cell[0], cell[1]), Vector2i.UP,
		map.call(&"get_pixel_rect"))
	await _frames(LEAD_FRAMES)
	var battles: Node = boot.call(&"get_battle_director")
	var hud: Node = boot.call(&"get_battle_hud")
	print("[intro] start frame %d (%s)" % [Engine.get_frames_drawn(), setup["trainer"]])
	if _args.has("shots"):
		battles.connect(&"trainer_intro_step", _plan_shot)
		var banner: Object = hud.call(&"get_message_banner")
		banner.connect(&"message_shown", func(text: String, _wait: bool) -> void:
			if text.contains("veut se battre") or text.contains("défi"):
				_shots[Engine.get_process_frames() + 20] = "entree")
	var done := [false]
	var runner := func() -> void:
		await battles.call(&"run", StringName(setup["trainer"]), map,
			{} as Dictionary[StringName, StringName])
		done[0] = true
	runner.call()
	var guard := 0
	while guard < TIMEOUT_FRAMES:
		guard += 1
		await process_frame
		_take_shot()
		var battle: Object = battles.call(&"get_battle")
		if battle != null and int(battle.call(&"get_state")) == 1 \
				and int(hud.call(&"get_zone")) == 1:
			break
	print("[intro] actions frame %d" % Engine.get_frames_drawn())
	await _frames(TAIL_FRAMES)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(START_PATH))
	quit()


## Cliché aux moments des maquettes, en images après le début de l'étape [param step].
func _plan_shot(step: int) -> void:
	var catalog: RefCounted = load("res://game/battle/trainer_intro_catalog.gd").call(&"shared")
	var fps := float(Engine.physics_ticks_per_second)
	var now := Engine.get_process_frames()
	match step:
		4:  # FOE_SEND : Ball au milieu du vol.
			var windup: float = catalog.call(&"duration", "send_windup")
			var throw: float = catalog.call(&"duration", "send_throw")
			_shots[now + int(round((windup + throw * 0.5) * fps))] = "lancer"
		1:  # VS_HOLD : emblème posé.
			var hold: float = catalog.call(&"duration", "vs_hold")
			_shots[now + int(round(hold * 0.5 * fps))] = "vs"


func _take_shot() -> void:
	var frame := Engine.get_process_frames()
	if not _shots.has(frame):
		return
	var dir := String(_args["shots"])
	DirAccess.make_dir_recursive_absolute(dir)
	var image := root.get_texture().get_image()
	image.save_png(dir.path_join("%s.png" % _shots[frame]))
	print("[intro] shot %s frame %d" % [_shots[frame], frame])


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
