extends GutTest
## Pêche dans la partie (passe systèmes 2, S2C-bis ; plan du J22 §2.7, dossier 25 §7.3) :
## [FishingDirector] sur une mini-carte fabriquée en code (joueur en (3, 3) tourné vers le nord,
## eau pêchable en (3, 2), eau non pêchable en (4, 2)), puis sur la vraie scène Boot (cible
## PÊCHER du contrôleur, partie instable pendant la pêche, Sac → canne).

const PLAYER_SCENE := preload("res://game/player/player.tscn")
const BOOT_SCENE := preload("res://game/boot.tscn")
const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const PLAYER_CELL := Vector2i(3, 3)
const WATER := Vector2i(3, 2)
const PLAIN_WATER := Vector2i(4, 2)
const FADE := 0.05
const TIMEOUT := 12.0


class FakeState:
	extends Node
	var bag := Bag.new()
	var rng: GameRng = GameRng.new(7)


class FakeRunner:
	extends DialogueRunner
	var played: Array[StringName] = []

	func play(dialogue_id: StringName, _npc: Npc = null, _map: GameMap = null,
			_delay: float = 0.0) -> bool:
		played.append(dialogue_id)
		return false


class FakeEncounters:
	extends EncounterDirector
	var started: Array[WildEncounter] = []
	var terrains: Array[StringName] = []

	func start_encounter(encounter: WildEncounter, terrain: StringName = &"") -> bool:
		started.append(encounter)
		terrains.append(terrain)
		return true


var _map: GameMap
var _player: Player
var _state: FakeState
var _runner: FakeRunner
var _encounters: FakeEncounters
var _director: FishingDirector
var _clock: TweenClock


func before_each() -> void:
	_clock = null
	_map = GameMap.new()
	_map.map_id = &"qa_fish"
	_map.size = Vector2i(7, 5)
	for group: String in ["Entities", "Spawns", "Warps", "Interactables"]:
		var node := Node2D.new()
		node.name = group
		_map.add_child(node)
	var spawn := Marker2D.new()
	spawn.name = "start"
	spawn.position = Grid.cell_to_world(PLAYER_CELL)
	_map.get_node(^"Spawns").add_child(spawn)
	_map.fishable_cells = [WATER]
	add_child_autofree(_map)
	_map.get_grid().set_water(WATER)
	_map.get_grid().set_water(PLAIN_WATER)
	_player = PLAYER_SCENE.instantiate() as Player
	_map.spawn_player(_player, &"start", Vector2i.UP)
	_player.set_process(false)
	_state = FakeState.new()
	add_child_autofree(_state)
	_runner = FakeRunner.new()
	add_child_autofree(_runner)
	_encounters = FakeEncounters.new()
	add_child_autofree(_encounters)
	_director = FishingDirector.new()
	add_child_autofree(_director)
	_director.setup(_state, _qa_tables(), null, _player, _runner, _encounters, null)
	_director.set_map(_map)


func after_each() -> void:
	if _clock != null:
		_clock.release()
		_clock = null


func _qa_tables() -> WaterRodTables:
	var tables := WaterRodTables.new()
	assert_true(tables.add_from_dict({
		"old": {"maps": ["*"], "terrain": "water_rod", "rod": "old_rod", "rate": 100,
			"slots": [{"species": "goldeen", "level": 5, "weight": 1}]},
		"good": {"maps": ["*"], "terrain": "water_rod", "rod": "good_rod", "rate": 50,
			"slots": [{"species": "horsea", "level": 10, "weight": 1}]},
		"super": {"maps": ["*"], "default": true, "terrain": "water_rod", "rod": "super_rod",
			"rate": 75, "slots": [{"species": "staryu", "level": 15, "weight": 1}]},
	}, "test"))
	return tables


## Lance une pêche sous horloge simulée et la mène jusqu'à [param done].
func _fish_until(rod: StringName, done: Callable) -> void:
	_clock = TweenClock.new(get_tree())
	_director.fish(rod, WATER)
	_clock.run_until(done)


# --- Cible PÊCHER ----------------------------------------------------------------------

func test_no_rod_no_target() -> void:
	assert_null(_director.target_at(PLAYER_CELL, Vector2i.UP))


