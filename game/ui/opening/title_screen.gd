class_name TitleScreen
extends CanvasLayer
## Écran titre (OUV.1, dossier 13 §5.2–§5.4 ; composition de reference/ouverture-titre-v1.webp,
## qui ne fait foi ni pour le décor ni pour le logo, règle 10).
##
## Calque LAYER_MENU posé sur la vraie carte en mode décor ([TitleBackdrop], côté monde) :
## - logo « Kanto 2026 » détouré en haut à gauche, sans cadre ;
## - colonne de cartes à droite (à gauche en mode gaucher, [method set_left_handed], le logo passe
##   alors à droite) : **Continuer** (la plus grande : buste, prénom, lieu, temps de jeu, badges,
##   captures), **Nouvelle partie**, **Paramètres** ; l'entrée mise en avant porte un liseré doré ;
## - message d'état de la sauvegarde (corrompue, plus récente) sous la colonne ;
## - confirmation de nouvelle partie : le choix à deux cartes ([ChoiceCards]) ;
## - Paramètres : le même [SettingsScreen] que le Menu Dresseur, sur le titre flouté.
##
## Vue pure : il affiche un [TitleMenuModel] (et son [SaveSummary]) et relaie les touchers par
## signaux ; c'est l'[OpeningDirector] qui décide. Retour Android : géré par le directeur
## ([method is_settings_open], [method is_confirm_open]).

## Une entrée touchée ([constant TitleMenuModel.ENTRY_CONTINUE]…), un seul signal par toucher.
signal entry_chosen(entry: StringName)
## Carte de confirmation : vrai = « Nouvelle partie », faux = « Annuler ».
signal confirm_chosen(confirmed: bool)
## « ‹ » des Paramètres.
signal settings_back_requested
## Un réglage change dans les Paramètres (valeur du réglage).
signal setting_changed(key: StringName, value: Variant)

const LOGO: Texture2D = preload("res://assets/ui/opening/logo_kanto_2026.png")
const BUST: Texture2D = preload("res://assets/ui/menu/hero_bust.webp")
const NEW_GAME_ICON: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")
const SETTINGS_ICON: Texture2D = preload("res://assets/ui/icons/menu/settings.svg")
const CHEVRON_ICON: Texture2D = preload("res://assets/ui/icons/menu/chevron.svg")
const CLOCK_ICON: Texture2D = preload("res://assets/ui/icons/menu/clock.svg")
const BADGE_ICON: Texture2D = preload("res://assets/ui/icons/trainer/badge_slot.svg")
const CAUGHT_ICON: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")
const BACKDROP_SHADER: Shader = preload("res://game/ui/menu/menu_backdrop.gdshader")
const ENTRY_ICONS: Dictionary[StringName, Texture2D] = {
	TitleMenuModel.ENTRY_NEW_GAME: NEW_GAME_ICON,
	TitleMenuModel.ENTRY_SETTINGS: SETTINGS_ICON,
}

## Durées multipliées (0 = instantané, pour les tests).
var speed_scale: float = 1.0:
	set(value):
		speed_scale = value
		if _confirm != null:
			_confirm.speed_scale = value
		if _settings != null:
			_settings.speed_scale = value

var _model: TitleMenuModel
var _left_handed: bool = false
var _root: Control
var _logo: TextureRect
var _column: VBoxContainer
var _buttons: Dictionary[StringName, Button] = {}
var _message: PanelContainer
var _message_label: Label
var _confirm: ChoiceCards
var _settings_layer: Control
var _settings_backdrop: ColorRect
var _settings: SettingsScreen
var _blur_enabled: bool = true


