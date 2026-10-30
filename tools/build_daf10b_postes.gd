extends SceneTree
## Lot DAF.10b (`tools/art/daf10b.py`, fiche `docs/design/fiches-assets/daf-10b/fiche.md`, RP-272
## pour les postes des routes) : repeint les postes écrits en tuiles provisoires par
## `build_j22_maps.gd` (`route_15_gate`, `route_15_gate_2f`, `route_16_gate`, `route_18_gate`).
##
## Seconde passe, idempotente. **La logique ne change pas** (gel du J33) : couches de tuiles
## masquées, `blocked_cells`, passages, déclencheurs et PNJ gardés. L'image : enveloppe peinte
## (`Daf10bShell`, un `Sprite2D` de la taille de la pièce, neuve, Codex) et meubles du kit posés
## **sans emprise** sur les cases bloquées de la grille (comptoirs `N`, bibliothèques `B`,
## plantes `x`, jumelles `J` [D : petits meubles]), escaliers sur les cases `U`. Lumière `interior_warm` [D], comme
## le poste de la Route 12.
## Contrôle : `tools/dump_map_logic.gd` et `tools/dump_map_nodes.gd` identiques avant / après.
##
##   godot --headless --path . -s res://tools/build_daf10b_postes.gd

const TILE: int = 96
const PROPS_DIR: String = "res://game/world/props/painted/"
const SHELLS: String = "res://assets/world/interiors/%s.png"
const PREFIX: String = "Daf10b"
const Z_GROUND: int = -3
## Pièce → [enveloppe, meubles : [objet, première case, dernière case, échelle, nœud]].
const ROOMS: Dictionary = {
	&"route_15_gate": ["int_poste_traversant_coque", [
		[&"int_grande_etagere_01", Vector2i(1, 3), Vector2i(2, 3), 1.0, "Bookshelf"],
		[&"int_comptoir_pension_01", Vector2i(5, 4), Vector2i(7, 4), 1.0, "Counter"],
		[&"int_escalier_montant_01", Vector2i(10, 3), Vector2i(10, 3), 0.5, "StairsUp"],
		[&"int_plante", Vector2i(1, 7), Vector2i(1, 7), 1.0, "PlantWest"],
		[&"int_plante", Vector2i(10, 7), Vector2i(10, 7), 1.0, "PlantEast"],
	]],
	&"route_15_gate_2f": ["int_poste_etage_coque", [
		# [D] Jumelles : petits meubles en attendant l'image des jumelles (Codex, fiche).
		[&"int_petite_etagere_01", Vector2i(2, 3), Vector2i(2, 3), 1.0, "BinocularsWest"],
		[&"int_petite_etagere_01", Vector2i(7, 3), Vector2i(7, 3), 1.0, "BinocularsEast"],
		[&"int_escalier_descendant_01", Vector2i(10, 3), Vector2i(10, 3), 0.5, "StairsDown"],
		[&"int_banc_piscine_01", Vector2i(2, 6), Vector2i(3, 6), 1.0, "Bench"],
		[&"int_plante", Vector2i(1, 7), Vector2i(1, 7), 1.0, "PlantWest"],
		[&"int_plante", Vector2i(10, 7), Vector2i(10, 7), 1.0, "PlantEast"],
	]],
	&"route_16_gate": ["int_poste_16_coque", [
		[&"int_plante", Vector2i(1, 3), Vector2i(1, 3), 1.0, "PlantWest"],
		[&"int_plante", Vector2i(12, 3), Vector2i(12, 3), 1.0, "PlantEast"],
		[&"int_petite_etagere_01", Vector2i(5, 5), Vector2i(5, 5), 1.0, "CabinetWest"],
		[&"int_petite_etagere_01", Vector2i(7, 5), Vector2i(7, 5), 1.0, "CabinetEast"],
	]],
	&"route_18_gate": ["int_poste_traversant_coque", [
		[&"int_grande_etagere_01", Vector2i(7, 3), Vector2i(8, 3), 1.0, "Bookshelf"],
		[&"int_comptoir_pension_01", Vector2i(2, 4), Vector2i(4, 4), 1.0, "Counter"],
		[&"int_plante", Vector2i(10, 3), Vector2i(10, 3), 1.0, "PlantNorth"],
		[&"int_plante", Vector2i(10, 7), Vector2i(10, 7), 1.0, "PlantSouth"],
	]],
}

var _rules: GDScript = load("res://game/world/props/painted_prop_rules.gd")
var _errors: int = 0


func _init() -> void:
	for map_id: StringName in ROOMS:
		_build(map_id)
	quit(1 if _errors > 0 else 0)


func _build(map_id: StringName) -> void:
	var spec: Array = ROOMS[map_id]
	var shell_path := SHELLS % spec[0]
	if not ResourceLoader.exists(shell_path):
		push_error("%s : enveloppe absente %s (daf10b.py --modules, puis --import)"
			% [map_id, shell_path])
		_errors += 1
		return
	var path := "res://game/world/maps/%s.tscn" % map_id
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean(root)
	for layer: Node in root.get_children():
		if layer is TileMapLayer:
			(layer as TileMapLayer).visible = false
	var size: Vector2i = root.get(&"size")
	var shell := Sprite2D.new()
	shell.name = PREFIX + "Shell"
	shell.texture = load(shell_path)
	shell.centered = false
	shell.z_index = Z_GROUND
	if shell.texture.get_size() != Vector2(size * TILE):
		push_error("%s : enveloppe %s ≠ %s cases" % [map_id, shell.texture.get_size(), size])
		_errors += 1
	root.add_child(shell)
	shell.owner = root
	root.move_child(shell, root.get_node(^"Obstacles").get_index() + 1)
	var blocked: Array = root.get(&"blocked_cells")
	var entities := root.get_node(^"Entities")
	for entry: Array in spec[1]:
		var id: StringName = entry[0]
		var first: Vector2i = entry[1]
		var last: Vector2i = entry[2]
		var scale: float = entry[3]
		var cells: Array[Vector2i] = _rules.call(&"footprint", id)
		var foot: Vector2
		if cells.is_empty() or scale != 1.0:
			# Objet traversable ou réduit à une case : pied au bas du milieu de ses cases.
			foot = Vector2((first.x + last.x + 1) / 2.0, last.y + 1) * TILE
		else:
			var low := Vector2i(1000, 1000)
			for cell: Vector2i in cells:
				low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
			var anchor := Vector2i(first.x - low.x, last.y)
			foot = _rules.call(&"foot_position", id, anchor)
			for cell: Vector2i in cells:
				if not blocked.has(anchor + cell) and anchor.y + cell.y == last.y:
					push_error("%s/%s : %s praticable" % [map_id, entry[4], anchor + cell])
					_errors += 1
		var prop := (load(PROPS_DIR + String(id) + ".tscn") as PackedScene).instantiate(
			PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
		prop.name = PREFIX + String(entry[4])
		prop.position = foot.round()
		prop.scale = Vector2(scale, scale)
		prop.set(&"footprint", [] as Array[Vector2i])
		entities.add_child(prop)
		prop.owner = root
	if StringName(root.get(&"light_profile")) == &"":
		root.set(&"light_profile", &"interior_warm")
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s : %s (%d meubles)" % [map_id, error_string(err), (spec[1] as Array).size()])
	if err != OK:
		_errors += 1
	root.free()


func _clean(root: Node) -> void:
	for parent: Node in [root, root.get_node(^"Entities")]:
		for child: Node in parent.get_children():
			if String(child.name).begins_with(PREFIX):
				parent.remove_child(child)
				child.free()
