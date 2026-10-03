class_name EvolutionStageView
extends RefCounted
## Un stade de la lignée dans la fiche Équipe (jalon-06.md §3.3, Q-9) : construit par
## [EvolutionReveal]. Contrat figé au T6.
##
## Anti-spoiler (Q-9, décision verrouillée) : un stade inconnu n'a **ni nom, ni espèce, ni
## image** ([member species_id] vide, [member name] = [constant UNKNOWN_NAME]). Aucun champ ne
## porte de condition (niveau, objet) : il n'y en a pas.

## Ce qu'affiche un stade inconnu.
const UNKNOWN_NAME: String = "???"

## Colonne de la lignée (0 = forme de base). Deux stades de la même colonne sont des branches
## (« Aquali / Voltali ») ; l'écran les sépare par « / » et les colonnes par « → ».
var step: int = 0
## Espèce (sprite) ; &"" si le stade est inconnu.
var species_id: StringName = &""
## « Salamèche », ou « ??? ».
var name: String = UNKNOWN_NAME
var known: bool = false
## Le stade du Pokémon de la fiche (mis en valeur).
var current: bool = false


func _init(column: int = 0, species: StringName = &"", shown_name: String = UNKNOWN_NAME,
		is_current: bool = false) -> void:
	step = column
	species_id = species
	known = not species.is_empty()
	name = shown_name if known else UNKNOWN_NAME
	current = is_current and known
