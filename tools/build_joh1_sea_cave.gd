extends SceneTree
## Construit les deux salles de la grotte marine (Chapitre Johto, jalon JOH1 ; dossier JOH-02 §3.2,
## `docs/tech/jalon-joh1.md` §2.1, §2.2), en tuiles provisoires (`OverworldTiles`), d'après les
## grilles validées `tools/plans/grotte_marine_1.txt` et `grotte_marine_2.txt` (la grille fait
## foi ; contrôle `tools/art/plan_check_joh1.py`). Même méthode que la Grotte Azurée
## (`tools/build_cerulean_cave.gd`) et les Îles Écume (courants).
##
## Par salle :
##   - sol : paroi `#` et rochers `o` (falaise), îlots `.` (terre), plage `g` et sortie `E`
##     (sable), eau `w d > v` (eau surfable : `surf_cells`) ; aucune case pêchable [D] ;
##   - courants : `>` de la salle 1 permanents (`current_cells`) ; chenal `v` de la salle 2 =
##     [CurrentGate] `CourantChenal`, actif tant que `johto_team_returned` est bas (la grille dit
##     `actif_sans=johto_act2` : alias [constant FLAG_ALIASES], plan §2.2 [D]) ;
##   - arrivées de la grille (`<id>`, `<id>_1`… une par case, Surf forcé si `surf=1`) ;
##   - passages ([constant WARPS]) : salle 1 ↔ Bourg Palette (PUSH ↑, `from_sea_cave`), salle 1 ↔
##     salle 2 (PUSH), salle 2 → Oliville (STEP_ON ↓, `from_sea_cave`, tourné →) ;
##   - déclencheurs : `ombre_lugia` (scène `sea_cave_lugia_shadow`), `courant_retour` (↑, scène
##     `sea_cave_current_back`) ; `legende_grotte` n'est pas posé (la description O-24 est celle de
##     la zone `sea_cave`, plan §2.1 [D]) ;
##   - l'ombre de Lugia (salle 2) : [FlagGate] `LugiaShadow` (`if johto_lugia_passing`, levé puis
##     baissé par la scène) portant le sprite provisoire `lugia_shadow.png`
##     (`tools/build_joh1_placeholders.gd`), déplacé par l'étape `animate` de la scène ; placé
##     entre le sol et `Entities` (sous le joueur).
## Objets visibles (Perle, Rappel Max) : PNJ de `data/npcs/sea_cave_*.json` (scènes `give`).
## Lumière : profil `sea_cave` (`data/world/lighting.json`) ; Vol interdit (`no_fly`) [D].
##
##   godot --headless --path . -s res://tools/build_joh1_sea_cave.gd
##   godot --headless --path . --import

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const SHADOW_TEXTURE: String = "res://assets/world/props/placeholder/lugia_shadow.png"
## Warp.Trigger (les scripts d'outil lisent les enums par valeur).
const STEP_ON: int = 0
const PUSH: int = 1
const MAPS: Dictionary = {&"sea_cave_1": "grotte_marine_1", &"sea_cave_2": "grotte_marine_2"}
const DISPLAY_NAME: String = "Grotte marine"
const REGION: String = "Bourg Palette — Oliville"
const LIGHT: StringName = &"sea_cave"
const SOLID_CHARS: String = "#o"
const WATER_CHARS: String = "wd>v"
const SAND_CHARS: String = "gE"
const CURRENTS: Dictionary = {">": Vector2i.RIGHT, "v": Vector2i.DOWN, "<": Vector2i.LEFT,
	"^": Vector2i.UP}
const SENSES: Dictionary = {"bas": Vector2i.DOWN, "haut": Vector2i.UP, "gauche": Vector2i.LEFT,
	"droite": Vector2i.RIGHT}
## Drapeau de la grille → drapeau du jeu (plan §2.2 [D] : la fin de l'acte 1 est
## `johto_team_returned`, JOH0).
const FLAG_ALIASES: Dictionary = {"johto_act2": "johto_team_returned"}
## Passages : carte → position de la grille → [déclenchement, direction, carte cible, arrivée
## (suffixe `_n` par case de rang n), orientation à l'arrivée].
const WARPS: Dictionary = {
	&"sea_cave_1": {
		"warp_nord": [PUSH, Vector2i.UP, &"pallet_town", "from_sea_cave", Vector2i.UP],
		"warp_sud": [PUSH, Vector2i.DOWN, &"sea_cave_2", "from_sea_cave_1", Vector2i.DOWN],
	},
	&"sea_cave_2": {
		"warp_nord": [PUSH, Vector2i.UP, &"sea_cave_1", "from_sea_cave_2", Vector2i.UP],
		"warp_sud": [STEP_ON, Vector2i.DOWN, &"olivine_city", "from_sea_cave", Vector2i.RIGHT],
	},
}
## Déclencheurs : position de la grille → [scène, direction du pas (ZERO = toutes)].
const TRIGGERS: Dictionary = {
	"ombre_lugia": [&"sea_cave_lugia_shadow", Vector2i.ZERO],
	"courant_retour": [&"sea_cave_current_back", Vector2i.UP],
}
## Ombre de Lugia (salle 2) : case de départ (bord ouest de l'eau profonde, rangée du
## déclencheur) ; la scène la déplace de 11 cases vers l'est.
const SHADOW_MAP: StringName = &"sea_cave_2"
const SHADOW_START := Vector2i(9, 17)
const SHADOW_FLAG: StringName = &"johto_lugia_passing"
const SHADOW_SCALE: float = 2.0
## Arrivées de débogage [D] : devant la rangée de l'ombre (en Surf, 6 cases au nord).
const DEBUG_SPAWNS: Dictionary = {&"sea_cave_2": {"lugia_front": Vector2i(14, 11)}}

