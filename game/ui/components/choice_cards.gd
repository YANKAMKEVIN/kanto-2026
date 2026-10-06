class_name ChoiceCards
extends Control
## Choix à deux grandes cartes (bible UI/UX §4, Q-18 ; jalon-06.md §6.12) : une question, puis
## côte à côte la carte de l'action (en ACCENT, « OUBLIER ») et celle du renoncement (« GARDER »),
## chacune avec sa précision. Jamais « Oui / Non » ; jamais plus de deux cartes.
##
## Composant générique : le menu, le combat (confirmation d'oubli, T29) et le J7A (SOIGNER /
## PAS MAINTENANT) le montrent sur leur propre calque. Il couvre l'écran d'un voile qui intercepte
## le toucher pendant qu'il est affiché ; il **ne gère pas le retour Android** : celui qui le
## montre décide (le plus souvent, retour = renoncement).
## - Un seul [signal chosen] par question : une fois une carte touchée, le composant se ferme et
##   ne répond plus (un double toucher ne répète rien).
## - [code]speed_scale[/code] = 0 : apparition et disparition instantanées (tests).
## Placement (aspect expand, 1920 à 2340 de large) : plein cadre, contenu centré ; les cartes sont
## à plus de SAFE_MARGIN des bords.

## Une carte est touchée : [param confirmed] vrai pour l'action, faux pour le renoncement.
signal chosen(confirmed: bool)

## Durées multipliées (0 = instantané).
var speed_scale: float = 1.0

var _showing: bool = false
var _tween: Tween
var _scrim: ColorRect
var _center: CenterContainer
var _content: VBoxContainer
var _title: Label
var _detail: Label
var _confirm: Button
var _cancel: Button
var _confirm_label: Label
var _confirm_detail: Label
var _cancel_label: Label
var _cancel_detail: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrim = ColorRect.new()
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scrim.color = UiTokens.CHOICE_SCRIM
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_scrim)
	var center := CenterContainer.new()
	_center = center
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_content = VBoxContainer.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_theme_constant_override(&"separation", UiTokens.GAP)
	# Largeur fixée (les deux cartes + l'écart) : sans elle, les textes à retour automatique
	# réclament une hauteur démesurée au premier calcul et le contenu sort de l'écran.
	_content.custom_minimum_size.x = UiTokens.CHOICE_CARD_SIZE.x * 2.0 \
		+ UiTokens.CHOICE_CARD_GAP
	center.add_child(_content)
	_title = _text_label(&"ChoiceTitle", _content)
	_detail = _text_label(&"ChoiceDetail", _content)
	var cards := HBoxContainer.new()
	cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override(&"separation", UiTokens.CHOICE_CARD_GAP)
	_content.add_child(cards)
	var cancel_parts := _make_card(&"ChoiceCancel", &"ChoiceCancelLabel", &"ChoiceCancelDetail")
	var confirm_parts := _make_card(&"ChoiceConfirm", &"ChoiceConfirmLabel",
		&"ChoiceConfirmDetail")
	# Le renoncement à gauche, l'action à droite (le pouce droit atteint l'action).
	_cancel = cancel_parts[0]
	_cancel_label = cancel_parts[1]
	_cancel_detail = cancel_parts[2]
	_confirm = confirm_parts[0]
	_confirm_label = confirm_parts[1]
	_confirm_detail = confirm_parts[2]
	cards.add_child(_cancel)
	cards.add_child(_confirm)
	_cancel.pressed.connect(_on_chosen.bind(false))
	_confirm.pressed.connect(_on_chosen.bind(true))
	visible = false


## Montre la question de [param view] ; remplace celle qui serait déjà affichée.
func show_choice(view: ChoiceView) -> void:
	_title.text = view.title
	_title.visible = not view.title.is_empty()
	_detail.text = view.detail
	_detail.visible = not view.detail.is_empty()
	_confirm_label.text = view.confirm_label
	_confirm_detail.text = view.confirm_detail
	_confirm_detail.visible = not view.confirm_detail.is_empty()
	_cancel_label.text = view.cancel_label
	_cancel_detail.text = view.cancel_detail
	_cancel_detail.visible = not view.cancel_detail.is_empty()
	UiPrefsApplier.apply(self)
	_kill_tween()
	_showing = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var time := UiTokens.CHOICE_FADE * speed_scale
	if time <= 0.0:
		modulate.a = 1.0
		_set_slide(0.0)
		return
	modulate.a = 0.0
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"modulate:a", 1.0, time)
	_set_slide(UiTokens.CHOICE_SLIDE)
	_tween.tween_method(_set_slide, UiTokens.CHOICE_SLIDE, 0.0, time)


## Ferme sans rien émettre (la question n'a plus de raison d'être) ; fondu, puis invisible.
func hide_choice() -> void:
	_kill_tween()
	_showing = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var time := UiTokens.ANIM_MICRO * speed_scale
	if time <= 0.0 or not visible or not is_inside_tree():
		_finish_hide()
		return
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, ^"modulate:a", 0.0, time)
	_tween.tween_callback(_finish_hide)


## Vrai du [method show_choice] jusqu'au choix (ou [method hide_choice]).
func is_showing() -> bool:
	return _showing


func get_confirm_button() -> Button:
	return _confirm


func get_cancel_button() -> Button:
	return _cancel


func get_title_label() -> Label:
	return _title


## Tous les textes visibles, dans l'ordre de l'arbre (question, précision, cartes).
func get_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	for label: Label in [_title, _detail, _cancel_label, _cancel_detail, _confirm_label,
			_confirm_detail]:
		if label.visible and not label.text.is_empty():
			texts.append(label.text)
	return texts


func _make_card(variation: StringName, label_variation: StringName,
		detail_variation: StringName) -> Array:
	var card := Button.new()
	card.theme_type_variation = variation
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = UiTokens.CHOICE_CARD_SIZE
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTokens.CHOICE_CARD_PAD)
	card.add_child(margin)
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override(&"separation", UiTokens.GAP)
	margin.add_child(texts)
	var label := _text_label(label_variation, texts)
	var detail := _text_label(detail_variation, texts)
	return [card, label, detail]


func _text_label(variation: StringName, parent: Control) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


## Décalage vertical du contenu pendant l'apparition (les décalages d'ancrage gardent le
## centrage ; la position d'un conteneur ancré ne le garde pas).
func _set_slide(dy: float) -> void:
	_center.offset_top = dy
	_center.offset_bottom = dy


func _on_chosen(confirmed: bool) -> void:
	if not _showing:
		return
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	hide_choice()
	chosen.emit(confirmed)


func _finish_hide() -> void:
	_tween = null
	modulate.a = 0.0
	visible = false


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
