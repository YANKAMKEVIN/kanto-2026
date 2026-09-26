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
##   route1_full  jalon 3B (T4) : l'événement complet depuis la colonne 23 (ou 24 avec
##              « --column=24 ») : gel, « ??? », Chen qui entre dans l'écran, ses quatre
##              répliques, le suivi (deux images), le fondu, l'arrivée au labo, le rival vers
##              Chen puis vers le joueur, les quatre répliques du labo, le contrôle rendu,
##              Maya (deux pages), la chambre du rival vide, puis la pensée des herbes et le
##              recul. Captures jalon03b_t4_<colonne>_NN_*. Quitte seul à la fin (~2 500
##              images à 30 images/s : --quit-after 6000).
##              (« route1_oak » s'arrêtait aux répliques de Chen : depuis T4, la scène
##              continue jusqu'au labo, utiliser route1_full.)
##              Jalon 4 (T1) : après les quatre répliques du labo, les quatre répliques de la
##              proposition de Chen (17b à 17e).
##   starter_offer  jalon 4 (T1) : départ au labo sur le tapis d'entrée, drapeau oak_met
##              levé (Chen et le rival présents), puis la fin réelle de la variante 1 de
##              route1_grass (toutes les étapes après son change_map, lues dans
##              data/cutscenes/prologue.json) : deux pas, regards du rival, les quatre
##              répliques du labo, la proposition de Chen (4 pages ; il regarde la table à la
##              3e), contrôle rendu, puis un starter observé (bouton, puis boîte). Captures
##              jalon04a_t1_offer_NN_*. Quitte seul (~700 images : --quit-after 2000).
##   hop_styles  jalon 4 (T1) : départ au labo (oak_met), puis chacun des trois starters
##              saute de la table sur la case sous lui (Npc.hop_to, styles calm / eager /
##              playful) : captures à l'élan, au sommet de l'arc, à l'arrivée (rebond) et
##              posé ; puis les trois au sol. Captures jalon04a_t1_hop_<style>_*. Quitte seul
##              (~400 images : --quit-after 1500).
##   starter_choice  jalon 4 (T3) : départ au labo sur le tapis d'entrée, drapeaux oak_met,
##              oak_lab_reunion puis starter_offered (fin du discours de Chen) : légende,
##              marche jusqu'au starter de « --starter=bulbasaur|charmander|squirtle »
##              (défaut charmander), bouton RENCONTRER, fiche, CHOISIR (le vrai bouton), puis
##              toute la scène starter_chosen : saut du starter (pendant, posé), « réciproque »,
##              le rival qui regarde la table, « Alors ce sera toi. », saut de son Pokémon
##              (pendant, posé), départ, « Attends. », regard vers le Pokémon du joueur,
##              dernière réplique, contrôle rendu. Captures jalon04a_t3_<starter>_NN_*.
##              Quitte seul (~900 images : --quit-after 9000).
##   lab_exit   jalon 4 (T3) : départ au labo pendant le choix (oak_met, oak_lab_reunion,
##              starter_offered), joueur en (7, 8), « bas » tenu : il arrive sur le tapis,
##              « Pas si vite. … » (Prof. Chen), recul d'un pas, toujours au labo. Captures
##              jalon04a_t3_exit_NN_*. Quitte seul (~300 images : --quit-after 3000).
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
const T4_PREFIX: String = "jalon03b_t4_"
const OFFER_PREFIX: String = "jalon04a_t1_offer_"
const HOP_PREFIX: String = "jalon04a_t1_hop_"
const T3_CHOICE_PREFIX: String = "jalon04a_t3_"
const STARTER_PATH: String = "res://data/cutscenes/starter.json"
## Scène du scénario « starter_offer » : fin de la variante 1 de route1_grass (après son
## change_map), ajoutée à la bibliothèque de Boot sous ce nom.
const OFFER_SCENE: StringName = &"capture_starter_offer"
const PROLOGUE_PATH: String = "res://data/cutscenes/prologue.json"
## Scénario « hop_styles » : [PNJ, case d'arrivée] dans l'ordre des sauts.
const HOPS: Array = [
	[&"bulbasaur", Vector2i(10, 6)],
	[&"charmander", Vector2i(11, 6)],
	[&"squirtle", Vector2i(12, 6)],
]
## Délai maximal d'une attente du scénario « npcs » (images).
const NPCS_TIMEOUT: int = 900
## Images d'attente avant la capture d'une étape (titre de zone entré : ~0,3 s).
const SETTLE_FRAMES: int = 24
const MOVE_ACTIONS: Dictionary = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}

