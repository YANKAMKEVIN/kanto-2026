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
	# Première défaite : Maman parle automatiquement, variante 1 ; le joueur est bloqué par le
	# dialogue tant qu'il n'est pas fini, puis libre ; le drapeau est levé à la fin.
	assert_false(GameState.flags.has_flag(&"blacked_out_before"), "drapeau pas encore levé")
	var first := await _drive_wakeup_dialogue()
	assert_eq(first, "Tu m'as fait une de ces peurs...", "variante de première défaite")
	assert_true(GameState.flags.has_flag(&"blacked_out_before"), "drapeau levé à la fin")
	assert_true(_player.is_input_enabled(), "joueur libre après le mot de Maman")
	assert_push_error_count(0)


# --- Mot de Maman : défaites suivantes --------------------------------------------------

func test_a_second_defeat_plays_the_reassuring_line() -> void:
	var seed := _defeat_seed()
	assert_gt(seed, -1, "une graine de défaite sauvage")
	if seed < 0:
		return
	_new_route_game(seed)
	# Le drapeau est déjà levé : une défaite précédente a eu lieu (état persistant).
	GameState.flags.set_flag(&"blacked_out_before")
	GameState.party.get_lead().hp = 1
	_stand_below_grass()
	var enc := _boot.get_encounter_director()
	assert_true(enc.start_encounter(WildEncounter.new(&"rattata", 10, &"route_1_grass")))
	await wait_until(func() -> bool: return enc.is_running(), 5.0)
	var outcome := await _drive_battle(false)
	assert_eq(outcome, Battle.Outcome.LOSS, "défaite sauvage")
	await wait_until(func() -> bool:
		return _boot.get_map() != null and _boot.get_map().map_id == &"player_house_1f", TIMEOUT)
	var first := await _drive_wakeup_dialogue()
	assert_eq(first, "Tes Pokémon vont bien maintenant.", "variante des défaites suivantes")
	assert_true(GameState.flags.has_flag(&"blacked_out_before"), "drapeau toujours levé")
	assert_true(_player.is_input_enabled(), "joueur libre après le mot de Maman")
	assert_push_error_count(0)


## Fait défiler le mot automatique de Maman jusqu'à sa fin ; renvoie le texte de sa 1re page.
func _drive_wakeup_dialogue() -> String:
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	await wait_until(func() -> bool:
		return runner.is_running() and runner.get_dialogue_id() == &"mom_wakeup" \
			and runner.get_session() != null, TIMEOUT)
	var first_text := (box.get_node(^"%Text") as Label).text
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while runner.is_running() and Time.get_ticks_msec() < deadline:
		box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(runner.is_running(), "le mot de Maman s'est terminé")
	return first_text


# --- Titre de zone pendant un combat (jalon 5C T11) -------------------------------------

## Une rencontre juste après l'arrivée sur la Route 1 (le titre « ROUTE 1 » est encore là) : le
## titre se masque au début de la rencontre, reste caché pendant le combat, et ne réapparaît
## pas à la sortie.
func test_the_zone_title_is_hidden_during_a_battle_and_does_not_come_back() -> void:
	_new_route_game(1)
	var title := _boot.get_hud().get_zone_title()
	await wait_until(func() -> bool: return title.is_showing(), 3.0)
	assert_true(title.is_showing(), "le titre de la Route 1 est affiché à l'arrivée")
	var shown: Array[String] = []
	_boot.zone_announced.connect(func(name: String, _region: String) -> void:
		shown.append(name))
	var enc := _boot.get_encounter_director()
	_stand_below_grass()
	assert_true(enc.start_encounter(WildEncounter.new(&"rattata", 3, &"route_1_grass")))
	await wait_until(func() -> bool: return not title.is_showing(), 2.0)
	assert_false(title.is_showing(), "titre masqué dès la rencontre")
	assert_true(enc.is_running(), "la rencontre est toujours en cours")
	await _drive_battle(false)
	await wait_process_frames(10)
	assert_false(title.is_showing(), "le titre ne revient pas à la sortie du combat")
	assert_eq(shown.size(), 0, "aucun nouveau titre annoncé")
	assert_push_error_count(0)


# --- Cinq victoires : niveau et capacités de Rouge/Bleu ----------------------------------

## Clone de l'équipe (même Pokémon, mêmes PV, mêmes PP) pour simuler un combat sans le jouer.
func _clone_party(party: Party) -> Party:
	var copy := Party.new()
	assert_true(copy.load_array(party.to_array(), _boot.get_pokemon_data()), "équipe clonée")
	return copy


