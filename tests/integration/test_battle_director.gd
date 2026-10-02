extends GutTest
## BattleDirector (jalon-04.md §14.2, §14.11 T8) sur une mini-carte avec deux PNJ Pokémon, le
## vrai BattleStage et la vraie BattleHud, un GameState neuf, une graine fixe, speed_scale = 0,
## les choix du joueur simulés par les signaux de la HUD (toujours la 1re capacité).
## Vérifie : blocage du joueur dès l'appel ; un event_played par événement, dans l'ordre ; les
## PV de la carte suivent event.hp ; victoire (WIN) et défaite (LOSS) avec des graines
## choisies ; aucun message générique de début ni de fin ; équipe soignée après ; ni argent ni
## XP ; PNJ Pokémon réaffichés, caméra rendue, HUD cachée, joueur libre ; refus si un combat
## tourne ou si le dresseur est inconnu.

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
	_director.setup(_data, _trainers, _texts, _stage, _hud, _player, _state)
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
func _play() -> Array:
	var events: Array[BattleEvent] = []
	_director.event_played.connect(func(e: BattleEvent) -> void: events.append(e))
	var result: Array = [Battle.Outcome.NONE]
	var done: Array[bool] = [false]
	var world_actors: Dictionary[StringName, StringName] = {&"player": MINE_ID, &"foe": FOE_ID}
	var runner := func() -> void:
		result[0] = await _director.run(&"rival_lab", _map, world_actors)
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
	return BattleRequest.wild(encounter, _data, _state.rng as GameRng, Vector2i(5, 4))


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
