extends GutTest
## Tranche A du jalon 9 intégrée (jalon-09.md §6.11) : poison, évolution et Dresseurs ensemble,
## avec la vraie scène Boot, la carte de QA `qa_forest_systems`, les départs `trainers_qa` et
## `evolution_qa`, le combat instantané et une sauvegarde en mémoire :
## - un Dresseur de la forêt dont l'Aspicot connaît Dard-Venin peut empoisonner en combat de
##   Dresseur (Scout Noé : Aspicot puis Coconfort) ; le statut reste après le combat ;
## - une victoire contre un Dresseur qui fait passer Chenipan au N7 (Scout Théo) déclenche
##   l'écran d'évolution **après le bilan**, et la réplique « après » du Dresseur vient
##   **après l'évolution** (le combat rend la main une fois l'évolution jouée) ;
## - un Chenipan empoisonné qui évolue reste empoisonné ;
## - `trainers_qa` et `poison_qa` portent les Antidotes ajoutés à l'intégration.
## Graines : cherchées sur le moteur pur en reproduisant la consommation d'aléatoire du
## directeur (équipe du Dresseur, puis le combat ; le joueur joue toujours sa 1re capacité).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const TRAINERS_START := "res://tools/debug_start/trainers_qa.json"
const EVOLUTION_START := "res://tools/debug_start/evolution_qa.json"
const POISON_START := "res://tools/debug_start/poison_qa.json"
const SAVE_PATH := "user://test_forest_systems_together_save.json"
const DATE := "2026-10-07T17:00:00"
const FADE := 0.05
const SCENE_TIMEOUT_MS := 60000
const MAX_SEED := 800

var _fs: MemoryFs
var _boot: Boot
var _saved_router: Array = []
## Moments notés dans l'ordre (dialogues, bilan, évolution, fin du combat).
var _order: Array[String] = []
var _events: Array[BattleEvent] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	Haptics.sink = func(_ms: int) -> void: pass
	_fs = MemoryFs.new()
	_order.clear()
	_events.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Haptics.reset()


## Boot sur la carte de QA au point du départ [param start_path], partie appliquée à la main
## (un départ de débogage n'est pas lu sous GUT), combat instantané, moments notés.
func _start(start_path: String) -> DebugStart:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	var start := DebugStart.new()
	add_child_autofree(_boot)
	assert_true(start.load_file(start_path, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	await wait_process_frames(2)
	await SceneRouter.change_map(start.map, start.spawn, start.facing)
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, &"qa_forest_systems")
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var battles := _boot.get_battle_director()
	battles.speed_scale = 0.0
	battles.event_played.connect(_events.append)
	battles.exp_summary_shown.connect(func(_s: ExpSummary) -> void: _order.append("SUMMARY"))
	battles.battle_finished.connect(func(_t: StringName, _o: int) -> void:
		_order.append("FINISHED"))
	var evolutions := _boot.get_evolution_director()
	evolutions.evolution_started.connect(func(_i: int, into: StringName) -> void:
		_order.append("EVOLUTION %s" % into))
	evolutions.evolution_finished.connect(func(_i: int, _into: StringName, c: bool) -> void:
		_order.append("CANCELLED" if c else "EVOLVED"))
	_boot.get_dialogue_runner().dialogue_started.connect(func(id: StringName) -> void:
		_order.append("DIALOGUE %s" % id))
	return start


## Graine d'une victoire contre [param trainer_id] avec l'équipe courante
## de GameState, qui vérifie [param wanted] sur les événements ; −1 si aucune.
func _seed(trainer_id: StringName, wanted: Callable) -> int:
	var data := _boot.get_pokemon_data()
	var items := _boot.get_item_library()
	var library := TrainerLibrary.new(data)
	library.load_dir()
	var trainer := library.get_trainer(trainer_id)
	for seed: int in range(MAX_SEED):
		var party := _copy_party(data)
		var rng := GameRng.new(seed)
		var foes := library.build_team(trainer_id, GameState.starter_species, rng)
		var battle := Battle.new(BattleSide.new(party, true),
			BattleSide.new(foes, false, trainer.name, trainer.make_ai()), data, rng,
			BattleRules.for_trainer(trainer, items))
		var events: Array[BattleEvent] = []
		events.append_array(battle.start())
		var turns := 0
		while battle.get_state() == Battle.State.CHOOSING and turns < 80:
			events.append_array(battle.submit(BattleAction.move(0)))
			turns += 1
		if battle.get_outcome() == Battle.Outcome.WIN and wanted.call(events):
			return seed
	return -1


## Copie de l'équipe de GameState (même individus) pour la recherche de graine.
func _copy_party(data: PokemonData) -> Party:
	var copy := Party.new()
	for pokemon: Pokemon in GameState.party.get_all():
		copy.add(Pokemon.from_dict(pokemon.to_dict(), data))
	return copy


func _has(events: Array[BattleEvent], kind: BattleEvent.Kind,
		side: BattleEvent.SideId = BattleEvent.SideId.PLAYER) -> bool:
	return events.any(func(e: BattleEvent) -> bool: return e.kind == kind and e.side == side)


## Défi à la parole de [param npc_id] (ce que fait le contrôleur d'interactions), puis la
## séquence jusqu'au bout : pages avancées, combat piloté (ATTAQUER puis 1re capacité).
func _challenge_and_play(npc_id: StringName) -> void:
	var npc := _boot.get_map().get_npc(npc_id)
	assert_not_null(npc, "Dresseur %s posé sur la carte" % npc_id)
	assert_true(_boot.get_trainer_watcher().challenge(npc), "défi lancé")
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running()) and Time.get_ticks_msec() < deadline:
		if battles.is_running():
			var battle := battles.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match hud.get_zone():
					BattleHud.Zone.ACTIONS:
						hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						hud.move_selected.emit(0)
		await wait_process_frames(1)
		if box.is_open():
			box.advance_requested.emit()
	await wait_process_frames(3)
	assert_false(director.is_running(), "séquence terminée")


