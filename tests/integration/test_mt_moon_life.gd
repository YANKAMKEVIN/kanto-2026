extends GutTest
## La vie du Mont Sélénite (jalon 12, T21 ; `jalon-12.md` §2.7, §2.8, §2.22, dossier 15 §8.2,
## §11, §12, §20 n° 12–15) sur le vrai Boot, les vrais étages et les départs de débogage
## `mt_moon_*` : randonneur du 1F, panneau d'entrée, caisses et lampe du camp abandonné, Corde
## Sortie au sol (1F) et Potion (B1F), Réveil caché « face à un indice » (1F), rencontre sur les
## gravats de la vraie carte (pas sur le sol calme), compagnon des espèces de la série 14, reprise
## d'une partie quittée dans chaque étage.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_mt_moon_life_save.json"
const STARTS := "res://tools/debug_start/"
const FADE := 0.05
const TIMEOUT := 12.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const HIKER_CELL := Vector2i(34, 38)
const ROPE_CELL := Vector2i(9, 29)
const POTION_CELL := Vector2i(16, 21)
## Réveil caché : on se tient en (56, 19), l'indice (éclat clair) est en (57, 19).
const HIDDEN_STAND := Vector2i(56, 19)
const HIDDEN_CLUE := Vector2i(57, 19)
const HIDDEN_FLAG := &"got_mt_moon_1f_hidden_1"

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _toasts: Array[PackedStringArray] = []
var _dialogues: Array[StringName] = []
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-13T14:00:00")
	_fs = MemoryFs.new()
	_toasts.clear()
	_dialogues.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact", &"run"]:
		Input.action_release(action)
	get_tree().paused = false


## Boot sur [param start] (départ de débogage `tools/debug_start/<start>.json`) si [param fresh],
## sinon la partie en mémoire (rechargement).
func _start(start: String, fresh: bool = true) -> void:
	var data := DebugStart.new()
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	var path := STARTS + start + ".json"
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	_boot.start_map = StringName(json["map"])
	_boot.start_spawn = StringName(json["spawn"])
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		assert_true(data.load_file(path, _boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(data.get_errors()))
		data.apply(GameState, _boot.get_pokemon_data())
		_boot.get_companion_controller().refresh()
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_toasts.append(PackedStringArray([title, detail])))
	_runner.dialogue_started.connect(_dialogues.append)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)


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
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (director.is_running() or _runner.is_running()) \
			and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "scène finie")
	assert_false(_runner.is_running(), "dialogue fini")
	await wait_process_frames(5)


## Une case praticable voisine de [param cell] et l'orientation qui lui fait face.
func _approach(cell: Vector2i) -> Array:
	var grid := _boot.get_map().get_grid()
	for direction: Vector2i in DIRECTIONS:
		var stand := cell - direction
		if grid.is_free(stand) and _boot.get_map().get_warps().get_at(stand).is_empty():
			return [stand, direction]
	return []


func _pages(id: StringName) -> Array[String]:
	var texts: Array[String] = []
	for page: DialoguePage in _boot.get_dialogue_library().get_dialogue(id).variants[0].pages:
		texts.append(page.text)
	return texts


func _found(item: String, map_id: String) -> int:
	var count := 0
	for entry: Dictionary in GameState.found_items:
		if entry["item"] == item and entry["map"] == map_id:
			count += 1
	return count


## Examine [param cell] depuis une case voisine : le dialogue joué (vide si aucun).
func _examine(cell: Vector2i) -> StringName:
	var approach := _approach(cell)
	assert_false(approach.is_empty(), "%s : une case pour l'examiner" % cell)
	if approach.is_empty():
		return &""
	await _put(approach[0], approach[1])
	_dialogues.clear()
	await _press_interact()
	await wait_process_frames(3)
	var played: StringName = _dialogues[0] if not _dialogues.is_empty() else &""
	await _finish_scene()
	return played


# --- Randonneur, panneau, camp abandonné -------------------------------------------------------

func test_the_hiker_has_seen_people_in_black() -> void:
	await _start("mt_moon_1f")
	var hiker := _boot.get_map().get_npc(&"hiker")
	assert_not_null(hiker, "le randonneur près du puits de jour")
	if hiker == null:
		return
	assert_eq(hiker.get_cell(), HIKER_CELL)
	assert_eq(_pages(&"mt_moon_1f_hiker"), ["Des gens en noir fouillent plus bas.",
		"Je préfère ne pas savoir pourquoi."] as Array[String], "§20 n° 15")
	assert_eq(_boot.get_dialogue_library().get_dialogue(&"mt_moon_1f_hiker").speaker,
		"Randonneur")
	assert_eq(await _examine(HIKER_CELL), &"mt_moon_1f_hiker")
	assert_push_error_count(0)


