extends GutTest
## BattlePlayback et BattleBeat (jalon-04.md §14.2) : ordre des temps de mise en scène pour
## chaque sorte d'événement, phrases de BattleText, premier combat du rival rejoué en
## entier (aucun message générique de fin, décision de Kevin n° 15).

var _data: PokemonData
var _texts: BattleText
var _trainers: TrainerLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_texts = BattleText.new()
	_texts.load_file()
	_trainers = TrainerLibrary.new(_data)
	_trainers.load_dir()


func _event(kind: BattleEvent.Kind, side: BattleEvent.SideId, name: String) -> BattleEvent:
	var event := BattleEvent.new(kind, side)
	event.pokemon_name = name
	event.level = 5
	event.max_hp = 20
	event.hp = 20
	return event


func _kinds(beats: Array[BattleBeat]) -> Array[BattleBeat.Kind]:
	var kinds: Array[BattleBeat.Kind] = []
	for beat: BattleBeat in beats:
		kinds.append(beat.kind)
	return kinds


func _messages(beats: Array[BattleBeat]) -> Array[String]:
	var texts: Array[String] = []
	for beat: BattleBeat in beats:
		if beat.kind == BattleBeat.Kind.MESSAGE:
			texts.append(beat.text)
	return texts


func test_sent_out_foe_message_then_the_pokemon() -> void:
	var event := _event(BattleEvent.Kind.SENT_OUT, BattleEvent.SideId.FOE, "Carapuce")
	event.trainer_name = "Le Rival"
	var beats := BattlePlayback.beats(event, _texts, _data)
	assert_eq(_kinds(beats), [BattleBeat.Kind.MESSAGE, BattleBeat.Kind.SEND_OUT]
		as Array[BattleBeat.Kind])
	assert_eq(beats[0].text, "Le Rival envoie Carapuce !")
	assert_eq(beats[1].side, BattleEvent.SideId.FOE)
	assert_same(beats[1].event, event)


func test_move_used_message_then_the_move_with_its_category() -> void:
	var event := _event(BattleEvent.Kind.MOVE_USED, BattleEvent.SideId.FOE, "Carapuce")
	event.move_id = &"tail_whip"
	var beats := BattlePlayback.beats(event, _texts, _data)
	assert_eq(_kinds(beats), [BattleBeat.Kind.MESSAGE, BattleBeat.Kind.MOVE]
		as Array[BattleBeat.Kind])
	assert_eq(beats[0].text, "Carapuce utilise Mimi-Queue !")
	assert_eq(beats[1].category, MoveData.Category.STATUS)
	event.move_id = &"scratch"
	assert_eq(BattlePlayback.beats(event, _texts, _data)[1].category,
		MoveData.Category.PHYSICAL)


func test_damage_hit_and_bar_first_then_critical_and_effectiveness() -> void:
	var event := _event(BattleEvent.Kind.DAMAGE, BattleEvent.SideId.FOE, "Salamèche")
	event.amount = 8
	event.hp = 12
	event.critical = true
	event.effectiveness = 2.0
	var beats := BattlePlayback.beats(event, _texts, _data)
	assert_eq(_kinds(beats), [BattleBeat.Kind.DAMAGE, BattleBeat.Kind.MESSAGE,
		BattleBeat.Kind.MESSAGE] as Array[BattleBeat.Kind])
	assert_eq(_messages(beats), ["Coup critique !", "C'est super efficace !"]
		as Array[String])
	assert_eq(beats[0].event.hp, 12, "PV d'après, lus dans l'événement")
	var plain := _event(BattleEvent.Kind.DAMAGE, BattleEvent.SideId.PLAYER, "Salamèche")
	assert_eq(_kinds(BattlePlayback.beats(plain, _texts, _data)),
		[BattleBeat.Kind.DAMAGE] as Array[BattleBeat.Kind], "coup normal : aucun message")


func test_recoil_is_a_damage_beat_then_its_message() -> void:
	var event := _event(BattleEvent.Kind.RECOIL, BattleEvent.SideId.PLAYER, "Salamèche")
	event.amount = 5
	var beats := BattlePlayback.beats(event, _texts, _data)
	assert_eq(_kinds(beats), [BattleBeat.Kind.DAMAGE, BattleBeat.Kind.MESSAGE]
		as Array[BattleBeat.Kind])
	assert_eq(beats[1].text, "Salamèche est blessé par le contrecoup !")


