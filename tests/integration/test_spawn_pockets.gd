extends GutTest
## QA A17 du 2026-11-06 : l'arrivée de la chambre du Centre d'Oliville tombait dans une case dont
## la seule sortie était l'escalier ; le joueur ne pouvait plus quitter le Centre. Sur toutes les
## cartes, une arrivée doit ouvrir sur plus qu'une poche, sans passer par un warp au pas.

const MAPS_DIR := "res://game/world/maps/"
const MIN_REACH := 5
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]


func test_no_spawn_is_a_pocket() -> void:
	var pockets := PackedStringArray()
	for file: String in DirAccess.open(MAPS_DIR).get_files():
		if not file.ends_with(".tscn"):
			continue
		var map := (load(MAPS_DIR + file) as PackedScene).instantiate() as GameMap
		if map == null:
			continue
		add_child(map)
		var spawns := map.get_node_or_null(^"Spawns")
		if spawns != null:
			for spawn: Node in spawns.get_children():
				var start := map.get_spawn_cell(StringName(spawn.name))
				if _reach(map, start) < MIN_REACH:
					pockets.append("%s/%s %s" % [file.get_basename(), spawn.name, start])
		map.free()
	assert_eq(pockets.size(), 0, ", ".join(pockets))


## Cases atteignables à pied depuis [param start] sans déclencher de warp en marchant.
func _reach(map: GameMap, start: Vector2i) -> int:
	var seen: Dictionary[Vector2i, bool] = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for direction: Vector2i in DIRS:
			var next := cell + direction
			if seen.has(next) or not Rect2i(Vector2i.ZERO, map.size).has_point(next):
				continue
			if map.get_grid().is_solid(next) or map.get_warps().find_on_step(next, direction) != null:
				continue
			seen[next] = true
			queue.append(next)
	return seen.size()
