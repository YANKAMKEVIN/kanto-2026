class_name FirstExitCaption
extends RefCounted
## Légende de la toute première sortie (OUV.3, dossier 13 A12 et §8 point 8) :
## `data/opening/first_exit.json`.
##
## Classe pure. À la première sortie de la maison du joueur vers Bourg Palette, le titre de zone
## affiche « BOURG PALETTE / Le commencement de toute aventure » au lieu de la région (« Kanto »).
## « Première » se **déduit des cartes découvertes** de la partie (aucune donnée de sauvegarde) :
## la carte d'arrivée n'a jamais été découverte. La légende ne vaut que pour une arrivée **par une
## porte** depuis la carte « from » : jamais au démarrage, en reprise (Continuer) ni à un départ
## de débogage. Format (+ « _note ») :
## [codeblock]
## { "map": "pallet_town", "from": "player_house_1f",
##   "subtitle": "Le commencement de toute aventure" }
## [/codeblock]
## Validation stricte (clé inconnue ou manquante, texte vide = erreur) : un fichier en erreur
## n'est pas appliqué, aucune légende n'est alors jamais rendue.
##
## Jalon 18 (T24) : le fichier peut aussi être une **liste** d'arrivées (Bourg Palette, puis
## Lavanville) : `{ "arrivals": [ { "map", "from", "subtitle" }, … ] }`. Chaque arrivée garde la
## même règle ; la forme à une seule arrivée (OUV.3) reste valide.

const DEFAULT_PATH: String = "res://data/opening/first_exit.json"

const _KEYS: Array[String] = ["_note", "map", "from", "subtitle"]
const _LIST_KEYS: Array[String] = ["_note", "arrivals"]
const _REQUIRED: Array[String] = ["map", "from", "subtitle"]

## Arrivées chargées : { "map": StringName, "from": StringName, "subtitle": String }.
var _arrivals: Array[Dictionary] = []
var _errors: PackedStringArray = PackedStringArray()


## Charge [param path]. Faux (et rien d'appliqué) si le fichier manque ou contient une erreur.
func load_file(path: String = DEFAULT_PATH) -> bool:
	var errors := PackedStringArray()
	var data := OpeningJson.read_object(path, errors)
	if data.is_empty():
		_report(errors)
		return false
	return add_from_dict(data, path)


## Applique un dictionnaire déjà lu (tout ou rien) : une arrivée, ou `{ "arrivals": [ … ] }`.
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var errors := PackedStringArray()
	var entries: Array[Dictionary] = []
	if data.has("arrivals"):
		for key: String in OpeningJson.unknown_keys(data, _LIST_KEYS):
			errors.append("%s : clé inconnue « %s »" % [source, key])
		var list: Variant = data["arrivals"]
		if not list is Array or (list as Array).is_empty():
			errors.append("%s : « arrivals » doit être une liste non vide" % source)
		else:
			for i: int in (list as Array).size():
				var entry: Variant = (list as Array)[i]
				if entry is Dictionary:
					_check_entry(entry, "%s : arrivals[%d]" % [source, i], errors, entries)
				else:
					errors.append("%s : arrivals[%d] doit être un objet" % [source, i])
	else:
		_check_entry(data, source, errors, entries)
	if not errors.is_empty():
		_report(errors)
		return false
	_arrivals = entries
	return true


func is_loaded() -> bool:
	return not _arrivals.is_empty()


func get_errors() -> PackedStringArray:
	return _errors


## Carte d'arrivée de la première légende (&"" si rien n'est chargé).
func get_map() -> StringName:
	return _arrivals[0]["map"] if is_loaded() else &""


## Cartes d'arrivée de toutes les légendes, dans l'ordre du fichier.
func get_maps() -> Array[StringName]:
	var maps: Array[StringName] = []
	for arrival: Dictionary in _arrivals:
		maps.append(arrival["map"])
	return maps


## Sous-titre du titre de zone à l'arrivée sur [param map_id] depuis [param from_map] (&"" :
## démarrage, reprise, départ de débogage), **avant** que la carte ne soit marquée découverte :
## la légende si c'est la toute première sortie, sinon [param region] (le sous-titre habituel).
func subtitle_for(map_id: StringName, from_map: StringName, discovered: Dictionary,
		region: String) -> String:
	for arrival: Dictionary in _arrivals:
		if _matches(arrival, map_id, from_map, discovered):
			return arrival["subtitle"]
	return region


## Vrai si l'arrivée sur [param map_id] depuis [param from_map] est la toute première sortie.
func is_first_exit(map_id: StringName, from_map: StringName, discovered: Dictionary) -> bool:
	for arrival: Dictionary in _arrivals:
		if _matches(arrival, map_id, from_map, discovered):
			return true
	return false


func _matches(arrival: Dictionary, map_id: StringName, from_map: StringName,
		discovered: Dictionary) -> bool:
	return map_id == arrival["map"] and from_map == arrival["from"] \
		and not discovered.has(map_id)


func _check_entry(data: Dictionary, source: String, errors: PackedStringArray,
		entries: Array[Dictionary]) -> void:
	var before := errors.size()
	for key: String in OpeningJson.unknown_keys(data, _KEYS):
		errors.append("%s : clé inconnue « %s »" % [source, key])
	for key: String in _REQUIRED:
		if not OpeningJson.is_text(data.get(key)):
			errors.append("%s : « %s » doit être un texte non vide" % [source, key])
	if errors.size() == before:
		entries.append({ "map": StringName(data["map"]), "from": StringName(data["from"]),
			"subtitle": data["subtitle"] })


func _report(errors: PackedStringArray) -> void:
	_errors.append_array(errors)
	for error: String in errors:
		push_error("FirstExitCaption : %s" % error)
