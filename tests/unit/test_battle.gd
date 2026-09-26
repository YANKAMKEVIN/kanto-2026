extends GutTest
## Battle : journal d'événements, ordre des actions, statistiques, raté, K.O., Lutte,
## actions illégales, reproductibilité (jalon 4 §2.2 et §3.4).
##
## N5, IV 0 : Salamèche PV 18 Atq 10 Déf 9 Vit 11 ; Carapuce PV 19 Atq 9 Déf 11 Vit 9 ;
## Bulbizarre PV 19 Atq 9 Déf 9 Vit 9. Tirages imposés, dans l'ordre : IA adverse
## (pick_index), égalité de Vitesse, puis précision / critique (2 = non) / aléatoire (16 =
## 100 %) de chaque action.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE

var _data: PokemonData
var _rng: ScriptedRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _party(species_list: Array[StringName], data: PokemonData = _data) -> Party:
	var party := Party.new()
	for species: StringName in species_list:
		party.add(PokemonFactory.create(data, species, 5, ScriptedRng.new(IV_0)))
	return party


## Combat démarré ; [param draws] : tirages du moteur après le départ.
func _battle(player: StringName, foe: StringName, draws: Array[int],
		foe_party: Array[StringName] = []) -> Battle:
	_rng = ScriptedRng.new(draws)
	var foes: Array[StringName] = [foe]
	if not foe_party.is_empty():
		foes = foe_party
	var battle := Battle.new(BattleSide.new(_party([player]), true),
		BattleSide.new(_party(foes), false, "Le Rival", BattleAI.new()), _data, _rng)
	battle.start()
	return battle


func _kinds(events: Array[BattleEvent]) -> Array:
	var result: Array = []
	for event: BattleEvent in events:
		result.append([K.find_key(event.kind), BattleEvent.SideId.find_key(event.side)])
	return result


func _find(events: Array[BattleEvent], kind: BattleEvent.Kind) -> BattleEvent:
	for event: BattleEvent in events:
		if event.kind == kind:
			return event
	return null


# --- Départ -----------------------------------------------------------------------------

func test_start_presents_the_trainer_and_sends_both_pokemon() -> void:
	var battle := Battle.new(BattleSide.new(_party([&"charmander"]), true),
		BattleSide.new(_party([&"squirtle"]), false, "Le Rival"), _data, ScriptedRng.new())
	assert_eq(battle.get_state(), Battle.State.READY)
	var events := battle.start()
	assert_eq(_kinds(events), [["BATTLE_STARTED", "FOE"], ["SENT_OUT", "FOE"],
		["SENT_OUT", "PLAYER"]])
	assert_eq(events[0].trainer_name, "Le Rival")
	assert_eq(events[1].pokemon_name, "Carapuce")
	assert_eq(events[1].trainer_name, "Le Rival")
	assert_eq([events[1].species_id, events[1].level, events[1].hp, events[1].max_hp],
		[&"squirtle", 5, 19, 19])
	assert_eq(events[2].pokemon_name, "Salamèche")
	assert_eq(events[2].gender, Pokemon.Gender.MALE)
	assert_eq(battle.get_state(), Battle.State.CHOOSING)
	assert_eq(battle.get_turn(), 0)
	assert_eq(battle.get_outcome(), Battle.Outcome.NONE)
	assert_eq(battle.start().size(), 0, "une seule fois")
	assert_push_error("start impossible")


# --- Ordre ------------------------------------------------------------------------------

