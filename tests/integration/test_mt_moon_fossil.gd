extends GutTest
## Le chercheur Gaspard et le choix du fossile (jalon 12, T25 ; `jalon-12.md` §2.12, §2.13, §4
## « 12C », dossier 15 §9, §20 n° 20–30) sur le vrai Boot, la vraie carte B2F et les départs
## `mt_moon_b2f` (avant R3) et `mt_moon_fossil` (chercheur battu, choix à faire) :
## - le déclencheur du bas du couloir ne joue **rien** tant que R3 n'est pas battu (ordre B-9) ;
## - après R3 : « ! », il vient au joueur, méprise (n° 20), combat inévitable, défaite (n° 21),
##   partage (n° 22), il se range en (15, 30) ; rechargé : rangé, il redit n° 22 ;
## - défaite du joueur : réveil, le chercheur reprend sa garde, réplique de reprise (n° 25) ;
## - fossiles sur la dalle : EXAMINER → « Prendre le … ? » ; NON → rien (on peut regarder
##   l'autre) ; OUI → objet clé, toast « … » / « obtenu », l'autre disparaît, n° 24, Grand moment
##   `fossil` unique ; **définitif** : rien ne redonne l'autre, même après rechargement ; le
##   chercheur dit ensuite n° 26.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const STARTS := "res://tools/debug_start/"
const SAVE_PATH := "user://test_mt_moon_fossil_save.json"
const FADE := 0.05
const TIMEOUT := 14.0
const SCENE_TIMEOUT_MS := 90000
const RESEARCHER_HOME := Vector2i(13, 31)
const RESEARCHER_AFTER := Vector2i(15, 30)
const ABOVE_TRIGGER := Vector2i(25, 26)
const TRIGGER := Vector2i(25, 27)
const DOME := Vector2i(24, 31)
const HELIX := Vector2i(26, 31)
const BEFORE: Array[String] = ["Encore un de ces voleurs ?!",
	"Ces fossiles, c'est moi\nqui les ai trouvés !"]
const DEFEATED := "D'accord, d'accord !\nTu n'es pas avec eux."
const SHARE: Array[String] = ["Sans toi, ils les auraient emportés.", "Un fossile chacun. Choisis."]
const REMATCH := "Tu es revenu ?\nTu ne les auras pas !"
const CHOSEN: Array[String] = ["Alors je garde celui-ci.", "Prends-en soin."]
const LATER := "Je vais les étudier de près."

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _pages: Array[String] = []
var _speakers: Array[String] = []
var _scenes: Array[StringName] = []
var _toasts: Array[PackedStringArray] = []
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-14T16:00:00")
	Haptics.sink = func(_ms: int) -> void: pass
	_fs = MemoryFs.new()
	_clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Haptics.reset()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


func _clear() -> void:
	_pages.clear()
	_speakers.clear()
	_scenes.clear()
	_toasts.clear()


## Boot sur le départ [param start] (drapeaux [param flags] en plus ; équipe forte si
## [param strong]) si [param fresh], sinon la partie relue de la sauvegarde en mémoire.
func _start(start: String, fresh: bool = true, flags: Array[StringName] = [],
		strong: bool = true) -> void:
	var json: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(STARTS + start + ".json"))
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = StringName(json["map"])
	_boot.start_spawn = StringName(json["spawn"])
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		var data := DebugStart.new()
		assert_true(data.load_file(STARTS + start + ".json", _boot.get_pokemon_data(),
			_boot.get_item_library()), "\n".join(data.get_errors()))
		data.apply(GameState, _boot.get_pokemon_data())
		GameState.rng = GameRng.new(11)
		for flag: StringName in flags:
			GameState.flags.set_flag(flag)
		_set_party(40 if strong else 4)
		_boot.get_map().refresh_npcs(GameState.flags)
		_boot.get_companion_controller().refresh()
	_boot.get_battle_director().speed_scale = 0.0
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_runner.get_session().get_text())
		_speakers.append(_runner.get_session().get_speaker()))
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _scenes.append(id))
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_toasts.append(PackedStringArray([title, detail])))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)


## Une Salamèche seule : Nv. 40 (Flammèche, chaque combat gagné) ou Nv. 4 (Rugissement, perdu).
func _set_party(level: int) -> void:
	var mon := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", level,
		GameState.rng)
	mon.moves.clear()
	mon.moves.append(MoveSlot.new(&"ember" if level >= 10 else &"growl", 25))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(mon)
	GameState.companion_uid = ""


func _reload() -> void:
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	_clear()
	await _start("mt_moon_fossil", false)


func _put(cell: Vector2i, facing: Vector2i) -> void:
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


## Un pas réel vers le bas, du haut du déclencheur sur le déclencheur.
func _step_on_the_trigger() -> void:
	await _put(ABOVE_TRIGGER, Vector2i.DOWN)
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return _player.get_cell() == TRIGGER, TIMEOUT)
	Input.action_release(&"move_down")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	await wait_process_frames(5)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_process_frames(2)


