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
## Rituel de soin d'un Centre Pokémon (dossier 09 §7, « environ 3 secondes » ; jalon-07.md §13) :
## ×GameSettings.REDUCED_MENU_SPEED avec « Réduire les animations ». Vibration légère à l'éclat.
const CENTER_HEAL := 3.0
const CENTER_HEAL_HAPTIC_MS := 20
## Glissement des panneaux à l'apparition.
const PANEL_SLIDE := 40.0
## Échelle d'un bouton enfoncé.
const PRESSED_SCALE := 0.97

# --- Calques (CanvasLayer.layer) --------------------------------------------------------------

## Étalonnage d'écran du monde (jalon-07.md §6.1) : au-dessus du monde et des sprites de
## combat (LAYER_BATTLE_STAGE), sous le HUD.
const LAYER_WORLD_GRADE := 6
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

# --- Combat (jalon 4B ; dossier 05, références combat-v1 et combat-capacites-v1) --------------
# Positions mesurées sur les références (1536 × 1024, ramenées à 1080 de haut), puis arrondies
# pour respecter TOUCH_MIN et SAFE_MARGIN. Les composants sont ancrés aux coins de l'écran :
# ils restent en place de 1920 à 2340 de large (aspect expand).

## Calque des sprites de combat (entre le monde et l'UI) et calque de l'interface de combat.
const LAYER_BATTLE_STAGE := 5
const LAYER_BATTLE_HUD := 12
## Voile sombre posé sur le décor pendant le combat (opacité de FADE_COLOR) et zoom de caméra.
const BATTLE_DIM := 0.2
const BATTLE_ZOOM := 1.06

## Distance des composants aux bords de l'écran.
const BATTLE_EDGE := SAFE_MARGIN
## Haut de la carte adversaire (non interactive : un peu plus haut que SAFE_MARGIN serait
## possible, on garde l'air de la référence).
const BATTLE_FOE_CARD_TOP := 56
## Bas de la carte joueur depuis le bas de l'écran : laisse la place du bouton « ‹ » dessous.
const BATTLE_OWN_CARD_BOTTOM := SAFE_MARGIN + TOUCH_MIN + GAP
## Bas de la grille d'actions et du bandeau des messages depuis le bas de l'écran.
const BATTLE_GRID_BOTTOM := 80
## Bas des cartes de capacités depuis le bas de l'écran.
const BATTLE_MOVES_BOTTOM := 56
## Fermeture d'un composant (plus courte que l'ouverture ANIM_PANEL).
const BATTLE_PANEL_CLOSE := 0.2

# Cartes d'information (nom, sexe, niveau, PV).
const BATTLE_CARD_WIDTH := 480
## Hauteur fixe des cartes : sans chiffres (adversaire), avec « 19 / 19 » (joueur).
const BATTLE_CARD_HEIGHT := 112
const BATTLE_CARD_HEIGHT_NUMBERS := 156
## Translucides comme la boîte de dialogue (dossier 05, point à trancher ; jalon 4 Q17).
const BATTLE_CARD_BG := PANEL_BG
const BATTLE_CARD_PAD_H := 26
const BATTLE_CARD_PAD_V := 12
const BATTLE_CARD_ROW_GAP := 4
## Écart entre le nom et le symbole du sexe, et entre « Nv. » et le niveau.
const BATTLE_CARD_NAME_GAP := 10
const BATTLE_CARD_NAME_FONT := FONT_BODY
const BATTLE_CARD_LEVEL_FONT := FONT_CAPTION
const BATTLE_CARD_LEVEL_VALUE_FONT := FONT_BODY
const BATTLE_HP_NUMBERS_FONT := 28
## Symboles ♂ / ♀ (dessinés en SVG : la police par défaut n'a pas ces caractères).
const GENDER_ICON := 30
const GENDER_MALE := Color("#4A9BF0")
const GENDER_FEMALE := Color("#F2679A")

# Barre de PV.
const HP_BAR_HEIGHT := 14
## Retrait du remplissage à l'intérieur du fond (le fond forme un liseré autour).
const HP_BAR_INSET := 2
const HP_BAR_TRACK := Color(1, 1, 1, 0.15)
const HP_BAR_TRACK_BORDER := Color(1, 1, 1, 0.3)
const HP_BAR_LABEL_FONT := FONT_CAPTION
const HP_BAR_LABEL_GAP := 12
## Seuils de couleur : vert au-dessus de 50 %, jaune au-dessus de 20 %, rouge sinon.
const HP_HIGH_THRESHOLD := 0.5
const HP_LOW_THRESHOLD := 0.2
## Descente des PV : normale, puis rapide sur un gros coup (> HP_BIG_HIT des PV max, décidé
## par celui qui pilote la barre).
const HP_TWEEN := 0.4
const HP_TWEEN_FAST := 0.25
const HP_BIG_HIT := 0.25
## Pulsation de la carte sous HP_LOW_THRESHOLD (dossier 05 §12) : demi-période et échelle.
const HP_LOW_PULSE := 0.55
const HP_LOW_PULSE_SCALE := 1.025
## Vibrations sur un coup reçu, plus marquée sur un coup critique (bible §12).
const HAPTIC_HIT_MS := 30
const HAPTIC_CRIT_MS := 70

# Pastilles d'équipe (au-dessus de la carte joueur).
const PARTY_SIZE := 6
const PARTY_PIP := 28
const PARTY_PIP_GAP := 10
## Retrait depuis le bord gauche de la carte, et écart au-dessus de la carte.
const PARTY_PIPS_INSET := 20
const PARTY_PIPS_GAP := 12
const PARTY_PIP_EMPTY := Color(0.62, 0.67, 0.74, 0.9)
const PARTY_PIP_EMPTY_BORDER := Color(0.06, 0.09, 0.13, 0.55)

# Grille des 4 actions (combat-v1 : boutons colorés).
const ACTION_ATTACK := Color("#E04A3C")
const ACTION_BAG := Color("#D49A2E")
const ACTION_TEAM := Color("#2D6DB5")
const ACTION_RUN := Color(0.16, 0.2, 0.25, 0.92)
const BATTLE_ACTION_SIZE := Vector2(360, 136)
const BATTLE_ACTION_GAP := 22
const BATTLE_ACTION_ICON := 64
const BATTLE_ACTION_PAD_H := 30
## Liseré plus clair du bouton, fond enfoncé plus sombre (taux appliqués à la couleur).
const BATTLE_ACTION_BORDER_LIGHTEN := 0.3
const BATTLE_ACTION_PRESSED_DARKEN := 0.2
## Action indisponible : couleur mêlée à SURFACE_DARK, rendue plus transparente ; texte et
## icône atténués.
const BATTLE_ACTION_DISABLED_MIX := 0.6
const BATTLE_ACTION_DISABLED_ALPHA := 0.72
const TEXT_DISABLED := Color(1, 1, 1, 0.42)
## Lueur d'accent autour d'ATTAQUER, qui pulse doucement (dossier 05 §18) : couleur, taille,
## demi-période, opacité basse.
const ACTION_GLOW := Color(0.96, 0.77, 0.26, 0.7)
const ACTION_GLOW_SIZE := 16
const ACTION_GLOW_BORDER := 3
const ACTION_GLOW_PULSE := 0.9
const ACTION_GLOW_MIN := 0.35

