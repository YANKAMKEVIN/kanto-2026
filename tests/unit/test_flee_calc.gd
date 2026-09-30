extends GutTest
## FleeCalc : formule de fuite des 3e/4e générations (jalon 5 §2.2, Q18).
##
## Fuite assurée si la Vitesse du joueur ≥ celle du sauvage. Sinon F = ⌊A·128/B⌋ + 30·C,
## réussite si F > 255 ou roll(256) − 1 < F. Un seul tirage roll(256), seulement quand la
## fuite n'est pas déjà assurée.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")


func test_equal_or_faster_flees_without_a_roll() -> void:
	var rng := ScriptedRng.new([])
	assert_true(FleeCalc.can_flee(50, 50, 0, rng), "Vitesse égale : fuite assurée")
	assert_true(FleeCalc.can_flee(80, 50, 0, rng), "plus rapide : fuite assurée")
	assert_eq(rng.calls, 0, "aucun tirage quand la fuite est assurée")


func test_immobile_foe_always_flees() -> void:
	# Vitesse adverse nulle : pas de division, fuite assurée.
	var rng := ScriptedRng.new([])
	assert_true(FleeCalc.can_flee(0, 0, 0, rng))
	assert_eq(rng.calls, 0)


func test_slower_uses_the_formula() -> void:
	# A=25, B=50 → F = ⌊25·128/50⌋ = 64. Réussite si roll(256) − 1 < 64, soit roll ≤ 64.
	var win := ScriptedRng.new([64])
	assert_true(FleeCalc.can_flee(25, 50, 0, win), "roll 64 → 63 < 64 : fuite")
	var lose := ScriptedRng.new([65])
	assert_false(FleeCalc.can_flee(25, 50, 0, lose), "roll 65 → 64 < 64 faux : échec")


func test_failed_attempts_raise_the_odds() -> void:
	# Même A/B, mais C=2 : F = 64 + 30·2 = 124. roll 100 → 99 < 124 : fuite (échouait à C=0).
	var later := ScriptedRng.new([100])
	assert_true(FleeCalc.can_flee(25, 50, 2, later))
	var early := ScriptedRng.new([100])
	assert_false(FleeCalc.can_flee(25, 50, 0, early), "au 1er essai, roll 100 échoue")


func test_high_enough_f_is_guaranteed_without_a_roll() -> void:
	# A=100, B=50 donnerait A≥B ; prenons A=200, B=101 : F = ⌊200·128/101⌋ = 253, + 30·C.
	# À C=1, F = 283 > 255 : fuite assurée sans tirage.
	var rng := ScriptedRng.new([])
	assert_true(FleeCalc.can_flee(200, 101, 1, rng))
	assert_eq(rng.calls, 0, "F > 255 : pas de tirage")
