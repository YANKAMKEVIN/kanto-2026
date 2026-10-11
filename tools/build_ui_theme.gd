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
## Bilan de fin de combat (demande n° 1) :
##   SummaryCard / SummaryRow / SummaryRowLit (liseré ACCENT : la ligne qui monte de niveau) /
##   SummaryThumb / SummaryHint   PanelContainer ; SummaryExpBar   Control (barre plus épaisse) ;
##   SummaryName / SummaryLevel / SummaryLevelUp / SummaryPoints / SummaryGain / SummaryStatName /
##   SummaryStatValue   Label ; SummaryStatsBox   PanelContainer (grille des gains) /
##   SummaryHintText   Label
## Notifications :
##   Toast            PanelContainer  capsule du toast (bible UI/UX §6)
##   ToastTitle / ToastDetail   Label  « Poké Balls ×5 » (gras) / « Ajoutées au Sac » (discret)
## Menu Dresseur (jalon 6, T3) :
##   MenuPanel        PanelContainer  panneau translucide (carte du Dresseur)
##   MenuZonePill     PanelContainer  pastille du nom de zone (en-tête) ; MenuZoneName   Label
##   MenuCloseButton  Button  × rond de l'en-tête (TOUCH_MIN)
##   MenuCard         Button  grande carte (la teinte est posée par carte à l'usage)
##   MenuCardTitle / MenuCardCaption   Label ; MenuCardChevron   Panel  pastille « › »
##   MenuLeadCard     Button  carte du Pokémon de tête ; MenuLeadThumb   Panel
##   MenuLeadName / MenuLeadLevel / MenuLeadHp   Label
##   MenuName / MenuSubtitle / MenuStat   Label  carte du Dresseur ; MenuIdBar   Panel
##   MenuObjective    Label  ligne d'objectif, discrète
## Équipe (jalon 6, T7) :
##   TeamSlot / TeamSlotSelected / TeamSlotSource / TeamSlotTarget / TeamSlotEmpty   Panel
##   TeamSlotName / TeamSlotMeta / TeamCaption / TeamValue / TeamStat / TeamLevel   Label
##   TeamTab          Button  onglet (bouton à bascule : enfoncé = ACCENT) ; TeamAction /
##                    TeamActionOn  Button  actions de la fiche ; TeamSection  PanelContainer
##   Sac du menu (T11) : BagTabCount / BagNote / BagHint / PickerTitle / PickerName / PickerMeta /
##     PickerReason / ResultText  Label ; PickerRow / PickerRowSelected / PickerRowOff /
##     ResultBar / ResultBarRefused  PanelContainer
##   Carte (T20) : MapPanel / MapFrame / MapLabel / MapLabelOn / MapChip (PanelContainer),
##     MapEntry (Button), MapName / MapSubtitle / MapText / MapSection / MapEntryText /
##     MapLabelText / MapLabelTextOn (Label)
##   Dresseur (T24) : TrainerBadge / TrainerBadgeOn (PanelContainer), TrainerMoment / TrainerLink
##     (Button), TrainerMomentBox (PanelContainer), TrainerSection / TrainerBadgeName / TrainerMomentTitle / TrainerMomentDetail /
##     TrainerMomentMeta / TrainerStatLabel / TrainerStatValue / TrainerRow / TrainerEmpty (Label)
##   Pokédex (T15) : DexPanel (PanelContainer), DexCell / DexCellSelected / DexCellUnknown
##     (PanelContainer, case de la grille), DexTab (Button à bascule : onglets et filtres),
##     DexSearch (LineEdit), DexTitle / DexName / DexNumber (Label), DexSpriteFrame (Panel)
##   TeamPill / TeamPillAccent  PanelContainer  « Favori » et consigne du mode DÉPLACER ;
##   TeamPillText / TeamPillAccentText  Label ; TeamEvoCircle  Panel
##   Paramètres (T28, MM.3) : SettingsCategory / SettingsRow[Last] / SettingsArrow (Button),
##     SettingsRowBox[Last] / SettingsList / SettingsPill / SettingsActionRound (PanelContainer),
##     SettingsPanelTitle / SettingsSubtitle / SettingsLabel / SettingsDetail / SettingsState /
##     SettingsValue (Label) ; ChoiceConfirm / ChoiceCancel (Button, carte de ChoiceCards),
##     ChoiceTitle / ChoiceDetail / ChoiceConfirmLabel / ChoiceConfirmDetail / ChoiceCancelLabel /
##     ChoiceCancelDetail (Label)
##   Boutique (T11) : ShopStepper (Button, − / +), ShopName / ShopOwned / ShopDescription /
##     ShopCaption / ShopUnitPrice / ShopQuantity / ShopTotal / ShopCardPrice / ShopMoney /
##     ShopMoneyLabel (Label)
##   Stockage (T15) : StorageDropZone (Panel, cadre ACCENT), StorageRefusal / StorageMenu (PanelContainer),
##     StorageRefusalText / StorageTitle / StorageEmpty (Label)
##   Menu rapproché des maquettes (MM.1) : MenuGlass / MenuGlassCard / MenuStatusBar
##     (PanelContainer), MenuRoundButton / MenuArtCard / MenuAction / MenuActionOn / MenuTab /
##     MenuBagTab… (Button ou PanelContainer), MenuArtRim / MenuArtRimPressed / MenuArtRound /
##     MenuRoundThumb / MenuStatusDivider (Panel), MenuScreenTitle / MenuScreenCount /
##     MenuStatusText / MenuArtTitle / MenuArtCaption / MenuBagTabCaption / MenuTargetsTitle (Label)
## Écran titre (OUV.1) : TitleCard / TitleCardFeatured (Button, carte de verre ; liseré ACCENT et
##   halo pour l'entrée mise en avant), TitleDivider (Panel), TitleMessage (PanelContainer),
##   TitleEntryLabel / TitleContinueTitle / TitleContinueName / TitleContinueZone /
##   TitleContinueStat / TitleMessageText (Label)
## Écran de prénom (OUV.2) : NamePanel (PanelContainer, verre sombre à liseré ACCENT), NameField
##   (LineEdit clair), NameTitle / NameCounter / NameHelp (Label), NameChip / NameChipSelected (Button,
##   pastilles), NameValidate (Button ACCENT, éteint quand il est inactif)
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
	_add_menu(theme, bold, t)
	_add_team(theme, bold, t)
	_add_bag_screen(theme, bold, t)
	_add_pokedex_screen(theme, bold, t)
	_add_pokedex_layout(theme, bold, t)
	_add_pokedex_glass(theme, bold, t)
	_add_map_screen(theme, bold, t)
	_add_trainer_screen(theme, bold, t)
	_add_settings_screen(theme, bold, t)
	_add_shop_screen(theme, bold, t)
	_add_storage_screen(theme, bold, t)
	_add_menu_glass(theme, bold, t)
	_add_menu_mm2(theme, bold, t)
	_add_champion_card(theme, bold, t)
	_add_title_screen(theme, bold, t)
	_add_name_entry(theme, bold, t)

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
	_add_exp_summary(theme, bold, t)


## Bilan de fin de combat (demande n° 1).
func _add_exp_summary(theme: Theme, bold: Font, t: GDScript) -> void:
	var card := _panel_style(t.SUMMARY_CARD_BG, t.DIALOG_RADIUS, t)
	card.set_content_margin(SIDE_LEFT, t.SUMMARY_CARD_PAD_H)
	card.set_content_margin(SIDE_RIGHT, t.SUMMARY_CARD_PAD_H)
	card.set_content_margin(SIDE_TOP, t.SUMMARY_CARD_PAD_V)
	card.set_content_margin(SIDE_BOTTOM, t.SUMMARY_CARD_PAD_V)
	theme.set_type_variation(&"SummaryCard", &"PanelContainer")
	theme.set_stylebox(&"panel", &"SummaryCard", card)
	var row := _bag_box(t.SUMMARY_ROW_BG, t.SUMMARY_ROW_BORDER, t.BORDER_WIDTH,
		t.SUMMARY_ROW_PAD_H, t.SUMMARY_ROW_PAD_V, t)
	var lit := _bag_box(t.SUMMARY_ROW_LIT_BG, t.ACCENT, t.SUMMARY_ROW_HIGHLIGHT_BORDER,
		t.SUMMARY_ROW_PAD_H, t.SUMMARY_ROW_PAD_V, t)
	lit.shadow_color = t.MOVE_CARD_SELECTED_GLOW
	lit.shadow_size = t.MOVE_CARD_SELECTED_GLOW_SIZE
	for pair: Array in [[&"SummaryRow", row], [&"SummaryRowLit", lit]]:
		theme.set_type_variation(pair[0], &"PanelContainer")
		theme.set_stylebox(&"panel", pair[0], pair[1])
	var thumb := _bag_box(t.CAPTURE_THUMB_BG, t.CAPTURE_THUMB_BORDER, t.BORDER_WIDTH,
		t.SUMMARY_THUMB_PAD, t.SUMMARY_THUMB_PAD, t)
	theme.set_type_variation(&"SummaryThumb", &"PanelContainer")
	theme.set_stylebox(&"panel", &"SummaryThumb", thumb)
	var radius: int = t.SUMMARY_BAR_HEIGHT / 2
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
	theme.set_type_variation(&"SummaryExpBar", &"Control")
	theme.set_stylebox(&"background", &"SummaryExpBar", track)
	theme.set_stylebox(&"fill", &"SummaryExpBar", fill)
	_add_plain_label(theme, &"SummaryName", t.SUMMARY_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"SummaryLevel", t.SUMMARY_LEVEL_FONT, t.SUMMARY_SECONDARY, bold)
	_add_plain_label(theme, &"SummaryLevelUp", t.SUMMARY_LEVEL_UP_FONT, t.ACCENT, bold)
	_add_plain_label(theme, &"SummaryPoints", t.SUMMARY_POINTS_FONT, t.SUMMARY_SECONDARY, null)
	_add_plain_label(theme, &"SummaryGain", t.SUMMARY_GAIN_FONT, t.TEXT, bold)
	var stats := _bag_box(t.SUMMARY_STATS_BG, t.TRANSPARENT, 0, t.SUMMARY_STATS_PAD_H,
		t.SUMMARY_STATS_PAD_V, t)
	theme.set_type_variation(&"SummaryStatsBox", &"PanelContainer")
	theme.set_stylebox(&"panel", &"SummaryStatsBox", stats)
	_add_plain_label(theme, &"SummaryStatName", t.SUMMARY_STATS_FONT, t.SUMMARY_SECONDARY, null)
	_add_plain_label(theme, &"SummaryStatValue", t.SUMMARY_STATS_FONT, t.ACCENT, bold)
	var hint := _panel_style(t.SUMMARY_HINT_BG, t.ROUND_BUTTON, t)
	hint.shadow_size = 0
	hint.set_content_margin(SIDE_LEFT, t.SUMMARY_HINT_PAD_H)
	hint.set_content_margin(SIDE_RIGHT, t.SUMMARY_HINT_PAD_H)
	hint.set_content_margin(SIDE_TOP, t.SUMMARY_HINT_PAD_V)
	hint.set_content_margin(SIDE_BOTTOM, t.SUMMARY_HINT_PAD_V)
	theme.set_type_variation(&"SummaryHint", &"PanelContainer")
	theme.set_stylebox(&"panel", &"SummaryHint", hint)
	_add_plain_label(theme, &"SummaryHintText", t.SUMMARY_HINT_FONT, t.SUMMARY_SECONDARY, null)


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


# --- Menu Dresseur (jalon 6, T3) ----------------------------------------------------------------


