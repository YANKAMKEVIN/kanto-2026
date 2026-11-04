class_name WeeklyFlags
extends RefCounted
## Drapeaux de la semaine (Chapitre Johto, JOH7, `docs/tech/jalon-joh7.md` §2.6 ; dossier JOH-08
## JH-50 : « le Lokhlass revient le vendredi suivant tant qu'il n'est pas capturé »). Classe pure.
##
## Un drapeau de la semaine ne compte que **son jour** : posé ce jour-là (Lokhlass mis K.O. ou
## fui, `week_friday_lapras`), il est baissé dès qu'une carte se charge un autre jour
## ([method apply], appelé par Boot à chaque carte avec le jour de l'horloge réelle). Aucun champ
## de sauvegarde : la remise à zéro suit le jour où le jeu tourne (limite [D] : un joueur qui ne
## lancerait le jeu que ce jour-là garde le drapeau).
## Données : `data/story/weekly_flags.json`, { drapeau → jour ([constant WorldClock.WEEKDAY_NAMES]) }
## (clés commençant par « _ » ignorées).

const DATA_PATH: String = "res://data/story/weekly_flags.json"

## Drapeau → jour où il compte.
var days: Dictionary[StringName, StringName] = {}
var _errors: Array[String] = []

static var _default: WeeklyFlags = null


## Lit [param path] ; faux (et [method get_errors]) si le fichier ou une entrée est invalide.
func load_file(path: String = DATA_PATH) -> bool:
	days.clear()
	_errors.clear()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_errors.append("%s : objet JSON attendu" % path)
		return false
	for key: String in parsed:
		if key.begins_with("_"):
			continue
		var day: Variant = parsed[key]
		if not day is String or not WorldClock.WEEKDAY_NAMES.has(StringName(day)):
			_errors.append("%s : « %s » : jour inconnu « %s »" % [path, key, str(day)])
			continue
		days[StringName(key)] = StringName(day)
	return _errors.is_empty()


func get_errors() -> Array[String]:
	return _errors.duplicate()


## Baisse les drapeaux dont le jour n'est pas [param weekday] ; rend ceux qui ont été baissés.
## [param weekday] vide (horloge inconnue) : rien.
func apply(flags: StoryFlags, weekday: StringName) -> Array[StringName]:
	var cleared: Array[StringName] = []
	if flags == null or weekday.is_empty():
		return cleared
	for flag: StringName in days:
		if days[flag] != weekday and flags.has_flag(flag):
			flags.set_flag(flag, false)
			cleared.append(flag)
	return cleared


## Les données du jeu, lues une fois.
static func shared() -> WeeklyFlags:
	if _default == null:
		_default = WeeklyFlags.new()
		if not _default.load_file():
			for message: String in _default.get_errors():
				push_error("WeeklyFlags : " + message)
	return _default
