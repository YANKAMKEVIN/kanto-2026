class_name ShopData
extends RefCounted
## Une boutique, lue dans `data/shops/*.json` par [ShopLibrary] (dossier 09 §9, jalon-07.md
## §3.4). Donnée pure.
##
## Son stock évolue avec la progression : chaque objet a ses conditions « if » (drapeaux tous
## levés) et « unless » (aucun levé), comme les variantes de dialogue. Jamais un objet pour une
## mécanique absente (dossier 09 §9) : c'est aux données de ne pas le proposer. Les prix sont
## ceux des objets ([member ItemData.price]), les mêmes dans toutes les boutiques.

var id: StringName = &""
## Le stock, dans l'ordre d'affichage : { "item": StringName, "if": Array[StringName],
## "unless": Array[StringName] }.
var stock: Array[Dictionary] = []
## Fichier d'origine (messages d'erreur).
var source: String = ""


## Identifiants du stock, toutes conditions confondues, dans l'ordre des données.
func item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: Dictionary in stock:
		ids.append(entry["item"])
	return ids