# Cartes de capacités (combat-capacites-v1).
const MOVE_CARD_SIZE := Vector2(560, 136)
## Écart horizontal : il loge la flèche ▶ de sélection de la colonne de droite.
const MOVE_GAP_H := 48
const MOVE_GAP_V := 20
## Bandeau sombre derrière les cartes : marge intérieure (à gauche : MOVE_GAP_H, pour la
## flèche de la colonne de gauche) et débord jusqu'aux bords droit et bas de l'écran.
const MOVE_BAND_PAD := 24
const MOVE_BAND_BLEED := 96
const MOVE_BAND_BG := Color(0.06, 0.09, 0.13, 0.66)
## Part de la couleur du type dans le fond de la carte (mêlée à PANEL_BG), et opacité du
## liseré à la couleur du type.
const MOVE_CARD_TINT := 0.32
const MOVE_CARD_BORDER_ALPHA := 0.55
const MOVE_CARD_PAD_H := 20
const MOVE_CARD_PAD_V := 12
const MOVE_CARD_ICON := 56
const MOVE_CARD_ICON_COLUMN := 72
const MOVE_CARD_NAME_FONT := FONT_BODY
const MOVE_CARD_PP_FONT := 28
const MOVE_CARD_PP_TAG_FONT := 20
const MOVE_CARD_POWER_FONT := FONT_CAPTION
## Sélection : liseré ACCENT épais et halo.
const MOVE_CARD_SELECTED_BORDER := 4
const MOVE_CARD_SELECTED_GLOW := Color(0.96, 0.77, 0.26, 0.45)
const MOVE_CARD_SELECTED_GLOW_SIZE := 14
## Carte sans PP : atténuée (assombrie et un peu transparente, modulate), PP en HP_LOW ;
## MODULATE_FULL = pas d'atténuation.
const MOVE_CARD_DISABLED := Color(0.55, 0.58, 0.62, 0.85)
const MODULATE_FULL := Color(1, 1, 1, 1)
const MOVE_PP_EMPTY := HP_LOW
## Emplacement vide (moins de 4 capacités).
const MOVE_CARD_EMPTY_BG := Color(1, 1, 1, 0.04)
const MOVE_CARD_EMPTY_BORDER := Color(1, 1, 1, 0.12)
## Flèche ▶ de sélection (à gauche de la carte).
const MOVE_SELECT_ARROW := Vector2(26, 34)
## Pression longue sur une carte : fiche détaillée (dossier 05 §7).
const LONG_PRESS := 0.45

# Fiche détaillée d'une capacité (pression longue).
const MOVE_DETAIL_WIDTH := 600
const MOVE_DETAIL_BG := DIALOG_PANEL_BG
const MOVE_DETAIL_PAD := 28
const MOVE_DETAIL_GAP := 12
## Colonnes Puissance / Précision / PP.
const MOVE_DETAIL_STAT_GAP := 40
const MOVE_DETAIL_NAME_FONT := FONT_BUTTON
const MOVE_DETAIL_VALUE_FONT := FONT_BODY
const MOVE_DETAIL_TEXT_FONT := 28
const MOVE_DETAIL_OPEN := 0.18
const MOVE_DETAIL_CLOSE := 0.12
const MOVE_DETAIL_SLIDE := 24.0

# Bandeau des messages (à la place de la grille).
const BATTLE_MESSAGE_WIDTH := 1164
const BATTLE_MESSAGE_HEIGHT := 176
const BATTLE_MESSAGE_BG := DIALOG_PANEL_BG
const BATTLE_MESSAGE_PAD_H := 44
const BATTLE_MESSAGE_PAD_V := 26
const BATTLE_MESSAGE_MAX_LINES := 2
## Tenue d'un message avant que le combat avance seul (ou au toucher).
const BATTLE_MESSAGE_HOLD := 0.9

# Bouton rond « ‹ » (retour à la grille d'actions), sous la carte joueur.
const BATTLE_BACK_SIZE := TOUCH_MIN
const BATTLE_BACK_ICON := 56

# --- Toast (bible UI/UX §6 : « Poké Balls ×5 — Ajoutées au Sac ») ---------------------------

## Haut du toast (en haut au centre de l'écran, sous l'encoche ; non interactif).
const TOAST_TOP := SAFE_MARGIN
## Tenue entre l'apparition et la disparition (~2 s, jamais bloquant).
const TOAST_HOLD := 2.0
const TOAST_FADE_IN := 0.24
const TOAST_FADE_OUT := 0.3
## Glissement depuis le haut pendant l'apparition (et vers le haut à la disparition).
const TOAST_SLIDE := 24.0
## Capsule sombre translucide, comme la boîte de dialogue.
const TOAST_BG := DIALOG_PANEL_BG
const TOAST_RADIUS := 40
const TOAST_PAD_LEFT := 20
const TOAST_PAD_RIGHT := 40
const TOAST_PAD_V := 12
const TOAST_ICON := 56
const TOAST_GAP := GAP
## Écart vertical entre le titre et le détail.
const TOAST_LINE_GAP := -4
const TOAST_TITLE_FONT := FONT_BODY
const TOAST_DETAIL_FONT := FONT_CAPTION
## Vibration « tic » à l'apparition (ramasser un objet, bible §12) : plus légère qu'un appui.
const HAPTIC_TICK_MS := 10

# --- XP, niveau et oubli d'une capacité (jalon 5C T10, jalon-05.md §3.9 et §3.12) -----------
# Présentation du dossier 04 §6 : « +21 XP » qui monte et s'efface, une fine barre d'XP sous
# la carte du joueur (jamais permanente, bible §11), « Nv. 6 » qui pulse. Aucune fenêtre.

## Fine barre d'XP posée au bas de la carte du joueur : hauteur, remplissage, fond.
const EXP_BAR_HEIGHT := 8
## Descente de la barre sous le bord bas de la zone de contenu (dans la marge de la carte).
const EXP_BAR_DROP := 6
const EXP_BAR_FILL := Color("#4FB3FF")
const EXP_BAR_TRACK := HP_BAR_TRACK
## Remplissage d'une tranche de barre (une tranche par niveau gagné).
const EXP_TWEEN := 0.6
## Entre deux tranches la barre reste ; sinon elle disparaît après EXP_BAR_LINGER, en
## EXP_BAR_FADE.
const EXP_BAR_LINGER := 0.4
const EXP_BAR_FADE := ANIM_FADE_OUT
## « +21 XP » : durée totale (il monte de EXP_GAIN_RISE en s'effaçant), entrée et sortie en
## fondu, écart au bord haut de la carte.
const EXP_GAIN_HOLD := 0.8
const EXP_GAIN_RISE := 36.0
const EXP_GAIN_FADE_IN := ANIM_MICRO
const EXP_GAIN_FADE_OUT := 0.25
const EXP_GAIN_GAP := 10
const EXP_GAIN_FONT := FONT_BUTTON
## Contour sombre qui garde « +21 XP » lisible sur un Pokémon orange ou un décor clair.
const EXP_GAIN_OUTLINE := 8
## « Nv. 6 » : grossit un instant (LEVEL_PULSE_UP) en ACCENT, puis revient
## (LEVEL_PULSE_DOWN). Vibration courte au passage de niveau.
const LEVEL_PULSE_SCALE := 1.45
const LEVEL_PULSE_UP := 0.2
const LEVEL_PULSE_DOWN := 0.4
const HAPTIC_LEVEL_UP_MS := 25

