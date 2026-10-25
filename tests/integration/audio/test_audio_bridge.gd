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
	_bridge.species_dex = func(species: StringName) -> int:
		return { &"pikachu": 25, &"bulbasaur": 1, &"ivysaur": 2, &"pidgey": 16 }.get(species, 0)
	_bridge.party_species = func(_index: int) -> StringName: return &"bulbasaur"
	_bridge.companion_species = func() -> StringName: return &"pikachu"
	_bridge.move_info = func(move_id: StringName) -> Array:
		return { &"ember": [&"fire", &"special"], &"tackle": [&"normal", &"physical"],
			&"growl": [&"normal", &"status"] }.get(move_id, [])
	_bridge.ground_at = func(cell: Vector2i) -> StringName:
		return &"grass" if cell.x > 0 else &"indoor"


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


func _cries() -> Array:
	return _orders.filter(func(o: Dictionary) -> bool: return o["type"] == &"cry")


func test_cries_on_send_out_and_lower_on_faint() -> void:
	var sent := _event(BattleEvent.Kind.SENT_OUT)
	sent.species_id = &"pidgey"
	_bridge.on_battle_event(sent)
	var fainted := _event(BattleEvent.Kind.FAINTED)
	fainted.species_id = &"pidgey"
	_bridge.on_battle_event(fainted)
	var cries := _cries()
	assert_eq(cries.size(), 2)
	assert_eq(cries[0]["dex"], 16)
	assert_eq(cries[0]["pitch"], 1.0)
	assert_almost_eq(float(cries[1]["pitch"]), 0.8, 0.001, "K.O. : plus grave (RB)")


func test_encounter_pokedex_and_companion_cries() -> void:
	_bridge.play_species_cry(&"pikachu")
	_bridge.on_pokedex_cry(151)
	_bridge.on_companion_line(&"companion_talk")
	_bridge.play_species_cry(&"missingno")
	var dex: Array = _cries().map(func(o: Dictionary) -> int: return o["dex"])
	assert_eq(dex, [25, 151, 25], "espèce inconnue : aucun cri")


func test_evolution_cries_old_then_new() -> void:
	_bridge.on_evolution_started(0, &"ivysaur")
	_bridge.on_evolution_finished(0, &"ivysaur", false)
	var dex: Array = _cries().map(func(o: Dictionary) -> int: return o["dex"])
	assert_eq(dex, [1, 2], "ancienne forme au début, nouvelle à la fin")


func _sfx_ids() -> Array:
	return _orders.filter(func(o: Dictionary) -> bool: return o["type"] == &"sfx") \
		.map(func(o: Dictionary) -> StringName: return o["id"])


func test_every_sonorous_battle_event_kind_plays_its_sfx() -> void:
	# Critère T13 : chaque sorte de BattleEvent de la table joue son identifiant.
	var table: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/audio/sfx.json"))["battle_events"]
	for kind_name: String in table:
		_orders.clear()
		var event := _event(BattleEvent.Kind[kind_name])
		event.species_id = &"pidgey"
		_bridge.on_battle_event(event)
		assert_true(_sfx_ids().has(StringName(table[kind_name])), kind_name)


func test_damage_effectiveness_critical_stats_and_status() -> void:
	for case: Array in [[1.0, false, &"hit_normal"], [2.0, false, &"hit_super"],
			[0.5, false, &"hit_weak"], [1.0, true, &"critical"]]:
		_orders.clear()
		var hit := _event(BattleEvent.Kind.DAMAGE)
		hit.effectiveness = case[0]
		hit.critical = case[1]
		_bridge.on_battle_event(hit)
		assert_eq(_sfx_ids(), [case[2]], str(case))
	_orders.clear()
	var up := _event(BattleEvent.Kind.STAT_CHANGED)
	up.stages = 1
	_bridge.on_battle_event(up)
	var down := _event(BattleEvent.Kind.STAT_CHANGED)
	down.stages = -2
	_bridge.on_battle_event(down)
	var burn := _event(BattleEvent.Kind.STATUS_INFLICTED)
	burn.status = &"burn"
	_bridge.on_battle_event(burn)
	assert_eq(_sfx_ids(), [&"stat_up", &"stat_down", &"status_burn"])


func test_move_used_plays_its_family() -> void:
	for case: Array in [[&"ember", &"move_fire"], [&"tackle", &"move_hit"],
			[&"growl", &"move_sound"]]:
		_orders.clear()
		var used := _event(BattleEvent.Kind.MOVE_USED)
		used.move_id = case[0]
		_bridge.on_battle_event(used)
		assert_eq(_sfx_ids(), [case[1]], String(case[0]))


