extends GutTest
## Corde Sortie dans le vrai Boot (jalon 12, T20 ; `jalon-12.md` §2.6, dossier 15 §11, §20
## n° 33–34) : Sac → UTILISER. Hors grotte (Route 3, Argenta, Centre du Mont Sélénite) : bandeau
## « Impossible de l'utiliser ici. », rien ne change. Dans chaque étage (1F ; B1F ; B2F après
## l'événement) : menu fermé, « Tu utilises la Corde Sortie. », fondu, devant l'entrée côté
## Route 3 tourné ↓, une Corde de moins, ni soin ni point de repos, drapeaux et objets gardés ;
## pendant le fondu, la sauvegarde est encore celle d'avant (Corde comprise, dans la grotte) ;
## à l'arrivée, l'autosave écrit la Route 3 et la Corde en moins ensemble.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const SAVE_PATH := "user://test_escape_rope_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
const ROPE := &"escape_rope"
const EXIT_CELL := Vector2i(73, 10)
## Drapeaux d'une partie au Mont Sélénite (prologue fait, badge, un Dresseur battu, un objet
## ramassé).
const FLAGS: Array[StringName] = [&"mom_greeted", &"starter_chosen", &"rival_battle_done",
	&"rival_challenged", &"pewter_badge", &"beaten_route_3_hugo", &"got_mt_moon_1f_item_1"]

var _boot: Boot
var _fades: Array[float] = []
var _fs: MemoryFs
var _results: Array[String] = []
var _dialogues: Array[StringName] = []
## Contenu de la sauvegarde relevé à l'écran noir du fondu (fermeture simulée à ce moment).
var _save_at_black: Dictionary = {}


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-13T10:00:00")
	_fs = MemoryFs.new()
	_results.clear()
	_dialogues.clear()
	_save_at_black = {}


func after_each() -> void:
	Input.action_release(&"interact")
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


## Partie sauvegardée sur [param spawn] de [param map_id] (Charmander Nv. 15 blessé, deux Cordes,
## point de repos au Centre d'Argenta), reprise par un vrai Boot.
func _resume_at(map_id: StringName, spawn: StringName, extra_flags: Array[StringName] = []) \
		-> void:
	var data := PokemonData.new()
	data.load_dir()
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-13T09:00:00")
	state.new_game(42)
	for flag: StringName in FLAGS + extra_flags:
		state.flags.set_flag(flag)
	var lead := PokemonFactory.create(data, &"charmander", 15, GameRng.new(3))
	lead.hp = 7
	state.party.add(lead)
	state.bag.add(ROPE, 2)
	state.bag.add(&"potion", 3)
	state.heal_map = &"pewter_center"
	state.heal_spawn = &"heal"
	state.record_item_found(ROPE, &"mt_moon_1f")
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	var cell := map.get_spawn_cell(spawn)
	map.free()
	state.set_player_location(map_id, cell, Vector2i.DOWN)
	assert_eq(SaveSystem.new(_fs, SAVE_PATH).write(state.to_dict()), OK)
	await _start(&"player_house_2f", &"start")
	assert_true(_boot.has_resumed(), "partie reprise")
	assert_eq(_boot.get_map().map_id, map_id)


func _start(map: StringName, spawn: StringName) -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	# L'autosave de l'arrivée est écrit à la première image stable.
	await wait_process_frames(3)
	var menu := _boot.get_menu_director()
	menu.bag_result_shown.connect(func(text: String, _repeat: bool) -> void:
		_results.append(text))
	_boot.get_dialogue_runner().dialogue_started.connect(_dialogues.append)


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.read_text(SAVE_PATH))
	return parsed if parsed is Dictionary else {}


func _saved_ropes(save: Dictionary) -> int:
	return int(((save.get("bag", {}) as Dictionary).get("items", {}) as Dictionary).get(
		String(ROPE), 0))


## Ferme la narration en cours (appuis successifs).
func _close_dialogue() -> void:
	var runner := _boot.get_dialogue_runner()
	for i: int in 10:
		await wait_process_frames(3)
		if not runner.is_running():
			return
		Input.action_press(&"interact")
		await wait_process_frames(2)
		Input.action_release(&"interact")
	assert_false(runner.is_running(), "narration fermée")


## UTILISER la Corde depuis le Sac (menu ouvert comme le joueur le ferait).
func _use_rope() -> void:
	var menu := _boot.get_menu_director()
	assert_true(menu.open(), "le menu s'ouvre")
	menu.request_item_use(ROPE)


