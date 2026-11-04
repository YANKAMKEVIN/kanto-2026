extends SceneTree
## Bouche de la grotte marine à Bourg Palette (Chapitre Johto, jalon JOH1 ; dossier JOH-02 §3.1,
## `docs/tech/jalon-joh1.md` §2.3) : passe **idempotente** sur `pallet_town.tscn` (modèle des
## passes DAF : elle retire d'abord ses propres nœuds, préfixe `Joh1`), qui ne touche ni aux
## calques de tuiles ni aux cases bloquées : la géométrie figée du jalon 6
## (`tests/fixtures/maps/pallet_town_logic.txt`, `test_pallet_town_painted`) reste la même.
##
## Ajoute :
##   - l'eau de la mer surfable (`surf_cells` : les cases d'eau des rangées ≥ 28 de la grille
##     figée, rivage et canal compris ; la Route 21 n'a toujours pas de passage) ;
##   - la bouche (22..25, 33), dernière rangée, à l'est du ponton, dans l'eau : quatre [WarpPoint]
##     PUSH ↓ vers `sea_cave_1` / `from_pallet_town`, `_1`, `_2`, `_3`, **`if_flags:
##     [johto_letter_read]`** (avant la lettre : bord de carte ordinaire) ; arrivées `from_sea_cave`,
##     `_1`… sur ces cases, en Surf forcé ;
##   - le décor : [FlagGate] `Joh1GrotteOuverte` (`if johto_letter_read`, bouche sombre en aplats)
##     et `Joh1GrotteFermee` (`unless`, rochers) ; point d'examen `Joh1GrotteExamen` (tourné ↓,
##     dialogue `pallet_cave_mouth`, O-5, `if johto_letter_read`).
## Aplats provisoires : le décor peint de la bouche vient avec le lot d'art de Johto.
##
##   godot --headless --path . -s res://tools/build_joh1_pallet_cave.gd

const MAP_PATH: String = "res://game/world/maps/pallet_town.tscn"
const LOGIC_PATH: String = "res://tests/fixtures/maps/pallet_town_logic.txt"
const OWN_PREFIX: String = "Joh1"
const TILE: int = 96
const PUSH: int = 1
const SEA_FIRST_ROW: int = 28
const MOUTH_CELLS: Array[Vector2i] = [Vector2i(22, 33), Vector2i(23, 33), Vector2i(24, 33),
	Vector2i(25, 33)]
const TARGET_MAP: StringName = &"sea_cave_1"
const TARGET_SPAWN: String = "from_pallet_town"
const SPAWN: String = "from_sea_cave"
const FLAG: StringName = &"johto_letter_read"
const DIALOGUE: StringName = &"pallet_cave_mouth"
const ROCK := Color(0.42, 0.40, 0.38)
const ROCK_DARK := Color(0.28, 0.27, 0.26)
const MOUTH := Color(0.05, 0.07, 0.11)
const MOUTH_RIM := Color(0.16, 0.2, 0.26)

var _errors: int = 0


func _init() -> void:
	quit(_build())


