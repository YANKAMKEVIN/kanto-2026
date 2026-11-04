extends GutTest
## Résilience Android (J34, 34D, `docs/tech/jalon-34.md` §2 T5 ; fiche `jalon-34-34d.md`) avec la
## vraie scène Boot, un [SaveSystem] sur un système de fichiers en mémoire et une horloge du point
## de reprise imposée. Complète `test_save_background.gd` (dialogue, scène, combat, `FOCUS_OUT`)
## sur les interruptions qui restaient sans test :
## - mise en arrière-plan **pendant un changement de carte** : la position d'avant le passage est
##   écrite ; au retour la transition s'achève ; tuée pendant, la partie reprend avant le passage ;
## - **capture** interrompue (carte de capture affichée) : l'équipe d'avant le combat est écrite,
##   jamais le Pokémon à moitié rangé ; le combat fini, une seule capture est sauvegardée ;
## - **évolution par objet** (Super Bonbon) interrompue : bonbon, niveau et espèce d'avant restent
##   ensemble sur le disque ; à la fin, consommé et évolué ensemble, une seule fois ;
## - **mémoire basse** (`OS_MEMORY_WARNING`) : même point de reprise qu'une mise en arrière-plan,
##   sans quitter le premier plan.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_34d_save.json"
const DATE := "2026-11-04T10:00:00"
## Fondus longs : la mise en arrière-plan doit tomber **pendant** la transition.
const FADE := 0.4
const TIMEOUT := 15.0
const BALL := &"poke_ball"
const CANDY := &"rare_candy"

var _fs: MemoryFs
var _save: SaveSystem
var _boot: Boot
var _fades: Array[float] = []
## Horloge du point de reprise (s), avancée à la main.
var _now: Array[float] = [100.0]


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, SAVE_PATH)
	_now[0] = 100.0


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _start_boot(map: StringName = &"player_house_2f", spawn: StringName = &"start",
		facing: Vector2i = Vector2i.DOWN) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	_boot.background_clock = func() -> float: return _now[0]
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	await wait_process_frames(2)
	await _until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)


## Relance « après que le système a tué le processus » : nouveau Boot sur le même disque.
func _relaunch() -> void:
	_boot.queue_free()
	await wait_process_frames(2)
	await _start_boot()


## Comme wait_until, mais aussi pendant la pause du menu (l'attente de GUT est suspendue avec
## l'arbre) : une image à la fois, jusqu'à [param predicate] ou au délai de garde.
func _until(predicate: Callable, max_time: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(max_time * 1000.0)
	while not predicate.call():
		if Time.get_ticks_msec() > deadline:
			return false
		await get_tree().process_frame
	return true


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _saved() -> Dictionary:
	if not _fs.files.has(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(_fs.files[SAVE_PATH])
	return parsed if parsed is Dictionary else {}


func _saved_species() -> Array[String]:
	var result: Array[String] = []
	for member: Variant in _saved().get("party", []):
		if member is Dictionary:
			result.append(String((member as Dictionary).get("species", "")))
	return result


func _saved_item(item: StringName) -> int:
	return int(((_saved().get("bag", {}) as Dictionary).get("items", {}) as Dictionary).get(
		String(item), 0))


## Mise en arrière-plan à [param dt] s de la précédente (au-delà de l'écart minimal), puis retour.
func _background(dt: float = 10.0) -> void:
	_now[0] += dt
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)


# --- Changement de carte -----------------------------------------------------------------

func test_pause_during_a_map_change_writes_the_position_before_the_warp() -> void:
	await _start_boot()
	var cell := _boot.get_player().get_cell()
	_background()  # partie stable : le disque est à jour, à la position de départ
	var writes := _writes()
	SceneRouter.change_map(&"player_house_1f", &"stairs", Vector2i.DOWN)
	assert_true(SceneRouter.is_transitioning(), "transition engagée")
	await wait_process_frames(2)
	assert_false(_boot.is_stable(), "pendant la transition la partie n'est pas stable")
	_now[0] += 10.0
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	# Le disque était déjà à cette position : rien de plus récent à écrire ; s'il a écrit, c'est
	# la position d'avant le passage, jamais la carte en cours de chargement.
	assert_lte(_writes(), writes + 1)
	assert_eq(_saved().get("map"), "player_house_2f", "jamais la carte en cours de chargement")
	assert_eq(JsonFields.get_vector2i(_saved(), "cell"), cell, "case d'avant le passage")
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	# Au retour, la transition s'achève et le joueur est libre sur la nouvelle carte.
	# Au retour, la transition s'achève (Maman parle d'elle-même à l'arrivée : on avance son
	# dialogue, comme le joueur) et le joueur est libre sur la nouvelle carte.
	assert_true(await _until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT),
		"la transition s'achève après le retour")
	assert_eq(_boot.get_map().map_id, &"player_house_1f")
	assert_true(await _settle(), "partie stable sur la nouvelle carte")
	assert_true(_boot.get_player().is_input_enabled(), "commandes rendues")
	assert_eq(_saved().get("map"), "player_house_1f", "autosave d'arrivée")
	assert_push_error_count(0)


