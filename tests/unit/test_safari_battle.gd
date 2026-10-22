extends GutTest
## Rencontre Safari, moteur pur (J23, T13 ; dossier 26 §5, `jalon-23.md` §2.3) : SafariBattle,
## ordre d'un tour, dernière Ball, fuite et colère par tirages imposés ou graine fixe, textes 20 à
## 29 (dossier 26 §8, validés le 2026-10-16), requête et règles Safari.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const K := BattleEvent.Kind
## Tirages d'une Safari Ball : 1 réussit chaque test de secousse, 65536 échoue au premier.
const SHAKE_PASS := 1
const SHAKE_FAIL := 65536
## Tirage de fuite roll(256) : 256 → 255, jamais < seuil (≤ 255) ; 1 → 0, fuite si seuil > 0.
const NO_FLEE := 256
const FLEE := 1

var _data: PokemonData
var _texts: BattleText


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_texts = BattleText.new()
	_texts.load_file()


func _foe(species: StringName = &"scyther", level: int = 23) -> Pokemon:
	var foe := PokemonFactory.create(_data, species, level, GameRng.new(7))
	foe.gender = Pokemon.Gender.MALE
	return foe


func _visit(balls: int = 30) -> SafariVisit:
	var visit := SafariVisit.new()
	visit.active = true
	visit.steps_left = 100
	visit.balls_left = balls
	return visit


func _battle(foe: Pokemon, visit: SafariVisit, rng: GameRng) -> SafariBattle:
	var battle := SafariBattle.new(foe, _data, visit, 2.0, rng)
	battle.start()
	return battle


func _kinds(events: Array[BattleEvent]) -> Array[BattleEvent.Kind]:
	var result: Array[BattleEvent.Kind] = []
	for event: BattleEvent in events:
		result.append(event.kind)
	return result


func _lines(events: Array[BattleEvent]) -> Array[String]:
	var result: Array[String] = []
	for event: BattleEvent in events:
		result.append_array(_texts.lines(event, _data))
	return result


# --- Ouverture ------------------------------------------------------------------------------

func test_start_shows_the_wild_pokemon_alone() -> void:
	var battle := SafariBattle.new(_foe(), _data, _visit(), 2.0, ScriptedRng.new())
	var events := battle.start()
	assert_eq(_kinds(events), [K.SENT_OUT] as Array[BattleEvent.Kind], "aucun Pokémon allié")
	assert_eq(events[0].side, BattleEvent.SideId.FOE)
	assert_eq(events[0].trainer_name, "", "sauvage")
	assert_eq(_lines(events), ["Un Insécateur sauvage apparaît !"] as Array[String], "texte 20")
	assert_eq(battle.start().size(), 0, "une seule ouverture")
	assert_eq(battle.get_state(), SafariBattle.State.CHOOSING)
	assert_eq(battle.get_rules().rate, 45, "taux de base de l'espèce")


func test_no_action_is_legal_before_the_start() -> void:
	var battle := SafariBattle.new(_foe(), _data, _visit(), 2.0, ScriptedRng.new())
	assert_false(battle.is_legal(BattleAction.bait()))
	assert_false(battle.is_legal(BattleAction.move(0)), "aucune capacité")


# --- FUIR -----------------------------------------------------------------------------------

func test_run_always_succeeds_without_any_draw() -> void:
	var rng := ScriptedRng.new()
	var battle := _battle(_foe(), _visit(), rng)
	var events := battle.submit(BattleAction.run())
	assert_eq(_kinds(events), [K.SAFARI_LEFT, K.BATTLE_ENDED] as Array[BattleEvent.Kind])
	assert_eq(_lines(events), ["Tu t'éloignes doucement."] as Array[String], "texte 27")
	assert_eq(battle.get_outcome(), Battle.Outcome.FLED)
	assert_eq(battle.get_state(), SafariBattle.State.OVER)
	assert_eq(rng.calls, 0, "aucun tirage")


# --- Safari Ball ----------------------------------------------------------------------------

