extends GutTest
## Entrée des combats de Dresseur (dossier 05 §3, décision de Kevin du 2026-11-02) : durées en
## temps simulé ([TweenClock]) de la séquence « VS » ([VsBanner]) et de l'entrée du niveau 1
## ([TrainerIntroStage]) ; **jamais sautée** : un toucher pendant la séquence ne l'abrège pas ;
## « Réduire les animations » : fondus sur place (aucun glissé), même durée.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const STEP := TweenClock.STEP

var _catalog: TrainerIntroCatalog
var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir("res://tests/fixtures/pokemon/valid/")


func before_each() -> void:
	_catalog = TrainerIntroCatalog.new()
	_catalog.load_file()


func _intro(grand: bool, reduce_motion: bool = false) -> TrainerIntro:
	var trainer := TrainerData.new()
	trainer.name = "Gamin Hugo"
	if grand:
		trainer.name = "Pierre"
		trainer.card_name = "PIERRE"
		trainer.card_title = "Champion d'Arène d'Argenta"
		trainer.card_portrait = &"pierre"
	var party := Party.new()
	party.add(PokemonFactory.create(_data, &"sprout", 5, GameRng.new(1)))
	return TrainerIntro.build(trainer, party, _catalog, &"rival", reduce_motion)


func _touch() -> void:
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(960, 540)
	Input.parse_input_event(touch)
	var release := InputEventScreenTouch.new()
	release.position = touch.position
	Input.parse_input_event(release)


func _vs_steps(intro: TrainerIntro, touch_at: int, check: Callable = Callable()) -> int:
	var banner := VsBanner.new()
	add_child_autofree(banner)
	var clock := TweenClock.new(get_tree())
	banner.play(intro, "PIERRE", "Champion", null, "KEVIN", null)
	var steps := 0
	while banner.is_playing() and steps < 600:
		if steps == touch_at:
			_touch()
		if check.is_valid():
			check.call(banner, steps)
		clock.step()
		steps += 1
	clock.release()
	return steps


func _vs_total(intro: TrainerIntro) -> float:
	return intro.duration(TrainerIntro.Step.VS_IN) + intro.duration(TrainerIntro.Step.VS_HOLD) \
		+ intro.duration(TrainerIntro.Step.VS_OUT)


func test_vs_sequence_lasts_its_full_duration() -> void:
	var intro := _intro(true)
	var steps := _vs_steps(intro, -1)
	assert_gte(steps * STEP, _vs_total(intro) - STEP, "pas finie avant sa durée")
	assert_lte(steps * STEP, _vs_total(intro) + 3 * STEP, "au plus un pas par enchaînement")


func test_touch_does_not_skip_the_vs_sequence() -> void:
	var intro := _intro(true)
	var touch_at := int(intro.duration(TrainerIntro.Step.VS_IN) / STEP) + 5
	var steps := _vs_steps(intro, touch_at)
	assert_gte(steps * STEP, _vs_total(intro) - STEP, "le toucher n'abrège rien")


func test_vs_banners_slide_in_from_their_side_and_go_back() -> void:
	var intro := _intro(true)
	var width := get_viewport().get_visible_rect().size.x
	var seen := {"top_right": false, "top_left": false, "bottom_left": false,
		"bottom_right": false}
	_vs_steps(intro, -1, func(banner: VsBanner, _steps: int) -> void:
		var top := banner.get_foe_banner().position.x
		var bottom := banner.get_player_banner().position.x
		if top > width * 0.2:
			seen["top_right"] = true
		if top < -width * 0.2:
			seen["top_left"] = true
		if bottom < -width * 0.2:
			seen["bottom_left"] = true
		if bottom > width * 0.2:
			seen["bottom_right"] = true)
	assert_eq(seen, {"top_right": true, "top_left": false, "bottom_left": true,
		"bottom_right": false}, "rouge : de la droite (et y repart) ; bleue : de la gauche")


