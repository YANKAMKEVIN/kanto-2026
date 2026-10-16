extends GutTest
## La Grotte Sombre est obscure dans le vrai Boot (jalon 18, `jalon-18.md` §3, §6 ; moteur du J17 :
## [FlashRules], [FlashDirector], [DarknessController]) : sans Flash, voile sombre et « Il fait très
## sombre ici… » (T-3) une fois par entrée ; avec la CS05 et un compatible, Flash automatique
## (« {pokemon} utilise Flash ! », T-2), halo ouvert ; changement d'étage → rallumée ; Corde
## Sortie → Route 10 devant l'entrée nord, voile retiré ; Mont Sélénite toujours sans voile.
## Départs écrits à la volée d'après `tools/debug_start/flash_qa.json` (CS05, Pikachu compagnon).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BASE_START := "res://tools/debug_start/flash_qa.json"
const START_PATH := "user://test_dark_cave_flash_start.json"
const FADE := 0.05
const TIMEOUT := 12.0
const ROPE := &"escape_rope"

var _boot: Boot
var _fades: Array[float] = []
var _dialogues: Array[StringName] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-16T10:00:00")
	_dialogues.clear()


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"interact"]:
		Input.action_release(action)
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	if FileAccess.file_exists(START_PATH):
		DirAccess.remove_absolute(START_PATH)


## Départ de débogage sur [param spawn] de [param map_id] ; [param with_hm05] faux : sans CS05.
func _start(map_id: String, spawn: String, facing: String, with_hm05: bool) -> void:
	var start: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE_START))
	start["map"] = map_id
	start["spawn"] = spawn
	start["facing"] = facing
	if not with_hm05:
		(start["flags"] as Array).erase("got_hm05")
		(start["bag"] as Dictionary).erase("hm05")
	var file := FileAccess.open(START_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(start))
	file.close()
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), "user://test_dark_cave_flash_save.json")
	_boot.force_debug_start = true
	_boot.debug_start_path = START_PATH
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_dialogue_runner().dialogue_started.connect(_dialogues.append)
	await wait_process_frames(2)
	await _settle()


## Partie stable, sans action de Flash en attente (ou un dialogue ouvert).
func _settle() -> void:
	var flash := _boot.get_flash_director()
	await wait_until(func() -> bool: return not flash.is_pending() and not flash.is_running() \
		and _boot.is_stable() or _boot.get_dialogue_runner().is_running(), TIMEOUT)


func _walk_to(direction: Vector2i, map_id: StringName) -> void:
	assert_true(_boot.get_player().script_step(direction), "pas %s" % direction)
	await wait_until(func() -> bool: return _boot.get_map().map_id == map_id \
		and not SceneRouter.is_transitioning(), TIMEOUT)
	await wait_process_frames(2)
	await _settle()


func _close_dialogue() -> void:
	var runner := _boot.get_dialogue_runner()
	for i: int in 10:
		await wait_process_frames(3)
		if not runner.is_running():
			return
		Input.action_press(&"interact")
		await wait_process_frames(2)
		Input.action_release(&"interact")
	assert_false(runner.is_running(), "dialogue fermé")


func _caption_text() -> String:
	var caption := _boot.get_hud().find_child("WorldCaption", true, false) as Label
	return caption.text if caption != null else ""


func _warnings() -> int:
	return _dialogues.count(FlashDirector.WARN_DIALOGUE)


# --- Données -----------------------------------------------------------------------------------

func test_dark_cave_is_dark_and_mt_moon_is_not() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file(), "\n".join(caves.get_errors()))
	for map_id: StringName in [&"dark_cave_1f", &"dark_cave_b1f"]:
		assert_true(caves.is_dark(map_id), String(map_id))
	for map_id: StringName in [&"mt_moon_1f", &"mt_moon_b1f", &"mt_moon_b2f", &"route_10"]:
		assert_false(caves.is_dark(map_id), String(map_id))


