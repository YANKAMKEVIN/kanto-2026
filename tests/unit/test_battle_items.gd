extends GutTest
## Objets de combat du jalon 20 (`jalon-20.md` §2.9.3, §2.9.4 ; T11) dans le moteur : objets X
## (+1 étage, plafond), Muscle + (Puissance, puis échec), Poupée Poké (fuite garantie en combat
## sauvage, sans tour adverse ; refusée contre un Dresseur), Rappel (un Pokémon K.O. de l'équipe,
## la moitié de ses PV ; refusé sur un Pokémon debout) et leurs phrases (annexe A, n° 161 à 166).
##
## IV 0. Rondoudou N15 contre Bulbizarre N10 qui ne connaît que Boul'Armure : un tour adverse =
## l'IA de Bulbizarre (roll(1)), aucun autre tirage.

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

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


func _battle(trainer: bool = false, mine: Array = []) -> Battle:
	_rng = Kit.ScriptedRng.new([])
	var party: Array = [Kit.mon(_data, &"jigglypuff", 15, [&"defense_curl"])]
	party.append_array(mine)
	var rules := BattleRules.for_trainer(null, _items) if trainer \
		else BattleRules.for_wild(_items)
	return Kit.battle(_data, _rng, party, [Kit.mon(_data, &"bulbasaur", 10, [&"defense_curl"])],
		"Topdresseuse" if trainer else "", rules)


func _lines(events: Array[BattleEvent]) -> Array:
	var result: Array = []
	for event: BattleEvent in events:
		result.append_array(Array(_texts.lines(event, _data)))
	return result


func test_an_x_item_raises_one_stage_then_the_foe_plays() -> void:
	var battle := _battle()
	var active := battle.get_player_side().active
	assert_true(battle.is_legal(BattleAction.use_item(&"x_attack")))
	_rng.push([1])
	var events := battle.submit(BattleAction.use_item(&"x_attack"))
	assert_eq(_rng.remaining(), 0, "seule l'IA adverse tire")
	assert_eq(active.get_stage(&"atk"), 1, "+1 étage (RB)")
	assert_lt(Kit.index_of(events, K.BATTLE_ITEM_USED, P), Kit.index_of(events, K.STAT_CHANGED, P))
	assert_lt(Kit.index_of(events, K.STAT_CHANGED, P), Kit.index_of(events, K.MOVE_USED, F),
		"l'objet passe avant l'adversaire")
	assert_null(Kit.find(events, K.MOVE_USED, P), "l'objet prend le tour")
	var lines := _lines(events.slice(0, Kit.index_of(events, K.STAT_CHANGED, P) + 1))
	assert_eq(lines, ["Kevin utilise Attaque + !", "L'Attaque de Rondoudou augmente !"])


func test_each_x_item_targets_its_stat() -> void:
	var expected := {&"x_attack": &"atk", &"x_defend": &"def", &"x_speed": &"spe",
		&"x_special": &"spa", &"x_accuracy": &"acc"}
	for id: StringName in expected:
		var battle := _battle()
		_rng.push([1])
		battle.submit(BattleAction.use_item(id))
		assert_eq(battle.get_player_side().active.get_stage(expected[id]), 1, String(id))


func test_an_x_item_at_the_ceiling_changes_nothing() -> void:
	var battle := _battle()
	var active := battle.get_player_side().active
	active.change_stage(&"spe", 6)
	_rng.push([1])
	var events := battle.submit(BattleAction.use_item(&"x_speed"))
	assert_not_null(Kit.find(events, K.STAT_UNCHANGED, P))
	assert_null(Kit.find(events, K.STAT_CHANGED, P))
	assert_eq(active.get_stage(&"spe"), 6)
	assert_true(_lines(events).has("La Vitesse de Rondoudou ne peut plus augmenter !"),
		str(_lines(events)))


func test_dire_hit_focuses_once_then_fails() -> void:
	var battle := _battle()
	var active := battle.get_player_side().active
	_rng.push([1])
	var events := battle.submit(BattleAction.use_item(&"dire_hit"))
	assert_true(active.focused, "état de Puissance")
	assert_not_null(Kit.find(events, K.FOCUSED, P))
	_rng.push([1])
	events = battle.submit(BattleAction.use_item(&"dire_hit"))
	assert_not_null(Kit.find(events, K.FAILED, P), "déjà concentré : ça échoue")
	assert_null(Kit.find(events, K.FOCUSED, P))


func test_the_poke_doll_escapes_a_wild_battle_without_a_foe_turn() -> void:
	var battle := _battle()
	assert_true(battle.is_legal(BattleAction.use_item(&"poke_doll")))
	var events := battle.submit(BattleAction.use_item(&"poke_doll"))
	assert_eq(_rng.remaining(), 0, "aucun tirage")
	assert_eq(battle.get_outcome(), Battle.Outcome.FLED)
	assert_null(Kit.find(events, K.MOVE_USED, F), "l'adversaire ne joue pas")
	assert_eq(Kit.kinds(events), [["ITEM_ESCAPE", "PLAYER"], ["BATTLE_ENDED", "PLAYER"]])
	assert_eq(_lines(events), ["Kevin lance la Poupée Poké.",
		"Le Pokémon sauvage s'en désintéresse : tu t'éclipses !"])


func test_the_poke_doll_is_refused_against_a_trainer_but_x_items_are_not() -> void:
	var battle := _battle(true)
	assert_false(battle.is_legal(BattleAction.use_item(&"poke_doll")), "sauvage seulement")
	assert_true(battle.is_legal(BattleAction.use_item(&"x_defend")))
	assert_true(battle.is_legal(BattleAction.use_item(&"dire_hit")))
	var doll := _items.get_item(&"poke_doll")
	assert_false(doll.usable_in(battle.item_context()))


func test_battle_items_are_never_balls_nor_heals() -> void:
	var battle := _battle()
	assert_false(BattleAction.use_item(&"x_attack").is_heal())
	assert_false(battle.is_legal(BattleAction.use_item(&"potion")), "un soin a une cible")
	assert_false(battle.is_legal(BattleAction.use_item(&"unknown")))


func test_a_revive_raises_a_fainted_member_to_half_hp() -> void:
	var down := Kit.mon(_data, &"pidgey", 12, [&"tackle"])
	down.hp = 0
	down.status = StatusRules.NONE
	var battle := _battle(false, [down])
	assert_true(battle.is_legal(BattleAction.heal(&"revive", 1)))
	assert_false(battle.is_legal(BattleAction.heal(&"revive", 0)), "l'actif est debout")
	_rng.push([1])
	var events := battle.submit(BattleAction.heal(&"revive", 1))
	assert_eq(down.hp, maxi(1, floori(down.max_hp() / 2.0)))
	var used := Kit.find(events, K.ITEM_USED, P)
	var revived := Kit.find(events, K.REVIVED, P)
	assert_not_null(revived)
	assert_eq([used.amount, revived.amount, revived.party_index], [0, down.hp, 1])
	assert_lt(Kit.index_of(events, K.REVIVED, P), Kit.index_of(events, K.MOVE_USED, F))
	assert_eq(_lines(events.slice(0, Kit.index_of(events, K.REVIVED, P) + 1)),
		["Tu utilises Rappel sur Roucool.", "Roucool reprend connaissance !"])
	assert_eq(battle.check_switch(1), Battle.SwitchCheck.OK, "il peut de nouveau entrer")


func test_the_player_name_falls_back_without_tokens() -> void:
	var plain := BattleText.new()
	plain.load_file()
	assert_eq(plain.player_name(), BattleText.PLAYER_FALLBACK)
