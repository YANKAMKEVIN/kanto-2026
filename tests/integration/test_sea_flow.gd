extends GutTest
## Surf de bout en bout dans le vrai Boot (passe systèmes 2, §2.5, §2.6, T14, T15) : montée depuis
## la plage, nage, courant joué jusqu'au passage (→ `essai_mer_2`, toujours en Surf), bord de carte
## en mer (monture transmise), descente sur la rive, sauvegarde en mer puis reprise, appui long
## « Pêcher / Surfer ». Ancien `test_qa_sea_flow.gd` : la carte de QA `qa_sea` et le départ
## `s2_surf` sont retirés en S2Z (T33) ; la mer d'essai est construite en mémoire
## (`tests/helpers/sea_rig.gd`, branché sur [member SceneRouter.map_factory]) et le départ est
## écrit sous `user://`. Rien n'est livré.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SeaRig := preload("res://tests/helpers/sea_rig.gd")
const START := "user://test_sea_flow_start.json"
const SAVE_PATH := "user://test_sea_flow_save.json"
## Départ (ancien `s2_surf`) : Carapuce (CS03), Badge Âme, les trois cannes.
const START_DATA := {
	"map": "essai_mer", "spawn": "depart", "facing": "up",
	"flags": ["mom_greeted", "rival_met", "oak_met", "oak_lab_reunion", "starter_offered",
		"starter_chosen", "taken_charmander", "taken_squirtle", "rival_lab_won",
		"rival_challenged", "rival_battle_done", "rival_left_lab", "viridian_arrived",
		"got_oak_parcel", "pokedex_activated", "poison_unlocked", "badge_soul"],
	"party": [{"species": "squirtle", "level": 20}, {"species": "pikachu", "level": 18}],
	"companion": 0,
	"bag": {"hm03": 1, "old_rod": 1, "good_rod": 1, "super_rod": 1, "poke_ball": 10,
		"potion": 5},
	"money": 3000,
}
const TIMEOUT := 15.0

var _fs := MemoryFs.new()
var _boot: Boot
var _player: Player
var _fades: Array[float] = []


func before_each() -> void:
	_fs = MemoryFs.new()
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = 0.02
	SceneRouter.fade_in_duration = 0.02
	SceneRouter.map_factory = SeaRig.factory()
	var file := FileAccess.open(START, FileAccess.WRITE)
	file.store_string(JSON.stringify(START_DATA))
	file.close()
	await _start()


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	SceneRouter.map_factory = Callable()
	if FileAccess.file_exists(START):
		DirAccess.remove_absolute(START)


func _start(saved: bool = false) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	if not saved:
		_boot.start_map = SeaRig.SEA
		_boot.start_spawn = &"depart"
		_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	if not saved:
		var start := DebugStart.new()
		assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
		GameState.flags.set_flag(MountDirector.SURF_FIRST_FLAG)
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_boot.get_encounter_director().enabled = false


func _walk(direction: Vector2i, count: int) -> void:
	for i: int in count:
		await wait_until(func() -> bool: return not _player.is_moving() \
			and _player.is_input_enabled(), TIMEOUT)
		assert_true(_player.script_step(direction), "pas %s depuis %s" % [direction,
			_player.get_cell()])
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


func _surf_east_from_the_beach() -> void:
	await _walk(Vector2i.UP, 12)
	await _walk(Vector2i.RIGHT, 4)
	assert_eq(_player.get_cell(), Vector2i(6, 4))
	# Colonne x = 7 pêchable et cannes au Sac : PÊCHER prime sur SURFER [D].
	assert_eq(_boot.get_interaction_controller().get_target().kind, Interaction.Kind.FISH,
		"PÊCHER face à l'eau pêchable")
	assert_true(_boot.get_hud().get_interact_button().has_hold_choice(),
		"SURFER aussi possible : appui long « Pêcher / Surfer » (option A)")
	assert_eq(_boot.get_mount_director().start_surf(), SurfRules.MountCheck.READY)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_eq(_player.get_mount(), Mount.Kind.SURF)


