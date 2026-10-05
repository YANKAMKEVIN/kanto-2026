extends SceneTree
## Course latérale du héros dans Jadielle (retour S24 : « il glisse ») : enregistre, image par
## image, un recadrage autour du joueur pendant qu'il court vers la gauche puis vers la droite
## (place centrale, rangée 22).
## --always-on-top : une fenêtre masquée ne se redessine plus sur le Mac.
##
##   godot --path . --always-on-top --write-movie <tmp>/f.png --fixed-fps 60 \
##     -s res://tools/capture_run_cycle.gd -- --out=build/captures/jalon07_course
##
## 2340 × 1080 : `override.cfg` temporaire à la racine (comme capture_viridian.gd).
## Sorties sous --out : run_right_NNN.png, run_left_NNN.png (une image par image de jeu, cadre
## de 300 × 260 px centré sur le joueur) et run_<sens>_scene.png (écran entier, mi-course).
## Le journal donne la cellule et l'image d'animation à chaque image enregistrée.

const BOOT_SCENE := "res://game/boot.tscn"
const START := "res://tools/debug_start/viridian.json"
## Cellule de départ (place centrale) et nombre d'images enregistrées par sens.
const START_CELL := Vector2i(21, 22)
const FRAMES_PER_RUN := 60
const CROP := Vector2i(300, 260)

var _out_dir: String = "build/captures/jalon07_course"
var _boot: Node
var _player: Node2D
var _router: Node


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"debug_start_path", START)
	_boot.set(&"force_debug_start", true)
	root.add_child(_boot)
	_router = root.get_node(^"SceneRouter")
	_router.set(&"fade_out_duration", 0.15)
	_router.set(&"fade_in_duration", 0.15)
	_run()


func _run() -> void:
	await _frames(3)
	_player = _boot.call(&"get_player")
	root.get_node(^"GameState").get(&"flags").call(&"set_flag", &"viridian_arrived")
	await _seconds(1.0)
	await _until(func() -> bool: return not _router.call(&"is_transitioning"), 5.0)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_teleport(START_CELL, Vector2i.LEFT)
	await _frames(30)
	await _record(&"move_left", "run_left")
	await _frames(20)
	await _record(&"move_right", "run_right")
	quit()


func _record(action: StringName, prefix: String) -> void:
	Input.action_press(&"run")
	Input.action_press(action)
	for i: int in FRAMES_PER_RUN:
		await process_frame
		var image := root.get_texture().get_image()
		var sprite := _player.get_node(^"Sprite") as AnimatedSprite2D
		var center := _player.get_global_transform_with_canvas().origin
		var rect := Rect2i(Vector2i(center) - Vector2i(CROP.x / 2, CROP.y - 50), CROP)
		rect = rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
		image.get_region(rect).save_png(_out_dir.path_join("%s_%03d.png" % [prefix, i]))
		if i == FRAMES_PER_RUN / 2:
			image.save_png(_out_dir.path_join("%s_scene.png" % prefix))
		print("%s %03d cell=%s anim=%s frame=%d" % [prefix, i, _player.call(&"get_cell"),
			sprite.animation, sprite.frame])
	Input.action_release(action)
	Input.action_release(&"run")


func _teleport(cell: Vector2i, facing: Vector2i) -> void:
	var map: Node = _boot.call(&"get_map")
	map.call(&"spawn_player_at", _player, cell, facing)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func _until(condition: Callable, timeout: float) -> void:
	var waited := 0.0
	while not condition.call() and waited < timeout:
		await process_frame
		waited += root.get_process_delta_time()