func test_reduce_motion_fades_in_place() -> void:
	var intro := _intro(true, true)
	var moved := [false]
	var steps := _vs_steps(intro, -1, func(banner: VsBanner, _steps: int) -> void:
		if banner.get_foe_banner().position.x != 0.0 \
				or banner.get_player_banner().position.x != 0.0:
			moved[0] = true)
	assert_false(moved[0], "aucun glissé")
	assert_gte(steps * STEP, _vs_total(intro) - STEP, "séquence visible, même durée")


func test_vs_shows_names_and_portraits() -> void:
	var banner := VsBanner.new()
	add_child_autofree(banner)
	banner.speed_scale = 0.0
	var portrait := TrainerIntroStage.silhouette()
	await banner.play(_intro(true), "PIERRE", "Champion d'Arène d'Argenta", portrait, "KEVIN",
		null)
	assert_eq([banner.get_foe_name_text(), banner.get_foe_title_text(),
		banner.get_player_name_text()], ["Pierre", "Champion d'Arène d'Argenta", "Kevin"],
		"initiales en capitales, le reste en petites capitales de Cinzel (maquette 3)")
	assert_eq(banner.get_foe_portrait(), portrait)
	assert_false(banner.visible, "cachée à la fin")


func test_level_one_entry_lasts_its_duration_and_ignores_touch() -> void:
	var intro := _intro(false)
	var view := TrainerIntroStage.new()
	add_child_autofree(view)
	view.begin(intro, Vector2(1920, 1080), TrainerIntroStage.silhouette(),
		TrainerIntroStage.silhouette())
	var landed: Array[int] = []
	var done := [false]
	var clock := TweenClock.new(get_tree())
	var runner := func() -> void:
		await view.play_enter()
		await view.play_send(BattleEvent.SideId.FOE, func() -> void: landed.append(0))
		await view.play_send(BattleEvent.SideId.PLAYER, func() -> void: landed.append(1))
		done[0] = true
	runner.call()
	var steps := 0
	var trainers_seen := false
	while not done[0] and steps < 600:
		if steps == 20:
			_touch()
		if view.is_trainer_visible(BattleEvent.SideId.FOE) \
				and view.is_trainer_visible(BattleEvent.SideId.PLAYER):
			trainers_seen = true
		clock.step()
		steps += 1
		await get_tree().process_frame
	clock.release()
	assert_true(trainers_seen, "les deux dresseurs à l'écran ensemble")
	assert_eq(landed, [0, 1] as Array[int], "l'adversaire lance, puis le joueur")
	assert_gte(steps * STEP, intro.entry_total() - STEP, "jamais abrégée (toucher compris)")
	assert_lte(steps * STEP, intro.entry_total() + 8 * STEP)
	assert_false(view.is_trainer_visible(BattleEvent.SideId.FOE), "l'adversaire s'est effacé")
	assert_false(view.is_trainer_visible(BattleEvent.SideId.PLAYER), "le joueur s'est effacé")


## Maquettes validées : dresseurs ancrés au sol (ombre sous les pieds), joueur grand au premier
## plan en bas à gauche, adversaire plus loin à droite, cartouche des Balls au-dessus de lui.
func test_layout_follows_the_mockups() -> void:
	var intro := _intro(false)
	var view := TrainerIntroStage.new()
	add_child_autofree(view)
	var size := Vector2(2340, 1080)
	view.begin(intro, size, TrainerIntroStage.silhouette(), TrainerIntroStage.silhouette())
	view.speed_scale = 0.0
	await view.play_enter()
	var foe := BattleEvent.SideId.FOE
	var mine := BattleEvent.SideId.PLAYER
	var player_feet := view.get_feet(mine)
	var foe_feet := view.get_feet(foe)
	assert_lt(player_feet.x, size.x * 0.5, "joueur à gauche")
	assert_gt(foe_feet.x, size.x * 0.5, "adversaire à droite")
	assert_gt(player_feet.y, foe_feet.y, "joueur au premier plan (plus bas)")
	var player_h := view.get_trainer(mine).texture.get_height() * view.get_trainer(mine).scale.y
	var foe_h := view.get_trainer(foe).texture.get_height() * view.get_trainer(foe).scale.y
	assert_gt(player_h, foe_h * 1.5, "joueur nettement plus grand")
	for side: BattleEvent.SideId in [foe, mine]:
		assert_true(view.get_shadow(side).visible, "ombre au sol")
		assert_eq(view.get_shadow(side).position, view.get_feet(side), "sous les pieds")
	var cartouche := view.get_cartouche()
	assert_true(cartouche.visible, "cartouche des Balls")
	assert_lt(cartouche.position.y, foe_feet.y - foe_h, "au-dessus de la tête de l'adversaire")
	assert_gt(cartouche.position.x, size.x * 0.5, "rattaché à l'adversaire, pas en haut à gauche")


