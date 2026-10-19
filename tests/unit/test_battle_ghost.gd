extends GutTest
## Mode SPECTRE dans le moteur (jalon 19 T11, `jalon-19.md` §2.3, dossier 22 §6.2 et §16 n° 3) :
## la peur remplace toute capacité (ni PP, ni dégât, ni tirage), le sommeil et le gel gardent
## leur message, le SPECTRE ne fait que parler, la fuite réussit toujours, les Balls sont
## refusées, les soins et le changement restent permis, le poison du joueur continue, aucune XP,
## et tout événement adverse est masqué (pseudo-espèce, niveau 0).
##
## Aléatoire : [code]ScriptedRng[/code] à file vide (tout tirage imprévu échoue le test et
## [member ScriptedRng.calls] compte le rang) ; IV à 0 par une file fixe ; une graine fixe pour
## le test de l'état du [GameRng].

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE
const FOE_SPECIES := &"gastly"
const FOE_LEVEL := 20

var _data: PokemonData
var _items: ItemLibrary
var _rng: ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func _pokemon(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))


## Combat SPECTRE : [param mine] (puis [param bench]) contre un Fantominus N20, file de tirages
## [param draws] (vide : aucun tirage permis).
func _ghost_battle(mine: Pokemon, draws: Array[int] = [], bench: Array[Pokemon] = [],
		rng: GameRng = null) -> Battle:
	_rng = ScriptedRng.new(draws)
	var party := Party.new()
	party.add(mine)
	for other: Pokemon in bench:
		party.add(other)
	var foes := Party.new()
	foes.add(_pokemon(FOE_SPECIES, FOE_LEVEL))
	var battle := Battle.new(BattleSide.new(party, true), BattleSide.new(foes, false, ""),
		_data, rng if rng != null else _rng, BattleRules.for_ghost(_items))
	return battle


func _kinds(events: Array[BattleEvent]) -> Array[BattleEvent.Kind]:
	var kinds: Array[BattleEvent.Kind] = []
	for event: BattleEvent in events:
		kinds.append(event.kind)
	return kinds


func _has_kind(events: Array[BattleEvent], kind: BattleEvent.Kind) -> bool:
	return _kinds(events).has(kind)


# --- Règles ------------------------------------------------------------------------------

func test_ghost_rules() -> void:
	var rules := BattleRules.for_ghost(_items)
	assert_true(rules.ghost)
	assert_true(rules.flee_always)
	assert_true(rules.wild)
	assert_true(rules.can_flee)
	assert_false(rules.gives_exp, "aucune XP")
	assert_true(rules.allow_balls, "le Sac s'ouvre : c'est le refus qui parle")
	assert_true(rules.allow_heal_items)
	assert_eq(rules.items, _items)


func test_wild_and_trainer_rules_are_unchanged() -> void:
	for rules: BattleRules in [BattleRules.for_wild(_items), BattleRules.for_trainer(null, _items)]:
		assert_false(rules.ghost)
		assert_false(rules.flee_always)


func test_request_follows_the_encounter() -> void:
	var encounter := WildEncounter.new(FOE_SPECIES, FOE_LEVEL, &"t")
	var normal := BattleRequest.wild(encounter, _data, GameRng.new(1), Vector2i.ZERO, _items)
	assert_false(normal.rules.ghost, "sans SPECTRE : règles sauvages ordinaires")
	assert_true(normal.rules.gives_exp)
	encounter.ghost = true
	var ghost := BattleRequest.wild(encounter, _data, GameRng.new(1), Vector2i.ZERO, _items)
	assert_true(ghost.rules.ghost)
	assert_true(ghost.rules.flee_always)
	assert_eq(ghost.foe_party.get_lead().species_id, FOE_SPECIES, "l'espèce réelle reste dedans")


# --- La peur -----------------------------------------------------------------------------

func test_every_move_gives_scared_without_pp_damage_or_draw() -> void:
	var mine := _pokemon(&"charmander", 10)
	var battle := _ghost_battle(mine)
	battle.start()
	var foe := battle.get_foe_side().active.pokemon
	for slot: int in battle.get_usable_moves():
		var pp_before := mine.moves[slot].pp
		var foe_hp := foe.hp
		var events := battle.submit(BattleAction.move(slot))
		assert_true(_has_kind(events, K.GHOST_SCARED), "capacité %d : la peur" % slot)
		assert_false(_has_kind(events, K.MOVE_USED), "rien n'est lancé")
		assert_false(_has_kind(events, K.DAMAGE), "aucun dégât")
		assert_eq(mine.moves[slot].pp, pp_before, "aucun PP dépensé")
		assert_eq(foe.hp, foe_hp)
	assert_eq(_rng.calls, 0, "aucun tirage consommé")
	assert_eq(battle.get_state(), Battle.State.CHOOSING)


