extends SceneTree
## Construit les intérieurs **peints** du jalon 7 (docs/tech/jalon-07.md §6.3, §6.6) :
##   viridian_center — le Centre Pokémon de Jadielle (T8)
## (la Boutique, T12, viendra ici à son tour ; tools/build_viridian_shells.gd ne construit plus
## que sa coquille vide).
##
##   godot --headless --path . -s res://tools/build_painted_interiors.gd
##   godot --headless --path . --import
##
## Principe (§6.6, « intérieurs enveloppe vide + meubles séparés ») : l'enveloppe peinte de la
## pièce (15 × 10 cases, sprite opaque du sol, z −3) ; les meubles = scènes peintes
## `game/world/props/painted/<id>.tscn` (WorldProp, emprises de PaintedPropRules) dans
## `Entities` (tri par les pieds) ; les murs = cases bloquées (`GameMap.blocked_cells`) relevées
## sur l'enveloppe ; aucun TileMapLayer. Agencement : prototype validé par Kevin
## (`proto/da-jadielle:proto/da_jadielle/proto_interieur.gd`), colonnes posées sur la grille
## pour que les emprises tombent sous les images (banquettes en x = 3 et 12, symétriques).
##
## Coordonnées en cases (x vers l'est, y vers le sud). Un meuble : [identifiant, case d'ancrage,
## pied en cases (y, peut remonter dans la case d'ancrage comme au prototype), nom du nœud].

const MAPS_DIR := "res://game/world/maps/"
const PROPS_DIR := "res://game/world/props/painted/"
const RULES_SCRIPT := "res://game/world/props/painted_prop_rules.gd"
const TILE := 96
## Warp.Trigger (valeurs).
const PUSH := 1
## Interaction.Kind (valeurs).
const TALK := 0
## WorldLighting.Z_GROUND.
const Z_GROUND := -3

var _rules: GDScript
var _scenes: Dictionary = {}


func _init() -> void:
	_rules = load(RULES_SCRIPT)
	var errors := 0
	for room: Dictionary in [_viridian_center()]:
		var root := _build(room)
		var packed := PackedScene.new()
		var err := packed.pack(root)
		var path := MAPS_DIR + "%s.tscn" % room["id"]
		if err == OK:
			err = ResourceSaver.save(packed, path)
		print("%s : %s" % [room["id"], error_string(err)])
		if err != OK:
			errors += 1
		root.free()
	quit(1 if errors > 0 else 0)


## Centre Pokémon de Jadielle (dossier 09 §7) : comptoir au milieu (infirmière derrière, machine
## de soin à droite du plateau), terminal du Stockage au nord-ouest (posé **inerte** jusqu'au
## T16), deux banquettes, trois plantes ; pas d'escalier ni de Leveinard (arbitrages du dossier).
func _viridian_center() -> Dictionary:
	return {
		"id": &"viridian_center", "node": "ViridianCenter", "size": Vector2i(15, 10),
		"shell": "res://assets/world/interiors/int_centre_coque.png",
		"title": "Jadielle", "light": &"interior_warm",
		# Mur du fond : 3 rangées (prototype) ; derrière le comptoir : l'infirmière seule.
		"back_rows": 3,
		"exit": [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)],
		"exit_target": [&"viridian_city", &"from_center"],
		"blocked": [Vector2i(5, 3), Vector2i(6, 3), Vector2i(8, 3), Vector2i(9, 3)],
		"props": [
			[&"int_centre_comptoir", Vector2i(7, 4), 5.0, "Counter"],
			[&"int_centre_terminal", Vector2i(2, 3), 3.4, "StorageTerminal"],
			[&"int_plante", Vector2i(12, 3), 3.4, "PlantNorthEast"],
			[&"int_centre_banquette", Vector2i(3, 7), 7.2, "BenchWest"],
			[&"int_centre_banquette", Vector2i(12, 7), 7.2, "BenchEast"],
			[&"int_plante", Vector2i(1, 8), 8.8, "PlantSouthWest"],
			[&"int_plante", Vector2i(13, 8), 8.8, "PlantSouthEast"],
		],
		# Machine de soin : halos sur les six alvéoles du plateau peint dans le comptoir (pixels
		# de l'image du comptoir relevés : rangée du fond puis de devant, de gauche à droite),
		# relatifs à l'origine de la machine, posée 1 px devant le pied du comptoir.
		"machine": {
			"name": "HealMachine", "position": Vector2(720, 481), "attendant": &"nurse",
			"turn": Vector2i.RIGHT,
			"slots": [Vector2(120, -130), Vector2(146, -130), Vector2(171, -130),
				Vector2(122, -116), Vector2(148, -116), Vector2(173, -116)],
			"flash": Vector2(147, -123),
		},
		# Parler à l'infirmière par-dessus le comptoir (trois cases devant elle, tourné vers le
		# haut).
		"interactables": [["NurseCounter", Vector2i(6, 4), Vector2i(3, 1), &"nurse", TALK,
			Vector2i.UP]],
		"spawns": {"entrance": Vector2i(7, 8), "heal": Vector2i(7, 5)},
	}


