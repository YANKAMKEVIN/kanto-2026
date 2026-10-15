extends GutTest
## « Charge puis frappe » dans le moteur (jalon 14 T7, `jalon-14.md` §2.3, dossier 17 §7) :
## Tunnel en deux tours, PP une fois, verrou, esquive, interruptions, Vol, Ball bloquée, poison
## sous terre, Patience contre un Pokémon sous terre, IA « smart ».
##
## IV 0 : Salamèche N5 Vit 11 ; Racaillou N10 Vit 9 et Roucool N3 Vit 8 (plus lents). Tirages :
## IA (roll(n) pour n capacités, aucun pendant une action imposée), puis pour chaque Pokémon qui
## agit : statut (paralysie, gel : roll(100)), confusion (roll(100)), précision, critique
## (2 = non), aléatoire (16). Une capacité esquivée ne tire rien ; une immunité de type non plus.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const J14Moves := preload("res://tests/helpers/j14_moves.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE
## Un coup qui touche, sans critique, aléatoire à 100 %.
const HIT: Array[int] = [50, 2, 16]

var _data: PokemonData
var _items: ItemLibrary
var _rng: ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	J14Moves.ensure(_data)
	_items = ItemLibrary.new()
	_items.load_dir()


func _with_moves(species: StringName, level: int, move_ids: Array[StringName]) -> Pokemon:
	var pokemon := PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))
	pokemon.moves.clear()
	for move_id: StringName in move_ids:
		pokemon.moves.append(MoveSlot.new(move_id, _data.get_move(move_id).pp))
	return pokemon


func _digger() -> Pokemon:
	return _with_moves(&"charmander", 5, [&"dig", &"scratch"])


func _geodude(move_ids: Array[StringName] = [&"tackle"]) -> Pokemon:
	return _with_moves(&"geodude", 10, move_ids)


func _battle(mine: Array[Pokemon], foe: Pokemon, draws: Array[int],
		rules: BattleRules = null) -> Battle:
	_rng = ScriptedRng.new(draws)
	var party := Party.new()
	for pokemon: Pokemon in mine:
		party.add(pokemon)
	var foes := Party.new()
	foes.add(foe)
	var battle := Battle.new(BattleSide.new(party, true), BattleSide.new(foes, false, ""), _data,
		_rng, rules if rules != null else BattleRules.for_wild(_items))
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


func _kinds(events: Array[BattleEvent], side: BattleEvent.SideId) -> Array:
	var result: Array = []
	for event: BattleEvent in events:
		if event.side == side and event.kind != K.TURN_STARTED:
			result.append(K.find_key(event.kind))
	return result


func _line(event: BattleEvent) -> Array:
	var texts := BattleText.new()
	texts.load_file()
	return Array(texts.lines(event, _data))


func test_digs_then_strikes_with_one_pp() -> void:
	var charmander := _digger()
	var geodude := _geodude()
	var battle := _battle([charmander], geodude, _draws([1]))
	var pp := charmander.moves[0].pp
	var turn1 := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "tackle esquivé : aucun tirage")
	assert_eq(_kinds(turn1, P), ["MOVE_USED", "CHARGE_STARTED", "DODGED"])
	assert_eq(_line(_find(turn1, K.CHARGE_STARTED)), ["Salamèche creuse un trou !"])
	assert_eq(_line(_find(turn1, K.DODGED)), ["Salamèche évite l'attaque !"])
	assert_null(_find(turn1, K.DAMAGE, F), "aucun dégât au tour 1")
	assert_eq(charmander.hp, charmander.max_hp())
	assert_eq(charmander.moves[0].pp, pp - 1)
	assert_true(battle.get_player_side().active.invulnerable)
	assert_eq(battle.get_locked_move(), 0, "tour 2 imposé")
	_rng.push(_draws([1, HIT, HIT]))
	var turn2 := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_kinds(turn2, P).slice(0, 2), ["CHARGE_RELEASED", "MOVE_USED"])
	assert_eq(_find(turn2, K.MOVE_USED).pp, pp - 1, "aucun PP au tour 2")
	assert_eq(charmander.moves[0].pp, pp - 1)
	var hit := _find(turn2, K.DAMAGE, F)
	assert_eq(hit.move_id, &"dig")
	assert_eq(hit.effectiveness, 2.0, "Sol sur Roche/Sol")
	assert_not_null(_find(turn2, K.DAMAGE, P), "en surface : de nouveau touché")
	assert_false(battle.get_player_side().active.invulnerable)
	assert_eq(battle.get_locked_move(), Battle.NO_LOCK)


