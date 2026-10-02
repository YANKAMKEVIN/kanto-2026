extends SceneTree
## Génère game/ui/theme/ui_theme.tres à partir de UiTokens (seule source du style).
##
##   godot --headless --path . -s res://tools/build_ui_theme.gd
##
## Variations de type (theme_type_variation) :
##   ZoneTitleName    Label   nom de zone, 44, gras, ombre portée
##   ZoneTitleRegion  Label   région, 24, TEXT_MUTED, ombre portée
##   DialogBox        PanelContainer  boîte de dialogue sombre translucide (bible UI/UX §3)
##   DialogSpeaker    Label   nom du locuteur, gras, DIALOG_SPEAKER
##   DialogText       Label   réplique, FONT_BODY, TEXT
##   DialogNarration  Label   narration (Examiner, Observer), italique, DIALOG_NARRATION
##   DialogContinue   Label   indicateur de suite « › », gras, ACCENT
##   InteractLabel    PanelContainer  pastille du verbe du bouton contextuel
##   InteractLabelText Label  verbe (PARLER…), gras, majuscules
##   WorldCaption     Label   légende posée sur le monde, 44, gras, ombre portée (sans fond)
##   StarterSheet     PanelContainer  carte sombre translucide de la fiche du starter
##   StarterSheetName Label   nom du Pokémon, 44, gras
##   StarterSheetPhrase Label phrase, FONT_BODY, italique
##   TypeBadge        PanelContainer  pastille de type (fond recoloré par type à l'usage)
##   TypeBadgeText    Label   nom du type, gras, blanc ombré
##   AccentButton     Button  action principale (CHOISIR) : fond ACCENT, texte ACCENT_TEXT
##   PanelButton      Button  action secondaire (RETOUR) : voile clair, ACCENT à l'appui
## Combat (jalon 4B, game/ui/battle/) :
##   BattleCard       PanelContainer  carte d'information translucide (nom, niveau, PV)
##   BattleCardName / BattleCardLevel / BattleCardLevelValue / BattleCardHp   Label
##   HpBar            HBoxContainer   styles « background » (fond clair) et « fill »
##   HpBarLabel       Label   « PV », gras (couleur posée par la barre)
##   PartyPipEmpty    Panel   disque gris d'un emplacement d'équipe vide
##   BattleBackButton Button  bouton rond « ‹ »
##   ActionButton     Button  bouton d'action de combat (gras, blanc, icône à gauche) ;
##     ActionButtonAttack / Bag / Team / Run : ses couleurs (ACTION_*), atténuées si inactif
##   ActionGlow       Panel   lueur d'accent autour d'ATTAQUER (pulse)
##   MoveBand         Panel   bandeau sombre derrière les capacités (déborde jusqu'aux bords)
##   MoveCard / MoveCardSelected / MoveCardEmpty   PanelContainer  carte de capacité (fond
##     recoloré par type à l'usage), sélectionnée (liseré ACCENT + halo), emplacement vide
##   MoveCardName / MoveCardPp / MoveCardPpTag / MoveCardPower   Label
##   MoveDetailSheet  PanelContainer  fiche de pression longue
##   MoveDetailName / MoveDetailCaption / MoveDetailValue / MoveDetailText   Label
##   BattleMessage    PanelContainer  bandeau des messages ; BattleMessageText   Label
## XP et oubli (jalon 5C, T10) :
##   ExpBar           Control  styles « background » (fond clair) et « fill » (bleu) de la barre d'XP
##   ExpGain          Label    « +21 XP » : FONT_BUTTON, gras, ACCENT, ombre portée
##   ForgetBand       Panel    bandeau opaque du panneau d'oubli (déborde jusqu'aux bords)
##   ForgetCaption    Label    « Nouvelle capacité » / « Capacité à oublier », discret
##   ForgetConfirm    Button   OUBLIER : fond ACCENT, atténué et muet tant que rien n'est choisi
## Sac de combat et carte de capture (jalon 5D, T14) :
##   BagPanel         PanelContainer  cadre sombre translucide du Sac
##   BagTitle         Label    « SAC », FONT_TITLE, gras
##   BagDivider       Panel    filet sous l'en-tête
##   BagTab / BagTabSelected   PanelContainer  onglet de catégorie, sélectionné (fond teinté et
##     liseré ACCENT) ; BagTabName   Label
##   BagCard / BagCardSelected   PanelContainer  carte d'objet, sélectionnée (liseré ACCENT et halo) ;
##     BagCardName / BagCardQuantity   Label
##   BagDetail        PanelContainer  aperçu de l'objet touché ; BagDetailName / BagDetailQuantity /
##     BagDetailText   Label ; l'action est un AccentButton ; BagEmpty   Label
##   CaptureCard      PanelContainer  carte de capture ; CaptureTitle / CapturePokedex /
##     CaptureResult   Label ; CaptureThumb   PanelContainer  cadre de la vignette
## Notifications :
##   Toast            PanelContainer  capsule du toast (bible UI/UX §6)
##   ToastTitle / ToastDetail   Label  « Poké Balls ×5 » (gras) / « Ajoutées au Sac » (discret)
## tests/unit/test_ui_theme.gd vérifie que le fichier est à jour avec les tokens.

