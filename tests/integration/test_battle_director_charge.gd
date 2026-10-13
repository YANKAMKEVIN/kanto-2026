extends GutTest
## BattleDirector : Tunnel de bout en bout (jalon 14 T9). Le sprite du lanceur est caché dès
## CHARGE_STARTED et rendu à CHARGE_RELEASED ; pendant le tour verrouillé, aucun menu d'actions
## n'est proposé ; Téléport efface le sprite adverse (Rattata en doublure : Abra
## n'est pas encore en données).

const J14Moves := preload("res://tests/helpers/j14_moves.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const STAGE_SCENE := preload("res://game/battle/battle_stage.tscn")
const HUD_SCENE := preload("res://game/ui/battle/battle_hud.tscn")
const GAME_STATE := preload("res://game/autoload/game_state.gd")
const NPCS := "res://tests/fixtures/npcs/"
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

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
	J14Moves.ensure(_data)
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
	_map = GameMap.new()
	_map.name = "ChargeMap"
	_map.map_id = &"battle_charge_map"
	_map.npcs_dir = NPCS
	_map.size = Vector2i(20, 18)
	for group: String in ["Entities", "Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		_map.add_child(node)
	world.add_child(_map)
	_player = PLAYER_SCENE.instantiate() as Player
	_map.get_entities().add_child(_player)
	_player.enter_map(_map.get_grid(), Vector2i(11, 7), Vector2i.LEFT, _map.get_pixel_rect())
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


func _with_moves(species: StringName, level: int, ids: Array[StringName]) -> Pokemon:
	var pokemon := PokemonFactory.create(_data, species, level, GameRng.new(7))
	pokemon.moves.clear()
	for id: StringName in ids:
		pokemon.moves.append(MoveSlot.new(id, _data.get_move(id).pp))
	return pokemon


func test_dig_hides_then_returns_and_locked_turn_offers_no_menu() -> void:
	var party := Party.new()
	party.add(_with_moves(&"charmander", 8, [&"dig", &"scratch"]))
	_state.party = party
	_state.starter_species = &"charmander"
	_state.rng = GameRng.new(3)
	var request := BattleRequest.new()
	request.intro = BattleRequest.Intro.WILD
	request.foe_party = Party.new()
	request.foe_party.add(_with_moves(&"geodude", 3, [&"tackle"]))
	request.rules = BattleRules.for_wild(_items)
	request.origin_cell = Vector2i(5, 4)
	# Journal des temps forts : événements joués, apparitions du menu d'actions, état du sprite.
	var log: Array = []
	_director.event_played.connect(func(e: BattleEvent) -> void:
		log.append("event:" + K.find_key(e.kind))
		if e.kind == K.CHARGE_STARTED:
			log.append("buried:%s" % _stage.is_buried(P))
			log.append("hidden:%s" % (not _stage.get_sprite(P).visible))
		if e.kind == K.CHARGE_RELEASED:
			log.append("visible:%s" % _stage.get_sprite(P).visible))
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await _director.run_request(request, _map)
		done[0] = true
	runner.call()
	var was_actions := false
	var deadline := Time.get_ticks_msec() + 20000 # délai de garde
	while not done[0] and Time.get_ticks_msec() < deadline:
		var battle := _director.get_battle()
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			var in_actions := _hud.get_zone() == BattleHud.Zone.ACTIONS
			if in_actions and not was_actions:
				log.append("actions")
			was_actions = in_actions
			match _hud.get_zone():
				BattleHud.Zone.ACTIONS:
					_hud.action_selected.emit(ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					_hud.move_selected.emit(0)
		await wait_process_frames(1)
	assert_true(done[0], "le combat s'est terminé")
	var started := log.find("event:CHARGE_STARTED")
	var released := log.find("event:CHARGE_RELEASED")
	assert_gt(started, -1, "Tunnel chargé : %s" % [log])
	assert_gt(released, started, "puis libéré")
	assert_true(log.has("buried:true") and log.has("hidden:true"), "sprite caché")
	assert_true(log.has("visible:true"), "sprite rendu à la libération")
	assert_eq(log.slice(started, released).count("actions"), 0,
		"aucun menu pendant le tour verrouillé")
	assert_eq(log.count("actions"), 1, "un seul choix (tour 1) : %s" % [log])
	assert_false(_stage.is_buried(P))


func test_teleport_beat_erases_the_foe_sprite() -> void:
	var party := Party.new()
	party.add(_with_moves(&"charmander", 8, [&"scratch"]))
	_state.party = party
	_state.rng = GameRng.new(3)
	var request := BattleRequest.new()
	request.intro = BattleRequest.Intro.WILD
	request.foe_party = Party.new()
	request.foe_party.add(_with_moves(&"rattata", 5, [&"teleport"]))
	request.rules = BattleRules.for_wild(_items)
	request.origin_cell = Vector2i(5, 4)
	var seen: Array[bool] = [false, false]
	_director.event_played.connect(func(e: BattleEvent) -> void:
		if e.kind == K.SENT_OUT and e.side == F:
			seen[0] = _stage.get_sprite(F).visible
		if e.kind == K.TELEPORTED:
			seen[1] = not _stage.get_sprite(F).visible)
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await _director.run_request(request, _map)
		done[0] = true
	runner.call()
	var deadline := Time.get_ticks_msec() + 20000 # délai de garde
	while not done[0] and Time.get_ticks_msec() < deadline:
		var battle := _director.get_battle()
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			match _hud.get_zone():
				BattleHud.Zone.ACTIONS:
					_hud.action_selected.emit(ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					_hud.move_selected.emit(0)
		await wait_process_frames(1)
	assert_true(done[0])
	assert_true(seen[0], "le sauvage est apparu")
	assert_true(seen[1], "TELEPORTED : le sprite adverse est effacé")
	assert_eq(_director.is_running(), false)
