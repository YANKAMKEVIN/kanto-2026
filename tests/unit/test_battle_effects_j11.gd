extends GutTest
## Confusion et effets simples du J11 (`jalon-11.md` §2.2, dossier 14 §3.2 et §4) :
## multi-coups, apeurement, Puissance, dégâts fixes ; matrice d'interactions avec les statuts.
##
## N5, IV 0 : Salamèche Vit 11 ; Rattata Vit 12 ; Roucool N3 15 PV, Vit 8 (Tornade seule).
## Tirages : IA (roll(1)), puis pour chaque Pokémon qui agit : statut (paralysie / gel :
## roll(100)), confusion (roll(100) si encore confus), précision, critique (2 = non),
## aléatoire (16) ; nombre de coups (roll(8)) après le premier coup ; effets à chance.

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


func _with_move(species: StringName, level: int, move_id: StringName) -> Pokemon:
	var pokemon := PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))
	pokemon.moves.clear()
	pokemon.moves.append(MoveSlot.new(move_id, _data.get_move(move_id).pp))
	return pokemon


func _battle(team: Array[Pokemon], foe: Pokemon, draws: Array[int]) -> Battle:
	_rng = ScriptedRng.new(draws)
	var party := Party.new()
	for pokemon: Pokemon in team:
		party.add(pokemon)
	var foes := Party.new()
	foes.add(foe)
	var battle := Battle.new(BattleSide.new(party, true), BattleSide.new(foes, false, ""), _data,
		_rng, BattleRules.for_wild())
	battle.start()
	return battle


func _count(events: Array[BattleEvent], kind: BattleEvent.Kind, side: BattleEvent.SideId) -> int:
	var n := 0
	for event: BattleEvent in events:
		if event.kind == kind and event.side == side:
			n += 1
	return n


func _find(events: Array[BattleEvent], kind: BattleEvent.Kind) -> BattleEvent:
	for event: BattleEvent in events:
		if event.kind == kind:
			return event
	return null


# --- Confusion -----------------------------------------------------------------------------

func test_supersonic_confuses_then_hurts_itself_on_33_or_less_then_snaps_out() -> void:
	var pidgey := _with_move(&"pidgey", 3, &"gust")
	var battle := _battle([_with_move(&"charmander", 5, &"supersonic")], pidgey,
		[1, 50, 2, 33, 16])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(_find(events, K.CONFUSED), "Roucool est confus (2 tours)")
	assert_not_null(_find(events, K.CONFUSION_CHECK))
	var hurt := _find(events, K.HURT_ITSELF)
	assert_eq(hurt.side, F)
	assert_gt(hurt.amount, 0)
	assert_eq(_count(events, K.MOVE_USED, F), 0, "il ne lance rien")
	_rng.push([1, 50, 50, 2, 16])
	events = battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(_find(events, K.CONFUSION_UNCHANGED), "déjà confus")
	assert_not_null(_find(events, K.CONFUSION_ENDED), "n'est plus confus")
	assert_eq(_count(events, K.MOVE_USED, F), 1, "et agit dans le même tour")


func test_confusion_is_lost_on_switch_and_never_saved() -> void:
	var battle := _battle([_with_move(&"charmander", 5, &"scratch"),
		_with_move(&"squirtle", 5, &"tackle")], _with_move(&"pidgey", 3, &"gust"), [1, 50, 2, 16])
	battle.get_player_side().active.confusion_turns = 3
	battle.submit(BattleAction.switch_to(1))
	assert_eq(battle.get_player_side().active.confusion_turns, 0, "nouveau Pokémon")
	assert_false(battle.get_player_side().party.get_at(0).to_dict().has("confusion"))


# --- Multi-coups ---------------------------------------------------------------------------

