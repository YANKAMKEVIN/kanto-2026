extends GutTest
## Patience (CT34, jalon 11 T13 ; dossier 14 §6.3, `jalon-11.md` §2.7) : trois tours, action
## imposée, stock des coups directs reçus, riposte au double plafonnée, échec à vide, ruptures.
##
## N5, IV 0 : Salamèche Vit 11 ; Roucool N3 Vit 8 (plus lent) ; Rattata N10 plus rapide que
## Carapuce N10. Tirages : IA (roll(1), aucun pendant une Patience adverse), puis pour chaque
## Pokémon qui agit : statut (paralysie : roll(100)), confusion (roll(100)), précision,
## critique (2 = non), aléatoire (16). Patience ne tire rien (précision 0 : jamais ratée).

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE
## Un coup qui touche, sans critique, aléatoire à 100 %.
const HIT: Array[int] = [50, 2, 16]

var _data: PokemonData
var _rng: ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _with_move(species: StringName, level: int, move_id: StringName) -> Pokemon:
	var pokemon := PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))
	pokemon.moves.clear()
	pokemon.moves.append(MoveSlot.new(move_id, _data.get_move(move_id).pp))
	return pokemon


func _battle(mine: Pokemon, foe: Pokemon, draws: Array[int]) -> Battle:
	_rng = ScriptedRng.new(draws)
	var party := Party.new()
	party.add(mine)
	var foes := Party.new()
	foes.add(foe)
	var battle := Battle.new(BattleSide.new(party, true), BattleSide.new(foes, false, ""), _data,
		_rng, BattleRules.for_wild())
	battle.start()
	return battle


func _draws(parts: Array) -> Array[int]:
	var result: Array[int] = []
	for part: Variant in parts:
		if part is Array:
			for value: int in part:
				result.append(value)
		else:
			result.append(int(part))
	return result


func _find(events: Array[BattleEvent], kind: BattleEvent.Kind,
		side: BattleEvent.SideId = P) -> BattleEvent:
	for event: BattleEvent in events:
		if event.kind == kind and event.side == side:
			return event
	return null


func _damage_to(events: Array[BattleEvent], side: BattleEvent.SideId) -> int:
	var total := 0
	for event: BattleEvent in events:
		if event.kind == K.DAMAGE and event.side == side:
			total += event.amount
	return total


func test_three_turns_store_then_riposte_double_capped() -> void:
	var charmander := _with_move(&"charmander", 5, &"bide")
	var pidgey := _with_move(&"pidgey", 3, &"gust")
	var battle := _battle(charmander, pidgey, _draws([1, HIT]))
	var pp := charmander.moves[0].pp
	var turn1 := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(_find(turn1, K.MOVE_USED), "tour 1 : Patience est lancée")
	assert_not_null(_find(turn1, K.BIDE_STARTED))
	assert_eq(charmander.moves[0].pp, pp - 1, "un seul PP")
	assert_eq(battle.get_locked_move(), 0, "tour 2 imposé")
	assert_false(battle.is_legal(BattleAction.run()), "rien d'autre n'est permis")
	var stock := _damage_to(turn1, P)
	assert_gt(stock, 0)
	_rng.push(_draws([1, HIT]))
	var turn2 := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_null(_find(turn2, K.MOVE_USED), "pas de « … utilise Patience ! » au tour 2")
	assert_not_null(_find(turn2, K.BIDE_STORING))
	stock += _damage_to(turn2, P)
	assert_eq(battle.get_locked_move(), 0, "tour 3 imposé")
	_rng.push(_draws([1]))
	var turn3 := battle.submit(BattleAction.move(0))
	assert_not_null(_find(turn3, K.BIDE_UNLEASHED))
	var riposte := _find(turn3, K.DAMAGE, F)
	assert_eq(riposte.move_id, &"bide")
	assert_eq(riposte.amount, mini(2 * stock, 15), "2 × reçus, au plus les PV de la cible")
	assert_eq(charmander.moves[0].pp, pp - 1, "aucun PP aux tours 2 et 3")
	assert_eq(battle.get_locked_move(), Battle.NO_LOCK)
	var texts := BattleText.new()
	texts.load_file()
	var lines: Array = []
	for events: Array[BattleEvent] in [turn1, turn2, turn3]:
		for event: BattleEvent in events:
			if event.side == P and event.kind in [K.BIDE_STARTED, K.BIDE_STORING,
					K.BIDE_UNLEASHED]:
				lines.append_array(Array(texts.lines(event, _data)))
	# Textes n° 28 à 30 du §13.
	assert_eq(lines, ["Salamèche se prépare à encaisser !", "Salamèche encaisse !",
		"Salamèche riposte !"])


func test_hits_taken_on_turn_3_before_the_riposte_count() -> void:
	# Carapuce N10 : plus lent que Rattata N10, assez résistant pour encaisser trois Charges.
	var charmander := _with_move(&"squirtle", 10, &"bide")
	var rattata := _with_move(&"rattata", 10, &"tackle")
	var battle := _battle(charmander, rattata, _draws([1, HIT]))
	var turn1 := battle.submit(BattleAction.move(0))
	assert_not_null(_find(turn1, K.BIDE_STARTED))
	assert_eq(charmander.hp + _damage_to(turn1, P), charmander.max_hp(),
		"le coup d'avant la préparation…")
	_rng.push(_draws([1, HIT]))
	var stock := _damage_to(battle.submit(BattleAction.move(0)), P)
	_rng.push(_draws([1, HIT]))
	var turn3 := battle.submit(BattleAction.move(0))
	stock += _damage_to(turn3, P)
	var hp_before := rattata.max_hp()
	assert_eq(_find(turn3, K.DAMAGE, F).amount, mini(2 * stock, hp_before),
		"…ne compte pas ; ceux des tours 2 et 3 (avant la riposte) comptent")


