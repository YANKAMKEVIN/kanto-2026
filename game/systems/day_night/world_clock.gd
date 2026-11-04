class_name WorldClock
extends RefCounted
## Heure du monde (préparée au MM.1, décision de Kevin du 2026-10-07 ; docs/tech/menu-maquettes.md
## « Préparés dès maintenant ») : la puce « heure » du bandeau d'état du menu l'interroge.
##
## Classe pure. **Activée par le Chapitre Johto** (JOH0, `jalon-joh0.md` §2.3 ; dossier JOH-01
## §2, JH-6) : elle lit l'heure et le jour **réels du téléphone** par un [DeviceClock] injectable
## ([method start_on_device], puis [method sync] une fois par seconde par Boot) et les traduit en
## trois **moments** d'Or/Argent ([enum Period] : matin 4 h–9 h 59, jour 10 h–17 h 59, nuit
## 18 h–3 h 59) et sept **jours** ([method weekday]). Inactive, aucune heure n'est inventée :
## [method time_text] rend "" et la puce reste cachée (dossier 08, règle 5). Une scène peut
## **forcer** un moment ([method force_period] : arrivée à Oliville de nuit) ; le moment réel
## revient avec [method release_period]. Les anciennes entrées ([method start], [method advance],
## [method set_time]) restent pour les tests et les outils : une horloge démarrée sans appareil
## avance à la main.
##
## La portée (JH-8 : seules les cartes de Johto lisent l'heure) n'est pas décidée ici : l'horloge
## tourne partout, Boot choisit qui la lit.

## Moments de la journée (Or/Argent).
enum Period { MORNING, DAY, NIGHT }

const MINUTES_PER_DAY := 24 * 60
## « 10:24 » (24 h, deux chiffres).
const TIME_FORMAT := "%02d:%02d"
## Identifiants des moments dans les données (`period` des tables de rencontres, des règles
## d'évolution, des variantes de dialogue, des PNJ).
const PERIOD_NAMES: Dictionary[String, Period] = {
	"morning": Period.MORNING, "day": Period.DAY, "night": Period.NIGHT,
}
## Bornes des moments : heure de début (incluse) de chacun.
const MORNING_START_HOUR: int = 4
const DAY_START_HOUR: int = 10
const NIGHT_START_HOUR: int = 18
## Jours de la semaine (0 = lundi … 6 = dimanche ; Godot compte 0 = dimanche, converti à la
## lecture de l'appareil), identifiants des données (`if_weekday`).
const WEEKDAY_NAMES: Array[StringName] = [
	&"monday", &"tuesday", &"wednesday", &"thursday", &"friday", &"saturday", &"sunday",
]

## L'horloge a commencé ou s'est arrêtée.
signal activity_changed(active: bool)
## Le moment a changé (heure réelle qui passe une borne, moment forcé posé ou libéré). Jamais
## émis par [method start] ni par [method start_on_device] (l'appelant lit [method period]).
signal period_changed(period: Period)

var _active: bool = false
## Minutes écoulées depuis minuit (0 à MINUTES_PER_DAY − 1), secondes en fraction.
var _minutes: float = 0.0
## Jour de la semaine courant (0 = lundi).
var _weekday: int = 0
## Appareil suivi par [method sync] (null : horloge avancée à la main).
var _device: DeviceClock
## Moment forcé par une scène (−1 : aucun).
var _forced: int = -1
## Jour de la semaine imposé (JOH2, départ de débogage `weekday` ; −1 : le jour réel).
var _forced_weekday: int = -1
## Dernier moment annoncé par [signal period_changed] (pour ne l'émettre qu'au changement).
var _last_period: int = -1


## Vrai si le cycle jour/nuit existe et tourne.
func is_active() -> bool:
	return _active


## Active l'horloge à [param hour]:[param minute] (bornés à la journée), avancée à la main.
func start(hour: int, minute: int = 0) -> void:
	_device = null
	set_time(hour, minute)
	_last_period = int(period())
	if not _active:
		_active = true
		activity_changed.emit(true)


## Active l'horloge sur l'heure et le jour réels de [param device] ([method sync] la relit).
func start_on_device(device: DeviceClock) -> void:
	_device = device
	_read_device()
	_last_period = int(period())
	if not _active:
		_active = true
		activity_changed.emit(true)


