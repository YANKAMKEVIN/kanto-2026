extends GutTest
## Départ du S.S. Anne et arbuste de l'Arène sur les vraies cartes (jalon 16 T15, sous-jalon 16D ;
## `jalon-16.md` §0.3, §2.3, §2.4, §2.11 ; dossier 19 §7, §8, §13) avec la vraie scène Boot, une
## sauvegarde en mémoire, les vraies entrées (`move_*`, `interact`) et les départs de débogage :
## - passerelle du pont principal : PAS ENCORE garde à bord ; PARTIR → quai (spawn `dock`),
##   drapeau `ss_anne_departed` écrit **tout de suite** (étape `save`), spectacle, plus de navire
##   ni de passerelle, marin de retour (DEP-03), garde-fou ; Passe Bateau conservé ;
## - **fermeture de l'appli** à chaque étape de la scène (disque relevé dans `step_started`) :
##   avant l'écriture, à bord sans départ ; après, au quai sans navire ; jamais d'état mixte ;
##   relance sur chacun des deux états (le spectacle n'est pas rejoué, la confirmation l'est) ;
## - avant la CS01 : TXT-03 une fois, aller-retour Carmin ↔ navire par la passerelle ;
## - arbuste : les quatre états, LAISSER, COUPER (coupé une fois pour toutes, relu après une
##   relance), porte de l'Arène atteignable, aller-retour Carmin ↔ Arène ;
## - liste blanche de l'étape `save` dans les données.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_ss_anne_departure_save.json"
const STARTS := "res://tools/debug_start/%s.json"
const FADE := 0.05
const TIMEOUT := 12.0
const SCENE_TIMEOUT_MS := 60000
const WALK_STOP := &"test_walk_stop"
const CITY := &"vermilion_city"
const DECK := &"ss_anne_main_deck"
const GYM := &"vermilion_gym"
const DEPARTED := &"ss_anne_departed"
const CUT := &"cut_vermilion_gym_bush"
const DOCK := Vector2i(31, 24)
const GUARD: Array[Vector2i] = [Vector2i(31, 27), Vector2i(32, 27), Vector2i(31, 28),
	Vector2i(32, 28)]
## Cases de la passerelle à bord (sorties PUSH ↓) et arrivée au-dessus.
const EXIT_W := Vector2i(12, 11)
const ABOVE_EXIT_W := Vector2i(12, 10)
const TREE: Array[Vector2i] = [Vector2i(49, 10), Vector2i(50, 10)]
const UNDER_TREE := Vector2i(49, 11)
const GYM_DOOR := Vector2i(49, 9)

const DEP_01 := "Si tu pars, le navire appareille.\nTu ne pourras plus remonter."
const NOT_YET := "Prends ton temps.\nOn ne part pas sans toi."
const TXT_03 := "Tu redescends à terre ?\nLe navire reste à quai pour l'instant."
const DEP_03 := "Le S.S. Anne a pris le large."
const ARB_00 := "Un jeune arbre pousse devant l'entrée. Impossible de passer."
const ARB_02 := "Aucun Pokémon de l'équipe\nne peut couper cet arbuste."

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []
var _stop_at := Vector2i(-1, -1)
var _held: StringName = &""
## Réponses aux choix (vrai = carte de confirmation), dans l'ordre ; vide : annuler.
var _answers: Array[bool] = []
## Disque relevé au début de chaque étape de la scène de départ (« fermeture à l'étape i »).
var _disk_at_step: Array[Dictionary] = []
## Disque relevé quand les cartes PARTIR / PAS ENCORE sont affichées.
var _disk_at_choice: Dictionary = {}


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_fs = MemoryFs.new()
	_pages.clear()
	_answers.clear()
	_disk_at_step.clear()
	_disk_at_choice = {}


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


# --- Aides ---------------------------------------------------------------------------------

