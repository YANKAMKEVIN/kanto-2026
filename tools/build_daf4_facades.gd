extends SceneTree
## Lot DAF.4 (`tools/art/daf4.py`) : façades peintes du J29 à la place des dessins provisoires de
## `build_j29.gd` (`Batiment`, `Porte…`) : poste de la Ligue sur la Route 22 ouest
## (`bldg_poste_route_22_01`, 5 × 4, porte (8, 5)) et bâtiment de la Ligue sur le Plateau Indigo
## (`bldg_ligue_01`, 8 × 6, porte (9..10, 5)). Objets peints ordinaires (`WorldProp`, emprise et
## ombres de `PaintedPropRules`, porte libre) ; la logique de la carte ne change pas.
##
## Passe APRÈS `build_j29.gd` et `build_route_22_west.gd` ; idempotente.
##
##   godot --headless --path . -s res://tools/build_daf4_facades.gd

const MAPS_DIR: String = "res://game/world/maps/"
const PROPS: String = "res://game/world/props/painted/"
const TILE: int = 96
## Carte → [objet peint, pied (cases : x au milieu de l'emprise, y = bas de l'emprise)].
const FACADES: Dictionary = {
	&"route_22_west": ["bldg_poste_route_22_01", Vector2(8.5, 6.0)],
	&"indigo_plateau": ["bldg_ligue_01", Vector2(10.0, 6.0)],
}
const NODE_NAME: String = "Daf4Facade"

var _errors: int = 0


func _init() -> void:
	for map_id: StringName in FACADES:
		_build(map_id)
	quit(1 if _errors > 0 else 0)


func _build(map_id: StringName) -> void:
	var path := MAPS_DIR + "%s.tscn" % map_id
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	var entities := root.get_node(^"Entities")
	var removed := 0
	for child: Node in entities.get_children():
		var child_name := String(child.name)
		if child_name == NODE_NAME:
			entities.remove_child(child)
			child.free()
		elif child_name == "Batiment" or child_name.begins_with("Porte"):
			for drawing: Node in child.get_children():
				if drawing is Polygon2D:
					child.remove_child(drawing)
					drawing.free()
					removed += 1
	var spec: Array = FACADES[map_id]
	var prop := (load(PROPS + spec[0] + ".tscn") as PackedScene).instantiate(
		PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = NODE_NAME
	prop.position = (spec[1] as Vector2) * TILE
	entities.add_child(prop)
	prop.owner = root
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s : %s (%s, %d dessins retirés)" % [map_id, error_string(err), spec[0], removed])
	if err != OK:
		_errors += 1
	root.free()
