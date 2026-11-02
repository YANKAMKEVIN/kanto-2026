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


func test_vs_banners_slide_then_part() -> void:
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
	assert_eq(seen, {"top_right": true, "top_left": true, "bottom_left": true,
		"bottom_right": true}, "rouge : arrive de droite, part à gauche ; bleue : l'inverse")


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
	await banner.play(_intro(true), "Pierre", "Champion d'Arène d'Argenta", portrait, "Kevin",
		null)
	assert_eq([banner.get_foe_name_text(), banner.get_foe_title_text(),
		banner.get_player_name_text()], ["PIERRE", "Champion d'Arène d'Argenta", "KEVIN"])
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
		await view.play_send(BattleEvent.SideId.FOE, Vector2(1400, 500),
			func() -> void: landed.append(0))
		await view.play_send(BattleEvent.SideId.PLAYER, Vector2(500, 800),
			func() -> void: landed.append(1))
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