## Boot sur la carte du départ de débogage [param start_name], partie appliquée, puis une
## écriture (la « dernière sauvegarde stable » avant le test).
func _start(start_name: String) -> void:
	var start := DebugStart.new()
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	assert_true(start.load_file(STARTS % start_name, data, items), "\n".join(start.get_errors()))
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = start.map
	_boot.start_spawn = start.spawn
	_boot.start_facing = start.facing
	add_child_autofree(_boot)
	await _attach()
	start.apply(GameState, _boot.get_pokemon_data())
	_boot.get_map().refresh_npcs(GameState.flags)
	_boot.get_map().apply_flag_gates(GameState.flags)
	assert_eq(_boot.get_map().map_id, start.map)
	await _save_now()


## Relance de l'application sur le disque [param disk] (fermeture puis réouverture) : Boot lit
## la sauvegarde et reprend où elle a été écrite.
func _relaunch(disk: Dictionary) -> void:
	if is_instance_valid(_boot):
		_boot.queue_free()
		await wait_process_frames(2)
	_fs = MemoryFs.new()
	_fs.files[SAVE_PATH] = JSON.stringify(disk)
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	add_child_autofree(_boot)
	await _attach()


func _attach() -> void:
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_dialogue_runner().page_started.connect(_on_page_started)
	_boot.get_cutscene_director().step_started.connect(_on_step_started)
	_player.moved.connect(_on_player_moved)
	await wait_until(func() -> bool:
		return is_instance_valid(_boot.get_map()) and not SceneRouter.is_transitioning(),
		TIMEOUT)
	await wait_process_frames(3)


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _disk() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


func _save_now() -> void:
	var writes := _writes()
	_boot.request_autosave("test")
	await wait_until(func() -> bool: return _writes() > writes, TIMEOUT)
	assert_gt(_writes(), writes, "sauvegarde stable écrite")


func _on_page_started(_index: int) -> void:
	_pages.append(_boot.get_dialogue_box().get_text())


func _on_step_started(_index: int) -> void:
	if _boot.get_cutscene_director().get_cutscene_id() == &"ss_anne_departure":
		_disk_at_step.append(_disk())


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


func _on_player_moved(cell: Vector2i) -> void:
	if cell == _stop_at and not _held.is_empty():
		Input.action_release(_held)
		_held = &""
		_player.set_input_enabled(false, WALK_STOP)


## Maintient la direction jusqu'à [param until] (ou jusqu'à ce qu'une scène bloque le joueur).
func _walk(direction: Vector2i, until: Vector2i) -> void:
	_stop_at = until
	_held = _action(direction)
	Input.action_press(_held)
	await wait_until(func() -> bool:
		return _player.get_cell() == until or not _player.is_input_enabled(), TIMEOUT)
	await wait_process_frames(1)
	if not _held.is_empty():
		Input.action_release(_held)
		_held = &""
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	_player.set_input_enabled(true, WALK_STOP)


## Pousse [param direction] depuis la case du joueur (sortie PUSH) jusqu'à la carte
## [param map_id].
func _push_to(direction: Vector2i, map_id: StringName) -> void:
	var action := _action(direction)
	Input.action_press(action)
	await wait_until(func() -> bool:
		return _boot.get_map().map_id == map_id and not SceneRouter.is_transitioning(), TIMEOUT)
	Input.action_release(action)
	await _play_out()


## Joue tout ce qui est en cours (scène, dialogue, fondus), pages tournées, choix répondus.
func _play_out() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_choice_showing():
			if _disk_at_choice.is_empty():
				_disk_at_choice = _disk()
			var cards := box.get_choice_cards()
			var yes: bool = _answers.pop_front() if not _answers.is_empty() else false
			(cards.get_confirm_button() if yes else cards.get_cancel_button()).pressed.emit()
		elif box.is_open() and not runner.is_awaiting_choice():
			box.advance_requested.emit()
	await wait_process_frames(3)


func _interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await _play_out()


func _flag(flag: StringName) -> bool:
	return GameState.flags.has_flag(flag)


func _node(path: String) -> Node2D:
	return _boot.get_map().get_node(NodePath(path)) as Node2D


