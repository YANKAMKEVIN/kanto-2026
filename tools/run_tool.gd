extends SceneTree
## Lanceur des scripts d'outil qui nomment les classes du jeu (reliquats du Menu peint,
## 2026-11-02). Un script passé directement à `-s` est compilé **avant** l'enregistrement des
## autoloads : toute classe qui, de proche en proche, nomme `GameState` (npc.gd…) échoue
## (« Identifier not found: GameState »). Ce lanceur ne nomme rien du jeu ; à la première image,
## les autoloads sont là : il charge alors l'outil demandé et en prend le script (set_script
## exécute le `_init()` de l'outil ; les arguments après `--` restent lisibles par l'outil).
##
##   godot --path . --resolution 2340x1080 -s res://tools/run_tool.gd \
##     -- --tool=res://tools/capture_menu.gd --out=build/captures/menu
## `--check` : charge l'outil (compilation) puis quitte sans le lancer.


func _init() -> void:
	process_frame.connect(_launch, CONNECT_ONE_SHOT)


func _launch() -> void:
	var path := ""
	var check := false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--tool="):
			path = arg.trim_prefix("--tool=")
		elif arg == "--check":
			check = true
	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("run_tool : --tool=res://tools/<outil>.gd manquant ou introuvable (%s)" % path)
		quit(1)
		return
	var script := load(path) as GDScript
	if script == null or not script.can_instantiate():
		push_error("run_tool : %s ne compile pas" % path)
		quit(1)
		return
	if check:
		print("run_tool : %s compile" % path)
		quit()
		return
	set_script(script)
