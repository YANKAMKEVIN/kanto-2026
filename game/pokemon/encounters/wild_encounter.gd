class_name WildEncounter
extends RefCounted
## Le résultat d'un tirage de rencontre : l'espèce et le niveau du Pokémon sauvage à créer,
## avec la table d'origine (jalon 5 §2.2). Donnée pure.
##
## L'[EncounterDirector] passe ceci à [method BattleRequest.wild], qui crée le Pokémon par
## [method PokemonFactory.create].

var species: StringName = &""
var level: int = 1
## Identifiant de la table qui a produit ce tirage (traçabilité, tests).
var table_id: StringName = &""


func _init(encounter_species: StringName = &"", encounter_level: int = 1,
		source_table: StringName = &"") -> void:
	species = encounter_species
	level = encounter_level
	table_id = source_table