## Carte du disque [param disk] : « navire » (à bord, sans départ) ou « quai » (Carmin, au
## quai, navire parti) ; « mixte » sinon.
func _disk_state(disk: Dictionary) -> String:
	var departed := (disk.get("flags", []) as Array).has(String(DEPARTED))
	var map := str(disk.get("map", ""))
	var raw: Array = disk.get("cell", [0, 0])
	var cell := Vector2i(int(raw[0]), int(raw[1]))
	if not departed and map == String(DECK):
		return "navire"
	if departed and map == String(CITY) and cell == DOCK:
		return "quai"
	return "mixte (%s, %s, départ %s)" % [map, cell, departed]


## Le quai après le départ : navire et passerelle absents, marin en (31, 26), garde-fou sur la
## passerelle et l'accès.
func _assert_dock_after_departure(label: String) -> void:
	var map := _boot.get_map()
	assert_eq(map.map_id, CITY, label)
	assert_false(_node("Entities/SsAnne").visible, "%s : navire absent" % label)
	assert_false(_node("GroundDecals/Gangway").visible, "%s : passerelle absente" % label)
	var sailor := map.get_npc(&"sailor")
	assert_not_null(sailor, "%s : marin" % label)
	if sailor != null:
		assert_eq(sailor.get_cell(), Vector2i(31, 26))
	for cell: Vector2i in GUARD:
		assert_true(map.get_grid().is_occupied(cell), "%s : %s gardée" % [label, cell])
	assert_eq(GameState.bag.count_of(&"ss_ticket"), 1, "%s : Passe Bateau conservé" % label)


# --- Passerelle et départ ------------------------------------------------------------------

func test_exit_trigger_on_both_gangway_cells() -> void:
	var deck := (load(MapCatalog.scene_path(DECK)) as PackedScene).instantiate() as GameMap
	add_child_autofree(deck)
	for cell: Vector2i in [EXIT_W, EXIT_W + Vector2i.RIGHT]:
		for direction: Vector2i in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var trigger := deck.get_triggers().find_on_step(cell, direction)
			assert_not_null(trigger, "%s %s" % [cell, direction])
			if trigger != null:
				assert_eq(trigger.cutscene_id, &"ss_anne_departure")
		assert_not_null(deck.get_warps().find_on_push(cell, Vector2i.DOWN), "sortie PUSH")


func test_not_yet_keeps_the_player_on_board() -> void:
	await _start("ss_anne_exit")
	_answers = [false]
	var writes := _writes()
	await _walk(Vector2i.DOWN, EXIT_W)
	await _play_out()
	assert_true(_pages.has(DEP_01), "DEP-01")
	assert_true(_pages.has(NOT_YET), "réplique du marin après PAS ENCORE")
	assert_eq(_boot.get_map().map_id, DECK, "à bord")
	assert_eq(_player.get_cell(), ABOVE_EXIT_W, "un pas en arrière")
	assert_false(_flag(DEPARTED))
	assert_false(_flag(&"ss_anne_departure_chosen"))
	assert_eq(_disk_state(_disk()), "navire")
	assert_lte(_writes(), writes + 1, "au plus l'autosave de fin de scène")
	assert_push_error_count(0)