const TOKENS_PATH: String = "res://game/ui/theme/ui_tokens.gd"
const THEME_PATH: String = "res://game/ui/theme/ui_theme.tres"


func _init() -> void:
	var t: GDScript = load(TOKENS_PATH)
	var theme := Theme.new()
	theme.default_font_size = t.FONT_BODY
	theme.set_color(&"font_color", &"Label", t.TEXT)

	var bold := FontVariation.new()
	bold.resource_name = "BoldDefault"
	bold.variation_embolden = t.FONT_BOLD_EMBOLDEN

	_add_label_variation(theme, &"ZoneTitleName", t.FONT_TITLE, t.TEXT, t)
	theme.set_font(&"font", &"ZoneTitleName", bold)
	_add_label_variation(theme, &"ZoneTitleRegion", t.FONT_CAPTION, t.TEXT_MUTED, t)

	var italic := FontVariation.new()
	italic.resource_name = "ItalicDefault"
	italic.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(t.DIALOG_ITALIC_SLANT, 1.0),
		Vector2.ZERO)

	var dialog_box := _panel_style(t.DIALOG_PANEL_BG, t.DIALOG_RADIUS, t)
	dialog_box.set_content_margin(SIDE_LEFT, t.DIALOG_PAD_H)
	dialog_box.set_content_margin(SIDE_RIGHT, t.DIALOG_PAD_H)
	dialog_box.set_content_margin(SIDE_TOP, t.DIALOG_PAD_V)
	dialog_box.set_content_margin(SIDE_BOTTOM, t.DIALOG_PAD_V)
	theme.set_type_variation(&"DialogBox", &"PanelContainer")
	theme.set_stylebox(&"panel", &"DialogBox", dialog_box)

	_add_plain_label(theme, &"DialogSpeaker", t.DIALOG_SPEAKER_FONT, t.DIALOG_SPEAKER, bold)
	_add_plain_label(theme, &"DialogText", t.FONT_BODY, t.TEXT, null)
	_add_plain_label(theme, &"DialogNarration", t.FONT_BODY, t.DIALOG_NARRATION, italic)
	for type: StringName in [&"DialogText", &"DialogNarration"]:
		theme.set_constant(&"line_spacing", type, t.DIALOG_LINE_SPACING)
	_add_plain_label(theme, &"DialogContinue", t.DIALOG_CONTINUE_FONT, t.ACCENT, bold)

	var pill := _panel_style(t.PANEL_BG, t.ROUND_BUTTON, t)
	pill.shadow_size = 0
	pill.set_content_margin(SIDE_LEFT, t.INTERACT_LABEL_PAD_H)
	pill.set_content_margin(SIDE_RIGHT, t.INTERACT_LABEL_PAD_H)
	pill.set_content_margin(SIDE_TOP, t.INTERACT_LABEL_PAD_V)
	pill.set_content_margin(SIDE_BOTTOM, t.INTERACT_LABEL_PAD_V)
	theme.set_type_variation(&"InteractLabel", &"PanelContainer")
	theme.set_stylebox(&"panel", &"InteractLabel", pill)
	_add_plain_label(theme, &"InteractLabelText", t.INTERACT_LABEL_FONT, t.TEXT, bold)

	_add_caption(theme, t)
	_add_starter_sheet(theme, bold, italic, t)
	_add_buttons(theme, bold, t)
	_add_battle_cards(theme, bold, t)
	_add_battle_actions(theme, bold, t)
	_add_battle_moves(theme, bold, t)
	_add_battle_messages(theme, t)
	_add_exp_and_forget(theme, bold, t)
	_add_bag_and_capture(theme, bold, t)
	_add_toast(theme, bold, t)

	var err := ResourceSaver.save(theme, THEME_PATH)
	print("ui_theme.tres : ", error_string(err))
	quit(0 if err == OK else 1)


