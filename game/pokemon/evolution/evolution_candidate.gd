class_name EvolutionCandidate
extends RefCounted
## Un Pokémon de l'équipe qui peut évoluer à la fin d'un combat (jalon-09.md §2.3.1), rendu par
## [method Evolution.candidates]. Donnée pure : rien n'a encore changé sur le Pokémon.

## Place du Pokémon dans l'équipe (la même que [member BattleEvent.party_index]).
var party_index: int = -1
## Espèce avant l'évolution.
var from_species: StringName = &""
## Espèce après l'évolution.
var into: StringName = &""


func _init(index: int = -1, from: StringName = &"", target: StringName = &"") -> void:
	party_index = index
	from_species = from
	into = target