func test_leave_writes_at_once_then_plays_the_departure() -> void:
	await _start("ss_anne_exit")
	_answers = [true]
	var writes := _writes()
	await _walk(Vector2i.DOWN, EXIT_W)
	await _play_out()
	# Fermeture pendant la confirmation : à bord, sans départ.
	assert_eq(_disk_state(_disk_at_choice), "navire", "fermeture pendant le choix")
	# Fermeture à chaque étape : avant l'étape « save » (incluse), à bord ; ensuite, au quai.
	var steps := _boot.get_cutscene_library().get_cutscene(&"ss_anne_departure") \
		.variants[0].steps
	var save_index := -1
	for i: int in steps.size():
		if steps[i].kind == CutsceneStep.Kind.SAVE:
			save_index = i
	assert_gt(save_index, 0)
	# Étapes jouées (sautées comprises : « move » PAS ENCORE) : une entrée par étape.
	assert_eq(_disk_at_step.size(), steps.size(), "disque relevé à chaque étape")
	for i: int in _disk_at_step.size():
		var expected := "navire" if i <= save_index else "quai"
		assert_eq(_disk_state(_disk_at_step[i]), expected, "fermeture à l'étape %d" % (i + 1))
	assert_gte(_writes(), writes + 1, "écriture immédiate")
	# Fin de scène.
	assert_eq(_player.get_cell(), DOCK, "joueur sur le quai")
	assert_true(_flag(DEPARTED))
	_assert_dock_after_departure("après le spectacle")
	assert_eq(_disk_state(_disk()), "quai")
	# Le marin : DEP-03.
	_pages.clear()
	await _walk(Vector2i.DOWN, DOCK + Vector2i.DOWN)
	await _interact()
	assert_eq(_pages, [DEP_03] as Array[String], "DEP-03")
	assert_push_error_count(0)


func test_closing_after_the_save_resumes_on_the_dock_without_the_show() -> void:
	await _start("ss_anne_exit")
	_answers = [true]
	_boot.get_cutscene_director().reduce_motion = true
	await _walk(Vector2i.DOWN, EXIT_W)
	await _play_out()
	# Disque au début du spectacle (étape après « save ») : l'appli est fermée là.
	var during_show: Dictionary = _disk_at_step[-1]
	assert_eq(_disk_state(during_show), "quai")
	_pages.clear()
	await _relaunch(during_show)
	assert_false(_boot.get_cutscene_director().is_running(), "spectacle non rejoué")
	assert_eq(_player.get_cell(), DOCK)
	_assert_dock_after_departure("relance")
	# Retour impossible : le marin de retour et la bitte ferment la passerelle.
	await _walk(Vector2i.DOWN, DOCK + Vector2i.DOWN)
	Input.action_press(&"move_down")
	await wait_process_frames(40)
	Input.action_release(&"move_down")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_eq(_player.get_cell(), DOCK + Vector2i.DOWN, "arrêt devant le marin")
	assert_eq(_boot.get_map().map_id, CITY)
	assert_push_error_count(0)


func test_closing_before_the_save_replays_the_confirmation() -> void:
	await _start("ss_anne_exit")
	_answers = [true]
	_boot.get_cutscene_director().reduce_motion = true
	await _walk(Vector2i.DOWN, EXIT_W)
	await _play_out()
	assert_eq(_disk_state(_disk_at_choice), "navire")
	await _relaunch(_disk_at_choice)
	assert_eq(_boot.get_map().map_id, DECK, "reprise à bord")
	assert_false(_flag(DEPARTED))
	_pages.clear()
	_answers = [false]
	_player.face(Vector2i.DOWN)
	await _walk(Vector2i.DOWN, EXIT_W)
	await _play_out()
	assert_true(_pages.has(DEP_01), "confirmation à refaire")
	assert_eq(_boot.get_map().map_id, DECK)
	assert_push_error_count(0)


func test_departure_show_lasts_at_most_ten_seconds() -> void:
	var steps := CutsceneLibrary.new()
	steps.load_dir()
	var total := 0.0
	var after_save := false
	var last_fade := false
	for step: CutsceneStep in steps.get_cutscene(&"ss_anne_departure").variants[0].steps:
		match step.kind:
			CutsceneStep.Kind.SAVE:
				after_save = true
			CutsceneStep.Kind.WAIT:
				total += step.seconds
			CutsceneStep.Kind.CAPTION:
				total += UiTokens.CAPTION_HOLD + 2.0 * UiTokens.CAPTION_FADE
			CutsceneStep.Kind.ANIMATE:
				assert_eq(step.target, &"Entities/SsAnne")
				total += step.seconds + (CutsceneDirector.DESPAWN_FADE if step.fade else 0.0)
				last_fade = step.fade
	assert_true(after_save)
	assert_true(last_fade, "le navire disparaît à la fin")
	assert_lte(total, 10.0, "spectacle ≤ 10 s (dossier 19 §8)")