func test_nothing_received_fails() -> void:
	var battle := _battle(_with_move(&"charmander", 5, &"bide"),
		_with_move(&"pidgey", 3, &"growl"), _draws([1, 50]))
	battle.submit(BattleAction.move(0))
	_rng.push(_draws([1, 50]))
	battle.submit(BattleAction.move(0))
	_rng.push(_draws([1, 50]))
	var turn3 := battle.submit(BattleAction.move(0))
	assert_not_null(_find(turn3, K.BIDE_UNLEASHED))
	var failed := _find(turn3, K.FAILED)
	assert_not_null(failed, "« Mais ça échoue ! »")
	assert_eq(failed.move_id, &"bide")
	assert_null(_find(turn3, K.DAMAGE, F))


## Paralysie totale, sommeil, apeurement, se frapper dans la confusion : stock perdu, « La
## patience de … est rompue ! », le joueur redevient libre.
func test_breaks() -> void:
	var cases := {
		"paralysie totale": [func(b: Battler) -> void: b.pokemon.status = StatusRules.PARALYSIS,
			_draws([1, HIT, 10])],
		"sommeil": [func(b: Battler) -> void:
			b.pokemon.status = StatusRules.SLEEP
			b.pokemon.status_turns = 2, _draws([1, HIT])],
		"apeuré": [func(b: Battler) -> void: b.flinched = true, _draws([1, HIT])],
		"se frappe": [func(b: Battler) -> void: b.confusion_turns = 3, _draws([1, 10, 16, HIT])],
	}
	for name: String in cases:
		var charmander := _with_move(&"charmander", 5, &"bide")
		var battle := _battle(charmander, _with_move(&"pidgey", 3, &"gust"), _draws([1, HIT]))
		battle.submit(BattleAction.move(0))
		(cases[name][0] as Callable).call(battle.get_player_side().active)
		_rng.push(cases[name][1])
		var turn2 := battle.submit(BattleAction.move(0))
		var broken := _find(turn2, K.BIDE_BROKEN)
		assert_not_null(broken, name)
		assert_null(_find(turn2, K.BIDE_STORING), name)
		assert_eq(battle.get_locked_move(), Battle.NO_LOCK, "%s : de nouveau libre" % name)
		assert_eq(battle.get_player_side().active.bide_stock, 0, name)
		if name == "paralysie totale":
			var texts := BattleText.new()
			texts.load_file()
			assert_eq(Array(texts.lines(broken, _data)),
				["La patience de Salamèche est rompue !"], "texte n° 32")


func test_paralysis_that_does_not_block_lets_patience_go_on() -> void:
	var charmander := _with_move(&"charmander", 5, &"bide")
	var battle := _battle(charmander, _with_move(&"pidgey", 3, &"gust"), _draws([1, HIT]))
	battle.submit(BattleAction.move(0))
	charmander.status = StatusRules.PARALYSIS
	# Vitesse ÷ 2 : Roucool joue d'abord ; la paralysie ne bloque pas (90 > 25).
	_rng.push(_draws([1, HIT, 90]))
	var turn2 := battle.submit(BattleAction.move(0))
	assert_not_null(_find(turn2, K.BIDE_STORING))
	assert_null(_find(turn2, K.BIDE_BROKEN))


func test_a_biding_foe_plays_its_imposed_turns_without_ai_draws() -> void:
	var charmander := _with_move(&"charmander", 5, &"scratch")
	var rattata := _with_move(&"rattata", 5, &"bide")
	var battle := _battle(charmander, rattata, _draws([1, HIT]))
	var turn1 := battle.submit(BattleAction.move(0))
	assert_not_null(_find(turn1, K.BIDE_STARTED, F))
	_rng.push(HIT)
	var turn2 := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "aucun tirage d'IA pendant sa Patience")
	assert_not_null(_find(turn2, K.BIDE_STORING, F))
	_rng.push(HIT)
	var turn3 := battle.submit(BattleAction.move(0))
	assert_not_null(_find(turn3, K.BIDE_UNLEASHED, F))
	assert_not_null(_find(turn3, K.DAMAGE, P))


func test_patience_is_never_saved_and_smart_ai_never_picks_it() -> void:
	var charmander := _with_move(&"charmander", 5, &"bide")
	var battle := _battle(charmander, _with_move(&"pidgey", 3, &"gust"), _draws([1, HIT]))
	battle.submit(BattleAction.move(0))
	var saved := charmander.to_dict()
	for key: String in ["bide", "bide_stage", "bide_stock"]:
		assert_false(saved.has(key))
	var own := battle.get_player_side().active
	var foe := battle.get_foe_side().active
	assert_false(BattleAI.status_has_effect(_data.get_move(&"bide"), own, foe),
		"« smart » ne la choisit pas (dossier 14 §6.3)")
