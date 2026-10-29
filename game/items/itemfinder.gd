class_name Itemfinder
extends RefCounted
## Cherch'Objet (lot 32P, AUD-15). Classe statique et pure.
##
## Décision de Kevin (2026-10-29, Q3) : **avec la direction**. Le Cherch'Objet cherche l'objet
## caché encore à prendre le plus proche du joueur, à [constant RADIUS] cases au plus (distance de
## Tchebychev, environ une demi-hauteur d'écran) [D], et dit vers où il se trouve (l'axe le plus
## long ; à égalité, le nord ou le sud) [D]. Un objet caché = un point d'interaction qui
## disparaît avec le drapeau « got_<son dialogue> » ([method GameMap.hidden_item_cells]).

const RADIUS: int = 5
## Dialogues de `data/dialogues/key_items.json`, par direction ; rien à proximité.
const DIRECTION_DIALOGUES: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"itemfinder_north",
	Vector2i.DOWN: &"itemfinder_south",
	Vector2i.LEFT: &"itemfinder_west",
	Vector2i.RIGHT: &"itemfinder_east",
}
const NOTHING_DIALOGUE: StringName = &"itemfinder_nothing"
## Le joueur se tient sur la case de l'objet (aucun cas connu : les indices sont des cases
## bloquantes, mais une case libre reste possible).
const HERE_DIALOGUE: StringName = &"itemfinder_here"


## Case de l'objet caché le plus proche de [param player] parmi [param cells], à
## [constant RADIUS] cases au plus ; [code]Vector2i(-1, -1)[/code] s'il n'y en a aucun.
static func nearest(cells: Array[Vector2i], player: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := RADIUS + 1
	for cell: Vector2i in cells:
		var distance := distance_to(cell, player)
		if distance < best_distance:
			best = cell
			best_distance = distance
	return best


## Distance de Tchebychev entre deux cases.
static func distance_to(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Direction de [param target] vu de [param player] : l'axe le plus long (à égalité, vertical) ;
## [constant Vector2i.ZERO] sur la même case.
static func direction(player: Vector2i, target: Vector2i) -> Vector2i:
	var delta := target - player
	if delta == Vector2i.ZERO:
		return Vector2i.ZERO
	if absi(delta.y) >= absi(delta.x):
		return Vector2i.UP if delta.y < 0 else Vector2i.DOWN
	return Vector2i.LEFT if delta.x < 0 else Vector2i.RIGHT


## Dialogue à jouer pour [param player] face aux objets cachés [param cells].
static func dialogue_for(cells: Array[Vector2i], player: Vector2i) -> StringName:
	var target := nearest(cells, player)
	if target == Vector2i(-1, -1):
		return NOTHING_DIALOGUE
	var dir := direction(player, target)
	return HERE_DIALOGUE if dir == Vector2i.ZERO else DIRECTION_DIALOGUES[dir]
