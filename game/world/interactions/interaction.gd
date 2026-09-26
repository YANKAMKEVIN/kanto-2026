class_name Interaction
extends RefCounted
## Ce qu'on peut faire avec la case devant le joueur : parler, examiner, observer.
##
## Donnée pure (docs/tech/jalon-03.md §2.2). Deux origines :
## - un PNJ ou un Pokémon du décor (source = l'entité, qui occupe sa case dans la grille) :
##   il tient une instance à jour et la renvoie par [code]get_interaction()[/code] ;
## - un point fixe de la carte (`InteractPoint` : table, carte de Kanto, panneau), rangé
##   dans une [InteractionTable].
## [member facing] = orientation exigée du joueur (ZERO = de n'importe quel côté).

## Verbe du bouton contextuel : Parler / Examiner / Observer.
enum Kind { TALK, EXAMINE, OBSERVE }

var kind: Kind = Kind.EXAMINE
var cell: Vector2i = Vector2i.ZERO
var dialogue_id: StringName = &""
var facing: Vector2i = Vector2i.ZERO
## Entité à l'origine (PNJ, Pokémon) ; null pour un point fixe.
var source: Object = null


func _init(
	interaction_kind: Kind = Kind.EXAMINE,
	at_cell: Vector2i = Vector2i.ZERO,
	dialogue: StringName = &"",
	required_facing: Vector2i = Vector2i.ZERO,
	from_source: Object = null
) -> void:
	kind = interaction_kind
	cell = at_cell
	dialogue_id = dialogue
	facing = required_facing
	source = from_source


## Dialogue renseigné, orientation nulle ou cardinale.
func is_valid() -> bool:
	if dialogue_id.is_empty():
		return false
	return facing == Vector2i.ZERO or Grid.is_cardinal(facing)


## Vrai si un joueur orienté vers [param player_facing] peut l'utiliser.
func accepts(player_facing: Vector2i) -> bool:
	return facing == Vector2i.ZERO or facing == player_facing


## Nom du verbe (« talk », « examine », « observe ») : données et HUD.
static func kind_name(value: Kind) -> StringName:
	match value:
		Kind.TALK:
			return &"talk"
		Kind.OBSERVE:
			return &"observe"
	return &"examine"


## Verbe à partir de son nom ; -1 si inconnu.
static func kind_from_name(value: String) -> int:
	match value:
		"talk":
			return Kind.TALK
		"examine":
			return Kind.EXAMINE
		"observe":
			return Kind.OBSERVE
	return -1
