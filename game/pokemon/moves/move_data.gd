class_name MoveData
extends RefCounted
## Une capacité, lue dans `data/pokemon/moves/*.json` par [PokemonData] (jalon 4 §3.2).
##
## Donnée pure. Format d'une entrée (objet « identifiant → capacité ») :
## [codeblock]
## "bubble": {
##   "name": "Écume", "type": "water", "category": "special",
##   "power": 40, "accuracy": 100, "pp": 30,
##   "effects": [{ "kind": "stat_stage", "stat": "spe", "stages": -1, "target": "foe",
##                 "chance": 10 }],
##   "description": "…", "draft": true
## }
## [/codeblock]
## Clés : name, type, category (physical | special | status), accuracy (0 = ne rate
## jamais), pp, description : obligatoires. power (0 ; ≥ 1 pour une capacité offensive,
## 0 pour une capacité de statut), priority (0, −7..+5), crit_stage (0 ; 1 = critique
## élevé), effects ([MoveEffect]), pending_effects, typeless (false), draft (false).
##
## [b]pending_effects[/b] : effets de la capacité que le moteur ne gère [b]pas encore[/b],
## décrits pour ne pas les perdre ; le moteur les ignore. Chaînes libres en snake_case ; un
## suffixe `_N` = N % de chances. Vocabulaire actuel (le poison est joué depuis le jalon 9 :
## effet [code]status[/code] de [MoveEffect], plus de `poison`, `poison_20` ni `poison_30`) :
## - `burn_10` : 10 % de chances de brûler la cible ;
## - `paralysis`, `paralysis_10`, `paralysis_30` : paralyse la cible (toujours, 10 %, 30 %) ;
## - `confusion`, `confusion_10` : rend la cible confuse (toujours, 10 %) ;
## - `sleep` : endort la cible ;
## - `flinch_10`, `flinch_30` : 10 % ou 30 % de chances d'apeurer la cible (elle perd son
##   tour) ;
## - `trap` : piège la cible 4 à 5 tours et lui retire 1/8 de ses PV max à chaque tour ;
## - `two_turn` : se charge au premier tour, frappe au second ;
## - `charge_def_up` : la Défense du lanceur monte d'un niveau pendant la charge ;
## - `rage` : Frénésie, l'Attaque du lanceur monte à chaque coup reçu tant qu'il l'utilise ;
## - `rampage` : frappe 2 ou 3 tours de suite, puis le lanceur devient confus ;
## - `hits_2` : frappe deux fois ; `multi_hit` : frappe 2 à 5 fois ;
## - `crit_up` : augmente le taux de critique du lanceur ;
## - `force_switch` : chasse la cible (fin du combat contre un sauvage) ;
## - `mirror` : copie la dernière capacité de la cible ;
## - `half_hp` : retire la moitié des PV restants de la cible ;
## - `level_damage` : dégâts égaux au niveau du lanceur ;
## - `ohko` : met la cible K.O. en un coup.

enum Category { PHYSICAL, SPECIAL, STATUS }

const CATEGORY_NAMES: Dictionary[String, Category] = {
	"physical": Category.PHYSICAL, "special": Category.SPECIAL, "status": Category.STATUS,
}
## Chance de critique selon [member crit_stage] (règle moderne) : 1 sur 24, 8, 2, 1.
const CRIT_DENOMINATORS: Array[int] = [24, 8, 2, 1]

var id: StringName = &""
## Nom affiché (« Charge »).
var name: String = ""
## Type (identifiant de la table des types). Lutte garde « normal » pour l'affichage.
var type: StringName = &""
var category: Category = Category.PHYSICAL
## Puissance (0 = aucune, capacité de statut).
var power: int = 0
## Précision en % (0 = ne rate jamais).
var accuracy: int = 0
var pp: int = 0
var priority: int = 0
## Niveau de critique (0 : 1/24 ; 1 : 1/8, critique élevé ; 2 : 1/2 ; 3 : toujours).
var crit_stage: int = 0
var effects: Array[MoveEffect] = []
## Effets pas encore gérés par le moteur (voir la liste en tête de classe).
var pending_effects: PackedStringArray = PackedStringArray()
## Texte de la fiche de pression longue.
var description: String = ""
## Texte provisoire, à relire par Kevin.
var draft: bool = false
## Sans type en combat (Lutte) : efficacité toujours 1, jamais de bonus de type.
var typeless: bool = false
## Fichier d'origine (messages d'erreur).
var source: String = ""


## Vrai si la capacité inflige des dégâts (physique ou spéciale).
func is_damaging() -> bool:
	return category != Category.STATUS


func never_misses() -> bool:
	return accuracy == 0


## Dénominateur de la chance de critique (24 pour 1/24).
func crit_denominator() -> int:
	return CRIT_DENOMINATORS[clampi(crit_stage, 0, CRIT_DENOMINATORS.size() - 1)]