func _add_menu(theme: Theme, bold: Font, t: GDScript) -> void:
	var panel := _panel_style(t.MENU_PANEL_BG, t.RADIUS, t)
	panel.set_content_margin_all(t.MENU_PANEL_PAD)
	theme.set_type_variation(&"MenuPanel", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MenuPanel", panel)

	var pill := _panel_style(t.PANEL_BG, t.ROUND_BUTTON, t)
	pill.shadow_size = 0
	pill.set_content_margin(SIDE_LEFT, t.MENU_ZONE_PAD_H)
	pill.set_content_margin(SIDE_RIGHT, t.MENU_ZONE_PAD_H)
	pill.set_content_margin(SIDE_TOP, t.MENU_ZONE_PAD_V)
	pill.set_content_margin(SIDE_BOTTOM, t.MENU_ZONE_PAD_V)
	theme.set_type_variation(&"MenuZonePill", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MenuZonePill", pill)
	_add_plain_label(theme, &"MenuZoneName", t.FONT_BUTTON, t.TEXT, bold)

	var close_normal := _round_style(t.PANEL_BG, t)
	var close_pressed := _round_style(t.ACCENT, t)
	theme.set_type_variation(&"MenuCloseButton", &"Button")
	for state: StringName in [&"normal", &"hover", &"disabled"]:
		theme.set_stylebox(state, &"MenuCloseButton", close_normal)
	for state: StringName in [&"pressed", &"hover_pressed"]:
		theme.set_stylebox(state, &"MenuCloseButton", close_pressed)
	theme.set_stylebox(&"focus", &"MenuCloseButton", StyleBoxEmpty.new())
	for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_focus_color"]:
		theme.set_color(state, &"MenuCloseButton", t.TEXT)
	for state: StringName in [&"icon_pressed_color", &"icon_hover_pressed_color"]:
		theme.set_color(state, &"MenuCloseButton", t.ACCENT_TEXT)
	theme.set_constant(&"icon_max_width", &"MenuCloseButton", t.BATTLE_BACK_ICON)

	var card_normal := _menu_card_box(t.menu_card_bg(t.MENU_CARD_TINT_DEFAULT),
		t.menu_card_border(t.MENU_CARD_TINT_DEFAULT), t.RADIUS, t)
	var card_pressed := _menu_card_box(t.menu_card_bg_pressed(t.MENU_CARD_TINT_DEFAULT),
		t.ACCENT, t.RADIUS, t)
	_add_flat_button(theme, &"MenuCard", card_normal, card_pressed)
	var lead_normal := _menu_card_box(t.PANEL_BG, t.PANEL_BORDER, t.MENU_LEAD_HEIGHT, t)
	var lead_pressed := _menu_card_box(t.PANEL_BG_STRONG, t.ACCENT, t.MENU_LEAD_HEIGHT, t)
	_add_flat_button(theme, &"MenuLeadCard", lead_normal, lead_pressed)

	var chevron := StyleBoxFlat.new()
	chevron.bg_color = t.tinted(t.TEXT, 0.18)
	chevron.set_corner_radius_all(t.MENU_CARD_CHEVRON)
	chevron.anti_aliasing = true
	theme.set_type_variation(&"MenuCardChevron", &"Panel")
	theme.set_stylebox(&"panel", &"MenuCardChevron", chevron)
	var thumb := StyleBoxFlat.new()
	thumb.bg_color = t.CAPTURE_THUMB_BG
	thumb.border_color = t.CAPTURE_THUMB_BORDER
	thumb.set_border_width_all(t.BORDER_WIDTH)
	thumb.set_corner_radius_all(t.MENU_LEAD_THUMB)
	thumb.anti_aliasing = true
	theme.set_type_variation(&"MenuLeadThumb", &"Panel")
	theme.set_stylebox(&"panel", &"MenuLeadThumb", thumb)
	var bar := StyleBoxFlat.new()
	bar.bg_color = t.NAME_TAG
	bar.set_corner_radius_all(3)
	theme.set_type_variation(&"MenuIdBar", &"Panel")
	theme.set_stylebox(&"panel", &"MenuIdBar", bar)

	_add_plain_label(theme, &"MenuCardTitle", t.MENU_CARD_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"MenuCardCaption", t.MENU_CARD_CAPTION_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"MenuLeadName", t.MENU_LEAD_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"MenuLeadLevel", t.MENU_LEAD_LEVEL_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"MenuLeadHp", t.MENU_LEAD_HP_FONT, t.TEXT, null)
	_add_plain_label(theme, &"MenuName", t.MENU_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"MenuSubtitle", t.MENU_SUBTITLE_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"MenuStat", t.MENU_STAT_FONT, t.TEXT, null)
	_add_label_variation(theme, &"MenuObjective", t.MENU_OBJECTIVE_FONT, t.TEXT_MUTED, t)


func _add_flat_button(theme: Theme, type: StringName, normal: StyleBox, pressed: StyleBox) -> void:
	theme.set_type_variation(type, &"Button")
	for state: StringName in [&"normal", &"hover", &"disabled"]:
		theme.set_stylebox(state, type, normal)
	for state: StringName in [&"pressed", &"hover_pressed"]:
		theme.set_stylebox(state, type, pressed)
	theme.set_stylebox(&"focus", type, StyleBoxEmpty.new())


func _menu_card_box(bg: Color, border: Color, radius: int, t: GDScript) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(t.BORDER_WIDTH)
	box.set_corner_radius_all(radius)
	box.shadow_color = t.SHADOW
	box.shadow_size = t.SHADOW_SIZE
	box.anti_aliasing = true
	return box


# --- Équipe (jalon 6, T7) -------------------------------------------------------------------------


func _add_team(theme: Theme, bold: Font, t: GDScript) -> void:
	var slot := _menu_card_box(t.PANEL_BG, t.PANEL_BORDER, t.RADIUS, t)
	var slot_selected := _menu_card_box(t.PANEL_BG_STRONG, t.ACCENT, t.RADIUS, t)
	slot_selected.set_border_width_all(t.TEAM_SLOT_SELECTED_BORDER)
	slot_selected.shadow_color = t.MOVE_CARD_SELECTED_GLOW
	slot_selected.shadow_size = t.MOVE_CARD_SELECTED_GLOW_SIZE
	var slot_source := _menu_card_box(t.tinted(t.ACCENT, 0.12), t.ACCENT, t.RADIUS, t)
	var slot_target := _menu_card_box(t.PANEL_BG_STRONG, t.ACCENT, t.RADIUS, t)
	slot_target.set_border_width_all(t.TEAM_SLOT_SELECTED_BORDER)
	var slot_empty := _menu_card_box(t.MOVE_CARD_EMPTY_BG, t.MOVE_CARD_EMPTY_BORDER, t.RADIUS, t)
	slot_empty.shadow_size = 0
	for pair: Array in [[&"TeamSlot", slot], [&"TeamSlotSelected", slot_selected],
			[&"TeamSlotSource", slot_source], [&"TeamSlotTarget", slot_target],
			[&"TeamSlotEmpty", slot_empty]]:
		theme.set_type_variation(pair[0], &"Panel")
		theme.set_stylebox(&"panel", pair[0], pair[1])
	var section := _menu_card_box(t.TEAM_SECTION_BG, t.PANEL_BORDER, t.RADIUS, t)
	section.shadow_size = 0
	theme.set_type_variation(&"TeamSection", &"PanelContainer")
	theme.set_stylebox(&"panel", &"TeamSection", section)
	var circle := StyleBoxFlat.new()
	circle.bg_color = t.CAPTURE_THUMB_BG
	circle.border_color = t.CAPTURE_THUMB_BORDER
	circle.set_border_width_all(t.BORDER_WIDTH)
	circle.set_corner_radius_all(t.TEAM_EVO_CIRCLE)
	circle.anti_aliasing = true
	theme.set_type_variation(&"TeamEvoCircle", &"Panel")
	theme.set_stylebox(&"panel", &"TeamEvoCircle", circle)

	for pair: Array in [[&"TeamPill", t.tinted(t.ACCENT, 0.16), t.ACCENT],
			[&"TeamPillAccent", t.ACCENT, t.ACCENT]]:
		var pill := StyleBoxFlat.new()
		pill.bg_color = pair[1]
		pill.border_color = pair[2]
		pill.set_border_width_all(t.BORDER_WIDTH)
		pill.set_corner_radius_all(t.ROUND_BUTTON)
		pill.anti_aliasing = true
		pill.set_content_margin(SIDE_LEFT, t.TYPE_BADGE_PAD_H)
		pill.set_content_margin(SIDE_RIGHT, t.TYPE_BADGE_PAD_H)
		pill.set_content_margin(SIDE_TOP, t.TYPE_BADGE_PAD_V)
		pill.set_content_margin(SIDE_BOTTOM, t.TYPE_BADGE_PAD_V)
		theme.set_type_variation(pair[0], &"PanelContainer")
		theme.set_stylebox(&"panel", pair[0], pill)
	_add_plain_label(theme, &"TeamPillText", t.TYPE_BADGE_FONT, t.ACCENT, bold)
	_add_plain_label(theme, &"TeamPillAccentText", t.TYPE_BADGE_FONT, t.ACCENT_TEXT, bold)

	_add_plain_label(theme, &"TeamSlotName", t.TEAM_SLOT_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"TeamSlotMeta", t.TEAM_SLOT_META_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"TeamCaption", t.TEAM_BAR_LABEL_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"TeamValue", t.TEAM_STAT_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"TeamStat", t.TEAM_STAT_FONT, t.TEXT, null)
	_add_plain_label(theme, &"TeamLevel", t.TEAM_LEVEL_FONT, t.TEXT, null)

	var tab := _button_style(t.BUTTON_BG, true, t)
	var tab_on := _button_style(t.ACCENT, false, t)
	_add_button_variation(theme, &"TeamTab", tab, tab_on, bold, t)
	theme.set_font_size(&"font_size", &"TeamTab", t.TEAM_TAB_FONT)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color"]:
		theme.set_color(state, &"TeamTab", t.TEXT)
	for state: StringName in [&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"TeamTab", t.ACCENT_TEXT)

	var action := _button_style(t.BUTTON_BG, true, t)
	action.set_content_margin(SIDE_LEFT, t.TEAM_SLOT_PAD)
	action.set_content_margin(SIDE_RIGHT, t.TEAM_SLOT_PAD)
	var action_pressed := _button_style(t.ACCENT_PRESSED, false, t)
	var action_on := _button_style(t.ACCENT, false, t)
	for pair: Array in [[&"TeamAction", action, action_pressed],
			[&"TeamActionOn", action_on, action_pressed]]:
		_add_button_variation(theme, pair[0], pair[1], pair[2], bold, t)
		theme.set_font_size(&"font_size", pair[0], t.TEAM_ACTION_FONT)
		theme.set_constant(&"icon_max_width", pair[0], t.TEAM_ACTION_ICON)
		theme.set_constant(&"h_separation", pair[0], t.TEAM_HEADER_GAP)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color",
			&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"TeamActionOn", t.ACCENT_TEXT)
		theme.set_color(state, &"TeamAction", t.TEXT if state in [&"font_color",
			&"font_hover_color", &"font_focus_color"] else t.ACCENT_TEXT)
	for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_focus_color"]:
		theme.set_color(state, &"TeamAction", t.TEXT)
		theme.set_color(state, &"TeamActionOn", t.ACCENT_TEXT)
	for state: StringName in [&"icon_pressed_color", &"icon_hover_pressed_color"]:
		theme.set_color(state, &"TeamAction", t.ACCENT_TEXT)
		theme.set_color(state, &"TeamActionOn", t.ACCENT_TEXT)


# --- Écran Sac du menu et choix du Pokémon (jalon 6, T11) ---------------------------------------


func _add_bag_screen(theme: Theme, bold: Font, t: GDScript) -> void:
	var row := _bag_box(t.PANEL_BG, t.PANEL_BORDER, t.BORDER_WIDTH, t.PICKER_PAD, t.PICKER_PAD, t)
	var row_selected := _bag_box(t.PANEL_BG_STRONG, t.ACCENT, t.PICKER_SELECTED_BORDER,
		t.PICKER_PAD, t.PICKER_PAD, t)
	row_selected.shadow_color = t.MOVE_CARD_SELECTED_GLOW
	row_selected.shadow_size = t.MOVE_CARD_SELECTED_GLOW_SIZE
	var row_off := _bag_box(t.MOVE_CARD_EMPTY_BG, t.MOVE_CARD_EMPTY_BORDER, t.BORDER_WIDTH,
		t.PICKER_PAD, t.PICKER_PAD, t)
	for pair: Array in [[&"PickerRow", row], [&"PickerRowSelected", row_selected],
			[&"PickerRowOff", row_off]]:
		theme.set_type_variation(pair[0], &"PanelContainer")
		theme.set_stylebox(&"panel", pair[0], pair[1])
	var bar := _bag_box(t.tinted(t.SUCCESS, t.RESULT_BG_ALPHA), t.SUCCESS, t.BORDER_WIDTH,
		t.RESULT_PAD_H, t.RESULT_PAD_V, t)
	theme.set_type_variation(&"ResultBar", &"PanelContainer")
	theme.set_stylebox(&"panel", &"ResultBar", bar)
	var refused := _bag_box(t.tinted(t.ACCENT, t.RESULT_BG_ALPHA), t.ACCENT, t.BORDER_WIDTH,
		t.RESULT_PAD_H, t.RESULT_PAD_V, t)
	theme.set_type_variation(&"ResultBarRefused", &"PanelContainer")
	theme.set_stylebox(&"panel", &"ResultBarRefused", refused)
	_add_plain_label(theme, &"BagTabCount", t.BAG_TAB_COUNT_FONT, t.TEXT_MUTED, bold)
	_add_plain_label(theme, &"BagNote", t.BAG_NOTE_FONT, t.ACCENT, bold)
	_add_plain_label(theme, &"BagHint", t.BAG_HINT_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"PickerTitle", t.PICKER_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"PickerName", t.PICKER_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"PickerMeta", t.PICKER_META_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"PickerReason", t.PICKER_META_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"ResultText", t.RESULT_FONT, t.TEXT, bold)


# --- Écran Pokédex du menu (jalon 6, T15) -------------------------------------------------------


func _add_pokedex_screen(theme: Theme, bold: Font, t: GDScript) -> void:
	var panel := _panel_style(t.MENU_PANEL_BG, t.RADIUS, t)
	panel.set_content_margin_all(t.DEX_PANEL_PAD)
	theme.set_type_variation(&"DexPanel", &"PanelContainer")
	theme.set_stylebox(&"panel", &"DexPanel", panel)

	var cell := _bag_box(t.DEX_CELL_BG, t.PANEL_BORDER, t.BORDER_WIDTH, 0, 0, t)
	var cell_selected := _bag_box(t.DEX_CELL_BG, t.ACCENT, t.MOVE_CARD_SELECTED_BORDER, 0, 0, t)
	cell_selected.shadow_color = t.MOVE_CARD_SELECTED_GLOW
	cell_selected.shadow_size = t.MOVE_CARD_SELECTED_GLOW_SIZE
	var cell_unknown := _bag_box(t.MOVE_CARD_EMPTY_BG, t.MOVE_CARD_EMPTY_BORDER, t.BORDER_WIDTH,
		0, 0, t)
	for pair: Array in [[&"DexCell", cell], [&"DexCellSelected", cell_selected],
			[&"DexCellUnknown", cell_unknown]]:
		theme.set_type_variation(pair[0], &"PanelContainer")
		theme.set_stylebox(&"panel", pair[0], pair[1])

	var frame := _bag_box(t.CAPTURE_THUMB_BG, t.CAPTURE_THUMB_BORDER, t.BORDER_WIDTH, 0, 0, t)
	theme.set_type_variation(&"DexSpriteFrame", &"Panel")
	theme.set_stylebox(&"panel", &"DexSpriteFrame", frame)

	var tab := _button_style(t.BUTTON_BG, true, t)
	var tab_on := _button_style(t.ACCENT, false, t)
	_add_button_variation(theme, &"DexTab", tab, tab_on, bold, t)
	theme.set_font_size(&"font_size", &"DexTab", t.DEX_TAB_FONT)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color"]:
		theme.set_color(state, &"DexTab", t.TEXT)
	for state: StringName in [&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"DexTab", t.ACCENT_TEXT)

	var field := _bag_box(t.BUTTON_BG, t.PANEL_BORDER, t.BORDER_WIDTH, t.DEX_SEARCH_PAD_H, 0, t)
	var field_focus := _bag_box(t.BUTTON_BG, t.ACCENT, t.BORDER_WIDTH, t.DEX_SEARCH_PAD_H, 0, t)
	theme.set_type_variation(&"DexSearch", &"LineEdit")
	theme.set_stylebox(&"normal", &"DexSearch", field)
	theme.set_stylebox(&"read_only", &"DexSearch", field)
	theme.set_stylebox(&"focus", &"DexSearch", field_focus)
	theme.set_font_size(&"font_size", &"DexSearch", t.DEX_SEARCH_FONT)
	theme.set_color(&"font_color", &"DexSearch", t.TEXT)
	theme.set_color(&"font_placeholder_color", &"DexSearch", t.TEXT_MUTED)
	theme.set_color(&"caret_color", &"DexSearch", t.ACCENT)
	theme.set_color(&"selection_color", &"DexSearch", t.tinted(t.ACCENT, 0.35))

	_add_plain_label(theme, &"DexTitle", t.DEX_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"DexName", t.DEX_SHEET_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"DexNumber", t.DEX_SHEET_NUMBER_FONT, t.TEXT_MUTED, bold)


# --- Pokédex : composition en trois colonnes (refonte, T3) ---------------------------------------
##   DexHeroPanel (PanelContainer, panneau du portrait), DexFilterPill (Button à bascule en
##   pastille), DexPreviewCard (Button, carte tactile de l'Aperçu), DexCardCaption /
##   DexCardValue / DexDescription / DexPreviewTitle (Label)


func _add_pokedex_layout(theme: Theme, bold: Font, t: GDScript) -> void:
	var hero := _panel_style(t.MENU_PANEL_BG, t.RADIUS, t)
	hero.set_content_margin_all(t.DEX_LAYOUT_HERO_PAD)
	theme.set_type_variation(&"DexHeroPanel", &"PanelContainer")
	theme.set_stylebox(&"panel", &"DexHeroPanel", hero)

	var pill := _button_style(t.BUTTON_BG, true, t)
	pill.set_corner_radius_all(t.DEX_LAYOUT_PILL_RADIUS)
	var pill_on := _button_style(t.ACCENT, false, t)
	pill_on.set_corner_radius_all(t.DEX_LAYOUT_PILL_RADIUS)
	for box: StyleBoxFlat in [pill, pill_on]:
		box.set_content_margin(SIDE_LEFT, t.DEX_LAYOUT_FILTER_PAD)
		box.set_content_margin(SIDE_RIGHT, t.DEX_LAYOUT_FILTER_PAD)
	_add_button_variation(theme, &"DexFilterPill", pill, pill_on, bold, t)
	theme.set_font_size(&"font_size", &"DexFilterPill", t.DEX_LAYOUT_FILTER_FONT)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color"]:
		theme.set_color(state, &"DexFilterPill", t.TEXT)
	for state: StringName in [&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"DexFilterPill", t.ACCENT_TEXT)

	var sheet_tab := _button_style(t.BUTTON_BG, true, t)
	var sheet_tab_on := _button_style(t.ACCENT, false, t)
	for box: StyleBoxFlat in [sheet_tab, sheet_tab_on]:
		box.set_content_margin(SIDE_LEFT, t.DEX_LAYOUT_TAB_PAD)
		box.set_content_margin(SIDE_RIGHT, t.DEX_LAYOUT_TAB_PAD)
	_add_button_variation(theme, &"DexSheetTab", sheet_tab, sheet_tab_on, bold, t)
	theme.set_font_size(&"font_size", &"DexSheetTab", t.DEX_LAYOUT_TAB_FONT)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color"]:
		theme.set_color(state, &"DexSheetTab", t.TEXT)
	for state: StringName in [&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"DexSheetTab", t.ACCENT_TEXT)

	var card := _bag_box(t.TEAM_SECTION_BG, t.PANEL_BORDER, t.BORDER_WIDTH, t.GAP, t.GAP, t)
	var card_pressed := _bag_box(t.tinted(t.ACCENT, 0.25), t.ACCENT, t.BORDER_WIDTH, t.GAP,
		t.GAP, t)
	_add_button_variation(theme, &"DexPreviewCard", card, card_pressed, bold, t)
	theme.set_font_size(&"font_size", &"DexPreviewCard", t.DEX_LAYOUT_PREVIEW_TITLE_FONT)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color",
			&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"DexPreviewCard", t.TEXT)

	_add_plain_label(theme, &"DexHeaderTitle", t.DEX_LAYOUT_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"DexHeaderCounts", t.DEX_LAYOUT_COUNTS_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"DexCardCaption", t.DEX_LAYOUT_CARD_CAPTION_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"DexCardValue", t.DEX_LAYOUT_CARD_VALUE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"DexDescription", t.DEX_LAYOUT_DESC_FONT, t.TEXT, null)
	_add_plain_label(theme, &"DexPreviewTitle", t.DEX_LAYOUT_PREVIEW_TITLE_FONT, t.TEXT, bold)