func test_stat_changed_effect_then_message_and_unchanged_message_only() -> void:
	var event := _event(BattleEvent.Kind.STAT_CHANGED, BattleEvent.SideId.PLAYER, "Salamèche")
	event.stat = &"def"
	event.stages = -1
	var beats := BattlePlayback.beats(event, _texts, _data)
	assert_eq(_kinds(beats), [BattleBeat.Kind.STAT, BattleBeat.Kind.MESSAGE]
		as Array[BattleBeat.Kind])
	assert_eq(beats[1].text, "La Défense de Salamèche baisse !")
	event.kind = BattleEvent.Kind.STAT_UNCHANGED
	assert_eq(_kinds(BattlePlayback.beats(event, _texts, _data)),
		[BattleBeat.Kind.MESSAGE] as Array[BattleBeat.Kind])


func test_fainted_then_message() -> void:
	var event := _event(BattleEvent.Kind.FAINTED, BattleEvent.SideId.FOE, "Carapuce")
	event.hp = 0
	var beats := BattlePlayback.beats(event, _texts, _data)
	assert_eq(_kinds(beats), [BattleBeat.Kind.FAINT, BattleBeat.Kind.MESSAGE]
		as Array[BattleBeat.Kind])
	assert_eq(beats[1].text, "Carapuce est K.O. !")


func test_missed_no_effect_and_turn_started() -> void:
	var missed := _event(BattleEvent.Kind.MOVE_MISSED, BattleEvent.SideId.FOE, "Carapuce")
	assert_eq(_messages(BattlePlayback.beats(missed, _texts, _data)),
		["Carapuce rate son attaque !"] as Array[String])
	var turn := _event(BattleEvent.Kind.TURN_STARTED, BattleEvent.SideId.PLAYER, "")
	assert_eq(BattlePlayback.beats(turn, _texts, _data).size(), 0, "rien à jouer")


func test_battle_ended_depends_on_the_trainer_end_message() -> void:
	var rival := _trainers.get_trainer(&"rival_lab")
	var event := _event(BattleEvent.Kind.BATTLE_ENDED, BattleEvent.SideId.PLAYER, "")
	event.trainer_name = "Le Rival"
	event.outcome = Battle.Outcome.WIN
	assert_eq(BattlePlayback.beats(event, _texts, _data, rival).size(), 0,
		"premier combat du rival : pas de message générique de fin")
	assert_eq(_messages(BattlePlayback.beats(event, _texts, _data)),
		["Tu as battu Le Rival !"] as Array[String], "autres dresseurs")


func test_battle_started_depends_on_the_trainer_start_message() -> void:
	var rival := _trainers.get_trainer(&"rival_lab")
	assert_false(rival.start_message, "décision n° 17 : pas de « veut se battre »")
	var event := _event(BattleEvent.Kind.BATTLE_STARTED, BattleEvent.SideId.FOE, "")
	event.trainer_name = "Le Rival"
	assert_eq(BattlePlayback.beats(event, _texts, _data, rival).size(), 0,
		"premier combat du rival : pas de message de début")
	assert_eq(_messages(BattlePlayback.beats(event, _texts, _data)),
		["Le Rival veut se battre !"] as Array[String], "autres dresseurs")


func test_big_hit() -> void:
	var event := _event(BattleEvent.Kind.DAMAGE, BattleEvent.SideId.FOE, "Carapuce")
	event.max_hp = 20
	event.amount = 5
	var beat := BattleBeat.new(BattleBeat.Kind.DAMAGE, event)
	assert_false(beat.is_big_hit(0.25), "exactement 25 % : pas un gros coup")
	event.amount = 6
	assert_true(beat.is_big_hit(0.25))
	assert_false(BattleBeat.new(BattleBeat.Kind.MESSAGE, event).is_big_hit(0.25))


