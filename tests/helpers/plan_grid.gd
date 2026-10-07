extends RefCounted
## Lecture d'une grille fonctionnelle de carte (`tools/plans/<carte>.txt`), même format et mêmes
## règles que `tools/art/plan_grille.py` : section `GRILLE L H` (« NN » + espace + L caractères
## par rangée), `FIN`, puis section `POSITIONS` (identifiant, type, cases, `bloque` | `libre`,
## commentaire après `#`), `FIN`. Cases : « x,y » ou plages « x0..x1,y0..y1 », groupes séparés
## par « ; ». Ligne facultative avant la grille : `PRATICABLES <caractères>` (cases praticables de
## cette grille, [member walkable] ; défaut [constant WALKABLE], la légende de la Route 2).
##
## Utilisé par l'outil de construction de la Route 2 (`tools/build_route_2.gd`, jalon 8 T5) et
## par `test_route_2` (critères du T0 sur la vraie grille de la scène).
## Utilisation : [code]const PlanGrid := preload("res://tests/helpers/plan_grid.gd")[/code].

## Cases praticables par défaut ; tout autre caractère de la légende est bloqué.
const WALKABLE: String = ".=hvD"

var width: int = 0
var height: int = 0
var rows: PackedStringArray = []
## Cases praticables de cette grille (ligne `PRATICABLES`, sinon [constant WALKABLE]).
var walkable: String = WALKABLE
## Identifiant → { "kind": String, "cells": Array[Vector2i], "blocks": bool,
## "attrs": Dictionary (String → String, attributs « cle=valeur » après bloque / libre) }.
var positions: Dictionary = {}
## Message d'erreur de la dernière lecture (vide : lecture réussie).
var error: String = ""


## Lit [param path] ; faux (et [member error]) si le fichier est absent ou mal formé.
func load_file(path: String) -> bool:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		error = "fichier absent ou vide : %s" % path
		return false
	var section := ""
	for raw: String in text.split("\n"):
		var line := raw.strip_edges(false, true)
		if section != "GRILLE":
			line = line.get_slice("#", 0).strip_edges(false, true)
		if line.strip_edges().is_empty():
			continue
		var words := line.split(" ", false)
		if words[0] == "GRILLE":
			section = "GRILLE"
			width = int(words[1])
			height = int(words[2])
			continue
		if words[0] == "PRATICABLES" and section.is_empty():
			walkable = words[1]
			continue
		if words[0] == "POSITIONS":
			section = "POSITIONS"
			continue
		if words[0] == "FIN":
			section = ""
			continue
		if section == "GRILLE":
			if int(words[0]) != rows.size() or words[1].length() != width:
				error = "rangée %s invalide" % words[0]
				return false
			rows.append(words[1])
		elif section == "POSITIONS":
			if words.size() < 4 or not words[3] in ["bloque", "libre"]:
				error = "position invalide : %s" % line
				return false
			var attrs: Dictionary = {}
			for i: int in range(4, words.size()):
				if not words[i].contains("="):
					error = "attribut invalide : %s" % line
					return false
				attrs[words[i].get_slice("=", 0)] = words[i].get_slice("=", 1)
			positions[words[0]] = {"kind": words[1], "cells": parse_cells(words[2]),
				"blocks": words[3] == "bloque", "attrs": attrs}
	if rows.size() != height:
		error = "%d rangées au lieu de %d" % [rows.size(), height]
		return false
	return true


## Caractère de la grille en [param cell] (hors carte : « T »).
func at(cell: Vector2i) -> String:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return "T"
	return rows[cell.y][cell.x]


## Cases portant [param chars] (l'un des caractères), rangée par rangée.
func cells_of(chars: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in height:
		for x: int in width:
			if chars.contains(rows[y][x]):
				cells.append(Vector2i(x, y))
	return cells


func is_walkable(cell: Vector2i) -> bool:
	return walkable.contains(at(cell))


## Première case de la position [param id] ((-1, -1) si absente).
func cell_of(id: String) -> Vector2i:
	if not positions.has(id):
		return Vector2i(-1, -1)
	return (positions[id]["cells"] as Array)[0]


## Attribut [param key] de la position [param id] (« cle=valeur » ; vide si absent).
func attr(id: String, key: String) -> String:
	if not positions.has(id):
		return ""
	return str((positions[id]["attrs"] as Dictionary).get(key, ""))


## Toutes les cases de la position [param id].
func cells_at(id: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if positions.has(id):
		cells.assign(positions[id]["cells"])
	return cells


## Cases des positions marquées `bloque` (obstacles de `plan_check.py`).
func blocking_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for id: String in positions:
		if positions[id]["blocks"]:
			cells.append_array(positions[id]["cells"])
	return cells


static func parse_cells(text: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for group: String in text.split(";"):
		var xs := _range(group.get_slice(",", 0))
		var ys := _range(group.get_slice(",", 1))
		for y: int in ys:
			for x: int in xs:
				cells.append(Vector2i(x, y))
	return cells


static func _range(text: String) -> Array[int]:
	var values: Array[int] = []
	if text.contains(".."):
		for v: int in range(int(text.get_slice("..", 0)), int(text.get_slice("..", 1)) + 1):
			values.append(v)
	else:
		values.append(int(text))
	return values
