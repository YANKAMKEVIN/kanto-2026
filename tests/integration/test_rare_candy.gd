extends GutTest
## Super Bonbon dans le vrai Boot (jalon 14, T18b ; `jalon-14.md` §2.6, dossier 17 §5) : Sac →
## Super Bonbon → UTILISER → un Pokémon. Abra 15 → 16 (n° 62), puis évolution en Kadabra (annulable,
## comme une évolution par niveau) et Choc Mental appris ; niveau 100 et K.O. refusés sans rien
## consommer ; quatre capacités : l'écran « oublier une capacité » ; annulation de l'évolution :
## Abra reste au niveau 16, le bonbon est consommé. Pendant tout le déroulé la partie n'est pas
## stable (la sauvegarde reste celle d'avant, bonbon compris) ; à la fin, autosave (bonbon, niveau,
## capacités et espèce ensemble) ; une nouvelle session relit tout.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const SAVE_PATH := "user://test_rare_candy_save.json"
const FADE := 0.05
const TIMEOUT := 15.0
const CANDY := &"rare_candy"
const FLAGS: Array[StringName] = [&"mom_greeted", &"starter_chosen", &"rival_battle_done",
	&"rival_challenged", &"badge_boulder"]
## Équipe : Abra 15 (évolue au 16), Roucarnage 100, Rattata K.O., Papilusion 20 à quatre
## capacités (Ultrason au 21).
const ABRA := 0
const MAXED := 1
const FAINTED := 2
const FULL := 3
const FULL_MOVES: Array[StringName] = [&"confusion", &"poison_powder", &"stun_spore",
	&"sleep_powder"]

var _boot: Boot
var _fades: Array[float] = []
var _fs: MemoryFs
## Relevés au moment de evolution_applied : [place, espèce, partie stable, bonbons sauvegardés,
## niveau sauvegardé de la place].
var _applied: Array = []
## Phrases du bandeau de l'écran d'évolution.
var _evolution_lines: Array[String] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-14T10:00:00")
	_fs = MemoryFs.new()
	_applied.clear()
	_evolution_lines.clear()


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


## Partie sauvegardée à Argenta avec l'équipe ci-dessus et [param candies] Super Bonbons, reprise
## par un vrai Boot (durées du combat à [param speed]).
func _resume(candies: int, speed: float = 0.0) -> void:
	var data := PokemonData.new()
	data.load_dir()
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-14T09:00:00")
	state.new_game(42)
	for flag: StringName in FLAGS:
		state.flags.set_flag(flag)
	state.party.add(PokemonFactory.create(data, &"abra", 15, GameRng.new(3)))
	state.party.add(PokemonFactory.create(data, &"pidgeot", 100, GameRng.new(3)))
	var rattata := PokemonFactory.create(data, &"rattata", 12, GameRng.new(3))
	rattata.hp = 0
	state.party.add(rattata)
	var butterfree := PokemonFactory.create(data, &"butterfree", 20, GameRng.new(3))
	butterfree.moves.clear()
	for move_id: StringName in FULL_MOVES:
		butterfree.learn_move(move_id, data)
	state.party.add(butterfree)
	state.bag.add(CANDY, candies)
	state.bag.add(&"potion", 2)
	var map := (load(MapCatalog.scene_path(&"pewter_city")) as PackedScene).instantiate() \
		as GameMap
	var cell := map.get_spawn_cell(&"from_route_3_c")
	map.free()
	state.set_player_location(&"pewter_city", cell, Vector2i.DOWN)
	assert_eq(SaveSystem.new(_fs, SAVE_PATH).write(state.to_dict()), OK)
	await _start()
	assert_true(_boot.has_resumed(), "partie reprise")
	_boot.get_battle_director().speed_scale = speed
	_boot.get_battle_director().get_move_learn_prompt().speed_scale = 0.0
	_boot.get_evolution_director().evolution_applied.connect(_on_applied)
	_boot.get_evolution_director().get_screen().get_message_banner().message_shown.connect(
		func(text: String, _wait: bool) -> void: _evolution_lines.append(text))
	assert_eq(_moves_of(GameState.party.get_at(FULL)), FULL_MOVES, "Papilusion : 4 capacités")


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"player_house_2f"
	_boot.start_spawn = &"start"
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await _until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(3)


