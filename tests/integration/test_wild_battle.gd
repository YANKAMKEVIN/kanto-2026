extends GutTest
## Combat sauvage de bout en bout (jalon 5 §3.6 à §3.11, T7) avec la vraie scène Boot sur la
## Route 1, l'autoload SceneRouter (fondus raccourcis), texte et animations de combat instantanés.
## Le joueur a un starter N5 et a déjà choisi (starter_chosen). Trois issues, graines choisies :
## - victoire : on marche dans l'herbe, une rencontre se déclenche, on gagne en jouant la 1re
##   capacité, le joueur reste libre sur sa case d'herbe, contrôles visibles ;
## - fuite : FUITE réussit, le joueur reste libre sur sa case d'herbe ;
## - défaite : l'équipe (affaiblie, face à un sauvage rapide) tombe K.O., le joueur se réveille
##   chez Maman (player_house_1f), équipe soignée, sans titre de zone (intérieur).

const STARTER := &"charmander"
const LEVEL := 5
## Graine de l'équipe du joueur (indépendante de l'aléatoire de la partie).
const PARTY_SEED := 999
const FADE := 0.05
const TIMEOUT := 12.0

var _boot: Boot
var _player: Player
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.start_map = &"route_1"
	_boot.start_spawn = &"from_pallet_w"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_player = _boot.get_player()
	await wait_process_frames(2)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		Input.action_release(action)


# --- Mise en place -------------------------------------------------------------------

## Équipe du joueur (un starter N5), toujours identique (graine PARTY_SEED).
func _starter_party(data: PokemonData) -> Party:
	var party := Party.new()
	party.add(PokemonFactory.create(data, STARTER, LEVEL, GameRng.new(PARTY_SEED)))
	return party


## Nouvelle partie sur la Route 1 : graine [param seed], starter choisi, équipe N5. Le Boot
## tourne déjà sur la Route 1 ; on ne fait que ré-amorcer l'état et l'équipe.
func _new_route_game(seed: int) -> void:
	GameState.new_game(seed)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.starter_species = STARTER
	GameState.party = _starter_party(_boot.get_pokemon_data())


## Première case de hautes herbes dont la case juste au sud est praticable, non herbue : [sud,
## herbe]. Vide si aucune (la carte en a).
func _find_grass_step(map: GameMap) -> Array[Vector2i]:
	var grid := map.get_grid()
	for y: int in range(1, map.size.y - 1):
		for x: int in range(1, map.size.x - 1):
			var g := Vector2i(x, y)
			var below := g + Vector2i.DOWN
			if grid.is_tall_grass(g) and grid.is_free(g) \
					and grid.is_free(below) and not grid.is_tall_grass(below):
				return [below, g]
	return []


## Graine d'une rencontre déclenchée au premier pas (tirage non nul), d'issue [param outcome]
## quand le joueur joue sa 1re capacité (ou fuit si [param flee]). Reproduit la consommation du
## jeu : table.roll, création du sauvage, puis le moteur. −1 si rien trouvé.
func _route_seed(flee: bool, outcome: int) -> int:
	var data := _boot.get_pokemon_data()
	var table := _boot.get_encounter_library().get_table(&"route_1", &"grass")
	for seed: int in range(0, 4000):
		var rng := GameRng.new(seed)
		var enc := table.roll(rng)
		if enc == null:
			continue
		var wild := Party.new()
		wild.add(PokemonFactory.create(data, enc.species, enc.level, rng))
		var battle := Battle.new(BattleSide.new(_starter_party(data), true),
			BattleSide.new(wild, false, "", null), data, rng, BattleRules.for_wild())
		battle.start()
		while battle.get_state() == Battle.State.CHOOSING:
			var action := BattleAction.run() if flee \
				else BattleAction.move(0 if not battle.get_usable_moves().is_empty() \
					else BattleAction.STRUGGLE)
			battle.submit(action)
		if battle.get_outcome() == outcome:
			return seed
	return -1


## Place le joueur juste au sud d'une case d'herbe, tourné vers elle.
func _stand_below_grass() -> Array[Vector2i]:
	var map := _boot.get_map()
	var step := _find_grass_step(map)
	assert_false(step.is_empty(), "une case d'herbe avec un accès au sud")
	_player.enter_map(map.get_grid(), step[0], Vector2i.UP, map.get_pixel_rect())
	return step