func _build(room: Dictionary) -> Node2D:
	var size: Vector2i = room["size"]
	var root := Node2D.new()
	root.name = room["node"]
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", room["id"])
	root.set(&"display_name", room["title"])
	root.set(&"size", size)
	root.set(&"interior", true)
	root.set(&"light_profile", room["light"])
	root.set(&"blocked_cells", _walls(room))
	var shell := Sprite2D.new()
	shell.name = "Shell"
	shell.texture = load(room["shell"])
	shell.centered = false
	shell.z_index = Z_GROUND
	_attach(root, root, shell)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, root, entities)
	entities.unique_name_in_owner = true
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(root, root, node)
	for entry: Array in room["props"]:
		_add_prop(root, entities, entry[0], entry[1], entry[2], entry[3])
	if room.has("machine"):
		_add_machine(root, entities, room["machine"])
	var spawns: Dictionary = room["spawns"]
	for spawn_name: String in spawns:
		var marker := Marker2D.new()
		marker.name = spawn_name
		marker.position = _world(spawns[spawn_name])
		_attach(root, root.get_node(^"Spawns"), marker)
	var warp_script: GDScript = load("res://game/world/warp_point.gd")
	var target: Array = room["exit_target"]
	var index := 0
	for cell: Vector2i in room["exit"]:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = "Exit%d" % index
		point.position = _world(cell)
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.DOWN)
		point.set(&"target_map", target[0])
		point.set(&"target_spawn", target[1])
		point.set(&"arrival_facing", Vector2i.DOWN)
		_attach(root, root.get_node(^"Warps"), point)
		index += 1
	var point_script: GDScript = load("res://game/world/interactions/interact_point.gd")
	for entry: Array in room.get("interactables", []):
		var point := Marker2D.new()
		point.set_script(point_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"size", entry[2])
		point.set(&"dialogue_id", entry[3])
		point.set(&"kind", entry[4])
		point.set(&"facing", entry[5])
		_attach(root, root.get_node(^"Interactables"), point)
	return root


## Murs de l'enveloppe : les rangées du fond, les colonnes de côté, l'avant-dernière rangée sauf
## la sortie (le paillasson), la dernière rangée ; plus les cases listées (« blocked »).
func _walls(room: Dictionary) -> Array[Vector2i]:
	var size: Vector2i = room["size"]
	var exit: Array = room["exit"]
	var extra: Array = room.get("blocked", [])
	var cells: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			var wall := y < int(room["back_rows"]) or y == size.y - 1 or x == 0 \
				or x == size.x - 1 or extra.has(cell)
			if y == size.y - 2 and not exit.has(cell):
				wall = true
			if wall:
				cells.append(cell)
	return cells


func _add_prop(root: Node, parent: Node, id: StringName, anchor: Vector2i, foot_y: float,
		node_name: String) -> void:
	if not _scenes.has(id):
		_scenes[id] = load(PROPS_DIR + String(id) + ".tscn")
	var scene: PackedScene = _scenes[id]
	var prop := scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	var foot: Vector2 = _rules.call(&"foot_position", id, anchor)
	foot.y = roundf(foot_y * TILE)
	prop.position = foot
	if Vector2i(floori(foot.x / TILE), ceili(foot.y / TILE) - 1) != anchor:
		push_error("%s : le pied %s n'est pas dans la case %s" % [node_name, foot, anchor])
	_attach(root, parent, prop)


func _add_machine(root: Node, parent: Node, spec: Dictionary) -> void:
	var machine := Node2D.new()
	machine.set_script(load("res://game/world/props/heal_machine.gd"))
	machine.name = spec["name"]
	machine.position = spec["position"]
	var slots: Array[Vector2] = []
	slots.assign(spec["slots"])
	machine.set(&"slot_offsets", slots)
	machine.set(&"flash_offset", spec["flash"])
	machine.set(&"attendant", spec["attendant"])
	machine.set(&"attendant_turn", spec["turn"])
	_attach(root, parent, machine)
	machine.unique_name_in_owner = true


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root
