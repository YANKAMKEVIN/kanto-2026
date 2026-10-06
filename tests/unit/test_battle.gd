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


# --- Fuite (jalon 5 §2.2) ---------------------------------------------------------------

## Combat sauvage : camp adverse sans dresseur, règles [method BattleRules.for_wild].
func _wild(player: StringName, foe: StringName, draws: Array[int]) -> Battle:
	_rng = ScriptedRng.new(draws)
	var battle := Battle.new(BattleSide.new(_party([player]), true),
		BattleSide.new(_party([foe]), false, ""), _data, _rng, BattleRules.for_wild())
	battle.start()
	return battle


func test_run_is_illegal_without_rules() -> void:
	# Combat du rival (règles nulles = comportement du 4) : la fuite est refusée.
	var battle := _battle(&"charmander", &"squirtle", [])
	assert_false(battle.can_flee())
	assert_false(battle.is_legal(BattleAction.run()))
	assert_eq(battle.submit(BattleAction.run()).size(), 0)
	assert_eq(battle.get_state(), Battle.State.CHOOSING, "le combat continue")
	assert_push_error("action refusée")


func test_run_is_illegal_against_a_trainer() -> void:
	_rng = ScriptedRng.new([])
	var battle := Battle.new(BattleSide.new(_party([&"charmander"]), true),
		BattleSide.new(_party([&"squirtle"]), false, "Le Rival"), _data, _rng,
		BattleRules.for_trainer())
	battle.start()
	assert_false(battle.is_legal(BattleAction.run()))
	assert_eq(battle.submit(BattleAction.run()).size(), 0)
	assert_push_error("action refusée")


func test_run_succeeds_when_faster() -> void:
	# Salamèche (Vit 11) fuit un Carapuce sauvage (Vit 9) : réussite assurée, sans tirage,
	# avant toute capacité de l'adversaire.
	var battle := _wild(&"charmander", &"squirtle", [])
	assert_true(battle.can_flee())
	var events := battle.submit(BattleAction.run())
	assert_eq(_kinds(events), [["TURN_STARTED", "PLAYER"], ["FLED", "PLAYER"],
		["BATTLE_ENDED", "PLAYER"]])
	assert_eq(events[-1].outcome, Battle.Outcome.FLED)
	assert_eq(battle.get_state(), Battle.State.OVER)
	assert_eq(battle.get_outcome(), Battle.Outcome.FLED)
	assert_eq(_rng.remaining(), 0, "aucun tirage quand la fuite est assurée")


func test_run_fails_then_foe_acts() -> void:
	# Carapuce (Vit 9) contre un Salamèche sauvage (Vit 11) : A=9,B=11,F=104. roll(256)=200
	# → échec ; l'adversaire choisit (pick_index roll(2)=1 → Griffe) et joue.
	var battle := _wild(&"squirtle", &"charmander", [200, 1, 50, 2, 1])
	var events := battle.submit(BattleAction.run())
	var kinds := _kinds(events)
	assert_eq(kinds[0], ["TURN_STARTED", "PLAYER"])
	assert_eq(kinds[1], ["FLEE_FAILED", "PLAYER"])
	assert_true(kinds.has(["MOVE_USED", "FOE"]), "l'adversaire joue son tour")
	assert_eq(battle.get_state(), Battle.State.CHOOSING, "le combat continue")
	assert_eq(battle.get_outcome(), Battle.Outcome.NONE)


# --- XP, niveaux, apprentissage (jalon 5 §2.3) ------------------------------------------
# Roucool N3 (IV 0) : PV 15, Vit 8, ne connaît que Tornade (l'IA tire roll(1)). Courbe
# moyenne-lente des starters : N5 = 135, N6 = 179, N7 = 236, N8 = 314, N9 = 419, N10 = 560,
# N20 = 5460.

## Pokémon de niveau [param level], IV 0, mâle si l'espèce a deux sexes.
func _mon(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))


## Combat démarré : l'équipe [param team] contre [param foe] ; [param draws] : les tirages
## du moteur après le départ. Règles sauvages par défaut.
func _xp_battle(team: Array[Pokemon], foe: Pokemon, draws: Array[int],
		rules: BattleRules = BattleRules.for_wild(), trainer: String = "") -> Battle:
	_rng = ScriptedRng.new(draws)
	var party := Party.new()
	for pokemon: Pokemon in team:
		party.add(pokemon)
	var foes := Party.new()
	foes.add(foe)
	var battle := Battle.new(BattleSide.new(party, true), BattleSide.new(foes, false, trainer),
		_data, _rng, rules)
	battle.start()
	return battle


## Le Pokémon du joueur met K.O. l'adversaire (1 PV, ralenti) avec sa première capacité.
## Tirages : IA adverse, précision, critique (2 = non), aléatoire (16 = 100 %).
func _knock_out(battle: Battle) -> Array[BattleEvent]:
	battle.get_foe_side().active.pokemon.hp = 1
	battle.get_foe_side().active.change_stage(&"spe", -6)
	return battle.submit(BattleAction.move(0))


