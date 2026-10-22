extends GutTest
## Règle « uncatchable » et intro « révélation » côté moteur (jalon 21, `jalon-21.md` §2.5,
## §2.6 ; dossier 24 §5.3) : Balls refusées (le Sac s'ouvre, aucune Ball légale, aucun tirage),
## soins et changement permis, fuite par [FleeCalc] (elle peut échouer), XP gagnée ; mode
## SPECTRE inchangé ; la requête recopie la rencontre ; textes validés (§15.1).
## Le refus par le directeur (Ball non consommée, aucun tour) : test_battle_reveal.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const K := BattleEvent.Kind
const F := BattleEvent.SideId.FOE
const FOE := &"marowak"

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func _pokemon(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))


func _rules(uncatchable: bool = true) -> BattleRules:
	var rules := BattleRules.for_wild(_items)
	rules.uncatchable = uncatchable
	return rules


func _battle(mine: Pokemon, rng: GameRng, bench: Array[Pokemon] = [],
		rules: BattleRules = null) -> Battle:
	var party := Party.new()
	party.add(mine)
	for other: Pokemon in bench:
		party.add(other)
	var foes := Party.new()
	foes.add(_pokemon(FOE, 30))
	return Battle.new(BattleSide.new(party, true), BattleSide.new(foes, false, ""), _data, rng,
		rules if rules != null else _rules())


func _kinds(events: Array[BattleEvent]) -> Array[BattleEvent.Kind]:
	var kinds: Array[BattleEvent.Kind] = []
	for event: BattleEvent in events:
		kinds.append(event.kind)
	return kinds


# --- Règles et requête ---------------------------------------------------------------------

func test_rules_default_to_catchable() -> void:
	assert_false(BattleRules.new().uncatchable)
	assert_false(BattleRules.for_wild(_items).uncatchable)
	assert_false(BattleRules.for_ghost(_items).uncatchable)


func test_request_copies_reveal_and_uncatchable() -> void:
	var encounter := WildEncounter.new(FOE, 30, &"cutscene")
	assert_false(encounter.reveal, "faux par défaut")
	assert_false(encounter.uncatchable, "faux par défaut")
	var plain := BattleRequest.wild(encounter, _data, GameRng.new(1), Vector2i.ZERO, _items)
	assert_false(plain.reveal)
	assert_false(plain.rules.uncatchable)
	encounter.reveal = true
	encounter.uncatchable = true
	var request := BattleRequest.wild(encounter, _data, GameRng.new(1), Vector2i.ZERO, _items)
	assert_true(request.reveal)
	assert_true(request.rules.uncatchable)
	assert_false(request.rules.ghost)
	assert_true(request.rules.gives_exp, "XP gagnée")
	assert_false(request.rules.flee_always, "fuite par FleeCalc")


func test_reveal_is_never_set_on_a_ghost_request() -> void:
	var encounter := WildEncounter.new(FOE, 30, &"cutscene")
	encounter.ghost = true
	encounter.reveal = true
	var request := BattleRequest.wild(encounter, _data, GameRng.new(1), Vector2i.ZERO, _items)
	assert_false(request.reveal)
	assert_true(request.rules.ghost)


# --- Balls, soins, changement ------------------------------------------------------------

func test_balls_are_refused_without_any_draw() -> void:
	var rng := ScriptedRng.new([])
	var mine := _pokemon(&"charmander", 20)
	mine.hp = 5
	var battle := _battle(mine, rng, [_pokemon(&"pidgey", 8)])
	battle.start()
	assert_true(battle.refuses_balls())
	assert_true(battle.can_use_balls(), "le Sac s'ouvre")
	assert_false(battle.is_legal(BattleAction.ball(&"poke_ball")), "Ball illégale")
	assert_true(battle.is_legal(BattleAction.heal(&"potion", 0)), "soin permis")
	assert_true(battle.is_legal(BattleAction.switch_to(1)), "changement permis")
	assert_eq(battle.get_turn(), 0)
	assert_eq(rng.calls, 0, "aucun tirage")


func test_a_catchable_wild_battle_still_accepts_balls() -> void:
	var battle := _battle(_pokemon(&"charmander", 20), ScriptedRng.new([]), [], _rules(false))
	battle.start()
	assert_false(battle.refuses_balls())
	assert_true(battle.is_legal(BattleAction.ball(&"poke_ball")))


func test_ghost_mode_is_unchanged() -> void:
	var battle := _battle(_pokemon(&"charmander", 20), ScriptedRng.new([]), [],
		BattleRules.for_ghost(_items))
	battle.start()
	assert_true(battle.refuses_balls(), "SPECTRE : toujours refusées")
	assert_false(battle.get_rules().uncatchable)


# --- Fuite et XP ------------------------------------------------------------------------------

func test_flee_uses_flee_calc_and_can_fail() -> void:
	var mine := _pokemon(&"charmander", 20)
	mine.stats[&"spe"] = 1
	var battle := _battle(mine, GameRng.new(3))
	battle.start()
	battle.get_foe_side().active.pokemon.stats[&"spe"] = 250
	var events := battle.submit(BattleAction.run())
	assert_true(_kinds(events).has(K.FLEE_FAILED), "fuite ratée (F = 0)")
	assert_eq(battle.get_outcome(), Battle.Outcome.NONE)


func test_flee_succeeds_when_faster() -> void:
	var mine := _pokemon(&"charmander", 20)
	mine.stats[&"spe"] = 250
	var battle := _battle(mine, GameRng.new(3))
	battle.start()
	battle.get_foe_side().active.pokemon.stats[&"spe"] = 1
	battle.submit(BattleAction.run())
	assert_eq(battle.get_outcome(), Battle.Outcome.FLED)


func test_victory_gives_exp() -> void:
	var mine := _pokemon(&"charmander", 20)
	mine.stats[&"spe"] = 250
	mine.stats[&"atk"] = 500
	var battle := _battle(mine, GameRng.new(7))
	var events := battle.start()
	battle.get_foe_side().active.pokemon.hp = 1
	for i: int in 10:
		if battle.get_state() != Battle.State.CHOOSING:
			break
		events.append_array(battle.submit(BattleAction.move(0)))
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)
	assert_true(_kinds(events).has(K.EXP_GAINED), "XP gagnée")


# --- Textes et événements ---------------------------------------------------------------------

func test_validated_texts() -> void:
	var texts := BattleText.new()
	texts.load_file()
	assert_eq(texts.get_errors().size(), 0, str(texts.get_errors()))
	assert_eq(texts.get_template(&"ball_uncatchable"), "Ce Pokémon ne peut pas être capturé.")
	assert_eq(texts.get_template(&"ghost_revealed"),
		"Le Scope Sylphe révèle l'identité du SPECTRE !")
	assert_eq(texts.get_template(&"ghost_revealed_species"), "C'est un {pokemon} !")


func test_a_revealed_sent_out_says_c_est_un_instead_of_the_wild_line() -> void:
	var texts := BattleText.new()
	texts.load_file()
	var battle := _battle(_pokemon(&"charmander", 20), ScriptedRng.new([]))
	var name := _data.get_species(FOE).name
	for event: BattleEvent in battle.start():
		if event.kind != K.SENT_OUT or event.side != F:
			continue
		assert_false(event.disguised, "jamais masqué")
		assert_eq(Array(texts.lines(event, _data)), ["Un %s sauvage apparaît !" % name])
		event.revealed = true
		assert_eq(Array(texts.lines(event, _data)), ["C'est un %s !" % name])