# Panneau d'oubli : bandeau opaque (il recouvre le bandeau des messages), nouvelle capacité
# en haut, les quatre connues en 2 × 2 dessous, NE PAS APPRENDRE et OUBLIER tout en bas.
const FORGET_BAND_BG := PANEL_BG_STRONG
const FORGET_GAP_H := 24
const FORGET_ROW_GAP := 12
const FORGET_CAPTION_HEIGHT := 32
const FORGET_BUTTON_SIZE := Vector2(560, TOUCH_MIN)
## Haut de la fiche d'une capacité (pression longue) depuis le haut du panneau.
const FORGET_SHEET_TOP := 80
## OUBLIER inactif (rien de choisi) : fond et texte atténués.
const FORGET_CONFIRM_DISABLED_BG := Color(1, 1, 1, 0.08)

# --- Sac de combat et carte de capture (jalon 5D T14) ------------------------------------------
# Le Sac suit le langage visuel du Sac du jalon 6 (dossier 08 §3) : catégories, objets en cartes
# (illustration, nom, quantité), un toucher = un aperçu, une action claire. En combat il est un
# panneau en bas à gauche, au-dessus du bouton « ‹ » : l'adversaire (centre droit) reste visible.
# La carte de capture suit la case 9 de combat-capture-v1 : titre en capitales, vignette, une
# ligne Pokédex discrète, la ligne d'équipe, ▼.

## Vibrations (bible UI/UX §12) : « toc » d'une secousse de la Ball ; motif de la capture
## réussie, en alternance vibration / pause (millisecondes) : tic, tic, puis un long « clic ».
const HAPTIC_BALL_SHAKE_MS := 40
const HAPTIC_CAPTURE: Array[int] = [30, 70, 30, 70, 120]

# Panneau du Sac.
const BAG_PANEL_WIDTH := 1020
## Hauteur maximale du cadre (le cadre épouse son contenu, ancré au-dessus de « ‹ ») : 1080
## moins deux marges de bord, le bouton « ‹ » et l'écart qui le sépare du cadre.
const BAG_FRAME_MAX_HEIGHT := 840
const BAG_PANEL_BG := DIALOG_PANEL_BG
const BAG_PANEL_PAD := 28
const BAG_ROW_GAP := 16
const BAG_TITLE_ICON := 64
## Onglet de catégorie (≥ TOUCH_MIN de haut) : icône, nom ; sélectionné = fond teinté d'ACCENT
## et liseré ACCENT (jamais la couleur seule : le contenu change dessous).
const BAG_TAB_HEIGHT := TOUCH_MIN
const BAG_TAB_ICON := 56
const BAG_TAB_FONT := FONT_CAPTION
const BAG_TAB_PAD_H := 24
const BAG_TAB_GAP := 12
const BAG_TAB_SELECTED_BG := Color(ACCENT, 0.18)
const BAG_TAB_SELECTED_BORDER := 3
## Carte d'objet : illustration, nom, quantité « ×5 » au coin de l'illustration. Sélectionnée :
## liseré ACCENT épais, halo et léger grossissement (la forme change aussi).
const BAG_CARD_SIZE := Vector2(222, 232)
const BAG_CARD_GAP := 16
const BAG_COLUMNS := 4
const BAG_CARD_ICON := 112
const BAG_CARD_PAD_H := 12
const BAG_CARD_PAD_V := 12
const BAG_CARD_NAME_FONT := 28
const BAG_CARD_QTY_FONT := 28
const BAG_CARD_SELECTED_SCALE := 1.03
## Marge autour des cartes dans la liste défilante : elle loge le halo et le grossissement de la
## carte sélectionnée (la liste coupe ce qui dépasse).
const BAG_SCROLL_PAD := 14
## Au-delà de cette hauteur, la liste des cartes défile (une ligne et demie : on devine la suite).
const BAG_GRID_MAX_HEIGHT := 360
## Aperçu de l'objet touché : illustration, nom, quantité, description, action.
const BAG_DETAIL_PAD := 20
const BAG_DETAIL_ICON := 112
const BAG_DETAIL_GAP := 20
const BAG_DETAIL_NAME_FONT := FONT_BUTTON
const BAG_DETAIL_QTY_FONT := FONT_BODY
const BAG_DETAIL_TEXT_FONT := 28
const BAG_ACTION_SIZE := Vector2(300, TOUCH_MIN)
## Opacité de départ de l'aperçu quand l'objet change (fondu court jusqu'à 1).
const BAG_DETAIL_FADE_FROM := 0.4
## Texte posé quand rien n'est utilisable (pas un bouton).
const BAG_EMPTY_HEIGHT := 160
## Seuil commun (px de référence 1080 p) : un toucher qui bouge de plus que cela devient un
## défilement et n'active aucun contrôle ; en deçà, c'est un toucher (activé au relâchement).
const TAP_SLOP := 24.0
## Le doigt qui s'éloigne de plus que cela entre l'appui et le relâchement fait défiler : ce
## n'est pas un toucher.
const BAG_TAP_SLOP := TAP_SLOP

# Carte de capture.
const CAPTURE_CARD_WIDTH := 760
const CAPTURE_CARD_MAX_HEIGHT := 640
const CAPTURE_CARD_BG := DIALOG_PANEL_BG
const CAPTURE_CARD_PAD_H := 44
const CAPTURE_CARD_PAD_V := 32
const CAPTURE_ROW_GAP := 22
const CAPTURE_TITLE_FONT := FONT_TITLE
## Vignette du Pokémon : cadre arrondi, sprite pixel art à l'échelle entière (NEAREST).
const CAPTURE_THUMB := 192
const CAPTURE_THUMB_PAD := 12
const CAPTURE_THUMB_BG := Color(1, 1, 1, 0.10)
const CAPTURE_THUMB_BORDER := Color(1, 1, 1, 0.22)
const CAPTURE_LINE_FONT := FONT_BODY
const CAPTURE_LINE_ICON := 40
const CAPTURE_LINE_GAP := 12
const CAPTURE_CONTINUE_SIZE := Vector2(40, 28)
## Les lignes se révèlent l'une après l'autre (« discrètement ») : délai puis fondu.
const CAPTURE_LINE_DELAY := 0.28
const CAPTURE_LINE_FADE := 0.2
## Un toucher n'est pris qu'après ce délai : celui qui a lancé la Ball ne ferme pas la carte.
const CAPTURE_TOUCH_LOCK := 0.6

