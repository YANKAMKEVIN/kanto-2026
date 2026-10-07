extends GutTest
## BattleDirector + EvolutionDirector (jalon-09.md §2.3.1, T8) : une victoire qui fait monter
## un Pokémon à son niveau d'évolution le fait évoluer **après le bilan**, avant
## [signal BattleDirector.battle_finished], verrou gardé ; une défaite ne fait jamais évoluer
## (les niveaux restent) ; le retour Android pendant la transformation passe par le directeur de
## combat. Même mini-carte, même HUD et même scène que test_battle_director (speed_scale = 0,
## choix simulés : ATTAQUER puis 1re capacité). Les tests du combat existants restent inchangés
## dans test_battle_director (le filet de l'extraction du MoveLearnPrompt).

const PLAYER_SCENE := preload("res://game/player/player.tscn")
const STAGE_SCENE := preload("res://game/battle/battle_stage.tscn")
const HUD_SCENE := preload("res://game/ui/battle/battle_hud.tscn")
const GAME_STATE := preload("res://game/autoload/game_state.gd")
const FakeScreen := preload("res://tests/helpers/fake_evolution_screen.gd")
const NPCS := "res://tests/fixtures/npcs/"
const PLAYER_CELL := Vector2i(11, 7)
const PLAYER_SEED := 999

var _data: PokemonData
var _trainers: TrainerLibrary
var _texts: BattleText
var _items: ItemLibrary
var _stage: BattleStage
var _hud: BattleHud
var _player: Player
var _state: Node
var _director: BattleDirector
var _evolutions: EvolutionDirector
var _map: GameMap
## Ordre des moments notés par les signaux (bilan, évolution, fin du combat).
var _order: Array[String] = []


func before_each() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_trainers = TrainerLibrary.new(_data)
	_trainers.load_dir()
	_texts = BattleText.new()
	_texts.load_file()
	_items = ItemLibrary.new()
	_items.load_dir()
	_state = GAME_STATE.new()
	add_child_autofree(_state)
	var world := Node2D.new()
	add_child_autofree(world)
	_map = _make_map()
	world.add_child(_map)
	_player = PLAYER_SCENE.instantiate() as Player
	_map.get_entities().add_child(_player)
	_player.enter_map(_map.get_grid(), PLAYER_CELL, Vector2i.LEFT, _map.get_pixel_rect())
	_player.get_camera().make_current()
	_stage = STAGE_SCENE.instantiate() as BattleStage
	_stage.speed_scale = 0.0
	add_child_autofree(_stage)
	_hud = HUD_SCENE.instantiate() as BattleHud
	_hud.speed_scale = 0.0
	_hud.haptics_enabled = false
	add_child_autofree(_hud)
	_director = BattleDirector.new()
	_director.speed_scale = 0.0
	add_child_autofree(_director)
	_director.haptics_enabled = false
	_director.setup(_data, _trainers, _texts, _stage, _hud, _player, _state, _items)
	_evolutions = EvolutionDirector.new()
	add_child_autofree(_evolutions)
	_evolutions.setup(_state, _data, _texts, _director.get_move_learn_prompt())
	_director.set_evolution_director(_evolutions)
	_order.clear()
	_director.exp_summary_shown.connect(func(_s: ExpSummary) -> void: _order.append("SUMMARY"))
	_evolutions.evolution_started.connect(func(_i: int, into: StringName) -> void:
		_order.append("EVOLUTION %s" % into)
		_order.append("running" if _director.is_running() else "free")
		_order.append("blocked" if _player.is_blocked_by(BattleDirector.REASON) else "unblocked"))
	_evolutions.evolution_finished.connect(func(_i: int, _into: StringName, c: bool) -> void:
		_order.append("CANCELLED" if c else "EVOLVED"))
	_director.battle_finished.connect(func(_t: StringName, _o: int) -> void:
		_order.append("FINISHED"))
	await wait_process_frames(2)


