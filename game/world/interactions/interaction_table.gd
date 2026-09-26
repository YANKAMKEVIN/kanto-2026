class_name InteractionTable
extends RefCounted
## Points fixes d'interaction d'une carte, indexés par case (tables, cartes, panneaux).
##
## Construite par `GameMap` à partir de ses nœuds `InteractPoint` (docs/tech/jalon-03.md
## §2.2), comme la [WarpTable]. Refuse une interaction invalide ou **ambiguë** : deux
## interactions sur une même case qui acceptent une même orientation du joueur.

var _by_cell: Dictionary[Vector2i, Array] = {}
var _count: int = 0


## Ajoute [param interaction]. Faux (et rien n'est ajouté) si elle est invalide ou ambiguë.
func add(interaction: Interaction) -> bool:
	if interaction == null or not interaction.is_valid():
		return false
	var existing: Array = _by_cell.get(interaction.cell, [])
	for other: Interaction in existing:
		if _conflicts(other, interaction):
			return false
	existing.append(interaction)
	_by_cell[interaction.cell] = existing
	_count += 1
	return true


## Interaction de [param cell] utilisable par un joueur orienté vers [param player_facing].
func find(cell: Vector2i, player_facing: Vector2i) -> Interaction:
	for interaction: Interaction in _by_cell.get(cell, []):
		if interaction.accepts(player_facing):
			return interaction
	return null


func get_at(cell: Vector2i) -> Array[Interaction]:
	var result: Array[Interaction] = []
	result.assign(_by_cell.get(cell, []))
	return result


func get_all() -> Array[Interaction]:
	var result: Array[Interaction] = []
	for list: Array in _by_cell.values():
		result.append_array(list)
	return result


func size() -> int:
	return _count


func is_empty() -> bool:
	return _count == 0


static func _conflicts(a: Interaction, b: Interaction) -> bool:
	return a.facing == Vector2i.ZERO or b.facing == Vector2i.ZERO or a.facing == b.facing
