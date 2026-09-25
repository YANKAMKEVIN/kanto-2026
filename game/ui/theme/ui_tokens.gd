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
const NAME_TAG := Color("#3E7BD6")
const DIALOG_BG := Color(0.97, 0.97, 0.99, 0.96)
const DIALOG_TEXT := Color("#1E2530")
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
## planche ; le coin reste libre pour le futur bouton contextuel « parler »).
const RUN_BUTTON_CENTER_FROM_CORNER := Vector2(440, 220)

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
