extends GutTest
## Changement de Pokémon joué par le BattleDirector (jalon 7, jalon-07.md §15.23) avec le vrai
## BattleStage, la vraie BattleHud et le vrai panneau ÉQUIPE, speed_scale = 0 : ÉQUIPE ouvre le
## panneau à la place de la carte du joueur, « ‹ » la rend, ENVOYER joue « Reviens » / rappel /
## « En avant » puis l'adversaire ; la carte de PV du nouveau Pokémon est visible ; après un K.O.,
## le même panneau, sans « ‹ », fait choisir le suivant ; un Pokémon seul : ÉQUIPE atténué.

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


# --- Changement volontaire ---------------------------------------------------------------

func test_team_opens_the_panel_back_returns_and_send_switches() -> void:
	var charmander := _mon(&"charmander", 5)
	var squirtle := _mon(&"squirtle", 5)
	var bulbasaur := _mon(&"bulbasaur", 5)
	bulbasaur.hp = 0
	var request := _request([charmander, squirtle, bulbasaur], &"rattata", 3, &"tail_whip")
	var seen := {"phase": 0, "panel_tags": [], "panel_reasons": [], "card_hidden": false,
		"back_shown": false, "card_after_back": false, "after_switch": "", "sprite_hidden": false,
		"card_on_sent": false}
	_director.event_played.connect(func(e: BattleEvent) -> void:
		if e.kind == K.WITHDRAWN:
			seen["sprite_hidden"] = not _stage.get_sprite(BattleEvent.SideId.PLAYER).visible
		elif e.kind == K.SENT_OUT and e.side == BattleEvent.SideId.PLAYER \
				and seen["phase"] >= 4:
			seen["card_on_sent"] = _own_card().is_shown())
	var step := func(battle: Battle, panel: BattlePartyPanel) -> void:
		var choosing := battle.get_state() == Battle.State.CHOOSING \
			and _hud.get_zone() == BattleHud.Zone.ACTIONS
		match seen["phase"]:
			0:
				if choosing:
					assert_true(_hud.get_action_grid().is_action_enabled(ActionGrid.TEAM),
						"ÉQUIPE actif avec trois Pokémon")
					_hud.action_selected.emit(ActionGrid.TEAM)
					seen["phase"] = 1
			1:
				if _panel_waiting(panel):
					for card: BattlePartyCard in panel.get_cards():
						seen["panel_tags"].append(card.get_tag_text())
						seen["panel_reasons"].append(card.get_reason_text())
					seen["card_hidden"] = not _own_card().is_shown()
					seen["back_shown"] = panel.get_back_button().is_shown()
					panel.get_back_button().back_requested.emit()
					seen["phase"] = 2
			2:
				if choosing:
					seen["card_after_back"] = _own_card().is_shown()
					_hud.action_selected.emit(ActionGrid.TEAM)
					seen["phase"] = 3
			3:
				if _panel_waiting(panel):
					assert_eq(panel.get_selected_index(), 1, "Carapuce présélectionné")
					panel.get_send_button().pressed.emit()
					seen["phase"] = 4
			4:
				if choosing:
					seen["after_switch"] = "%s|%s" % [_own_card().get_name_text(),
						_own_card().is_shown()]
					assert_eq(battle.get_player_side().active.pokemon, squirtle)
					_hud.action_selected.emit(ActionGrid.RUN)
					seen["phase"] = 5
			_:
				if choosing:
					_hud.action_selected.emit(ActionGrid.RUN)
	var report := await _drive(request, step)
	assert_eq(report["outcome"], Battle.Outcome.FLED)
	assert_eq(seen["panel_tags"], ["ACTIF", "", "K.O."])
	assert_eq(seen["panel_reasons"], ["", "", "Ne peut plus combattre"])
	assert_true(seen["card_hidden"], "le panneau prend la place de la carte du joueur")
	assert_true(seen["back_shown"], "« ‹ » pour revenir")
	assert_true(seen["card_after_back"], "« ‹ » : la carte du joueur revient")
	assert_true(seen["sprite_hidden"], "le Pokémon rappelé a quitté la scène")
	assert_true(seen["card_on_sent"], "la carte du nouveau arrive à son envoi")
	assert_eq(seen["after_switch"], "CARAPUCE|true", "carte de PV du nouveau visible")
	# Journal du tour : rappel, envoi, puis l'adversaire joue (contre le nouveau).
	var kinds := _kinds(report["events"])
	var at := kinds.find(["WITHDRAWN", "PLAYER"])
	assert_gt(at, -1, "WITHDRAWN joué")
	assert_eq(kinds.slice(at, at + 3), [["WITHDRAWN", "PLAYER"], ["SENT_OUT", "PLAYER"],
		["MOVE_USED", "FOE"]])
	var sent: BattleEvent = report["events"][at + 1]
	assert_eq(sent.party_index, 1)
	assert_eq((_state.party as Party).get_all(), [charmander, squirtle, bulbasaur] as Array[Pokemon],
		"l'ordre de l'équipe ne change pas")
	assert_push_error_count(0)


