extends GutTest
## Piège du jalon 12 (Ligotage, Étreinte, Danse Flamme ; `jalon-12.md` §2.10, dossier 15 C-1) :
## 4–5 fins de tour à ⅛ des PV max, ni fuite ni changement (sans tour perdu), libération, fin
## quand le lanceur quitte le terrain ou tombe, remplacement après un K.O. permis, capture permise,
## ordre de fin de tour (graine, statut, piège), phrases par capacité.
##
## IV 0. Bulbizarre N20 (Vit 23, 48 PV : ⅛ = 6) plus rapide qu'Abo N10 (Vit 16). Tirages d'un
## tour : IA d'Abo (roll(1)), Ligotage (précision, critique, aléatoire), puis la durée du piège
## (roll(2) : 1 → 4 tours, 2 → 5) ; Boul'Armure ne tire rien.

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

var _data: PokemonData
var _rng: Kit.ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _bulbasaur() -> Pokemon:
	return Kit.mon(_data, &"bulbasaur", 20, [&"defense_curl"])


func _ekans() -> Pokemon:
	return Kit.mon(_data, &"ekans", 10, [&"wrap"])


## Le joueur (Bulbizarre, puis Salamèche en réserve) contre Abo sauvage qui ligote.
func _player_wrapped(first_draws: Array) -> Battle:
	_rng = Kit.ScriptedRng.new(Kit.draws(first_draws))
	return Kit.battle(_data, _rng, [_bulbasaur(), Kit.mon(_data, &"charmander", 10,
		[&"defense_curl"])], [_ekans()])


func test_trap_lasts_four_end_of_turns_at_an_eighth_then_frees() -> void:
	var battle := _player_wrapped([1, Kit.HIT, 1])
	var bulbasaur := battle.get_player_side().active.pokemon
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "tirages consommés")
	var trapped := Kit.find(events, K.TRAPPED, P)
	assert_not_null(trapped, "Bulbizarre est ligoté")
	assert_eq(trapped.move_id, &"wrap")
	assert_gt(Kit.index_of(events, K.TRAPPED), Kit.index_of(events, K.DAMAGE, P),
		"après les dégâts")
	var hurt := Kit.find(events, K.TRAP_DAMAGED, P)
	assert_eq(hurt.amount, maxi(floori(bulbasaur.max_hp() / 8.0), 1), "⅛ des PV max")
	assert_eq(hurt.amount, 6)
	assert_eq(hurt.hp, bulbasaur.hp)
	assert_eq(hurt.move_id, &"wrap")
	assert_true(battle.is_player_trapped())
	for turn: int in [2, 3, 4]:
		_rng.push(Kit.draws([1, Kit.HIT]))
		events = battle.submit(BattleAction.move(0))
		assert_eq(_rng.remaining(), 0, "tour %d : déjà piégé, aucune durée tirée" % turn)
		assert_null(Kit.find(events, K.TRAPPED), "tour %d : pas de nouveau piège" % turn)
		assert_eq(Kit.count(events, K.TRAP_DAMAGED), 1, "tour %d" % turn)
		if turn == 2:
			assert_eq(battle.get_player_side().active.trap_turns, 2, "compteur inchangé")
		if turn < 4:
			assert_true(battle.is_player_trapped(), "tour %d" % turn)
	assert_eq(Kit.index_of(events, K.TRAP_ENDED, P), Kit.index_of(events, K.TRAP_DAMAGED) + 1,
		"libéré juste après la quatrième perte")
	assert_false(battle.is_player_trapped())
	assert_true(battle.is_legal(BattleAction.run()))
	assert_true(battle.is_legal(BattleAction.switch_to(1)))


func test_five_turns_on_the_high_draw() -> void:
	var battle := _player_wrapped([1, Kit.HIT, 2])
	var damaged := 0
	var ended := false
	for turn: int in 6:
		if turn > 0:
			_rng.push(Kit.draws([1, Kit.HIT]))
		var events := battle.submit(BattleAction.move(0))
		damaged += Kit.count(events, K.TRAP_DAMAGED)
		if Kit.find(events, K.TRAP_ENDED) != null:
			assert_eq(turn, 4, "libéré à la cinquième fin de tour")
			assert_eq(damaged, 5)
			ended = true
			break
	assert_true(ended)


