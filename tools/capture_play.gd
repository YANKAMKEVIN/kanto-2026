extends SceneTree
## Outil de vérification visuelle (Movie Maker) : lance game/boot.tscn et joue un scénario.
##
##   godot --path . --write-movie build/cap/f.png --fixed-fps 30 --quit-after N \
##     -s res://tools/capture_play.gd -- --scenario=<spawn|corners|walk_roof>
##
## Taille de fenêtre : la surcharge 1170×540 du projet l'emporte sur --resolution ;
## utiliser un override.cfg temporaire (window_width/height_override = 2340×1080).
## Le script affiche « CAPTURE <nom> frame=<n> » : image Movie Maker à conserver.
##
## Scénarios :
##   spawn      joueur au spawn, rien d'autre.
##   corners    joueur téléporté près des 4 coins (caméra bornée, pas de gris hors carte).
##   fixes      joueur téléporté sous le grand arbre, derrière le labo, en haut de la Route 1.
##   walk_roof  entrées move_* injectées : spawn → (32, 10) → (32, 4) → (36, 4),
##              au nord de sa maison (le toit doit le masquer, y-sort).

const BOOT_SCENE: String = "res://game/boot.tscn"
const CORNERS: Array = [
	["camera_corners_nw", Vector2i(3, 1)],
	["camera_corners_ne", Vector2i(44, 4)],
	["camera_corners_sw", Vector2i(9, 33)],
	["camera_corners_se", Vector2i(44, 30)],
]
## Retouches après la QA du jalon 1 : transparence, bancs, haut de la Route 1.
const FIXES: Array = [
	["fix_plaza_tree_fade", Vector2i(22, 13)],
	["fix_lab_roof_benches", Vector2i(24, 17)],
	["fix_route1_top", Vector2i(23, 1)],
]
## Étapes de marche : [action, case d'arrivée].
const WALK: Array = [
	[&"move_left", Vector2i(32, 10)],
	[&"move_up", Vector2i(32, 4)],
	[&"move_right", Vector2i(36, 4)],
]

var _scenario: String = "spawn"
var _boot: Node
var _player: Node2D
var _frame: int = 0
var _step: int = 0
var _wait: int = 0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			_scenario = arg.trim_prefix("--scenario=")
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	root.add_child(_boot)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	if _player == null:
		_player = _boot.call(&"get_player")
		return
	match _scenario:
		"spawn":
			if _frame == 20:
				_mark("boot_spawn")
		"corners":
			_run_teleports(CORNERS)
		"fixes":
			_run_teleports(FIXES)
		"walk_roof":
			_run_walk()


func _mark(capture_name: String) -> void:
	print("CAPTURE %s frame=%d cell=%s facing=%s pos=%s" % [
		capture_name, _frame, _player.call(&"get_cell"), _player.call(&"get_facing"),
		_player.position,
	])


func _run_teleports(spots: Array) -> void:
	var index := (_frame - 5) / 20
	var phase := (_frame - 5) % 20
	if _frame < 5 or index >= spots.size():
		return
	var map: Node = _boot.call(&"get_map")
	if phase == 0:
		_player.call(&"enter_map", map.call(&"get_grid"), spots[index][1], Vector2i.DOWN,
			map.call(&"get_pixel_rect"))
	elif phase == 16:
		_mark(spots[index][0])


func _run_walk() -> void:
	if _frame == 5:
		_mark("walk_before")
	if _frame < 10:
		return
	if _step >= WALK.size():
		_wait += 1
		if _wait == 3:
			Input.action_press(&"move_up")
		elif _wait == 4:
			Input.action_release(&"move_up")
		elif _wait == 20:
			_mark("ysort_roof")
		return
	var action: StringName = WALK[_step][0]
	var goal: Vector2i = WALK[_step][1]
	var direction := _direction_of(action)
	var cell: Vector2i = _player.call(&"get_cell")
	var moving: bool = _player.call(&"is_moving")
	if cell == goal and not moving:
		_step += 1
		return
	if moving and cell + direction == goal:
		Input.action_release(action)
	elif not moving or cell != goal:
		if not Input.is_action_pressed(action) and not (moving and cell + direction == goal):
			Input.action_press(action)


func _direction_of(action: StringName) -> Vector2i:
	match action:
		&"move_left":
			return Vector2i.LEFT
		&"move_right":
			return Vector2i.RIGHT
		&"move_up":
			return Vector2i.UP
	return Vector2i.DOWN