func test_the_entrance_sign_and_the_abandoned_camp() -> void:
	await _start("mt_moon_1f")
	assert_eq(_pages(&"mt_moon_1f_sign"),
		["MONT SÉLÉNITE\nGaleries non éclairées. Prudence."] as Array[String], "§20 n° 12")
	assert_eq(_pages(&"mt_moon_1f_crate"), ["Une caisse marquée d'un R rouge.",
		"Elle est vide."] as Array[String], "§20 n° 13")
	assert_eq(_pages(&"mt_moon_1f_lamp"), ["Une lampe de chantier. Encore tiède."]
		as Array[String], "§20 n° 14")
	assert_eq(await _examine(Vector2i(26, 43)), &"mt_moon_1f_sign", "panneau de l'entrée")
	for crate: Vector2i in [Vector2i(4, 14), Vector2i(5, 14), Vector2i(4, 15)]:
		assert_eq(await _examine(crate), &"mt_moon_1f_crate", "caisse R %s" % crate)
	assert_eq(await _examine(Vector2i(10, 14)), &"mt_moon_1f_lamp", "lampe abandonnée")
	# Les traces de fouille restent un repère muet (indice sans texte).
	assert_eq(await _examine(Vector2i(4, 28)), &"", "tranchée : rien à lire")


# --- Objets visibles ----------------------------------------------------------------------------

func _take(npc_id: StringName, cell: Vector2i, item: StringName, flag: StringName,
		map_id: String) -> void:
	var map := _boot.get_map()
	assert_not_null(map.get_npc(npc_id), "%s au sol" % npc_id)
	var approach := _approach(cell)
	await _put(approach[0], approach[1])
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target, "cible PRENDRE")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.TAKE, "verbe PRENDRE")
	var before := GameState.bag.count_of(item)
	await _press_interact()
	await wait_until(func() -> bool: return map.get_npc(npc_id) == null, TIMEOUT)
	await _finish_scene()
	assert_null(map.get_npc(npc_id), "objet retiré")
	assert_eq(GameState.bag.count_of(item), before + 1, "%s + 1" % item)
	assert_true(GameState.flags.has_flag(flag), String(flag))
	assert_eq(_found(String(item), map_id), 1, "journal des objets trouvés")


func test_the_escape_rope_lies_on_the_ground_of_the_1f() -> void:
	await _start("mt_moon_1f")
	await _take(&"mt_moon_1f_ball_1", ROPE_CELL, &"escape_rope", &"got_mt_moon_1f_item_1",
		"mt_moon_1f")
	assert_eq(_toasts.size(), 1, "un toast")
	if _toasts.size() == 1:
		assert_eq(_toasts[0][0], "Corde Sortie ×1")
	# Rechargement : absente.
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start("mt_moon_1f", false)
	assert_null(_boot.get_map().get_npc(&"mt_moon_1f_ball_1"), "absente au rechargement")


func test_a_potion_in_the_b1f() -> void:
	await _start("mt_moon_b1f")
	await _take(&"mt_moon_b1f_ball_2", POTION_CELL, &"potion", &"got_mt_moon_b1f_item_2",
		"mt_moon_b1f")


# --- Réveil caché « face à un indice » ---------------------------------------------------------

func test_the_hidden_awakening_faces_its_clue_then_disappears() -> void:
	await _start("mt_moon_1f")
	var controller := _boot.get_interaction_controller()
	assert_true(_boot.get_map().get_grid().is_solid(HIDDEN_CLUE), "indice : case bloquée")
	await _put(HIDDEN_STAND, Vector2i.DOWN)
	assert_null(controller.get_target(), "de côté : rien")
	await _put(HIDDEN_STAND, Vector2i.LEFT)
	assert_null(controller.get_target(), "de dos : rien")
	await _put(HIDDEN_STAND, Vector2i.RIGHT)
	var target := controller.get_target()
	assert_not_null(target, "face à l'indice : EXAMINER (Q-2)")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.EXAMINE)
		assert_eq(target.dialogue_id, &"mt_moon_1f_hidden_1")
	var before := GameState.bag.count_of(&"awakening")
	await _press_interact()
	await wait_until(func() -> bool: return GameState.flags.has_flag(HIDDEN_FLAG), TIMEOUT)
	await _finish_scene()
	assert_eq(GameState.bag.count_of(&"awakening"), before + 1, "Réveil + 1")
	assert_eq(_found("awakening", "mt_moon_1f"), 1, "journal des objets trouvés")
	assert_eq(_toasts.size(), 1, "toast seul, aucune phrase nouvelle")
	if _toasts.size() == 1:
		assert_eq(_toasts[0][0], "Réveil ×1")
	await wait_process_frames(3)
	assert_null(controller.get_target(), "plus rien à examiner")
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start("mt_moon_1f", false)
	await _put(HIDDEN_STAND, Vector2i.RIGHT)
	assert_null(_boot.get_interaction_controller().get_target(), "ni après rechargement")
	assert_eq(GameState.bag.count_of(&"awakening"), before + 1, "trouvé une seule fois")