## Comme wait_until, mais aussi pendant la pause du menu (l'attente de GUT est suspendue avec
## l'arbre) : une image à la fois, jusqu'à [param predicate] ou au délai de garde.
func _until(predicate: Callable, max_time: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(max_time * 1000.0)
	while not predicate.call():
		if Time.get_ticks_msec() > deadline:
			return false
		await get_tree().process_frame
	return true


func _on_applied(index: int, into: StringName) -> void:
	var save := _saved()
	_applied.append([index, into, _boot.is_stable(), _saved_candies(save),
		int(_saved_member(save, index).get("level", 0))])


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.read_text(SAVE_PATH))
	return parsed if parsed is Dictionary else {}


func _saved_candies(save: Dictionary) -> int:
	return int(((save.get("bag", {}) as Dictionary).get("items", {}) as Dictionary).get(
		String(CANDY), 0))


func _saved_member(save: Dictionary, index: int) -> Dictionary:
	var party: Array = save.get("party", [])
	if index >= party.size() or not party[index] is Dictionary:
		return {}
	return party[index]


func _moves_of(pokemon: Pokemon) -> Array[StringName]:
	var result: Array[StringName] = []
	for slot: MoveSlot in pokemon.moves:
		result.append(slot.move_id)
	return result


## Sac → Super Bonbon → UTILISER → choix du Pokémon (vue relevée) → le Pokémon [param index].
func _use_candy_on(index: int) -> bool:
	var menu := _boot.get_menu_director()
	var pickers: Array[PartyPickerView] = []
	var collect := func(view: PartyPickerView) -> void: pickers.append(view)
	menu.bag_targets_shown.connect(collect)
	if not menu.is_open():
		assert_true(menu.open(), "le menu s'ouvre")
	menu.request_item_use(CANDY)
	menu.bag_targets_shown.disconnect(collect)
	assert_eq(pickers.size(), 1, "choix du Pokémon")
	return menu.use_item_on(CANDY, index)


## Attend que le bandeau du voile attende un toucher, et renvoie sa phrase.
func _overlay_line() -> String:
	var banner := _boot.get_tm_learn_overlay().get_message_banner()
	await _until(func() -> bool: return banner.is_waiting(), TIMEOUT)
	return banner.get_text()


## Fait avancer l'écran d'évolution jusqu'à sa fermeture (touchers et bandeaux).
func _finish_evolution() -> void:
	var director := _boot.get_evolution_director()
	var screen := director.get_screen()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while director.is_playing() and Time.get_ticks_msec() < deadline:
		var banner := screen.get_message_banner()
		if banner.is_waiting():
			banner.skip()
		elif screen.is_waiting_touch():
			_touch()
		await get_tree().process_frame
	await _until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(3)


func _touch() -> void:
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(960, 540)
	get_viewport().push_input(touch)
	var release := InputEventScreenTouch.new()
	release.position = touch.position
	get_viewport().push_input(release)


