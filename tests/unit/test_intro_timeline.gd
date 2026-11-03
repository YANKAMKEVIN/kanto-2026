extends GutTest
## Partition de l'ident de démarrage (J34) : ordre des repères, lettres décalées depuis la droite,
## filet puis halo après la dernière lettre, version réduite sans lettres, point d'arrivée du passage.


func test_full_order_card_then_letters_then_rule_glow_fade() -> void:
	var cues := IntroTimeline.build(8)
	var ids: Array[StringName] = []
	for cue: Dictionary in cues:
		ids.append(cue["id"])
	assert_eq(ids[0], IntroTimeline.CARD_IN)
	assert_eq(ids[1], IntroTimeline.CARD_OUT)
	assert_eq(ids.slice(2, 10), [IntroTimeline.LETTER, IntroTimeline.LETTER, IntroTimeline.LETTER,
		IntroTimeline.LETTER, IntroTimeline.LETTER, IntroTimeline.LETTER, IntroTimeline.LETTER,
		IntroTimeline.LETTER] as Array[StringName])
	assert_eq(ids.slice(10), [IntroTimeline.RULE, IntroTimeline.GLOW, IntroTimeline.FADE_OUT] as Array[StringName])


func test_card_leaves_before_the_first_letter_enters() -> void:
	var cues := IntroTimeline.build(8)
	var card_out := IntroTimeline.find(cues, IntroTimeline.CARD_OUT)
	var first := IntroTimeline.find(cues, IntroTimeline.LETTER, 0)
	assert_gt(card_out["start"], IntroTimeline.find(cues, IntroTimeline.CARD_IN)["duration"], "le carton tient")
	assert_gte(first["start"], card_out["start"] + card_out["duration"], "noir entre le carton et les lettres")


func test_letters_enter_one_by_one_in_reading_order() -> void:
	var cues := IntroTimeline.build(8)
	var previous: float = -1.0
	for i: int in 8:
		var letter := IntroTimeline.find(cues, IntroTimeline.LETTER, i)
		assert_false(letter.is_empty(), "lettre %d" % i)
		assert_gt(letter["start"], previous, "la lettre %d part après la précédente" % i)
		assert_almost_eq(letter["duration"], IntroTimeline.FULL["letter_travel"], 0.001)
		previous = letter["start"]
	var last := IntroTimeline.find(cues, IntroTimeline.LETTER, 7)
	var rule := IntroTimeline.find(cues, IntroTimeline.RULE)
	assert_almost_eq(rule["start"], last["start"] + last["duration"], 0.001, "le filet part quand la dernière lettre est posée")
	var glow := IntroTimeline.find(cues, IntroTimeline.GLOW)
	assert_almost_eq(glow["start"], rule["start"] + rule["duration"], 0.001)


func test_fade_out_is_last_and_total_is_about_seven_seconds() -> void:
	var cues := IntroTimeline.build(8)
	var fade := IntroTimeline.find(cues, IntroTimeline.FADE_OUT)
	assert_almost_eq(IntroTimeline.total(cues), fade["start"] + fade["duration"], 0.001)
	assert_between(IntroTimeline.total(cues), 6.0, 8.0)
	assert_almost_eq(IntroTimeline.logo_formed_at(cues),
		IntroTimeline.find(cues, IntroTimeline.GLOW)["start"] + IntroTimeline.FULL["glow"], 0.001)
	assert_almost_eq(fade["start"], IntroTimeline.logo_formed_at(cues) + IntroTimeline.FULL["hold"], 0.001)


func test_reduced_motion_has_no_moving_letters_and_is_shorter() -> void:
	var reduced := IntroTimeline.build(8, true)
	assert_true(IntroTimeline.find(reduced, IntroTimeline.LETTER, 0).is_empty())
	assert_true(IntroTimeline.find(reduced, IntroTimeline.RULE).is_empty())
	assert_false(IntroTimeline.find(reduced, IntroTimeline.LOGO_IN).is_empty())
	assert_lt(IntroTimeline.total(reduced), IntroTimeline.total(IntroTimeline.build(8)) / 2.0)
	assert_almost_eq(IntroTimeline.logo_formed_at(reduced),
		IntroTimeline.find(reduced, IntroTimeline.LOGO_IN)["start"] + IntroTimeline.REDUCED["logo_in"], 0.001)


func test_letter_count_drives_the_length() -> void:
	assert_gt(IntroTimeline.total(IntroTimeline.build(8)), IntroTimeline.total(IntroTimeline.build(5)))
	assert_true(IntroTimeline.find(IntroTimeline.build(1), IntroTimeline.LETTER, 1).is_empty())
