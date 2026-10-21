class_name MountRules
extends RefCounted
## Règles communes de la monture (passe systèmes 2, `docs/tech/systemes-2.md` §2.2) : pur,
## statique. Réunit ce qui ne dépend pas du type de monture : l'arrivée sur une carte et la durée
## d'un pas. Les règles propres restent dans [BikeRules] (monter, descendre) et [SurfRules]
## (monter, nager, reprise).

## Vitesse en Surf : la marche × 1,15 [D, `jalon-24.md` §2.3].
const SURF_SPEED_FACTOR: float = 1.15
## Saut de montée en Surf et de descente sur la rive, en secondes [D, `systemes-2.md` §8].
const SURF_HOP_DURATION: float = 0.5


## Vrai si le pas de [param from] à [param to] en Surf est un saut : il passe de la terre à
## l'eau surfable (montée) ou de l'eau à la terre (descente).
static func is_surf_hop(kind: Mount.Kind, grid: GridWorld, from: Vector2i, to: Vector2i) -> bool:
	return kind == Mount.Kind.SURF and grid != null \
		and grid.is_surfable(from) != grid.is_surfable(to)


## Monture à l'arrivée sur une carte (warp, bord, chargement), de case d'arrivée
## [param arrival_cell] :
## - une eau surfable ou une case « Surf forcé » de la carte → en Surf (on ne se tient pas sur
##   l'eau) ;
## - sinon en Surf → à pied (la terre ferme fait descendre) ;
## - en Vélo là où il n'est pas permis (intérieur) → à pied ;
## - à pied sur la Piste Cyclable avec la Bicyclette → en Vélo d'office ;
## - sinon on garde la monture.
static func on_map_entered(current: Mount.Kind, map: MapTraits, arrival_cell: Vector2i,
		grid: GridWorld, has_bike: bool) -> Mount.Kind:
	if map.forced_surf_cells.has(arrival_cell) \
			or (grid != null and grid.is_surfable(arrival_cell)):
		return Mount.Kind.SURF
	var kind := current
	if kind == Mount.Kind.SURF:
		kind = Mount.Kind.NONE
	if kind == Mount.Kind.BIKE and not map.allows_bike():
		kind = Mount.Kind.NONE
	if kind == Mount.Kind.NONE and map.cycling_road and has_bike and map.allows_bike():
		kind = Mount.Kind.BIKE
	return kind


## Durée d'un pas : Vélo (la course est ignorée), Surf (la course est ignorée), course, marche.
static func step_duration(kind: Mount.Kind, running: bool) -> float:
	match kind:
		Mount.Kind.BIKE:
			return BikeRules.BIKE_STEP_DURATION
		Mount.Kind.SURF:
			return Grid.WALK_STEP_DURATION / SURF_SPEED_FACTOR
	return Grid.RUN_STEP_DURATION if running else Grid.WALK_STEP_DURATION