## Le premier combat du rival, joué en entier avec le moteur (graine fixe, le joueur
## choisit toujours sa 1re capacité), puis découpé : chaque événement joué a ses temps,
## les PV de chaque temps DAMAGE sont ceux du moteur, la fin est muette.
func test_whole_rival_battle_for_each_starter() -> void:
	var rival := _trainers.get_trainer(&"rival_lab")
	for starter: StringName in [&"bulbasaur", &"charmander", &"squirtle"]:
		var rng := GameRng.new(7)
		var party := Party.new()
		party.add(PokemonFactory.create(_data, starter, 5, rng))
		var foes := _trainers.build_team(&"rival_lab", starter, rng)
		var battle := Battle.new(BattleSide.new(party, true),
			BattleSide.new(foes, false, rival.name, rival.make_ai()), _data, rng)
		var events := battle.start()
		while battle.get_state() == Battle.State.CHOOSING:
			events.append_array(battle.submit(BattleAction.move(0)))
		var beats := BattlePlayback.beats_for_log(events, _texts, _data, rival)
		var kinds := _kinds(beats)
		# Décision n° 17 (Q-K) : pas de « Le Rival veut se battre ! » (start_message faux).
		assert_eq(kinds.slice(0, 4), [BattleBeat.Kind.MESSAGE,
			BattleBeat.Kind.SEND_OUT, BattleBeat.Kind.MESSAGE, BattleBeat.Kind.SEND_OUT]
			as Array[BattleBeat.Kind], "%s : ouverture" % starter)
		assert_string_contains(beats[0].text, "Le Rival envoie ")
		assert_string_starts_with(beats[2].text, "En avant, ")
		var seen: Dictionary[BattleEvent, bool] = {}
		for beat: BattleBeat in beats:
			seen[beat.event] = true
			if beat.kind == BattleBeat.Kind.DAMAGE:
				assert_true(beat.event.kind in [BattleEvent.Kind.DAMAGE,
					BattleEvent.Kind.RECOIL])
		for event: BattleEvent in events:
			# BATTLE_STARTED muet aussi contre le rival (start_message faux, décision n° 17).
			var silent := event.kind in [BattleEvent.Kind.TURN_STARTED,
				BattleEvent.Kind.BATTLE_ENDED, BattleEvent.Kind.BATTLE_STARTED]
			assert_eq(seen.has(event), not silent,
				"%s : %s joué" % [starter, BattleEvent.Kind.find_key(event.kind)])
		assert_eq(beats[-1].kind, BattleBeat.Kind.MESSAGE)
		assert_string_ends_with(beats[-1].text, " est K.O. !", "%s : fin muette" % starter)


# --- Jalon 5C : XP, niveaux, apprentissage, Vampigraine ----------------------------------

## Demande n° 1 : ni l'XP ni le niveau n'ont de phrase pendant le combat (le bilan les raconte).
func test_exp_and_level_up_have_a_beat_only() -> void:
	var exp_event := _event(BattleEvent.Kind.EXP_GAINED, BattleEvent.SideId.PLAYER, "Salamèche")
	exp_event.amount = 21
	assert_eq(_kinds(BattlePlayback.beats(exp_event, _texts, _data)),
		[BattleBeat.Kind.EXP] as Array[BattleBeat.Kind], "aucune phrase")
	var level_event := _event(BattleEvent.Kind.LEVEL_UP, BattleEvent.SideId.PLAYER, "Salamèche")
	assert_eq(_kinds(BattlePlayback.beats(level_event, _texts, _data)),
		[BattleBeat.Kind.LEVEL] as Array[BattleBeat.Kind], "plus de « monte au niveau »")


func test_move_learned_is_a_message_and_forget_offer_is_a_message_then_a_choice() -> void:
	var learned := _event(BattleEvent.Kind.MOVE_LEARNED, BattleEvent.SideId.PLAYER, "Bulbizarre")
	learned.move_id = &"leech_seed"
	assert_eq(_messages(BattlePlayback.beats(learned, _texts, _data)),
		["Bulbizarre apprend Vampigraine !"] as Array[String])
	assert_eq(_kinds(BattlePlayback.beats(learned, _texts, _data)),
		[BattleBeat.Kind.MESSAGE] as Array[BattleBeat.Kind])
	var offered := _event(BattleEvent.Kind.MOVE_FORGET_OFFERED, BattleEvent.SideId.PLAYER,
		"Bulbizarre")
	offered.move_id = &"poison_powder"
	var beats := BattlePlayback.beats(offered, _texts, _data)
	assert_eq(_kinds(beats), [BattleBeat.Kind.MESSAGE, BattleBeat.Kind.FORGET]
		as Array[BattleBeat.Kind], "le message, puis le choix (lecture suspendue)")
	assert_eq(beats[0].text,
		"Bulbizarre veut apprendre Poudre Toxik, mais connaît déjà quatre capacités.")