var _scenario: String = "spawn"
## Colonne du chemin de la Route 1 (scénario « route1_full »).
var _column: int = 23
## Starter choisi (scénario « starter_choice »).
var _starter: StringName = &"charmander"
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
		elif arg.begins_with("--column="):
			_column = int(arg.trim_prefix("--column="))
		elif arg.begins_with("--starter="):
			_starter = StringName(arg.trim_prefix("--starter="))
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
	elif _scenario in ["starter_offer", "hop_styles", "starter_choice", "lab_exit"]:
		_boot.set(&"start_map", &"oak_lab")
		_boot.set(&"start_spawn", &"entrance")
		_boot.set(&"start_facing", Vector2i.UP)
		for action: StringName in MOVE_ACTIONS.values():
			InputMap.action_erase_events(action)
		InputMap.action_erase_events(&"run")
		InputMap.action_erase_events(&"interact")
	elif _scenario in ["route1_freeze", "route1_oak", "route1_full"]:
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
		elif _scenario == "route1_full":
			_router = root.get_node(^"SceneRouter")
			_run_route1_full()
		elif _scenario == "starter_offer":
			_router = root.get_node(^"SceneRouter")
			_run_starter_offer()
		elif _scenario == "hop_styles":
			_router = root.get_node(^"SceneRouter")
			_run_hop_styles()
		elif _scenario == "starter_choice":
			_router = root.get_node(^"SceneRouter")
			_run_starter_choice()
		elif _scenario == "lab_exit":
			_router = root.get_node(^"SceneRouter")
			_run_lab_exit()
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


# --- Scénario « route1_full » (jalon 3B, T4) ----------------------------------------

