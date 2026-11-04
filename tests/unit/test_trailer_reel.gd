extends GutTest
## Bande-annonce de l'ident (J34, v2 en vidéo) : lecture stricte des données (vidéo Theora
## existante, durée bornée, bandes noires), tout ou rien ; la partition place la vidéo entre le
## carton et les lettres ; la bande-annonce livrée, si elle existe, dure 30 à 40 s (Kevin).

const VIDEO := "res://assets/ui/opening/trailer.ogv"


func _shipped() -> bool:
	return ResourceLoader.exists(VIDEO)


func test_valid_reel_keeps_video_seconds_and_letterbox() -> void:
	if not _shipped():
		pass_test("pas encore de vidéo livrée")
		return
	var reel := TrailerReel.new()
	assert_true(reel.add_from_dict({"video": VIDEO, "seconds": 37.5, "letterbox": 0.05}, "test"),
		str(reel.get_errors()))
	assert_true(reel.has_video())
	assert_eq(reel.video, VIDEO)
	assert_eq(reel.durations(), [37.5] as Array[float], "un seul plan : la vidéo")
	assert_almost_eq(reel.total(0.7), 37.5, 0.001, "aucun fondu enchaîné à déduire")
	assert_almost_eq(reel.letterbox, 0.05, 0.0001)


func test_letterbox_defaults_to_cinema_bars() -> void:
	if not _shipped():
		pass_test("pas encore de vidéo livrée")
		return
	var reel := TrailerReel.new()
	assert_true(reel.add_from_dict({"video": VIDEO, "seconds": 30.0}, "test"))
	assert_almost_eq(reel.letterbox, TrailerReel.DEFAULT_LETTERBOX, 0.0001)


func test_strict_reading_refuses_bad_data_all_or_nothing() -> void:
	var cases := {
		"vidéo absente": {"seconds": 30.0},
		"vidéo introuvable": {"video": "res://nope.ogv", "seconds": 30.0},
		"pas du Theora": {"video": "res://assets/ui/opening/splash_pokemake.png", "seconds": 30.0},
		"durée manquante": {"video": VIDEO},
		"durée trop courte": {"video": VIDEO, "seconds": 1.0},
		"durée trop longue": {"video": VIDEO, "seconds": 90.0},
		"letterbox trop grand": {"video": VIDEO, "seconds": 30.0, "letterbox": 0.5},
		"clé inconnue": {"video": VIDEO, "seconds": 30.0, "shots": []},
	}
	for label: String in cases:
		var reel := TrailerReel.new()
		assert_false(reel.add_from_dict(cases[label], label), label)
		assert_false(reel.has_video(), label + " : aucune vidéo gardée")
		assert_eq(reel.durations().size(), 0, label + " : aucun plan")
		assert_false(reel.get_errors().is_empty(), label + " : erreur signalée")


func test_missing_file_means_no_reel() -> void:
	var reel := TrailerReel.new()
	assert_false(reel.load_file("res://data/opening/absent_trailer.json"))
	assert_false(reel.has_video())
	assert_almost_eq(reel.total(), 0.0, 0.001)


func test_the_shipped_reel_if_present_is_valid_and_lasts_30_to_40_seconds() -> void:
	var reel := TrailerReel.new()
	if not FileAccess.file_exists(TrailerReel.DEFAULT_PATH):
		pass_test("pas encore de bande-annonce livrée")
		return
	assert_true(reel.load_file(), str(reel.get_errors()))
	assert_true(reel.has_video())
	assert_between(reel.total(), 30.0, 40.0, "30 à 40 s (demande de Kevin du 2026-11-03)")


func test_timeline_places_the_video_between_card_and_letters() -> void:
	var cues := IntroTimeline.build(8, false, [37.5] as Array[float])
	var card_out := IntroTimeline.find(cues, IntroTimeline.CARD_OUT)
	var video := IntroTimeline.find(cues, IntroTimeline.SHOT, 0)
	assert_false(video.is_empty())
	assert_gte(video["start"], card_out["start"] + card_out["duration"], "après le carton")
	assert_almost_eq(video["duration"], 37.5, 0.001)
	var reel_out := IntroTimeline.find(cues, IntroTimeline.REEL_OUT)
	assert_almost_eq(reel_out["start"] + reel_out["duration"], video["start"] + 37.5, 0.001,
		"la vidéo s'éteint sur sa fin")
	var first_letter := IntroTimeline.find(cues, IntroTimeline.LETTER, 0)
	assert_gte(first_letter["start"], reel_out["start"] + reel_out["duration"] + IntroTimeline.FULL["gap"] - 0.001,
		"noir avant les lettres")
	assert_true(IntroTimeline.find(IntroTimeline.build(8), IntroTimeline.SHOT, 0).is_empty(), "sans vidéo : partition d'avant")
	assert_true(IntroTimeline.find(IntroTimeline.build(8, true, [37.5] as Array[float]), IntroTimeline.SHOT, 0).is_empty(), "réduite : pas de bande-annonce")
