extends GutTest
## Coupe sur les deux arbustes du J17 (T23, `jalon-17.md` §2.13 ; dossier 20 §3.4, §3.5), avec la
## vraie scène Boot, les vraies cartes et les vraies entrées (`interact`, `move_*`) ; mécanisme du
## J16 tel quel (examen à variantes « field », COUPER → scène `cut_tree_*`, drapeau définitif) :
## - couloir de la Route 2 est : sans CS01 (ARB-00), CS01 sans Badge Cascade (ARB-01), aucun
##   Pokémon compatible (ARB-02), prêt (ARB-03 → COUPER, ARB-04) ; LAISSER ne coupe rien ;
##   coupé : on passe au sud, et l'arbuste reste coupé après sauvegarde et relance ;
## - FUTUR A : texte T7 du dossier 11 sans CS01, textes du J16 dès la CS01 ; coupé : la clairière
##   et sa Super Potion sont atteintes.
## Départs `route_2_east_cut` et `route_2_futur_a_cut` (Salamèche N22 en tête, compatible).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START_EAST := "res://tools/debug_start/route_2_east_cut.json"
const START_FUTUR_A := "res://tools/debug_start/route_2_futur_a_cut.json"
const SAVE_PATH := "user://test_j17_bushes_save.json"
const TIMEOUT := 12.0
const FADE := 0.05
const WALK_STOP := &"test_walk_stop"
const EAST_FLAG := &"cut_route_2_east_bush"
const FUTUR_A_FLAG := &"cut_route_2_futur_a"
const EAST_BUSH: Array[Vector2i] = [Vector2i(6, 21), Vector2i(7, 21)]
const NORTH_OF_BUSH := Vector2i(6, 20)
const SOUTH_OF_BUSH := Vector2i(6, 23)
const FUTUR_A := Vector2i(4, 19)
const EAST_OF_FUTUR_A := Vector2i(5, 19)
const CLEARING := Vector2i(2, 19)
const POTION_NPC := &"route_2_item_5"
const POTION_CELL := Vector2i(1, 17)
const ARB_00 := "Un arbuste barre le passage.\nIl faudrait savoir le couper."
const ARB_01 := "Sans le Badge Cascade, Salamèche\nn'ose pas couper cet arbuste."
const ARB_02 := "Aucun Pokémon de l'équipe\nne peut couper cet arbuste."
const ARB_03: Array[String] = ["Salamèche peut couper cet arbuste.", "Utiliser Coupe ?"]
const ARB_03_04: Array[String] = [
	"Salamèche peut couper cet arbuste.", "Utiliser Coupe ?", "Salamèche utilise Coupe !"]
const T7 := "Les branches sont trop épaisses. Impossible de passer par ici."

var _boot: Boot
var _player: Player
var _fs: MemoryFs
var _saved_router: Array = []
var _pages: Array[String] = []
var _stop_at := Vector2i(-1, -1)
var _held: StringName = &""


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_fs = MemoryFs.new()
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


# --- Aides ---------------------------------------------------------------------------------

## Boot sur le départ [param path] ; [param change] (func() -> void) retouche la partie avant
## que la carte relise ses drapeaux (CS retirée, badge absent, équipe réduite).
func _start(path: String, change: Callable = Callable()) -> void:
	var start := DebugStart.new()
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	assert_true(start.load_file(path, data, items), "\n".join(start.get_errors()))
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = start.map
	_boot.start_spawn = start.spawn
	_boot.start_facing = start.facing
	add_child_autofree(_boot)
	await _attach()
	start.apply(GameState, _boot.get_pokemon_data())
	_boot.get_encounter_director().enabled = false
	if change.is_valid():
		change.call()
	_boot.get_map().refresh_npcs(GameState.flags)
	_boot.get_map().apply_flag_gates(GameState.flags)
	assert_eq(_boot.get_map().map_id, start.map)
	assert_eq(_player.get_cell(), _boot.get_map().get_spawn_cell(start.spawn))


## Fermeture puis réouverture de l'application sur le disque en mémoire : Boot lit la sauvegarde.
func _relaunch() -> void:
	_boot.queue_free()
	await wait_process_frames(2)
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	add_child_autofree(_boot)
	await _attach()
	_boot.get_encounter_director().enabled = false