# --- Menu Dresseur (jalon 6, T3 : tableau de bord) -------------------------------------------------

## Ouverture (fond puis panneaux) et fermeture du menu ; vibration légère à l'ouverture.
const MENU_OPEN := 0.25
const MENU_CLOSE := 0.2
const HAPTIC_MENU_MS := HAPTIC_TAP_MS
## Monde flouté et assombri derrière le menu (jalon-06.md §6.2) : rayon du flou en pixels de
## référence, niveau de mipmap de base, voile SURFACE_DARK (opacité).
const MENU_BLUR_RADIUS := 5.0
const MENU_BLUR_LOD := 1.5
const MENU_DIM := 0.5
## En-tête : × (zone tactile TOUCH_MIN) et nom de la zone ; le corps commence dessous.
const MENU_CLOSE_SIZE := TOUCH_MIN
const MENU_BODY_TOP := SAFE_MARGIN + TOUCH_MIN + GAP
const MENU_ZONE_ICON := 40
const MENU_ZONE_PAD_H := 28
const MENU_ZONE_PAD_V := 14
## Panneaux du menu : plus translucides que PANEL_BG pour laisser deviner le monde.
const MENU_PANEL_BG := Color(0.07, 0.10, 0.15, 0.72)
const MENU_PANEL_PAD := 28
## Carte du Dresseur (à gauche) : largeur, portrait en pixel art à l'échelle entière (NEAREST).
const MENU_LEFT_WIDTH := 680
const MENU_PORTRAIT_SOURCE := Vector2i(32, 64)
const MENU_PORTRAIT_SCALE := 6
const MENU_NAME_FONT := FONT_TITLE
const MENU_SUBTITLE_FONT := 28
const MENU_STAT_FONT := 28
const MENU_STAT_ICON := 40
const MENU_STAT_GAP := 14
const MENU_ID_BAR := Vector2(96, 6)
## Pokémon de tête : carte tactile (≥ TOUCH_MIN), vignette en pixel art à l'échelle entière.
const MENU_LEAD_HEIGHT := 160
const MENU_LEAD_THUMB := 128
const MENU_LEAD_SPRITE_SCALE := 2
const MENU_LEAD_NAME_FONT := FONT_BUTTON
const MENU_LEAD_LEVEL_FONT := 26
const MENU_LEAD_HP_FONT := 26
## Grandes cartes : écart, icône, pastille « › », barre de teinte, textes.
const MENU_CARD_GAP := GAP
const MENU_CARD_PAD := 24
const MENU_CARD_ICON := 112
const MENU_CARD_CHEVRON := 64
const MENU_CARD_CHEVRON_ICON := 36
const MENU_CARD_BAR := Vector2(56, 6)
const MENU_CARD_TITLE_FONT := FONT_BUTTON
const MENU_CARD_CAPTION_FONT := FONT_CAPTION
## Teinte de chaque carte (planche : bleu, rouge, or, vert, violet, gris).
const MENU_CARD_TINTS: Dictionary[StringName, Color] = {
	&"team": Color("#3E7BD6"),
	&"pokedex": Color("#E8473C"),
	&"bag": Color("#D9A93A"),
	&"map": Color("#2FB88A"),
	&"trainer": Color("#7B5BD6"),
	&"settings": Color("#8A94A6"),
}
const MENU_CARD_TINT_DEFAULT := Color("#8A94A6")
## Ligne d'objectif : discrète, en bas du tableau de bord.
const MENU_OBJECTIVE_HEIGHT := 48
const MENU_OBJECTIVE_FONT := FONT_CAPTION
## Bouton Menu de l'exploration (Q-1) : rond, translucide, coin haut-droit ; centre mesuré depuis
## le coin haut-droit de l'écran.
const MENU_BUTTON_ALPHA := 0.7
const MENU_BUTTON_CENTER_FROM_CORNER := Vector2(SAFE_MARGIN + ROUND_BUTTON * 0.5,
	SAFE_MARGIN + ROUND_BUTTON * 0.5)


# --- Équipe (jalon 6, T7) ---------------------------------------------------------------------

## Colonnes : liste (à gauche) et fiche (à droite) ; la vedette prend le reste.
const TEAM_LIST_WIDTH := 560
const TEAM_SHEET_WIDTH := 800
const TEAM_COLUMN_GAP := GAP
## Emplacement de la liste (≥ TOUCH_MIN) : six de TEAM_SLOT_HEIGHT + cinq écarts ≤ 840.
const TEAM_SLOT_HEIGHT := TOUCH_MIN
const TEAM_SLOT_GAP := 14
const TEAM_SLOT_PAD := 12
const TEAM_SLOT_THUMB := 112
const TEAM_SLOT_NAME_FONT := FONT_BODY
const TEAM_SLOT_META_FONT := FONT_CAPTION
const TEAM_SLOT_STAR := 28
## Un doigt qui bouge de plus que cela avant LONG_PRESS n'est pas un appui long (px).
const TEAM_DRAG_SLOP := 28.0
## Pendant le glissement : l'emplacement d'origine s'atténue, la copie suit le doigt.
const TEAM_DRAG_SOURCE_ALPHA := 0.4
const TEAM_DRAG_GHOST_ALPHA := 0.92
## Échange (les deux emplacements glissent l'un vers l'autre) et changement de Pokémon.
const TEAM_SWAP_TIME := 0.2
const TEAM_SWITCH_TIME := 0.14
## Vedette : sprite 64 px ×6 (entier, NEAREST), respiration par décalage vertical (px).
const TEAM_SPRITE_SOURCE := 64
const TEAM_SPRITE_SCALE := 6
const TEAM_BREATH_PX := 6
const TEAM_BREATH_TIME := 1.1
const TEAM_SHADOW := Color(0, 0, 0, 0.3)
const TEAM_NAME_FONT := FONT_TITLE
const TEAM_LEVEL_FONT := FONT_BODY
const TEAM_HEADER_GAP := 8
const TEAM_BAR_LABEL_FONT := FONT_CAPTION
## Fiche : onglets (≥ TOUCH_MIN), actions (≥ TOUCH_MIN), pages.
const TEAM_TAB_HEIGHT := TOUCH_MIN
const TEAM_TAB_FONT := 28
const TEAM_ACTION_HEIGHT := TOUCH_MIN
const TEAM_ACTION_FONT := FONT_CAPTION
const TEAM_ACTION_ICON := 44
const TEAM_PAGE_GAP := 10
const TEAM_PANEL_PAD := 20
const TEAM_SECTION_BG := Color(1, 1, 1, 0.06)
const TEAM_STAT_ROW := 32
const TEAM_STAT_FONT := 26
const TEAM_STAT_NAME_WIDTH := 200
const TEAM_STAT_VALUE_WIDTH := 70
const TEAM_GAUGE_HEIGHT := 12
const TEAM_GAUGE_FILL := ACCENT
const TEAM_MOVE_CARD_HEIGHT := 116
const TEAM_HISTORY_FONT := 30
const TEAM_EVO_CIRCLE := 64
const TEAM_EVO_SPRITE := 64
const TEAM_EVO_FONT := FONT_CAPTION
## Fiche d'une capacité ouverte au toucher : voile derrière.
const TEAM_SCRIM := Color(0.02, 0.03, 0.05, 0.55)
## Sélection d'un emplacement et cible de dépôt.
const TEAM_SLOT_SELECTED_BORDER := 4
const HAPTIC_TEAM_DRAG_MS := 25
const HAPTIC_TEAM_SWAP_MS := 20