func test_rod_and_fishable_water_give_a_cached_fish_target() -> void:
	_state.bag.add(&"old_rod")
	var target := _director.target_at(PLAYER_CELL, Vector2i.UP)
	assert_not_null(target)
	assert_eq(target.kind, Interaction.Kind.FISH)
	assert_eq(target.cell, WATER)
	assert_true(target.is_valid())
	assert_same(_director.target_at(PLAYER_CELL, Vector2i.UP), target, "même instance")


func test_water_not_fishable_or_not_in_front_gives_no_target() -> void:
	_state.bag.add(&"old_rod")
	assert_null(_director.target_at(PLAYER_CELL + Vector2i.RIGHT, Vector2i.UP),
		"eau non marquée pêchable")
	assert_null(_director.target_at(PLAYER_CELL, Vector2i.LEFT), "pas face à l'eau")


func test_no_target_while_fishing() -> void:
	_state.bag.add(&"old_rod")
	_clock = TweenClock.new(get_tree())
	_director.fish(&"old_rod", WATER)
	assert_true(_director.is_running())
	assert_null(_director.target_at(PLAYER_CELL, Vector2i.UP))


# --- Déroulé ---------------------------------------------------------------------------

func test_the_best_rod_is_used() -> void:
	_state.bag.add(&"old_rod")
	_state.bag.add(&"super_rod")
	watch_signals(_director)
	_clock = TweenClock.new(get_tree())
	_director.on_fish_requested(WATER)
	assert_signal_emitted_with_parameters(_director, "fishing_started", [&"super_rod"])


func test_a_bite_starts_an_ordinary_wild_battle() -> void:
	_state.bag.add(&"old_rod")
	watch_signals(_director)
	_fish_until(&"old_rod", func() -> bool: return not _encounters.started.is_empty())
	assert_eq(_encounters.started.size(), 1, "combat lancé")
	assert_eq(_encounters.started[0].species, &"goldeen")
	assert_eq(_encounters.started[0].level, 5)
	assert_eq(_encounters.terrains[0], EncounterDirector.WATER_ROD_TERRAIN, "sans herbe")
	assert_eq(_runner.played, [FishingDirector.CAST_DIALOGUE,
		FishingDirector.BITE_DIALOGUE] as Array[StringName])
	assert_true(_director.is_running(), "la pêche attend la fin du combat")
	assert_true(_player.is_blocked_by(FishingDirector.INPUT_REASON))
	_encounters.encounter_finished.emit(Battle.Outcome.WIN)
	assert_false(_director.is_running())
	assert_true(_player.is_input_enabled(), "entrée rendue")
	assert_signal_emitted_with_parameters(_director, "fishing_finished", [true])


func test_nothing_bites_plays_the_text_and_frees_the_player() -> void:
	_state.bag.add(&"good_rod")
	# Attente : roll(11) = 1 → 1,0 s ; touche : chance(50, 100) avec 100 → rien.
	_state.rng = ScriptedRng.new([1, 100])
	watch_signals(_director)
	_fish_until(&"good_rod", func() -> bool: return not _director.is_running())
	assert_false(_director.is_running())
	assert_eq(_encounters.started.size(), 0, "aucun combat")
	assert_eq(_runner.played, [FishingDirector.CAST_DIALOGUE,
		FishingDirector.NOTHING_DIALOGUE] as Array[StringName])
	assert_true(_player.is_input_enabled())
	assert_signal_emitted_with_parameters(_director, "fishing_finished", [false])


func test_the_wait_lasts_one_to_two_seconds() -> void:
	_state.bag.add(&"good_rod")
	# roll(11) = 11 → 2,0 s ; puis rien ne mord.
	_state.rng = ScriptedRng.new([11, 100])
	_clock = TweenClock.new(get_tree())
	_director.fish(&"good_rod", WATER)
	var steps := _clock.run_until(func() -> bool: return not _director.is_running())
	assert_between(steps, 120, 121, "2 s simulées (un pas de plus au plus)")


func test_player_is_blocked_during_the_wait() -> void:
	_state.bag.add(&"old_rod")
	_clock = TweenClock.new(get_tree())
	_director.fish(&"old_rod", WATER)
	assert_true(_director.is_running())
	assert_false(_player.is_input_enabled(), "Boot.is_stable faux : entrée bloquée")
	assert_true(_player.is_blocked_by(FishingDirector.INPUT_REASON))