func _attach() -> void:
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_dialogue_runner().page_started.connect(_on_page_started)
	_player.moved.connect(_on_player_moved)
	await wait_until(func() -> bool:
		return is_instance_valid(_boot.get_map()) and not SceneRouter.is_transitioning(),
		TIMEOUT)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _on_page_started(_index: int) -> void:
	_pages.append(_boot.get_dialogue_box().get_text())


func _on_player_moved(cell: Vector2i) -> void:
	if cell == _stop_at and not _held.is_empty():
		Input.action_release(_held)
		_held = &""
		_player.set_input_enabled(false, WALK_STOP)


## Examine la case devant le joueur tourné vers [param facing] ; aux cartes COUPER / LAISSER,
## répond [param confirm]. Joue tout (dialogue, scène) et rend les pages lues.
func _examine(facing: Vector2i, confirm: bool = true) -> Array[String]:
	_pages.clear()
	_player.face(facing)
	await wait_process_frames(1)
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var deadline := Time.get_ticks_msec() + 30000
	while (director.is_running() or runner.is_running() or box.is_open()) \
			and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_choice_showing():
			var cards := box.get_choice_cards()
			var button := cards.get_confirm_button() if confirm else cards.get_cancel_button()
			button.pressed.emit()
		elif box.is_open() and not runner.is_awaiting_choice():
			box.advance_requested.emit()
	await wait_process_frames(3)
	var pages: Array[String] = []
	pages.assign(_pages)
	return pages


