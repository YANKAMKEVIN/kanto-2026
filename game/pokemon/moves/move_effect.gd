class_name MoveEffect
extends RefCounted
## Effet secondaire d'une capacité, géré par le moteur de combat (jalon 4 §2.1).
##
## Donnée pure, lue par [PokemonData] dans la liste « effects » d'une capacité :
## [codeblock]
## { "kind": "stat_stage", "stat": "atk", "stages": -1, "target": "foe" }
## { "kind": "stat_stage", "stat": "spe", "stages": -1, "target": "foe", "chance": 10 }
## { "kind": "recoil", "fraction": 0.25 }
## { "kind": "seed", "fraction": 0.125, "immune_types": ["grass"] }
## [/codeblock]
## Seulement les sortes que le moteur sait appliquer. Les effets pas encore gérés
## (brûlure, sommeil…) ne sont pas des MoveEffect : voir [member MoveData.pending_effects].
## SEED (Vampigraine, jalon 5 Q28) : plante une graine sur la cible, qui perd en fin de tour
## [member fraction] de ses PV max au profit du Pokémon d'en face ; une cible d'un type de
## [member immune_types] n'est pas affectée. Seul statut volatil du jalon 5.

enum Kind { STAT_STAGE, RECOIL, SEED }
enum Target { SELF, FOE }

## Noms des sortes dans les données.
const KIND_NAMES: Dictionary[String, Kind] = {
	"stat_stage": Kind.STAT_STAGE, "recoil": Kind.RECOIL, "seed": Kind.SEED,
}
const TARGET_NAMES: Dictionary[String, Target] = {"self": Target.SELF, "foe": Target.FOE}
## Statistiques qui ont un niveau en combat (−6..+6) ; « acc » précision, « eva » esquive.
const STAGE_STATS: Array[StringName] = [&"atk", &"def", &"spa", &"spd", &"spe", &"acc", &"eva"]

var kind: Kind = Kind.STAT_STAGE
## STAT_STAGE : statistique modifiée (une de [constant STAGE_STATS]).
var stat: StringName = &""
## STAT_STAGE : variation demandée (−6..+6, jamais 0).
var stages: int = 0
## STAT_STAGE : qui la subit (le lanceur ou la cible).
var target: Target = Target.FOE
## STAT_STAGE : chance en % (100 = toujours ; sinon un tirage 1..100 ≤ chance).
var chance: int = 100
## RECOIL : fraction des PV max du lanceur perdue après l'attaque (Lutte : 0,25).
## SEED : fraction des PV max de la cible drainée à chaque fin de tour (Vampigraine : ⅛).
var fraction: float = 0.0
## SEED : types de cible qui n'en sont pas affectés (Vampigraine : Plante).
var immune_types: Array[StringName] = []