func test_fury_swipes_hits_two_to_five_times_and_reports_the_count() -> void:
	# Rattata (Vit 12) frappe d'abord : 6 PV par coup, roll(8) = 1 → 2 coups (12 sur 15 PV).
	var pidgey := _with_move(&"pidgey", 3, &"gust")
	var battle := _battle([_with_move(&"rattata", 5, &"fury_swipes")], pidgey,
		[1, 50, 2, 16, 1, 2, 16, 50, 2, 16])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_count(events, K.DAMAGE, F), 2, "1 → 2 coups")
	assert_eq(_find(events, K.MULTI_HIT).amount, 2)
	# Répartition : 1–3 → 2, 4–6 → 3, 7 → 4, 8 → 5.
	var counts: Array = []
	for draw: int in [3, 4, 6, 7, 8]:
		var sponge := _with_move(&"pidgey", 3, &"growl")
		sponge.hp = 999
		var b := _battle([_with_move(&"rattata", 5, &"fury_swipes")], sponge,
			[1, 50, 2, 16, draw])
		_rng.push([2, 16, 2, 16, 2, 16, 2, 16, 50])
		var log := b.submit(BattleAction.move(0))
		counts.append(_find(log, K.MULTI_HIT).amount)
	assert_eq(counts, [2, 3, 3, 4, 5])


func test_double_kick_always_hits_twice_and_stops_at_a_ko() -> void:
	var pidgey := _with_move(&"pidgey", 3, &"gust")
	pidgey.hp = 1
	var battle := _battle([_with_move(&"rattata", 5, &"double_kick")], pidgey, [1, 50, 2, 16])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "aucun roll(8) pour deux coups fixes")
	assert_eq(_count(events, K.DAMAGE, F), 1, "K.O. au premier coup")
	assert_eq(_find(events, K.MULTI_HIT).amount, 1, "« Touché 1 fois ! »")


# --- Apeurement ----------------------------------------------------------------------------

func test_bite_flinches_a_slower_target_on_30_or_less() -> void:
	var pidgey := _with_move(&"pidgey", 3, &"gust")
	var battle := _battle([_with_move(&"charmander", 5, &"bite")], pidgey, [1, 50, 2, 16, 30])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_eq(_find(events, K.FLINCHED).side, F)
	assert_eq(_count(events, K.MOVE_USED, F), 0)
	assert_false(battle.get_foe_side().active.flinched, "remis à faux en fin de tour")


func test_no_flinch_when_the_user_moves_second() -> void:
	var charmander := _with_move(&"charmander", 5, &"bite")
	charmander.status = StatusRules.PARALYSIS
	var battle := _battle([charmander], _with_move(&"pidgey", 3, &"gust"),
		[1, 50, 2, 16, 99, 50, 2, 16, 1])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "le tirage de l'effet a lieu")
	assert_null(_find(events, K.FLINCHED), "Roucool a déjà agi")


# --- Puissance et dégâts fixes -------------------------------------------------------------

func test_focus_energy_raises_the_crit_stage_once() -> void:
	var battle := _battle([_with_move(&"charmander", 5, &"focus_energy")],
		_with_move(&"pidgey", 3, &"growl"), [1, 50, 1, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(_find(events, K.FOCUSED))
	var user := battle.get_player_side().active
	assert_eq(DamageCalc.crit_denominator(user, _data.get_move(&"scratch")), 2, "1/24 → 1/2")
	events = battle.submit(BattleAction.move(0))
	assert_eq(_find(events, K.FAILED).side, P, "déjà concentré")


func test_super_fang_halves_and_seismic_toss_deals_the_level() -> void:
	var pidgey := _with_move(&"pidgey", 3, &"growl")
	var start_hp := pidgey.hp
	var battle := _battle([_with_move(&"rattata", 5, &"super_fang")], pidgey, [1, 50, 50])
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_find(events, K.DAMAGE).amount, floori(start_hp / 2.0))
	var other := _with_move(&"pidgey", 3, &"growl")
	battle = _battle([_with_move(&"mankey", 5, &"seismic_toss")], other, [1, 50, 50])
	events = battle.submit(BattleAction.move(0))
	assert_eq(_find(events, K.DAMAGE).amount, 5, "niveau du lanceur")


# --- Interactions --------------------------------------------------------------------------

func test_sleep_blocks_before_confusion_and_confusion_does_not_count_down() -> void:
	var pidgey := _with_move(&"pidgey", 3, &"gust")
	StatusRules.apply(StatusRules.SLEEP, pidgey, ScriptedRng.new([2]))
	var battle := _battle([_with_move(&"charmander", 5, &"growl")], pidgey, [1, 50])
	battle.get_foe_side().active.confusion_turns = 3
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0, "ni test de confusion ni coup")
	assert_not_null(_find(events, K.STATUS_PREVENTED))
	assert_null(_find(events, K.CONFUSION_CHECK))
	assert_eq(battle.get_foe_side().active.confusion_turns, 3, "pas décompté en dormant")


