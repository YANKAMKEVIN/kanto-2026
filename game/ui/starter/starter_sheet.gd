class_name StarterSheet
extends CanvasLayer
## Fiche très légère d'un starter (jalon 4A, calque LAYER_MENU) : NOM, pastilles de type,
## phrase en italique, et deux boutons, RETOUR et CHOISIR (accent). Pas de statistiques.
##
## Carte sombre translucide à GAUCHE de l'écran, centrée verticalement, pour laisser voir la
## table et le joueur. Elle entre en glissant de PANEL_SLIDE depuis la gauche en fondu
## (ANIM_PANEL) et ressort de même (STARTER_SHEET_CLOSE).
## Elle ne fait qu'afficher et relayer : elle reçoit une StarterSheetView (des chaînes) et
## émet choose_pressed / back_pressed ; celui qui l'a ouverte décide et la ferme.
## - Un toucher sur un bouton = un signal (souris émulée depuis le toucher, ou toucher émulé
##   depuis la souris sur Mac : seul le bouton de l'interface, piloté par la souris, compte).
##   Après un premier signal, la fiche n'en émet plus jusqu'à sa réouverture (pas de double
##   choix sur un double toucher).
## - L'action « interact » (E, Espace) n'a aucun effet : les boutons ne prennent pas le focus.
## - Fermée, elle est invisible et ne reçoit rien.
## Placement (aspect expand, 1920 à 2340 de large) : ancrée au bord gauche, à
## STARTER_SHEET_LEFT, largeur STARTER_SHEET_WIDTH.

## CHOISIR touché (fiche ouverte).
signal choose_pressed
## RETOUR touché (fiche ouverte).
signal back_pressed
## Fin de l'animation de fermeture (la fiche est invisible).
signal closed

const BADGE_SCENE: PackedScene = preload("res://game/ui/components/type_badge.tscn")

var _open: bool = false
## Un bouton a déjà répondu depuis l'ouverture.
var _answered: bool = false
var _tween: Tween
var _press_tweens: Dictionary[Button, Tween] = {}

@onready var _root: Control = %Root
@onready var _card: PanelContainer = %Card
@onready var _content: VBoxContainer = %Content
@onready var _name_label: Label = %NameLabel
@onready var _types: HBoxContainer = %Types
@onready var _phrase: Label = %Phrase
@onready var _buttons: HBoxContainer = %Buttons
@onready var _back_button: Button = %BackButton
@onready var _choose_button: Button = %ChooseButton


func _ready() -> void:
	layer = UiTokens.LAYER_MENU
	_card.offset_left = UiTokens.STARTER_SHEET_LEFT
	_card.offset_right = UiTokens.STARTER_SHEET_LEFT + UiTokens.STARTER_SHEET_WIDTH
	_card.custom_minimum_size.x = UiTokens.STARTER_SHEET_WIDTH
	_content.add_theme_constant_override(&"separation", UiTokens.STARTER_SHEET_GAP)
	_types.add_theme_constant_override(&"separation", UiTokens.GAP)
	_buttons.add_theme_constant_override(&"separation", UiTokens.GAP)
	(%ButtonsGap as Control).custom_minimum_size.y = \
		UiTokens.STARTER_SHEET_BUTTONS_GAP - UiTokens.STARTER_SHEET_GAP
	for button: Button in [_back_button, _choose_button]:
		button.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN, UiTokens.TOUCH_MIN)
		button.focus_mode = Control.FOCUS_NONE
		button.button_down.connect(_press_feedback.bind(button, true))
		button.button_up.connect(_press_feedback.bind(button, false))
	_choose_button.pressed.connect(_on_button.bind(choose_pressed))
	_back_button.pressed.connect(_on_button.bind(back_pressed))
	_set_closed_state()


## Ouvre la fiche sur [param view] (nom, 1 ou 2 types, phrase). Déjà ouverte, elle change de
## contenu sans rejouer l'entrée. Une vue invalide est refusée (erreur), la fiche reste telle.
func open(view: StarterSheetView) -> void:
	if view == null or not view.is_valid():
		push_error("StarterSheet : vue invalide")
		return
	_fill(view)
	_answered = false
	if _open:
		return
	_open = true
	_kill_tween()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	# Rouverte pendant sa fermeture : elle revient depuis sa position courante.
	if not visible:
		offset = Vector2(-UiTokens.PANEL_SLIDE, 0.0)
		_card.modulate.a = 0.0
	visible = true
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"offset", Vector2.ZERO, UiTokens.ANIM_PANEL)
	_tween.parallel().tween_property(_card, ^"modulate:a", 1.0, UiTokens.ANIM_PANEL)


## Ferme la fiche : elle ressort vers la gauche en fondu (STARTER_SHEET_CLOSE), puis devient
## invisible et émet closed. Dès l'appel, elle n'émet plus rien. Sans effet si fermée.
func close() -> void:
	if not _open:
		return
	_open = false
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kill_tween()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, ^"offset", Vector2(-UiTokens.PANEL_SLIDE, 0.0),
		UiTokens.STARTER_SHEET_CLOSE)
	_tween.parallel().tween_property(_card, ^"modulate:a", 0.0, UiTokens.STARTER_SHEET_CLOSE)
	_tween.tween_callback(_on_closed)


func is_open() -> bool:
	return _open


func get_name_text() -> String:
	return _name_label.text


func get_phrase_label() -> Label:
	return _phrase


func get_badges() -> Array[TypeBadge]:
	var badges: Array[TypeBadge] = []
	for child: Node in _types.get_children():
		if child is TypeBadge and not child.is_queued_for_deletion():
			badges.append(child as TypeBadge)
	return badges


func get_card() -> PanelContainer:
	return _card


func get_choose_button() -> Button:
	return _choose_button


func get_back_button() -> Button:
	return _back_button


func _fill(view: StarterSheetView) -> void:
	_name_label.text = view.display_name.to_upper()
	_phrase.text = view.phrase
	_phrase.visible = not view.phrase.is_empty()
	for child: Node in _types.get_children():
		_types.remove_child(child)
		child.queue_free()
	for i: int in view.type_ids.size():
		var badge := BADGE_SCENE.instantiate() as TypeBadge
		badge.set_type(view.type_ids[i], view.type_names[i])
		_types.add_child(badge)
	# Hauteur recalculée par le conteneur ; ancrée au milieu, la carte grandit des deux côtés
	# (pas de reset_size, qui la ferait grandir vers le bas seulement).
	_card.offset_top = 0.0
	_card.offset_bottom = 0.0


func _on_button(sig: Signal) -> void:
	if not _open or _answered:
		return
	_answered = true
	Input.vibrate_handheld(UiTokens.HAPTIC_TAP_MS)
	sig.emit()


## Légère mise à l'échelle à l'appui (PRESSED_SCALE), retour au relâchement.
func _press_feedback(button: Button, down: bool) -> void:
	var previous: Tween = _press_tweens.get(button, null)
	if previous != null:
		previous.kill()
	button.pivot_offset = button.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target := Vector2.ONE * (UiTokens.PRESSED_SCALE if down else 1.0)
	tween.tween_property(button, ^"scale", target, UiTokens.ANIM_MICRO)
	_press_tweens[button] = tween


func _on_closed() -> void:
	_set_closed_state()
	closed.emit()


func _set_closed_state() -> void:
	visible = false
	offset = Vector2(-UiTokens.PANEL_SLIDE, 0.0)
	_card.modulate.a = 0.0
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for button: Button in [_back_button, _choose_button]:
		button.scale = Vector2.ONE


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
