extends GutTest
## Master Ball (jalon 26, T4, jalon-26.md §2.4) : objet de données « master_ball », capture
## certaine par la règle existante de [CaptureCalc] (a ≥ 255, aucun tirage), même pour un taux de
## capture de 3 (légendaires) à PV pleins, jamais en boutique ; le refus des Balls contre un
## Dresseur reste inchangé. Aucune règle de capture n'est ajoutée : le bonus de la Ball suffit.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const K := BattleEvent.Kind

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func _master_bonus() -> float:
	return _items.get_item(&"master_ball").catch_bonus


func test_master_ball_is_a_ball_never_sold() -> void:
	assert_true(_items.has_item(&"master_ball"))
	var item := _items.get_item(&"master_ball")
	assert_eq(item.name, "Master Ball")
	assert_eq(item.plural, "Master Balls")
	assert_eq(item.category, ItemData.Category.BALL)
	assert_eq(item.price, 0, "jamais en boutique (prix absent)")
	assert_eq(item.description,
		"La meilleure Ball qui soit. Elle attrape à coup sûr n'importe quel Pokémon sauvage.")
	assert_gte(item.catch_bonus, 255.0 * 3.0, "assez pour un taux de 1 à PV pleins")


func test_no_shop_sells_the_master_ball() -> void:
	var shops := ShopLibrary.new()
	shops.load_dir()
	for id: StringName in shops.get_ids():
		assert_false(shops.get_shop(id).item_ids().has(&"master_ball"), "boutique %s" % id)


func test_catch_is_certain_at_full_hp_for_every_catch_rate() -> void:
	var bonus := _master_bonus()
	for max_hp: int in [1, 10, 15, 60, 143, 714]:
		for rate: int in [1, 3, 45, 255]:
			assert_gte(CaptureCalc.catch_value(max_hp, max_hp, rate, bonus), CaptureCalc.CERTAIN,
				"PV pleins %d, taux %d" % [max_hp, rate])
			assert_eq(CaptureCalc.chance(max_hp, max_hp, rate, bonus), 1.0)


func test_throw_at_rate_3_full_hp_catches_without_any_draw() -> void:
	var rng := ScriptedRng.new()
	var result := CaptureCalc.throw_ball(143, 143, 3, _master_bonus(), rng)
	assert_true(result.caught)
	assert_eq(result.shakes, CaptureCalc.SHOWN_SHAKES)
	assert_eq(rng.calls, 0, "aucun tirage")
	# Contre-épreuve : une Poké Ball dans la même situation n'est jamais certaine.
	assert_lt(CaptureCalc.chance(143, 143, 3, 1.0), 0.01)


func test_wild_battle_catches_a_rate_3_pokemon_at_full_hp() -> void:
	# Espèce de test au numéro 9999 : le 144 est celui d'Artikodin depuis la fusion de `main` (J24).
	assert_true(_data.add_species_from_dict({"zz_legend": {
		"dex": 9999, "name": "Zz", "types": ["ice", "flying"],
		"base_stats": { "hp": 90, "atk": 85, "def": 100, "spa": 95, "spd": 125, "spe": 85 },
		"male_ratio": -1, "growth_rate": "slow", "base_exp": 261, "catch_rate": 3,
		"learnset": [[1, "gust"]]}}))
	var foe := PokemonFactory.create(_data, &"zz_legend", 50, ScriptedRng.new(IV_0))
	var battle := _battle(foe, BattleRules.for_wild(_items), false)
	assert_true(battle.is_legal(BattleAction.ball(&"master_ball")))
	var events := battle.submit(BattleAction.ball(&"master_ball"))
	assert_eq(battle.get_outcome(), Battle.Outcome.CAUGHT)
	assert_eq(events[1].kind, K.BALL_THROWN)
	assert_eq(events[1].item_id, &"master_ball")
	assert_eq(events[1].hp, events[1].max_hp, "PV pleins")
	assert_eq(events[-2].kind, K.CAUGHT)


func test_balls_are_still_refused_against_a_trainer() -> void:
	var foe := PokemonFactory.create(_data, &"squirtle", 5, ScriptedRng.new(IV_0))
	var rules := BattleRules.for_trainer()
	rules.items = _items
	var battle := _battle(foe, rules, true)
	assert_false(battle.can_use_balls())
	assert_false(battle.is_legal(BattleAction.ball(&"master_ball")))
	assert_eq(battle.submit(BattleAction.ball(&"master_ball")).size(), 0)
	assert_push_error("action refusée")
	assert_eq(battle.get_outcome(), Battle.Outcome.NONE)


func _battle(foe: Pokemon, rules: BattleRules, trainer: bool) -> Battle:
	var party := Party.new()
	party.add(PokemonFactory.create(_data, &"charmander", 5, ScriptedRng.new(IV_0)))
	var foes := Party.new()
	foes.add(foe)
	var battle := Battle.new(BattleSide.new(party, true),
		BattleSide.new(foes, false, "Le Rival" if trainer else ""), _data,
		ScriptedRng.new(), rules)
	battle.start()
	return battle
