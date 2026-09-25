class_name Grid
extends RefCounted
## Constantes et conversions partagées de la grille du monde.
##
## Convention de position : une entité ou un prop posé sur une case a son origine
## « aux pieds », au milieu du bord bas de la case (voir [method cell_to_world]).
## Une case couvre donc l'intervalle vertical ]haut, bas] : le bord haut appartient
## à la case du dessus. Les vitesses se règlent ici, au test sur téléphone.

## Côté d'une case, en unités monde (= pixels de la résolution de référence 1080 p).
const TILE_SIZE: int = 96
const HALF_TILE: int = 48

## Durée d'un pas en marchant (s/case). ≈ 4,5 cases/s.
const WALK_STEP_DURATION: float = 0.22
## Durée d'un pas en courant (s/case). ≈ 8,3 cases/s.
const RUN_STEP_DURATION: float = 0.12
## Durée d'un saut de rebord (2 cases franchies d'un coup).
const LEDGE_JUMP_DURATION: float = 0.40
## Maintien minimal d'une nouvelle direction, à l'arrêt, avant de marcher.
## Un appui plus bref fait seulement pivoter le personnage.
const TURN_HOLD_DURATION: float = 0.09


## Position monde (pieds, bas-centre) d'une case.
static func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE_SIZE + HALF_TILE, (cell.y + 1) * TILE_SIZE)


## Case contenant une position monde (bord haut exclu, bord bas inclus).
static func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / TILE_SIZE),
		ceili(world_position.y / TILE_SIZE) - 1
	)


## Rectangle monde couvert par une carte de [param size] cases (limites de caméra).
static func map_pixel_rect(size: Vector2i) -> Rect2i:
	return Rect2i(Vector2i.ZERO, size * TILE_SIZE)


## Vrai pour les quatre directions unitaires (haut, bas, gauche, droite).
static func is_cardinal(direction: Vector2i) -> bool:
	return absi(direction.x) + absi(direction.y) == 1