func _add_label_variation(
	theme: Theme, type: StringName, size: int, color: Color, t: GDScript
) -> void:
	theme.set_type_variation(type, &"Label")
	theme.set_font_size(&"font_size", type, size)
	theme.set_color(&"font_color", type, color)
	theme.set_color(&"font_shadow_color", type, t.TEXT_SHADOW)
	theme.set_constant(&"shadow_offset_x", type, 0)
	theme.set_constant(&"shadow_offset_y", type, t.TEXT_SHADOW_OFFSET)
	theme.set_constant(&"shadow_outline_size", type, t.TEXT_SHADOW_OFFSET * 2)


## Label sans ombre (texte posé sur un panneau) ; [param font] null = police du thème.
func _add_plain_label(
	theme: Theme, type: StringName, size: int, color: Color, font: Font
) -> void:
	theme.set_type_variation(type, &"Label")
	theme.set_font_size(&"font_size", type, size)
	theme.set_color(&"font_color", type, color)
	if font != null:
		theme.set_font(&"font", type, font)


## Panneau arrondi : fond, bordure PANEL_BORDER, ombre SHADOW, anticrénelé.
func _panel_style(bg: Color, radius: int, t: GDScript) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = t.PANEL_BORDER
	box.set_border_width_all(t.BORDER_WIDTH)
	box.set_corner_radius_all(radius)
	box.shadow_color = t.SHADOW
	box.shadow_size = t.SHADOW_SIZE
	box.anti_aliasing = true
	return box


## Légende sur le monde : pas de fond, ombre portée large (halo) pour rester lisible.
func _add_caption(theme: Theme, t: GDScript) -> void:
	var spaced := FontVariation.new()
	spaced.resource_name = "CaptionDefault"
	spaced.variation_embolden = t.FONT_BOLD_EMBOLDEN
	spaced.spacing_glyph = t.CAPTION_LETTER_SPACING
	_add_label_variation(theme, &"WorldCaption", t.FONT_TITLE, t.TEXT, t)
	theme.set_font(&"font", &"WorldCaption", spaced)
	theme.set_constant(&"shadow_offset_y", &"WorldCaption", t.CAPTION_SHADOW_OFFSET)
	theme.set_constant(&"shadow_outline_size", &"WorldCaption", t.CAPTION_SHADOW_OUTLINE)


func _add_starter_sheet(theme: Theme, bold: Font, italic: Font, t: GDScript) -> void:
	var card := _panel_style(t.PANEL_BG, t.RADIUS, t)
	card.set_content_margin_all(t.STARTER_SHEET_PAD)
	theme.set_type_variation(&"StarterSheet", &"PanelContainer")
	theme.set_stylebox(&"panel", &"StarterSheet", card)
	_add_plain_label(theme, &"StarterSheetName", t.FONT_TITLE, t.TEXT, bold)
	_add_plain_label(theme, &"StarterSheetPhrase", t.FONT_BODY, t.STARTER_SHEET_PHRASE, italic)

	var badge := StyleBoxFlat.new()
	badge.bg_color = t.TYPE_COLOR_UNKNOWN
	badge.set_corner_radius_all(t.TYPE_BADGE_RADIUS)
	badge.anti_aliasing = true
	badge.set_content_margin(SIDE_LEFT, t.TYPE_BADGE_PAD_H - t.TYPE_BADGE_PAD_V)
	badge.set_content_margin(SIDE_RIGHT, t.TYPE_BADGE_PAD_H)
	badge.set_content_margin(SIDE_TOP, t.TYPE_BADGE_PAD_V)
	badge.set_content_margin(SIDE_BOTTOM, t.TYPE_BADGE_PAD_V)
	theme.set_type_variation(&"TypeBadge", &"PanelContainer")
	theme.set_stylebox(&"panel", &"TypeBadge", badge)
	_add_plain_label(theme, &"TypeBadgeText", t.TYPE_BADGE_FONT, t.TEXT, bold)
	theme.set_color(&"font_shadow_color", &"TypeBadgeText", t.TEXT_SHADOW)
	theme.set_constant(&"shadow_offset_x", &"TypeBadgeText", 0)
	theme.set_constant(&"shadow_offset_y", &"TypeBadgeText", t.TEXT_SHADOW_OFFSET)


