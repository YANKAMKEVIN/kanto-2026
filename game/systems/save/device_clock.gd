class_name DeviceClock
extends RefCounted
## Date réelle de l'appareil, au format ISO 8601 local (`2026-10-02T14:03:05`), jalon 5 §16.3.
##
## Classe pure, injectable : [GameState] en tient une instance pour dater les faits du journal
## (première observation, zones découvertes, grands moments…). Les tests la remplacent par
## `tests/helpers/fixed_clock.gd` (date imposée) pour des résultats déterministes. L'heure du jeu
## (jour / nuit du Chapitre Johto, [WorldClock]) la lit aussi, par [method now_dict].


## Date et heure locales de l'appareil, ISO 8601 sans fuseau (`AAAA-MM-JJTHH:MM:SS`).
func now_iso() -> String:
	return Time.get_datetime_string_from_system(false, false)


## Date et heure locales décomposées (`Time.get_datetime_dict_from_system` : « year », « month »,
## « day », « weekday » (0 = dimanche … 6 = samedi), « hour », « minute », « second »).
func now_dict() -> Dictionary:
	return Time.get_datetime_dict_from_system(false)