func _run_route1_full() -> void:
	var tag := "%d_" % _column
	var director: Node = _boot.call(&"get_cutscene_director")
	var runner: Node = _boot.call(&"get_dialogue_runner")
	await _frames(5)
	var map: Node = _boot.call(&"get_map")
	_player.call(&"enter_map", map.call(&"get_grid"), Vector2i(_column, 7), Vector2i.UP,
		map.call(&"get_pixel_rect"))
	await _frames(20)
	await _hold_up_until_scene(director)
	await _frames(2)
	await _t4_shot(tag + "01_freeze")
	await _page_complete()
	await _t4_shot(tag + "02_call")
	await _finish_dialogue()
	# Chen apparaît hors de l'écran, puis entre en courant.
	var oak: Node2D = null
	for i: int in NPCS_TIMEOUT:
		oak = _boot.call(&"get_map").call(&"get_npc", &"oak")
		if oak != null and (oak.call(&"get_cell") as Vector2i).y <= 10:
			break
		await process_frame
	await _t4_shot(tag + "03_oak_enters")
	var lines: Array[String] = ["04_oak_line1", "05_oak_line2_grass", "06_oak_line3",
		"07_oak_line4"]
	await _dialogue_shots(runner, tag, lines)
	# Suivi : deux images en chemin.
	var follow: Dictionary[int, String] = {5: "08_follow_start", 8: "09_follow_middle"}
	for i: int in NPCS_TIMEOUT:
		if follow.is_empty() or _router.call(&"is_transitioning"):
			break
		var row: int = (_player.call(&"get_cell") as Vector2i).y
		if follow.has(row) and _player.call(&"is_moving"):
			await _t4_shot(tag + follow[row])
			follow.erase(row)
		await process_frame
	# Fondu, puis arrivée au labo.
	for i: int in NPCS_TIMEOUT:
		if _router.call(&"is_transitioning"):
			break
		await process_frame
	await _frames(6)
	await _t4_shot(tag + "10_fade")
	for i: int in NPCS_TIMEOUT:
		if not _router.call(&"is_transitioning"):
			break
		await process_frame
	await _t4_shot(tag + "11_lab_arrival")
	# Le rival regarde Chen (haut), puis le joueur (gauche).
	var lab: Node = _boot.call(&"get_map")
	var rival: Node = lab.call(&"get_npc", &"rival")
	var looks: Dictionary[Vector2i, String] = {
		Vector2i.UP: "12_rival_looks_oak", Vector2i.LEFT: "13_rival_looks_player",
	}
	for i: int in NPCS_TIMEOUT:
		if looks.is_empty() or runner.call(&"is_running") or rival == null:
			break
		var facing: Vector2i = rival.call(&"get_facing")
		if looks.has(facing):
			await _frames(4)
			await _t4_shot(tag + looks[facing])
			looks.erase(facing)
		await process_frame
	await _dialogue_shots(runner, tag, ["14_enfin", "15_patience", "16_une_heure",
		"17_toujours_la"])
	# Jalon 4 (T1) : la proposition de Chen.
	await _dialogue_shots(runner, tag, ["17b_offer_1", "17c_offer_2", "17d_offer_3_table",
		"17e_offer_4"])
	for i: int in NPCS_TIMEOUT:
		if not director.call(&"is_running"):
			break
		await process_frame
	await _frames(10)
	await _t4_shot(tag + "18_control_back")
	# Maya : la nouvelle réplique.
	await _go(Vector2i(5, 4))
	_player.call(&"face", Vector2i.UP)
	await _frames(6)
	await _interact()
	await _dialogue_shots(runner, tag, ["19_maya_1", "20_maya_2"])
	# Sortie, puis la maison du rival : personne.
	await _go(Vector2i(7, 9))
	await _push_through(Vector2i.DOWN)
	await _go_through(Vector2i(11, 9), true)
	await _t4_shot(tag + "21_rival_house_empty")
	await _go(Vector2i(14, 4))
	await _frames(6)
	await _t4_shot(tag + "22_rival_room_empty")
	await _go(Vector2i(9, 9))
	await _push_through(Vector2i.DOWN)
	# Les herbes restent fermées : la pensée, puis le recul.
	await _go(Vector2i(_column, 5), true)
	await _frames(6)
	await _hold_up_until_scene(director)
	await _page_complete()
	await _t4_shot(tag + "23_thought")
	await _finish_dialogue()
	for i: int in NPCS_TIMEOUT:
		if not director.call(&"is_running"):
			break
		await process_frame
	await _frames(10)
	await _t4_shot(tag + "24_after_recoil")
	await _frames(5)
	print("ROUTE1_FULL terminé (frame %d)" % _frame)
	quit()


## Une capture par page complète du dialogue en cours ([param names] : une par page),
## avance entre les pages, puis termine le dialogue.
func _dialogue_shots(runner: Node, tag: String, names: Array[String]) -> void:
	for i: int in NPCS_TIMEOUT:
		if runner.call(&"is_running"):
			break
		await process_frame
	for page: int in names.size():
		await _page_complete()
		await _t4_shot(tag + names[page])
		if page < names.size() - 1:
			await _interact()
	await _finish_dialogue()


func _t4_shot(capture_name: String) -> void:
	var hud: Node = _boot.call(&"get_hud")
	var map: Node = _boot.call(&"get_map")
	var box: Node = _boot.call(&"get_dialogue_box")
	var who: Array[String] = []
	for id: StringName in [&"oak", &"rival"]:
		var npc: Node = map.call(&"get_npc", id)
		if npc != null:
			who.append("%s %s %s" % [id, npc.call(&"get_cell"), npc.call(&"get_facing")])
	print("  contrôles visibles : %s ; boîte : %s « %s » ; %s" % [
		hud.call(&"are_controls_visible"), box.call(&"is_open"),
		box.call(&"get_speaker_text"), ", ".join(who)])
	_mark(T4_PREFIX + capture_name)
	await _frames(2)


# --- Scénarios « starter_offer » et « hop_styles » (jalon 4, T1) --------------------

