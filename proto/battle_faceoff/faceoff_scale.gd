class_name FaceoffScale
extends RefCounted
## Échelle des artworks officiels en combat face à face (prototype, scène QA isolée).
## Classe pure, statique : aucune dépendance à l'arbre de scènes.
##
## Pas un multiplicateur identique pour les 151 : la **présence** d'un Pokémon à l'écran
## (racine de l'aire de sa boîte visible, en pixels de référence 1080 de haut) suit sa taille
## réelle, mais comprimée (exposant < 1) pour qu'un Rattata reste lisible et qu'un Onix ne
## sorte pas de l'écran. Mesurer l'aire plutôt que la hauteur traite les morphologies longues
## (Onix, Minidraco) comme les autres. L'adversaire, plus loin, est réduit d'un facteur de
## profondeur ; chaque camp a une boîte maximale qui protège l'interface.

## Taille de référence (m) et présence (px) du Pokémon du joueur à cette taille (Salamèche).
const REFERENCE_HEIGHT_M: float = 0.6
const REFERENCE_PRESENCE: float = 300.0
## Compression de l'écart de taille : 0 = tous identiques, 1 = proportionnel au réel.
const EXPONENT: float = 0.4
## Présence minimale et maximale du Pokémon du joueur (px).
const MIN_PRESENCE: float = 220.0
const MAX_PRESENCE: float = 520.0
## Facteur de profondeur de l'adversaire (plus loin, donc plus petit).
const FOE_DEPTH: float = 0.68
## Boîtes maximales à l'écran (px, référence 1080 de haut) : protègent les cartes et les
## boutons du combat.
const PLAYER_MAX_BOX := Vector2(600.0, 480.0)
const FOE_MAX_BOX := Vector2(420.0, 320.0)


## Présence (px) d'un Pokémon de [param height_m] mètres, du côté du joueur ou non.
static func presence(height_m: float, is_player: bool) -> float:
	var ratio := maxf(height_m, 0.05) / REFERENCE_HEIGHT_M
	var value := clampf(REFERENCE_PRESENCE * pow(ratio, EXPONENT), MIN_PRESENCE, MAX_PRESENCE)
	return value if is_player else value * FOE_DEPTH


## Échelle à appliquer à un artwork dont la boîte visible mesure [param box] pixels (taille
## dans l'image source), pour un Pokémon de [param height_m] mètres, à une vue de
## [param view_height] pixels de haut (référence 1080).
static func sprite_scale(box: Vector2, height_m: float, is_player: bool,
		view_height: float = 1080.0) -> float:
	if box.x <= 0.0 or box.y <= 0.0:
		return 1.0
	var unit := view_height / 1080.0
	var scale := presence(height_m, is_player) / sqrt(box.x * box.y)
	var limit: Vector2 = PLAYER_MAX_BOX if is_player else FOE_MAX_BOX
	scale = minf(scale, minf(limit.x / box.x, limit.y / box.y))
	return scale * unit