func _ready() -> void:
	layer = UiTokens.LAYER_MENU
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_logo = TextureRect.new()
	_logo.name = "Logo"
	_logo.texture = LOGO
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_logo)
	_column = VBoxContainer.new()
	_column.name = "Column"
	_column.alignment = BoxContainer.ALIGNMENT_CENTER
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_theme_constant_override(&"separation", UiTokens.TITLE_COLUMN_GAP)
	_root.add_child(_column)
	_message = PanelContainer.new()
	_message.name = "Message"
	_message.theme_type_variation = &"TitleMessage"
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message_label = Label.new()
	_message_label.theme_type_variation = &"TitleMessageText"
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message.add_child(_message_label)
	_confirm = ChoiceCards.new()
	_confirm.name = "Confirm"
	_confirm.speed_scale = speed_scale
	_confirm.chosen.connect(confirm_chosen.emit)
	_root.add_child(_confirm)
	_build_settings_layer()
	_layout()
	if _model != null:
		_rebuild()


## Affiche [param model] : entrées, mise en avant, carte Continuer, message.
func show_title(model: TitleMenuModel) -> void:
	_model = model
	if _root != null:
		_rebuild()


## Mode gaucher : colonne à gauche, logo à droite (dossier 13 §7).
func set_left_handed(left_handed: bool) -> void:
	_left_handed = left_handed
	if _root != null:
		_layout()


## Flou du fond des Paramètres (graphismes « Économie » : voile seul, comme le Menu Dresseur).
func set_backdrop_blur(enabled: bool) -> void:
	_blur_enabled = enabled
	if _settings_backdrop != null:
		(_settings_backdrop.material as ShaderMaterial).set_shader_parameter(&"blur_on", enabled)


## Carte de confirmation de nouvelle partie (§5.4).
func show_confirm(view: ChoiceView) -> void:
	_confirm.show_choice(view)


func hide_confirm() -> void:
	if _confirm.is_showing():
		_confirm.hide_choice()


func is_confirm_open() -> bool:
	return _confirm != null and _confirm.is_showing()


## Paramètres (§5.3) : ouvre l'écran sur le titre flouté, ou le met à jour s'il est ouvert (la
## catégorie ouverte reste).
func show_settings(view: SettingsView) -> void:
	_settings.show_settings(view)
	UiPrefsApplier.apply(_settings)
	if _settings_layer.visible:
		return
	_settings_layer.visible = true
	_column.visible = false
	_settings.enter()


func hide_settings() -> void:
	if not _settings_layer.visible:
		return
	_settings_layer.visible = false
	_settings.hide_now()
	_column.visible = true


func is_settings_open() -> bool:
	return _settings_layer != null and _settings_layer.visible


func get_entry_button(entry: StringName) -> Button:
	return _buttons.get(entry)


## Entrées affichées, de haut en bas.
func get_entries() -> Array[StringName]:
	var entries: Array[StringName] = []
	entries.assign(_buttons.keys())
	return entries


## Entrée mise en avant (liseré doré).
func get_featured() -> StringName:
	for entry: StringName in _buttons:
		if _buttons[entry].theme_type_variation == &"TitleCardFeatured":
			return entry
	return &""


func get_message_text() -> String:
	return _message_label.text if _message.visible and _message.is_inside_tree() else ""


func get_logo() -> TextureRect:
	return _logo


func get_column() -> VBoxContainer:
	return _column


func get_confirm() -> ChoiceCards:
	return _confirm


func get_settings() -> SettingsScreen:
	return _settings


func get_settings_backdrop() -> ColorRect:
	return _settings_backdrop


## Tous les textes visibles du titre (hors Paramètres et confirmation), dans l'ordre de l'arbre.
func get_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	_collect_texts(_column, texts)
	return texts