func test_seeded_is_a_message_and_drained_is_both_bars_then_a_message() -> void:
	var seeded := _event(BattleEvent.Kind.SEEDED, BattleEvent.SideId.FOE, "Rattata")
	assert_eq(_messages(BattlePlayback.beats(seeded, _texts, _data)),
		["Une graine est plantée sur Rattata !"] as Array[String])
	var drained := _event(BattleEvent.Kind.DRAINED, BattleEvent.SideId.FOE, "Rattata")
	drained.healed = 2
	drained.healed_hp = 12
	var beats := BattlePlayback.beats(drained, _texts, _data)
	assert_eq(_kinds(beats), [BattleBeat.Kind.DRAIN, BattleBeat.Kind.MESSAGE]
		as Array[BattleBeat.Kind])
	assert_eq(beats[0].side, BattleEvent.SideId.FOE, "le Pokémon drainé")


func test_capture_events_become_throw_shakes_catch_and_release() -> void:
	var thrown := _event(BattleEvent.Kind.BALL_THROWN, BattleEvent.SideId.FOE, "Rattata")
	thrown.item_name = "Poké Ball"
	var beats := BattlePlayback.beats(thrown, _texts, _data)
	assert_eq(_kinds(beats), [BattleBeat.Kind.MESSAGE, BattleBeat.Kind.THROW]
		as Array[BattleBeat.Kind], "le message, puis le lancer")
	assert_eq(beats[0].text, "Tu lances une Poké Ball !")
	var shake := _event(BattleEvent.Kind.BALL_SHAKE, BattleEvent.SideId.FOE, "Rattata")
	shake.shake = 2
	assert_eq(_kinds(BattlePlayback.beats(shake, _texts, _data)),
		[BattleBeat.Kind.SHAKE] as Array[BattleBeat.Kind], "une secousse, sans phrase")
	var caught := _event(BattleEvent.Kind.CAUGHT, BattleEvent.SideId.FOE, "Rattata")
	assert_eq(_kinds(BattlePlayback.beats(caught, _texts, _data)),
		[BattleBeat.Kind.CATCH] as Array[BattleBeat.Kind], "l'éclat ; le texte est sur la carte")
	var freed := _event(BattleEvent.Kind.BROKE_FREE, BattleEvent.SideId.FOE, "Rattata")
	beats = BattlePlayback.beats(freed, _texts, _data)
	assert_eq(_kinds(beats), [BattleBeat.Kind.RELEASE, BattleBeat.Kind.MESSAGE]
		as Array[BattleBeat.Kind], "il ressort, puis le message")
	assert_eq(beats[1].text, "Oh non ! Il s'est libéré !")


func test_a_caught_battle_end_has_no_message() -> void:
	var ended := BattleEvent.new(BattleEvent.Kind.BATTLE_ENDED, BattleEvent.SideId.PLAYER)
	ended.outcome = Battle.Outcome.CAUGHT
	assert_eq(BattlePlayback.beats(ended, _texts, _data).size(), 0)


## Jalon 6 : le soin dit l'objet, remonte la barre, puis dit les PV rendus.
func test_item_used_is_a_message_the_heal_then_a_message() -> void:
	var used := _event(BattleEvent.Kind.ITEM_USED, BattleEvent.SideId.PLAYER, "Salamèche")
	used.item_id = &"potion"
	used.item_name = "Potion"
	used.amount = 13
	used.hp = 18
	used.max_hp = 18
	used.party_index = 1
	var beats := BattlePlayback.beats(used, _texts, _data)
	assert_eq(_kinds(beats), [BattleBeat.Kind.MESSAGE, BattleBeat.Kind.HEAL,
		BattleBeat.Kind.MESSAGE] as Array[BattleBeat.Kind])
	assert_eq(_messages(beats), ["Tu utilises Potion sur Salamèche.",
		"Salamèche récupère 13 PV."] as Array[String])
	assert_eq(beats[1].event.party_index, 1, "le directeur sait quel Pokémon remonte")
	assert_eq(beats[1].side, BattleEvent.SideId.PLAYER)