func test_struggle_is_scared_too() -> void:
	var mine := _pokemon(&"charmander", 10)
	for slot: MoveSlot in mine.moves:
		slot.pp = 0
	var battle := _ghost_battle(mine)
	battle.start()
	var events := battle.submit(BattleAction.move(BattleAction.STRUGGLE))
	assert_true(_has_kind(events, K.GHOST_SCARED))
	assert_false(_has_kind(events, K.RECOIL), "aucun contrecoup de Lutte")
	assert_eq(_rng.calls, 0)


func test_scared_comes_first_then_the_ghost_speaks() -> void:
	var battle := _ghost_battle(_pokemon(&"charmander", 10))
	battle.start()
	var kinds := _kinds(battle.submit(BattleAction.move(0)))
	assert_eq(kinds, [K.TURN_STARTED, K.GHOST_SCARED, K.GHOST_SPOKE] as Array[BattleEvent.Kind])


func test_game_rng_state_is_untouched_with_a_fixed_seed() -> void:
	var rng := GameRng.new(4242)
	var battle := _ghost_battle(_pokemon(&"charmander", 10), [], [], rng)
	battle.start()
	var before := rng.to_dict()
	for i: int in 5:
		battle.submit(BattleAction.move(0))
	assert_eq(rng.to_dict(), before, "même rang après cinq tours de peur")


func test_sleep_keeps_its_message_then_wakes_into_fear() -> void:
	var mine := _pokemon(&"charmander", 10)
	mine.status = StatusRules.SLEEP
	mine.status_turns = 1
	var battle := _ghost_battle(mine)
	battle.start()
	var asleep := battle.submit(BattleAction.move(0))
	assert_true(_has_kind(asleep, K.STATUS_PREVENTED), "il dort")
	assert_false(_has_kind(asleep, K.GHOST_SCARED), "jamais la peur pendant le sommeil")
	for event: BattleEvent in asleep:
		if event.kind == K.STATUS_PREVENTED:
			assert_eq(event.status, StatusRules.SLEEP)
	var woke := _kinds(battle.submit(BattleAction.move(0)))
	assert_lt(woke.find(K.STATUS_ENDED), woke.find(K.GHOST_SCARED), "réveil, puis la peur")
	assert_ne(woke.find(K.STATUS_ENDED), -1)
	assert_eq(_rng.calls, 0, "le sommeil ne tire rien")


func test_freeze_keeps_its_message_then_thaws_into_fear() -> void:
	var mine := _pokemon(&"charmander", 10)
	mine.status = StatusRules.FREEZE
	var battle := _ghost_battle(mine, [100, 1])
	battle.start()
	var frozen := battle.submit(BattleAction.move(0))
	assert_true(_has_kind(frozen, K.STATUS_PREVENTED), "gelé")
	assert_false(_has_kind(frozen, K.GHOST_SCARED))
	var thawed := _kinds(battle.submit(BattleAction.move(0)))
	assert_ne(thawed.find(K.STATUS_ENDED), -1, "dégel")
	assert_lt(thawed.find(K.STATUS_ENDED), thawed.find(K.GHOST_SCARED), "puis la peur")
	assert_eq(_rng.remaining(), 0, "un seul tirage de dégel par tour")


func test_paralysis_gives_fear_without_a_paralysis_draw() -> void:
	var mine := _pokemon(&"charmander", 10)
	mine.status = StatusRules.PARALYSIS
	var battle := _ghost_battle(mine)
	battle.start()
	var events := battle.submit(BattleAction.move(0))
	assert_true(_has_kind(events, K.GHOST_SCARED))
	assert_false(_has_kind(events, K.STATUS_PREVENTED))
	assert_eq(_rng.calls, 0, "aucun tirage de paralysie")