## Graine d'une victoire sur [param species] N[param level] avec l'équipe actuelle de GameState
## (1re capacité à chaque tour) ; −1 si aucune. Même aléatoire que le jeu : BattleRequest.wild
## crée le sauvage, puis le moteur.
func _win_seed(species: StringName, level: int) -> int:
	var data := _boot.get_pokemon_data()
	for seed: int in range(0, 400):
		var rng := GameRng.new(seed)
		var request := BattleRequest.wild(WildEncounter.new(species, level, &"route_1_grass"),
			data, rng, Vector2i.ZERO)
		var battle := Battle.new(BattleSide.new(_clone_party(GameState.party), true),
			BattleSide.new(request.foe_party, false, "", null), data, rng, request.rules)
		battle.start()
		while battle.get_state() == Battle.State.CHOOSING:
			battle.submit(BattleAction.move(0 if not battle.get_usable_moves().is_empty() \
				else BattleAction.STRUGGLE))
		if battle.get_outcome() == Battle.Outcome.WIN:
			return seed
	return -1


## Un starter N5 gagne cinq combats sauvages à la suite (Roucool N5, équipe soignée entre les
## combats, 35 XP chacun : 135 + 175 = 310 XP) : N7 d'après la courbe, et les capacités de
## Rouge/Bleu à ce niveau (Vampigraine au N7 pour Bulbizarre ; rien de nouveau avant le N8 de
## Carapuce ni le N9 de Salamèche). Tout passe par le vrai jeu (Boot, rencontre, directeur).
func test_five_wins_give_the_rouge_bleu_level_and_moves_for_each_starter() -> void:
	var expected: Dictionary[StringName, Array] = {
		&"bulbasaur": [&"tackle", &"growl", &"leech_seed"],
		&"charmander": [&"scratch", &"growl"],
		&"squirtle": [&"tackle", &"tail_whip"],
	}
	var data := _boot.get_pokemon_data()
	var gain := ExpCalc.amount(PokemonFactory.create(data, &"pidgey", 5, GameRng.new(1)), data)
	assert_eq(gain, 35, "Roucool N5 rapporte 35 XP")
	for starter: StringName in expected:
		GameState.new_game(1)
		GameState.flags.set_flag(&"starter_chosen")
		GameState.starter_species = starter
		var party := Party.new()
		party.add(PokemonFactory.create(data, starter, LEVEL, GameRng.new(PARTY_SEED)))
		GameState.party = party
		var lead := party.get_lead()
		var start_exp := lead.experience
		_stand_below_grass()
		var enc := _boot.get_encounter_director()
		for fight: int in 5:
			party.heal_all()
			var seed := _win_seed(&"pidgey", 5)
			assert_gt(seed, -1, "%s combat %d : une graine de victoire" % [starter, fight + 1])
			if seed < 0:
				return
			GameState.rng = GameRng.new(seed)
			assert_true(enc.start_encounter(WildEncounter.new(&"pidgey", 5, &"route_1_grass")))
			var outcome := await _drive_battle(false)
			assert_eq(outcome, Battle.Outcome.WIN, "%s combat %d gagné" % [starter, fight + 1])
		assert_eq(lead.experience - start_exp, 5 * gain, "%s : 5 × 35 XP" % starter)
		assert_eq(lead.level, 7, "%s : niveau 7" % starter)
		var known: Array[StringName] = []
		for slot: MoveSlot in lead.moves:
			known.append(slot.move_id)
		assert_eq(known, expected[starter], "%s : capacités de Rouge/Bleu au N7" % starter)
		assert_true(_player.is_input_enabled(), "joueur libre")
	assert_push_error_count(0)


# --- Capture (jalon 5D, T15) ------------------------------------------------------------
# Une Poké Ball lancée sur un sauvage de la Route 1, par le vrai jeu (Boot, rencontre dans
# l'herbe, SAC, LANCER, carte de capture). Graines choisies par simulation du même flux.

const BALL := &"poke_ball"


## Simule le premier lancer d'une Poké Ball sur [param species] N[param level] avec la graine
## [param seed] : vrai s'il capture. [param rolled] : la rencontre est tirée dans la table de la
## Route 1 d'abord (marche dans l'herbe), sinon le sauvage est créé directement.
func _throw_catches(seed: int, species: StringName, level: int, rolled: bool) -> bool:
	var data := _boot.get_pokemon_data()
	var rng := GameRng.new(seed)
	var encounter := WildEncounter.new(species, level, &"route_1_grass")
	if rolled:
		var table := _boot.get_encounter_library().get_table(&"route_1", &"grass")
		encounter = table.roll(rng)
		if encounter == null:
			return false
	var wild := Party.new()
	wild.add(PokemonFactory.create(data, encounter.species, encounter.level, rng))
	var battle := Battle.new(BattleSide.new(_starter_party(data), true),
		BattleSide.new(wild, false, "", null), data, rng,
		BattleRules.for_wild(_boot.get_item_library()))
	battle.start()
	for event: BattleEvent in battle.submit(BattleAction.ball(BALL)):
		if event.kind == BattleEvent.Kind.CAUGHT:
			return true
	return false


