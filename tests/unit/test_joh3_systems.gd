extends GutTest
## JOH3 (`jalon-joh3.md` §2.4 à §2.6) : promotion du jour de la Boutique (JH-33), paliers du lien
## du Pokémon de tête (Mme Clémence, D-24 à D-27) et variante de dialogue « if_lead_bond_tier ».

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")

var _items: ItemLibrary
var _data: PokemonData
var _state: Node


func before_all() -> void:
	_items = ItemLibrary.new()
	_items.load_dir()
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_state = GameStateScript.new()
	_state.clock = FixedClock.new("2026-11-04T10:00:00")
	_state.new_game(3)


func after_each() -> void:
	_state.free()


func _shop(raw: Dictionary) -> ShopData:
	var shops := ShopLibrary.new()
	assert_true(shops.add_from_dict({"dept": raw}, "test"), str(shops.get_errors()))
	return shops.get_shop(&"dept")


func _mon(species: StringName, bond: int, egg: bool = false) -> Pokemon:
	var mon := PokemonFactory.create(_data, species, 10, GameRng.new(4))
	mon.bond = bond
	if egg:
		mon.egg_steps = 500
	_state.party.add(mon)
	return mon


# --- Promotion du jour ----------------------------------------------------------------------------

func test_a_promoted_item_costs_half_on_its_day_only() -> void:
	var shop := _shop({"stock": [{"item": "poke_ball"}, {"item": "potion"}],
		"promotions": {"monday": ["poke_ball"], "tuesday": ["potion"]}})
	var ball := _items.get_item(&"poke_ball")
	assert_eq(ShopRules.unit_price(shop, ball, &"monday"), ball.price / 2)
	assert_eq(ShopRules.unit_price(shop, ball, &"tuesday"), ball.price)
	assert_eq(ShopRules.unit_price(shop, ball, &""), ball.price, "sans jour : prix normal")
	assert_true(ShopRules.is_promoted(shop, ball, &"monday"))
	_state.money = 1000
	assert_eq(ShopRules.buy(_state, shop, ball, 2, &"monday"), ShopRules.Status.OK)
	assert_eq(_state.money, 1000 - ball.price, "deux Balls au prix d'une")
	var view := ShopViews.build(_state, shop, _items, ShopViews.MODE_BUY, &"monday")
	assert_eq(view.entry(&"poke_ball").unit_price, ball.price / 2)
	assert_eq(view.entry(&"potion").unit_price, _items.get_item(&"potion").price)


func test_a_weekday_line_is_sold_on_that_day_only() -> void:
	var shop := _shop({"stock": [{"item": "potion"}, {"item": "revive", "if_weekday": "friday"}],
		"promotions": {"friday": ["revive"]}})
	assert_eq(ShopRules.stock(shop, _state.flags, &"friday"), [&"potion", &"revive"] as Array[StringName])
	assert_eq(ShopRules.stock(shop, _state.flags, &"monday"), [&"potion"] as Array[StringName])
	assert_eq(ShopRules.stock(shop, _state.flags), [&"potion"] as Array[StringName],
		"sans jour (Kanto) : jamais")
	_state.money = 5000
	assert_eq(ShopRules.buy(_state, shop, _items.get_item(&"revive"), 1, &"monday"),
		ShopRules.Status.NOT_SOLD_HERE)


func test_invalid_promotions_are_refused() -> void:
	for raw: Dictionary in [
			{"stock": [{"item": "potion"}], "promotions": {"funday": ["potion"]}},
			{"stock": [{"item": "potion"}], "promotions": {"monday": ["poke_ball"]}},
			{"stock": [{"item": "potion"}], "promotions": {"monday": []}},
			{"stock": [{"item": "potion", "if_weekday": "someday"}]}]:
		var shops := ShopLibrary.new()
		assert_false(shops.add_from_dict({"bad": raw}, "bad"), str(raw))
	assert_push_error_count(4)


