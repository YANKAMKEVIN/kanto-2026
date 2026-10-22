extends GutTest
## Défaut D5 de la QA du J24 (moteur commun) : au bord de la carte, la caméra est bornée et le
## joueur peut passer sous les boutons. Le groupe de boutons qu'il touche devient transparent
## (toujours actif) ; ailleurs, rien ne change. Branché dans Boot à chaque image.

const HUD_SCENE := "res://game/ui/hud/exploration_hud.tscn"
const BOOT_SCENE := "res://game/boot.tscn"

var _hud: ExplorationHud


func before_each() -> void:
	_hud = (load(HUD_SCENE) as PackedScene).instantiate() as ExplorationHud
	add_child_autofree(_hud)


func _settle() -> void:
	for i: int in 20:
		_hud._process(1.0 / 60.0)


func test_buttons_stay_opaque_away_from_the_player() -> void:
	_hud.set_player_screen_rect(Rect2(900, 400, 74, 130))
	_settle()
	assert_false(_hud.is_group_under_player(&"corner"))
	assert_eq(_hud.get_group_alpha(&"corner"), 1.0)
	assert_eq(_hud.get_group_alpha(&"menu"), 1.0)


func test_player_under_the_run_button_fades_the_corner_group_only() -> void:
	var run: Rect2 = _hud.get_button_rects()[&"run"]
	_hud.set_player_screen_rect(Rect2(run.get_center() - Vector2(37, 65), Vector2(74, 130)))
	_settle()
	assert_true(_hud.is_group_under_player(&"corner"))
	assert_almost_eq(_hud.get_group_alpha(&"corner"), UiTokens.BUTTONS_UNDER_PLAYER_ALPHA, 0.001)
	assert_eq(_hud.get_group_alpha(&"menu"), 1.0, "le bouton Menu n'est pas touché")
	_hud.set_player_screen_rect(Rect2(900, 400, 74, 130))
	_settle()
	assert_eq(_hud.get_group_alpha(&"corner"), 1.0, "revient opaque")


func test_player_under_the_menu_button_fades_it() -> void:
	var menu: Rect2 = _hud.get_button_rects()[&"menu"]
	_hud.set_player_screen_rect(Rect2(menu.position, Vector2(74, 130)))
	_settle()
	assert_true(_hud.is_group_under_player(&"menu"))
	assert_almost_eq(_hud.get_group_alpha(&"menu"), UiTokens.BUTTONS_UNDER_PLAYER_ALPHA, 0.001)


func test_fading_starts_and_ends_without_a_jump() -> void:
	var run: Rect2 = _hud.get_button_rects()[&"run"]
	_hud.set_player_screen_rect(run)
	_hud._process(1.0 / 60.0)
	var alpha := _hud.get_group_alpha(&"corner")
	assert_true(alpha < 1.0 and alpha > UiTokens.BUTTONS_UNDER_PLAYER_ALPHA, "fondu court")


func test_hidden_controls_are_not_faded() -> void:
	_hud.set_controls_visible(false)
	_hud.set_player_screen_rect(_hud.get_button_rects()[&"run"])
	_settle()
	assert_false(_hud.is_group_under_player(&"corner"))


func test_boot_feeds_the_player_rect_on_screen() -> void:
	var boot := (load(BOOT_SCENE) as PackedScene).instantiate() as Boot
	add_child_autofree(boot)
	await wait_process_frames(3)
	var player := boot.get_player()
	assert_true(player.is_inside_tree())
	var rect := player.get_screen_body_rect()
	assert_true(rect.has_area(), "rectangle du joueur à l'écran")
	assert_eq(rect.size, player.get_body_rect().size, "zoom 1")
