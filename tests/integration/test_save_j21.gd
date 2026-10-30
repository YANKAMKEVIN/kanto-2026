extends GutTest
## Sauvegarde du jalon 21 (T15, T23, `jalon-21.md` §2.14 ; dossier 24 §16) : **aucune nouvelle
## version** (v7 ; v8 depuis le J23) ; chaque drapeau du J21 survit à un aller-retour ; points de coupure sur la
## **vraie Boot** (coordinateur de sauvegarde, fichier en mémoire, partie reprise au démarrage) :
## - n° 1 : après la victoire contre Ossatueur → 6F : brume légère, aucun déclencheur ; escalier
##   vers le 7F ; objectif « trouver M. Fuji… » ;
## - n° 3 : « entre deux scènes » (`fuji_rescued`, pas de Flûte) → joueur dans la maison, Fuji
##   présent, lui parler → remise ; **une** Flûte ;
## - n° 4 : après la remise → une Flûte, `got_poke_flute` ; le pas d'entrée ne rejoue rien ; Fuji
##   §15.4.6 ;
## - n° 5 : après réveil + fuite (Ronflex de la Route 12) → Ronflex en place, `_awake` absent,
##   `_woken` présent, §15.7.5 à l'examen ;
## - n° 7 : après capture (Ronflex de la Route 12) → absent, passage libre, Ronflex au Stockage ;
##   Ronflex 16 inchangé ;
## - n° 9 : partie du J20 (Scope, aucun drapeau du J21) relue → rien du J21 ; révélation au 6F.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save_j21.json"
const BOOT_PATH := "user://test/save_j21_boot.json"
const START_6F := "res://tools/debug_start/tower_marowak_qa.json"
const START_FUJI := "res://tools/debug_start/fuji_flute_qa.json"
const START_ROUTE_12 := "res://tools/debug_start/route_12_qa.json"
const FADE := 0.05
const TIMEOUT := 30.0
const FLUTE := &"poke_flute"
const SCOPE := &"silph_scope"
const AFTER_TEXT: String = "Ma Flûte t'a-t-elle été utile ?"
const AGAIN_FIRST: String = "Ronflex dort de nouveau."
const SNORLAX_12: Array[Vector2i] = [Vector2i(25, 93), Vector2i(26, 93), Vector2i(25, 94),
	Vector2i(26, 94)]
const SNORLAX_16: Array[Vector2i] = [Vector2i(24, 22), Vector2i(24, 23), Vector2i(25, 22),
	Vector2i(25, 23)]
const FACE_12 := Vector2i(25, 92)

## Drapeaux du J21 (§2.14), plus `snorlax_route_12_seen` (T-6 du J17, repris par la Route 12).
static var J21_FLAGS: Array[StringName] = _j21_flags()

var _data: PokemonData
var _fs: MemoryFs
var _save: SaveSystem
var _fades: Array[float] = []
var _boot: Boot
var _pages: Array[String] = []


static func _j21_flags() -> Array[StringName]:
	var flags: Array[StringName] = [
		&"ghost_marowak_calmed", &"tower_6f_mist_lifted",
		&"beaten_tower_rocket_1", &"beaten_tower_rocket_2", &"beaten_tower_rocket_3",
		&"fuji_rescued", &"got_poke_flute",
		&"got_tm39", &"route_12_visited", &"route_16_visited",
	]
	for n: int in [12, 16]:
		for suffix: String in ["awake", "woken", "caught", "done", "seen"]:
			flags.append(StringName("snorlax_route_%d_%s" % [n, suffix]))
	return flags


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon")


func before_each() -> void:
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, PATH)
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)
	if is_instance_valid(_boot):
		await _stop_boot()


# --- Version et drapeaux -----------------------------------------------------------------------


func test_the_jalon_21_adds_no_save_version() -> void:
	assert_eq(SaveSystem.VERSION, 9, "aucune version du J21 : v7 depuis le J15 (Pension), v8 du J23, v9 JR")


func test_every_flag_of_the_jalon_21_survives_a_save() -> void:
	assert_eq(J21_FLAGS.size(), 20, "2 + 3 + 2 + 3 + 2 × 5 drapeaux (§2.14, `_seen` du 12 compris)")
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-22T03:00:00")
	state.new_game(21)
	state.party.add(PokemonFactory.create(_data, &"charmeleon", 33, GameRng.new(1)))
	for flag: StringName in J21_FLAGS:
		state.flags.set_flag(flag)
	state.bag.add(FLUTE)
	state.bag.add(&"tm39")
	assert_eq(_save.write(state.to_dict()), OK, "écriture")
	var content := _save.read()
	assert_eq(_save.last_status, OK, "relecture")
	assert_eq(int(content["version"]), SaveSystem.VERSION)
	var loaded: Node = autofree(GameStateScript.new())
	loaded.clock = FixedClock.new("2026-10-22T03:00:00")
	loaded.new_game(1)
	assert_true(loaded.load_dict(content, _data), "chargé sans entrée écartée")
	for flag: StringName in J21_FLAGS:
		assert_true(loaded.flags.has_flag(flag), "%s relu" % flag)
	assert_eq(loaded.bag.count_of(FLUTE), 1, "Flûte relue")
	assert_eq(loaded.bag.count_of(&"tm39"), 1, "CT39 relue")


