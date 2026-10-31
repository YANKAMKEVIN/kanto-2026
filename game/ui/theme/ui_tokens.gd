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
## Écran de prénom de l'introduction (OUV.2) : au-dessus de la boîte de dialogue, qui reste
## ouverte derrière et prendrait sinon tous les touchers (QA S21).
const LAYER_NAME_ENTRY := 31
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
## Bouton Vélo (passe systèmes 2, `systemes-2.md` §2.3) : à gauche du bouton courir, même hauteur
## [D] ; au-dessus, il couvrait l'étiquette du bouton contextuel (QA S21, 2026-10-21).
const BIKE_BUTTON_CENTER_FROM_CORNER := Vector2(620, 220)
## Bouton Vélo grisé (intérieur, Piste) : opacité [D] ; le toucher dit le refus.
const BIKE_BUTTON_DIMMED_ALPHA := 0.45
## Boutons d'exploration sous le joueur (moteur commun, défaut D5 de la QA du J24 : au bord de la
## carte, la caméra est bornée et le joueur peut passer sous les boutons) : le groupe de boutons
## qu'il touche devient transparent [D] (il reste actif) ; marge autour des boutons (px) [D].
const BUTTONS_UNDER_PLAYER_ALPHA := 0.3
const BUTTONS_UNDER_PLAYER_MARGIN := 12.0

## Contextuel : un seul bouton en bas à droite, au-dessus et à droite du bouton courir
## (planche DA 2026 ; bible UI/UX §1). Centre mesuré depuis le coin bas-droit.
const INTERACT_BUTTON_CENTER_FROM_CORNER := Vector2(190, 360)
## Étiquette du verbe (PARLER, EXAMINER…) : pastille à gauche du bouton contextuel.
const INTERACT_LABEL_FONT := 26
const INTERACT_LABEL_PAD_H := 20
const INTERACT_LABEL_PAD_V := 8
## Vibration courte à l'appui du bouton contextuel (millisecondes).
const HAPTIC_TAP_MS := 15

# --- Bulle « ! » d'un Dresseur (jalon 9, T12) -----------------------------------------------

## Durée totale (s) : apparition en rebond + tenue + fondu ; [constant Npc.EMOTE_DURATION].
const EMOTE_DURATION := 0.6
const EMOTE_POP := 0.18
const EMOTE_FADE := 0.15
## Hauteur (px monde) de la pointe de la bulle au-dessus des pieds (la tête est à ~ -128 : la pointe en effleure le haut).
const EMOTE_TIP_HEIGHT := 118.0
## Taille affichée (échelle de l'icône 96 px) ; le rebond (TRANS_BACK) dépasse d'environ 10 %.
const EMOTE_SCALE := 0.7
## Montée de la bulle pendant l'apparition (px monde).
const EMOTE_RISE := 18.0
## Dépassement maximal du rebond (TRANS_BACK, ≈ 10 %) : sert à garder la bulle dans l'écran.
const EMOTE_OVERSHOOT := 1.12

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
## Bas de la carte joueur depuis le bas de l'écran (CB.2) : en bas à droite, juste au-dessus
## de la grille d'actions et du bandeau des capacités (le plus haut des deux : 348 px).
const BATTLE_OWN_CARD_BOTTOM := 358
## Bas de la grille d'actions et du bandeau des messages depuis le bas de l'écran.
const BATTLE_GRID_BOTTOM := 56
## Bas des cartes de capacités depuis le bas de l'écran.
const BATTLE_MOVES_BOTTOM := 56
## CB.2 — Sac de combat en rangées (storyboard) : largeur du panneau (l'ÉQUIPE garde
## BAG_PANEL_WIDTH), hauteur, écart, icône des rangées.
const BATTLE_BAG_WIDTH := 760
const BATTLE_BAG_ROW_HEIGHT := 128
const BATTLE_BAG_ROW_GAP := 12
const BATTLE_BAG_ROW_ICON := 72
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
## Taille plancher du nom : un nom long (« GROTADMORV ») rétrécit jusqu'ici pour tenir en entier
## dans BATTLE_CARD_WIDTH avec ♀, statut et « Nv. 100 » (QA 23E), jamais rogné. 22 et non 24 :
## le pire cas des données (« DARDARGNAN ♀ BRÛ Nv. 100 ») descend à 23 (défaut, règle 4).
const BATTLE_CARD_NAME_FONT_MIN := 22
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
## Trace des PV perdus (CV-9) : segment clair qui reste HP_TRAIL_HOLD s derrière la barre, puis
## la rattrape en HP_TRAIL_CATCH s. Valeurs par défaut, provisoires.
const HP_TRAIL_HOLD := 0.3
const HP_TRAIL_CATCH := 0.25
const HP_TRAIL_COLOR := Color(1, 1, 1, 0.7)
## Pulsation de la carte sous HP_LOW_THRESHOLD (dossier 05 §12) : demi-période et échelle.
const HP_LOW_PULSE := 0.55
const HP_LOW_PULSE_SCALE := 1.025
## Vibrations sur un coup reçu, plus marquée sur un coup critique (bible §12).
const HAPTIC_HIT_MS := 30
const HAPTIC_CRIT_MS := 70
## Combat vivant (§4.2) [D] : vibration d'un gros coup (plus de HP_BIG_HIT des PV max), entre le
## coup et le critique.
const HAPTIC_BIG_HIT_MS := 50

# Pastilles d'équipe (au-dessus de la carte joueur).
const PARTY_SIZE := 6
const PARTY_PIP := 28
const PARTY_PIP_GAP := 10
## Retrait depuis le bord gauche de la carte, et écart au-dessus de la carte.
const PARTY_PIPS_INSET := 20
const PARTY_PIPS_GAP := 8
const PARTY_PIP_EMPTY := Color(0.62, 0.67, 0.74, 0.9)
const PARTY_PIP_EMPTY_BORDER := Color(0.06, 0.09, 0.13, 0.55)

# Grille des 4 actions (combat-v1 : boutons colorés).
const ACTION_ATTACK := Color("#E04A3C")
const ACTION_BAG := Color("#D49A2E")
const ACTION_TEAM := Color("#2D6DB5")
const ACTION_RUN := Color(0.16, 0.2, 0.25, 0.92)
const BATTLE_ACTION_SIZE := Vector2(360, 128)
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
const MOVE_CARD_SIZE := Vector2(560, 128)
## Écart horizontal : il loge la flèche ▶ de sélection de la colonne de droite.
const MOVE_GAP_H := 48
const MOVE_GAP_V := 16
## Bandeau sombre derrière les cartes : marge intérieure (à gauche : MOVE_GAP_H, pour la
## flèche de la colonne de gauche) et débord jusqu'aux bords droit et bas de l'écran.
const MOVE_BAND_PAD := 20
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
## Une phrase qui attend un toucher (« X apprend Y ! ») ignore les touchers de cette durée.
const BATTLE_MESSAGE_TOUCH_LOCK := 0.3

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
const BAG_GRID_MAX_HEIGHT := 400
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

# --- Bilan de fin de combat (demande n° 1, décisions de Kevin du 2026-10-06) ------------------
# Une carte sans titre, centrée, le décor du combat visible autour : une ligne par Pokémon qui a
# gagné de l'XP (vignette, nom, « Nv. 8 ▸ Nv. 9 », barre d'XP, « 112 / 173 », « +11 XP »), les
# gains de statistiques sous la ligne de celui qui monte, la consigne discrète en dessous.