# --- Pokédex : rapprochement de la maquette (refonte, T4) -------------------------------------
##   Remplace DexPanel / DexHeroPanel par du verre teinté (DEX_GLASS_*), et ajoute :
##   DexHeroRim (Panel, liseré seul, par-dessus le décor du portrait), DexCard (PanelContainer,
##   carte d'un panneau), DexCapsule (PanelContainer, capsule des filtres), DexSegment (Button à
##   bascule, segment de la capsule), DexBackRound (Button rond « ‹ »), DexRefine (Button, capsule
##   fine de la grille), DexTopTitle / DexTopCounts / DexSceneNumber / DexSceneName (Label),
##   DexEvoCircle (Panel). DexSearch, DexSheetTab et DexPreviewCard sont redessinés. Les zones
##   touchables restent de TOUCH_MIN : le dessin est resserré par des marges d'expansion négatives.


## Boîte dessinée plus petite que le contrôle : [param draw_h] de haut, centrée verticalement
## dans [param control_h] (et [param inset_x] de chaque côté).
func _inset(box: StyleBoxFlat, control_h: float, draw_h: float, inset_x: float = 0.0) -> void:
	var dy := -(control_h - draw_h) * 0.5
	box.expand_margin_top = dy
	box.expand_margin_bottom = dy
	box.expand_margin_left = -inset_x
	box.expand_margin_right = -inset_x


func _glass(bg: Color, border: Color, radius: int, t: GDScript) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(t.DEX_GLASS_BORDER_WIDTH)
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	return box


