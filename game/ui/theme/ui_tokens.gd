class_name UiTokens
extends RefCounted
## Tokens de l'UI 2026 (skill ui-theme-2026) : seule source des couleurs, tailles et durées.
##
## Aucun écran ni composant ne met de couleur ou de taille en dur : tout vient d'ici,
## directement ou via le Theme global game/ui/theme/ui_theme.tres (généré à partir de
## ces constantes par tools/build_ui_theme.gd). Tailles en pixels de la référence 1080 p.

# --- Couleurs ---------------------------------------------------------------------------

const PANEL_BG := Color(0.10, 0.14, 0.20, 0.82)
const PANEL_BG_STRONG := Color(0.08, 0.11, 0.16, 0.92)
const PANEL_BORDER := Color(1, 1, 1, 0.14)
const ACCENT := Color("#F5C542")
const ACCENT_TEXT := Color("#1C1C1C")
const TEXT := Color("#FFFFFF")
const TEXT_MUTED := Color("#B8C4D6")
## Étiquette de nom et boîte claire de la planche v1 : remplacées pour les dialogues par la
## boîte sombre de la bible UI/UX §3 (DIALOG_PANEL_BG), gardées pour d'autres écrans clairs.
const NAME_TAG := Color("#3E7BD6")
const DIALOG_BG := Color(0.97, 0.97, 0.99, 0.96)
const DIALOG_TEXT := Color("#1E2530")
## Surface sombre des panneaux « cinéma » (boîte de dialogue), opaque ; ses variantes
## translucides en dérivent.
const SURFACE_DARK := Color(0.06, 0.09, 0.13)
## Fond de la boîte de dialogue : SURFACE_DARK à ~88 % (le décor transparaît à peine, le
## texte reste lisible sur un intérieur clair comme sur l'herbe du village).
const DIALOG_PANEL_BG := Color(0.06, 0.09, 0.13, 0.88)
## Nom du locuteur (au-dessus du texte, dans le panneau).
const DIALOG_SPEAKER := Color("#F5C542")
## Narration (Examiner, Observer) : italique, blanc légèrement adouci.
const DIALOG_NARRATION := Color("#DDE5F0")
const HP_HIGH := Color("#4CD964")
const HP_MID := Color("#F5C542")
const HP_LOW := Color("#FF5A4F")
const SUCCESS := Color("#4CD964")
const SHADOW := Color(0, 0, 0, 0.35)
## Ombre portée du texte posé directement sur le monde (titre de zone).
const TEXT_SHADOW := Color(0, 0, 0, 0.45)
const TRANSPARENT := Color(0, 0, 0, 0)
## PANEL_BG entièrement transparent : fin des dégradés de panneau (sans virer au gris).
const PANEL_BG_CLEAR := Color(0.10, 0.14, 0.20, 0.0)
## Rideau des transitions (quasi noir bleuté) ; même valeur que le fond des petites pièces
## (rendering/environment/defaults/default_clear_color).
const FADE_COLOR := Color(0.02, 0.03, 0.05)

# --- Formes -----------------------------------------------------------------------------

const RADIUS := 16
const RADIUS_SMALL := 10
const BORDER_WIDTH := 2
const SHADOW_SIZE := 12
const PAD := 24
const GAP := 16
## Marge de bord d'écran : rien d'interactif plus près des bords (caméra perforée du S24).
const SAFE_MARGIN := 48
## Zone touchable minimale (≈ 48 dp sur S24).
const TOUCH_MIN := 128

# --- Typographie --------------------------------------------------------------------------

const FONT_TITLE := 44
const FONT_BUTTON := 36
const FONT_BODY := 32
const FONT_CAPTION := 24
## Graisse ajoutée à la police par défaut pour les titres (en attendant Barlow).
const FONT_BOLD_EMBOLDEN := 0.6
const TEXT_SHADOW_OFFSET := 2

# --- Animations (secondes) ------------------------------------------------------------------

const ANIM_MICRO := 0.12
const ANIM_PANEL := 0.3
## Fondu au noir d'un changement de carte : descente du rideau, puis levée (≈ 0,45 s au total).
const ANIM_FADE_OUT := 0.2
const ANIM_FADE_IN := 0.25
## Glissement des panneaux à l'apparition.
const PANEL_SLIDE := 40.0
## Échelle d'un bouton enfoncé.
const PRESSED_SCALE := 0.97

