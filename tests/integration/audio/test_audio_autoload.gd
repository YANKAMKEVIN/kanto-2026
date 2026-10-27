extends GutTest
## Autoload « Audio » (Son.0, T4) : bus, pile de musique exécutée, fondus, bruitages, cris,
## ambiance, volumes ; muet tolérant (aucun fichier son en Son.0) ; espion `sink`.

const AudioScript := preload("res://game/autoload/audio.gd")
const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const L := MusicStack.Layer

var _orders: Array[Dictionary] = []


func _audio(spied: bool = true) -> Node:
	_orders.clear()
	var audio: Node = AudioScript.new()
	if spied:
		audio.sink = func(order: Dictionary) -> void: _orders.append(order)
	add_child_autofree(audio)
	return audio


func _music_orders() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for order: Dictionary in _orders:
		if order["type"] == &"music":
			result.append(order)
	return result


func after_each() -> void:
	AudioServer.set_bus_mute(0, false)
	AudioServer.set_bus_volume_db(0, 0.0)
	for bus: StringName in AudioScript.BUSES:
		var index := AudioServer.get_bus_index(bus)
		AudioServer.set_bus_mute(index, false)
		AudioServer.set_bus_volume_db(index, 0.0)


func test_the_buses_of_the_layout_exist() -> void:
	for bus: StringName in AudioScript.BUSES:
		var index := AudioServer.get_bus_index(bus)
		assert_gt(index, 0, String(bus))
		assert_eq(AudioServer.get_bus_send(index), &"Master")


func test_the_global_autoload_is_loaded_and_silent() -> void:
	var global := get_tree().root.get_node_or_null(^"Audio")
	assert_not_null(global, "autoload « Audio »")
	assert_eq(global.library.get_errors(), PackedStringArray())
	assert_eq(global.current_track(), AudioLibrary.SILENCE, "Son.0 : branché nulle part")
	for player: AudioStreamPlayer in global.get_music_players():
		assert_false(player.playing)


func test_zone_track_then_the_same_track_is_not_restarted() -> void:
	var audio := _audio()
	audio.set_music(L.ZONE, &"pallet_town")
	audio.set_music(L.ZONE, &"pallet_town")
	var music := _music_orders()
	assert_eq(music.size(), 1, "même morceau : il continue")
	assert_eq(music[0]["track"], &"pallet_town")
	assert_eq(audio.current_track(), &"pallet_town")
	audio.set_music(L.ZONE, &"road_to_viridian")
	assert_eq(_music_orders().size(), 2)
	assert_eq(_music_orders()[1]["track"], &"road_to_viridian")


func test_missing_jingle_ends_at_once_and_the_zone_resumes() -> void:
	var audio := _audio()
	audio.set_music(L.ZONE, &"pewter_city")
	audio.play_jingle(&"pokemon_healed")
	var music := _music_orders()
	assert_eq(music.size(), 3)
	assert_eq(music[1]["track"], &"pokemon_healed")
	assert_eq(music[2]["track"], &"pewter_city")
	assert_true(music[2]["resumed"], "reprise de la zone")
	assert_eq(audio.track_of(L.JINGLE), &"", "jingle terminé")


func test_battle_victory_then_zone_resumes() -> void:
	var audio := _audio()
	audio.set_music(L.ZONE, &"road_to_viridian")
	audio.set_music(L.BATTLE, &"battle_wild")
	audio.set_music(L.BATTLE, &"victory_wild")
	audio.clear_music(L.BATTLE)
	var tracks: Array = _music_orders().map(func(o: Dictionary) -> StringName: return o["track"])
	assert_eq(tracks, [&"road_to_viridian", &"battle_wild", &"victory_wild", &"road_to_viridian"])
	assert_true(_music_orders()[3]["resumed"])


func test_music_changed_signal() -> void:
	var audio := _audio()
	watch_signals(audio)
	audio.set_music(L.ZONE, &"pallet_town")
	assert_signal_emitted_with_parameters(audio, "music_changed", [&"pallet_town"])
	audio.stop_music()
	assert_signal_emitted_with_parameters(audio, "music_changed", [AudioLibrary.SILENCE])
	assert_eq(audio.current_track(), AudioLibrary.SILENCE)


func test_without_sink_missing_files_stay_silent_without_errors() -> void:
	# Muet tolérant : un morceau et un jingle déclarés mais sans fichier.
	var library := AudioLibrary.new()
	library.load_dir()
	library.add_tracks({ "tracks": {
		"ghost_zone": { "file": "res://assets/audio/music/absent.ogg", "kind": "music",
			"expected": true },
		"ghost_jingle": { "file": "res://assets/audio/music/absent_j.ogg", "kind": "jingle",
			"loop": false, "expected": true } } })
	_orders.clear()
	var audio: Node = AudioScript.new()
	audio.library = library
	add_child_autofree(audio)
	audio.set_music(L.ZONE, &"ghost_zone")
	audio.play_jingle(&"ghost_jingle")
	assert_true(audio.play_sfx(&"ui_confirm"), "accepté, même sans fichier (SonC)")
	assert_true(audio.play_cry(25), "accepté, même sans fichier (SonB)")
	audio.set_ambience(&"sea")
	assert_eq(audio.current_track(), &"ghost_zone", "le jingle muet s'est terminé")
	for player: AudioStreamPlayer in audio.get_music_players():
		assert_false(player.playing, "aucun fichier : rien ne joue")


