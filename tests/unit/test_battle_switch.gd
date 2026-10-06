extends GutTest
## Battle : changement de Pokémon (jalon 7, jalon-07.md §15.23). Le changement passe avant
## les capacités, l'adversaire attaque ensuite le nouveau ; interdits (actif, K.O.) ; niveaux
## de statistiques remis à zéro ; K.O. du joueur → il choisit le suivant (REPLACING) ; XP
## partagée entre les participants encore debout.
##
## N5, IV 0 : Salamèche PV 18, Carapuce PV 19 ; Roucool N3. Tirages imposés, dans l'ordre :
## IA adverse (pick_index), puis précision / critique (2 = non) / aléatoire (16) de son action.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const K := BattleEvent.Kind

var _data: PokemonData
var _rng: ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _mon(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))


## Combat démarré : [param team] contre [param foes] ; [param draws] : tirages après le départ.
func _battle(team: Array[Pokemon], foes: Array[Pokemon], draws: Array[int],
		rules: BattleRules = BattleRules.for_wild(), trainer: String = "") -> Battle:
	_rng = ScriptedRng.new(draws)
	var party := Party.new()
	for pokemon: Pokemon in team:
		party.add(pokemon)
	var foe_party := Party.new()
	for pokemon: Pokemon in foes:
		foe_party.add(pokemon)
	var battle := Battle.new(BattleSide.new(party, true),
		BattleSide.new(foe_party, false, trainer), _data, _rng, rules)
	battle.start()
	return battle


func _kinds(events: Array[BattleEvent]) -> Array:
	var result: Array = []
	for event: BattleEvent in events:
		result.append([K.find_key(event.kind), BattleEvent.SideId.find_key(event.side)])
	return result


func _of_kind(events: Array[BattleEvent], kind: BattleEvent.Kind) -> Array[BattleEvent]:
	var result: Array[BattleEvent] = []
	for event: BattleEvent in events:
		if event.kind == kind:
			result.append(event)
	return result


# --- Ordre ------------------------------------------------------------------------------

func test_switch_goes_first_then_the_foe_hits_the_new_pokemon() -> void:
	var charmander := _mon(&"charmander", 5)
	var squirtle := _mon(&"squirtle", 5)
	var battle := _battle([charmander, squirtle], [_mon(&"pidgey", 3)], [1, 50, 2, 16])
	# Même plus lent que l'adversaire, le changement passe avant (priorité du changement).
	battle.get_player_side().active.change_stage(&"spe", -6)
	var action := BattleAction.switch_to(1)
	assert_true(battle.is_legal(action))
	var events := battle.submit(action)
	assert_eq(_rng.remaining(), 0, "le changement ne tire rien")
	assert_eq(_kinds(events), [["TURN_STARTED", "PLAYER"], ["WITHDRAWN", "PLAYER"],
		["SENT_OUT", "PLAYER"], ["MOVE_USED", "FOE"], ["DAMAGE", "PLAYER"]])
	assert_eq([events[1].pokemon_name, events[1].party_index], ["Salamèche", 0])
	assert_eq([events[2].pokemon_name, events[2].party_index], ["Carapuce", 1])
	assert_eq(events[4].pokemon_name, "Carapuce", "l'adversaire vise le nouveau Pokémon")
	assert_eq(battle.get_player_side().active.pokemon, squirtle)
	assert_lt(squirtle.hp, squirtle.max_hp())
	assert_eq(charmander.hp, charmander.max_hp(), "le sortant n'est pas touché")
	assert_eq(battle.get_state(), Battle.State.CHOOSING)
	assert_eq(battle.get_turn(), 1)
	assert_eq(battle.get_player_side().party.get_all(), [charmander, squirtle] as Array[Pokemon],
		"l'ordre de l'équipe ne change pas")


func test_switch_is_allowed_against_a_trainer_and_without_rules() -> void:
	var trainer := _battle([_mon(&"charmander", 5), _mon(&"squirtle", 5)],
		[_mon(&"pidgey", 3)], [], BattleRules.for_trainer(TrainerData.new()), "Gamin")
	assert_true(trainer.is_legal(BattleAction.switch_to(1)))
	var no_rules := _battle([_mon(&"charmander", 5), _mon(&"squirtle", 5)],
		[_mon(&"pidgey", 3)], [], null, "Le Rival")
	assert_true(no_rules.is_legal(BattleAction.switch_to(1)))


# --- Interdits ----------------------------------------------------------------------------