# --- Avant la CS01 : sortie libre et aller-retour ------------------------------------------

func test_free_exit_and_round_trip_between_carmin_and_the_ship() -> void:
	await _start("ss_anne_free_exit")
	var zones: Array[String] = []
	_boot.zone_announced.connect(func(zone: String, region: String) -> void:
		zones.append("%s / %s" % [zone, region]))
	await _walk(Vector2i.DOWN, EXIT_W)
	await _play_out()
	assert_eq(_pages, [TXT_03] as Array[String], "TXT-03 au premier passage")
	assert_eq(_boot.get_map().map_id, DECK, "rien d'autre")
	await _push_to(Vector2i.DOWN, CITY)
	assert_eq(_player.get_cell(), Vector2i(31, 27), "sur la passerelle de Carmin")
	assert_true(_node("Entities/SsAnne").visible, "navire à quai")
	# Retour à bord par l'embarquement.
	await _walk(Vector2i.DOWN, Vector2i(31, 28))
	await wait_until(func() -> bool:
		return _boot.get_map().map_id == DECK and not SceneRouter.is_transitioning(), TIMEOUT)
	await _play_out()
	assert_eq(_player.get_cell(), ABOVE_EXIT_W, "arrivée à bord au-dessus de la passerelle")
	# Décision de Kevin du 2026-10-16 : « S.S. ANNE » dès l'embarquement (pont principal, un
	# intérieur ; zone `interior_title`), une fois par aller.
	assert_eq(zones, ["Carmin-sur-Mer / Le port des grands départs",
		"S.S. Anne / Le grand paquebot de Kanto"]
		as Array[String], "titres de zone : Carmin, puis le navire dès le pont principal")
	# Seconde sortie : plus de TXT-03.
	_pages.clear()
	await _walk(Vector2i.DOWN, EXIT_W)
	await _play_out()
	assert_eq(_pages, [] as Array[String], "TXT-03 une seule fois")
	await _push_to(Vector2i.DOWN, CITY)
	assert_false(_flag(DEPARTED))
	assert_push_error_count(0)


# --- Marin de la passerelle : même parole que la sortie -----------------------------------

## Avant la CS01 : le marin dit TXT-03 (une seule source : son dialogue, joué aussi par la
## sortie) ; après l'avoir entendu de lui, la passerelle ne le répète pas.
func test_sailor_before_the_hm_then_gangway_says_txt03_once() -> void:
	await _start("ss_anne_free_exit")
	assert_eq(_player.get_cell(), ABOVE_EXIT_W)
	_player.face(Vector2i.LEFT)
	await _interact()
	assert_eq(_pages, [TXT_03] as Array[String], "le marin : TXT-03")
	_pages.clear()
	await _walk(Vector2i.DOWN, EXIT_W)
	await _play_out()
	assert_eq(_pages, [] as Array[String], "passerelle : pas de second TXT-03")
	await _push_to(Vector2i.DOWN, CITY)
	assert_false(_flag(DEPARTED))
	assert_push_error_count(0)


## Avant la CS01, sortie d'abord (TXT-03), puis le marin : sa parole reste TXT-03, jamais la
## réplique de la confirmation (« Prends ton temps… »).
func test_gangway_then_sailor_before_the_hm() -> void:
	await _start("ss_anne_free_exit")
	await _walk(Vector2i.DOWN, EXIT_W)
	await _play_out()
	assert_eq(_pages, [TXT_03] as Array[String])
	await _walk(Vector2i.UP, ABOVE_EXIT_W)
	_pages.clear()
	_player.face(Vector2i.LEFT)
	await _interact()
	assert_eq(_pages, [TXT_03] as Array[String], "le marin redit TXT-03")
	assert_push_error_count(0)