func test_killed_during_a_map_change_the_game_resumes_before_the_warp() -> void:
	await _start_boot()
	var cell := _boot.get_player().get_cell()
	await _start_dialogue_and_finish()  # une écriture ordinaire plus tôt, puis du jeu
	GameState.add_money(300)
	SceneRouter.change_map(&"player_house_1f", &"stairs", Vector2i.DOWN)
	await wait_process_frames(2)
	assert_false(_boot.is_stable())
	_now[0] += 10.0
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_saved().get("map"), "player_house_2f")
	assert_eq(int(_saved().get("money", -1)), GameState.money,
		"ce qui s'est passé avant le passage est gardé")
	# Android tue le processus en arrière-plan : relancée, la partie reprend avant le passage.
	await _relaunch()
	assert_eq(_boot.get_map().map_id, &"player_house_2f")
	assert_eq(_boot.get_player().get_cell(), cell)
	assert_true(_boot.is_stable(), "aucune transition fantôme à la reprise")
	assert_push_error_count(0)


## Un dialogue joué jusqu'au bout : l'état du disque n'est plus celui du départ.
func _start_dialogue_and_finish() -> void:
	assert_true(_boot.get_dialogue_runner().play(&"mom_wakeup", null, _boot.get_map()))
	assert_true(await _settle(), "le dialogue s'est terminé")


## Avance tout dialogue ouvert (comme le joueur) jusqu'à ce que la partie soit stable, puis
## laisse passer les autosaves en attente. Faux si elle ne l'est pas dans le délai.
func _settle() -> bool:
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while not _boot.is_stable() and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_process_frames(3)
	return _boot.is_stable()


# --- Capture -----------------------------------------------------------------------------

## Vrai si, avec la graine [param seed], le premier lancer d'une Poké Ball capture
## [param species] N[param level] (même flux d'aléatoire que la rencontre réelle).
func _throw_catches(seed: int, species: StringName, level: int) -> bool:
	var data := _boot.get_pokemon_data()
	var rng := GameRng.new(seed)
	var wild := Party.new()
	wild.add(PokemonFactory.create(data, species, level, rng))
	var battle := Battle.new(BattleSide.new(_starter_party(data), true),
		BattleSide.new(wild, false, "", null), data, rng,
		BattleRules.for_wild(_boot.get_item_library()))
	battle.start()
	for event: BattleEvent in battle.submit(BattleAction.ball(BALL)):
		if event.kind == BattleEvent.Kind.CAUGHT:
			return true
	return false


func _starter_party(data: PokemonData) -> Party:
	var party := Party.new()
	party.add(PokemonFactory.create(data, &"charmander", 5, GameRng.new(999)))
	return party


func _catch_seed(species: StringName, level: int) -> int:
	for seed: int in 3000:
		if _throw_catches(seed, species, level):
			return seed
	return -1


