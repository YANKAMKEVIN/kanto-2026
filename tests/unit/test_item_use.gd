extends GutTest
## ItemUse (jalon-06.md §3.4, Q-10, Q-11) : une seule règle pour le menu et le moteur de
## combat. PV pleins, K.O., contexte, objet qui ne se donne pas, Sac vide, retrait unique.
## Salamèche N5, IV 0 : 18 PV max.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const C := ItemUse.Check

var _data: PokemonData
var _items: ItemLibrary
var _potion: ItemData
var _ball: ItemData
var _bag: Bag
var _mon: Pokemon


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()
	_potion = _items.get_item(&"potion")
	_ball = _items.get_item(&"poke_ball")


func before_each() -> void:
	_bag = Bag.new()
	_bag.add(&"potion", 2)
	_bag.add(&"poke_ball", 5)
	_mon = PokemonFactory.create(_data, &"charmander", 5, ScriptedRng.new(IV_0))
	_mon.hp = 5


func test_a_potion_heals_20_hp_and_leaves_the_bag_once() -> void:
	assert_eq(_mon.max_hp(), 18)
	assert_eq(ItemUse.check(_bag, _potion, _mon, ItemData.CONTEXT_FIELD), C.OK)
	var result := ItemUse.apply(_bag, _potion, _mon, ItemData.CONTEXT_FIELD)
	assert_true(result.is_ok())
	assert_eq([result.item_id, result.hp_before, result.hp_after, result.max_hp,
		result.remaining], [&"potion", 5, 18, 18, 1], "PV bornés au maximum")
	assert_eq(result.amount(), 13)
	assert_eq(_mon.hp, 18)
	assert_eq(_bag.count_of(&"potion"), 1, "un seul exemplaire retiré")


func test_full_hp_is_refused_and_nothing_is_spent() -> void:
	_mon.hp = 18
	var result := ItemUse.apply(_bag, _potion, _mon, ItemData.CONTEXT_FIELD)
	assert_eq(result.check, C.FULL_HP)
	assert_eq([result.hp_before, result.hp_after, result.remaining], [18, 18, 2])
	assert_eq(result.amount(), 0)
	assert_eq(_bag.count_of(&"potion"), 2)


func test_a_fainted_pokemon_cannot_be_healed() -> void:
	_mon.hp = 0
	assert_eq(ItemUse.check(_bag, _potion, _mon, ItemData.CONTEXT_FIELD), C.FAINTED,
		"Q-11 : aucun objet ne ranime")
	ItemUse.apply(_bag, _potion, _mon, ItemData.CONTEXT_FIELD)
	assert_eq(_mon.hp, 0)
	assert_eq(_bag.count_of(&"potion"), 2)


func test_empty_bag() -> void:
	_bag.remove(&"potion", 2)
	var result := ItemUse.apply(_bag, _potion, _mon, ItemData.CONTEXT_FIELD)
	assert_eq(result.check, C.NOT_IN_BAG)
	assert_eq(result.remaining, 0)
	assert_eq(_mon.hp, 5)
	assert_eq(ItemUse.check(null, _potion, _mon, ItemData.CONTEXT_FIELD), C.NOT_IN_BAG)


func test_contexts() -> void:
	for context: StringName in [ItemData.CONTEXT_FIELD, ItemUse.CONTEXT_TEAM,
			ItemData.CONTEXT_WILD_BATTLE, ItemData.CONTEXT_TRAINER_BATTLE]:
		assert_eq(ItemUse.check(_bag, _potion, _mon, context), C.OK, String(context))
	assert_eq(ItemUse.check(_bag, _potion, _mon, &"elsewhere"), C.WRONG_CONTEXT)
	assert_eq(ItemUse.rule_context(ItemUse.CONTEXT_TEAM), ItemData.CONTEXT_FIELD)
	assert_eq(ItemUse.CONTEXT_TEAM, MenuRoute.BAG_CONTEXT_TEAM)


func test_a_ball_or_nothing_is_not_given_to_a_pokemon() -> void:
	assert_eq(ItemUse.check(_bag, _ball, _mon, ItemData.CONTEXT_WILD_BATTLE), C.NOT_USABLE)
	assert_eq(ItemUse.check(_bag, null, _mon, ItemData.CONTEXT_FIELD), C.NOT_USABLE)
	assert_eq(ItemUse.check(_bag, _potion, null, ItemData.CONTEXT_FIELD), C.NOT_USABLE)
	var result := ItemUse.apply(_bag, _ball, _mon, ItemData.CONTEXT_WILD_BATTLE)
	assert_eq(result.check, C.NOT_USABLE)
	assert_eq(_bag.count_of(&"poke_ball"), 5)
	assert_eq(ItemUse.restore(_ball, _mon), 0)


func test_check_target_and_restore_never_touch_the_bag() -> void:
	# Le moteur de combat : il vérifie et soigne, le directeur retire l'objet.
	var empty := Bag.new()
	assert_eq(ItemUse.check_target(_potion, _mon, ItemData.CONTEXT_WILD_BATTLE), C.OK)
	assert_eq(ItemUse.check(empty, _potion, _mon, ItemData.CONTEXT_WILD_BATTLE), C.NOT_IN_BAG)
	assert_eq(ItemUse.restore(_potion, _mon), 13)
	assert_eq(_mon.hp, 18)
	assert_eq(_bag.count_of(&"potion"), 2)
	assert_eq(ItemUse.check_target(_potion, _mon, ItemData.CONTEXT_WILD_BATTLE), C.FULL_HP)