func test_unknown_species_bites_nothing() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	# Jalon 24 : Magicarpe existe désormais ; une table à espèce inconnue garde le cas.
	var tables := WaterRodTables.new()
	assert_true(tables.add_from_dict({"old_rod_any": {"maps": ["*"], "terrain": "water_rod",
		"rod": "old_rod", "rate": 100,
		"slots": [{"species": "missingno", "level": 5, "weight": 1}]}}, "test"))
	_director.setup(_state, tables, data, _player, _runner, _encounters, null)
	_state.bag.add(&"old_rod")
	_fish_until(&"old_rod", func() -> bool: return not _director.is_running())
	assert_push_error("espèce inconnue")
	assert_eq(_encounters.started.size(), 0)
	assert_eq(_runner.played.back(), FishingDirector.NOTHING_DIALOGUE)
	assert_true(_player.is_input_enabled())


# --- Sac → canne -----------------------------------------------------------------------

func test_bag_rod_without_water_says_no_fishing_here() -> void:
	_state.bag.add(&"good_rod")
	_player.face(Vector2i.LEFT)
	watch_signals(_director)
	assert_true(_director.use_rod(&"good_rod"))
	assert_eq(_runner.played, [FishingDirector.NO_WATER_DIALOGUE] as Array[StringName])
	assert_signal_not_emitted(_director, "fishing_started")


func test_bag_rod_in_front_of_water_fishes_with_that_rod() -> void:
	_state.bag.add(&"old_rod")
	_state.bag.add(&"super_rod")
	watch_signals(_director)
	_clock = TweenClock.new(get_tree())
	assert_true(_director.use_rod(&"old_rod"))
	assert_signal_emitted_with_parameters(_director, "fishing_started", [&"old_rod"])


func test_rod_not_in_bag_is_refused() -> void:
	assert_false(_director.use_rod(&"old_rod"))
	assert_eq(_runner.played.size(), 0)


func test_key_item_director_routes_rods_to_fishing() -> void:
	var items := ItemLibrary.new()
	assert_true(items.load_dir())
	var key_items := KeyItemDirector.new()
	add_child_autofree(key_items)
	key_items.setup(_state, items, null, _runner, null, null, _player)
	key_items.set_fishing(_director)
	_state.bag.add(&"super_rod")
	_player.face(Vector2i.DOWN)
	assert_true(key_items.use(&"super_rod"))
	assert_eq(_runner.played, [FishingDirector.NO_WATER_DIALOGUE] as Array[StringName])


# --- Données ----------------------------------------------------------------------------

func test_rods_are_key_items_used_in_the_field_only() -> void:
	var items := ItemLibrary.new()
	assert_true(items.load_dir())
	var names := {&"old_rod": "Canne", &"good_rod": "Super Canne", &"super_rod": "Méga Canne"}
	for rod: StringName in FishingRules.RODS:
		var item := items.get_item(rod)
		assert_not_null(item, String(rod))
		assert_eq(item.name, names[rod])
		assert_eq(item.category, ItemData.Category.KEY)
		assert_eq(item.key_use, rod)
		assert_eq(item.contexts(), [ItemData.CONTEXT_FIELD] as Array[StringName])


func test_fishing_texts_exist() -> void:
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	for id: StringName in [FishingDirector.CAST_DIALOGUE, FishingDirector.BITE_DIALOGUE,
			FishingDirector.NOTHING_DIALOGUE, FishingDirector.NO_WATER_DIALOGUE]:
		assert_true(dialogues.has_dialogue(id), String(id))


func test_qa_sea_tables_use_existing_species_for_every_rod() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var tables := WaterRodTables.new(data)
	assert_true(tables.load_file(WaterRodTables.QA_DATA_PATH), "espèces connues")
	for rod: StringName in FishingRules.RODS:
		var table := tables.get_table(rod, &"qa_sea")
		assert_not_null(table, String(rod))
		assert_eq(tables.bite_percent_of(table.id), FishingRules.bite_chance(rod))
	var all := WaterRodTables.new()
	assert_true(all.load_game_files(), "tables globales et de QA ensemble")
	assert_eq(all.get_table(&"old_rod", &"qa_sea").id, &"qa_sea_old_rod")
	assert_eq(all.get_table(&"old_rod", &"route_6").id, &"old_rod_any")


# --- Vraie scène Boot ----------------------------------------------------------------------

