extends GutTest
## Entrave (jalon 12 ; `jalon-12.md` §2.10, dossier 15 C-2, §20 n° 43 et 46) : bloque la dernière
## capacité utilisée par la cible pendant 4 fins de tour (celle de l'Entrave comprise), échoue sans
## capacité précédente, sur une capacité déjà bloquée ou sur une cible en Patience ; la capacité
## sort des choix (joueur, IA ; seule capacité → Lutte) ; perdue au changement.
##
## IV 0. Vit : Rattata N10 19 > Nosferapti N10 16 > Rondoudou N15 11 > Racaillou N10 9.
## Tirages : IA (roll(n), n = capacités utilisables ; aucun pendant une Patience), puis pour chaque
## Pokémon qui agit : précision (roll(100), sauf capacité qui ne rate jamais), critique, aléatoire.

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

var _data: PokemonData
var _rng: Kit.ScriptedRng
var _texts: BattleText


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_texts = BattleText.new()
	_texts.load_file()


func _lines(events: Array[BattleEvent], kind: BattleEvent.Kind) -> Array:
	var result: Array = []
	for event: BattleEvent in events:
		if event.kind == kind:
			result.append_array(Array(_texts.lines(event, _data)))
	return result


func test_disable_blocks_the_last_move_four_end_of_turns() -> void:
	_rng = Kit.ScriptedRng.new(Kit.draws([1, Kit.HIT, 50]))
	var battle := Kit.battle(_data, _rng,
		[Kit.mon(_data, &"jigglypuff", 15, [&"disable", &"defense_curl"])],
		[Kit.mon(_data, &"rattata", 10, [&"tackle", &"tail_whip"])])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	var disabled := Kit.find(events, K.MOVE_DISABLED, F)
	assert_not_null(disabled, "Charge de Rattata bloquée")
	assert_eq(disabled.move_id, &"tackle")
	assert_eq(_lines(events, K.MOVE_DISABLED), ["Charge de Rattata est bloquée !"])
	var rattata := battle.get_foe_side().active
	assert_eq(rattata.disabled_slot, 0)
	assert_eq(rattata.disabled_turns, 3, "première fin de tour décomptée")
	assert_eq(rattata.usable_moves(), [1] as Array[int], "l'IA ne la voit plus")
	assert_eq(battle.get_disabled_move(), Battle.NO_LOCK, "rien de bloqué chez le joueur")
	for turn: int in [2, 3, 4]:
		# IA : une seule capacité possible (roll(1)) : Mimi-Queue, jamais Charge.
		_rng.push([1, 50])
		events = battle.submit(BattleAction.move(1))
		assert_eq(_rng.remaining(), 0, "tour %d" % turn)
		var used := Kit.find(events, K.MOVE_USED, F)
		assert_eq(used.move_id, &"tail_whip", "tour %d" % turn)
		if turn < 4:
			assert_null(Kit.find(events, K.DISABLE_ENDED), "tour %d" % turn)
	assert_eq(_lines(events, K.DISABLE_ENDED), ["Charge n'est plus bloquée."])
	assert_eq(Kit.find(events, K.DISABLE_ENDED).side, F)
	assert_false(rattata.has_disabled_move())
	assert_eq(rattata.usable_moves(), [0, 1] as Array[int])


func test_disable_fails_before_any_move_and_on_an_already_disabled_target() -> void:
	_rng = Kit.ScriptedRng.new(Kit.draws([1, 50, Kit.HIT]))
	var battle := Kit.battle(_data, _rng,
		[Kit.mon(_data, &"zubat", 10, [&"disable", &"defense_curl"])],
		[Kit.mon(_data, &"geodude", 10, [&"tackle", &"defense_curl"])])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	var failed := Kit.find(events, K.FAILED, P)
	assert_not_null(failed, "Racaillou n'a encore rien lancé")
	assert_eq(_lines(events, K.FAILED), ["Mais ça échoue !"])
	assert_null(Kit.find(events, K.MOVE_DISABLED))
	# Tour 2 : Charge bloquée avant que Racaillou (plus lent) ne la lance.
	_rng.push([1, 50])
	events = battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(Kit.find(events, K.MOVE_DISABLED, F), "Charge bloquée")
	# Racaillou n'a plus que Boul'Armure (roll(1)) ; une seconde Entrave échoue.
	_rng.push([1, 50])
	events = battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(Kit.find(events, K.FAILED, P), "déjà une capacité bloquée")
	assert_eq(battle.get_foe_side().active.disabled_slot, 0, "toujours Charge")


