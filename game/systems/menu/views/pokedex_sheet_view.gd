class_name PokedexSheetView
extends RefCounted
## La fiche d'une espèce **vue** (dossier 08 §4 ; jalon-06.md §3.5) : Aperçu, Habitat,
## Évolution, Observations. Construite par [method PokedexQuery.sheet] (null pour une espèce
## inconnue : une fiche inconnue n'existe pas). Contrat figé au T14 (§6.9) : on peut seulement
## ajouter des champs (architecte) ; **texte vide = élément absent**.
##
## Vue seulement : sprite, numéro, nom, habitats, compteur, évolution, notes. À la capture
## seulement : types, taille, poids, description. **Jamais** de statistiques de base, de
## talents, de silhouette ni de condition d'évolution.

## Onglets, dans l'ordre (toujours les quatre).
const TAB_LABELS: PackedStringArray = ["Aperçu", "Habitat", "Évolution", "Observations"]

var species_id: StringName = &""
var number: int = 0
## « N° 004 ».
var number_text: String = ""
## « Salamèche ».
var name: String = ""
## SEEN ou CAUGHT.
var state: PokedexQuery.State = PokedexQuery.State.SEEN
var caught: bool = false
## Aperçu, à la capture : types (TypeBadge : identifiants et noms, même ordre), « 0,6 m »,
## « 8,5 kg », description. Vides pour une espèce seulement vue.
var type_ids: Array[StringName] = []
var type_names: PackedStringArray = PackedStringArray()
var height_text: String = ""
var weight_text: String = ""
var description: String = ""
## « Vu 3 fois » ; à la capture « Vu 3 fois · capturé 1 fois ».
var counts_text: String = ""
## Habitat : zones où l'espèce a été observée, dans l'ordre de découverte.
var habitats: Array[PokedexHabitatView] = []
## Habitat vide (espèce vue hors de toute zone) : la phrase à afficher ; "" sinon.
var habitat_empty_text: String = ""
## Évolution ([EvolutionReveal], Q-9) : stades vus ou « ??? », jamais de condition ;
## vide = pas de section (lignée d'une seule espèce).
var evolution: Array[EvolutionStageView] = []
## La même chose en une ligne (« Salamèche → ??? »).
var evolution_text: String = ""
## Observations : textes des notes débloquées, dans l'ordre de déblocage.
var notes: PackedStringArray = PackedStringArray()
## Observations vides : la phrase à afficher ; "" s'il y a des notes.
var notes_empty_text: String = ""