# --- Vraie Boot --------------------------------------------------------------------------------


## Boot sur [param fs] : départ de débogage [param start] (« » : reprise de la sauvegarde).
func _start_boot(fs: MemoryFs, start: String = "") -> void:
	GameState.clock = FixedClock.new("2026-10-22T03:00:00")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(fs, BOOT_PATH)
	# Le départ est appliqué à la main (comme `test_route_12`) : un départ forcé n'écrit pas la
	# sauvegarde, une nouvelle partie sur la carte du départ, si.
	var debug := DebugStart.new()
	if not start.is_empty():
		var items := ItemLibrary.new()
		items.load_dir()
		assert_true(debug.load_file(start, _data, items), "\n".join(debug.get_errors()))
		_boot.start_map = debug.map
		_boot.start_spawn = debug.spawn
		_boot.start_facing = debug.facing
	add_child(_boot)
	if not start.is_empty():
		debug.apply(GameState, _boot.get_pokemon_data())
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	_boot.get_encounter_director().enabled = false
	var runner := _boot.get_dialogue_runner()
	runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text().replace("\n", " / ")))


func _stop_boot() -> void:
	remove_child(_boot)
	_boot.free()
	_boot = null
	await wait_process_frames(2)


func _file(fs: MemoryFs) -> Dictionary:
	var parsed: Variant = JSON.parse_string(fs.files.get(BOOT_PATH, ""))
	return parsed if parsed is Dictionary else {}


## Écrit la partie et attend que le fichier contienne [param flag] (ou, sans drapeau, que le
## fichier change).
func _save_now(fs: MemoryFs, flag: StringName = &"") -> Dictionary:
	var before: String = fs.files.get(BOOT_PATH, "")
	_boot.request_autosave("test J21")
	await wait_until(func() -> bool:
		if flag.is_empty():
			return fs.files.get(BOOT_PATH, "") != before
		return (_file(fs).get("flags", []) as Array).has(String(flag)), TIMEOUT)
	var saved := _file(fs)
	assert_eq(int(saved.get("version", 0)), SaveSystem.VERSION, "toujours v7 (v8 depuis le J23)")
	return saved


## Reprend la partie de [param fs] dans une Boot neuve.
func _reload(fs: MemoryFs) -> void:
	await _stop_boot()
	GameState.new_game(1)
	await _start_boot(fs)
	assert_true(_boot.has_resumed(), "sauvegarde reprise")
	assert_true(_boot.is_autosave_enabled(), "rien d'écarté")


func _place(cell: Vector2i, facing: Vector2i) -> void:
	_boot.get_map().spawn_player_at(_boot.get_player(), cell, facing)
	await wait_process_frames(3)