## Première graine (à partir de [param from]) dont le premier lancer capture ; −1 si aucune.
func _catch_seed(species: StringName, level: int, rolled: bool, from: int = 0) -> int:
	for seed: int in range(from, from + 3000):
		if _throw_catches(seed, species, level, rolled):
			return seed
	return -1


## Pilote une rencontre jusqu'au bout : SAC puis LANCER à chaque choix (jusqu'à [param throws]
## lancers, puis FUITE) ; la carte de capture est lue puis fermée. Renvoie { outcome, card }.
func _drive_capture(throws: int = 1) -> Dictionary:
	var enc := _boot.get_encounter_director()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var report := {"outcome": Battle.Outcome.NONE, "card": {}}
	enc.encounter_finished.connect(func(o: int) -> void: report["outcome"] = o)
	var thrown := 0
	var pending := false
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while enc.is_running() and Time.get_ticks_msec() < deadline:
		var card := battle_director.get_capture_card()
		var panel := battle_director.get_bag_panel()
		var battle := battle_director.get_battle()
		if card != null and card.is_waiting():
			report["card"] = {
				"title": card.get_title_text(), "result": card.get_result_text(),
				"pokedex_shown": card.is_pokedex_line_shown(),
			}
			card.skip()
		elif pending and panel != null and panel.is_shown() and not panel.is_answered():
			pending = false
			panel.get_action_button().pressed.emit()
		elif battle != null and battle.get_state() == Battle.State.CHOOSING \
				and battle_hud.get_zone() == BattleHud.Zone.ACTIONS and not pending:
			if thrown < throws:
				thrown += 1
				pending = true
				battle_hud.action_selected.emit(ActionGrid.BAG)
			else:
				battle_hud.action_selected.emit(ActionGrid.RUN)
		await wait_process_frames(1)
	assert_false(enc.is_running(), "la rencontre s'est terminée")
	return report


func test_a_ball_thrown_in_the_grass_captures_the_wild_pokemon() -> void:
	var seed := _catch_seed(&"pidgey", 3, true)
	assert_gt(seed, -1, "une graine : rencontre au 1er pas puis capture au 1er lancer")
	if seed < 0:
		return
	_new_route_game(seed)
	GameState.bag.add(BALL, 5)
	var step := _stand_below_grass()
	var enc := _boot.get_encounter_director()
	var battle_director := _boot.get_battle_director()
	var haptics: Array[int] = []
	battle_director.haptic_requested.connect(func(ms: int) -> void: haptics.append(ms))
	var caught: Array[Pokemon] = []
	battle_director.pokemon_caught.connect(func(p: Pokemon, _stored: bool) -> void:
		caught.append(p))
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return enc.is_running(), 5.0)
	Input.action_release(&"move_up")
	assert_eq(_player.get_cell(), step[1], "arrêté dans l'herbe")
	var report := await _drive_capture()
	assert_eq(report["outcome"], Battle.Outcome.CAUGHT, "capture")
	assert_eq(GameState.bag.count_of(BALL), 4, "une Ball retirée")
	assert_eq(GameState.party.size(), 2, "équipe de 2")
	assert_eq(caught.size(), 1, "pokemon_caught une fois")
	assert_same(GameState.party.get_at(1), caught[0], "le Pokémon capturé est dans l'équipe")
	var pokemon := GameState.party.get_at(1)
	assert_true(pokemon.species_id in [&"pidgey", &"rattata"], "espèce de la table")
	assert_eq(pokemon.hp, pokemon.max_hp(), "PV pleins : aucun dégât avant la capture")
	assert_true(GameState.pokedex.is_caught(pokemon.species_id), "capturé au Pokédex")
	assert_eq(GameState.pokedex.times_seen(pokemon.species_id), 1,
		"vu au combat puis capturé : une seule observation, pas deux")
	assert_eq(pokemon.origin, Pokemon.Origin.CAPTURE)
	assert_eq(pokemon.met_map, &"route_1")
	assert_eq(GameState.moments.size(), 1, "un grand moment")
	assert_eq(GameState.moments[0]["type"], "first_capture")
	assert_eq(GameState.moments[0]["map"], "route_1")
	var card: Dictionary = report["card"]
	assert_true((card["title"] as String).ends_with("!"), "carte de capture affichée")
	assert_false(card["pokedex_shown"], "pas de ligne Pokédex avant Chen")
	assert_eq(haptics.slice(0, 3), [40, 40, 40] as Array[int], "trois secousses vibrent")
	assert_eq(haptics.slice(3), [30, 30, 120] as Array[int], "puis le motif de capture")
	# Retour à l'exploration comme après une victoire : sans soin, joueur libre sur sa case.
	assert_eq(_boot.get_map().map_id, &"route_1")
	assert_eq(_player.get_cell(), step[1], "resté sur sa case d'herbe")
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_true(_boot.get_hud().are_controls_visible(), "contrôles revenus")
	assert_false(_boot.get_battle_hud().is_shown(), "HUD de combat cachée")
	assert_false(_boot.get_battle_stage().is_active(), "scène de combat rendue")
	assert_push_error_count(0)