func test_the_current_carries_the_player_to_the_next_map_still_surfing() -> void:
	await _surf_east_from_the_beach()
	# Le cinquième pas pose le joueur sur le premier courant (12, 4) : la glissade part.
	await _walk(Vector2i.RIGHT, 5)
	await wait_until(func() -> bool: return _boot.get_map().map_id == SeaRig.SEA_2 \
		and _boot.is_stable(), TIMEOUT)
	assert_eq(_player.get_cell(), Vector2i(5, 3), "arrivée en Surf forcé")
	assert_eq(_player.get_mount(), Mount.Kind.SURF)
	assert_true(_player.is_input_enabled())


func test_the_sea_edge_keeps_the_mount_and_the_shore_dismounts() -> void:
	await _surf_east_from_the_beach()
	await _walk(Vector2i.DOWN, 8)
	await _walk(Vector2i.RIGHT, 18)
	assert_eq(_player.get_cell(), Vector2i(25, 12))
	_player.face(Vector2i.RIGHT)
	_player.bumped.emit(Vector2i.RIGHT)
	await wait_until(func() -> bool: return _boot.get_map().map_id == SeaRig.SEA_2 \
		and _boot.is_stable(), TIMEOUT)
	assert_eq(_player.get_cell(), Vector2i(0, 12))
	assert_eq(_player.get_mount(), Mount.Kind.SURF, "bord de carte : Surf gardé")
	await _walk(Vector2i.RIGHT, 9)
	assert_eq(_player.get_cell(), Vector2i(9, 12))
	assert_eq(_player.get_mount(), Mount.Kind.NONE, "rive : à pied")


func test_a_save_at_sea_resumes_surfing() -> void:
	await _surf_east_from_the_beach()
	await _walk(Vector2i.DOWN, 6)
	assert_eq(_player.get_cell(), Vector2i(7, 10))
	GameState.set_player_location(SeaRig.SEA, _player.get_cell(), Vector2i.DOWN)
	assert_eq(GameState.player_mount, Mount.Kind.SURF)
	assert_eq(SaveSystem.new(_fs, SAVE_PATH).write(GameState.to_dict()), OK)
	remove_child(_boot)
	_boot.free()
	await _start(true)
	assert_true(_boot.has_resumed(), "partie reprise")
	assert_eq(_boot.get_map().map_id, SeaRig.SEA)
	assert_eq(_player.get_cell(), Vector2i(7, 10), "reprise sur l'eau")
	assert_eq(_player.get_mount(), Mount.Kind.SURF)


func _long_press_choice(confirmed: bool) -> void:
	await _walk(Vector2i.UP, 12)
	await _walk(Vector2i.RIGHT, 4)
	await wait_process_frames(2)
	var runner := _boot.get_dialogue_runner()
	_boot.get_hud().get_interact_button().long_pressed.emit()
	assert_eq(runner.get_dialogue_id(), Boot.WATER_CHOICE_DIALOGUE, "choix ouvert")
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while runner.is_running() and runner.get_dialogue_id() == Boot.WATER_CHOICE_DIALOGUE \
			and Time.get_ticks_msec() < deadline:
		if runner.is_awaiting_choice():
			runner.choose(confirmed)
		elif box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_ne(runner.get_dialogue_id(), Boot.WATER_CHOICE_DIALOGUE, "choix fermé")


func test_long_press_then_surf_mounts() -> void:
	await _long_press_choice(false)
	assert_true(await wait_until(func() -> bool: return _player.get_mount() == Mount.Kind.SURF \
		and not _player.is_moving(), TIMEOUT), "en Surf")
	assert_eq(_player.get_cell(), Vector2i(7, 4), "SURFER choisi : sur l'eau")


func test_long_press_then_fish_casts() -> void:
	await _long_press_choice(true)
	assert_true(await wait_until(func() -> bool: return _boot.get_dialogue_runner() \
		.get_dialogue_id() == &"fishing_cast", TIMEOUT), "ligne lancée")
	assert_eq(_player.get_mount(), Mount.Kind.NONE, "PÊCHER choisi : à pied")


func test_the_south_beach_has_no_hold_choice() -> void:
	await _walk(Vector2i.UP, 4)
	await _walk(Vector2i.RIGHT, 4)
	await wait_process_frames(2)
	assert_eq(_player.get_cell(), Vector2i(6, 12))
	assert_eq(_boot.get_interaction_controller().get_target().kind, Interaction.Kind.SURF)
	assert_false(_boot.get_hud().get_interact_button().has_hold_choice(), "SURFER seul")