func _add_pokedex_glass(theme: Theme, bold: Font, t: GDScript) -> void:
	var panel := _glass(t.DEX_GLASS_BG, t.DEX_GLASS_BORDER, t.DEX_GLASS_RADIUS, t)
	panel.shadow_color = t.DEX_GLASS_SHADOW
	panel.shadow_size = t.DEX_GLASS_SHADOW_SIZE
	panel.set_content_margin_all(t.DEX_PANEL_PAD)
	theme.set_stylebox(&"panel", &"DexPanel", panel)
	# Portrait : le verre seul (le décor et le contenu se posent dessus), puis le liseré par-dessus.
	var hero := _glass(t.DEX_GLASS_BG, Color(0, 0, 0, 0), t.DEX_GLASS_RADIUS, t)
	hero.set_border_width_all(0)
	hero.shadow_color = t.DEX_GLASS_SHADOW
	hero.shadow_size = t.DEX_GLASS_SHADOW_SIZE
	hero.set_content_margin_all(0)
	theme.set_stylebox(&"panel", &"DexHeroPanel", hero)
	var rim := _glass(Color(0, 0, 0, 0), t.DEX_GLASS_BORDER, t.DEX_GLASS_RADIUS, t)
	rim.draw_center = false
	theme.set_type_variation(&"DexHeroRim", &"Panel")
	theme.set_stylebox(&"panel", &"DexHeroRim", rim)

	var card := _glass(t.DEX_CARD_BG, t.DEX_CARD_BORDER, t.DEX_CARD_RADIUS, t)
	card.set_content_margin_all(t.DEX_CARD_PAD)
	theme.set_type_variation(&"DexCard", &"PanelContainer")
	theme.set_stylebox(&"panel", &"DexCard", card)
	var preview := _glass(t.DEX_CARD_BG, t.DEX_CARD_BORDER, t.DEX_CARD_RADIUS, t)
	var preview_on := _glass(t.tinted(t.ACCENT, 0.22), t.ACCENT, t.DEX_CARD_RADIUS, t)
	_add_button_variation(theme, &"DexPreviewCard", preview, preview_on, bold, t)
	theme.set_font_size(&"font_size", &"DexPreviewCard", t.DEX_LAYOUT_PREVIEW_TITLE_FONT)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color",
			&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"DexPreviewCard", t.TEXT)

	var touch := float(t.TOUCH_MIN)
	var capsule := _glass(t.DEX_GLASS_BG, t.DEX_GLASS_BORDER, t.DEX_CAPSULE_DRAW / 2, t)
	_inset(capsule, touch, t.DEX_CAPSULE_DRAW)
	capsule.set_content_margin(SIDE_LEFT, t.DEX_CAPSULE_PAD)
	capsule.set_content_margin(SIDE_RIGHT, t.DEX_CAPSULE_PAD)
	theme.set_type_variation(&"DexCapsule", &"PanelContainer")
	theme.set_stylebox(&"panel", &"DexCapsule", capsule)
	var segment := StyleBoxFlat.new()
	segment.bg_color = Color(0, 0, 0, 0)
	segment.set_content_margin(SIDE_LEFT, t.DEX_SEGMENT_PAD)
	segment.set_content_margin(SIDE_RIGHT, t.DEX_SEGMENT_PAD)
	var segment_on := _glass(t.DEX_SEGMENT_ON_BG, t.DEX_SEGMENT_ON_BORDER, t.DEX_SEGMENT_DRAW / 2,
		t)
	_inset(segment_on, touch, t.DEX_SEGMENT_DRAW)
	segment_on.set_content_margin(SIDE_LEFT, t.DEX_SEGMENT_PAD)
	segment_on.set_content_margin(SIDE_RIGHT, t.DEX_SEGMENT_PAD)
	_add_button_variation(theme, &"DexSegment", segment, segment_on, bold, t)
	theme.set_font_size(&"font_size", &"DexSegment", t.DEX_SEGMENT_FONT)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color"]:
		theme.set_color(state, &"DexSegment", t.TEXT_MUTED)
	for state: StringName in [&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"DexSegment", t.TEXT)

	var back := _glass(t.DEX_GLASS_BG, t.DEX_GLASS_BORDER, t.DEX_TOP_BACK_DRAW / 2, t)
	var back_on := _glass(t.ACCENT, t.ACCENT, t.DEX_TOP_BACK_DRAW / 2, t)
	for box: StyleBoxFlat in [back, back_on]:
		_inset(box, touch, t.DEX_TOP_BACK_DRAW, (touch - t.DEX_TOP_BACK_DRAW) * 0.5)
	_add_button_variation(theme, &"DexBackRound", back, back_on, bold, t)
	theme.set_color(&"icon_pressed_color", &"DexBackRound", t.ACCENT_TEXT)
	theme.set_color(&"icon_hover_pressed_color", &"DexBackRound", t.ACCENT_TEXT)

	var refine := _glass(t.DEX_CARD_BG, t.DEX_CARD_BORDER, t.DEX_REFINE_DRAW / 2, t)
	var refine_on := _glass(t.tinted(t.ACCENT, 0.25), t.ACCENT, t.DEX_REFINE_DRAW / 2, t)
	for box: StyleBoxFlat in [refine, refine_on]:
		_inset(box, touch, t.DEX_REFINE_DRAW)
		box.set_content_margin(SIDE_LEFT, t.DEX_SEGMENT_PAD)
		box.set_content_margin(SIDE_RIGHT, t.DEX_SEGMENT_PAD)
	_add_button_variation(theme, &"DexRefine", refine, refine_on, bold, t)
	theme.set_font_size(&"font_size", &"DexRefine", t.DEX_REFINE_FONT)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color",
			&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"DexRefine", t.TEXT)

	var field := _glass(t.DEX_GLASS_BG, t.DEX_GLASS_BORDER, t.DEX_SEARCH_DRAW / 2, t)
	var field_focus := _glass(t.DEX_GLASS_BG, t.ACCENT, t.DEX_SEARCH_DRAW / 2, t)
	for box: StyleBoxFlat in [field, field_focus]:
		_inset(box, touch, t.DEX_SEARCH_DRAW)
		box.set_content_margin(SIDE_LEFT, t.DEX_SEGMENT_PAD)
		box.set_content_margin(SIDE_RIGHT, t.DEX_SEGMENT_PAD)
	theme.set_stylebox(&"normal", &"DexSearch", field)
	theme.set_stylebox(&"read_only", &"DexSearch", field)
	theme.set_stylebox(&"focus", &"DexSearch", field_focus)
	theme.set_font_size(&"font_size", &"DexSearch", t.DEX_SEGMENT_FONT)

	var tab := _glass(t.DEX_CARD_BG, t.DEX_CARD_BORDER, t.DEX_CARD_RADIUS, t)
	var tab_on := _glass(t.ACCENT, t.ACCENT, t.DEX_CARD_RADIUS, t)
	for box: StyleBoxFlat in [tab, tab_on]:
		box.set_content_margin(SIDE_LEFT, t.DEX_LAYOUT_TAB_PAD)
		box.set_content_margin(SIDE_RIGHT, t.DEX_LAYOUT_TAB_PAD)
	_add_button_variation(theme, &"DexSheetTab", tab, tab_on, bold, t)
	theme.set_font_size(&"font_size", &"DexSheetTab", t.DEX_TAB_LABEL_FONT)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color"]:
		theme.set_color(state, &"DexSheetTab", t.TEXT)
	for state: StringName in [&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"DexSheetTab", t.ACCENT_TEXT)
	for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_focus_color"]:
		theme.set_color(state, &"DexSheetTab", t.TEXT)
	for state: StringName in [&"icon_pressed_color", &"icon_hover_pressed_color"]:
		theme.set_color(state, &"DexSheetTab", t.ACCENT_TEXT)
	theme.set_constant(&"icon_max_width", &"DexSheetTab", t.DEX_TAB_ICON)
	theme.set_constant(&"h_separation", &"DexSheetTab", 4)

	var circle := StyleBoxFlat.new()
	circle.bg_color = t.DEX_CARD_BG
	circle.border_color = t.DEX_GLASS_BORDER
	circle.set_border_width_all(t.BORDER_WIDTH)
	circle.set_corner_radius_all(t.DEX_LAYOUT_EVO_PREVIEW)
	circle.anti_aliasing = true
	theme.set_type_variation(&"DexEvoCircle", &"Panel")
	theme.set_stylebox(&"panel", &"DexEvoCircle", circle)

	_add_plain_label(theme, &"DexTopTitle", t.DEX_TOP_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"DexTopCounts", t.DEX_TOP_COUNTS_FONT, t.TEXT_MUTED, null)
	for pair: Array in [[&"DexSceneNumber", t.DEX_SHEET_NUMBER_FONT, t.TEXT],
			[&"DexSceneName", t.DEX_SHEET_NAME_FONT, t.TEXT]]:
		_add_plain_label(theme, pair[0], pair[1], pair[2], bold)
		theme.set_color(&"font_shadow_color", pair[0], t.DEX_SCENE_TEXT_SHADOW)
		theme.set_constant(&"shadow_offset_x", pair[0], 0)
		theme.set_constant(&"shadow_offset_y", pair[0], 2)
		theme.set_constant(&"shadow_outline_size", pair[0], t.DEX_SCENE_TEXT_SHADOW_SIZE)


# --- Écran Carte du menu (jalon 6, T20) ---------------------------------------------------------