func test_front_texture_fallback_chain() -> void:
	var intro := _intro(false)
	var none := func(_path: String) -> bool: return false
	var texture := TrainerIntroStage.foe_texture(intro, none)
	assert_not_null(texture)
	assert_eq(texture.get_size(), TrainerIntroStage.world_texture(&"youngster").get_size(),
		"sans image peinte : apparence du monde")
	var trainer := TrainerData.new()
	trainer.name = "Inconnu"
	var unknown := TrainerIntro.build(trainer, Party.new(), _catalog)
	assert_eq(TrainerIntroStage.foe_texture(unknown, none).get_size(),
		Vector2(TrainerIntroStage.SILHOUETTE_SIZE), "aucune classe : silhouette")


## Le lancer : la Ball reste ronde (même échelle sur les deux axes), passe par le point de
## l'arc des données, et la traînée part de la main.
func test_ball_flies_round_through_the_arc() -> void:
	var intro := _intro(false)
	var view := TrainerIntroStage.new()
	add_child_autofree(view)
	var size := Vector2(2340, 1080)
	view.begin(intro, size, TrainerIntroStage.silhouette(), TrainerIntroStage.silhouette())
	view.speed_scale = 0.0
	await view.play_enter()
	var ball := view.get_node(^"ThrownBall") as Sprite2D
	var trail := view.get_node(^"Trail") as Line2D
	var via := _catalog.point("foe_via") * size
	var closest := [INF]
	var round_ball := [true]
	var trail_from_hand := [true]
	var clock := TweenClock.new(get_tree())
	view.speed_scale = 1.0
	var done := [false]
	var runner := func() -> void:
		await view.play_send(BattleEvent.SideId.FOE, Callable())
		done[0] = true
	runner.call()
	var steps := 0
	while not done[0] and steps < 300:
		clock.step()
		steps += 1
		if ball.visible:
			closest[0] = minf(closest[0], ball.position.distance_to(via))
			round_ball[0] = round_ball[0] and is_equal_approx(ball.scale.x, ball.scale.y)
			if trail.get_point_count() > 1:
				var hand := trail.get_point_position(0)
				trail_from_hand[0] = trail_from_hand[0] and hand.distance_to(
					trail.get_point_position(0)) < 0.5
		await get_tree().process_frame
	clock.release()
	assert_true(done[0])
	assert_lt(closest[0], 0.03 * size.x, "l'arc passe près de (56 %, 28 %)")
	assert_true(round_ball[0], "Ball ronde")
	var width := TrainerIntroStage.visible_width(ball.texture)
	assert_almost_eq(ball.scale.x * width, 0.024 * size.x, 0.5, "diamètre 2,4 % de la largeur")


## Hauteur visible mesurée sur la boîte alpha (art peint posé sur une toile) : la hauteur
## affichée d'un personnage ne dépend pas du remplissage de sa toile.
func test_visible_height_ignores_the_empty_canvas() -> void:
	var gamin := load("res://assets/sprites/trainers/battle/gamin.webp") as Texture2D
	var pierre := load("res://assets/sprites/trainers/battle/pierre.webp") as Texture2D
	assert_almost_eq(TrainerIntroStage.visible_height(gamin), 768.0 - 16.0, 2.0)
	assert_almost_eq(TrainerIntroStage.visible_height(pierre), 768.0 - 16.0, 2.0)


