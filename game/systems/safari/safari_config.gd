class_name SafariConfig
extends RefCounted
## Réglages du Parc Safari (J23, dossier 26 §4 et §5.4 ; décisions de Kevin du 2026-10-16), lus
## dans `data/safari/safari.json`. Donnée pure, sans règle.
##
## Format (toutes les clés sont obligatoires ; une clé inconnue est une erreur) :
## [codeblock]
## {
##   "fee": 500,              # prix d'une visite (RB)
##   "balls": 30,             # Safari Balls remises à l'entrée (RB)
##   "steps": 500,            # pas utilisables (RB : 502 dont 2 scriptés ; K26 : 500 du joueur)
##   "ball_bonus": 2.0,       # multiplicateur de la Safari Ball dans CaptureCalc (N-5 : Ultra Ball)
##   "maps": ["…"],           # cartes où la visite compte les pas et où les rencontres sont Safari
##   "end_map": "…",          # carte où la fin de visite ramène le joueur (la Porte)
##   "end_spawn": "…"         # point d'apparition de la fin de visite
## }
## [/codeblock]
## Un fichier invalide laisse les valeurs par défaut ci-dessous et signale l'erreur
## ([method get_errors], push_error).

const DATA_PATH: String = "res://data/safari/safari.json"
const _KEYS: Array[String] = [
	"fee", "balls", "steps", "ball_bonus", "maps", "end_map", "end_spawn",
]

var fee: int = 500
var balls: int = 30
var steps: int = 500
var ball_bonus: float = 2.0
var maps: Array[StringName] = []
var end_map: StringName = &"safari_zone_gate"
var end_spawn: StringName = &"arrivee_fin"

var _errors: PackedStringArray = PackedStringArray()


## Réglages lus dans [param path] (valeurs par défaut et erreurs signalées si le fichier est
## invalide).
static func load_default(path: String = DATA_PATH) -> SafariConfig:
	var config := SafariConfig.new()
	config.load_file(path)
	return config


## Charge [param path]. Faux si le fichier est illisible ou invalide (rien ne change alors).
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet est attendu" % path)
	return set_from_dict(json.data, path)


## Applique un objet déjà lu ; tout ou rien : faux (rien ne change) à la première erreur.
func set_from_dict(data: Dictionary, source: String = "") -> bool:
	for key: Variant in data:
		if not _KEYS.has(str(key)):
			return _fail("%s : clé inconnue « %s »" % [source, key])
	for key: String in _KEYS:
		if not data.has(key):
			return _fail("%s : clé « %s » manquante" % [source, key])
	for key: String in ["fee", "balls", "steps"]:
		if not JsonFields.is_int(data[key]) or int(data[key]) < 1:
			return _fail("%s : « %s » doit être un entier ≥ 1" % [source, key])
	if not (data["ball_bonus"] is float or data["ball_bonus"] is int) \
			or float(data["ball_bonus"]) <= 0.0:
		return _fail("%s : « ball_bonus » doit être un nombre > 0" % source)
	if not data["maps"] is Array or (data["maps"] as Array).is_empty():
		return _fail("%s : « maps » doit être une liste non vide" % source)
	for map: Variant in data["maps"]:
		if not map is String or str(map).is_empty():
			return _fail("%s : « maps » ne contient que des identifiants de carte" % source)
	for key: String in ["end_map", "end_spawn"]:
		if not data[key] is String or str(data[key]).is_empty():
			return _fail("%s : « %s » doit être un identifiant" % [source, key])
	fee = int(data["fee"])
	balls = int(data["balls"])
	steps = int(data["steps"])
	ball_bonus = float(data["ball_bonus"])
	maps.clear()
	for map: Variant in data["maps"]:
		maps.append(StringName(str(map)))
	end_map = StringName(str(data["end_map"]))
	end_spawn = StringName(str(data["end_spawn"]))
	return true


## Vrai si la carte [param map_id] fait partie du Parc (compteur de pas, rencontres Safari).
func is_safari_map(map_id: StringName) -> bool:
	return maps.has(map_id)


func get_errors() -> PackedStringArray:
	return _errors


func _fail(message: String) -> bool:
	_errors.append(message)
	push_error("SafariConfig : " + message)
	return false