func test_faster_pokemon_acts_first_and_the_log_carries_the_state() -> void:
	# IA : roll(2) = 2 → Mimi-Queue. Griffe de Salamèche sur Carapuce :
	# ⌊⌊4·40·10/11⌋/50⌋ + 2 = 4.
	var battle := _battle(&"charmander", &"squirtle", [2, 50, 2, 16, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_kinds(events), [["TURN_STARTED", "PLAYER"], ["MOVE_USED", "PLAYER"],
		["DAMAGE", "FOE"], ["MOVE_USED", "FOE"], ["STAT_CHANGED", "PLAYER"]])
	assert_eq(events[0].turn, 1)
	assert_eq([events[1].move_id, events[1].pp], [&"scratch", 34])
	assert_eq([events[2].amount, events[2].hp, events[2].max_hp], [4, 15, 19])
	assert_eq([events[2].effectiveness, events[2].critical], [1.0, false])
	assert_eq(events[3].move_id, &"tail_whip")
	assert_eq([events[4].stat, events[4].stages, events[4].stage], [&"def", -1, -1])
	assert_eq(battle.get_player_side().active.pokemon.moves[0].pp, 34, "PP décomptés")
	assert_eq(battle.get_turn(), 1)
	assert_eq(battle.get_state(), Battle.State.CHOOSING)


func test_slower_player_acts_second() -> void:
	var battle := _battle(&"squirtle", &"charmander", [1, 50, 2, 16, 50, 2, 16])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_kinds(events).slice(1), [["MOVE_USED", "FOE"], ["DAMAGE", "PLAYER"],
		["MOVE_USED", "PLAYER"], ["DAMAGE", "FOE"]])


func test_priority_beats_speed() -> void:
	var fixture := PokemonData.new()
	fixture.load_dir("res://tests/fixtures/pokemon/valid/")
	# Pousse (Vit 9) connaît Tranch'Herbe en 4e (priorité +1) ; Feu Follet (Vit 13).
	_rng = ScriptedRng.new([1, 50, 2, 16, 50, 2, 16])
	var battle := Battle.new(BattleSide.new(_party([&"sprout"], fixture), true),
		BattleSide.new(_party([&"wisp"], fixture), false), fixture, _rng)
	battle.start()
	var events := battle.submit(BattleAction.move(3))
	assert_eq(_rng.remaining(), 0)
	assert_eq([events[1].side, events[1].move_id], [P, &"razor_leaf"])
	assert_eq(_find(events.slice(3), K.MOVE_USED).side, F)


func test_speed_tie_is_drawn() -> void:
	# Tirage 1 → le joueur d'abord ; 2 → l'adversaire d'abord.
	var battle := _battle(&"charmander", &"charmander", [1, 1, 50, 2, 16, 50, 2, 16])
	assert_eq(battle.submit(BattleAction.move(0))[1].side, P)
	battle = _battle(&"charmander", &"charmander", [1, 2, 50, 2, 16, 50, 2, 16])
	assert_eq(battle.submit(BattleAction.move(0))[1].side, F)
	assert_eq(_rng.remaining(), 0)


# --- Statistiques et précision -----------------------------------------------------------

func test_growl_lowers_attack_until_it_cannot() -> void:
	# Salamèche (plus rapide) rugit d'abord ; l'Attaque de Bulbizarre est déjà à −6.
	var battle := _battle(&"bulbasaur", &"charmander", [2, 50, 50])
	battle.get_foe_side().active.change_stage(&"atk", -6)
	var events := battle.submit(BattleAction.move(1))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_kinds(events).slice(1), [["MOVE_USED", "FOE"], ["STAT_CHANGED", "PLAYER"],
		["MOVE_USED", "PLAYER"], ["STAT_UNCHANGED", "FOE"]])
	assert_eq([events[2].stat, events[2].stages, events[2].stage], [&"atk", -1, -1])
	assert_eq([events[4].stat, events[4].stages, events[4].stage], [&"atk", -1, -6])


func test_missed_move() -> void:
	var battle := _battle(&"charmander", &"bulbasaur", [2, 81, 50])
	var player := battle.get_player_side().active.pokemon
	player.replace_move(0, &"hydro_pump", _data)
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_kinds(events).slice(1, 3), [["MOVE_USED", "PLAYER"], ["MOVE_MISSED", "PLAYER"]])
	assert_eq([events[1].pp, events[2].move_id], [4, &"hydro_pump"], "un PP dépensé")
	assert_eq(battle.get_foe_side().active.pokemon.hp, 19)