## Boutons de panneau. Pas d'état de survol distinct : sur le téléphone, la souris émulée
## laisserait le bouton « survolé » après le toucher. Pas de cadre de focus (tactile).
func _add_buttons(theme: Theme, bold: Font, t: GDScript) -> void:
	var accent := _button_style(t.ACCENT, false, t)
	var accent_pressed := _button_style(t.ACCENT_PRESSED, false, t)
	_add_button_variation(theme, &"AccentButton", accent, accent_pressed, bold, t)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color",
			&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"AccentButton", t.ACCENT_TEXT)

	var panel := _button_style(t.BUTTON_BG, true, t)
	var panel_pressed := _button_style(t.ACCENT, false, t)
	_add_button_variation(theme, &"PanelButton", panel, panel_pressed, bold, t)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color"]:
		theme.set_color(state, &"PanelButton", t.TEXT)
	for state: StringName in [&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"PanelButton", t.ACCENT_TEXT)


func _add_button_variation(theme: Theme, type: StringName, normal: StyleBox,
		pressed: StyleBox, font: Font, t: GDScript) -> void:
	theme.set_type_variation(type, &"Button")
	theme.set_stylebox(&"normal", type, normal)
	theme.set_stylebox(&"hover", type, normal)
	theme.set_stylebox(&"pressed", type, pressed)
	theme.set_stylebox(&"hover_pressed", type, pressed)
	theme.set_stylebox(&"disabled", type, normal)
	theme.set_stylebox(&"focus", type, StyleBoxEmpty.new())
	theme.set_font(&"font", type, font)
	theme.set_font_size(&"font_size", type, t.FONT_BUTTON)


func _button_style(bg: Color, bordered: bool, t: GDScript) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	if bordered:
		box.border_color = t.PANEL_BORDER
		box.set_border_width_all(t.BORDER_WIDTH)
	box.set_corner_radius_all(t.RADIUS)
	box.anti_aliasing = true
	box.set_content_margin(SIDE_LEFT, t.BUTTON_PAD_H)
	box.set_content_margin(SIDE_RIGHT, t.BUTTON_PAD_H)
	return box


# --- Combat (jalon 4B) ------------------------------------------------------------------------


func _add_battle_cards(theme: Theme, bold: Font, t: GDScript) -> void:
	var card := _panel_style(t.BATTLE_CARD_BG, t.RADIUS, t)
	card.set_content_margin(SIDE_LEFT, t.BATTLE_CARD_PAD_H)
	card.set_content_margin(SIDE_RIGHT, t.BATTLE_CARD_PAD_H)
	card.set_content_margin(SIDE_TOP, t.BATTLE_CARD_PAD_V)
	card.set_content_margin(SIDE_BOTTOM, t.BATTLE_CARD_PAD_V)
	theme.set_type_variation(&"BattleCard", &"PanelContainer")
	theme.set_stylebox(&"panel", &"BattleCard", card)
	_add_plain_label(theme, &"BattleCardName", t.BATTLE_CARD_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"BattleCardLevel", t.BATTLE_CARD_LEVEL_FONT, t.TEXT_MUTED, bold)
	_add_plain_label(theme, &"BattleCardLevelValue", t.BATTLE_CARD_LEVEL_VALUE_FONT, t.TEXT,
		bold)
	_add_plain_label(theme, &"BattleCardHp", t.BATTLE_HP_NUMBERS_FONT, t.TEXT, bold)

	var radius: int = t.HP_BAR_HEIGHT / 2
	var track := StyleBoxFlat.new()
	track.bg_color = t.HP_BAR_TRACK
	track.border_color = t.HP_BAR_TRACK_BORDER
	track.set_border_width_all(t.BORDER_WIDTH)
	track.set_corner_radius_all(radius)
	track.anti_aliasing = true
	var fill := StyleBoxFlat.new()
	fill.bg_color = t.HP_HIGH
	fill.set_corner_radius_all(radius - t.HP_BAR_INSET)
	fill.anti_aliasing = true
	theme.set_type_variation(&"HpBar", &"HBoxContainer")
	theme.set_stylebox(&"background", &"HpBar", track)
	theme.set_stylebox(&"fill", &"HpBar", fill)
	_add_plain_label(theme, &"HpBarLabel", t.HP_BAR_LABEL_FONT, t.HP_HIGH, bold)

	var pip := StyleBoxFlat.new()
	pip.bg_color = t.PARTY_PIP_EMPTY
	pip.border_color = t.PARTY_PIP_EMPTY_BORDER
	pip.set_border_width_all(t.BORDER_WIDTH)
	pip.set_corner_radius_all(t.PARTY_PIP)
	pip.anti_aliasing = true
	theme.set_type_variation(&"PartyPipEmpty", &"Panel")
	theme.set_stylebox(&"panel", &"PartyPipEmpty", pip)

	var round_normal := _round_style(t.PANEL_BG, t)
	var round_pressed := _round_style(t.ACCENT, t)
	theme.set_type_variation(&"BattleBackButton", &"Button")
	for state: StringName in [&"normal", &"hover", &"disabled"]:
		theme.set_stylebox(state, &"BattleBackButton", round_normal)
	for state: StringName in [&"pressed", &"hover_pressed"]:
		theme.set_stylebox(state, &"BattleBackButton", round_pressed)
	theme.set_stylebox(&"focus", &"BattleBackButton", StyleBoxEmpty.new())
	for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_focus_color"]:
		theme.set_color(state, &"BattleBackButton", t.TEXT)
	for state: StringName in [&"icon_pressed_color", &"icon_hover_pressed_color"]:
		theme.set_color(state, &"BattleBackButton", t.ACCENT_TEXT)
	theme.set_constant(&"icon_max_width", &"BattleBackButton", t.BATTLE_BACK_ICON)


