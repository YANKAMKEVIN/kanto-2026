class_name EvolutionRule
extends RefCounted
## Une règle d'évolution d'une espèce, lue dans la liste « evolutions » de
## `data/pokemon/species/*.json` par [PokemonData] (décision de Kevin, jalon 4 §8 point 4).
##
## Donnée pure :
## [codeblock]
## "evolutions": [
##   { "into": "ivysaur", "method": "level", "level": 16 },
##   { "into": "vaporeon", "method": "item", "item": "water_stone" },
##   { "into": "alakazam", "method": "trade" }
## ]
## [/codeblock]
## level : « level » obligatoire (1..100) ; item : « item » obligatoire (identifiant
## d'objet, non vérifié tant que les objets n'existent pas) ; trade : aucune autre clé.
## Les évolutions par échange existent dans le format, mais aucune logique de jeu ne les
## déclenche (adaptation solo à décider par Kevin).

enum Method { LEVEL, ITEM, TRADE }

const METHOD_NAMES: Dictionary[String, Method] = {
	"level": Method.LEVEL, "item": Method.ITEM, "trade": Method.TRADE,
}

## Espèce obtenue.
var into: StringName = &""
var method: Method = Method.LEVEL
## LEVEL : niveau minimal.
var level: int = 0
## ITEM : objet à utiliser.
var item: StringName = &""
