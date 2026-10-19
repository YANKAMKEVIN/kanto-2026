extends GutTest
## Flash en combat (jalon 17, dossier 20 §8.1, `jalon-17.md` §2.9 ; Q-1 « tout J17 », tranchée
## le 2026-10-16) : Normal, statut, précision 70 %, PP 20, Précision de l'adversaire −1 (RB).
## Aucune ligne de moteur : l'effet est celui de Jet de Sable, lu dans les données.

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const F := BattleEvent.SideId.FOE

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))


func test_flash_data() -> void:
	var move := _data.get_move(&"flash")
	assert_not_null(move)
	if move == null:
		return
	assert_eq([move.name, move.type, move.accuracy, move.pp], ["Flash", &"normal", 70, 20])
	assert_eq(move.category, MoveData.Category.STATUS)
	assert_eq(move.description, "Une lumière aveuglante qui baisse la précision de l'ennemi.",
		"T-16")
	assert_true(move.pending_effects.is_empty(), "effet joué par le moteur")


## Tirage de précision 70 : touche ; la Précision de l'adversaire baisse d'un cran.
func test_flash_lowers_foe_accuracy_by_one() -> void:
	var rng := Kit.ScriptedRng.new([1, 70])
	var foe := Kit.mon(_data, &"geodude", 20, [&"defense_curl"])
	var battle := Kit.battle(_data, rng, [Kit.mon(_data, &"drowzee", 20, [&"flash"])], [foe])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(rng.remaining(), 0)
	var changed := _accuracy_change(events)
	assert_not_null(changed, "Précision de l'adversaire baissée")
	if changed != null:
		assert_eq(changed.stages, -1)
	assert_null(Kit.find(events, K.MOVE_MISSED))
	assert_eq(battle.get_foe_side().active.get_stage(&"acc"), -1)
	assert_eq(battle.get_player_side().active.get_stage(&"acc"), 0, "le lanceur n'y gagne rien")


## Tirage 71 : rate (précision 70 %), aucun cran perdu.
func test_flash_can_miss() -> void:
	var rng := Kit.ScriptedRng.new([1, 71])
	var foe := Kit.mon(_data, &"geodude", 20, [&"defense_curl"])
	var battle := Kit.battle(_data, rng, [Kit.mon(_data, &"drowzee", 20, [&"flash"])], [foe])
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.MOVE_MISSED), "Flash rate")
	assert_null(_accuracy_change(events))
	assert_eq(battle.get_foe_side().active.get_stage(&"acc"), 0)


## Baisse de Précision de l'adversaire parmi [param events] (Boul'Armure de l'adversaire, elle,
## touche sa Défense).
func _accuracy_change(events: Array[BattleEvent]) -> BattleEvent:
	for event: BattleEvent in events:
		if event.kind == K.STAT_CHANGED and event.side == F and event.stat == &"acc":
			return event
	return null
