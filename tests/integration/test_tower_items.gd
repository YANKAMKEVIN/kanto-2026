extends GutTest
## Objets des étages 3F à 6F de la Tour Pokémon (jalon 19, T18 ; `jalon-19.md` §2.9, dossier 22
## §4) sur le vrai Boot et les vraies cartes :
## - cinq objets visibles (Corde Sortie 3F, Réveil et Super Potion 4F, Pépite 5F, Super Potion
##   6F) : PRENDRE, toast, Sac, journal, drapeau `got_<id>`, absents au rechargement ;
## - objet caché du 5F (Super Potion, « offrande fanée » en (4, 11), la grille fait foi sur le
##   dossier §4.2) : EXAMINER seulement face à l'indice, toast « Super Potion ×1 », plus rien
##   ensuite ni après un rechargement (modèle de `test_hidden_items`).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/tower_5f_zone.json"
const SAVE_PATH := "user://test_tower_items_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
## [étage, carte, spawn, identifiant, case, objet, toast].
const ITEMS: Array = [
	["3f", &"pokemon_tower_3f", &"arrivee_T23", &"tower_3f_objet_1", Vector2i(12, 1),
		&"escape_rope", "Corde Sortie ×1"],
	["4f", &"pokemon_tower_4f", &"arrivee_T34", &"tower_4f_objet_1", Vector2i(9, 10),
		&"awakening", "Réveil ×1"],
	["4f", &"pokemon_tower_4f", &"arrivee_T34", &"tower_4f_objet_2", Vector2i(12, 10),
		&"elixir", "Élixir ×1"],  # lot 32P : Élixir RB (repli Super Potion de K-17 défait),
	["5f", &"pokemon_tower_5f", &"arrivee_T45", &"tower_5f_objet_1", Vector2i(6, 14),
		&"nugget", "Pépite ×1"],
	["6f", &"pokemon_tower_6f", &"arrivee_T56", &"tower_6f_objet_1", Vector2i(14, 14),
		&"super_potion", "Super Potion ×1"],
]
const HIDDEN_ID := "tower_5f_cache_1"
const HIDDEN_CLUE := Vector2i(4, 11)
const HIDDEN_STAND := Vector2i(4, 10)

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _toasts: Array[PackedStringArray] = []
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-19T14:00:00")
	_fs = MemoryFs.new()
	_toasts.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


func _start(map_id: StringName, spawn: StringName, fresh: bool = true) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map_id
	_boot.start_spawn = spawn
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		var data := DebugStart.new()
		assert_true(data.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(data.get_errors()))
		data.apply(GameState, _boot.get_pokemon_data())
		_boot.get_map().refresh_npcs(GameState.flags)
		_boot.get_companion_controller().refresh()
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_toasts.append(PackedStringArray([title, detail])))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)


func _reload(map_id: StringName, spawn: StringName) -> void:
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	_toasts.clear()
	await _start(map_id, spawn, false)


func _put(cell: Vector2i, facing: Vector2i) -> void:
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


func _finish_scene() -> void:
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)  # temps réel : délai de garde
	while (director.is_running() or _runner.is_running()) \
			and Time.get_ticks_msec() < deadline:  # temps réel : délai de garde
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "scène finie")
	await wait_process_frames(5)


func _found(item: String, map_id: String) -> int:
	var count := 0
	for entry: Dictionary in GameState.found_items:
		if entry["item"] == item and entry["map"] == map_id:
			count += 1
	return count


