class_name WorldClock
extends RefCounted
## Heure du monde (préparée au MM.1, décision de Kevin du 2026-10-07 ; docs/tech/menu-maquettes.md
## « Préparés dès maintenant ») : la puce « heure » du bandeau d'état du menu l'interroge.
##
## Classe pure. **Inactive tant que le cycle jour/nuit n'existe pas** (phase 10) : aucune heure
## n'est inventée, [method time_text] rend "" et la puce reste cachée (dossier 08, règle 5 :
## « L'heure : jamais avant l'existence réelle du cycle jour/nuit »). La phase 10 n'aura qu'à
## l'activer ([method start]) et la faire avancer ([method advance]).

const MINUTES_PER_DAY := 24 * 60
## « 10:24 » (24 h, deux chiffres).
const TIME_FORMAT := "%02d:%02d"

## L'horloge a commencé ou s'est arrêtée.
signal activity_changed(active: bool)

var _active: bool = false
## Minutes écoulées depuis minuit (0 à MINUTES_PER_DAY − 1), secondes en fraction.
var _minutes: float = 0.0


## Vrai si le cycle jour/nuit existe et tourne.
func is_active() -> bool:
	return _active


## Active l'horloge à [param hour]:[param minute] (bornés à la journée).
func start(hour: int, minute: int = 0) -> void:
	set_time(hour, minute)
	if not _active:
		_active = true
		activity_changed.emit(true)


## Arrête l'horloge (la puce se cache).
func stop() -> void:
	if _active:
		_active = false
		activity_changed.emit(false)


func set_time(hour: int, minute: int = 0) -> void:
	_minutes = float(posmod(hour * 60 + minute, MINUTES_PER_DAY))


## Fait avancer l'heure de [param game_minutes] (sans effet si l'horloge est inactive).
func advance(game_minutes: float) -> void:
	if _active and game_minutes > 0.0:
		_minutes = fposmod(_minutes + game_minutes, float(MINUTES_PER_DAY))


@warning_ignore("integer_division")
func get_hour() -> int:
	return int(_minutes) / 60


func get_minute() -> int:
	return int(_minutes) % 60


## « 10:24 » ; "" si l'horloge est inactive (rien à montrer).
func time_text() -> String:
	if not _active:
		return ""
	return TIME_FORMAT % [get_hour(), get_minute()]