func _of_kind(events: Array[BattleEvent], kind: BattleEvent.Kind) -> Array[BattleEvent]:
	var result: Array[BattleEvent] = []
	for event: BattleEvent in events:
		if event.kind == kind:
			result.append(event)
	return result


## Somme des XP annoncées par les EXP_GAINED.
func _gained(events: Array[BattleEvent]) -> int:
	var total := 0
	for event: BattleEvent in _of_kind(events, K.EXP_GAINED):
		total += event.amount
	return total


func test_wild_knock_out_gives_exp_between_fainted_and_battle_ended() -> void:
	var charmander := _mon(&"charmander", 5)
	var battle := _xp_battle([charmander], _mon(&"pidgey", 3), [1, 50, 2, 16])
	var events := _knock_out(battle)
	assert_eq(_rng.remaining(), 0, "l'XP ne tire rien")
	assert_eq(_kinds(events).slice(1), [["MOVE_USED", "PLAYER"], ["DAMAGE", "FOE"],
		["FAINTED", "FOE"], ["EXP_GAINED", "PLAYER"], ["BATTLE_ENDED", "PLAYER"]])
	var gained := events[4]
	assert_eq([gained.amount, gained.level, gained.pokemon_name], [21, 5, "Salamèche"])
	assert_eq(gained.exp_from, 0.0)
	assert_almost_eq(gained.exp_to, 21.0 / 44.0, 0.0001)
	assert_eq(charmander.experience, 135 + 21)
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)


func test_level_up_then_learned_move_then_battle_ended() -> void:
	# Salamèche N8 à 1 XP du N9 : +21 → N9, apprend Flammèche (2 capacités : place libre).
	var charmander := _mon(&"charmander", 8)
	charmander.experience = 418
	var battle := _xp_battle([charmander], _mon(&"pidgey", 3), [1, 50, 2, 16])
	var events := _knock_out(battle)
	# La tranche du N8 (1 XP), le niveau, sa capacité, puis la tranche du N9, puis la fin.
	assert_eq(_kinds(events).slice(3), [["FAINTED", "FOE"], ["EXP_GAINED", "PLAYER"],
		["LEVEL_UP", "PLAYER"], ["MOVE_LEARNED", "PLAYER"], ["EXP_GAINED", "PLAYER"],
		["BATTLE_ENDED", "PLAYER"]])
	var first := events[4]
	assert_eq([first.amount, first.level, first.exp_to], [21, 8, 1.0],
		"XP totale sur la première tranche")
	assert_almost_eq(first.exp_from, 104.0 / 105.0, 0.0001, "N8 : 314 → 419")
	var level_up := events[5]
	assert_eq(level_up.level, 9)
	assert_eq([level_up.hp, level_up.max_hp], [charmander.hp, charmander.max_hp()])
	assert_eq(events[6].move_id, &"ember")
	assert_eq(events[6].level, 9)
	assert_true(charmander.knows_move(&"ember"), "appris par le moteur")
	assert_eq(charmander.moves.size(), 3)
	var second := events[7]
	assert_eq([second.amount, second.level, second.exp_from], [0, 9, 0.0])
	assert_almost_eq(second.exp_to, 20.0 / 141.0, 0.0001, "N9 : 419 → 560")
	assert_eq(charmander.level, 9)
	assert_eq(_gained(events), charmander.experience - 418, "XP = somme des événements")


func test_two_levels_at_once_give_two_slices() -> void:
	# Roucool N14 : ⌊50 × 14 / 7⌋ = 100 XP. Salamèche N5 à 136 XP → 236 = N7 tout juste.
	var charmander := _mon(&"charmander", 5)
	charmander.experience = 136
	var battle := _xp_battle([charmander], _mon(&"pidgey", 14), [1, 50, 2, 16])
	var events := _knock_out(battle)
	var slices := _of_kind(events, K.EXP_GAINED)
	assert_eq(slices.size(), 2, "une tranche par niveau traversé")
	assert_eq([slices[0].level, slices[0].amount, slices[0].exp_to], [5, 100, 1.0])
	assert_almost_eq(slices[0].exp_from, 1.0 / 44.0, 0.0001)
	assert_eq([slices[1].level, slices[1].amount, slices[1].exp_from, slices[1].exp_to],
		[6, 0, 0.0, 1.0])
	var levels: Array = []
	for event: BattleEvent in _of_kind(events, K.LEVEL_UP):
		levels.append(event.level)
	assert_eq(levels, [6, 7])
	assert_eq(_kinds(events).slice(-5), [["EXP_GAINED", "PLAYER"], ["LEVEL_UP", "PLAYER"],
		["EXP_GAINED", "PLAYER"], ["LEVEL_UP", "PLAYER"], ["BATTLE_ENDED", "PLAYER"]])
	assert_eq(charmander.level, 7)
	assert_eq(_gained(events), 100)
	assert_eq(charmander.experience, 236)


