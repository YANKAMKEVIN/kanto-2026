class_name AwakeningResult
extends RefCounted
## Ce que le Réveil a fait à **un** Pokémon ([method StoneAwakening.apply] ; dossier JOH-11 §13).
## Donnée pure : l'écran ([AwakeningOverlay]) la montre, rien ici n'est sauvegardé.

## Le Pokémon réveillé (déjà à jour : l'instance de l'équipe ou du Stockage).
var pokemon: Pokemon
## Place dans l'équipe ; −1 pour le Stockage.
var party_index: int = -1
## Vrai pour une capture du Stockage (JH-71) : ni plan ni attaques à choisir.
var stored: bool = false
## Titre de sa ligne à l'écran : son nom, ou « Chenipan → Papilusion ».
var title: String = ""
var level_before: int = 0
var level_after: int = 0
var species_before: StringName = &""
## Espèces traversées, dans l'ordre (vide : pas d'évolution ; Chenipan : Chrysacier, Papilusion).
var chain: Array[StringName] = []
## Niveau du palier de chaque évolution de [member chain] (même longueur, croissant) : là où le
## compteur s'arrête à l'écran.
var stage_levels: Array[int] = []
## Attaques à proposer à l'écran, du niveau le plus bas au plus haut (au plus
## [constant StoneAwakening.OFFERED_MOVES]) : pas encore apprises, rien n'est imposé.
var new_moves: Array[StringName] = []


## Espèce à l'arrivée.
func species_after() -> StringName:
	return chain[chain.size() - 1] if not chain.is_empty() else species_before


func evolved() -> bool:
	return not chain.is_empty()