# --- Calques (CanvasLayer.layer) --------------------------------------------------------------

const LAYER_HUD := 10
const LAYER_MENU := 20
const LAYER_DIALOG := 30
const LAYER_TRANSITION := 100

# --- Titre de zone ----------------------------------------------------------------------------

const ZONE_TITLE_ICON := 64
const ZONE_TITLE_HOLD := 2.5
## Longueur du dégradé qui prolonge le fond vers la droite, jusqu'à la transparence.
const ZONE_TITLE_FADE := 120
## Écart vertical entre le nom et la région.
const ZONE_TITLE_LINE_GAP := -6

# --- Bouton rond d'exploration (courir, parler, menu) -------------------------------------------

const ROUND_BUTTON := 128
const ROUND_BUTTON_OUTLINE := Color(1, 1, 1, 0.75)
const ROUND_BUTTON_OUTLINE_WIDTH := 3.0
const ROUND_BUTTON_ICON := 64
## Centre du bouton courir mesuré depuis le coin bas-droit de l'écran (position de la
## planche ; le coin est laissé au bouton contextuel).
const RUN_BUTTON_CENTER_FROM_CORNER := Vector2(440, 220)

## Contextuel : un seul bouton en bas à droite, au-dessus et à droite du bouton courir
## (planche DA 2026 ; bible UI/UX §1). Centre mesuré depuis le coin bas-droit.
const INTERACT_BUTTON_CENTER_FROM_CORNER := Vector2(190, 360)
## Étiquette du verbe (PARLER, EXAMINER…) : pastille à gauche du bouton contextuel.
const INTERACT_LABEL_FONT := 26
const INTERACT_LABEL_PAD_H := 20
const INTERACT_LABEL_PAD_V := 8
## Vibration courte à l'appui du bouton contextuel (millisecondes).
const HAPTIC_TAP_MS := 15

# --- Boîte de dialogue (bible UI/UX §3) --------------------------------------------------------

const DIALOG_BOX_WIDTH := 1400
const DIALOG_BOX_MIN_HEIGHT := 200
## Une page tient en 3 lignes au plus.
const DIALOG_MAX_LINES := 3
## Écriture rapide du texte (le déroulé est piloté de l'extérieur par set_visible_characters).
const DIALOG_CHARS_PER_SECOND := 45.0
## Demi-période du clignotement de l'indicateur de suite « › ».
const DIALOG_CONTINUE_BLINK := 0.5
## Opacité basse du clignotement (l'indicateur ne disparaît jamais complètement).
const DIALOG_CONTINUE_DIM := 0.3
const DIALOG_BOTTOM_MARGIN := SAFE_MARGIN
## Montée depuis le bas (pas de « pop ») : durée, puis distance parcourue.
const DIALOG_OPEN := 0.18
const DIALOG_CLOSE := 0.14
const DIALOG_SLIDE := 36.0
const DIALOG_RADIUS := 22
const DIALOG_PAD_H := 44
const DIALOG_PAD_V := 26
## Écart entre le nom du locuteur et le texte.
const DIALOG_SPEAKER_GAP := 6
const DIALOG_SPEAKER_FONT := 28
const DIALOG_LINE_SPACING := 6
const DIALOG_CONTINUE_FONT := 48
## Largeur réservée à « › » à droite du texte (le texte ne passe jamais dessous).
const DIALOG_CONTINUE_WIDTH := 40
## Pente de l'italique de synthèse de la narration (police par défaut sans italique).
const DIALOG_ITALIC_SLANT := 0.2

# --- Joystick ---------------------------------------------------------------------------------

