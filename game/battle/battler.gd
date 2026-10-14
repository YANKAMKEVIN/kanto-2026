class_name Battler
extends RefCounted
## Le Pokémon en jeu d'un camp : le [Pokemon] et ses niveaux de statistiques du combat
## (jalon 4 §2.2). Classe pure.
##
## Niveaux −6..+6 pour [constant MoveEffect.STAGE_STATS] ; « acc » et « eva » existent mais
## aucune capacité du jalon ne les modifie. Multiplicateurs modernes : max(2, 2+s)/max(2, 2−s)
## pour les statistiques, max(3, 3+s)/max(3, 3−s) pour la précision.

const STAGE_MIN: int = -6
const STAGE_MAX: int = 6

var pokemon: Pokemon
## Types de l'espèce (copiés à l'envoi : bonus de type, efficacité).
var types: Array[StringName] = []
## Vampigraine (jalon 5 Q28) : fraction des PV max drainée à chaque fin de tour, 0 = pas de
## graine. Statut volatil : il disparaît quand le Pokémon quitte le terrain (un nouveau
## Battler est créé à chaque envoi).
var seed_fraction: float = 0.0
## Confusion (jalon 11, dossier 14 §3.2) : tentatives d'agir encore confuses (1 à 4 à
## l'application) ; 0 = pas confus. Perdue au changement de Pokémon et à la fin du combat
## (un nouveau Battler à chaque envoi ; jamais sauvegardée).
var confusion_turns: int = 0
## Apeuré ce tour-ci (jalon 11) : il ne pourra pas agir ; remis à faux en fin de tour.
var flinched: bool = false
## Puissance (jalon 11) : critique +2 niveaux tant que le Pokémon reste en jeu.
var focused: bool = false
## Patience (jalon 11, CT34, dossier 14 §6.3) : tour de Patience déjà joué (0 = pas de Patience,
## 1 = s'est préparé, 2 = a encaissé ; la riposte vient au tour suivant), emplacement de la
## capacité (action imposée) et dégâts directs reçus depuis la préparation. Perdu au changement,
## au K.O. et à la fin du combat (jamais sauvegardé).
var bide_stage: int = 0
var bide_slot: int = -1
var bide_stock: int = 0
## Piège (jalon 12, Ligotage, Étreinte, Danse Flamme) : fins de tour encore à subir (0 = libre),
## capacité qui le retient (phrases par capacité), part des PV max perdue par tour, et le
## [Battler] lanceur : le piège finit quand il quitte le terrain. Perdu au changement, au K.O. et
## à la fin du combat (jamais sauvegardé).
var trap_turns: int = 0
var trap_move: StringName = &""
var trap_fraction: float = 0.0
var trap_source: Battler = null
## Entrave (jalon 12) : emplacement de la dernière capacité lancée (posé à MOVE_USED ; −1 = aucune
## encore, ou Lutte), emplacement bloqué (−1 = aucun) et fins de tour restantes.
var last_move_slot: int = -1
var disabled_slot: int = -1
var disabled_turns: int = 0
var _stages: Dictionary[StringName, int] = {}

@warning_ignore_start("integer_division")


func _init(in_battle: Pokemon, species_types: Array[StringName]) -> void:
	pokemon = in_battle
	types = species_types.duplicate()
	reset_stages()


## Niveau actuel de [param stat] (0 si la statistique n'a pas de niveau).
func get_stage(stat: StringName) -> int:
	return _stages.get(stat, 0)


## Applique [param delta] au niveau de [param stat], borné à −6..+6. Renvoie la variation
## réellement appliquée (0 si déjà au bout).
func change_stage(stat: StringName, delta: int) -> int:
	if not _stages.has(stat):
		push_error("Battler : statistique sans niveau « %s »" % stat)
		return 0
	var before: int = _stages[stat]
	_stages[stat] = clampi(before + delta, STAGE_MIN, STAGE_MAX)
	return _stages[stat] - before


func reset_stages() -> void:
	for stat: StringName in MoveEffect.STAGE_STATS:
		_stages[stat] = 0


## Statistique [param stat] en combat, niveau compris. Un coup critique ignore les baisses
## de l'attaquant ([param ignore_drops]) et les hausses du défenseur ([param ignore_boosts]).
func effective_stat(stat: StringName, ignore_drops: bool = false,
		ignore_boosts: bool = false) -> int:
	var stage := get_stage(stat)
	if (ignore_drops and stage < 0) or (ignore_boosts and stage > 0):
		stage = 0
	return pokemon.stats.get(stat, 0) * maxi(2, 2 + stage) / maxi(2, 2 - stage)


## Vrai si le Pokémon est en pleine Patience (son action est imposée).
func is_biding() -> bool:
	return bide_stage > 0


## Oublie la Patience en cours (riposte, rupture).
func clear_bide() -> void:
	bide_stage = 0
	bide_slot = -1
	bide_stock = 0


## Vrai si le Pokémon est confus.
func is_confused() -> bool:
	return confusion_turns > 0


## Vrai si une graine de Vampigraine est plantée sur ce Pokémon.
func is_seeded() -> bool:
	return seed_fraction > 0.0


## Vrai si le Pokémon a l'un des types de [param type_ids].
func has_any_type(type_ids: Array[StringName]) -> bool:
	for type: StringName in type_ids:
		if types.has(type):
			return true
	return false


## Indices des capacités qui ont encore des PP, sauf celle que bloque une Entrave (jalon 12) ;
## vide = Lutte.
func usable_moves() -> Array[int]:
	var result: Array[int] = []
	for i: int in pokemon.moves.size():
		if pokemon.moves[i].pp > 0 and i != disabled_slot:
			result.append(i)
	return result


## Multiplicateur d'un niveau de statistique (−6 → 0,25 ; +6 → 4).
static func stage_multiplier(stage: int) -> float:
	return float(maxi(2, 2 + stage)) / float(maxi(2, 2 - stage))


## Multiplicateur de précision pour un niveau net (précision − esquive).
static func accuracy_multiplier(stage: int) -> float:
	var net := clampi(stage, STAGE_MIN, STAGE_MAX)
	return float(maxi(3, 3 + net)) / float(maxi(3, 3 - net))


## Vrai si le Pokémon est piégé (Ligotage…) : ni fuite ni changement (jalon 12).
func is_trapped() -> bool:
	return trap_turns > 0


## Libère le Pokémon de son piège.
func clear_trap() -> void:
	trap_turns = 0
	trap_move = &""
	trap_fraction = 0.0
	trap_source = null


## Vrai si une capacité du Pokémon est bloquée par une Entrave (jalon 12).
func has_disabled_move() -> bool:
	return disabled_slot >= 0


## Lève l'Entrave.
func clear_disable() -> void:
	disabled_slot = -1
	disabled_turns = 0
