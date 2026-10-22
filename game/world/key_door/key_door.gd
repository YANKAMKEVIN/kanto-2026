class_name KeyDoor
extends FlagGate
## Porte à carte (passe systèmes 2, `docs/tech/systemes-2.md` §2.10, T28) : un [FlagGate] qui
## occupe [member blocking_cells] tant que le drapeau [method get_open_flag] n'est pas levé.
## Face à la porte, le bouton contextuel montre OUVRIR (un [InteractPoint] de
## [constant Interaction.Kind.OPEN] posé sur chaque case de la porte par l'outil de
## construction, retiré par le même drapeau) ; [KeyDoorDirector] ouvre avec [member key_item]
## (gardée : une seule carte ouvre toutes les portes, pour toujours [D, RB]) ou joue
## [member locked_dialogue].
##
## Posée par les outils de construction : [member unless_flags] = [`door_<carte>_<id>_open`]
## ([method open_flag]).

## Dialogue joué sans la clé (« Il faut une carte. » [D]).
const LOCKED_DIALOGUE: StringName = &"key_door_locked"

## Identifiant de la porte dans sa carte (`ab`, `bd`…).
@export var door_id: StringName = &""
## Objet clé qui ouvre la porte (gardé dans le Sac).
@export var key_item: StringName = &"card_key"
@export var locked_dialogue: StringName = LOCKED_DIALOGUE


## Drapeau d'ouverture de la porte [param door] de la carte [param map_id].
static func open_flag(map_id: StringName, door: StringName) -> StringName:
	return StringName("door_%s_%s_open" % [map_id, door])


## Drapeau qui ouvre cette porte : le premier de [member unless_flags] (posé par l'outil).
func get_open_flag() -> StringName:
	return unless_flags[0] if not unless_flags.is_empty() else &""


## Vrai si [param cell] est une case de la porte.
func covers(cell: Vector2i) -> bool:
	return blocking_cells.has(cell)


## Ce que fait un appui OUVRIR : rien (déjà ouverte), ouverture (clé dans le Sac) ou refus.
enum Outcome { NONE, OPEN, LOCKED }


static func decide(already_open: bool, has_key: bool) -> Outcome:
	if already_open:
		return Outcome.NONE
	return Outcome.OPEN if has_key else Outcome.LOCKED
