class_name RestPointLibrary
extends RefCounted
## Points de repos, lus dans `data/world/rest_points.json` (dossier 09 §7 ; jalon-07.md §3.3).
##
## Classe pure. Règles :
## - **Le dernier Centre utilisé** devient le point de retour après une défaite
##   ([method register], appelé à la fin du soin d'un Centre) ; le toast « Point de repos
##   enregistré — <zone> » n'apparaît que si le point a changé ([method registered_toast] :
##   titre et détail du toast, comme « Poké Balls ×5 — Ajoutées au Sac »).
## - Tant qu'aucun Centre n'a servi, le point de retour reste la maison (défaut de
##   [GameState]) ; Maman soigne toujours mais ne réenregistre jamais la maison
##   (`registers: false`).
## - Au réveil, [method wakeup_point] donne la carte, le point d'apparition, l'orientation et
##   le mot du lieu. Rien ne change le format de sauvegarde (v3 : `heal_map`, `heal_spawn`).
## Format :
## [codeblock]
## {
##   "registered_title": "Point de repos enregistré",
##   "points": {
##     "player_house_1f": { "spawn": "heal", "facing": "up", "wakeup_dialogue": "mom_wakeup",
##                          "registers": false },
##     "viridian_center": { "spawn": "heal", "facing": "up",
##                          "wakeup_dialogue": "nurse_wakeup", "registers": true }
##   }
## }
## [/codeblock]
## Clés d'un point : « spawn » et « wakeup_dialogue » (identifiants non vides), « facing »
## (nom de direction, défaut « up »), « registers » (défaut false). Toute clé inconnue est une
## erreur ; un point invalide est écarté, l'erreur signalée ([method get_errors], push_error).
## Que la carte, son point d'apparition et le dialogue existent se vérifie avec les vraies
## données (test_rest_point_data).

const DATA_PATH: String = "res://data/world/rest_points.json"
const _ROOT_KEYS: Array[String] = ["registered_title", "points"]
const _POINT_KEYS: Array[String] = ["spawn", "facing", "wakeup_dialogue", "registers"]

var _points: Dictionary[StringName, RestPoint] = {}
var _registered_title: String = ""
var _errors: PackedStringArray = PackedStringArray()


## Enregistre [param point] comme point de repos de [param state] (GameState, ou une instance
## de game_state.gd en test) s'il `registers`. Vrai si le point de repos a changé (toast).
## Un point qui n'enregistre pas (la maison), null ou déjà courant : faux, rien ne change.
static func register(state: Node, point: RestPoint) -> bool:
	if state == null or point == null or not point.registers:
		return false
	if state.heal_map == point.map and state.heal_spawn == point.spawn:
		return false
	state.heal_map = point.map
	state.heal_spawn = point.spawn
	return true


## Charge [param path]. Faux si le fichier est illisible ou contient une erreur (les points
## valides sont gardés).
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { \"points\": { … } } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les points d'un objet déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if not _ROOT_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	if data.has("registered_title"):
		var title: Variant = data["registered_title"]
		if not title is String or (title as String).strip_edges().is_empty():
			ok = _fail("%s : « registered_title » doit être un texte non vide" % source)
		else:
			_registered_title = title
	if not data.get("points") is Dictionary:
		return _fail("%s : « points » doit être un objet { carte: point }" % source)
	var points: Dictionary = data["points"]
	for key: Variant in points:
		var map := StringName(str(key))
		var where := "%s « %s »" % [source, map]
		if map.is_empty():
			ok = _fail("%s : carte vide" % source)
			continue
		if _points.has(map):
			ok = _fail("%s : point déjà défini dans %s" % [where, _points[map].source])
			continue
		var point := _parse_point(points[key], where)
		if point == null:
			ok = false
			continue
		point.map = map
		point.source = source
		_points[map] = point
	return ok


## Point de repos de la carte [param map], ou null si elle n'en a pas.
func get_point(map: StringName) -> RestPoint:
	return _points.get(map)


func has_point(map: StringName) -> bool:
	return _points.has(map)


## Cartes qui ont un point de repos, triées.
func get_maps() -> Array[StringName]:
	var maps: Array[StringName] = []
	maps.assign(_points.keys())
	maps.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return maps


func size() -> int:
	return _points.size()


## Où se réveiller après une défaite, d'après [param state] (heal_map / heal_spawn) : le point
## de la donnée si la carte en a un au même point d'apparition ; sinon (donnée retirée, point
## d'apparition changé) un point construit sur l'état, tourné vers le haut, **sans** mot de
## réveil. Jamais null.
func wakeup_point(state: Node) -> RestPoint:
	var map: StringName = state.heal_map
	var spawn: StringName = state.heal_spawn
	var point := get_point(map)
	if point != null and point.spawn == spawn:
		return point
	var fallback := RestPoint.new()
	fallback.map = map
	fallback.spawn = spawn
	return fallback


## Toast d'un point de repos enregistré, [titre, détail] : « Point de repos enregistré —
## Jadielle » (dossier 09 §19). [param zone_name] : nom de la zone de la carte
## (ZoneLibrary.zone_name_of). Pour [method Toast.show_toast].
func registered_toast(zone_name: String) -> PackedStringArray:
	return PackedStringArray([_registered_title, zone_name])


## Erreurs signalées depuis la création.
func get_errors() -> PackedStringArray:
	return _errors


func _parse_point(value: Variant, where: String) -> RestPoint:
	if not value is Dictionary:
		_fail("%s : un objet est attendu" % where)
		return null
	var entry: Dictionary = value
	var point := RestPoint.new()
	var ok := true
	for key: Variant in entry:
		if not _POINT_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	for key: String in ["spawn", "wakeup_dialogue"]:
		if not entry.get(key) is String or (entry[key] as String).is_empty():
			ok = _fail("%s : « %s » doit être un identifiant non vide" % [where, key])
	if ok:
		point.spawn = StringName(entry["spawn"])
		point.wakeup_dialogue = StringName(entry["wakeup_dialogue"])
	if entry.has("facing"):
		var facing: Variant = entry["facing"]
		if not facing is String or not Grid.is_direction_name(facing):
			ok = _fail("%s : « facing » doit être une direction (up, down, left, right)"
				% where)
		else:
			point.facing = Grid.direction_from_name(facing)
	if entry.has("registers"):
		if not entry["registers"] is bool:
			ok = _fail("%s : « registers » : true ou false attendu" % where)
		else:
			point.registers = entry["registers"]
	return point if ok else null


func _fail(message: String) -> bool:
	var full := "RestPointLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false
