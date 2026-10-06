class_name WorldLighting
extends CanvasLayer
## Applique un [LightProfile] au monde (lumière C2, docs/tech/jalon-07.md §6.6, §6.7) :
## - les « global uniform » des shaders du monde (liseré, vent, couleurs des ombres, gains de
##   l'étalonnage) : changer d'ambiance ne touche aucun nœud de carte ;
## - l'étalonnage d'écran (calque [constant UiTokens.LAYER_WORLD_GRADE], au-dessus du monde et
##   de BattleStage, sous le HUD) : caché quand le profil n'en a pas (aucun coût) ;
## - les ombres portées des objets peints (groupe [constant GROUP_CAST_SHADOWS]) : écrasement
##   et inclinaison posés **une fois** ([method shadow_transform]), cachées sans ombre portée ;
##   les ombres de contact (groupe [constant GROUP_CONTACT_SHADOWS]), cachées sans contact.
## **Profil vide (ou null) = aucun effet** : Bourg Palette, la Route 1 et les intérieurs
## existants restent tels quels (`GameMap.light_profile` vide).
## « Économie » ([method set_reduced_effects], 6F) coupe le vent et le liseré, garde
## l'étalonnage et les ombres (jalon-07.md §7).
##
## Usage : `apply(profile, map)` à chaque changement de carte (écran noir du fondu), carte
## déjà dans l'arbre. Le jour/nuit (phase 10) appellera [method apply] quand l'heure change.

## Groupes des sprites d'ombre des objets peints (scènes de tools/build_painted_props.gd).
const GROUP_CAST_SHADOWS: StringName = &"cast_shadows"
const GROUP_CONTACT_SHADOWS: StringName = &"contact_shadows"
## Ombre portée telle que pré-calculée par tools/art/preparer.py (manifeste.json,
## « ombre_portee » : écrasement 0,26, inclinaison 45° vers le bas à droite, réduction 2).
## Un profil identique laisse l'image telle quelle ; un autre la cisaille et l'étire.
const BAKED_SHADOW_LENGTH: float = 0.26
const BAKED_SHADOW_ANGLE_DEG: float = 45.0
## Les ombres sont préparées à demi-résolution : affichées à l'échelle 2.
const SHADOW_TEXTURE_SCALE: float = 2.0
## Ordre de dessin d'une carte peinte (z_index) : sol peint, ombres, décalcomanies et relief
## (falaises, escaliers : toujours sous les personnages), puis `Entities` (0, tri par les pieds).
const Z_GROUND: int = -3
const Z_SHADOWS: int = -2
const Z_GROUND_DECALS: int = -1
## Noms des « global uniform » (déclarés dans project.godot, [shader_globals]).
const SUN_DIR: StringName = &"world_sun_dir"
const RIM_COLOR: StringName = &"world_rim_color"
const RIM_STRENGTH: StringName = &"world_rim_strength"
const RIM_WIDTH: StringName = &"world_rim_width"
const WIND: StringName = &"world_wind"
const CAST_SHADOW_COLOR: StringName = &"world_cast_shadow_color"
const CONTACT_COLOR: StringName = &"world_contact_color"
const GRADE_SHADOWS: StringName = &"world_grade_shadows"
const GRADE_MIDTONES: StringName = &"world_grade_midtones"
const GRADE_HIGHLIGHTS: StringName = &"world_grade_highlights"
const GRADE_STRENGTH: StringName = &"world_grade_strength"
const _GRADE_MATERIAL: Material = preload(
	"res://game/world/lighting/materials/screen_grade.tres")

var _profile: LightProfile = LightProfile.new()
var _reduced: bool = false
var _globals: Dictionary[StringName, Variant] = {}
var _grade: ColorRect


func _init() -> void:
	name = "WorldLighting"
	layer = UiTokens.LAYER_WORLD_GRADE
	_grade = ColorRect.new()
	_grade.name = "Grade"
	_grade.material = _GRADE_MATERIAL
	_grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grade.visible = false
	add_child(_grade)


## Pose [param profile] (null = profil vide : aucun effet) ; règle les ombres des objets
## peints sous [param map] (tout l'arbre si null).
func apply(profile: LightProfile, map: Node = null) -> void:
	_profile = profile if profile != null else LightProfile.new()
	_push_globals()
	_grade.visible = _profile.has_grade()
	apply_shadows(map)


## Coupe (vrai) ou rend le vent et le liseré (« Économie », 6F).
func set_reduced_effects(enabled: bool) -> void:
	_reduced = enabled
	_push_globals()


