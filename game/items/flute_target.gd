class_name FluteTarget
extends RefCounted
## Un Pokémon endormi qu'on réveille à la Poké Flûte (Ronflex, jalon 21 §2.2) : ses cases, ses
## conditions d'existence et la scène du réveil.
##
## Classe pure, sans scène. La carte en construit une par point d'examen qui porte une scène de
## Flûte ([method GameMap.flute_targets], plan) ; [PokeFluteRules] la lit.

## Cases occupées par le dormeur (2 × 2 pour Ronflex).
var cells: Array[Vector2i] = []
## Le dormeur n'existe plus si l'un de ces drapeaux est levé (`snorlax_route_11_done`…).
var unless_flags: Array[StringName] = []
## Scène jouée quand la Flûte retentit à côté de lui.
var cutscene_id: StringName = &""


## Vrai si le dormeur est encore là (aucun de ses [member unless_flags] n'est levé ; un
## [param flags] nul compte comme « aucun drapeau »).
func is_present(flags: StoryFlags) -> bool:
	return flags == null or flags.has_none(unless_flags)


## Vrai si [param cell] est l'une des 4 cases voisines (haut, bas, gauche, droite) de l'une de
## ses cases, sans être elle-même une de ses cases.
func touches(cell: Vector2i) -> bool:
	if cells.has(cell):
		return false
	for own: Vector2i in cells:
		var delta := cell - own
		if absi(delta.x) + absi(delta.y) == 1:
			return true
	return false
