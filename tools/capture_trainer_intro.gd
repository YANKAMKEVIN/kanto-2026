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
## - `grand` : Arène d'Argenta, Pierre (séquence « VS », puis la même entrée) ;
## - `argenta`, `azuria`, `carmin`, `celadopole`, `parmanie`, `safrania`, `cramois`, `jadielle` :
##   chaque Champion dans son Arène (planches docs/design/fiches-assets/entree-champions/).
## - ou `--trainer=<id> --map=<carte> --spawn=<point>` : n'importe quel Dresseur (classes
##   ordinaires, tools/capture_ordinaires.sh).
## Le combat commence ≈ 0,7 s après l'arrivée sur la carte ; l'outil quitte ≈ 1,5 s après
## l'apparition de la grille d'actions. Imprime l'image du début du combat (« [intro] start »)
## pour rogner la vidéo. Aucune entrée n'est simulée pendant l'entrée (jamais sautée).
##
## `--shots=<dossier>` (avec `--fixed-fps 60`) : enregistre aussi les images des moments des
## maquettes (`entree.png` : message « … veut se battre ! » ; `lancer.png` : Ball au
## milieu de son vol ; `lancer_joueur.png` : Ball du joueur au milieu de son vol ; `vs.png` :
## emblème posé), pour le comparatif.
##
## `--surf` : le joueur surfe (`player_mount` = Surf) et la mise en scène « Surf » est activée
## pour cette capture seulement (réglage `surf.enabled` de data/battle/decors.json forcé à vrai) :
## planche comparative banc de sable / Surf (fiche entree-dresseurs §13). `--look=heroine` : la
## joueuse.

