class_name ExpBar
extends Control
## Fine barre d'XP (jalon 5C T10) : fond clair translucide et remplissage EXP_BAR_FILL, coins
## ronds, hauteur EXP_BAR_HEIGHT. Elle ne connaît qu'une fraction 0..1 ; une tranche de barre
## est une fraction de départ et une d'arrivée (un niveau gagné ouvre une nouvelle tranche).
##
## set_fraction est immédiat ; animate_fraction glisse en EXP_TWEEN (multiplié par
## speed_scale, 0 = instantané). Styles « background » et « fill » du thème (variation ExpBar).

## Durées multipliées (0 = instantané, pour les tests).
var speed_scale: float = 1.0

var _fraction: float = 0.0
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = UiTokens.EXP_BAR_HEIGHT
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_style_box(get_theme_stylebox(&"background"), rect)
	if _fraction <= 0.0:
		return
	var inner := rect.grow(-UiTokens.BORDER_WIDTH)
	var width := maxf(inner.size.x * _fraction, inner.size.y)
	draw_style_box(get_theme_stylebox(&"fill"), Rect2(inner.position, Vector2(width, inner.size.y)))


## Affiche [param fraction] (0..1) tout de suite (interrompt une animation).
func set_fraction(fraction: float) -> void:
	_kill_tween()
	_set_shown(fraction)


## Coroutine : fait glisser la barre de [param from] à [param to] en EXP_TWEEN. Se termine
## quand la valeur est atteinte (ou si set_fraction / une autre animation l'interrompt).
func animate_fraction(from: float, to: float) -> void:
	_kill_tween()
	_set_shown(from)
	var time := UiTokens.EXP_TWEEN * speed_scale
	if time <= 0.0 or is_equal_approx(from, to):
		_set_shown(to)
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_shown, clampf(from, 0.0, 1.0), clampf(to, 0.0, 1.0), time)
	_tween.tween_callback(_on_done)
	# Fin du Tween, pas un signal de la barre (voir BattleWidget.complete_tween).
	await _tween.finished


## Fraction affichée (continue pendant l'animation).
func get_fraction() -> float:
	return _fraction


func is_animating() -> bool:
	return _tween != null


func _set_shown(value: float) -> void:
	_fraction = clampf(value, 0.0, 1.0)
	queue_redraw()


func _on_done() -> void:
	_tween = null


## Une animation interrompue se termine d'abord à sa valeur (ceux qui l'attendaient
## reprennent), puis la nouvelle demande s'applique.
func _kill_tween() -> void:
	var previous := _tween
	_tween = null
	BattleWidget.complete_tween(previous)
