class_name SettingsScreen
extends MenuScreen
## Écran Paramètres du Menu Dresseur (dossier 08 §7 ; jalon-06.md §6.12 ; maquette
## menu-parametres-v1.jpg pour la DA seulement, règle 10), recomposé en paysage : catégories à
## gauche (JEU, COMMANDES, ACCESSIBILITÉ, GRAPHISMES), contrôles de la catégorie ouverte à droite.
##
## Il reçoit un [SettingsView] et n'en sait rien d'autre : il **n'invente pas l'état**. Un geste
## émet un signal ; la nouvelle valeur ne s'affiche que quand [method show_settings] revient avec
## la vue reconstruite.
## - Interrupteur : [signal setting_changed] (clé, contraire de la valeur).
## - Choix : [signal setting_changed] (clé, valeur de l'option) ; l'option déjà choisie : rien.
## - Curseur : un [signal setting_changed] au lâcher, valeur sur un cran.
## - Action « Sauvegarder maintenant » active : un [signal save_now_requested] ; inactive : rien
##   (sa raison est écrite dans la ligne). Le résultat arrive par [method show_save_result].
## - RETOUR : [signal back_requested].
## Placement : rempli par [TrainerMenu] sous l'en-tête, marges de SAFE_MARGIN.

## Un réglage change : [param value] est la valeur du réglage (booléen, entier d'enum, flottant).
signal setting_changed(key: StringName, value: Variant)
## « Sauvegarder maintenant » touché (action active).
signal save_now_requested

const TITLE := "Paramètres"
const BACK_TEXT := "RETOUR"
const BACK_ICON: Texture2D = preload("res://assets/ui/icons/battle/back.svg")
const SAVE_ICON: Texture2D = preload("res://assets/ui/icons/settings/save.svg")
const CATEGORY_ICONS: Dictionary[StringName, Texture2D] = {
	SettingsViews.CATEGORY_GAME: preload("res://assets/ui/icons/settings/game.svg"),
	SettingsViews.CATEGORY_CONTROLS: preload("res://assets/ui/icons/settings/controls.svg"),
	SettingsViews.CATEGORY_ACCESSIBILITY:
		preload("res://assets/ui/icons/settings/accessibility.svg"),
	SettingsViews.CATEGORY_GRAPHICS: preload("res://assets/ui/icons/settings/graphics.svg"),
}

var _view: SettingsView
var _built: bool = false
var _selected: StringName = &""
var _back: Button
var _category_box: VBoxContainer
var _category_buttons: Dictionary[StringName, Button] = {}
var _category_group := ButtonGroup.new()
var _panel_title: Label
var _scroll: ScrollContainer
var _rows_box: VBoxContainer
## Contrôles de la catégorie ouverte, par clé.
var _rows: Dictionary[StringName, Control] = {}
var _result_bar: PanelContainer
var _result_text: Label
var _result_tween: Tween


func _ready() -> void:
	super()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.GAP)
	add_child(column)
	_build_header(column)
	var body := HBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", UiTokens.GAP)
	column.add_child(body)
	body.add_child(_build_categories())
	body.add_child(_build_content())
	_built = true
	if _view != null:
		_apply(_view)


## Affiche [param view]. Rappelé pendant que l'écran est affiché, il met à jour **sans rejouer
## l'entrée** : la catégorie ouverte et le défilement sont gardés.
func show_settings(view: SettingsView) -> void:
	_view = view
	if _built:
		_apply(view)


## Message bref sous les contrôles (« Partie sauvegardée ») ; il s'efface après
## SETTINGS_RESULT_HOLD (jamais à speed_scale = 0, pour les tests). Texte vide : efface.
func show_save_result(text: String) -> void:
	if not _built:
		return
	if _result_tween != null:
		_result_tween.kill()
		_result_tween = null
	_result_text.text = text
	_result_bar.visible = not text.is_empty()
	_result_bar.modulate.a = 1.0
	UiPrefsApplier.apply(_result_bar)
	if text.is_empty() or speed_scale <= 0.0:
		return
	_result_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_result_tween.tween_interval(UiTokens.SETTINGS_RESULT_HOLD * speed_scale)
	_result_tween.tween_property(_result_bar, ^"modulate:a", 0.0,
		UiTokens.SETTINGS_FADE * speed_scale)
	_result_tween.tween_callback(_result_bar.hide)


## Ouvre la catégorie [param id] (sans geste : la vue la garde aux mises à jour suivantes).
func select_category(id: StringName) -> void:
	if _view == null or _view.category(id) == null:
		return
	_selected = id
	_apply(_view)


func get_selected_category() -> StringName:
	return _selected


func get_back_button() -> Button:
	return _back


func get_category_buttons() -> Dictionary[StringName, Button]:
	return _category_buttons


