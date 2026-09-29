class_name BattleBackButton
extends BattleWidget
## Bouton rond « ‹ » (combat-capacites-v1) : sous la carte joueur, en bas à gauche ; ramène
## de la grille des capacités à la grille d'actions.
##
## Cercle BATTLE_BACK_SIZE (≥ TOUCH_MIN), fond PANEL_BG, chevron blanc (SVG : la flèche est
## dessinée, pas tirée de la police). Un toucher = un back_requested (souris émulée depuis le
## toucher sur le téléphone, souris réelle sur Mac : un seul des deux compte). « ui_cancel »
## (Échap) fait de même tant qu'il est affiché. Vibration courte.

## « ‹ » touché (ou Échap) pendant que le bouton est affiché.
signal back_requested

const ICON: Texture2D = preload("res://assets/ui/icons/battle/back.svg")

var _press_tween: Tween

@onready var _button: Button = %Body


func _ready() -> void:
	slide_direction = Vector2.LEFT
	super._ready()
	_button.custom_minimum_size = Vector2.ONE * UiTokens.BATTLE_BACK_SIZE
	_button.icon = ICON
	_button.focus_mode = Control.FOCUS_NONE
	_button.pressed.connect(_on_pressed)
	_button.button_down.connect(_press_feedback.bind(true))
	_button.button_up.connect(_press_feedback.bind(false))


func _unhandled_input(event: InputEvent) -> void:
	if _shown and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_pressed()


func get_button() -> Button:
	return _button


func _on_pressed() -> void:
	if not _shown:
		return
	_haptic(UiTokens.HAPTIC_TAP_MS)
	back_requested.emit()


func _press_feedback(down: bool) -> void:
	if _press_tween != null:
		_press_tween.kill()
	_press_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target := Vector2.ONE * (UiTokens.PRESSED_SCALE if down else 1.0)
	_press_tween.tween_property(_button, ^"scale", target, UiTokens.ANIM_MICRO)