func test_secondary_effect_chance() -> void:
	# Écume de Carapuce (Vit 9, avant Bulbizarre par tirage d'égalité) : 10 % de −1 Vitesse.
	var battle := _battle(&"squirtle", &"bulbasaur", [2, 1, 50, 2, 16, 10, 50])
	battle.get_player_side().active.pokemon.replace_move(0, &"bubble", _data)
	var events := battle.submit(BattleAction.move(0))
	var changed := _find(events, K.STAT_CHANGED)
	assert_not_null(changed)
	assert_eq([changed.side, changed.stat, changed.stages], [F, &"spe", -1])
	battle = _battle(&"squirtle", &"bulbasaur", [2, 1, 50, 2, 16, 11, 50])
	battle.get_player_side().active.pokemon.replace_move(0, &"bubble", _data)
	events = battle.submit(BattleAction.move(0))
	assert_eq(_find(events.slice(0, 4), K.STAT_CHANGED), null, "11 > 10 : rien")
	assert_eq(_rng.remaining(), 0)


# --- K.O. et fin ------------------------------------------------------------------------

func test_knock_out_ends_the_battle_before_the_foe_acts() -> void:
	var battle := _battle(&"charmander", &"squirtle", [1, 50, 2, 16])
	battle.get_foe_side().active.pokemon.hp = 1
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_kinds(events).slice(1), [["MOVE_USED", "PLAYER"], ["DAMAGE", "FOE"],
		["FAINTED", "FOE"], ["BATTLE_ENDED", "PLAYER"]])
	assert_eq([events[2].amount, events[2].hp], [1, 0])
	assert_eq(events[4].outcome, Battle.Outcome.WIN)
	assert_eq(events[4].trainer_name, "Le Rival")
	assert_eq(battle.get_state(), Battle.State.OVER)
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)
	assert_eq(battle.submit(BattleAction.move(0)).size(), 0, "plus aucune action")
	assert_push_error("action refusée")


func test_player_knocked_out_is_a_loss() -> void:
	var battle := _battle(&"squirtle", &"charmander", [1, 50, 2, 16])
	battle.get_player_side().active.pokemon.hp = 1
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_kinds(events).slice(-2), [["FAINTED", "PLAYER"], ["BATTLE_ENDED", "PLAYER"]])
	assert_eq(battle.get_outcome(), Battle.Outcome.LOSS)


func test_next_pokemon_is_sent_at_the_end_of_the_turn() -> void:
	var battle := _battle(&"charmander", &"squirtle", [1, 50, 2, 16], [&"squirtle",
		&"bulbasaur"])
	battle.get_foe_side().active.pokemon.hp = 1
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_kinds(events).slice(1), [["MOVE_USED", "PLAYER"], ["DAMAGE", "FOE"],
		["FAINTED", "FOE"], ["SENT_OUT", "FOE"]])
	assert_eq(events[4].species_id, &"bulbasaur")
	assert_eq(battle.get_state(), Battle.State.CHOOSING)


# --- Lutte ------------------------------------------------------------------------------

