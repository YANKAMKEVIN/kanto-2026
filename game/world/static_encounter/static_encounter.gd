class_name StaticEncounter
extends RefCounted
## Rencontre légendaire fixe (passe systèmes 2, `docs/tech/systemes-2.md` §0.4 Q-6, T30 ;
## politique d'Artikodin, `jalon-24.md` §2.7) : pur. Artikodin (J24), Sulfura (J29), Mewtwo (J31),
## Électhor plus tard.
##
## - Le Pokémon est visible tant que [member done_flag] n'est pas posé ([method is_present]).
## - Issues du combat ([enum Battle.Outcome]) : capture → [member done_flag] et
##   [member caught_flag] ; K.O. → [member done_flag] ; fuite, défaite, fuite du sauvage → rien
##   (on peut revenir).
## - Une issue qui pose des drapeaux demande une **sauvegarde forcée** à la sortie du combat,
##   avant le premier texte ([method needs_forced_save]).
##
## Branchement (après la fusion du J20, qui modifie les étapes de scène) : l'étape `wild_battle`
## reçoit les drapeaux de [method flags_for] ; l'acteur de la carte se cache si absent.

var id: StringName = &""
var species: StringName = &""
var level: int = 1
## Posé quand la rencontre est consommée (capture ou K.O.).
var done_flag: StringName = &""
## Posé en plus quand le Pokémon est capturé.
var caught_flag: StringName = &""


func _init(p_id: StringName = &"", p_species: StringName = &"", p_level: int = 1,
		p_done_flag: StringName = &"", p_caught_flag: StringName = &"") -> void:
	id = p_id
	species = p_species
	level = p_level
	done_flag = p_done_flag
	caught_flag = p_caught_flag


## Vrai tant que la rencontre n'est pas consommée.
func is_present(flags: StoryFlags) -> bool:
	return flags == null or not flags.has_flag(done_flag)


## Drapeaux à poser pour l'issue [param outcome] ([enum Battle.Outcome]).
func flags_for(outcome: int) -> Array[StringName]:
	match outcome:
		Battle.Outcome.CAUGHT:
			return [done_flag, caught_flag]
		Battle.Outcome.WIN:
			return [done_flag]
	return []


## Vrai si l'issue [param outcome] consomme la rencontre : sauvegarde forcée avant le premier
## texte.
func needs_forced_save(outcome: int) -> bool:
	return not flags_for(outcome).is_empty()