func test_full_paralysis_comes_before_confusion() -> void:
	var pidgey := _with_move(&"pidgey", 3, &"gust")
	pidgey.status = StatusRules.PARALYSIS
	var battle := _battle([_with_move(&"charmander", 5, &"growl")], pidgey, [1, 50, 1])
	battle.get_foe_side().active.confusion_turns = 3
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(_find(events, K.STATUS_PREVENTED))
	assert_null(_find(events, K.CONFUSION_CHECK))


func test_a_flinched_and_asleep_pokemon_only_sleeps() -> void:
	var pidgey := _with_move(&"pidgey", 3, &"gust")
	StatusRules.apply(StatusRules.SLEEP, pidgey, ScriptedRng.new([2]))
	var battle := _battle([_with_move(&"charmander", 5, &"bite")], pidgey, [1, 50, 2, 16, 1])
	var events := battle.submit(BattleAction.move(0))
	assert_not_null(_find(events, K.STATUS_PREVENTED))
	assert_null(_find(events, K.FLINCHED), "pas de message d'apeurement")


func test_a_confused_pokemon_hurting_itself_does_not_use_its_multi_hit() -> void:
	var rattata := _with_move(&"rattata", 5, &"fury_swipes")
	var battle := _battle([rattata], _with_move(&"pidgey", 3, &"growl"), [1, 30, 16, 50])
	battle.get_player_side().active.confusion_turns = 3
	var events := battle.submit(BattleAction.move(0))
	assert_eq(_rng.remaining(), 0)
	assert_not_null(_find(events, K.HURT_ITSELF))
	assert_null(_find(events, K.MULTI_HIT), "aucun coup")
	assert_eq(rattata.moves[0].pp, rattata.moves[0].max_pp, "aucun PP")


# --- Textes (dossier 14 §13, lot validé) ---------------------------------------------------

func test_the_validated_lines_of_the_new_events() -> void:
	var texts := BattleText.new()
	assert_true(texts.load_file())
	var event := BattleEvent.new(K.MULTI_HIT, F)
	event.amount = 3
	assert_eq(Array(texts.lines(event, _data)), ["Touché 3 fois !"])
	event = BattleEvent.new(K.CONFUSION_CHECK, F)
	event.pokemon_name = "Nidoran"
	event.gender = Pokemon.Gender.FEMALE
	assert_eq(Array(texts.lines(event, _data)), ["Nidoran est confuse…"])
	event = BattleEvent.new(K.HURT_ITSELF, P)
	event.pokemon_name = "Salamèche"
	assert_eq(Array(texts.lines(event, _data)), ["Salamèche se blesse dans sa confusion !"])
	event = BattleEvent.new(K.FLINCHED, P)
	event.pokemon_name = "Salamèche"
	assert_eq(Array(texts.lines(event, _data)), ["Salamèche a peur ! Impossible d'agir !"])
	event = BattleEvent.new(K.STATUS_PREVENTED, P)
	event.pokemon_name = "Salamèche"
	event.status = StatusRules.PARALYSIS
	assert_eq(Array(texts.lines(event, _data)), ["Salamèche est paralysé ! Impossible d'agir !"])
	event = BattleEvent.new(K.STATUS_ENDED, P)
	event.pokemon_name = "Salamèche"
	event.status = StatusRules.SLEEP
	assert_eq(Array(texts.lines(event, _data)), ["Salamèche se réveille !"])
	event = BattleEvent.new(K.FAILED, P)
	assert_eq(Array(texts.lines(event, _data)), ["Mais ça échoue !"])