func _build_settings_layer() -> void:
	_settings_layer = Control.new()
	_settings_layer.name = "SettingsLayer"
	_settings_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_layer.visible = false
	_root.add_child(_settings_layer)
	_settings_backdrop = ColorRect.new()
	_settings_backdrop.name = "Backdrop"
	_settings_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = BACKDROP_SHADER
	material.set_shader_parameter(&"amount", 1.0)
	material.set_shader_parameter(&"blur_radius", UiTokens.MENU_GLASS_BLUR)
	material.set_shader_parameter(&"blur_lod", UiTokens.MENU_GLASS_LOD)
	material.set_shader_parameter(&"blur_on", _blur_enabled)
	material.set_shader_parameter(&"dim", UiTokens.TITLE_SETTINGS_DIM)
	material.set_shader_parameter(&"dim_color", UiTokens.SURFACE_DARK)
	_settings_backdrop.material = material
	_settings_layer.add_child(_settings_backdrop)
	# Même zone que l'hôte du Menu Dresseur : l'écran est identique à celui du menu.
	var host := Control.new()
	host.name = "Host"
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.offset_left = UiTokens.SAFE_MARGIN
	host.offset_right = -UiTokens.SAFE_MARGIN
	host.offset_top = UiTokens.MENU_BODY_TOP
	host.offset_bottom = -UiTokens.SAFE_MARGIN
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settings_layer.add_child(host)
	_settings = SettingsScreen.new()
	_settings.speed_scale = speed_scale
	_settings.back_requested.connect(settings_back_requested.emit)
	_settings.setting_changed.connect(setting_changed.emit)
	host.add_child(_settings)
	_settings.hide_now()


## Logo et colonne selon la main : logo en haut du côté opposé à la colonne.
func _layout() -> void:
	var logo_size := Vector2(UiTokens.TITLE_LOGO_WIDTH,
		UiTokens.TITLE_LOGO_WIDTH * LOGO.get_height() / float(LOGO.get_width()))
	var margin := float(UiTokens.SAFE_MARGIN)
	var width := float(UiTokens.TITLE_COLUMN_WIDTH)
	var logo_side := 1.0 if _left_handed else 0.0
	_logo.anchor_left = logo_side
	_logo.anchor_right = logo_side
	_logo.anchor_top = 0.0
	_logo.anchor_bottom = 0.0
	_logo.offset_left = -margin - logo_size.x if _left_handed else margin
	_logo.offset_right = _logo.offset_left + logo_size.x
	_logo.offset_top = margin
	_logo.offset_bottom = margin + logo_size.y
	var column_side := 0.0 if _left_handed else 1.0
	_column.anchor_left = column_side
	_column.anchor_right = column_side
	_column.anchor_top = 0.0
	_column.anchor_bottom = 1.0
	_column.offset_left = margin if _left_handed else -margin - width
	_column.offset_right = _column.offset_left + width
	_column.offset_top = margin
	_column.offset_bottom = -margin


func _rebuild() -> void:
	for child: Node in _column.get_children():
		_column.remove_child(child)
		if child != _message:
			child.queue_free()
	_buttons.clear()
	for entry: StringName in _model.entries:
		var button: Button
		if entry == TitleMenuModel.ENTRY_CONTINUE:
			button = _make_continue_card(_model.summary)
		else:
			button = _make_entry_card(entry)
		button.theme_type_variation = &"TitleCardFeatured" if entry == _model.featured \
			else &"TitleCard"
		button.pressed.connect(_on_entry_pressed.bind(entry))
		_column.add_child(button)
		_buttons[entry] = button
	_message_label.text = _model.message
	if not _model.message.is_empty():
		_column.add_child(_message)
	UiPrefsApplier.apply(_root)


## Carte Continuer : buste à gauche ; « CONTINUER », prénom, lieu, filet, puis temps de jeu,
## badges et captures (lignes vides omises : jamais « 0 badge », captures seulement avec le
## Pokédex activé).
func _make_continue_card(summary: SaveSummary) -> Button:
	var card := _card_button(UiTokens.TITLE_CONTINUE_BUST.y)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.PAD)
	_fill(card, row)
	var bust := TextureRect.new()
	bust.name = "Bust"
	bust.texture = BUST
	bust.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bust.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bust.custom_minimum_size = UiTokens.TITLE_CONTINUE_BUST
	bust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bust)
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override(&"separation", UiTokens.TITLE_CONTINUE_LINE_GAP)
	row.add_child(texts)
	var title := _label(&"TitleContinueTitle", _model.labels.get(TitleMenuModel.ENTRY_CONTINUE,
		""))
	title.uppercase = true
	texts.add_child(title)
	if summary == null:
		return card
	texts.add_child(_label(&"TitleContinueName", summary.player_name))
	if not summary.zone_name.is_empty():
		texts.add_child(_label(&"TitleContinueZone", summary.zone_name))
	var divider := Panel.new()
	divider.theme_type_variation = &"TitleDivider"
	divider.custom_minimum_size.y = UiTokens.BORDER_WIDTH
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(divider)
	for line: Array in [[CLOCK_ICON, summary.play_time_text()],
			[BADGE_ICON, summary.badges_text()], [CAUGHT_ICON, summary.caught_text()]]:
		if not (line[1] as String).is_empty():
			texts.add_child(_stat_line(line[0], line[1]))
	return card