func _boot_on_route_1() -> Boot:
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-21T10:00:00")
	var boot := BOOT_SCENE.instantiate() as Boot
	boot.save_system = SaveSystem.new(MemoryFs.new(), "user://test_fishing_director.json")
	boot.start_map = &"route_1"
	boot.start_spawn = &"from_pallet_w"
	boot.start_facing = Vector2i.UP
	add_child_autofree(boot)
	boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return boot.is_stable(), TIMEOUT)
	GameState.flags.set_flag(&"starter_chosen")
	return boot


func _finish_dialogues(boot: Boot) -> void:
	var runner := boot.get_dialogue_runner()
	var box := boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)  # temps réel : délai de garde
	while runner.is_running() and Time.get_ticks_msec() < deadline:  # temps réel : délai de garde
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)


func test_boot_offers_fish_and_is_unstable_while_fishing() -> void:
	var fades := [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	var boot: Boot = await _boot_on_route_1()
	var player := boot.get_player()
	var map := boot.get_map()
	var water := player.get_cell() + player.get_facing()
	map.get_grid().set_water(water)
	map.fishable_cells = [water]
	var fishing := boot.get_fishing_director()
	fishing.set_map(map)
	# Jalon 24 : Magicarpe existe désormais ; une table à espèce inconnue garde le cas « rien ne
	# mord » sans lancer de combat (le joueur de ce test n'a pas d'équipe).
	var tables := WaterRodTables.new()
	tables.add_from_dict({"old_rod_any": {"maps": ["*"], "terrain": "water_rod",
		"rod": "old_rod", "rate": 100,
		"slots": [{"species": "missingno", "level": 5, "weight": 1}]}}, "test")
	fishing._tables = tables
	await wait_process_frames(2)
	var before := boot.get_interaction_controller().get_target()
	assert_true(before == null or before.kind != Interaction.Kind.FISH, "sans canne : pas PÊCHER")
	GameState.bag.add(&"old_rod")
	await wait_process_frames(2)
	var target := boot.get_interaction_controller().get_target()
	assert_not_null(target)
	assert_eq(target.kind, Interaction.Kind.FISH, "PÊCHER")
	boot.get_interaction_controller().fish_requested.emit(target.cell)
	assert_true(fishing.is_running())
	assert_false(boot.is_stable(), "pêche : pas de sauvegarde")
	await _finish_dialogues(boot)
	assert_true(fishing.is_running(), "attente de la touche")
	assert_false(boot.is_stable(), "attente : toujours instable")
	await wait_until(func() -> bool:
		return boot.get_dialogue_runner().is_running() or not fishing.is_running(), TIMEOUT)
	await _finish_dialogues(boot)
	await wait_until(func() -> bool: return not fishing.is_running(), TIMEOUT)
	# Espèce inconnue : rien ne mord, sans planter.
	assert_push_error("espèce inconnue")
	assert_false(fishing.is_running())
	await wait_until(func() -> bool: return boot.is_stable(), TIMEOUT)
	assert_true(boot.is_stable(), "pêche finie : stable")
	SceneRouter.fade_out_duration = fades[0]
	SceneRouter.fade_in_duration = fades[1]
	GameState.clock = DeviceClock.new()


func test_boot_bag_rod_without_water_says_no_fishing_here() -> void:
	var fades := [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	var boot: Boot = await _boot_on_route_1()
	var pages: Array[String] = []
	boot.get_dialogue_runner().page_started.connect(func(_index: int) -> void:
		pages.append(boot.get_dialogue_runner().get_session().get_text()))
	GameState.bag.add(&"good_rod")
	var menu := boot.get_menu_director()
	assert_true(menu.open())
	menu.request_item_use(&"good_rod")
	await wait_process_frames(3)
	assert_false(menu.is_open(), "le menu se ferme")
	assert_true(boot.get_dialogue_runner().is_running())
	assert_eq(pages, ["On ne peut pas pêcher ici."] as Array[String])
	assert_false(boot.get_fishing_director().is_running())
	await _finish_dialogues(boot)
	assert_true(GameState.bag.has(&"good_rod"), "rien n'est consommé")
	SceneRouter.fade_out_duration = fades[0]
	SceneRouter.fade_in_duration = fades[1]
	GameState.clock = DeviceClock.new()