func _round_style(bg: Color, t: GDScript) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = t.ROUND_BUTTON_OUTLINE
	box.set_border_width_all(int(t.ROUND_BUTTON_OUTLINE_WIDTH))
	box.set_corner_radius_all(t.BATTLE_BACK_SIZE)
	box.shadow_color = t.SHADOW
	box.shadow_size = t.SHADOW_SIZE
	box.anti_aliasing = true
	return box


## Boutons d'action colorés (combat-v1). Enfoncé : couleur assombrie ; inactif : couleur mêlée
## à SURFACE_DARK et plus transparente, texte et icône atténués.
func _add_battle_actions(theme: Theme, bold: Font, t: GDScript) -> void:
	theme.set_type_variation(&"ActionButton", &"Button")
	theme.set_font(&"font", &"ActionButton", bold)
	theme.set_font_size(&"font_size", &"ActionButton", t.FONT_BUTTON)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color",
			&"font_pressed_color", &"font_hover_pressed_color", &"icon_normal_color",
			&"icon_hover_color", &"icon_focus_color", &"icon_pressed_color",
			&"icon_hover_pressed_color"]:
		theme.set_color(state, &"ActionButton", t.TEXT)
	theme.set_color(&"font_disabled_color", &"ActionButton", t.TEXT_DISABLED)
	theme.set_color(&"icon_disabled_color", &"ActionButton", t.TEXT_DISABLED)
	theme.set_color(&"font_shadow_color", &"ActionButton", t.TEXT_SHADOW)
	theme.set_constant(&"shadow_offset_x", &"ActionButton", 0)
	theme.set_constant(&"shadow_offset_y", &"ActionButton", t.TEXT_SHADOW_OFFSET)
	theme.set_constant(&"icon_max_width", &"ActionButton", t.BATTLE_ACTION_ICON)
	theme.set_constant(&"h_separation", &"ActionButton", t.GAP)
	theme.set_stylebox(&"focus", &"ActionButton", StyleBoxEmpty.new())
	var colors: Dictionary[StringName, Color] = {
		&"ActionButtonAttack": t.ACTION_ATTACK,
		&"ActionButtonBag": t.ACTION_BAG,
		&"ActionButtonTeam": t.ACTION_TEAM,
		&"ActionButtonRun": t.ACTION_RUN,
	}
	for type: StringName in colors:
		var color: Color = colors[type]
		var normal := _action_style(color, t)
		var pressed := _action_style(color.darkened(t.BATTLE_ACTION_PRESSED_DARKEN), t)
		var dim: Color = color.lerp(t.SURFACE_DARK, t.BATTLE_ACTION_DISABLED_MIX)
		dim.a = t.BATTLE_ACTION_DISABLED_ALPHA
		var disabled := _action_style(dim, t)
		disabled.border_color = t.PANEL_BORDER
		disabled.shadow_size = 0
		theme.set_type_variation(type, &"ActionButton")
		theme.set_stylebox(&"normal", type, normal)
		theme.set_stylebox(&"hover", type, normal)
		theme.set_stylebox(&"pressed", type, pressed)
		theme.set_stylebox(&"hover_pressed", type, pressed)
		theme.set_stylebox(&"disabled", type, disabled)

	var glow := StyleBoxFlat.new()
	glow.bg_color = t.TRANSPARENT
	glow.draw_center = false
	glow.border_color = t.ACCENT
	glow.set_border_width_all(t.ACTION_GLOW_BORDER)
	# Derrière le bouton : l'anneau d'accent dépasse du bouton, le halo au-delà.
	glow.set_expand_margin_all(t.ACTION_GLOW_BORDER)
	glow.set_corner_radius_all(t.RADIUS)
	glow.shadow_color = t.ACTION_GLOW
	glow.shadow_size = t.ACTION_GLOW_SIZE
	glow.anti_aliasing = true
	theme.set_type_variation(&"ActionGlow", &"Panel")
	theme.set_stylebox(&"panel", &"ActionGlow", glow)


