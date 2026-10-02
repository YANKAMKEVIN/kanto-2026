class_name BagEntryView
extends RefCounted
## Ce qu'affiche le panneau du Sac (BattleBagPanel) pour un objet : des chaînes, des entiers et
## une texture, rien d'autre. Celui qui pilote l'interface la remplit à partir du Sac et des
## données ; le panneau ne connaît ni les objets ni les règles du combat.
##
## [member usable] : l'objet peut servir maintenant. Un objet inutilisable (la Potion au
## jalon 5 : son usage arrive au jalon 6) n'est jamais affiché : pas de bouton grisé pour une
## fonction absente (dossier 08, règle 8).

## Dossier des illustrations : une par identifiant d'objet (« poke_ball.svg »).
const ICON_DIR := "res://assets/ui/icons/items/"
## Illustration d'un objet qui n'a pas encore la sienne : la Poké Ball serait trompeuse, on
## prend le sac.
const GENERIC_ICON: Texture2D = preload("res://assets/ui/icons/battle/bag.svg")
## Nom affiché de chaque catégorie (onglets du Sac) ; les identifiants sont ceux des données.
const CATEGORY_LABELS: Dictionary[StringName, String] = {
	&"ball": "CAPTURE",
	&"heal": "SOINS",
}
## Verbe de l'action selon la catégorie ; UTILISER pour le reste.
const ACTION_LABELS: Dictionary[StringName, String] = {
	&"ball": "LANCER",
}
const DEFAULT_ACTION := "UTILISER"

var item_id: StringName = &""
## Nom accordé à la quantité (« Poké Ball » ou « Poké Balls »).
var display_name: String = ""
var quantity: int = 0
var description: String = ""
## Identifiant de catégorie (&"ball", &"heal"…) : onglet sous lequel l'objet se range.
var category_id: StringName = &""
var usable: bool = true
## Verbe du bouton d'action (« LANCER ») ; la catégorie en donne un par défaut.
var action_label: String = ""
## Illustration ; null = celle de [method icon_for].
var icon: Texture2D = null


func _init(
	id: StringName = &"", name: String = "", count: int = 0, text: String = "",
	category: StringName = &"", can_use: bool = true
) -> void:
	item_id = id
	display_name = name
	quantity = count
	description = text
	category_id = category
	usable = can_use
	action_label = action_label_for(category)


## Une vue affichable : identifiant, nom, catégorie, au moins un exemplaire, utilisable.
func is_displayable() -> bool:
	return item_id != &"" and not display_name.is_empty() and category_id != &"" \
		and quantity >= 1 and usable


## « ×12 ».
func quantity_text() -> String:
	return "×%d" % quantity


## Illustration à montrer : la sienne, sinon le fichier de l'objet, sinon l'illustration neutre.
func get_icon() -> Texture2D:
	return icon if icon != null else icon_for(item_id)


## Illustration de l'objet [param id] (fichier du même nom dans [constant ICON_DIR]).
static func icon_for(id: StringName) -> Texture2D:
	var path := ICON_DIR + String(id) + ".svg"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return GENERIC_ICON


## Nom de l'onglet de la catégorie [param category] (l'identifiant en majuscules si inconnue).
static func category_label(category: StringName) -> String:
	return CATEGORY_LABELS.get(category, String(category).to_upper())


## Verbe de l'action pour la catégorie [param category].
static func action_label_for(category: StringName) -> String:
	return ACTION_LABELS.get(category, DEFAULT_ACTION)
