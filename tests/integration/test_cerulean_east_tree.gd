extends GutTest
## L'arbre à couper de la sortie est d'Azuria (jalon 18 T15, dossier 21 §9, I-2 ; `jalon-18.md`
## §4.4), avec la vraie scène Boot, les vraies cartes et les vraies entrées : mécanisme de Coupe
## du J16 tel quel (examen à variantes « field », COUPER → `cut_tree_cerulean_east`, drapeau
## `cut_cerulean_east_tree` définitif) :
## - sans CS01 : le texte 17 « On ne passe pas par là pour l'instant. », l'arbre bloque ;
## - LAISSER ne coupe rien ;
## - coupé : la case (53, 23) est libre, le raccord est mène à la Route 9 (`from_cerulean`) ;
##   au retour par la Route 9, l'arbre reste coupé.
## Départ `cerulean_east_cut` (Reptincel N25 en tête, compatible ; Badges Roche et Cascade).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/cerulean_east_cut.json"
const SAVE_PATH := "user://test_cerulean_east_tree_save.json"
const TIMEOUT := 12.0
const FADE := 0.05
const FLAG := &"cut_cerulean_east_tree"
const GATE := "Entities/EastTree"
const TREE := Vector2i(53, 23)
const BEYOND := Vector2i(55, 23)
const TEXT_17 := "On ne passe pas par là pour l'instant."
const READY: Array[String] = ["Reptincel peut couper cet arbuste.", "Utiliser Coupe ?"]
const READY_CUT: Array[String] = [
	"Reptincel peut couper cet arbuste.", "Utiliser Coupe ?", "Reptincel utilise Coupe !"]

var _boot: Boot
var _player: Player
var _fs: MemoryFs
var _saved_router: Array = []
var _pages: Array[String] = []


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

## Boot sur le départ ; [param change] (func() -> void) retouche la partie avant que la carte
## relise ses drapeaux.
func _start(change: Callable = Callable()) -> void:
	var start := DebugStart.new()
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	assert_true(start.load_file(START, data, items), "\n".join(start.get_errors()))
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = start.map
	_boot.start_spawn = start.spawn
	_boot.start_facing = start.facing
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_dialogue_runner().page_started.connect(_on_page_started)
	await _settle()
	start.apply(GameState, _boot.get_pokemon_data())
	_boot.get_encounter_director().enabled = false
	if change.is_valid():
		change.call()
	_boot.get_map().refresh_npcs(GameState.flags)
	_boot.get_map().apply_flag_gates(GameState.flags)
	assert_eq(_boot.get_map().map_id, &"cerulean_city")
	assert_eq(_player.get_cell(), TREE + Vector2i.LEFT, "devant l'arbre")


func _settle() -> void:
	await wait_until(func() -> bool:
		return is_instance_valid(_boot.get_map()) and not SceneRouter.is_transitioning(),
		TIMEOUT)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _on_page_started(_index: int) -> void:
	_pages.append(_boot.get_dialogue_box().get_text())


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


## Un pas scripté vers [param direction] (sans entrée tenue : jamais de pas de trop).
func _step(direction: Vector2i) -> void:
	assert_true(_player.script_step(direction), "pas %s" % direction)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


## Pousse vers [param direction] au bord de la carte : la touche est relâchée dès que la
## transition commence, puis on attend la nouvelle carte.
func _push(direction: Vector2i) -> void:
	var action: StringName = {Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right"}[direction]
	var from_id := _boot.get_map().map_id
	Input.action_press(action)
	await wait_until(func() -> bool: return SceneRouter.is_transitioning(), 8.0)
	Input.action_release(action)
	await wait_until(func() -> bool: return is_instance_valid(_boot.get_map()) \
		and _boot.get_map().map_id != from_id and not SceneRouter.is_transitioning(), TIMEOUT)
	await _settle()


## Pousse contre la case suivante (occupée) : le joueur ne bouge pas.
func _bump(direction: Vector2i) -> void:
	var from := _player.get_cell()
	Input.action_press(&"move_right" if direction == Vector2i.RIGHT else &"move_left")
	await wait_process_frames(30)
	Input.action_release(&"move_right")
	Input.action_release(&"move_left")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_eq(_player.get_cell(), from, "bloqué")


func _gate() -> FlagGate:
	return _boot.get_map().get_node(NodePath(GATE)) as FlagGate


# --- Tests -----------------------------------------------------------------------------------

func test_without_hm01_the_tree_says_text_17_and_blocks() -> void:
	await _start(func() -> void: GameState.bag.remove(&"hm01"))
	assert_eq(await _examine(Vector2i.RIGHT), [TEXT_17] as Array[String], "texte 17")
	assert_false(GameState.flags.has_flag(FLAG))
	assert_true(_gate().visible, "arbre debout")
	assert_true(_boot.get_map().get_grid().is_occupied(TREE), "case de l'arbre occupée")
	await _bump(Vector2i.RIGHT)
	assert_push_error_count(0)


func test_left_alone_the_tree_stays() -> void:
	await _start()
	assert_eq(await _examine(Vector2i.RIGHT, false), READY, "prêt, puis LAISSER")
	assert_false(GameState.flags.has_flag(FLAG), "LAISSER : rien n'est coupé")
	assert_true(_gate().visible)
	assert_push_error_count(0)


func test_cut_opens_route_9_and_the_tree_stays_cut_on_the_way_back() -> void:
	await _start()
	assert_eq(await _examine(Vector2i.RIGHT), READY_CUT, "prêt, COUPER, « utilise Coupe ! »")
	assert_true(GameState.flags.has_flag(FLAG), "arbre coupé")
	assert_false(_gate().visible, "arbre retiré")
	assert_false(_boot.get_map().get_grid().is_occupied(TREE), "case libérée")
	assert_eq(await _examine(Vector2i.RIGHT), [] as Array[String], "plus d'examen")
	assert_true(_boot.get_map().get_grid().find_reachable(TREE + Vector2i.LEFT).has(BEYOND),
		"raccord est atteignable")
	for i: int in 3:
		await _step(Vector2i.RIGHT)
	assert_eq(_player.get_cell(), BEYOND, "au bord est")
	await _push(Vector2i.RIGHT)
	assert_eq(_boot.get_map().map_id, &"route_9", "Route 9 chargée")
	assert_eq(_player.get_cell(), _boot.get_map().get_spawn_cell(&"from_cerulean"))
	await _push(Vector2i.LEFT)
	assert_eq(_boot.get_map().map_id, &"cerulean_city", "retour à Azuria")
	assert_eq(_player.get_cell(), BEYOND, "arrivée sur la même rangée")
	assert_false(_gate().visible, "l'arbre reste coupé")
	assert_false(_boot.get_map().get_grid().is_occupied(TREE))
	assert_push_error_count(0)
