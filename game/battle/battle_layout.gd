class_name BattleLayout
extends RefCounted
## Placement de la vue de combat dans le décor réel (jalon-04.md §14.4, décision de Kevin
## n° 10). Classe pure, statique : aucune dépendance à l'arbre de scènes.
##
## Composition d'après combat-v1 : le Pokémon du joueur, de dos, au premier plan en bas à
## gauche ; l'adversaire, de face, au centre droit, plus haut (plus loin). Les ancres sont
## exprimées en **hauteurs d'écran** depuis le centre horizontal (x) et depuis le haut (y) :
## le duel garde la même composition resserrée de 1920 à 2340 de large (aspect expand), comme
## sur la référence, au lieu de s'écarter vers les bords ; pieds sur l'ancre. Les rectangles
## des sprites restent dans l'écran et ne chevauchent aucun emplacement de l'interface de
## combat (BattleHudLayout, vérifié par les tests à 1920 × 1080 et 2340 × 1080).

## Pieds du Pokémon du joueur (x : décalage depuis le centre, y : depuis le haut, en
## hauteurs d'écran) et échelle (64 px natif → 256 px).
const PLAYER_FEET := Vector2(-0.30, 0.63)
const PLAYER_SCALE: int = 4
## Pieds de l'adversaire et échelle (64 px natif → 192 px).
const FOE_FEET := Vector2(0.24, 0.47)
const FOE_SCALE: int = 3
## Taille native des sprites de combat.
const NATIVE := Vector2i(64, 64)
## Point de l'écran où tombe le centre de l'arène : de l'adversaire (0) vers le Pokémon du
## joueur (1). L'adversaire se tient **sur** l'arène, le tien au premier plan, à son bord.
const ARENA_BIAS: float = 0.3
## Le cadrage monde est remonté d'une demi-case : le sol occupe le bas de l'image.
const FOCUS_RAISE: float = Grid.HALF_TILE


## Ancres en pixels écran pour une vue de [param view_size] :
## { player_feet, foe_feet (Vector2), player_scale, foe_scale (int) }.
static func anchors(view_size: Vector2) -> Dictionary:
	return {
		"player_feet": feet(PLAYER_FEET, view_size),
		"foe_feet": feet(FOE_FEET, view_size),
		"player_scale": PLAYER_SCALE,
		"foe_scale": FOE_SCALE,
	}


## Pieds écran pour une ancre [param anchor] (en hauteurs d'écran, voir [constant PLAYER_FEET]).
static func feet(anchor: Vector2, view_size: Vector2) -> Vector2:
	return Vector2(view_size.x / 2.0 + anchor.x * view_size.y, anchor.y * view_size.y).round()


## Centre monde du cadrage quand la carte a une **arène** ([param arena], rectangle monde :
## le tapis central du labo) : le centre de l'arène tombe entre les deux ancres, près de
## l'adversaire ([constant ARENA_BIAS]) : il se tient sur l'arène, le tien au premier plan.
## Sur chaque axe, si la carte [param bounds] (rectangle monde) dépasse la vue au zoom
## [param zoom], la vue reste dedans ; sinon la carte reste **entière** à l'écran (le bord
## sombre des petites pièces peut être plus large d'un côté). [param bounds] vide : pas de
## contrainte.
static func arena_focus(arena: Rect2, bounds: Rect2, view_size: Vector2, zoom: float) -> Vector2:
	var middle: Vector2 = arena_screen_point(view_size)
	var focus_point := arena.get_center() - (middle - view_size / 2.0) / zoom
	if bounds.has_area():
		var half := view_size / (2.0 * zoom)
		for axis: int in 2:
			var low: float = bounds.position[axis] + half[axis]
			var high: float = bounds.end[axis] - half[axis]
			focus_point[axis] = clampf(focus_point[axis], minf(low, high), maxf(low, high))
	return focus_point.round()


## Point écran où [method arena_focus] place le centre de l'arène.
static func arena_screen_point(view_size: Vector2) -> Vector2:
	var a := anchors(view_size)
	var foe: Vector2 = a["foe_feet"]
	var mine: Vector2 = a["player_feet"]
	return foe.lerp(mine, ARENA_BIAS)


## Centre monde du cadrage sans arène : milieu (boîte englobante) des centres des cases
## [param cells] (combattants et dresseurs), remonté de [constant FOCUS_RAISE].
static func focus(cells: Array[Vector2i]) -> Vector2:
	if cells.is_empty():
		return Vector2.ZERO
	var low := Vector2(cells[0])
	var high := Vector2(cells[0])
	for cell: Vector2i in cells:
		low = low.min(Vector2(cell))
		high = high.max(Vector2(cell))
	var middle := (low + high) / 2.0 * Grid.TILE_SIZE + Vector2.ONE * Grid.HALF_TILE
	return middle - Vector2(0.0, FOCUS_RAISE)


## Rectangle écran d'un sprite de taille native [param native] affiché à l'échelle
## [param scale], pieds (bas-centre) sur [param feet].
static func sprite_rect(feet: Vector2, scale: int, native: Vector2i) -> Rect2:
	var size := Vector2(native) * scale
	return Rect2(feet - Vector2(size.x / 2.0, size.y), size)