func test_two_levels_with_a_remainder_give_three_slices() -> void:
	# Roucool N15 : 107 XP. Salamèche N5 (135) → 242 : N7 et 6 XP de plus.
	var charmander := _mon(&"charmander", 5)
	var battle := _xp_battle([charmander], _mon(&"pidgey", 15), [1, 50, 2, 16])
	var events := _knock_out(battle)
	var slices := _of_kind(events, K.EXP_GAINED)
	assert_eq(slices.size(), 3)
	assert_eq([slices[2].level, slices[2].exp_from], [7, 0.0])
	assert_almost_eq(slices[2].exp_to, 6.0 / 78.0, 0.0001, "N7 : 236 → 314")
	assert_eq(_gained(events), 107)
	assert_eq(charmander.experience, 242)


func test_four_moves_offer_to_forget_and_change_nothing() -> void:
	# Bulbizarre N19 (4 capacités) à 1 XP du N20 : Poudre Toxik est proposée.
	var bulbasaur := _mon(&"bulbasaur", 19)
	bulbasaur.experience = 5459
	var before: Array[StringName] = []
	for slot: MoveSlot in bulbasaur.moves:
		before.append(slot.move_id)
	assert_eq(before, [&"tackle", &"growl", &"leech_seed", &"vine_whip"] as Array[StringName])
	var battle := _xp_battle([bulbasaur], _mon(&"pidgey", 3), [1, 50, 2, 16])
	var events := _knock_out(battle)
	var offered := _find(events, K.MOVE_FORGET_OFFERED)
	assert_not_null(offered)
	assert_eq([offered.move_id, offered.level, offered.side], [&"poison_powder", 20, P])
	assert_null(_find(events, K.MOVE_LEARNED))
	var after: Array[StringName] = []
	for slot: MoveSlot in bulbasaur.moves:
		after.append(slot.move_id)
	assert_eq(after, before, "rien n'est changé : la présentation fera choisir")
	assert_eq(bulbasaur.level, 20)
	assert_eq(_kinds(events)[-1], ["BATTLE_ENDED", "PLAYER"])


## Combat démarré avec les événements de départ conservés : [param team] contre [param foe].
func _start_with_events(team: Array[Pokemon], foe: Pokemon, draws: Array[int]) -> Array:
	_rng = ScriptedRng.new(draws)
	var party := Party.new()
	for pokemon: Pokemon in team:
		party.add(pokemon)
	var foes := Party.new()
	foes.add(foe)
	var battle := Battle.new(BattleSide.new(party, true), BattleSide.new(foes, false),
		_data, _rng, BattleRules.for_wild())
	return [battle, battle.start()]


func test_events_carry_the_party_index_of_the_pokemon() -> void:
	# Deux Bulbizarre N19 identiques : le second tient debout et apprend, le premier est K.O.
	var fainted := _mon(&"bulbasaur", 19)
	fainted.hp = 0
	var learner := _mon(&"bulbasaur", 19)
	learner.experience = 5459
	var started := _start_with_events([fainted, learner] as Array[Pokemon],
		_mon(&"pidgey", 3), [1, 50, 2, 16])
	var battle: Battle = started[0]
	var opening: Array[BattleEvent] = started[1]
	var sent: Array[BattleEvent] = _of_kind(opening, K.SENT_OUT)
	assert_eq(sent.size(), 2)
	assert_eq([sent[0].side, sent[0].party_index], [F, 0], "adversaire : en tête")
	assert_eq([sent[1].side, sent[1].party_index], [P, 1],
		"le moteur envoie le premier Pokémon non K.O., pas le premier de l'équipe")
	var events := _knock_out(battle)
	var offered := _find(events, K.MOVE_FORGET_OFFERED)
	assert_not_null(offered)
	assert_eq(offered.party_index, 1, "l'offre d'oubli porte la place de celui qui apprend")
	for kind: K in [K.EXP_GAINED, K.LEVEL_UP]:
		assert_eq(_find(events, kind).party_index, 1, "même place sur %s" % K.find_key(kind))
	assert_eq(_find(events, K.FAINTED).party_index, 0, "le Roucool adverse")


func test_the_party_index_tells_two_identical_pokemon_apart() -> void:
	# Même espèce, même nom, même niveau : seule la place les distingue. Ici le premier apprend.
	var first := _mon(&"bulbasaur", 19)
	first.experience = 5459
	var second := _mon(&"bulbasaur", 19)
	var started := _start_with_events([first, second] as Array[Pokemon],
		_mon(&"pidgey", 3), [1, 50, 2, 16])
	var events := _knock_out(started[0])
	var offered := _find(events, K.MOVE_FORGET_OFFERED)
	assert_not_null(offered)
	assert_eq(offered.party_index, 0)
	assert_eq(offered.pokemon_name, second.display_name(_data), "le nom seul est ambigu")
	assert_eq(offered.to_dict()["party_index"], 0, "visible dans le journal")


