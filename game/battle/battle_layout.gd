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
##
## **Cadrage B « façon Rouge/Bleu »** (décision de Kevin, 2026-10-25,
## `docs/design/fiches-assets/dos-cadrage-rb/README.md`) : ton Pokémon est vu de dos, grand et
## proche, **coupé par le bas de l'écran** ([method back_scale], [method back_sink]) ; il passe
## devant le feuillage flou du premier plan et n'a plus d'ombre au sol. [constant PLAYER_FEET]
## reste l'ancre du sol du décor peint ([BattleDecor] en tire son échelle) ; le dos se pose sur
## [constant PLAYER_BACK]. Une image de dos « corps entier » (dos IA, dos 3D, provisoire) est
## enfoncée de [constant BACK_CROP] sous le bord ; un dos peint en plongée (`dos_rb_NNN.png`)
## est déjà coupé et se pose sur le bord.

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
## Adversaire : 0,27 au pilote, 0,34 en cadrage B (décision de Kevin, 2026-10-25 : à côté du dos
## agrandi, il paraissait petit).
const FOE_PRESENCE: float = 0.34
## Compression de l'écart de taille réel (0 : tous pareils, 1 : proportionnel) et bornes du
## rapport à la référence (Rattata reste lisible, Onix ne mange pas l'écran).
const SIZE_EXPONENT: float = 0.4
const MIN_RATIO: float = 0.73
const MAX_RATIO: float = 1.73
## Boîtes maximales (largeur, hauteur en hauteurs d'écran) : protègent l'interface. La hauteur
## du joueur suit ses pieds (0,90 − 0,40 = 0,50 : jamais dans le quart haut gauche).
const PLAYER_MAX_BOX := Vector2(0.80, 0.40)
## Adversaire en cadrage B (décision de Kevin, 2026-10-25) : 0,70 × 0,46 (0,50 × 0,38 au pilote) ;
## la hauteur reste sous le haut de l'écran (pieds à 0,50).
const FOE_MAX_BOX := Vector2(0.70, 0.46)
## Cadrage B : bas-centre de la partie visible du dos (bord bas de l'écran, à gauche), en hauteurs
## d'écran comme les autres ancres. Essai validé : 0,58 à gauche du centre.
const PLAYER_BACK := Vector2(-0.58, 1.0)
## Hauteur visible (au-dessus du bord bas) d'un dos de la taille de référence, suivant la loi de
## taille, et ses bornes (essai : Carapuce 0,58, Onix 0,86 ; plafond 0,80 pour rester sous la
## carte adverse, [method back_zone]).
const BACK_HEIGHT: float = 0.62
const BACK_MIN_HEIGHT: float = 0.45
const BACK_MAX_HEIGHT: float = 0.80
## Largeur maximale du dos : sa moitié (0,50) reste à gauche du centre, hors des commandes.
const BACK_MAX_WIDTH: float = 1.0
## Part de la hauteur d'un dos « corps entier » enfoncée sous le bord bas (pattes et bas du corps
## coupés, comme le montage B validé).
const BACK_CROP: float = 0.30
## Taille native des sprites provisoires (pixel art) : dos du joueur, adversaire sans artwork.
const NATIVE := Vector2i(64, 64)
## Point de l'écran où tombe le centre de l'arène : de l'adversaire (0) vers le Pokémon du
## joueur (1). L'adversaire se tient **sur** l'arène, le tien au premier plan, à son bord.
const ARENA_BIAS: float = 0.3
## Le cadrage monde est remonté d'une demi-case : le sol occupe le bas de l'image.
const FOCUS_RAISE: float = Grid.HALF_TILE


## Pieds en pixels écran pour une vue de [param view_size] : { player_feet (sol du décor),
## player_back (bord bas du dos, cadrage B), foe_feet }.
static func anchors(view_size: Vector2) -> Dictionary:
	return {
		"player_feet": feet(PLAYER_FEET, view_size),
		"player_back": feet(PLAYER_BACK, view_size),
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


## Cadrage B : hauteur visible voulue (px) du dos d'un Pokémon de [param height_m] mètres.
static func back_height(height_m: float, view_height: float) -> float:
	return clampf(BACK_HEIGHT * size_ratio(height_m), BACK_MIN_HEIGHT, BACK_MAX_HEIGHT) \
		* view_height


## Cadrage B : échelle d'un dos dont la boîte visible mesure [param box] px, dont la part
## [param crop] de la hauteur passe sous le bord bas ; largeur bornée ([constant BACK_MAX_WIDTH]).
## [param whole] : pixel art net, échelle entière (arrondie vers le bas au-delà d'une borne).
static func back_scale(box: Vector2, height_m: float, view_height: float, crop: float,
		whole: bool = false) -> float:
	if box.x <= 0.0 or box.y <= 0.0:
		return 1.0
	var shown := box.y * (1.0 - clampf(crop, 0.0, 0.9))
	var largest := minf(BACK_MAX_WIDTH * view_height / box.x,
		BACK_MAX_HEIGHT * view_height / shown)
	var scale := minf(back_height(height_m, view_height) / shown, largest)
	if whole:
		scale = clampf(roundf(scale), 1.0, maxf(floorf(largest), 1.0))
	return scale


## Cadrage B : de combien de px les pieds du dos (bas de sa boîte) passent sous
## [constant PLAYER_BACK].
static func back_sink(box: Vector2, scale: float, crop: float) -> float:
	return roundf(box.y * scale * clampf(crop, 0.0, 0.9))


## Cadrage B : zone que la partie visible du dos ne quitte jamais (bas gauche, sous la carte
## adverse, à gauche des commandes).
static func back_zone(view_size: Vector2) -> Rect2:
	var bottom := feet(PLAYER_BACK, view_size)
	var size := Vector2(BACK_MAX_WIDTH, BACK_MAX_HEIGHT) * view_size.y
	return Rect2(bottom - Vector2(size.x / 2.0, size.y), size)


## Carte adverse (contrat de l'interface, [BattleHudLayout]) : le dos agrandi passe sous elle.
static func foe_card_zone(view_size: Vector2) -> Rect2:
	var bottom := float(UiTokens.BATTLE_FOE_CARD_TOP + UiTokens.BATTLE_CARD_HEIGHT)
	return Rect2(0.0, 0.0, view_size.x / 2.0, bottom)


## Rectangle écran d'une boîte visible de [param box_size] px affichée à [param scale], pieds
## (bas-centre de la boîte) sur [param feet].
static func sprite_rect(feet: Vector2, scale: float, box_size: Vector2) -> Rect2:
	var size := box_size * scale
	return Rect2(feet - Vector2(size.x / 2.0, size.y), size)


## Zone que le Pokémon d'un camp ne quitte jamais (boîte maximale posée sur ses pieds).
## Ton Pokémon : partie visible du dos en cadrage B ([method back_zone]).
static func max_rect(is_player: bool, view_size: Vector2) -> Rect2:
	if is_player:
		return back_zone(view_size)
	return sprite_rect(feet(FOE_FEET, view_size), 1.0, FOE_MAX_BOX * view_size.y)


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
