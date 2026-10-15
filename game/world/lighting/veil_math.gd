class_name VeilMath
extends RefCounted
## Calculs du voile d'obscurité, sans nœud (docs/tech/jalon-18.md §2.4) : **miroir exact** du
## shader `shaders/darkness_veil.gdshader` (le rendu ne se relit pas en headless : les tests
## passent par ici, une capture Mac contrôle l'accord), sources des halos fixes, centre du trou.

## Au plus [constant MAX_SOURCES] halos fixes percent le voile (uniforme du shader, budget du
## J12 : ≤ 16 halos par carte).
const MAX_SOURCES: int = 16
## Part du rayon d'un halo fixe où son trou est encore net (comme le shader).
const SOURCE_CLEAR_SHARE: float = 0.4


## Opacité du voile au point [param point] (monde, px) : [member VeilParams.outside] hors des
## halos, 0 au cœur du trou du joueur ([param center]) et des [param sources] (x, y, rayon px,
## force 0..1). [param breath_factor] : multiplicateur des rayons du joueur (battement ; 1 =
## repos).
static func alpha_at(point: Vector2, center: Vector2, params: VeilParams,
		sources: PackedVector4Array, breath_factor: float = 1.0) -> float:
	var lit := 1.0 - smoothstep(params.clear_px * breath_factor, params.fade_px * breath_factor,
		point.distance_to(center))
	for i: int in mini(sources.size(), MAX_SOURCES):
		var s := sources[i]
		var d := point.distance_to(Vector2(s.x, s.y))
		lit = maxf(lit, s.w * (1.0 - smoothstep(s.z * SOURCE_CLEAR_SHARE, s.z, d)))
	return params.outside * (1.0 - lit)


## Éclaircissement du sol par la lueur du halo ([HaloFloorLight]) : miroir du shader
## `halo_floor_light.gdshader` ; [param strength] au cœur du halo, 0 au-delà de la fin du fondu.
static func lift_at(point: Vector2, center: Vector2, params: VeilParams, strength: float) -> float:
	return strength * (1.0 - smoothstep(params.clear_px, params.fade_px, point.distance_to(center)))


## Centre du trou : les pieds du joueur ([param player_position], origine du sprite) relevés de
## [param offset_px] (négatif = vers le haut, centre du corps).
static func body_center(player_position: Vector2, offset_px: float) -> Vector2:
	return player_position + Vector2(0.0, offset_px)


## Sources des halos fixes : position monde, rayon du trou (rayon du type en cases ×
## [param hole_scale], en px), force 1. Les colonnes (`shape` « column ») percent à leur pied.
## Un type inconnu est ignoré ; au-delà de [constant MAX_SOURCES], push_error et les premières
## sont gardées.
static func sources_of(glows: Array[LightGlow], library: LightGlowLibrary,
		hole_scale: float) -> PackedVector4Array:
	var sources := PackedVector4Array()
	for glow: LightGlow in glows:
		var type := library.get_type(glow.glow_type) if library != null else null
		if type == null:
			continue
		if sources.size() >= MAX_SOURCES:
			push_error("VeilMath : plus de %d halos sur la carte, les suivants ne percent pas "
				% MAX_SOURCES + "le voile")
			break
		var at := glow.global_position
		sources.append(Vector4(at.x, at.y, type.radius * hole_scale * Grid.TILE_SIZE, 1.0))
	return sources


## Rectangle à couvrir : la vue ([param view], monde) agrandie de [param margin] px de chaque
## côté (la caméra peut avancer d'une image avant que le voile ne suive).
static func cover_rect(view: Rect2, margin: float) -> Rect2:
	return view.grow(margin)
