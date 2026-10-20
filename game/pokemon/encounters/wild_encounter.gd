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
## Combat SPECTRE (jalon 19, dossier 22 §6) : décidé au moment du tirage par
## [method GhostRule.is_ghost] (clé [member EncounterTable.ghost_unless_item] et Sac du moment),
## jamais par la table seule. Faux par défaut. L'espèce réelle reste dans [member species] :
## elle n'est jamais montrée (masque [GhostDisguise]).
var ghost: bool = false
## Entrée en scène « légendaire » (passe systèmes 2, T30 : clé « intro » de l'étape de scène
## « wild_battle ») : plus lente ([constant BattleStage.LEGENDARY_INTRO_SLOWDOWN]). Faux par défaut.
var legendary_intro: bool = false


func _init(encounter_species: StringName = &"", encounter_level: int = 1,
		source_table: StringName = &"") -> void:
	species = encounter_species
	level = encounter_level
	table_id = source_table
