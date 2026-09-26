class_name StatCalc
extends RefCounted
## Formules modernes des statistiques (jalon 4 §2.1). Statique et pur.
##
## PV = ⌊(2·B + IV + ⌊EV/4⌋)·N/100⌋ + N + 10 ;
## autres = ⌊⌊(2·B + IV + ⌊EV/4⌋)·N/100⌋ + 5⌋ × nature (neutre, 1,0, au jalon 4).

const IV_MAX: int = 31
const EV_MAX: int = 252

@warning_ignore_start("integer_division")


## Statistiques de [param species] au niveau [param level] ([constant SpeciesData.STATS]).
## IV et EV absents valent 0.
static func compute(species: SpeciesData, level: int, ivs: Dictionary[StringName, int],
		evs: Dictionary[StringName, int]) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	for stat: StringName in SpeciesData.STATS:
		result[stat] = value(stat, species.base_stats.get(stat, 0), ivs.get(stat, 0),
			evs.get(stat, 0), level)
	return result


## Une statistique : [param stat] = &"hp" pour la formule des PV.
static func value(stat: StringName, base: int, iv: int, ev: int, level: int) -> int:
	var core := (2 * base + iv + ev / 4) * level / 100
	if stat == &"hp":
		return core + level + 10
	return core + 5