func test_struggle_when_no_pp_is_left() -> void:
	# Lutte : ⌊⌊4·50·10/11⌋/50⌋ + 2 = 5, recul ⌊18/4⌋ = 4 ; Charge de Carapuce : 5.
	var battle := _battle(&"charmander", &"squirtle", [1, 2, 16, 50, 2, 16])
	for slot: MoveSlot in battle.get_player_side().active.pokemon.moves:
		slot.pp = 0
	assert_eq(battle.get_usable_moves(), [] as Array[int])
	assert_false(battle.is_legal(BattleAction.move(0)))
	assert_true(battle.is_legal(BattleAction.move(BattleAction.STRUGGLE)))
	var events := battle.submit(BattleAction.move(BattleAction.STRUGGLE))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_kinds(events).slice(1), [["MOVE_USED", "PLAYER"], ["DAMAGE", "FOE"],
		["RECOIL", "PLAYER"], ["MOVE_USED", "FOE"], ["DAMAGE", "PLAYER"]])
	assert_eq([events[1].move_id, events[1].pp], [&"struggle", -1])
	assert_eq([events[2].amount, events[2].hp], [5, 14])
	assert_eq([events[3].amount, events[3].hp, events[3].max_hp], [4, 14, 18])
	assert_eq(events[5].hp, 9)


func test_foe_without_pp_struggles_too() -> void:
	var battle := _battle(&"charmander", &"squirtle", [50, 2, 16, 2, 16])
	for slot: MoveSlot in battle.get_foe_side().active.pokemon.moves:
		slot.pp = 0
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "aucun tirage d'IA sans PP")
	assert_eq(events[3].move_id, &"struggle")


func test_both_fainting_on_recoil_is_a_win_for_the_user() -> void:
	var battle := _battle(&"charmander", &"squirtle", [1, 2, 16])
	var player := battle.get_player_side().active.pokemon
	for slot: MoveSlot in player.moves:
		slot.pp = 0
	player.hp = 1
	battle.get_foe_side().active.pokemon.hp = 1
	var events := battle.submit(BattleAction.move(BattleAction.STRUGGLE))
	assert_eq(_kinds(events).slice(-3), [["FAINTED", "FOE"], ["FAINTED", "PLAYER"],
		["BATTLE_ENDED", "PLAYER"]])
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)


# --- Actions illégales ------------------------------------------------------------------

func test_illegal_actions_are_refused() -> void:
	var battle := Battle.new(BattleSide.new(_party([&"charmander"]), true),
		BattleSide.new(_party([&"squirtle"]), false), _data, ScriptedRng.new())
	assert_eq(battle.submit(BattleAction.move(0)).size(), 0, "avant start")
	battle.start()
	assert_eq(battle.submit(BattleAction.move(2)).size(), 0, "emplacement vide")
	assert_eq(battle.submit(BattleAction.move(BattleAction.STRUGGLE)).size(), 0,
		"Lutte alors qu'il reste des PP")
	assert_eq(battle.submit(null).size(), 0)
	battle.get_player_side().active.pokemon.moves[1].pp = 0
	assert_eq(battle.submit(BattleAction.move(1)).size(), 0, "plus de PP")
	assert_push_error_count(5)
	assert_eq(battle.get_turn(), 0)
	assert_eq(battle.get_player_side().active.pokemon.moves[0].pp, 35, "rien n'a bougé")


# --- Reproductibilité -------------------------------------------------------------------

func _full_log(seed_value: int) -> Array:
	var rng := GameRng.new(seed_value)
	var player_party := Party.new()
	player_party.add(PokemonFactory.create(_data, &"charmander", 5, rng))
	var foe_party := Party.new()
	foe_party.add(PokemonFactory.create(_data, &"squirtle", 5, rng))
	var player := BattleSide.new(player_party, true)
	var battle := Battle.new(player, BattleSide.new(foe_party, false, "Le Rival"), _data, rng)
	var journal: Array = []
	for event: BattleEvent in battle.start():
		journal.append(event.to_dict())
	var chooser := BattleAI.new()
	while battle.get_state() == Battle.State.CHOOSING and battle.get_turn() < 200:
		for event: BattleEvent in battle.submit(chooser.choose(player, null, rng)):
			journal.append(event.to_dict())
	return journal


func test_same_seed_same_actions_same_log() -> void:
	var first := _full_log(42)
	assert_eq(first, _full_log(42))
	assert_eq(first[-1]["kind"], "BATTLE_ENDED")
	assert_ne(first, _full_log(43))
