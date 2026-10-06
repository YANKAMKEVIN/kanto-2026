extends GutTest
## BattleDirector (jalon-04.md §14.2, §14.11 T8) sur une mini-carte avec deux PNJ Pokémon, le
## vrai BattleStage et la vraie BattleHud, un GameState neuf, une graine fixe, speed_scale = 0,
## les choix du joueur simulés par les signaux de la HUD (toujours la 1re capacité).
## Vérifie : blocage du joueur dès l'appel ; un event_played par événement, dans l'ordre ; les
## PV de la carte suivent event.hp ; victoire (WIN) et défaite (LOSS) avec des graines
## choisies ; aucun message générique de début ni de fin ; équipe soignée après ; ni argent ni
## XP ; PNJ Pokémon réaffichés, caméra rendue, HUD cachée, joueur libre ; refus si un combat
## tourne ou si le dresseur est inconnu.

const FakeChoiceCards := preload("res://tests/helpers/fake_choice_cards.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const STAGE_SCENE := preload("res://game/battle/battle_stage.tscn")
const HUD_SCENE := preload("res://game/ui/battle/battle_hud.tscn")
const GAME_STATE := preload("res://game/autoload/game_state.gd")
const NPCS := "res://tests/fixtures/npcs/"
const MINE_ID := &"mine_poke"
const FOE_ID := &"foe_poke"
const PLAYER_CELL := Vector2i(11, 7)
const MINE_CELL := Vector2i(10, 7)
const FOE_CELL := Vector2i(8, 7)
## Graine du joueur : le même Pokémon à chaque essai (recherche de graine reproductible).
const PLAYER_SEED := 999
const LEVEL := 5
const STARTERS: Array[StringName] = [&"bulbasaur", &"charmander", &"squirtle"]

var _data: PokemonData
var _trainers: TrainerLibrary
var _texts: BattleText
var _items: ItemLibrary
var _stage: BattleStage
var _hud: BattleHud
var _player: Player
var _state: Node
var _director: BattleDirector
var _map: GameMap


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
	_map.add_npc(_npc_spec(MINE_ID, &"charmander", MINE_CELL, Vector2i.RIGHT))
	_map.add_npc(_npc_spec(FOE_ID, &"squirtle", FOE_CELL, Vector2i.LEFT))
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
	await wait_process_frames(2)


func _make_map() -> GameMap:
	var map := GameMap.new()
	map.name = "DirectorMap"
	map.map_id = &"battle_dir_map"
	map.npcs_dir = NPCS
	map.size = Vector2i(20, 18)
	for group: String in ["Entities", "Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		map.add_child(node)
	return map


func _npc_spec(id: StringName, sprite: StringName, cell: Vector2i, facing: Vector2i) -> NpcSpec:
	var spec := NpcSpec.new()
	spec.id = id
	spec.sprite = sprite
	spec.cell = cell
	spec.facing = facing
	return spec


## Équipe du joueur (un starter au niveau 5), toujours identique (graine PLAYER_SEED).
func _player_party(starter: StringName) -> Party:
	var party := Party.new()
	party.add(PokemonFactory.create(_data, starter, LEVEL, GameRng.new(PLAYER_SEED)))
	return party


## Prépare GameState pour un combat contre le rival : équipe du joueur, starter, graine de
## combat imposée [param battle_seed].
func _prepare(starter: StringName, battle_seed: int) -> void:
	_state.party = _player_party(starter)
	_state.starter_species = starter
	_state.rng = GameRng.new(battle_seed)


## Graine de combat qui donne [param outcome] contre le rival, avec le starter [param starter]
## et l'équipe reproductible du joueur ; reproduit exactement la consommation d'aléatoire du
## directeur (build_team puis submit(1re capacité)). −1 si aucune trouvée sous la limite.
func _seed_for(starter: StringName, outcome: int) -> int:
	var trainer := _trainers.get_trainer(&"rival_lab")
	for battle_seed: int in range(0, 800):
		var rng := GameRng.new(battle_seed)
		var foes := _trainers.build_team(&"rival_lab", starter, rng)
		var battle := Battle.new(BattleSide.new(_player_party(starter), true),
			BattleSide.new(foes, false, trainer.name, trainer.make_ai()), _data, rng)
		battle.start()
		while battle.get_state() == Battle.State.CHOOSING:
			battle.submit(BattleAction.move(0))
		if battle.get_outcome() == outcome:
			return battle_seed
	return -1


## Joue tout le combat : lance run (coroutine), pilote la HUD (ATTAQUER puis 1re capacité à
## chaque choix), collecte les événements joués. Renvoie [issue, événements, pv_aux_damage].
func _play(trainer_id: StringName = &"rival_lab") -> Array:
	var events: Array[BattleEvent] = []
	_director.event_played.connect(func(e: BattleEvent) -> void: events.append(e))
	var result: Array = [Battle.Outcome.NONE]
	var done: Array[bool] = [false]
	var world_actors: Dictionary[StringName, StringName] = {&"player": MINE_ID, &"foe": FOE_ID}
	var runner := func() -> void:
		result[0] = await _director.run(trainer_id, _map, world_actors)
		done[0] = true
	runner.call()
	# Le joueur est bloqué dès l'appel (avant tout await).
	assert_true(_player.is_blocked_by(BattleDirector.REASON), "bloqué dans l'appel même")
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
	return [result[0], events]


func after_each() -> void:
	Input.action_release(&"interact")


# --- Victoire et défaite --------------------------------------------------------------

func test_win_for_each_starter() -> void:
	for starter: StringName in STARTERS:
		await _run_outcome(starter, Battle.Outcome.WIN)


func test_loss_for_each_starter() -> void:
	for starter: StringName in STARTERS:
		await _run_outcome(starter, Battle.Outcome.LOSS)


func _run_outcome(starter: StringName, outcome: int) -> void:
	var battle_seed := _seed_for(starter, outcome)
	assert_gt(battle_seed, -1, "%s : une graine pour l'issue %d" % [starter, outcome])
	if battle_seed < 0:
		return
	_prepare(starter, battle_seed)
	var exp_before: int = (_state.party as Party).get_lead().experience
	var played: Array = await _play()
	assert_eq(played[0], outcome, "%s : issue %d" % [starter, outcome])
	var events: Array[BattleEvent] = played[1]
	# Un event_played par événement du journal, BATTLE_ENDED compris, dans l'ordre.
	assert_gt(events.size(), 4, "%s : journal joué" % starter)
	assert_eq(events[0].kind, BattleEvent.Kind.BATTLE_STARTED)
	assert_eq(events.back().kind, BattleEvent.Kind.BATTLE_ENDED)
	assert_eq(events.back().outcome, outcome)
	# Aucun message générique de début ni de fin (start_message / end_message faux).
	for event: BattleEvent in events:
		if event.kind in [BattleEvent.Kind.BATTLE_STARTED, BattleEvent.Kind.BATTLE_ENDED]:
			var lines := _texts.lines(event, _data, _trainers.get_trainer(&"rival_lab"))
			assert_eq(lines.size(), 0, "%s : pas de message générique" % starter)
	# Équipe soignée (PV et PP pleins), aucune XP, joueur libre, HUD cachée, PNJ réaffichés.
	var lead: Pokemon = (_state.party as Party).get_lead()
	assert_eq(lead.hp, lead.max_hp(), "%s : soigné (PV)" % starter)
	for slot: MoveSlot in lead.moves:
		assert_eq(slot.pp, slot.max_pp, "%s : soigné (PP)" % starter)
	assert_eq(lead.experience, exp_before, "%s : aucune XP" % starter)
	assert_false(_director.is_running())
	assert_null(_director.get_battle())
	assert_false(_hud.is_shown(), "%s : HUD cachée" % starter)
	assert_false(_stage.is_active(), "%s : scène de combat rendue" % starter)
	assert_true(_map.get_npc(MINE_ID).visible, "%s : PNJ du joueur réaffiché" % starter)
	assert_eq(_map.get_npc(MINE_ID).get_cell(), MINE_CELL)
	assert_true(_map.get_npc(FOE_ID).visible)
	assert_true(_player.is_input_enabled(), "%s : joueur libre" % starter)
	assert_eq(_player.get_camera().zoom, Vector2.ONE, "%s : caméra rendue" % starter)


# --- Cartes et PV ---------------------------------------------------------------------

func test_damage_updates_the_hp_card_to_the_event_value() -> void:
	var battle_seed := _seed_for(&"charmander", Battle.Outcome.WIN)
	_prepare(&"charmander", battle_seed)
	var seen_damage: Array[bool] = [false]
	_director.event_played.connect(func(e: BattleEvent) -> void:
		if e.kind == BattleEvent.Kind.DAMAGE:
			seen_damage[0] = true
			var side := BattleHud.Side.PLAYER if e.side == BattleEvent.SideId.PLAYER \
				else BattleHud.Side.FOE
			assert_eq(_hud.get_card(side).get_hp_bar().get_target_hp(), e.hp,
				"PV de la carte = event.hp"))
	await _play()
	assert_true(seen_damage[0], "au moins un coup encaissé")


# --- Combat sauvage (jalon 5 §3.8) ----------------------------------------------------

## Simule un combat sauvage pur (charmander N5 contre [param species] N[param level]) avec la
## graine [param seed], le joueur jouant sa 1re capacité (ou la fuite si [param flee]) : même
## consommation d'aléatoire que le directeur (BattleRequest.wild crée le sauvage, puis le moteur).
func _simulate_wild(species: StringName, level: int, seed: int, flee: bool) -> Dictionary:
	var rng := GameRng.new(seed)
	var wild_party := Party.new()
	wild_party.add(PokemonFactory.create(_data, species, level, rng))
	var player_party := _player_party(&"charmander")
	var battle := Battle.new(BattleSide.new(player_party, true),
		BattleSide.new(wild_party, false, "", null), _data, rng, BattleRules.for_wild())
	var events: Array[BattleEvent] = []
	events.append_array(battle.start())
	while battle.get_state() == Battle.State.CHOOSING:
		var action := BattleAction.run() if flee \
			else BattleAction.move(0 if not battle.get_usable_moves().is_empty() \
				else BattleAction.STRUGGLE)
		events.append_array(battle.submit(action))
	var lead := player_party.get_lead()
	return {"outcome": battle.get_outcome(), "events": events, "hp": lead.hp,
		"max": lead.max_hp()}


## Graine d'une victoire sauvage où le starter a [b]encaissé des dégâts[/b] (pour prouver
## l'absence de soin). −1 si aucune sous la limite.
func _wild_win_seed(species: StringName, level: int) -> int:
	for seed: int in range(0, 2000):
		var sim := _simulate_wild(species, level, seed, false)
		if sim["outcome"] == Battle.Outcome.WIN and int(sim["hp"]) < int(sim["max"]):
			return seed
	return -1


## Espèce/niveau/graine d'une fuite finalement réussie (FLED) après au moins un échec
## (FLEE_FAILED) : le sauvage est plus rapide (niveau élevé). Vide si rien trouvé.
func _wild_flee_fail_case() -> Dictionary:
	for level: int in [10, 12, 15, 20]:
		for seed: int in range(0, 1500):
			var sim := _simulate_wild(&"rattata", level, seed, true)
			if sim["outcome"] != Battle.Outcome.FLED:
				continue
			var failed := false
			for event: BattleEvent in sim["events"]:
				if event.kind == BattleEvent.Kind.FLEE_FAILED:
					failed = true
					break
			if failed:
				return {"level": level, "seed": seed}
	return {}


## Prépare GameState pour un combat sauvage (charmander N5) et renvoie la requête ; la création
## du sauvage consomme l'aléatoire de la graine [param seed], le moteur poursuit le même flux.
func _wild_request(species: StringName, level: int, seed: int) -> BattleRequest:
	_state.party = _player_party(&"charmander")
	_state.starter_species = &"charmander"
	_state.rng = GameRng.new(seed)
	var encounter := WildEncounter.new(species, level, &"route_1_grass")
	return BattleRequest.wild(encounter, _data, _state.rng as GameRng, Vector2i(5, 4), _items)


## Joue la requête [param request] par le directeur, en pilotant la HUD (FUITE si [param flee],
## sinon ATTAQUER puis 1re capacité). Renvoie [issue, événements joués].
func _play_request(request: BattleRequest, flee: bool) -> Array:
	var events: Array[BattleEvent] = []
	_director.event_played.connect(func(e: BattleEvent) -> void: events.append(e))
	var result: Array = [Battle.Outcome.NONE]
	var done: Array[bool] = [false]
	var runner := func() -> void:
		result[0] = await _director.run_request(request, _map)
		done[0] = true
	runner.call()
	assert_true(_player.is_blocked_by(BattleDirector.REASON), "bloqué dans l'appel même")
	var deadline := Time.get_ticks_msec() + 20000
	while not done[0] and Time.get_ticks_msec() < deadline:
		var battle := _director.get_battle()
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			match _hud.get_zone():
				BattleHud.Zone.ACTIONS:
					_hud.action_selected.emit(ActionGrid.RUN if flee else ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					_hud.move_selected.emit(0)
		await wait_process_frames(1)
	assert_true(done[0], "le combat s'est terminé")
	return [result[0], events]


func test_wild_victory_plays_every_event_and_never_heals() -> void:
	var seed := _wild_win_seed(&"rattata", 3)
	assert_gt(seed, -1, "une graine de victoire sauvage avec dégâts")
	if seed < 0:
		return
	var sim := _simulate_wild(&"rattata", 3, seed, false)
	var request := _wild_request(&"rattata", 3, seed)
	var played: Array = await _play_request(request, false)
	assert_eq(played[0], Battle.Outcome.WIN, "victoire sauvage")
	var events: Array[BattleEvent] = played[1]
	# Chaque événement du journal joué une fois, dans l'ordre (même nombre qu'à la simulation).
	assert_eq(events.size(), (sim["events"] as Array).size(), "un event_played par événement")
	assert_eq(events[0].kind, BattleEvent.Kind.BATTLE_STARTED)
	assert_eq(events.back().kind, BattleEvent.Kind.BATTLE_ENDED)
	assert_eq(events.back().outcome, Battle.Outcome.WIN)
	# Le sauvage « apparaît » : SENT_OUT côté FOE sans dresseur → « Un Rattata sauvage apparaît ! ».
	var saw_wild_appear := false
	for event: BattleEvent in events:
		if event.kind == BattleEvent.Kind.SENT_OUT and event.side == BattleEvent.SideId.FOE:
			saw_wild_appear = _texts.lines(event, _data, null).size() == 1
	assert_true(saw_wild_appear, "une phrase d'apparition du sauvage")
	# PV non soignés : l'état du starter est exactement celui de la fin du combat.
	var lead: Pokemon = (_state.party as Party).get_lead()
	assert_eq(lead.hp, int(sim["hp"]), "PV = fin du combat (aucun soin sauvage)")
	assert_lt(lead.hp, lead.max_hp(), "le starter a gardé ses dégâts")
	assert_false(_director.is_running())
	assert_null(_director.get_battle())
	assert_false(_hud.is_shown(), "HUD cachée")
	assert_false(_stage.is_active(), "scène de combat rendue")
	assert_true(_player.is_input_enabled(), "joueur libre")


func test_wild_flee_fails_then_succeeds_and_the_foe_acts() -> void:
	var found := _wild_flee_fail_case()
	assert_false(found.is_empty(), "une graine : fuite ratée puis réussie")
	if found.is_empty():
		return
	var request := _wild_request(&"rattata", found["level"], found["seed"])
	var played: Array = await _play_request(request, true)
	assert_eq(played[0], Battle.Outcome.FLED, "fuite finalement réussie")
	var events: Array[BattleEvent] = played[1]
	var saw_failed := false
	var saw_fled := false
	var foe_acted_after_fail := false
	for i: int in events.size():
		match events[i].kind:
			BattleEvent.Kind.FLEE_FAILED:
				saw_failed = true
				for j: int in range(i + 1, events.size()):
					if events[j].kind == BattleEvent.Kind.FLED:
						break
					if events[j].kind == BattleEvent.Kind.MOVE_USED \
							and events[j].side == BattleEvent.SideId.FOE:
						foe_acted_after_fail = true
						break
			BattleEvent.Kind.FLED:
				saw_fled = true
	assert_true(saw_failed, "au moins une fuite ratée")
	assert_true(saw_fled, "la fuite finit par réussir")
	assert_true(foe_acted_after_fail, "l'adversaire joue après un échec de fuite")
	assert_false(_director.is_running())
	assert_true(_player.is_input_enabled(), "joueur libre après la fuite")


func test_run_request_with_an_empty_foe_party_is_refused() -> void:
	_state.party = _player_party(&"charmander")
	_state.starter_species = &"charmander"
	_state.rng = GameRng.new(1)
	var request := BattleRequest.new()
	request.intro = BattleRequest.Intro.WILD
	request.foe_party = Party.new()
	request.rules = BattleRules.for_wild()
	var outcome: int = await _director.run_request(request, _map)
	assert_eq(outcome, Battle.Outcome.NONE)
	assert_push_error("équipe adverse vide")
	assert_false(_director.is_running())
	assert_true(_player.is_input_enabled())


# --- Refus ----------------------------------------------------------------------------

func test_run_while_a_battle_is_running_is_refused() -> void:
	_prepare(&"charmander", _seed_for(&"charmander", Battle.Outcome.WIN))
	var actors: Dictionary[StringName, StringName] = {&"player": MINE_ID, &"foe": FOE_ID}
	var runner := func() -> void: await _director.run(&"rival_lab", _map, actors)
	runner.call()
	await wait_process_frames(1)
	assert_true(_director.is_running())
	var second: int = await _director.run(&"rival_lab", _map, actors)
	assert_eq(second, Battle.Outcome.NONE, "second combat refusé")
	assert_push_error("un combat tourne déjà")
	# Termine le premier combat proprement.
	var deadline := Time.get_ticks_msec() + 20000
	while _director.is_running() and Time.get_ticks_msec() < deadline:
		match _hud.get_zone():
			BattleHud.Zone.ACTIONS:
				_hud.action_selected.emit(ActionGrid.ATTACK)
			BattleHud.Zone.MOVES:
				_hud.move_selected.emit(0)
		await wait_process_frames(1)


# --- Rival n° 2 : argent et SAC (jalon 7, T24) -----------------------------------------

## Victoire contre le rival de la Route 22 : « Tu remportes 280 ₽. » (35 × Nv. 8 du dernier
## Pokémon) puis l'argent versé ; SAC actif dans la grille ; pas de soin.
func test_route22_victory_pays_the_prize_and_offers_the_bag() -> void:
	var party := Party.new()
	var strong := PokemonFactory.create(_data, &"charmander", 40, GameRng.new(PLAYER_SEED))
	strong.moves.clear()
	strong.moves.append(MoveSlot.new(&"ember", 25))
	party.add(strong)
	_state.party = party
	_state.starter_species = &"bulbasaur"
	_state.rng = GameRng.new(5)
	_state.money = 3000
	var bag_seen: Array[bool] = []
	_hud.get_action_grid().visibility_changed.connect(func() -> void:
		bag_seen.append(_hud.get_action_grid().is_action_enabled(ActionGrid.BAG)))
	var played: Array = await _play(&"rival_route22")
	assert_eq(played[0], Battle.Outcome.WIN)
	assert_eq(_state.money, 3280, "3 000 + 35 × 8")
	assert_eq(_hud.get_message_banner().get_text(), "Tu remportes %s." % MenuFormat.money(280))
	assert_true(_hud.get_action_grid().is_action_enabled(ActionGrid.BAG), "SAC actif")
	assert_false(_hud.get_action_grid().is_action_enabled(ActionGrid.RUN), "FUITE atténuée")


## Défaite : aucun argent gagné, aucun perdu (dossier 09 §10).
func test_route22_defeat_keeps_the_money() -> void:
	var party := Party.new()
	party.add(PokemonFactory.create(_data, &"bulbasaur", 2, GameRng.new(PLAYER_SEED)))
	_state.party = party
	_state.starter_species = &"bulbasaur"
	_state.rng = GameRng.new(5)
	_state.money = 3000
	var played: Array = await _play(&"rival_route22")
	assert_eq(played[0], Battle.Outcome.LOSS)
	assert_eq(_state.money, 3000)
	assert_ne(_hud.get_message_banner().get_text(), "Tu remportes %s." % MenuFormat.money(280))


## Le labo garde le SAC muet (décision n° 12), même avec des Potions.
func test_rival_lab_keeps_the_bag_silent() -> void:
	_prepare(&"charmander", 1)
	_state.bag.add(&"potion", 2)
	await _play()
	assert_false(_hud.get_action_grid().is_action_enabled(ActionGrid.BAG))


func test_unknown_trainer_is_refused_and_the_player_stays_free() -> void:
	_prepare(&"charmander", 1)
	var actors: Dictionary[StringName, StringName] = {}
	var outcome: int = await _director.run(&"nobody", _map, actors)
	assert_eq(outcome, Battle.Outcome.NONE)
	assert_push_error("dresseur inconnu")
	assert_false(_director.is_running())
	assert_true(_player.is_input_enabled(), "joueur libre")


func test_empty_party_is_refused() -> void:
	_state.party = Party.new()
	_state.starter_species = &"charmander"
	_state.rng = GameRng.new(1)
	var actors: Dictionary[StringName, StringName] = {}
	var outcome: int = await _director.run(&"rival_lab", _map, actors)
	assert_eq(outcome, Battle.Outcome.NONE)
	assert_push_error("aucun Pokémon valide")


# --- XP, niveaux, apprentissage et oubli (jalon 5C, T11) --------------------------------

## Équipe d'un seul Pokémon : [param species] au niveau [param level] ; [param to_next] XP avant
## le niveau suivant (0 = XP du niveau) ; [param moves] remplace ses capacités si non vide.
func _xp_party(species: StringName, level: int, to_next: int,
		moves: Array[StringName] = []) -> Party:
	var pokemon := PokemonFactory.create(_data, species, level, GameRng.new(PLAYER_SEED))
	if not moves.is_empty():
		pokemon.moves.clear()
		for move_id: StringName in moves:
			pokemon.learn_move(move_id, _data)
	if to_next > 0:
		var rate := _data.get_species(species).growth_rate
		pokemon.experience = ExpCurve.exp_for_level(rate, level + 1) - to_next
	var party := Party.new()
	party.add(pokemon)
	return party


## Graine d'une victoire sauvage (le joueur joue les capacités de [param order] dans l'ordre, la
## dernière ensuite) avec une équipe neuve de [param party_fn] ; [param wanted] : prédicat sur
## le journal (Array d'événements) à satisfaire. −1 si aucune sous la limite.
func _xp_seed(party_fn: Callable, species: StringName, level: int, order: Array[int],
		wanted: Callable) -> int:
	for seed: int in range(0, 600):
		var rng := GameRng.new(seed)
		var foes := Party.new()
		foes.add(PokemonFactory.create(_data, species, level, rng))
		var battle := Battle.new(BattleSide.new(party_fn.call(), true),
			BattleSide.new(foes, false, "", null), _data, rng, BattleRules.for_wild())
		var events: Array[BattleEvent] = []
		events.append_array(battle.start())
		var turn := 0
		while battle.get_state() == Battle.State.CHOOSING and turn < 60:
			var index := order[mini(turn, order.size() - 1)]
			events.append_array(battle.submit(BattleAction.move(index)))
			turn += 1
		if battle.get_outcome() == Battle.Outcome.WIN and bool(wanted.call(events)):
			return seed
	return -1


## Prépare GameState pour un combat sauvage contre [param species] N[param level] avec
## [param party] ; la graine [param seed] est celle de la simulation d'_xp_seed.
func _xp_request(party: Party, species: StringName, level: int, seed: int) -> BattleRequest:
	_state.party = party
	_state.starter_species = party.get_lead().species_id
	_state.rng = GameRng.new(seed)
	var encounter := WildEncounter.new(species, level, &"route_1_grass")
	return BattleRequest.wild(encounter, _data, _state.rng as GameRng, Vector2i(5, 4))


## Joue [param request] ; les capacités jouées suivent [param order] (la dernière ensuite).
## À chaque offre d'oubli, [param on_offer] (reçoit le panneau ouvert et le journal joué) est
## appelé une fois, en coroutine : c'est lui qui répond. Renvoie [issue, événements joués].
func _play_with_offers(request: BattleRequest, order: Array[int],
		on_offer: Callable = Callable()) -> Array:
	var events: Array[BattleEvent] = []
	_director.event_played.connect(func(e: BattleEvent) -> void: events.append(e))
	var result: Array = [Battle.Outcome.NONE]
	var done: Array[bool] = [false]
	var runner := func() -> void:
		result[0] = await _director.run_request(request, _map)
		done[0] = true
	runner.call()
	var turn := 0
	var deadline := Time.get_ticks_msec() + 20000
	while not done[0] and Time.get_ticks_msec() < deadline:
		var panel := _director.get_forget_panel()
		if panel != null and panel.is_shown() and not panel.is_answered() \
				and on_offer.is_valid():
			await on_offer.call(panel, events)
		var battle := _director.get_battle()
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			match _hud.get_zone():
				BattleHud.Zone.ACTIONS:
					_hud.action_selected.emit(ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					_hud.move_selected.emit(order[mini(turn, order.size() - 1)])
					turn += 1
		await wait_process_frames(1)
	assert_true(done[0], "le combat s'est terminé")
	return [result[0], events]


## La carte du joueur porte le niveau et les PV de [param e] (LEVEL_UP rejoué).
func _check_card_level(e: BattleEvent) -> void:
	var card := _hud.get_card(BattleHud.Side.PLAYER)
	assert_eq(card.get_level_text(), "Nv. %d" % e.level, "Nv. de la carte à jour")
	assert_eq(card.get_hp_bar().get_target_hp(), e.hp, "PV de la carte à jour")
	assert_eq(card.get_hp_bar().get_max_hp(), e.max_hp, "PV max de la carte")


## Ponction de Vampigraine rejouée : la cible a perdu, celui d'en face a gagné.
func _check_drain_bars(e: BattleEvent) -> void:
	var victim := BattleHud.Side.PLAYER if e.side == BattleEvent.SideId.PLAYER \
		else BattleHud.Side.FOE
	var other := BattleHud.Side.FOE if victim == BattleHud.Side.PLAYER \
		else BattleHud.Side.PLAYER
	assert_eq(_hud.get_card(victim).get_hp_bar().get_target_hp(), e.hp, "la cible perd")
	assert_eq(_hud.get_card(other).get_hp_bar().get_target_hp(), e.healed_hp, "le lanceur gagne")


func _has_kind(events: Array, kind: BattleEvent.Kind) -> bool:
	return events.any(func(e: BattleEvent) -> bool: return e.kind == kind)


## L'XP du Pokémon augmente exactement de la somme des gains du journal, et c'est ce que montre
## le bilan de fin de combat (demande n° 1) : une ligne, « +N XP », « Nv. 6 », la barre et les
## nombres finissent à la bonne valeur. Pendant le combat, plus de « +N XP » sur la carte ni de
## « monte au niveau » ; la carte prend en silence le niveau et les PV max. Ordre du journal
## respecté.
func test_xp_gained_equals_the_sum_shown_and_the_card_follows_the_level() -> void:
	var party_fn := func() -> Party: return _xp_party(&"charmander", 5, 1)
	var seed := _xp_seed(party_fn, &"rattata", 3, [0] as Array[int],
		func(events: Array) -> bool: return _has_kind(events, BattleEvent.Kind.LEVEL_UP))
	assert_gt(seed, -1, "une victoire avec montée de niveau")
	if seed < 0:
		return
	var party: Party = party_fn.call()
	var lead := party.get_lead()
	var before := lead.experience
	var request := _xp_request(party, &"rattata", 3, seed)
	var gain_shown: Array[bool] = []
	var levels: Array[int] = []
	var banner: Array[String] = []
	_director.event_played.connect(func(e: BattleEvent) -> void:
		banner.append(_hud.get_message_banner().get_text())
		if e.kind == BattleEvent.Kind.EXP_GAINED and e.amount > 0:
			gain_shown.append(_hud.get_card(BattleHud.Side.PLAYER).is_exp_gain_visible())
		elif e.kind == BattleEvent.Kind.LEVEL_UP:
			levels.append(e.level)
			_check_card_level(e))
	var seen: Dictionary = {}
	_director.exp_summary_shown.connect(func(summary: ExpSummary) -> void:
		var card := _director.get_summary_card()
		seen["entries"] = summary.get_entries().size()
		seen["shown"] = card != null and card.is_visible_in_tree() and card.is_filled()
		var row := card.get_rows()[0]
		seen["gain"] = row.get_gain_text()
		seen["level"] = row.get_level_text()
		seen["start"] = row.get_start_level_text()
		seen["fraction"] = row.get_bar().get_fraction()
		seen["points"] = row.get_points_text()
		seen["lit"] = row.is_lit()
		seen["stats"] = row.get_stats_text()
		seen["hud_hidden"] = not _hud.is_shown())
	var played := await _play_with_offers(request, [0] as Array[int])
	assert_eq(played[0], Battle.Outcome.WIN)
	var events: Array[BattleEvent] = played[1]
	var total := 0
	var kinds: Array[BattleEvent.Kind] = []
	for event: BattleEvent in events:
		kinds.append(event.kind)
		if event.kind == BattleEvent.Kind.EXP_GAINED:
			total += event.amount
	assert_gt(total, 0, "de l'XP a été gagnée")
	assert_eq(lead.experience - before, total, "XP du Pokémon = somme des gains joués")
	assert_eq(gain_shown, [false] as Array[bool], "plus de « +N XP » sur la carte en combat")
	assert_eq(levels, [6] as Array[int], "montée au niveau 6")
	assert_eq(lead.level, 6)
	for line: String in banner:
		assert_false(line.contains("monte au niveau"), "plus de phrase de niveau : " + line)
	var span := ExpCalc.level_span(lead, _data)
	assert_eq(seen.get("entries"), 1, "un Pokémon dans le bilan")
	assert_true(seen.get("shown", false), "bilan affiché, barres arrivées")
	assert_true(seen.get("hud_hidden", false), "cartes et bandeau sortis pendant le bilan")
	assert_eq(seen.get("gain"), "+%d XP" % total, "le bilan montre le total gagné")
	assert_eq([seen.get("start"), seen.get("level")], ["Nv. 5", "Nv. 6"])
	assert_almost_eq(float(seen.get("fraction", -1.0)), ExpCalc.progress(lead, _data), 0.0001,
		"la barre finit à la bonne valeur")
	assert_eq(seen.get("points"), "%d / %d" % [span.x, span.y], "nombres du nouveau niveau")
	assert_true(seen.get("lit", false), "sa ligne est mise en valeur")
	assert_true(String(seen.get("stats", "")).begins_with("PV +"), "gains de statistiques")
	assert_null(_director.get_summary_card(), "bilan libéré à la fin")
	# Ordre du journal : K.O. adverse, puis XP, puis niveau, puis la fin du combat.
	assert_lt(kinds.rfind(BattleEvent.Kind.FAINTED), kinds.find(BattleEvent.Kind.EXP_GAINED),
		"XP après le K.O.")
	assert_lt(kinds.find(BattleEvent.Kind.EXP_GAINED), kinds.find(BattleEvent.Kind.LEVEL_UP))
	assert_lt(kinds.find(BattleEvent.Kind.LEVEL_UP), kinds.find(BattleEvent.Kind.BATTLE_ENDED))
	assert_false(_hud.is_shown(), "HUD cachée à la fin")
	assert_push_error_count(0)


## Capacité apprise dans un emplacement libre : la phrase « apprend » est jouée (bandeau) et le
## panneau d'oubli ne s'ouvre pas.
func test_a_learned_move_is_announced_without_the_forget_panel() -> void:
	var party_fn := func() -> Party: return _xp_party(&"bulbasaur", 6, 5)
	var seed := _xp_seed(party_fn, &"rattata", 3, [0] as Array[int],
		func(events: Array) -> bool: return _has_kind(events, BattleEvent.Kind.MOVE_LEARNED))
	assert_gt(seed, -1, "une victoire qui apprend une capacité")
	if seed < 0:
		return
	var party: Party = party_fn.call()
	var request := _xp_request(party, &"rattata", 3, seed)
	var lines: Array[String] = []
	var order: Array[String] = []
	_director.event_played.connect(func(e: BattleEvent) -> void:
		if e.kind in [BattleEvent.Kind.MOVE_LEARNED, BattleEvent.Kind.BATTLE_ENDED]:
			order.append(BattleEvent.Kind.find_key(e.kind))
		if e.kind == BattleEvent.Kind.MOVE_LEARNED:
			lines.append(_hud.get_message_banner().get_text()))
	_director.exp_summary_shown.connect(func(_s: ExpSummary) -> void: order.append("SUMMARY"))
	var played := await _play_with_offers(request, [0] as Array[int])
	assert_eq(played[0], Battle.Outcome.WIN)
	assert_eq(order, ["BATTLE_ENDED", "SUMMARY", "MOVE_LEARNED"] as Array[String],
		"fin du combat, bilan, puis l'apprentissage")
	assert_true(party.get_lead().knows_move(&"leech_seed"), "Vampigraine apprise au N7")
	assert_eq(lines, ["Bulbizarre apprend Vampigraine !"] as Array[String],
		"phrase d'apprentissage")
	assert_null(_director.get_forget_panel(), "aucun panneau d'oubli")
	assert_push_error_count(0)


## 4 capacités connues : la lecture du journal est suspendue, le bandeau est sorti, le panneau
## montre la nouvelle capacité et les quatre connues ; rien ne se décide sans le geste du
## joueur (une sélection seule ne ferme rien) ; OUBLIER remplace la capacité (PP pleins).
func test_forget_offer_suspends_the_journal_and_forgetting_replaces_the_move() -> void:
	var moves: Array[StringName] = [&"tackle", &"growl", &"leech_seed", &"vine_whip"]
	var party_fn := func() -> Party: return _xp_party(&"bulbasaur", 19, 1, moves)
	var seed := _xp_seed(party_fn, &"rattata", 3, [0] as Array[int],
		func(events: Array) -> bool:
			return _has_kind(events, BattleEvent.Kind.MOVE_FORGET_OFFERED))
	assert_gt(seed, -1, "une victoire qui propose une cinquième capacité")
	if seed < 0:
		return
	var party: Party = party_fn.call()
	var lead := party.get_lead()
	var request := _xp_request(party, &"rattata", 3, seed)
	var seen: Dictionary = {}
	var offers: Array[int] = []
	var line: Array[String] = []
	_director.event_played.connect(func(e: BattleEvent) -> void:
		if e.kind == BattleEvent.Kind.MOVE_FORGET_OFFERED:
			line.append(_hud.get_message_banner().get_text()))
	var on_offer := func(panel: MoveForgetPanel, events: Array) -> void:
		offers.append(1)
		var played_before := events.size()
		await wait_process_frames(6)
		seen["suspended"] = events.size() == played_before and _director.is_running() \
			and panel.is_shown() and panel.is_visible_in_tree()
		seen["banner_out"] = not _hud.get_message_banner().is_shown()
		seen["new_card"] = panel.get_new_card().get_view().display_name
		var known: Array[String] = []
		for slot: int in MoveForgetPanel.SLOTS:
			known.append(panel.get_card(slot).get_view().display_name)
		seen["known"] = known
		# Une sélection seule ne décide rien : le panneau attend toujours.
		panel.select(2)
		await wait_process_frames(6)
		seen["waits_after_select"] = not panel.is_answered() \
			and events.size() == played_before and not lead.knows_move(&"poison_powder")
		panel.get_confirm_button().pressed.emit()
	var played := await _play_with_offers(request, [0] as Array[int], on_offer)
	assert_eq(played[0], Battle.Outcome.WIN)
	assert_eq(offers.size(), 1, "une seule offre")
	assert_true(seen["suspended"], "journal suspendu, panneau ouvert")
	assert_true(seen["banner_out"], "le bandeau est sorti avant le panneau")
	assert_eq(seen["new_card"], _data.get_move(&"poison_powder").name,
		"nouvelle capacité")
	assert_eq(seen["known"].size(), 4, "les quatre capacités connues")
	assert_true(seen["waits_after_select"], "une sélection ne ferme pas l'offre")
	assert_eq(lead.moves[2].move_id, &"poison_powder", "la capacité sélectionnée est remplacée")
	assert_eq(lead.moves[2].pp, lead.moves[2].max_pp, "PP pleins")
	assert_eq(lead.moves[2].max_pp, _data.get_move(&"poison_powder").pp)
	for slot: int in [0, 1, 3]:
		assert_eq(lead.moves[slot].move_id, moves[slot], "emplacement %d inchangé" % slot)
	assert_eq(line, ["Bulbizarre oublie Vampigraine et apprend Poudre Toxik !"] as Array[String],
		"phrase de l'oubli")
	assert_null(_director.get_forget_panel(), "panneau libéré à la fin du combat")
	assert_push_error_count(0)


## NE PAS APPRENDRE : les capacités ne changent pas, la phrase « n'apprend pas » est jouée.
func test_forget_offer_refused_keeps_the_moves() -> void:
	var moves: Array[StringName] = [&"tackle", &"growl", &"leech_seed", &"vine_whip"]
	var party_fn := func() -> Party: return _xp_party(&"bulbasaur", 19, 1, moves)
	var seed := _xp_seed(party_fn, &"rattata", 3, [0] as Array[int],
		func(events: Array) -> bool:
			return _has_kind(events, BattleEvent.Kind.MOVE_FORGET_OFFERED))
	assert_gt(seed, -1, "une victoire qui propose une cinquième capacité")
	if seed < 0:
		return
	var party: Party = party_fn.call()
	var lead := party.get_lead()
	var request := _xp_request(party, &"rattata", 3, seed)
	var after: Array[String] = []
	_director.event_played.connect(func(e: BattleEvent) -> void:
		if e.kind == BattleEvent.Kind.MOVE_FORGET_OFFERED:
			after.append(_hud.get_message_banner().get_text()))
	var on_offer := func(panel: MoveForgetPanel, _events: Array) -> void:
		await wait_process_frames(2)
		panel.get_skip_button().pressed.emit()
	var played := await _play_with_offers(request, [0] as Array[int], on_offer)
	assert_eq(played[0], Battle.Outcome.WIN)
	var known: Array[StringName] = []
	for slot: MoveSlot in lead.moves:
		known.append(slot.move_id)
	assert_eq(known, moves, "capacités inchangées")
	assert_false(lead.knows_move(&"poison_powder"))
	assert_eq(after, ["Bulbizarre n'apprend pas Poudre Toxik."] as Array[String],
		"phrase du refus")
	assert_push_error_count(0)


## « Confirmer certaines actions » (T29) : OUBLIER passe par une question à deux cartes ;
## GARDER ramène au panneau, OUBLIER confirme.
func test_forget_confirmation_asks_before_forgetting() -> void:
	var moves: Array[StringName] = [&"tackle", &"growl", &"leech_seed", &"vine_whip"]
	var party_fn := func() -> Party: return _xp_party(&"bulbasaur", 19, 1, moves)
	var seed := _xp_seed(party_fn, &"rattata", 3, [0] as Array[int],
		func(events: Array) -> bool:
			return _has_kind(events, BattleEvent.Kind.MOVE_FORGET_OFFERED))
	assert_gt(seed, -1, "une victoire qui propose une cinquième capacité")
	if seed < 0:
		return
	var party: Party = party_fn.call()
	var lead := party.get_lead()
	var request := _xp_request(party, &"rattata", 3, seed)
	FakeChoiceCards.views.clear()
	FakeChoiceCards.answers = [false, true] as Array[bool]
	_director.confirm_forget = true
	_director.choice_cards_script = FakeChoiceCards
	var offers: Array[int] = []
	var on_offer := func(panel: MoveForgetPanel, _events: Array) -> void:
		offers.append(1)
		await wait_process_frames(2)
		panel.select(2)
		panel.get_confirm_button().pressed.emit()
	var played := await _play_with_offers(request, [0] as Array[int], on_offer)
	assert_eq(played[0], Battle.Outcome.WIN)
	assert_eq(FakeChoiceCards.views.size(), 2, "deux questions : GARDER puis OUBLIER")
	assert_eq(FakeChoiceCards.views[0].title, "Oublier Vampigraine ?")
	assert_eq(FakeChoiceCards.views[0].confirm_label, "OUBLIER")
	assert_eq(FakeChoiceCards.views[0].cancel_label, "GARDER")
	assert_eq(offers.size(), 2, "GARDER rend la main au panneau")
	assert_eq(lead.moves[2].move_id, &"poison_powder", "la seconde réponse a confirmé")
	assert_push_error_count(0)


## Même question avec le vrai composant `ChoiceCards` : texte à l'écran, GARDER puis OUBLIER.
func test_forget_confirmation_with_the_real_choice_cards() -> void:
	var moves: Array[StringName] = [&"tackle", &"growl", &"leech_seed", &"vine_whip"]
	var party_fn := func() -> Party: return _xp_party(&"bulbasaur", 19, 1, moves)
	var seed := _xp_seed(party_fn, &"rattata", 3, [0] as Array[int],
		func(events: Array) -> bool:
			return _has_kind(events, BattleEvent.Kind.MOVE_FORGET_OFFERED))
	if seed < 0:
		fail_test("aucune graine avec offre d'oubli")
		return
	var party: Party = party_fn.call()
	var lead := party.get_lead()
	var request := _xp_request(party, &"rattata", 3, seed)
	_director.confirm_forget = true
	var asked: Array[String] = []
	var on_offer := func(panel: MoveForgetPanel, _events: Array) -> void:
		await wait_process_frames(2)
		panel.select(2)
		panel.get_confirm_button().pressed.emit()
		var cards: ChoiceCards = null
		for i: int in 120:
			await wait_process_frames(1)
			for child: Node in _hud.get_screen().get_children():
				if child is ChoiceCards and (child as ChoiceCards).is_showing():
					cards = child
			if cards != null:
				break
		assert_not_null(cards, "la question est affichée")
		if cards == null:
			return
		asked.append(cards.get_title_label().text)
		if asked.size() == 1:
			cards.get_cancel_button().pressed.emit()
		else:
			cards.get_confirm_button().pressed.emit()
	var played := await _play_with_offers(request, [0] as Array[int], on_offer)
	assert_eq(played[0], Battle.Outcome.WIN)
	assert_eq(asked.size(), 2)
	assert_eq(asked[0], "Oublier Vampigraine ?")
	assert_eq(lead.moves[2].move_id, &"poison_powder", "OUBLIER a remplacé la capacité")


## Équipe de deux Bulbizarre identiques (même espèce, même nom) : le premier est K.O. avec
## [param first_moves], le second tient debout, à 1 XP du N20, avec [param second_moves].
func _twin_party(first_moves: Array[StringName], second_moves: Array[StringName]) -> Party:
	var party := _xp_party(&"bulbasaur", 19, 0, first_moves)
	var second := _xp_party(&"bulbasaur", 19, 1, second_moves).get_lead()
	party.get_lead().hp = 0
	party.add(second)
	return party


func _move_ids(pokemon: Pokemon) -> Array[StringName]:
	var ids: Array[StringName] = []
	for slot: MoveSlot in pokemon.moves:
		ids.append(slot.move_id)
	return ids


## Deux Pokémon de la même espèce dans l'équipe : l'offre d'oubli concerne celui qui apprend
## (retrouvé par sa place dans l'équipe, jamais par espèce et nom).
func test_forget_offer_targets_the_right_pokemon_among_identical_ones() -> void:
	var first_moves: Array[StringName] = [&"tackle", &"growl", &"vine_whip", &"leech_seed"]
	var second_moves: Array[StringName] = [&"tackle", &"growl", &"leech_seed", &"vine_whip"]
	var party_fn := func() -> Party: return _twin_party(first_moves, second_moves)
	var seed := _xp_seed(party_fn, &"rattata", 3, [0] as Array[int],
		func(events: Array) -> bool:
			return _has_kind(events, BattleEvent.Kind.MOVE_FORGET_OFFERED))
	assert_gt(seed, -1, "une victoire qui propose une cinquième capacité")
	if seed < 0:
		return
	var party: Party = party_fn.call()
	var request := _xp_request(party, &"rattata", 3, seed)
	var seen: Dictionary = {}
	var on_offer := func(panel: MoveForgetPanel, _events: Array) -> void:
		var known: Array[String] = []
		for slot: int in MoveForgetPanel.SLOTS:
			known.append(panel.get_card(slot).get_view().display_name)
		seen["known"] = known
		await wait_process_frames(2)
		panel.select(2)
		await wait_process_frames(2)
		panel.get_confirm_button().pressed.emit()
	var played := await _play_with_offers(request, [0] as Array[int], on_offer)
	assert_eq(played[0], Battle.Outcome.WIN)
	var offers: Array = played[1].filter(func(e: BattleEvent) -> bool:
		return e.kind == BattleEvent.Kind.MOVE_FORGET_OFFERED)
	assert_eq(offers.size(), 1)
	assert_eq(offers[0].party_index, 1, "l'offre porte la place du second Bulbizarre")
	var second_names: Array[String] = []
	for move_id: StringName in second_moves:
		second_names.append(_data.get_move(move_id).name)
	assert_eq(seen.get("known"), second_names, "le panneau montre les capacités du second")
	assert_eq(party.get_at(1).moves[2].move_id, &"poison_powder", "le second oublie et apprend")
	assert_eq(_move_ids(party.get_at(0)), first_moves, "le premier n'a pas changé")
	assert_push_error_count(0)


## La recherche du Pokémon d'un événement se fait par la place dans l'équipe : deux Pokémon
## identiques ne se confondent jamais, quelle que soit leur position.
func test_the_event_party_index_finds_the_exact_pokemon() -> void:
	var moves: Array[StringName] = [&"tackle", &"growl", &"leech_seed", &"vine_whip"]
	_state.party = _twin_party(moves, moves)
	var first: Pokemon = (_state.party as Party).get_at(0)
	var second: Pokemon = (_state.party as Party).get_at(1)
	var event := BattleEvent.new(BattleEvent.Kind.MOVE_FORGET_OFFERED, BattleEvent.SideId.PLAYER)
	event.species_id = &"bulbasaur"
	event.pokemon_name = second.display_name(_data)
	event.party_index = 1
	assert_same(_director._find_player_pokemon(event), second)
	event.party_index = 0
	assert_same(_director._find_player_pokemon(event), first)
	event.party_index = 5
	assert_null(_director._find_player_pokemon(event), "place absente : rien")
	event.party_index = -1
	assert_null(_director._find_player_pokemon(event))


## Premier Pokémon de l'équipe K.O. : l'entrée en scène, le sprite et la carte du joueur sont
## ceux du Pokémon que le moteur envoie (le premier debout), pas ceux de la tête d'équipe.
func test_a_fainted_lead_is_not_the_pokemon_shown() -> void:
	var party := _xp_party(&"charmander", 5, 0)
	party.get_lead().hp = 0
	party.add(PokemonFactory.create(_data, &"bulbasaur", 12, GameRng.new(PLAYER_SEED)))
	var request := _xp_request(party, &"rattata", 3, 5)
	var at_start: Array[String] = []
	var cards: Array[String] = []
	_director.event_played.connect(func(e: BattleEvent) -> void:
		if e.kind == BattleEvent.Kind.BATTLE_STARTED:
			# Après l'entrée en scène, avant les SENT_OUT : le sprite est déjà le bon.
			var texture := _stage.get_sprite(BattleEvent.SideId.PLAYER).texture
			at_start.append(texture.resource_path if texture != null else "")
		elif e.kind == BattleEvent.Kind.SENT_OUT and e.side == BattleEvent.SideId.PLAYER:
			var card := _hud.get_card(BattleHud.Side.PLAYER)
			cards.append("%s|%s|%s" % [card.get_name_text(), card.get_level_text(),
				card.get_hp_text()])
			assert_eq(e.party_index, 1, "SENT_OUT : le moteur envoie le second"))
	await _play_with_offers(request, [0] as Array[int])
	assert_eq(at_start, [BattleStage.sprite_path(&"bulbasaur", true)] as Array[String],
		"entrée en scène : le sprite de Bulbizarre, pas celui de Salamèche K.O.")
	assert_eq(cards.size(), 1, "un seul envoi du joueur")
	assert_true(cards[0].begins_with("BULBIZARRE|Nv. 12|"), "carte : %s" % cards[0])
	assert_push_error_count(0)


## Vampigraine : le Pokémon drainé perd des PV et celui d'en face en regagne, les deux barres
## suivent l'événement (la cible perd, le lanceur gagne).
func test_leech_seed_drives_both_hp_bars() -> void:
	var moves: Array[StringName] = [&"leech_seed", &"tackle"]
	var party_fn := func() -> Party: return _xp_party(&"bulbasaur", 8, 0, moves)
	var seed := _xp_seed(party_fn, &"rattata", 4, [0, 1] as Array[int],
		func(events: Array) -> bool:
			return events.any(func(e: BattleEvent) -> bool:
				return e.kind == BattleEvent.Kind.DRAINED and e.healed > 0))
	assert_gt(seed, -1, "un combat où Vampigraine rend des PV")
	if seed < 0:
		return
	var request := _xp_request(party_fn.call(), &"rattata", 4, seed)
	var checked: Array[int] = []
	var seeded: Array[String] = []
	_director.event_played.connect(func(e: BattleEvent) -> void:
		if e.kind == BattleEvent.Kind.SEEDED:
			seeded.append(_hud.get_message_banner().get_text())
		elif e.kind == BattleEvent.Kind.DRAINED:
			_check_drain_bars(e)
			checked.append(1))
	var played := await _play_with_offers(request, [0, 1] as Array[int])
	assert_eq(played[0], Battle.Outcome.WIN)
	assert_gt(checked.size(), 0, "au moins une ponction jouée sur les deux barres")
	assert_gt(seeded.size(), 0, "la graine est annoncée")
	assert_eq(seeded[0], "Une graine est plantée sur Rattata !")
	assert_push_error_count(0)


## Combat de dresseur sans XP (rival du 4B) : aucun événement d'XP, XP intacte.
func test_the_rival_battle_still_gives_no_xp() -> void:
	var battle_seed := _seed_for(&"charmander", Battle.Outcome.WIN)
	_prepare(&"charmander", battle_seed)
	var kinds: Array[BattleEvent.Kind] = []
	_director.event_played.connect(func(e: BattleEvent) -> void: kinds.append(e.kind))
	var before := (_state.party as Party).get_lead().experience
	await _play()
	assert_false(kinds.has(BattleEvent.Kind.EXP_GAINED), "aucune XP")
	assert_false(kinds.has(BattleEvent.Kind.LEVEL_UP))
	assert_eq((_state.party as Party).get_lead().experience, before)


# --- Capture (jalon 5D, T15) ------------------------------------------------------------
# Le joueur ouvre le SAC, touche LANCER (ou « ‹ »), le directeur retire la Ball du Sac, le moteur
# joue le lancer, le Pokémon rejoint l'équipe (ou le stockage) et la carte de capture attend un
# toucher. Les graines sont cherchées par simulation du même flux d'aléatoire.

const BALL := &"poke_ball"


## Événements du premier lancer d'une Poké Ball contre [param species] N[param level] avec la
## graine [param seed] : même consommation d'aléatoire que le directeur (BattleRequest.wild crée
## le sauvage, puis le moteur lance).
func _first_throw(species: StringName, level: int, seed: int) -> Array[BattleEvent]:
	var rng := GameRng.new(seed)
	var wild := Party.new()
	wild.add(PokemonFactory.create(_data, species, level, rng))
	var battle := Battle.new(BattleSide.new(_player_party(&"charmander"), true),
		BattleSide.new(wild, false, "", null), _data, rng, BattleRules.for_wild(_items))
	battle.start()
	return battle.submit(BattleAction.ball(BALL))


## Première graine (à partir de [param from]) dont le premier lancer capture ([param caught]) ou
## échoue ; −1 si aucune sous la limite.
func _throw_seed(species: StringName, level: int, caught: bool, from: int = 0) -> int:
	for seed: int in range(from, from + 3000):
		var has_caught := false
		for event: BattleEvent in _first_throw(species, level, seed):
			has_caught = has_caught or event.kind == BattleEvent.Kind.CAUGHT
		if has_caught == caught:
			return seed
	return -1


func _kinds_of(events: Array) -> Array[BattleEvent.Kind]:
	var kinds: Array[BattleEvent.Kind] = []
	for event: BattleEvent in events:
		kinds.append(event.kind)
	return kinds


## Une équipe d'un starter N5, un Sac de [param balls] Poké Balls et une Potion.
func _prepare_capture(seed: int, balls: int = 3) -> void:
	_state.party = _player_party(&"charmander")
	_state.starter_species = &"charmander"
	_state.rng = GameRng.new(seed)
	_state.bag.add(BALL, balls)
	_state.bag.add(&"potion", 1)


## Joue [param request] avec le plan [param plan] : à chaque choix d'action, l'entrée suivante —
## &"ball" (SAC puis LANCER), &"back" (SAC puis « ‹ »), &"attack", &"run" (aussi quand le plan
## est épuisé). La carte de capture est lue puis fermée dès qu'elle attend un toucher. Renvoie
## { outcome, events, haptics, card, bag_empty_shown, own_card_after_back, after_break,
## bag_seen }.
func _play_capture(request: BattleRequest, plan: Array[StringName]) -> Dictionary:
	var report := {
		"outcome": Battle.Outcome.NONE, "events": [], "haptics": [], "card": {},
		"bag_empty_shown": false, "bag_seen": false, "own_card_after_back": false,
		"after_break": {},
	}
	_director.event_played.connect(func(e: BattleEvent) -> void:
		report["events"].append(e)
		if e.kind == BattleEvent.Kind.BROKE_FREE:
			report["after_break"] = {
				"foe_card": _hud.get_card(BattleHud.Side.FOE).is_shown(),
				"own_card": _hud.get_card(BattleHud.Side.PLAYER).is_shown(),
			})
	_director.haptic_requested.connect(func(ms: int) -> void: report["haptics"].append(ms))
	var done: Array[bool] = [false]
	var runner := func() -> void:
		report["outcome"] = await _director.run_request(request, _map)
		done[0] = true
	runner.call()
	var bag_steps: Array[StringName] = []
	var after_back := false
	var deadline := Time.get_ticks_msec() + 20000
	while not done[0] and Time.get_ticks_msec() < deadline:
		var card := _director.get_capture_card()
		var panel := _director.get_bag_panel()
		var battle := _director.get_battle()
		if card != null and card.is_waiting():
			report["card"] = {
				"title": card.get_title_text(), "result": card.get_result_text(),
				"pokedex_shown": card.is_pokedex_line_shown(),
				"pokedex_text": card.get_pokedex_text(),
			}
			card.skip()
		elif panel != null and panel.is_shown() and not panel.is_answered() \
				and not bag_steps.is_empty():
			report["bag_seen"] = true
			report["bag_empty_shown"] = panel.get_empty_label().visible
			if bag_steps.pop_front() == &"back":
				panel.get_back_button().back_requested.emit()
				after_back = true
			else:
				panel.get_action_button().pressed.emit()
		elif battle != null and battle.get_state() == Battle.State.CHOOSING \
				and _hud.get_zone() == BattleHud.Zone.ACTIONS and bag_steps.is_empty():
			if after_back:
				report["own_card_after_back"] = _hud.get_card(BattleHud.Side.PLAYER).is_shown()
				after_back = false
			var step: StringName = plan.pop_front() if not plan.is_empty() else &"run"
			match step:
				&"ball":
					bag_steps.append(&"throw")
					_hud.action_selected.emit(ActionGrid.BAG)
				&"back":
					bag_steps.append(&"back")
					_hud.action_selected.emit(ActionGrid.BAG)
				&"attack":
					_hud.action_selected.emit(ActionGrid.ATTACK)
				_:
					_hud.action_selected.emit(ActionGrid.RUN)
		elif battle != null and battle.get_state() == Battle.State.CHOOSING \
				and _hud.get_zone() == BattleHud.Zone.MOVES:
			_hud.move_selected.emit(0)
		await wait_process_frames(1)
	assert_true(done[0], "le combat s'est terminé")
	return report


func _wild_catch_request(species: StringName, level: int, seed: int) -> BattleRequest:
	_prepare_capture(seed)
	return _wild_request(species, level, seed)


## Requête sauvage qui garde l'état de la partie (équipe, Sac) et ne change que la graine.
func _next_request(species: StringName, level: int, seed: int) -> BattleRequest:
	_state.rng = GameRng.new(seed)
	var encounter := WildEncounter.new(species, level, &"route_1_grass")
	return BattleRequest.wild(encounter, _data, _state.rng as GameRng, Vector2i(5, 4), _items)


## Accord au féminin du titre et de la ligne de stockage : « CAPTURÉ » / « CAPTURÉE ».
func _fem(pokemon: Pokemon) -> String:
	return "e" if pokemon.gender == Pokemon.Gender.FEMALE else ""


func test_a_ball_leaves_the_bag_once_and_the_same_pokemon_joins_the_team() -> void:
	var seed := _throw_seed(&"rattata", 3, true)
	assert_gt(seed, -1, "une graine de capture au premier lancer")
	if seed < 0:
		return
	var request := _wild_catch_request(&"rattata", 3, seed)
	var foe := request.foe_party.get_lead()
	var hp_before := foe.hp
	var report := await _play_capture(request, [&"ball"])
	assert_eq(report["outcome"], Battle.Outcome.CAUGHT, "capture")
	assert_eq(_state.bag.count_of(BALL), 2, "une seule Ball retirée")
	assert_eq(_state.bag.count_of(&"potion"), 1, "la Potion n'est pas touchée")
	var party := _state.party as Party
	assert_eq(party.size(), 2, "équipe de 2")
	assert_same(party.get_at(1), foe, "le même Pokémon, pas une copie")
	assert_eq(foe.hp, hp_before, "PV conservés")
	assert_true(_state.pokedex.is_caught(&"rattata"), "capturé au Pokédex")
	assert_true(_state.storage.is_empty(), "rien au stockage")
	assert_eq(foe.origin, Pokemon.Origin.CAPTURE, "rencontre : capture")
	assert_eq(foe.met_map, &"battle_dir_map", "rencontre : la carte du combat")
	# Le journal : lancer, 3 secousses, capture, fin ; ni adversaire qui joue, ni XP.
	var kinds := _kinds_of(report["events"])
	assert_eq(kinds.count(BattleEvent.Kind.BALL_THROWN), 1)
	assert_eq(kinds.count(BattleEvent.Kind.BALL_SHAKE), 3, "trois secousses")
	assert_eq(kinds.count(BattleEvent.Kind.CAUGHT), 1)
	assert_eq(kinds.back(), BattleEvent.Kind.BATTLE_ENDED)
	assert_false(kinds.has(BattleEvent.Kind.EXP_GAINED), "pas d'XP")
	assert_false(kinds.has(BattleEvent.Kind.MOVE_USED), "personne n'attaque")
	# Vibrations : une par secousse, puis le motif de capture (vibrations des rangs pairs).
	var shake_ms := UiTokens.HAPTIC_BALL_SHAKE_MS
	var expected: Array[int] = [shake_ms, shake_ms, shake_ms]
	for i: int in UiTokens.HAPTIC_CAPTURE.size():
		if i % 2 == 0:
			expected.append(UiTokens.HAPTIC_CAPTURE[i])
	assert_eq(report["haptics"], expected, "3 secousses puis le motif de capture")
	# Carte : titre en capitales, équipe, sans ligne Pokédex (non activé).
	var card: Dictionary = report["card"]
	assert_eq(card["title"], "RATTATA CAPTURÉ%s !" % _fem(foe).to_upper())
	assert_eq(card["result"], "Rattata rejoint ton équipe.")
	assert_false(card["pokedex_shown"], "pas de « Nouvelle entrée Pokédex » avant Chen")
	# Fin comme après une victoire : pas de soin, pas de combat, joueur libre.
	assert_false(_director.is_running())
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_false(_hud.is_shown(), "HUD cachée")
	assert_false(_stage.is_active(), "scène de combat rendue")
	assert_null(_director.get_bag_panel(), "Sac libéré")
	assert_null(_director.get_capture_card(), "carte libérée")
	assert_push_error_count(0)


func test_the_capture_is_recorded_once_even_after_a_second_capture() -> void:
	var first := _throw_seed(&"rattata", 3, true)
	var second := _throw_seed(&"pidgey", 3, true, 5000)
	assert_gt(first, -1)
	assert_gt(second, -1)
	if first < 0 or second < 0:
		return
	var emitted: Array[bool] = []
	_director.pokemon_caught.connect(func(_p: Pokemon, stored: bool) -> void:
		emitted.append(stored))
	await _play_capture(_wild_catch_request(&"rattata", 3, first), [&"ball"])
	assert_eq(_state.moments.size(), 1, "un grand moment")
	assert_eq(_state.moments[0]["type"], "first_capture")
	assert_eq(_state.moments[0]["map"], "battle_dir_map")
	assert_eq(_state.moments[0]["details"]["species"], "rattata")
	# Seconde capture : l'état de la partie continue (Sac, équipe), la graine change.
	await _play_capture(_next_request(&"pidgey", 3, second), [&"ball"])
	assert_eq((_state.party as Party).size(), 3, "deux Pokémon capturés")
	assert_true(_state.pokedex.is_caught(&"pidgey"))
	var firsts := 0
	for moment: Dictionary in _state.moments:
		firsts += int(moment["type"] == "first_capture")
	assert_eq(firsts, 1, "« première capture » enregistrée une seule fois")
	assert_eq(emitted, [false, false] as Array[bool], "pokemon_caught à chaque capture")
	assert_push_error_count(0)


func test_the_starter_is_not_a_first_capture_but_the_first_wild_one_is() -> void:
	# Le starter (Boot) enregistre « starter », jamais « first_capture » : la capture sauvage est
	# la première capture.
	var seed := _throw_seed(&"rattata", 3, true)
	if seed < 0:
		fail_test("une graine de capture")
		return
	_prepare_capture(seed)
	_state.record_moment(_state.MOMENT_STARTER, &"oak_lab", {"species": "charmander"})
	assert_false(_state.has_moment(_state.MOMENT_FIRST_CAPTURE))
	await _play_capture(_wild_request(&"rattata", 3, seed), [&"ball"])
	assert_true(_state.has_moment(_state.MOMENT_FIRST_CAPTURE))
	assert_eq(_state.moments.size(), 2)


func test_a_full_team_sends_the_capture_to_the_storage() -> void:
	var seed := _throw_seed(&"rattata", 3, true)
	assert_gt(seed, -1)
	if seed < 0:
		return
	_prepare_capture(seed)
	var party := _state.party as Party
	while not party.is_full():
		party.add(PokemonFactory.create(_data, &"pidgey", 3, GameRng.new(party.size())))
	var request := _next_request(&"rattata", 3, seed)
	var foe := request.foe_party.get_lead()
	var report := await _play_capture(request, [&"ball"])
	assert_eq(report["outcome"], Battle.Outcome.CAUGHT)
	assert_eq(party.size(), Party.MAX_SIZE, "l'équipe reste à 6")
	assert_false(party.get_all().has(foe), "le Pokémon n'est pas dans l'équipe")
	var storage := _state.storage as PokemonStorage
	assert_eq(storage.size(), 1, "stocké")
	assert_same(storage.get_all()[0], foe, "le même Pokémon")
	assert_eq(foe.origin, Pokemon.Origin.CAPTURE)
	assert_true(_state.pokedex.is_caught(&"rattata"))
	var card: Dictionary = report["card"]
	assert_eq(card["result"],
		"Rattata a été confié%s au système de recherche de Chen." % _fem(foe))
	assert_eq(card["title"], "RATTATA CAPTURÉ%s !" % _fem(foe).to_upper())
	assert_eq(_state.bag.count_of(BALL), 2)


func test_a_failed_throw_loses_the_ball_and_the_foe_plays() -> void:
	var seed := _throw_seed(&"rattata", 3, false)
	assert_gt(seed, -1, "une graine d'échec au premier lancer")
	if seed < 0:
		return
	var request := _wild_catch_request(&"rattata", 3, seed)
	var foe := request.foe_party.get_lead()
	var report := await _play_capture(request, [&"ball"])
	assert_ne(report["outcome"], Battle.Outcome.CAUGHT)
	assert_eq(_state.bag.count_of(BALL), 2, "la Ball est perdue")
	assert_false((_state.party as Party).get_all().has(foe), "pas dans l'équipe")
	assert_true(_state.storage.is_empty())
	assert_false(_state.pokedex.is_caught(&"rattata"), "pas capturé")
	assert_true(_state.moments.is_empty(), "aucun grand moment")
	var kinds := _kinds_of(report["events"])
	var thrown := kinds.find(BattleEvent.Kind.BALL_THROWN)
	var broke := kinds.find(BattleEvent.Kind.BROKE_FREE)
	assert_gt(thrown, -1)
	assert_gt(broke, thrown, "il se libère après le lancer")
	assert_true(kinds.slice(broke).has(BattleEvent.Kind.MOVE_USED), "l'adversaire joue ensuite")
	# Les secousses vibrent, pas de motif de capture.
	var shakes := kinds.count(BattleEvent.Kind.BALL_SHAKE)
	assert_eq((report["haptics"] as Array).size(), shakes, "une vibration par secousse")
	# Le Pokémon ressort : sa carte et celle du joueur sont de retour avant le tour adverse.
	assert_true(report["after_break"]["foe_card"], "carte adverse revenue")
	assert_true(report["after_break"]["own_card"], "carte du joueur revenue")
	assert_true((report["card"] as Dictionary).is_empty(), "aucune carte de capture")
	assert_push_error_count(0)


func test_back_from_the_bag_consumes_nothing() -> void:
	_prepare_capture(7)
	var request := _wild_request(&"rattata", 3, 7)
	var report := await _play_capture(request, [&"back", &"back", &"run"])
	assert_true(report["bag_seen"], "le Sac s'est ouvert")
	assert_eq(_state.bag.count_of(BALL), 3, "aucune Ball consommée")
	assert_false(_kinds_of(report["events"]).has(BattleEvent.Kind.BALL_THROWN), "aucun lancer")
	assert_true(report["own_card_after_back"], "la carte du joueur est revenue")
	assert_eq((_state.party as Party).size(), 1)
	assert_push_error_count(0)


## Joue [param request] : SAC, onglet SOINS, Potion, UTILISER, puis le Pokémon [param target]
## (ou « ‹ » du choix si [param back_from_picker]) ; ensuite FUITE. Renvoie { events, view,
## picker_seen, bag_reopened }.
func _play_potion(request: BattleRequest, target: int, back_from_picker: bool = false) -> Dictionary:
	var report := {"events": [], "view": null, "picker_seen": false, "bag_reopened": false,
		"foe_turn_own_card": false, "foe_turn_hp_text": ""}
	_director.event_played.connect(func(e: BattleEvent) -> void:
		report["events"].append(e)
		var kinds := _kinds_of(report["events"])
		# Premier coup de l'adversaire après le soin : la carte du joueur doit être là.
		if (e.kind == BattleEvent.Kind.MOVE_USED or e.kind == BattleEvent.Kind.MOVE_MISSED) \
				and e.side == BattleEvent.SideId.FOE and kinds.has(BattleEvent.Kind.ITEM_USED) \
				and not report["foe_turn_own_card"]:
			var card := _hud.get_card(BattleHud.Side.PLAYER)
			report["foe_turn_own_card"] = card.is_shown() and card.visible
			report["foe_turn_hp_text"] = card.get_hp_text())
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await _director.run_request(request, _map)
		done[0] = true
	runner.call()
	var stage := 0
	var answered := false
	var deadline := Time.get_ticks_msec() + 20000
	while not done[0] and Time.get_ticks_msec() < deadline:
		var panel := _director.get_bag_panel()
		var picker := _director.get_party_picker()
		var battle := _director.get_battle()
		if picker != null and picker.is_shown() and not answered:
			report["picker_seen"] = true
			report["view"] = picker.get_view()
			answered = true
			if back_from_picker:
				picker.back_requested.emit()
			else:
				picker.target_chosen.emit(target)
		elif panel != null and panel.is_shown() and not panel.is_answered():
			if stage == 1 and report["picker_seen"]:
				report["bag_reopened"] = true
				panel.get_back_button().back_requested.emit()
			else:
				panel.open_category(&"heal")
				panel.select_item(&"potion")
				panel.get_action_button().pressed.emit()
				stage = 1
		elif battle != null and battle.get_state() == Battle.State.CHOOSING \
				and _hud.get_zone() == BattleHud.Zone.ACTIONS:
			_hud.action_selected.emit(ActionGrid.BAG if stage == 0 else ActionGrid.RUN)
		await wait_process_frames(1)
	assert_true(done[0], "le combat s'est terminé")
	return report


## Équipe : [param starter] au complet, puis un Roucool au Nv. 20 blessé (PV [param hp]).
func _prepare_potion(hp: int) -> BattleRequest:
	var request := _wild_request(&"rattata", 3, 7)
	var hurt := PokemonFactory.create(_data, &"pidgey", 20, GameRng.new(3))
	hurt.hp = hp
	(_state.party as Party).add(hurt)
	_state.bag.add(&"potion", 3)
	return request


func test_a_potion_on_another_member_heals_it_once_then_the_foe_plays() -> void:
	var request := _prepare_potion(5)
	var hurt: Pokemon = (_state.party as Party).get_at(1)
	var report := await _play_potion(request, 1)
	assert_true(report["picker_seen"], "le choix du Pokémon s'est ouvert")
	assert_eq(hurt.hp, 25, "+20 PV")
	assert_eq(_state.bag.count_of(&"potion"), 2, "une seule Potion retirée")
	var kinds := _kinds_of(report["events"])
	var used := kinds.find(BattleEvent.Kind.ITEM_USED)
	assert_gt(used, -1, "ITEM_USED")
	assert_true(kinds.slice(used).has(BattleEvent.Kind.MOVE_USED)
		or kinds.slice(used).has(BattleEvent.Kind.MOVE_MISSED), "l'adversaire joue ensuite")
	assert_eq(report["view"].targets.size(), 2)
	assert_false(report["view"].targets[0].usable, "le Pokémon en jeu est à PV pleins")
	assert_true(report["view"].targets[1].usable)
	assert_push_error_count(0)


func test_a_potion_on_the_lead_brings_the_player_card_back_with_the_healed_hp() -> void:
	var request := _prepare_potion(5)
	var lead: Pokemon = (_state.party as Party).get_lead()
	lead.hp = 3
	var report := await _play_potion(request, 0)
	assert_gt(lead.hp, 3, "le Pokémon en jeu est soigné")
	assert_true(report["foe_turn_own_card"], "la carte du joueur est visible au tour adverse")
	assert_true(String(report["foe_turn_hp_text"]).contains(str(lead.hp))
		or lead.hp < 3, "la carte affiche les PV soignés : %s" % report["foe_turn_hp_text"])
	assert_push_error_count(0)


func test_a_potion_on_a_bench_member_also_brings_the_player_card_back() -> void:
	var request := _prepare_potion(5)
	var report := await _play_potion(request, 1)
	assert_true(report["foe_turn_own_card"], "la carte du joueur est visible au tour adverse")
	assert_push_error_count(0)


func test_back_from_the_party_choice_reopens_the_bag_and_consumes_nothing() -> void:
	var request := _prepare_potion(5)
	var hurt: Pokemon = (_state.party as Party).get_at(1)
	var report := await _play_potion(request, 1, true)
	assert_true(report["picker_seen"])
	assert_true(report["bag_reopened"], "le Sac revient")
	assert_eq(hurt.hp, 5)
	assert_eq(_state.bag.count_of(&"potion"), 3)
	assert_false(_kinds_of(report["events"]).has(BattleEvent.Kind.ITEM_USED))


func test_without_an_item_library_no_ball_can_be_thrown() -> void:
	# Sans ItemLibrary dans la requête, le moteur refuse toute Ball (piège du T13).
	_prepare_capture(7)
	var encounter := WildEncounter.new(&"rattata", 3, &"route_1_grass")
	var request := BattleRequest.wild(encounter, _data, _state.rng as GameRng, Vector2i(5, 4))
	var battle := Battle.new(BattleSide.new(_state.party, true),
		BattleSide.new(request.foe_party, false, "", null), _data, _state.rng, request.rules)
	battle.start()
	assert_false(battle.can_use_balls())
	assert_false(battle.is_legal(BattleAction.ball(BALL)))


func test_the_pokedex_line_is_shown_only_once_chen_has_activated_the_pokedex() -> void:
	var seed := _throw_seed(&"rattata", 3, true)
	assert_gt(seed, -1)
	if seed < 0:
		return
	# Avant l'activation : les données sont enregistrées, la ligne n'est pas montrée.
	var request := _wild_catch_request(&"rattata", 3, seed)
	var before := await _play_capture(request, [&"ball"])
	assert_true(_state.pokedex.is_caught(&"rattata"), "donnée enregistrée")
	assert_false((before["card"] as Dictionary)["pokedex_shown"], "pas de ligne Pokédex")
	# Après l'activation (jalon 7) : nouvelle espèce, la ligne apparaît.
	_state.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	var other := _throw_seed(&"pidgey", 3, true, 7000)
	assert_gt(other, -1)
	if other < 0:
		return
	var after := await _play_capture(_next_request(&"pidgey", 3, other), [&"ball"])
	var card: Dictionary = after["card"]
	assert_true(card["pokedex_shown"], "ligne montrée une fois le Pokédex activé")
	assert_eq(card["pokedex_text"], "Nouvelle entrée Pokédex")
	# Une espèce déjà capturée n'est plus « nouvelle ».
	var third := _throw_seed(&"pidgey", 3, true, 9000)
	if third < 0:
		return
	var again := await _play_capture(_next_request(&"pidgey", 3, third), [&"ball"])
	assert_false((again["card"] as Dictionary)["pokedex_shown"], "plus nouvelle")
	assert_push_error_count(0)


func test_the_bag_stays_closed_against_a_trainer() -> void:
	var battle_seed := _seed_for(&"charmander", Battle.Outcome.WIN)
	_prepare(&"charmander", battle_seed)
	_state.bag.add(BALL, 3)
	_state.bag.add(&"potion", 2)
	var opened: Array[bool] = [false]
	var done: Array[bool] = [false]
	var actors: Dictionary[StringName, StringName] = {&"player": MINE_ID, &"foe": FOE_ID}
	var runner := func() -> void:
		await _director.run(&"rival_lab", _map, actors)
		done[0] = true
	runner.call()
	var deadline := Time.get_ticks_msec() + 20000
	var tried := false
	while not done[0] and Time.get_ticks_msec() < deadline:
		opened[0] = opened[0] or _director.get_bag_panel() != null
		var battle := _director.get_battle()
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			match _hud.get_zone():
				BattleHud.Zone.ACTIONS:
					# SAC est atténué : même si le signal arrivait, rien ne s'ouvre.
					_hud.action_selected.emit(ActionGrid.ATTACK if tried else ActionGrid.BAG)
					tried = true
				BattleHud.Zone.MOVES:
					_hud.move_selected.emit(0)
		await wait_process_frames(1)
	assert_true(done[0])
	assert_false(opened[0], "le Sac ne s'ouvre pas contre un dresseur")
	assert_eq(_state.bag.count_of(BALL), 3, "aucune Ball consommée")
	assert_eq(_state.bag.count_of(&"potion"), 2, "aucune Potion consommée")