func test_ball_breaks_free_then_end_turn_then_flee_test() -> void:
	var visit := _visit(30)
	var rng := ScriptedRng.new([SHAKE_FAIL, NO_FLEE])
	var battle := _battle(_foe(), visit, rng)
	var events := battle.submit(BattleAction.safari_ball())
	assert_eq(_kinds(events), [K.SAFARI_BALL_THROWN, K.BROKE_FREE] as Array[BattleEvent.Kind])
	assert_eq(events[0].amount, 29, "Balls restantes portées par le lancer")
	assert_eq(_lines(events.slice(0, 1)), ["Le Dresseur lance une SAFARI BALL !"] as Array[String],
		"texte 21")
	assert_eq(visit.balls_left, 29, "on_ball_thrown")
	assert_true(visit.active)
	assert_eq(rng.calls, 2, "un test de secousse puis le test de fuite")
	assert_eq(battle.get_state(), SafariBattle.State.CHOOSING)


func test_ball_capture_ends_the_battle_without_flee_test() -> void:
	var visit := _visit(10)
	var rng := ScriptedRng.new([SHAKE_PASS, SHAKE_PASS, SHAKE_PASS, SHAKE_PASS])
	var battle := _battle(_foe(), visit, rng)
	var events := battle.submit(BattleAction.safari_ball())
	assert_eq(_kinds(events), [K.SAFARI_BALL_THROWN, K.BALL_SHAKE, K.BALL_SHAKE, K.BALL_SHAKE,
		K.CAUGHT, K.BATTLE_ENDED] as Array[BattleEvent.Kind])
	assert_eq(battle.get_outcome(), Battle.Outcome.CAUGHT)
	assert_eq(rng.calls, 4, "aucun test de fuite après une capture")
	assert_eq(visit.balls_left, 9)
	assert_true(visit.active)
	for event: BattleEvent in events:
		assert_ne(event.kind, K.EXP_GAINED, "aucune XP")


func test_last_ball_without_capture_ends_the_battle_and_the_visit() -> void:
	var visit := _visit(1)
	var rng := ScriptedRng.new([SHAKE_FAIL])
	var battle := _battle(_foe(), visit, rng)
	var events := battle.submit(BattleAction.safari_ball())
	assert_eq(_kinds(events), [K.SAFARI_BALL_THROWN, K.BROKE_FREE, K.SAFARI_NO_BALLS,
		K.BATTLE_ENDED] as Array[BattleEvent.Kind])
	assert_eq(_lines(events.slice(2, 3)),
		["Ding-dong ! Tu n'as plus de SAFARI BALLS !"] as Array[String], "texte 29")
	assert_eq(battle.get_outcome(), Battle.Outcome.FLED, "[D] fin sans capture")
	assert_eq(rng.calls, 1, "ni fin de tour, ni test de fuite")
	assert_false(visit.active, "la dernière Ball termine la visite")
	assert_eq(visit.balls_left, 0)


func test_last_ball_with_capture_ends_the_battle_and_the_visit() -> void:
	var visit := _visit(1)
	var rng := ScriptedRng.new([SHAKE_PASS, SHAKE_PASS, SHAKE_PASS, SHAKE_PASS])
	var battle := _battle(_foe(), visit, rng)
	var events := battle.submit(BattleAction.safari_ball())
	var kinds := _kinds(events)
	assert_eq(kinds.slice(-3), [K.CAUGHT, K.SAFARI_NO_BALLS, K.BATTLE_ENDED] \
		as Array[BattleEvent.Kind], "texte 29 après la capture")
	assert_eq(battle.get_outcome(), Battle.Outcome.CAUGHT)
	assert_false(visit.active)
	assert_false(battle.is_legal(BattleAction.safari_ball()), "plus rien après la fin")