func test_a_real_music_file_plays_and_loops_from_its_offset() -> void:
	# SonA, T9 : le fichier existe ; il joue, boucle, et repart de « loop_offset ».
	var audio := _audio(false)
	audio.set_music(L.ZONE, &"pallet_town")
	var player: AudioStreamPlayer = audio.get_music_player()
	assert_true(player.playing)
	var stream := player.stream as AudioStreamOggVorbis
	assert_not_null(stream)
	assert_true(stream.loop)
	assert_almost_eq(stream.loop_offset, float(audio.library.track(&"pallet_town")["loop_offset"]),
		0.001)
	audio.play_jingle(&"pokemon_healed")
	assert_eq(audio.current_track(), &"pokemon_healed", "un vrai jingle attend sa fin")
	assert_false((audio.get_music_player().stream as AudioStreamOggVorbis).loop)


func test_crossfade_fades_the_old_player_out() -> void:
	# Le fondu se vérifie sur le volume des lecteurs (temps simulé).
	var audio := _audio(false)
	var clock := TweenClock.new(get_tree())
	audio.set_music(L.ZONE, &"pallet_town")
	var first: AudioStreamPlayer = audio.get_music_player()
	audio.set_music(L.ZONE, &"road_to_viridian")
	assert_ne(audio.get_music_player(), first, "lecteurs A/B qui alternent")
	clock.run_until(func() -> bool: return false, AudioScript.FADE_OUT + 0.1)
	assert_eq(first.volume_db, VolumeMath.MUTED_DB, "l'ancien lecteur s'est tu")
	assert_false(first.playing)
	clock.release()


func test_sfx_orders_carry_a_variant_and_unknown_ids_are_refused() -> void:
	var audio := _audio()
	assert_true(audio.play_sfx(&"step_grass"))
	var order: Dictionary = _orders.back()
	assert_eq(order["type"], &"sfx")
	assert_true((order["file"] as String).begins_with("res://assets/audio/sfx/step_grass_"))
	assert_false(audio.play_sfx(&"nope"), "identifiant inconnu")


func test_cry_orders_and_faint_pitch() -> void:
	var audio := _audio()
	assert_true(audio.play_cry(25))
	assert_eq(_orders.back()["file"], "res://assets/audio/cries/25.ogg")
	assert_eq(_orders.back()["pitch"], 1.0)
	assert_true(audio.play_cry(25, true))
	assert_almost_eq(float(_orders.back()["pitch"]), 0.8, 0.001)
	assert_false(audio.play_cry(0))
	assert_false(audio.play_cry(152))


func test_ambience_changes_once_and_unknown_is_none() -> void:
	var audio := _audio()
	audio.set_ambience(&"cave")
	audio.set_ambience(&"cave")
	assert_eq(_orders.size(), 1)
	assert_eq(audio.current_ambience(), &"cave")
	audio.set_ambience(&"unknown")
	assert_eq(audio.current_ambience(), &"", "inconnue : aucune")
	assert_eq(_orders.back()["id"], &"")


func test_volumes_drive_the_buses() -> void:
	var audio := _audio()
	audio.apply_volumes(0.5, 0.0, 1.0)
	var music := AudioServer.get_bus_index(AudioScript.BUS_MUSIC)
	assert_almost_eq(AudioServer.get_bus_volume_db(music), VolumeMath.to_db(0.5), 0.01)
	assert_false(AudioServer.is_bus_mute(music))
	for bus: StringName in [AudioScript.BUS_SFX, AudioScript.BUS_AMBIENCE]:
		assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index(bus)), "Effets à 0 : coupé")
	var cries := AudioServer.get_bus_index(AudioScript.BUS_CRIES)
	assert_almost_eq(AudioServer.get_bus_volume_db(cries), 0.0, 0.01)


func test_settings_defaults_applied_to_the_buses() -> void:
	var audio := _audio()
	audio.apply_settings(GameSettings.new())
	var music := AudioServer.get_bus_index(AudioScript.BUS_MUSIC)
	assert_almost_eq(AudioServer.get_bus_volume_db(music), VolumeMath.to_db(0.7), 0.01)
	var sfx := AudioServer.get_bus_index(AudioScript.BUS_SFX)
	assert_almost_eq(AudioServer.get_bus_volume_db(sfx), VolumeMath.to_db(0.8), 0.01)


func test_background_mutes_master_and_resume_fades_it_back() -> void:
	# Jalon Son, T7 (§1.10) : APPLICATION_PAUSED → Master coupé ; RESUMED → fondu de 0,5 s.
	var audio := _audio()
	var clock := TweenClock.new(get_tree())
	audio.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_true(audio.is_backgrounded())
	assert_true(AudioServer.is_bus_mute(0), "Master coupé tout de suite")
	audio.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_false(audio.is_backgrounded())
	assert_false(AudioServer.is_bus_mute(0))
	assert_lt(AudioServer.get_bus_volume_db(0), -40.0, "le fondu commence en bas")
	clock.run_until(func() -> bool: return false, AudioScript.RESUME_FADE + 0.05)
	assert_almost_eq(AudioServer.get_bus_volume_db(0), 0.0, 0.01, "rétabli")
	clock.release()


func test_call_banner_ducks_music_and_ambience_only() -> void:
	var audio := _audio()
	audio.apply_volumes(1.0, 1.0, 1.0)
	audio.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(audio.is_focus_ducked())
	var music := AudioServer.get_bus_index(AudioScript.BUS_MUSIC)
	var sfx := AudioServer.get_bus_index(AudioScript.BUS_SFX)
	assert_almost_eq(AudioServer.get_bus_volume_db(music), AudioScript.FOCUS_DUCK_DB, 0.01)
	assert_almost_eq(AudioServer.get_bus_volume_db(sfx), 0.0, 0.01, "les effets ne bougent pas")
	assert_false(AudioServer.is_bus_mute(0), "pas coupé : seulement atténué")
	audio.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_false(audio.is_focus_ducked())
	assert_almost_eq(AudioServer.get_bus_volume_db(music), 0.0, 0.01)
