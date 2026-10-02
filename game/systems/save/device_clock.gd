class_name DeviceClock
extends RefCounted
## Date réelle de l'appareil, au format ISO 8601 local (`2026-10-02T14:03:05`), jalon 5 §16.3.
##
## Classe pure, injectable : [GameState] en tient une instance pour dater les faits du journal
## (première observation, zones découvertes, grands moments…). Les tests la remplacent par
## `tests/helpers/fixed_clock.gd` (date imposée) pour des résultats déterministes. Rien à voir
## avec l'heure du jeu (jour / nuit), qui viendra avec un futur `GameClock`.


## Date et heure locales de l'appareil, ISO 8601 sans fuseau (`AAAA-MM-JJTHH:MM:SS`).
func now_iso() -> String:
	return Time.get_datetime_string_from_system(false, false)