func _action_style(bg: Color, t: GDScript) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = bg.lightened(t.BATTLE_ACTION_BORDER_LIGHTEN)
	box.set_border_width_all(t.BORDER_WIDTH)
	box.set_corner_radius_all(t.RADIUS)
	box.shadow_color = t.SHADOW
	box.shadow_size = t.SHADOW_SIZE / 2
	box.anti_aliasing = true
	box.set_content_margin(SIDE_LEFT, t.BATTLE_ACTION_PAD_H)
	box.set_content_margin(SIDE_RIGHT, t.BATTLE_ACTION_PAD_H)
	return box


func _add_battle_moves(theme: Theme, bold: Font, t: GDScript) -> void:
	var band := StyleBoxFlat.new()
	band.bg_color = t.MOVE_BAND_BG
	band.border_color = t.PANEL_BORDER
	band.border_width_top = t.BORDER_WIDTH
	band.border_width_left = t.BORDER_WIDTH
	band.corner_radius_top_left = t.RADIUS
	band.expand_margin_right = t.MOVE_BAND_BLEED
	band.expand_margin_bottom = t.MOVE_BAND_BLEED
	band.anti_aliasing = true
	theme.set_type_variation(&"MoveBand", &"Panel")
	theme.set_stylebox(&"panel", &"MoveBand", band)

	var card := _move_card_style(t.PANEL_BG, t.PANEL_BORDER, t.BORDER_WIDTH, t)
	var selected := _move_card_style(t.PANEL_BG, t.ACCENT, t.MOVE_CARD_SELECTED_BORDER, t)
	selected.shadow_color = t.MOVE_CARD_SELECTED_GLOW
	selected.shadow_size = t.MOVE_CARD_SELECTED_GLOW_SIZE
	var empty := _move_card_style(t.MOVE_CARD_EMPTY_BG, t.MOVE_CARD_EMPTY_BORDER, t.BORDER_WIDTH,
		t)
	for pair: Array in [[&"MoveCard", card], [&"MoveCardSelected", selected],
			[&"MoveCardEmpty", empty]]:
		theme.set_type_variation(pair[0], &"PanelContainer")
		theme.set_stylebox(&"panel", pair[0], pair[1])
	_add_plain_label(theme, &"MoveCardName", t.MOVE_CARD_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"MoveCardPp", t.MOVE_CARD_PP_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"MoveCardPpTag", t.MOVE_CARD_PP_TAG_FONT, t.TEXT_MUTED, bold)
	_add_plain_label(theme, &"MoveCardPower", t.MOVE_CARD_POWER_FONT, t.TEXT_MUTED, null)

	var sheet := _panel_style(t.MOVE_DETAIL_BG, t.RADIUS, t)
	sheet.set_content_margin_all(t.MOVE_DETAIL_PAD)
	theme.set_type_variation(&"MoveDetailSheet", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MoveDetailSheet", sheet)
	_add_plain_label(theme, &"MoveDetailName", t.MOVE_DETAIL_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"MoveDetailCaption", t.FONT_CAPTION, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"MoveDetailValue", t.MOVE_DETAIL_VALUE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"MoveDetailText", t.MOVE_DETAIL_TEXT_FONT, t.DIALOG_NARRATION, null)


func _move_card_style(bg: Color, border: Color, width: int, t: GDScript) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(t.RADIUS)
	box.anti_aliasing = true
	box.set_content_margin(SIDE_LEFT, t.MOVE_CARD_PAD_H)
	box.set_content_margin(SIDE_RIGHT, t.MOVE_CARD_PAD_H)
	box.set_content_margin(SIDE_TOP, t.MOVE_CARD_PAD_V)
	box.set_content_margin(SIDE_BOTTOM, t.MOVE_CARD_PAD_V)
	return box


## Barre d'XP, « +N XP » et panneau d'oubli d'une capacité (jalon 5C, T10).
func _add_exp_and_forget(theme: Theme, bold: Font, t: GDScript) -> void:
	var radius: int = t.EXP_BAR_HEIGHT / 2
	var track := StyleBoxFlat.new()
	track.bg_color = t.EXP_BAR_TRACK
	track.border_color = t.HP_BAR_TRACK_BORDER
	track.set_border_width_all(t.BORDER_WIDTH)
	track.set_corner_radius_all(radius)
	track.anti_aliasing = true
	var fill := StyleBoxFlat.new()
	fill.bg_color = t.EXP_BAR_FILL
	fill.set_corner_radius_all(radius - t.BORDER_WIDTH)
	fill.anti_aliasing = true
	theme.set_type_variation(&"ExpBar", &"Control")
	theme.set_stylebox(&"background", &"ExpBar", track)
	theme.set_stylebox(&"fill", &"ExpBar", fill)
	_add_label_variation(theme, &"ExpGain", t.EXP_GAIN_FONT, t.ACCENT, t)
	theme.set_font(&"font", &"ExpGain", bold)
	theme.set_constant(&"outline_size", &"ExpGain", t.EXP_GAIN_OUTLINE)
	theme.set_color(&"font_outline_color", &"ExpGain", t.SURFACE_DARK)

	var band := StyleBoxFlat.new()
	band.bg_color = t.FORGET_BAND_BG
	band.border_color = t.PANEL_BORDER
	band.border_width_top = t.BORDER_WIDTH
	band.border_width_left = t.BORDER_WIDTH
	band.corner_radius_top_left = t.RADIUS
	band.expand_margin_right = t.MOVE_BAND_BLEED
	band.expand_margin_bottom = t.MOVE_BAND_BLEED
	band.anti_aliasing = true
	theme.set_type_variation(&"ForgetBand", &"Panel")
	theme.set_stylebox(&"panel", &"ForgetBand", band)
	_add_plain_label(theme, &"ForgetCaption", t.FONT_CAPTION, t.TEXT_MUTED, bold)

	var accent := _button_style(t.ACCENT, false, t)
	var accent_pressed := _button_style(t.ACCENT_PRESSED, false, t)
	var disabled := _button_style(t.FORGET_CONFIRM_DISABLED_BG, true, t)
	_add_button_variation(theme, &"ForgetConfirm", accent, accent_pressed, bold, t)
	theme.set_stylebox(&"disabled", &"ForgetConfirm", disabled)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color",
			&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"ForgetConfirm", t.ACCENT_TEXT)
	theme.set_color(&"font_disabled_color", &"ForgetConfirm", t.TEXT_DISABLED)