const JOYSTICK_RING := 260
const JOYSTICK_KNOB := 110
## Course maximale du centre de la pastille ; le vecteur transmis est normalisé par elle.
const JOYSTICK_TRAVEL := 100.0
const JOYSTICK_RING_WIDTH := 4.0
const JOYSTICK_RING_LINE := Color(1, 1, 1, 0.75)
const JOYSTICK_RING_FILL := Color(0.10, 0.14, 0.20, 0.22)
const JOYSTICK_KNOB_FILL := Color(1, 1, 1, 0.35)
const JOYSTICK_KNOB_LINE := Color(1, 1, 1, 0.55)
const JOYSTICK_KNOB_LINE_WIDTH := 2.0
const JOYSTICK_ARROW := Color(1, 1, 1, 0.6)
const JOYSTICK_ARROW_SIZE := 14.0
## Distance du bord intérieur de l'anneau aux flèches.
const JOYSTICK_ARROW_INSET := 26.0
const JOYSTICK_FADE_IN := 0.08
const JOYSTICK_FADE_OUT := 0.2

# --- Légende sur le monde (jalon 4A ; bible UI/UX §5 et §11) ---------------------------------

## Tenue de la légende entre ses deux fondus (jamais permanente).
const CAPTION_HOLD := 3.0
## Fondu d'apparition et de disparition de la légende.
const CAPTION_FADE := ANIM_PANEL
## Haut de la légende : sous la bande du titre de zone (en haut à gauche), pour que les deux
## ne se chevauchent jamais, même affichés ensemble à 1920 de large.
const CAPTION_TOP := 176
## Halo de l'ombre portée (texte sans rectangle, lisible sur un sol clair comme sur l'herbe).
const CAPTION_SHADOW_OUTLINE := 12
const CAPTION_SHADOW_OFFSET := 3
## Espacement des lettres de la légende (titre aéré).
const CAPTION_LETTER_SPACING := 3

# --- Boutons de panneau (fiche du starter, menus) --------------------------------------------

## Fond du bouton secondaire (RETOUR) : voile clair sur le panneau.
const BUTTON_BG := Color(1, 1, 1, 0.08)
## Bouton d'accent enfoncé : ACCENT assombri.
const ACCENT_PRESSED := Color("#D9A92A")
const BUTTON_PAD_H := 28

# --- Fiche du starter (jalon 4A) -------------------------------------------------------------

const STARTER_SHEET_WIDTH := 600
## Bord gauche de la fiche (≥ SAFE_MARGIN) : elle laisse voir la table et le joueur.
const STARTER_SHEET_LEFT := 96
const STARTER_SHEET_PAD := 36
## Écart entre le nom et les pastilles, les pastilles et la phrase…
const STARTER_SHEET_GAP := 20
## …et plus d'air avant les boutons.
const STARTER_SHEET_BUTTONS_GAP := 36
## Fermeture (plus courte que l'ouverture ANIM_PANEL).
const STARTER_SHEET_CLOSE := 0.2
## Phrase de la fiche : blanc légèrement adouci, comme la narration.
const STARTER_SHEET_PHRASE := DIALOG_NARRATION

# --- Pastilles de type -----------------------------------------------------------------------

const TYPE_BADGE_ICON := 30
const TYPE_BADGE_FONT := 24
const TYPE_BADGE_PAD_H := 16
const TYPE_BADGE_PAD_V := 6
const TYPE_BADGE_GAP := 8
const TYPE_BADGE_RADIUS := 22
## Couleur d'une pastille dont le type n'est pas dans TYPE_COLORS.
const TYPE_COLOR_UNKNOWN := TEXT_MUTED
## Couleur de chaque type (skill ui-theme-2026, + Acier, Ténèbres, Fée : jalon 4 Q10).
## Clés : identifiants de data/pokemon/types.json.
const TYPE_COLORS: Dictionary[StringName, Color] = {
	&"normal": Color("#A8A77A"),
	&"fire": Color("#EE8130"),
	&"water": Color("#6390F0"),
	&"electric": Color("#F7D02C"),
	&"grass": Color("#7AC74C"),
	&"ice": Color("#96D9D6"),
	&"fighting": Color("#C22E28"),
	&"poison": Color("#A33EA1"),
	&"ground": Color("#E2BF65"),
	&"flying": Color("#A98FF3"),
	&"psychic": Color("#F95587"),
	&"bug": Color("#A6B91A"),
	&"rock": Color("#B6A136"),
	&"ghost": Color("#735797"),
	&"dragon": Color("#6F35FC"),
	&"dark": Color("#705746"),
	&"steel": Color("#B7B7CE"),
	&"fairy": Color("#D685AD"),
}
