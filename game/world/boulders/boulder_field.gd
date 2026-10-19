class_name BoulderField
extends RefCounted
## Rochers de Force d'une carte (passe systèmes 2, `docs/tech/systemes-2.md` §2.7.2, §2.7.4) :
## pur, sans nœud. Positions d'origine des rochers, trous (ouverts tant que leur drapeau n'est
## pas posé), interrupteurs (drapeau posé une fois pour toutes), cases interdites aux rochers.
##
## **Aucune position de rocher n'est sauvegardée** (J24, Rouge/Bleu) : à chaque entrée sur la
## carte, les rochers repartent de leur origine ([method boulders_at_load]) ; seuls les drapeaux
## (trous bouchés, interrupteurs enfoncés) restent. Un rocher **désigné** d'un trou (`trou=` dans
## la grille) disparaît quand ce trou est bouché : il y est tombé.
##
## Construit par la carte à l'entrée (T18), ou depuis les positions d'une grille
## ([method from_positions] : types `rocher`, `trou`, `interrupteur`, `interdit_rocher`, légende
## commune du §1.3). Le `SeafoamState` du J24 peut s'y brancher pour ses règles propres.

## Origine d'un rocher → numéro du trou où il est destiné à tomber (0 : aucun).
var _boulders: Dictionary[Vector2i, int] = {}
## Case d'un trou → { "n": int, "flag": StringName }.
var _holes: Dictionary[Vector2i, Dictionary] = {}
## Case d'un interrupteur → { "id": StringName, "flag": StringName }.
var _switches: Dictionary[Vector2i, Dictionary] = {}
## Cases interdites aux rochers (objets cachés…).
var _no_push: Dictionary[Vector2i, bool] = {}


## Rocher d'origine [param cell] ; [param hole] : numéro du trou désigné (0 : aucun).
func add_boulder(cell: Vector2i, hole: int = 0) -> void:
	_boulders[cell] = hole


## Trou n° [param n] en [param cell], bouché quand [param flag] est posé.
func add_hole(cell: Vector2i, n: int, flag: StringName) -> void:
	_holes[cell] = {&"n": n, &"flag": flag}


## Interrupteur [param id] en [param cell] ; [param flag] posé quand un rocher s'y arrête.
func add_switch(cell: Vector2i, id: StringName, flag: StringName) -> void:
	_switches[cell] = {&"id": id, &"flag": flag}


func add_no_push(cell: Vector2i) -> void:
	_no_push[cell] = true


## Depuis les positions d'une grille (format de `tests/helpers/plan_grid.gd` : identifiant →
## { "kind", "cells", "attrs" }). L'identifiant d'un interrupteur est celui de sa position.
static func from_positions(positions: Dictionary) -> BoulderField:
	var field := BoulderField.new()
	for id: String in positions:
		var p: Dictionary = positions[id]
		var attrs: Dictionary = p.get("attrs", {})
		var cells: Array = p.get("cells", [])
		match String(p.get("kind", "")):
			"rocher":
				field.add_boulder(cells[0], int(attrs.get("trou", "0")))
			"trou":
				field.add_hole(cells[0], int(attrs.get("n", "0")), StringName(attrs.get("drapeau", "")))
			"interrupteur":
				field.add_switch(cells[0], StringName(id), StringName(attrs.get("drapeau", "")))
			"interdit_rocher":
				for cell: Vector2i in cells:
					field.add_no_push(cell)
	return field


## Rochers présents à l'entrée sur la carte : toutes les origines, sauf ceux dont le trou désigné
## est déjà bouché.
func boulders_at_load(flags: StoryFlags) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _boulders:
		var hole := _boulders[cell]
		if hole == 0 or not _is_set(flags, hole_flag(hole)):
			cells.append(cell)
	return cells


## Trous ouverts (case → numéro) : ceux dont le drapeau n'est pas posé.
func open_holes(flags: StoryFlags) -> Dictionary[Vector2i, int]:
	var open: Dictionary[Vector2i, int] = {}
	for cell: Vector2i in _holes:
		if not _is_set(flags, _holes[cell][&"flag"]):
			open[cell] = int(_holes[cell][&"n"])
	return open


## Interrupteurs (case → identifiant), enfoncés ou non.
func switch_cells() -> Dictionary[Vector2i, StringName]:
	var cells: Dictionary[Vector2i, StringName] = {}
	for cell: Vector2i in _switches:
		cells[cell] = _switches[cell][&"id"]
	return cells


## Vrai si l'interrupteur de [param cell] est enfoncé (dessin « enfoncé »).
func is_switch_pressed(cell: Vector2i, flags: StoryFlags) -> bool:
	return _switches.has(cell) and _is_set(flags, _switches[cell][&"flag"])


## Drapeau du trou n° [param n] (vide si inconnu).
func hole_flag(n: int) -> StringName:
	for cell: Vector2i in _holes:
		if int(_holes[cell][&"n"]) == n:
			return _holes[cell][&"flag"]
	return &""


## Drapeau de l'interrupteur [param id] (vide si inconnu).
func switch_flag(id: StringName) -> StringName:
	for cell: Vector2i in _switches:
		if _switches[cell][&"id"] == id:
			return _switches[cell][&"flag"]
	return &""


## Poussée du rocher de [param boulder_cell] vers [param direction], avec les trous ouverts, les
## cases interdites et les interrupteurs de la carte ([method BoulderRules.push]).
func push(grid: GridWorld, boulder_cell: Vector2i, direction: Vector2i,
		flags: StoryFlags) -> BoulderRules.Push:
	return BoulderRules.push(grid, boulder_cell, direction, open_holes(flags), _no_push,
		switch_cells())


## Drapeau à poser après [param result] (vide : rien) : trou bouché (FELL), interrupteur enfoncé
## pour la première fois (ON_SWITCH). Poser un drapeau ici demande une **sauvegarde forcée**.
func flag_to_set(result: BoulderRules.Push, flags: StoryFlags) -> StringName:
	var flag := &""
	match result.outcome:
		BoulderRules.Outcome.FELL:
			flag = hole_flag(result.hole)
		BoulderRules.Outcome.ON_SWITCH:
			flag = switch_flag(result.switch_id)
	return &"" if flag == &"" or _is_set(flags, flag) else flag


static func _is_set(flags: StoryFlags, flag: StringName) -> bool:
	return flag != &"" and flags != null and flags.has_flag(flag)