func test_withdraw_and_send_out_lines_are_played() -> void:
	var request := _request([_mon(&"charmander", 5), _mon(&"squirtle", 5)], &"rattata", 3,
		&"tail_whip")
	var lines: Array[String] = []
	var phase: Array[int] = [0]
	var step := func(battle: Battle, panel: BattlePartyPanel) -> void:
		var choosing := battle.get_state() == Battle.State.CHOOSING \
			and _hud.get_zone() == BattleHud.Zone.ACTIONS
		if phase[0] == 0 and choosing:
			_hud.action_selected.emit(ActionGrid.TEAM)
			phase[0] = 1
		elif phase[0] == 1 and _panel_waiting(panel):
			panel.get_send_button().pressed.emit()
			phase[0] = 2
		elif phase[0] == 2 and choosing:
			_hud.action_selected.emit(ActionGrid.RUN)
	var report := await _drive(request, step)
	for event: BattleEvent in report["events"]:
		if event.side == BattleEvent.SideId.PLAYER \
				and event.kind in [K.WITHDRAWN, K.SENT_OUT]:
			lines.append_array(_texts.lines(event, _data))
	assert_eq(lines, ["En avant, Salamèche !", "Reviens, Salamèche !", "En avant, Carapuce !"]
		as Array[String])


## Bilan de fin de combat (demande n° 1) : les deux participants (Salamèche, puis Carapuce
## envoyé) ont leur ligne, dans l'ordre de l'équipe, avec leur part ; Bulbizarre, resté dans
## l'équipe, est absent.
func test_summary_lists_the_participants_only() -> void:
	var charmander := _mon(&"charmander", 5)
	var squirtle := _mon(&"squirtle", 5)
	var bulbasaur := _mon(&"bulbasaur", 5)
	var request := _request([charmander, squirtle, bulbasaur], &"rattata", 2, &"tail_whip")
	var phase: Array[int] = [0]
	var seen := {}
	_director.exp_summary_shown.connect(func(summary: ExpSummary) -> void:
		var names: Array[String] = []
		var gains: Array[String] = []
		for row: ExpSummaryRow in _director.get_summary_card().get_rows():
			names.append(row.get_name_text())
			gains.append(row.get_gain_text())
		seen["names"] = names
		seen["gains"] = gains
		seen["shares"] = summary.get_entries().map(
			func(entry: ExpSummaryEntry) -> int: return entry.exp_gained))
	var step := func(battle: Battle, panel: BattlePartyPanel) -> void:
		var zone := _hud.get_zone()
		var choosing := battle.get_state() == Battle.State.CHOOSING
		if phase[0] == 0 and choosing and zone == BattleHud.Zone.ACTIONS:
			_hud.action_selected.emit(ActionGrid.TEAM)
			phase[0] = 1
		elif phase[0] == 1 and _panel_waiting(panel):
			panel.get_send_button().pressed.emit()
			phase[0] = 2
		elif phase[0] == 2 and choosing:
			if zone == BattleHud.Zone.ACTIONS:
				_hud.action_selected.emit(ActionGrid.ATTACK)
			elif zone == BattleHud.Zone.MOVES:
				_hud.move_selected.emit(0)
	var report := await _drive(request, step)
	assert_eq(report["outcome"], Battle.Outcome.WIN)
	assert_eq(seen.get("names"), ["Salamèche", "Carapuce"] as Array[String],
		"les deux participants, pas Bulbizarre")
	var shares: Array = seen.get("shares", [])
	assert_eq(shares.size(), 2)
	if shares.size() == 2:
		assert_eq(seen.get("gains"), ["+%d XP" % shares[0], "+%d XP" % shares[1]]
			as Array[String])
	assert_push_error_count(0)