var _over: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_rng.seed = 3101
	for id: StringName in MAPS:
		_build(id)
	print("build_joh1_sea_cave : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _build(map_id: StringName) -> void:
	var plan := _plan(MAPS[map_id])
	if plan == null:
		return
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map(String(map_id).to_pascal_case(), map_id, size)
	_paint(root, plan)
	var entities: Node = root.get_node(^"Entities")
	# Eau surfable.
	var surf: Array[Vector2i] = []
	surf.assign(plan.cells_of(WATER_CHARS))
	root.set(&"surf_cells", surf)
	# Courants : ceux d'une position « courant » suivent un drapeau, les autres sont permanents.
	var gated: Dictionary = {}
	for id: String in _ids(plan, "courant"):
		var sense: String = plan.attr(id, "sens")
		if not SENSES.has(sense):
			_fail("%s : sens de courant inconnu « %s » (%s)" % [map_id, sense, id])
			continue
		var cells: Dictionary[Vector2i, Vector2i] = {}
		for cell: Vector2i in plan.cells_at(id):
			cells[cell] = SENSES[sense]
			gated[cell] = true
		var flag: String = plan.attr(id, "actif_sans")
		flag = FLAG_ALIASES.get(flag, flag)
		var unless: Array = [StringName(flag)] if not flag.is_empty() else []
		var gate := Node2D.new()
		gate.set_script(load("res://game/world/surf/current_gate.gd"))
		gate.name = id.to_pascal_case()
		gate.set(&"cells", cells)
		var typed_unless: Array[StringName] = []
		typed_unless.assign(unless)
		gate.set(&"unless_flags", typed_unless)
		_attach(root, entities, gate)
	var currents: Dictionary[Vector2i, Vector2i] = {}
	for c: String in CURRENTS:
		for cell: Vector2i in plan.cells_of(c):
			if not gated.has(cell):
				currents[cell] = CURRENTS[c]
	root.set(&"current_cells", currents)
	# Arrivées (une par case) et Surf forcé. Bord nord (QA A17, caméra) : la rangée 0 est bloquée
	# et entrées et arrivées passent à la rangée 1, comme le haut de la Route 1 à Bourg Palette
	# (BLOCKED_CELLS) : sinon le joueur arrive la tête hors de l'écran.
	var forced: Array[Vector2i] = []
	var top_row: Array[Vector2i] = []
	for id: String in _ids(plan, "spawn"):
		var cells: Array[Vector2i] = plan.cells_at(id)
		for i: int in cells.size():
			var cell := _off_top(cells[i])
			_spawn(root, id if i == 0 else "%s_%d" % [id, i], cell)
			if plan.attr(id, "surf") == "1":
				forced.append(cell)
	for id: String in _ids(plan, "warp"):
		for cell: Vector2i in plan.cells_at(id):
			if cell.y == 0:
				top_row.append(cell)
	root.set(&"forced_surf_cells", forced)
	root.set(&"blocked_cells", top_row)
	var debug: Dictionary = DEBUG_SPAWNS.get(map_id, {})
	for spawn_name: String in debug:
		_spawn(root, spawn_name, debug[spawn_name])
	# Passages.
	var warps: Dictionary = WARPS[map_id]
	for id: String in warps:
		if not plan.positions.has(id):
			_fail("%s : position « %s » absente de la grille" % [map_id, id])
			continue
		var spec: Array = warps[id]
		var cells: Array[Vector2i] = plan.cells_at(id)
		for i: int in cells.size():
			var arrival: String = spec[3] if i == 0 else "%s_%d" % [spec[3], i]
			_warp(root, "%s_%d" % [id.to_pascal_case(), i], _off_top(cells[i]), spec[0], spec[1],
				spec[2], StringName(arrival), spec[4])
	# Déclencheurs.
	for id: String in _ids(plan, "declencheur"):
		if not TRIGGERS.has(id):
			continue
		var spec: Array = TRIGGERS[id]
		_trigger(root, id.to_pascal_case(), plan.cells_at(id), spec[1], spec[0])
	if map_id == SHADOW_MAP:
		_shadow(root, entities)
	_save(root, MAPS_DIR + String(map_id) + ".tscn")


## Une case de la rangée 0 (bord nord) passe à la rangée 1 (voir les arrivées).
func _off_top(cell: Vector2i) -> Vector2i:
	return cell + Vector2i.DOWN if cell.y == 0 else cell


## Sol provisoire : un type de tuile par caractère.
func _paint(root: Node, plan: Object) -> void:
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var c: String = plan.at(cell)
			var kind: int = _over.Kind.DIRT
			if SOLID_CHARS.contains(c):
				kind = _over.Kind.CLIFF
			elif WATER_CHARS.contains(c):
				kind = _over.Kind.WATER
			elif SAND_CHARS.contains(c):
				kind = _over.Kind.SAND
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))


