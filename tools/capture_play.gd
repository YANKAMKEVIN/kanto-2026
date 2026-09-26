extends SceneTree
## Outil de vérification visuelle (Movie Maker) : lance game/boot.tscn et joue un scénario.
##
##   godot --path . --always-on-top --write-movie build/cap/f.png --fixed-fps 30 \
##     --quit-after N -s res://tools/capture_play.gd -- --scenario=<nom> [--out=build/captures]
##
## Taille de fenêtre : la surcharge 1170×540 du projet l'emporte sur --resolution ;
## utiliser un override.cfg temporaire (window_width/height_override = 2340×1080).
## Le script affiche « CAPTURE <nom> frame=<n> » : image Movie Maker à conserver. Avec
## « --out=<dossier> », il enregistre aussi l'image affichée sous <dossier>/<nom>.png
## (texture du viewport lue à l'image suivante : c'est l'image de la marque).
## Sauf « doors », les scénarios démarrent dans Bourg Palette (Boot.start_map).
##
## Scénarios :
##   spawn      joueur au spawn, rien d'autre.
##   corners    joueur téléporté près des 4 coins (caméra bornée, pas de gris hors carte).
##   fixes      joueur téléporté sous le grand arbre, derrière le labo, en haut de la Route 1.
##   walk_roof  entrées move_* injectées : spawn → (32, 10) → (32, 4) → (36, 4),
##              au nord de sa maison (le toit doit le masquer, y-sort).
##   doors      départ réel du jeu (chambre) puis portes, tapis et escaliers (jalon 2, T5) :
##              chambre → escalier → rez-de-chaussée → dehors (titre) → maison du rival →
##              sa chambre (même carte) → dehors (sans titre) → labo → dehors.
##              Une capture par étape (jalon02_doors_NN_*), plus le fondu : image où la
##              nouvelle carte est posée sous le rideau, et une image à mi-fondu.
##              Marche en plus court chemin (BFS sur la GridWorld de la carte courante),
##              entrées injectées par Input.action_press. Quitte seul à la fin.
##              Environ 1 000 images à 30 images/s : --quit-after 1500.

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

## Étapes du scénario « doors » : goal = case à atteindre (plus court chemin) ; push =
## direction à tenir ensuite sur place (tapis de sortie) ; map = carte attendue à l'arrivée
## ("" : pas de passage) ; capture = nom de l'image prise une fois la carte visible.
## Un passage STEP_ON (porte, escalier) se déclenche en atteignant goal.
const DOORS_HOUSE: Array[Dictionary] = [
	{"goal": Vector2i(6, 9), "map": &"player_house_1f", "capture": "02_ground_floor"},
	{"goal": Vector2i(7, 8), "push": Vector2i.DOWN, "map": &"pallet_town",
		"capture": "03_outside_title"},
]
## Maison du rival, un seul niveau (jalon 2 §4.5) : entrée, chambre du rival, sortie.
const DOORS_RIVAL: Array[Dictionary] = [
	{"goal": Vector2i(11, 9), "map": &"rival_house", "capture": "04_rival_house"},
	{"goal": Vector2i(14, 4), "map": &"", "capture": "05_rival_bedroom"},
	{"goal": Vector2i(9, 9), "push": Vector2i.DOWN, "map": &"pallet_town",
		"capture": "06_outside_no_title"},
]
## Labo (16 × 11, tient dans l'écran, §4.7) : une capture de la pièce entière.
const DOORS_LAB: Array[Dictionary] = [
	{"goal": Vector2i(24, 22), "map": &"oak_lab", "capture": "07_lab"},
	{"goal": Vector2i(7, 9), "push": Vector2i.DOWN, "map": &"pallet_town",
		"capture": "08_outside_after_lab"},
]
const DOORS_PREFIX: String = "jalon02_doors_"
## Images d'attente avant la capture d'une étape (titre de zone entré : ~0,3 s).
const SETTLE_FRAMES: int = 24
const MOVE_ACTIONS: Dictionary = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}

var _scenario: String = "spawn"
var _out_dir: String = ""
var _boot: Node
var _player: Node2D
var _frame: int = 0
var _step: int = 0
var _wait: int = 0
## Scénario « doors ».
var _router: Node
var _doors: Array[Dictionary] = []
var _path: Array[Vector2i] = []
var _phase: String = "start"
var _arrived: bool = false
var _pending_shots: Dictionary[int, String] = {}
var _map_changes: int = 0
## Marques différées (image → nom) : le fondu avance entre-temps.
var _deferred_marks: Dictionary[int, String] = {}


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			_scenario = arg.trim_prefix("--scenario=")
		elif arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	# Les autoloads (SceneRouter, utilisé par Boot) ne sont ajoutés qu'après _init.
	process_frame.connect(_start_boot, CONNECT_ONE_SHOT)


func _start_boot() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	if _scenario != "doors":
		_boot.set(&"start_map", &"pallet_town")
	else:
		_setup_doors()
	root.add_child(_boot)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	_save_pending_shot()
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
		"doors":
			_run_doors()


