class_name FishingSpot
extends RefCounted
## Case d'eau où pêcher, devant le joueur (jalon 22 §0.4 n° 1 et 2, §2.5). Pur, statique.
##
## [b]Provisoire (T3 → T12).[/b] [GridWorld] n'a pas encore de marque « pêchable » : les cases
## pêchables sont passées en paramètre (ensemble de cases). T12 branchera la marque de la grille
## et `data/world/fishable.json`.

## Valeur renvoyée quand il n'y a rien à pêcher.
const NONE: Vector2i = Vector2i(-1, -1)


## Case d'eau pêchable devant le joueur, ou [constant NONE]. Conditions : [param facing]
## cardinal ; la case de devant est de l'eau, dans [param fishable] et sans entité ; le joueur
## ([param cell]) se tient sur une case praticable (ni solide, ni eau) ; pas sur la Piste
## Cyclable ([param cycling_road]).
static func in_front(grid: GridWorld, cell: Vector2i, facing: Vector2i, cycling_road: bool,
		fishable: Dictionary[Vector2i, bool]) -> Vector2i:
	if grid == null or cycling_road or not Grid.is_cardinal(facing):
		return NONE
	if not grid.is_in_bounds(cell) or grid.is_solid(cell) or grid.is_water(cell):
		return NONE
	var target := cell + facing
	if not grid.is_in_bounds(target) or not grid.is_water(target):
		return NONE
	if not fishable.get(target, false) or grid.is_occupied(target):
		return NONE
	return target