func test_switch_to_the_active_a_fainted_or_a_missing_pokemon_is_refused() -> void:
	var squirtle := _mon(&"squirtle", 5)
	var battle := _battle([_mon(&"charmander", 5), squirtle, _mon(&"bulbasaur", 5)],
		[_mon(&"pidgey", 3)], [])
	squirtle.hp = 0
	assert_eq(battle.check_switch(0), Battle.SwitchCheck.ACTIVE)
	assert_eq(battle.check_switch(1), Battle.SwitchCheck.FAINTED)
	assert_eq(battle.check_switch(2), Battle.SwitchCheck.OK)
	assert_eq(battle.check_switch(3), Battle.SwitchCheck.NO_POKEMON)
	assert_eq(battle.check_switch(-1), Battle.SwitchCheck.NO_POKEMON)
	for index: int in [0, 1, 3]:
		assert_false(battle.is_legal(BattleAction.switch_to(index)), "place %d" % index)
	assert_eq(battle.submit(BattleAction.switch_to(0)).size(), 0)
	assert_push_error("action refusée")
	assert_eq(battle.get_turn(), 0)


# --- Niveaux de statistiques --------------------------------------------------------------

func test_stat_stages_and_seed_of_the_outgoing_pokemon_are_reset() -> void:
	var charmander := _mon(&"charmander", 5)
	var battle := _battle([charmander, _mon(&"squirtle", 5)], [_mon(&"pidgey", 3)],
		[1, 50, 2, 16, 1, 50, 2, 16])
	var before := battle.get_player_side().active
	before.change_stage(&"atk", 2)
	before.change_stage(&"def", -1)
	before.seed_fraction = 0.125
	battle.submit(BattleAction.switch_to(1))
	assert_eq(battle.get_player_side().active.get_stage(&"atk"), 0)
	battle.submit(BattleAction.switch_to(0))
	assert_eq(_rng.remaining(), 0)
	var back := battle.get_player_side().active
	assert_eq(back.pokemon, charmander)
	assert_ne(back, before, "un nouveau Battler à chaque entrée")
	for stat: StringName in [&"atk", &"def"]:
		assert_eq(back.get_stage(stat), 0, stat)
	assert_false(back.is_seeded())


# --- K.O. du joueur : il choisit ----------------------------------------------------------

func test_player_knock_out_waits_for_the_player_choice() -> void:
	var charmander := _mon(&"charmander", 5)
	var squirtle := _mon(&"squirtle", 5)
	var bulbasaur := _mon(&"bulbasaur", 5)
	var battle := _battle([charmander, squirtle, bulbasaur], [_mon(&"pidgey", 3)],
		[1, 50, 2, 16])
	charmander.hp = 1
	battle.get_player_side().active.change_stage(&"spe", -6)
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_kinds(events).slice(-2), [["DAMAGE", "PLAYER"], ["FAINTED", "PLAYER"]])
	assert_true(_of_kind(events, K.SENT_OUT).is_empty(), "pas d'envoi automatique")
	assert_eq(battle.get_state(), Battle.State.REPLACING)
	assert_true(battle.needs_replacement())
	# Ni capacité, ni changement par un tour, ni fuite : seulement replace().
	assert_false(battle.is_legal(BattleAction.move(0)))
	assert_false(battle.is_legal(BattleAction.switch_to(2)))
	assert_false(battle.is_legal(BattleAction.run()))
	assert_false(battle.can_flee())
	assert_eq(battle.replace(0).size(), 0, "K.O. refusé")
	assert_push_error("remplacement refusé")
	var sent := battle.replace(2)
	assert_eq(_rng.remaining(), 0, "le remplacement ne tire rien")
	assert_eq(_kinds(sent), [["SENT_OUT", "PLAYER"]])
	assert_eq([sent[0].pokemon_name, sent[0].party_index], ["Bulbizarre", 2])
	assert_eq(battle.get_player_side().active.pokemon, bulbasaur)
	assert_eq(battle.get_state(), Battle.State.CHOOSING)
	assert_false(battle.needs_replacement())
	assert_eq(battle.get_turn(), 1, "le remplacement n'est pas un tour")
	assert_eq(battle.replace(1).size(), 0, "plus de remplacement attendu")
	assert_push_error("remplacement refusé")


func test_last_pokemon_knocked_out_ends_the_battle_without_replacement() -> void:
	var charmander := _mon(&"charmander", 5)
	var squirtle := _mon(&"squirtle", 5)
	squirtle.hp = 0
	var battle := _battle([charmander, squirtle], [_mon(&"pidgey", 3)], [1, 50, 2, 16])
	charmander.hp = 1
	battle.get_player_side().active.change_stage(&"spe", -6)
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_kinds(events).slice(-2), [["FAINTED", "PLAYER"], ["BATTLE_ENDED", "PLAYER"]])
	assert_eq(battle.get_state(), Battle.State.OVER)
	assert_eq(battle.get_outcome(), Battle.Outcome.LOSS)