func _add_battle_messages(theme: Theme, t: GDScript) -> void:
	var banner := _panel_style(t.BATTLE_MESSAGE_BG, t.DIALOG_RADIUS, t)
	banner.set_content_margin(SIDE_LEFT, t.BATTLE_MESSAGE_PAD_H)
	banner.set_content_margin(SIDE_RIGHT, t.BATTLE_MESSAGE_PAD_H)
	banner.set_content_margin(SIDE_TOP, t.BATTLE_MESSAGE_PAD_V)
	banner.set_content_margin(SIDE_BOTTOM, t.BATTLE_MESSAGE_PAD_V)
	theme.set_type_variation(&"BattleMessage", &"PanelContainer")
	theme.set_stylebox(&"panel", &"BattleMessage", banner)
	_add_plain_label(theme, &"BattleMessageText", t.FONT_BODY, t.TEXT, null)
	theme.set_constant(&"line_spacing", &"BattleMessageText", t.DIALOG_LINE_SPACING)


## Toast (bible UI/UX §6) : capsule sombre translucide, titre gras, détail discret.
func _add_toast(theme: Theme, bold: Font, t: GDScript) -> void:
	var capsule := _panel_style(t.TOAST_BG, t.TOAST_RADIUS, t)
	capsule.set_content_margin(SIDE_LEFT, t.TOAST_PAD_LEFT)
	capsule.set_content_margin(SIDE_RIGHT, t.TOAST_PAD_RIGHT)
	capsule.set_content_margin(SIDE_TOP, t.TOAST_PAD_V)
	capsule.set_content_margin(SIDE_BOTTOM, t.TOAST_PAD_V)
	theme.set_type_variation(&"Toast", &"PanelContainer")
	theme.set_stylebox(&"panel", &"Toast", capsule)
	_add_plain_label(theme, &"ToastTitle", t.TOAST_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"ToastDetail", t.TOAST_DETAIL_FONT, t.TEXT_MUTED, null)