func _use_rope_in_cave(map_id: StringName, spawn: StringName,
		extra_flags: Array[StringName] = []) -> void:
	await _resume_at(map_id, spawn, extra_flags)
	var before := _saved()
	assert_eq(StringName(before.get("map", "")), map_id, "sauvegarde d'avant : dans la grotte")
	assert_eq(_saved_ropes(before), 2)
	var lead: Pokemon = GameState.party.get_at(0)
	SceneRouter.map_changed.connect(func(_m: GameMap) -> void: _save_at_black = _saved(),
		CONNECT_ONE_SHOT)
	await _use_rope()
	assert_false(_boot.get_menu_director().is_open(), "menu fermé")
	assert_eq(_dialogues, [Boot.ESCAPE_ROPE_DIALOGUE] as Array[StringName],
		"« Tu utilises la Corde Sortie. »")
	assert_eq(GameState.bag.count_of(ROPE), 2, "pas encore retirée pendant la narration")
	await _close_dialogue()
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"route_3" \
		and _boot.is_stable(), TIMEOUT)
	var player := _boot.get_player()
	assert_eq(player.get_cell(), EXIT_CELL, "devant l'entrée côté Route 3")
	assert_eq(player.get_facing(), Vector2i.DOWN, "tourné vers le sud")
	assert_eq(GameState.bag.count_of(ROPE), 1, "une Corde de moins")
	assert_eq(GameState.bag.count_of(&"potion"), 3)
	assert_eq(lead.hp, 7, "ni soin")
	assert_eq([GameState.heal_map, GameState.heal_spawn], [&"pewter_center", &"heal"],
		"ni point de repos")
	for flag: StringName in FLAGS + extra_flags:
		assert_true(GameState.flags.has_flag(flag), "%s gardé" % flag)
	assert_eq(GameState.found_items.size(), 1, "objets trouvés gardés")
	# Fermeture pendant le fondu : la sauvegarde d'avant, Corde comprise.
	assert_eq(StringName(_save_at_black.get("map", "")), map_id, "écran noir : encore la grotte")
	assert_eq(_saved_ropes(_save_at_black), 2, "écran noir : Corde comprise")
	# Arrivée : position et Sac écrits ensemble.
	await wait_process_frames(3)
	var after := _saved()
	assert_eq(StringName(after.get("map", "")), &"route_3")
	assert_eq(JsonFields.get_vector2i(after, "cell"), EXIT_CELL)
	assert_eq(_saved_ropes(after), 1)
	assert_eq(_results, [] as Array[String], "aucun refus")


# --- Refus ------------------------------------------------------------------------------------

func _refused_on(map_id: StringName, spawn: StringName) -> void:
	await _start(map_id, spawn)
	GameState.bag.add(ROPE, 2)
	var cell := _boot.get_player().get_cell()
	await _use_rope()
	await wait_process_frames(2)
	assert_eq(_results, ["Impossible de l'utiliser ici."] as Array[String], String(map_id))
	assert_true(_boot.get_menu_director().is_open(), "le Sac reste ouvert")
	assert_eq(GameState.bag.count_of(ROPE), 2, "rien consommé")
	assert_false(SceneRouter.is_transitioning(), "aucun départ")
	assert_eq(_boot.get_map().map_id, map_id)
	assert_eq(_boot.get_player().get_cell(), cell)
	assert_eq(_dialogues, [] as Array[StringName], "aucune narration")
	_boot.get_menu_director().close()


func test_refused_on_route_3() -> void:
	await _refused_on(&"route_3", &"from_mt_moon_w")


func test_refused_in_pewter_city() -> void:
	await _refused_on(&"pewter_city", &"from_route_3_c")


func test_refused_in_the_mt_moon_center() -> void:
	await _refused_on(&"mt_moon_center", &"heal")


# --- Grotte -----------------------------------------------------------------------------------

func test_from_1f() -> void:
	await _use_rope_in_cave(&"mt_moon_1f", &"arrivee_a")


func test_from_b1f() -> void:
	await _use_rope_in_cave(&"mt_moon_b1f", &"arrivee_b", [&"beaten_mt_moon_rocket_1"])


func test_from_b2f_after_the_event_goes_back_to_route_3_not_the_gate() -> void:
	await _use_rope_in_cave(&"mt_moon_b2f", &"arrivee_s", [&"beaten_mt_moon_rocket_1",
		&"beaten_mt_moon_rocket_3", &"beaten_mt_moon_researcher", &"mt_moon_fossil_chosen"])


func test_last_rope_leaves_the_bag() -> void:
	await _resume_at(&"mt_moon_1f", &"arrivee_a")
	GameState.bag.remove(ROPE, 1)
	await _use_rope()
	await _close_dialogue()
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"route_3" \
		and _boot.is_stable(), TIMEOUT)
	assert_false(GameState.bag.has(ROPE), "plus de Corde")