## Après la CS01 : parler au marin pose la même question que la passerelle (DEP-01, PARTIR /
## PAS ENCORE) ; « Prends ton temps… » n'est dit qu'après PAS ENCORE ; PARTIR part.
func test_sailor_after_the_hm_asks_the_same_confirmation() -> void:
	await _start("ss_anne_exit")
	assert_eq(_player.get_cell(), ABOVE_EXIT_W)
	_player.face(Vector2i.LEFT)
	_answers = [false]
	await _interact()
	assert_eq(_pages, [DEP_01, NOT_YET] as Array[String], "DEP-01 puis PAS ENCORE")
	assert_eq(_boot.get_map().map_id, DECK, "à bord")
	assert_false(_flag(DEPARTED))
	assert_false(_flag(&"ss_anne_departure_chosen"))
	assert_eq(_disk_state(_disk()), "navire")
	# Retour devant le marin, PARTIR.
	await _walk(Vector2i.DOWN, ABOVE_EXIT_W)
	_player.face(Vector2i.LEFT)
	_pages.clear()
	_answers = [true]
	await _interact()
	assert_true(_pages.has(DEP_01))
	assert_false(_pages.has(NOT_YET))
	assert_true(_flag(DEPARTED))
	assert_eq(_disk_state(_disk()), "quai")
	_assert_dock_after_departure("PARTIR par le marin")
	assert_push_error_count(0)


# --- Arbuste de l'Arène ------------------------------------------------------------------

func test_tree_dialogue_for_each_state_without_cutting() -> void:
	var expected := {
		"cut_no_hm": ARB_00,
		"cut_no_badge": "Sans le Badge Cascade, %s\nn'ose pas couper cet arbuste.",
		"cut_no_pokemon": ARB_02,
	}
	for start_name: String in expected:
		_pages.clear()
		await _start(start_name)
		assert_eq(_player.get_cell(), UNDER_TREE)
		await _interact()
		var line: String = expected[start_name]
		if line.contains("%s"):
			var state := _boot.field_state(&"cut")
			line = line % GameState.party.get_at(state.pokemon_index).display_name(
				_boot.get_pokemon_data())
		assert_eq(_pages, [line] as Array[String], start_name)
		assert_false(_flag(CUT), start_name)
		assert_true(_node("Entities/GymTree").visible, start_name)
		_boot.queue_free()
		await wait_process_frames(2)
		_fs = MemoryFs.new()
	assert_push_error_count(0)


func test_leave_then_cut_for_good_and_round_trip_to_the_gym() -> void:
	await _start("cut_ready")
	var name := GameState.party.get_at(_boot.field_state(&"cut").pokemon_index) \
		.display_name(_boot.get_pokemon_data())
	_answers = [false]
	await _interact()
	assert_eq(_pages, ["%s peut couper cet arbuste." % name, "Utiliser Coupe ?"]
		as Array[String], "ARB-03")
	assert_false(_flag(CUT), "LAISSER : rien ne change")
	assert_true(_node("Entities/GymTree").visible)
	_pages.clear()
	_answers = [true]
	await _interact()
	assert_true(_pages.has("%s utilise Coupe !" % name), "ARB-04")
	assert_true(_flag(CUT))
	assert_false(_node("Entities/GymTree").visible, "arbuste coupé")
	for cell: Vector2i in TREE:
		assert_false(_boot.get_map().get_grid().is_occupied(cell), "%s libérée" % cell)
	# Porte de l'Arène atteignable, aller-retour Carmin ↔ Arène.
	await _walk(Vector2i.UP, GYM_DOOR)
	await wait_until(func() -> bool:
		return _boot.get_map().map_id == GYM and not SceneRouter.is_transitioning(), TIMEOUT)
	await _play_out()
	assert_eq(_player.get_cell(), Vector2i(8, 12), "entrée de l'Arène")
	await _walk(Vector2i.DOWN, Vector2i(8, 13))
	await _push_to(Vector2i.DOWN, CITY)
	assert_eq(_player.get_cell(), _boot.get_map().get_spawn_cell(&"from_gym"))
	assert_false(_node("Entities/GymTree").visible, "toujours coupé au retour")
	# Relance : coupé pour toujours.
	await _save_now()
	await _relaunch(_disk())
	assert_true(_flag(CUT))
	assert_false(_node("Entities/GymTree").visible, "coupé après la relance")
	var gate := _node("Entities/GymTree")
	for cell: Vector2i in TREE:
		assert_ne(_boot.get_map().get_grid().get_occupant(cell), gate, "%s libre" % cell)
	assert_eq(_player.get_cell(), Vector2i(50, 10), "reprise devant la porte, sur l'arbuste coupé")
	assert_push_error_count(0)