## Déroule la scène ou le dialogue en cours : pages avancées, combat piloté, choix répondu par
## [param answer].
func _finish(answer: bool = false) -> void:
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or _runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		if battles.is_running():
			var battle := battles.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match hud.get_zone():
					BattleHud.Zone.ACTIONS:
						hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						hud.move_selected.emit(0)
		await wait_process_frames(1)
		if _runner.is_awaiting_choice():
			_runner.choose(answer)
		elif box.is_open():
			box.advance_requested.emit()
	await wait_process_frames(5)
	assert_false(director.is_running(), "scène finie")
	assert_false(_runner.is_running(), "dialogue fini")


## Examine le fossile [param cell] depuis [param stand] et répond [param answer].
func _choose(cell: Vector2i, stand: Vector2i, answer: bool) -> void:
	await _put(stand, cell - stand)
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target, "%s : une cible" % cell)
	if target == null:
		return
	assert_eq(target.kind, Interaction.Kind.EXAMINE, "verbe EXAMINER")
	await _press_interact()
	await _finish(answer)


func _moments() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for moment: Dictionary in GameState.moments:
		if moment.get("type", "") == "fossil":
			found.append(moment)
	return found


# --- Le chercheur --------------------------------------------------------------------------

func test_the_trigger_plays_nothing_before_the_guardian_is_beaten() -> void:
	await _start("mt_moon_b2f")
	assert_not_null(_boot.get_map().get_npc(&"mt_moon_researcher"), "il garde le goulet")
	assert_eq(_boot.get_map().get_npc(&"mt_moon_researcher").get_cell(), RESEARCHER_HOME)
	await _step_on_the_trigger()
	assert_eq(_scenes, [] as Array[StringName], "rien avant R3 (B-9)")
	assert_true(_player.is_input_enabled())


func test_mistaken_then_battle_then_share_and_he_steps_aside() -> void:
	await _start("mt_moon_b2f", true, [&"beaten_mt_moon_rocket_3"] as Array[StringName])
	var map := _boot.get_map()
	assert_null(map.get_npc(&"rocket_gardien"), "R3 parti")
	assert_not_null(map.get_npc(&"fossile_dome"), "les fossiles sur la dalle")
	await _step_on_the_trigger()
	assert_eq(_scenes, [&"mt_moon_researcher"] as Array[StringName], "le chercheur sort")
	await _finish()
	assert_true(GameState.flags.has_flag(&"beaten_mt_moon_researcher"), "battu")
	assert_eq(_pages, BEFORE + [DEFEATED] + SHARE, "méprise, défaite, partage")
	assert_eq(_speakers[0], "Chercheur Gaspard")
	var researcher := map.get_npc(&"mt_moon_researcher")
	assert_not_null(researcher)
	if researcher != null:
		assert_eq(researcher.get_cell(), RESEARCHER_AFTER, "rangé en (15, 30)")
		assert_eq(researcher.get_facing(), Vector2i.RIGHT, "tourné vers la dalle")
	assert_true(_player.is_input_enabled(), "joueur libre")
	# Rechargement : rangé, il redit le partage ; le déclencheur ne rejoue rien.
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	_clear()
	await _start("mt_moon_b2f", false)
	map = _boot.get_map()
	assert_null(map.get_npc(&"mt_moon_researcher"), "plus au goulet")
	var after := map.get_npc(&"mt_moon_researcher_after")
	assert_not_null(after, "rangé")
	if after != null:
		assert_eq(after.get_cell(), RESEARCHER_AFTER)
	await _step_on_the_trigger()
	assert_eq(_scenes, [] as Array[StringName], "pas deux fois")
	await _put(RESEARCHER_AFTER + Vector2i.RIGHT, Vector2i.LEFT)
	await _press_interact()
	await _finish()
	assert_eq(_pages, SHARE, "avant le choix : n° 22")


func test_a_defeat_then_the_researcher_says_his_rematch_line() -> void:
	await _start("mt_moon_b2f", true, [&"beaten_mt_moon_rocket_3"] as Array[StringName], false)
	await _step_on_the_trigger()
	await _finish()
	assert_false(GameState.flags.has_flag(&"beaten_mt_moon_researcher"), "pas battu")
	assert_true(GameState.flags.has_flag(&"lost_mt_moon_researcher"), "défaite notée")
	assert_ne(_boot.get_map().map_id, &"mt_moon_b2f", "réveil au point de repos")
	_clear()
	await SceneRouter.change_map(&"mt_moon_b2f", &"arrivee_d", Vector2i.DOWN)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	var researcher := _boot.get_map().get_npc(&"mt_moon_researcher")
	assert_not_null(researcher, "il reprend sa garde")
	if researcher != null:
		assert_eq(researcher.get_cell(), RESEARCHER_HOME)
	await _step_on_the_trigger()
	await wait_until(func() -> bool: return not _pages.is_empty(), TIMEOUT)
	assert_eq(_pages[0], REMATCH, "n° 25")
	assert_false(_pages.has(BEFORE[0]), "pas la méprise")
	await _finish()


