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
## { "kind": "status", "status": "poison" }
## { "kind": "status", "status": "poison", "chance": 30 }
## [/codeblock]
## Seulement les sortes que le moteur sait appliquer. Les effets pas encore gérés
## (brûlure, sommeil…) ne sont pas des MoveEffect : voir [member MoveData.pending_effects].
## SEED (Vampigraine, jalon 5 Q28) : plante une graine sur la cible, qui perd en fin de tour
## [member fraction] de ses PV max au profit du Pokémon d'en face ; une cible d'un type de
## [member immune_types] n'est pas affectée. Seul statut volatil du jalon 5.
## STATUS (jalon 9 §2.1.2) : inflige à la cible le statut durable [member status] (un de
## [constant StatusRules.KNOWN]) ; immunités et « déjà un statut » : [StatusRules]. Sur une
## capacité de statut (Poudre Toxik), un refus est annoncé (NO_EFFECT, STATUS_UNCHANGED) ; en
## effet secondaire d'une attaque (Dard-Venin, [member chance] < 100), il est silencieux.
## Jalon 11 (`jalon-11.md` §2.2, dossier 14 §3.2 et §4) :
## [codeblock]
## { "kind": "confusion" }                  { "kind": "confusion", "chance": 10 }
## { "kind": "hits", "min": 2, "max": 2 }    { "kind": "hits", "min": 2, "max": 5 }
## { "kind": "flinch", "chance": 30 }        { "kind": "crit_up" }
## { "kind": "fixed_damage", "mode": "half_hp" }   { "kind": "fixed_damage", "mode": "level" }
## [/codeblock]
## CONFUSION : rend la cible confuse (état temporaire du [Battler], 1 à 4 tours). HITS : la
## capacité frappe de [member min_hits] à [member max_hits] fois (2 à 5 : 3/8, 3/8, 1/8, 1/8).
## FLINCH : apeure la cible si elle n'a pas encore agi ce tour-ci. CRIT_UP : critique +2 niveaux
## pour le lanceur (Puissance). FIXED_DAMAGE : dégâts fixes, moitié des PV de la cible
## (« half_hp », Croc Fatal) ou niveau du lanceur (« level », Frappe Atlas). BIDE : Patience
## (CT34, dossier 14 §6.3) : le lanceur encaisse deux tours, puis riposte ([Battle]).
## Jalon 12 (`jalon-12.md` §2.10, dossier 15 C-1 à C-3), règles G+ simplifiées :
## [codeblock]
## { "kind": "drain", "fraction": 0.5 }
## { "kind": "trap", "turns": [4, 5], "fraction": 0.125, "messages": "wrap" }
## { "kind": "disable", "turns": 4 }      { "kind": "rest" }      { "kind": "self_ko" }
## { "kind": "fixed_damage", "mode": "value", "amount": 20 }
## [/codeblock]
## DRAIN : le lanceur récupère [member fraction] des dégâts infligés (au moins 1, plafonné à ses
## PV max). TRAP : la cible est piégée [member min_turns] à [member max_turns] tours (tirés), perd
## [member fraction] de ses PV max à chaque fin de tour, ne peut ni fuir ni être changée ;
## [member messages] choisit les phrases (une de [constant TRAP_MESSAGES]). DISABLE : bloque la
## dernière capacité utilisée par la cible [member min_turns] tours. REST : le lanceur soigne son
## statut, récupère tous ses PV et dort deux tours ([method StatusRules.apply_rest]). SELF_KO : le
## lanceur tombe K.O. après sa capacité (Destruction, Explosion). FIXED_DAMAGE « value » : dégâts
## fixes [member amount] (Sonicboom).

enum Kind {
	STAT_STAGE, RECOIL, SEED, STATUS, CONFUSION, HITS, FLINCH, CRIT_UP, FIXED_DAMAGE, BIDE,
	DRAIN, TRAP, DISABLE, REST, SELF_KO,
}
enum Target { SELF, FOE }

## Noms des sortes dans les données.
const KIND_NAMES: Dictionary[String, Kind] = {
	"stat_stage": Kind.STAT_STAGE, "recoil": Kind.RECOIL, "seed": Kind.SEED,
	"status": Kind.STATUS, "confusion": Kind.CONFUSION, "hits": Kind.HITS,
	"flinch": Kind.FLINCH, "crit_up": Kind.CRIT_UP, "fixed_damage": Kind.FIXED_DAMAGE,
	"bide": Kind.BIDE,
	"drain": Kind.DRAIN, "trap": Kind.TRAP, "disable": Kind.DISABLE, "rest": Kind.REST,
	"self_ko": Kind.SELF_KO,
}
## Modes de FIXED_DAMAGE.
const FIXED_MODES: Array[StringName] = [&"half_hp", &"level", &"value"]
const TARGET_NAMES: Dictionary[String, Target] = {"self": Target.SELF, "foe": Target.FOE}
## Statistiques qui ont un niveau en combat (−6..+6) ; « acc » précision, « eva » esquive.
const STAGE_STATS: Array[StringName] = [&"atk", &"def", &"spa", &"spd", &"spe", &"acc", &"eva"]
## TRAP : familles de phrases connues (modèles « trap_<famille>_started » et
## « trap_<famille>_damaged » de `data/battle/messages.json`) ; « clamp » (Claquoir) : J13.
const TRAP_MESSAGES: Array[StringName] = [&"wrap", &"bind", &"fire_spin", &"clamp"]

var kind: Kind = Kind.STAT_STAGE
## STAT_STAGE : statistique modifiée (une de [constant STAGE_STATS]).
var stat: StringName = &""
## STAT_STAGE : variation demandée (−6..+6, jamais 0).
var stages: int = 0
## STAT_STAGE : qui la subit (le lanceur ou la cible).
var target: Target = Target.FOE
## STAT_STAGE, STATUS, CONFUSION, FLINCH : chance en % (100 = toujours ; sinon un tirage
## 1..100 ≤ chance).
var chance: int = 100
## RECOIL : fraction des PV max du lanceur perdue après l'attaque (Lutte : 0,25).
## SEED : fraction des PV max de la cible drainée à chaque fin de tour (Vampigraine : ⅛).
## DRAIN : part des dégâts infligés rendue au lanceur (½) ; TRAP : part des PV max perdue par la
## cible à chaque fin de tour (⅛).
var fraction: float = 0.0
## SEED : types de cible qui n'en sont pas affectés (Vampigraine : Plante).
var immune_types: Array[StringName] = []
## STATUS : statut infligé à la cible ([constant StatusRules.KNOWN]).
var status: StringName = &""
## HITS : nombre de coups (2 et 2 : deux coups ; 2 et 5 : de deux à cinq).
var min_hits: int = 1
var max_hits: int = 1
## FIXED_DAMAGE : « half_hp », « level » ou « value » ([constant FIXED_MODES]).
var mode: StringName = &""
## TRAP : nombre de tours tiré entre ces bornes ; DISABLE : les deux valent « turns ».
var min_turns: int = 0
var max_turns: int = 0
## TRAP : famille de phrases ([constant TRAP_MESSAGES]).
var messages: StringName = &""
## FIXED_DAMAGE « value » : dégâts infligés.
var amount: int = 0