func test_flee_and_switch_are_refused_without_losing_the_turn() -> void:
	var battle := _player_wrapped([1, Kit.HIT, 1])
	battle.submit(BattleAction.move(0))
	assert_true(battle.is_player_trapped())
	assert_true(battle.can_flee(), "le bouton FUITE reste là")
	assert_false(battle.is_legal(BattleAction.run()))
	assert_false(battle.is_legal(BattleAction.switch_to(1)))
	assert_eq(battle.check_switch(1), Battle.SwitchCheck.OK, "la place elle-même est valide")
	assert_true(battle.is_legal(BattleAction.move(0)), "attaquer reste permis")
	var turn := battle.get_turn()
	assert_eq(battle.submit(BattleAction.run()).size(), 0)
	assert_eq(battle.submit(BattleAction.switch_to(1)).size(), 0)
	assert_push_error_count(2)
	assert_eq(battle.get_turn(), turn, "aucun tour joué")
	assert_eq(battle.get_state(), Battle.State.CHOOSING)


func test_end_of_turn_order_is_seed_then_status_then_trap() -> void:
	var battle := _player_wrapped([1, Kit.HIT, 1])
	var mine := battle.get_player_side().active
	mine.seed_fraction = 0.125
	mine.pokemon.status = StatusRules.POISON
	var events := battle.submit(BattleAction.move(0))
	var seed := Kit.index_of(events, K.DRAINED, P)
	var poison := Kit.index_of(events, K.STATUS_DAMAGED, P)
	var trap := Kit.index_of(events, K.TRAP_DAMAGED, P)
	assert_true(seed >= 0 and poison > seed and trap > poison, "graine, poison, piège")


func test_the_caster_leaving_the_field_frees_the_target_silently() -> void:
	_rng = Kit.ScriptedRng.new(Kit.draws([1, Kit.HIT, 1]))
	var battle := Kit.battle(_data, _rng, [_ekans(), Kit.mon(_data, &"charmander", 10,
		[&"defense_curl"])], [_bulbasaur()])
	battle.submit(BattleAction.move(0))
	var foe := battle.get_foe_side().active
	assert_true(foe.is_trapped(), "Bulbizarre sauvage ligoté")
	_rng.push([1])
	var events := battle.submit(BattleAction.switch_to(1))
	assert_eq(_rng.remaining(), 0)
	assert_false(foe.is_trapped(), "Abo rappelé : le piège tombe")
	assert_null(Kit.find(events, K.TRAP_DAMAGED))
	assert_null(Kit.find(events, K.TRAP_ENDED), "sans phrase")


func test_the_caster_fainting_frees_the_target() -> void:
	_rng = Kit.ScriptedRng.new(Kit.draws([1, Kit.HIT, 1]))
	var bulbasaur := Kit.mon(_data, &"bulbasaur", 20, [&"defense_curl", &"tackle"])
	var ekans := _ekans()
	var battle := Kit.battle(_data, _rng, [bulbasaur], [ekans, Kit.mon(_data, &"rattata", 5,
		[&"defense_curl"])], "Sbire", BattleRules.for_trainer())
	battle.submit(BattleAction.move(0))
	assert_true(battle.is_player_trapped())
	ekans.hp = 1
	_rng.push(Kit.draws([1, Kit.HIT]))
	var events := battle.submit(BattleAction.move(1))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(Kit.find(events, K.FAINTED, F))
	assert_null(Kit.find(events, K.TRAP_DAMAGED), "lanceur K.O. : plus de perte")
	assert_null(Kit.find(events, K.TRAP_ENDED))
	assert_false(battle.is_player_trapped())
	assert_eq(battle.get_foe_side().active.pokemon.species_id, &"rattata")


func test_forced_replacement_after_a_ko_is_allowed_while_trapped() -> void:
	var battle := _player_wrapped([1, Kit.HIT, 1])
	battle.submit(BattleAction.move(0))
	assert_true(battle.is_player_trapped())
	battle.get_player_side().active.pokemon.hp = 1
	_rng.push(Kit.draws([1, Kit.HIT]))
	battle.submit(BattleAction.move(0))
	assert_true(battle.needs_replacement(), "Bulbizarre K.O.")
	assert_eq(battle.replace(1).size(), 1, "SENT_OUT : le remplacement reste permis")
	assert_false(battle.is_player_trapped(), "le nouveau n'est pas piégé")
	assert_true(battle.is_legal(BattleAction.run()))


