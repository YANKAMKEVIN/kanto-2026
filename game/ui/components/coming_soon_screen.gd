class_name ComingSoonScreen
extends CanvasLayer
## Écran provisoire « JADIELLE — À venir » (dossier-07 §12, build de développement).
##
## Texte seul sur fond sombre (FADE_COLOR, le même noir que le rideau de transition, posé juste
## au-dessus de lui) dans le style des légendes du monde (WorldCaption, MAJUSCULES pour le nom,
## « À venir » en casse normale). Fondu du texte, tenue [constant HOLD] ou toucher, fondu de
## sortie ; [method present] est une coroutine que le routeur de scènes attend. Il ne connaît ni la
## carte ni le joueur : c'est le routeur qui baisse le rideau avant et le lève après.

## Tenue du texte entre ses deux fondus (le toucher l'abrège, une fois [constant SKIP_DELAY]
## passé : le doigt qui tenait le joystick ne doit pas l'écourter).
const HOLD: float = 2.0
const SKIP_DELAY: float = 0.5
## Au-dessus du rideau de transition (LAYER_TRANSITION) qui est opaque pendant l'écran.
const LAYER_COMING_SOON: int = UiTokens.LAYER_TRANSITION + 1

## L'écran est entièrement parti (fin de [method present]).
signal finished

@export var fade_duration: float = UiTokens.CAPTION_FADE
@export var hold_duration: float = HOLD

var _tween: Tween
var _leaving: bool = false
var _shown_msec: int = 0

@onready var _root: ColorRect = %Root
@onready var _label: Label = %Label


func _ready() -> void:
	layer = LAYER_COMING_SOON
	_root.color = UiTokens.FADE_COLOR
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_process_input(false)


## Montre « <destination> — À venir » puis rend la main une fois l'écran parti.
## Coroutine : await screen.present("JADIELLE").
func present(destination: String) -> void:
	_label.text = "%s — À venir" % destination.to_upper()
	_label.modulate.a = 0.0
	_leaving = false
	_shown_msec = Time.get_ticks_msec()
	visible = true
	set_process_input(true)
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_label, ^"modulate:a", 1.0, fade_duration)
	_tween.tween_interval(hold_duration)
	_tween.tween_callback(_leave)
	await finished


func is_showing() -> bool:
	return visible


func get_label() -> Label:
	return _label


func _input(event: InputEvent) -> void:
	if _leaving or Time.get_ticks_msec() - _shown_msec < int(SKIP_DELAY * 1000.0):
		return
	var tapped := (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or event.is_action_pressed(&"interact")
	if tapped:
		get_viewport().set_input_as_handled()
		_leave()


## Fondu de sortie du texte, puis l'écran se retire et [signal finished] part.
func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_label, ^"modulate:a", 0.0, fade_duration)
	_tween.tween_callback(_done)


func _done() -> void:
	visible = false
	set_process_input(false)
	finished.emit()
