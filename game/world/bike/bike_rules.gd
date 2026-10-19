class_name BikeRules
extends RefCounted
## Règles pures de la Bicyclette (docs/tech/jalon-22.md §2.1, dossier 25 §6.3 et §6.4) : monter,
## descendre, durée d'un pas, monter ou descendre à l'arrivée sur une carte. Classe statique, sans
## nœud. Les refus renvoient un code [enum Check] ; les textes (dossier 25 §16.1) sont branchés par
## l'appelant : [constant Check.INDOORS] → T-3, [constant Check.ON_CYCLING_ROAD] → T-4.
##
## Les grottes comptent comme des extérieurs (`GameMap.interior = false`) : le vélo y est permis.

enum Check { OK, NO_BIKE, INDOORS, ON_CYCLING_ROAD, BUSY }

## Durée d'un pas à vélo (0,12 s par case, dossier 25 §6.3 [D]).
## Copie locale provisoire : T14 la déplacera dans [Grid] (`Grid.BIKE_STEP_DURATION`), puis la
## retirera d'ici.
const BIKE_STEP_DURATION: float = 0.12

## Réponses de [method on_map_entered].
const ENTER_DISMOUNT: StringName = &"dismount"
const ENTER_MOUNT: StringName = &"mount"
const ENTER_NOTHING: StringName = &""


## Peut-on monter ? Bicyclette dans le Sac, carte extérieure (ou grotte), joueur libre.
## Ordre des refus : occupé, puis sans vélo, puis intérieur.
static func can_mount(has_bike: bool, map_interior: bool, busy: bool) -> Check:
	if busy:
		return Check.BUSY
	if not has_bike:
		return Check.NO_BIKE
	if map_interior:
		return Check.INDOORS
	return Check.OK


## Peut-on descendre ? Jamais sur un tronçon de Piste Cyclable.
static func can_dismount(on_cycling_road: bool, busy: bool) -> Check:
	if busy:
		return Check.BUSY
	if on_cycling_road:
		return Check.ON_CYCLING_ROAD
	return Check.OK


## Durée d'un pas selon le mode : vélo plus rapide que la course, elle-même plus rapide que la
## marche. La course est ignorée à vélo.
static func step_duration(riding: bool, run: bool) -> float:
	if riding:
		return BIKE_STEP_DURATION
	if run:
		return Grid.RUN_STEP_DURATION
	return Grid.WALK_STEP_DURATION


## À l'arrivée sur une carte : [constant ENTER_DISMOUNT] en selle dans un intérieur,
## [constant ENTER_MOUNT] à pied sur un tronçon de Piste avec la Bicyclette, sinon
## [constant ENTER_NOTHING].
static func on_map_entered(
		riding: bool, map_interior: bool, cycling_road: bool, has_bike: bool) -> StringName:
	if riding and map_interior:
		return ENTER_DISMOUNT
	if not riding and cycling_road and has_bike and not map_interior:
		return ENTER_MOUNT
	return ENTER_NOTHING