## Interagit, puis mène dialogues, choix ([param confirm]) et combat ([param flee] : FUITE ; sinon
## rien n'est piloté) jusqu'au calme.
func _play_out(confirm: bool = false) -> void:
	var cutscenes := _boot.get_cutscene_director()
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var box := _boot.get_dialogue_box()
	var runner := _boot.get_dialogue_runner()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	await wait_process_frames(3)
	while (cutscenes.is_running() or runner.is_running() or box.is_open()
			or battles.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		var battle := battles.get_battle() if battles.is_running() else null
		if battle != null and battle.get_state() == Battle.State.CHOOSING \
				and hud.get_zone() == BattleHud.Zone.ACTIONS:
			hud.action_selected.emit(ActionGrid.RUN)
		await wait_process_frames(1)
		if box.is_choice_showing():
			var cards := box.get_choice_cards()
			(cards.get_confirm_button() if confirm else cards.get_cancel_button()).pressed.emit()
		elif box.is_open() and not runner.is_awaiting_choice():
			box.advance_requested.emit()
	assert_false(cutscenes.is_running(), "scène finie")
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(5)


func _talk(confirm: bool = false) -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await _play_out(confirm)


func _blocked(cells: Array[Vector2i]) -> bool:
	var grid := _boot.get_map().get_grid()
	for cell: Vector2i in cells:
		if not grid.is_occupied(cell):
			return false
	return true


## n° 1 : après la victoire contre Ossatueur (fin de scène), avant le 7F.
func test_1_after_marowak_the_6f_reloads_calm_with_the_light_mist() -> void:
	await _start_boot(_fs, START_6F)
	GameState.flags.set_flag(&"ghost_marowak_calmed")
	GameState.flags.set_flag(&"tower_6f_mist_lifted")
	await _place(Vector2i(10, 16), Vector2i.DOWN)
	await _save_now(_fs, &"tower_6f_mist_lifted")
	await _reload(_fs)
	var map := _boot.get_map()
	assert_eq(map.map_id, &"pokemon_tower_6f", "reprise au 6F")
	assert_true(GameState.flags.has_flag(&"ghost_marowak_calmed"))
	assert_false((map.get_node(^"MistDenseGate") as CanvasItem).visible, "brume dense cachée")
	assert_true((map.get_node(^"MistLightGate") as CanvasItem).visible, "brume légère")
	var scene := _boot.get_cutscene_library().get_cutscene(&"tower_6f_ghost")
	assert_null(scene.pick(GameState.flags, GameState.bag), "aucun déclencheur ne joue")
	var stairs := map.get_warps().get_at(Vector2i(9, 16))
	assert_eq(stairs.size(), 1)
	if not stairs.is_empty():
		assert_eq(stairs[0].target_map, &"pokemon_tower_7f", "escalier vers le 7F")
	var objectives := ObjectiveLibrary.new()
	assert_true(objectives.load_file())
	assert_eq(objectives.current_id(GameState.flags), &"find_fuji", "« trouver M. Fuji… »")
	assert_push_error_count(0)


## n° 3 : sauvegarde « entre deux scènes » (`fuji_rescued`, pas de Flûte).
func test_3_between_the_two_scenes_fuji_gives_exactly_one_flute() -> void:
	await _start_boot(_fs, START_FUJI)
	assert_true(GameState.flags.has_flag(&"fuji_rescued"))
	assert_false(GameState.bag.has(FLUTE))
	await _save_now(_fs, &"fuji_rescued")
	await _reload(_fs)
	assert_eq(_boot.get_map().map_id, &"pokemon_house", "joueur dans la maison")
	assert_not_null(_boot.get_map().get_npc(&"mr_fuji"), "Fuji présent")
	assert_false(GameState.bag.has(FLUTE))
	await _place(Vector2i(7, 4), Vector2i.UP)
	await _talk()
	assert_eq(GameState.bag.count_of(FLUTE), 1, "une Flûte")
	assert_true(GameState.flags.has_flag(&"got_poke_flute"))
	_pages.clear()
	await _talk()
	assert_eq(GameState.bag.count_of(FLUTE), 1, "toujours une seule")
	assert_eq(_pages, [AFTER_TEXT] as Array[String], "§15.4.6")
	assert_push_error_count(0)


## n° 4 : après la remise.
func test_4_after_the_gift_nothing_replays() -> void:
	await _start_boot(_fs, START_FUJI)
	GameState.bag.add(FLUTE)
	GameState.flags.set_flag(&"got_poke_flute")
	await _save_now(_fs, &"got_poke_flute")
	await _reload(_fs)
	assert_eq(GameState.bag.count_of(FLUTE), 1)
	assert_true(GameState.flags.has_flag(&"got_poke_flute"))
	var scene := _boot.get_cutscene_library().get_cutscene(&"pokemon_house_flute")
	assert_null(scene.pick(GameState.flags, GameState.bag), "la scène ne se rejoue pas")
	# Le pas d'entrée (6..8, 7) ne joue rien.
	await _place(Vector2i(7, 8), Vector2i.UP)
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return _boot.get_player().get_cell() == Vector2i(7, 7), TIMEOUT)
	Input.action_release(&"move_up")
	await wait_process_frames(10)
	assert_false(_boot.get_cutscene_director().is_running(), "aucune scène")
	assert_eq(GameState.bag.count_of(FLUTE), 1)
	await _place(Vector2i(7, 4), Vector2i.UP)
	_pages.clear()
	await _talk()
	assert_eq(_pages, [AFTER_TEXT] as Array[String], "§15.4.6")
	assert_eq(GameState.bag.count_of(FLUTE), 1, "une seule Flûte")
	assert_push_error_count(0)