func test_confusion_neither_hurts_nor_counts_down() -> void:
	var battle := _ghost_battle(_pokemon(&"charmander", 10))
	battle.start()
	var me := battle.get_player_side().active
	me.confusion_turns = 3
	var events := battle.submit(BattleAction.move(0))
	assert_true(_has_kind(events, K.GHOST_SCARED))
	assert_false(_has_kind(events, K.HURT_ITSELF))
	assert_false(_has_kind(events, K.CONFUSION_CHECK))
	assert_eq(me.confusion_turns, 3, "aucun décompte")
	assert_eq(_rng.calls, 0)


# --- Le SPECTRE --------------------------------------------------------------------------

func test_ghost_only_speaks() -> void:
	var mine := _pokemon(&"charmander", 10)
	var battle := _ghost_battle(mine)
	battle.start()
	var me := battle.get_player_side().active
	var hp := mine.hp
	for i: int in 4:
		var events := battle.submit(BattleAction.move(0))
		var spoke := 0
		for event: BattleEvent in events:
			if event.side == F and event.kind != K.GHOST_SPOKE:
				fail_test("le SPECTRE ne fait que parler : %s" % K.find_key(event.kind))
			if event.kind == K.GHOST_SPOKE:
				spoke += 1
				assert_eq(event.side, F)
		assert_eq(spoke, 1)
	assert_eq(mine.hp, hp, "PV inchangés")
	assert_eq(mine.status, StatusRules.NONE, "statut inchangé")
	for stat: StringName in MoveEffect.STAGE_STATS:
		assert_eq(me.get_stage(stat), 0, "stade %s inchangé" % stat)


func test_every_foe_event_is_disguised() -> void:
	var battle := _ghost_battle(_pokemon(&"charmander", 10), [], [_pokemon(&"pidgey", 8)])
	var events := battle.start()
	events.append_array(battle.submit(BattleAction.move(0)))
	events.append_array(battle.submit(BattleAction.switch_to(1)))
	events.append_array(battle.submit(BattleAction.run()))
	var foe_events := 0
	for event: BattleEvent in events:
		assert_ne(event.species_id, FOE_SPECIES, "jamais l'espèce réelle (%s)"
			% K.find_key(event.kind))
		if event.side != F:
			assert_false(event.disguised, "le camp du joueur n'est jamais masqué")
			continue
		foe_events += 1
		assert_true(event.disguised, K.find_key(event.kind))
		assert_eq(event.species_id, GhostDisguise.SPECIES)
		assert_eq(event.level, 0)
		assert_eq(event.gender, Pokemon.Gender.NONE)
		assert_true(GhostDisguise.is_masked(event))
	assert_gte(foe_events, 4, "début, envoi, deux paroles")


# --- Fuite, Sac, changement ----------------------------------------------------------------

func test_flee_always_succeeds_whatever_the_speeds() -> void:
	for attempt: int in 50:
		var mine := _pokemon(&"charmander", 5)
		mine.stats[&"spe"] = 1
		var battle := _ghost_battle(mine)
		battle.start()
		battle.get_foe_side().active.pokemon.stats[&"spe"] = 200
		var events := battle.submit(BattleAction.run())
		assert_false(_has_kind(events, K.FLEE_FAILED), "essai %d" % attempt)
		assert_true(_has_kind(events, K.FLED))
		assert_eq(battle.get_outcome(), Battle.Outcome.FLED)
		assert_eq(battle.get_turn(), 1, "au premier tour")
		assert_eq(_rng.calls, 0, "sans tirage de fuite")


func test_balls_are_refused_heals_and_switches_are_allowed() -> void:
	var mine := _pokemon(&"charmander", 10)
	mine.hp = 5
	var battle := _ghost_battle(mine, [], [_pokemon(&"pidgey", 8)])
	battle.start()
	assert_true(battle.refuses_balls())
	assert_true(battle.can_use_balls(), "le Sac s'ouvre")
	assert_false(battle.is_legal(BattleAction.ball(&"poke_ball")), "Ball illégale")
	assert_true(battle.is_legal(BattleAction.heal(&"potion", 0)), "soin permis")
	assert_true(battle.is_legal(BattleAction.switch_to(1)), "changement permis")
	assert_false(battle.is_legal(BattleAction.speak()), "parler n'est pas une action du joueur")
	var healed := battle.submit(BattleAction.heal(&"potion", 0))
	assert_true(_has_kind(healed, K.ITEM_USED))
	assert_eq(_kinds(healed).back(), K.GHOST_SPOKE, "le SPECTRE parle ensuite")
	var switched := _kinds(battle.submit(BattleAction.switch_to(1)))
	assert_eq(switched, [K.TURN_STARTED, K.WITHDRAWN, K.SENT_OUT, K.GHOST_SPOKE]
		as Array[BattleEvent.Kind])
	assert_eq(_rng.calls, 0)