func test_no_exp_without_rules_or_against_the_first_rival() -> void:
	# Règles nulles (comportement du 4B) : pas d'XP.
	var battle := _battle(&"charmander", &"squirtle", [1, 50, 2, 16])
	var player := battle.get_player_side().active.pokemon
	var events := _knock_out(battle)
	assert_null(_find(events, K.EXP_GAINED))
	assert_eq(player.experience, 135)
	# Règles du premier combat du rival (données : rival_lab, gives_exp faux).
	var trainers := TrainerLibrary.new(_data)
	trainers.load_dir()
	var rival_rules := BattleRules.for_trainer(trainers.get_trainer(&"rival_lab"))
	assert_false(rival_rules.gives_exp)
	var charmander := _mon(&"charmander", 5)
	battle = _xp_battle([charmander], _mon(&"squirtle", 5), [2, 50, 2, 16], rival_rules,
		"Le Rival")
	events = _knock_out(battle)
	assert_null(_find(events, K.EXP_GAINED))
	assert_eq(_kinds(events).slice(-2), [["FAINTED", "FOE"], ["BATTLE_ENDED", "PLAYER"]])
	assert_eq(charmander.experience, 135)
	# Règles sauvages sans XP.
	var no_exp := BattleRules.for_wild()
	no_exp.gives_exp = false
	charmander = _mon(&"charmander", 5)
	battle = _xp_battle([charmander], _mon(&"pidgey", 3), [1, 50, 2, 16], no_exp)
	assert_null(_find(_knock_out(battle), K.EXP_GAINED))
	assert_eq(charmander.experience, 135)


func test_trainer_exp_is_multiplied() -> void:
	# Dresseur ordinaire (gives_exp vrai) : ×1,5 → 32 XP pour un Roucool N3.
	var charmander := _mon(&"charmander", 5)
	var battle := _xp_battle([charmander], _mon(&"pidgey", 3), [1, 50, 2, 16],
		BattleRules.for_trainer(TrainerData.new()), "Gamin")
	var events := _knock_out(battle)
	assert_eq(_gained(events), 32)
	assert_eq(charmander.experience, 135 + 32)


func test_fainted_participant_gets_nothing() -> void:
	# Salamèche (1 PV, ralenti) tombe sous Tornade ; Carapuce prend le relais et met Roucool
	# K.O. : Salamèche a participé mais est K.O., Carapuce reçoit tout.
	var charmander := _mon(&"charmander", 5)
	var squirtle := _mon(&"squirtle", 5)
	var battle := _xp_battle([charmander, squirtle], _mon(&"pidgey", 3),
		[1, 50, 2, 16, 1, 50, 2, 16])
	charmander.hp = 1
	battle.get_player_side().active.change_stage(&"spe", -6)
	var first := battle.submit(BattleAction.move(0))
	assert_eq(_kinds(first).slice(-2), [["DAMAGE", "PLAYER"], ["FAINTED", "PLAYER"]])
	# Jalon 7 : le joueur choisit son remplaçant.
	assert_eq(battle.get_state(), Battle.State.REPLACING)
	assert_eq(_kinds(battle.replace(1)), [["SENT_OUT", "PLAYER"]])
	assert_eq(battle.get_participants(), [charmander, squirtle] as Array[Pokemon])
	var events := _knock_out(battle)
	assert_eq(_rng.remaining(), 0)
	var slices := _of_kind(events, K.EXP_GAINED)
	assert_eq(slices.size(), 1)
	assert_eq([slices[0].pokemon_name, slices[0].amount], ["Carapuce", 21])
	assert_eq(charmander.experience, 135, "K.O. : rien")
	assert_eq(squirtle.experience, 135 + 21)


func test_both_fainting_gives_no_exp_to_the_fainted_user() -> void:
	# Lutte : Roucool K.O., puis le contrecoup met Salamèche K.O. : aucune XP.
	var charmander := _mon(&"charmander", 5)
	var battle := _xp_battle([charmander], _mon(&"pidgey", 3), [1, 2, 16])
	for slot: MoveSlot in charmander.moves:
		slot.pp = 0
	charmander.hp = 1
	battle.get_foe_side().active.pokemon.hp = 1
	var events := battle.submit(BattleAction.move(BattleAction.STRUGGLE))
	assert_eq(_kinds(events).slice(-3), [["FAINTED", "FOE"], ["FAINTED", "PLAYER"],
		["BATTLE_ENDED", "PLAYER"]])
	assert_eq(charmander.experience, 135)


func test_participants_reset_when_the_foe_changes() -> void:
	var battle := _battle(&"charmander", &"squirtle", [1, 50, 2, 16], [&"squirtle",
		&"bulbasaur"])
	var lead := battle.get_player_side().active.pokemon
	assert_eq(battle.get_participants(), [lead] as Array[Pokemon])
	battle.get_foe_side().active.pokemon.hp = 1
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_kinds(events)[-1], ["SENT_OUT", "FOE"])
	assert_eq(battle.get_participants(), [lead] as Array[Pokemon],
		"nouvel adversaire : le Pokémon en jeu seul")


func test_exp_log_is_reproducible() -> void:
	var logs: Array = []
	for i: int in 2:
		var charmander := _mon(&"charmander", 8)
		charmander.experience = 418
		var battle := _xp_battle([charmander], _mon(&"pidgey", 3), [1, 50, 2, 16])
		var journal: Array = []
		for event: BattleEvent in _knock_out(battle):
			journal.append(event.to_dict())
		logs.append(journal)
	assert_eq(logs[0], logs[1])


