extends GutTest
## Ident de démarrage (J34) : huit lettres découpées dans le logo, parties hors écran à droite puis
## posées à leur place ; carton puis logo ; passage sur un toucher ; speed_scale 0 = instantané ;
## le logo formé a la largeur du splash et sa hauteur.

const WIDTH := 2340
const HEIGHT := 1080
## Images attendues au plus (les tweens tournent en vitesse × 50 : quelques images suffisent).
const MAX_FRAMES := 600


const VIDEO := "res://assets/ui/opening/trailer.ogv"
const VIDEO_SECONDS := 30.0


## Bande-annonce de test (null sans vidéo livrée : les tests qui en dépendent passent à vide).
func _reel() -> TrailerReel:
	if not ResourceLoader.exists(VIDEO):
		return null
	var reel := TrailerReel.new()
	assert_true(reel.add_from_dict({"letterbox": 0.07, "video": VIDEO, "seconds": VIDEO_SECONDS}, "test"),
		str(reel.get_errors()))
	return reel


func _ident(speed: float, reduced: bool = false, reel: TrailerReel = null) -> IdentSequence:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(WIDTH, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var ident := IdentSequence.new()
	ident.speed_scale = speed
	ident.reduced = reduced
	ident.set_texts("Les studios Kevin & Co", "vous présentent")
	if reel != null:
		ident.set_reel(reel)
	viewport.add_child(ident)
	await wait_process_frames(2)
	return ident


func test_eight_letters_and_a_rule_cut_from_the_logo_start_offscreen_right() -> void:
	var ident := await _ident(1.0)
	assert_eq(ident.get_letters().size(), 8, "P, O, K, E, M, A, K, E")
	assert_not_null(ident.get_rule())
	var root_width: float = ident.get_root().size.x
	for i: int in 8:
		var letter := ident.get_letters()[i]
		assert_gt(letter.global_position.x, root_width, "lettre %d hors écran à droite" % i)
		if i > 0:
			assert_gt(ident.letter_target_x(i), ident.letter_target_x(i - 1), "ordre de lecture")
	assert_almost_eq(ident.get_full_logo().size.x, float(UiTokens.IDENT_LOGO_WIDTH), 0.5)
	assert_eq(ident.get_full_logo().modulate.a, 0.0, "le vrai logo attend le halo")
	assert_eq(ident.get_card().modulate.a, 1.0, "le carton prolonge l'image de démarrage")
	assert_eq(ident.get_card().get_child(0).text, "Les studios Kevin & Co")


func test_played_fast_the_card_shows_then_the_letters_land_and_it_finishes() -> void:
	var ident := await _ident(0.02)
	var finished: Array[bool] = []
	ident.finished.connect(func() -> void: finished.append(true))
	ident.play()
	assert_true(ident.is_playing())
	for _i: int in MAX_FRAMES:
		if not finished.is_empty():
			break
		await wait_process_frames(1)
	assert_eq(finished.size(), 1, "finished émis une fois")
	assert_true(ident.is_done())
	for i: int in 8:
		assert_almost_eq(ident.get_letters()[i].position.x, ident.letter_target_x(i), 0.5, "lettre %d posée" % i)
	assert_almost_eq(ident.get_full_logo().modulate.a, 1.0, 0.001, "logo allumé")
	assert_almost_eq(ident.get_rule().scale.x, 1.0, 0.001, "filet tracé")
	assert_almost_eq(ident.get_root().modulate.a, 0.0, 0.001, "fondu de sortie fini")


func test_a_touch_skips_to_the_formed_logo_then_finishes() -> void:
	var ident := await _ident(1.0)
	var finished: Array[bool] = []
	ident.finished.connect(func() -> void: finished.append(true))
	ident.play()
	await wait_process_frames(3)
	assert_true(finished.is_empty(), "l'ident dure plusieurs secondes")
	ident.speed_scale = 0.01
	ident.skip()
	for i: int in 8:
		assert_almost_eq(ident.get_letters()[i].position.x, ident.letter_target_x(i), 0.5)
	assert_almost_eq(ident.get_full_logo().modulate.a, 1.0, 0.001)
	for _i: int in MAX_FRAMES:
		if not finished.is_empty():
			break
		await wait_process_frames(1)
	assert_eq(finished.size(), 1)


func test_speed_zero_finishes_at_once_without_animating() -> void:
	var ident := await _ident(0.0)
	var finished: Array[bool] = []
	ident.finished.connect(func() -> void: finished.append(true))
	ident.play()
	await wait_process_frames(2)
	assert_eq(finished.size(), 1)


func test_reduced_motion_fades_the_whole_logo_without_moving_letters() -> void:
	var ident := await _ident(0.02, true)
	ident.play()
	assert_almost_eq(ident.total_duration(), IntroTimeline.total(IntroTimeline.build(8, true)), 0.001)
	for _i: int in MAX_FRAMES:
		if ident.is_done():
			break
		await wait_process_frames(1)
	assert_true(ident.is_done())
	assert_almost_eq(ident.get_full_logo().modulate.a, 1.0, 0.001)
	assert_gt(ident.get_letters()[0].position.x, ident.letter_target_x(0), "les lettres n'ont pas bougé")


func test_the_reel_plays_its_video_between_the_card_and_the_letters() -> void:
	var reel := _reel()
	if reel == null:
		pass_test("pas encore de vidéo livrée")
		return
	var ident := await _ident(0.02, false, reel)
	var player := ident.get_video_player()
	assert_not_null(player, "un lecteur vidéo")
	assert_eq(ident.get_reel_root().modulate.a, 0.0, "bande-annonce éteinte avant le carton")
	assert_eq(player.size, Vector2(WIDTH, HEIGHT), "la vidéo couvre l'écran")
	assert_true(player.expand)
	assert_false(player.is_playing(), "elle attend son repère")
	assert_eq(player.bus, IdentSequence.VIDEO_BUS, "le son suit le curseur Musique")
	ident.play()
	assert_almost_eq(ident.total_duration(),
		IntroTimeline.total(IntroTimeline.build(8, false, [VIDEO_SECONDS] as Array[float])), 0.001)
	assert_gt(ident.total_duration(), IntroTimeline.total(IntroTimeline.build(8)) + VIDEO_SECONDS - 1.0,
		"plus long avec la bande-annonce")
	var played := false
	for _i: int in MAX_FRAMES:
		if ident.is_done():
			break
		played = played or player.is_playing()
		await wait_process_frames(1)
	assert_true(ident.is_done())
	assert_true(played, "la vidéo a été lancée")
	assert_false(player.is_playing(), "arrêtée avec l'ident")
	assert_almost_eq(ident.get_reel_root().modulate.a, 0.0, 0.001, "bande-annonce éteinte avant le logo")


func test_a_skip_stops_the_video() -> void:
	var reel := _reel()
	if reel == null:
		pass_test("pas encore de vidéo livrée")
		return
	var ident := await _ident(1.0, false, reel)
	ident.play()
	ident.get_video_player().play()
	await wait_process_frames(2)
	ident.speed_scale = 0.01
	ident.skip()
	assert_false(ident.get_video_player().is_playing(), "le passage coupe la vidéo")
	for _i: int in MAX_FRAMES:
		if ident.is_done():
			break
		await wait_process_frames(1)
	assert_true(ident.is_done())


func test_reduced_motion_skips_the_reel() -> void:
	var reel := _reel()
	if reel == null:
		pass_test("pas encore de vidéo livrée")
		return
	var ident := await _ident(0.02, true, reel)
	ident.play()
	assert_almost_eq(ident.total_duration(), IntroTimeline.total(IntroTimeline.build(8, true)), 0.001)
