class_name TrainerSlot
extends RefCounted
## Un Pokémon de l'équipe d'un dresseur ([TrainerData]). Donnée pure.

var species: StringName = &""
var level: int = 1
## Capacités choisies à la main (1 à 4, distinctes, connues de [PokemonData]), dans l'ordre ;
## vide = celles de Rouge/Bleu au niveau ([PokemonFactory]). Dossier 12 §2 (Pierre).
var moves: Array[StringName] = []