# --- Vampigraine (jalon 5 Q28) ----------------------------------------------------------
# Bulbizarre N7 (IV 0) : PV 23, Vit 11 ; Charge, Rugissement, Vampigraine (emplacement 2).

func test_leech_seed_plants_then_drains_at_the_end_of_the_turn() -> void:
	# Bulbizarre (plus rapide) plante la graine ; Roucool attaque ; fin du tour : ⌊15/8⌋ = 1.
	var bulbasaur := _mon(&"bulbasaur", 7)
	var battle := _xp_battle([bulbasaur], _mon(&"pidgey", 3), [1, 50, 50, 2, 16])
	var pidgey := battle.get_foe_side().active.pokemon
	assert_eq(pidgey.max_hp(), 15)
	var events := battle.submit(BattleAction.move(2))
	assert_eq(_rng.remaining(), 0, "la fin du tour ne tire rien")
	assert_eq(_kinds(events).slice(1), [["MOVE_USED", "PLAYER"], ["SEEDED", "FOE"],
		["MOVE_USED", "FOE"], ["DAMAGE", "PLAYER"], ["DRAINED", "FOE"]])
	assert_true(battle.get_foe_side().active.is_seeded())
	var drained := events[5]
	assert_eq([drained.amount, drained.hp, drained.max_hp], [1, 14, 15])
	assert_eq(drained.healed, mini(1, events[4].amount), "rendu au lanceur (≤ PV perdus)")
	assert_eq(drained.healed_hp, bulbasaur.hp)
	assert_eq(pidgey.hp, 14)


func test_leech_seed_does_not_affect_grass_types() -> void:
	var battle := _xp_battle([_mon(&"bulbasaur", 7)], _mon(&"bulbasaur", 5),
		[1, 50, 50, 2, 16])
	var events := battle.submit(BattleAction.move(2))
	var immune := _find(events, K.NO_EFFECT)
	assert_not_null(immune)
	assert_eq([immune.side, immune.move_id], [F, &"leech_seed"])
	assert_null(_find(events, K.SEEDED))
	assert_null(_find(events, K.DRAINED))
	assert_false(battle.get_foe_side().active.is_seeded())


func test_leech_seed_on_a_seeded_target_fails() -> void:
	var battle := _xp_battle([_mon(&"bulbasaur", 7)], _mon(&"pidgey", 3),
		[1, 50, 50, 2, 16, 1, 50, 50, 2, 16])
	battle.submit(BattleAction.move(2))
	var events := battle.submit(BattleAction.move(2))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_kinds(events).slice(1, 3), [["MOVE_USED", "PLAYER"], ["MOVE_MISSED", "PLAYER"]])
	assert_null(_find(events, K.SEEDED))
	assert_not_null(_find(events, K.DRAINED), "la graine déjà plantée draine toujours")


func test_drain_takes_at_least_one_and_heals_up_to_max_hp() -> void:
	# Tornade de Roucool rate (Précision −6 : seuil 33, tirage 81) : Bulbizarre reste au
	# maximum, le drain ne lui rend rien.
	var bulbasaur := _mon(&"bulbasaur", 7)
	var battle := _xp_battle([bulbasaur], _mon(&"pidgey", 3), [1, 50, 81])
	battle.get_foe_side().active.change_stage(&"acc", -6)
	var events := battle.submit(BattleAction.move(2))
	assert_eq(_rng.remaining(), 0)
	var drained := _find(events, K.DRAINED)
	assert_eq(drained.amount, 1)
	assert_eq([drained.healed, drained.healed_hp], [0, bulbasaur.max_hp()], "déjà au maximum")


func test_drain_knock_out_gives_exp_and_ends_the_battle() -> void:
	var bulbasaur := _mon(&"bulbasaur", 7)
	var battle := _xp_battle([bulbasaur], _mon(&"pidgey", 3), [1, 50, 50, 2, 16])
	battle.get_foe_side().active.pokemon.hp = 1
	var events := battle.submit(BattleAction.move(2))
	var kinds := _kinds(events)
	assert_eq(kinds.slice(kinds.find(["DRAINED", "FOE"])), [["DRAINED", "FOE"],
		["FAINTED", "FOE"], ["EXP_GAINED", "PLAYER"], ["BATTLE_ENDED", "PLAYER"]])
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)
	assert_eq(bulbasaur.experience, 236 + 21)


# --- Capture (jalon 5D §2.4) ------------------------------------------------------------
# Roucool N3 (IV 0) : 15 PV ; Poké Ball ×1, taux 255. À PV pleins b = 49 795 : un test de
# secousse réussit si roll(65536) ≤ 49 795. Après un échec, l'IA de Roucool tire roll(1)
# (Tornade seule), puis précision, critique (2 = non), aléatoire (16).

## Objets réels (Poké Ball) : les règles sauvages y lisent le bonus de la Ball.
func _items() -> ItemLibrary:
	var items := ItemLibrary.new()
	items.load_dir()
	return items