func _make_map() -> GameMap:
	var map := GameMap.new()
	map.name = "EvolutionMap"
	map.map_id = &"battle_evo_map"
	map.npcs_dir = NPCS
	map.size = Vector2i(20, 18)
	for group: String in ["Entities", "Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		map.add_child(node)
	return map


## Équipe d'un seul Pokémon [param species] N[param level], à [param to_next] XP du suivant.
func _party(species: StringName, level: int, to_next: int) -> Party:
	var pokemon := PokemonFactory.create(_data, species, level, GameRng.new(PLAYER_SEED))
	var rate := _data.get_species(species).growth_rate
	pokemon.experience = ExpCurve.exp_for_level(rate, level + 1) - to_next
	var party := Party.new()
	party.add(pokemon)
	return party


func _has_kind(events: Array[BattleEvent], kind: BattleEvent.Kind) -> bool:
	return events.any(func(e: BattleEvent) -> bool: return e.kind == kind)


## Graine d'une issue [param outcome] contre [param foe_party_fn] (sauvage si [param trainer]
## est null), le joueur jouant toujours sa 1re capacité, avec un niveau gagné ; reproduit la
## consommation d'aléatoire du directeur. −1 si aucune sous la limite.
func _seed(party_fn: Callable, trainer_id: StringName, wild: StringName, wild_level: int,
		outcome: Battle.Outcome) -> int:
	var trainer := _trainers.get_trainer(trainer_id) if not trainer_id.is_empty() else null
	for seed: int in range(0, 800):
		var rng := GameRng.new(seed)
		var foes: Party
		var foe_side: BattleSide
		var rules: BattleRules
		if trainer != null:
			foes = _trainers.build_team(trainer_id, &"charmander", rng)
			foe_side = BattleSide.new(foes, false, trainer.name, trainer.make_ai())
			rules = BattleRules.for_trainer(trainer, _items)
		else:
			foes = Party.new()
			foes.add(PokemonFactory.create(_data, wild, wild_level, rng))
			foe_side = BattleSide.new(foes, false, "", null)
			rules = BattleRules.for_wild(_items)
		var battle := Battle.new(BattleSide.new(party_fn.call(), true), foe_side, _data, rng,
			rules)
		var events: Array[BattleEvent] = []
		events.append_array(battle.start())
		var turns := 0
		while battle.get_state() == Battle.State.CHOOSING and turns < 80:
			events.append_array(battle.submit(BattleAction.move(0)))
			turns += 1
		if battle.get_outcome() == outcome and _has_kind(events, BattleEvent.Kind.LEVEL_UP):
			return seed
	return -1


## Joue le combat (requête sauvage, ou dresseur si [param trainer_id]), en pilotant la HUD
## (ATTAQUER puis 1re capacité). Renvoie l'issue.
func _run(party: Party, seed: int, trainer_id: StringName, wild: StringName,
		wild_level: int) -> int:
	_state.party = party
	_state.starter_species = &"charmander"
	_state.rng = GameRng.new(seed)
	var result: Array[int] = [Battle.Outcome.NONE]
	var done: Array[bool] = [false]
	var runner := func() -> void:
		if trainer_id.is_empty():
			var encounter := WildEncounter.new(wild, wild_level, &"route_1_grass")
			var request := BattleRequest.wild(encounter, _data, _state.rng as GameRng,
				Vector2i(5, 4), _items)
			result[0] = await _director.run_request(request, _map)
		else:
			var actors: Dictionary[StringName, StringName] = {}
			result[0] = await _director.run(trainer_id, _map, actors)
		done[0] = true
	runner.call()
	var deadline := Time.get_ticks_msec() + 20000
	while not done[0] and Time.get_ticks_msec() < deadline:
		var battle := _director.get_battle()
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			match _hud.get_zone():
				BattleHud.Zone.ACTIONS:
					_hud.action_selected.emit(ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					_hud.move_selected.emit(0)
		await wait_process_frames(1)
	assert_true(done[0], "le combat s'est terminé")
	return result[0]


func test_a_win_that_reaches_the_level_evolves_after_the_summary() -> void:
	var party_fn := func() -> Party: return _party(&"charmander", 15, 1)
	var seed := _seed(party_fn, &"", &"rattata", 3, Battle.Outcome.WIN)
	assert_gt(seed, -1, "une victoire avec montée au niveau 16")
	if seed < 0:
		return
	var party: Party = party_fn.call()
	var outcome := await _run(party, seed, &"", &"rattata", 3)
	assert_eq(outcome, Battle.Outcome.WIN)
	assert_eq(_order, ["SUMMARY", "EVOLUTION charmeleon", "running", "blocked", "EVOLVED",
		"FINISHED"] as Array[String], "bilan → évolution (verrou gardé) → fin du combat")
	var lead := party.get_lead()
	assert_eq([lead.species_id, lead.level], [&"charmeleon", 16])
	assert_true(_state.pokedex.is_caught(&"charmeleon"), "Pokédex : vu et possédé")
	assert_eq(_state.pokedex.get_entry(&"charmeleon").seen_maps, [] as Array[StringName],
		"aucun habitat")
	assert_false(_director.is_running())
	assert_true(_player.is_input_enabled(), "joueur libre après")
	assert_push_error_count(0)


func test_a_defeat_never_evolves_even_after_a_level_up() -> void:
	# Chenipan N6 bat le Chenipan N6 du Scout Milo (niveau 7), puis perd contre son Aspicot.
	var party_fn := func() -> Party: return _party(&"caterpie", 6, 1)
	var seed := _seed(party_fn, &"forest_scout_milo", &"", 0, Battle.Outcome.LOSS)
	assert_gt(seed, -1, "une défaite après une montée de niveau")
	if seed < 0:
		return
	var party: Party = party_fn.call()
	var outcome := await _run(party, seed, &"forest_scout_milo", &"", 0)
	assert_eq(outcome, Battle.Outcome.LOSS)
	var lead := party.get_lead()
	assert_eq(lead.level, 7, "le niveau reste")
	assert_eq(lead.species_id, &"caterpie", "aucune évolution après une défaite")
	assert_eq(_order, ["FINISHED"] as Array[String], "ni bilan ni évolution")
	assert_false(_state.pokedex.is_seen(&"metapod"))


func test_back_during_the_transformation_goes_through_the_battle_director() -> void:
	var screen := FakeScreen.new()
	add_child_autofree(screen)
	screen.cancel = true
	screen.back = _director.handle_back
	_evolutions.set_screen(screen)
	var party_fn := func() -> Party: return _party(&"caterpie", 6, 1)
	var seed := _seed(party_fn, &"", &"rattata", 3, Battle.Outcome.WIN)
	assert_gt(seed, -1, "une victoire avec montée au niveau 7")
	if seed < 0:
		return
	var party: Party = party_fn.call()
	var outcome := await _run(party, seed, &"", &"rattata", 3)
	assert_eq(outcome, Battle.Outcome.WIN)
	assert_eq(screen.back_answers, [true] as Array[bool], "retour consommé pendant l'évolution")
	assert_eq(screen.calls, ["open", "present", "transform", "revert", "close"] as Array[String])
	assert_eq(party.get_lead().species_id, &"caterpie", "annulée")
	assert_eq(_order, ["SUMMARY", "EVOLUTION metapod", "running", "blocked", "CANCELLED",
		"FINISHED"] as Array[String])
	assert_false(_director.handle_back(), "hors combat, le retour ne sert plus")