## Sac de combat et carte de capture (jalon 5D, T14).
func _add_bag_and_capture(theme: Theme, bold: Font, t: GDScript) -> void:
	var frame := _panel_style(t.BAG_PANEL_BG, t.RADIUS, t)
	frame.set_content_margin_all(t.BAG_PANEL_PAD)
	theme.set_type_variation(&"BagPanel", &"PanelContainer")
	theme.set_stylebox(&"panel", &"BagPanel", frame)
	_add_plain_label(theme, &"BagTitle", t.FONT_TITLE, t.TEXT, bold)
	var divider := StyleBoxFlat.new()
	divider.bg_color = t.PANEL_BORDER
	theme.set_type_variation(&"BagDivider", &"Panel")
	theme.set_stylebox(&"panel", &"BagDivider", divider)
	_add_plain_label(theme, &"BagEmpty", t.FONT_BODY, t.TEXT_MUTED, null)

	var tab := _bag_box(t.BUTTON_BG, t.PANEL_BORDER, t.BORDER_WIDTH, t.BAG_TAB_PAD_H, 8, t)
	var tab_selected := _bag_box(t.BAG_TAB_SELECTED_BG, t.ACCENT, t.BAG_TAB_SELECTED_BORDER,
		t.BAG_TAB_PAD_H, 8, t)
	var card := _bag_box(t.PANEL_BG, t.PANEL_BORDER, t.BORDER_WIDTH, t.BAG_CARD_PAD_H,
		t.BAG_CARD_PAD_V, t)
	var card_selected := _bag_box(t.PANEL_BG, t.ACCENT, t.MOVE_CARD_SELECTED_BORDER,
		t.BAG_CARD_PAD_H, t.BAG_CARD_PAD_V, t)
	card_selected.shadow_color = t.MOVE_CARD_SELECTED_GLOW
	card_selected.shadow_size = t.MOVE_CARD_SELECTED_GLOW_SIZE
	var detail := _bag_box(t.BUTTON_BG, t.PANEL_BORDER, t.BORDER_WIDTH, t.BAG_DETAIL_PAD,
		t.BAG_DETAIL_PAD, t)
	for pair: Array in [[&"BagTab", tab], [&"BagTabSelected", tab_selected],
			[&"BagCard", card], [&"BagCardSelected", card_selected], [&"BagDetail", detail]]:
		theme.set_type_variation(pair[0], &"PanelContainer")
		theme.set_stylebox(&"panel", pair[0], pair[1])
	_add_plain_label(theme, &"BagTabName", t.BAG_TAB_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"BagCardName", t.BAG_CARD_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"BagCardQuantity", t.BAG_CARD_QTY_FONT, t.TEXT, bold)
	theme.set_constant(&"outline_size", &"BagCardQuantity", t.EXP_GAIN_OUTLINE)
	theme.set_color(&"font_outline_color", &"BagCardQuantity", t.SURFACE_DARK)
	_add_plain_label(theme, &"BagDetailName", t.BAG_DETAIL_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"BagDetailQuantity", t.BAG_DETAIL_QTY_FONT, t.TEXT_MUTED, bold)
	_add_plain_label(theme, &"BagDetailText", t.BAG_DETAIL_TEXT_FONT, t.DIALOG_NARRATION, null)

	var capture := _panel_style(t.CAPTURE_CARD_BG, t.DIALOG_RADIUS, t)
	capture.set_content_margin(SIDE_LEFT, t.CAPTURE_CARD_PAD_H)
	capture.set_content_margin(SIDE_RIGHT, t.CAPTURE_CARD_PAD_H)
	capture.set_content_margin(SIDE_TOP, t.CAPTURE_CARD_PAD_V)
	capture.set_content_margin(SIDE_BOTTOM, t.CAPTURE_CARD_PAD_V)
	theme.set_type_variation(&"CaptureCard", &"PanelContainer")
	theme.set_stylebox(&"panel", &"CaptureCard", capture)
	var thumb := _bag_box(t.CAPTURE_THUMB_BG, t.CAPTURE_THUMB_BORDER, t.BORDER_WIDTH,
		t.CAPTURE_THUMB_PAD, t.CAPTURE_THUMB_PAD, t)
	theme.set_type_variation(&"CaptureThumb", &"PanelContainer")
	theme.set_stylebox(&"panel", &"CaptureThumb", thumb)
	_add_plain_label(theme, &"CaptureTitle", t.CAPTURE_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"CapturePokedex", t.CAPTURE_LINE_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"CaptureResult", t.CAPTURE_LINE_FONT, t.TEXT, null)


## Case arrondie du Sac et de la carte de capture : fond, liseré, marges [param pad_h] et
## [param pad_v] ; pas d'ombre (celle des cartes sélectionnées est posée à part).
func _bag_box(bg: Color, border: Color, width: int, pad_h: int, pad_v: int,
		t: GDScript) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(t.RADIUS)
	box.anti_aliasing = true
	box.set_content_margin(SIDE_LEFT, pad_h)
	box.set_content_margin(SIDE_RIGHT, pad_h)
	box.set_content_margin(SIDE_TOP, pad_v)
	box.set_content_margin(SIDE_BOTTOM, pad_v)
	return box
