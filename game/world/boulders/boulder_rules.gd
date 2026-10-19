class_name BoulderRules
extends RefCounted
## Poussée d'un rocher de Force (jalon 24, T9 ; dossier 27 §6.3, `jalon-24.md` §2.5) : classe
## pure et statique. [method push] **décrit** ce qui arrive, sans rien modifier : l'appelant
## (le joueur, T10) déplace l'occupant ([method GridWorld.move_occupant]) ou retire le rocher et
## pose le drapeau du trou.
##
## Un rocher est un **occupant** de la grille. Il glisse d'une case (MOVED), s'arrête sur un
## interrupteur (ON_SWITCH, passe systèmes 2 §2.7.4), tombe dans un trou ouvert (FELL) ou ne bouge
## pas (REFUSED : le rocher tremble, sans texte). Refus (§6.3) :
## - mur, arête, case hors carte (WALL) ; rebord (LEDGE) ;
## - eau, y compris un courant (WATER) ;
## - escalier, échelle, entrée, sol haut : tout **changement de niveau de sol** (LEVEL :
##   [method GridWorld.get_level] de la case visée différent de celui du rocher ; une échelle ou une
##   entrée est de niveau ANY, un escalier STAIRS : refusés face à un rocher du sol bas) ;
## - case interdite par la carte, [param no_push] : case d'objet caché, et toute case qu'un niveau
##   de sol ne suffit pas à décrire (une porte sur une carte sans niveaux) (NO_PUSH) ;
## - un autre rocher, un PNJ, Artikodin : tout occupant (OCCUPIED) ; un panneau est solide (WALL).
## Le pousseur (le joueur, case [param boulder_cell] − [param direction]) ne pousse pas depuis l'eau
## ni depuis un autre niveau de sol (PUSHER).

enum Outcome {
	MOVED, ## Le rocher avance d'une case ([member Push.target]), le joueur le suit.
	FELL, ## Le rocher tombe dans le trou n° [member Push.hole] ([member Push.target]).
	REFUSED, ## Le rocher ne bouge pas ([member Push.refusal]).
	ON_SWITCH, ## Comme MOVED, sur l'interrupteur [member Push.switch_id] (§2.7.4).
}

enum Refusal { NONE, BAD_DIRECTION, PUSHER, WALL, LEDGE, WATER, LEVEL, NO_PUSH, OCCUPIED }


## Résultat de [method push].
class Push:
	extends RefCounted
	var outcome: Outcome = Outcome.REFUSED
	var refusal: Refusal = Refusal.NONE
	## Case visée (celle où le rocher arrive, ou le trou).
	var target: Vector2i = Vector2i.ZERO
	## Numéro du trou pour FELL (0 sinon).
	var hole: int = 0
	## Interrupteur pour ON_SWITCH (vide sinon).
	var switch_id: StringName = &""

	func _init(p_outcome: Outcome = Outcome.REFUSED, p_target: Vector2i = Vector2i.ZERO,
			p_refusal: Refusal = Refusal.NONE, p_hole: int = 0) -> void:
		outcome = p_outcome
		target = p_target
		refusal = p_refusal
		hole = p_hole

	func is_refused() -> bool:
		return outcome == Outcome.REFUSED


## Le rocher de [param boulder_cell] poussé vers [param direction].
## [param open_holes] : trou ouvert (case → numéro) ; un trou bouché n'y figure pas (sol).
## [param no_push] : cases interdites aux rochers (cases d'objets cachés…).
## [param switches] : interrupteurs (case → identifiant) ; un interrupteur déjà enfoncé y figure
## aussi (l'appelant ne repose pas un drapeau déjà posé).
static func push(grid: GridWorld, boulder_cell: Vector2i, direction: Vector2i,
		open_holes: Dictionary = {}, no_push: Dictionary = {}, switches: Dictionary = {}) -> Push:
	var target := boulder_cell + direction
	if grid == null or not Grid.is_cardinal(direction):
		return Push.new(Outcome.REFUSED, target, Refusal.BAD_DIRECTION)
	var pusher := boulder_cell - direction
	var level := grid.get_level(boulder_cell)
	if grid.is_water(pusher) or not GridWorld.levels_compatible(grid.get_level(pusher), level):
		return Push.new(Outcome.REFUSED, target, Refusal.PUSHER)
	if not grid.is_in_bounds(target) or grid.is_solid(target):
		return Push.new(Outcome.REFUSED, target, Refusal.WALL)
	if grid.is_water(target):
		return Push.new(Outcome.REFUSED, target, Refusal.WATER)
	if grid.get_ledge(target) != GridWorld.Ledge.NONE:
		return Push.new(Outcome.REFUSED, target, Refusal.LEDGE)
	if grid.get_level(target) != level:
		return Push.new(Outcome.REFUSED, target, Refusal.LEVEL)
	if no_push.has(target):
		return Push.new(Outcome.REFUSED, target, Refusal.NO_PUSH)
	if grid.is_occupied(target):
		return Push.new(Outcome.REFUSED, target, Refusal.OCCUPIED)
	if open_holes.has(target):
		return Push.new(Outcome.FELL, target, Refusal.NONE, int(open_holes[target]))
	if switches.has(target):
		var on_switch := Push.new(Outcome.ON_SWITCH, target)
		on_switch.switch_id = StringName(switches[target])
		return on_switch
	return Push.new(Outcome.MOVED, target)
