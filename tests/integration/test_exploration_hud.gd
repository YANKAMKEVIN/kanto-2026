extends GutTest
## HUD d'exploration : calque, titre de zone (texte, placement, cycle d'animation),
## placement du bouton courir, câblage dans Boot.

const HUD_SCENE := "res://game/ui/hud/exploration_hud.tscn"
const TITLE_SCENE := "res://game/ui/components/zone_title.tscn"
## Largeurs d'écran visées par l'aspect expand (1080 de haut) : 16:9 et S24.
const SCREEN_WIDTHS: Array[float] = [1920.0, 2340.0]
const SCREEN_HEIGHT := 1080.0

var _hud: ExplorationHud


func before_each() -> void:
	_hud = (load(HUD_SCENE) as PackedScene).instantiate() as ExplorationHud
	add_child_autofree(_hud)


func test_is_hud_canvas_layer() -> void:
	assert_eq(_hud.layer, UiTokens.LAYER_HUD)
	assert_eq(UiTokens.LAYER_HUD, 10)


func test_zone_title_hidden_before_arrival() -> void:
	assert_false(_hud.get_zone_title().is_showing())


func test_show_zone_title_texts() -> void:
	_hud.show_zone_title("Bourg Palette", "Kanto")
	var title := _hud.get_zone_title()
	assert_true(title.is_showing())
	assert_eq(title.get_zone_name_text(), "BOURG PALETTE")
	assert_eq(title.get_region_text(), "Kanto")


func test_zone_title_top_left_inside_safe_margin() -> void:
	_hud.show_zone_title("Bourg Palette", "Kanto")
	var title := _hud.get_zone_title()
	var rest := title.get_rest_position()
	assert_eq(rest, Vector2.ONE * UiTokens.SAFE_MARGIN)
	assert_true(rest.x >= 48.0 and rest.y >= 48.0)
	assert_true(title.size.x > 0.0 and title.size.y > 0.0)
	assert_true(rest.y + title.size.y < SCREEN_HEIGHT * 0.5, "reste en haut de l'écran")
	assert_true(rest.x + title.size.x < SCREEN_WIDTHS[0] * 0.5, "reste à gauche")


func test_zone_title_styles() -> void:
	var title := _hud.get_zone_title()
	var name_label := title.get_node(^"%NameLabel") as Label
	var region_label := title.get_node(^"%RegionLabel") as Label
	assert_eq(name_label.get_theme_font_size(&"font_size"), UiTokens.FONT_TITLE)
	assert_eq(region_label.get_theme_font_size(&"font_size"), UiTokens.FONT_CAPTION)
	assert_eq(region_label.get_theme_color(&"font_color"), UiTokens.TEXT_MUTED)
	assert_eq(name_label.get_theme_color(&"font_color"), UiTokens.TEXT)
	var bold := name_label.get_theme_font(&"font") as FontVariation
	assert_not_null(bold, "nom de zone en gras")


func test_zone_title_animation_cycle() -> void:
	var title := (load(TITLE_SCENE) as PackedScene).instantiate() as ZoneTitle
	title.slide_duration = 0.05
	title.hold_duration = 0.1
	add_child_autofree(title)
	watch_signals(title)
	title.show_title("Route 1", "Kanto")
	assert_eq(title.position.x, UiTokens.SAFE_MARGIN - UiTokens.PANEL_SLIDE, "part décalé")
	await wait_for_signal(title.title_shown, 1.0)
	assert_eq(title.position, title.get_rest_position())
	assert_almost_eq(title.modulate.a, 1.0, 0.01)
	await wait_for_signal(title.title_hidden, 1.0)
	assert_signal_emitted(title, "title_hidden")
	assert_false(title.is_showing())


func test_zone_title_default_timing_from_tokens() -> void:
	var title := _hud.get_zone_title()
	assert_eq(title.slide_duration, 0.3)
	assert_eq(title.hold_duration, 2.5)


func test_run_button_in_right_half_inside_safe_margin() -> void:
	var button := _hud.get_run_button()
	assert_eq(button.action, "run")
	var radius := UiTokens.ROUND_BUTTON * 0.5
	var from_corner := -button.position
	for width: float in SCREEN_WIDTHS:
		var center := Vector2(width, SCREEN_HEIGHT) - from_corner
		assert_true(center.x - radius >= width * 0.5, "moitié droite (%d)" % width)
		assert_true(center.x + radius <= width - UiTokens.SAFE_MARGIN, "bord droit")
		assert_true(center.y + radius <= SCREEN_HEIGHT - UiTokens.SAFE_MARGIN, "bord bas")
		assert_true(center.y - radius >= UiTokens.SAFE_MARGIN, "bord haut")


func test_run_button_anchored_bottom_right() -> void:
	var anchor := _hud.get_run_button().get_parent() as Control
	assert_eq(Vector4(anchor.anchor_left, anchor.anchor_top, anchor.anchor_right,
		anchor.anchor_bottom), Vector4.ONE)


func test_focus_out_releases_run() -> void:
	Input.action_press(&"run")
	_hud.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(Input.is_action_pressed(&"run"))


func test_paused_releases_run() -> void:
	Input.action_press(&"run")
	_hud.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_false(Input.is_action_pressed(&"run"))


func test_joystick_covers_screen() -> void:
	var joystick := _hud.get_joystick()
	assert_eq(Vector4(joystick.anchor_left, joystick.anchor_top, joystick.anchor_right,
		joystick.anchor_bottom), Vector4(0, 0, 1, 1))
	assert_false(joystick.is_active())


func test_boot_shows_zone_title_at_start() -> void:
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	add_child_autofree(boot)
	var hud := boot.get_node(^"%ExplorationHud") as ExplorationHud
	assert_not_null(hud)
	assert_true(hud.get_zone_title().is_showing())
	assert_eq(hud.get_zone_title().get_zone_name_text(), "BOURG PALETTE")
	assert_eq(hud.get_zone_title().get_region_text(), "Kanto")