func test_capture_uses_the_safari_rate_and_the_ball_bonus() -> void:
	# Leveinard (taux 30) à 1 PV : a ≈ 59 au taux de base (tirages), a ≥ 255 après trois
	# cailloux (taux 240) : capture assurée, sans aucun tirage de secousse.
	var foe := _foe(&"chansey", 23)
	foe.hp = 1
	# Colère de 5 à chaque caillou : elle ne retombe jamais à 0 (le taux reste doublé).
	var rng := ScriptedRng.new([5, NO_FLEE, 5, NO_FLEE, 5, NO_FLEE])
	var battle := _battle(foe, _visit(), rng)
	for i: int in 3:
		battle.submit(BattleAction.rock())
	assert_eq(battle.get_rules().rate, 240, "30 × 2 × 2 × 2")
	var calls := rng.calls
	var events := battle.submit(BattleAction.safari_ball())
	assert_eq(_kinds(events).slice(-2), [K.CAUGHT, K.BATTLE_ENDED] as Array[BattleEvent.Kind])
	assert_eq(rng.calls, calls, "a ≥ 255 : aucun tirage")
	assert_gte(CaptureCalc.catch_value(foe.max_hp(), 1, 240, battle.ball_bonus), 255)


func test_status_gives_no_capture_bonus() -> void:
	# Noeunoeuf (taux 90) à 1 PV, endormi : a ≈ 179 (× 2 du statut le rendrait assuré).
	var foe := _foe(&"exeggcute", 24)
	foe.hp = 1
	foe.status = StatusRules.SLEEP
	var rng := ScriptedRng.new([SHAKE_FAIL, NO_FLEE])
	var battle := _battle(foe, _visit(), rng)
	var events := battle.submit(BattleAction.safari_ball())
	assert_true(_kinds(events).has(K.BROKE_FREE), "aucun bonus de statut : tirage, échec")


# --- Appât, caillou, fuite ------------------------------------------------------------------

func test_bait_feeds_then_flee_test_at_a_quarter() -> void:
	var foe := _foe()
	var rng := ScriptedRng.new([3, FLEE])
	var battle := _battle(foe, _visit(), rng)
	var events := battle.submit(BattleAction.bait())
	assert_eq(_kinds(events), [K.BAIT_THROWN, K.SAFARI_EATING, K.SAFARI_FLED, K.BATTLE_ENDED] \
		as Array[BattleEvent.Kind])
	assert_eq(_lines(events.slice(0, 3)), ["Le Dresseur lance un appât.", "Insécateur mange !",
		"Insécateur s'enfuit !"] as Array[String], "textes 22, 24, 26")
	assert_eq(battle.get_rules().rate, 22, "45 ÷ 2")
	assert_eq(battle.get_rules().bait, 2, "3 tours de repas, un mangé")
	assert_eq(battle.get_outcome(), Battle.Outcome.FOE_FLED)


func test_rock_angers_and_doubles_the_flee_threshold() -> void:
	var foe := _foe()
	var rng := ScriptedRng.new([2, NO_FLEE])
	var battle := _battle(foe, _visit(), rng)
	var events := battle.submit(BattleAction.rock())
	assert_eq(_kinds(events), [K.ROCK_THROWN, K.SAFARI_ANGRY] as Array[BattleEvent.Kind])
	assert_eq(_lines(events), ["Le Dresseur lance un caillou.",
		"Insécateur est en colère !"] as Array[String], "textes 23, 25")
	assert_eq(battle.get_rules().rate, 90)
	assert_eq(battle.get_rules().anger, 1)
	assert_eq(battle.get_rules().flee_threshold(foe.stats[&"spe"]),
		mini(foe.stats[&"spe"] * 2 * 2, 255), "colère : × 2 plafonné")


func test_anger_wears_off_and_restores_the_base_rate() -> void:
	var rng := ScriptedRng.new([1, NO_FLEE])
	var battle := _battle(_foe(), _visit(), rng)
	var events := battle.submit(BattleAction.rock())
	assert_true(_kinds(events).has(K.SAFARI_ANGRY), "le tour de colère est joué")
	assert_eq(battle.get_rules().anger, 0, "1 tour de colère, déjà passé")
	assert_eq(battle.get_rules().rate, 45, "fin de colère : taux de base")


