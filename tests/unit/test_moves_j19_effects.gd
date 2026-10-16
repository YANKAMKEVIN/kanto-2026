extends GutTest
## Effets du jalon 19 dans le moteur : Dévorêve, Hurlement, Bélier, Ultralaser. Règles de
## Rouge/Bleu, sauf deux décisions de Kevin du 2026-10-16 (« comme la 2e génération ») :
## Hurlement contre un Dresseur force un changement aléatoire, Ultralaser impose le repos même
## après un K.O.
##
## Tirages (voir `battle_kit_j12.gd`) : IA adverse (roll(n) pour n capacités, aucun pendant une
## action imposée), égalité de Vitesse (roll(2)), puis pour chaque Pokémon qui agit : précision,
## critique (2 = non), aléatoire (16 = 100 %) ; une capacité de statut ne tire que sa précision
## (aucune si elle ne rate jamais) ; Hurlement contre un Dresseur : pick_index de la réserve.

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

var _data: PokemonData
var _rng: Kit.ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _wild(mine: Array, foe: Pokemon, draws: Array) -> Battle:
	_rng = Kit.ScriptedRng.new(Kit.draws(draws))
	return Kit.battle(_data, _rng, mine, [foe])


func _trainer(mine: Array, foes: Array, draws: Array) -> Battle:
	_rng = Kit.ScriptedRng.new(Kit.draws(draws))
	return Kit.battle(_data, _rng, mine, foes, "Exorciste", BattleRules.for_trainer())


# --- Données ----------------------------------------------------------------------------------

func test_the_four_moves_carry_their_effects_and_no_pending_one() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))
	var dream := _data.get_move(&"dream_eater")
	assert_not_null(dream.effect_of(MoveEffect.Kind.REQUIRES_SLEEP))
	assert_eq(dream.effect_of(MoveEffect.Kind.DRAIN).fraction, 0.5)
	assert_not_null(_data.get_move(&"roar").effect_of(MoveEffect.Kind.FORCE_SWITCH))
	assert_eq(_data.get_move(&"take_down").effect_of(MoveEffect.Kind.RECOIL_DAMAGE).fraction, 0.25)
	assert_not_null(_data.get_move(&"hyper_beam").effect_of(MoveEffect.Kind.RECHARGE))
	for id: StringName in [&"dream_eater", &"roar", &"take_down", &"hyper_beam"]:
		var move := _data.get_move(id)
		assert_eq(move.pending_effects.size(), 0, String(id))
		assert_false(move.description.contains("Sans effet"), String(id))


func test_unknown_values_of_the_new_kinds_are_refused() -> void:
	var data := PokemonData.new()
	var bad := {
		"x": { "name": "X", "type": "normal", "category": "physical", "power": 90,
			"accuracy": 85, "pp": 20, "description": "x",
			"effects": [{ "kind": "recoil_damage" }] },
	}
	assert_false(data.add_moves_from_dict(bad, "test"), "« fraction » obligatoire")
	assert_push_error("fraction")


# --- Dévorêve -----------------------------------------------------------------------------

func test_dream_eater_drains_half_the_damage_from_a_sleeping_target() -> void:
	var mine := Kit.mon(_data, &"gastly", 30, [&"dream_eater"])
	mine.hp = 1
	var foe := Kit.mon(_data, &"rattata", 20, [&"growl"])
	foe.status = StatusRules.SLEEP
	foe.status_turns = 2
	var battle := _wild([mine], foe, [1, Kit.HIT])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	var damage := Kit.find(events, K.DAMAGE, F)
	assert_not_null(damage)
	var drained := Kit.find(events, K.DRAINED_HP, P)
	assert_not_null(drained, "le lanceur récupère des PV")
	assert_eq(drained.amount, mini(maxi(floori(damage.amount / 2.0), 1), mine.max_hp() - 1))
	assert_gt(Kit.index_of(events, K.DRAINED_HP), Kit.index_of(events, K.DAMAGE))
	assert_eq(mine.moves[0].pp, 14)


