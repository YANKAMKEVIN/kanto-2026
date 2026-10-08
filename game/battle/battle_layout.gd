class_name BattleLayout
extends RefCounted
## Placement de la vue de combat dans le décor réel. Classe pure, statique : aucune dépendance
## à l'arbre de scènes.
##
## Composition du pilote validée (fiche `serie-combat-dos-pilote.md` §1, 2026-10-05 ; reprise
## au CB.1, `docs/tech/combat-maquettes.md`) : lieu réel resserré, ton Pokémon **de dos** au
## premier plan en bas à gauche (pieds sur le sol visible, au-dessus du feuillage flou de premier
## plan du décor peint), l'adversaire nettement plus loin en haut à droite. L'interface occupe l'autre diagonale : carte adverse dans le quart
## haut gauche, ta carte et les commandes dans le bas droit ([method hud_zones]) ; aucun
## Pokémon n'y entre, quelle que soit sa taille (boîtes maximales).
##
## Les ancres sont en **hauteurs d'écran** depuis le centre horizontal (x) et depuis le haut
## (y) : même composition de 1920 à 2340 de large. Taille : la **présence** d'un Pokémon
## (racine de l'aire de sa boîte visible) suit sa taille réelle (Pokédex), comprimée
## ([constant SIZE_EXPONENT]) et bornée, à partir de Salamèche (référence de gabarit, ≈ 60 %
## du premier essai du pilote).

## Pieds du Pokémon du joueur et de l'adversaire (prototype `duel_qa.gd`, cadrage « combat »).
## Correctif QA S24 (2026-10-07) : pieds du joueur remontés de 0,97 à 0,90 (à 0,97 la base
## touchait le bord bas et passait derrière le feuillage de premier plan du décor peint).
const PLAYER_FEET := Vector2(-0.42, 0.90)
const FOE_FEET := Vector2(0.36, 0.50)
## Taille réelle (m) de référence : Salamèche.
const REFERENCE_HEIGHT_M: float = 0.6
## Présence (hauteurs d'écran) d'un Pokémon de la taille de référence : de dos (le tien,
## Salamèche ≈ 0,336 de haut = 60 % de 0,56) et de face (l'adversaire : Roucool, 0,3 m, ≈ 0,21
## de haut au pilote, ramené à 0,6 m par la loi de taille).
const PLAYER_PRESENCE: float = 0.31
const FOE_PRESENCE: float = 0.27
## Compression de l'écart de taille réel (0 : tous pareils, 1 : proportionnel) et bornes du
## rapport à la référence (Rattata reste lisible, Onix ne mange pas l'écran).
const SIZE_EXPONENT: float = 0.4
const MIN_RATIO: float = 0.73
const MAX_RATIO: float = 1.73
## Boîtes maximales (largeur, hauteur en hauteurs d'écran) : protègent l'interface. La hauteur
## du joueur suit ses pieds (0,90 − 0,40 = 0,50 : jamais dans le quart haut gauche).
const PLAYER_MAX_BOX := Vector2(0.80, 0.40)
const FOE_MAX_BOX := Vector2(0.50, 0.38)
## Taille native des sprites provisoires (pixel art) : dos du joueur, adversaire sans artwork.
const NATIVE := Vector2i(64, 64)
## Point de l'écran où tombe le centre de l'arène : de l'adversaire (0) vers le Pokémon du
## joueur (1). L'adversaire se tient **sur** l'arène, le tien au premier plan, à son bord.
const ARENA_BIAS: float = 0.3
## Le cadrage monde est remonté d'une demi-case : le sol occupe le bas de l'image.
const FOCUS_RAISE: float = Grid.HALF_TILE


## Pieds en pixels écran pour une vue de [param view_size] : { player_feet, foe_feet }.
static func anchors(view_size: Vector2) -> Dictionary:
	return {
		"player_feet": feet(PLAYER_FEET, view_size),
		"foe_feet": feet(FOE_FEET, view_size),
	}


## Pieds écran pour une ancre [param anchor] (en hauteurs d'écran, voir [constant PLAYER_FEET]).
static func feet(anchor: Vector2, view_size: Vector2) -> Vector2:
	return Vector2(view_size.x / 2.0 + anchor.x * view_size.y, anchor.y * view_size.y).round()


## Rapport de présence d'un Pokémon de [param height_m] mètres à la référence (comprimé, borné).
static func size_ratio(height_m: float) -> float:
	var ratio := maxf(height_m, 0.05) / REFERENCE_HEIGHT_M
	return clampf(pow(ratio, SIZE_EXPONENT), MIN_RATIO, MAX_RATIO)


## Présence voulue (px) d'un Pokémon de [param height_m] mètres sur une vue de
## [param view_height] px de haut.
static func presence(height_m: float, is_player: bool, view_height: float) -> float:
	var base := PLAYER_PRESENCE if is_player else FOE_PRESENCE
	return base * size_ratio(height_m) * view_height


## Échelle d'une image dont la boîte visible mesure [param box] px (dans la texture), pour un
## Pokémon de [param height_m] mètres. [param whole] : pixel art net, échelle entière (≥ 1,
## jamais au-delà de la boîte maximale si possible).
static func sprite_scale(box: Vector2, height_m: float, is_player: bool, view_height: float,
		whole: bool = false) -> float:
	if box.x <= 0.0 or box.y <= 0.0:
		return 1.0
	var limit := (PLAYER_MAX_BOX if is_player else FOE_MAX_BOX) * view_height
	var largest := minf(limit.x / box.x, limit.y / box.y)
	var scale := minf(presence(height_m, is_player, view_height) / sqrt(box.x * box.y), largest)
	if whole:
		scale = roundf(scale)
		if scale > largest:
			scale = floorf(largest)
		scale = maxf(scale, 1.0)
	return scale


## Rectangle écran d'une boîte visible de [param box_size] px affichée à [param scale], pieds
## (bas-centre de la boîte) sur [param feet].
static func sprite_rect(feet: Vector2, scale: float, box_size: Vector2) -> Rect2:
	var size := box_size * scale
	return Rect2(feet - Vector2(size.x / 2.0, size.y), size)


## Zone que le Pokémon d'un camp ne quitte jamais (boîte maximale posée sur ses pieds).
static func max_rect(is_player: bool, view_size: Vector2) -> Rect2:
	var a := anchors(view_size)
	var box := (PLAYER_MAX_BOX if is_player else FOE_MAX_BOX) * view_size.y
	return sprite_rect(a["player_feet" if is_player else "foe_feet"], 1.0, box)


## Zones réservées à l'interface (contrat CB.1 / CB.2) : le quart haut gauche (carte adverse)
## et le bas droit (ta carte, tes pastilles, les commandes : moitié basse, moitié droite).
static func hud_zones(view_size: Vector2) -> Array[Rect2]:
	var half := view_size / 2.0
	return [Rect2(Vector2.ZERO, half), Rect2(half, half)]


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
	return clamp_focus(focus_point, bounds, view_size, zoom)


## [param focus_point] (centre monde) ramené pour que la vue au zoom [param zoom] reste dans
## [param bounds] sur chaque axe où la carte est plus grande que la vue (sinon la carte reste
## entière à l'écran) ; [param bounds] vide : arrondi seulement.
static func clamp_focus(focus_point: Vector2, bounds: Rect2, view_size: Vector2,
		zoom: float) -> Vector2:
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