## Contrôle (ligne) de la catégorie ouverte pour [param key] : SettingToggle, SettingChoice,
## SettingSlider ou le bouton de l'action ; null s'il n'est pas dans la catégorie ouverte.
func get_row(key: StringName) -> Control:
	return _rows.get(key)


## Bouton de l'action « Sauvegarder maintenant » (null hors de la catégorie JEU).
func get_action_button() -> Button:
	var row: Control = _rows.get(SettingsViews.SAVE_NOW)
	if row == null:
		return null
	return row.find_child("Action", true, false) as Button


func get_scroll() -> ScrollContainer:
	return _scroll


func get_result_label() -> Label:
	return _result_text


func get_result_bar() -> PanelContainer:
	return _result_bar


func get_panel_title() -> Label:
	return _panel_title


## Tous les textes visibles de l'écran, dans l'ordre de l'arbre.
func get_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	_collect_texts(self, texts)
	return texts


## Tous les contrôles qui répondent au toucher (boutons visibles et actifs, pistes de curseur) :
## pour vérifier les tailles et les marges.
func get_touch_controls() -> Array[Control]:
	var found: Array[Control] = []
	_collect_touch(self, found)
	return found


func _build_header(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size.y = UiTokens.TRAINER_HEADER_HEIGHT
	row.add_theme_constant_override(&"separation", UiTokens.GAP)
	parent.add_child(row)
	_back = Button.new()
	_back.theme_type_variation = &"PanelButton"
	_back.text = BACK_TEXT
	_back.icon = BACK_ICON
	_back.focus_mode = Control.FOCUS_NONE
	_back.custom_minimum_size = Vector2(UiTokens.TRAINER_BACK_WIDTH, UiTokens.TOUCH_MIN)
	_back.pressed.connect(_on_back)
	row.add_child(_back)
	var title := Label.new()
	title.theme_type_variation = &"DexTitle"
	title.text = TITLE
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title)


func _build_categories() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"MenuPanel"
	panel.custom_minimum_size.x = UiTokens.SETTINGS_CATEGORY_WIDTH
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_category_box = VBoxContainer.new()
	_category_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_category_box.add_theme_constant_override(&"separation", UiTokens.SETTINGS_CATEGORY_GAP)
	panel.add_child(_category_box)
	return panel


func _build_content() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"MenuPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.GAP)
	panel.add_child(column)
	_panel_title = Label.new()
	_panel_title.theme_type_variation = &"SettingsPanelTitle"
	_panel_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Le nom de la catégorie est déjà dans la liste de gauche : la place va aux contrôles.
	_panel_title.visible = false
	column.add_child(_panel_title)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_scroll)
	_rows_box = VBoxContainer.new()
	_rows_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_box.add_theme_constant_override(&"separation", UiTokens.SETTINGS_ROW_GAP)
	_scroll.add_child(_rows_box)
	_result_bar = PanelContainer.new()
	_result_bar.theme_type_variation = &"ResultBar"
	_result_bar.custom_minimum_size.y = UiTokens.SETTINGS_RESULT_HEIGHT
	_result_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_bar.visible = false
	column.add_child(_result_bar)
	_result_text = Label.new()
	_result_text.theme_type_variation = &"ResultText"
	_result_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_result_bar.add_child(_result_text)
	return panel


func _apply(view: SettingsView) -> void:
	if view.categories.is_empty():
		return
	if view.category(_selected) == null:
		_selected = view.categories[0].id
	_sync_categories(view)
	var category := view.category(_selected)
	_panel_title.text = category.title
	_sync_rows(category)
	UiPrefsApplier.apply(self)


## Les boutons de catégorie suivent la vue (reconstruits seulement si les identifiants changent).
func _sync_categories(view: SettingsView) -> void:
	var same := _category_buttons.size() == view.categories.size()
	if same:
		var i := 0
		for id: StringName in _category_buttons:
			same = same and view.categories[i].id == id
			i += 1
	if not same:
		for button: Button in _category_buttons.values():
			_category_box.remove_child(button)
			button.queue_free()
		_category_buttons.clear()
		for item: SettingsCategoryView in view.categories:
			var button := Button.new()
			button.theme_type_variation = &"SettingsCategory"
			button.toggle_mode = true
			button.button_group = _category_group
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.icon = CATEGORY_ICONS.get(item.id)
			button.focus_mode = Control.FOCUS_NONE
			button.custom_minimum_size = Vector2(0.0, UiTokens.TOUCH_MIN)
			button.pressed.connect(_on_category_pressed.bind(item.id))
			_category_box.add_child(button)
			_category_buttons[item.id] = button
	for item: SettingsCategoryView in view.categories:
		var button := _category_buttons[item.id]
		button.text = item.title
		button.set_pressed_no_signal(item.id == _selected)