# Écran Sac du Menu Dresseur (jalon 6, T11).
## Colonnes : catégories à gauche, cartes au centre (le reste), aperçu à droite.
const BAG_SCREEN_LEFT_WIDTH := 440
const BAG_SCREEN_DETAIL_WIDTH := 580
const BAG_SCREEN_GAP := GAP
const BAG_SCREEN_TITLE_FONT := FONT_TITLE
const BAG_SCREEN_HEADER_GAP := 12
const BAG_TAB_COUNT_FONT := 26
const BAG_TAB_COUNT_WIDTH := 56
const BAG_SORT_WIDTH := 400
const BAG_SORT_ICON := 40
const BAG_BIG_ICON := 208
const BAG_STAR_ICON := 32
const BAG_CARD_STAR_ICON := 36
const BAG_NOTE_FONT := FONT_CAPTION
const BAG_HINT_FONT := 22
## Appui long sur une carte : vibration de confirmation (favori marqué ou retiré).
const HAPTIC_BAG_FAVORITE_MS := 25
# Choix du Pokémon (PartyPicker) et résultat d'un usage (UseResultBar).
const PICKER_ROW_HEIGHT := 140
const PICKER_COLUMN_WIDTH := 540
const PICKER_COLUMNS := 2
const PICKER_GAP := 14
const PICKER_PAD := 10
const PICKER_THUMB := 116
const PICKER_NAME_FONT := FONT_BODY
const PICKER_META_FONT := 26
const PICKER_TITLE_FONT := FONT_BUTTON
const PICKER_CHEVRON := 48
const PICKER_UNUSABLE_ALPHA := 0.6
const PICKER_SELECTED_BORDER := 4
## Refus d'une cible inutilisable : la carte tremble (amplitude horizontale, allers-retours
## en PICKER_SHAKE_TIME), vibration courte.
const PICKER_SHAKE_AMPLITUDE := 12.0
const PICKER_SHAKE_TIME := 0.25
const PICKER_SHAKE_STEPS := 4
const HAPTIC_REFUSE_MS := 20
## Soin réussi : éclat vert de la carte (opacité au départ), qui s'estompe après la barre.
const PICKER_HEAL_FLASH_ALPHA := 0.4
const PICKER_HEAL_FLASH_COLOR := Color(0.298, 0.851, 0.392, PICKER_HEAL_FLASH_ALPHA)
const PICKER_HEAL_FLASH_FADE := ANIM_PANEL
# Panneau ÉQUIPE du combat (jalon 7, BattlePartyPanel) : même cadre que le Sac (BAG_PANEL_WIDTH,
# BagPanel), deux colonnes de cartes de PICKER_ROW_HEIGHT (≥ TOUCH_MIN), pied avec ENVOYER.
const BATTLE_PARTY_COLUMNS := 2
## (BAG_PANEL_WIDTH − 2 × BAG_PANEL_PAD − PICKER_GAP) / 2, arrondi en dessous.
const BATTLE_PARTY_CARD_WIDTH := 475
const BATTLE_PARTY_CARD_HEIGHT := PICKER_ROW_HEIGHT
## Pastille de type (cercle à la couleur du type, icône blanche) à gauche de la carte.
const BATTLE_PARTY_TYPE_CHIP := 52
const BATTLE_PARTY_TYPE_ICON := 32
## Pied : nom du Pokémon choisi (ou raison d'un refus) et ENVOYER (BAG_ACTION_SIZE).
const BATTLE_PARTY_FOOTER_HEIGHT := TOUCH_MIN
const RESULT_HEIGHT := TOUCH_MIN
const RESULT_FONT := FONT_BODY
const RESULT_PAD_H := 28
const RESULT_PAD_V := 8
const RESULT_ICON := 56
const RESULT_BG_ALPHA := 0.16
const RESULT_REPEAT_WIDTH := 460


## [param tint] avec l'opacité [param alpha] (les écrans ne construisent jamais de couleur).
static func tinted(tint: Color, alpha: float) -> Color:
	return Color(tint, alpha)


## Fond d'une grande carte : SURFACE_DARK teinté, translucide.
static func menu_card_bg(tint: Color) -> Color:
	return tinted(SURFACE_DARK.lerp(tint, 0.38), 0.86)


## Fond d'une grande carte enfoncée.
static func menu_card_bg_pressed(tint: Color) -> Color:
	return tinted(SURFACE_DARK.lerp(tint, 0.62), 0.94)


## Liseré d'une grande carte.
static func menu_card_border(tint: Color) -> Color:
	return tinted(tint, 0.6)

# Écran Pokédex du Menu Dresseur (jalon 6, T15). Aucune statistique, aucun talent, aucune
# silhouette : seulement ce que le joueur a découvert.
## En-tête : RETOUR, titre + compteur, filtres (TOUS · VUS · CAPTURÉS · HABITATS).
const DEX_HEADER_HEIGHT := TOUCH_MIN
const DEX_BACK_WIDTH := MENU_CARD_ICON * 2
const DEX_TITLE_FONT := FONT_TITLE
const DEX_COUNTS_FONT := FONT_CAPTION
const DEX_FILTER_MIN_WIDTH := 168
const DEX_FILTER_FONT := 26
const DEX_GAP := GAP
const DEX_SECTION_GAP := 12
## Colonne de la grille quand la fiche est ouverte ; sans fiche, la grille prend tout.
const DEX_LIST_WIDTH := 828
const DEX_PANEL_PAD := 20
const DEX_SCROLL_PAD := 6
## Ligne de recherche : champ, bouton Type, bouton Zone (filtre HABITATS seulement).
const DEX_SEARCH_MIN_WIDTH := 260
const DEX_SEARCH_FONT := 28
const DEX_SEARCH_ICON := 40
const DEX_SEARCH_PAD_H := 20
const DEX_REFINE_WIDTH := 220
## Case de la grille : légère (un seul dessin), sprite de 64 px affiché à l'échelle entière.
const DEX_CELL_GAP := 12
const DEX_CELL_SPRITE_SOURCE := 64
const DEX_CELL_SPRITE_SCALE := 2
## Une case inconnue : numéro et « ??? » seulement, estompés.
## Fiche : identité (vignette, numéro, nom, types), onglets, pages.
const DEX_SHEET_MIN_WIDTH := 960
const DEX_SPRITE_FRAME := 160
const DEX_SHEET_SPRITE_SCALE := 2
const DEX_SHEET_NAME_FONT := FONT_TITLE
const DEX_SHEET_NUMBER_FONT := 26
const DEX_TAB_HEIGHT := TOUCH_MIN
const DEX_TAB_FONT := 26
const DEX_SHEET_GAP := 12
const DEX_SHEET_FADE := ANIM_PANEL
const DEX_SEEN_ALPHA := 0.7
const DEX_INFO_FONT := 30
const DEX_DESCRIPTION_FONT := 28
## Évolution : un stade = un rond et un nom ; un stade inconnu = un rond vide et « ??? ».
const DEX_EVO_CIRCLE := 152
const DEX_EVO_SPRITE_SCALE := 2
## Habitat : petite carte (seulement les zones observées, le reste est voilé) et pastilles.
const DEX_MAP_SIZE := Vector2(460, 288)
const DEX_MAP_PIN := 9
const DEX_MAP_PIN_BORDER := 3
## Marge autour de chaque zone (px de l'illustration) et autour de l'ensemble montré.
const DEX_MAP_PATCH_MARGIN := 14.0
const DEX_MAP_FRAME_MARGIN := 40.0
const DEX_MAP_PATCH_BORDER := 2
const DEX_CHIP_HEIGHT := TOUCH_MIN
const DEX_CHIP_ICON := 40
## Images (refonte du Pokédex, T1) : artworks officiels, vignettes de l'atlas, silhouettes.
## Silhouette d'une espèce inconnue (forme seule, plus sombre que la case, sur le halo).
const DEX_SILHOUETTE := Color(0.05, 0.07, 0.10, 0.88)
## Halo radial clair derrière chaque image (centre → transparent), pour les Pokémon sombres.
const DEX_HALO_CENTER := Color(1.0, 1.0, 1.0, 0.16)
## Opacité du halo derrière une silhouette (moitié du halo d'une espèce connue).
const DEX_HALO_UNKNOWN_ALPHA := 0.5
## Côté de la texture du halo (étirée par l'écran, filtre linéaire).
const DEX_HALO_TEXTURE := 128