## Largeur de la carte (référence 1920) et marges ; écart entre les lignes.
const SUMMARY_CARD_WIDTH := 1800
const SUMMARY_CARD_MAX_HEIGHT := 984
## Fond quasi opaque : ni la tête du Pokémon ni le joueur ne transparaissent sous le texte
## (le décor reste visible autour de la carte, sous le voile du combat).
const SUMMARY_CARD_BG := Color(0.06, 0.09, 0.13, 0.97)
## Texte secondaire (« Nv. 8 », « 58 / 105 », consigne, libellés des stats) : plus clair que
## TEXT_MUTED, contraste ≥ 7 : 1 sur le fond de la carte (testé).
const SUMMARY_SECONDARY := DIALOG_NARRATION
const SUMMARY_CARD_PAD_H := 28
const SUMMARY_CARD_PAD_V := 24
const SUMMARY_ROW_GAP := 10
## Écart entre la ligne nom/niveaux et la ligne barre/points.
const SUMMARY_LINE_GAP := 6
## Une ligne : fond translucide, liseré ; celle qui monte de niveau prend un liseré ACCENT.
const SUMMARY_ROW_BG := Color(1, 1, 1, 0.05)
const SUMMARY_ROW_BORDER := PANEL_BORDER
const SUMMARY_ROW_PAD_H := 16
const SUMMARY_ROW_PAD_V := 6
const SUMMARY_ROW_HIGHLIGHT_BORDER := 3
## Fond de la ligne mise en valeur : opaque, pour que le halo ACCENT reste autour (pas dessous).
const SUMMARY_ROW_LIT_BG := PANEL_BG_STRONG
## Vignette du Pokémon (sprite pixel art, NEAREST) et son cadre.
const SUMMARY_THUMB := 112
const SUMMARY_THUMB_PAD := 4
## Colonnes : nom, niveaux, barre (le reste), « 112 / 173 », « +11 XP ».
const SUMMARY_NAME_WIDTH := 300
const SUMMARY_LEVEL_WIDTH := 340
const SUMMARY_POINTS_WIDTH := 210
const SUMMARY_GAIN_WIDTH := 230
const SUMMARY_NAME_FONT := FONT_TITLE
const SUMMARY_LEVEL_FONT := FONT_BUTTON
const SUMMARY_LEVEL_UP_FONT := FONT_TITLE
const SUMMARY_POINTS_FONT := FONT_BODY
const SUMMARY_GAIN_FONT := FONT_TITLE
const SUMMARY_LEVEL_ARROW := 28
## Gains de statistiques : grille de SUMMARY_STATS_COLUMNS colonnes à droite de la ligne
## (libellé clair, valeur ACCENT), dans un cadre discret.
const SUMMARY_STATS_FONT := FONT_BODY
const SUMMARY_STATS_COLUMNS := 2
const SUMMARY_STATS_LABEL_WIDTH := 150
const SUMMARY_STATS_VALUE_WIDTH := 56
const SUMMARY_STATS_GAP_H := 28
const SUMMARY_STATS_GAP_V := 0
const SUMMARY_STATS_BG := Color(1, 1, 1, 0.06)
const SUMMARY_STATS_PAD_H := 20
const SUMMARY_STATS_PAD_V := 8
## Barre d'XP du bilan : plus épaisse que celle de la carte de combat.
const SUMMARY_BAR_HEIGHT := 14
## Consigne « Touchez l'écran pour continuer » : capsule discrète sous la carte.
const SUMMARY_HINT_FONT := FONT_BODY
const SUMMARY_HINT_BG := PANEL_BG
const SUMMARY_HINT_PAD_H := 32
const SUMMARY_HINT_PAD_V := 10
const SUMMARY_HINT_GAP := 18
const SUMMARY_HINT_FADE := ANIM_PANEL
## Rythme : les barres partent ensemble après SUMMARY_START_DELAY ; sans montée de niveau, une
## barre se remplit en SUMMARY_FILL (≈ 1,2 s avec l'arrivée de la carte) ; avec montée, chaque
## tranche prend SUMMARY_FILL_SLICE, puis le passage de niveau tient SUMMARY_LEVEL_HOLD (niveau
## qui pulse, ligne mise en valeur, gains de statistiques).
const SUMMARY_START_DELAY := 0.1
const SUMMARY_FILL := 0.8
const SUMMARY_FILL_SLICE := 0.6
const SUMMARY_LEVEL_HOLD := 0.7
## « Nv. 9 » grossit un instant (comme LEVEL_PULSE), la ligne rebondit légèrement.
const SUMMARY_LEVEL_PULSE_SCALE := 1.35
const SUMMARY_ROW_BOUNCE := 1.03
const SUMMARY_STATS_FADE := 0.25
## Un toucher pendant le remplissage accélère tout (×SUMMARY_FAST) ; un second termine.
const SUMMARY_FAST := 4.0
## Un toucher n'est pris qu'après ce délai (celui du dernier message ne compte pas).
const SUMMARY_TOUCH_LOCK := 0.3

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
const TEAM_LIST_WIDTH := 520
const TEAM_SHEET_WIDTH := 760
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
const TEAM_EVO_CIRCLE := 88
const TEAM_EVO_SPRITE := 84
const TEAM_EVO_FONT := FONT_CAPTION
## Fiche d'une capacité ouverte au toucher : voile derrière.
const TEAM_SCRIM := Color(0.02, 0.03, 0.05, 0.55)
## Sélection d'un emplacement et cible de dépôt.
const TEAM_SLOT_SELECTED_BORDER := 4
const HAPTIC_TEAM_DRAG_MS := 25
const HAPTIC_TEAM_SWAP_MS := 20

# Écran Sac du Menu Dresseur (jalon 6, T11).
## Colonnes : catégories à gauche, cartes au centre (le reste), aperçu à droite.
const BAG_SCREEN_LEFT_WIDTH := 460
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
## En-tête : RETOUR, titre + compteur, filtres (Tous · Vus · Capturés · Habitats).
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
const DEX_SILHOUETTE := Color(0.10, 0.13, 0.19, 0.92)
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
## L'écran remonte dans la rangée du × (hauteur de l'en-tête commun) et y pose son « ‹ » (MM.2).
const DEX_LAYOUT_RISE := MENU_BODY_TOP - SAFE_MARGIN
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
const DEX_LAYOUT_EVO_PREVIEW := 120
## Vignette dans son rond (part du diamètre) ; hauteur des lignes titre / pied des aperçus.
const DEX_LAYOUT_EVO_IMAGE_RATIO := 0.86
const DEX_LAYOUT_PREVIEW_ROW := 48
const DEX_LAYOUT_PREVIEW_ICON := 36
const DEX_LAYOUT_PREVIEW_TITLE_FONT := 28
const DEX_LAYOUT_PILL_RADIUS := 64
## Onglets de la fiche : texte serré pour que « Observations » tienne à 1920.
const DEX_LAYOUT_TAB_FONT := 22
const DEX_LAYOUT_TAB_PAD := 4

