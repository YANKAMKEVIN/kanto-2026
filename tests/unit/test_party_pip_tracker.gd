extends GutTest
## PartyPipTracker : état des pastilles d'équipe (en forme, statut, K.O.) lu au début du combat,
## puis tenu au fil des événements joués, sans interroger le moteur.

var _data: PokemonData
var _rng: GameRng
var _tracker: PartyPipTracker


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_rng = GameRng.new(7)
	_tracker = PartyPipTracker.new()


func _party(count: int) -> Party:
	var party := Party.new()
	for i: int in count:
		party.add(PokemonFactory.create(_data, &"charmander", 5, _rng))
	return party


func _event(kind: BattleEvent.Kind, side: BattleEvent.SideId, index: int,
		status: StringName = StatusRules.NONE) -> BattleEvent:
	var event := BattleEvent.new(kind, side)
	event.party_index = index
	event.status = status
	return event


func test_start_states_follow_the_parties() -> void:
	var party := _party(3)
	party.get_at(1).status = StatusRules.POISON
	party.get_at(2).take_damage(party.get_at(2).max_hp())
	_tracker.reset(party, _party(2))
	assert_eq(_tracker.states(BattleEvent.SideId.PLAYER), [PartyPips.State.READY,
		PartyPips.State.STATUS, PartyPips.State.FAINTED] as Array[PartyPips.State])
	assert_eq(_tracker.states(BattleEvent.SideId.FOE), [PartyPips.State.READY,
		PartyPips.State.READY] as Array[PartyPips.State])


func test_wild_battle_has_no_foe_states() -> void:
	_tracker.reset(_party(1), null)
	assert_eq(_tracker.states(BattleEvent.SideId.FOE).size(), 0)
	assert_false(_tracker.apply(_event(BattleEvent.Kind.FAINTED, BattleEvent.SideId.FOE, 0)),
		"un sauvage n'a pas de pastille")


func test_faint_then_revive() -> void:
	_tracker.reset(_party(2), _party(2))
	assert_true(_tracker.apply(_event(BattleEvent.Kind.FAINTED, BattleEvent.SideId.FOE, 0)))
	assert_eq(_tracker.states(BattleEvent.SideId.FOE)[0], PartyPips.State.FAINTED)
	assert_eq(_tracker.states(BattleEvent.SideId.PLAYER)[0], PartyPips.State.READY,
		"l'autre camp ne bouge pas")
	assert_false(_tracker.apply(_event(BattleEvent.Kind.FAINTED, BattleEvent.SideId.FOE, 0)),
		"déjà K.O. : rien ne change")
	_tracker.apply(_event(BattleEvent.Kind.FAINTED, BattleEvent.SideId.PLAYER, 1))
	assert_true(_tracker.apply(_event(BattleEvent.Kind.REVIVED, BattleEvent.SideId.PLAYER, 1)))
	assert_eq(_tracker.states(BattleEvent.SideId.PLAYER)[1], PartyPips.State.READY)


func test_status_inflicted_then_cured() -> void:
	_tracker.reset(_party(1), _party(1))
	assert_true(_tracker.apply(_event(BattleEvent.Kind.STATUS_INFLICTED,
		BattleEvent.SideId.PLAYER, 0, StatusRules.POISON)))
	assert_eq(_tracker.states(BattleEvent.SideId.PLAYER)[0], PartyPips.State.STATUS)
	# L'événement de guérison porte le statut effacé, pas l'état d'après.
	assert_true(_tracker.apply(_event(BattleEvent.Kind.STATUS_CURED,
		BattleEvent.SideId.PLAYER, 0, StatusRules.POISON)))
	assert_eq(_tracker.states(BattleEvent.SideId.PLAYER)[0], PartyPips.State.READY)


func test_sent_out_carries_the_status() -> void:
	_tracker.reset(_party(2), _party(1))
	_tracker.apply(_event(BattleEvent.Kind.SENT_OUT, BattleEvent.SideId.PLAYER, 1,
		StatusRules.POISON))
	assert_eq(_tracker.states(BattleEvent.SideId.PLAYER)[1], PartyPips.State.STATUS)


func test_events_without_a_pokemon_or_out_of_range_are_ignored() -> void:
	_tracker.reset(_party(1), _party(1))
	assert_false(_tracker.apply(null))
	assert_false(_tracker.apply(_event(BattleEvent.Kind.FAINTED, BattleEvent.SideId.FOE, -1)))
	assert_false(_tracker.apply(_event(BattleEvent.Kind.FAINTED, BattleEvent.SideId.FOE, 4)))
	assert_false(_tracker.apply(_event(BattleEvent.Kind.DAMAGE, BattleEvent.SideId.FOE, 0)),
		"un coup ne change pas la pastille")


func test_states_is_a_copy() -> void:
	_tracker.reset(_party(1), null)
	var states := _tracker.states(BattleEvent.SideId.PLAYER)
	states[0] = PartyPips.State.FAINTED
	assert_eq(_tracker.states(BattleEvent.SideId.PLAYER)[0], PartyPips.State.READY)