## Marche vers [param direction] jusqu'à [param until] (arrêt net sur la case).
func _walk(direction: Vector2i, until: Vector2i) -> void:
	_stop_at = until
	_held = {Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
		Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right"}[direction]
	Input.action_press(_held)
	await wait_until(func() -> bool:
		return _player.get_cell() == until or not _player.is_input_enabled(), 8.0)
	await wait_process_frames(1)
	if not _held.is_empty():
		Input.action_release(_held)
		_held = &""
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	_player.set_input_enabled(true, WALK_STOP)


## Pousse vers [param direction] contre une case occupée : le joueur ne bouge pas.
func _bump(direction: Vector2i) -> void:
	var from := _player.get_cell()
	var action: StringName = {Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
		Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right"}[direction]
	Input.action_press(action)
	await wait_process_frames(30)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_eq(_player.get_cell(), from, "bloqué par l'arbuste")


func _gate(map_node: String) -> FlagGate:
	return _boot.get_map().get_node(NodePath(map_node)) as FlagGate


func _without_hm() -> void:
	GameState.bag.remove(&"hm01")


func _without_badge() -> void:
	GameState.flags.set_flag(&"badge_cascade", false)


## Salamèche retiré : Roucool, Rattata, Piafabec, Nidoran♀, Férosinge, aucun ne coupe.
func _without_compatible() -> void:
	GameState.party.remove_at(0)


func _save_now() -> void:
	var writes := _writes()
	_boot.request_autosave("test")
	await wait_until(func() -> bool: return _writes() > writes, TIMEOUT)
	assert_gt(_writes(), writes, "sauvegarde écrite")


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


# --- Couloir de la Route 2 est ---------------------------------------------------------------

func test_corridor_bush_without_hm01_says_arb_00() -> void:
	await _start(START_EAST, _without_hm)
	assert_eq(await _examine(Vector2i.DOWN), [ARB_00] as Array[String])
	assert_false(GameState.flags.has_flag(EAST_FLAG))
	assert_true(_gate("Entities/CorridorBush").visible)
	await _bump(Vector2i.DOWN)
	assert_push_error_count(0)


func test_corridor_bush_without_the_cascade_badge_says_arb_01() -> void:
	await _start(START_EAST, _without_badge)
	assert_eq(await _examine(Vector2i.DOWN), [ARB_01] as Array[String])
	assert_false(GameState.flags.has_flag(EAST_FLAG))
	await _bump(Vector2i.DOWN)
	assert_push_error_count(0)


func test_corridor_bush_without_a_compatible_pokemon_says_arb_02() -> void:
	await _start(START_EAST, _without_compatible)
	assert_eq(await _examine(Vector2i.DOWN), [ARB_02] as Array[String])
	assert_false(GameState.flags.has_flag(EAST_FLAG))
	assert_push_error_count(0)


func test_corridor_bush_left_alone_stays() -> void:
	await _start(START_EAST)
	assert_eq(await _examine(Vector2i.DOWN, false), ARB_03, "ARB-03 puis LAISSER")
	assert_false(GameState.flags.has_flag(EAST_FLAG), "LAISSER : rien n'est coupé")
	assert_true(_gate("Entities/CorridorBush").visible)
	await _bump(Vector2i.DOWN)
	assert_push_error_count(0)


func test_corridor_bush_cut_opens_the_south_for_good_even_after_a_relaunch() -> void:
	await _start(START_EAST)
	var pages := await _examine(Vector2i.DOWN)
	assert_eq(pages, ARB_03_04, "ARB-03, COUPER, ARB-04")
	assert_true(GameState.flags.has_flag(EAST_FLAG), "arbuste coupé")
	var map := _boot.get_map()
	assert_false(_gate("Entities/CorridorBush").visible, "arbuste retiré")
	for cell: Vector2i in EAST_BUSH:
		assert_false(map.get_grid().is_occupied(cell), "case %s libérée" % cell)
	# Plus rien à examiner là où était l'arbuste.
	assert_eq(await _examine(Vector2i.DOWN), [] as Array[String], "plus d'examen")
	# Passage : le sud du couloir, puis la clairière de la Pierre Lune.
	await _walk(Vector2i.DOWN, SOUTH_OF_BUSH)
	assert_eq(_player.get_cell(), SOUTH_OF_BUSH, "sud du couloir atteint")
	var reach := map.get_grid().find_reachable(SOUTH_OF_BUSH)
	assert_true(reach.has(Vector2i(0, 43)), "bord ouest atteignable")
	assert_true(reach.has(Vector2i(12, 27)), "Pierre Lune atteignable (case du dessous)")
	# Sauvegarde, fermeture, relance : toujours coupé, toujours libre.
	await _save_now()
	await _relaunch()
	assert_eq(_boot.get_map().map_id, &"route_2_east", "reprise dans le couloir")
	assert_eq(_player.get_cell(), SOUTH_OF_BUSH)
	assert_true(GameState.flags.has_flag(EAST_FLAG), "drapeau relu")
	assert_false(_gate("Entities/CorridorBush").visible, "toujours coupé")
	for cell: Vector2i in EAST_BUSH:
		assert_false(_boot.get_map().get_grid().is_occupied(cell), "%s toujours libre" % cell)
	await _walk(Vector2i.UP, NORTH_OF_BUSH)
	assert_eq(_player.get_cell(), NORTH_OF_BUSH, "retour au nord par le goulet")
	assert_push_error_count(0)


# --- FUTUR A (Route 2 sud) -------------------------------------------------------------------

func test_futur_a_keeps_the_t7_text_without_hm01() -> void:
	await _start(START_FUTUR_A, _without_hm)
	assert_eq(await _examine(Vector2i.LEFT), [T7] as Array[String], "texte T7 du dossier 11")
	assert_false(GameState.flags.has_flag(FUTUR_A_FLAG))
	await _bump(Vector2i.LEFT)
	assert_push_error_count(0)


func test_futur_a_takes_the_j16_texts_with_hm01() -> void:
	await _start(START_FUTUR_A, _without_badge)
	assert_eq(await _examine(Vector2i.LEFT), [ARB_01] as Array[String], "CS01 sans Cascade")
	GameState.flags.set_flag(&"badge_cascade")
	GameState.party.remove_at(0)
	assert_eq(await _examine(Vector2i.LEFT), [ARB_02] as Array[String], "aucun compatible")
	assert_false(GameState.flags.has_flag(FUTUR_A_FLAG))
	assert_push_error_count(0)


func test_futur_a_cut_reaches_the_clearing_and_its_super_potion() -> void:
	await _start(START_FUTUR_A)
	var map := _boot.get_map()
	assert_false(map.get_grid().find_reachable(EAST_OF_FUTUR_A).has(CLEARING),
		"clairière fermée avant la coupe")
	var pages := await _examine(Vector2i.LEFT)
	assert_eq(pages, ARB_03_04, "ARB-03, COUPER, ARB-04")
	assert_true(GameState.flags.has_flag(FUTUR_A_FLAG))
	assert_false(_gate("Entities/FuturABush").visible, "arbuste retiré")
	assert_false(map.get_grid().is_occupied(FUTUR_A), "case libérée")
	await _walk(Vector2i.LEFT, CLEARING)
	assert_eq(_player.get_cell(), CLEARING, "dans la clairière")
	assert_not_null(map.get_npc(POTION_NPC), "Super Potion au fond de la clairière")
	assert_true(map.get_grid().find_reachable(CLEARING).has(POTION_CELL + Vector2i.DOWN),
		"Super Potion atteignable")
	assert_push_error_count(0)