# --- Pokédex : rapprochement de la maquette (refonte, T4) ----------------------------------------
## Fond du menu derrière le Pokédex : voile plus léger que MENU_DIM (le monde lumineux, flouté,
## se voit à travers les panneaux de verre) et flou un peu plus large.
const DEX_BACKDROP_DIM := 0.2
const DEX_BACKDROP_BLUR := 10.0
const DEX_BACKDROP_LOD := 3.0
## Panneaux en verre teinté : fond translucide, coins très arrondis, liseré fin et clair.
const DEX_GLASS_BG := Color(0.05, 0.09, 0.14, 0.62)
const DEX_GLASS_BORDER := Color(1.0, 1.0, 1.0, 0.18)
const DEX_GLASS_BORDER_WIDTH := 2
const DEX_GLASS_RADIUS := 30
const DEX_GLASS_SHADOW := Color(0.0, 0.0, 0.0, 0.25)
const DEX_GLASS_SHADOW_SIZE := 18
## Cartes posées dans un panneau (Types, Habitat, Évolution, Vu / Capturé, Taille / Poids).
const DEX_CARD_BG := Color(0.03, 0.06, 0.10, 0.42)
const DEX_CARD_BORDER := Color(1.0, 1.0, 1.0, 0.12)
const DEX_CARD_RADIUS := 20
const DEX_CARD_PAD := 16
## Rangée du haut : « Pokédex » sobre + compteur discret, capsule de filtres, recherche compacte.
## Les zones touchables gardent TOUCH_MIN de haut ; le dessin est plus fin (marges négatives).
const DEX_TOP_TITLE_FONT := 42
const DEX_TOP_COUNTS_FONT := 20
const DEX_TOP_BALL := 56
const DEX_TOP_BACK_DRAW := 96
const DEX_CAPSULE_DRAW := 80
const DEX_CAPSULE_PAD := 6
const DEX_SEGMENT_DRAW := 66
const DEX_SEGMENT_MIN_WIDTH := TOUCH_MIN
const DEX_SEGMENT_PAD := 22
const DEX_SEGMENT_FONT := 26
const DEX_SEGMENT_ON_BG := Color(0.16, 0.36, 0.48, 0.85)
const DEX_SEGMENT_ON_BORDER := Color(0.55, 0.85, 0.95, 0.9)
const DEX_SEARCH_WIDTH := 400
const DEX_SEARCH_DRAW := 80
## Tête de la grille : bouton Type (et Zone) en capsule fine.
const DEX_REFINE_DRAW := 68
const DEX_REFINE_FONT := 26
## Grand portrait : décor peint flouté (PokedexScene) sous le Pokémon, lumière douce et chaude,
## vignettage léger, fondu vers le panneau en bas (description lisible).
const DEX_SCENE_LIGHT_CENTER := Vector2(0.55, 0.36)
const DEX_SCENE_LIGHT_COLOR := Color(1.0, 0.86, 0.62)
const DEX_SCENE_LIGHT := 0.32
const DEX_SCENE_LIFT := 0.0
const DEX_SCENE_SATURATION := 1.2
const DEX_SCENE_VIGNETTE := 0.45
const DEX_SCENE_FADE_COLOR := Color(0.05, 0.08, 0.13, 0.94)
## Le fondu commence au bas des cartes Vu / Capturé (part de la hauteur du panneau) + marge.
const DEX_SCENE_FADE_SPAN := 0.16
## Le Pokémon : boîte au plus PORTRAIT_WIDTH de la scène en largeur ; il peut monter dans la zone
## du nom de PORTRAIT_RISE de sa hauteur ; ses pieds s'arrêtent FEET_GAP au-dessus des cartes.
const DEX_PORTRAIT_WIDTH := 0.9
const DEX_PORTRAIT_RISE := 0.35
const DEX_PORTRAIT_FEET_GAP := 6
const DEX_PORTRAIT_SHIFT := 0.07
## Hauteur maximale du Pokémon (espèce seulement vue : la scène est plus haute).
const DEX_PORTRAIT_MAX := 470.0
const DEX_PORTRAIT_HALO_ALPHA := 0.55
## Nom et numéro lisibles sur le décor (ombre portée).
const DEX_SCENE_TEXT_SHADOW := Color(0.0, 0.0, 0.0, 0.55)
const DEX_SCENE_TEXT_SHADOW_SIZE := 6
## Cartes Taille / Poids sous la description (centre).
const DEX_FACT_ICON := 40
## Onglets de la fiche : icône au-dessus du libellé.
const DEX_TAB_ICON := 44
const DEX_TAB_LABEL_FONT := 22
## Aperçu : carte d'Habitat (carte resserrée sur les zones observées, à gauche ; noms à droite).
const DEX_MAP_PREVIEW_HEIGHT := 250
const DEX_MAP_ASPECT := 1.5
## Part de la largeur de la carte d'Habitat face à ses noms (la carte domine, comme la maquette).
const DEX_MAP_STRETCH := 1.5
## Région la plus petite montrée (pixels de l'illustration) : une petite zone n'est pas
## agrandie à l'excès.
const DEX_MAP_MIN_REGION := Vector2(300, 200)
## Voile sur la géographie autour des zones observées (aucune zone n'y est nommée ni marquée).
const DEX_MAP_VEIL := Color(0.04, 0.07, 0.12, 0.6)
const DEX_MAP_RADIUS := 16
const DEX_MAP_ZONE_ROWS := 3
const DEX_PREVIEW_ROW := 44

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
# MM.3 (maquette, valeurs par défaut règle 4) : catégories de verre à gauche (la choisie en
# ACCENT avec un halo), section de verre à droite (icône, titre, sous-titre), lignes séparées par
# un filet dans une carte intérieure.
const SETTINGS_CATEGORY_WIDTH := 420
const SETTINGS_CATEGORY_ICON := 44
const SETTINGS_CATEGORY_GAP := 10
const SETTINGS_CATEGORY_FONT := FONT_BODY
const SETTINGS_CATEGORY_BG := Color(1, 1, 1, 0.05)
const SETTINGS_CATEGORY_GLOW := Color(0.96, 0.77, 0.26, 0.4)
const SETTINGS_CATEGORY_GLOW_SIZE := 14
const SETTINGS_ROW_HEIGHT := TOUCH_MIN
const SETTINGS_ROW_GAP := 0
const SETTINGS_ROW_PAD_H := 28
const SETTINGS_ROW_PAD_V := 6
const SETTINGS_ROW_BG := Color(1, 1, 1, 0.0)
const SETTINGS_ROW_DIVIDER := Color(1, 1, 1, 0.09)
const SETTINGS_ROW_DIVIDER_WIDTH := 2
const SETTINGS_ROW_PRESSED_BG := Color(0.96, 0.77, 0.26, 0.16)
const SETTINGS_PANEL_TITLE_FONT := FONT_TITLE
const SETTINGS_SUBTITLE_FONT := FONT_CAPTION
const SETTINGS_SECTION_ICON := 64
const SETTINGS_SECTION_GAP := 20
const SETTINGS_LABEL_FONT := 30
const SETTINGS_DETAIL_FONT := FONT_CAPTION
const SETTINGS_VALUE_FONT := 28
const SETTINGS_OPTION_FONT := 28
const SETTINGS_TEXT_MIN_WIDTH := 300
## Sélecteur « ‹ Valeur › » : pilule de SETTINGS_PILL_HEIGHT dessinée dans une rangée de
## TOUCH_MIN ; flèches de TOUCH_MIN de côté, valeur au milieu.
const SETTINGS_PILL_HEIGHT := 76
const SETTINGS_PILL_BG := Color(1, 1, 1, 0.07)
const SETTINGS_PILL_BORDER := Color(1, 1, 1, 0.16)
const SETTINGS_PILL_VALUE_WIDTH := 250
const SETTINGS_ARROW_ICON := 30
const SETTINGS_ARROW_PRESSED_DRAW := 64
const SETTINGS_ARROW_OFF := Color(1, 1, 1, 0.22)
## Valeur écrite à côté d'un interrupteur (« Activé ») : discrète, la règle 7 la garde.
const SETTINGS_STATE_FONT := FONT_CAPTION
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
## Action « Sauvegarder maintenant » : toute la ligne se touche ; icône sombre dans un rond
## ACCENT à droite (action principale).
const SETTINGS_ACTION_ROUND := 88
const SETTINGS_ACTION_ICON := 40
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
## Recherche (champ DexSearch) et bouton de tri, à droite du titre STOCKAGE (≥ TOUCH_MIN de haut).
const STORAGE_SEARCH_WIDTH := 360
const STORAGE_SORT_WIDTH := 300
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