# --- Données -------------------------------------------------------------------------------

## L'étape « save » (écriture immédiate) n'existe que dans le départ du navire (la scène de la
## carte de QA est retirée au T20) : liste blanche (`jalon-16.md` §2.4).
func test_save_step_only_in_the_departure() -> void:
	var library := CutsceneLibrary.new()
	library.load_dir()
	var found: Array[StringName] = []
	for id: StringName in library.get_ids():
		for variant: CutsceneVariant in library.get_cutscene(id).variants:
			for step: CutsceneStep in variant.steps:
				if step.kind == CutsceneStep.Kind.SAVE and not found.has(id):
					found.append(id)
	found.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	# Jalon 24 : sauvegardes forcées du dossier 27 §13.3 (CT35, fossile confié, don).
	assert_eq(found, [&"cinnabar_fossil_give_kabuto", &"cinnabar_fossil_give_omanyte",
		&"cinnabar_fossil_take_kabuto", &"cinnabar_fossil_take_omanyte", &"cinnabar_lab_tm35",
		&"ss_anne_departure"] as Array[StringName])


func test_departure_data_order_and_texts() -> void:
	var library := CutsceneLibrary.new()
	library.load_dir()
	var departure := library.get_cutscene(&"ss_anne_departure")
	var flags := StoryFlags.new()
	assert_same(departure.pick(flags), departure.variants[1], "avant la CS01 : TXT-03")
	flags.set_flag(&"ss_anne_exit_told")
	assert_null(departure.pick(flags), "TXT-03 une seule fois")
	flags.set_flag(&"got_hm01")
	assert_same(departure.pick(flags), departure.variants[0], "après la CS01 : confirmation")
	flags.set_flag(DEPARTED)
	assert_null(departure.pick(flags))
	var kinds: Array = []
	for step: CutsceneStep in departure.variants[0].steps:
		kinds.append(step.kind)
	var change := kinds.find(CutsceneStep.Kind.CHANGE_MAP)
	var set_departed := kinds.find(CutsceneStep.Kind.SET_FLAGS)
	var save := kinds.find(CutsceneStep.Kind.SAVE)
	var animate := kinds.find(CutsceneStep.Kind.ANIMATE)
	# Drapeau levé après l'arrivée au quai (navire encore amarré à l'arrivée) ; aucune écriture
	# avant « save » (scène en cours) ; le spectacle réaffiche le navire tout de suite.
	assert_true(change < set_departed and set_departed < save and save == animate - 1,
		"change_map, set, save, puis le spectacle")
	var step: CutsceneStep = departure.variants[0].steps[change]
	assert_eq([step.map_id, step.spawn], [CITY, &"dock"])
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	var confirm := dialogues.get_dialogue(&"ss_anne_departure_confirm").variants[0]
	assert_eq(confirm.choice.confirm_label, "PARTIR")
	assert_eq(confirm.choice.cancel_label, "PAS ENCORE")
	var sailor := dialogues.get_dialogue(&"vermilion_sailor")
	assert_eq(sailor.variants[0].if_flags, [DEPARTED] as Array[StringName])
	assert_eq(sailor.variants[0].pages[0].text, DEP_03, "DEP-03")



