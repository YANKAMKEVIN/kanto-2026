extends SceneTree
## Plans de la bande-annonce de l'ident (J34) : la vraie scène Boot lancée sur un départ de
## débogage nommé (`tools/debug_start/<nom>.json`), HUD d'exploration caché, puis une capture du
## viewport une fois le décor posé. À lancer sur le Mac (pas en headless), en 2340 × 1080 :
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_trailer.gd \
##     -- --start=pallet_town --out=build/captures/trailer/pallet_town.png [--frames=90]
##     [--walk=down:3,left:2] [--hud]
##
## `--walk` : pas du joueur avant la capture (actions `move_*` tenues), pour s'éloigner du point
## d'apparition ; `--hud` garde le HUD (défaut : caché, la bande-annonce montre le monde).
## Moments (demande de Kevin : course, vélo, eau, Vol, évolution, Menu, Pokédex) :
##   --run            les pas de `--walk` se font en courant (action `run` tenue) ;
##   --mid            la capture se prend au milieu du dernier pas (pose de course ou de vélo) ;
##   --bike           le joueur monte sur la Bicyclette avant `--walk` ;
##   --surf           face à l'eau après `--walk`, saute en Surf, puis `--walk2=dir:n` sur l'eau ;
##   --fly=<zone>     s'envole vers la zone (après `--walk`), capture `--frames` images plus tard ;
##   --evolve=<espèce> fait évoluer le premier de l'équipe vers l'espèce, capture pendant la
##                    transformation (`--frames` images après son début) ;
##   --menu[=écran]   ouvre le Menu Dresseur (tableau de bord, ou `pokedex`, `team`, `map`…).
## Série : `tools/capture_trailer.sh`.

const ABSENT: String = "user://cap_trailer_absent.json"

var _start: String = "pallet_town"
var _out: String = "build/captures/trailer/shot.png"
var _frames: int = 90
var _walk: Array[Array] = []
var _walk2: Array[Array] = []
var _hud: bool = false
var _running: bool = false
var _mid: bool = false
var _bike: bool = false
var _surf: bool = false
var _fly: String = ""
var _evolve: String = ""
var _menu: String = ""
var _boot: Node


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--start="):
			_start = arg.trim_prefix("--start=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--frames="):
			_frames = int(arg.trim_prefix("--frames="))
		elif arg.begins_with("--walk="):
			_walk = _steps(arg.trim_prefix("--walk="))
		elif arg.begins_with("--walk2="):
			_walk2 = _steps(arg.trim_prefix("--walk2="))
		elif arg == "--hud":
			_hud = true
		elif arg == "--run":
			_running = true
		elif arg == "--mid":
			_mid = true
		elif arg == "--bike":
			_bike = true
		elif arg == "--surf":
			_surf = true
		elif arg.begins_with("--fly="):
			_fly = arg.trim_prefix("--fly=")
		elif arg.begins_with("--evolve="):
			_evolve = arg.trim_prefix("--evolve=")
		elif arg == "--menu":
			_menu = "dashboard"
		elif arg.begins_with("--menu="):
			_menu = arg.trim_prefix("--menu=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out.get_base_dir())
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"debug_start_path", "res://tools/debug_start/%s.json" % _start)
	_boot.set(&"force_debug_start", true)
	_boot.set(&"debug_unlocks_path", ABSENT)
	root.add_child(_boot)
	# Le fondu d'arrivée bloque les entrées pendant une demi-seconde : on attend qu'il soit fini.
	await _wait(75)
	if not _hud:
		var hud: CanvasLayer = _boot.call(&"get_hud")
		if hud != null:
			hud.visible = false
	var player: Node = _boot.call(&"get_player")
	if _bike:
		player.call(&"set_mount", 1)  # Mount.Kind.BIKE
		await _wait(5)
	var mid_shot_done := await _do_steps(_walk, _mid and not _surf and _walk2.is_empty())
	if _surf:
		# Le dernier pas (bloqué par l'eau) finit son heurt : le Surf exige un joueur immobile.
		await _wait(40)
		var check: int = _boot.call(&"get_mount_director").call(&"start_surf")
		print("TRAILER : start_surf → %d" % check)
		await _wait(45)
		mid_shot_done = await _do_steps(_walk2, _mid)
	if not _fly.is_empty():
		var fly: Node = _boot.call(&"get_fly_director")
		fly.call(&"fly", StringName(_fly))
		print("TRAILER : vol vers %s" % _fly)
	if not _evolve.is_empty():
		# Les autoloads ne sont pas des identifiants dans un script lancé par -s.
		var party: RefCounted = root.get_node("GameState").get(&"party")
		var first: RefCounted = party.call(&"get_at", 0)
		var candidate := EvolutionCandidate.new(0, first.get(&"species_id"), StringName(_evolve))
		candidate.cancellable = false
		var director: Node = _boot.call(&"get_evolution_director")
		director.call(&"play", [candidate] as Array[EvolutionCandidate], party)
		var screen: Node = director.call(&"get_screen")
		for _i: int in 600:
			await process_frame
			if screen != null and bool(screen.call(&"is_transforming")):
				break
		print("TRAILER : évolution en cours")
	if not _menu.is_empty():
		var menu: Node = _boot.call(&"get_menu_director")
		var route: RefCounted = MenuRoute.new(StringName(_menu))
		var opened: bool = menu.call(&"open", route)
		print("TRAILER : menu %s → %s" % [_menu, opened])
	if not mid_shot_done:
		await _wait(_frames)
		_shot()
	quit()


## Pas du joueur ; avec [param mid], la capture se prend au milieu du dernier pas. Rend vrai si la
## capture a été prise.
func _do_steps(steps: Array[Array], mid: bool) -> bool:
	if _running:
		Input.action_press(&"run")
	var done := false
	for s: int in steps.size():
		var step: Array = steps[s]
		var action: StringName = StringName("move_" + str(step[0]))
		for i: int in int(step[1]):
			var last: bool = s == steps.size() - 1 and i == int(step[1]) - 1
			Input.action_press(action)
			if mid and last:
				await _wait(_frames if _frames < 14 else 6)
				_shot()
				done = true
			await _wait(14 if not _running else 8)
			Input.action_release(action)
			await _wait(4)
	if _running:
		Input.action_release(&"run")
	return done


func _shot() -> void:
	root.get_texture().get_image().save_png(_out)
	print("TRAILER : %s → %s" % [_start, _out])


static func _steps(spec: String) -> Array[Array]:
	var out: Array[Array] = []
	for step: String in spec.split(",", false):
		var parts := step.split(":")
		out.append([parts[0], int(parts[1]) if parts.size() > 1 else 1])
	return out


func _wait(n: int) -> void:
	for _i: int in n:
		await process_frame
