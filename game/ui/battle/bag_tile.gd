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

## Variation de thème au repos et sélectionnée (fixées par la case concrète).
var normal_variation: StringName = &""
var selected_variation: StringName = &""
## Échelle d'une case sélectionnée (1 = inchangée).
var selected_scale: float = 1.0

var _selected: bool = false
var _held: bool = false
var _press_position: Vector2 = Vector2.ZERO
var _scale_tween: Tween


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
		_animate_scale()
		return
	if not _held:
		return
	_held = false
	_animate_scale()
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
