extends GutTest
## Statuts du J11 dans le moteur (`jalon-11.md` §2.2, dossier 14 §3.1) : paralysie, sommeil,
## brûlure, gel ; immunités ; ordre d'action ; capacités de statut qui échouent.
##
## N5, IV 0 : Pikachu Vit 14 ; Salamèche Vit 11 ; Bulbizarre N7 Vit 11 ; Roucool N3 Vit 8
## (Tornade seule) ; Racaillou N5 Vit 7. Tirages : IA adverse (roll(1) avec une capacité), puis
## pour chaque Pokémon qui agit : statut (roll(100) pour la paralysie et le gel), précision,
## critique (2 = non), aléatoire (16) ; effet à chance (roll(100)) ; sommeil (roll(3)).

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

var _data: PokemonData
var _rng: ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _mon(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))


func _with_move(species: StringName, level: int, move_id: StringName) -> Pokemon:
	var pokemon := _mon(species, level)
	pokemon.moves.clear()
	pokemon.moves.append(MoveSlot.new(move_id, _data.get_move(move_id).pp))
	return pokemon


func _battle(player: Pokemon, foe: Pokemon, draws: Array[int]) -> Battle:
	_rng = ScriptedRng.new(draws)
	var party := Party.new()
	party.add(player)
	var foes := Party.new()
	foes.add(foe)
	var battle := Battle.new(BattleSide.new(party, true), BattleSide.new(foes, false, ""), _data,
		_rng, BattleRules.for_wild())
	battle.start()
	return battle


func _kinds(events: Array[BattleEvent]) -> Array:
	var result: Array = []
	for event: BattleEvent in events:
		if event.kind != K.TURN_STARTED:
			result.append([K.find_key(event.kind), BattleEvent.SideId.find_key(event.side)])
	return result


func _find(events: Array[BattleEvent], kind: BattleEvent.Kind) -> BattleEvent:
	for event: BattleEvent in events:
		if event.kind == kind:
			return event
	return null


# --- Paralysie -----------------------------------------------------------------------------

func test_thunder_wave_paralyses_then_full_paralysis_skips_the_turn() -> void:
	var pidgey := _with_move(&"pidgey", 3, &"gust")
	var battle := _battle(_with_move(&"pikachu", 5, &"thunder_wave"), pidgey,
		[1, 50, 99, 50, 2, 16])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "tirages consommés")
	var inflicted := _find(events, K.STATUS_INFLICTED)
	assert_eq([inflicted.status, inflicted.side], [StatusRules.PARALYSIS, F])
	assert_eq(pidgey.status, StatusRules.PARALYSIS)
	assert_not_null(_find(events, K.DAMAGE), "Roucool agit (99 > 25)")
	# Tour 2 : déjà paralysé (même statut) ; Roucool totalement paralysé (25).
	_rng.push([1, 50, 25])
	events = battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_kinds(events), [["MOVE_USED", "PLAYER"], ["STATUS_UNCHANGED", "FOE"],
		["STATUS_PREVENTED", "FOE"]])
	assert_eq(_find(events, K.STATUS_PREVENTED).status, StatusRules.PARALYSIS)
	assert_eq(pidgey.moves[0].pp, pidgey.moves[0].max_pp - 1, "aucun PP dépensé ce tour-ci")


func test_paralysis_halves_speed_in_the_turn_order() -> void:
	# Salamèche Vit 11 paralysé → 5 < Roucool 8 : Roucool agit d'abord.
	var charmander := _with_move(&"charmander", 5, &"scratch")
	charmander.status = StatusRules.PARALYSIS
	var battle := _battle(charmander, _with_move(&"pidgey", 3, &"gust"),
		[1, 50, 2, 16, 99, 50, 2, 16])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_kinds(events).slice(0, 2), [["MOVE_USED", "FOE"], ["DAMAGE", "PLAYER"]])


func test_electric_types_are_immune_and_ground_ignores_thunder_wave() -> void:
	var battle := _battle(_with_move(&"pikachu", 5, &"thunder_wave"),
		_with_move(&"pikachu", 5, &"thunder_wave"), [1, 1, 50, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_find(events, K.NO_EFFECT).side, F, "Électrik : immunisé")
	assert_null(_find(events, K.STATUS_INFLICTED))
	var geodude := _with_move(&"geodude", 5, &"defense_curl")
	battle = _battle(_with_move(&"pikachu", 5, &"thunder_wave"), geodude, [1, 50])
	events = battle.submit(BattleAction.move(0))
	assert_eq(_find(events, K.NO_EFFECT).side, F, "Sol : sans effet")
	assert_eq(geodude.status, StatusRules.NONE)


func test_a_status_move_on_a_target_with_another_status_fails() -> void:
	var pidgey := _with_move(&"pidgey", 3, &"gust")
	pidgey.status = StatusRules.POISON
	var battle := _battle(_with_move(&"pikachu", 5, &"thunder_wave"), pidgey,
		[1, 50, 50, 2, 16])
	var events := battle.submit(BattleAction.move(0))
	var failed := _find(events, K.FAILED)
	assert_eq([failed.side, failed.move_id], [P, &"thunder_wave"], "« Mais ça échoue ! »")
	assert_null(_find(events, K.STATUS_UNCHANGED))
	assert_eq(pidgey.status, StatusRules.POISON)


# --- Sommeil -------------------------------------------------------------------------------

func test_sleep_powder_skips_the_drawn_turns_then_wakes_and_acts_the_same_turn() -> void:
	var pidgey := _with_move(&"pidgey", 3, &"gust")
	var battle := _battle(_with_move(&"bulbasaur", 7, &"sleep_powder"), pidgey, [1, 50, 2])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(pidgey.status, StatusRules.SLEEP)
	assert_eq(_find(events, K.STATUS_PREVENTED).status, StatusRules.SLEEP, "dort dès ce tour")
	assert_eq(pidgey.status_turns, 1, "2 tirés, 1 déjà passé")
	_rng.push([1, 50])
	events = battle.submit(BattleAction.move(0))
	assert_not_null(_find(events, K.STATUS_UNCHANGED), "déjà endormi")
	assert_not_null(_find(events, K.STATUS_PREVENTED))
	assert_eq(pidgey.status_turns, 0)
	_rng.push([1, 50, 50, 2, 16])
	events = battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_find(events, K.STATUS_ENDED).status, StatusRules.SLEEP, "se réveille")
	assert_not_null(_find(events, K.DAMAGE), "et agit dans le même tour")
	assert_eq(pidgey.status, StatusRules.NONE)


