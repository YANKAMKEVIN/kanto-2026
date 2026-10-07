class_name AmbientRules
extends RefCounted
## Réactions des Pokémon d'ambiance à l'approche du joueur (dossier 04 §1, jalon 5 §3.5).
##
## Classe pure, statique, sans dépendance à l'arbre de scènes : [AmbientWatcher]
## (présentation, jalon 5) l'appelle pour décider quand un Pokémon « shy » réagit, s'il quitte
## la carte et, pour une fuite, par où il détale. Aucun aléatoire : le résultat ne dépend que
## de la grille et des positions (reproductible).

## Ordre d'exploration des fuites (haut, bas, gauche, droite) : chemin toujours identique.
const _DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
]


## Vrai si la réaction [param action] ([constant NpcSpec.SHY_ACTIONS]) fait quitter la carte
## au Pokémon (envol, fuite, retrait vers le feuillage) ; faux pour « notice » (il relève la
## tête et reste, jalon 9). Une fuite sans issue reste aussi sur place ([method flee_path] vide).
static func leaves_map(action: StringName) -> bool:
	return action != &"notice"


## Vrai si le joueur est à [param radius] cases ou moins de [param npc_cell] (distance de
## Manhattan).
static func is_within(npc_cell: Vector2i, player_cell: Vector2i, radius: int) -> bool:
	return _manhattan(npc_cell, player_cell) <= radius


## Suite de directions (jusqu'à [param max_steps]) qui **éloignent** de [param away_from], une
## par pas, chacune vers une case où le Pokémon peut se tenir ([method GridWorld.is_free], donc
## ni solide, ni eau, ni rebord, ni occupée). Glouton : à chaque pas, la première direction de
## [constant _DIRECTIONS] qui augmente la distance de Manhattan. Vide si aucun pas n'éloigne
## dès le départ (le Pokémon est acculé : il reste et ne traverse jamais le joueur).
static func flee_path(grid: GridWorld, from: Vector2i, away_from: Vector2i, max_steps: int,
		mover: Object = null) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if grid == null:
		return path
	var current := from
	for _step: int in maxi(max_steps, 0):
		var best := _best_step(grid, current, away_from, mover)
		if best == Vector2i.ZERO:
			break
		current += best
		path.append(best)
	return path


## Première direction qui éloigne vers une case libre, ou Vector2i.ZERO si aucune.
static func _best_step(grid: GridWorld, from: Vector2i, away_from: Vector2i,
		mover: Object) -> Vector2i:
	var current_distance := _manhattan(from, away_from)
	for direction: Vector2i in _DIRECTIONS:
		var target := from + direction
		if not grid.is_free(target, mover):
			continue
		if _manhattan(target, away_from) > current_distance:
			return direction
	return Vector2i.ZERO


static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