func test_entry_actions_auto_warn_none() -> void:
	var caves := CaveLibrary.new()
	caves.load_file()
	var auto := FlashRules.Entry.AUTO
	var warn := FlashRules.Entry.WARN
	var none := FlashRules.Entry.NONE
	assert_eq(FlashRules.entry_action(&"route_10", &"dark_cave_1f", caves, true), auto)
	assert_eq(FlashRules.entry_action(&"route_10", &"dark_cave_1f", caves, false), warn)
	assert_eq(FlashRules.entry_action(&"dark_cave_1f", &"dark_cave_b1f", caves, true), auto,
		"changement d'étage : rallumée")
	assert_eq(FlashRules.entry_action(&"", &"dark_cave_b1f", caves, false), warn, "reprise")
	assert_eq(FlashRules.entry_action(&"dark_cave_1f", &"route_10", caves, true), none)
	assert_eq(FlashRules.entry_action(&"route_3", &"mt_moon_1f", caves, true), none)
	assert_eq(FlashRules.entry_action(&"route_3", &"mt_moon_1f", caves, false), none)


## T-2 du J18 = T-17 du J17 (bandeau des données de [FieldMoves]) ; T-3 = l'avertissement du J17.
func test_texts_t2_and_t3() -> void:
	var moves := FieldMoves.new()
	assert_true(moves.load_file())
	assert_eq(moves.cue_text(&"flash", "Pikachu"), "Pikachu utilise Flash !")
	var library := DialogueLibrary.new()
	library.load_dir()
	var dialogue := library.get_dialogue(FlashDirector.WARN_DIALOGUE)
	assert_not_null(dialogue)
	var texts: PackedStringArray = []
	for page: DialoguePage in dialogue.variants[0].pages:
		texts.append(page.text.replace("\n", " "))
	var text := " ".join(texts)
	assert_eq(text, "Il fait très sombre ici… Mieux vaut avancer prudemment.")


# --- Vrai Boot ---------------------------------------------------------------------------------

func test_without_flash_dark_veil_and_one_warning() -> void:
	await _start("route_10", "from_dark_cave_n_w", "up", false)
	var darkness := _boot.get_darkness()
	var flash := _boot.get_flash_director()
	assert_false(flash.is_available(), "sans CS05")
	assert_false(darkness.is_dark(), "Route 10 : aucun voile")
	await _walk_to(Vector2i.UP, &"dark_cave_1f")
	assert_true(_boot.get_dialogue_runner().is_running(), "avertissement")
	assert_eq(_boot.get_dialogue_runner().get_dialogue_id(), FlashDirector.WARN_DIALOGUE)
	await _close_dialogue()
	await _settle()
	assert_true(darkness.is_dark(), "voile posé")
	assert_true(darkness.get_veil().visible)
	assert_false(darkness.is_lit(), "halo sombre")
	assert_eq(flash.get_cue_count(), 0)
	await wait_process_frames(10)
	assert_eq(_warnings(), 1, "une fois par entrée")


func test_with_flash_auto_relit_on_floor_change() -> void:
	await _start("route_10", "from_dark_cave_n_w", "up", true)
	var darkness := _boot.get_darkness()
	var flash := _boot.get_flash_director()
	assert_true(flash.is_available(), "CS05 au Sac, Pikachu compatible")
	var banners: Array[String] = []
	flash.flash_used.connect(func(_map_id: StringName) -> void:
		banners.append(_caption_text()))
	await _walk_to(Vector2i.UP, &"dark_cave_1f")
	await wait_until(func() -> bool: return flash.get_cue_count() == 1 \
		and not flash.is_running() and _boot.is_stable(), TIMEOUT)
	assert_true(darkness.is_dark())
	assert_true(darkness.is_lit(), "AUTO : halo de Flash ouvert")
	assert_eq(banners, ["Pikachu utilise Flash !"] as Array[String], "T-2")
	assert_eq(_warnings(), 0, "aucun avertissement")
	# Changement d'étage (échelle A) : nouvelle arrivée, Flash se rallume.
	SceneRouter.change_map(&"dark_cave_b1f", &"arrivee_a", Vector2i.DOWN)
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"dark_cave_b1f" \
		and flash.get_cue_count() == 2 and not flash.is_running() and _boot.is_stable(),
		TIMEOUT)
	assert_true(darkness.is_dark())
	assert_true(darkness.is_lit(), "B1F : rallumée")
	assert_eq(_warnings(), 0)


