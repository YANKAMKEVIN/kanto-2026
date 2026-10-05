extends SceneTree
## **Provisoire (T4)** : construit l'intérieur **vide** de la Boutique de Jadielle
## (game/world/maps/viridian_mart.tscn), pour que sa porte mène quelque part. L'intérieur jouable
## (meubles, marchand) est la tâche T12 de docs/tech/jalon-07.md, qui **remplace** cette carte
## (dans tools/build_painted_interiors.gd) et retire cet outil. Le Centre (T8) est déjà construit
## par tools/build_painted_interiors.gd.
##
##   godot --headless --path . -s res://tools/build_viridian_shells.gd
##
## Chaque carte : l'enveloppe peinte (15 × 10 cases, sprite opaque du sol, z −3) ; murs =
## cases bloquées (deux rangées du fond, colonnes de côté, mur du bas sauf le paillasson) ;
## sortie = trois cases PUSH vers le bas sur le paillasson ; spawn « entrance » au milieu ;
## lumière `interior_warm` ; aucun PNJ.

const SIZE := Vector2i(15, 10)
const TILE := 96
const PUSH := 1
## WorldLighting.Z_GROUND.
const Z_GROUND := -3
## Cases du paillasson (rangée 8), sortie vers Jadielle.
const EXIT_CELLS: Array[Vector2i] = [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)]
const ENTRANCE := Vector2i(7, 8)
## [identifiant de carte, nom du nœud, enveloppe, spawn de retour dans Jadielle]. Titre de
## carte = nom de la ville (règle des intérieurs, test_zone_names_match_the_map_titles).
const SHELLS: Array = [
	[&"viridian_mart", "ViridianMart",
		"res://assets/world/interiors/int_boutique_coque.png", &"from_mart"],
]


func _init() -> void:
	var errors := 0
	for shell: Array in SHELLS:
		var root := _build(shell)
		var packed := PackedScene.new()
		var err := packed.pack(root)
		var path := "res://game/world/maps/%s.tscn" % shell[0]
		if err == OK:
			err = ResourceSaver.save(packed, path)
		print("%s : %s" % [shell[0], error_string(err)])
		if err != OK:
			errors += 1
		root.free()
	quit(1 if errors > 0 else 0)


func _build(shell: Array) -> Node2D:
	var root := Node2D.new()
	root.name = shell[1]
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", shell[0])
	root.set(&"display_name", "Jadielle")
	root.set(&"size", SIZE)
	root.set(&"interior", true)
	root.set(&"light_profile", &"interior_warm")
	root.set(&"blocked_cells", _walls())
	var floor_sprite := Sprite2D.new()
	floor_sprite.name = "Shell"
	floor_sprite.texture = load(shell[2])
	floor_sprite.centered = false
	floor_sprite.z_index = Z_GROUND
	_attach(root, root, floor_sprite)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, root, entities)
	entities.unique_name_in_owner = true
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(root, root, node)
	var marker := Marker2D.new()
	marker.name = "entrance"
	marker.position = _world(ENTRANCE)
	_attach(root, root.get_node(^"Spawns"), marker)
	var warp_script: GDScript = load("res://game/world/warp_point.gd")
	var index := 0
	for cell: Vector2i in EXIT_CELLS:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = "Exit%d" % index
		point.position = _world(cell)
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.DOWN)
		point.set(&"target_map", &"viridian_city")
		point.set(&"target_spawn", shell[3])
		point.set(&"arrival_facing", Vector2i.DOWN)
		_attach(root, root.get_node(^"Warps"), point)
		index += 1
	return root


## Murs de l'enveloppe : rangées 0–1 (mur du fond), colonnes 0 et 14, rangée 8 sauf le
## paillasson, rangée 9.
func _walls() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			var wall := y <= 1 or y == SIZE.y - 1 or x == 0 or x == SIZE.x - 1
			if y == SIZE.y - 2 and not EXIT_CELLS.has(cell):
				wall = true
			if wall:
				cells.append(cell)
	return cells


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root
