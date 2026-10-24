class_name BattleLayout
extends RefCounted
## Placement de la vue de combat dans le décor réel. Classe pure, statique : aucune dépendance
## à l'arbre de scènes.
##
## Composition du pilote validée (fiche `serie-combat-dos-pilote.md` §1, 2026-10-05 ; reprise
## au CB.1, `docs/tech/combat-maquettes.md`) : lieu réel resserré, ton Pokémon **de dos** au
## premier plan en bas à gauche, l'adversaire nettement plus loin en haut à droite.
## **Cadrage B** (décision de Kevin, 2026-10-25, fiche `fiches-assets/dos-cadrage-rb/`) : ton
## Pokémon est grand, de trois quarts arrière et **coupé par le bas de l'écran** comme dans
## Rouge/Bleu ([method back_feet]) ; [constant PLAYER_FEET] ne place plus son sprite, il reste
## la ligne de sol du premier plan qui cale le décor peint ([method BattleDecor.fit]) et l'arène.
## L'interface occupe l'autre diagonale : carte adverse en haut à gauche, ta carte et les
## commandes dans le bas droit ([method hud_zones]) ; aucun Pokémon n'y entre, quelle que soit
## sa taille (boîtes maximales).
##
## Les ancres sont en **hauteurs d'écran** depuis le centre horizontal (x) et depuis le haut
## (y) : même composition de 1920 à 2340 de large. Taille : la **présence** d'un Pokémon
## (racine de l'aire de sa boîte visible) suit sa taille réelle (Pokédex), comprimée
## ([constant SIZE_EXPONENT]) et bornée, à partir de Salamèche (référence de gabarit, ≈ 60 %
## du premier essai du pilote).

## Sol du premier plan (côté du joueur) et pieds de l'adversaire (prototype `duel_qa.gd`,
## cadrage « combat »). Correctif QA S24 (2026-10-07) : sol du joueur remonté de 0,97 à 0,90.
## Ne pas déplacer : l'échelle des décors peints en dépend ([method BattleDecor.fit]).
const PLAYER_FEET := Vector2(-0.42, 0.90)
const FOE_FEET := Vector2(0.36, 0.50)
## Taille réelle (m) de référence : Salamèche.
const REFERENCE_HEIGHT_M: float = 0.6
## Présence (hauteurs d'écran) de l'adversaire de la taille de référence : 0,34 en cadrage B
## (décision de Kevin, 2026-10-25 ; 0,27 avant : il paraissait petit face au dos agrandi).
const FOE_PRESENCE: float = 0.34
## Compression de l'écart de taille réel (0 : tous pareils, 1 : proportionnel) et bornes du
## rapport à la référence (Rattata reste lisible, Onix ne mange pas l'écran).
const SIZE_EXPONENT: float = 0.4
const MIN_RATIO: float = 0.73
const MAX_RATIO: float = 1.73
## Boîte maximale de l'adversaire (largeur, hauteur en hauteurs d'écran) : protège
## l'interface ; 0,70 × 0,46 en cadrage B (décision de Kevin, 2026-10-25 ; ses pieds à 0,50,
## il ne touche jamais le haut de l'écran).
const FOE_MAX_BOX := Vector2(0.70, 0.46)
## Cadrage B du dos (valeurs en hauteurs d'écran) : centre de l'image à [constant BACK_X] du
## centre de l'écran ; part **visible** (au-dessus du bas de l'écran) haute de
## [constant BACK_HEIGHT] pour un Pokémon de la taille de référence, suivie par la loi de taille
## ([method size_ratio] : Carapuce ≈ 0,58, comme l'essai) ; [constant BACK_CUT] : part de la
## boîte de l'image sous le bas de l'écran (valeur par défaut, 2026-10-25 : on garde la tête et
## le haut du corps, les pieds sortent du cadre). [constant BACK_MAX_BOX] (largeur, hauteur de
## la part visible) borne les grands : le haut ne monte jamais dans la carte adverse
## ([method hud_zones]), le bord droit reste loin du bas droit (commandes). Sur un écran 16:9
## (1920 de large), un dos très large peut aussi déborder un peu du bord gauche (≤ 0,2).
const BACK_X: float = -0.58
const BACK_HEIGHT: float = 0.62
const BACK_CUT: float = 0.25
const BACK_MAX_BOX := Vector2(1.00, 0.80)
## Haut de l'écran réservé à la carte adverse, à gauche (carte : 56 + 112 px ≈ 0,16, plus une
## marge).
const FOE_CARD_ZONE: float = 0.20
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