const START_PATH: String = "user://trainer_intro_capture_start.json"
const SETUPS := {
	"ordinary": {"map": "route_3", "spawn": "from_pewter_c", "cell": [20, 24], "facing": "up",
		"trainer": "route_3_hugo"},
	"grand": {"map": "pewter_gym", "spawn": "entrance", "cell": [7, 4], "facing": "up",
		"trainer": "pewter_gym_brock"},
	# Étape 2 (les 8 Champions dans leur Arène) : le joueur reste au point d'entrée de l'Arène.
	"argenta": {"map": "pewter_gym", "spawn": "entrance", "cell": [7, 4], "facing": "up",
		"trainer": "pewter_gym_brock"},
	"azuria": {"map": "cerulean_gym", "spawn": "entrance", "facing": "up",
		"trainer": "cerulean_gym_misty"},
	"carmin": {"map": "vermilion_gym", "spawn": "entrance", "facing": "up",
		"trainer": "vermilion_gym_surge"},
	"celadopole": {"map": "celadon_gym", "spawn": "entrance", "facing": "up",
		"trainer": "celadon_gym_erika"},
	"parmanie": {"map": "fuchsia_gym", "spawn": "entree", "facing": "up",
		"trainer": "fuchsia_gym_koga"},
	"safrania": {"map": "saffron_gym", "spawn": "entrance", "facing": "up",
		"trainer": "saffron_gym_sabrina"},
	"cramois": {"map": "cinnabar_gym", "spawn": "depuis_ile", "facing": "up",
		"trainer": "cinnabar_gym_blaine"},
	"jadielle": {"map": "viridian_gym", "spawn": "entrance", "facing": "up",
		"trainer": "viridian_gym_giovanni"},
	# Étape 3 (les autres grands combats, planches docs/design/fiches-assets/entree-grands-combats/).
	"rival_labo": {"map": "oak_lab", "spawn": "entrance", "facing": "up", "trainer": "rival_lab"},
	"rival_route22": {"map": "route_22", "spawn": "from_viridian", "facing": "left",
		"trainer": "rival_route22"},
	"rival_route24": {"map": "route_24", "spawn": "bridge_top", "facing": "up",
		"trainer": "rival_cerulean"},
	"rival_ss_anne": {"map": "ss_anne_captain_corridor", "spawn": "entrance", "facing": "up",
		"trainer": "rival_ss_anne"},
	"rival_tour": {"map": "pokemon_tower_2f", "spawn": "devant_rival", "facing": "up",
		"trainer": "rival_tower"},
	"rival_sylphe": {"map": "silph_co_7f", "spawn": "from_elevator", "facing": "up",
		"trainer": "rival_silph"},
	"rival_route22_final": {"map": "route_22_west", "spawn": "from_route_22", "facing": "left",
		"trainer": "rival_route22_final"},
	"giovanni_repaire": {"map": "rocket_hideout_b4f", "spawn": "from_elevator", "facing": "up",
		"trainer": "giovanni_hideout"},
	"giovanni_sylphe": {"map": "silph_co_11f", "spawn": "from_elevator", "facing": "up",
		"trainer": "silph_co_giovanni"},
	"olga": {"map": "league_lorelei", "spawn": "from_south", "facing": "up",
		"trainer": "league_lorelei"},
	"aldo": {"map": "league_bruno", "spawn": "from_south", "facing": "up", "trainer": "league_bruno"},
	"agatha": {"map": "league_agatha", "spawn": "from_south", "facing": "up",
		"trainer": "league_agatha"},
	"peter": {"map": "league_lance", "spawn": "from_south", "facing": "up", "trainer": "league_lance"},
	"maitre": {"map": "league_champion", "spawn": "from_south", "facing": "up",
		"trainer": "rival_champion"},
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
	var setup: Dictionary = {}
	if _args.has("trainer"):  # Dresseur quelconque : --trainer=<id> --map=<carte> --spawn=<point>
		setup = {"map": _args["map"], "spawn": _args["spawn"], "facing": "up",
			"trainer": _args["trainer"]}
	else:
		setup = SETUPS[String(_args.get("battle", "ordinary"))]
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
	if _args.has("rival_look"):  # --rival_look=rivale : la rivale (apparence choisie à l'ouverture)
		game_state.set(&"rival_look", StringName(_args["rival_look"]))
		game_state.set(&"rival_name", "Rose")
	if _args.has("look"):
		game_state.set(&"player_look", StringName(_args["look"]))
	if _args.has("surf"):
		game_state.set(&"player_mount", 2)  # Mount.Kind.SURF
		var decors: RefCounted = load("res://game/battle/battle_decor_catalog.gd").call(&"load_file")
		decors.set(&"surf_enabled", true)
		boot.call(&"get_battle_stage").call(&"set_decor_catalog", decors)
	var player: Node = boot.call(&"get_player")
	var map: Node = boot.call(&"get_map")
	if setup.has("cell"):
		var cell: Array = setup["cell"]
		player.call(&"enter_map", map.call(&"get_grid"), Vector2i(cell[0], cell[1]),
			Vector2i.UP, map.call(&"get_pixel_rect"))
	await _frames(LEAD_FRAMES)
	if _args.has("shots"):  # `monde.png` : la carte avant le combat (apparences du monde).
		DirAccess.make_dir_recursive_absolute(String(_args["shots"]))
		root.get_texture().get_image().save_png(String(_args["shots"]).path_join("monde.png"))
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
		4, 5:  # FOE_SEND, PLAYER_SEND : Ball au milieu du vol.
			# `--entree=dresseurs` : l'entrée est prise au début du lancer adverse, dresseurs en
			# place (le message d'ouverture peut précéder l'arrivée de la caméra dans le décor).
			if step == 4 and String(_args.get("entree", "")) == "dresseurs":
				_shots[now + 2] = "entree"
			var windup: float = catalog.call(&"duration", "send_windup")
			var throw: float = catalog.call(&"duration", "send_throw")
			_shots[now + int(round((windup + throw * 0.5) * fps))] = \
				"lancer" if step == 4 else "lancer_joueur"
		2:  # VS_OUT : Champions sans message d'ouverture, dresseurs revenus à l'entrée.
			if not _shots.values().has("entree"):
				var out: float = catalog.call(&"duration", "vs_out")
				_shots[now + int(round(out * fps)) + 1] = "entree"
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
