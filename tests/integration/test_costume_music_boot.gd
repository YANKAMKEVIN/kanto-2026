extends GutTest
## Costumes avec le vrai Boot (dossier-costumes.md CO-12 à CO-20) : thème de combat du costume
## porté contre un sauvage, jingle d'arrivée en ville puis reprise de la ville, Analyste sur les
## cartes d'attaque. Sans les fichiers (CI : ils restent hors du dépôt, CO-19), la musique normale.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_costume_music_boot_save.json"
const FIXTURE_V1 := "res://tests/fixtures/save/v1_after_capture.json"
const TIMEOUT := 30.0
const FADE := 0.01

var _boot: Boot
var _fades: Array[float] = []


func before_each() -> void:
	GameState.clock = FixedClock.new("2026-11-07T10:00:00")
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE


func after_each() -> void:
	get_tree().paused = false
	GameState.clock = DeviceClock.new()
	GameState.player_costume = GameState.NO_COSTUME
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]


func _start(costume: StringName) -> void:
	var fs := MemoryFs.new()
	fs.files[SAVE_PATH] = FileAccess.get_file_as_string(FIXTURE_V1)
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(fs, SAVE_PATH)
	add_child_autofree(_boot)
	await wait_until(func() -> bool: return _boot.is_stable(), 12.0)
	var catalog := CostumeCatalog.shared()
	GameState.flags.set_flag(catalog.badges.flag(catalog.badge_of(costume)))
	assert_true(GameState.wear_costume(costume))


func _playable(tracks: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for track: StringName in tracks:
		if ResourceLoader.exists(Audio.library.track(track)["file"]):
			result.append(track)
	return result


## Pilote le combat sauvage en cours jusqu'à sa fin par FUITE ; [param on_moves] est appelé une
## fois, cartes d'attaque affichées (ATTAQUER d'abord, puis « ‹ » et FUITE).
func _flee(on_moves: Callable = Callable()) -> void:
	var enc := _boot.get_encounter_director()
	var director := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var seen_moves := not on_moves.is_valid()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while enc.is_running() and Time.get_ticks_msec() < deadline:
		var battle := director.get_battle() if director.is_running() else null
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			match hud.get_zone():
				BattleHud.Zone.ACTIONS:
					hud.action_selected.emit(ActionGrid.RUN if seen_moves else ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					if not seen_moves:
						seen_moves = true
						on_moves.call(hud)
					hud.back_requested.emit()
		await wait_process_frames(1)
	assert_false(enc.is_running(), "la rencontre s'est terminée")


func test_wild_battle_plays_a_costume_theme() -> void:
	await _start(&"soul")
	var themes := CostumeCatalog.shared().music_tracks(&"soul", CostumeCatalog.MUSIC_BATTLE)
	var expected := _playable(themes)
	var enc := _boot.get_encounter_director()
	assert_true(enc.start_encounter(WildEncounter.new(&"rattata", 3, &"route_1_grass")))
	await wait_until(func() -> bool: return _boot.get_battle_director().is_running(), TIMEOUT)
	if expected.is_empty():
		assert_eq(Audio.current_track(), &"battle_wild", "sans fichier : musique normale")
	else:
		assert_has(expected, Audio.current_track(), "thème du costume")
		var player := Audio.get_music_player()
		assert_true(player.playing, "le thème joue")
		assert_eq(player.stream.resource_path,
			Audio.library.track(Audio.current_track())["file"])
	await _flee()


func test_original_outfit_keeps_the_wild_music() -> void:
	await _start(&"soul")
	assert_true(GameState.wear_costume(GameState.NO_COSTUME))
	var enc := _boot.get_encounter_director()
	assert_true(enc.start_encounter(WildEncounter.new(&"rattata", 3, &"route_1_grass")))
	await wait_until(func() -> bool: return _boot.get_battle_director().is_running(), TIMEOUT)
	assert_eq(Audio.current_track(), &"battle_wild")
	await _flee()


func test_analyste_writes_effectiveness_on_move_cards() -> void:
	await _start(&"marsh")
	var texts: Array[String] = []
	var enc := _boot.get_encounter_director()
	assert_true(enc.start_encounter(WildEncounter.new(&"gastly", 3, &"route_1_grass")))
	await wait_until(func() -> bool: return _boot.get_battle_director().is_running(), TIMEOUT)
	await _flee(func(hud: BattleHud) -> void:
		for index: int in 4:
			var card := hud.get_move_grid().get_card(index)
			if card != null and not card.is_empty():
				texts.append(card.get_power_text()))
	assert_false(texts.is_empty(), "cartes d'attaque lues")
	var hinted := texts.filter(func(text: String) -> bool:
		return text.ends_with(BattleViews.HINT_NONE))
	assert_false(hinted.is_empty(), "une attaque Normal sur Fantominus : %s" % [texts])


func test_town_song_plays_then_gives_way_to_a_battle() -> void:
	await _start(&"soul")
	var jingles := _playable(CostumeCatalog.shared().music_tracks(&"soul",
		CostumeCatalog.MUSIC_TOWN))
	var heard: Array[StringName] = []
	Audio.music_changed.connect(func(track: StringName) -> void: heard.append(track))
	await SceneRouter.change_map(&"viridian_city", &"from_gym", Vector2i.DOWN)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	var town := _boot.get_audio_bridge().selector.track_for(&"viridian_city")
	if jingles.is_empty():
		assert_eq(Audio.current_track(), town, "sans fichier : la ville seule")
		return
	assert_true(heard.any(func(track: StringName) -> bool: return jingles.has(track)),
		"jingle du costume entendu : %s" % [heard])
	assert_has(jingles, Audio.current_track(), "le chant d'arrivée joue encore (une minute)")
	# Un combat pendant le chant : le thème de combat passe devant, le chant s'arrête, et la
	# ville reprend après le combat.
	var enc := _boot.get_encounter_director()
	assert_true(enc.start_encounter(WildEncounter.new(&"rattata", 3, &"route_1_grass")))
	await wait_until(func() -> bool: return _boot.get_battle_director().is_running(), TIMEOUT)
	assert_true(Audio.get_music_player().stream.resource_path.contains("battle") \
		or Audio.current_track() == &"battle_wild", "musique de combat : %s" % Audio.current_track())
	await _flee()
	await wait_until(func() -> bool: return Audio.current_track() == town, TIMEOUT)
	assert_eq(Audio.current_track(), town, "la ville reprend, sans le chant")