# --- Gravats sur la vraie carte ----------------------------------------------------------------

func test_encounters_only_on_the_real_rubble() -> void:
	await _start("mt_moon_1f")
	assert_true(_boot.get_encounter_library().override_table(&"mt_moon_1f", &"rubble",
		{"rate": 255, "slots": [{"species": "zubat", "levels": [9, 9], "weight": 1}]}, "test"))
	var encounters: Array[StringName] = []
	_boot.get_encounter_director().encounter_started.connect(
		func(species: StringName, _level: int) -> void: encounters.append(species))
	# G1 : bande obligatoire de la branche ouest (15..17, 21..28) ; on entre par le sol calme.
	var grid := _boot.get_map().get_grid()
	assert_true(grid.is_rubble(Vector2i(16, 24)), "G1 de la grille")
	assert_false(grid.is_rubble(Vector2i(18, 24)), "sol calme du carrefour")
	await _put(Vector2i(19, 24), Vector2i.LEFT)
	# Marche réelle (comme le joueur) : deux pas vers l'ouest, le sol calme puis les gravats.
	Input.action_press(&"move_left")
	await wait_until(func() -> bool: return _player.get_cell() == Vector2i(18, 24), TIMEOUT)
	assert_eq(encounters.size(), 0, "sol calme : aucune rencontre")
	await wait_until(func() -> bool: return _player.get_cell() == Vector2i(17, 24), TIMEOUT)
	Input.action_release(&"move_left")
	var director := _boot.get_encounter_director()
	await wait_until(func() -> bool: return encounters.size() > 0, TIMEOUT)
	assert_eq(encounters, [&"zubat"] as Array[StringName], "gravats : rencontre")
	assert_true(director.is_running() or _boot.get_battle_director().is_running())


# --- Compagnon des espèces de la série 14 ------------------------------------------------------

func test_jigglypuff_and_zubat_follow_in_the_galleries() -> void:
	await _start("mt_moon_1f")
	var companion := _boot.get_companion_controller()
	assert_eq(GameState.companion_uid, GameState.party.get_at(1).uid, "Rondoudou compagnon")
	await _put(Vector2i(31, 40), Vector2i.UP)
	companion.on_cutscene_started()
	companion.on_cutscene_finished()
	assert_true(_player.script_step(Vector2i.UP))
	await wait_until(func() -> bool: return companion.is_shown(), TIMEOUT)
	assert_true(companion.is_shown(), "Rondoudou suit dans la galerie")
	var catalog := CompanionCatalog.new()
	assert_true(catalog.load_file())
	for species: StringName in [&"jigglypuff", &"clefairy", &"ekans", &"paras", &"zubat",
			&"geodude", &"pidgeotto", &"nidorino", &"nidorina", &"raticate", &"fearow"]:
		assert_true(catalog.is_eligible_species(species), String(species))
		assert_true(CharacterLook.resolve(catalog.sprite_of(species)).painted,
			"%s : planche peinte" % species)
	assert_true(catalog.is_flying(&"zubat"), "Nosferapti en vol")


# --- Reprise d'une partie quittée dans chaque étage --------------------------------------------

func test_resuming_a_game_left_in_each_floor() -> void:
	for start: String in ["mt_moon_1f", "mt_moon_b1f", "mt_moon_b2f"]:
		_fs = MemoryFs.new()
		await _start(start)
		var map_id := _boot.get_map().map_id
		var cell := _boot.get_player().get_cell()
		var companion_uid := GameState.companion_uid
		var ropes := GameState.bag.count_of(&"escape_rope")
		GameState.flags.set_flag(&"beaten_mt_moon_test_marker")
		_boot.request_autosave("test")
		await wait_process_frames(5)
		_boot.queue_free()
		await wait_process_frames(3)
		await _start(start, false)
		assert_true(_boot.has_resumed(), "%s : partie reprise" % start)
		assert_eq(_boot.get_map().map_id, map_id, "%s : même étage" % start)
		assert_eq(_boot.get_player().get_cell(), cell, "%s : même case" % start)
		assert_true(GameState.flags.has_flag(&"beaten_mt_moon_test_marker"),
			"%s : drapeaux gardés" % start)
		assert_eq(GameState.companion_uid, companion_uid, "%s : compagnon gardé" % start)
		assert_eq(GameState.bag.count_of(&"escape_rope"), ropes, "%s : Sac gardé" % start)
		if GameState.flags.has_flag(&"got_mt_moon_1f_item_1") and map_id == &"mt_moon_1f":
			assert_null(_boot.get_map().get_npc(&"mt_moon_1f_ball_1"), "objet ramassé absent")
		_boot.queue_free()
		await wait_process_frames(3)