func test_locked_turn_refuses_every_other_action() -> void:
	var battle := _battle([_digger(), _with_moves(&"rattata", 5, [&"tackle"])], _geodude(),
		_draws([1]))
	battle.submit(BattleAction.move(0))
	assert_true(battle.is_legal(BattleAction.move(0)))
	assert_false(battle.is_legal(BattleAction.move(1)), "autre capacité")
	assert_false(battle.is_legal(BattleAction.switch_to(1)), "changement")
	assert_false(battle.is_legal(BattleAction.ball(&"poke_ball")), "Sac")
	assert_false(battle.is_legal(BattleAction.heal(&"potion", 1)), "Sac")
	assert_false(battle.is_legal(BattleAction.run()), "fuite")


func test_last_pp_still_strikes_on_turn_2() -> void:
	var charmander := _digger()
	charmander.moves[0].pp = 1
	var battle := _battle([charmander], _geodude(), _draws([1]))
	battle.submit(BattleAction.move(0))
	assert_eq(charmander.moves[0].pp, 0)
	assert_true(battle.is_legal(BattleAction.move(0)), "imposée même sans PP")
	_rng.push(_draws([1, HIT, HIT]))
	assert_not_null(_find(battle.submit(BattleAction.move(0)), K.DAMAGE, F))


func test_foe_charge_is_imposed_without_ai_draw() -> void:
	var charmander := _with_moves(&"charmander", 5, [&"scratch"])
	var geodude := _geodude([&"dig", &"tackle"])
	# Tour 1 : IA roll(2) = 1 (Tunnel) ; Griffe touche d'abord, puis Racaillou creuse.
	var battle := _battle([charmander], geodude, _draws([1, HIT]))
	var turn1 := battle.submit(BattleAction.move(0))
	assert_not_null(_find(turn1, K.CHARGE_STARTED, F))
	# Tour 2 : aucun tirage d'IA ; Griffe esquivée (aucun tirage), Tunnel frappe.
	_rng.push(HIT)
	var turn2 := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "action imposée : pas de tirage d'IA")
	assert_not_null(_find(turn2, K.DODGED, F))
	assert_eq(_kinds(turn2, F).slice(0, 2), ["DODGED", "CHARGE_RELEASED"])
	assert_eq(_find(turn2, K.DAMAGE, P).move_id, &"dig")


func test_self_moves_are_not_dodged_but_foe_moves_are() -> void:
	var cases := {
		&"harden": K.STAT_CHANGED, &"growl": K.DODGED, &"poison_powder": K.DODGED,
		&"leech_seed": K.DODGED, &"super_fang": K.DODGED,
	}
	for move_id: StringName in cases:
		var battle := _battle([_digger()], _geodude([move_id]), _draws([1]))
		var turn1 := battle.submit(BattleAction.move(0))
		assert_eq(_rng.remaining(), 0, String(move_id))
		var expected: BattleEvent.Kind = cases[move_id]
		var side := F if expected == K.STAT_CHANGED else P
		assert_not_null(_find(turn1, expected, side), String(move_id))


func test_poison_and_seed_still_hurt_underground() -> void:
	var charmander := _digger()
	charmander.status = StatusRules.POISON
	var battle := _battle([charmander], _geodude([&"harden"]), _draws([1]))
	battle.get_player_side().active.seed_fraction = 0.125
	var turn1 := battle.submit(BattleAction.move(0))
	assert_not_null(_find(turn1, K.CHARGE_STARTED))
	assert_not_null(_find(turn1, K.DRAINED), "graine en fin de tour")
	assert_not_null(_find(turn1, K.STATUS_DAMAGED), "poison en fin de tour")
	assert_true(battle.get_player_side().active.is_charging())


## Tour 1 : sommeil, paralysie totale, apeurement, se frapper dans la confusion : il ne creuse
## pas, aucun PP, rien d'imposé ensuite.
func test_turn_1_interruptions_keep_it_on_the_surface() -> void:
	var cases := {
		"sommeil": [func(b: Battler) -> void:
			b.pokemon.status = StatusRules.SLEEP
			b.pokemon.status_turns = 2, _draws([1, HIT])],
		"paralysie totale": [func(b: Battler) -> void: b.pokemon.status = StatusRules.PARALYSIS,
			_draws([1, HIT, 10])],
		"apeuré": [func(b: Battler) -> void: b.flinched = true, _draws([1, HIT])],
		"se frappe": [func(b: Battler) -> void: b.confusion_turns = 3, _draws([1, 10, 16, HIT])],
	}
	for name: String in cases:
		var charmander := _digger()
		var battle := _battle([charmander], _geodude(), [])
		var active := battle.get_player_side().active
		(cases[name][0] as Callable).call(active)
		_rng.push(cases[name][1])
		var turn1 := battle.submit(BattleAction.move(0))
		assert_eq(_rng.remaining(), 0, name)
		assert_null(_find(turn1, K.CHARGE_STARTED), name)
		assert_null(_find(turn1, K.MOVE_USED), name)
		assert_eq(charmander.moves[0].pp, 10, "%s : aucun PP" % name)
		assert_false(active.is_charging(), name)
		assert_eq(battle.get_locked_move(), Battle.NO_LOCK, name)