func test_the_goldenrod_dept_store_follows_the_dossier() -> void:
	var shops := ShopLibrary.new()
	assert_true(shops.load_dir(), str(shops.get_errors()))
	var first := shops.get_shop(&"goldenrod_dept_2f")
	assert_not_null(first)
	var expected := {"monday": [&"poke_ball"], "tuesday": [&"potion", &"super_potion"],
		"wednesday": [&"great_ball"], "friday": [&"revive"], "saturday": [&"full_heal"]}
	for day: String in expected:
		assert_eq(first.promotions.get(StringName(day), []), expected[day], day)
	assert_eq(shops.get_shop(&"goldenrod_dept_3f").promotions.get(&"thursday", []),
		[&"repel", &"super_repel"])
	for drink: String in ["water", "soda", "lemonade"]:
		var roof := shops.get_shop(StringName("goldenrod_dept_roof_" + drink))
		assert_eq(roof.promotions.keys(), [&"sunday"], drink)


func test_the_menu_reads_the_weekday_when_the_shop_opens() -> void:
	var shop := _shop({"stock": [{"item": "poke_ball"}], "promotions": {"monday": ["poke_ball"]}})
	var ball := _items.get_item(&"poke_ball")
	_state.money = 1000
	assert_eq(ShopRules.max_buy(ball, 1000, _state.bag, ball.price / 2), mini(99, 1000 / (ball.price / 2)))
	assert_eq(ShopRules.buy_total(ball, 3, ShopRules.unit_price(shop, ball, &"monday")),
		3 * (ball.price / 2))


# --- Lien du Pokémon de tête ----------------------------------------------------------------------

func test_the_lead_is_the_companion_then_the_first_pokemon() -> void:
	assert_eq(BondReader.lead_tier(_state), BondReader.NONE, "équipe vide")
	var first := _mon(&"rattata", 20)
	var second := _mon(&"pidgey", 95)
	assert_eq(BondReader.lead_tier(_state), 0, "< 30")
	assert_true(_state.set_companion(second))
	assert_eq(BondReader.lead_tier(_state), 3, "le compagnon : ≥ 90")
	assert_eq(BondReader.lead_pokemon(_state), second)
	_state.set_companion(null)
	first.bond = 30
	assert_eq(BondReader.lead_tier(_state), 1)
	first.bond = 89
	assert_eq(BondReader.lead_tier(_state), 2)


func test_an_egg_in_front_has_its_own_answer() -> void:
	_mon(&"togepi", 50, true)
	var other := _mon(&"rattata", 75)
	assert_eq(BondReader.lead_tier(_state), BondReader.EGG)
	assert_true(_state.set_companion(other))
	assert_eq(BondReader.lead_tier(_state), 2, "le compagnon passe devant l'œuf")


func test_dialogue_variants_pick_the_lead_bond_tier() -> void:
	var library := DialogueLibrary.new()
	assert_true(library.add_from_dict({"clemence": {"speaker": "Mme Clémence", "variants": [
		{"if_lead_bond_tier": "egg", "pages": ["Un œuf !"]},
		{"if_lead_bond_tier": [2, 3], "pages": ["Il t'aime."]},
		{"if_lead_bond_tier": 0, "pages": ["Pas encore."]},
		{"pages": ["Autre."]},
	]}}, "test"), str(library.get_errors()))
	var dialogue := library.get_dialogue(&"clemence")
	var flags := StoryFlags.new()
	var pick := func(tier: int) -> String:
		return dialogue.pick(flags, null, 0, Callable(), Callable(), Callable(), &"", &"", 0,
			tier).pages[0].text
	assert_eq(pick.call(BondReader.EGG), "Un œuf !")
	assert_eq(pick.call(3), "Il t'aime.")
	assert_eq(pick.call(2), "Il t'aime.")
	assert_eq(pick.call(0), "Pas encore.")
	assert_eq(pick.call(1), "Autre.")
	assert_eq(dialogue.pick(flags).pages[0].text, "Autre.", "sans source : aucune condition de lien")
	for bad: Variant in [4, -1, "oeuf", []]:
		var other := DialogueLibrary.new()
		assert_false(other.add_from_dict({"x": {"variants": [
			{"if_lead_bond_tier": bad, "pages": ["…"]}]}}, "bad"), str(bad))
	assert_push_error_count(4)