func _add_map_screen(theme: Theme, bold: Font, t: GDScript) -> void:
	var panel := _panel_style(t.MENU_PANEL_BG, t.RADIUS, t)
	panel.set_content_margin_all(t.MAP_PANEL_PAD)
	theme.set_type_variation(&"MapPanel", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MapPanel", panel)

	var frame := StyleBoxFlat.new()
	frame.bg_color = t.SURFACE_DARK
	frame.border_color = t.PANEL_BORDER
	frame.set_border_width_all(t.MAP_FRAME_BORDER)
	frame.set_corner_radius_all(t.RADIUS)
	frame.anti_aliasing = true
	theme.set_type_variation(&"MapFrame", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MapFrame", frame)

	var label := _bag_box(t.MAP_LABEL_BG, t.PANEL_BORDER, t.BORDER_WIDTH, t.MAP_LABEL_PAD_H,
		t.MAP_LABEL_PAD_V, t)
	var label_on := _bag_box(t.ACCENT, t.ACCENT, t.BORDER_WIDTH, t.MAP_LABEL_PAD_H,
		t.MAP_LABEL_PAD_V, t)
	theme.set_type_variation(&"MapLabel", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MapLabel", label)
	theme.set_type_variation(&"MapLabelOn", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MapLabelOn", label_on)
	_add_plain_label(theme, &"MapLabelText", t.MAP_LABEL_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"MapLabelTextOn", t.MAP_LABEL_FONT, t.ACCENT_TEXT, bold)

	var chip := _bag_box(t.PANEL_BG, t.PANEL_BORDER, t.BORDER_WIDTH, t.MAP_CHIP_PAD_H,
		t.MAP_CHIP_PAD_V, t)
	theme.set_type_variation(&"MapChip", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MapChip", chip)

	var entry := _button_style(t.BUTTON_BG, true, t)
	var entry_pressed := _button_style(t.ACCENT, false, t)
	_add_button_variation(theme, &"MapEntry", entry, entry_pressed, bold, t)
	theme.set_font_size(&"font_size", &"MapEntry", t.MAP_ENTRY_FONT)

	_add_plain_label(theme, &"MapName", t.MAP_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"MapSubtitle", t.MAP_SUBTITLE_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"MapText", t.MAP_TEXT_FONT, t.TEXT, null)
	_add_plain_label(theme, &"MapSection", t.MAP_SECTION_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"MapEntryText", t.MAP_ENTRY_FONT, t.TEXT, bold)


# --- Écran Dresseur du menu (jalon 6, T24) ------------------------------------------------------


func _add_trainer_screen(theme: Theme, bold: Font, t: GDScript) -> void:
	var mute := StyleBoxFlat.new()
	mute.bg_color = t.TRAINER_BADGE_MUTE_BG
	mute.border_color = t.TRAINER_BADGE_MUTE_BORDER
	mute.set_border_width_all(t.BORDER_WIDTH)
	mute.set_corner_radius_all(t.RADIUS)
	mute.anti_aliasing = true
	theme.set_type_variation(&"TrainerBadge", &"PanelContainer")
	theme.set_stylebox(&"panel", &"TrainerBadge", mute)
	var on := mute.duplicate() as StyleBoxFlat
	on.bg_color = t.tinted(t.ACCENT, 0.18)
	on.border_color = t.ACCENT
	on.set_content_margin_all(t.GAP)
	theme.set_type_variation(&"TrainerBadgeOn", &"PanelContainer")
	theme.set_stylebox(&"panel", &"TrainerBadgeOn", on)

	var row := _bag_box(t.TRAINER_MOMENT_BG, Color(0, 0, 0, 0), 0, t.TRAINER_MOMENT_PAD_H,
		t.TRAINER_MOMENT_PAD_V, t)
	row.set_corner_radius_all(t.RADIUS_SMALL)
	var row_pressed := _bag_box(t.tinted(t.ACCENT, 0.25), t.ACCENT, t.BORDER_WIDTH,
		t.TRAINER_MOMENT_PAD_H, t.TRAINER_MOMENT_PAD_V, t)
	row_pressed.set_corner_radius_all(t.RADIUS_SMALL)
	_add_flat_button(theme, &"TrainerMoment", row, row_pressed)
	theme.set_type_variation(&"TrainerMomentBox", &"PanelContainer")
	theme.set_stylebox(&"panel", &"TrainerMomentBox", StyleBoxEmpty.new())

	var link := _button_style(t.BUTTON_BG, true, t)
	var link_pressed := _button_style(t.ACCENT, false, t)
	_add_button_variation(theme, &"TrainerLink", link, link_pressed, bold, t)
	theme.set_font_size(&"font_size", &"TrainerLink", t.TRAINER_LINK_FONT)

	_add_plain_label(theme, &"TrainerSection", t.TRAINER_SECTION_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"TrainerBadgeName", t.TRAINER_BADGE_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"TrainerMomentTitle", t.TRAINER_MOMENT_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"TrainerMomentDetail", t.TRAINER_MOMENT_DETAIL_FONT, t.TEXT, null)
	_add_plain_label(theme, &"TrainerMomentMeta", t.TRAINER_MOMENT_META_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"TrainerStatLabel", t.TRAINER_STAT_LABEL_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"TrainerStatValue", t.TRAINER_STAT_VALUE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"TrainerRow", t.TRAINER_ROW_FONT, t.TEXT, null)
	_add_plain_label(theme, &"TrainerEmpty", t.TRAINER_EMPTY_FONT, t.TEXT_MUTED, null)


# --- Écran Paramètres et ChoiceCards (jalon 6, T28) ---------------------------------------------


func _row_box(bg: Color, border: Color, width: int, pad_h: int, pad_v: int,
		t: GDScript) -> StyleBoxFlat:
	var box := _bag_box(bg, border, width, pad_h, pad_v, t)
	box.set_corner_radius_all(t.RADIUS_SMALL)
	return box


## Ligne de réglage (MM.3) : fond [param bg], filet SETTINGS_ROW_DIVIDER dessous sauf la dernière.
func _settings_row(bg: Color, last: bool, t: GDScript) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = t.SETTINGS_ROW_DIVIDER
	box.border_width_bottom = 0 if last else t.SETTINGS_ROW_DIVIDER_WIDTH
	box.anti_aliasing = true
	box.set_content_margin(SIDE_LEFT, t.SETTINGS_ROW_PAD_H)
	box.set_content_margin(SIDE_RIGHT, t.SETTINGS_ROW_PAD_H)
	box.set_content_margin(SIDE_TOP, t.SETTINGS_ROW_PAD_V)
	box.set_content_margin(SIDE_BOTTOM, t.SETTINGS_ROW_PAD_V)
	return box


func _add_settings_screen(theme: Theme, bold: Font, t: GDScript) -> void:
	# Catégories (MM.3) : verre léger, la choisie en ACCENT avec un halo (bouton à bascule).
	var category := _row_box(t.SETTINGS_CATEGORY_BG, Color(0, 0, 0, 0), 0, t.SETTINGS_ROW_PAD_H,
		0, t)
	var category_on := _row_box(t.ACCENT, Color(0, 0, 0, 0), 0, t.SETTINGS_ROW_PAD_H, 0, t)
	category_on.shadow_color = t.SETTINGS_CATEGORY_GLOW
	category_on.shadow_size = t.SETTINGS_CATEGORY_GLOW_SIZE
	_add_flat_button(theme, &"SettingsCategory", category, category_on)
	theme.set_font(&"font", &"SettingsCategory", bold)
	theme.set_font_size(&"font_size", &"SettingsCategory", t.SETTINGS_CATEGORY_FONT)
	theme.set_constant(&"h_separation", &"SettingsCategory", t.GAP + 8)
	theme.set_constant(&"icon_max_width", &"SettingsCategory", t.SETTINGS_CATEGORY_ICON)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color",
			&"icon_normal_color", &"icon_hover_color", &"icon_focus_color"]:
		theme.set_color(state, &"SettingsCategory", t.TEXT)
	for state: StringName in [&"font_pressed_color", &"font_hover_pressed_color",
			&"icon_pressed_color", &"icon_hover_pressed_color"]:
		theme.set_color(state, &"SettingsCategory", t.ACCENT_TEXT)

	# Lignes (MM.3) : sans fond, un filet dessous (pas sous la dernière : variante « Last ») ;
	# l'interrupteur et l'action sont des boutons (toute la ligne), teintés d'ACCENT à l'appui.
	for last: bool in [false, true]:
		var row := _settings_row(t.SETTINGS_ROW_BG, last, t)
		var row_pressed := _settings_row(t.SETTINGS_ROW_PRESSED_BG, last, t)
		var suffix := "Last" if last else ""
		_add_flat_button(theme, StringName("SettingsRow" + suffix), row, row_pressed)
		theme.set_type_variation(StringName("SettingsRowBox" + suffix), &"PanelContainer")
		theme.set_stylebox(&"panel", StringName("SettingsRowBox" + suffix), row)
	# Carte intérieure qui porte les lignes.
	var list := _glass(t.MENU_GLASS_CARD_BG, t.MENU_GLASS_CARD_BORDER, t.MENU_GLASS_CARD_RADIUS, t)
	list.set_content_margin_all(0)
	theme.set_type_variation(&"SettingsList", &"PanelContainer")
	theme.set_stylebox(&"panel", &"SettingsList", list)

	# Sélecteur « ‹ Valeur › » : pilule dessinée plus basse que sa rangée tactile.
	var touch := float(t.TOUCH_MIN)
	var pill := _glass(t.SETTINGS_PILL_BG, t.SETTINGS_PILL_BORDER, t.SETTINGS_PILL_HEIGHT / 2, t)
	pill.set_content_margin_all(0)
	_inset(pill, touch, t.SETTINGS_PILL_HEIGHT)
	theme.set_type_variation(&"SettingsPill", &"PanelContainer")
	theme.set_stylebox(&"panel", &"SettingsPill", pill)
	var arrow := StyleBoxEmpty.new()
	var arrow_on := _circle(t.tinted(t.ACCENT, 0.3), Color(0, 0, 0, 0), 0,
		t.SETTINGS_ARROW_PRESSED_DRAW)
	_inset(arrow_on, touch, t.SETTINGS_ARROW_PRESSED_DRAW,
		(touch - t.SETTINGS_ARROW_PRESSED_DRAW) * 0.5)
	_add_flat_button(theme, &"SettingsArrow", arrow, arrow_on)
	theme.set_constant(&"icon_max_width", &"SettingsArrow", t.SETTINGS_ARROW_ICON)
	for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_focus_color",
			&"icon_pressed_color", &"icon_hover_pressed_color"]:
		theme.set_color(state, &"SettingsArrow", t.TEXT)
	theme.set_color(&"icon_disabled_color", &"SettingsArrow", t.SETTINGS_ARROW_OFF)

	# Rond de l'action au bout de sa ligne : ACCENT (action principale), icône sombre.
	var action := _circle(t.ACCENT, Color(0, 0, 0, 0), 0, t.SETTINGS_ACTION_ROUND)
	theme.set_type_variation(&"SettingsActionRound", &"PanelContainer")
	theme.set_stylebox(&"panel", &"SettingsActionRound", action)

	_add_plain_label(theme, &"SettingsPanelTitle", t.SETTINGS_PANEL_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"SettingsSubtitle", t.SETTINGS_SUBTITLE_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"SettingsLabel", t.SETTINGS_LABEL_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"SettingsDetail", t.SETTINGS_DETAIL_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"SettingsValue", t.SETTINGS_VALUE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"SettingsState", t.SETTINGS_STATE_FONT, t.TEXT_MUTED, null)

	# ChoiceCards : la carte de l'action (ACCENT) et celle du renoncement (panneau).
	var confirm := _menu_card_box(t.ACCENT, t.ACCENT, t.RADIUS, t)
	var confirm_pressed := _menu_card_box(t.ACCENT_PRESSED, t.ACCENT_PRESSED, t.RADIUS, t)
	_add_flat_button(theme, &"ChoiceConfirm", confirm, confirm_pressed)
	var cancel := _menu_card_box(t.PANEL_BG_STRONG, t.PANEL_BORDER, t.RADIUS, t)
	var cancel_pressed := _menu_card_box(t.tinted(t.ACCENT, 0.25), t.ACCENT, t.RADIUS, t)
	_add_flat_button(theme, &"ChoiceCancel", cancel, cancel_pressed)
	_add_plain_label(theme, &"ChoiceTitle", t.CHOICE_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"ChoiceDetail", t.CHOICE_DETAIL_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"ChoiceConfirmLabel", t.CHOICE_LABEL_FONT, t.ACCENT_TEXT, bold)
	_add_plain_label(theme, &"ChoiceConfirmDetail", t.CHOICE_CARD_DETAIL_FONT, t.ACCENT_TEXT, null)
	_add_plain_label(theme, &"ChoiceCancelLabel", t.CHOICE_LABEL_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"ChoiceCancelDetail", t.CHOICE_CARD_DETAIL_FONT, t.TEXT_MUTED, null)


# --- Écran Boutique (jalon 7, T11) --------------------------------------------------------------


func _add_storage_screen(theme: Theme, bold: Font, t: GDScript) -> void:
	# Zone de dépôt : un cadre ACCENT sans fond, posé par-dessus la colonne visée par un glisser.
	var drop := StyleBoxFlat.new()
	drop.bg_color = t.tinted(t.ACCENT, 0.10)
	drop.border_color = t.ACCENT
	drop.set_border_width_all(t.STORAGE_DROP_BORDER)
	drop.set_corner_radius_all(t.RADIUS)
	drop.anti_aliasing = true
	theme.set_type_variation(&"StorageDropZone", &"Panel")
	theme.set_stylebox(&"panel", &"StorageDropZone", drop)
	# Raison d'un refus : pastille sombre rougie, texte clair.
	var refusal := _panel_style(t.STORAGE_REFUSAL_BG, t.RADIUS_SMALL, t)
	refusal.border_color = t.HP_LOW
	refusal.set_border_width_all(t.BORDER_WIDTH)
	refusal.set_content_margin_all(t.GAP)
	theme.set_type_variation(&"StorageRefusal", &"PanelContainer")
	theme.set_stylebox(&"panel", &"StorageRefusal", refusal)
	# Menu « ⋯ » : opaque (il recouvre des boutons).
	var menu := _panel_style(Color(t.PANEL_BG_STRONG, 1.0), t.RADIUS, t)
	menu.set_content_margin_all(t.GAP)
	theme.set_type_variation(&"StorageMenu", &"PanelContainer")
	theme.set_stylebox(&"panel", &"StorageMenu", menu)
	_add_plain_label(theme, &"StorageRefusalText", t.STORAGE_REFUSAL_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"StorageTitle", t.STORAGE_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"StorageEmpty", t.FONT_BODY, t.TEXT_MUTED, null)


func _add_shop_screen(theme: Theme, bold: Font, t: GDScript) -> void:
	var stepper := _button_style(t.BUTTON_BG, true, t)
	var stepper_pressed := _button_style(t.ACCENT, false, t)
	stepper.set_content_margin_all(0)
	stepper_pressed.set_content_margin_all(0)
	_add_button_variation(theme, &"ShopStepper", stepper, stepper_pressed, bold, t)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color"]:
		theme.set_color(state, &"ShopStepper", t.TEXT)
	for state: StringName in [&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"ShopStepper", t.ACCENT_TEXT)
	for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_focus_color",
			&"icon_disabled_color"]:
		theme.set_color(state, &"ShopStepper", t.TEXT)
	for state: StringName in [&"icon_pressed_color", &"icon_hover_pressed_color"]:
		theme.set_color(state, &"ShopStepper", t.ACCENT_TEXT)
	_add_plain_label(theme, &"ShopName", t.SHOP_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"ShopOwned", t.SHOP_OWNED_FONT, t.TEXT_MUTED, bold)
	_add_plain_label(theme, &"ShopDescription", t.SHOP_DESCRIPTION_FONT, t.DIALOG_NARRATION,
		null)
	_add_plain_label(theme, &"ShopCaption", t.SHOP_CAPTION_FONT, t.TEXT_MUTED, bold)
	_add_plain_label(theme, &"ShopUnitPrice", t.SHOP_UNIT_PRICE_FONT, t.ACCENT, bold)
	_add_plain_label(theme, &"ShopQuantity", t.SHOP_QUANTITY_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"ShopTotal", t.SHOP_TOTAL_FONT, t.ACCENT, bold)
	_add_plain_label(theme, &"ShopCardPrice", t.SHOP_CARD_PRICE_FONT, t.ACCENT, bold)
	_add_plain_label(theme, &"ShopMoney", t.SHOP_MONEY_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"ShopMoneyLabel", t.SHOP_MONEY_LABEL_FONT, t.TEXT_MUTED, bold)


# --- Menu Dresseur rapproché des maquettes (MM.1) ------------------------------------------------


func _circle(bg: Color, border: Color, width: int, diameter: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(diameter)
	box.anti_aliasing = true
	return box


func _add_menu_glass(theme: Theme, bold: Font, t: GDScript) -> void:
	var glass := _glass(t.MENU_GLASS_BG, t.MENU_GLASS_BORDER, t.MENU_GLASS_RADIUS, t)
	glass.shadow_color = t.DEX_GLASS_SHADOW
	glass.shadow_size = t.DEX_GLASS_SHADOW_SIZE
	glass.set_content_margin_all(t.MENU_GLASS_PAD)
	theme.set_type_variation(&"MenuGlass", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MenuGlass", glass)
	var card := _glass(t.MENU_GLASS_CARD_BG, t.MENU_GLASS_CARD_BORDER, t.MENU_GLASS_CARD_RADIUS, t)
	card.set_content_margin_all(t.DEX_CARD_PAD)
	theme.set_type_variation(&"MenuGlassCard", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MenuGlassCard", card)

	# × et ‹ : un rond de verre dessiné plus petit que sa zone tactile (TOUCH_MIN).
	var touch := float(t.TOUCH_MIN)
	var round := _glass(t.MENU_GLASS_BG, t.MENU_GLASS_BORDER, t.MENU_ROUND_DRAW / 2, t)
	var round_on := _glass(t.ACCENT, t.ACCENT, t.MENU_ROUND_DRAW / 2, t)
	for box: StyleBoxFlat in [round, round_on]:
		_inset(box, touch, t.MENU_ROUND_DRAW, (touch - t.MENU_ROUND_DRAW) * 0.5)
	_add_button_variation(theme, &"MenuRoundButton", round, round_on, bold, t)
	for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_focus_color"]:
		theme.set_color(state, &"MenuRoundButton", t.TEXT)
	for state: StringName in [&"icon_pressed_color", &"icon_hover_pressed_color"]:
		theme.set_color(state, &"MenuRoundButton", t.ACCENT_TEXT)
	theme.set_constant(&"icon_max_width", &"MenuRoundButton", t.MENU_ROUND_ICON)

	var status := _glass(t.MENU_GLASS_BG, t.MENU_GLASS_BORDER, t.MENU_STATUS_DRAW / 2, t)
	status.set_content_margin(SIDE_LEFT, t.MENU_STATUS_PAD_H)
	status.set_content_margin(SIDE_RIGHT, t.MENU_STATUS_PAD_H)
	theme.set_type_variation(&"MenuStatusBar", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MenuStatusBar", status)
	var divider := StyleBoxFlat.new()
	divider.bg_color = t.MENU_STATUS_DIVIDER
	theme.set_type_variation(&"MenuStatusDivider", &"Panel")
	theme.set_stylebox(&"panel", &"MenuStatusDivider", divider)
	_add_plain_label(theme, &"MenuStatusText", t.MENU_STATUS_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"MenuScreenTitle", t.MENU_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"MenuScreenCount", t.MENU_TITLE_COUNT_FONT, t.TEXT_MUTED, bold)

	# Grandes cartes illustrées : le fond (teinte posée par la carte) est sous l'illustration ;
	# le liseré est un Panel par-dessus (MenuArtRim, ACCENT quand la carte est enfoncée).
	var art := _glass(t.menu_card_bg(t.MENU_CARD_TINT_DEFAULT), Color(0, 0, 0, 0),
		t.MENU_ART_RADIUS, t)
	art.set_border_width_all(0)
	art.shadow_color = t.SHADOW
	art.shadow_size = t.SHADOW_SIZE
	_add_flat_button(theme, &"MenuArtCard", art, art)
	var rim := _glass(Color(0, 0, 0, 0), t.MENU_GLASS_BORDER, t.MENU_ART_RADIUS, t)
	rim.draw_center = false
	rim.set_border_width_all(t.MENU_ART_RIM_WIDTH)
	theme.set_type_variation(&"MenuArtRim", &"Panel")
	theme.set_stylebox(&"panel", &"MenuArtRim", rim)
	var rim_on := rim.duplicate() as StyleBoxFlat
	rim_on.border_color = t.ACCENT
	rim_on.set_border_width_all(t.MENU_ART_RIM_WIDTH * 2)
	theme.set_type_variation(&"MenuArtRimPressed", &"Panel")
	theme.set_stylebox(&"panel", &"MenuArtRimPressed", rim_on)
	theme.set_type_variation(&"MenuArtRound", &"Panel")
	theme.set_stylebox(&"panel", &"MenuArtRound", _circle(t.tinted(t.TEXT, 0.18),
		t.tinted(t.TEXT, 0.25), t.BORDER_WIDTH, t.MENU_ART_ROUND))
	_add_plain_label(theme, &"MenuArtTitle", t.MENU_CARD_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"MenuArtCaption", t.MENU_CARD_CAPTION_FONT, t.TEXT, null)
	for type: StringName in [&"MenuArtTitle", &"MenuArtCaption"]:
		theme.set_color(&"font_shadow_color", type, t.DEX_SCENE_TEXT_SHADOW)
		theme.set_constant(&"shadow_offset_x", type, 0)
		theme.set_constant(&"shadow_offset_y", type, 2)
	theme.set_type_variation(&"MenuRoundThumb", &"Panel")
	theme.set_stylebox(&"panel", &"MenuRoundThumb", _circle(t.MENU_ROUND_THUMB_BG,
		t.MENU_ROUND_THUMB_BORDER, t.BORDER_WIDTH, t.TOUCH_MIN))
	var lead := _glass(t.MENU_GLASS_CARD_BG, t.MENU_GLASS_CARD_BORDER, t.MENU_LEAD_HEIGHT, t)
	var lead_on := _glass(t.tinted(t.ACCENT, 0.22), t.ACCENT, t.MENU_LEAD_HEIGHT, t)
	_add_flat_button(theme, &"MenuLeadCard", lead, lead_on)

	# Équipe : emplacements, sections, onglets et actions en verre.
	var slot := _glass(t.MENU_GLASS_CARD_BG, t.MENU_GLASS_CARD_BORDER, t.MENU_GLASS_CARD_RADIUS, t)
	var slot_selected := _glass(t.MENU_GLASS_SELECTED_BG, t.ACCENT, t.MENU_GLASS_CARD_RADIUS, t)
	slot_selected.set_border_width_all(t.TEAM_SLOT_SELECTED_BORDER)
	slot_selected.shadow_color = t.MOVE_CARD_SELECTED_GLOW
	slot_selected.shadow_size = t.MOVE_CARD_SELECTED_GLOW_SIZE
	var slot_source := _glass(t.tinted(t.ACCENT, 0.12), t.ACCENT, t.MENU_GLASS_CARD_RADIUS, t)
	var slot_target := _glass(t.MENU_GLASS_BG, t.ACCENT, t.MENU_GLASS_CARD_RADIUS, t)
	slot_target.set_border_width_all(t.TEAM_SLOT_SELECTED_BORDER)
	var slot_empty := _glass(t.tinted(t.MENU_GLASS_CARD_BG, 0.2), t.tinted(t.TEXT, 0.08),
		t.MENU_GLASS_CARD_RADIUS, t)
	for pair: Array in [[&"TeamSlot", slot], [&"TeamSlotSelected", slot_selected],
			[&"TeamSlotSource", slot_source], [&"TeamSlotTarget", slot_target],
			[&"TeamSlotEmpty", slot_empty]]:
		theme.set_stylebox(&"panel", pair[0], pair[1])
	var section := _glass(t.MENU_GLASS_CARD_BG, t.MENU_GLASS_CARD_BORDER, t.MENU_GLASS_CARD_RADIUS, t)
	theme.set_stylebox(&"panel", &"TeamSection", section)
	theme.set_stylebox(&"panel", &"TeamEvoCircle", _circle(t.MENU_ROUND_THUMB_BG,
		t.MENU_ROUND_THUMB_BORDER, t.BORDER_WIDTH, t.TEAM_EVO_CIRCLE))

	var tab := _glass(t.MENU_GLASS_CARD_BG, t.MENU_GLASS_CARD_BORDER, t.MENU_GLASS_CARD_RADIUS, t)
	var tab_on := _glass(t.ACCENT, t.ACCENT, t.MENU_GLASS_CARD_RADIUS, t)
	_add_button_variation(theme, &"MenuTab", tab, tab_on, bold, t)
	theme.set_font_size(&"font_size", &"MenuTab", t.TEAM_TAB_FONT)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color",
			&"icon_normal_color", &"icon_hover_color", &"icon_focus_color"]:
		theme.set_color(state, &"MenuTab", t.TEXT)
	for state: StringName in [&"font_pressed_color", &"font_hover_pressed_color",
			&"icon_pressed_color", &"icon_hover_pressed_color"]:
		theme.set_color(state, &"MenuTab", t.ACCENT_TEXT)
	theme.set_constant(&"icon_max_width", &"MenuTab", t.DEX_TAB_ICON)
	theme.set_constant(&"h_separation", &"MenuTab", t.TEAM_HEADER_GAP)

	var action := _glass(t.MENU_GLASS_BG, t.tinted(t.TEXT, 0.4), t.MENU_GLASS_CARD_RADIUS, t)
	var action_pressed := _glass(t.ACCENT_PRESSED, t.ACCENT_PRESSED, t.MENU_GLASS_CARD_RADIUS, t)
	var action_on := _glass(t.ACCENT, t.ACCENT, t.MENU_GLASS_CARD_RADIUS, t)
	for box: StyleBoxFlat in [action, action_pressed, action_on]:
		box.set_content_margin(SIDE_LEFT, t.TEAM_SLOT_PAD)
		box.set_content_margin(SIDE_RIGHT, t.TEAM_SLOT_PAD)
	for pair: Array in [[&"MenuAction", action], [&"MenuActionOn", action_on]]:
		_add_button_variation(theme, pair[0], pair[1], action_pressed, bold, t)
		theme.set_font_size(&"font_size", pair[0], t.TEAM_ACTION_FONT)
		theme.set_constant(&"icon_max_width", pair[0], t.TEAM_ACTION_ICON)
		theme.set_constant(&"h_separation", pair[0], t.TEAM_HEADER_GAP)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color",
			&"icon_normal_color", &"icon_hover_color", &"icon_focus_color"]:
		theme.set_color(state, &"MenuAction", t.TEXT)
		theme.set_color(state, &"MenuActionOn", t.ACCENT_TEXT)
	for state: StringName in [&"font_pressed_color", &"font_hover_pressed_color",
			&"icon_pressed_color", &"icon_hover_pressed_color"]:
		theme.set_color(state, &"MenuAction", t.ACCENT_TEXT)
		theme.set_color(state, &"MenuActionOn", t.ACCENT_TEXT)

	# Sac : onglets (icône peinte, nom, légende, compteur rond), cartes et cibles en verre.
	var bag_tab := _glass(t.MENU_GLASS_CARD_BG, t.MENU_GLASS_CARD_BORDER, t.MENU_GLASS_CARD_RADIUS, t)
	var bag_tab_on := _glass(t.MENU_GLASS_SELECTED_BG, t.ACCENT, t.MENU_GLASS_CARD_RADIUS, t)
	bag_tab_on.set_border_width_all(t.BAG_TAB_SELECTED_BORDER)
	var bag_card := _glass(t.MENU_GLASS_CARD_BG, t.MENU_GLASS_CARD_BORDER, t.MENU_GLASS_CARD_RADIUS, t)
	var bag_card_on := _glass(t.MENU_GLASS_SELECTED_BG, t.ACCENT, t.MENU_GLASS_CARD_RADIUS, t)
	bag_card_on.set_border_width_all(t.MOVE_CARD_SELECTED_BORDER)
	bag_card_on.shadow_color = t.MOVE_CARD_SELECTED_GLOW
	bag_card_on.shadow_size = t.MOVE_CARD_SELECTED_GLOW_SIZE
	for box: StyleBoxFlat in [bag_tab, bag_tab_on]:
		box.set_content_margin(SIDE_LEFT, t.BAG_TAB_PAD_H)
		box.set_content_margin(SIDE_RIGHT, t.BAG_TAB_PAD_H / 2)
		box.set_content_margin(SIDE_TOP, 8)
		box.set_content_margin(SIDE_BOTTOM, 8)
	for box: StyleBoxFlat in [bag_card, bag_card_on]:
		box.set_content_margin(SIDE_LEFT, t.BAG_CARD_PAD_H)
		box.set_content_margin(SIDE_RIGHT, t.BAG_CARD_PAD_H)
		box.set_content_margin(SIDE_TOP, t.BAG_CARD_PAD_V)
		box.set_content_margin(SIDE_BOTTOM, t.BAG_CARD_PAD_V)
	var row := _glass(t.MENU_GLASS_CARD_BG, t.MENU_GLASS_CARD_BORDER, t.MENU_GLASS_CARD_RADIUS, t)
	var row_on := _glass(t.MENU_GLASS_SELECTED_BG, t.ACCENT, t.MENU_GLASS_CARD_RADIUS, t)
	row_on.set_border_width_all(t.PICKER_SELECTED_BORDER)
	var row_off := _glass(t.tinted(t.MENU_GLASS_CARD_BG, 0.25), t.tinted(t.TEXT, 0.08),
		t.MENU_GLASS_CARD_RADIUS, t)
	for box: StyleBoxFlat in [row, row_on, row_off]:
		box.set_content_margin_all(t.PICKER_PAD)
	for pair: Array in [[&"MenuBagTab", bag_tab], [&"MenuBagTabSelected", bag_tab_on],
			[&"MenuBagCard", bag_card], [&"MenuBagCardSelected", bag_card_on],
			[&"MenuPickerRow", row], [&"MenuPickerRowSelected", row_on],
			[&"MenuPickerRowOff", row_off]]:
		theme.set_type_variation(pair[0], &"PanelContainer")
		theme.set_stylebox(&"panel", pair[0], pair[1])
	theme.set_type_variation(&"MenuCountRound", &"PanelContainer")
	var count := _circle(t.tinted(t.TEXT, 0.12), Color(0, 0, 0, 0), 0, t.BAG_TAB_COUNT_WIDTH)
	count.set_content_margin_all(4)
	theme.set_stylebox(&"panel", &"MenuCountRound", count)
	_add_plain_label(theme, &"MenuBagTabName", t.BAG_TAB_COUNT_FONT + 4, t.TEXT, bold)
	_add_plain_label(theme, &"MenuBagTabCaption", t.BAG_TAB_CAPTION_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"MenuTargetsTitle", t.BAG_TARGETS_TITLE_FONT, t.TEXT, bold)


# --- Menu Dresseur rapproché des maquettes (MM.2) : Carte et Dresseur ------------------------------


func _add_shadowed_label(theme: Theme, type: StringName, size: int, color: Color,
		font: Font, t: GDScript) -> void:
	_add_plain_label(theme, type, size, color, font)
	theme.set_color(&"font_shadow_color", type, t.DEX_SCENE_TEXT_SHADOW)
	theme.set_constant(&"shadow_offset_x", type, 0)
	theme.set_constant(&"shadow_offset_y", type, 2)
	theme.set_constant(&"shadow_outline_size", type, t.DEX_SCENE_TEXT_SHADOW_SIZE)


func _add_menu_mm2(theme: Theme, bold: Font, t: GDScript) -> void:
	# Carte : cadre de l'illustration et panneau de la zone en verre.
	var frame := _glass(t.SURFACE_DARK, t.MENU_GLASS_BORDER, t.MENU_GLASS_RADIUS, t)
	frame.shadow_color = t.DEX_GLASS_SHADOW
	frame.shadow_size = t.DEX_GLASS_SHADOW_SIZE
	theme.set_stylebox(&"panel", &"MapFrame", frame)
	var panel := _glass(t.MENU_GLASS_BG, t.MENU_GLASS_BORDER, t.MENU_GLASS_RADIUS, t)
	panel.shadow_color = t.DEX_GLASS_SHADOW
	panel.shadow_size = t.DEX_GLASS_SHADOW_SIZE
	panel.set_content_margin_all(t.MENU_GLASS_PAD)
	theme.set_stylebox(&"panel", &"MapPanel", panel)
	var strip := _glass(t.MENU_GLASS_BG, t.MENU_GLASS_BORDER, t.MENU_GLASS_RADIUS, t)
	strip.set_content_margin_all(t.MAP_STRIP_PAD)
	theme.set_type_variation(&"MapStrip", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MapStrip", strip)
	var section := _glass(t.MENU_GLASS_CARD_BG, t.MENU_GLASS_CARD_BORDER, t.MENU_GLASS_CARD_RADIUS, t)
	section.set_content_margin_all(t.DEX_CARD_PAD)
	theme.set_type_variation(&"MapSectionCard", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MapSectionCard", section)
	var hero := _glass(t.SURFACE_DARK, t.MENU_GLASS_CARD_BORDER, t.MAP_HERO_RADIUS, t)
	theme.set_type_variation(&"MapHero", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MapHero", hero)

	# Étiquettes : verre sombre ; lieu courant en ACCENT ; zone du panneau cerclée d'ACCENT.
	var label := _bag_box(t.MAP_LABEL_BG, t.MENU_GLASS_BORDER, t.BORDER_WIDTH,
		t.MAP_LABEL_PAD_H, t.MAP_LABEL_PAD_V, t)
	label.set_corner_radius_all(t.MAP_LABEL_FONT * 2)
	var label_on := label.duplicate() as StyleBoxFlat
	label_on.bg_color = t.ACCENT
	label_on.border_color = t.ACCENT
	var label_sel := label.duplicate() as StyleBoxFlat
	label_sel.border_color = t.ACCENT
	label_sel.set_border_width_all(t.MAP_LABEL_SELECTED_BORDER)
	for pair: Array in [[&"MapLabel", label], [&"MapLabelOn", label_on],
			[&"MapLabelSelected", label_sel]]:
		theme.set_type_variation(pair[0], &"PanelContainer")
		theme.set_stylebox(&"panel", pair[0], pair[1])
	theme.set_type_variation(&"MapPortrait", &"Panel")
	theme.set_stylebox(&"panel", &"MapPortrait", _circle(t.MAP_PORTRAIT_BG, t.ACCENT,
		t.MAP_PORTRAIT_BORDER, t.TOUCH_MIN))

	# Panneau : nom sur l'image, « Tu es ici », cellules des Pokémon et des objets.
	_add_shadowed_label(theme, &"MapHeroName", t.MAP_NAME_FONT, t.TEXT, bold, t)
	_add_shadowed_label(theme, &"MapHeroSubtitle", t.MAP_SUBTITLE_FONT, t.TEXT, null, t)
	var here := _bag_box(t.ACCENT, t.ACCENT, 0, 14, 4, t)
	here.set_corner_radius_all(t.MAP_HERE_FONT * 2)
	theme.set_type_variation(&"MapHere", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MapHere", here)
	_add_plain_label(theme, &"MapHereText", t.MAP_HERE_FONT, t.ACCENT_TEXT, bold)
	var cell := _glass(Color(0, 0, 0, 0), Color(0, 0, 0, 0), t.MENU_GLASS_CARD_RADIUS, t)
	cell.set_border_width_all(0)
	var cell_on := _glass(t.tinted(t.ACCENT, 0.2), t.ACCENT, t.MENU_GLASS_CARD_RADIUS, t)
	_add_flat_button(theme, &"MapEntry", cell, cell_on)
	theme.set_type_variation(&"MapItemCell", &"PanelContainer")
	theme.set_stylebox(&"panel", &"MapItemCell", StyleBoxEmpty.new())

	# Bandeau du bas : carte « Exploration » et vignettes des zones.
	_add_plain_label(theme, &"MapExploreTitle", t.MAP_EXPLORE_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"MapExploreText", t.MAP_EXPLORE_TEXT_FONT, t.TEXT_MUTED, null)
	var thumb := _glass(t.SURFACE_DARK, Color(0, 0, 0, 0), t.MAP_THUMB_RADIUS, t)
	thumb.set_border_width_all(0)
	_add_flat_button(theme, &"MapThumb", thumb, thumb)
	var rim := _glass(Color(0, 0, 0, 0), t.MENU_GLASS_BORDER, t.MAP_THUMB_RADIUS, t)
	rim.draw_center = false
	var rim_on := rim.duplicate() as StyleBoxFlat
	rim_on.border_color = t.ACCENT
	rim_on.set_border_width_all(t.MAP_THUMB_RIM)
	for pair: Array in [[&"MapThumbRim", rim], [&"MapThumbRimOn", rim_on]]:
		theme.set_type_variation(pair[0], &"Panel")
		theme.set_stylebox(&"panel", pair[0], pair[1])
	_add_shadowed_label(theme, &"MapThumbName", t.MAP_THUMB_NAME_FONT, t.TEXT, bold, t)

	# Dresseur : badges en verre (silhouette commune et « ??? » tant qu'ils ne sont pas obtenus).
	var badge := _glass(t.MENU_GLASS_CARD_BG, t.MENU_GLASS_CARD_BORDER, t.MENU_GLASS_CARD_RADIUS, t)
	badge.set_content_margin_all(8)
	var badge_on := _glass(t.tinted(t.ACCENT, 0.16), t.ACCENT, t.MENU_GLASS_CARD_RADIUS, t)
	badge_on.set_content_margin_all(8)
	theme.set_stylebox(&"panel", &"TrainerBadge", badge)
	theme.set_stylebox(&"panel", &"TrainerBadgeOn", badge_on)
	_add_plain_label(theme, &"TrainerBadgeUnknown", t.TRAINER_BADGE_UNKNOWN_FONT, t.TEXT_MUTED,
		bold)
	var moment := _glass(t.MENU_GLASS_CARD_BG, Color(0, 0, 0, 0), t.MENU_GLASS_CARD_RADIUS, t)
	moment.set_border_width_all(0)
	var moment_on := _glass(t.tinted(t.ACCENT, 0.2), t.ACCENT, t.MENU_GLASS_CARD_RADIUS, t)
	for box: StyleBoxFlat in [moment, moment_on]:
		box.set_content_margin(SIDE_LEFT, t.TRAINER_MOMENT_PAD_H)
		box.set_content_margin(SIDE_RIGHT, t.TRAINER_MOMENT_PAD_H)
		box.set_content_margin(SIDE_TOP, t.TRAINER_MOMENT_PAD_V)
		box.set_content_margin(SIDE_BOTTOM, t.TRAINER_MOMENT_PAD_V)
	_add_flat_button(theme, &"TrainerMoment", moment, moment_on)
	var team := _glass(t.MENU_GLASS_CARD_BG, t.MENU_GLASS_CARD_BORDER, t.MENU_GLASS_CARD_RADIUS, t)
	team.set_content_margin_all(12)
	theme.set_type_variation(&"TrainerTeamCard", &"PanelContainer")
	theme.set_stylebox(&"panel", &"TrainerTeamCard", team)
	_add_plain_label(theme, &"TrainerTeamName", t.TRAINER_TEAM_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"TrainerTeamLevel", t.TRAINER_TEAM_LEVEL_FONT, t.TEXT_MUTED, bold)
	var link := _glass(t.MENU_GLASS_SELECTED_BG, t.tinted(t.TEXT, 0.3), t.MENU_GLASS_CARD_RADIUS, t)
	var link_pressed := _glass(t.ACCENT, t.ACCENT, t.MENU_GLASS_CARD_RADIUS, t)
	_add_button_variation(theme, &"TrainerLink", link, link_pressed, bold, t)
	theme.set_font_size(&"font_size", &"TrainerLink", t.TRAINER_LINK_FONT)


## Carte de présentation du Champion (jalon 10, T5) : verre sombre, liseré ACCENT à gauche.
func _add_champion_card(theme: Theme, bold: Font, t: GDScript) -> void:
	var card := _panel_style(t.CHAMPION_CARD_BG, t.CHAMPION_CARD_RADIUS, t)
	card.border_width_left = t.CHAMPION_CARD_ACCENT_WIDTH
	card.border_color = t.ACCENT
	card.set_content_margin(SIDE_LEFT, t.CHAMPION_CARD_PAD_H)
	card.set_content_margin(SIDE_RIGHT, t.CHAMPION_CARD_PAD_H)
	card.set_content_margin(SIDE_TOP, t.CHAMPION_CARD_PAD_V)
	card.set_content_margin(SIDE_BOTTOM, t.CHAMPION_CARD_PAD_V)
	theme.set_type_variation(&"ChampionCard", &"PanelContainer")
	theme.set_stylebox(&"panel", &"ChampionCard", card)
	_add_plain_label(theme, &"ChampionCardName", t.CHAMPION_CARD_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"ChampionCardTitle", t.CHAMPION_CARD_TITLE_FONT, t.TEXT_MUTED, null)


# --- Écran titre (OUV.1, dossier 13 §5.2) --------------------------------------------------------


func _title_card(bg: Color, border: Color, width: int, t: GDScript) -> StyleBoxFlat:
	var box := _glass(bg, border, t.TITLE_CARD_RADIUS, t)
	box.set_border_width_all(width)
	box.set_content_margin(SIDE_LEFT, t.TITLE_CARD_PAD_H)
	box.set_content_margin(SIDE_RIGHT, t.TITLE_CARD_PAD_H)
	box.set_content_margin(SIDE_TOP, t.TITLE_CARD_PAD_V)
	box.set_content_margin(SIDE_BOTTOM, t.TITLE_CARD_PAD_V)
	box.shadow_color = t.SHADOW
	box.shadow_size = t.SHADOW_SIZE
	return box


func _add_title_screen(theme: Theme, bold: Font, t: GDScript) -> void:
	var card := _title_card(t.TITLE_CARD_BG, t.TITLE_CARD_BORDER, t.TITLE_CARD_BORDER_WIDTH, t)
	var card_on := _title_card(t.TITLE_CARD_PRESSED_BG, t.ACCENT, t.TITLE_CARD_BORDER_WIDTH, t)
	_add_flat_button(theme, &"TitleCard", card, card_on)
	var featured := _title_card(t.TITLE_CARD_BG, t.ACCENT, t.TITLE_CARD_FEATURED_BORDER_WIDTH, t)
	featured.shadow_color = t.TITLE_CARD_GLOW
	featured.shadow_size = t.TITLE_CARD_GLOW_SIZE
	var featured_on := featured.duplicate() as StyleBoxFlat
	featured_on.bg_color = t.TITLE_CARD_PRESSED_BG
	_add_flat_button(theme, &"TitleCardFeatured", featured, featured_on)
	_add_plain_label(theme, &"TitleEntryLabel", t.TITLE_ENTRY_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"TitleContinueTitle", t.TITLE_CONTINUE_TITLE_FONT, t.ACCENT, bold)
	_add_plain_label(theme, &"TitleContinueName", t.TITLE_CONTINUE_NAME_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"TitleContinueZone", t.TITLE_CONTINUE_ZONE_FONT, t.TEXT_MUTED, null)
	_add_plain_label(theme, &"TitleContinueStat", t.TITLE_CONTINUE_STAT_FONT, t.TEXT, null)
	var divider := StyleBoxFlat.new()
	divider.bg_color = t.TITLE_CONTINUE_DIVIDER
	theme.set_type_variation(&"TitleDivider", &"Panel")
	theme.set_stylebox(&"panel", &"TitleDivider", divider)
	var message := _panel_style(t.TITLE_MESSAGE_BG, t.RADIUS_SMALL, t)
	message.border_width_left = t.CHAMPION_CARD_ACCENT_WIDTH
	message.border_color = t.ACCENT
	message.set_content_margin(SIDE_LEFT, t.PAD)
	message.set_content_margin(SIDE_RIGHT, t.PAD)
	message.set_content_margin(SIDE_TOP, t.GAP)
	message.set_content_margin(SIDE_BOTTOM, t.GAP)
	theme.set_type_variation(&"TitleMessage", &"PanelContainer")
	theme.set_stylebox(&"panel", &"TitleMessage", message)
	_add_plain_label(theme, &"TitleMessageText", t.TITLE_MESSAGE_FONT, t.TEXT, null)


# --- Écran de prénom (OUV.2) ------------------------------------------------------------------


func _add_name_entry(theme: Theme, bold: Font, t: GDScript) -> void:
	var panel := _glass(t.NAME_PANEL_BG, t.ACCENT, t.NAME_PANEL_RADIUS, t)
	panel.set_border_width_all(t.NAME_PANEL_BORDER_WIDTH)
	panel.shadow_color = t.NAME_PANEL_GLOW
	panel.shadow_size = t.NAME_PANEL_GLOW_SIZE
	panel.set_content_margin_all(t.NAME_PANEL_PAD)
	theme.set_type_variation(&"NamePanel", &"PanelContainer")
	theme.set_stylebox(&"panel", &"NamePanel", panel)

	var field := StyleBoxFlat.new()
	field.bg_color = t.NAME_FIELD_BG
	field.set_corner_radius_all(t.NAME_FIELD_RADIUS)
	field.anti_aliasing = true
	field.set_content_margin(SIDE_LEFT, t.NAME_FIELD_PAD_H)
	field.set_content_margin(SIDE_RIGHT, t.NAME_FIELD_PAD_H + t.NAME_COUNTER_WIDTH)
	var focus := field.duplicate() as StyleBoxFlat
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = t.ACCENT
	focus.set_border_width_all(t.NAME_FIELD_FOCUS_WIDTH)
	theme.set_type_variation(&"NameField", &"LineEdit")
	theme.set_stylebox(&"normal", &"NameField", field)
	theme.set_stylebox(&"read_only", &"NameField", field)
	theme.set_stylebox(&"focus", &"NameField", focus)
	theme.set_font(&"font", &"NameField", bold)
	theme.set_font_size(&"font_size", &"NameField", t.NAME_FIELD_FONT)
	theme.set_color(&"font_color", &"NameField", t.NAME_FIELD_TEXT)
	theme.set_color(&"font_placeholder_color", &"NameField", t.NAME_COUNTER_COLOR)
	theme.set_color(&"caret_color", &"NameField", t.NAME_FIELD_TEXT)
	theme.set_color(&"selection_color", &"NameField", t.tinted(t.ACCENT, 0.45))
	theme.set_constant(&"caret_width", &"NameField", 3)

	_add_plain_label(theme, &"NameTitle", t.NAME_TITLE_FONT, t.TEXT, bold)
	_add_plain_label(theme, &"NameCounter", t.NAME_COUNTER_FONT, t.NAME_COUNTER_COLOR, null)
	_add_plain_label(theme, &"NameHelp", t.NAME_HELP_FONT, t.ACCENT, null)

	var chip := _glass(t.BUTTON_BG, t.PANEL_BORDER, t.NAME_CHIP_RADIUS, t)
	chip.set_border_width_all(t.BORDER_WIDTH)
	var chip_on := _glass(t.ACCENT, t.ACCENT, t.NAME_CHIP_RADIUS, t)
	for type: StringName in [&"NameChip", &"NameChipSelected"]:
		var normal := chip if type == &"NameChip" else chip_on
		_add_flat_button(theme, type, normal, chip_on)
		theme.set_font(&"font", type, bold)
		theme.set_font_size(&"font_size", type, t.NAME_CHIP_FONT)
		var text: Color = t.TEXT if type == &"NameChip" else t.ACCENT_TEXT
		for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color"]:
			theme.set_color(state, type, text)
		for state: StringName in [&"font_pressed_color", &"font_hover_pressed_color"]:
			theme.set_color(state, type, t.ACCENT_TEXT)

	var validate := _glass(t.ACCENT, t.ACCENT, t.NAME_CHIP_RADIUS, t)
	var validate_on := _glass(t.ACCENT_PRESSED, t.ACCENT_PRESSED, t.NAME_CHIP_RADIUS, t)
	var validate_off := _glass(t.tinted(t.ACCENT, t.NAME_VALIDATE_DISABLED_ALPHA),
		t.tinted(t.ACCENT, t.NAME_VALIDATE_DISABLED_ALPHA), t.NAME_CHIP_RADIUS, t)
	_add_flat_button(theme, &"NameValidate", validate, validate_on)
	theme.set_stylebox(&"disabled", &"NameValidate", validate_off)
	theme.set_font(&"font", &"NameValidate", bold)
	theme.set_font_size(&"font_size", &"NameValidate", t.FONT_BUTTON)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color",
			&"font_pressed_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"NameValidate", t.ACCENT_TEXT)
	theme.set_color(&"font_disabled_color", &"NameValidate",
		t.tinted(t.ACCENT_TEXT, t.NAME_VALIDATE_DISABLED_ALPHA * 2.0))
