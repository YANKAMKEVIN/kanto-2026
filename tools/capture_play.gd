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
##   route1_grass  jalon 3B (T1) : joueur téléporté en (23, 4) tourné vers le nord (hautes
##              herbes, Roucool et Rattata de la prairie), puis move_up injecté jusqu'en
##              (23, 2) (dans les herbes : rien ne se passe encore), puis move_down jusqu'en
##              (23, 5). Captures jalon03b_route1_grass_{below,inside,out}. ~200 images.
##   route1_freeze  jalon 3B (T2) : joueur téléporté en (23, 7) tourné vers le nord, move_up
##              tenu : gel en (23, 3) (contrôles cachés), « ??? — Hé ! Attends ! », le joueur
##              retourné (contrôles rendus), un pas vers le bas puis move_up à nouveau : la
##              pensée en narration. Captures jalon03b_t2_NN_*. ~400 images à 30 images/s :
##              --quit-after 900.
##   route1_oak  jalon 3B (T3) : pour chacune des deux colonnes du chemin (23 puis 24),
##              joueur téléporté en (x, 7) tourné vers le nord, move_up tenu : gel en (x, 3),
##              « ??? », le joueur se retourne, Chen apparaît en (24, 13) hors de l'écran et
##              arrive en courant (captures à l'entrée dans l'écran et en chemin), s'arrête à
##              côté du joueur ; ses quatre répliques (étiquette « Prof. Chen », Chen tourné
##              vers les herbes à la deuxième) ; contrôle rendu. Entre les deux colonnes : Chen
##              retiré et drapeaux remis à zéro. Pour finir, la pensée des herbes puis le recul
##              d'un pas. Captures jalon03b_t3_<colonne>_NN_*. Quitte seul à la fin (~2 000
##              images à 30 images/s : --quit-after 4000).
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
##   npcs       jalon 3A (T4) : départ réel du jeu, puis tous les PNJ et points d'examen :
##              Maman qui parle d'elle-même, table, rival (page 1, puis page 2 tourné vers
##              le joueur), carte de Kanto, Maya, les trois starters (Salamèche en
##              réaction), Mme Aoki et ses Roucool, Léo (Rattata en réaction), panneau,
##              Haru. Captures jalon03_npcs_NN_* (bouton contextuel avant certaines
##              interactions, puis boîte de dialogue page complète). Déroulé écrit en
##              coroutine (await process_frame) ; marche en plus court chemin, course
##              tenue dehors, entrées injectées. Quitte seul à la fin (~3 000 images :
##              --quit-after 6000 ; préférer --write-movie <dossier>/x.avi, plus léger).

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
## Scénario « route1_grass » (jalon 3B, T1) : case de départ, puis marches
## [action, case d'arrivée, capture prise à l'arrêt].
const ROUTE1_START := Vector2i(23, 4)
const ROUTE1_WALK: Array = [
	[&"move_up", Vector2i(23, 2), "jalon03b_route1_grass_inside"],
	[&"move_down", Vector2i(23, 5), "jalon03b_route1_grass_out"],
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
const NPCS_PREFIX: String = "jalon03_npcs_"
const T2_PREFIX: String = "jalon03b_t2_"
const T3_PREFIX: String = "jalon03b_t3_"
## Délai maximal d'une attente du scénario « npcs » (images).
const NPCS_TIMEOUT: int = 900
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
	if _scenario == "doors":
		_setup_doors()
	elif _scenario == "npcs":
		_setup_doors()
		InputMap.action_erase_events(&"interact")
	elif _scenario == "route1_freeze" or _scenario == "route1_oak":
		_boot.set(&"start_map", &"pallet_town")
		for action: StringName in MOVE_ACTIONS.values():
			InputMap.action_erase_events(action)
		InputMap.action_erase_events(&"run")
		InputMap.action_erase_events(&"interact")
	else:
		_boot.set(&"start_map", &"pallet_town")
	root.add_child(_boot)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	_save_pending_shot()
	if _player == null:
		_player = _boot.call(&"get_player")
		if _scenario == "npcs":
			_run_npcs()
		elif _scenario == "route1_freeze":
			_run_route1_freeze()
		elif _scenario == "route1_oak":
			_run_route1_oak()
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
		"route1_grass":
			_run_route1_grass()
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


func _run_route1_grass() -> void:
	if _frame == 5:
		var map: Node = _boot.call(&"get_map")
		_player.call(&"enter_map", map.call(&"get_grid"), ROUTE1_START, Vector2i.UP,
			map.call(&"get_pixel_rect"))
	elif _frame == 24:
		_mark("jalon03b_route1_grass_below")
	if _frame < 30 or _step >= ROUTE1_WALK.size():
		if _step >= ROUTE1_WALK.size():
			_wait += 1
			if _wait == 20:
				print("ROUTE1_GRASS terminé (frame %d)" % _frame)
				quit()
		return
	var action: StringName = ROUTE1_WALK[_step][0]
	var goal: Vector2i = ROUTE1_WALK[_step][1]
	var cell: Vector2i = _player.call(&"get_cell")
	var moving: bool = _player.call(&"is_moving")
	if cell == goal and not moving:
		Input.action_release(action)
		_wait += 1
		if _wait == 16:
			_mark(ROUTE1_WALK[_step][2])
			_step += 1
			_wait = 0
		return
	if moving and cell + _direction_of(action) == goal:
		Input.action_release(action)
	elif not moving:
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
	if _scenario != "doors" or not _router.call(&"is_transitioning"):
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


# --- Scénario « npcs » (jalon 3A, T4) ----------------------------------------------

func _run_npcs() -> void:
	await _frames(20)
	# Chambre → escalier : Maman parle d'elle-même à l'arrivée.
	await _go_through(Vector2i(6, 9))
	await _page_complete()
	await _shot("01_mom_auto")
	await _finish_dialogue()
	# Table du petit-déjeuner.
	await _go(Vector2i(4, 6))
	await _face_and_shot(Vector2i.UP, "02_table_button")
	await _talk("03_table")
	# Dehors, puis chez le rival.
	await _go(Vector2i(7, 8))
	await _push_through(Vector2i.DOWN)
	await _go_through(Vector2i(11, 9), true)
	await _go(Vector2i(12, 4))
	await _face_and_shot(Vector2i.RIGHT, "04_rival_button")
	await _interact()
	await _page_complete()
	await _shot("05_rival_page1")
	await _interact()
	await _page_complete()
	await _shot("06_rival_page2_turned")
	await _finish_dialogue()
	await _go(Vector2i(14, 4))
	_player.call(&"face", Vector2i.RIGHT)
	await _talk("07_kanto_map")
	# Labo : Maya et les trois starters.
	await _go(Vector2i(9, 9))
	await _push_through(Vector2i.DOWN)
	await _go_through(Vector2i(24, 22), true)
	await _go(Vector2i(5, 4))
	_player.call(&"face", Vector2i.UP)
	await _talk("08_maya")
	await _go(Vector2i(10, 6))
	_player.call(&"face", Vector2i.UP)
	await _talk("09_bulbasaur")
	await _go(Vector2i(11, 6))
	await _face_and_shot(Vector2i.UP, "10_charmander_button")
	await _interact()
	await _frames(4)
	await _shot("11_charmander_react")
	await _page_complete()
	await _shot("12_charmander")
	await _finish_dialogue()
	await _go(Vector2i(12, 6))
	_player.call(&"face", Vector2i.UP)
	await _talk("13_squirtle")
	# Village : Mme Aoki, Léo, panneau, Haru.
	await _go(Vector2i(7, 9))
	await _push_through(Vector2i.DOWN)
	await _go(Vector2i(30, 13), true)
	_player.call(&"face", Vector2i.LEFT)
	await _talk("14_aoki")
	await _go(Vector2i(19, 9), true)
	_player.call(&"face", Vector2i.LEFT)
	await _interact()
	await _page_complete()
	await _interact()
	await _frames(5)
	await _shot("15_leo_rattata_react")
	await _page_complete()
	await _shot("16_leo_page2")
	await _finish_dialogue()
	await _go(Vector2i(21, 14), true)
	await _face_and_shot(Vector2i.UP, "17_sign_button")
	await _talk("18_sign")
	await _go(Vector2i(9, 32), true)
	await _face_and_shot(Vector2i.DOWN, "19_haru_button")
	await _talk("20_haru")
	await _frames(5)
	print("NPCS terminé (frame %d)" % _frame)
	quit()


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _shot(capture_name: String) -> void:
	_mark(NPCS_PREFIX + capture_name)
	await _frames(2)


## Pivote vers [param direction], laisse le bouton contextuel apparaître, capture.
func _face_and_shot(direction: Vector2i, capture_name: String) -> void:
	_player.call(&"face", direction)
	await _frames(12)
	await _shot(capture_name)


func _interact() -> void:
	Input.action_press(&"interact")
	await process_frame
	Input.action_release(&"interact")
	await process_frame


## Attend que la page courante soit entièrement écrite (« › » ou dernière page).
func _page_complete() -> void:
	var runner: Node = _boot.call(&"get_dialogue_runner")
	for i: int in NPCS_TIMEOUT:
		var session: RefCounted = runner.call(&"get_session")
		if session != null and session.call(&"is_page_complete"):
			break
		await process_frame
	await _frames(8)


func _finish_dialogue() -> void:
	var runner: Node = _boot.call(&"get_dialogue_runner")
	for i: int in NPCS_TIMEOUT:
		if not runner.call(&"is_running"):
			break
		await _interact()
	await _frames(6)


## Lance le dialogue de la cible, capture sa première page complète, le termine.
func _talk(capture_name: String) -> void:
	await _frames(6)
	await _interact()
	await _page_complete()
	await _shot(capture_name)
	await _finish_dialogue()


## Marche (plus court chemin) jusqu'à [param goal] et s'y arrête.
func _go(goal: Vector2i, run: bool = false) -> void:
	_path = _find_path(_player.call(&"get_cell"), goal)
	if _path.is_empty():
		push_error("npcs : aucun chemin vers %s" % goal)
		quit(1)
		return
	if run:
		Input.action_press(&"run")
	for i: int in NPCS_TIMEOUT * 2:
		await process_frame
		var cell: Vector2i = _player.call(&"get_cell")
		var moving: bool = _player.call(&"is_moving")
		if not moving and cell == goal:
			break
		var from := cell + (_player.call(&"get_facing") as Vector2i) if moving else cell
		var index := _path.find(from)
		if index < 0 or index == _path.size() - 1:
			_release_moves()
			continue
		_hold(_path[index + 1] - from)
	_release_moves()
	Input.action_release(&"run")
	await _frames(2)


## Marche jusqu'à une case de passage (porte, escalier) et attend la nouvelle carte.
func _go_through(goal: Vector2i, run: bool = false) -> void:
	_arrived = false
	await _go(goal, run)
	await _wait_arrival()


## Pousse vers [param direction] sur un tapis de sortie jusqu'à la nouvelle carte.
func _push_through(direction: Vector2i) -> void:
	_arrived = false
	for i: int in NPCS_TIMEOUT:
		if _router.call(&"is_transitioning"):
			break
		_hold(direction)
		await process_frame
	_release_moves()
	await _wait_arrival()


func _wait_arrival() -> void:
	for i: int in NPCS_TIMEOUT:
		if _arrived:
			break
		await process_frame
	_release_moves()
	await _frames(SETTLE_FRAMES)


# --- Scénario « route1_freeze » (jalon 3B, T2) --------------------------------------

func _run_route1_freeze() -> void:
	await _frames(5)
	var map: Node = _boot.call(&"get_map")
	_player.call(&"enter_map", map.call(&"get_grid"), Vector2i(23, 7), Vector2i.UP,
		map.call(&"get_pixel_rect"))
	await _frames(20)
	var director: Node = _boot.call(&"get_cutscene_director")
	await _hold_up_until_scene(director)
	await _frames(2)
	await _t2_shot("01_freeze")
	await _page_complete()
	await _t2_shot("02_call")
	await _finish_dialogue()
	await _frames(10)
	await _t2_shot("03_turned")
	await _go(Vector2i(23, 4))
	await _frames(6)
	await _hold_up_until_scene(director)
	await _page_complete()
	await _t2_shot("04_thought")
	await _finish_dialogue()
	await _frames(10)
	await _t2_shot("05_after_thought")
	await _frames(5)
	print("ROUTE1_FREEZE terminé (frame %d)" % _frame)
	quit()


## Tient move_up jusqu'au début d'une scène, puis relâche.
func _hold_up_until_scene(director: Node) -> void:
	Input.action_press(&"move_up")
	for i: int in NPCS_TIMEOUT:
		if director.call(&"is_running"):
			break
		await process_frame
	Input.action_release(&"move_up")


func _t2_shot(capture_name: String) -> void:
	var hud: Node = _boot.call(&"get_hud")
	print("  contrôles visibles : %s" % hud.call(&"are_controls_visible"))
	_mark(T2_PREFIX + capture_name)
	await _frames(2)


# --- Scénario « route1_oak » (jalon 3B, T3) -----------------------------------------

func _run_route1_oak() -> void:
	await _frames(5)
	await _oak_column(23, "a")
	# Nouvelle interception sur l'autre colonne : Chen retiré, drapeaux remis à zéro.
	_boot.call(&"get_map").call(&"remove_npc", &"oak")
	root.get_node(^"GameState").call(&"new_game")
	await _frames(4)
	await _oak_column(24, "b")
	# Remonter : la pensée des herbes, puis le recul d'un pas.
	var director: Node = _boot.call(&"get_cutscene_director")
	await _go(Vector2i(24, 4))
	await _frames(6)
	await _hold_up_until_scene(director)
	await _page_complete()
	await _t3_shot("b_08_thought")
	await _finish_dialogue()
	for i: int in NPCS_TIMEOUT:
		if not director.call(&"is_running"):
			break
		await process_frame
	await _frames(10)
	await _t3_shot("b_09_after_recoil")
	await _frames(5)
	print("ROUTE1_OAK terminé (frame %d)" % _frame)
	quit()


## Interception complète depuis la colonne [param x] (captures préfixées [param tag]).
func _oak_column(x: int, tag: String) -> void:
	var map: Node = _boot.call(&"get_map")
	_player.call(&"enter_map", map.call(&"get_grid"), Vector2i(x, 7), Vector2i.UP,
		map.call(&"get_pixel_rect"))
	await _frames(20)
	var director: Node = _boot.call(&"get_cutscene_director")
	var runner: Node = _boot.call(&"get_dialogue_runner")
	await _hold_up_until_scene(director)
	await _page_complete()
	await _t3_shot(tag + "_01_call")
	await _finish_dialogue()
	# Chen apparaît (0,3 s), puis court : image à l'entrée dans l'écran et en chemin.
	var oak: Node2D = null
	for i: int in NPCS_TIMEOUT:
		oak = _boot.call(&"get_map").call(&"get_npc", &"oak")
		if oak != null:
			break
		await process_frame
	await _t3_shot(tag + "_02_turned_oak_offscreen")
	var shots: Dictionary[int, String] = {
		10: tag + "_03_oak_enters", 7: tag + "_04_oak_running",
	}
	for i: int in NPCS_TIMEOUT:
		if oak == null or not is_instance_valid(oak) or runner.call(&"is_running"):
			break
		var row: int = (oak.call(&"get_cell") as Vector2i).y
		if shots.has(row) and oak.call(&"is_moving"):
			await _t3_shot(shots[row])
			shots.erase(row)
		await process_frame
	# Répliques du Prof. Chen : une capture par page complète.
	var names: Array[String] = ["_05_line1", "_06_line2_grass", "_07_line3", "_07b_line4"]
	for page: int in names.size():
		await _page_complete()
		await _t3_shot(tag + names[page])
		if page < names.size() - 1:
			await _interact()
	await _finish_dialogue()
	for i: int in NPCS_TIMEOUT:
		if not director.call(&"is_running"):
			break
		await process_frame
	await _frames(10)
	await _t3_shot(tag + "_07c_control_back")


func _t3_shot(capture_name: String) -> void:
	var hud: Node = _boot.call(&"get_hud")
	var oak: Node = _boot.call(&"get_map").call(&"get_npc", &"oak")
	print("  contrôles visibles : %s ; Chen : %s" % [hud.call(&"are_controls_visible"),
		"absent" if oak == null else "%s %s" % [oak.call(&"get_cell"), oak.call(&"get_facing")]])
	_mark(T3_PREFIX + capture_name)
	await _frames(2)