## Au labo : drapeau oak_met levé, PNJ ajustés (Chen et le rival apparaissent).
func _lab_with_oak() -> Node:
	await _frames(5)
	var state: Node = root.get_node(^"GameState")
	(state.get(&"flags") as RefCounted).call(&"set_flag", &"oak_met")
	var lab: Node = _boot.call(&"get_map")
	lab.call(&"refresh_npcs", state.get(&"flags"))
	await _frames(10)
	return lab


func _run_starter_offer() -> void:
	var lab: Node = await _lab_with_oak()
	var director: Node = _boot.call(&"get_cutscene_director")
	var runner: Node = _boot.call(&"get_dialogue_runner")
	if not _add_offer_scene():
		quit(1)
		return
	await _offer_shot("01_lab_entrance")
	if not director.call(&"play", OFFER_SCENE):
		push_error("starter_offer : scène refusée")
		quit(1)
		return
	await _dialogue_shots_with(runner, OFFER_PREFIX, ["02_enfin", "03_patience",
		"04_une_heure", "05_toujours_la"])
	await _dialogue_shots_with(runner, OFFER_PREFIX, ["06_offer_1", "07_offer_2",
		"08_offer_3_table", "09_offer_4"])
	for i: int in NPCS_TIMEOUT:
		if not director.call(&"is_running"):
			break
		await process_frame
	await _frames(10)
	var flags: RefCounted = root.get_node(^"GameState").get(&"flags")
	print("  starter_offered : %s" % flags.call(&"has_flag", &"starter_offered"))
	await _offer_shot("10_control_back")
	# Un starter s'observe encore : Salamèche, depuis (11, 6).
	await _go(Vector2i(11, 6))
	_player.call(&"face", Vector2i.UP)
	await _frames(12)
	await _offer_shot("11_observe_button")
	await _interact()
	await _page_complete()
	await _offer_shot("12_observe_charmander")
	await _finish_dialogue()
	await _frames(5)
	print("STARTER_OFFER terminé (frame %d)" % _frame)
	quit()


## Ajoute à la bibliothèque de Boot la fin réelle de la variante 1 de route1_grass.
func _add_offer_scene() -> bool:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(PROLOGUE_PATH)) != OK:
		push_error("starter_offer : %s illisible" % PROLOGUE_PATH)
		return false
	var steps: Array = json.data["route1_grass"]["variants"][0]["steps"]
	var tail: Array = []
	var after_change := false
	for step: Dictionary in steps:
		if after_change:
			tail.append(step)
		elif step.has("change_map"):
			after_change = true
	var library: RefCounted = _boot.call(&"get_cutscene_library")
	return library.call(&"add_from_dict", {String(OFFER_SCENE): {"steps": tail}}, "capture")


## Comme _dialogue_shots, avec un préfixe de capture.
func _dialogue_shots_with(runner: Node, prefix: String, names: Array[String]) -> void:
	for i: int in NPCS_TIMEOUT:
		if runner.call(&"is_running"):
			break
		await process_frame
	for page: int in names.size():
		await _page_complete()
		await _offer_shot(names[page], prefix)
		if page < names.size() - 1:
			await _interact()
	await _finish_dialogue()


func _offer_shot(capture_name: String, prefix: String = OFFER_PREFIX) -> void:
	var hud: Node = _boot.call(&"get_hud")
	var map: Node = _boot.call(&"get_map")
	var box: Node = _boot.call(&"get_dialogue_box")
	var who: Array[String] = []
	for id: StringName in [&"oak", &"rival", &"bulbasaur", &"charmander", &"squirtle"]:
		var npc: Node = map.call(&"get_npc", id)
		if npc != null:
			who.append("%s %s %s" % [id, npc.call(&"get_cell"), npc.call(&"get_facing")])
	print("  contrôles visibles : %s ; boîte : %s « %s » « %s » ; %s" % [
		hud.call(&"are_controls_visible"), box.call(&"is_open"),
		box.call(&"get_speaker_text"), box.call(&"get_text"), ", ".join(who)])
	_mark(prefix + capture_name)
	await _frames(2)


