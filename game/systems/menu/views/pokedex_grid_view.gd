class_name PokedexGridView
extends RefCounted
## L'écran principal du Pokédex (dossier 08 §4 ; jalon-06.md §3.5) : en-tête, compteur,
## filtres, grille. Construit par [method PokedexQuery.grid] ; l'écran ne connaît ni le
## Pokédex ni les données. Contrat figé au T14 (§6.9) : on peut seulement ajouter des champs
## (architecte) ; **texte vide = élément absent**.

## « POKÉDEX — KANTO ».
var title: String = ""
## « 3 vus · 2 capturés · 151 espèces » (jamais « 3 / 151 »).
var counts_text: String = ""
## Filtre actif ([enum PokedexQuery.Filter], mêmes valeurs que `MenuRoute.DEX_FILTER_*`).
var filter: int = 0
## Libellés des filtres, dans l'ordre de l'enum : TOUS, VUS, CAPTURÉS, HABITATS.
var filter_labels: PackedStringArray = PackedStringArray()
## Filtre HABITATS : zone choisie (&"" hors de ce filtre, ou si aucune zone n'est connue).
var zone: StringName = &""
## Zones proposées par le filtre HABITATS (celles où au moins une espèce a été observée,
## dans l'ordre de `zones.json`, celui du voyage) : identifiants et noms, même ordre.
var zone_ids: Array[StringName] = []
var zone_names: PackedStringArray = PackedStringArray()
## Filtre par type (&"" = aucun). Types proposés : ceux des espèces **capturées** (le type
## d'une espèce seulement vue n'est pas connu), identifiants et noms, même ordre.
var type: StringName = &""
var type_ids: Array[StringName] = []
var type_names: PackedStringArray = PackedStringArray()
## Recherche par nom (espèces connues seulement), telle que saisie.
var text: String = ""
## Cases à afficher, par numéro. Filtre TOUS sans type ni recherche : les 151 cases (inconnues
## comprises) ; sinon, seulement les espèces connues qui correspondent.
var slots: Array[PokedexSlotView] = []
## Espèce dont la fiche s'affiche à l'arrivée : celle de la route si elle est connue, sinon
## la première espèce connue de la grille ; &"" = aucune.
var selected: StringName = &""
## Phrase d'une grille vide (« Aucune espèce ne correspond. ») ; "" si la grille a des cases.
var empty_text: String = ""
## Pokédex sans aucune espèce vue (débogage seulement) : la phrase du centre et de la droite
## (« Aucune espèce enregistrée. ») ; "" sinon.
var no_species_text: String = ""


func is_empty() -> bool:
	return slots.is_empty()


## Case de [param species_id], ou null (jamais une case inconnue).
func slot(species_id: StringName) -> PokedexSlotView:
	if species_id.is_empty():
		return null
	for found: PokedexSlotView in slots:
		if found.species_id == species_id:
			return found
	return null