## Présence voulue (px) de l'adversaire de [param height_m] mètres sur une vue de
## [param view_height] px de haut.
static func presence(height_m: float, view_height: float) -> float:
	return FOE_PRESENCE * size_ratio(height_m) * view_height


## Hauteur voulue (px) de la part visible du dos d'un Pokémon de [param height_m] mètres.
static func back_height(height_m: float, view_height: float) -> float:
	return BACK_HEIGHT * size_ratio(height_m) * view_height


## Échelle d'une image dont la boîte visible mesure [param box] px (dans la texture), pour un
## Pokémon de [param height_m] mètres : l'adversaire par sa présence, ton Pokémon (de dos) par
## la hauteur de sa part visible ([constant BACK_CUT] de la boîte sous l'écran). [param whole] :
## pixel art net, échelle entière (≥ 1, jamais au-delà de la boîte maximale si possible).
static func sprite_scale(box: Vector2, height_m: float, is_player: bool, view_height: float,
		whole: bool = false) -> float:
	if box.x <= 0.0 or box.y <= 0.0:
		return 1.0
	var largest: float
	var scale: float
	if is_player:
		var shown := box.y * (1.0 - BACK_CUT)
		var limit := BACK_MAX_BOX * view_height
		largest = minf(limit.x / box.x, limit.y / shown)
		scale = minf(back_height(height_m, view_height) / shown, largest)
	else:
		var limit := FOE_MAX_BOX * view_height
		largest = minf(limit.x / box.x, limit.y / box.y)
		scale = minf(presence(height_m, view_height) / sqrt(box.x * box.y), largest)
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


## Pieds écran (bas-centre de la boîte de l'image) du dos de ton Pokémon, affiché haut de
## [param shown_height] px en tout : sous le bas de l'écran de [constant BACK_CUT] de sa hauteur.
static func back_feet(view_size: Vector2, shown_height: float) -> Vector2:
	return Vector2(view_size.x / 2.0 + BACK_X * view_size.y,
		view_size.y + BACK_CUT * shown_height).round()


## Zone **à l'écran** que le Pokémon d'un camp ne quitte jamais : boîte maximale posée sur les
## pieds de l'adversaire, ou part visible maximale du dos posée sur le bas de l'écran.
static func max_rect(is_player: bool, view_size: Vector2) -> Rect2:
	if is_player:
		var size := BACK_MAX_BOX * view_size.y
		var bottom := Vector2(view_size.x / 2.0 + BACK_X * view_size.y, view_size.y)
		return sprite_rect(bottom, 1.0, size)
	return sprite_rect(anchors(view_size)["foe_feet"], 1.0, FOE_MAX_BOX * view_size.y)


## Zones réservées à l'interface (contrat CB.1 / CB.2, resserré au cadrage B) : le haut de la
## moitié gauche (carte adverse, [constant FOE_CARD_ZONE]) et le bas droit (ta carte, tes
## pastilles, les commandes : moitié basse, moitié droite).
static func hud_zones(view_size: Vector2) -> Array[Rect2]:
	var half := view_size / 2.0
	return [Rect2(0.0, 0.0, half.x, FOE_CARD_ZONE * view_size.y), Rect2(half, half)]


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
