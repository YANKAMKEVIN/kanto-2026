class_name Dialogue
extends RefCounted
## Dialogue d'un PNJ, texte d'un objet examiné ou d'un Pokémon observé.
##
## Donnée pure, construite par [DialogueLibrary]. [method pick] renvoie la **première**
## variante qui s'applique aux drapeaux d'histoire : on écrit les cas particuliers d'abord,
## le cas général (sans condition) en dernier (docs/tech/jalon-03.md §2.4).

var id: StringName = &""
## Nom affiché dans l'étiquette (« Maman », « Maya », « Bulbizarre ») ; vide = pas
## d'étiquette (objets examinés).
var speaker: String = ""
## Texte de narration (examiner, observer) : style distinct de la parole (italique).
var narration: bool = false
## Texte provisoire, à remplacer par un texte de Kevin (sans effet en jeu).
var draft: bool = false
## Fichier d'origine (messages d'erreur).
var source: String = ""
var variants: Array[DialogueVariant] = []


## Première variante qui s'applique à [param flags], ou null si aucune.
func pick(flags: StoryFlags) -> DialogueVariant:
	for variant: DialogueVariant in variants:
		if variant.matches(flags):
			return variant
	return null
