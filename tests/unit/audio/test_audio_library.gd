extends GutTest
## AudioLibrary (Son.0, T3) : les données `data/audio/*.json` se lisent sans erreur, chaque
## carte a une musique, aucun identifiant inconnu, tout fichier manquant est « attendu ».

var _library: AudioLibrary


func before_all() -> void:
	_library = AudioLibrary.new()
	_library.load_dir()


func test_the_data_files_load_without_errors() -> void:
	assert_eq(_library.get_errors(), PackedStringArray())
	assert_gt(_library.track_ids().size(), 40, "les morceaux du §2")
	assert_gt(_library.sfx_ids().size(), 60, "les bruitages du §3")


func test_every_map_of_zones_json_has_music() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(_library.uncovered_maps(zones), [] as Array[StringName])


func test_every_map_scene_has_music() -> void:
	var zones := ZoneLibrary.new()
	zones.load_file()
	var selector := MusicSelector.new(_library, zones)
	for file: String in DirAccess.get_files_at("res://game/world/maps"):
		if not file.ends_with(".tscn"):
			continue
		var map_id := StringName(file.get_basename())
		assert_ne(selector.track_for(map_id), AudioLibrary.SILENCE, String(map_id))


func test_every_missing_file_is_declared_expected() -> void:
	for id: StringName in _library.track_ids():
		var track := _library.track(id)
		assert_true(ResourceLoader.exists(track["file"]) or track["expected"], String(id))
	for id: StringName in _library.sfx_ids():
		var sfx := _library.sfx(id)
		for file: String in sfx["files"]:
			assert_true(ResourceLoader.exists(file) or sfx["expected"], String(id))


func test_son_0_ships_no_sound_file() -> void:
	for id: StringName in _library.track_ids():
		assert_true(_library.track(id)["expected"], "Son.0 : %s attendu" % id)


func test_tracks_carry_kind_loop_and_file() -> void:
	var town := _library.track(&"pallet_town")
	assert_eq(town["title"], "Pallet Town Theme")
	assert_eq(town["file"], "res://assets/audio/music/pallet_town.ogg")
	assert_true(town["loop"], "un thème de zone boucle")
	assert_false(_library.is_jingle(&"pallet_town"))
	assert_true(_library.is_jingle(&"pokemon_healed"))
	assert_false(_library.track(&"pokemon_healed")["loop"], "un jingle ne boucle pas")


func test_wild_victory_is_the_trainer_victory_cut_short() -> void:
	# SON-14 A tant que T1 n'a rien trouvé : « Victory! (Trainer Battle) » coupé à ~4 s.
	var wild := _library.track(&"victory_wild")
	assert_eq(wild["file"], _library.track(&"victory_trainer")["file"])
	assert_almost_eq(wild["fade_out_after"], 4.0, 0.001)


func test_events_point_to_known_tracks() -> void:
	assert_eq(_library.event_track(&"heal"), &"pokemon_healed")
	assert_eq(_library.event_track(&"badge"), &"obtained_badge")
	assert_eq(_library.event_track(&"splash"), AudioLibrary.SILENCE)
	assert_eq(_library.event_track(&"unknown"), &"")


func test_ambience_by_map_then_zone_then_weather() -> void:
	assert_eq(_library.ambience_for(&"mt_moon_1f", &"mt_moon"), &"cave")
	assert_eq(_library.ambience_for(&"mt_moon_center", &"mt_moon"), &"", "« none » : rien")
	assert_eq(_library.ambience_for(&"player_house_1f", &"pallet_town"), &"")
	assert_eq(_library.ambience_for(&"route_1", &"route_1", &"rain"), &"rain", "la météo prime")


func test_unknown_references_are_errors() -> void:
	var library := AudioLibrary.new()
	library.add_tracks({ "tracks": { "a": { "file": "res://a.ogg", "kind": "music" } } })
	assert_false(library.add_music_zones({ "zones": { "z": "nope" }, "maps": { "m": "a" } }))
	assert_eq(library.zone_track(&"z"), &"", "l'entrée fautive est écartée")
	assert_eq(library.map_track(&"m"), &"a")
	assert_false(library.add_tracks({ "tracks": { "silence": { "file": "res://s.ogg" } } }),
		"« silence » est réservé")
	assert_false(library.add_tracks({ "tracks": { "b": { "file": "x.ogg" } } }), "res:// attendu")
	assert_false(library.add_tracks({ "tracks": { "c": { "file": "res://c.ogg", "oops": 1 } } }),
		"clé inconnue")
	assert_eq(library.get_errors().size(), 4)
	assert_push_error_count(4)
