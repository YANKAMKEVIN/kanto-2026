class_name HpBar
extends HBoxContainer
## Barre de PV (dossier 05 §12) : libellé « PV » à gauche, coloré comme la barre, puis la
## barre (HP_BAR_HEIGHT, coins ronds, fond clair translucide).
##
## Vert au-dessus de HP_HIGH_THRESHOLD (50 %), jaune au-dessus de HP_LOW_THRESHOLD (20 %),
## rouge sinon ; pendant une descente animée, la couleur change aux seuils franchis.
## set_hp est immédiat ; animate_hp descend (ou remonte) en HP_TWEEN, plus vite si « gros
## coup » (HP_TWEEN_FAST). Elle ne connaît que des entiers.

## La valeur affichée (arrondie) a changé, pendant une animation ou par set_hp.
signal display_changed(hp: int, max_hp: int)

## Libellé (texte d'interface).
const LABEL_TEXT := "PV"

## Durées multipliées (0 = instantané, pour les tests).
var speed_scale: float = 1.0

var _max_hp: int = 1
var _target_hp: int = 1
## Valeur affichée (continue pendant l'animation).
var _shown_hp: float = 1.0
var _color: Color = UiTokens.HP_HIGH
var _tween: Tween
## Trace des PV perdus (CV.3, CV-9) : valeur continue du bord de la trace, toujours >= la valeur
## affichée ; son Tween est indépendant (jamais attendu, donc sans effet sur les durées).
var _trail_hp: float = 1.0
var _trail_tween: Tween
var _fill: StyleBoxFlat

@onready var _label: Label = %Label
@onready var _track: Control = %Track


func _ready() -> void:
	add_theme_constant_override(&"separation", UiTokens.HP_BAR_LABEL_GAP)
	_label.text = LABEL_TEXT
	_track.custom_minimum_size.y = UiTokens.HP_BAR_HEIGHT
	_fill = (get_theme_stylebox(&"fill") as StyleBoxFlat).duplicate() as StyleBoxFlat
	_track.draw.connect(_draw_track)
	_apply()


## Couleur de la barre pour [param hp] sur [param max_hp] (seuils stricts : 50 % tout juste
## est jaune, 20 % tout juste est rouge).
static func color_for(hp: int, max_hp: int) -> Color:
	if max_hp <= 0:
		return UiTokens.HP_LOW
	return color_for_ratio(float(hp) / float(max_hp))


static func color_for_ratio(ratio: float) -> Color:
	if ratio > UiTokens.HP_HIGH_THRESHOLD:
		return UiTokens.HP_HIGH
	if ratio > UiTokens.HP_LOW_THRESHOLD:
		return UiTokens.HP_MID
	return UiTokens.HP_LOW


## Affiche [param hp] / [param max_hp] tout de suite (interrompt une animation).
func set_hp(hp: int, max_hp: int) -> void:
	_kill_tween()
	_kill_trail()
	_max_hp = maxi(max_hp, 1)
	_target_hp = clampi(hp, 0, _max_hp)
	_set_shown(float(_target_hp))
	_trail_hp = _shown_hp


## Coroutine : fait glisser la barre jusqu'à [param hp] en HP_TWEEN, ou HP_TWEEN_FAST si
## [param big] (gros coup). Se termine quand la valeur est atteinte (ou si une autre
## animation, ou set_hp, l'interrompt).
func animate_hp(hp: int, max_hp: int, big: bool = false) -> void:
	_kill_tween()
	if max_hp != _max_hp:
		_max_hp = maxi(max_hp, 1)
		_shown_hp = minf(_shown_hp, float(_max_hp))
	_target_hp = clampi(hp, 0, _max_hp)
	var time := (UiTokens.HP_TWEEN_FAST if big else UiTokens.HP_TWEEN) * speed_scale
	if time <= 0.0 or is_equal_approx(_shown_hp, float(_target_hp)):
		_set_shown(float(_target_hp))
		_kill_trail()
		_trail_hp = _shown_hp
		return
	_start_trail(time)
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_shown, _shown_hp, float(_target_hp), time)
	_tween.tween_callback(_on_done)
	# Fin du Tween, pas un signal de la barre (voir BattleWidget.complete_tween).
	await _tween.finished


