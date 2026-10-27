extends GutTest
## Abîme (`fissure`, jalon 28, `docs/tech/jalon-28.md` §2.2, §5) : données (type Sol, précision 30,
## 5 PP, effet `ohko`, CT27) et K.O. en un coup dans le moteur (règle de la passe systèmes 2,
## modèle `test_ohko.gd`) : K.O. sur une cible de niveau inférieur ou égal, échec sur un niveau
## supérieur, aucun effet sur un Pokémon Vol.
##
## Tirages (voir `battle_kit_j12.gd`) : IA adverse (roll(n)), puis la précision de la capacité ;
## une capacité K.O. en un coup n'en tire aucun si elle échoue d'avance (niveau, type).

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


# --- Données ----------------------------------------------------------------------------------

func test_fissure_data() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))
	var move := _data.get_move(&"fissure")
	assert_not_null(move, "Abîme existe")
	assert_eq(move.name, "Abîme")
	assert_eq(move.type, &"ground")
	assert_eq(move.accuracy, 30)
	assert_eq(move.pp, 5)
	assert_not_null(move.effect_of(MoveEffect.Kind.OHKO), "effet K.O. en un coup")
	assert_eq(move.pending_effects.size(), 0)
	assert_false(move.description.contains("Sans effet"))


func test_tm27_teaches_fissure() -> void:
	var items := ItemLibrary.new()
	assert_true(items.load_dir(), "\n".join(items.get_errors()))
	var tm := items.get_item(&"tm27")
	assert_not_null(tm, "CT27 existe")
	assert_eq(tm.name, "CT27 — Abîme")
	assert_eq(tm.tm_number, 27)
	assert_eq(tm.teaches, &"fissure")
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/pokemon/tm_compatibility.json"))
	assert_true(parsed is Dictionary)
	var tms: Dictionary = (parsed as Dictionary)["tms"]
	assert_eq(tms["27"], "fissure", "tm_compatibility.json : CT27 = Abîme")
	assert_eq(tms["26"], "earthquake", "la CT26 reste Séisme")


# --- Combat -----------------------------------------------------------------------------------

func test_hit_on_a_lower_level_takes_all_remaining_hp() -> void:
	var mine := Kit.mon(_data, &"rattata", 30, [&"fissure"])
	var foe := Kit.mon(_data, &"rattata", 10, [&"growl"])
	var hp_before := foe.hp
	var battle := _wild(mine, foe, [1, 50])
	var events := battle.submit(BattleAction.move(0))
	var damage := Kit.find(events, K.DAMAGE, F)
	assert_not_null(damage)
	assert_eq(damage.amount, hp_before, "tous les PV restants")
	assert_eq(foe.hp, 0)
	assert_not_null(Kit.find(events, K.OHKO, F))
	assert_not_null(Kit.find(events, K.FAINTED, F))


func test_hit_on_an_equal_level_with_a_draw_of_30() -> void:
	var mine := Kit.mon(_data, &"rattata", 20, [&"fissure"])
	var foe := Kit.mon(_data, &"geodude", 20, [&"growl"])
	# Niveau égal : précision 30 % ; 30 touche, 31 rate (Ratta plus rapide : pas d'égalité de
	# vitesse à départager).
	var battle := _wild(mine, foe, [1, 30])
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.OHKO, F), "tirage 30 : K.O.")
	assert_eq(foe.hp, 0)
	var other_foe := Kit.mon(_data, &"geodude", 20, [&"growl"])
	var hp_before := other_foe.hp
	var missed := _wild(Kit.mon(_data, &"rattata", 20, [&"fissure"]), other_foe, [1, 31, 1])
	events = missed.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.MOVE_MISSED, P), "tirage 31 : raté")
	assert_null(Kit.find(events, K.OHKO))
	assert_eq(other_foe.hp, hp_before)


func test_higher_level_target_fails_without_a_draw() -> void:
	var mine := Kit.mon(_data, &"rattata", 10, [&"fissure"])
	var foe := Kit.mon(_data, &"rattata", 30, [&"growl"])
	var hp_before := foe.hp
	# IA adverse, Rugissement adverse (plus rapide), puis l'échec sans tirage.
	var battle := _wild(mine, foe, [1, 1])
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.FAILED, P), "échec : niveau supérieur")
	assert_null(Kit.find(events, K.MOVE_MISSED, P))
	assert_null(Kit.find(events, K.OHKO))
	assert_eq(foe.hp, hp_before)
	assert_eq(_rng.remaining(), 0)


func test_flying_target_is_not_affected() -> void:
	var mine := Kit.mon(_data, &"rattata", 30, [&"fissure"])
	var foe := Kit.mon(_data, &"pidgey", 10, [&"growl"])
	var hp_before := foe.hp
	var battle := _wild(mine, foe, [1, 1])
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.NO_EFFECT, F), "Sol sur Vol : aucun effet")
	assert_null(Kit.find(events, K.OHKO))
	assert_eq(foe.hp, hp_before)
	assert_eq(_rng.remaining(), 0)
