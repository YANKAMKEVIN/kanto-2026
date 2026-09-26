extends GutTest
## Interface de combat, jalon 4B (4/4) : bandeau des messages. Texte tel quel en FONT_BODY,
## 2 lignes au plus, show_message se termine après BATTLE_MESSAGE_HOLD ou au toucher, pas de
## « › », place de la grille (à droite de la carte joueur, jamais dessous) à 1920 et 2340.

const BANNER_SCENE := "res://game/ui/battle/battle_message_banner.tscn"
const CARD_SCENE := "res://game/ui/battle/battle_info_card.tscn"
const SCREEN_WIDTHS: Array[float] = [1920.0, 2340.0]
const SCREEN_HEIGHT := 1080.0
const INTRO := "Le Rival envoie Carapuce !"

var _banner: BattleMessageBanner
var _done: bool = false


func before_each() -> void:
	_banner = (load(BANNER_SCENE) as PackedScene).instantiate() as BattleMessageBanner
	add_child_autofree(_banner)
	_done = false


func _show_and_flag(text: String) -> void:
	await _banner.show_message(text)
	_done = true


func _touch(pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = Vector2(900, 500)
	event.pressed = pressed
	get_viewport().push_input(event, true)


func test_hidden_at_start() -> void:
	assert_false(_banner.visible)


func test_text_shown_as_is_in_body_font() -> void:
	_banner.speed_scale = 0.0
	await _banner.show_message(INTRO)
	assert_true(_banner.visible)
	assert_eq(_banner.get_text(), INTRO, "affiché tel quel")
	var label := _banner.get_label()
	assert_eq(label.get_theme_font_size(&"font_size"), UiTokens.FONT_BODY)
	assert_eq(label.max_lines_visible, 2, "2 lignes au plus")
	assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
	assert_false(label.text.contains("›"), "pas d'indicateur de suite")


func test_banner_is_dark_translucent() -> void:
	var box := _banner.get_body().get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_eq(box.bg_color, UiTokens.BATTLE_MESSAGE_BG)
	assert_lt(box.bg_color.a, 1.0)


func test_ends_after_hold() -> void:
	# Une image d'abord : celle du chargement (before_each) compterait dans la tenue.
	await wait_process_frames(2)
	_show_and_flag(INTRO)
	await wait_seconds(UiTokens.BATTLE_MESSAGE_HOLD - 0.1)
	assert_false(_done, "pas avant BATTLE_MESSAGE_HOLD")
	assert_true(_banner.is_waiting())
	await wait_seconds(0.2)
	assert_true(_done, "terminé après BATTLE_MESSAGE_HOLD")
	assert_false(_banner.is_waiting())


func test_ends_on_touch() -> void:
	_show_and_flag(INTRO)
	await wait_seconds(0.1)
	assert_false(_done)
	_touch(true)
	await wait_process_frames(1)
	assert_true(_done, "le toucher fait avancer")
	_touch(false)


func test_touch_when_not_waiting_is_not_consumed() -> void:
	_banner.speed_scale = 0.0
	await _banner.show_message(INTRO)
	assert_false(_banner.is_waiting())
	_touch(true)
	_touch(false)
	await wait_process_frames(1)
	assert_true(true, "aucun effet ni erreur")


func test_next_message_replaces_previous() -> void:
	_show_and_flag(INTRO)
	await wait_process_frames(2)
	_banner.show_message("Carapuce utilise Mimi-Queue !")
	await wait_process_frames(1)
	assert_true(_done, "le précédent se termine")
	assert_eq(_banner.get_text(), "Carapuce utilise Mimi-Queue !")
	_banner.skip()


func test_instant_with_speed_scale_zero() -> void:
	_banner.speed_scale = 0.0
	await _show_and_flag(INTRO)
	assert_true(_done)


func test_slides_in_on_first_message_and_out() -> void:
	_show_and_flag(INTRO)
	assert_eq(_banner.modulate.a, 0.0, "fondu")
	assert_eq(_banner.get_body().position, Vector2.DOWN * UiTokens.PANEL_SLIDE, "glissement")
	await wait_seconds(UiTokens.ANIM_PANEL + 0.05)
	assert_eq(_banner.get_body().position, Vector2.ZERO)
	_banner.skip()
	await _banner.slide_out()
	assert_false(_banner.visible)


func test_long_message_fits_two_lines() -> void:
	_banner.speed_scale = 0.0
	await _banner.show_message("Ce n'est pas très efficace... Salamèche ne peut plus baisser "
		+ "davantage l'Attaque de Carapuce !")
	await wait_process_frames(2)
	var label := _banner.get_label()
	assert_lte(label.get_visible_line_count(), 2)
	assert_eq(_banner.get_body().size,
		Vector2(UiTokens.BATTLE_MESSAGE_WIDTH, UiTokens.BATTLE_MESSAGE_HEIGHT), "taille fixe")


func test_placed_right_of_own_card_never_below() -> void:
	for width: float in SCREEN_WIDTHS:
		var screen := Control.new()
		screen.size = Vector2(width, SCREEN_HEIGHT)
		add_child_autofree(screen)
		var banner := (load(BANNER_SCENE) as PackedScene).instantiate() as BattleMessageBanner
		var card := (load(CARD_SCENE) as PackedScene).instantiate() as BattleInfoCard
		screen.add_child(banner)
		screen.add_child(card)
		BattleHudLayout.place(banner, BattleHudLayout.Slot.MESSAGE)
		BattleHudLayout.place(card, BattleHudLayout.Slot.OWN_CARD)
		banner.speed_scale = 0.0
		await banner.show_message(INTRO)
		await wait_process_frames(2)
		var rect := banner.get_global_rect()
		var own := card.get_global_rect()
		assert_gt(rect.position.x, own.end.x, "à droite de la carte joueur à %d" % width)
		assert_false(rect.intersects(own), "pas de chevauchement")
		var actions := BattleHudLayout.rect(BattleHudLayout.Slot.ACTIONS, screen.size)
		assert_true(rect.intersects(actions), "à la place de la grille")
		assert_true(Rect2(Vector2.ONE * UiTokens.SAFE_MARGIN,
			screen.size - Vector2.ONE * UiTokens.SAFE_MARGIN * 2.0).encloses(rect))
