class_name EvolutionStageView
extends RefCounted
## Un stade de la lignée dans la fiche Équipe (jalon-06.md §3.3, Q-9) : construit par
## [EvolutionReveal]. Contrat figé au T6.
##
## Anti-spoiler (Q-9, décision verrouillée) : un stade inconnu n'a **ni nom, ni espèce**
## ([member species_id] vide, [member name] = [constant UNKNOWN_NAME], [member known] faux).
## Aucun champ ne porte de condition (niveau, objet) : il n'y en a pas.
##
## Silhouette (refonte du Pokédex, Q-1 de Kevin, 2026-10-06) : un stade inconnu porte quand
## même son [member number], pour que le Pokédex dessine sa **silhouette**
## ([method PokedexArt.thumbnail] + [method PokedexArt.silhouette_material]) ; jamais son
## artwork en couleur. [member number] vaut 0 quand le stade ne désigne pas une seule espèce
## (colonne de branches toutes inconnues, lignée avant l'activation du Pokédex) : rond vide.

## Ce qu'affiche un stade inconnu.
const UNKNOWN_NAME: String = "???"

## Colonne de la lignée (0 = forme de base). Deux stades de la même colonne sont des branches
## (« Aquali / Voltali ») ; l'écran les sépare par « / » et les colonnes par « → ».
var step: int = 0
## Numéro du Pokédex (artwork, ou silhouette si [member known] est faux) ; 0 si aucun.
var number: int = 0
## Espèce (sprite) ; &"" si le stade est inconnu.
var species_id: StringName = &""
## « Salamèche », ou « ??? ».
var name: String = UNKNOWN_NAME
## Faux pour un stade inconnu : « ??? », silhouette (si [member number]) ou rond vide.
var known: bool = false
## Le stade du Pokémon de la fiche (mis en valeur).
var current: bool = false


func _init(column: int = 0, species: StringName = &"", shown_name: String = UNKNOWN_NAME,
		is_current: bool = false, dex_number: int = 0) -> void:
	step = column
	number = dex_number
	species_id = species
	known = not species.is_empty()
	name = shown_name if known else UNKNOWN_NAME
	current = is_current and known