## Case de la grille (refonte du Pokédex, T2) : carré tactile, halo + vignette de l'atlas,
## numéro en haut à gauche, Poké Ball en haut à droite (capturé). Ni nom ni « Vu / Capturé ».
const DEX_CELL_SIZE := Vector2(128, 128)
## Côté de l'image (vignette de l'atlas, 128 px réduite) et distance de son bord haut.
const DEX_CELL_IMAGE := 112
const DEX_CELL_IMAGE_TOP := 12
## Fond d'une case connue : un peu plus clair que le panneau, comme la maquette.
const DEX_CELL_BG := Color(0.17, 0.22, 0.31, 0.92)
## Marge du numéro et de la Poké Ball au bord de la case.
const DEX_CELL_PAD := 8
const DEX_CELL_NUMBER_FONT := 22
const DEX_CELL_BALL := 24
## Contour du numéro d'une case connue (lisible sur un artwork clair).
const DEX_CELL_NUMBER_OUTLINE := 6
const DEX_CELL_NUMBER_OUTLINE_COLOR := Color(0.04, 0.06, 0.10, 0.85)
const DEX_CELL_SELECTED_SCALE := 1.03
## Numéro d'une case inconnue (estompé).
const DEX_UNKNOWN_ALPHA := 0.55

# --- Pokédex : composition en trois colonnes (refonte, T3) -------------------------------------
## L'écran remonte dans la rangée du × (hauteur de l'en-tête commun) et lui laisse sa place.
const DEX_LAYOUT_RISE := MENU_BODY_TOP - SAFE_MARGIN
const DEX_LAYOUT_CLOSE_RESERVE := MENU_CLOSE_SIZE + GAP
## Rangée d'en-tête : ‹ RETOUR · Poké Ball + titre + compteur · filtres · recherche.
const DEX_LAYOUT_BACK_WIDTH := 190
const DEX_LAYOUT_TITLE_ICON := 64
const DEX_LAYOUT_FILTER_MIN_WIDTH := 110
const DEX_LAYOUT_FILTER_FONT := 24
const DEX_LAYOUT_FILTER_PAD := 20
const DEX_LAYOUT_TITLE_FONT := 36
const DEX_LAYOUT_COUNTS_FONT := 22
const DEX_LAYOUT_SEARCH_MIN_WIDTH := 200
## Colonne de la grille : 4 cases de 128 px (cible tactile) ; le surplus d'écran va à droite.
const DEX_LAYOUT_COLUMNS := 4
const DEX_LAYOUT_CELL := TOUCH_MIN
const DEX_LAYOUT_CELL_GAP := 12
const DEX_LAYOUT_SCROLLBAR := 12
const DEX_LAYOUT_GRID_WIDTH := DEX_LAYOUT_COLUMNS * DEX_LAYOUT_CELL \
	+ (DEX_LAYOUT_COLUMNS - 1) * DEX_LAYOUT_CELL_GAP + 2 * DEX_SCROLL_PAD + 2 * DEX_PANEL_PAD \
	+ DEX_LAYOUT_SCROLLBAR
## Centre (portrait) et droite (fiche) : largeurs minimales et partage du surplus.
const DEX_LAYOUT_CENTER_MIN := 500
const DEX_LAYOUT_CENTER_STRETCH := 1.0
const DEX_LAYOUT_RIGHT_MIN := 620
const DEX_LAYOUT_RIGHT_STRETCH := 1.25
## Grand portrait : boîte carrée qui prend la hauteur restante (au moins PORTRAIT_MIN).
const DEX_LAYOUT_PORTRAIT_MIN := 280
const DEX_LAYOUT_PORTRAIT_GAP := 10
const DEX_LAYOUT_HALO_SCALE := 1.15
## Ombre au sol : ellipse sombre sous les pieds (largeur et hauteur en part de la boîte).
const DEX_LAYOUT_SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.5)
const DEX_LAYOUT_SHADOW_WIDTH := 0.62
const DEX_LAYOUT_SHADOW_HEIGHT := 0.09
const DEX_LAYOUT_SHADOW_RISE := 0.03
## Respiration discrète (échelle 1 ↔ 1 + BREATH, durée d'un aller-retour) et fondu de l'espèce.
const DEX_LAYOUT_BREATH := 0.015
const DEX_LAYOUT_BREATH_TIME := 2.4
const DEX_LAYOUT_PORTRAIT_FADE := 0.15
## Cartes Vu / Capturé, texte du centre.
const DEX_LAYOUT_CARD_ICON := 44
const DEX_LAYOUT_CARD_CAPTION_FONT := 22
const DEX_LAYOUT_CARD_VALUE_FONT := 28
const DEX_LAYOUT_DESC_FONT := 26
const DEX_LAYOUT_HERO_PAD := 24
## Aperçu de droite : petite carte d'habitat, ronds d'évolution.
const DEX_LAYOUT_MAP_PREVIEW_HEIGHT := 150
const DEX_LAYOUT_EVO_PREVIEW := 104
## Vignette dans son rond (part du diamètre) ; hauteur des lignes titre / pied des aperçus.
const DEX_LAYOUT_EVO_IMAGE_RATIO := 0.86
const DEX_LAYOUT_PREVIEW_ROW := 48
const DEX_LAYOUT_PREVIEW_ICON := 36
const DEX_LAYOUT_PREVIEW_TITLE_FONT := 28
const DEX_LAYOUT_PILL_RADIUS := 64
## Onglets de la fiche : texte serré pour que « Observations » tienne à 1920.
const DEX_LAYOUT_TAB_FONT := 22
const DEX_LAYOUT_TAB_PAD := 4