func test_abra_15_climbs_to_16_then_evolves_into_kadabra() -> void:
	await _resume(2)
	var abra: Pokemon = GameState.party.get_at(ABRA)
	var hp_before := abra.hp
	var max_before := abra.max_hp()
	assert_true(_use_candy_on(ABRA))
	assert_true(_boot.is_rare_candy_running())
	assert_false(_boot.is_stable(), "pendant le déroulé : rien n'est écrit")
	assert_eq(GameState.bag.count_of(CANDY), 1, "bonbon retiré avec l'effet")
	assert_eq(abra.level, 16)
	assert_eq(abra.max_hp() - max_before, abra.hp - hp_before, "PV montés de la différence")
	var overlay := _boot.get_tm_learn_overlay()
	assert_true(overlay.is_open(), "voile au-dessus du menu")
	assert_true(_boot.get_menu_director().is_open(), "le menu reste dessous")
	assert_eq(await _overlay_line(), "Abra monte au niveau 16 !", "texte n° 62")
	assert_eq(_saved_candies(_saved()), 2, "sauvegarde d'avant, bonbon compris")
	overlay.get_message_banner().skip()
	await _until(func() -> bool: return _boot.get_evolution_director().is_playing() \
		or not _boot.is_rare_candy_running(), TIMEOUT)
	assert_false(overlay.is_open())
	assert_false(_boot.get_menu_director().is_open(), "menu fermé pour l'évolution")
	await _finish_evolution()
	assert_false(_boot.is_rare_candy_running())
	assert_eq(abra.species_id, &"kadabra", "évolution par niveau")
	assert_eq(abra.level, 16)
	assert_true(abra.knows_move(&"confusion"), "Choc Mental (Kadabra, niveau 16)")
	assert_true(GameState.pokedex.is_caught(&"kadabra"))
	assert_true(_evolution_lines.has("Kadabra apprend Choc Mental !"),
		str(_evolution_lines))
	assert_eq(_applied.size(), 1)
	assert_eq(_applied[0], [ABRA, &"kadabra", false, 2, 15],
		"pendant l'évolution : la sauvegarde d'avant (bonbon et niveau ensemble)")
	assert_true(_boot.get_player().is_input_enabled(), "retour au monde")
	var save := _saved()
	assert_eq(_saved_candies(save), 1, "autosave : bonbon consommé")
	assert_eq([_saved_member(save, ABRA).get("species"),
		int(_saved_member(save, ABRA).get("level"))], ["kadabra", 16])
	# Nouvelle session : relue telle quelle.
	_boot.queue_free()
	await wait_process_frames(2)
	await _start()
	var reloaded: Pokemon = GameState.party.get_at(ABRA)
	assert_eq([reloaded.species_id, reloaded.level], [&"kadabra", 16])
	assert_true(reloaded.knows_move(&"confusion"))
	assert_eq(GameState.bag.count_of(CANDY), 1)
	assert_push_error_count(0)


func test_level_100_and_fainted_are_refused_and_nothing_changes() -> void:
	await _resume(1)
	var menu := _boot.get_menu_director()
	var pickers: Array[PartyPickerView] = []
	menu.bag_targets_shown.connect(pickers.append)
	assert_true(menu.open())
	menu.request_item_use(CANDY)
	var picker: PartyPickerView = pickers.back()
	assert_eq([picker.target_at(MAXED).usable, picker.target_at(MAXED).reason],
		[false, "Sans effet"])
	assert_eq([picker.target_at(FAINTED).usable, picker.target_at(FAINTED).reason],
		[false, "Ce Pokémon est K.O."])
	assert_false(menu.use_item_on(CANDY, MAXED), "niveau 100")
	assert_false(menu.use_item_on(CANDY, FAINTED), "K.O.")
	assert_false(_boot.is_rare_candy_running())
	assert_eq(GameState.bag.count_of(CANDY), 1, "rien consommé")
	assert_eq((GameState.party.get_at(MAXED) as Pokemon).level, 100)
	assert_eq((GameState.party.get_at(FAINTED) as Pokemon).level, 12)
	assert_true(menu.is_open(), "le Sac reste ouvert")
	menu.close()
	await wait_process_frames(3)
	assert_eq(_saved_candies(_saved()), 1)


