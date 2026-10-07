class_name Interaction
extends RefCounted
## Ce qu'on peut faire avec la case devant le joueur : parler, examiner, observer,
## rencontrer (un starter, jalon 4).
##
## Donnée pure (docs/tech/jalon-03.md §2.2). Deux origines :
## - un PNJ ou un Pokémon du décor (source = l'entité, qui occupe sa case dans la grille) :
##   il tient une instance à jour et la renvoie par [code]get_interaction()[/code] ;
## - un point fixe de la carte (`InteractPoint` : table, carte de Kanto, panneau), rangé
##   dans une [InteractionTable].
## [member facing] = orientation exigée du joueur (ZERO = de n'importe quel côté).
## [constant Kind.MEET] (« Rencontrer », jalon 4 §2.1) ne joue pas de dialogue : le
## contrôleur d'interactions signale la rencontre et le code du choix du starter s'en charge.
## Elle est posée par le code sur un PNJ (surcharge), jamais écrite dans les données.

## Verbe du bouton contextuel : Parler / Examiner / Observer / Rencontrer / Prendre
## ([constant Kind.TAKE] : objet visible au sol, jalon 8 §2.3, porté par un PNJ). Nouvelles
## valeurs en fin d'enum (les scripts d'outil écrivent les valeurs dans les cartes).
enum Kind { TALK, EXAMINE, OBSERVE, MEET, TAKE }

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


## Orientation nulle ou cardinale ; dialogue renseigné, sauf MEET : pas de dialogue, mais
## une [member source] (le PNJ rencontré) obligatoire.
func is_valid() -> bool:
	if kind == Kind.MEET:
		if source == null or not dialogue_id.is_empty():
			return false
	elif dialogue_id.is_empty():
		return false
	return facing == Vector2i.ZERO or Grid.is_cardinal(facing)


## Vrai si un joueur orienté vers [param player_facing] peut l'utiliser.
func accepts(player_facing: Vector2i) -> bool:
	return facing == Vector2i.ZERO or facing == player_facing


## Nom du verbe (« talk », « examine », « observe », « meet », « take ») : données, HUD.
static func kind_name(value: Kind) -> StringName:
	match value:
		Kind.TALK:
			return &"talk"
		Kind.OBSERVE:
			return &"observe"
		Kind.MEET:
			return &"meet"
		Kind.TAKE:
			return &"take"
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
		"meet":
			return Kind.MEET
		"take":
			return Kind.TAKE
	return -1
