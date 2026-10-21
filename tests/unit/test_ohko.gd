extends GutTest
## K.O. en un coup (passe systèmes 2, `docs/tech/systemes-2.md` §2.11 ; Q-2 : règle moderne) :
## [OhkoRules], effet `ohko` dans le moteur, IA, données d'Empal'Korne.
##
## Tirages (voir `battle_kit_j12.gd`) : IA adverse (roll(n)), puis pour chaque Pokémon qui agit
## sa précision ; une capacité K.O. en un coup ne tire que sa précision (aucun tirage si elle
## échoue d'avance : niveau inférieur, type sans effet).

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

var _data: PokemonData
var _rng: Kit.ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _wild(mine: Pokemon, foe: Pokemon, draws: Array) -> Battle:
	_rng = Kit.ScriptedRng.new(Kit.draws(draws))
	return Kit.battle(_data, _rng, [mine], [foe])


# --- Règle pure -------------------------------------------------------------------------------

func test_accuracy_rises_with_the_level_gap() -> void:
	assert_eq(OhkoRules.accuracy(30, 20, 20), 30)
	assert_eq(OhkoRules.accuracy(30, 30, 20), 40)
	assert_eq(OhkoRules.accuracy(30, 100, 5), 100, "au plus 100 %")


func test_lower_level_never_hits() -> void:
	assert_false(OhkoRules.level_allows(19, 20))
	assert_true(OhkoRules.level_allows(20, 20))
	assert_eq(OhkoRules.accuracy(30, 19, 20), 0)


# --- Données ----------------------------------------------------------------------------------

func test_horn_drill_carries_the_effect() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))
	var move := _data.get_move(&"horn_drill")
	assert_not_null(move.effect_of(MoveEffect.Kind.OHKO))
	assert_eq(move.pending_effects.size(), 0)
	assert_false(move.description.contains("Sans effet"))
	assert_true(ChargeRules.targets_foe(move), "une cible sous terre l'évite")


# --- Combat -----------------------------------------------------------------------------------

func test_hit_takes_all_remaining_hp() -> void:
	var mine := Kit.mon(_data, &"rattata", 30, [&"horn_drill"])
	var foe := Kit.mon(_data, &"rattata", 10, [&"growl"])
	var hp_before := foe.hp
	var battle := _wild(mine, foe, [1, 50])
	var events := battle.submit(BattleAction.move(0))
	var damage := Kit.find(events, K.DAMAGE, F)
	assert_not_null(damage)
	assert_eq(damage.amount, hp_before)
	assert_eq(foe.hp, 0)
	assert_not_null(Kit.find(events, K.OHKO, F))
	assert_gt(Kit.index_of(events, K.OHKO), Kit.index_of(events, K.DAMAGE))
	assert_not_null(Kit.find(events, K.FAINTED, F))


func test_draw_above_the_chance_misses() -> void:
	var mine := Kit.mon(_data, &"rattata", 30, [&"horn_drill"])
	var foe := Kit.mon(_data, &"rattata", 10, [&"growl"])
	var hp_before := foe.hp
	# Chance 30 + 20 = 50 : 51 rate ; puis Rugissement adverse (précision).
	var battle := _wild(mine, foe, [1, 51, 1])
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.MOVE_MISSED, P))
	assert_null(Kit.find(events, K.OHKO))
	assert_eq(foe.hp, hp_before)
	assert_eq(_rng.remaining(), 0)


func test_lower_level_fails_without_a_draw() -> void:
	var mine := Kit.mon(_data, &"rattata", 10, [&"horn_drill"])
	var foe := Kit.mon(_data, &"rattata", 30, [&"growl"])
	# IA adverse, Rugissement adverse (plus rapide), puis l'échec sans tirage.
	var battle := _wild(mine, foe, [1, 1])
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.FAILED, P))
	assert_null(Kit.find(events, K.MOVE_MISSED, P))
	assert_null(Kit.find(events, K.OHKO))
	assert_eq(_rng.remaining(), 0)


func test_type_immunity_applies() -> void:
	var mine := Kit.mon(_data, &"rattata", 30, [&"horn_drill"])
	var foe := Kit.mon(_data, &"gastly", 10, [&"growl"])
	var battle := _wild(mine, foe, [1, 1])
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.NO_EFFECT, F), "Normal sur Spectre")
	assert_null(Kit.find(events, K.OHKO))
	assert_eq(_rng.remaining(), 0)


func test_message_text() -> void:
	var file := FileAccess.get_file_as_string("res://data/battle/messages.json")
	assert_true(file.contains("\"ohko\": { \"text\": \"C'est un K.O. en un coup !\" }"))


# --- IA ---------------------------------------------------------------------------------------

func test_ai_never_picks_it_when_it_fails_in_advance() -> void:
	var chart := _data.get_type_chart()
	var move := _data.get_move(&"horn_drill")
	var strong := _battler(&"rattata", 30)
	var weak := _battler(&"rattata", 10)
	var ghost := _battler(&"gastly", 10)
	assert_eq(BattleAI.score_move(move, weak, strong, chart, 0), 0.0, "niveau inférieur")
	assert_eq(BattleAI.score_move(move, strong, ghost, chart, 0), 0.0, "type sans effet")
	assert_almost_eq(BattleAI.score_move(move, strong, weak, chart, 0),
		BattleAI.STATUS_SCORE * 0.5, 0.001, "précision selon les niveaux (50 %)")


func _battler(species: StringName, level: int) -> Battler:
	return Battler.new(Kit.mon(_data, species, level, [&"growl"]),
		_data.get_species(species).types)
