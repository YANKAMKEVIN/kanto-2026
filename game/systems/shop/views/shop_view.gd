class_name ShopView
extends RefCounted
## Ce qu'affiche l'écran de la Boutique (dossier 09 §9, jalon-07.md §3.4, §6.4, §6.9) : l'onglet
## ouvert, l'argent, les objets de cet onglet. Construit par [method ShopViews.build] ; l'écran
## ne connaît ni GameState, ni le Sac, ni les données.
##
## Contrat figé au T10 : on peut seulement ajouter des champs. **Texte vide = élément absent.**

## Onglet ouvert : [constant ShopViews.MODE_BUY] ou [constant ShopViews.MODE_SELL].
var mode: StringName = &""
## Boutique affichée (identifiant, journaux et tests).
var shop_id: StringName = &""
## Onglets, dans l'ordre (ACHETER, VENDRE) : identifiants et libellés.
var modes: Array[StringName] = []
var mode_labels: PackedStringArray = PackedStringArray()
## Argent du joueur : « 3 000 ₽ ».
var money_text: String = ""
## Objets de l'onglet, dans l'ordre : stock de la boutique (ACHETER), ordre des données des
## objets vendables du Sac (VENDRE).
var entries: Array[ShopEntryView] = []
## Phrase d'un onglet sans objet (VENDRE avec un Sac sans rien de vendable) ; vide sinon.
var empty_text: String = ""


func is_empty() -> bool:
	return entries.is_empty()


## Vue de l'objet [param item_id] dans l'onglet, ou null.
func entry(item_id: StringName) -> ShopEntryView:
	for found: ShopEntryView in entries:
		if found.item_id == item_id:
			return found
	return null