func test_the_sleep_counter_is_kept_after_the_battle_and_saved() -> void:
	var rattata := _mon(&"rattata", 3)
	StatusRules.apply(StatusRules.SLEEP, rattata, ScriptedRng.new([3]))
	var copy := Pokemon.from_dict(JSON.parse_string(JSON.stringify(rattata.to_dict())), _data)
	assert_eq([copy.status, copy.status_turns], [StatusRules.SLEEP, 3])


# --- Brûlure -------------------------------------------------------------------------------

func test_burn_takes_a_sixteenth_at_the_end_of_the_turn() -> void:
	var charmander := _with_move(&"charmander", 5, &"scratch")
	var pidgey := _with_move(&"pidgey", 3, &"gust")
	pidgey.status = StatusRules.BURN
	var battle := _battle(charmander, pidgey, [1, 50, 2, 16, 50, 2, 16])
	var events := battle.submit(BattleAction.move(0))
	var damaged := _find(events, K.STATUS_DAMAGED)
	assert_eq([damaged.status, damaged.side, damaged.amount], [StatusRules.BURN, F, 1],
		"1/16 de 15 PV : au moins 1")


func test_a_burned_attacker_deals_half_physical_damage() -> void:
	var chart := _data.get_type_chart()
	var scratch := _data.get_move(&"scratch")
	var attacker := Battler.new(_mon(&"charmander", 30), [&"fire"] as Array[StringName])
	var defender := Battler.new(_mon(&"rattata", 30), [&"normal"] as Array[StringName])
	var normal := DamageCalc.compute(attacker, defender, scratch, chart, ScriptedRng.new([50, 2, 16]))
	attacker.pokemon.status = StatusRules.BURN
	var burned := DamageCalc.compute(attacker, defender, scratch, chart, ScriptedRng.new([50, 2, 16]))
	assert_eq(burned.amount, maxi(normal.amount / 2, 1), "physique ÷ 2")
	var ember := _data.get_move(&"ember")
	var special_normal := DamageCalc.compute(attacker, defender, ember, chart,
		ScriptedRng.new([50, 2, 16]))
	attacker.pokemon.status = StatusRules.NONE
	var special := DamageCalc.compute(attacker, defender, ember, chart,
		ScriptedRng.new([50, 2, 16]))
	assert_eq(special_normal.amount, special.amount, "spéciale : inchangée")


func test_ember_burns_on_10_or_less_and_fire_types_are_immune() -> void:
	var pidgey := _with_move(&"pidgey", 3, &"gust")
	var battle := _battle(_with_move(&"charmander", 5, &"ember"), pidgey,
		[1, 50, 2, 16, 10, 50, 2, 16])
	var events := battle.submit(BattleAction.move(0))
	assert_false(pidgey.is_fainted(), "Flammèche : 9 PV sur 15")
	assert_eq(_find(events, K.STATUS_INFLICTED).status, StatusRules.BURN)
	var other := _with_move(&"charmander", 5, &"scratch")
	battle = _battle(_with_move(&"charmander", 5, &"ember"), other, [1, 1, 50, 2, 16, 1, 50, 2, 16])
	events = battle.submit(BattleAction.move(0))
	assert_eq(other.status, StatusRules.NONE, "Feu : jamais brûlé (refus silencieux)")


# --- Gel ------------------------------------------------------------------------------------

func test_a_frozen_pokemon_cannot_act_then_thaws_on_20_or_less() -> void:
	var pidgey := _with_move(&"pidgey", 3, &"gust")
	StatusRules.apply(StatusRules.FREEZE, pidgey, ScriptedRng.new())
	var battle := _battle(_with_move(&"charmander", 5, &"growl"), pidgey, [1, 50, 21])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_find(events, K.STATUS_PREVENTED).status, StatusRules.FREEZE)
	_rng.push([1, 50, 20, 50, 2, 16])
	events = battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_find(events, K.STATUS_ENDED).status, StatusRules.FREEZE, "dégel")
	assert_not_null(_find(events, K.DAMAGE), "il agit dans le même tour")


func test_a_fire_move_thaws_its_target() -> void:
	var rattata := _with_move(&"rattata", 3, &"tail_whip")
	StatusRules.apply(StatusRules.FREEZE, rattata, ScriptedRng.new())
	var battle := _battle(_with_move(&"charmander", 5, &"ember"), rattata,
		[1, 50, 2, 16, 99, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	var ended := _find(events, K.STATUS_ENDED)
	assert_eq([ended.status, ended.side], [StatusRules.FREEZE, F])
	assert_lt(events.find(_find(events, K.DAMAGE)), events.find(ended), "après le coup")
	assert_eq(rattata.status, StatusRules.NONE)


# --- Capture --------------------------------------------------------------------------------

func test_capture_uses_the_status_bonus() -> void:
	assert_eq(StatusRules.catch_bonus(StatusRules.SLEEP), 2.5)
	assert_eq(StatusRules.catch_bonus(StatusRules.PARALYSIS), 1.5)