func test_a_small_heal_is_exact() -> void:
	_mon.hp = 17
	var result := ItemUse.apply(_bag, _potion, _mon, ItemData.CONTEXT_FIELD)
	assert_eq(result.amount(), 1, "+1 PV, jamais au-delà du maximum")


# --- Antidote (jalon 9 §2.1.5) -----------------------------------------------------------

func test_an_antidote_cures_poison_even_at_full_hp() -> void:
	var antidote := _items.get_item(&"antidote")
	assert_true(antidote.targets_pokemon(), "un soin de statut se donne à un Pokémon")
	assert_eq(antidote.cures, [&"poison"] as Array[StringName])
	_bag.add(&"antidote", 2)
	_mon.hp = 18
	_mon.status = StatusRules.POISON
	_mon.gender = Pokemon.Gender.FEMALE
	assert_eq(ItemUse.check(_bag, antidote, _mon, ItemData.CONTEXT_FIELD), C.OK)
	var result := ItemUse.apply(_bag, antidote, _mon, ItemData.CONTEXT_FIELD)
	assert_true(result.is_ok())
	assert_eq([result.status_cured, result.amount(), result.remaining, result.gender],
		[&"poison", 0, 1, Pokemon.Gender.FEMALE])
	assert_eq(_mon.status, StatusRules.NONE)
	assert_eq(_mon.hp, 18, "aucun PV rendu")


func test_an_antidote_has_no_effect_without_poison() -> void:
	var antidote := _items.get_item(&"antidote")
	_bag.add(&"antidote", 1)
	var result := ItemUse.apply(_bag, antidote, _mon, ItemData.CONTEXT_FIELD)
	assert_eq(result.check, C.NO_EFFECT, "« Sans effet »")
	assert_eq([result.status_cured, result.remaining], [StatusRules.NONE, 1], "rien consommé")
	assert_eq(ItemUse.check_target(antidote, _mon, ItemData.CONTEXT_WILD_BATTLE), C.NO_EFFECT)


func test_an_antidote_cannot_help_a_fainted_pokemon() -> void:
	var antidote := _items.get_item(&"antidote")
	_bag.add(&"antidote", 1)
	_mon.hp = 0
	_mon.status = StatusRules.POISON
	assert_eq(ItemUse.check(_bag, antidote, _mon, ItemData.CONTEXT_FIELD), C.FAINTED)
	assert_eq(ItemUse.cure(antidote, _mon), &"poison", "cure ne vérifie rien (le moteur)")


func test_a_potion_does_not_cure_poison() -> void:
	_mon.status = StatusRules.POISON
	var result := ItemUse.apply(_bag, _potion, _mon, ItemData.CONTEXT_FIELD)
	assert_true(result.is_ok())
	assert_eq(result.status_cured, StatusRules.NONE)
	assert_eq(_mon.status, &"poison")
	_mon.hp = 18
	assert_eq(ItemUse.check(_bag, _potion, _mon, ItemData.CONTEXT_FIELD), C.FULL_HP,
		"PV pleins, même empoisonné")
	assert_eq(ItemUse.cure(_potion, _mon), StatusRules.NONE)
	assert_eq(ItemUse.cure(_ball, _mon), StatusRules.NONE)
	assert_eq(ItemUse.cure(null, _mon), StatusRules.NONE)


# --- Rappel (jalon 20, §2.9.4) -----------------------------------------------------------

func test_a_revive_only_raises_a_fainted_pokemon_to_half_hp() -> void:
	var revive := _items.get_item(&"revive")
	_bag.add(&"revive", 2)
	assert_eq(ItemUse.check(_bag, revive, _mon, ItemData.CONTEXT_FIELD), C.NOT_FAINTED,
		"debout : refusé")
	_mon.hp = 0
	_mon.status = StatusRules.NONE
	for context: StringName in [ItemData.CONTEXT_FIELD, ItemData.CONTEXT_WILD_BATTLE,
			ItemData.CONTEXT_TRAINER_BATTLE]:
		assert_eq(ItemUse.check(_bag, revive, _mon, context), C.OK, String(context))
	var result := ItemUse.apply(_bag, revive, _mon, ItemData.CONTEXT_FIELD)
	assert_true(result.is_ok())
	assert_true(result.revived)
	assert_eq(_mon.hp, 9, "floor(18 × 0,5)")
	assert_false(_mon.is_fainted())
	assert_eq(_bag.count_of(&"revive"), 1, "un seul retiré")
	assert_eq(BagQuery.result_text(result, "Salamèche"), "Salamèche reprend connaissance !")
	assert_eq(ItemUse.check(_bag, revive, _mon, ItemData.CONTEXT_FIELD), C.NOT_FAINTED)
	assert_eq(BagQuery.reason_text(C.NOT_FAINTED), "Pas K.O.")
	assert_eq(BagQuery.refusal_text(C.NOT_FAINTED, "Salamèche"),
		"Cela n'aurait aucun effet sur Salamèche.")


func test_a_revive_gives_at_least_one_hp() -> void:
	var item := ItemData.new()
	item.category = ItemData.Category.HEAL
	item.revive = 0.01
	_mon.hp = 0
	assert_eq(ItemUse.restore(item, _mon), 1)
	assert_eq(_mon.hp, 1)
	assert_eq(ItemUse.restore(item, _mon), 0, "debout : rien")


func test_the_potion_still_refuses_a_fainted_pokemon() -> void:
	_mon.hp = 0
	assert_eq(ItemUse.check(_bag, _potion, _mon, ItemData.CONTEXT_FIELD), C.FAINTED)