func _check_visible(entry: Array) -> void:
	var map_id: StringName = entry[1]
	var id: StringName = entry[3]
	var cell: Vector2i = entry[4]
	var item: StringName = entry[5]
	await _start(map_id, entry[2])
	var map := _boot.get_map()
	assert_not_null(map.get_npc(id), "%s au sol" % id)
	assert_eq(map.get_npc(id).get_cell(), cell, "case de la grille")
	var grid := map.get_grid()
	var stand := Vector2i(-1, -1)
	var facing := Vector2i.ZERO
	for direction: Vector2i in DIRECTIONS:
		if grid.is_free(cell - direction):
			stand = cell - direction
			facing = direction
			break
	assert_ne(stand, Vector2i(-1, -1), "une case d'où la prendre")
	await _put(stand, facing)
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target, "cible PRENDRE")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.TAKE, "verbe PRENDRE")
	var before := GameState.bag.count_of(item)
	await _press_interact()
	await wait_until(func() -> bool: return map.get_npc(id) == null, TIMEOUT)
	await _finish_scene()
	assert_null(map.get_npc(id), "objet retiré")
	assert_eq(GameState.bag.count_of(item), before + 1, "%s + 1" % item)
	assert_true(GameState.flags.has_flag(StringName("got_" + String(id))), "drapeau got_<id>")
	assert_eq(_found(String(item), String(map_id)), 1, "journal des objets trouvés")
	assert_eq(_toasts.size(), 1, "un toast")
	if _toasts.size() == 1:
		assert_eq(_toasts[0][0], entry[6], "toast")
	await _reload(map_id, entry[2])
	assert_null(_boot.get_map().get_npc(id), "absent au rechargement")
	assert_eq(GameState.bag.count_of(item), before + 1, "Sac inchangé au rechargement")
	assert_push_error_count(0)


func test_3f_escape_rope_in_the_north_alcove() -> void:
	await _check_visible(ITEMS[0])


func test_4f_awakening() -> void:
	await _check_visible(ITEMS[1])


func test_4f_super_potion() -> void:
	await _check_visible(ITEMS[2])


func test_5f_nugget_in_the_south_west_corner() -> void:
	await _check_visible(ITEMS[3])


func test_6f_super_potion_in_the_pocket() -> void:
	await _check_visible(ITEMS[4])


func test_the_hidden_5f_super_potion_faces_its_offering_then_disappears() -> void:
	await _start(&"pokemon_tower_5f", &"arrivee_T45")
	var flag := StringName("got_" + HIDDEN_ID)
	var grid := _boot.get_map().get_grid()
	assert_true(grid.is_solid(HIDDEN_CLUE), "l'indice est bloquant")
	assert_false(grid.is_solid(HIDDEN_STAND), "le voisin (4, 10) est praticable")
	var controller := _boot.get_interaction_controller()
	await _put(HIDDEN_STAND, Vector2i.UP)
	assert_null(controller.get_target(), "de dos : rien")
	await _put(HIDDEN_STAND, Vector2i.LEFT)
	assert_null(controller.get_target(), "de côté : rien")
	await _put(HIDDEN_STAND, Vector2i.DOWN)
	var target := controller.get_target()
	assert_not_null(target, "face à l'indice : une cible")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.EXAMINE, "verbe EXAMINER")
	var before := GameState.bag.count_of(&"elixir")
	await _press_interact()
	await wait_until(func() -> bool: return GameState.flags.has_flag(flag), TIMEOUT)
	await _finish_scene()
	assert_eq(GameState.bag.count_of(&"elixir"), before + 1, "Sac + 1")
	assert_eq(_found("elixir", "pokemon_tower_5f"), 1, "journal des objets trouvés")
	assert_eq(_toasts.size(), 1, "un toast")
	if _toasts.size() == 1:
		assert_eq(_toasts[0], PackedStringArray(["Élixir ×1", "Ajouté au Sac"]))
	assert_null(controller.get_target(), "plus de cible une fois trouvé")
	await _reload(&"pokemon_tower_5f", &"arrivee_T45")
	await _put(HIDDEN_STAND, Vector2i.DOWN)
	assert_true(GameState.flags.has_flag(flag), "drapeau relu")
	assert_null(_boot.get_interaction_controller().get_target(), "rechargé : plus de cible")
	assert_eq(GameState.bag.count_of(&"elixir"), before + 1)
	assert_push_error_count(0)
