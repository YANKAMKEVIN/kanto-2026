class_name UiPrefs
extends RefCounted
## Préférences d'affichage lues à l'exécution (Q-19, jalon-06.md §3.8) : taille du texte et
## contraste renforcé. Les constantes de [UiTokens] restent la référence ; ces fonctions les
## ajustent selon les réglages.
##
## Lues par les écrans du menu, la boîte de dialogue, le toast et le titre de zone (T28) ; le
## HUD de combat n'est pas couvert au J6 (Q-19). Posées par `Boot._apply_settings` (T29) via
## [method apply]. Statique : une seule interface à la fois.
##
## [member revision] augmente à chaque changement : un composant déjà construit compare la
## révision qu'il a appliquée pour savoir s'il doit se remettre en forme (pas de signal
## statique en GDScript).

## Facteur des tailles de police (1,0 ou [constant UiTokens.TEXT_SCALE_LARGE]).
static var text_scale: float = 1.0
static var high_contrast: bool = false
## Augmente à chaque changement effectif ([method apply]).
static var revision: int = 0


## Applique [param settings] ; vrai si quelque chose a changé ([member revision] augmente).
static func apply(settings: GameSettings) -> bool:
	var scale := UiTokens.TEXT_SCALE_LARGE \
		if settings.text_size == GameSettings.TextSize.LARGE else 1.0
	if is_equal_approx(scale, text_scale) and settings.high_contrast == high_contrast:
		return false
	text_scale = scale
	high_contrast = settings.high_contrast
	revision += 1
	return true


## Taille de police à utiliser pour [param size] (une constante FONT_* de [UiTokens]).
static func font(size: int) -> int:
	return roundi(size * text_scale)


## Fond de panneau : [param base] (PANEL_BG par défaut), rendu plus opaque en contraste
## renforcé (jamais moins opaque qu'il ne l'est).
static func panel_bg(base: Color = UiTokens.PANEL_BG) -> Color:
	if not high_contrast:
		return base
	var color := base
	color.a = maxf(base.a, UiTokens.CONTRAST_PANEL_ALPHA)
	return color


## Couleur du texte secondaire.
static func text_muted() -> Color:
	return UiTokens.TEXT_MUTED_CONTRAST if high_contrast else UiTokens.TEXT_MUTED


## Valeurs de départ (tests).
static func reset() -> void:
	text_scale = 1.0
	high_contrast = false
	revision += 1