## Relit l'appareil (sans effet si l'horloge est inactive ou avancée à la main) et émet
## [signal period_changed] si le moment a changé. Vrai si le moment a changé.
func sync() -> bool:
	if not _active or _device == null:
		return false
	_read_device()
	return _announce()


## Arrête l'horloge (la puce se cache) ; le moment forcé est libéré sans signal.
func stop() -> void:
	_forced = -1
	_forced_weekday = -1
	if _active:
		_active = false
		activity_changed.emit(false)


func set_time(hour: int, minute: int = 0) -> void:
	_minutes = float(posmod(hour * 60 + minute, MINUTES_PER_DAY))


## Jour de la semaine (0 = lundi … 6 = dimanche), ramené dans la semaine.
func set_weekday(day: int) -> void:
	_weekday = posmod(day, WEEKDAY_NAMES.size())


## Fait avancer l'heure de [param game_minutes] (sans effet si l'horloge est inactive) ; passe
## au jour suivant à minuit ; émet [signal period_changed] si le moment change.
func advance(game_minutes: float) -> void:
	if not _active or game_minutes <= 0.0:
		return
	var total := _minutes + game_minutes
	var days := int(total / float(MINUTES_PER_DAY))
	_minutes = fposmod(total, float(MINUTES_PER_DAY))
	if days > 0:
		set_weekday(_weekday + days)
	_announce()


@warning_ignore("integer_division")
func get_hour() -> int:
	return int(_minutes) / 60


func get_minute() -> int:
	return int(_minutes) % 60


## Jour de la semaine courant (0 = lundi … 6 = dimanche) : le jour imposé s'il y en a un.
func weekday() -> int:
	if _forced_weekday >= 0:
		return _forced_weekday
	return _weekday


## Impose le jour [param day] (0 = lundi … 6 = dimanche) jusqu'à [method release_weekday] ou
## [method stop] (JOH2 : départ de débogage « weekday », pour voir un PNJ de la semaine un
## autre jour que le sien). Sans signal : les PNJ datés sont relus à l'entrée sur une carte.
func force_weekday(day: int) -> void:
	_forced_weekday = posmod(day, WEEKDAY_NAMES.size())


## Rend le jour réel.
func release_weekday() -> void:
	_forced_weekday = -1


## Vrai tant qu'un jour est imposé.
func is_weekday_forced() -> bool:
	return _forced_weekday >= 0


## Identifiant du jour courant (« monday »…).
func weekday_name() -> StringName:
	return WEEKDAY_NAMES[weekday()]


## Moment courant : le moment forcé s'il y en a un, sinon celui de l'heure. MORNING si
## l'horloge est inactive (l'appelant vérifie [method is_active]).
func period() -> Period:
	if _forced >= 0:
		return _forced as Period
	return period_of(get_hour())


## Identifiant du moment courant (« morning », « day », « night »).
func period_name() -> StringName:
	return StringName(PERIOD_NAMES.find_key(period()))


## Moment de l'heure [param hour] (0..23) : matin 4–9, jour 10–17, nuit 18–3.
static func period_of(hour: int) -> Period:
	var h := posmod(hour, 24)
	if h >= NIGHT_START_HOUR or h < MORNING_START_HOUR:
		return Period.NIGHT
	if h >= DAY_START_HOUR:
		return Period.DAY
	return Period.MORNING


## Impose [param forced] (scène) jusqu'à [method release_period] ; émet
## [signal period_changed] si le moment vu change.
func force_period(forced: Period) -> void:
	_forced = int(forced)
	_announce()


## Rend le moment réel ; émet [signal period_changed] s'il diffère du moment forcé.
func release_period() -> void:
	_forced = -1
	_announce()


## Vrai tant qu'une scène impose un moment.
func is_period_forced() -> bool:
	return _forced >= 0


## « 10:24 » ; "" si l'horloge est inactive (rien à montrer).
func time_text() -> String:
	if not _active:
		return ""
	return TIME_FORMAT % [get_hour(), get_minute()]


func _read_device() -> void:
	var now := _device.now_dict()
	set_time(int(now.get("hour", 0)), int(now.get("minute", 0)))
	# Godot : 0 = dimanche … 6 = samedi ; ici 0 = lundi … 6 = dimanche.
	set_weekday(int(now.get("weekday", 1)) - 1)


func _announce() -> bool:
	var current := int(period())
	if current == _last_period:
		return false
	_last_period = current
	period_changed.emit(current as Period)
	return true