## Le point critique n'est franchi ni après une panne d'écriture ni après un renommage manqué.
func test_departure_waits_for_a_successful_disk_commit() -> void:
	await _start("ss_anne_exit")
	var director := _boot.get_cutscene_director()
	director.save_retry_delay = 0.0
	director.reduce_motion = true
	var failures: Array[Error] = []
	var checkpoint := -1
	var steps := _boot.get_cutscene_library().get_cutscene(&"ss_anne_departure").variants[0].steps
	for i: int in steps.size():
		if steps[i].kind == CutsceneStep.Kind.SAVE:
			checkpoint = i
	director.step_started.connect(func(index: int) -> void:
		if index == checkpoint:
			_fs.fail_writes = true)
	director.save_failed.connect(func(_reason: String, error: Error) -> void:
		failures.append(error)
		assert_true(director.is_running(), "la scène garde les contrôles")
		assert_eq(director.get_step_index(), checkpoint, "aucun spectacle avant l'écriture")
		assert_eq(_disk_state(_disk()), "navire", "ancien fichier intact")
		_fs.fail_writes = false
		# La deuxième tentative échoue au remplacement, la troisième réussit.
		_fs.fail_renames = failures.size() == 1)
	_answers = [true]
	await _walk(Vector2i.DOWN, EXIT_W)
	await _play_out()
	assert_eq(failures.size(), 2)
	assert_eq(_disk_state(_disk()), "quai")
	_assert_dock_after_departure("après nouvelle tentative")
	assert_push_error_count(0)


## Refus passager (transition en cours, ERR_BUSY) : la même étape réessaie à l'image suivante,
## sans message d'échec ni attente de 5 s, puis la scène continue.
func test_a_busy_checkpoint_retries_next_frame_without_reporting_a_failure() -> void:
	await _start("ss_anne_exit")
	var director := _boot.get_cutscene_director()
	var library := CutsceneLibrary.new()
	assert_true(library.add_from_dict({"checkpoint_busy": {"steps": [
		{"save": "test critique"}, {"set": ["checkpoint_busy_finished"]},
	]}}, "test"))
	var calls: Array[int] = [0]
	director.save_handler = func(_reason: String) -> Error:
		calls[0] += 1
		return ERR_BUSY if calls[0] < 3 else OK
	var failures: Array[Error] = []
	director.save_failed.connect(func(_reason: String, error: Error) -> void:
		failures.append(error))
	assert_true(director.play_variant(&"checkpoint_busy",
		library.get_cutscene(&"checkpoint_busy").variants[0]))
	await wait_until(func() -> bool: return _flag(&"checkpoint_busy_finished"), 2.0)
	assert_true(_flag(&"checkpoint_busy_finished"), "la scène a continué")
	assert_eq(calls[0], 3, "deux refus passagers, puis la réussite")
	assert_eq(failures.size(), 0, "aucun « Sauvegarde impossible » pour un refus passager")
	assert_push_error_count(0)


func test_restarting_during_a_failed_checkpoint_keeps_the_previous_save() -> void:
	await _start("ss_anne_exit")
	var director := _boot.get_cutscene_director()
	director.save_retry_delay = 0.0
	var library := CutsceneLibrary.new()
	assert_true(library.add_from_dict({"checkpoint_test": {"steps": [
		{"save": "test critique"}, {"set": ["checkpoint_test_finished"]},
	]}}, "test"))
	_fs.fail_writes = true
	# La variante de test passe par le même verrou que les scènes de contenu.
	assert_true(director.play_variant(&"checkpoint_test",
		library.get_cutscene(&"checkpoint_test").variants[0]))
	await wait_process_frames(2)
	assert_true(director.is_running())
	assert_false(_flag(&"checkpoint_test_finished"), "l'étape suivante n'a pas été jouée")
	var disk := _disk()
	await _relaunch(disk)
	assert_eq(_disk_state(_disk()), "navire")
	assert_false(_flag(DEPARTED))
	assert_false(_flag(&"checkpoint_test_finished"))
	assert_push_error_count(0)
