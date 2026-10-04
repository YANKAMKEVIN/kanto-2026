class_name TapGuard
extends Node
## Garde-fou « toucher ou défilement » pour un [BaseButton] posé dans une liste qui défile
## (Paramètres, frise du Dresseur, panneau de la Carte).
##
## Un Button émet `pressed` au relâchement dès que le doigt est encore dessus, même après un
## long glissement : dans un ScrollContainer, le geste de défilement activait donc le contrôle.
## Le garde écoute le bouton : si le doigt s'éloigne de plus de [constant UiTokens.TAP_SLOP] de
## l'appui, l'appui du bouton est **annulé** (le relâchement qui suit ne fait rien) et le geste
## reste au défilement. Un toucher court et immobile garde le comportement normal : `pressed` au
## relâchement. Le bouton doit rester en `MOUSE_FILTER_PASS` (le glissement atteint la liste).
##
## Usage : `TapGuard.attach(button)` une fois, à la création du bouton.

## Vrai tant qu'un appui a été converti en défilement (jusqu'au prochain appui).
var cancelled: bool = false

var _button: BaseButton
var _held: bool = false
var _origin: Vector2 = Vector2.ZERO


## Pose un garde sur [param button] et le renvoie.
static func attach(button: BaseButton) -> TapGuard:
	var guard := TapGuard.new()
	guard.name = "TapGuard"
	guard._button = button
	button.add_child(guard)
	button.gui_input.connect(guard._on_gui_input)
	return guard


## Vrai si [param to] est assez loin de [param from] pour que le geste soit un défilement.
static func is_scroll(from: Vector2, to: Vector2) -> bool:
	return from.distance_to(to) > UiTokens.TAP_SLOP


func _on_gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.button_index == MOUSE_BUTTON_LEFT:
		_held = mouse.pressed
		cancelled = false
		_origin = mouse.global_position
		return
	var motion := event as InputEventMouseMotion
	if motion == null or not _held or cancelled:
		return
	if is_scroll(_origin, motion.global_position):
		cancelled = true
		_cancel_press()


## BaseButton n'a pas d'annulation publique : le désactiver un instant efface l'appui en cours.
func _cancel_press() -> void:
	if _button == null or _button.disabled:
		return
	var was_pressed := _button.button_pressed
	_button.disabled = true
	_button.disabled = false
	if _button.toggle_mode:
		_button.set_pressed_no_signal(was_pressed)