# --- Poison (jalon 9, T5 ; dossier 08 §2 : le statut est toujours un texte) -------------------
## Étiquette « PSN » : pastille de la couleur du type Poison (TypeBadge, sans icône) sur la carte
## de PV du combat.
const STATUS_POISON := Color("#A33EA1")
## Même teinte éclaircie pour le texte « PSN » posé sur un panneau sombre (listes d'équipe, cibles
## du Sac) : la pastille pleine ne tient pas dans ces lignes, et #A33EA1 seul y est trop sombre.
const STATUS_POISON_TEXT := Color("#E08EDD")
## Dégât de poison : voile violet sur le Pokémon (shader du sprite : la couleur se fond vers
## STATUS_VEIL, jusqu'à STATUS_VEIL_AMOUNT au pic, puis revient), durée totale (s) à
## speed_scale = 1 ; version douce quand « Réduire les animations » est actif.
const STATUS_VEIL := Color("#B04CC8")
## Brûlure (jalon 11) : même voile de fin de tour, teinte orangée.
const STATUS_BURN_VEIL := Color("#F07A2A")
const STATUS_VEIL_AMOUNT := 0.6
const STATUS_VEIL_AMOUNT_REDUCED := 0.3
const STATUS_VEIL_DURATION := 0.35
## Vibration du dégât de poison (ms) : plus douce qu'un coup reçu (HAPTIC_HIT_MS).
const HAPTIC_STATUS_MS := 20

# --- Écran d'évolution (jalon 9, jalon-09.md §2.3.3 ; dossier 04 §7 : 8 à 12 s) --------------
# Défauts (règle 4). Durées en secondes, multipliées par EvolutionScreen.speed_scale (0 = tests ;
# « Réduire les animations » : facteur du combat). Total hors lecture des textes : OPEN +
# PRESENT + TRANSFORM + FLASH + SILENCE + REVEAL = 0,5 + 1,5 + 2,5 + 0,3 + 0,3 + 0,8 = 5,9 s
# (jalon 11, dossier 14 §7 : évolution courte ≈ 6 s, au lieu de 8,5 s ; surtout la transformation).
# Toucher l'écran pendant la séquence la joue ×EVOLUTION_RUSH (EvolutionScreen).

## Calque : au-dessus de l'interface de combat (LAYER_BATTLE_HUD), sous les transitions.
const LAYER_EVOLUTION := 24
## L'environnement disparaît : fondu vers le fond sombre.
const EVOLUTION_OPEN := 0.5
## L'ancienne espèce au centre et « Quoi ? X évolue ! », sans toucher.
const EVOLUTION_PRESENT := 1.5
## Dans PRESENT : le Pokémon monte en fondu, la phrase suit.
const EVOLUTION_ENTER := 0.6
const EVOLUTION_ENTER_RISE := 36.0
const EVOLUTION_TEXT_DELAY := 0.35
## Deuxième évolution du même écran : l'espèce précédente s'efface d'abord (dans PRESENT).
const EVOLUTION_SWITCH_OUT := 0.25
## Transformation (ARRÊTER visible) ; couleurs → silhouette blanche en son début.
const EVOLUTION_TRANSFORM := 2.5
const EVOLUTION_TO_SILHOUETTE := 0.4
## Intervalle entre deux silhouettes, au début et à la fin (elles alternent en accélérant).
const EVOLUTION_SWAP_START := 0.45
const EVOLUTION_SWAP_END := 0.045
## Petit grossissement à chaque bascule de silhouette (fraction de la taille).
const EVOLUTION_SWAP_POP := 0.06
## Flash : montée puis retombée (total FLASH), opacité au sommet ; « Réduire les flashs ».
const EVOLUTION_FLASH := 0.3
const EVOLUTION_FLASH_RISE := 0.08
const EVOLUTION_FLASH_ALPHA := 0.95
const EVOLUTION_FLASH_REDUCED_ALPHA := 0.3
## Silence : la nouvelle silhouette, immobile, avant les couleurs.
const EVOLUTION_SILENCE := 0.3
## Révélation : silhouette → couleurs, halo doré, onde ; nom puis phrase.
const EVOLUTION_REVEAL := 0.8
const EVOLUTION_NAME_DELAY := 0.2
const EVOLUTION_LINE_DELAY := 0.45
## Jalon 11 [D] : vitesse de la séquence après un toucher (×2), jusqu'à la consigne de toucher.
const EVOLUTION_RUSH := 2.0
## Annulée : retour aux couleurs de l'ancienne espèce.
const EVOLUTION_REVERT := 0.6
## Apparition et disparition d'une phrase ; montée du texte.
const EVOLUTION_TEXT_IN := 0.35
const EVOLUTION_TEXT_OUT := 0.15
const EVOLUTION_TEXT_RISE := 18.0
## Consigne « Touchez l'écran… » : apparition puis respiration (période, opacité basse).
const EVOLUTION_HINT_IN := 0.3
const EVOLUTION_HINT_PERIOD := 1.4
const EVOLUTION_HINT_DIM := 0.45
## Fermeture : retour à la vue de combat.
const EVOLUTION_CLOSE := 0.45
## Bouton ARRÊTER : apparition / disparition.
const EVOLUTION_STOP_IN := 0.18
const EVOLUTION_STOP_OUT := 0.12
## Vibration courte à la révélation.
const EVOLUTION_HAPTIC_MS := 35

## Composition (référence 1080 de haut ; centrée horizontalement, de 1920 à 2340 de large).
## Cadre de l'artwork (carré, l'image y est posée sur le bas) et centre de ce cadre.
const EVOLUTION_ART_SIZE := 500
const EVOLUTION_ART_CENTER_Y := 400
## Halo derrière le Pokémon, ombre au sol (largeur, hauteur), onde de la révélation.
const EVOLUTION_GLOW_SIZE := 980
const EVOLUTION_SHADOW_SIZE := Vector2(420, 64)
const EVOLUTION_RING_SIZE := 900
## Rayons : nombre, rayon, demi-largeur d'un rayon (radians), vitesse de rotation (rad/s)
## au repos et au plus fort de la transformation.
const EVOLUTION_RAY_COUNT := 18
const EVOLUTION_RAY_RADIUS := 760.0
const EVOLUTION_RAY_HALF_WIDTH := 0.06
const EVOLUTION_RAY_SPIN := 0.06
const EVOLUTION_RAY_SPIN_PEAK := 0.9
## Textes : nom de la nouvelle espèce (MAJUSCULES), phrase, consigne — hauts de ligne.
const EVOLUTION_NAME_FONT := 64
const EVOLUTION_NAME_TOP := 700
const EVOLUTION_LINE_TOP := 790
const EVOLUTION_LINE_WIDTH := 1500
const EVOLUTION_HINT_TOP := 872
## Bouton ARRÊTER (≥ TOUCH_MIN), en bas à droite.
const EVOLUTION_STOP_SIZE := Vector2(320, TOUCH_MIN)
const EVOLUTION_STOP_RIGHT := SAFE_MARGIN + 32
const EVOLUTION_STOP_BOTTOM := SAFE_MARGIN + 16
const EVOLUTION_STOP_ICON := 40
## Panneau d'oubli ouvert (il prend la droite) : le Pokémon et son nom glissent au milieu de
## la place libre, à cette vitesse de rattrapage (1/s, exponentielle).
const EVOLUTION_MAKE_ROOM_RATE := 8.0
## Bandeau des capacités apprises : en bas au centre.
const EVOLUTION_BANNER_BOTTOM := SAFE_MARGIN
## Poussières de lumière qui montent (nombre, vie, vitesse min/max, étendue de l'émission).
const EVOLUTION_MOTES := 36
const EVOLUTION_MOTE_LIFE := 7.0
const EVOLUTION_MOTE_SPEED := Vector2(22.0, 58.0)
const EVOLUTION_MOTE_AREA := Vector2(1240.0, 260.0)
const EVOLUTION_MOTE_TEXTURE := 32
const EVOLUTION_MOTE_SCALE := Vector2(0.25, 0.8)
## Accélération des poussières au plus fort de la transformation.
const EVOLUTION_MOTE_RUSH := 4.0

