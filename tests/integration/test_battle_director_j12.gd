extends GutTest
## Combat du jalon 12 joué par le BattleDirector (T14, `jalon-12.md` §2.10, annexe A.4), vraie
## HUD, vrai panneau ÉQUIPE, speed_scale = 0. Pokémon du joueur piégé : FUITE affiche
## « Impossible de fuir ! » **sans rien soumettre** (aucun tour, aucune erreur de submit), puis la
## grille revient ; ÉQUIPE : « Impossible de changer » sur les cartes, ENVOYER éteint. Entrave :
## la carte de la capacité bloquée est grisée, « BLOQUÉE », et l'autre capacité se joue.
## Volatils posés directement sur le Battler (moteur testé au T13) et retirés avant tout tour.

const PLAYER_SCENE := preload("res://game/player/player.tscn")
const STAGE_SCENE := preload("res://game/battle/battle_stage.tscn")
const HUD_SCENE := preload("res://game/ui/battle/battle_hud.tscn")
const GAME_STATE := preload("res://game/autoload/game_state.gd")
const NPCS := "res://tests/fixtures/npcs/"
const PLAYER_CELL := Vector2i(11, 7)
const PLAYER_SEED := 999
const K := BattleEvent.Kind

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
	map.name = "SwitchMap"
	map.map_id = &"battle_switch_map"
	map.npcs_dir = NPCS
	map.size = Vector2i(20, 18)
	for group: String in ["Entities", "Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		map.add_child(node)
	return map


func _mon(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(PLAYER_SEED))


## Combat sauvage contre [param species] N[param level] qui ne connaît que [param foe_move] ;
## l'équipe du joueur est [param team].
func _request(team: Array[Pokemon], species: StringName, level: int,
		foe_move: StringName) -> BattleRequest:
	var party := Party.new()
	for pokemon: Pokemon in team:
		party.add(pokemon)
	_state.party = party
	_state.starter_species = team[0].species_id
	_state.rng = GameRng.new(7)
	var encounter := WildEncounter.new(species, level, &"route_1_grass")
	var request := BattleRequest.wild(encounter, _data, _state.rng as GameRng, Vector2i(5, 4),
		_items)
	var foe := request.foe_party.get_lead()
	foe.moves.clear()
	foe.learn_move(foe_move, _data)
	return request


## Lance [param request] ; à chaque image, [param step] (reçoit le combat et le panneau ÉQUIPE,
## éventuellement null) pilote la HUD. Renvoie { outcome, events }.
func _drive(request: BattleRequest, step: Callable) -> Dictionary:
	var report := {"outcome": Battle.Outcome.NONE, "events": []}
	_director.event_played.connect(func(e: BattleEvent) -> void: report["events"].append(e))
	var done: Array[bool] = [false]
	var runner := func() -> void:
		report["outcome"] = await _director.run_request(request, _map)
		done[0] = true
	runner.call()
	var deadline := Time.get_ticks_msec() + 20000
	while not done[0] and Time.get_ticks_msec() < deadline:
		var battle := _director.get_battle()
		if battle != null:
			step.call(battle, _director.get_party_panel())
		await wait_process_frames(1)
	assert_true(done[0], "le combat s'est terminé")
	return report


func _panel_waiting(panel: BattlePartyPanel) -> bool:
	return panel != null and panel.is_shown() and not panel.is_answered() \
		and not panel.is_sliding()


func _own_card() -> BattleInfoCard:
	return _hud.get_card(BattleHud.Side.PLAYER)


func _kinds(events: Array) -> Array:
	var result: Array = []
	for event: BattleEvent in events:
		result.append([K.find_key(event.kind), BattleEvent.SideId.find_key(event.side)])
	return result


# --- Piège et Entrave ---------------------------------------------------------------------

func test_trapped_flee_and_switch_are_refused_and_the_blocked_move_is_grey() -> void:
	var charmander := _mon(&"charmander", 5)
	var squirtle := _mon(&"squirtle", 5)
	var request := _request([charmander, squirtle], &"rattata", 3, &"tail_whip")
	var seen := {"phase": 0, "turns_before": -1, "turns_after": -1, "banner": "",
		"reasons": [], "send_disabled": false, "footer": "", "blocked": [], "labels": [],
		"usable": []}
	var turns := [0]
	_director.event_played.connect(func(e: BattleEvent) -> void:
		if e.kind == K.TURN_STARTED:
			turns[0] += 1)
	# Le bandeau tient 0 s en test (speed_scale = 0) : la phrase est relevée dans son signal.
	var shown: Array[String] = []
	_hud.get_message_banner().message_shown.connect(func(text: String, _wait: bool) -> void:
		if seen["phase"] == 1:
			shown.append(text))
	var step := func(battle: Battle, panel: BattlePartyPanel) -> void:
		var choosing := battle.get_state() == Battle.State.CHOOSING \
			and _hud.get_zone() == BattleHud.Zone.ACTIONS
		var lead := battle.get_player_side().active
		match seen["phase"]:
			0:
				if choosing:
					lead.trap_turns = 3
					seen["turns_before"] = turns[0]
					# Phase posée avant : sans durée, la phrase passe dans l'appel même.
					seen["phase"] = 1
					_hud.action_selected.emit(ActionGrid.RUN)
			1:
				if not shown.is_empty() and choosing:
					seen["banner"] = "|".join(shown)
					seen["turns_after"] = turns[0]
					_hud.action_selected.emit(ActionGrid.TEAM)
					seen["phase"] = 3
			3:
				if _panel_waiting(panel):
					for card: BattlePartyCard in panel.get_cards():
						seen["reasons"].append(card.get_reason_text())
					seen["send_disabled"] = not panel.get_send_button().visible
					panel.get_card(1).tapped.emit()
					seen["footer"] = panel.get_footer_text()
					panel.get_back_button().back_requested.emit()
					seen["phase"] = 4
			4:
				if choosing:
					lead.clear_trap()
					lead.disabled_slot = 0
					lead.disabled_turns = 3
					_hud.action_selected.emit(ActionGrid.ATTACK)
					seen["phase"] = 5
			5:
				var grid := _hud.get_move_grid()
				if _hud.get_zone() == BattleHud.Zone.MOVES and grid.is_shown() \
						and not grid.is_sliding():
					for i: int in 2:
						seen["blocked"].append(grid.get_card(i).is_blocked())
						seen["labels"].append(grid.get_card(i).get_power_text())
						seen["usable"].append(grid.get_card(i).is_usable())
					_hud.move_selected.emit(1)
					seen["phase"] = 6
			6:
				if choosing:
					lead.clear_disable()
					_hud.action_selected.emit(ActionGrid.RUN)
					seen["phase"] = 7
	var report := await _drive(request, step)
	assert_eq(report["outcome"], Battle.Outcome.FLED, "la fuite libre finit le combat")
	assert_eq(seen["banner"], "Impossible de fuir !")
	assert_gt(seen["turns_before"], -1)
	assert_eq(seen["turns_after"], seen["turns_before"], "fuite refusée : aucun tour joué")
	assert_eq(seen["reasons"], ["", "Impossible de changer"],
		"l'actif dit ACTIF, l'autre sa raison")
	assert_true(seen["send_disabled"], "ENVOYER caché : personne à envoyer")
	assert_string_contains(seen["footer"], "Impossible de changer")
	assert_eq(seen["blocked"], [true, false])
	assert_eq(seen["labels"], ["BLOQUÉE", "Statut"])
	assert_eq(seen["usable"], [false, true])
	var kinds := _kinds(report["events"])
	assert_true(kinds.has(["MOVE_USED", "PLAYER"]), "Rugissement joué")
	assert_false(kinds.has(["WITHDRAWN", "PLAYER"]), "aucun changement")
	assert_eq(charmander.moves[0].pp, charmander.moves[0].max_pp, "Griffe jamais lancée")
	assert_push_error_count(0, "rien n'a été refusé par submit")