func test_fixed_seed_reproduces_the_same_encounter() -> void:
	var runs: Array = []
	for attempt: int in 2:
		var rng := GameRng.new(4242)
		var battle := _battle(_foe(), _visit(30), rng)
		var log: Array = []
		var plan: Array[BattleAction] = [BattleAction.rock(), BattleAction.rock(),
			BattleAction.bait(), BattleAction.safari_ball(), BattleAction.safari_ball()]
		for action: BattleAction in plan:
			if battle.get_state() != SafariBattle.State.CHOOSING:
				break
			log.append(_kinds(battle.submit(action)))
		log.append(battle.get_outcome())
		runs.append(log)
	assert_eq(runs[0], runs[1], "même graine, même rencontre")


func test_a_seed_with_anger_then_flight_exists_and_is_stable() -> void:
	# Graine fixe trouvée une fois pour toutes : caillou → colère, puis fuite au même tour.
	var found := -1
	for seed: int in range(1, 400):
		var battle := _battle(_foe(), _visit(), GameRng.new(seed))
		var kinds := _kinds(battle.submit(BattleAction.rock()))
		if kinds == ([K.ROCK_THROWN, K.SAFARI_ANGRY, K.SAFARI_FLED, K.BATTLE_ENDED] \
				as Array[BattleEvent.Kind]):
			found = seed
			break
	assert_gt(found, 0, "Insécateur (rapide) fuit souvent en colère")
	var again := _battle(_foe(), _visit(), GameRng.new(found))
	again.submit(BattleAction.rock())
	assert_eq(again.get_outcome(), Battle.Outcome.FOE_FLED)


# --- Requête, règles, libellés ----------------------------------------------------------------

func test_safari_request_and_rules() -> void:
	var visit := _visit()
	var request := BattleRequest.safari(WildEncounter.new(&"tauros", 28, &"safari_zone_north_grass"),
		_data, GameRng.new(3), Vector2i(4, 5), visit, 2.0)
	assert_true(request.is_safari())
	assert_true(request.is_wild())
	assert_same(request.safari_visit, visit)
	assert_almost_eq(request.safari_ball_bonus, 2.0, 0.0001)
	assert_eq(request.foe_party.get_lead().species_id, &"tauros")
	var rules := request.rules
	assert_true(rules.safari)
	assert_false(rules.gives_exp, "ni XP")
	assert_false(rules.allow_balls, "ni Balls du Sac")
	assert_false(rules.allow_heal_items, "ni soins")
	assert_true(rules.flee_always, "FUIR toujours réussi")
	assert_false(BattleRequest.wild(WildEncounter.new(&"tauros", 28, &""), _data, GameRng.new(3),
		Vector2i.ZERO).is_safari())


func test_menu_labels_come_from_the_battle_texts() -> void:
	var labels := BattleDirector.safari_action_labels(_texts, 30)
	assert_eq(labels[ActionGrid.ATTACK], "SAFARI BALL ×30")
	assert_eq(labels[ActionGrid.BAG], "APPÂT")
	assert_eq(labels[ActionGrid.TEAM], "CAILLOU")
	assert_eq(labels[ActionGrid.RUN], "FUIR")


func test_safari_beats() -> void:
	var foe := _foe()
	var battle := _battle(foe, _visit(), ScriptedRng.new([SHAKE_FAIL, NO_FLEE]))
	var beats := BattlePlayback.beats_for_log(battle.submit(BattleAction.safari_ball()), _texts,
		_data)
	assert_eq(beats[0].kind, BattleBeat.Kind.MESSAGE)
	assert_eq(beats[1].kind, BattleBeat.Kind.THROW, "la phrase, puis le lancer")
	var fled := BattleEvent.new(K.SAFARI_FLED, BattleEvent.SideId.FOE)
	fled.pokemon_name = "Insécateur"
	var fled_beats := BattlePlayback.beats(fled, _texts, _data)
	assert_eq(fled_beats[0].kind, BattleBeat.Kind.VANISH, "il disparaît, puis la phrase")
	assert_eq(fled_beats[1].text, "Insécateur s'enfuit !")