## Couleurs. Fond opaque (nuit bleutée), lueur ambiante au centre, halo froid puis doré,
## silhouette blanche, flash, poussières.
const EVOLUTION_BG := Color(0.02, 0.03, 0.06)
const EVOLUTION_AMBIENT := Color(0.13, 0.19, 0.31, 1.0)
const EVOLUTION_GLOW_COOL := Color(0.62, 0.78, 1.0, 1.0)
const EVOLUTION_GLOW_GOLD := Color(1.0, 0.84, 0.45, 1.0)
## Opacité du halo : calme, au plus fort de la transformation, après la révélation.
const EVOLUTION_GLOW_CALM := 0.28
const EVOLUTION_GLOW_PEAK := 0.85
const EVOLUTION_GLOW_REVEALED := 0.5
const EVOLUTION_SILHOUETTE := Color(1.0, 1.0, 1.0, 1.0)
## Aura de la silhouette : copies agrandies et translucides (une lueur sans flou coûteux).
const EVOLUTION_AURA_SCALES: Array[float] = [1.02, 1.045, 1.07, 1.1, 1.135]
const EVOLUTION_AURA_ALPHAS: Array[float] = [0.3, 0.19, 0.12, 0.07, 0.035]
const EVOLUTION_FLASH_COLOR := Color(1.0, 0.98, 0.92, 1.0)
const EVOLUTION_RAY_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const EVOLUTION_RAY_ALPHA_PEAK := 0.26
const EVOLUTION_RAY_ALPHA_REVEALED := 0.12
const EVOLUTION_MOTE := Color(1.0, 0.93, 0.75, 0.55)
const EVOLUTION_SHADOW := Color(0.0, 0.0, 0.0, 0.55)

# Menu Dresseur rapproché des maquettes (MM.1, docs/tech/menu-maquettes.md) : tableau de bord,
# Équipe et Sac. Verre léger sur le monde flouté (méthode du Pokédex), bandeau d'état en haut à
# droite, retour « ‹ » compact. Valeurs par défaut notées dans etat-projet.md.
## Fond du menu derrière ces écrans : voile plus léger que MENU_DIM, flou du Pokédex.
const MENU_GLASS_DIM := 0.3
const MENU_GLASS_BLUR := DEX_BACKDROP_BLUR
const MENU_GLASS_LOD := DEX_BACKDROP_LOD
## Panneau de verre (MenuGlass) et carte intérieure (MenuGlassCard) : ceux du Pokédex.
const MENU_GLASS_BG := DEX_GLASS_BG
const MENU_GLASS_BORDER := DEX_GLASS_BORDER
const MENU_GLASS_RADIUS := DEX_GLASS_RADIUS
const MENU_GLASS_PAD := 24
const MENU_GLASS_CARD_BG := DEX_CARD_BG
const MENU_GLASS_CARD_BORDER := DEX_CARD_BORDER
const MENU_GLASS_CARD_RADIUS := DEX_CARD_RADIUS
## Rangée d'en-tête : × (tableau de bord) ou ‹ (écrans) dessinés en rond de MENU_ROUND_DRAW,
## zone tactile TOUCH_MIN.
const MENU_ROUND_DRAW := 88
const MENU_ROUND_ICON := 40
## Titre d'écran dans la rangée d'en-tête (« Équipe 3/6 », « Sac ») : icône, titre, compteur.
const MENU_TITLE_ICON := 60
const MENU_TITLE_FONT := FONT_TITLE
const MENU_TITLE_COUNT_FONT := FONT_BODY
const MENU_TITLE_GAP := 20
## Bandeau d'état (lieu · heure · argent) : pastille de verre de MENU_STATUS_DRAW de haut.
const MENU_STATUS_DRAW := 80
const MENU_STATUS_FONT := 30
const MENU_STATUS_ICON := 36
const MENU_STATUS_PAD_H := 30
const MENU_STATUS_GAP := 14
const MENU_STATUS_DIVIDER := Color(1, 1, 1, 0.2)
const MENU_STATUS_DIVIDER_SIZE := Vector2(2, 36)
## Grandes cartes illustrées : l'illustration couvre la carte (coins arrondis), un dégradé vers
## la teinte de la carte commence à MENU_ART_FADE_FROM de la hauteur (le titre se lit dessus).
const MENU_ART_RADIUS := 24
const MENU_ART_FADE_FROM := 0.38
const MENU_ART_FADE_ALPHA := 0.96
## Le point de l'illustration gardé quand elle est rognée (0 haut, 1 bas).
const MENU_ART_FOCUS_Y := 0.2
const MENU_ART_TITLE_ICON := 52
const MENU_ART_ROUND := 72
const MENU_ART_ROUND_ICON := 34
const MENU_ART_RIM_WIDTH := 2
## Carte du Dresseur : portrait peint du héros, ancré en bas à droite, au plus cette hauteur.
const MENU_HERO_HEIGHT := 640
const MENU_HERO_OFFSET_X := -8
## Pokémon de tête et liste de l'Équipe : artwork dans un rond.
const MENU_ROUND_THUMB_BG := Color(0.55, 0.75, 0.95, 0.22)
const MENU_ROUND_THUMB_BORDER := Color(1, 1, 1, 0.3)
## Part du rond occupée par l'artwork (l'atlas a déjà une marge de 4 px).
const MENU_ROUND_THUMB_ART := 0.96
## Équipe : grand artwork au centre (au plus MENU_TEAM_ART, réduit à la place disponible).
const TEAM_ART_MAX := 540
const TEAM_ART_HALO_ALPHA := 0.55
const TEAM_ART_BREATH_PX := 6.0
## Écran Stockage : même vedette, plus petite.
const STORAGE_ART := 192
## Sac : panneau de droite (objet en grand, « Utiliser sur… » et l'équipe dans le panneau).
const BAG_HERO_ICON := 180
const BAG_HERO_MIN_HEIGHT := 200
const BAG_HERO_GAP := 16
const BAG_TAB_CAPTION_FONT := 22
const BAG_TAB_PAINTED_ICON := 56
const BAG_TARGETS_TITLE_FONT := FONT_BODY
## Ligne de la cible dans le panneau du Sac (≥ TOUCH_MIN) et son rond.
const PICKER_COMPACT_ROW := TOUCH_MIN
const PICKER_COMPACT_THUMB := 100
const PICKER_COMPACT_GAP := 10
## Fond d'une carte de verre sélectionnée (le liseré ACCENT porte la sélection).
const MENU_GLASS_SELECTED_BG := Color(0.04, 0.07, 0.11, 0.78)