## Combat sauvage de capture : Salamèche N5 contre Roucool N3, Balls permises.
func _capture_battle(draws: Array[int], items: ItemLibrary = null) -> Battle:
	return _xp_battle([_mon(&"charmander", 5)], _mon(&"pidgey", 3), draws,
		BattleRules.for_wild(items if items != null else _items()))


func test_ball_is_illegal_against_a_trainer_or_without_rules() -> void:
	_rng = ScriptedRng.new([])
	var trainer := Battle.new(BattleSide.new(_party([&"charmander"]), true),
		BattleSide.new(_party([&"squirtle"]), false, "Le Rival"), _data, _rng,
		BattleRules.for_trainer())
	trainer.get_rules().items = _items()
	trainer.start()
	assert_false(trainer.can_use_balls())
	assert_false(trainer.is_legal(BattleAction.ball(&"poke_ball")))
	assert_eq(trainer.submit(BattleAction.ball(&"poke_ball")).size(), 0)
	var rival := _battle(&"charmander", &"squirtle", [])
	assert_false(rival.can_use_balls(), "règles nulles (rival du 4B)")
	assert_eq(rival.submit(BattleAction.ball(&"poke_ball")).size(), 0)
	assert_push_error_count(2)
	assert_eq(trainer.get_state(), Battle.State.CHOOSING, "le combat continue")
	assert_eq(trainer.get_turn(), 0)


func test_ball_needs_a_known_ball() -> void:
	var no_items := _xp_battle([_mon(&"charmander", 5)], _mon(&"pidgey", 3), [],
		BattleRules.for_wild())
	assert_false(no_items.can_use_balls(), "sans objets connus")
	assert_false(no_items.is_legal(BattleAction.ball(&"poke_ball")))
	var battle := _capture_battle([])
	assert_true(battle.can_use_balls())
	assert_true(battle.is_legal(BattleAction.ball(&"poke_ball")))
	assert_false(battle.is_legal(BattleAction.ball(&"master_ball")), "objet inconnu")
	assert_false(battle.is_legal(BattleAction.ball(&"potion")), "pas une Ball")
	assert_eq(battle.submit(BattleAction.ball(&"potion")).size(), 0)
	assert_push_error("action refusée")


func test_capture_ends_the_battle_without_foe_action_nor_exp() -> void:
	var battle := _capture_battle([1, 2, 3, 49795])
	var charmander := battle.get_player_side().active.pokemon
	var exp_before := charmander.experience
	var events := battle.submit(BattleAction.ball(&"poke_ball"))
	assert_eq(_rng.remaining(), 0, "4 tests, aucun tirage de l'IA")
	assert_eq(_kinds(events), [["TURN_STARTED", "PLAYER"], ["BALL_THROWN", "FOE"],
		["BALL_SHAKE", "FOE"], ["BALL_SHAKE", "FOE"], ["BALL_SHAKE", "FOE"], ["CAUGHT", "FOE"],
		["BATTLE_ENDED", "PLAYER"]])
	var thrown := events[1]
	assert_eq([thrown.item_id, thrown.item_name], [&"poke_ball", "Poké Ball"])
	assert_eq([thrown.species_id, thrown.level, thrown.hp, thrown.max_hp],
		[&"pidgey", 3, 15, 15])
	assert_eq([events[2].shake, events[3].shake, events[4].shake], [1, 2, 3])
	assert_eq(events[5].pokemon_name, "Roucool")
	assert_eq(events[6].outcome, Battle.Outcome.CAUGHT)
	assert_eq(battle.get_outcome(), Battle.Outcome.CAUGHT)
	assert_eq(battle.get_state(), Battle.State.OVER)
	assert_false(battle.can_use_balls(), "plus rien à lancer")
	assert_null(_find(events, K.EXP_GAINED), "pas d'XP à la capture (Q26, Rouge/Bleu)")
	assert_eq(charmander.experience, exp_before)
	assert_eq(battle.get_foe_side().active.pokemon.hp, 15, "le Pokémon capturé garde ses PV")


func test_broken_free_then_the_foe_plays_its_turn() -> void:
	var battle := _capture_battle([1, 49796, 1, 50, 2, 16])
	var events := battle.submit(BattleAction.ball(&"poke_ball"))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_kinds(events), [["TURN_STARTED", "PLAYER"], ["BALL_THROWN", "FOE"],
		["BALL_SHAKE", "FOE"], ["BROKE_FREE", "FOE"], ["MOVE_USED", "FOE"],
		["DAMAGE", "PLAYER"]])
	assert_eq(events[2].shake, 1)
	assert_eq(battle.get_state(), Battle.State.CHOOSING, "le combat continue")
	assert_eq(battle.get_outcome(), Battle.Outcome.NONE)
	assert_eq(battle.get_turn(), 1)


func test_broken_free_without_any_shake() -> void:
	var battle := _capture_battle([60000, 1, 50, 2, 16])
	var events := battle.submit(BattleAction.ball(&"poke_ball"))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_kinds(events).slice(1, 4), [["BALL_THROWN", "FOE"], ["BROKE_FREE", "FOE"],
		["MOVE_USED", "FOE"]])
	assert_null(_find(events, K.BALL_SHAKE))