## Les lignes de la catégorie ouverte : mises à jour en place si ce sont les mêmes contrôles
## (l'interrupteur glisse, le défilement reste), sinon reconstruites.
func _sync_rows(category: SettingsCategoryView) -> void:
	var same := _rows.size() == category.controls.size()
	if same:
		for item: SettingControlView in category.controls:
			var row: Control = _rows.get(item.key)
			same = same and row != null and _row_kind(row) == item.kind
	if not same:
		for child: Node in _rows_box.get_children():
			_rows_box.remove_child(child)
			child.queue_free()
		_rows.clear()
		_scroll.scroll_vertical = 0
		for item: SettingControlView in category.controls:
			var row := _make_row(item)
			_rows_box.add_child(row)
			_rows[item.key] = row
	for item: SettingControlView in category.controls:
		_setup_row(_rows[item.key], item, same)


func _make_row(item: SettingControlView) -> Control:
	match item.kind:
		SettingControlView.Kind.TOGGLE:
			var toggle := SettingToggle.new()
			toggle.speed_scale = speed_scale
			toggle.changed.connect(setting_changed.emit)
			return toggle
		SettingControlView.Kind.CHOICE:
			var choice := SettingChoice.new()
			choice.changed.connect(setting_changed.emit)
			return choice
		SettingControlView.Kind.SLIDER:
			var slider := SettingSlider.new()
			slider.changed.connect(setting_changed.emit)
			return slider
	return _make_action_row()


func _row_kind(row: Control) -> SettingControlView.Kind:
	if row is SettingToggle:
		return SettingControlView.Kind.TOGGLE
	if row is SettingChoice:
		return SettingControlView.Kind.CHOICE
	if row is SettingSlider:
		return SettingControlView.Kind.SLIDER
	return SettingControlView.Kind.ACTION


func _setup_row(row: Control, item: SettingControlView, animate: bool) -> void:
	match item.kind:
		SettingControlView.Kind.TOGGLE:
			(row as SettingToggle).speed_scale = speed_scale
			(row as SettingToggle).setup(item, animate)
		SettingControlView.Kind.CHOICE:
			(row as SettingChoice).setup(item)
		SettingControlView.Kind.SLIDER:
			(row as SettingSlider).setup(item)
		_:
			_setup_action(row, item)


## Ligne de l'action : texte (libellé, raison si inactive) à gauche, bouton d'accent à droite.
func _make_action_row() -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"SettingsRowBox"
	panel.custom_minimum_size = Vector2(0.0, UiTokens.SETTINGS_ROW_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.GAP)
	panel.add_child(row)
	var texts := VBoxContainer.new()
	texts.name = "Texts"
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override(&"separation", 0)
	row.add_child(texts)
	for variation: StringName in [&"SettingsLabel", &"SettingsDetail"]:
		var label := Label.new()
		label.theme_type_variation = variation
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = UiTokens.SETTINGS_TEXT_MIN_WIDTH
		texts.add_child(label)
	var button := Button.new()
	button.name = "Action"
	button.theme_type_variation = &"SettingsAction"
	button.icon = SAVE_ICON
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.custom_minimum_size = Vector2(UiTokens.SETTINGS_ACTION_WIDTH, UiTokens.TOUCH_MIN)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(_on_action_pressed)
	row.add_child(button)
	return panel


func _setup_action(row: Control, item: SettingControlView) -> void:
	var texts := row.find_child("Texts", true, false)
	var label := texts.get_child(0) as Label
	var detail := texts.get_child(1) as Label
	label.text = item.label
	detail.text = item.detail
	detail.visible = not item.detail.is_empty()
	var button := row.find_child("Action", true, false) as Button
	button.text = item.label.to_upper()
	button.disabled = not item.enabled


func _on_back() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	back_requested.emit()


func _on_category_pressed(id: StringName) -> void:
	if id == _selected or _view == null:
		return
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	_selected = id
	_apply(_view)


func _on_action_pressed() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	save_now_requested.emit()


func _collect_texts(node: Node, into: PackedStringArray) -> void:
	for child: Node in node.get_children():
		if child.is_queued_for_deletion():
			continue
		var label := child as Label
		if label != null and label.is_visible_in_tree() and not label.text.is_empty():
			into.append(label.text)
		var button := child as Button
		if button != null and button.is_visible_in_tree() and not button.text.is_empty():
			into.append(button.text)
		_collect_texts(child, into)


func _collect_touch(node: Node, into: Array[Control]) -> void:
	for child: Node in node.get_children():
		if child.is_queued_for_deletion():
			continue
		var button := child as BaseButton
		var track := child as SettingSliderTrack
		if button != null and button.is_visible_in_tree() and not button.disabled:
			into.append(button)
		elif track != null and track.is_visible_in_tree() and track.enabled:
			into.append(track)
		_collect_touch(child, into)
