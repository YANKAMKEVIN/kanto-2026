class_name BadgeBubble
extends PanelContainer
## Bulle de détail d'un badge obtenu (jalon 10, T6 ; dossier 08 §6, dossier 12 §13, lot de textes
## E) : « Badge Roche » puis « Argenta — Pierre », tels que la vue [BadgeSlotView] les donne.
## Elle n'affiche que ces deux lignes ; fermée par un toucher (voir [TrainerScreen]).

var _name: Label
var _detail: Label
var _tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.x = UiTokens.TRAINER_BUBBLE_MIN_WIDTH
	var style := StyleBoxFlat.new()
	style.bg_color = UiTokens.TRAINER_BUBBLE_BG
	style.set_corner_radius_all(UiTokens.TRAINER_BUBBLE_RADIUS)
	style.border_width_top = 4
	style.border_color = UiTokens.ACCENT
	style.content_margin_left = UiTokens.TRAINER_BUBBLE_PAD_H
	style.content_margin_right = UiTokens.TRAINER_BUBBLE_PAD_H
	style.content_margin_top = UiTokens.TRAINER_BUBBLE_PAD_V
	style.content_margin_bottom = UiTokens.TRAINER_BUBBLE_PAD_V
	style.shadow_color = UiTokens.SHADOW
	style.shadow_size = UiTokens.SHADOW_SIZE
	add_theme_stylebox_override(&"panel", style)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.TRAINER_BUBBLE_LINE_GAP)
	add_child(column)
	_name = _label(&"TrainerMomentTitle")
	column.add_child(_name)
	_detail = _label(&"TrainerMomentDetail")
	column.add_child(_detail)


## Pose les deux lignes de [param view] (nom, puis ville et Champion).
func setup(view: BadgeSlotView) -> void:
	_name.text = view.name
	_detail.text = view.detail
	_detail.visible = not view.detail.is_empty()
	size = get_combined_minimum_size()


func get_name_label() -> Label:
	return _name


func get_detail_label() -> Label:
	return _detail


## Apparition courte : fondu et glissement vers le haut (instantané si [param speed_scale] = 0).
func appear(speed_scale: float) -> void:
	if _tween != null:
		_tween.kill()
	var target := position
	if speed_scale <= 0.0:
		modulate.a = 1.0
		return
	modulate.a = 0.0
	position = target + Vector2(0.0, UiTokens.TRAINER_BUBBLE_SLIDE)
	var time := UiTokens.TRAINER_BUBBLE_FADE * speed_scale
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, time)
	_tween.tween_property(self, "position", target, time)


func _label(variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