## Carte secondaire : icône, libellé en capitales, chevron « › ».
func _make_entry_card(entry: StringName) -> Button:
	var card := _card_button(UiTokens.TITLE_ENTRY_HEIGHT - UiTokens.TITLE_CARD_PAD_V * 2)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.PAD)
	_fill(card, row)
	row.add_child(_icon(ENTRY_ICONS.get(entry), UiTokens.TITLE_ENTRY_ICON))
	var label := _label(&"TitleEntryLabel", _model.labels.get(entry, ""))
	label.uppercase = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	row.add_child(_icon(CHEVRON_ICON, UiTokens.TITLE_CHEVRON))
	return card


## Bouton de carte : au moins [param content_height] de contenu (plus les marges), et autant que
## son contenu le demande (taille du texte « Grande »).
func _card_button(content_height: float) -> Button:
	var card := Button.new()
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = Vector2(0.0, content_height + UiTokens.TITLE_CARD_PAD_V * 2)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return card


## Pose [param content] dans [param card] aux marges de la carte ; la carte grandit avec lui.
func _fill(card: Button, content: Control) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override(&"margin_left", UiTokens.TITLE_CARD_PAD_H)
	margin.add_theme_constant_override(&"margin_right", UiTokens.TITLE_CARD_PAD_H)
	margin.add_theme_constant_override(&"margin_top", UiTokens.TITLE_CARD_PAD_V)
	margin.add_theme_constant_override(&"margin_bottom", UiTokens.TITLE_CARD_PAD_V)
	card.add_child(margin)
	margin.add_child(content)
	card.set_meta(&"floor_height", card.custom_minimum_size.y)
	margin.minimum_size_changed.connect(_fit_card.bind(card, margin))
	_fit_card.call_deferred(card, margin)


## Hauteur de la carte : au moins son plancher, et tout son contenu (un Button ne grandit pas
## avec ses enfants).
func _fit_card(card: Button, margin: MarginContainer) -> void:
	if not is_instance_valid(card) or not is_instance_valid(margin):
		return
	var floor_height: float = card.get_meta(&"floor_height", 0.0)
	card.custom_minimum_size.y = maxf(floor_height, margin.get_combined_minimum_size().y)


func _stat_line(icon: Texture2D, text: String) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override(&"separation", UiTokens.GAP)
	line.add_child(_icon(icon, UiTokens.TITLE_CONTINUE_STAT_ICON))
	var label := _label(&"TitleContinueStat", text)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Rognée avec « … » : sans largeur demandée, elle n'en aurait aucune dans la ligne.
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(label)
	return line


func _label(variation: StringName, text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


func _icon(texture: Texture2D, side: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * side
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _on_entry_pressed(entry: StringName) -> void:
	if is_settings_open() or is_confirm_open():
		return
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	entry_chosen.emit(entry)


func _collect_texts(node: Node, into: PackedStringArray) -> void:
	for child: Node in node.get_children():
		if child.is_queued_for_deletion():
			continue
		var label := child as Label
		if label != null and label.is_visible_in_tree() and not label.text.is_empty():
			into.append(label.text.to_upper() if label.uppercase else label.text)
		_collect_texts(child, into)
