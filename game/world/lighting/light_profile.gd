class_name LightProfile
extends RefCounted
## Une ambiance lumineuse du monde (méthode C : assets neutres, lumière portée par Godot ;
## fiches série 01, « Comparaison de lumière », calibration C2). Donnée pure, lue dans
## `data/world/lighting.json` par [LightingLibrary] ; `WorldLighting` (T3) la pose sur les
## shaders du monde à chaque changement de carte (docs/tech/jalon-07.md §3.2, §6.7).
## Le jour/nuit du Chapitre Johto (JOH0, `jalon-joh0.md` §2.4) interpole entre deux profils
## ([method lerp]) pendant le fondu de 10 s d'un changement de moment.

## Bornes de validation (lues par [LightingLibrary]).
const GAIN_MAX: float = 2.0
const RIM_WIDTH_MAX: float = 16.0
const SKEW_MAX_DEG: float = 89.0
const WIND_MAX: float = 20.0
## Largeur maximale de la pénombre d'une pièce (cases) et rayon maximal de sa flaque.
const ROOM_EDGE_MAX: float = 8.0
const ROOM_POOL_RADIUS_MAX: float = 2.0

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
## JOH1 (QA A17 du 2026-11-04) : en mode « économie » (lumière d'ambiance coupée, défaut de l'A17),
## l'étalonnage plein écran disparaît ; un profil qui porte ce drapeau garde alors son gain des
## tons moyens **à plat** (presque gratuit), pour que la nuit de Johto reste une nuit. Tons
## moyens ≤ 1 exigés (le calque ne fait qu'assombrir).
var grade_economy_flat: bool = false
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
## Lumière de pièce des intérieurs ([RoomLight], DAF.6) : pénombre au pourtour (couleur **avec**
## son alpha ; largeur en cases) et flaque chaude des fenêtres (couleur avec son alpha ; centre
## en fraction de la pièce ; rayon en fraction de sa hauteur). Alphas 0 = aucune.
var room_edge_color: Color = Color(0.0, 0.0, 0.0, 0.0)
var room_edge_width: float = 0.0
var room_pool_color: Color = Color(0.0, 0.0, 0.0, 0.0)
var room_pool_center: Vector2 = Vector2(0.5, 0.5)
var room_pool_radius: float = 0.0


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


func has_room() -> bool:
	return (room_edge_color.a > 0.0 and room_edge_width > 0.0) \
		or (room_pool_color.a > 0.0 and room_pool_radius > 0.0)


## Profil intermédiaire entre [param from] (t = 0) et [param to] (t = 1), JOH0 : gains, couleurs
## (alpha compris), intensités, largeur, longueur, inclinaison, direction du soleil et vent
## interpolés linéairement ; l'identifiant, « flat » et la lumière de pièce sont ceux de
## [param to] (ils ne s'interpolent pas). Un bloc absent d'un côté (alpha 0, intensité 0) s'ouvre
## ou se ferme en fondu. Null d'un côté = profil vide.
static func lerp(from: LightProfile, to: LightProfile, t: float) -> LightProfile:
	var a := from if from != null else LightProfile.new()
	var b := to if to != null else LightProfile.new()
	var w := clampf(t, 0.0, 1.0)
	var result := LightProfile.new()
	result.id = b.id
	result.grade_shadows = a.grade_shadows.lerp(b.grade_shadows, w)
	result.grade_midtones = a.grade_midtones.lerp(b.grade_midtones, w)
	result.grade_highlights = a.grade_highlights.lerp(b.grade_highlights, w)
	result.grade_strength = lerpf(a.grade_strength, b.grade_strength, w)
	result.grade_flat = b.grade_flat
	result.grade_economy_flat = b.grade_economy_flat
	result.rim_color = a.rim_color.lerp(b.rim_color, w)
	result.rim_strength = lerpf(a.rim_strength, b.rim_strength, w)
	result.rim_width = lerpf(a.rim_width if a.has_rim() else b.rim_width,
		b.rim_width if b.has_rim() else a.rim_width, w)
	result.sun_direction = a.sun_direction.lerp(b.sun_direction, w)
	if result.sun_direction.is_zero_approx():
		result.sun_direction = b.sun_direction
	result.cast_shadow_color = a.cast_shadow_color.lerp(b.cast_shadow_color, w)
	result.cast_shadow_length = lerpf(a.cast_shadow_length if a.has_cast_shadow()
		else b.cast_shadow_length, b.cast_shadow_length if b.has_cast_shadow()
		else a.cast_shadow_length, w)
	result.cast_shadow_skew_deg = lerpf(a.cast_shadow_skew_deg if a.has_cast_shadow()
		else b.cast_shadow_skew_deg, b.cast_shadow_skew_deg if b.has_cast_shadow()
		else a.cast_shadow_skew_deg, w)
	result.contact_color = a.contact_color.lerp(b.contact_color, w)
	result.wind_strength = lerpf(a.wind_strength, b.wind_strength, w)
	result.room_edge_color = b.room_edge_color
	result.room_edge_width = b.room_edge_width
	result.room_pool_color = b.room_pool_color
	result.room_pool_center = b.room_pool_center
	result.room_pool_radius = b.room_pool_radius
	return result