func test_both_knocked_out_the_foe_sends_first_then_the_player_chooses() -> void:
	# Lutte : Roucool K.O., puis le contrecoup met Salamèche K.O. ; l'adversaire envoie son
	# premier valide, le joueur choisit le sien.
	var charmander := _mon(&"charmander", 5)
	var squirtle := _mon(&"squirtle", 5)
	var battle := _battle([charmander, squirtle], [_mon(&"pidgey", 3), _mon(&"rattata", 3)],
		[1, 2, 16], BattleRules.for_trainer(TrainerData.new()), "Gamin")
	for slot: MoveSlot in charmander.moves:
		slot.pp = 0
	charmander.hp = 1
	battle.get_foe_side().active.pokemon.hp = 1
	var events := battle.submit(BattleAction.move(BattleAction.STRUGGLE))
	assert_eq(_kinds(events).slice(-2), [["FAINTED", "PLAYER"], ["SENT_OUT", "FOE"]])
	assert_eq(battle.get_state(), Battle.State.REPLACING)
	assert_eq(battle.get_participants(), [] as Array[Pokemon])
	battle.replace(1)
	assert_eq(battle.get_participants(), [squirtle] as Array[Pokemon])


# --- XP ---------------------------------------------------------------------------------

func test_exp_is_shared_between_the_standing_participants_after_a_switch() -> void:
	# Salamèche commence, Carapuce entre puis met Roucool K.O. : 21 XP en deux parts égales
	# (le reste au premier, ExpCalc.split).
	var charmander := _mon(&"charmander", 5)
	var squirtle := _mon(&"squirtle", 5)
	var battle := _battle([charmander, squirtle], [_mon(&"pidgey", 3)],
		[1, 50, 2, 16, 1, 50, 2, 16])
	battle.submit(BattleAction.switch_to(1))
	assert_eq(battle.get_participants(), [charmander, squirtle] as Array[Pokemon])
	battle.get_foe_side().active.pokemon.hp = 1
	battle.get_foe_side().active.change_stage(&"spe", -6)
	var events := battle.submit(BattleAction.move(0))
	var slices := _of_kind(events, K.EXP_GAINED)
	assert_eq(slices.size(), 2)
	assert_eq([slices[0].pokemon_name, slices[0].amount, slices[0].party_index],
		["Salamèche", 11, 0])
	assert_eq([slices[1].pokemon_name, slices[1].amount, slices[1].party_index],
		["Carapuce", 10, 1])
	assert_eq(charmander.experience, 135 + 11)
	assert_eq(squirtle.experience, 135 + 10)
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)


# --- Vues, phrases et mise en scène ---------------------------------------------------------

func test_team_action_needs_at_least_two_pokemon() -> void:
	var wild := BattleViews.WILD_BATTLE_ACTIONS
	assert_false(BattleViews.with_team(wild, 1).has(&"team"), "seul : ÉQUIPE atténué")
	assert_true(BattleViews.with_team(wild, 2)[&"team"])
	assert_false(wild.has(&"team"), "l'original ne change pas")
	var trainer := BattleViews.with_team(BattleViews.trainer_actions(null), 3)
	assert_true(trainer[&"team"])


func test_party_views_follow_check_switch_with_reasons() -> void:
	var texts := BattleText.new()
	assert_true(texts.load_file())
	var squirtle := _mon(&"squirtle", 5)
	var battle := _battle([_mon(&"charmander", 5), squirtle, _mon(&"bulbasaur", 6)],
		[_mon(&"pidgey", 3)], [])
	squirtle.hp = 0
	var views := BattleViews.party(battle, _data, texts)
	assert_eq(views.size(), 3)
	assert_eq([views[0].display_name, views[0].active, views[0].can_send, views[0].reason],
		["Salamèche", true, false, "Déjà au combat"])
	assert_eq([views[1].status_text, views[1].can_send, views[1].reason],
		["K.O.", false, "Ne peut plus combattre"])
	assert_eq([views[2].party_index, views[2].level, views[2].can_send, views[2].reason],
		[2, 6, true, ""])
	assert_eq(views[2].type_ids, [&"grass", &"poison"] as Array[StringName])
	assert_eq(Array(views[2].type_names), ["Plante", "Poison"])
	assert_true(views[2].is_valid())


func test_withdrawn_is_a_line_then_a_withdraw_beat() -> void:
	var texts := BattleText.new()
	assert_true(texts.load_file())
	var battle := _battle([_mon(&"charmander", 5), _mon(&"squirtle", 5)],
		[_mon(&"pidgey", 3)], [1, 50, 2, 16])
	var events := battle.submit(BattleAction.switch_to(1))
	var withdrawn := events[1]
	assert_eq(texts.lines(withdrawn, _data), PackedStringArray(["Reviens, Salamèche !"]))
	var beats := BattlePlayback.beats(withdrawn, texts, _data)
	assert_eq(beats.size(), 2)
	assert_eq([beats[0].kind, beats[0].text], [BattleBeat.Kind.MESSAGE, "Reviens, Salamèche !"])
	assert_eq(beats[1].kind, BattleBeat.Kind.WITHDRAW)
	var sent := BattlePlayback.beats(events[2], texts, _data)
	assert_eq(sent[0].text, "En avant, Carapuce !", "le message d'envoi existant")
	assert_eq(sent[1].kind, BattleBeat.Kind.SEND_OUT)
	for id: StringName in [&"switch_reason_active", &"switch_reason_fainted",
			&"replace_prompt"]:
		assert_false(texts.get_template(id).is_empty(), id)