func test_trainers_qa_carries_an_antidote() -> void:
	await _start(TRAINERS_START)
	assert_eq(GameState.bag.count_of(&"antidote"), 1)


func test_poison_qa_starts_poisoned_with_two_antidotes() -> void:
	await _start(POISON_START)
	assert_true(GameState.party.get_lead().has_status(StatusRules.POISON))
	assert_eq(GameState.bag.count_of(&"antidote"), 2)


func test_a_forest_trainer_weedle_can_poison_in_a_trainer_battle() -> void:
	await _start(TRAINERS_START)
	var seed := _seed(&"forest_scout_noe", func(events: Array[BattleEvent]) -> bool:
		return _has(events, BattleEvent.Kind.STATUS_INFLICTED) \
			and _has(events, BattleEvent.Kind.STATUS_DAMAGED) \
			and not _has(events, BattleEvent.Kind.FAINTED))
	assert_gt(seed, -1, "une victoire où Dard-Venin empoisonne le Pokémon du joueur")
	if seed < 0:
		return
	GameState.rng = GameRng.new(seed)
	await _challenge_and_play(&"noe")
	assert_true(_has(_events, BattleEvent.Kind.STATUS_INFLICTED), "empoisonné en combat")
	assert_true(_has(_events, BattleEvent.Kind.STATUS_DAMAGED), "dégât de poison en fin de tour")
	var poisoned := _events.filter(func(e: BattleEvent) -> bool:
		return e.kind == BattleEvent.Kind.STATUS_INFLICTED)
	assert_eq((poisoned[0] as BattleEvent).status, StatusRules.POISON)
	assert_true(GameState.party.get_lead().has_status(StatusRules.POISON),
		"le poison reste après le combat (Dresseur : pas de soin)")
	assert_true(GameState.flags.has_flag(&"beaten_forest_scout_noe"))
	assert_eq(_order.back(), "DIALOGUE forest_scout_noe_after")
	assert_push_error_count(0)


func test_a_trainer_win_evolves_caterpie_then_the_after_line() -> void:
	await _start(EVOLUTION_START)
	# Chenipan N6 (à 1 XP du N7) en tête : il combat seul et gagne le niveau.
	GameState.party.move(1, 0)
	assert_eq(GameState.party.get_lead().species_id, &"caterpie")
	var seed := _seed(&"forest_scout_theo", func(events: Array[BattleEvent]) -> bool:
		return _has(events, BattleEvent.Kind.LEVEL_UP) \
			and not _has(events, BattleEvent.Kind.FAINTED))
	assert_gt(seed, -1, "une victoire de Chenipan sans K.O. avec montée au N7")
	if seed < 0:
		return
	GameState.rng = GameRng.new(seed)
	await _challenge_and_play(&"theo")
	assert_eq(_order, ["DIALOGUE forest_scout_theo_before", "SUMMARY", "EVOLUTION metapod",
		"EVOLVED", "FINISHED", "DIALOGUE forest_scout_theo_after"] as Array[String],
		"bilan → évolution → fin du combat → réplique « après »")
	var lead := GameState.party.get_lead()
	assert_eq([lead.species_id, lead.level], [&"metapod", 7])
	assert_true(GameState.flags.has_flag(&"beaten_forest_scout_theo"))
	assert_true(_boot.get_player().is_input_enabled(), "joueur libre à la fin")
	assert_push_error_count(0)


## Poison et évolution : un Chenipan empoisonné qui évolue reste empoisonné (le statut suit
## [method Pokemon.evolve_into]), dégâts de fin de tour compris pendant le combat.
func test_a_poisoned_caterpie_evolves_and_stays_poisoned() -> void:
	await _start(EVOLUTION_START)
	GameState.party.move(1, 0)
	GameState.party.get_lead().status = StatusRules.POISON
	var seed := _seed(&"forest_scout_theo", func(events: Array[BattleEvent]) -> bool:
		return _has(events, BattleEvent.Kind.LEVEL_UP) \
			and _has(events, BattleEvent.Kind.STATUS_DAMAGED) \
			and not _has(events, BattleEvent.Kind.FAINTED))
	assert_gt(seed, -1, "une victoire de Chenipan empoisonné, sans K.O., avec montée au N7")
	if seed < 0:
		return
	GameState.rng = GameRng.new(seed)
	await _challenge_and_play(&"theo")
	assert_true(_order.has("EVOLVED"), "il a évolué")
	var lead := GameState.party.get_lead()
	assert_eq(lead.species_id, &"metapod")
	assert_true(lead.has_status(StatusRules.POISON), "Chrysacier reste empoisonné")
	assert_eq(_order.back(), "DIALOGUE forest_scout_theo_after")
	assert_push_error_count(0)