func _mark(capture_name: String) -> void:
	var map: Node = _boot.call(&"get_map")
	print("CAPTURE %s frame=%d map=%s cell=%s facing=%s pos=%s" % [
		capture_name, _frame, map.get(&"map_id") if map != null else &"",
		_player.call(&"get_cell"), _player.call(&"get_facing"), _player.position,
	])
	if not _out_dir.is_empty():
		# La texture du viewport contient l'image précédente : on la lit à l'image suivante.
		_pending_shots[_frame + 1] = capture_name


func _save_pending_shot() -> void:
	if not _pending_shots.has(_frame):
		return
	var capture_name: String = _pending_shots[_frame]
	_pending_shots.erase(_frame)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var path := _out_dir.path_join(capture_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("  → %s" % path)


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


# --- Scénario « doors » -------------------------------------------------------------

func _setup_doors() -> void:
	# La fenêtre de capture prend le focus : seules les entrées injectées pilotent le joueur.
	for action: StringName in MOVE_ACTIONS.values():
		InputMap.action_erase_events(action)
	InputMap.action_erase_events(&"run")
	_doors.assign(DOORS_HOUSE + DOORS_RIVAL + DOORS_LAB)
	_router = root.get_node(^"SceneRouter")
	_router.connect(&"transition_started", _on_doors_transition_started)
	_router.connect(&"map_changed", _on_doors_map_changed)
	_router.connect(&"map_entered", _on_doors_map_entered)


func _on_doors_transition_started(target: StringName) -> void:
	_release_moves()
	print("transition → %s (frame %d)" % [target, _frame])


func _on_doors_map_changed(_map: Node) -> void:
	if not _router.call(&"is_transitioning"):
		return  # start() : pas de fondu
	_map_changes += 1
	if _map_changes == 1:
		# Première transition : nouvelle carte posée sous le rideau opaque, puis mi-fondu.
		_mark(DOORS_PREFIX + "fade_black")
		_pending_mark(_frame + 3, DOORS_PREFIX + "fade_mid")


func _on_doors_map_entered(_map: Node) -> void:
	_arrived = true


func _pending_mark(at_frame: int, capture_name: String) -> void:
	_deferred_marks[at_frame] = capture_name


func _run_doors() -> void:
	if _deferred_marks.has(_frame):
		_mark(_deferred_marks[_frame])
		_deferred_marks.erase(_frame)
	match _phase:
		"start":
			if _frame == 20:
				_mark(DOORS_PREFIX + "01_bedroom")
				_start_step()
		"walk":
			_doors_walk()
		"push":
			var push: Vector2i = _doors[_step]["push"]
			Input.action_press(MOVE_ACTIONS[push])
			if _router.call(&"is_transitioning"):
				_release_moves()
				_phase = "arrival"
		"arrival":
			if _arrived:
				_phase = "settle"
				_wait = 0
		"settle":
			_wait += 1
			if _wait == SETTLE_FRAMES:
				var capture: String = _doors[_step].get("capture", "")
				if not capture.is_empty():
					_mark(DOORS_PREFIX + capture)
				_step += 1
				_start_step()
		"done":
			_wait += 1
			if _wait == 5:
				print("DOORS terminé (frame %d)" % _frame)
				quit()


func _start_step() -> void:
	_release_moves()
	if _step >= _doors.size():
		_phase = "done"
		_wait = 0
		return
	_arrived = false
	var goal: Vector2i = _doors[_step]["goal"]
	_path = _find_path(_player.call(&"get_cell"), goal)
	if _path.is_empty():
		push_error("doors : aucun chemin vers %s" % goal)
		quit(1)
		return
	_phase = "walk"


func _doors_walk() -> void:
	var cell: Vector2i = _player.call(&"get_cell")
	var goal: Vector2i = _path.back()
	var from := cell
	if _player.call(&"is_moving"):
		from = cell + (_player.call(&"get_facing") as Vector2i)
	var index := _path.find(from)
	if not _player.call(&"is_moving") and cell == goal:
		_release_moves()
		var step: Dictionary = _doors[_step]
		if step.has("push"):
			_phase = "push"
		elif StringName(step.get("map", &"")).is_empty():
			_phase = "settle"
			_wait = 0
		else:
			_phase = "arrival"
		return
	if index < 0 or index == _path.size() - 1:
		_release_moves()
		return
	_hold(_path[index + 1] - from)


func _hold(direction: Vector2i) -> void:
	for dir: Vector2i in MOVE_ACTIONS:
		var action: StringName = MOVE_ACTIONS[dir]
		if dir == direction:
			if not Input.is_action_pressed(action):
				Input.action_press(action)
		elif Input.is_action_pressed(action):
			Input.action_release(action)


func _release_moves() -> void:
	for action: StringName in MOVE_ACTIONS.values():
		Input.action_release(action)


## Plus court chemin (pas simples, sans rebord) sur la grille de la carte courante.
func _find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var grid: RefCounted = _boot.call(&"get_map").call(&"get_grid")
	var previous: Dictionary[Vector2i, Vector2i] = {start: start}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell == goal:
			break
		for dir: Vector2i in MOVE_ACTIONS:
			var next := cell + dir
			if previous.has(next):
				continue
			if grid.call(&"get_step_target", cell, dir, _player) != next:
				continue
			previous[next] = cell
			queue.append(next)
	var path: Array[Vector2i] = []
	if not previous.has(goal):
		return path
	var cursor := goal
	while cursor != start:
		path.push_front(cursor)
		cursor = previous[cursor]
	path.push_front(start)
	return path
