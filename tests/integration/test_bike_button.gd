extends GutTest
## Bouton rond Vélo du HUD d'exploration (passe systèmes 2, `systemes-2.md` §2.3, T8) : au-dessus
## du bouton courir, visible avec la Bicyclette et les contrôles, grisé là où il refuse (le
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


func test_placed_above_the_run_button_and_mirrored_for_left_handers() -> void:
	var run := _hud.get_run_button().position
	var bike := _hud.get_bike_button().position
	assert_eq(bike.x, run.x, "même colonne que courir")
	assert_lt(bike.y, run.y, "au-dessus")
	assert_gt(run.y - bike.y, UiTokens.ROUND_BUTTON, "sans chevauchement")
	_hud.set_left_handed(true)
	assert_eq(_hud.get_bike_button().position,
		Vector2(UiTokens.BIKE_BUTTON_CENTER_FROM_CORNER.x, -UiTokens.BIKE_BUTTON_CENTER_FROM_CORNER.y))


func test_scaled_with_the_run_button() -> void:
	_hud.set_button_scale(1.2)
	assert_eq(_hud.get_bike_button().scale, _hud.get_run_button().scale)
