extends GutTest
## Pierre Lune dans le vrai Boot (jalon 12, T23 ; `jalon-12.md` §2.9, dossier 15 §10) : Sac →
## Pierre Lune → UTILISER → choix du Pokémon (COMPATIBLE / INCOMPATIBLE) → évolution hors combat,
## non annulable. Les quatre espèces compatibles évoluent (une pierre chacune) ; un Pokémon
## incompatible est refusé sans rien changer ; la pierre quitte le Sac **exactement une fois**, au
## moment où l'évolution est appliquée ; pendant la séquence, la partie n'est pas stable (la
## sauvegarde reste celle d'avant, pierre comprise) ; à la fin, autosave ; une nouvelle session
## relit l'évolution et le Sac. Retour Android pendant la transformation : consommé, sans effet.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const SAVE_PATH := "user://test_moon_stone_save.json"
const FADE := 0.05
const TIMEOUT := 15.0
const STONE := &"moon_stone"
const FLAGS: Array[StringName] = [&"mom_greeted", &"starter_chosen", &"rival_battle_done",
	&"rival_challenged", &"pewter_badge"]
## Équipe : les quatre espèces compatibles (Nv. 20 : aucune capacité nouvelle à ce niveau) et
## Pikachu, incompatible.
const TEAM: Array[StringName] = [&"nidorina", &"nidorino", &"clefairy", &"jigglypuff", &"pikachu"]
const INTO: Array[StringName] = [&"nidoqueen", &"nidoking", &"clefable", &"wigglytuff"]

var _boot: Boot
var _fades: Array[float] = []
var _fs: MemoryFs
## Relevés au moment de evolution_applied : [place, espèce visée, pierres au Sac, espèce du
## Pokémon, partie stable, carte sauvegardée, pierres sauvegardées, espèce sauvegardée].
var _applied: Array = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-13T10:00:00")
	_fs = MemoryFs.new()
	_applied.clear()


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


## Partie sauvegardée à Argenta avec [constant TEAM] et [param stones] Pierres Lune, reprise par un
## vrai Boot (évolution instantanée sauf [param speed]).
func _resume(stones: int, speed: float = 0.0) -> void:
	var data := PokemonData.new()
	data.load_dir()
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-13T09:00:00")
	state.new_game(42)
	for flag: StringName in FLAGS:
		state.flags.set_flag(flag)
	for species: StringName in TEAM:
		state.party.add(PokemonFactory.create(data, species, 20, GameRng.new(3)))
	if stones > 0:
		state.bag.add(STONE, stones)
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
	_boot.get_evolution_director().evolution_applied.connect(_on_applied)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"player_house_2f"
	_boot.start_spawn = &"start"
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(3)


func _on_applied(index: int, into: StringName) -> void:
	var save := _saved()
	assert_false(_boot.get_player().is_input_enabled(), "joueur bloqué pendant la séquence")
	assert_false(_boot.get_menu_director().is_open(), "menu fermé avant l'évolution")
	_applied.append([index, into, GameState.bag.count_of(STONE),
		(GameState.party.get_at(index) as Pokemon).species_id, _boot.is_stable(),
		StringName(save.get("map", "")), _saved_stones(save), _saved_species(save, index)])


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.read_text(SAVE_PATH))
	return parsed if parsed is Dictionary else {}


func _saved_stones(save: Dictionary) -> int:
	return int(((save.get("bag", {}) as Dictionary).get("items", {}) as Dictionary).get(
		String(STONE), 0))


func _saved_species(save: Dictionary, index: int) -> StringName:
	var party: Array = save.get("party", [])
	if index >= party.size() or not party[index] is Dictionary:
		return &""
	return StringName(str((party[index] as Dictionary).get("species", "")))


## Sac → Pierre Lune → UTILISER → le Pokémon [param index], puis attente du retour au monde.
func _use_stone_on(index: int) -> void:
	var menu := _boot.get_menu_director()
	var pickers: Array[PartyPickerView] = []
	var collect := func(view: PartyPickerView) -> void: pickers.append(view)
	menu.bag_targets_shown.connect(collect)
	assert_true(menu.open(), "le menu s'ouvre")
	menu.request_item_use(STONE)
	menu.bag_targets_shown.disconnect(collect)
	assert_eq(pickers.size(), 1, "choix du Pokémon")
	assert_true(pickers[0].target_at(index).usable, "COMPATIBLE")
	assert_true(menu.use_item_on(STONE, index))
	assert_false(menu.is_open(), "menu fermé")
	# Évolution instantanée (vitesse 0) : elle peut finir dans l'appel ; l'état pendant la
	# séquence est relevé dans evolution_applied ([method _on_applied]).
	await wait_until(func() -> bool: return not _boot.get_evolution_director().is_playing() \
		and _boot.is_stable(), TIMEOUT)
	await wait_process_frames(3)


