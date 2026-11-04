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
##   { "into": "alakazam", "method": "trade" },
##   { "into": "steelix", "method": "trade", "item": "metal_coat" },
##   { "into": "espeon", "method": "bond", "period": ["morning", "day"] }
## ]
## [/codeblock]
## level : « level » obligatoire (1..100) ; item : « item » obligatoire (identifiant
## d'objet, non vérifié tant que les objets n'existent pas) ; trade : « item » facultatif
## (Chapitre Johto, `jalon-joh0.md` §2.8 : l'objet est demandé et consommé au terminal
## d'échange local, [LocalTrade]) ; bond (JOH0, JH-11) : « period » facultatif, un moment
## ([constant WorldClock.PERIOD_NAMES]) ou une liste de moments ; l'évolution se fait au prochain
## niveau gagné si le lien ([member Pokemon.bond]) atteint [constant BondRules.THRESHOLD] et,
## s'il y a des moments, si le moment courant en fait partie.
## Les évolutions par échange sont déclenchées par le terminal d'échange local (J32).

enum Method { LEVEL, ITEM, TRADE, BOND }

const METHOD_NAMES: Dictionary[String, Method] = {
	"level": Method.LEVEL, "item": Method.ITEM, "trade": Method.TRADE, "bond": Method.BOND,
}

## Espèce obtenue.
var into: StringName = &""
var method: Method = Method.LEVEL
## LEVEL : niveau minimal.
var level: int = 0
## ITEM : objet à utiliser ; TRADE : objet demandé au terminal (&"" = aucun).
var item: StringName = &""
## BOND : moments où l'évolution est permise (vide = à tout moment).
var periods: Array[StringName] = []


## Vrai si la règle BOND accepte le moment [param period] (&"" = moment inconnu : seules les
## règles sans moment l'acceptent).
func allows_period(period: StringName) -> bool:
	return periods.is_empty() or (not period.is_empty() and periods.has(period))