func test_wild_battle_still_accepts_balls() -> void:
	var party := Party.new()
	party.add(_pokemon(&"charmander", 10))
	var foes := Party.new()
	foes.add(_pokemon(FOE_SPECIES, FOE_LEVEL))
	var battle := Battle.new(BattleSide.new(party, true), BattleSide.new(foes, false, ""), _data,
		ScriptedRng.new([]), BattleRules.for_wild(_items))
	battle.start()
	assert_false(battle.refuses_balls())
	assert_true(battle.is_legal(BattleAction.ball(&"poke_ball")))


# --- Poison, fin du combat -----------------------------------------------------------------

func test_player_poison_still_hurts_and_can_lose() -> void:
	var mine := _pokemon(&"charmander", 10)
	mine.status = StatusRules.POISON
	var tick := StatusRules.end_turn_damage(mine)
	mine.hp = tick + 1
	var battle := _ghost_battle(mine)
	battle.start()
	var first := battle.submit(BattleAction.move(0))
	assert_true(_has_kind(first, K.STATUS_DAMAGED), "dégâts de fin de tour")
	assert_eq(mine.hp, 1)
	assert_eq(battle.get_state(), Battle.State.CHOOSING)
	var last := battle.submit(BattleAction.move(0))
	assert_true(_has_kind(last, K.FAINTED))
	assert_eq(battle.get_outcome(), Battle.Outcome.LOSS, "K.O. par le poison : défaite")
	assert_eq(_rng.calls, 0)


func test_no_exp_and_no_coins() -> void:
	var mine := _pokemon(&"charmander", 10)
	var exp := mine.experience
	var battle := _ghost_battle(mine)
	var events := battle.start()
	for i: int in 3:
		events.append_array(battle.submit(BattleAction.move(0)))
	events.append_array(battle.submit(BattleAction.run()))
	assert_false(_has_kind(events, K.EXP_GAINED))
	assert_false(_has_kind(events, K.LEVEL_UP))
	assert_eq(mine.experience, exp)
	assert_eq(battle.get_pay_day_coins(), 0)


# --- Textes --------------------------------------------------------------------------------

func test_ghost_lines_are_the_validated_texts() -> void:
	var texts := BattleText.new()
	texts.load_file()
	assert_eq(texts.get_errors().size(), 0)
	var battle := _ghost_battle(_pokemon(&"charmander", 10))
	var lines: Array[String] = []
	for event: BattleEvent in battle.start() + battle.submit(BattleAction.move(0)):
		lines.append_array(Array(texts.lines(event, _data)))
	assert_has(lines, "Un SPECTRE apparaît !")
	assert_has(lines, "Impossible d'identifier le SPECTRE…")
	assert_has(lines, "Salamèche a trop peur pour bouger !")
	assert_has(lines, "SPECTRE : Va-t'en… Va-t'en…")
	assert_false(lines.has("Un Fantominus sauvage apparaît !"))
	assert_eq(texts.get_template(&"ghost_name"), "SPECTRE")
	assert_eq(texts.get_template(&"ghost_ball_refused"),
		"Pas question de lancer une Ball sur… ça. Elle passerait au travers.")


func test_card_hides_the_level() -> void:
	var battle := _ghost_battle(_pokemon(&"charmander", 10))
	for event: BattleEvent in battle.start():
		if event.kind == K.SENT_OUT and event.side == F:
			var view := BattleViews.card(event)
			assert_true(view.level_hidden)
			assert_true(view.is_valid(), "une carte masquée reste affichable")
		elif event.kind == K.SENT_OUT:
			assert_false(BattleViews.card(event).level_hidden)


func test_ghost_image_is_the_silhouette() -> void:
	var art := BattleArt.new()
	art.setup(_data, null)
	var front := art.image(GhostDisguise.SPECIES, false)
	assert_not_null(front["texture"], "silhouette")
	assert_eq((front["texture"] as Texture2D).resource_path, GhostDisguise.TEXTURE_PATH)
	assert_true(front["official"], "peinte : filtre linéaire")
	assert_null(art.image(GhostDisguise.SPECIES, true)["texture"], "pas de dos")
