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
## Scène enchaînée à la fin de celle-ci (jalon 13 §2.9, clé « next ») ; &"" = aucune. Boot
## écrit la sauvegarde entre les deux, puis joue la suivante si une de ses variantes s'applique.
var next: StringName = &""


## Première variante qui s'applique à [param flags], ou null si aucune.
func pick(flags: StoryFlags) -> CutsceneVariant:
	for variant: CutsceneVariant in variants:
		if variant.matches(flags):
			return variant
	return null


## Capacité de terrain (« cut ») par laquelle commence la variante jouée pour [param flags]
## (jalon 16 : le compagnon qui coupe reste dehors) ; &"" si elle commence autrement.
func leading_field_move(flags: StoryFlags) -> StringName:
	var variant := pick(flags)
	if variant == null:
		return &""
	for step: CutsceneStep in variant.steps:
		if step.applies(flags):
			return step.field_move if step.kind == CutsceneStep.Kind.FIELD_MOVE else &""
	return &""


## Vrai si une variante s'applique à [param flags].
func matches(flags: StoryFlags) -> bool:
	return pick(flags) != null


## Alias d'acteurs utilisés par toutes les variantes (sans « $ », triés) : ceux que le code
## qui lance la scène doit fournir (jalon 4 §3.6).
func get_aliases() -> Array[StringName]:
	var found: Array[StringName] = []
	for variant: CutsceneVariant in variants:
		for step: CutsceneStep in variant.steps:
			for alias: StringName in step.get_aliases():
				if not found.has(alias):
					found.append(alias)
	found.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return found
