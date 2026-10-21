extends GutTest
## Bouton rond Vélo du HUD d'exploration (passe systèmes 2, `systemes-2.md` §2.3, T8) : à gauche
## du bouton courir, hors de l'étiquette du bouton contextuel, visible avec la Bicyclette et les contrôles, grisé là où il refuse (le
## toucher reste actif pour dire le refus), miroir en mode gaucher, même échelle que courir.

const HUD_SCENE := "res://game/ui/hud/exploration_hud.tscn"

var _hud: ExplorationHud


func before_each() -> void:
	_hud = (load(HUD_SCENE) as PackedScene).instantiate() as ExplorationHud
	add_child_autofree(_hud)


func test_hidden_until_the_bicycle_is_there() -> void:
	assert_false(_hud.get_bike_button().visible)
	_hud.set_bike_button(true, false)
	assert_true(_hud.get_bike_button().visible)


func test_it_follows_the_controls() -> void:
	_hud.set_bike_button(true, false)
	_hud.set_controls_visible(false)
	assert_false(_hud.get_bike_button().visible, "caché pendant un dialogue")
	_hud.set_controls_visible(true)
	assert_true(_hud.get_bike_button().visible)


func test_dimmed_where_it_refuses_but_still_touchable() -> void:
	_hud.set_bike_button(true, true)
	assert_true(_hud.is_bike_button_dimmed())
	assert_almost_eq(_hud.get_bike_button().modulate.a, UiTokens.BIKE_BUTTON_DIMMED_ALPHA, 0.001)
	watch_signals(_hud)
	_hud.get_bike_button().pressed.emit()
	assert_signal_emitted(_hud, "bike_requested", "le toucher dit le refus")


func test_placed_left_of_the_run_button_and_mirrored_for_left_handers() -> void:
	var run := _hud.get_run_button().position
	var bike := _hud.get_bike_button().position
	assert_eq(bike.y, run.y, "même hauteur que courir")
	assert_lt(bike.x, run.x, "à gauche")
	assert_gt(run.x - bike.x, UiTokens.ROUND_BUTTON, "sans chevauchement")
	_hud.set_left_handed(true)
	assert_eq(_hud.get_bike_button().position,
		Vector2(UiTokens.BIKE_BUTTON_CENTER_FROM_CORNER.x, -UiTokens.BIKE_BUTTON_CENTER_FROM_CORNER.y))


func test_clear_of_the_longest_interact_label() -> void:
	_hud.set_bike_button(true, false)
	_hud.show_interact(&"meet")
	await wait_process_frames(3)
	var tag := _hud.get_interact_button().get_tag().get_global_rect()
	var button := _hud.get_bike_button()
	var radius := UiTokens.ROUND_BUTTON * 0.5 * button.scale.x
	var center := button.get_global_transform_with_canvas().origin
	var circle := Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	assert_gt(tag.size.x, 0.0, "étiquette RENCONTRER posée")
	assert_false(circle.intersects(tag), "le bouton Vélo ne couvre pas l'étiquette (QA S21)")


func test_scaled_with_the_run_button() -> void:
	_hud.set_button_scale(1.2)
	assert_eq(_hud.get_bike_button().scale, _hud.get_run_button().scale)
