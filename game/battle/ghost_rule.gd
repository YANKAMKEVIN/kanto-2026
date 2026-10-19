class_name GhostRule
extends RefCounted
## Règle du SPECTRE (jalon 19, `jalon-19.md` §2.3 ; dossier 22 §6, K-8, K-9, K-11). Classe pure.
##
## Sans l'objet qui révèle (« silph_scope »), un combat sauvage de la Tour est un combat
## SPECTRE. La décision est [b]relue à chaque rencontre[/b] avec le Sac du moment : aucun
## drapeau, aucun cache, aucune migration (le jour où l'objet est dans le Sac, le mode normal
## revient tout seul).
##
## Deux sources :
## - une table de rencontres ([member EncounterTable.ghost_unless_item]) : [method is_ghost] ;
## - une étape de scène « combat sauvage » (T13) : clé « ghost » ([constant ALWAYS] : toujours
##   masqué, même avec l'objet, pour le SPECTRE du 6F jusqu'au J21) et/ou clé
##   « ghost_unless_item » (comme les tables) : [method is_ghost_for].

## Valeur de la clé « ghost » d'une étape de scène : SPECTRE quel que soit le Sac.
const ALWAYS: StringName = &"always"
## Valeurs acceptées pour la clé « ghost » (vide = clé absente).
const MODES: Array[StringName] = [&"", ALWAYS]


## Vrai si [param item_id] n'est pas vide et que [param bag] ne le contient pas (un Sac absent
## ne contient rien). Un identifiant vide : jamais de SPECTRE.
static func is_ghost(item_id: StringName, bag: Bag) -> bool:
	if item_id.is_empty():
		return false
	return bag == null or not bag.has(item_id)


## Décision complète d'une étape de scène : [param mode] = [constant ALWAYS] force le SPECTRE ;
## sinon c'est [method is_ghost] sur [param item_id]. Un mode inconnu ne force rien (la
## validation des données le refuse avant, [method is_known_mode]).
static func is_ghost_for(mode: StringName, item_id: StringName, bag: Bag) -> bool:
	if mode == ALWAYS:
		return true
	return is_ghost(item_id, bag)


## Vrai si [param mode] est une valeur permise pour la clé « ghost » d'une étape de scène.
static func is_known_mode(mode: StringName) -> bool:
	return MODES.has(mode)


## Vrai si la peur remplace l'action du Pokémon du joueur qui a choisi une capacité, selon son
## statut durable [param status] ([constant StatusRules.NONE] = aucun). Le sommeil et le gel
## gardent leur propre message (dossier 22 §6.2) : faux. Paralysie, poison, brûlure, aucun
## statut : vrai (la peur passe avant la paralysie et la confusion, `jalon-19.md` §7).
static func fear_applies(status: StringName) -> bool:
	return status != StatusRules.SLEEP and status != StatusRules.FREEZE