func test_steps_by_ground_ledge_and_mounts() -> void:
	_bridge.on_player_step(Vector2i.ZERO, Vector2i(3, 0), &"walk")
	_bridge.on_player_step(Vector2i.ZERO, Vector2i(-3, 0), &"run")
	_bridge.on_player_step(Vector2i.ZERO, Vector2i(3, 2), &"jump")
	_bridge.on_player_step(Vector2i.ZERO, Vector2i(3, 0), &"bike")
	_bridge.on_player_step(Vector2i.ZERO, Vector2i(3, 0), &"surf")
	var ids := _sfx_ids()
	assert_eq(ids.size(), 3, "rien à Vélo ni en Surf")
	assert_eq(ids, [&"step_grass", &"step_indoor", &"ledge_jump"])


func test_world_and_interface_sounds() -> void:
	_bridge.on_bumped(Vector2i.UP)
	_bridge.on_transition_started(&"route_1")
	_bridge.on_menu_opened()
	_bridge.on_menu_closed(false)
	_bridge.on_dialogue_page(0)
	_bridge.on_dialogue_page(1)
	assert_eq(_sfx_ids(), [&"bump", &"door", &"ui_menu_open", &"ui_menu_close",
		&"ui_dialog_next"], "pas de son à la première page")


func test_one_hook_for_every_button_except_the_exploration_hud() -> void:
	var screen := Control.new()
	var hud := Control.new()
	add_child_autofree(screen)
	add_child_autofree(hud)
	var existing := Button.new()
	screen.add_child(existing)
	_bridge.watch_ui(screen, hud)
	var later := Button.new()
	screen.add_child(later)
	var joystick := Button.new()
	hud.add_child(joystick)
	existing.pressed.emit()
	later.pressed.emit()
	joystick.pressed.emit()
	_bridge.unwatch_ui(get_tree())
	var after := Button.new()
	screen.add_child(after)
	after.pressed.emit()
	assert_eq(_sfx_ids(), [&"ui_confirm", &"ui_confirm"], "HUD muet ; plus rien après unwatch")


func test_real_boot_wires_every_game_signal_to_the_bridge() -> void:
	# Garde-fou (QA T14) : chaque signal du jeu relayé au son est bien branché par Boot.
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	boot.start_map = &"route_1"
	add_child(boot)
	var bridge := boot.get_audio_bridge()
	var battle := boot.get_battle_director()
	var cutscenes := boot.get_cutscene_director()
	var links: Array = [
		[boot.get_player().mount_changed, bridge.on_mount_changed],
		[boot.get_player().step_started, bridge.on_player_step],
		[boot.get_player().bumped, bridge.on_bumped],
		[boot.get_trainer_watcher().trainer_spotted, bridge.on_trainer_spotted],
		[battle.battle_started, bridge.on_battle_started],
		[battle.event_played, bridge.on_battle_event],
		[battle.battle_finished, bridge.on_battle_finished],
		[cutscenes.item_given, bridge.on_item_given],
		[cutscenes.item_found, bridge.on_item_found],
		[cutscenes.step_played, bridge.on_cutscene_step],
		[cutscenes.cutscene_finished, bridge.on_cutscene_finished],
		[boot.get_evolution_director().evolution_started, bridge.on_evolution_started],
		[boot.get_evolution_director().evolution_finished, bridge.on_evolution_finished],
		[SceneRouter.transition_started, bridge.on_transition_started],
	]
	for link: Array in links:
		assert_true((link[0] as Signal).is_connected(link[1]), str(link[0]))
	var global := get_tree().root.get_node(^"Audio")
	battle.battle_started.emit(&"")
	assert_eq(global.current_track(), &"battle_wild", "vrai Boot : musique de combat")
	battle.battle_finished.emit(&"", Battle.Outcome.WIN)
	assert_eq(global.current_track(), &"road_to_viridian", "reprise de la route")
	boot.free()


func test_wild_cry_at_appearance_is_not_repeated_at_send_out() -> void:
	# [D] (QA T14) : le sauvage crie dans l'herbe ; pas un second cri à son entrée en combat.
	_bridge.on_encounter_cry(&"pidgey")
	_bridge.on_battle_started(&"")
	var foe := _event(BattleEvent.Kind.SENT_OUT)
	foe.side = BattleEvent.SideId.FOE
	foe.species_id = &"pidgey"
	_bridge.on_battle_event(foe)
	var mine := _event(BattleEvent.Kind.SENT_OUT)
	mine.species_id = &"bulbasaur"
	_bridge.on_battle_event(mine)
	_bridge.on_battle_event(foe)
	var dex: Array = _cries().map(func(o: Dictionary) -> int: return o["dex"])
	assert_eq(dex, [16, 1, 16], "apparition, envoi du joueur, puis un second envoi crie")
