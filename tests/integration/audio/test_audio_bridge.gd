extends GutTest
## AudioBridge (SonA, T6) : carte, monture, « ! », combat, victoire, jingles, évolution, clé
## « music » des cinématiques, sur un autoload « Audio » espionné ; puis le vrai Boot.

const AudioScript := preload("res://game/autoload/audio.gd")
const L := MusicStack.Layer

var _orders: Array[Dictionary] = []
var _audio: Node
var _bridge: AudioBridge
var _mount: Mount.Kind = Mount.Kind.NONE
var _flags: Array[StringName] = []
var _caught: int = 5


func before_each() -> void:
	_orders.clear()
	_mount = Mount.Kind.NONE
	_flags.clear()
	_caught = 5
	_audio = AudioScript.new()
	_audio.sink = func(order: Dictionary) -> void: _orders.append(order)
	add_child_autofree(_audio)
	var zones := ZoneLibrary.new()
	zones.load_file()
	_bridge = AudioBridge.new()
	_bridge.setup(_audio, zones)
	_bridge.current_mount = func() -> Mount.Kind: return _mount
	_bridge.has_flag = func(flag: StringName) -> bool: return _flags.has(flag)
	_bridge.trainer_name = func(id: StringName) -> String:
		return "Fillette Lila" if id == &"lass" else "Gamin Ben"
	_bridge.caught_count = func() -> int: return _caught
	var items := ItemLibrary.new()
	items.load_dir()
	_bridge.items = items


func _map(map_id: StringName, music: StringName = &"") -> GameMap:
	var map := GameMap.new()
	map.map_id = map_id
	map.music = music
	autofree(map)
	return map


func _tracks() -> Array:
	return _orders.filter(func(o: Dictionary) -> bool: return o["type"] == &"music") \
		.map(func(o: Dictionary) -> StringName: return o["track"])


func _event(kind: BattleEvent.Kind, outcome: int = 0) -> BattleEvent:
	var event := BattleEvent.new()
	event.kind = kind
	event.outcome = outcome
	return event


func test_map_change_plays_the_zone_and_keeps_it_indoors() -> void:
	_bridge.on_map_changed(_map(&"pallet_town"))
	_bridge.on_map_changed(_map(&"player_house_1f"))
	assert_eq(_tracks(), [&"pallet_town"], "même morceau : il continue")
	_bridge.on_map_changed(_map(&"oak_lab"))
	assert_eq(_audio.current_track(), &"oaks_lab")


func test_map_change_sets_the_ambience() -> void:
	_bridge.on_map_changed(_map(&"mt_moon_1f"))
	assert_eq(_audio.current_ambience(), &"cave")
	_bridge.on_map_changed(_map(&"mt_moon_center"))
	assert_eq(_audio.current_ambience(), &"")


func test_map_override_wins() -> void:
	_bridge.on_map_changed(_map(&"route_1", &"game_corner"))
	assert_eq(_audio.current_track(), &"game_corner")


func test_surf_and_bike_change_the_music() -> void:
	_bridge.on_map_changed(_map(&"route_19"))
	assert_eq(_audio.current_track(), &"road_to_cerulean")
	_mount = Mount.Kind.SURF
	_bridge.on_mount_changed(_mount)
	assert_eq(_audio.current_track(), &"the_sea")
	_mount = Mount.Kind.NONE
	_bridge.on_mount_changed(_mount)
	assert_eq(_audio.current_track(), &"road_to_cerulean")


func test_freed_tower_flag() -> void:
	_flags.append(&"fuji_rescued")
	_bridge.on_map_changed(_map(&"pokemon_tower_2f"))
	assert_eq(_audio.current_track(), &"lavender_town", "SON-10 B")


func test_trainer_encounter_battle_victory_then_zone_resumes() -> void:
	_bridge.on_map_changed(_map(&"route_3"))
	_bridge.on_trainer_spotted(&"npc", &"lass")
	assert_eq(_audio.current_track(), &"trainer_appears_girl")
	_bridge.on_battle_started(&"lass")
	assert_eq(_audio.current_track(), &"battle_trainer")
	_bridge.on_battle_event(_event(BattleEvent.Kind.BATTLE_ENDED, Battle.Outcome.WIN))
	assert_eq(_audio.current_track(), &"victory_trainer")
	_bridge.on_battle_finished(&"lass", Battle.Outcome.WIN)
	assert_eq(_audio.current_track(), &"road_to_cerulean", "le thème du « ! » se retire aussi")
	assert_eq(_audio.track_of(L.SCENE), &"")
	assert_true(_orders.filter(func(o: Dictionary) -> bool: return o["type"] == &"music") \
		.back()["resumed"], "SON-6 : reprise")


func test_wild_battle_and_loss_without_victory() -> void:
	_bridge.on_map_changed(_map(&"route_1"))
	_bridge.on_battle_started(&"")
	assert_eq(_audio.current_track(), &"battle_wild")
	_bridge.on_battle_event(_event(BattleEvent.Kind.BATTLE_ENDED, Battle.Outcome.LOSS))
	assert_eq(_audio.current_track(), &"battle_wild", "pas de victoire après une défaite")
	_bridge.on_battle_finished(&"", Battle.Outcome.LOSS)
	assert_eq(_audio.current_track(), &"road_to_viridian")