## Valeur affichée, arrondie (celle des chiffres « 19 / 19 »).
func get_shown_hp() -> int:
	return roundi(_shown_hp)


## Valeur affichée, continue (pendant une animation).
func get_shown_value() -> float:
	return _shown_hp


func get_max_hp() -> int:
	return _max_hp


## Valeur visée par la dernière demande.
func get_target_hp() -> int:
	return _target_hp


func get_color() -> Color:
	return _color


func is_animating() -> bool:
	return _tween != null


func get_label() -> Label:
	return _label


func get_track() -> Control:
	return _track


## Valeur du bord de la trace (continue) ; égale à la valeur affichée quand il n'y en a pas.
func get_trail_value() -> float:
	return _trail_hp


func is_trail_shown() -> bool:
	return _trail_hp > _shown_hp + 0.001


## Lance la trace d'une descente de [param time] s : le bord reste où était la barre, attend la
## fin de la descente puis HP_TRAIL_HOLD, et rattrape en HP_TRAIL_CATCH. Rien si ça monte.
func _start_trail(time: float) -> void:
	_kill_trail()
	if float(_target_hp) >= _shown_hp:
		_trail_hp = _shown_hp
		return
	_trail_hp = maxf(_trail_hp, _shown_hp)
	_trail_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_trail_tween.tween_interval(time + UiTokens.HP_TRAIL_HOLD * speed_scale)
	_trail_tween.tween_method(_set_trail, _trail_hp, float(_target_hp),
		UiTokens.HP_TRAIL_CATCH * speed_scale)
	_trail_tween.tween_callback(_on_trail_done)


func _set_trail(value: float) -> void:
	_trail_hp = value
	_track.queue_redraw()


func _on_trail_done() -> void:
	_trail_tween = null
	_trail_hp = _shown_hp
	_track.queue_redraw()


func _kill_trail() -> void:
	if _trail_tween != null:
		_trail_tween.kill()
		_trail_tween = null


func _set_shown(value: float) -> void:
	var before := roundi(_shown_hp)
	_shown_hp = value
	_apply()
	if roundi(_shown_hp) != before or _tween == null:
		display_changed.emit(roundi(_shown_hp), _max_hp)


func _apply() -> void:
	_color = color_for_ratio(_shown_hp / float(_max_hp))
	_fill.bg_color = _color
	_label.add_theme_color_override(&"font_color", _color)
	_track.queue_redraw()


func _draw_track() -> void:
	var rect := Rect2(Vector2.ZERO, _track.size)
	_track.draw_style_box(get_theme_stylebox(&"background"), rect)
	if _shown_hp <= 0.0:
		return
	var inner := rect.grow(-UiTokens.HP_BAR_INSET)
	var width := maxf(inner.size.x * _shown_hp / float(_max_hp), inner.size.y)
	if _trail_hp > _shown_hp:
		var trail_width := maxf(inner.size.x * _trail_hp / float(_max_hp), inner.size.y)
		var trail := _fill.duplicate() as StyleBoxFlat
		trail.bg_color = UiTokens.HP_TRAIL_COLOR
		_track.draw_style_box(trail, Rect2(inner.position, Vector2(trail_width, inner.size.y)))
	_track.draw_style_box(_fill, Rect2(inner.position, Vector2(width, inner.size.y)))


func _on_done() -> void:
	_tween = null


## Une animation interrompue se termine d'abord à sa valeur (ceux qui l'attendaient
## reprennent), puis la nouvelle demande s'applique.
func _kill_tween() -> void:
	var previous := _tween
	_tween = null
	BattleWidget.complete_tween(previous)