func test_a_trapped_wild_pokemon_can_be_caught() -> void:
	var items := ItemLibrary.new()
	items.load_dir()
	_rng = Kit.ScriptedRng.new(Kit.draws([1, Kit.HIT, 1]))
	var battle := Kit.battle(_data, _rng, [_ekans()], [Kit.mon(_data, &"bulbasaur", 5,
		[&"defense_curl"])], "", BattleRules.for_wild(items))
	battle.submit(BattleAction.move(0))
	assert_true(battle.get_foe_side().active.is_trapped())
	assert_true(battle.is_legal(BattleAction.ball(&"poke_ball")))
	_rng.push([1, 1, 1, 1, 1])
	battle.submit(BattleAction.ball(&"poke_ball"))
	assert_eq(battle.get_outcome(), Battle.Outcome.CAUGHT)


func test_a_ko_by_the_trap_follows_the_usual_path() -> void:
	_rng = Kit.ScriptedRng.new(Kit.draws([1, Kit.HIT, 1]))
	var battle := Kit.battle(_data, _rng, [_ekans()], [_bulbasaur()])
	battle.submit(BattleAction.move(0))
	battle.get_foe_side().active.pokemon.hp = 1
	# Ligotage rate (95 > 90) : seul le piège de fin de tour met Bulbizarre K.O.
	_rng.push([1, 95])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	var hurt := Kit.index_of(events, K.TRAP_DAMAGED, F)
	assert_gt(hurt, 0)
	assert_eq(events[hurt].hp, 0)
	assert_eq(Kit.index_of(events, K.FAINTED, F), hurt + 1, "FAINTED juste après")
	assert_null(Kit.find(events, K.TRAP_ENDED))
	assert_eq(events[-1].kind, K.BATTLE_ENDED)
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)


func test_trap_texts_are_the_validated_ones_per_move() -> void:
	var texts := BattleText.new()
	assert_true(texts.load_file())
	var expected := {
		&"wrap": ["Abo est ligoté !", "Abo est ligotée !", "Abo souffre du Ligotage !"],
		&"bind": ["Abo est pris dans l'Étreinte !", "Abo est prise dans l'Étreinte !",
			"Abo souffre de l'Étreinte !"],
		&"fire_spin": ["Abo est pris dans un tourbillon de flammes !",
			"Abo est prise dans un tourbillon de flammes !", "Abo souffre de la Danse Flamme !"],
		# Jalon 13 (annexe A.3 de jalon-13.md) : Claquoir.
		&"clamp": ["Abo est pris dans le Claquoir !", "Abo est prise dans le Claquoir !",
			"Abo souffre du Claquoir !"],
	}
	for move_id: StringName in expected:
		var lines: Array = []
		for gender: Pokemon.Gender in [Pokemon.Gender.MALE, Pokemon.Gender.FEMALE]:
			lines.append_array(Array(texts.lines(_event(K.TRAPPED, move_id, gender), _data)))
		lines.append_array(Array(texts.lines(_event(K.TRAP_DAMAGED, move_id), _data)))
		assert_eq(lines, expected[move_id], String(move_id))
	assert_eq(Array(texts.lines(_event(K.TRAP_ENDED, &"wrap"), _data)), ["Abo est libéré !"])
	assert_eq(Array(texts.lines(_event(K.TRAP_ENDED, &"bind", Pokemon.Gender.FEMALE), _data)),
		["Abo est libérée !"])
	assert_eq(texts.get_template(&"switch_reason_trapped"), "Impossible de changer")
	assert_eq(texts.get_template(&"flee_failed"), "Impossible de fuir !")


func test_every_trap_family_has_its_two_templates() -> void:
	var texts := BattleText.new()
	assert_true(texts.load_file())
	for family: StringName in MoveEffect.TRAP_MESSAGES:
		for stage: String in ["started", "damaged"]:
			assert_ne(texts.get_template(StringName("trap_%s_%s" % [family, stage])), "",
				"%s %s" % [family, stage])
	for id: StringName in _data.get_move_ids():
		var trap := _data.get_move(id).effect_of(MoveEffect.Kind.TRAP)
		if trap != null:
			assert_true(MoveEffect.TRAP_MESSAGES.has(trap.messages), String(id))


func _event(kind: BattleEvent.Kind, move_id: StringName,
		gender: Pokemon.Gender = Pokemon.Gender.MALE) -> BattleEvent:
	var event := BattleEvent.new(kind, F)
	event.pokemon_name = "Abo"
	event.species_id = &"ekans"
	event.gender = gender
	event.move_id = move_id
	return event
