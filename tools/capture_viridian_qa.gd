extends SceneTree
## Captures de la QA T5 de Jadielle (S21, jalon-07.md §15.22) : toit du niveau bas sous le
## joueur de la terrasse, garde-corps des murs sud et nord, habitants hors des goulets.
##
##   godot --path . --resolution 2340x1080 --write-movie build/cap/qa.png --fixed-fps 30 \
##     -s res://tools/capture_viridian_qa.gd \
##     -- --out=build/captures/jalon07_t5_qa --prefix=apres
##
## Départ `tools/debug_start/viridian.json`, arrivée déjà faite (habitants d'après la scène).

const BOOT_SCENE := "res://game/boot.tscn"
const START := "res://tools/debug_start/viridian.json"
const TILE := 96

var _out_dir: String = ""
var _prefix: String = "qa"
var _boot: Node
var _player: Node2D
var _router: Node


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--prefix="):
			_prefix = arg.trim_prefix("--prefix=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	# Fenêtre masquée par une autre : sans cela la synchronisation verticale gèle la boucle.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"debug_start_path", START)
	_boot.set(&"force_debug_start", true)
	root.add_child(_boot)
	_router = root.get_node(^"SceneRouter")
	_router.set(&"fade_out_duration", 0.1)
	_router.set(&"fade_in_duration", 0.1)
	_run()


func _run() -> void:
	await _frames(3)
	_player = _boot.call(&"get_player")
	root.get_node(^"GameState").get(&"flags").call(&"set_flag", &"viridian_arrived")
	_router.call(&"change_map", &"viridian_city", &"from_center", Vector2i.DOWN)
	await _until(func() -> bool: return not _router.call(&"is_transitioning"), 5.0)
	# Rue est, à côté de la Boutique : le livreur sur sa boucle, la rangée du garde-corps libre
	# et visible (2e passe : « rue d'une case de large »).
	_teleport(Vector2i(45, 23), Vector2i.LEFT)
	await _seconds(2.0)
	await _shot("3_rue_est")
	# 1. Rue de la place au-dessus du toit vert (maison sud-ouest) : le toit reste opaque.
	_teleport(Vector2i(20, 23), Vector2i.DOWN)
	await _seconds(1.0)
	await _shot("1_toit_niveau_bas")
	# 2. Garde-corps du mur sud, joueur collé ; un habitant posé à côté pour comparer.
	_teleport(Vector2i(34, 23), Vector2i.DOWN)
	_pose_npc(&"courier", Vector2i(32, 23))
	await _seconds(0.3)
	await _shot("2_garde_corps_sud")
	# Garde-corps du mur nord (parvis de l'Arène, terrasse haute).
	_teleport(Vector2i(14, 11), Vector2i.DOWN)
	await _seconds(0.8)
	await _shot("2_garde_corps_nord")
	# 3. Parvis de l'Arène : le gardien sur le côté, la porte libre.
	_teleport(Vector2i(10, 10), Vector2i.UP)
	await _seconds(0.8)
	await _shot("3_parvis_arene")
	# Rue de la place, côté ouest : Dresseuse, enfant et Rattata hors du passage.
	_teleport(Vector2i(20, 22), Vector2i.LEFT)
	await _seconds(2.5)
	await _shot("3_rue_ouest")
	await _seconds(2.0)
	await _shot("3_rue_ouest_b")
	# Le héros longe le garde-corps vers l'ouest (rangée du bas de la rue), puis s'arrête.
	_teleport(Vector2i(19, 23), Vector2i.LEFT)
	await _seconds(0.3)
	Input.action_press(&"move_left")
	await _seconds(1.2)
	await _shot("3_rue_ouest_marche")
	Input.action_release(&"move_left")
	await _seconds(0.8)
	await _shot("3_rue_ouest_arret")
	quit()


## Pose un habitant sur une case pour la photo (figé, sans passer par la grille).
func _pose_npc(id: StringName, cell: Vector2i) -> void:
	var map: Node = _boot.call(&"get_map")
	var npc := map.call(&"get_npc", id) as Node2D
	if npc == null:
		return
	npc.process_mode = Node.PROCESS_MODE_DISABLED
	npc.position = Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _teleport(cell: Vector2i, facing: Vector2i) -> void:
	var map: Node = _boot.call(&"get_map")
	map.call(&"spawn_player_at", _player, cell, facing)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


## Attente en images (30 i/s fixes de Movie Maker) : ne dépend pas des minuteries.
func _seconds(seconds: float) -> void:
	await _frames(ceili(seconds * 30.0))


func _until(condition: Callable, timeout: float) -> void:
	var waited := 0.0
	while not condition.call() and waited < timeout:
		await process_frame
		waited += root.get_process_delta_time()


func _shot(capture_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	print("CAPTURE %s cell=%s" % [capture_name, _player.call(&"get_cell")])
	if _out_dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var path := _out_dir.path_join("%s_%s.png" % [_prefix, capture_name])
	root.get_texture().get_image().save_png(path)
	print("  → %s" % path)