# --- K.O. : choix forcé --------------------------------------------------------------------

func test_a_knock_out_makes_the_player_choose_without_back() -> void:
	var charmander := _mon(&"charmander", 5)
	charmander.hp = 1
	var squirtle := _mon(&"squirtle", 5)
	var request := _request([charmander, squirtle], &"rattata", 5, &"tackle")
	var seen := {"forced": [], "title": "", "back_shown": true, "tag0": "", "card_hidden": false,
		"refused": "", "after": "", "replaced": false}
	var step := func(battle: Battle, panel: BattlePartyPanel) -> void:
		if _panel_waiting(panel):
			seen["forced"].append(panel.is_forced())
			seen["title"] = panel.get_title_text()
			seen["back_shown"] = panel.get_back_button().is_shown()
			seen["tag0"] = panel.get_card(0).get_tag_text()
			seen["card_hidden"] = not _own_card().is_shown()
			assert_true(battle.needs_replacement())
			# Toucher le K.O. : refusé, sa raison ; « ‹ » ne fait rien ; ENVOYER Carapuce.
			panel.get_card(0).tapped.emit()
			seen["refused"] = panel.get_footer_text()
			panel.get_back_button().back_requested.emit()
			panel.get_send_button().pressed.emit()
			seen["replaced"] = true
			return
		if battle.get_state() != Battle.State.CHOOSING:
			return
		match _hud.get_zone():
			BattleHud.Zone.ACTIONS:
				if seen["replaced"] and seen["after"] == "":
					seen["after"] = "%s|%s" % [_own_card().get_name_text(),
						_own_card().is_shown()]
				_hud.action_selected.emit(ActionGrid.RUN if seen["replaced"]
					else ActionGrid.ATTACK)
			BattleHud.Zone.MOVES:
				_hud.move_selected.emit(0)
	var report := await _drive(request, step)
	assert_eq(seen["forced"], [true], "un seul choix, forcé")
	assert_eq(seen["title"], "Qui envoyer au combat ?")
	assert_false(seen["back_shown"], "pas de retour après un K.O.")
	assert_eq(seen["tag0"], "K.O.")
	assert_true(seen["card_hidden"])
	assert_eq(seen["refused"], "Salamèche : Ne peut plus combattre")
	assert_eq(seen["after"], "CARAPUCE|true", "carte de PV du remplaçant visible")
	var kinds := _kinds(report["events"])
	var fainted := kinds.find(["FAINTED", "PLAYER"])
	assert_gt(fainted, -1)
	assert_eq(kinds.find(["WITHDRAWN", "PLAYER"]), -1, "pas de rappel pour un K.O.")
	var sent := kinds.find(["SENT_OUT", "PLAYER"], fainted)
	assert_gt(sent, fainted, "le remplaçant entre après le K.O.")
	assert_eq((report["events"][sent] as BattleEvent).party_index, 1)
	assert_ne(report["outcome"], Battle.Outcome.LOSS)


# --- Un seul Pokémon -----------------------------------------------------------------------

func test_team_stays_dimmed_with_a_single_pokemon() -> void:
	var request := _request([_mon(&"charmander", 5)], &"rattata", 3, &"tail_whip")
	var seen: Array[bool] = []
	var step := func(battle: Battle, _panel: BattlePartyPanel) -> void:
		if battle.get_state() == Battle.State.CHOOSING \
				and _hud.get_zone() == BattleHud.Zone.ACTIONS:
			seen.append(_hud.get_action_grid().is_action_enabled(ActionGrid.TEAM))
			_hud.action_selected.emit(ActionGrid.TEAM)
			_hud.action_selected.emit(ActionGrid.RUN)
	var report := await _drive(request, step)
	assert_eq(report["outcome"], Battle.Outcome.FLED)
	assert_false(seen.is_empty())
	assert_false(seen.has(true), "ÉQUIPE atténué")
	assert_null(_director.get_party_panel(), "aucun panneau ouvert")