# Écran Carte du Menu Dresseur (jalon 6, T20). Un journal : l'illustration entière, les noms
# des seules zones découvertes, un panneau latéral ; aucun total, aucun « ??? ».
## En-tête : RETOUR et titre.
const MAP_HEADER_HEIGHT := TOUCH_MIN
const MAP_BACK_WIDTH := MENU_CARD_ICON * 2
const MAP_TITLE_FONT := FONT_TITLE
const MAP_GAP := GAP
## Cadre de l'illustration (coins arrondis, l'image est rognée aux coins seulement).
const MAP_FRAME_BORDER := BORDER_WIDTH
## Étiquette d'une zone découverte : pastille sombre translucide, nom discret.
const MAP_LABEL_FONT := FONT_CAPTION
const MAP_LABEL_PAD_H := 14
const MAP_LABEL_PAD_V := 6
const MAP_LABEL_GAP := 8
const MAP_LABEL_BG := Color(0.07, 0.10, 0.15, 0.8)
const MAP_LABEL_ALPHA := 0.9
## Zone du panneau : halo sur l'illustration (au moins MAP_HIGHLIGHT_MIN de côté pour qu'une
## route fine reste visible), remplissage léger et liseré d'ACCENT.
const MAP_HIGHLIGHT_MIN := 56.0
const MAP_HIGHLIGHT_FILL := 0.22
const MAP_HIGHLIGHT_BORDER := 4.0
const MAP_HIGHLIGHT_RADIUS := 12.0
## Portrait du joueur (hauteur ; la largeur suit le rapport 1 : 2 de l'image).
const MAP_PORTRAIT_HEIGHT := 80.0
## Panneau latéral.
const MAP_PANEL_WIDTH := 700
const MAP_PANEL_PAD := 24
const MAP_PANEL_GAP := 16
const MAP_NAME_FONT := FONT_TITLE
const MAP_SUBTITLE_FONT := 28
const MAP_TEXT_FONT := 28
const MAP_SECTION_FONT := 30
const MAP_ENTRY_FONT := FONT_CAPTION
## Pokémon observé : cellule tactile (≥ TOUCH_MIN), sprite de 64 px à l'échelle entière.
const MAP_ENTRY_SIZE := Vector2(172, 190)
const MAP_ENTRY_SPRITE_SOURCE := 64
const MAP_ENTRY_SPRITE_SCALE := 2
const MAP_ENTRY_GAP := 12
## Objet trouvé et service : pastille (icône, nom, « ×2 »).
const MAP_CHIP_ICON := 56
const MAP_CHIP_PAD_H := 18
const MAP_CHIP_PAD_V := 10
const MAP_FADE := ANIM_PANEL


# --- Écran Dresseur du Menu Dresseur (jalon 6, T24) ----------------------------------------------
# Paysage : identité et portrait à gauche, badges et statistiques au centre, grands moments à
# droite. Aucun niveau, XP, titre, tenue ni compteur de badges.
const TRAINER_LEFT_WIDTH := 520
const TRAINER_RIGHT_WIDTH := 600
const TRAINER_GAP := GAP
const TRAINER_HEADER_HEIGHT := TOUCH_MIN
const TRAINER_BACK_WIDTH := MENU_CARD_ICON * 2
const TRAINER_TITLE_FONT := FONT_TITLE
const TRAINER_SECTION_FONT := 30
const TRAINER_SECTION_GAP := 12
## Portrait (sprite du joueur de face, pixel art à l'échelle entière, provisoire jusqu'à la DA).
const TRAINER_PORTRAIT_SCALE := 4
const TRAINER_ROW_ICON := 40
const TRAINER_ROW_FONT := 28
## « vus » / « capturés » : boutons de lien (≥ TOUCH_MIN de haut).
const TRAINER_LINK_HEIGHT := TOUCH_MIN
const TRAINER_LINK_FONT := 28
const TRAINER_LINK_GAP := 12
## Emplacements de badges : 4 par ligne, toujours 8 ; muets tant que non obtenus (Q-13).
const TRAINER_BADGE_COLUMNS := 4
const TRAINER_BADGE_HEIGHT := 150
const TRAINER_BADGE_GAP := 16
const TRAINER_BADGE_MUTE_BG := Color(1, 1, 1, 0.05)
const TRAINER_BADGE_MUTE_BORDER := Color(1, 1, 1, 0.10)
const TRAINER_BADGE_NAME_FONT := FONT_CAPTION
## Statistiques : deux colonnes, icône, libellé discret et valeur.
const TRAINER_STAT_COLUMNS := 2
const TRAINER_STAT_ICON := 44
const TRAINER_STAT_LABEL_FONT := FONT_CAPTION
const TRAINER_STAT_VALUE_FONT := FONT_BUTTON
const TRAINER_STAT_GAP := 14
## Frise des grands moments : rail (ligne et pastille), ligne tactile si lien (≥ TOUCH_MIN).
const TRAINER_MOMENT_HEIGHT := TOUCH_MIN
const TRAINER_MOMENT_GAP := 12
const TRAINER_MOMENT_PAD_H := 16
const TRAINER_MOMENT_PAD_V := 12
const TRAINER_MOMENT_BG := Color(1, 1, 1, 0.06)
const TRAINER_RAIL_WIDTH := 36
const TRAINER_RAIL_LINE := 3.0
const TRAINER_RAIL_DOT := 9.0
const TRAINER_RAIL_COLOR := Color(1, 1, 1, 0.3)
const TRAINER_MOMENT_ICON := 48
const TRAINER_MOMENT_SPRITE := 64
const TRAINER_MOMENT_TITLE_FONT := 30
const TRAINER_MOMENT_DETAIL_FONT := 26
const TRAINER_MOMENT_META_FONT := FONT_CAPTION
const TRAINER_EMPTY_FONT := FONT_BODY
const TRAINER_FADE := ANIM_PANEL

# --- Paramètres (jalon 6, T27 : préférences lues à l'exécution par UiPrefs) ----------------

## Taille du texte « Grande » (Q-19) : facteur des tailles de police (UiPrefs.font).
const TEXT_SCALE_LARGE := 1.15
## Contraste renforcé (Q-19) : opacité minimale des panneaux et texte secondaire plus clair.
const CONTRAST_PANEL_ALPHA := 0.95
const TEXT_MUTED_CONTRAST := Color("#E2E8F2")

