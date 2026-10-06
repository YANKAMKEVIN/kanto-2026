class_name ExpSummaryRowView
extends RefCounted
## Une ligne du bilan de fin de combat (ExpSummaryCard, demande n° 1) : des chaînes, des
## nombres et une texture. La carte ne formule rien et ne connaît ni le moteur ni les données.
##
## La barre se remplit par tranches ([member segments], une par niveau) ; entre deux tranches,
## le Pokémon passe au niveau suivant : « Nv. » prend [member level_texts] de ce passage et la
## ligne des gains prend [member stat_texts] (cumulés depuis le début du bilan). Les nombres
## « 112 / 173 » suivent la barre ([member points]).

## Séparateur des gains dans [member stat_texts] (celui du formulateur de textes, vérifié
## par un test) : la ligne les range en grille.
const STAT_SEPARATOR := " · "

## Surnom, sinon nom de l'espèce.
var display_name: String = ""
## Vignette du Pokémon (sprite de face) ; null = pas de vignette.
var portrait: Texture2D = null
## « +11 XP ».
var gain_text: String = ""
## « Nv. 8 » : le niveau avant le combat.
var start_level_text: String = ""
## Un texte par niveau gagné, dans l'ordre (« Nv. 9 », « Nv. 10 »).
var level_texts: PackedStringArray = PackedStringArray()
## Un texte par niveau gagné : gains de statistiques cumulés jusqu'à ce niveau
## (« PV +2 · Attaque +1 »).
var stat_texts: PackedStringArray = PackedStringArray()
## Tranches de barre (x = départ, y = arrivée, fractions 0..1) : une de plus que de niveaux.
var segments: Array[Vector2] = []
## Les mêmes en points d'XP du niveau : (départ, arrivée, XP du niveau) ; z = 0 : pas de
## nombres (niveau 100).
var points: Array[Vector3i] = []


## Niveaux gagnés pendant le combat.
func levels_gained() -> int:
	return level_texts.size()


## Une vue affichable : un nom, un gain, un niveau de départ, une tranche par niveau (plus la
## dernière), autant de gains de statistiques que de niveaux, et des nombres pour chaque tranche.
func is_valid() -> bool:
	return not display_name.is_empty() and not gain_text.is_empty() \
		and not start_level_text.is_empty() and segments.size() == level_texts.size() + 1 \
		and stat_texts.size() == level_texts.size() and points.size() == segments.size()