func test_dream_eater_misses_an_awake_target_without_damage_draws() -> void:
	var mine := Kit.mon(_data, &"gastly", 30, [&"dream_eater"])
	var foe := Kit.mon(_data, &"rattata", 20, [&"growl"])
	var battle := _wild([mine], foe, [1, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "aucun tirage de dégâts pour Dévorêve")
	assert_not_null(Kit.find(events, K.MOVE_MISSED, P), "rate, comme MoveHitTest de RB")
	assert_null(Kit.find(events, K.DAMAGE, F))
	assert_null(Kit.find(events, K.DRAINED_HP))
	assert_eq(foe.hp, foe.max_hp())
	assert_eq(mine.moves[0].pp, 14, "PP dépensé")


func test_smart_ai_does_not_pick_dream_eater_on_an_awake_target() -> void:
	var own := Battler.new(Kit.mon(_data, &"gastly", 30, [&"dream_eater"]), [&"ghost"])
	var foe_mon := Kit.mon(_data, &"rattata", 20, [&"growl"])
	var foe := Battler.new(foe_mon, [&"normal"])
	var move := _data.get_move(&"dream_eater")
	assert_eq(BattleAI.score_move(move, own, foe, _data.get_type_chart(), 0), 0.0)
	foe_mon.status = StatusRules.SLEEP
	assert_gt(BattleAI.score_move(move, own, foe, _data.get_type_chart(), 0), 0.0)


# --- Hurlement ----------------------------------------------------------------------------

func test_roar_from_the_player_makes_the_wild_foe_flee() -> void:
	var mine := Kit.mon(_data, &"rattata", 30, [&"roar"])
	var foe := Kit.mon(_data, &"rattata", 5, [&"growl"])
	var battle := _wild([mine], foe, [1, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "Hurlement ne rate jamais : aucun tirage")
	assert_lt(Kit.index_of(events, K.MOVE_USED, F), Kit.index_of(events, K.MOVE_USED, P),
		"priorité −6 : le sauvage agit d'abord")
	assert_not_null(Kit.find(events, K.SCARED_AWAY, F))
	assert_eq(battle.get_outcome(), Battle.Outcome.FOE_FLED)
	assert_eq(battle.get_state(), Battle.State.OVER)
	assert_null(Kit.find(events, K.EXP_GAINED), "ni XP")
	assert_eq(events[-1].kind, K.BATTLE_ENDED)


func test_roar_from_a_wild_foe_chases_the_player_without_a_defeat() -> void:
	var mine := Kit.mon(_data, &"rattata", 5, [&"growl"])
	var foe := Kit.mon(_data, &"rattata", 30, [&"roar"])
	var battle := _wild([mine], foe, [1, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(Kit.find(events, K.SCARED_AWAY, P))
	assert_eq(battle.get_outcome(), Battle.Outcome.FLED, "le joueur est chassé, pas battu")
	assert_eq(events[-1].kind, K.BATTLE_ENDED)


func test_roar_against_a_trainer_forces_a_random_able_reserve_in() -> void:
	var mine := Kit.mon(_data, &"rattata", 30, [&"roar"])
	var first := Kit.mon(_data, &"rattata", 10, [&"growl"])
	var second := Kit.mon(_data, &"pidgey", 10, [&"growl"])
	var third := Kit.mon(_data, &"gastly", 10, [&"growl"])
	# Réserve de deux : pick_index(2), la valeur 2 tire le troisième.
	var battle := _trainer([mine], [first, second, third], [1, 50, 2])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	var forced := Kit.index_of(events, K.FORCED_OUT, F)
	assert_gt(forced, -1, "la cible quitte le terrain")
	assert_eq(events[forced].species_id, &"rattata")
	var sent := Kit.index_of(events, K.SENT_OUT, F)
	assert_eq(sent, forced + 1, "le remplaçant entre aussitôt")
	assert_eq(events[sent].species_id, &"gastly")
	assert_eq(events[sent].trainer_name, "Exorciste")
	assert_eq(battle.get_foe_side().active.pokemon, third)
	assert_eq(battle.get_state(), Battle.State.CHOOSING)
	assert_eq(battle.get_participants(), [mine] as Array[Pokemon])


func test_roar_against_a_trainer_skips_fainted_reserves_and_draws_nothing_for_one() -> void:
	var mine := Kit.mon(_data, &"rattata", 30, [&"roar"])
	var first := Kit.mon(_data, &"rattata", 10, [&"growl"])
	var fainted := Kit.mon(_data, &"pidgey", 10, [&"growl"])
	fainted.hp = 0
	var last := Kit.mon(_data, &"gastly", 10, [&"growl"])
	var battle := _trainer([mine], [first, fainted, last], [1, 50])
	battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "un seul candidat : aucun tirage")
	assert_eq(battle.get_foe_side().active.pokemon, last)


func test_roar_fails_when_the_trainer_has_no_other_able_pokemon() -> void:
	var mine := Kit.mon(_data, &"rattata", 30, [&"roar"])
	var only := Kit.mon(_data, &"rattata", 10, [&"growl"])
	var fainted := Kit.mon(_data, &"pidgey", 10, [&"growl"])
	fainted.hp = 0
	var battle := _trainer([mine], [only, fainted], [1, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(Kit.find(events, K.FAILED, P), "« Mais ça échoue ! »")
	assert_null(Kit.find(events, K.FORCED_OUT))
	assert_eq(battle.get_foe_side().active.pokemon, only)


func test_a_trainer_roar_forces_a_random_player_pokemon_in_without_a_choice() -> void:
	var lead := Kit.mon(_data, &"rattata", 5, [&"growl"])
	var second := Kit.mon(_data, &"pidgey", 5, [&"growl"])
	var third := Kit.mon(_data, &"gastly", 5, [&"growl"])
	var foe := Kit.mon(_data, &"rattata", 30, [&"roar"])
	var battle := _trainer([lead, second, third], [foe], [1, 50, 1])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(Kit.find(events, K.FORCED_OUT, P))
	assert_eq(Kit.find(events, K.SENT_OUT, P).species_id, &"pidgey")
	assert_eq(battle.get_player_side().active.pokemon, second)
	assert_eq(battle.get_state(), Battle.State.CHOOSING, "pas de choix de remplaçant")
	assert_true(battle.get_participants().has(second), "le remplaçant gagnera de l'XP")


func test_roar_against_a_pokemon_underground_is_dodged() -> void:
	assert_true(ChargeRules.targets_foe(_data.get_move(&"roar")), "Hurlement vise la cible")


func test_roar_texts_and_beats() -> void:
	var texts := BattleText.new()
	assert_true(texts.load_file(), "\n".join(texts.get_errors()))
	var mine := Kit.mon(_data, &"rattata", 30, [&"roar"])
	var foe := Kit.mon(_data, &"rattata", 5, [&"growl"])
	var battle := _wild([mine], foe, [1, 50])
	var events := battle.submit(BattleAction.move(0))
	var scared := Kit.find(events, K.SCARED_AWAY, F)
	assert_eq(texts.lines(scared, _data), PackedStringArray(["Rattata prend peur et s'enfuit !"]))
	var beats := BattlePlayback.beats(scared, texts, _data)
	assert_eq(beats[0].kind, BattleBeat.Kind.VANISH)
	var forced := BattleEvent.new(K.FORCED_OUT, BattleEvent.SideId.FOE)
	forced.pokemon_name = "Rattata"
	assert_eq(texts.lines(forced, _data), PackedStringArray(["Rattata est chassé du combat !"]))
	assert_eq(BattlePlayback.beats(forced, texts, _data)[-1].kind, BattleBeat.Kind.WITHDRAW)


# --- Bélier -------------------------------------------------------------------------------

func test_take_down_recoil_is_a_quarter_of_the_damage_dealt() -> void:
	var mine := Kit.mon(_data, &"rattata", 30, [&"take_down"])
	var foe := Kit.mon(_data, &"pidgey", 30, [&"growl"])
	var battle := _wild([mine], foe, [1, Kit.HIT, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	var damage := Kit.find(events, K.DAMAGE, F)
	var recoil := Kit.find(events, K.RECOIL, P)
	assert_not_null(recoil)
	assert_gt(damage.amount, 4, "assez de dégâts pour un quart supérieur à 1")
	assert_eq(recoil.amount, floori(damage.amount / 4.0))
	assert_eq(mine.hp, mine.max_hp() - recoil.amount)


func test_take_down_recoil_is_at_least_one_even_when_the_target_faints() -> void:
	var mine := Kit.mon(_data, &"rattata", 30, [&"take_down"])
	var foe := Kit.mon(_data, &"pidgey", 5, [&"growl"])
	foe.hp = 1
	var battle := _wild([mine], foe, [1, Kit.HIT])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(Kit.find(events, K.DAMAGE, F).amount, 1, "un seul PV à prendre")
	assert_eq(Kit.find(events, K.RECOIL, P).amount, 1, "au moins 1")
	assert_lt(Kit.index_of(events, K.RECOIL, P), Kit.index_of(events, K.FAINTED, F))
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)


func test_take_down_that_misses_has_no_recoil() -> void:
	var mine := Kit.mon(_data, &"rattata", 30, [&"take_down"])
	var foe := Kit.mon(_data, &"pidgey", 30, [&"growl"])
	var battle := _wild([mine], foe, [1, 86, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(Kit.find(events, K.MOVE_MISSED, P))
	assert_null(Kit.find(events, K.RECOIL))


# --- Ultralaser ---------------------------------------------------------------------------

func _beamer(level: int = 20) -> Pokemon:
	return Kit.mon(_data, &"gyarados", level, [&"hyper_beam", &"bite"])


func test_hyper_beam_that_hits_forces_a_rest_next_turn() -> void:
	var mine := _beamer()
	var foe := Kit.mon(_data, &"geodude", 50, [&"growl"])
	var battle := _wild([mine], foe, [1, Kit.HIT, 50])
	battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_false(foe.is_fainted())
	assert_eq(battle.get_locked_move(), 0, "tour de repos imposé")
	assert_false(battle.is_legal(BattleAction.run()), "ni fuite")
	assert_false(battle.is_legal(BattleAction.move(1)), "ni autre capacité")
	_rng.push(Kit.draws([1, 50]))
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "le repos ne tire rien")
	assert_not_null(Kit.find(events, K.RECHARGING, P))
	assert_null(Kit.find(events, K.MOVE_USED, P), "le tour est perdu")
	assert_eq(mine.moves[0].pp, 4, "aucun PP au repos")
	assert_eq(battle.get_locked_move(), Battle.NO_LOCK, "un seul tour")


func test_hyper_beam_that_misses_needs_no_rest() -> void:
	var mine := _beamer()
	var foe := Kit.mon(_data, &"geodude", 50, [&"growl"])
	var battle := _wild([mine], foe, [1, 91, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(Kit.find(events, K.MOVE_MISSED, P))
	assert_eq(battle.get_locked_move(), Battle.NO_LOCK)


func test_hyper_beam_without_effect_needs_no_rest() -> void:
	var mine := _beamer()
	var foe := Kit.mon(_data, &"gastly", 50, [&"growl"])
	var battle := _wild([mine], foe, [1, Kit.HIT, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.NO_EFFECT, F), "Normal → Spectre")
	assert_eq(battle.get_locked_move(), Battle.NO_LOCK)


func test_hyper_beam_rests_even_after_a_ko_against_the_replacement() -> void:
	# Décision de Kevin du 2026-10-16 (2e génération ; en Rouge/Bleu, pas de repos après un K.O.).
	var mine := _beamer()
	var first := Kit.mon(_data, &"rattata", 5, [&"growl"])
	var next := Kit.mon(_data, &"pidgey", 5, [&"growl"])
	var battle := _trainer([mine], [first, next], [1, Kit.HIT])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_true(first.is_fainted())
	assert_eq(Kit.find(events, K.SENT_OUT, F).species_id, &"pidgey")
	assert_eq(battle.get_locked_move(), 0, "repos face au remplaçant")
	_rng.push(Kit.draws([1, 50]))
	events = battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(Kit.find(events, K.RECHARGING, P))
	assert_not_null(Kit.find(events, K.MOVE_USED, F), "le remplaçant agit")


func test_the_rest_is_cancelled_when_the_pokemon_is_forced_out() -> void:
	var mine := _beamer()
	var reserve := Kit.mon(_data, &"rattata", 5, [&"growl"])
	var foe := Kit.mon(_data, &"geodude", 50, [&"roar"])
	var battle := _trainer([mine, reserve], [foe], [1, Kit.HIT])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(Kit.find(events, K.FORCED_OUT, P), "Hurlement après l'Ultralaser")
	assert_eq(battle.get_player_side().active.pokemon, reserve)
	assert_eq(battle.get_locked_move(), Battle.NO_LOCK, "le remplaçant choisit librement")
	assert_true(battle.is_legal(BattleAction.move(0)))


func test_the_rest_is_cancelled_when_the_pokemon_faints_and_is_replaced() -> void:
	var mine := _beamer()
	mine.hp = 1
	var reserve := Kit.mon(_data, &"rattata", 5, [&"growl"])
	var foe := Kit.mon(_data, &"geodude", 50, [&"tackle"])
	var battle := _trainer([mine, reserve], [foe], [1, Kit.HIT, Kit.HIT])
	battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_true(mine.is_fainted())
	assert_true(battle.needs_replacement())
	battle.replace(1)
	assert_eq(battle.get_locked_move(), Battle.NO_LOCK)


func test_the_foe_ai_is_not_consulted_while_it_rests() -> void:
	var mine := Kit.mon(_data, &"geodude", 50, [&"growl"])
	var foe := Kit.mon(_data, &"gyarados", 40, [&"hyper_beam", &"bite"])
	# Tour 1 : IA roll(2) = 1 (Ultralaser), le sauvage plus rapide frappe, Rugissement du joueur.
	var battle := _wild([mine], foe, [1, Kit.HIT, 50])
	battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_false(mine.is_fainted())
	assert_true(battle.get_foe_side().active.is_recharging())
	assert_true(battle.get_foe_side().active.is_locked(), "ni changement de l'IA")
	# Tour 2 : aucun tirage d'IA (un roll(2) consommerait le 50 et échouerait).
	_rng.push([50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_rng.calls, 6, "tour 2 : la seule précision de Rugissement")
	assert_not_null(Kit.find(events, K.RECHARGING, F))
	assert_null(Kit.find(events, K.MOVE_USED, F))
	assert_eq(foe.moves[0].pp, 4)


func test_recharging_text() -> void:
	var texts := BattleText.new()
	assert_true(texts.load_file(), "\n".join(texts.get_errors()))
	var event := BattleEvent.new(K.RECHARGING, BattleEvent.SideId.FOE)
	event.pokemon_name = "Léviator"
	assert_eq(texts.lines(event, _data), PackedStringArray(["Léviator doit se reposer !"]))