## Itération 4 : le joueur entre bras tendu (pose de lancer), passe en garde (pose debout) au
## lancer de l'adversaire, lance avec la pose de lancer ; images choisies par les données.
func test_player_image_follows_the_phase() -> void:
	var intro := _intro(false)
	var view := TrainerIntroStage.new()
	add_child_autofree(view)
	var stand := TrainerIntroStage.silhouette()
	var throw := ImageTexture.create_from_image(Image.create(32, 96, false, Image.FORMAT_RGBA8))
	view.begin(intro, Vector2(2340, 1080), TrainerIntroStage.silhouette(), stand, null, throw)
	view.speed_scale = 0.0
	var mine := view.get_trainer(BattleEvent.SideId.PLAYER)
	assert_eq(mine.texture, throw, "entrée : bras tendu (maquette 1)")
	await view.play_enter()
	var seen: Array[Texture2D] = []
	var frames := [1.0]
	view.framing_changed.connect(func(zoom: float, _from: Vector2, _to: Vector2) -> void:
		frames[0] = maxf(frames[0], zoom))
	view.step_started.connect(func(_step: TrainerIntro.Step) -> void: seen.append(mine.texture))
	await view.play_send(BattleEvent.SideId.FOE, Callable())
	assert_eq(mine.texture, stand, "garde pendant le lancer de l'adversaire (maquette 2)")
	assert_almost_eq(frames[0], _catalog.framing_zoom, 0.001, "le décor est recadré au lancer")
	assert_eq(view.get_framing(), 0.0, "puis revient au cadrage du combat")
	assert_eq(view.get_feet(BattleEvent.SideId.PLAYER),
		(Vector2(_catalog.pose("throw", "player").x, _catalog.pose("throw", "player").y)
			* Vector2(2340, 1080)).round(), "joueur au premier plan du lancer")
	await view.play_send(BattleEvent.SideId.PLAYER, Callable())
	assert_eq(mine.texture, throw, "il lance avec la pose de lancer")


## Rangée : Balls actives pleines, emplacements vides sombres à liseré clair (texture à part).
func test_empty_slots_are_light_grey_balls() -> void:
	var intro := _intro(false)
	var view := TrainerIntroStage.new()
	add_child_autofree(view)
	view.begin(intro, Vector2(2340, 1080), TrainerIntroStage.silhouette(),
		TrainerIntroStage.silhouette())
	var row := view.get_ball_row()
	assert_eq(row[0].texture, BattleStage.BALL_TEXTURE)
	assert_eq(row[0].modulate.a, 1.0, "active : opacité pleine")
	assert_eq(row[5].texture, TrainerIntroStage.empty_slot(), "vide : disque sombre à liseré")
	assert_ne(row[5].texture, row[0].texture, "nettement distinct d'une Ball active")


## Itération 5 : pendant le « VS », le joueur prend sa pose dédiée (repli : l'image de l'entrée).
func test_player_vs_pose_with_fallback() -> void:
	var intro := _intro(true)
	var stand := TrainerIntroStage.silhouette()
	var throw := ImageTexture.create_from_image(Image.create(32, 96, false, Image.FORMAT_RGBA8))
	var pose := ImageTexture.create_from_image(Image.create(40, 96, false, Image.FORMAT_RGBA8))
	for vs: Texture2D in [pose, null]:
		var view := TrainerIntroStage.new()
		add_child_autofree(view)
		view.begin(intro, Vector2(2340, 1080), TrainerIntroStage.silhouette(), stand, null, throw,
			vs)
		view.speed_scale = 0.0
		await view.play_enter()
		await view.move_to_pose(&"vs", 0.3)
		var mine := view.get_trainer(BattleEvent.SideId.PLAYER)
		assert_eq(mine.texture, pose if vs != null else throw,
			"pose du « VS », sinon celle de l'entrée")
