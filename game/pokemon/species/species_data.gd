class_name SpeciesData
extends RefCounted
## Une espèce de Pokémon, lue dans `data/pokemon/species/*.json` par [PokemonData]
## (jalon 4 §3.2 et décisions de Kevin du §8).
##
## Donnée pure. Format d'une entrée (objet « identifiant → espèce ») :
## [codeblock]
## "charmander": {
##   "dex": 4, "name": "Salamèche", "types": ["fire"],
##   "base_stats": { "hp": 39, "atk": 52, "def": 43, "spa": 60, "spd": 50, "spe": 65 },
##   "male_ratio": 0.875, "growth_rate": "medium_slow", "base_exp": 62, "catch_rate": 45,
##   "learnset": [[1, "scratch"], [1, "growl"], [9, "ember"], ...],
##   "evolutions": [{ "into": "charmeleon", "method": "level", "level": 16 }]
## }
## [/codeblock]
## Toutes les clés sont obligatoires sauf « evolutions » (voir [EvolutionRule]).
## male_ratio : part de mâles (0..1), −1 = asexué. growth_rate : une courbe de
## [ExpCurve]. learnset : tables d'apprentissage de Rouge/Bleu (décision de Kevin), liste
## de [niveau, capacité] par niveaux croissants ; une capacité peut y figurer plusieurs
## fois (niveau 1 et niveau 7 chez Herbizarre). Le sprite suit l'identifiant.

## Statistiques de base, dans l'ordre d'affichage.
const STATS: Array[StringName] = [&"hp", &"atk", &"def", &"spa", &"spd", &"spe"]
## Capacités connues au maximum (dossier 04).
const MAX_MOVES: int = 4

var id: StringName = &""
## Numéro du Pokédex national.
var dex: int = 0
## Nom affiché (« Salamèche »).
var name: String = ""
## 1 ou 2 types.
var types: Array[StringName] = []
var base_stats: Dictionary[StringName, int] = {}
## Part de mâles (0..1) ; −1 = asexué.
var male_ratio: float = -1.0
var growth_rate: ExpCurve.Rate = ExpCurve.Rate.MEDIUM_FAST
## Rendement d'XP de base (formule d'XP gagnée : jalon 5).
var base_exp: int = 0
## Taux de capture officiel, 1..255 (255 = le plus facile ; [CaptureCalc], jalon 5D).
var catch_rate: int = 0
## Paires [niveau: int, capacité: StringName], niveaux croissants.
var learnset: Array[Array] = []
var evolutions: Array[EvolutionRule] = []
## Fichier d'origine (messages d'erreur).
var source: String = ""


func is_genderless() -> bool:
	return male_ratio < 0.0


## Capacités connues par un Pokémon sauvage ou neuf de niveau [param level] : les
## [constant MAX_MOVES] dernières apprises au plus tard à ce niveau (règle moderne), sans
## doublon (une capacité réapprise compte à son dernier niveau), dans l'ordre d'apprentissage.
func moves_at(level: int) -> Array[StringName]:
	var known: Array[StringName] = []
	for entry: Array in learnset:
		if int(entry[0]) > level:
			break
		var move_id: StringName = entry[1]
		known.erase(move_id)
		known.append(move_id)
	if known.size() > MAX_MOVES:
		known = known.slice(known.size() - MAX_MOVES)
	return known


## Capacités apprises exactement au niveau [param level] (montée de niveau), sans doublon.
func moves_learned_at(level: int) -> Array[StringName]:
	var result: Array[StringName] = []
	for entry: Array in learnset:
		var move_id: StringName = entry[1]
		if int(entry[0]) == level and not result.has(move_id):
			result.append(move_id)
	return result


## Toutes les capacités du learnset, sans doublon, dans l'ordre du fichier.
func learnset_moves() -> Array[StringName]:
	var result: Array[StringName] = []
	for entry: Array in learnset:
		var move_id: StringName = entry[1]
		if not result.has(move_id):
			result.append(move_id)
	return result