func _build() -> int:
	var scene := load(MAP_PATH) as PackedScene
	if scene == null:
		push_error("build_joh1_pallet_cave : scène introuvable %s" % MAP_PATH)
		return 1
	var root := scene.instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean(root)
	var size: Vector2i = root.get(&"size")
	# Mer surfable, lue dans la grille figée (jamais la scène : aucune reconstruction de grille ici).
	var surf := _sea_cells(size)
	if surf.is_empty():
		push_error("build_joh1_pallet_cave : grille figée illisible %s" % LOGIC_PATH)
		root.free()
		return 1
	for cell: Vector2i in MOUTH_CELLS:
		if not surf.has(cell):
			push_error("build_joh1_pallet_cave : %s n'est pas une case d'eau" % cell)
			_errors += 1
	root.set(&"surf_cells", surf)
	var forced: Array[Vector2i] = []
	forced.assign(MOUTH_CELLS)
	root.set(&"forced_surf_cells", forced)
	var spawns := root.get_node(^"Spawns")
	var warps := root.get_node(^"Warps")
	var entities := root.get_node(^"Entities")
	var interactables := root.get_node_or_null(^"Interactables")
	if interactables == null:
		interactables = Node2D.new()
		interactables.name = "Interactables"
		_attach(root, root, interactables)
	for i: int in MOUTH_CELLS.size():
		var cell := MOUTH_CELLS[i]
		var marker := Marker2D.new()
		marker.name = SPAWN if i == 0 else "%s_%d" % [SPAWN, i]
		marker.position = _world(cell)
		_attach(root, spawns, marker)
		var point := Marker2D.new()
		point.set_script(load("res://game/world/warp_point.gd"))
		point.name = "%sGrotte_%d" % [OWN_PREFIX, i]
		point.position = _world(cell)
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.DOWN)
		point.set(&"target_map", TARGET_MAP)
		point.set(&"target_spawn", StringName(TARGET_SPAWN if i == 0 else "%s_%d" % [TARGET_SPAWN, i]))
		point.set(&"arrival_facing", Vector2i.DOWN)
		var if_flags: Array[StringName] = [FLAG]
		point.set(&"if_flags", if_flags)
		_attach(root, warps, point)
	# Décor : la bouche ouverte, les rochers fermés (pied au bas de la rangée 33).
	var foot := Vector2((MOUTH_CELLS[0].x + 2.0) * TILE, (MOUTH_CELLS[0].y + 1) * TILE)
	var open := _gate(root, entities, OWN_PREFIX + "GrotteOuverte", foot, [FLAG], [])
	_rect(root, open, Rect2(-2.0 * TILE, -1.4 * TILE, 4.0 * TILE, 1.4 * TILE), ROCK)
	_rect(root, open, Rect2(-1.6 * TILE, -1.1 * TILE, 3.2 * TILE, 1.1 * TILE), MOUTH_RIM)
	_rect(root, open, Rect2(-1.3 * TILE, -0.9 * TILE, 2.6 * TILE, 0.9 * TILE), MOUTH)
	var closed := _gate(root, entities, OWN_PREFIX + "GrotteFermee", foot, [], [FLAG])
	_rect(root, closed, Rect2(-2.0 * TILE, -1.0 * TILE, 4.0 * TILE, 1.0 * TILE), ROCK)
	for x: float in [-1.6, -0.5, 0.7]:
		_rect(root, closed, Rect2(x * TILE, -1.35 * TILE, 0.9 * TILE, 0.6 * TILE), ROCK_DARK)
	var examine := Marker2D.new()
	examine.set_script(load("res://game/world/interactions/interact_point.gd"))
	examine.name = OWN_PREFIX + "GrotteExamen"
	examine.position = _world(MOUTH_CELLS[0])
	examine.set(&"size", Vector2i(MOUTH_CELLS.size(), 1))
	examine.set(&"facing", Vector2i.DOWN)
	examine.set(&"dialogue_id", DIALOGUE)
	var examine_if: Array[StringName] = [FLAG]
	examine.set(&"if_flags", examine_if)
	_attach(root, interactables, examine)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, MAP_PATH)
	print("build_joh1_pallet_cave : %s (%d cases surfables)" % [error_string(err), surf.size()])
	root.free()
	return 0 if err == OK and _errors == 0 else 1


## Cases d'eau de la mer (rangées ≥ [constant SEA_FIRST_ROW]) de la grille figée.
func _sea_cells(size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var text := FileAccess.get_file_as_string(LOGIC_PATH)
	var rows := text.split("\n", false)
	if rows.size() < size.y:
		return cells
	for y: int in range(SEA_FIRST_ROW, size.y):
		for x: int in mini(size.x, rows[y].length()):
			if rows[y][x] == "~":
				cells.append(Vector2i(x, y))
	return cells


func _clean(root: Node) -> void:
	for group: NodePath in [^"Entities", ^"Warps", ^"Interactables"]:
		var parent := root.get_node_or_null(group)
		if parent == null:
			continue
		for child: Node in parent.get_children():
			if String(child.name).begins_with(OWN_PREFIX):
				parent.remove_child(child)
				child.free()
	var spawns := root.get_node(^"Spawns")
	for child: Node in spawns.get_children():
		if String(child.name) == SPAWN or String(child.name).begins_with(SPAWN + "_"):
			spawns.remove_child(child)
			child.free()


func _gate(root: Node, parent: Node, gate_name: String, foot: Vector2, if_flags: Array,
		unless: Array) -> Node2D:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = gate_name
	gate.position = foot
	var typed_if: Array[StringName] = []
	typed_if.assign(if_flags)
	var typed_unless: Array[StringName] = []
	typed_unless.assign(unless)
	gate.set(&"if_flags", typed_if)
	gate.set(&"unless_flags", typed_unless)
	_attach(root, parent, gate)
	return gate


func _rect(root: Node, parent: Node, rect: Rect2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = "Dessin%d" % parent.get_child_count()
	poly.color = color
	poly.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)])
	_attach(root, parent, poly)


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root
