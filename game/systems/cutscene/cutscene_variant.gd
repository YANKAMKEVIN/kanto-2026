class_name CutsceneVariant
extends RefCounted
## Une version d'une scène : ses étapes et les drapeaux qui la conditionnent, comme une
## [DialogueVariant] (docs/tech/jalon-03b.md §2.3).
##
## Elle s'applique si tous les drapeaux de [member if_flags] sont levés et aucun de
## [member unless_flags]. Une même case de déclencheur joue ainsi l'interception de Chen la
## première fois, puis la pensée du joueur tant qu'il n'a pas de Pokémon.

var if_flags: Array[StringName] = []
var unless_flags: Array[StringName] = []
var steps: Array[CutsceneStep] = []


## Vrai si la variante s'applique avec les drapeaux [param flags] (null = aucun drapeau).
func matches(flags: StoryFlags) -> bool:
	if flags == null:
		return if_flags.is_empty()
	return flags.has_all(if_flags) and flags.has_none(unless_flags)
