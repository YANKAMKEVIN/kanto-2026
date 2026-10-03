class_name BagTile
extends PanelContainer
## Base des cases tactiles du Sac de combat (onglet de catégorie, carte d'objet) : un toucher
## = un seul tapped, sélection par variation de thème, légère mise à l'échelle à l'appui.
##
## Seule la souris compte (émulée depuis le toucher sur le téléphone, réelle sur Mac) : un
## toucher n'est jamais compté deux fois. Le relâchement doit tomber sur la case, à moins de
## BAG_TAP_SLOP de l'appui : un doigt qui glisse fait défiler la liste au lieu de choisir.

## Relâchement après un appui sur la case : le toucher compte.
signal tapped
## Option (long_press_enabled) : le doigt est resté LONG_PRESS sur la case sans s'éloigner ; émis
## une seule fois, et le relâchement qui suit n'est alors PAS un toucher.
signal long_pressed

## Variation de thème au repos et sélectionnée (fixées par la case concrète).
var normal_variation: StringName = &""
var selected_variation: StringName = &""
## Échelle d'une case sélectionnée (1 = inchangée).
var selected_scale: float = 1.0
## Active l'appui long (BagScreen : favori). Faux par défaut : le Sac du combat n'en a pas.
var long_press_enabled: bool = false

var _selected: bool = false
var _held: bool = false
var _press_position: Vector2 = Vector2.ZERO
var _scale_tween: Tween
var _held_time: float = 0.0
var _long_done: bool = false


func _init() -> void:
	set_process(false)


func _notification(what: int) -> void:
	if what != NOTIFICATION_READY:
		return
	# Godot active _process à l'entrée dans l'arbre dès que le script en définit une, par-dessus
	# le set_process(false) de _init : sans cela, toute carte devenait « favori » après LONG_PRESS.
	# (notification et non _ready : les sous-classes redéfinissent _ready.)
	set_process(false)


func _process(delta: float) -> void:
	_held_time += delta
	if not _long_done and _held_time >= UiTokens.LONG_PRESS:
		_long_done = true
		set_process(false)
		long_pressed.emit()


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	if mouse.pressed:
		if _held:
			return
		_held = true
		_press_position = mouse.global_position
		_held_time = 0.0
		_long_done = false
		set_process(long_press_enabled)
		_animate_scale()
		return
	if not _held:
		return
	_held = false
	set_process(false)
	_animate_scale()
	if _long_done:
		return
	var inside := Rect2(Vector2.ZERO, size).has_point(mouse.position)
	var moved := mouse.global_position.distance_to(_press_position)
	if inside and moved <= UiTokens.BAG_TAP_SLOP:
		tapped.emit()


## Case sélectionnée (liseré d'accent) ou non.
func set_selected(selected: bool) -> void:
	_selected = selected
	if not normal_variation.is_empty():
		theme_type_variation = selected_variation if selected else normal_variation
	_animate_scale()


func is_selected() -> bool:
	return _selected


## Le doigt est posé sur la case.
func is_held() -> bool:
	return _held


func _animate_scale() -> void:
	if not is_inside_tree():
		return
	pivot_offset = size * 0.5
	var target := selected_scale if _selected else 1.0
	if _held:
		target *= UiTokens.PRESSED_SCALE
	if _scale_tween != null:
		_scale_tween.kill()
	_scale_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(self, ^"scale", Vector2.ONE * target, UiTokens.ANIM_MICRO)
