extends GutTest
## Repos (jalon 12 ; `jalon-12.md` §2.10 et §0.4 n° 1, dossier 15 C-3, §20 n° 44 et 46) : statut
## soigné, PV pleins, sommeil sans tirage (compteur 2) : le lanceur manque exactement deux
## tentatives et agit à la troisième ; échec à PV pleins ; Réveil du J11 s'applique.
##
## IV 0. Bulbizarre N10 (Vit 14) plus rapide que Rondoudou N15 (Vit 11) ; Boul'Armure et Repos ne
## tirent rien : un tour = l'IA de Bulbizarre (roll(1)).

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER

var _data: PokemonData
var _rng: Kit.ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _battle(rules: BattleRules = null) -> Battle:
	_rng = Kit.ScriptedRng.new([1])
	return Kit.battle(_data, _rng,
		[Kit.mon(_data, &"jigglypuff", 15, [&"rest", &"defense_curl"])],
		[Kit.mon(_data, &"bulbasaur", 10, [&"defense_curl"])], "", rules)


func test_rest_fails_at_full_hp() -> void:
	var battle := _battle()
	var jiggly := battle.get_player_side().active.pokemon
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(Kit.find(events, K.FAILED, P))
	assert_null(Kit.find(events, K.RESTED))
	assert_eq(jiggly.status, StatusRules.NONE)
	assert_eq(jiggly.moves[0].pp, _data.get_move(&"rest").pp - 1, "le PP est dépensé")


func test_rest_heals_cures_and_sleeps_exactly_two_turns() -> void:
	var battle := _battle()
	var jiggly := battle.get_player_side().active.pokemon
	jiggly.hp = 5
	jiggly.status = StatusRules.POISON
	var events := battle.submit(BattleAction.move(0))
	var rested := Kit.find(events, K.RESTED, P)
	assert_not_null(rested)
	assert_eq(rested.amount, jiggly.max_hp() - 5)
	assert_eq([rested.hp, rested.max_hp, rested.status],
		[jiggly.max_hp(), jiggly.max_hp(), StatusRules.SLEEP])
	assert_eq([jiggly.hp, jiggly.status, jiggly.status_turns],
		[jiggly.max_hp(), StatusRules.SLEEP, 2])
	assert_null(Kit.find(events, K.STATUS_DAMAGED), "le poison est soigné")
	var texts := BattleText.new()
	texts.load_file()
	assert_eq(Array(texts.lines(rested, _data)), ["Rondoudou s'endort et récupère !"])
	for missed: int in 2:
		_rng.push([1])
		events = battle.submit(BattleAction.move(1))
		assert_not_null(Kit.find(events, K.STATUS_PREVENTED, P), "tentative %d" % (missed + 1))
		assert_null(Kit.find(events, K.MOVE_USED, P))
	_rng.push([1])
	events = battle.submit(BattleAction.move(1))
	assert_eq(_rng.remaining(), 0)
	assert_lt(Kit.index_of(events, K.STATUS_ENDED, P), Kit.index_of(events, K.MOVE_USED, P),
		"réveillé à la troisième, il agit le même tour")
	assert_eq(jiggly.status, StatusRules.NONE)


func test_rest_replaces_another_status() -> void:
	var battle := _battle()
	var jiggly := battle.get_player_side().active.pokemon
	jiggly.hp = 1
	jiggly.status = StatusRules.PARALYSIS
	# Paralysé : roll(100) au moment d'agir (99 : il agit).
	_rng.push([99])
	battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq([jiggly.status, jiggly.status_turns], [StatusRules.SLEEP, 2])


func test_awakening_after_rest_wakes_it_up() -> void:
	var items := ItemLibrary.new()
	items.load_dir()
	var battle := _battle(BattleRules.for_wild(items))
	var jiggly := battle.get_player_side().active.pokemon
	jiggly.hp = 1
	battle.submit(BattleAction.move(0))
	assert_eq(jiggly.status, StatusRules.SLEEP)
	_rng.push([1])
	var events := battle.submit(BattleAction.heal(&"awakening", 0))
	var cured := Kit.find(events, K.STATUS_CURED, P)
	assert_not_null(cured, "Réveil")
	assert_eq(cured.status, StatusRules.SLEEP)
	_rng.push([1])
	events = battle.submit(BattleAction.move(1))
	assert_eq(_rng.remaining(), 0)
	assert_null(Kit.find(events, K.STATUS_PREVENTED), "il agit tout de suite")
	assert_not_null(Kit.find(events, K.MOVE_USED, P))


func test_apply_rest_rules() -> void:
	var pokemon := Kit.mon(_data, &"jigglypuff", 15, [&"rest"])
	assert_false(StatusRules.apply_rest(pokemon), "PV pleins")
	pokemon.hp = 3
	pokemon.status = StatusRules.SLEEP
	pokemon.status_turns = 1
	assert_false(StatusRules.apply_rest(pokemon), "déjà endormi")
	assert_eq([pokemon.hp, pokemon.status_turns], [3, 1], "rien ne change")
	pokemon.status = StatusRules.BURN
	pokemon.status_turns = 0
	assert_true(StatusRules.apply_rest(pokemon))
	assert_eq([pokemon.hp, pokemon.status, pokemon.status_turns],
		[pokemon.max_hp(), StatusRules.SLEEP, StatusRules.REST_SLEEP_TURNS])
	pokemon.hp = 0
	pokemon.cure_status()
	assert_false(StatusRules.apply_rest(pokemon), "K.O.")
	assert_false(StatusRules.apply_rest(null))
