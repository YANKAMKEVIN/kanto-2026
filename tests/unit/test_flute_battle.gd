extends GutTest
## Poké Flûte en combat (passe systèmes 2, `systemes-2.md` §2.4, T11 ; dossier 24 §8, L-9) :
## légale seulement si un Pokémon dort, elle réveille les endormis des deux camps (banc compris),
## prend le tour, n'est jamais consommée ; textes du dossier 24 §15.6.
##
## IV 0. Rondoudou N15 contre Bulbizarre N10 qui ne connaît que Boul'Armure : un tour adverse =
## l'IA de Bulbizarre (roll(1)), aucun autre tirage.

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE
const FLUTE := &"poke_flute"

var _data: PokemonData
var _items: ItemLibrary
var _texts: BattleText
var _rng: Kit.ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()
	_texts = BattleText.new()
	_texts.load_file()
	_texts.token_values = func() -> Dictionary[StringName, String]:
		return {DialogueTokens.PLAYER: "Kevin"}


func _battle(trainer: bool = false, mine: Array = [], foes: Array = []) -> Battle:
	_rng = Kit.ScriptedRng.new([])
	var party: Array = [Kit.mon(_data, &"jigglypuff", 15, [&"defense_curl"])]
	party.append_array(mine)
	var foe_party: Array = [Kit.mon(_data, &"bulbasaur", 10, [&"defense_curl"])]
	foe_party.append_array(foes)
	var rules := BattleRules.for_trainer(null, _items) if trainer \
		else BattleRules.for_wild(_items)
	return Kit.battle(_data, _rng, party, foe_party, "Topdresseuse" if trainer else "", rules)


func _sleep(pokemon: Pokemon, turns: int = 3) -> Pokemon:
	pokemon.status = StatusRules.SLEEP
	pokemon.status_turns = turns
	return pokemon


func _lines(events: Array[BattleEvent]) -> Array:
	var result: Array = []
	for event: BattleEvent in events:
		result.append_array(Array(_texts.lines(event, _data)))
	return result


func test_the_flute_is_a_key_item_usable_in_both_battles_and_the_field() -> void:
	var flute := _items.get_item(FLUTE)
	assert_eq(flute.key_use, ItemData.KEY_USE_POKE_FLUTE)
	assert_true(flute.usable_in(ItemData.CONTEXT_FIELD))
	assert_true(flute.usable_in(ItemData.CONTEXT_WILD_BATTLE))
	assert_true(flute.usable_in(ItemData.CONTEXT_TRAINER_BATTLE))
	assert_false(_items.get_item(&"bicycle").usable_in(ItemData.CONTEXT_WILD_BATTLE),
		"la Bicyclette ne sert pas en combat")


func test_without_a_sleeper_the_flute_is_not_legal() -> void:
	var battle := _battle()
	assert_true(battle.can_use_key_items())
	assert_false(battle.flute_has_effect())
	assert_false(battle.is_legal(BattleAction.key_item(FLUTE)), "aucun tour pris (L-9)")


func test_only_the_flute_is_a_legal_key_item() -> void:
	var battle := _battle()
	_sleep(battle.get_player_side().active.pokemon)
	assert_true(battle.is_legal(BattleAction.key_item(FLUTE)))
	assert_false(battle.is_legal(BattleAction.key_item(&"bicycle")))
	assert_false(battle.is_legal(BattleAction.key_item(&"oak_parcel")))


func test_the_flute_wakes_every_sleeper_of_both_sides_then_the_foe_plays() -> void:
	var bench := _sleep(Kit.mon(_data, &"pidgey", 12, [&"tackle"]))
	var battle := _battle(true, [bench], [_sleep(Kit.mon(_data, &"rattata", 9, [&"tackle"]))])
	var mine := _sleep(battle.get_player_side().active.pokemon)
	var foe := _sleep(battle.get_foe_side().active.pokemon)
	var foe_bench := battle.get_foe_side().party.get_at(1)
	_rng.push([1])
	var events := battle.submit(BattleAction.key_item(FLUTE))
	assert_eq(_rng.remaining(), 0, "seule l'IA adverse tire")
	for pokemon: Pokemon in [mine, bench, foe, foe_bench]:
		assert_false(pokemon.has_status(StatusRules.SLEEP), pokemon.species_id)
		assert_eq(pokemon.status_turns, 0)
	var woke := events.filter(func(e: BattleEvent) -> bool: return e.kind == K.FLUTE_WOKE)
	assert_eq(woke.size(), 4, "un événement par Pokémon réveillé, banc compris")
	assert_eq((woke[0] as BattleEvent).side, P, "le joueur d'abord")
	assert_true((woke[0] as BattleEvent).on_field)
	assert_false((woke[1] as BattleEvent).on_field, "le Roucool du banc")
	assert_eq((woke[2] as BattleEvent).side, F)
	assert_lt(Kit.index_of(events, K.ALL_WOKE, P), Kit.index_of(events, K.MOVE_USED, F),
		"la Flûte passe avant l'adversaire")
	assert_null(Kit.find(events, K.MOVE_USED, P), "la Flûte prend le tour")


func test_other_statuses_and_fainted_pokemon_are_untouched() -> void:
	var poisoned := Kit.mon(_data, &"pidgey", 12, [&"tackle"])
	poisoned.status = StatusRules.POISON
	var fainted := _sleep(Kit.mon(_data, &"rattata", 9, [&"tackle"]))
	fainted.hp = 0
	var battle := _battle(false, [poisoned, fainted])
	_sleep(battle.get_foe_side().active.pokemon)
	_rng.push([1])
	battle.submit(BattleAction.key_item(FLUTE))
	assert_true(poisoned.has_status(StatusRules.POISON))
	assert_true(fainted.is_fainted())


func test_the_flute_lines_are_those_of_dossier_24() -> void:
	var battle := _battle()
	_sleep(battle.get_foe_side().active.pokemon)
	_rng.push([1])
	var events := battle.submit(BattleAction.key_item(FLUTE))
	var lines := _lines(events.slice(0, Kit.index_of(events, K.ALL_WOKE, P) + 1))
	assert_eq(lines, ["Kevin joue de la Poké Flûte.", "Tous les Pokémon endormis se réveillent !"])
	assert_eq(_texts.get_template(&"flute_no_effect"), "Personne ne dort.")
	assert_eq(_texts.get_template(&"flute_no_effect_2"), "La Flûte n'aurait aucun effet.")


func test_a_woken_active_pokemon_loses_its_tag_on_the_card() -> void:
	var battle := _battle()
	_sleep(battle.get_player_side().active.pokemon)
	_rng.push([1])
	var events := battle.submit(BattleAction.key_item(FLUTE))
	var woke: BattleEvent = Kit.find(events, K.FLUTE_WOKE, P)
	var beats := BattlePlayback.beats(woke, _texts, _data)
	assert_eq(beats.size(), 1)
	assert_eq(beats[0].kind, BattleBeat.Kind.STATUS_TAG)
	assert_eq(woke.status, StatusRules.NONE, "l'étiquette part")