func test_pause_on_the_capture_card_never_saves_a_half_stored_pokemon() -> void:
	await _start_boot(&"route_1", &"from_pallet_w", Vector2i.UP)
	var seed := _catch_seed(&"rattata", 3)
	assert_gt(seed, -1, "une graine qui capture au premier lancer")
	if seed < 0:
		return
	GameState.new_game(seed)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.starter_species = &"charmander"
	GameState.party = _starter_party(_boot.get_pokemon_data())
	GameState.bag.add(BALL, 5)
	GameState.rng = GameRng.new(seed)
	await wait_process_frames(1)
	_background()  # stable : équipe d'un seul Pokémon et 5 Balls sur le disque
	assert_eq(_saved_species(), ["charmander"])
	var enc := _boot.get_encounter_director()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var caught_count: Array[int] = [0]
	var saved_on_catch: Array = []
	battle_director.pokemon_caught.connect(func(_p: Pokemon, _stored: bool) -> void:
		caught_count[0] += 1
		# Le Pokémon est rangé en mémoire, la carte de capture arrive : le système met
		# l'application en arrière-plan juste là.
		_now[0] += 10.0
		_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		saved_on_catch.append([_saved_species(), _saved_item(BALL)])
		_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED))
	assert_true(enc.start_encounter(WildEncounter.new(&"rattata", 3, &"route_1_grass")))
	var pending := false
	var thrown := false
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while enc.is_running() and Time.get_ticks_msec() < deadline:
		var card := battle_director.get_capture_card()
		var panel := battle_director.get_bag_panel()
		var battle := battle_director.get_battle()
		if card != null and card.is_waiting():
			card.skip()
		elif pending and panel != null and panel.is_shown() and not panel.is_answered():
			pending = false
			panel.get_action_button().pressed.emit()
		elif battle != null and battle.get_state() == Battle.State.CHOOSING \
				and battle_hud.get_zone() == BattleHud.Zone.ACTIONS and not pending:
			if not thrown:
				thrown = true
				pending = true
				battle_hud.action_selected.emit(ActionGrid.BAG)
			else:
				battle_hud.action_selected.emit(ActionGrid.RUN)
		await wait_process_frames(1)
	assert_false(enc.is_running(), "la rencontre s'est terminée")
	assert_eq(caught_count[0], 1, "capturé une fois")
	assert_eq(saved_on_catch, [[["charmander"], 5]],
		"sur la carte de capture : l'équipe et les Balls d'avant le combat, jamais l'entre-deux")
	await _until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(3)
	assert_eq(_saved_species(), ["charmander", "rattata"], "autosave de la capture : une fois")
	assert_eq(_saved_item(BALL), 4, "une Ball de moins, avec le Pokémon")
	# Tuée et relancée : exactement un Rattata, jamais deux.
	await _relaunch()
	assert_eq(GameState.party.size(), 2)
	assert_eq(GameState.party.get_at(1).species_id, &"rattata")
	assert_eq(GameState.bag.count_of(BALL), 4)
	assert_push_error_count(0)


# --- Évolution par objet (Super Bonbon) --------------------------------------------------

## Partie sauvegardée à Argenta : Abra N15 (évolue au 16) et [param candies] Super Bonbons.
func _resume_with_abra(candies: int) -> void:
	var data := PokemonData.new()
	data.load_dir()
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-11-04T09:00:00")
	state.new_game(42)
	for flag: StringName in [&"mom_greeted", &"starter_chosen", &"rival_battle_done",
			&"rival_challenged", &"badge_boulder"]:
		state.flags.set_flag(flag)
	state.party.add(PokemonFactory.create(data, &"abra", 15, GameRng.new(3)))
	state.bag.add(CANDY, candies)
	var map := (load(MapCatalog.scene_path(&"pewter_city")) as PackedScene).instantiate() \
		as GameMap
	var cell := map.get_spawn_cell(&"from_route_3_c")
	map.free()
	state.set_player_location(&"pewter_city", cell, Vector2i.DOWN)
	assert_eq(_save.write(state.to_dict()), OK)
	await _start_boot()
	assert_true(_boot.has_resumed(), "partie reprise")
	_boot.get_battle_director().get_move_learn_prompt().speed_scale = 0.0


func _use_candy_on_abra() -> bool:
	var menu := _boot.get_menu_director()
	if not menu.is_open():
		assert_true(menu.open(), "le menu s'ouvre")
	menu.request_item_use(CANDY)
	return menu.use_item_on(CANDY, 0)


