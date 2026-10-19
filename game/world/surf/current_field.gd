class_name CurrentField
extends RefCounted
## Courants d'eau (jalon 24, T9 ; dossier 27 §7.4, `jalon-24.md` §2.6) : classe pure et statique.
##
## Un courant est une suite de cases d'eau portant une direction ([method GridWorld.set_current],
## posée par la carte **seulement si le courant est actif** ; aux Îles Écume, le J24 la pose selon
## ses drapeaux). Générique : n'importe quelle eau (passe systèmes 2, §0.2 ; d'abord dans
## `game/world/seafoam/`).
## Quand le joueur entre sur une case de courant, [method ride] calcule d'avance tout le trajet :
## les cases traversées et la direction de chaque pas, jusqu'à
## - une case d'eau calme (le joueur s'y arrête, toujours en Surf) ;
## - une case de terre (il y **descend**, [member Ride.dismounts]) ;
## - un terminal (passage, warp : [member Ride.warp], par ex. la fin du courant 1 → B4F).
## Erreurs de données (jamais sur les grilles validées, prouvé par `plan_check_j24_seafoam.py`) :
## case suivante infranchissable (BLOCKED), boucle (LOOP), trajet trop long (TOO_LONG).
##
## **Lecture en jeu** : le trajet a la forme de `SpinSlide` du J20 (cases sans la case de départ,
## une direction par pas, case de fin, statut). Après la fusion du J20, le directeur du joueur le
## jouera avec la glissade de `SpinSlide` (aucune entrée, pas de sauvegarde pendant la glissade :
## [method Ride.can_save]) ; ce fichier ne dépend pas du J20 (règle d'ancienneté, §0.1).

enum Status {
	OK, ## Le trajet se termine normalement.
	NOT_A_CURRENT, ## La case de départ n'est pas un courant : aucun trajet.
	BLOCKED, ## La case suivante est infranchissable en Surf (erreur de données).
	LOOP, ## Le trajet repasse par une case (erreur de données).
	TOO_LONG, ## Plus de pas que [constant MAX_STEPS] (erreur de données).
}

## Limite de longueur d'un trajet [D] (le courant 1 en fait 14).
const MAX_STEPS: int = 64


## Trajet d'une glissade de courant, calculé d'avance par [method CurrentField.ride].
class Ride:
	extends RefCounted
	var start: Vector2i = Vector2i.ZERO
	## Cases traversées dans l'ordre, **sans** la case de départ.
	var cells: Array[Vector2i] = []
	## Direction de chaque pas (même longueur que [member cells]).
	var facings: Array[Vector2i] = []
	## Dernière case atteinte ([member start] si aucun pas).
	var end: Vector2i = Vector2i.ZERO
	var status: Status = Status.NOT_A_CURRENT
	## Le trajet finit sur un terminal (passage, warp) : l'appelant déclenche le transfert.
	var warp: bool = false
	## Le trajet finit sur une case de terre : le joueur y repasse à pied.
	var dismounts: bool = false
	## Pas déjà joués par le directeur.
	var steps_done: int = 0

	func is_ok() -> bool:
		return status == Status.OK

	func size() -> int:
		return cells.size()

	## Vrai tant qu'un trajet valide n'a pas fini de se jouer.
	func is_sliding() -> bool:
		return status == Status.OK and steps_done < cells.size()

	## Faux pendant la glissade (dossier §5.7 : jamais de sauvegarde sur un courant).
	func can_save() -> bool:
		return not is_sliding()

	## Direction du prochain pas (ZERO si fini ou invalide).
	func next_direction() -> Vector2i:
		return facings[steps_done] if is_sliding() else Vector2i.ZERO

	## Marque le prochain pas comme joué.
	func step_done() -> void:
		if is_sliding():
			steps_done += 1


## Trajet depuis la case de courant [param start] (où le joueur vient d'entrer).
## [param terminals] : cases qui arrêtent le trajet par un transfert (passages, warps).
## [param mover] : le joueur, ignoré dans le test d'occupation.
static func ride(grid: GridWorld, start: Vector2i, terminals: Dictionary = {},
		mover: Object = null) -> Ride:
	var result := Ride.new()
	result.start = start
	result.end = start
	if grid == null or not grid.is_current(start):
		return result
	result.status = Status.OK
	var visited: Dictionary[Vector2i, bool] = {start: true}
	var pos := start
	while true:
		if terminals.has(pos):
			result.warp = true
			break
		var direction := grid.get_current(pos)
		if direction == Vector2i.ZERO:
			break
		var next := pos + direction
		if not grid.can_enter_as(next, direction, GridWorld.MoveMode.SURF, mover):
			result.status = Status.BLOCKED
			break
		if visited.has(next):
			result.status = Status.LOOP
			break
		if result.cells.size() >= MAX_STEPS:
			result.status = Status.TOO_LONG
			break
		visited[next] = true
		result.cells.append(next)
		result.facings.append(direction)
		result.end = next
		pos = next
		if not grid.is_surfable(next):
			result.dismounts = true
			break
	return result


## Vrai si [param cell] est une case de courant actif.
static func is_active_at(grid: GridWorld, cell: Vector2i) -> bool:
	return grid != null and grid.is_current(cell)