func _run_hop_styles() -> void:
	var lab: Node = await _lab_with_oak()
	var npc_script: Script = load("res://game/world/npc/npc.gd")
	await _offer_shot("00_on_table", HOP_PREFIX)
	for hop: Array in HOPS:
		var npc: Node2D = lab.call(&"get_npc", hop[0])
		var style: StringName = (npc.call(&"get_spec") as RefCounted).get(&"hop_style")
		var params: Dictionary = npc_script.call(&"hop_params", style)
		var before := float(params["hesitate"]) + float(params["windup"])
		var flight := float(params["duration"])
		# Images (30 images/s) : élan (fin de l'hésitation), sommet, rebond, posé.
		var shots: Dictionary[int, String] = {
			maxi(1, roundi(before * 0.5 * 30.0)): "a_before",
			roundi((before + flight * 0.5) * 30.0): "b_peak",
			roundi((before + flight + 0.05) * 30.0): "c_landing",
		}
		var tag := "%s_" % style
		if not npc.call(&"hop_to", hop[1], lab.call(&"get_grid")):
			push_error("hop_styles : saut de %s refusé" % hop[0])
			quit(1)
			return
		var frame := 0
		while npc.call(&"is_hopping") and frame < NPCS_TIMEOUT:
			await process_frame
			frame += 1
			if shots.has(frame):
				await _hop_shot(npc, tag + shots[frame])
				frame += 2
		await _frames(10)
		print("  %s posé en %s, lift %s" % [hop[0], npc.call(&"get_cell"),
			npc.call(&"get_lift")])
		await _hop_shot(npc, tag + "d_after")
	await _frames(10)
	await _offer_shot("zz_all_three", HOP_PREFIX)
	print("HOP_STYLES terminé (frame %d)" % _frame)
	quit()


func _hop_shot(npc: Node2D, capture_name: String) -> void:
	var sprite := npc.get_node(^"%Sprite") as Node2D
	print("  %s : pos %s sprite %s échelle %s rot %.1f° z %d" % [npc.name, npc.position,
		sprite.position, sprite.scale, rad_to_deg(sprite.rotation), npc.z_index])
	_mark(HOP_PREFIX + capture_name)
	await _frames(2)


# --- Scénarios « starter_choice » et « lab_exit » (jalon 4, T3) ---------------------------

## Au labo pendant le choix : oak_met, oak_lab_reunion, puis starter_offered (légende).
func _lab_in_choice() -> Node:
	var lab: Node = await _lab_with_oak()
	var flags: RefCounted = root.get_node(^"GameState").get(&"flags")
	flags.call(&"set_flag", &"oak_lab_reunion")
	flags.call(&"set_flag", &"starter_offered")
	return lab


func _run_starter_choice() -> void:
	var prefix := "%s%s_" % [T3_CHOICE_PREFIX, _starter]
	var lab: Node = await _lab_in_choice()
	var director: Node = _boot.call(&"get_cutscene_director")
	var runner: Node = _boot.call(&"get_dialogue_runner")
	var sheet: Node = _boot.call(&"get_starter_sheet")
	var offer: RefCounted = _boot.call(&"get_starter_offer")
	var data: RefCounted = _boot.call(&"get_pokemon_data")
	var mine: Node2D = lab.call(&"get_npc", _starter)
	var rival_species: StringName = offer.call(&"rival_pick", _starter, data)
	var theirs: Node2D = lab.call(&"get_npc", rival_species)
	if mine == null or theirs == null:
		push_error("starter_choice : starter inconnu « %s »" % _starter)
		quit(1)
		return
	await _frames(20)
	await _offer_shot("01_caption", prefix)
	var meet: Vector2i = (mine.call(&"get_cell") as Vector2i) + Vector2i.DOWN
	await _go(meet)
	_player.call(&"face", Vector2i.UP)
	await _frames(14)
	await _offer_shot("02_meet_button", prefix)
	await _interact()
	await _frames(18)
	await _offer_shot("03_sheet", prefix)
	(sheet.call(&"get_choose_button") as BaseButton).pressed.emit()
	await _hop_shots(mine, prefix, "04_hop_mid", "05_hop_landed")
	await _dialogue_shots_with(runner, prefix, ["06_reciprocal"])
	await _wait_step(director, {"face": "rival", "to": "$rival_starter"})
	await _frames(10)
	await _offer_shot("07_rival_looks_table", prefix)
	await _dialogue_shots_with(runner, prefix, ["08_pick"])
	await _hop_shots(theirs, prefix, "09_rival_hop_mid", "10_rival_hop_landed")
	var rival: Node2D = lab.call(&"get_npc", &"rival")
	for i: int in NPCS_TIMEOUT:
		if rival.call(&"is_moving"):
			break
		await process_frame
	await _frames(12)
	await _offer_shot("11_leaving", prefix)
	await _dialogue_shots_with(runner, prefix, ["12_wait"])
	await _wait_step(director, {"face": "rival", "to": "$player_starter"})
	await _frames(10)
	await _offer_shot("13_rival_looks_mine", prefix)
	await _dialogue_shots_with(runner, prefix, ["14_challenge"])
	for i: int in NPCS_TIMEOUT:
		if not director.call(&"is_running"):
			break
		await process_frame
	await _frames(15)
	var state: Node = root.get_node(^"GameState")
	print("  équipe : %d, starter : %s, drapeaux : %s" % [
		(state.get(&"party") as RefCounted).call(&"size"), state.get(&"starter_species"),
		(state.get(&"flags") as RefCounted).call(&"to_array")])
	await _offer_shot("15_control_back", prefix)
	print("STARTER_CHOICE terminé (frame %d)" % _frame)
	quit()


