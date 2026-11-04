class_name TeamReturnOverlay
extends TmLearnOverlay
## L'écran du choix des 6 au retour de l'équipe (JH-24 ; `jalon-joh0.md` §2.2) : un voile
## au-dessus du monde, un panneau avec la liste des Pokémon de la réserve (équipe de Johto puis
## équipe confisquée, 12 au plus), une case par Pokémon (bouton à bascule : nom, niveau,
## provenance), le compteur « n / 6 » et VALIDER, permis seulement quand le choix l'est
## ([method TeamReturnSelection.can_confirm]). Pas de retour Android : le choix est obligatoire
## (le retour est avalé, [method handle_back]). Aucune règle ici : tout vient de
## [TeamReturnSelection]. Visuels provisoires (règle 3) ; DA en phase DA.

## Le joueur a validé : les identifiants gardés, dans l'ordre de touche.
signal confirmed(kept: Array[String])

## Titre et textes [D].
const TITLE_TEXT := "Choisis les 6 qui t'accompagnent"
const COUNT_FORMAT := "%d / %d"
const CONFIRM_TEXT := "VALIDER"
const SOURCE_TEXTS: Dictionary[TeamReturnSelection.Source, String] = {
	TeamReturnSelection.Source.JOHTO: "Johto", TeamReturnSelection.Source.KANTO: "Kanto",
}
const ROW_FORMAT := "%s   ·   %s"
## Dimensions du panneau [D] : la largeur du sélecteur de l'équipe, la hauteur de l'écran moins
## les marges sûres.
const PANEL_HEIGHT := 1080 - 2 * UiTokens.SAFE_MARGIN - UiTokens.TOUCH_MIN

var _panel: PanelContainer
var _title: Label
var _count: Label
var _list: VBoxContainer
var _confirm: Button
var _buttons: Array[Button] = []
var _selection: TeamReturnSelection
var _labels: Array[String] = []


func _ready() -> void:
	super()
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.theme_type_variation = &"MenuPanel"
	var size := Vector2(BattleHudLayout.picker_size().x, PANEL_HEIGHT)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -size.x * 0.5
	_panel.offset_right = size.x * 0.5
	_panel.offset_top = -size.y * 0.5
	_panel.offset_bottom = size.y * 0.5
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.visible = false
	_root.add_child(_panel)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override(&"separation", UiTokens.PICKER_GAP)
	_panel.add_child(column)
	var header := HBoxContainer.new()
	header.name = "Header"
	column.add_child(header)
	_title = Label.new()
	_title.name = "Title"
	_title.theme_type_variation = &"PickerTitle"
	_title.text = TITLE_TEXT
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_count = Label.new()
	_count.name = "Count"
	_count.theme_type_variation = &"PickerTitle"
	header.add_child(_count)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Défilement au doigt par-dessus les boutons (QA A17 du 2026-11-04 : sans zone morte ni
	# garde, la liste ne défilait pas et les lignes 5 à 7 restaient hors d'atteinte).
	scroll.scroll_deadzone = roundi(UiTokens.TAP_SLOP)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override(&"separation", UiTokens.PICKER_GAP)
	scroll.add_child(_list)
	_confirm = Button.new()
	_confirm.name = "Confirm"
	_confirm.theme_type_variation = &"AccentButton"
	_confirm.text = CONFIRM_TEXT
	_confirm.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
	_confirm.pressed.connect(_on_confirm_pressed)
	column.add_child(_confirm)


## Ouvre le choix sur [param selection] (sélection par défaut posée si elle est vide), avec
## [param labels] (une étiquette par ligne de la réserve, dans son ordre : nom et niveau, fournis
## par Boot ; l'écran ne lit pas les données) et attend VALIDER ; rend les identifiants gardés.
func pick(selection: TeamReturnSelection, labels: Array[String] = []) -> Array[String]:
	_selection = selection
	_labels = labels
	if selection.count() == 0:
		selection.select(selection.default_selection())
	_rebuild()
	_panel.visible = true
	open()
	var kept: Array[String] = await confirmed
	_panel.visible = false
	close()
	return kept


## Retour Android pendant le choix : avalé, le choix est obligatoire.
func handle_back() -> bool:
	return is_open()


func get_buttons() -> Array[Button]:
	return _buttons.duplicate()


func get_confirm_button() -> Button:
	return _confirm


func get_count_text() -> String:
	return _count.text


func get_selection() -> TeamReturnSelection:
	return _selection


func _rebuild() -> void:
	for button: Button in _buttons:
		button.queue_free()
	_buttons.clear()
	var uids := _selection.uids()
	for i: int in uids.size():
		var button := Button.new()
		button.name = "Row%d" % i
		button.theme_type_variation = &"PanelButton"
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		# Toucher ou défilement : le glissement atteint la liste, un appui court bascule.
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		TapGuard.attach(button)
		var label: String = _labels[i] if i < _labels.size() else uids[i]
		button.text = ROW_FORMAT % [label, SOURCE_TEXTS[_selection.source_of(i)]]
		button.toggled.connect(_on_row_toggled.bind(uids[i]))
		_list.add_child(button)
		_buttons.append(button)
	_refresh()


func _refresh() -> void:
	var uids := _selection.uids()
	for i: int in _buttons.size():
		_buttons[i].set_pressed_no_signal(_selection.is_selected(uids[i]))
	_count.text = COUNT_FORMAT % [_selection.count(), TeamReturnSelection.MAX_KEPT]
	_confirm.disabled = not _selection.can_confirm()


func _on_row_toggled(_pressed: bool, uid: String) -> void:
	_selection.toggle(uid)
	_refresh()


func _on_confirm_pressed() -> void:
	if _selection == null or not _selection.can_confirm():
		return
	confirmed.emit(_selection.kept())
