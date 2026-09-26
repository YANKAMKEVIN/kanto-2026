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

## Durée d'un pas en marchant (s/case). ≈ 3,7 cases/s. Réglage « A » validé par Kevin sur S24
## (2026-09-26). Échelle à respecter : marche < course < vélo (vélo prévu vers 0,09 s/case).
const WALK_STEP_DURATION: float = 0.27
## Durée d'un pas en courant (s/case). ≈ 6,2 cases/s.
const RUN_STEP_DURATION: float = 0.16
## Durée d'un saut de rebord (2 cases franchies d'un coup).
const LEDGE_JUMP_DURATION: float = 0.40
## Maintien minimal d'une nouvelle direction, à l'arrêt, avant de marcher.
## Un appui plus bref fait seulement pivoter le personnage.
const TURN_HOLD_DURATION: float = 0.09

## Noms des quatre directions dans les fichiers de données (PNJ, dialogues, scènes).
const _DIRECTION_NAMES: Dictionary[StringName, Vector2i] = {
	&"up": Vector2i.UP, &"down": Vector2i.DOWN, &"left": Vector2i.LEFT, &"right": Vector2i.RIGHT,
}


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


## Direction nommée dans les données (« up », « down », « left », « right ») ; ZERO si le
## nom est inconnu.
static func direction_from_name(direction_name: String) -> Vector2i:
	return _DIRECTION_NAMES.get(StringName(direction_name), Vector2i.ZERO)


## Vrai si [param direction_name] est un des quatre noms de direction.
static func is_direction_name(direction_name: String) -> bool:
	return _DIRECTION_NAMES.has(StringName(direction_name))


## Nom d'une direction cardinale (&"up"…) ; &"" sinon.
static func direction_name(direction: Vector2i) -> StringName:
	for key: StringName in _DIRECTION_NAMES:
		if _DIRECTION_NAMES[key] == direction:
			return key
	return &""


## Direction cardinale de [param from] vers [param to] selon l'axe dominant (à égalité,
## l'axe vertical) ; ZERO si c'est la même case. Règle unique pour « se tourner vers ».
static func dominant_direction(from: Vector2i, to: Vector2i) -> Vector2i:
	var delta := to - from
	if delta == Vector2i.ZERO:
		return Vector2i.ZERO
	if absi(delta.x) > absi(delta.y):
		return Vector2i(signi(delta.x), 0)
	return Vector2i(0, signi(delta.y))
