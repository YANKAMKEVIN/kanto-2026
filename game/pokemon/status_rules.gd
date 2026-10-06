class_name StatusRules
extends RefCounted
## Statuts durables des Pokémon (jalon 9 §2.1.1) : classe statique et pure.
##
## Un statut est un identifiant ([member Pokemon.status]) ; [constant NONE] = aucun. Un seul
## statut à la fois. Jalon 9 : le poison seul. T2 (sauvegarde v4) ne pose que le vocabulaire
## ([constant KNOWN]) ; les règles du poison (dégâts de fin de tour, immunités, capture)
## arrivent au T4, le J11 ajoute ses statuts à [constant KNOWN] sans toucher au modèle.

const NONE: StringName = &""
const POISON: StringName = &"poison"
## Statuts connus de cette build (sauvegarde, départs de débogage, effets de capacité).
const KNOWN: Array[StringName] = [POISON]


## Vrai si [param id] est un statut connu ([constant NONE] n'en est pas un).
static func is_known(id: StringName) -> bool:
	return KNOWN.has(id)
