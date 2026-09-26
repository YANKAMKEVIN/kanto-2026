class_name BattleMoveView
extends RefCounted
## Ce qu'affiche une carte de capacité (MoveCard) et sa fiche détaillée (MoveDetailSheet) :
## des chaînes, des entiers et un identifiant de type, rien d'autre.
##
## Celui qui pilote l'interface la remplit à partir des données ; les cartes ne connaissent
## ni les capacités ni la table des types.

## Catégorie affichée dans la fiche (Physique / Spéciale / Statut) ; STATUS affiche « Statut »
## au lieu de la puissance sur la carte.
enum Category { PHYSICAL, SPECIAL, STATUS }

## Nom affiché (« Griffe » ; la carte le met en MAJUSCULES).
var display_name: String = ""
## Identifiant du type (&"normal"…, clé de UiTokens.TYPE_COLORS) : teinte, icône, pastille.
var type_id: StringName = &""
## Nom du type à afficher (« Normal »).
var type_name: String = ""
var category: Category = Category.PHYSICAL
var pp: int = 0
var max_pp: int = 0
## 0 = aucune puissance (« — » dans la fiche).
var power: int = 0
## 0 = ne rate jamais (« — » dans la fiche).
var accuracy: int = 0
## Description de la fiche (texte fourni tel quel).
var description: String = ""


func _init(
	name: String = "", type: StringName = &"", shown_type: String = "",
	kind: Category = Category.PHYSICAL, current_pp: int = 0, maximum_pp: int = 0,
	move_power: int = 0, move_accuracy: int = 0, text: String = ""
) -> void:
	display_name = name
	type_id = type
	type_name = shown_type
	category = kind
	pp = current_pp
	max_pp = maximum_pp
	power = move_power
	accuracy = move_accuracy
	description = text


## Vue affichable : un nom, un type, 0 ≤ PP ≤ PP max, PP max ≥ 1.
func is_valid() -> bool:
	return not display_name.is_empty() and type_id != &"" and max_pp >= 1 \
		and pp >= 0 and pp <= max_pp


## Encore des PP : la carte peut être choisie.
func is_usable() -> bool:
	return pp > 0