## Tour 2 : endormi (même s'il se réveille ici), gelé (même s'il dégèle ici), paralysie
## totale, apeuré, se frappe : il remonte sans frapper (n° 54), de nouveau touché.
func test_turn_2_interruptions_bring_it_up() -> void:
	var cases := {
		"sommeil": [func(b: Battler) -> void:
			b.pokemon.status = StatusRules.SLEEP
			b.pokemon.status_turns = 2, _draws([1, HIT])],
		"réveil": [func(b: Battler) -> void:
			b.pokemon.status = StatusRules.SLEEP
			b.pokemon.status_turns = 0, _draws([1, HIT])],
		"gel": [func(b: Battler) -> void: b.pokemon.status = StatusRules.FREEZE,
			_draws([1, 90, HIT])],
		"dégel": [func(b: Battler) -> void: b.pokemon.status = StatusRules.FREEZE,
			_draws([1, 10, HIT])],
		# Vitesse ÷ 2 : Racaillou joue d'abord, encore esquivé, puis la paralysie bloque.
		"paralysie totale": [func(b: Battler) -> void: b.pokemon.status = StatusRules.PARALYSIS,
			_draws([1, 10])],
		"apeuré": [func(b: Battler) -> void: b.flinched = true, _draws([1, HIT])],
		"se frappe": [func(b: Battler) -> void: b.confusion_turns = 3, _draws([1, 10, 16, HIT])],
	}
	for name: String in cases:
		var charmander := _digger()
		var battle := _battle([charmander], _geodude(), _draws([1]))
		battle.submit(BattleAction.move(0))
		var active := battle.get_player_side().active
		(cases[name][0] as Callable).call(active)
		_rng.push(cases[name][1])
		var turn2 := battle.submit(BattleAction.move(0))
		assert_eq(_rng.remaining(), 0, name)
		var broken := _find(turn2, K.CHARGE_BROKEN)
		assert_not_null(broken, name)
		assert_null(_find(turn2, K.CHARGE_RELEASED), name)
		assert_null(_find(turn2, K.DAMAGE, F), "%s : rien n'est frappé" % name)
		if name == "paralysie totale":
			assert_not_null(_find(turn2, K.DODGED), "%s : encore sous terre" % name)
		else:
			assert_not_null(_find(turn2, K.DAMAGE, P), "%s : en surface, touché" % name)
		assert_false(active.is_charging(), name)
		assert_false(active.invulnerable, name)
		assert_eq(battle.get_locked_move(), Battle.NO_LOCK, "%s : de nouveau libre" % name)
		if name == "sommeil":
			assert_eq(_line(broken), ["Salamèche remonte à la surface."], "n° 54")


func test_flying_target_is_not_affected() -> void:
	var pidgey := _with_moves(&"pidgey", 3, [&"gust"])
	var battle := _battle([_digger()], pidgey, _draws([1]))
	var turn1 := battle.submit(BattleAction.move(0))
	assert_not_null(_find(turn1, K.DODGED), "Tornade esquivée")
	_rng.push(_draws([1, HIT]))
	var turn2 := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "immunité : aucun tirage")
	var immune := _find(turn2, K.NO_EFFECT, F)
	assert_not_null(immune, "Vol : « n'est pas affecté »")
	assert_eq(immune.move_id, &"dig")
	assert_eq(pidgey.hp, pidgey.max_hp())


