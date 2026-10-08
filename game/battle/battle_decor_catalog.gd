class_name BattleDecorCatalog
extends RefCounted
## Catalogue des décors peints de combat (CB.3, règle 7 : en données, `data/battle/decors.json`).
##
## - `decors` : décors par identifiant ([BattleDecor] : zone, variante, images, ligne de sol) ;
## - `places` : pour chaque **carte** (map_id), la liste des décors possibles. Une entrée peut
##   porter `cells` = [x, y, largeur, hauteur] (cases) : variante locale choisie quand le combat
##   se déclenche dans ce rectangle (première entrée qui contient la case) ; une entrée sans
##   `cells` est le décor par défaut de la carte.
## Carte absente (ou décor introuvable) : [method pick] rend null → **repli** du BattleStage
## (l'ancien fond : la carte recadrée et floutée).
## Classe pure : aucune dépendance à l'arbre de scènes.

const DEFAULT_PATH: String = "res://data/battle/decors.json"

var _decors: Dictionary[StringName, BattleDecor] = {}
## map_id → [{ "decor": StringName, "cells": Rect2i (vide : défaut) }].
var _places: Dictionary[StringName, Array] = {}


## Catalogue lu dans [param path] (vide si le fichier manque ou est illisible).
static func load_file(path: String = DEFAULT_PATH) -> BattleDecorCatalog:
	var catalog := BattleDecorCatalog.new()
	if not FileAccess.file_exists(path):
		push_error("BattleDecorCatalog : fichier absent « %s »" % path)
		return catalog
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		catalog.read(data)
	else:
		push_error("BattleDecorCatalog : JSON illisible « %s »" % path)
	return catalog


## Remplit le catalogue depuis [param data] (contenu de `decors.json`).
func read(data: Dictionary) -> void:
	_decors.clear()
	_places.clear()
	var decors: Dictionary = data.get("decors", {})
	for key: String in decors:
		var decor := BattleDecor.from_dict(StringName(key), decors[key])
		if decor != null:
			_decors[decor.id] = decor
	var places: Dictionary = data.get("places", {})
	for map_key: String in places:
		var entries: Array = []
		for raw: Variant in places[map_key]:
			var entry := raw as Dictionary
			if entry == null or not entry.has("decor"):
				continue
			var cells := Rect2i()
			var area := entry.get("cells", []) as Array
			if area != null and area.size() == 4:
				cells = Rect2i(int(area[0]), int(area[1]), int(area[2]), int(area[3]))
			entries.append({"decor": StringName(str(entry["decor"])), "cells": cells})
		_places[StringName(map_key)] = entries


## Décor du combat déclenché sur la carte [param map_id], case [param cell] : la variante
## locale qui contient la case, sinon le décor par défaut de la carte ; null : aucun (repli).
func pick(map_id: StringName, cell: Vector2i) -> BattleDecor:
	var entries: Array = _places.get(map_id, [])
	var fallback: BattleDecor = null
	for entry: Dictionary in entries:
		var decor: BattleDecor = _decors.get(entry["decor"])
		if decor == null:
			continue
		var cells: Rect2i = entry["cells"]
		if not cells.has_area():
			if fallback == null:
				fallback = decor
		elif cells.has_point(cell):
			return decor
	return fallback


## Décor par défaut de la carte [param map_id] (première entrée sans `cells`) ; null : aucun.
## C'est lui que le BattleStage précharge à l'entrée de la carte.
func default_for(map_id: StringName) -> BattleDecor:
	for entry: Dictionary in _places.get(map_id, []):
		var cells: Rect2i = entry["cells"]
		var decor: BattleDecor = _decors.get(entry["decor"])
		if decor != null and not cells.has_area():
			return decor
	return null


func get_decor(decor_id: StringName) -> BattleDecor:
	return _decors.get(decor_id)


func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_decors.keys())
	return ids


## Cartes qui ont au moins un décor.
func get_maps() -> Array[StringName]:
	var maps: Array[StringName] = []
	maps.assign(_places.keys())
	return maps