func test_four_compatible_species_one_stone_each() -> void:
	await _resume(4)
	for i: int in INTO.size():
		await _use_stone_on(i)
		var pokemon: Pokemon = GameState.party.get_at(i)
		assert_eq(pokemon.species_id, INTO[i], "place %d évoluée" % i)
		assert_eq(GameState.bag.count_of(STONE), 3 - i, "une pierre de moins (place %d)" % i)
		assert_true(GameState.pokedex.is_caught(INTO[i]), "Pokédex : %s possédé" % INTO[i])
	assert_false(GameState.bag.has(STONE), "plus de pierre")
	assert_eq(GameState.bag.count_of(&"potion"), 2, "le reste du Sac intact")
	assert_eq(_applied.size(), 4, "une évolution par pierre")
	for i: int in _applied.size():
		var at: Array = _applied[i]
		assert_eq(at.slice(0, 5), [i, INTO[i], 3 - i, INTO[i], false],
			"pierre retirée dans l'appel même de l'évolution (place %d)" % i)
	assert_eq(GameState.party.get_at(4).species_id, &"pikachu")


func test_incompatible_is_refused_and_nothing_changes() -> void:
	await _resume(1)
	var menu := _boot.get_menu_director()
	assert_true(menu.open())
	assert_false(menu.use_item_on(STONE, 4), "Pikachu : INCOMPATIBLE")
	assert_true(menu.is_open(), "le Sac reste ouvert")
	assert_false(_boot.get_evolution_director().is_playing())
	assert_eq(GameState.bag.count_of(STONE), 1, "rien consommé")
	assert_eq(GameState.party.get_at(4).species_id, &"pikachu")
	menu.close()
	await wait_process_frames(3)
	assert_eq(_applied, [])


func test_closing_during_the_sequence_keeps_the_save_before_then_autosave_and_reload() -> void:
	await _resume(2)
	assert_eq(_saved_stones(_saved()), 2)
	await _use_stone_on(2)
	assert_eq(_applied.size(), 1)
	var at: Array = _applied[0]
	assert_eq(at.slice(5), [&"pewter_city", 2, &"clefairy"],
		"pendant la séquence : la sauvegarde d'avant, pierre comprise")
	# Fin : autosave (évolution et pierre ensemble).
	var after := _saved()
	assert_eq(_saved_stones(after), 1)
	assert_eq(_saved_species(after, 2), &"clefable")
	# Deuxième pierre sur un autre Pokémon.
	await _use_stone_on(3)
	assert_eq(_saved_stones(_saved()), 0)
	assert_eq(_saved_species(_saved(), 3), &"wigglytuff")
	# Nouvelle session : relue telle quelle.
	_boot.queue_free()
	await wait_process_frames(2)
	_applied.clear()
	await _start()
	assert_true(_boot.has_resumed())
	assert_eq(GameState.party.get_at(2).species_id, &"clefable")
	assert_eq(GameState.party.get_at(3).species_id, &"wigglytuff")
	assert_false(GameState.bag.has(STONE))
	assert_eq(GameState.party.get_at(0).species_id, &"nidorina", "les autres inchangés")


func test_back_during_the_transformation_is_absorbed() -> void:
	await _resume(1, 1.0)
	var screen := _boot.get_evolution_director().get_screen()
	var menu := _boot.get_menu_director()
	assert_true(menu.open())
	assert_true(menu.use_item_on(STONE, 1))
	await wait_until(func() -> bool: return screen.is_transforming(), TIMEOUT)
	assert_false(screen.is_stop_active(), "pas d'ARRÊTER")
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(screen.is_transforming(), "retour sans effet")
	assert_false(menu.is_open(), "le retour n'ouvre pas le menu")
	await wait_until(func() -> bool: return screen.is_waiting_touch(), TIMEOUT)
	assert_eq(GameState.party.get_at(1).species_id, &"nidoking", "évolution faite")
	assert_eq(GameState.bag.count_of(STONE), 0)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(960, 540)
	get_viewport().push_input(touch)
	var release := InputEventScreenTouch.new()
	release.position = touch.position
	get_viewport().push_input(release)
	await wait_until(func() -> bool: return not _boot.get_evolution_director().is_playing() \
		and _boot.is_stable(), TIMEOUT)
	assert_true(_boot.get_player().is_input_enabled(), "retour au monde")
	assert_eq(_applied.size(), 1)
