class_name EvolutionCandidate
extends RefCounted
## Un Pokémon de l'équipe qui peut évoluer à la fin d'un combat (jalon-09.md §2.3.1), rendu par
## [method Evolution.candidates], ou par une pierre ([method StoneUse.candidate], jalon 12).
## Donnée pure : rien n'a encore changé sur le Pokémon.

## Place du Pokémon dans l'équipe (la même que [member BattleEvent.party_index]).
var party_index: int = -1
## Espèce avant l'évolution.
var from_species: StringName = &""
## Espèce après l'évolution.
var into: StringName = &""
## Le joueur peut l'arrêter (ARRÊTER, retour Android) : vrai par défaut (fin de combat, inchangé) ;
## faux pour une pierre (jalon 12, T23 : le joueur l'a choisie, dossier 15 §10).
var cancellable: bool = true
## Objet qui la provoque (pierre, [method EvolutionDirector.play_item]) ; &"" en fin de combat.
var item_id: StringName = &""
## Jalon 32 (T5, échange local) : applique l'évolution à la place d'[method Evolution.evolve].
## `func() -> Dictionary` : `{pokemon, moves}` (l'individu évolué, désormais dans l'équipe, et
## les capacités à proposer), ou un dictionnaire vide si rien n'a changé. Invalide : par défaut.
var applier: Callable


func _init(index: int = -1, from: StringName = &"", target: StringName = &"") -> void:
	party_index = index
	from_species = from
	into = target
