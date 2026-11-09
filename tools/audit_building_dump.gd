extends SceneTree
## Audit des emprises, étape 1 : écrit pour chaque carte extérieure ce qui bloque quelles cases
## (tuiles, cases bloquées, emprise de chaque objet) et l'image de chaque bâtiment posé. L'étape 2
## est tools/audit_building_margins.py. Lit les cartes sans jamais les réenregistrer.
##   godot --headless --path . -s res://tools/audit_building_dump.gd
const MAPS_DIR: String = "res://game/world/maps"
const OUT: String = "res://build/audit_decor/batiments.json"
const LAYERS: Array[String] = ["Ground", "Detail", "Obstacles", "Overhead"]


func _init() -> void:
	var names := DirAccess.get_files_at(MAPS_DIR)
	names.sort()
	var result: Array = []
	for file: String in names:
		if not file.ends_with(".tscn"):
			continue
		var map: Node2D = (load("%s/%s" % [MAPS_DIR, file]) as PackedScene).instantiate() as Node2D
		if map == null or not map.has_method(&"get_grid") or bool(map.get(&"interior")):
			if map != null:
				map.free()
			continue
		result.append(_dump(file.get_basename(), map))
		map.free()
	var out := FileAccess.open(OUT, FileAccess.WRITE)
	out.store_string(JSON.stringify(result))
	out.close()
	print("AUDIT emprises : %d cartes" % result.size())
	quit()


func _dump(id: String, map: Node2D) -> Dictionary:
	var solid: Array = []
	for layer_name: String in LAYERS:
		var layer := map.get_node_or_null(layer_name) as TileMapLayer
		if layer == null:
			continue
		for cell: Vector2i in layer.get_used_cells():
			var data := layer.get_cell_tile_data(cell)
			if data != null and bool(map.call(&"_get_bool", data, OverworldTiles.DATA_SOLID)):
				solid.append([cell.x, cell.y, layer_name])
	var blocked: Array = []
	for cell: Vector2i in map.get(&"blocked_cells"):
		blocked.append([cell.x, cell.y])
	var props: Array = []
	var entities := map.get_node_or_null(^"Entities")
	if entities != null:
		for child: Node in entities.get_children():
			if child.has_method(&"get_footprint"):
				props.append(_prop(child as Node2D))
	var markers: Array = []
	for group: String in ["Warps", "Interactables", "Triggers"]:
		var parent := map.get_node_or_null(group)
		if parent == null:
			continue
		for child: Node in parent.get_children():
			if child is Node2D:
				var at := (child as Node2D).position
				markers.append([floori(at.x / 96.0), floori(at.y / 96.0), group, str(child.name)])
	var size: Vector2i = map.get(&"size")
	return {"map": id, "size": [size.x, size.y], "tiles": solid, "blocked": blocked, "props": props, "markers": markers}


func _prop(prop: Node2D) -> Dictionary:
	var cells: Array = []
	for offset: Vector2i in prop.call(&"get_footprint"):
		cells.append([offset.x, offset.y])
	var anchor: Vector2i = prop.call(&"get_anchor_cell") if prop.has_method(&"get_anchor_cell") else Vector2i.ZERO
	var entry := {"name": str(prop.name), "scene": prop.scene_file_path, "visible": prop.visible,
		"anchor": [anchor.x, anchor.y], "footprint": cells,
		"pos": [prop.position.x, prop.position.y], "scale": [prop.scale.x, prop.scale.y]}
	var sprite := prop.get_node_or_null(^"Sprite") as Sprite2D
	if sprite != null and sprite.texture != null:
		entry["sprite"] = {"path": sprite.texture.resource_path, "offset": [sprite.offset.x, sprite.offset.y],
			"centered": sprite.centered, "flip": sprite.flip_h, "at": [sprite.position.x, sprite.position.y],
			"scale": [sprite.scale.x, sprite.scale.y], "region": sprite.region_enabled}
	return entry