func test_capture_reads_the_current_hp() -> void:
	# À 1 PV, b = 64 750 : les tirages de 60 000, qui échouent à PV pleins, passent.
	var battle := _capture_battle([60000, 60000, 60000, 60000])
	battle.get_foe_side().active.pokemon.hp = 1
	var events := battle.submit(BattleAction.ball(&"poke_ball"))
	assert_eq(battle.get_outcome(), Battle.Outcome.CAUGHT)
	assert_eq(events[1].hp, 1)


func test_capture_reads_the_ball_bonus_from_the_rules() -> void:
	# Une Ball ×3 : a = ⌊15·255·3/45⌋ = 255 → capturé sans tirage.
	var items := ItemLibrary.new()
	items.add_from_dict({"strong_ball": {"name": "Forte Ball", "plural": "Fortes Balls",
		"feminine": true, "category": "ball", "catch_bonus": 3, "description": "…"}})
	var battle := _capture_battle([], items)
	var events := battle.submit(BattleAction.ball(&"strong_ball"))
	assert_eq(_rng.calls, 0, "a ≥ 255 : aucun tirage")
	assert_eq(events[1].item_name, "Forte Ball")
	assert_eq(_of_kind(events, K.BALL_SHAKE).size(), 3)
	assert_eq(battle.get_outcome(), Battle.Outcome.CAUGHT)


func test_failed_ball_then_knock_out_still_gives_exp() -> void:
	var battle := _capture_battle([60000, 1, 50, 2, 16, 1, 50, 2, 16])
	battle.submit(BattleAction.ball(&"poke_ball"))
	var events := _knock_out(battle)
	assert_eq(_rng.remaining(), 0)
	assert_not_null(_find(events, K.EXP_GAINED), "la Ball ratée ne change rien à l'XP")
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)


func test_capture_log_is_reproducible() -> void:
	var logs: Array = []
	for i: int in 2:
		var rng := GameRng.new(2026)
		var party := Party.new()
		party.add(_mon(&"charmander", 5))
		var foes := Party.new()
		foes.add(_mon(&"pidgey", 3))
		var battle := Battle.new(BattleSide.new(party, true), BattleSide.new(foes, false, ""),
			_data, rng, BattleRules.for_wild(_items()))
		var journal: Array = []
		battle.start()
		while battle.get_state() == Battle.State.CHOOSING and battle.get_turn() < 50:
			for event: BattleEvent in battle.submit(BattleAction.ball(&"poke_ball")):
				journal.append(event.to_dict())
		logs.append(journal)
	assert_eq(logs[0], logs[1])
	assert_eq(logs[0][1]["kind"], "BALL_THROWN")
	assert_eq(logs[0][-1]["kind"], "BATTLE_ENDED")


# --- Soin en combat (jalon 6 §3.4, Q-10, Q-11) ------------------------------------------
# Salamèche N5 (18 PV) et Bulbizarre N5 (19 PV) contre Roucool N3 (Tornade seule). Après le
# soin, l'adversaire joue : IA roll(1)=1, précision 50, critique 2 (non), aléatoire 16.

const FOE_TURN: Array[int] = [1, 50, 2, 16]


func _heal_battle(draws: Array[int], rules: BattleRules = null) -> Battle:
	return _xp_battle([_mon(&"charmander", 5), _mon(&"bulbasaur", 5)], _mon(&"pidgey", 3),
		draws, rules if rules != null else BattleRules.for_wild(_items()))


func test_heal_takes_the_turn_then_the_foe_plays() -> void:
	var battle := _heal_battle(FOE_TURN)
	var charmander := battle.get_player_side().active.pokemon
	charmander.hp = 3
	var action := BattleAction.heal(&"potion", 0)
	assert_true(action.is_heal())
	assert_false(BattleAction.ball(&"poke_ball").is_heal())
	assert_true(battle.can_use_heal_items())
	assert_true(battle.is_legal(action))
	var events := battle.submit(action)
	assert_eq(_rng.remaining(), 0, "aucun tirage propre au soin ; puis le tour adverse")
	var kinds := _kinds(events)
	assert_eq(kinds.slice(0, 3), [["TURN_STARTED", "PLAYER"], ["ITEM_USED", "PLAYER"],
		["MOVE_USED", "FOE"]], "le soin avant l'adversaire, qui joue ensuite (Q-10)")
	var used := events[1]
	assert_eq([used.item_id, used.item_name, used.amount, used.hp, used.max_hp,
		used.party_index, used.species_id, used.pokemon_name],
		[&"potion", "Potion", 15, 18, 18, 0, &"charmander", "Salamèche"], "PV bornés : +15")
	assert_lt(charmander.hp, 18, "puis Tornade le touche")
	assert_eq(battle.get_state(), Battle.State.CHOOSING)
	assert_eq(battle.get_turn(), 1)