# Menu Dresseur rapproché des maquettes (MM.2) : Carte et Dresseur. Valeurs par défaut (règle 4)
# notées dans etat-projet.md et docs/tech/menu-maquettes.md.
## Carte : bandeau du bas (carte « Exploration » + frise des zones découvertes).
const MAP_STRIP_HEIGHT := 168
const MAP_STRIP_PAD := 16
const MAP_EXPLORE_WIDTH := 540
const MAP_EXPLORE_ROUND := 104
const MAP_EXPLORE_TITLE_FONT := 30
const MAP_EXPLORE_TEXT_FONT := FONT_CAPTION
## Vignette d'une zone dans la frise (≥ TOUCH_MIN de haut) : image, nom, liseré.
const MAP_THUMB_WIDTH := 232
const MAP_THUMB_GAP := 14
const MAP_THUMB_RADIUS := 16
const MAP_THUMB_FADE_FROM := 0.35
const MAP_THUMB_NAME_FONT := FONT_CAPTION
const MAP_THUMB_PIN := 30
const MAP_THUMB_RIM := 3
## Panneau de la zone : largeur entre ces bornes (le reste va à l'illustration).
const MAP_PANEL_MIN := 680
const MAP_PANEL_MAX := 860
## Grande image de la zone en tête du panneau (nom écrit dessus).
const MAP_HERO_HEIGHT := 230
const MAP_HERO_RADIUS := 20
const MAP_HERO_FADE_FROM := 0.3
const MAP_HERO_PAD := 20
const MAP_HERE_FONT := FONT_CAPTION
const MAP_HERE_ICON := 26
## Pokémon observés (artwork dans un rond) et objets trouvés (icône peinte).
const MAP_POKEMON_CELL := Vector2(144, 176)
const MAP_POKEMON_ROUND := 108
const MAP_ITEM_CELL := Vector2(144, 132)
const MAP_ITEM_ICON := 76
const MAP_SECTION_GAP := 12
## Fond du cadre de l'illustration (illustration étirée très floue et assombrie).
const MAP_ECHO_LOD := 5.0
const MAP_ECHO_DIM := 0.6
## Étiquettes des zones découvertes : icône du genre de zone ; lieu courant en ACCENT.
const MAP_LABEL_ICON := 28
const MAP_LABEL_SELECTED_BORDER := 3
## Portrait du joueur sur l'illustration : tête du buste peint dans un rond (région du buste).
const MAP_PORTRAIT_REGION := Rect2(80, 0, 300, 300)
const MAP_PORTRAIT_BG := Color(0.86, 0.91, 0.98)
const MAP_PORTRAIT_BORDER := 4
## Dresseur : identité (portrait peint) à gauche, badges et équipe au centre, statistiques et
## grands moments à droite.
const TRAINER_IDENTITY_WIDTH := 540
const TRAINER_SIDE_WIDTH := 640
const TRAINER_HERO_MAX := 560
const TRAINER_HERO_OFFSET_X := -4
const TRAINER_BADGE_SLOT_HEIGHT := 112
const TRAINER_BADGE_ICON := 56
const TRAINER_BADGE_UNKNOWN := Color(1, 1, 1, 0.22)
const TRAINER_BADGE_UNKNOWN_FONT := FONT_CAPTION
const TRAINER_TEAM_COLUMNS := 3
const TRAINER_TEAM_ART := 104
const TRAINER_TEAM_NAME_FONT := 24
const TRAINER_TEAM_LEVEL_FONT := 22
const TRAINER_MOMENT_THUMB := Vector2(150, 92)
const TRAINER_MOMENT_THUMB_RADIUS := 12
const TRAINER_MOMENT_ART := 64

## Carte de présentation du Champion (jalon 10, T5) : « PIERRE » / « Champion d'Arène
## d'Argenta », posée sur le monde avant le combat. Verre sombre du combat (CB.2), liseré
## ACCENT à gauche, aucun portrait. Réutilisée pour les 8 Champions.
const CHAMPION_CARD_BG := DIALOG_PANEL_BG
const CHAMPION_CARD_RADIUS := RADIUS
## Liseré ACCENT sur le bord gauche de la carte.
const CHAMPION_CARD_ACCENT_WIDTH := 10
const CHAMPION_CARD_PAD_H := 56
const CHAMPION_CARD_PAD_V := 32
const CHAMPION_CARD_MIN_WIDTH := 640
const CHAMPION_CARD_LINE_GAP := 8
const CHAMPION_CARD_NAME_FONT := FONT_TITLE
const CHAMPION_CARD_TITLE_FONT := FONT_BODY
## Centre de la carte : fraction de la hauteur d'écran ; bord gauche à SAFE_MARGIN.
const CHAMPION_CARD_CENTER_Y := 0.42
## Entrée glissée depuis la gauche, tenue (un toucher l'abrège), sortie.
const CHAMPION_CARD_SLIDE_IN := 0.4
const CHAMPION_CARD_HOLD := 3.0
const CHAMPION_CARD_SLIDE_OUT := 0.25

## Écran Dresseur, badge obtenu (jalon 10, T6) : bulle de détail ancrée sous l'emplacement
## (« Badge Roche » / « Argenta — Pierre »), verre sombre du combat, liseré ACCENT en haut.
const TRAINER_BUBBLE_BG := DIALOG_PANEL_BG
const TRAINER_BUBBLE_RADIUS := RADIUS_SMALL
const TRAINER_BUBBLE_PAD_H := 32
const TRAINER_BUBBLE_PAD_V := 20
const TRAINER_BUBBLE_MIN_WIDTH := 360
const TRAINER_BUBBLE_LINE_GAP := 4
## Écart entre l'emplacement et la bulle ; glissement (px) et durée (s) de l'apparition.
const TRAINER_BUBBLE_OFFSET := 12
const TRAINER_BUBBLE_SLIDE := 16
const TRAINER_BUBBLE_FADE := 0.16

## Remise d'un badge (jalon 10, T9 ; dossier 12 §13, arbitrage 11) : « BADGE ROCHE » par la
## légende posée sur le monde (WorldCaption, comme « POKÉDEX ACTIVÉ »), tenue courte, et une
## vibration légère à son apparition. Aucun toast.
const BADGE_CAPTION_HOLD := 2.0
const HAPTIC_BADGE_MS := 40
## Position de « BADGE ROCHE » : centre vertical de l'écran (ancre 0,5), Pierre reste visible
## en haut de l'Arène (caméra fixe). Les autres légendes restent à CAPTION_TOP.
const CAPTION_CENTER_ANCHOR := 0.5

