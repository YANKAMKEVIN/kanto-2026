class_name PokedexSlotView
extends RefCounted
## Une case de la grille du Pokédex (dossier 08 §4 ; jalon-06.md §3.5). Construite par
## [PokedexQuery]. Contrat figé au T14 (§6.9) : on peut seulement ajouter des champs
## (architecte).
##
## Anti-spoiler : une case **inconnue** n'a que son numéro et « ??? » : ni espèce, ni nom
## ([member species_id] vide). Refonte du Pokédex (décision D2 de Kevin) : l'écran en dessine
## la **silhouette** depuis le seul [member number] ([method PokedexArt.thumbnail] +
## [method PokedexArt.silhouette_material]), sans jamais connaître l'espèce.

## Ce qu'affiche une case inconnue.
const UNKNOWN_NAME: String = "???"

## Numéro du Pokédex (1 à 151).
var number: int = 0
## « 004 ».
var number_text: String = ""
## Espèce (sprite, `PokedexScreen.species_opened`) ; &"" si inconnue.
var species_id: StringName = &""
## « Salamèche », ou « ??? ».
var name: String = UNKNOWN_NAME
## [enum PokedexQuery.State] : UNKNOWN, SEEN, CAUGHT.
var state: PokedexQuery.State = PokedexQuery.State.UNKNOWN
## Capturé (l'écran le signale par un symbole **et** un texte, jamais une couleur seule).
var caught: bool = false


func _init(dex_number: int = 0, species: StringName = &"", shown_name: String = "",
		slot_state: PokedexQuery.State = PokedexQuery.State.UNKNOWN) -> void:
	number = dex_number
	number_text = "%03d" % dex_number
	if species.is_empty() or slot_state == PokedexQuery.State.UNKNOWN:
		return
	species_id = species
	name = shown_name
	state = slot_state
	caught = slot_state == PokedexQuery.State.CAUGHT


## Vrai si la case est inconnue (aucune image, aucun toucher).
func is_unknown() -> bool:
	return species_id.is_empty()
