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


## Vrai si une graine de Vampigraine est plantée sur ce Pokémon.
func is_seeded() -> bool:
	return seed_fraction > 0.0


## Vrai si le Pokémon a l'un des types de [param type_ids].
func has_any_type(type_ids: Array[StringName]) -> bool:
	for type: StringName in type_ids:
		if types.has(type):
			return true
	return false


## Indices des capacités qui ont encore des PP (vide = Lutte).
func usable_moves() -> Array[int]:
	var result: Array[int] = []
	for i: int in pokemon.moves.size():
		if pokemon.moves[i].pp > 0:
			result.append(i)
	return result


## Multiplicateur d'un niveau de statistique (−6 → 0,25 ; +6 → 4).
static func stage_multiplier(stage: int) -> float:
	return float(maxi(2, 2 + stage)) / float(maxi(2, 2 - stage))


## Multiplicateur de précision pour un niveau net (précision − esquive).
static func accuracy_multiplier(stage: int) -> float:
	var net := clampi(stage, STAGE_MIN, STAGE_MAX)
	return float(maxi(3, 3 + net)) / float(maxi(3, 3 - net))
