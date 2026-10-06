class_name BagView
extends RefCounted
## Ce qu'affiche l'écran Sac du menu (dossier 08 §3, jalon-06.md §3.4) : les objets, les
## onglets, l'onglet d'ouverture, le tri. Construit par [method BagQuery.view] ; l'écran ne
## connaît ni le Sac ni les données. Contrat figé au T10 (§6.8) : on peut seulement ajouter des
## champs ; **texte vide = élément absent**.

## Contexte d'ouverture ([constant BagQuery.CONTEXT_FIELD] ou [constant BagQuery.CONTEXT_TEAM]).
var context: StringName = &""
## Tous les objets listés, triés selon [member sort] ; chacun une seule fois, sous son
## [member BagEntryView.category_id].
var entries: Array[BagEntryView] = []
## Rangée FAVORIS (objets favoris présents dans le Sac) : les mêmes vues que dans
## [member entries] ; en « pertinence », dans l'ordre où ils ont été marqués.
var favorites: Array[BagEntryView] = []
## Onglets dans l'ordre (FAVORIS s'il y en a, SOINS, CAPTURE, COMBAT, AVENTURE, OBJETS CLÉS) ;
## un onglet vide n'y est pas.
var categories: Array[StringName] = []
## Onglet ouvert à l'arrivée (&"" si le Sac est vide).
var start_category: StringName = &""
## Tri ([enum BagQuery.Sort]) et noms des tris, dans l'ordre de l'enum (« Pertinence »…).
var sort: int = 0
var sort_labels: PackedStringArray = PackedStringArray()
## Phrase d'un Sac sans objet à montrer (« Ton Sac est vide. ») ; vide si des objets existent.
var empty_text: String = ""
## Depuis la fiche Équipe : place du Pokémon visé (UTILISER s'applique à lui, sans choix) ;
## −1 sinon.
var target_index: int = -1
## Depuis la fiche Équipe : son nom (« Salamèche »), vide sinon.
var target_name: String = ""
## Argent du joueur, « 3 000 ₽ » (J7, dossier 09 §10) ; vide = non affiché.
var money_text: String = ""


func is_empty() -> bool:
	return entries.is_empty()


## Objets de l'onglet [param category] ([constant BagQuery.FAVORITES] compris), dans l'ordre.
func entries_in(category: StringName) -> Array[BagEntryView]:
	if category == BagQuery.FAVORITES:
		return favorites.duplicate()
	var found: Array[BagEntryView] = []
	for entry: BagEntryView in entries:
		if entry.category_id == category:
			found.append(entry)
	return found


## Vue de l'objet [param item_id], ou null.
func entry(item_id: StringName) -> BagEntryView:
	for found: BagEntryView in entries:
		if found.item_id == item_id:
			return found
	return null


## Nom affiché de l'onglet [param category] (« SOINS », « FAVORIS »).
func category_label(category: StringName) -> String:
	return BagEntryView.category_label(category)