## Oriente et montre (ou cache) les ombres sous [param map] selon le profil courant (à
## rappeler si des objets peints sont ajoutés après [method apply]).
func apply_shadows(map: Node = null) -> void:
	var basis := shadow_transform(_profile)
	for node: Node in _shadow_nodes(GROUP_CAST_SHADOWS, map):
		var sprite := node as Node2D
		sprite.transform = Transform2D(basis.x, basis.y, sprite.position)
		sprite.visible = _profile.has_cast_shadow()
	for node: Node in _shadow_nodes(GROUP_CONTACT_SHADOWS, map):
		(node as CanvasItem).visible = _profile.has_contact_shadow()


func get_profile() -> LightProfile:
	return _profile


## Vrai si le calque d'étalonnage est affiché.
func is_grade_visible() -> bool:
	return _grade.visible


## Valeurs des « global uniform » posées au dernier [method apply] (tests, journal).
func get_applied_globals() -> Dictionary[StringName, Variant]:
	return _globals.duplicate()


## Valeurs des « global uniform » pour [param profile] (classe pure, testée seule). Un bloc
## absent du profil donne la valeur neutre (gain 1, intensité 0, alpha 0, vent 0).
static func global_values(profile: LightProfile, reduced: bool = false
		) -> Dictionary[StringName, Variant]:
	var p := profile if profile != null else LightProfile.new()
	var rim := p.has_rim() and not reduced
	var values: Dictionary[StringName, Variant] = {
		SUN_DIR: p.sun_direction,
		RIM_COLOR: p.rim_color,
		RIM_STRENGTH: p.rim_strength if rim else 0.0,
		RIM_WIDTH: p.rim_width if rim else 0.0,
		WIND: p.wind_strength if p.has_wind() and not reduced else 0.0,
		CAST_SHADOW_COLOR: p.cast_shadow_color if p.has_cast_shadow() else Color(0, 0, 0, 0),
		CONTACT_COLOR: p.contact_color if p.has_contact_shadow() else Color(0, 0, 0, 0),
		GRADE_SHADOWS: p.grade_shadows if p.has_grade() else Vector3.ONE,
		GRADE_MIDTONES: p.grade_midtones if p.has_grade() else Vector3.ONE,
		GRADE_HIGHLIGHTS: p.grade_highlights if p.has_grade() else Vector3.ONE,
		GRADE_STRENGTH: p.grade_strength if p.has_grade() else 0.0,
	}
	return values


## Base (axes x et y, sans origine) d'un sprite d'ombre portée pour [param profile] :
## l'ombre pré-calculée ([constant BAKED_SHADOW_LENGTH], [constant BAKED_SHADOW_ANGLE_DEG])
## est cisaillée et étirée autour du pied pour prendre la longueur et l'inclinaison du profil,
## à l'échelle [constant SHADOW_TEXTURE_SCALE]. Profil sans ombre portée : l'ombre préparée.
## Inclinaison du profil : `skew_deg` négatif = vers la droite en descendant (−45° au
## prototype, soleil en haut à gauche).
static func shadow_transform(profile: LightProfile) -> Transform2D:
	var baked_angle := deg_to_rad(BAKED_SHADOW_ANGLE_DEG)
	var kx0 := sin(baked_angle) * BAKED_SHADOW_LENGTH
	var ky0 := cos(baked_angle) * BAKED_SHADOW_LENGTH
	var kx := kx0
	var ky := ky0
	if profile != null and profile.has_cast_shadow():
		var angle := deg_to_rad(-profile.cast_shadow_skew_deg)
		kx = sin(angle) * profile.cast_shadow_length
		ky = cos(angle) * profile.cast_shadow_length
	# Un point de l'image préparée à la profondeur y (sous le pied) vient d'un point de la
	# silhouette à la hauteur y / ky0 : on le replace à (x + (kx − kx0)·y/ky0, ky·y/ky0).
	var s := SHADOW_TEXTURE_SCALE
	return Transform2D(Vector2(s, 0.0), Vector2(s * (kx - kx0) / ky0, s * ky / ky0), Vector2.ZERO)


func _push_globals() -> void:
	_globals = global_values(_profile, _reduced)
	for key: StringName in _globals:
		RenderingServer.global_shader_parameter_set(key, _globals[key])


func _shadow_nodes(group: StringName, map: Node) -> Array[Node]:
	var found: Array[Node] = []
	if map != null and not map.is_inside_tree():
		_collect(map, group, found)
		return found
	if not is_inside_tree():
		return found
	for node: Node in get_tree().get_nodes_in_group(group):
		if map == null or map.is_ancestor_of(node):
			found.append(node)
	return found


static func _collect(node: Node, group: StringName, found: Array[Node]) -> void:
	if node.is_in_group(group):
		found.append(node)
	for child: Node in node.get_children():
		_collect(child, group, found)
