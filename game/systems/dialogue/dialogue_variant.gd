class_name DialogueVariant
extends RefCounted
## Une version d'un dialogue : ses pages et les drapeaux qui la conditionnent.
##
## Donnée pure, construite par [DialogueLibrary] à partir des fichiers de `data/dialogues/`.
## Elle s'applique si tous les drapeaux de [member if_flags] sont levés et aucun de
## [member unless_flags] ; [member set_flags] sont levés à la fin du dialogue
## (docs/tech/jalon-03.md §2.4). Une variante [member auto] se joue d'elle-même quand le
## joueur arrive sur la carte du PNJ (premier dialogue de Maman).

var pages: Array[DialoguePage] = []
var if_flags: Array[StringName] = []
var unless_flags: Array[StringName] = []
var set_flags: Array[StringName] = []
## Se déclenche à l'arrivée du joueur sur la carte du PNJ, si la variante s'applique.
var auto: bool = false


## Vrai si la variante s'applique avec les drapeaux [param flags] (null = aucun drapeau).
func matches(flags: StoryFlags) -> bool:
	if flags == null:
		return if_flags.is_empty()
	return flags.has_all(if_flags) and flags.has_none(unless_flags)


## Vrai si la variante ne dépend d'aucun drapeau.
func is_unconditional() -> bool:
	return if_flags.is_empty() and unless_flags.is_empty()
