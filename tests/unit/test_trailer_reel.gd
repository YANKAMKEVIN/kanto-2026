extends GutTest
## Plans de la bande-annonce de l'ident (J34) : lecture stricte des données, mouvements par défaut
## alternés, durées pour la partition, et la partition qui place les plans entre le carton et les
## lettres en fondu enchaîné.

const IMAGE := "res://assets/ui/opening/splash_pokemake.png"


func _good() -> Dictionary:
	return {
		"letterbox": 0.07,
		"shots": [
			{"image": IMAGE, "seconds": 2.0},
			{"image": IMAGE, "seconds": 3.0, "zoom": [1.0, 1.2], "pan": [0.0, 0.0, 0.05, -0.02]},
			{"image": IMAGE},
		],
	}


func test_valid_reel_keeps_shots_and_defaults() -> void:
	var reel := TrailerReel.new()
	assert_true(reel.add_from_dict(_good(), "test"), str(reel.get_errors()))
	assert_eq(reel.shots.size(), 3)
	assert_eq(reel.durations(), [2.0, 3.0, TrailerReel.DEFAULT_SECONDS] as Array[float])
	assert_eq(reel.shots[1]["zoom"], [1.0, 1.2] as Array[float])
	assert_eq(reel.shots[1]["pan"], [0.0, 0.0, 0.05, -0.02] as Array[float])
	assert_eq(reel.shots[0]["zoom"], TrailerReel.DEFAULT_ZOOM_IN, "plan pair : poussée")
	assert_eq(reel.shots[2]["zoom"], TrailerReel.DEFAULT_ZOOM_IN)
	assert_almost_eq(reel.letterbox, 0.07, 0.0001)
	assert_almost_eq(reel.total(0.7), 2.0 + 3.0 + TrailerReel.DEFAULT_SECONDS - 1.4, 0.001)


func test_default_motion_alternates_push_and_pull() -> void:
	assert_eq(TrailerReel.default_motion(0)["zoom"], TrailerReel.DEFAULT_ZOOM_IN)
	assert_eq(TrailerReel.default_motion(1)["zoom"], TrailerReel.DEFAULT_ZOOM_OUT)
	assert_eq(TrailerReel.default_motion(2)["zoom"], TrailerReel.DEFAULT_ZOOM_IN)
	var pan0: Array[float] = TrailerReel.default_motion(0)["pan"]
	var pan2: Array[float] = TrailerReel.default_motion(2)["pan"]
	assert_ne(pan0[2], pan2[2], "glissement alterné")


func test_strict_reading_refuses_bad_shots_all_or_nothing() -> void:
	var cases := {
		"image absente": {"shots": [{"seconds": 2.0}]},
		"image introuvable": {"shots": [{"image": "res://nope.webp"}]},
		"durée hors bornes": {"shots": [{"image": IMAGE, "seconds": 9.0}]},
		"zoom hors bornes": {"shots": [{"image": IMAGE, "zoom": [0.5, 1.0]}]},
		"pan mal formé": {"shots": [{"image": IMAGE, "pan": [0.0, 0.0]}]},
		"clé inconnue": {"shots": [{"image": IMAGE, "duration": 2.0}]},
		"letterbox trop grand": {"letterbox": 0.5, "shots": [{"image": IMAGE}]},
		"shots manquant": {"letterbox": 0.07},
	}
	for label: String in cases:
		var reel := TrailerReel.new()
		assert_false(reel.add_from_dict(cases[label], label), label)
		assert_eq(reel.shots.size(), 0, label + " : aucun plan gardé")
		assert_false(reel.get_errors().is_empty(), label + " : erreur signalée")


func test_missing_file_means_no_reel() -> void:
	var reel := TrailerReel.new()
	assert_false(reel.load_file("res://data/opening/absent_trailer.json"))
	assert_eq(reel.shots.size(), 0)


func test_the_shipped_reel_if_present_is_valid_and_lasts_15_to_20_seconds() -> void:
	var reel := TrailerReel.new()
	if not FileAccess.file_exists(TrailerReel.DEFAULT_PATH):
		pass_test("pas encore de bande-annonce livrée")
		return
	assert_true(reel.load_file(), str(reel.get_errors()))
	assert_between(reel.total(IntroTimeline.FULL["xfade"]), 15.0, 20.0, "15 à 20 s (demande de Kevin)")
	assert_gte(reel.shots.size(), 6)


func test_timeline_places_shots_between_card_and_letters_with_crossfades() -> void:
	var cues := IntroTimeline.build(8, false, [2.0, 3.0, 2.5] as Array[float])
	var card_out := IntroTimeline.find(cues, IntroTimeline.CARD_OUT)
	var s0 := IntroTimeline.find(cues, IntroTimeline.SHOT, 0)
	var s1 := IntroTimeline.find(cues, IntroTimeline.SHOT, 1)
	var s2 := IntroTimeline.find(cues, IntroTimeline.SHOT, 2)
	var xfade: float = IntroTimeline.FULL["xfade"]
	assert_gte(s0["start"], card_out["start"] + card_out["duration"], "après le carton")
	assert_almost_eq(s1["start"], s0["start"] + 2.0 - xfade, 0.001, "fondu enchaîné")
	assert_almost_eq(s2["start"], s1["start"] + 3.0 - xfade, 0.001)
	var reel_out := IntroTimeline.find(cues, IntroTimeline.REEL_OUT)
	assert_almost_eq(reel_out["start"] + reel_out["duration"], s2["start"] + 2.5, 0.001, "le dernier plan s'éteint sur sa fin")
	var first_letter := IntroTimeline.find(cues, IntroTimeline.LETTER, 0)
	assert_gte(first_letter["start"], reel_out["start"] + reel_out["duration"] + IntroTimeline.FULL["gap"] - 0.001, "noir avant les lettres")
	assert_true(IntroTimeline.find(IntroTimeline.build(8), IntroTimeline.SHOT, 0).is_empty(), "sans plans : partition d'avant")
	assert_true(IntroTimeline.find(IntroTimeline.build(8, true, [2.0] as Array[float]), IntroTimeline.SHOT, 0).is_empty(), "réduite : pas de bande-annonce")