func test_four_moves_open_the_forget_screen_then_back_to_the_bag() -> void:
	await _resume(1)
	var butterfree: Pokemon = GameState.party.get_at(FULL)
	var menu := _boot.get_menu_director()
	var pickers: Array[PartyPickerView] = []
	menu.bag_targets_shown.connect(pickers.append)
	assert_true(_use_candy_on(FULL))
	assert_eq(await _overlay_line(), "Papilusion monte au niveau 21 !")
	var overlay := _boot.get_tm_learn_overlay()
	overlay.get_message_banner().skip()
	var prompt := _boot.get_battle_director().get_move_learn_prompt()
	await _until(func() -> bool: return prompt.get_forget_panel() != null \
		and prompt.get_forget_panel().is_visible_in_tree(), TIMEOUT)
	assert_not_null(prompt.get_forget_panel(), "écran « oublier une capacité »")
	# Retour Android pendant le déroulé : absorbé (le menu reste ouvert, rien ne change).
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(menu.is_open())
	assert_true(_boot.is_rare_candy_running())
	prompt.get_forget_panel().forget_chosen.emit(0)
	assert_eq(await _overlay_line(), "Papilusion oublie Choc Mental et apprend Ultrason !")
	overlay.get_message_banner().skip()
	await _until(func() -> bool: return not _boot.is_rare_candy_running(), TIMEOUT)
	assert_false(overlay.is_open())
	assert_true(menu.is_open(), "pas d'évolution : retour au Sac")
	assert_true(_boot.get_player().is_input_enabled())
	assert_eq(butterfree.level, 21)
	assert_eq(_moves_of(butterfree), [&"supersonic", &"poison_powder", &"stun_spore",
		&"sleep_powder"] as Array[StringName])
	assert_eq(GameState.bag.count_of(CANDY), 0)
	assert_eq(pickers.back().target_at(FULL).reason, "Il n'en reste plus",
		"choix du Pokémon réémis")
	assert_eq(_saved_candies(_saved()), 1, "rien d'écrit avant la fermeture du menu")
	menu.close()
	await _until(func() -> bool: return _saved_candies(_saved()) == 0, TIMEOUT)
	var member := _saved_member(_saved(), FULL)
	assert_eq(int(member.get("level")), 21, "autosave à la fermeture")
	assert_push_error_count(0)


func test_keeping_all_moves_still_spends_the_candy() -> void:
	await _resume(1)
	var butterfree: Pokemon = GameState.party.get_at(FULL)
	assert_true(_use_candy_on(FULL))
	await _overlay_line()
	_boot.get_tm_learn_overlay().get_message_banner().skip()
	var prompt := _boot.get_battle_director().get_move_learn_prompt()
	await _until(func() -> bool: return prompt.get_forget_panel() != null \
		and prompt.get_forget_panel().is_visible_in_tree(), TIMEOUT)
	prompt.get_forget_panel().skip_chosen.emit()
	assert_eq(await _overlay_line(), "Papilusion n'apprend pas Ultrason.")
	_boot.get_tm_learn_overlay().get_message_banner().skip()
	await _until(func() -> bool: return not _boot.is_rare_candy_running(), TIMEOUT)
	assert_eq(butterfree.level, 21, "le niveau est gagné")
	assert_eq(_moves_of(butterfree), FULL_MOVES, "NE PAS APPRENDRE : capacités gardées")
	assert_eq(GameState.bag.count_of(CANDY), 0, "bonbon consommé")


func test_cancelling_the_evolution_keeps_abra_at_16_and_spends_the_candy() -> void:
	await _resume(1, 1.0)
	var abra: Pokemon = GameState.party.get_at(ABRA)
	assert_true(_use_candy_on(ABRA))
	await _overlay_line()
	_boot.get_tm_learn_overlay().get_message_banner().skip()
	var screen := _boot.get_evolution_director().get_screen()
	await _until(func() -> bool: return screen.is_transforming(), TIMEOUT)
	assert_true(screen.is_stop_active(), "ARRÊTER présent (évolution par niveau)")
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _finish_evolution()
	assert_eq(abra.species_id, &"abra", "évolution annulée")
	assert_eq(abra.level, 16)
	assert_eq(_applied, [], "jamais appliquée")
	assert_eq(GameState.bag.count_of(CANDY), 0, "le bonbon a servi")
	assert_eq(RareCandy.evolution_after(abra, _boot.get_pokemon_data()), &"kadabra",
		"reproposée au prochain niveau gagné")
	var save := _saved()
	assert_eq(_saved_candies(save), 0)
	assert_eq([_saved_member(save, ABRA).get("species"),
		int(_saved_member(save, ABRA).get("level"))], ["abra", 16])
	assert_true(_boot.get_player().is_input_enabled())