func test_a_second_capture_keeps_a_single_first_capture_moment() -> void:
	var first := _catch_seed(&"pidgey", 3, false)
	var second := _catch_seed(&"rattata", 3, false, 6000)
	assert_gt(first, -1)
	assert_gt(second, -1)
	if first < 0 or second < 0:
		return
	_new_route_game(first)
	GameState.bag.add(BALL, 5)
	_stand_below_grass()
	var enc := _boot.get_encounter_director()
	assert_true(enc.start_encounter(WildEncounter.new(&"pidgey", 3, &"route_1_grass")))
	assert_eq((await _drive_capture())["outcome"], Battle.Outcome.CAUGHT, "première capture")
	GameState.rng = GameRng.new(second)
	assert_true(enc.start_encounter(WildEncounter.new(&"rattata", 3, &"route_1_grass")))
	assert_eq((await _drive_capture())["outcome"], Battle.Outcome.CAUGHT, "seconde capture")
	assert_eq(GameState.party.size(), 3, "équipe de 3")
	assert_eq(GameState.bag.count_of(BALL), 3, "deux Balls retirées")
	var firsts := 0
	for moment: Dictionary in GameState.moments:
		firsts += int(moment["type"] == "first_capture")
	assert_eq(firsts, 1, "« première capture » une seule fois")
	assert_true(GameState.pokedex.is_caught(&"pidgey"))
	assert_true(GameState.pokedex.is_caught(&"rattata"))
	assert_push_error_count(0)


# --- Soin en combat (jalon 6, T12) -----------------------------------------------------------

## Pilote une rencontre : SAC, SOINS, Potion, UTILISER, puis le Pokémon [param target] ; ensuite
## FUITE jusqu'à la fin. Renvoie le nombre de fois où le choix du Pokémon s'est ouvert.
func _drive_potion(target: int) -> int:
	var enc := _boot.get_encounter_director()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var opened := 0
	var answered := false
	var stage := 0
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while enc.is_running() and Time.get_ticks_msec() < deadline:
		var picker := battle_director.get_party_picker()
		var panel := battle_director.get_bag_panel()
		var battle := battle_director.get_battle()
		if picker != null and picker.is_shown() and not answered:
			opened += 1
			answered = true
			picker.target_chosen.emit(target)
		elif panel != null and panel.is_shown() and not panel.is_answered():
			panel.open_category(&"heal")
			panel.select_item(&"potion")
			panel.get_action_button().pressed.emit()
		elif battle != null and battle.get_state() == Battle.State.CHOOSING \
				and battle_hud.get_zone() == BattleHud.Zone.ACTIONS:
			battle_hud.action_selected.emit(ActionGrid.BAG if stage == 0 else ActionGrid.RUN)
			stage = 1
		await wait_process_frames(1)
	assert_false(enc.is_running(), "la rencontre s'est terminée")
	return opened


func test_a_potion_in_a_wild_battle_heals_another_member_once() -> void:
	var seed := _route_seed(true, Battle.Outcome.FLED)
	assert_gt(seed, -1, "une graine de rencontre")
	if seed < 0:
		return
	_new_route_game(seed)
	var hurt := PokemonFactory.create(_boot.get_pokemon_data(), &"pidgey", 20, GameRng.new(3))
	hurt.hp = 4
	GameState.party.add(hurt)
	GameState.bag.add(&"potion", 3)
	_stand_below_grass()
	var enc := _boot.get_encounter_director()
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return enc.is_running(), 5.0)
	Input.action_release(&"move_up")
	var opened := await _drive_potion(1)
	assert_eq(opened, 1, "le choix du Pokémon s'est ouvert une fois")
	assert_eq(hurt.hp, 24, "+20 PV")
	assert_eq(GameState.bag.count_of(&"potion"), 2, "une Potion retirée")
	assert_push_error_count(0)
