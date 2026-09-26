class_name BattleMessageBanner
extends BattleWidget
## Bandeau des messages de combat (jalon 4 Q12) : bandeau sombre translucide qui prend la
## place de la grille d'actions, en bas à droite, à droite de la carte joueur (jamais
## dessous) ; texte FONT_BODY, 2 lignes au plus, affiché tel quel (le moteur le formule).
##
## show_message est une coroutine : elle se termine après BATTLE_MESSAGE_HOLD, ou plus tôt
## au premier toucher sur l'écran (appui d'un InputEventScreenTouch : sur Mac, le toucher est
## émulé depuis la souris). Pas d'indicateur « › » : le combat avance seul (dossier 05 §21).
## Un nouveau message remplace le précédent (qui se termine aussitôt).

var _hold: Tween

@onready var _text: Label = %Text


func _ready() -> void:
	super._ready()
	_body.custom_minimum_size = Vector2(
		UiTokens.BATTLE_MESSAGE_WIDTH, UiTokens.BATTLE_MESSAGE_HEIGHT)
	_text.max_lines_visible = UiTokens.BATTLE_MESSAGE_MAX_LINES


func _input(event: InputEvent) -> void:
	if not is_waiting():
		return
	var touch := event as InputEventScreenTouch
	if touch == null or not touch.pressed:
		return
	get_viewport().set_input_as_handled()
	skip()


## Coroutine : affiche [param text] (le bandeau apparaît s'il était caché) et attend
## BATTLE_MESSAGE_HOLD ou un toucher. Le bandeau reste affiché ensuite (slide_out le cache).
func show_message(text: String) -> void:
	skip()
	_text.text = text
	if not _shown:
		slide_in()
	var time := UiTokens.BATTLE_MESSAGE_HOLD * speed_scale
	if time <= 0.0:
		return
	_hold = create_tween()
	_hold.tween_interval(time)
	await _hold.finished


## Termine tout de suite le message en attente (comme un toucher).
func skip() -> void:
	var hold := _hold
	_hold = null
	BattleWidget.complete_tween(hold)


## Un message attend (tenue en cours).
func is_waiting() -> bool:
	return _hold != null and _hold.is_valid() and _hold.is_running()


func get_text() -> String:
	return _text.text


func get_label() -> Label:
	return _text
