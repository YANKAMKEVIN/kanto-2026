class_name TrainerRules
extends RefCounted
## Règles pures des Dresseurs du monde (jalon 9, jalon-09.md §2.4.2) : mémoire « battu »,
## champ de vision, pas de l'approche. Aucune dépendance à l'arbre de scènes.
##
## Un Dresseur est immobile et regarde toujours dans la même direction (défaut du plan) : il
## voit le joueur en **ligne droite devant lui**, jusqu'à sa portée. La ligne s'arrête à la
## première case infranchissable (décor, eau, bord de la carte, autre personnage) ; les hautes
## herbes et les rebords ne la coupent pas. Repéré, il marche jusqu'à la case voisine du joueur
## (Rouge/Bleu).

## Portée de vision permise dans les données ([NpcRoster], bloc « trainer »).
const SIGHT_MIN: int = 1
const SIGHT_MAX: int = 8
## Préfixe du drapeau d'histoire « battu » (sauvegardé avec les autres drapeaux).
const BEATEN_PREFIX: String = "beaten_"
## Pas de joueur en vue ([method sight_distance]).
const NOT_SEEN: int = -1
## Jalon 12 (jalon-12.md §2.11) : préfixe du drapeau « le joueur a perdu contre lui » (réplique
## de reprise ; levé seulement pour un Dresseur qui a une réplique « rematch »).
const LOST_PREFIX: String = "lost_"


## Drapeau levé quand le joueur a battu [param trainer_id] : `beaten_<id>`.
static func beaten_flag(trainer_id: StringName) -> StringName:
	return StringName(BEATEN_PREFIX + String(trainer_id))


## Vrai si [param trainer_id] a été battu (null = nouvelle partie : jamais).
static func is_beaten(flags: StoryFlags, trainer_id: StringName) -> bool:
	return flags != null and flags.has_flag(beaten_flag(trainer_id))


## Distance (1..[param sight]) du joueur [param target] sur la ligne droite devant le Dresseur
## (case [param from], orientation [param facing]), ou [constant NOT_SEEN]. La ligne s'arrête à
## la première case hors carte, solide, d'eau, ou occupée par un autre que le joueur ; les
## hautes herbes et les rebords ne la coupent pas. S2C : pour un Nageur
## ([param mode] SURF), l'eau **surfable** ne coupe pas la ligne (il voit le joueur en Surf).
static func sight_distance(grid: GridWorld, from: Vector2i, facing: Vector2i, sight: int,
		target: Vector2i, mode: GridWorld.MoveMode = GridWorld.MoveMode.WALK) -> int:
	if grid == null or not Grid.is_cardinal(facing):
		return NOT_SEEN
	for distance: int in range(1, sight + 1):
		var cell := from + facing * distance
		if not grid.is_in_bounds(cell):
			return NOT_SEEN
		if cell == target:
			return distance
		if grid.is_solid(cell) or grid.is_occupied(cell):
			return NOT_SEEN
		if grid.is_water(cell) and not (mode == GridWorld.MoveMode.SURF
				and grid.is_surfable(cell)):
			return NOT_SEEN
	return NOT_SEEN


## Pas de l'approche du Dresseur qui a vu le joueur à [param distance] cases : il avance dans
## son orientation [param facing] jusqu'à la case voisine du joueur (distance − 1 pas ; aucun
## si le joueur est déjà à côté).
static func approach_path(facing: Vector2i, distance: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	for i: int in maxi(distance - 1, 0):
		path.append(facing)
	return path


## Jalon 12 : drapeau levé quand le joueur a perdu contre [param trainer_id] : `lost_<id>`.
static func lost_flag(trainer_id: StringName) -> StringName:
	return StringName(LOST_PREFIX + String(trainer_id))
