extends GutTest
## Drain d'une attaque (Vampirisme ; `jalon-12.md` §2.10, dossier 15 §20 n° 41 et 46) : le lanceur
## récupère la moitié des dégâts portés (au moins 1), plafonnée à ses PV max ; rien à PV pleins ;
## distinct de la Vampigraine (DRAINED).
##
## IV 0. Nosferapti N10 (Vit 16) plus rapide que Bulbizarre N10 (Vit 14), qui ne fait que
## Boul'Armure (aucun tirage). Tirages : IA (roll(1)), Vampirisme (précision, critique, aléatoire).

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

var _data: PokemonData
var _rng: Kit.ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _battle(foe_level: int = 10) -> Battle:
	_rng = Kit.ScriptedRng.new(Kit.draws([1, Kit.HIT]))
	return Kit.battle(_data, _rng, [Kit.mon(_data, &"zubat", 10, [&"leech_life"])],
		[Kit.mon(_data, &"bulbasaur", foe_level, [&"defense_curl"])])


func test_the_user_recovers_half_the_damage_dealt() -> void:
	var battle := _battle()
	var zubat := battle.get_player_side().active.pokemon
	zubat.hp = 1
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	var damage := Kit.find(events, K.DAMAGE, F)
	var drained := Kit.find(events, K.DRAINED_HP, P)
	assert_not_null(drained)
	assert_eq(drained.amount, maxi(floori(damage.amount * 0.5), 1), "½, au moins 1")
	assert_eq(drained.hp, 1 + drained.amount)
	assert_eq(zubat.hp, drained.hp)
	assert_eq(Kit.index_of(events, K.DRAINED_HP), Kit.index_of(events, K.DAMAGE, F) + 1,
		"juste après les dégâts")
	assert_null(Kit.find(events, K.DRAINED), "pas la Vampigraine")
	var texts := BattleText.new()
	texts.load_file()
	assert_eq(Array(texts.lines(drained, _data)), ["Nosferapti récupère des PV !"])


func test_the_heal_is_capped_at_max_hp() -> void:
	var battle := _battle()
	var zubat := battle.get_player_side().active.pokemon
	zubat.hp = zubat.max_hp() - 1
	var drained := Kit.find(battle.submit(BattleAction.move(0)), K.DRAINED_HP, P)
	assert_eq(drained.amount, 1, "un seul PV manquait")
	assert_eq(zubat.hp, zubat.max_hp())


func test_nothing_at_full_hp() -> void:
	var battle := _battle()
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.DAMAGE, F))
	assert_null(Kit.find(events, K.DRAINED_HP), "PV pleins : ni soin ni phrase")


func test_nothing_when_the_move_misses() -> void:
	var battle := _battle()
	var zubat := battle.get_player_side().active.pokemon
	zubat.hp = 1
	# Esquive +6 de la cible : seuil 100 × 3/9 = 33 ; 50 rate.
	battle.get_foe_side().active.change_stage(&"eva", 6)
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(Kit.find(events, K.MOVE_MISSED, P))
	assert_null(Kit.find(events, K.DRAINED_HP))
	assert_eq(zubat.hp, 1)


func test_the_drain_still_heals_when_the_target_faints() -> void:
	var battle := _battle()
	var zubat := battle.get_player_side().active.pokemon
	zubat.hp = 1
	battle.get_foe_side().active.pokemon.hp = 1
	var events := battle.submit(BattleAction.move(0))
	var drained := Kit.find(events, K.DRAINED_HP, P)
	assert_eq(drained.amount, 1, "1 PV porté : ½ arrondi, au moins 1")
	assert_lt(Kit.index_of(events, K.DRAINED_HP), Kit.index_of(events, K.FAINTED, F),
		"le soin avant le K.O.")