# --- Écran Paramètres et choix à deux cartes (jalon 6, T28) -------------------------------------
# Paysage : catégories à gauche, contrôles de la catégorie ouverte à droite. Chaque contrôle fait
# au moins SETTINGS_ROW_HEIGHT de haut (zone tactile ≥ TOUCH_MIN) ; la valeur est toujours écrite.
const SETTINGS_CATEGORY_WIDTH := 460
const SETTINGS_CATEGORY_ICON := 48
const SETTINGS_CATEGORY_GAP := 12
const SETTINGS_ROW_HEIGHT := TOUCH_MIN + 16
const SETTINGS_ROW_GAP := 12
const SETTINGS_ROW_PAD_H := 24
const SETTINGS_ROW_PAD_V := 8
const SETTINGS_ROW_BG := Color(1, 1, 1, 0.06)
const SETTINGS_PANEL_TITLE_FONT := FONT_BUTTON
const SETTINGS_LABEL_FONT := FONT_BODY
const SETTINGS_DETAIL_FONT := FONT_CAPTION
const SETTINGS_VALUE_FONT := 28
const SETTINGS_OPTION_FONT := 28
const SETTINGS_OPTION_MIN_WIDTH := 180
const SETTINGS_OPTION_GAP := 12
const SETTINGS_TEXT_MIN_WIDTH := 300
## Interrupteur : piste arrondie (vert SUCCESS activé, grisé sinon) et pastille blanche.
const SETTINGS_SWITCH_SIZE := Vector2(112, 64)
const SETTINGS_SWITCH_KNOB := 48
const SETTINGS_SWITCH_OFF := Color(1, 1, 1, 0.22)
const SETTINGS_SWITCH_KNOB_COLOR := Color(1, 1, 1, 1)
## Curseur : piste, pastille, largeur de la zone tactile et du pourcentage.
const SETTINGS_SLIDER_WIDTH := 460
const SETTINGS_SLIDER_TRACK := 12
const SETTINGS_SLIDER_KNOB := 56
const SETTINGS_SLIDER_VALUE_WIDTH := 110
const SETTINGS_SLIDER_TRACK_BG := Color(1, 1, 1, 0.18)
## Action « Sauvegarder maintenant ».
const SETTINGS_ACTION_WIDTH := 480
const SETTINGS_ACTION_OFF_BG := Color(1, 1, 1, 0.10)
## Résultat de la sauvegarde : barre sous les contrôles, tenue avant de s'effacer.
const SETTINGS_RESULT_HEIGHT := 88
const SETTINGS_RESULT_HOLD := 3.5
const SETTINGS_FADE := ANIM_PANEL
## ChoiceCards : voile sur le jeu, deux grandes cartes côte à côte.
const CHOICE_SCRIM := Color(0.02, 0.03, 0.05, 0.82)
const CHOICE_CARD_SIZE := Vector2(560, 240)
const CHOICE_CARD_GAP := 32
const CHOICE_CARD_PAD := 28
const CHOICE_TITLE_FONT := FONT_TITLE
const CHOICE_DETAIL_FONT := FONT_BODY
const CHOICE_LABEL_FONT := FONT_TITLE
const CHOICE_CARD_DETAIL_FONT := 28
const CHOICE_SLIDE := 40.0
const CHOICE_FADE := ANIM_PANEL

# Écran Boutique (jalon 7, T11) : langage du Sac (colonnes, cartes) + sélecteur de quantité.
## Colonne de droite (aperçu, QUANTITÉ, TOTAL, CONFIRMER).
const SHOP_DETAIL_WIDTH := 580
const SHOP_ICON := 112
const SHOP_NAME_FONT := FONT_BUTTON
const SHOP_OWNED_FONT := FONT_CAPTION
const SHOP_DESCRIPTION_FONT := 28
const SHOP_CAPTION_FONT := FONT_CAPTION
const SHOP_UNIT_PRICE_FONT := FONT_BODY
## Prix sous chaque carte d'objet.
const SHOP_CARD_PRICE_FONT := 28
const SHOP_CARD_PRICE_HEIGHT := 44
## Sélecteur de quantité : boutons − / + (≥ TOUCH_MIN) et nombre au centre.
const SHOP_STEPPER_SIZE := TOUCH_MIN
const SHOP_STEPPER_ICON := 56
const SHOP_QUANTITY_FONT := 56
const SHOP_TOTAL_FONT := 44
## Argent affiché dans la colonne de gauche.
const SHOP_MONEY_FONT := 44
const SHOP_MONEY_LABEL_FONT := FONT_CAPTION
const SHOP_COIN_ICON := 48
## Appui long sur − / + : délai (LONG_PRESS), intervalle lent puis rapide, pas rapide.
const SHOP_REPEAT_DELAY := LONG_PRESS
const SHOP_REPEAT_SLOW := 0.16
const SHOP_REPEAT_FAST := 0.06
const SHOP_REPEAT_FAST_AFTER := 1.2
const SHOP_REPEAT_FAST_STEP := 5
## Indisponible : CONFIRMER et sélecteur atténués (la raison est écrite à côté).
const SHOP_DISABLED_ALPHA := 0.45

# --- Écran Stockage (jalon 7, T15 ; jalon-07.md §6.4, §6.9) --------------------------------------
# Trois colonnes dans la zone sous l'en-tête (840 px de haut) : ÉQUIPE (six cartes de TOUCH_MIN),
# Pokémon sélectionné et ses actions, STOCKAGE (grille défilante, 2 colonnes à 1920, 3 à 2340).

const STORAGE_PARTY_WIDTH := 440
const STORAGE_DETAIL_WIDTH := 400
const STORAGE_COLUMN_GAP := GAP
## Titre de colonne (« ÉQUIPE », « STOCKAGE »).
const STORAGE_TITLE_HEIGHT := 40
const STORAGE_TITLE_FONT := FONT_BODY
## Écart entre les six cartes de l'équipe : six de TOUCH_MIN + cinq écarts + le titre ≤ 840.
const STORAGE_PARTY_GAP := 4
## Grille : largeur minimale d'une carte et écarts.
const STORAGE_GRID_MIN_CELL := 420
const STORAGE_GRID_GAP := 12
const STORAGE_GRID_PAD := 8
## Pokémon sélectionné : sprite 64 px à l'échelle entière.
const STORAGE_SPRITE_SOURCE := 64
const STORAGE_SPRITE_SCALE := 3
const STORAGE_DETAIL_GAP := 6
## Boutons d'action (≥ TOUCH_MIN) : le principal prend la place, FAVORI aussi, « ⋯ » est carré.
const STORAGE_ACTION_HEIGHT := TOUCH_MIN
const STORAGE_MORE_WIDTH := TOUCH_MIN
## Menu secondaire « ⋯ » : largeur et hauteur d'un choix.
const STORAGE_MENU_WIDTH := 360
const STORAGE_MENU_ITEM_HEIGHT := TOUCH_MIN
## La raison d'un refus reste affichée ce temps (s) ou jusqu'au prochain geste.
const STORAGE_REFUSAL_SECONDS := 4.0
const STORAGE_REFUSAL_FONT := 28
const STORAGE_REFUSAL_BG := Color(0.30, 0.08, 0.08, 0.94)
## Cadre de la colonne visée par un glisser.
const STORAGE_DROP_BORDER := 4
const HAPTIC_STORAGE_MOVE_MS := 20
