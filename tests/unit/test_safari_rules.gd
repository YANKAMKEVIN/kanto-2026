extends GutTest
## Parc Safari, rencontre (J23, dossier 26 §5, plan `jalon-23.md` §2.3, T4) : SafariRules, règles
## de Rouge/Bleu (`engine/battle/core.asm`), particularités comprises.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")


func test_begin_keeps_the_species_rate() -> void:
	var rules := SafariRules.begin(45)
	assert_eq(rules.rate, 45)
	assert_eq(rules.base_rate, 45)
	assert_eq(SafariRules.begin(0).rate, 1, "taux plancher 1")
	assert_eq(SafariRules.begin(400).rate, 255, "taux plafond 255")


func test_bait_halves_the_rate_calms_and_feeds() -> void:
	var rules := SafariRules.begin(45)
	rules.anger = 3
	rules.throw_bait(ScriptedRng.new([4]))
	assert_eq(rules.rate, 22, "45 ÷ 2")
	assert_eq(rules.anger, 0, "l'appât efface la colère")
	assert_eq(rules.bait, 4, "repas += 1 à 5 (tirage 4)")


func test_rock_doubles_the_rate_with_a_cap_and_angers() -> void:
	var rules := SafariRules.begin(200)
	rules.bait = 2
	rules.throw_rock(ScriptedRng.new([5]))
	assert_eq(rules.rate, 255, "200 × 2 plafonné à 255")
	assert_eq(rules.bait, 0, "le caillou efface le repas")
	assert_eq(rules.anger, 5)
	rules.throw_rock(ScriptedRng.new([1]))
	assert_eq(rules.anger, 6, "les colères s'additionnent")


func test_end_turn_eats_first_then_anger() -> void:
	var rules := SafariRules.begin(45)
	rules.bait = 1
	rules.anger = 0
	assert_eq(rules.end_turn(), SafariRules.EATING)
	assert_eq(rules.bait, 0)
	assert_eq(rules.end_turn(), SafariRules.NONE, "ni repas ni colère")
	rules.anger = 2
	assert_eq(rules.end_turn(), SafariRules.ANGRY)
	assert_eq(rules.anger, 1)


func test_the_end_of_anger_restores_the_base_rate_and_erases_the_baits() -> void:
	var rules := SafariRules.begin(45)
	rules.throw_bait(ScriptedRng.new([1]))
	rules.end_turn()
	assert_eq(rules.rate, 22, "le repas fini, la division reste (particularité RB)")
	rules.throw_rock(ScriptedRng.new([1]))
	assert_eq(rules.rate, 44)
	assert_eq(rules.end_turn(), SafariRules.ANGRY, "colère 1 → 0")
	assert_eq(rules.rate, 45, "fin de la colère : taux de base (efface l'appât)")


func test_several_baits_keep_dividing() -> void:
	var rules := SafariRules.begin(45)
	for i: int in 3:
		rules.throw_bait(ScriptedRng.new([1]))
		rules.end_turn()
	assert_eq(rules.rate, 5, "45 → 22 → 11 → 5, jamais annulé")


func test_no_flee_test_before_the_first_action() -> void:
	var rules := SafariRules.begin(45)
	var rng := ScriptedRng.new([])
	assert_false(rules.flees(110, rng))
	assert_eq(rng.calls, 0, "aucun tirage")


func test_flee_threshold_follows_the_state() -> void:
	var rules := SafariRules.begin(45)
	assert_eq(rules.flee_threshold(60), 120, "Vitesse × 2")
	assert_eq(rules.flee_threshold(200), 255, "plafond")
	rules.bait = 1
	assert_eq(rules.flee_threshold(60), 30, "en train de manger : ÷ 4")
	rules.bait = 0
	rules.anger = 1
	assert_eq(rules.flee_threshold(60), 240, "en colère : × 2")
	assert_eq(rules.flee_threshold(100), 255, "en colère : plafond 255")


func test_flee_compares_a_roll_from_0_to_255() -> void:
	var rules := SafariRules.begin(45)
	rules.throw_ball()
	assert_true(rules.flees(60, ScriptedRng.new([120])), "tirage 119 < 120 : fuite")
	assert_false(rules.flees(60, ScriptedRng.new([121])), "tirage 120 : reste")