func test_gym_leader_music() -> void:
	_bridge.on_map_changed(_map(&"pewter_gym"))
	_bridge.on_battle_started(&"pewter_gym_brock")
	assert_eq(_audio.current_track(), &"battle_gym_leader")
	_bridge.on_battle_event(_event(BattleEvent.Kind.BATTLE_ENDED, Battle.Outcome.WIN))
	assert_eq(_audio.current_track(), &"victory_gym_leader")


func test_jingles_play_then_the_zone_resumes() -> void:
	_bridge.on_map_changed(_map(&"viridian_center"))
	_bridge.on_center_healed(&"viridian_center", true)
	_bridge.on_item_given(&"potion", 1)
	_bridge.on_item_given(&"oak_parcel", 1)
	_bridge.on_item_found(&"potion", 1)
	var tracks := _tracks()
	for jingle: StringName in [&"pokemon_healed", &"picked_up_item", &"obtained_key_item"]:
		assert_true(tracks.has(jingle), String(jingle))
	assert_eq(tracks.back(), &"pokemon_center", "jingle muet : reprise aussitôt")


func test_first_catch_and_later_catches() -> void:
	_caught = 1
	_bridge.on_pokemon_caught()
	_caught = 2
	_bridge.on_pokemon_caught()
	var tracks := _tracks()
	assert_true(tracks.has(&"caught_pokemon"), "première capture")
	assert_true(tracks.has(&"caught_pokemon_short"))


func test_level_up_jingle_over_the_battle() -> void:
	_bridge.on_map_changed(_map(&"route_1"))
	_bridge.on_battle_started(&"")
	_bridge.on_battle_event(_event(BattleEvent.Kind.LEVEL_UP))
	assert_true(_tracks().has(&"level_up"))
	assert_eq(_audio.current_track(), &"battle_wild")


func test_evolution_and_cancelled_evolution() -> void:
	_bridge.on_map_changed(_map(&"route_1"))
	_bridge.on_evolution_started(0, &"ivysaur")
	assert_eq(_audio.current_track(), &"evolution")
	_bridge.on_evolution_finished(0, &"ivysaur", false)
	assert_true(_tracks().has(&"evolved"))
	assert_eq(_audio.current_track(), &"road_to_viridian")
	_bridge.on_evolution_started(0, &"ivysaur")
	_bridge.on_evolution_finished(0, &"ivysaur", true)
	assert_eq(_audio.current_track(), &"road_to_viridian", "annulée : retour direct")


func test_cutscene_music_key_badge_and_flute() -> void:
	_bridge.on_map_changed(_map(&"pallet_town"))
	var step := CutsceneStep.new()
	step.kind = CutsceneStep.Kind.DIALOGUE
	step.music = &"rival"
	_bridge.on_cutscene_step(step)
	assert_eq(_audio.current_track(), &"blue_theme", "moment « rival »")
	step.music = &"professor_oak"
	_bridge.on_cutscene_step(step)
	assert_eq(_audio.current_track(), &"professor_oak", "identifiant de morceau")
	step.music = AudioBridge.STOP
	_bridge.on_cutscene_step(step)
	assert_eq(_audio.current_track(), &"pallet_town")
	var badge := CutsceneStep.new()
	badge.kind = CutsceneStep.Kind.BADGE
	_bridge.on_cutscene_step(badge)
	var flute := CutsceneStep.new()
	flute.kind = CutsceneStep.Kind.FLUTE
	_bridge.on_cutscene_step(flute)
	assert_true(_tracks().has(&"obtained_badge"))
	assert_true(_tracks().has(&"poke_flute"))


func test_cutscene_end_stops_scene_music() -> void:
	_bridge.on_map_changed(_map(&"pallet_town"))
	var step := CutsceneStep.new()
	step.music = &"oak"
	_bridge.on_cutscene_step(step)
	_bridge.on_cutscene_finished(&"x")
	assert_eq(_audio.current_track(), &"pallet_town")


func test_title_then_intro_then_game() -> void:
	_bridge.play_title()
	assert_eq(_audio.current_track(), &"title_screen")
	_bridge.on_intro_opened()
	assert_eq(_audio.current_track(), &"guide")
	_bridge.on_intro_closed()
	_bridge.on_map_changed(_map(&"player_house_2f"))
	assert_eq(_audio.current_track(), &"pallet_town")


func test_real_boot_plays_the_start_map_music_and_resets_on_exit() -> void:
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	boot.start_map = &"route_1"
	add_child(boot)
	var global := get_tree().root.get_node(^"Audio")
	assert_eq(global.current_track(), &"road_to_viridian", "Boot → AudioBridge → Audio")
	assert_not_null(boot.get_audio_bridge())
	boot.free()
	assert_eq(global.current_track(), AudioLibrary.SILENCE, "Boot quitté : l'autoload repart muet")