## Écran titre (OUV.1, dossier 13 §5.2 ; composition de reference/ouverture-titre-v1.webp, règle
## 10 : le décor et le logo de l'image ne font pas foi). Logo en haut à gauche, colonne de cartes
## à droite (à gauche en mode gaucher, le logo passe alors à droite) ; la vraie carte derrière.
## Largeur du logo détouré (assets/ui/opening/logo_kanto_2026.png, 1280 × 602 à la source).
const TITLE_LOGO_WIDTH := 760
## Colonne d'actions : largeur, écart entre cartes, haut de la colonne (centrée en hauteur sinon).
const TITLE_COLUMN_WIDTH := 660
const TITLE_COLUMN_GAP := 20
## Cartes : verre sombre plus dense que le menu (posées sur un monde lumineux) ; la carte mise en
## avant (Continuer, ou Nouvelle partie sans sauvegarde) a un liseré ACCENT et un halo doré.
const TITLE_CARD_BG := Color(0.04, 0.07, 0.11, 0.82)
const TITLE_CARD_PRESSED_BG := Color(0.12, 0.14, 0.12, 0.9)
const TITLE_CARD_BORDER := Color(1.0, 1.0, 1.0, 0.22)
const TITLE_CARD_RADIUS := 26
const TITLE_CARD_BORDER_WIDTH := 3
const TITLE_CARD_FEATURED_BORDER_WIDTH := 4
const TITLE_CARD_GLOW := Color(0.96, 0.77, 0.26, 0.4)
const TITLE_CARD_GLOW_SIZE := 18
const TITLE_CARD_PAD_H := 32
const TITLE_CARD_PAD_V := 24
## Cartes secondaires (Nouvelle partie, Paramètres) : hauteur (≥ TOUCH_MIN), icône, chevron.
const TITLE_ENTRY_HEIGHT := 144
const TITLE_ENTRY_ICON := 72
const TITLE_ENTRY_FONT := FONT_BUTTON
const TITLE_CHEVRON := 56
## Carte Continuer : buste, titre « CONTINUER », prénom, lieu, lignes de résumé (icône + texte).
const TITLE_CONTINUE_BUST := Vector2(220, 300)
const TITLE_CONTINUE_TITLE_FONT := 56
const TITLE_CONTINUE_NAME_FONT := FONT_TITLE
const TITLE_CONTINUE_ZONE_FONT := FONT_BODY
const TITLE_CONTINUE_STAT_FONT := FONT_BODY
const TITLE_CONTINUE_STAT_ICON := 40
const TITLE_CONTINUE_LINE_GAP := 8
const TITLE_CONTINUE_DIVIDER := Color(0.36, 0.55, 0.85, 0.7)
## Message d'état de la sauvegarde (corrompue, plus récente) : sous la colonne, verre sombre.
const TITLE_MESSAGE_FONT := FONT_CAPTION
const TITLE_MESSAGE_BG := Color(0.04, 0.07, 0.11, 0.86)
## Fondus de l'ouverture (dossier 13 §4) : apparition du titre après le splash ; sortie au noir
## vers la partie (valeur des portes) ; entrée dans la partie.
const TITLE_FADE_IN := 0.4
const TITLE_FADE_OUT := 0.45
const TITLE_GAME_FADE_IN := ANIM_FADE_IN
## Paramètres depuis le titre : même voile et flou que dans le Menu Dresseur.
const TITLE_SETTINGS_DIM := MENU_GLASS_DIM

## Introduction du Prof. Chen (OUV.2, dossier 13 §4, §5.5, §9.0 ; composition de
## reference/ouverture-chen-v1.webp et ouverture-prenom-v1.webp, règle 10). Fond : la vraie carte
## du labo en mode décor, **très floutée** (même shader que le Menu Dresseur), sous une lumière
## dorée procédurale (dégradé radial venu de la fenêtre, en haut) et un voile chaud en bas.
const INTRO_BLUR_RADIUS := 14.0
const INTRO_BLUR_LOD := 4.0
const INTRO_DIM := 0.06
const INTRO_DIM_COLOR := Color(0.16, 0.09, 0.03)
## Lumière dorée : cœur (haut, vers la fenêtre) → bord transparent ; centre et rayon en part de
## l'écran.
const INTRO_GLOW := Color(1.0, 0.86, 0.55, 0.62)
const INTRO_GLOW_EDGE := Color(1.0, 0.72, 0.36, 0.08)
const INTRO_GLOW_CENTER := Vector2(0.55, 0.15)
const INTRO_GLOW_RADIUS := 0.75
## Voile chaud du bas (sol), sous les portraits : du transparent (milieu) à cette teinte (bas).
const INTRO_FLOOR_SHADE := Color(0.2, 0.11, 0.04, 0.4)
const INTRO_FLOOR_CLEAR := Color(0.2, 0.11, 0.04, 0.0)
## Emplacements des portraits (part de la largeur de l'écran : l'aspect « expand » va de 1920 à
## 2340 de large) et ligne des pieds (juste au-dessus de la boîte de dialogue).
const INTRO_SLOT_X: Dictionary[StringName, float] = {
	&"left": 0.27, &"center": 0.5, &"right": 0.72,
}
const INTRO_FEET_Y := 828.0
## Hauteurs affichées : adulte (Chen, à 1:1 de son portrait de 768 px), enfants (héros, rival :
## un peu plus petits que Chen), Pokémon (artwork officiel 475 px, marges comprises).
const INTRO_HEIGHT_ADULT := 768.0
const INTRO_HEIGHT_CHILD := 700.0
const INTRO_HEIGHT_POKEMON := 440.0
## Mouvements de scène (dossier 13 §4) : entrée en fondu et légère montée, sortie en fondu,
## glissement d'un emplacement à l'autre. « Réduire les animations » : durées × INTRO_REDUCED,
## sans montée ni glissement (le portrait change de place dans un fondu).
const INTRO_PORTRAIT_IN := 0.45
const INTRO_PORTRAIT_OUT := 0.3
const INTRO_PORTRAIT_MOVE := 0.4
const INTRO_PORTRAIT_RISE := 28.0
const INTRO_REDUCED := 0.5
## Sortie de Poké Ball (procédurale, §9.2) : éclair blanc doré qui grandit et s'éteint, quelques
## étincelles, puis le Pokémon apparaît ; petite respiration du Pokémon ensuite.
const INTRO_FLASH := 0.35
const INTRO_FLASH_SIZE := 420.0
const INTRO_FLASH_COLOR := Color(1.0, 0.97, 0.84, 0.95)
const INTRO_FLASH_EDGE := Color(1.0, 0.9, 0.6, 0.0)
const INTRO_SPARKLES := 8
const INTRO_SPARKLE_SIZE := 44.0
const INTRO_SPARKLE_DISTANCE := 240.0
const INTRO_BREATH := 0.015
const INTRO_BREATH_TIME := 1.6
## Fondu d'entrée dans l'introduction (depuis le noir du titre).
const INTRO_FADE_IN := TITLE_FADE_IN
## Fin de l'introduction (OUV.3, dossier 13 §4 plans 8 et 9) : après « Allez… en route ! », le
## portrait du joueur **rétrécit vers son centre et se dissout dans la lumière** (il blanchit et
## s'efface, un halo chaud grandit à sa place) ; le **fondu au blanc chaud** part au milieu du
## rétrécissement ([constant INTRO_SEND_OFF_LEAD], part de [constant INTRO_SEND_OFF]) ; la chambre
## apparaît ensuite en fondu depuis le blanc. « Réduire les animations » : pas de rétrécissement,
## fondus × INTRO_REDUCED (défauts, règle 4).
const INTRO_SEND_OFF := 0.7
const INTRO_SEND_OFF_LEAD := 0.5
const INTRO_SEND_OFF_SCALE := 0.08
## Teinte du portrait qui se dissout (au-delà de 1 : il blanchit avant de s'effacer).
const INTRO_SEND_OFF_GLOW := Color(2.4, 2.2, 1.8, 0.0)
const INTRO_SEND_OFF_HALO := 640.0
const INTRO_WHITE := Color(1.0, 0.96, 0.87)
const INTRO_WHITE_OUT := 0.8
const INTRO_WHITE_IN := 0.8