func test_heal_a_member_who_is_not_in_play() -> void:
	var battle := _heal_battle(FOE_TURN)
	var bulbasaur := battle.get_player_side().party.get_at(1)
	bulbasaur.hp = 2
	var events := battle.submit(BattleAction.heal(&"potion", 1))
	var used := _find(events, K.ITEM_USED)
	assert_eq([used.party_index, used.species_id, used.amount, used.hp], [1, &"bulbasaur", 17, 19])
	assert_eq(bulbasaur.hp, 19)
	assert_eq(battle.get_player_side().active.pokemon.species_id, &"charmander",
		"le Pokémon en jeu ne change pas")
	assert_not_null(_find(events, K.MOVE_USED), "l'adversaire joue")


func test_heal_is_refused_on_full_hp_fainted_or_missing_member() -> void:
	var battle := _heal_battle([])
	var party := battle.get_player_side().party
	party.get_at(1).hp = 0
	assert_false(battle.is_legal(BattleAction.heal(&"potion", 0)), "PV pleins")
	assert_false(battle.is_legal(BattleAction.heal(&"potion", 1)), "K.O. (Q-11)")
	assert_false(battle.is_legal(BattleAction.heal(&"potion", 2)), "pas de membre")
	party.get_at(0).hp = 1
	assert_false(battle.is_legal(BattleAction.heal(&"poke_ball", 0)), "une Ball ne soigne pas")
	assert_false(battle.is_legal(BattleAction.heal(&"elixir", 0)), "objet inconnu")
	assert_false(battle.is_legal(BattleAction.ball(&"potion")), "la Potion ne se lance pas")
	assert_eq(battle.submit(BattleAction.heal(&"potion", 1)).size(), 0)
	assert_push_error("action refusée")
	assert_eq(battle.get_turn(), 0, "rien n'a été joué")
	assert_eq(party.get_at(1).hp, 0)


func test_heal_needs_rules_and_items() -> void:
	var rival := _battle(&"charmander", &"squirtle", [])
	rival.get_player_side().active.pokemon.hp = 1
	assert_false(rival.can_use_heal_items(), "règles nulles (rival du 4B)")
	assert_false(rival.is_legal(BattleAction.heal(&"potion", 0)))
	var no_items := _heal_battle([], BattleRules.for_wild())
	no_items.get_player_side().active.pokemon.hp = 1
	assert_false(no_items.is_legal(BattleAction.heal(&"potion", 0)), "sans objets connus")
	var trainer_rules := BattleRules.for_trainer()
	assert_true(trainer_rules.allow_heal_items, "Q-10 : permis contre un dresseur")
	var trainer := _heal_battle([], trainer_rules)
	trainer.get_player_side().active.pokemon.hp = 1
	assert_false(trainer.is_legal(BattleAction.heal(&"potion", 0)),
		"rival du labo : la requête ne passe aucun objet")
	assert_eq(trainer.item_context(), ItemData.CONTEXT_TRAINER_BATTLE)
	var with_items := _heal_battle([], BattleRules.for_trainer(null, _items()))
	with_items.get_player_side().active.pokemon.hp = 1
	assert_true(with_items.is_legal(BattleAction.heal(&"potion", 0)))
	assert_false(with_items.is_legal(BattleAction.ball(&"poke_ball")),
		"toujours pas de Ball contre un dresseur")
	assert_eq(_heal_battle([]).item_context(), ItemData.CONTEXT_WILD_BATTLE)


func test_the_engine_never_touches_the_bag_and_the_rules_stay_as_in_j5() -> void:
	var wild := BattleRules.for_wild(_items())
	assert_true(wild.allow_balls and wild.allow_heal_items and wild.can_flee)
	var trainer := BattleRules.for_trainer()
	assert_false(trainer.allow_balls or trainer.can_flee)
	assert_null(trainer.items)
	# Le moteur n'a aucun Sac : une Potion « donnée » ne retire rien nulle part ; c'est le
	# directeur qui la retire (T12). Le soin rendu est celui des données.
	var battle := _heal_battle(FOE_TURN)
	battle.get_player_side().active.pokemon.hp = 1
	var used := _find(battle.submit(BattleAction.heal(&"potion", 0)), K.ITEM_USED)
	assert_eq(used.amount, 17)


func test_heal_log_is_reproducible() -> void:
	var logs: Array = []
	for i: int in 2:
		var rng := GameRng.new(77)
		var party := Party.new()
		party.add(_mon(&"charmander", 5))
		var foes := Party.new()
		foes.add(_mon(&"pidgey", 3))
		var battle := Battle.new(BattleSide.new(party, true), BattleSide.new(foes, false, ""),
			_data, rng, BattleRules.for_wild(_items()))
		var journal: Array = []
		battle.start()
		while battle.get_state() == Battle.State.CHOOSING and battle.get_turn() < 50:
			var action := BattleAction.heal(&"potion", 0)
			if not battle.is_legal(action):
				action = BattleAction.move(0)
			for event: BattleEvent in battle.submit(action):
				journal.append(event.to_dict())
		logs.append(journal)
	assert_eq(logs[0], logs[1])
