class_name LightProfile
extends RefCounted
## Une ambiance lumineuse du monde (méthode C : assets neutres, lumière portée par Godot ;
## fiches série 01, « Comparaison de lumière », calibration C2). Donnée pure, lue dans
## `data/world/lighting.json` par [LightingLibrary] ; `WorldLighting` (T3) la pose sur les
## shaders du monde à chaque changement de carte (docs/tech/jalon-07.md §3.2, §6.7).
## Le jour/nuit (phase 10) interpolera entre plusieurs profils ; rien ne l'anticipe ici
## au-delà de la forme des données.

## Bornes de validation (lues par [LightingLibrary]).
const GAIN_MAX: float = 2.0
const RIM_WIDTH_MAX: float = 16.0
const SKEW_MAX_DEG: float = 89.0
const WIND_MAX: float = 20.0

var id: StringName = &""
## Étalonnage d'écran par zones de luminance (gains RVB : ombres, tons moyens, hautes
## lumières) ; [member grade_strength] de 0 (calque caché) à 1.
var grade_shadows: Vector3 = Vector3.ONE
var grade_midtones: Vector3 = Vector3.ONE
var grade_highlights: Vector3 = Vector3.ONE
var grade_strength: float = 0.0
## Étalonnage « à plat » (J21, A17) : un seul gain RVB (celui des tons moyens), posé par un
## calque en mélange multiplicatif, **sans lecture de l'écran** (la copie de l'écran coûte
## ≈ 6 i/s sur un Mali-G57). Réservé aux ambiances dont les trois gains sont proches et ≤ 1
## (Tour Pokémon) : l'écart avec l'étalonnage par zones y reste sous 2 % de la luminance.
var grade_flat: bool = false
## Liseré de soleil sur les bords des objets tournés vers la lumière ; [member rim_width] en
## pixels de texture ; [member rim_strength] 0 = aucun liseré.
var rim_color: Color = Color.WHITE
var rim_strength: float = 0.0
var rim_width: float = 0.0
## D'où vient la lumière (haut-gauche : (-0.7, -0.7)) ; jamais nulle.
var sun_direction: Vector2 = Vector2(-0.7, -0.7)
## Ombre portée (silhouette pré-floutée, écrasée, inclinée) : couleur **avec** son alpha
## (alpha 0 = aucune ombre portée), écrasement vertical (0,26 au prototype), inclinaison
## (−45° au prototype).
var cast_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.0)
var cast_shadow_length: float = 0.0
var cast_shadow_skew_deg: float = 0.0
## Ombre de contact (couleur avec son alpha ; alpha 0 = aucune).
var contact_color: Color = Color(0.0, 0.0, 0.0, 0.0)
## Amplitude du vent dans les arbres (pixels) ; 0 = arbres immobiles.
var wind_strength: float = 0.0


## Vrai si l'étalonnage d'écran est visible (sinon le calque est caché : aucun coût).
func has_grade() -> bool:
	return grade_strength > 0.0


## Gain unique de l'étalonnage à plat : tons moyens, dosés par [member grade_strength].
func flat_grade_color() -> Color:
	var gain := Vector3.ONE.lerp(grade_midtones, grade_strength)
	return Color(gain.x, gain.y, gain.z, 1.0)


func has_rim() -> bool:
	return rim_strength > 0.0 and rim_width > 0.0


func has_cast_shadow() -> bool:
	return cast_shadow_color.a > 0.0 and cast_shadow_length > 0.0


func has_contact_shadow() -> bool:
	return contact_color.a > 0.0


func has_wind() -> bool:
	return wind_strength > 0.0