func test_disable_fails_on_a_target_locked_in_bide() -> void:
	_rng = Kit.ScriptedRng.new([1, 50])
	var battle := Kit.battle(_data, _rng, [Kit.mon(_data, &"zubat", 10, [&"disable"])],
		[Kit.mon(_data, &"geodude", 10, [&"bide"])])
	battle.submit(BattleAction.move(0))
	assert_true(battle.get_foe_side().active.is_biding())
	_rng.push([50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "Patience imposée : aucun tirage de l'IA")
	assert_not_null(Kit.find(events, K.FAILED, P), "en pleine Patience")
	assert_not_null(Kit.find(events, K.BIDE_STORING, F), "la Patience continue")
	assert_false(battle.get_foe_side().active.has_disabled_move())


func test_the_only_move_disabled_in_the_same_turn_then_struggle() -> void:
	_rng = Kit.ScriptedRng.new(Kit.draws([1, 50, Kit.HIT]))
	var geodude := Kit.mon(_data, &"geodude", 10, [&"tackle"])
	var battle := Kit.battle(_data, _rng, [geodude],
		[Kit.mon(_data, &"zubat", 10, [&"disable"])])
	battle.submit(BattleAction.move(0))
	var pp := geodude.moves[0].pp
	# Tour 2 : Nosferapti (plus rapide) bloque Charge, que Racaillou avait déjà choisie.
	_rng.push([1, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(Kit.count(events, K.MOVE_DISABLED), 2, "l'Entrave, puis la tentative bloquée")
	assert_eq(Kit.kinds(events), [["MOVE_USED", "FOE"], ["MOVE_DISABLED", "PLAYER"],
		["MOVE_DISABLED", "PLAYER"]])
	assert_null(Kit.find(events, K.MOVE_USED, P), "rien n'est lancé")
	assert_eq(geodude.moves[0].pp, pp, "aucun PP")
	assert_eq(battle.get_disabled_move(), 0)
	assert_eq(battle.get_usable_moves(), [] as Array[int])
	assert_false(battle.is_legal(BattleAction.move(0)))
	assert_true(battle.is_legal(BattleAction.move(BattleAction.STRUGGLE)), "Lutte")


func test_disable_is_lost_when_the_pokemon_switches_out() -> void:
	_rng = Kit.ScriptedRng.new(Kit.draws([1, 50, Kit.HIT]))
	var battle := Kit.battle(_data, _rng, [Kit.mon(_data, &"geodude", 10, [&"tackle"]),
		Kit.mon(_data, &"charmander", 10, [&"defense_curl"])],
		[Kit.mon(_data, &"zubat", 10, [&"disable"])])
	battle.submit(BattleAction.move(0))
	_rng.push([1, 50])
	battle.submit(BattleAction.move(0))
	assert_eq(battle.get_disabled_move(), 0)
	_rng.push([1, 50])
	battle.submit(BattleAction.switch_to(1))
	assert_eq(battle.get_disabled_move(), Battle.NO_LOCK)
	_rng.push([1, 50])
	var events := battle.submit(BattleAction.switch_to(0))
	assert_not_null(Kit.find(events, K.FAILED, F), "le revenant n'a encore rien lancé")
	assert_eq(battle.get_disabled_move(), Battle.NO_LOCK)
	assert_eq(battle.get_usable_moves(), [0] as Array[int])


func test_the_card_label_is_the_validated_one() -> void:
	assert_eq(_texts.get_template(&"move_disabled_label"), "BLOQUÉE")