func test_escape_rope_leads_to_route_10_north_entrance_without_veil() -> void:
	await _start("dark_cave_b1f", "arrivee_b", "down", true)
	var darkness := _boot.get_darkness()
	var flash := _boot.get_flash_director()
	await wait_until(func() -> bool: return flash.get_cue_count() == 1 \
		and not flash.is_running() and _boot.is_stable(), TIMEOUT)
	assert_true(darkness.is_lit(), "reprise dans la grotte : rallumée")
	var ropes := GameState.bag.count_of(ROPE)
	var menu := _boot.get_menu_director()
	assert_true(menu.open(), "le menu s'ouvre")
	menu.request_item_use(ROPE)
	await wait_process_frames(2)
	await _close_dialogue()
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"route_10" \
		and _boot.is_stable(), TIMEOUT)
	var route := _boot.get_map()
	assert_eq(_boot.get_player().get_cell(), route.get_spawn_cell(&"from_dark_cave_n_w"),
		"devant l'entrée nord")
	assert_eq(_boot.get_player().get_facing(), Vector2i.DOWN)
	assert_eq(GameState.bag.count_of(ROPE), ropes - 1)
	assert_false(darkness.is_dark(), "voile retiré")
	assert_false(darkness.get_veil().visible)


func test_mt_moon_has_no_veil_even_with_flash() -> void:
	await _start("mt_moon_1f", "arrivee_a", "down", true)
	await wait_process_frames(10)
	assert_eq(_boot.get_map().map_id, &"mt_moon_1f")
	assert_false(_boot.get_darkness().is_dark(), "Mont Sélénite : jamais de voile")
	assert_eq(_boot.get_flash_director().get_cue_count(), 0, "ni Flash")
	assert_eq(_warnings(), 0, "ni avertissement")


## Corde Sortie depuis la moitié sud du 1F (arrivée de l'échelle B) : devant l'entrée nord,
## côté Route 10, tourné vers le sud (dossier 21 §5.6, I-11).
func test_escape_rope_from_the_south_half_leads_to_the_north_entrance() -> void:
	await _start("dark_cave_1f", "arrivee_b", "left", true)
	assert_eq(_boot.get_map().map_id, &"dark_cave_1f")
	assert_gt(_boot.get_player().get_cell().y, 31, "moitié sud")
	var ropes := GameState.bag.count_of(ROPE)
	assert_true(_boot.get_menu_director().open(), "le menu s'ouvre")
	_boot.get_menu_director().request_item_use(ROPE)
	await wait_process_frames(2)
	await _close_dialogue()
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"route_10" \
		and _boot.is_stable(), TIMEOUT)
	assert_eq(_boot.get_player().get_cell(),
		_boot.get_map().get_spawn_cell(&"from_dark_cave_n_w"), "devant l'entrée nord")
	assert_eq(_boot.get_player().get_facing(), Vector2i.DOWN)
	assert_eq(GameState.bag.count_of(ROPE), ropes - 1)
	assert_false(_boot.get_darkness().is_dark(), "voile retiré")


## G-1 Roger voit le joueur dans le premier couloir et engage le combat (sans Flash, sous le
## voile : les personnages sont sous le voile, la bulle « ! » au-dessus).
func test_roger_spots_the_player_under_the_veil() -> void:
	await _start("dark_cave_1f", "from_route_10_n_w", "down", false)
	await _close_dialogue()
	var darkness := _boot.get_darkness()
	assert_true(darkness.is_dark())
	_boot.get_map().spawn_player_at(_boot.get_player(), Vector2i(27, 7), Vector2i.DOWN)
	await wait_process_frames(3)
	_dialogues.clear()
	assert_true(_boot.get_player().script_step(Vector2i.DOWN), "pas dans sa vue")
	await wait_until(func() -> bool: return &"dark_cave_roger_before" in _dialogues, TIMEOUT)
	assert_true(&"dark_cave_roger_before" in _dialogues, "Roger engage (T-51)")
	var roger := _boot.get_map().get_npc(&"g1_roger")
	assert_not_null(roger)
	assert_lt(roger.z_index, WorldLighting.Z_VEIL, "Roger sous le voile")