## Écran de prénom (OUV.2, dossier 13 §5.5) : panneau en haut à droite, **entier dans la moitié
## haute** (le clavier du téléphone couvre le bas en paysage) : champ clair, compteur, aide,
## pastilles et VALIDER sur une même ligne.
const NAME_PANEL_WIDTH := 1040
const NAME_PANEL_PAD := 32
const NAME_PANEL_GAP := 16
const NAME_PANEL_BG := TITLE_CARD_BG
const NAME_PANEL_RADIUS := TITLE_CARD_RADIUS
const NAME_PANEL_BORDER_WIDTH := TITLE_CARD_FEATURED_BORDER_WIDTH
const NAME_PANEL_GLOW := TITLE_CARD_GLOW
const NAME_PANEL_GLOW_SIZE := TITLE_CARD_GLOW_SIZE
## Champ : clair, texte sombre, liseré ACCENT au focus.
const NAME_FIELD_HEIGHT := 112
const NAME_FIELD_FONT := 52
const NAME_FIELD_PAD_H := 32
const NAME_FIELD_BG := DIALOG_BG
const NAME_FIELD_TEXT := DIALOG_TEXT
const NAME_FIELD_RADIUS := 28
const NAME_FIELD_FOCUS_WIDTH := 4
## Compteur « 4 / 10 », dans le champ à droite (discret, gris sur le champ clair).
const NAME_COUNTER_FONT := FONT_CAPTION
const NAME_COUNTER_COLOR := Color("#7A8494")
## Place du compteur au bout du champ (le texte saisi ne passe jamais dessous).
const NAME_COUNTER_WIDTH := 120
## Aide (« Lettres, espaces, - et ’ seulement ») : place réservée sous le champ (rien ne bouge
## quand elle apparaît).
const NAME_HELP_FONT := FONT_CAPTION
const NAME_HELP_HEIGHT := 32
## L'aide s'efface d'elle-même après ce délai (ou à la frappe suivante sans caractère refusé).
const NAME_HELP_HOLD := 3.0
## Titre du panneau : la question de Chen (le clavier scindé cache la boîte de dialogue).
const NAME_TITLE_FONT := FONT_TITLE
## Pastilles des noms proposés et VALIDER : zones tactiles d'au moins TOUCH_MIN.
const NAME_CHIP_WIDTH := 200
const NAME_CHIP_FONT := FONT_BUTTON
const NAME_CHIP_RADIUS := 64
const NAME_VALIDATE_WIDTH := 312
## VALIDER inactif : ACCENT éteint (texte et icône portent aussi l'état : jamais la couleur seule).
const NAME_VALIDATE_DISABLED_ALPHA := 0.35
## Choix de l'apparence (chantier JR, dossier 13 §5.6) : deux cartes carrées illustrées des
## portraits en pied, dans le panneau de l'écran de prénom (même largeur, même place) [D].
const LOOK_CARD_SIZE := Vector2(480, 480)
## Carte non choisie : légèrement éteinte (le liseré de la carte choisie porte aussi l'état).
const LOOK_CARD_DIM := 0.55

# --- Combat du jalon 12 (T14) : Entrave ------------------------------------------------------

## Carte d'une capacité bloquée (Entrave) : fond gris neutre (sans la teinte du type), liseré
## discret ; atténuée en plus par MOVE_CARD_DISABLED (inerte, comme une carte sans PP).
const MOVE_CARD_BLOCKED_BG := Color(0.17, 0.19, 0.22, 0.90)
const MOVE_CARD_BLOCKED_BORDER := Color(1, 1, 1, 0.16)
## « BLOQUÉE » (style des PP, en gras) : blanc, lisible malgré l'atténuation.
const MOVE_CARD_BLOCKED_TEXT := TEXT

# --- Étape de scène « flash » (jalon 14, jalon-14.md §2.7 ; défauts §6) --------------------
## Éclair plein écran de la machine de Léo ([ScreenFlash]) : blanc bleuté.
const FLASH_COLOR := Color("#e6f0ff")
## Éclair normal : opacité au plus fort, montée, tenue, descente (0,4 s en tout).
const FLASH_ALPHA := 0.9
const FLASH_RISE := 0.08
const FLASH_HOLD := 0.08
const FLASH_FALL := 0.24
## Écart entre deux éclairs.
const FLASH_GAP := 0.2
## « Réduire les animations » ou « Réduire les flashs » : fondu doux, opacité au plus fort et
## durée totale (moitié montée, moitié descente).
const FLASH_REDUCED_ALPHA := 0.35
const FLASH_REDUCED_DURATION := 0.6
## Vibration légère au début de chaque éclair (si les vibrations sont permises).
const HAPTIC_FLASH_MS := 25

## Voix d'esprit (J19 T12, dossier 22 §11) : réplique d'un Exorciste possédé, italique, teinte
## adoucie et froide (le texte reste lisible sur DIALOG_PANEL_BG).
const DIALOG_SPIRIT := Color("#B7B4DA")
## Valeurs de la clé de page « voice ».
const VOICE_SPIRIT := &"spirit"

# --- Panneau d'étages de l'ascenseur (J20 T14, jalon-20.md §2.3.4) -------------------------------
## Voile derrière le panneau : le monde reste deviné, comme les cartes de choix.
const ELEVATOR_SCRIM := CHOICE_SCRIM
## Carte d'étage : large pour le pouce, 128 px de haut (cible tactile).
const ELEVATOR_CARD_SIZE := Vector2(400, TOUCH_MIN)
const ELEVATOR_CARD_GAP := 16
## Au-delà de ce nombre d'étages, les cartes passent sur deux colonnes (6 étages du magasin).
const ELEVATOR_SINGLE_COLUMN_MAX := 4
const ELEVATOR_COLUMNS := 2
const ELEVATOR_PAD := 32
const ELEVATOR_TITLE_FONT := FONT_TITLE
const ELEVATOR_CARD_FONT := FONT_BUTTON
## Étage courant : fond atténué (carte inerte), libellé en TEXT_DISABLED.
const ELEVATOR_HERE_BG := Color(1, 1, 1, 0.06)
## Pastille d'accent à gauche du libellé de l'étage courant (repère « vous êtes ici »).
const ELEVATOR_HERE_DOT := 16
const ELEVATOR_SLIDE := PANEL_SLIDE
const ELEVATOR_FADE := ANIM_PANEL

# --- Panthéon et générique (J30 T15, T16, jalon-30.md §2.4) : défauts (règle 4) --------------------
## Calque des deux écrans : au-dessus des menus, dialogues et combats, sous les transitions.
const LAYER_HALL_OF_FAME := 90
## Panthéon : ouverture et fermeture (fondu du fond nuit), entrée d'un Pokémon (fondu et léger
## grossissement depuis HALL_ENTER_SCALE), tenue (un toucher l'abrège), sortie.
const HALL_OPEN := 0.6
const HALL_CLOSE := 0.5
const HALL_ENTER := 0.6
const HALL_ENTER_SCALE := 0.9
const HALL_HOLD := 1.6
const HALL_LEAVE := 0.3
## Équipe entière : tenue minimale avant d'accepter le toucher qui ferme l'écran.
const HALL_TEAM_MIN := 1.2
## Un toucher n'est pris qu'après ce délai depuis l'ouverture (le doigt du dernier dialogue).
const HALL_TAP_DELAY := 0.5
## Artwork d'un Pokémon seul (hauteur), centre du halo (décalage vertical depuis le centre).
const HALL_ART := 560
const HALL_ART_CENTER_Y := -60.0
const HALL_LINE_GAP := 16
## Halo doré derrière le Pokémon seul.
const HALL_HALO := Color(0.96, 0.77, 0.26, 0.35)
const HALL_HALO_SIZE := 900.0
## Équipe entière : artwork d'une carte et écart entre les cartes.
const HALL_TEAM_ART := 260
const HALL_TEAM_GAP := 24
## Générique : fondu d'entrée et de sortie, vitesse de défilement (px de référence / s),
## multiplicateur pendant un toucher tenu, tenue de la dernière ligne au centre.
const CREDITS_FADE := 0.8
const CREDITS_SPEED := 110.0
const CREDITS_RUSH := 4.0
const CREDITS_END_HOLD := 3.0
const CREDITS_LOGO_HEIGHT := 300
const CREDITS_LINE_GAP := 18
const CREDITS_BLOCK_GAP := 140
const CREDITS_SKIP_WIDTH := 260
## Écran Dresseur : largeur minimale du lien « Panthéon » (J30, Q30-4).
const TRAINER_HALL_LINK_WIDTH := 240
