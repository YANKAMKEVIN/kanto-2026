extends GutTest
## Vues du combat du jalon 12 (T14, `jalon-12.md` §2.10, annexe A.4) : Pokémon du joueur piégé →
## aucune carte de l'équipe envoyable, raison « Impossible de changer » (le remplacement après
## un K.O. reste libre) ; capacité bloquée par Entrave → vue « BLOQUÉE », non utilisable.
##
## Volatils posés directement sur le Battler (le moteur est testé par le T13) ; IV 0.

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")

var _data: PokemonData
var _texts: BattleText


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_texts = BattleText.new()
	_texts.load_file()


func _battle(mine: Array, draws: Array = []) -> Battle:
	return Kit.battle(_data, Kit.ScriptedRng.new(Kit.draws(draws)), mine,
		[Kit.mon(_data, &"bulbasaur", 5, [&"defense_curl"])])


func _team() -> Array:
	var fainted := Kit.mon(_data, &"rattata", 5, [&"tackle"])
	fainted.hp = 0
	return [Kit.mon(_data, &"geodude", 21, [&"self_destruct", &"tackle"]),
		Kit.mon(_data, &"charmander", 10, [&"scratch"]), fainted]


func test_validated_texts() -> void:
	assert_eq(_texts.get_template(&"switch_reason_trapped"), "Impossible de changer")
	assert_eq(_texts.get_template(&"move_disabled_label"), "BLOQUÉE")
	assert_eq(_texts.get_template(&"flee_failed"), "Impossible de fuir !")


func test_free_party_is_unchanged() -> void:
	var views := BattleViews.party(_battle(_team()), _data, _texts)
	assert_eq(views.map(func(v: BattlePartyView) -> bool: return v.can_send),
		[false, true, false])
	assert_eq(views.map(func(v: BattlePartyView) -> String: return v.reason),
		["Déjà au combat", "", "Ne peut plus combattre"])


func test_trapped_player_cannot_send_anyone_and_reads_why() -> void:
	var battle := _battle(_team())
	battle.get_player_side().active.trap_turns = 3
	assert_true(battle.is_player_trapped())
	var views := BattleViews.party(battle, _data, _texts)
	assert_eq(views.map(func(v: BattlePartyView) -> bool: return v.can_send),
		[false, false, false])
	assert_eq(views.map(func(v: BattlePartyView) -> String: return v.reason),
		["Déjà au combat", "Impossible de changer", "Ne peut plus combattre"],
		"les autres raisons ne changent pas")


func test_replacement_after_a_knock_out_ignores_the_trap() -> void:
	# Destruction ratée (esquive +6) : le lanceur tombe K.O., le joueur doit remplacer.
	var battle := _battle(_team(), [1, 50])
	battle.get_foe_side().active.change_stage(&"eva", 6)
	battle.submit(BattleAction.move(0))
	assert_true(battle.needs_replacement())
	battle.get_player_side().active.trap_turns = 3
	var views := BattleViews.party(battle, _data, _texts)
	assert_true(views[1].can_send, "le remplacement reste libre")
	assert_eq(views[1].reason, "")


func test_player_moves_mark_the_disabled_slot() -> void:
	var battle := _battle(_team())
	var lead := battle.get_player_side().active
	var plain := BattleViews.player_moves(battle, _data, _texts)
	assert_eq(plain.size(), 2)
	assert_false(plain[0].blocked or plain[1].blocked, "rien de bloqué")
	lead.disabled_slot = 1
	lead.disabled_turns = 3
	assert_eq(battle.get_disabled_move(), 1)
	var views := BattleViews.player_moves(battle, _data, _texts)
	assert_false(views[0].blocked)
	assert_true(views[0].is_usable())
	assert_true(views[1].blocked)
	assert_eq(views[1].blocked_text, "BLOQUÉE")
	assert_false(views[1].is_usable(), "PP pleins mais bloquée")
	assert_eq(views[1].pp, views[1].max_pp, "les PP restent affichés")