## L'ombre de Lugia : porte de drapeaux sous `Entities` (dessinée après le sol, avant le joueur).
func _shadow(root: Node, entities: Node) -> void:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = "LugiaShadow"
	gate.position = Vector2((SHADOW_START.x + 0.5) * TILE, (SHADOW_START.y + 0.5) * TILE)
	var if_flags: Array[StringName] = [SHADOW_FLAG]
	gate.set(&"if_flags", if_flags)
	gate.visible = false
	_attach(root, root, gate)
	root.move_child(gate, entities.get_index())
	var sprite := Sprite2D.new()
	sprite.name = "Ombre"
	sprite.texture = load(SHADOW_TEXTURE)
	if sprite.texture == null:
		_fail("ombre de Lugia : image absente %s (tools/build_joh1_placeholders.gd)" % SHADOW_TEXTURE)
	sprite.scale = Vector2.ONE * SHADOW_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_attach(root, gate, sprite)


## Identifiants des positions de type [param kind], dans l'ordre du fichier.
func _ids(plan: Object, kind: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in plan.positions:
		if plan.positions[id]["kind"] == kind:
			ids.append(id)
	return ids


func _plan(plan_id: String) -> Object:
	var plan := PlanGrid.new()
	if not plan.load_file(PLANS_DIR + plan_id + ".txt"):
		_fail(plan.error)
		return null
	return plan


func _new_map(node_name: String, map_id: StringName, size: Vector2i) -> Node2D:
	var root := Node2D.new()
	root.name = node_name
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", map_id)
	root.set(&"display_name", DISPLAY_NAME)
	root.set(&"region", REGION)
	root.set(&"size", size)
	root.set(&"interior", false)
	root.set(&"no_fly", true)
	root.set(&"light_profile", LIGHT)
	var tileset: TileSet = load(_over.TILESET_PATH)
	_add_layer(root, "Ground", tileset)
	_add_layer(root, "Detail", tileset)
	_add_layer(root, "Obstacles", tileset)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, root, entities)
	entities.unique_name_in_owner = true
	var overhead := _add_layer(root, "Overhead", tileset)
	overhead.z_index = 10
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(root, root, node)
	return root


func _spawn(root: Node, spawn_name: String, cell: Vector2i) -> void:
	var marker := Marker2D.new()
	marker.name = spawn_name
	marker.position = _world(cell)
	_attach(root, root.get_node(^"Spawns"), marker)


func _warp(root: Node, warp_name: String, cell: Vector2i, trigger: int, direction: Vector2i,
		target: StringName, spawn: StringName, facing: Vector2i) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = warp_name
	point.position = _world(cell)
	point.set(&"trigger", trigger)
	point.set(&"direction", direction)
	point.set(&"target_map", target)
	point.set(&"target_spawn", spawn)
	point.set(&"arrival_facing", facing)
	_attach(root, root.get_node(^"Warps"), point)


func _trigger(root: Node, node_name: String, cells: Array[Vector2i], direction: Vector2i,
		cutscene: StringName) -> void:
	var top_left := cells[0]
	var bottom_right := cells[0]
	for cell: Vector2i in cells:
		top_left = Vector2i(mini(top_left.x, cell.x), mini(top_left.y, cell.y))
		bottom_right = Vector2i(maxi(bottom_right.x, cell.x), maxi(bottom_right.y, cell.y))
	var point := Marker2D.new()
	point.set_script(load("res://game/world/triggers/event_trigger_point.gd"))
	point.name = node_name
	point.position = _world(Vector2i(top_left.x, bottom_right.y))
	point.set(&"size", bottom_right - top_left + Vector2i.ONE)
	point.set(&"direction", direction)
	point.set(&"cutscene_id", cutscene)
	_attach(root, root.get_node(^"Triggers"), point)


func _save(root: Node, path: String) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s : %s" % [path, "OK" if err == OK else "ERREUR %d" % err])
	if err != OK:
		_errors += 1
	root.free()


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


func _add_layer(root: Node, layer_name: String, tileset: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tileset
	_attach(root, root, layer)
	return layer


func _fail(message: String) -> void:
	push_error("build_joh1_sea_cave : " + message)
	_errors += 1