func test_ball_cannot_aim_at_a_foe_underground() -> void:
	# Carapuce N10 (Vit 13, plus rapide que Racaillou) encaisse Tunnel.
	var squirtle := _with_moves(&"squirtle", 10, [&"scratch"])
	var geodude := _geodude([&"dig", &"tackle"])
	var battle := _battle([squirtle], geodude, _draws([1, HIT]))
	battle.submit(BattleAction.move(0))
	assert_true(battle.is_legal(BattleAction.ball(&"poke_ball")), "le joueur reste libre")
	_rng.push(HIT)
	var turn2 := battle.submit(BattleAction.ball(&"poke_ball"))
	assert_eq(_rng.remaining(), 0, "aucun tirage de capture")
	var blocked := _find(turn2, K.BALL_BLOCKED, F)
	assert_not_null(blocked)
	assert_eq(blocked.item_id, &"poke_ball")
	assert_eq(_line(blocked), ["Impossible de viser !"])
	assert_null(_find(turn2, K.BALL_THROWN, F))
	assert_not_null(_find(turn2, K.CHARGE_RELEASED, F), "puis l'adversaire joue son tour")
	assert_not_null(_find(turn2, K.DAMAGE, P))
	assert_eq(battle.get_state(), Battle.State.CHOOSING)


func test_foe_fainted_by_poison_underground_ends_the_battle() -> void:
	var charmander := _with_moves(&"charmander", 5, [&"growl"])
	var geodude := _geodude([&"dig"])
	geodude.status = StatusRules.POISON
	geodude.hp = 1
	# Grognement ne tire rien de plus que sa précision (50).
	var battle := _battle([charmander], geodude, _draws([1, 50]))
	var turn1 := battle.submit(BattleAction.move(0))
	assert_not_null(_find(turn1, K.CHARGE_STARTED, F))
	assert_not_null(_find(turn1, K.FAINTED, F), "K.O. par le poison sous terre")
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)
	assert_false(battle.get_foe_side().active.is_charging(), "rien n'est gardé")


func test_player_fainted_by_poison_underground_is_replaced_free() -> void:
	var charmander := _digger()
	charmander.status = StatusRules.POISON
	charmander.hp = 1
	var battle := _battle([charmander, _with_moves(&"rattata", 5, [&"tackle"])], _geodude(),
		_draws([1]))
	var turn1 := battle.submit(BattleAction.move(0))
	assert_not_null(_find(turn1, K.FAINTED))
	assert_true(battle.needs_replacement())
	battle.replace(1)
	assert_eq(battle.get_locked_move(), Battle.NO_LOCK, "le remplaçant choisit librement")
	assert_false(battle.get_player_side().active.invulnerable)


func test_bide_riposte_is_dodged_underground() -> void:
	var charmander := _with_moves(&"charmander", 5, [&"bide"])
	var geodude := _geodude([&"tackle", &"dig"])
	# Tour 1 : IA roll(2) = 1 (Charge) ; Patience commence, Charge touche (stock).
	var battle := _battle([charmander], geodude, _draws([1, HIT]))
	battle.submit(BattleAction.move(0))
	# Tour 2 : IA roll(2) = 2 (Tunnel) ; Patience encaisse, Racaillou creuse.
	_rng.push(_draws([2]))
	var turn2 := battle.submit(BattleAction.move(0))
	assert_not_null(_find(turn2, K.CHARGE_STARTED, F))
	# Tour 3 : les deux actions imposées ; la riposte est esquivée, puis Tunnel frappe.
	_rng.push(HIT)
	var turn3 := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(_find(turn3, K.BIDE_UNLEASHED))
	assert_not_null(_find(turn3, K.DODGED, F), "riposte esquivée")
	assert_null(_find(turn3, K.DAMAGE, F))
	assert_eq(_find(turn3, K.DAMAGE, P).move_id, &"dig")
	assert_eq(battle.get_locked_move(), Battle.NO_LOCK)


func test_smart_ai_scores_dig_at_half_and_picks_it() -> void:
	var own := Battler.new(_geodude([&"dig", &"tackle"]), _data.get_species(&"geodude").types)
	var foe := Battler.new(_with_moves(&"rattata", 5, [&"tackle"]),
		_data.get_species(&"rattata").types)
	var chart := _data.get_type_chart()
	var dig := _data.get_move(&"dig")
	# Sol sur Normal : ×1 ; bonus de type (Racaillou est Sol) : ×1,5 ; deux tours : ×0,5.
	assert_eq(BattleAI.score_move(dig, own, foe, chart, 0), 100 * 1.5 * 0.5)
	assert_eq(BattleAI.score_move(_data.get_move(&"tackle"), own, foe, chart, 0), 40.0)
	var own_side := BattleSide.new(Party.new(), false, "")
	own_side.active = own
	var foe_side := BattleSide.new(Party.new(), true)
	foe_side.active = foe
	var ai := BattleAI.new(BattleAI.SMART)
	assert_eq(ai.choose(own_side, foe_side, ScriptedRng.new([]), _data).move_index, 0,
		"Tunnel (75) devant Charge (40), sans tirage")