# --- Le choix du fossile -------------------------------------------------------------------

func test_no_does_nothing_then_yes_takes_the_dome_for_good() -> void:
	await _start("mt_moon_fossil")
	var map := _boot.get_map()
	assert_not_null(map.get_npc(&"fossile_dome"))
	assert_not_null(map.get_npc(&"fossile_nautile"))
	# NON : rien, on peut regarder l'autre.
	await _choose(DOME, DOME + Vector2i.UP, false)
	assert_eq(_pages, ["Prendre le Fossile Dôme ?"] as Array[String], "n° 23")
	await _choose(HELIX, HELIX + Vector2i.DOWN, false)
	assert_eq(_pages, ["Prendre le Fossile Dôme ?", "Prendre le Fossile Nautile ?"]
		as Array[String])
	assert_eq(_scenes, [] as Array[StringName], "NON : aucune scène")
	assert_not_null(map.get_npc(&"fossile_dome"), "toujours là")
	assert_not_null(map.get_npc(&"fossile_nautile"), "toujours là")
	assert_eq(GameState.bag.count_of(&"dome_fossil"), 0)
	assert_false(GameState.flags.has_flag(&"mt_moon_fossil_chosen"))
	# Rechargement entre deux : rien n'a changé.
	await _reload()
	assert_not_null(_boot.get_map().get_npc(&"fossile_dome"), "rechargé : les deux fossiles")
	assert_not_null(_boot.get_map().get_npc(&"fossile_nautile"))
	# OUI sur le Dôme.
	await _choose(DOME, DOME + Vector2i.DOWN, true)
	map = _boot.get_map()
	assert_eq(_scenes, [&"mt_moon_fossil_dome"] as Array[StringName])
	assert_eq(GameState.bag.count_of(&"dome_fossil"), 1, "objet clé")
	assert_eq(GameState.bag.count_of(&"helix_fossil"), 0, "pas l'autre")
	assert_true(GameState.flags.has_flag(&"mt_moon_fossil_chosen"))
	assert_true(GameState.flags.has_flag(&"mt_moon_got_dome_fossil"))
	assert_null(map.get_npc(&"fossile_dome"), "pris")
	assert_null(map.get_npc(&"fossile_nautile"), "le chercheur garde l'autre")
	assert_eq(_toasts, [PackedStringArray(["Fossile Dôme", "obtenu"])], "toast n° 27")
	assert_true(_pages.slice(1) == CHOSEN, "n° 24")
	var moments := _moments()
	assert_eq(moments.size(), 1, "Grand moment unique")
	if moments.size() == 1:
		assert_eq(moments[0]["details"], {"item": "dome_fossil"})
		assert_eq(moments[0]["map"], "mt_moon_b2f")
	assert_true(_player.is_input_enabled(), "joueur libre")
	# Définitif : rechargé, plus aucun fossile, le chercheur dit n° 26.
	await _reload()
	assert_null(_boot.get_map().get_npc(&"fossile_dome"))
	assert_null(_boot.get_map().get_npc(&"fossile_nautile"))
	await _put(DOME + Vector2i.DOWN, Vector2i.UP)
	assert_null(_boot.get_interaction_controller().get_target(), "la dalle est vide")
	await _put(RESEARCHER_AFTER + Vector2i.RIGHT, Vector2i.LEFT)
	await _press_interact()
	await _finish()
	assert_eq(_pages, [LATER] as Array[String], "n° 26")
	assert_eq(GameState.bag.count_of(&"dome_fossil"), 1)
	assert_eq(GameState.bag.count_of(&"helix_fossil"), 0)
	assert_eq(_moments().size(), 1, "toujours un seul Grand moment")


func test_yes_on_the_helix() -> void:
	await _start("mt_moon_fossil")
	await _choose(HELIX, HELIX + Vector2i.UP, true)
	assert_eq(_scenes, [&"mt_moon_fossil_helix"] as Array[StringName])
	assert_eq(GameState.bag.count_of(&"helix_fossil"), 1)
	assert_eq(GameState.bag.count_of(&"dome_fossil"), 0)
	assert_true(GameState.flags.has_flag(&"mt_moon_got_helix_fossil"))
	assert_null(_boot.get_map().get_npc(&"fossile_dome"))
	assert_null(_boot.get_map().get_npc(&"fossile_nautile"))
	assert_eq(_toasts, [PackedStringArray(["Fossile Nautile", "obtenu"])])
	var moments := _moments()
	assert_eq(moments.size(), 1)
	if moments.size() == 1:
		assert_eq(moments[0]["details"], {"item": "helix_fossil"})
	await _reload()
	assert_null(_boot.get_map().get_npc(&"fossile_dome"), "définitif")
	assert_eq(GameState.bag.count_of(&"helix_fossil"), 1)