## Pilote un combat sauvage en cours jusqu'à la fin de la rencontre (FUITE si [param flee],
## sinon ATTAQUER puis 1re capacité). Renvoie l'issue finale.
func _drive_battle(flee: bool) -> int:
	var enc := _boot.get_encounter_director()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var outcome: Array[int] = [Battle.Outcome.NONE]
	enc.encounter_finished.connect(func(o: int) -> void: outcome[0] = o)
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while enc.is_running() and Time.get_ticks_msec() < deadline:
		if battle_director.is_running():
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						battle_hud.action_selected.emit(
							ActionGrid.RUN if flee else ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		await wait_process_frames(1)
	assert_false(enc.is_running(), "la rencontre s'est terminée")
	return outcome[0]


# --- Victoire ------------------------------------------------------------------------

func test_walking_into_grass_triggers_a_battle_won_and_the_player_stays_free() -> void:
	var seed := _route_seed(false, Battle.Outcome.WIN)
	assert_gt(seed, -1, "une graine : rencontre au 1er pas puis victoire")
	if seed < 0:
		return
	_new_route_game(seed)
	var step := _stand_below_grass()
	var enc := _boot.get_encounter_director()
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return enc.is_running(), 5.0)
	Input.action_release(&"move_up")
	assert_true(enc.is_running(), "une rencontre s'est déclenchée en marchant")
	assert_eq(_player.get_cell(), step[1], "le joueur s'est arrêté dans l'herbe")
	assert_false(_boot.get_hud().are_controls_visible(), "contrôles cachés pendant le combat")
	var outcome := await _drive_battle(false)
	assert_eq(outcome, Battle.Outcome.WIN, "victoire sauvage")
	assert_eq(_boot.get_map().map_id, &"route_1", "toujours sur la Route 1")
	assert_eq(_player.get_cell(), step[1], "le joueur est resté sur sa case d'herbe")
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_true(_boot.get_hud().are_controls_visible(), "contrôles revenus")
	assert_true(GameState.pokedex.seen_count() >= 1, "le sauvage est marqué « vu »")
	assert_push_error_count(0)


# --- Fuite ---------------------------------------------------------------------------

func test_fleeing_a_wild_battle_leaves_the_player_free() -> void:
	var seed := _route_seed(true, Battle.Outcome.FLED)
	assert_gt(seed, -1, "une graine : rencontre au 1er pas puis fuite réussie")
	if seed < 0:
		return
	_new_route_game(seed)
	var step := _stand_below_grass()
	var enc := _boot.get_encounter_director()
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return enc.is_running(), 5.0)
	Input.action_release(&"move_up")
	assert_eq(_player.get_cell(), step[1], "arrêté dans l'herbe")
	var outcome := await _drive_battle(true)
	assert_eq(outcome, Battle.Outcome.FLED, "fuite réussie")
	assert_eq(_boot.get_map().map_id, &"route_1", "toujours sur la Route 1")
	assert_eq(_player.get_cell(), step[1], "resté sur sa case d'herbe")
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_push_error_count(0)


# --- Défaite -------------------------------------------------------------------------

## Graine d'une défaite : un sauvage rapide (Rattata N10) devance et achève le starter réduit à
## 1 PV. Reproduit la rencontre forcée (BattleRequest.wild crée le sauvage, puis le moteur).
func _defeat_seed() -> int:
	var data := _boot.get_pokemon_data()
	for seed: int in range(0, 2000):
		var rng := GameRng.new(seed)
		var encounter := WildEncounter.new(&"rattata", 10, &"route_1_grass")
		var request := BattleRequest.wild(encounter, data, rng, Vector2i.ZERO)
		var party := _starter_party(data)
		party.get_lead().hp = 1
		var battle := Battle.new(BattleSide.new(party, true),
			BattleSide.new(request.foe_party, false, "", null), data, rng, request.rules)
		battle.start()
		while battle.get_state() == Battle.State.CHOOSING:
			battle.submit(BattleAction.move(0 if not battle.get_usable_moves().is_empty() \
				else BattleAction.STRUGGLE))
		if battle.get_outcome() == Battle.Outcome.LOSS:
			return seed
	return -1


func test_a_defeat_wakes_at_mom_with_a_healed_team_and_no_zone_title() -> void:
	var seed := _defeat_seed()
	assert_gt(seed, -1, "une graine de défaite sauvage")
	if seed < 0:
		return
	_new_route_game(seed)
	GameState.party.get_lead().hp = 1
	var step := _stand_below_grass()
	# Aucun titre ne doit s'afficher après la défaite (la maison est un intérieur).
	var titles: Array[String] = []
	_boot.zone_announced.connect(func(name: String, _region: String) -> void:
		titles.append(name))
	var enc := _boot.get_encounter_director()
	# Rencontre forcée contre un sauvage rapide (défaite déterministe, impossible naturellement
	# contre un sauvage N2–5 de la table).
	assert_true(enc.start_encounter(WildEncounter.new(&"rattata", 10, &"route_1_grass")))
	await wait_until(func() -> bool: return enc.is_running(), 5.0)
	var outcome := await _drive_battle(false)
	assert_eq(outcome, Battle.Outcome.LOSS, "défaite sauvage")
	await wait_until(func() -> bool:
		return _boot.get_map() != null and _boot.get_map().map_id == &"player_house_1f", TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"player_house_1f", "réveil chez Maman")
	var lead := GameState.party.get_lead()
	assert_eq(lead.hp, lead.max_hp(), "équipe soignée")
	assert_eq(_player.get_cell(), _boot.get_map().get_spawn_cell(&"heal"), "sur le point de soin")
	assert_eq(titles.size(), 0, "aucun titre de zone (intérieur)")
	await wait_until(func() -> bool: return _player.is_input_enabled(), TIMEOUT)
	assert_true(_player.is_input_enabled(), "joueur libre chez Maman")
	assert_push_error_count(0)
