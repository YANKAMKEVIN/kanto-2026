class_name Cutscene
extends RefCounted
## Scène scriptée : une liste d'étapes jouées dans l'ordre, sans embranchement ni
## parallélisme, en une ou plusieurs variantes (docs/tech/jalon-03b.md §2.3).
##
## Donnée pure, construite par [CutsceneLibrary]. [method pick] renvoie la **première**
## variante qui s'applique aux drapeaux d'histoire (même règle que les dialogues) ; aucune =
## la scène ne fait rien (déclencheur « désarmé »).

var id: StringName = &""
## Fichier d'origine (messages d'erreur).
var source: String = ""
var variants: Array[CutsceneVariant] = []


## Première variante qui s'applique à [param flags], ou null si aucune.
func pick(flags: StoryFlags) -> CutsceneVariant:
	for variant: CutsceneVariant in variants:
		if variant.matches(flags):
			return variant
	return null


## Vrai si une variante s'applique à [param flags].
func matches(flags: StoryFlags) -> bool:
	return pick(flags) != null