## n° 5 : après réveil + fuite (Ronflex du croisement de la Route 12).
func test_5_after_waking_and_fleeing_snorlax_stays_and_awake_is_gone() -> void:
	await _start_boot(_fs, START_ROUTE_12)
	SceneRouter.change_map(&"route_12", &"from_lavender", Vector2i.DOWN)
	await wait_until(func() -> bool: return (_boot.get_map().map_id == &"route_12"
		and _boot.is_stable() and not SceneRouter.is_transitioning()), TIMEOUT)
	await _place(FACE_12, Vector2i.DOWN)
	_boot.get_menu_director().key_item_requested.emit(FLUTE)
	await _play_out(true)
	assert_true(GameState.flags.has_flag(&"snorlax_route_12_woken"))
	await _save_now(_fs)
	await _reload(_fs)
	assert_eq(_boot.get_map().map_id, &"route_12")
	assert_false(GameState.flags.has_flag(&"snorlax_route_12_awake"), "`_awake` absent")
	assert_true(GameState.flags.has_flag(&"snorlax_route_12_woken"), "`_woken` présent")
	assert_false(GameState.flags.has_flag(&"snorlax_route_12_done"))
	assert_true(_blocked(SNORLAX_12), "Ronflex en place")
	await _place(FACE_12, Vector2i.DOWN)
	_pages.clear()
	await _talk(false)
	assert_eq(_pages.front() if not _pages.is_empty() else "", AGAIN_FIRST, "§15.7.5")
	assert_push_error_count(0)


## n° 7 : après capture (Ronflex de la Route 12) ; le Ronflex 16 ne change pas.
func test_7_after_the_capture_the_crossing_is_free_and_route_16_unchanged() -> void:
	await _start_boot(_fs, START_ROUTE_12)
	SceneRouter.change_map(&"route_12", &"from_lavender", Vector2i.DOWN)
	await wait_until(func() -> bool: return (_boot.get_map().map_id == &"route_12"
		and _boot.is_stable() and not SceneRouter.is_transitioning()), TIMEOUT)
	for flag: StringName in [&"snorlax_route_12_woken", &"snorlax_route_12_done",
			&"snorlax_route_12_caught"]:
		GameState.flags.set_flag(flag)
	GameState.storage.add(PokemonFactory.create(_boot.get_pokemon_data(), &"snorlax", 30,
		GameRng.new(3)))
	await _save_now(_fs, &"snorlax_route_12_caught")
	await _reload(_fs)
	assert_eq(_boot.get_map().map_id, &"route_12")
	assert_false(_blocked(SNORLAX_12), "passage libre")
	var gate := _boot.get_map().find_child("Ronflex", true, false) as FlagGate
	assert_false(gate.visible, "Ronflex absent")
	var found := false
	for pokemon: Pokemon in GameState.party.get_all() + GameState.storage.get_all():
		found = found or pokemon.species_id == &"snorlax"
	assert_true(found, "Ronflex dans l'équipe ou le Stockage")
	for suffix: String in ["awake", "woken", "done", "caught"]:
		assert_false(GameState.flags.has_flag(StringName("snorlax_route_16_%s" % suffix)),
			"Ronflex 16 inchangé : %s" % suffix)
	SceneRouter.change_map(&"route_16", &"from_celadon", Vector2i.LEFT)
	await wait_until(func() -> bool: return (_boot.get_map().map_id == &"route_16"
		and _boot.is_stable() and not SceneRouter.is_transitioning()), TIMEOUT)
	assert_true(_blocked(SNORLAX_16), "Ronflex 16 toujours là")
	assert_push_error_count(0)


## n° 9 : partie du J20 (Scope, aucun drapeau du J21) relue.
func test_9_a_jalon_20_save_reloads_unchanged_then_the_6f_reveals() -> void:
	await _start_boot(_fs, START_6F)
	for flag: StringName in J21_FLAGS:
		assert_false(GameState.flags.has_flag(flag), "partie du J20 : %s absent" % flag)
	assert_true(GameState.bag.has(SCOPE))
	var saved := await _save_now(_fs)
	for flag: StringName in J21_FLAGS:
		assert_does_not_have(saved.get("flags", []) as Array, String(flag), "fichier sans %s" % flag)
	await _reload(_fs)
	for flag: StringName in J21_FLAGS:
		assert_false(GameState.flags.has_flag(flag), "relue : %s absent" % flag)
	assert_eq(GameState.bag.count_of(SCOPE), 1, "Scope relu")
	assert_eq(_boot.get_map().map_id, &"pokemon_tower_6f")
	assert_true((_boot.get_map().get_node(^"MistDenseGate") as CanvasItem).visible,
		"brume dense")
	var scene := _boot.get_cutscene_library().get_cutscene(&"tower_6f_ghost")
	var variant := scene.pick(GameState.flags, GameState.bag)
	assert_same(variant, scene.variants[0], "révélation au 6F (variante A)")
	assert_true(variant != null and variant.if_items.has(SCOPE))
	assert_push_error_count(0)
