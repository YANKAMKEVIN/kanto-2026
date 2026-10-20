class_name ElevatorPanel
extends CanvasLayer
## Panneau d'étages de l'ascenseur (jalon 20 T14, `docs/tech/jalon-20.md` §2.3.4) : voile, panneau
## centré (titre, une carte par étage, FERMER), étage courant grisé. Jetons de `ui_tokens.gd`,
## thème global (`MenuPanel`, `PanelButton`), cartes de 128 px de haut, marge de bord 48 px.
##
## Interface (inchangée depuis T13) :
## - [method open] (vue [ElevatorPanelView]), [method close], [method is_open] ;
## - [signal floor_chosen] (un étage touché, jamais le courant) et [signal closed] (FERMER).
## Le retour Android ne passe pas par l'écran : [ElevatorDirector] appelle [method close].
## L'écran ne décide rien (pas de règle, pas de clé) : il affiche et relaie.

## Un étage a été touché (jamais l'étage courant, désactivé).
signal floor_chosen(floor_id: StringName)
## FERMER a été touché.
signal closed

## « Réduire les animations » : ouverture et fermeture sans glissement ni fondu.
var reduce_motion: bool = false

var _root: Control
var _scrim: ColorRect
var _panel: PanelContainer
var _slide: MarginContainer
var _content: VBoxContainer
var _title: Label
var _grid: GridContainer
var _close_button: Button
var _view: ElevatorPanelView
var _open: bool = false
var _tween: Tween


func _ready() -> void:
	layer = UiTokens.LAYER_MENU
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_scrim = ColorRect.new()
	_scrim.name = "Scrim"
	_scrim.color = UiTokens.ELEVATOR_SCRIM
	_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_scrim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, UiTokens.SAFE_MARGIN)
	_root.add_child(margin)
	_slide = margin
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(center)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.theme_type_variation = &"MenuPanel"
	center.add_child(_panel)
	var pad := MarginContainer.new()
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		pad.add_theme_constant_override(side, UiTokens.ELEVATOR_PAD)
	_panel.add_child(pad)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override(&"separation", UiTokens.ELEVATOR_CARD_GAP)
	pad.add_child(_content)
	_title = Label.new()
	_title.name = "Title"
	_title.theme_type_variation = &"MenuScreenTitle"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_title)
	_grid = GridContainer.new()
	_grid.name = "Floors"
	_grid.add_theme_constant_override(&"h_separation", UiTokens.ELEVATOR_CARD_GAP)
	_grid.add_theme_constant_override(&"v_separation", UiTokens.ELEVATOR_CARD_GAP)
	_content.add_child(_grid)
	_close_button = Button.new()
	_close_button.name = "Close"
	_close_button.theme_type_variation = &"AccentButton"
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
	_close_button.pressed.connect(_on_close_pressed)
	_content.add_child(_close_button)
	visible = false


## Montre [param view] : un bouton par étage (l'étage courant désactivé), puis FERMER.
func open(view: ElevatorPanelView) -> void:
	_view = view
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_title.text = view.title
	_close_button.text = view.close_label
	_grid.columns = 1 if view.floors.size() <= UiTokens.ELEVATOR_SINGLE_COLUMN_MAX \
		else UiTokens.ELEVATOR_COLUMNS
	for entry: Dictionary in view.floors:
		_grid.add_child(_floor_card(entry))
	UiPrefsApplier.apply(_root)
	_open = true
	visible = true
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_animate(true)


func close() -> void:
	_open = false
	_view = null
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_animate(false)


func is_open() -> bool:
	return _open


## Vue affichée (null panneau fermé).
func get_view() -> ElevatorPanelView:
	return _view


## Carte d'un étage (tests et captures) ; null si l'identifiant n'est pas affiché.
func get_floor_button(floor_id: StringName) -> Button:
	return _grid.get_node_or_null("Floor_%s" % floor_id) as Button


func get_close_button() -> Button:
	return _close_button


func get_title_label() -> Label:
	return _title


## Colonnes de la grille d'étages.
func get_columns() -> int:
	return _grid.columns


func _floor_card(entry: Dictionary) -> Button:
	var button := Button.new()
	button.name = "Floor_%s" % entry["id"]
	button.theme_type_variation = &"PanelButton"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = UiTokens.ELEVATOR_CARD_SIZE
	button.text = String(entry["label"])
	button.add_theme_font_size_override(&"font_size", UiTokens.ELEVATOR_CARD_FONT)
	var floor_id: StringName = entry["id"]
	if entry["current"]:
		button.disabled = true
		var here := button.get_theme_stylebox(&"normal").duplicate() as StyleBoxFlat
		here.bg_color = UiTokens.ELEVATOR_HERE_BG
		button.add_theme_stylebox_override(&"disabled", here)
		button.add_theme_color_override(&"font_disabled_color", UiTokens.TEXT_DISABLED)
	else:
		button.pressed.connect(_on_floor_pressed.bind(floor_id))
	return button


func _on_floor_pressed(floor_id: StringName) -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	floor_chosen.emit(floor_id)


func _on_close_pressed() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	closed.emit()


## Ouverture (fondu + glissement de 40 px) ou fermeture (fondu court) ; instantanée avec
## « Réduire les animations ».
func _animate(opening: bool) -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	var time := UiTokens.ELEVATOR_FADE if opening else UiTokens.ANIM_MICRO
	if reduce_motion or time <= 0.0 or not is_inside_tree():
		_set_shown(1.0 if opening else 0.0)
		if not opening:
			visible = false
		return
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_OUT if opening else Tween.EASE_IN)
	var from := 0.0 if opening else 1.0
	_set_shown(from)
	_tween.tween_method(_set_shown, from, 1.0 if opening else 0.0, time)
	if not opening:
		_tween.tween_callback(func() -> void: visible = false)


## [param amount] : 0 (invisible, panneau décalé) à 1 (pleinement affiché).
func _set_shown(amount: float) -> void:
	_root.modulate.a = amount
	_slide.position.y = (1.0 - amount) * UiTokens.ELEVATOR_SLIDE