## Fait avancer le voile du niveau puis l'écran d'évolution jusqu'à la fin du déroulé.
func _finish_candy() -> void:
	var overlay := _boot.get_tm_learn_overlay()
	var director := _boot.get_evolution_director()
	var screen := director.get_screen()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while _boot.is_rare_candy_running() and Time.get_ticks_msec() < deadline:
		if overlay.is_open() and overlay.get_message_banner().is_waiting():
			overlay.get_message_banner().skip()
		elif director.is_playing():
			var banner := screen.get_message_banner()
			if banner.is_waiting():
				banner.skip()
			elif screen.is_waiting_touch():
				var touch := InputEventScreenTouch.new()
				touch.pressed = true
				touch.position = Vector2(960, 540)
				get_viewport().push_input(touch)
				var release := InputEventScreenTouch.new()
				release.position = touch.position
				get_viewport().push_input(release)
		await get_tree().process_frame
	assert_false(_boot.is_rare_candy_running(), "le déroulé s'est terminé")
	await _until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(3)


func test_pause_during_an_item_evolution_keeps_candy_level_and_species_together() -> void:
	await _resume_with_abra(2)
	assert_true(_use_candy_on_abra())
	assert_true(_boot.is_rare_candy_running())
	assert_eq(GameState.bag.count_of(CANDY), 1, "bonbon retiré en mémoire")
	# Pendant le voile du niveau : arrière-plan.
	var saved_during: Array = []
	_background()
	saved_during.append([_saved_item(CANDY), _saved_species(),
		int((_saved()["party"][0] as Dictionary).get("level", 0))])
	# Au début de l'écran d'évolution (Abra encore Abra en mémoire) : arrière-plan encore.
	_boot.get_evolution_director().evolution_started.connect(
		func(_index: int, _into: StringName) -> void:
			_background()
			saved_during.append([_saved_item(CANDY), _saved_species(),
				int((_saved()["party"][0] as Dictionary).get("level", 0))]))
	await _finish_candy()
	assert_eq(saved_during, [[2, ["abra"], 15], [2, ["abra"], 15]],
		"sur le disque : bonbon, espèce et niveau d'avant, ensemble")
	assert_eq(GameState.party.get_at(0).species_id, &"kadabra")
	assert_eq([_saved_item(CANDY), _saved_species(),
		int((_saved()["party"][0] as Dictionary).get("level", 0))], [1, ["kadabra"], 16],
		"à la fin : consommé et évolué ensemble")
	await _relaunch()
	assert_eq([GameState.party.get_at(0).species_id, GameState.party.get_at(0).level,
		GameState.bag.count_of(CANDY)], [&"kadabra", 16, 1], "une seule fois")
	assert_push_error_count(0)


func test_killed_during_an_item_evolution_the_candy_is_still_there() -> void:
	await _resume_with_abra(1)
	assert_true(_use_candy_on_abra())
	_now[0] += 10.0
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await _relaunch()
	assert_eq([GameState.party.get_at(0).species_id, GameState.party.get_at(0).level,
		GameState.bag.count_of(CANDY)], [&"abra", 15, 1],
		"rien de perdu, rien de dupliqué : le bonbon est à réutiliser")
	assert_push_error_count(0)


# --- Mémoire basse -----------------------------------------------------------------------

func test_a_memory_warning_writes_the_checkpoint_without_leaving_the_foreground() -> void:
	await _start_boot()
	var money := GameState.money
	var runner := _boot.get_dialogue_runner()
	assert_true(runner.play(&"mom_wakeup", null, _boot.get_map()))
	await wait_process_frames(2)
	assert_false(_boot.is_stable())
	GameState.add_money(500)
	var writes := _writes()
	var play_time := GameState.play_time
	_now[0] += 10.0
	_boot.notification(Node.NOTIFICATION_OS_MEMORY_WARNING)
	assert_eq(_writes(), writes + 1, "point de reprise écrit")
	assert_eq(int(_saved().get("money", -1)), money, "état d'avant le dialogue")
	_boot._process(0.1)
	assert_gt(GameState.play_time, play_time, "toujours au premier plan")
	_now[0] += 0.5
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_writes(), writes + 1, "déjà sur le disque : rien de plus")
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while runner.is_running() and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_push_error_count(0)
