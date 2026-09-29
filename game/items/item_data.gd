class_name ItemData
extends RefCounted
## Un objet du Sac, lu dans `data/items/*.json` par [ItemLibrary] (jalon-04.md §14.6,
## jalon-05.md §2.4). Donnée pure.
##
## Le nom et son accord servent aux textes d'interface : « Poké Balls ×5 » et
## « Ajoutées au Sac » (toast, bible UI §6) sont formés ici, jamais recopiés dans le code
## qui donne l'objet.

## Catégories d'objets. `heal` (jalon 5) : la Potion cachée de la Route 1 est seulement
## ramassée et rangée au jalon 5 ; son usage (soin) viendra avec le Sac au jalon 6.
enum Category { BALL, HEAL }

## Nom de chaque catégorie dans les fichiers, dans l'ordre de [enum Category].
const CATEGORY_NAMES: Array[String] = ["ball", "heal"]
## Texte du toast après l'ajout au Sac (bible UI §6 : « Potion ×1 — Ajoutée au Sac »).
const ADDED_BASE := "Ajouté"
const ADDED_SUFFIX := " au Sac"

var id: StringName = &""
## Nom au singulier (« Poké Ball ») et au pluriel (« Poké Balls »).
var name: String = ""
var plural: String = ""
## Nom féminin (accord de « Ajoutée »).
var feminine: bool = false
var category: Category = Category.BALL
## Multiplicateur de capture (Poké Ball : 1 ; catégorie BALL seulement).
var catch_bonus: float = 1.0
## Description (fiche du Sac, jalon 5), texte provisoire tant que [member draft].
var description: String = ""
var draft: bool = false
## Fichier d'origine (messages d'erreur).
var source: String = ""


## Nom accordé à [param count] : singulier pour 1, pluriel au-delà.
func name_for(count: int) -> String:
	return name if count <= 1 else plural


## « Poké Balls ×5 », « Poké Ball ×1 ».
func quantity_text(count: int) -> String:
	return "%s ×%d" % [name_for(count), count]


## « Ajoutée au Sac », « Ajoutées au Sac », « Ajouté au Sac »… accordé au genre du nom et à
## [param count].
func added_text(count: int) -> String:
	return ADDED_BASE + ("e" if feminine else "") + ("s" if count > 1 else "") + ADDED_SUFFIX