## Capture au sommet du saut de [param npc], puis une fois posé (rebonds compris).
func _hop_shots(npc: Node2D, prefix: String, mid: String, landed: String) -> void:
	for i: int in NPCS_TIMEOUT:
		if npc.call(&"is_hopping"):
			break
		await process_frame
	var npc_script: Script = load("res://game/world/npc/npc.gd")
	var style: StringName = (npc.call(&"get_spec") as RefCounted).get(&"hop_style")
	var params: Dictionary = npc_script.call(&"hop_params", style)
	var peak := float(params["hesitate"]) + float(params["windup"]) \
		+ float(params["duration"]) * 0.5
	await _frames(maxi(1, roundi(peak * 30.0) - 1))
	var sprite := npc.get_node(^"%Sprite") as Node2D
	print("  %s en vol : pos %s sprite %s" % [npc.name, npc.position, sprite.position])
	await _offer_shot(mid, prefix)
	for i: int in NPCS_TIMEOUT:
		if not npc.call(&"is_hopping"):
			break
		await process_frame
	await _frames(6)
	await _offer_shot(landed, prefix)


## Attend le début de l'étape de la scène du choix égale à [param wanted] (lue dans
## data/cutscenes/starter.json).
func _wait_step(director: Node, wanted: Dictionary) -> void:
	var json := JSON.new()
	json.parse(FileAccess.get_file_as_string(STARTER_PATH))
	var steps: Array = json.data["starter_chosen"]["steps"]
	var index := -1
	for i: int in steps.size():
		if steps[i] == wanted:
			index = i
			break
	for i: int in NPCS_TIMEOUT:
		if int(director.call(&"get_step_index")) >= index:
			return
		await process_frame


func _run_lab_exit() -> void:
	var prefix := T3_CHOICE_PREFIX + "exit_"
	await _lab_in_choice()
	var runner: Node = _boot.call(&"get_dialogue_runner")
	var director: Node = _boot.call(&"get_cutscene_director")
	await _go(Vector2i(7, 8))
	await _frames(40)
	await _offer_shot("01_above_mat", prefix)
	_hold(Vector2i.DOWN)
	for i: int in NPCS_TIMEOUT:
		if runner.call(&"is_running"):
			break
		await process_frame
	_release_moves()
	await _dialogue_shots_with(runner, prefix, ["02_pas_si_vite"])
	for i: int in NPCS_TIMEOUT:
		if not director.call(&"is_running"):
			break
		await process_frame
	await _frames(15)
	print("  carte : %s" % (_boot.call(&"get_map") as Node).get(&"map_id"))
	await _offer_shot("03_recoil", prefix)
	print("LAB_EXIT terminé (frame %d)" % _frame)
	quit()
