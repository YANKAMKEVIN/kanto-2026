extends SceneTree
## Construit la carte extérieure d'Oliville (Chapitre Johto, jalon JOH1 T5 ; dossier JOH-02 §3.3,
## `docs/tech/jalon-joh1.md` §2.7), en tuiles provisoires (`OverworldTiles`), d'après la grille
## validée `tools/plans/oliville.txt` (la grille fait foi). Bâtiments peints du kit de Kanto
## (Centre, Boutique, maisons) ; Phare = tour provisoire en `Polygon2D` ; lampes de nuit =
## halos `LightGlow` du groupe `night_lights`, cachés le jour (`WorldLighting.set_night`).
## Les PNJ viennent de `data/npcs/olivine_city.json`.
## Arc des Pierres (JOHP2, `docs/tech/jalon-joh-pierres.md` §4.2, variante ARC de la grille) : le
## Goéland, silhouette provisoire amarrée au ponton est, [FlagGate] qui n'existe et ne bloque
## qu'avec `johto_stones_quest` ; arrivée `from_goeland` ; déclencheur de la mer du sud (A-13). La
## grille de base reste celle du sol ; rien ne change à l'écran sans ce drapeau.
## **Image** : la passe d'ambiance `tools/build_joh_ambiance.gd` repeint la carte (sol peint, forêt,
## falaise, mer, quai, phare peint) sans toucher à la logique ; la relancer après cet outil.
##
##   godot --headless --path . -s res://tools/build_joh1_olivine.gd

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const MAP_ID: StringName = &"olivine_city"
const PLAN: String = "res://tools/plans/oliville.txt"
const MAPS_DIR: String = "res://game/world/maps/"
const OUT: String = MAPS_DIR + "olivine_city.tscn"
const PROPS_DIR: String = "res://game/world/props/painted/"
const STEP_ON: int = 0
const PUSH: int = 1
const OUTDOOR_KINDS: Dictionary = {
	"T": "FOREST", "R": "CLIFF", ".": "GRASS", "p": "COBBLE", "g": "SAND", "q": "BOARDWALK",
	"w": "WATER", "x": "FOREST", "G": "FOREST", "y": "GRASS", "n": "GRASS", "k": "COBBLE",
	"C": "CLIFF", "O": "CLIFF", "m": "CLIFF", "N": "CLIFF", "P": "CLIFF", "D": "COBBLE",
	"E": "SAND",
}
## Cases d'aspect praticable mais bloquées (massif, banc, caisses).
const BLOCKED_CHARS: String = "ynk"
## Bâtiments peints : [prop, case d'ancrage].
const BUILDINGS: Array = [
	["bldg_centre_01", Vector2i(28, 19)],
	["bldg_boutique_01", Vector2i(38, 19)],
	["bldg_maison_argenta_01", Vector2i(16, 19)],
	["bldg_maison_argenta_01", Vector2i(37, 30)],
]
const LAMPPOSTS: Array[Vector2i] = [Vector2i(12, 19), Vector2i(22, 19), Vector2i(33, 19),
	Vector2i(44, 19)]
## Lampes de nuit, en cases (x, y) ; pixels = × 96.
const NIGHT_LIGHTS: Array[Vector2] = [
	Vector2(5.5, 8.0), Vector2(12, 18.3), Vector2(22, 18.3), Vector2(33, 18.3),
	Vector2(44, 18.3), Vector2(27.5, 18.6), Vector2(37.5, 18.6), Vector2(33, 32.6),
]
const LIGHTHOUSE_FOOT := Vector2i(6, 19)
## Variante ARC : le Goéland n'est là que pendant et après l'arc des Pierres.
const ARC_QUEST_FLAG: StringName = &"johto_stones_quest"

var _over: GDScript
var _rules: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_rules = load("res://game/world/props/painted_prop_rules.gd")
	_rng.seed = 3905
	_build()
	print("build_joh1_olivine : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _build() -> void:
	var plan := PlanGrid.new()
	if not plan.load_file(PLAN):
		_fail(plan.error)
		return
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map(size)
	var ground := root.get_node(^"Ground") as TileMapLayer
	var blocked: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var mark: String = plan.at(cell)
			if not OUTDOOR_KINDS.has(mark):
				_fail("caractère inconnu « %s » en %s" % [mark, cell])
				continue
			var kind: int = _over.Kind[OUTDOOR_KINDS[mark]]
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))
			if BLOCKED_CHARS.contains(mark):
				blocked.append(cell)
	root.set(&"blocked_cells", blocked)
	var surf: Array[Vector2i] = []
	surf.assign(plan.cells_of("w"))
	root.set(&"surf_cells", surf)
	var forced: Array[Vector2i] = []
	forced.assign(plan.cells_at("from_route_40"))
	root.set(&"forced_surf_cells", forced)
	_decor(root)
	_night_lights(root)
	_spawns(root, plan)
	_warps(root, plan)
	_points(root)
	_arc(root)
	_save(root)


func _decor(root: Node) -> void:
	var entities := root.get_node(^"Entities")
	var index := 0
	for entry: Array in BUILDINGS:
		var prop := _prop(String(entry[0]), entry[1], "Bat%02d" % index)
		if prop != null:
			prop.set(&"footprint", [] as Array[Vector2i])
			_attach(root, entities, prop)
		index += 1
	for cell: Vector2i in [Vector2i(23, 19), Vector2i(6, 19)]:
		var sign_prop := _prop("prop_panneau_01", cell, "Panneau_%d_%d" % [cell.x, cell.y])
		if sign_prop != null:
			_attach(root, entities, sign_prop)
	# Banc de 2 cases, pied sur le bord : ancré en 17 il couvre 16..17.
	var bench := _prop("prop_banc_01", Vector2i(17, 27), "Banc")
	if bench != null:
		_attach(root, entities, bench)
	for cell: Vector2i in LAMPPOSTS:
		var lamp := _prop("prop_lampadaire_01", cell, "Lampadaire_%d" % cell.x)
		if lamp != null:
			_attach(root, entities, lamp)
	_lighthouse(root, entities)


func _prop(id: String, cell: Vector2i, node_name: String) -> Node2D:
	var scene := load(PROPS_DIR + id + ".tscn") as PackedScene
	if scene == null:
		_fail("objet peint introuvable : %s" % id)
		return null
	var prop := scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	prop.position = _rules.call(&"foot_position", StringName(id), cell)
	return prop


## Phare provisoire : fût gris-blanc (trapèze), bande, galerie et lanterne sombre au sommet.
## Pied au milieu du bas de l'emprise (6, 19) ; la tour monte sur ~9 cases.
func _lighthouse(root: Node, entities: Node) -> void:
	var tower := Node2D.new()
	tower.name = "PharePlaceholder"
	tower.position = Vector2(LIGHTHOUSE_FOOT.x * TILE + TILE / 2.0, LIGHTHOUSE_FOOT.y * TILE)
	_attach(root, entities, tower)
	var shaft := Polygon2D.new()
	shaft.name = "Fut"
	shaft.color = Color("d9d6cc")
	shaft.polygon = PackedVector2Array([Vector2(-250, 0), Vector2(250, 0), Vector2(140, -700),
		Vector2(-140, -700)])
	_attach(root, tower, shaft)
	var band := Polygon2D.new()
	band.name = "Bande"
	band.color = Color("b4413a")
	band.polygon = PackedVector2Array([Vector2(-196, -300), Vector2(196, -300),
		Vector2(177, -420), Vector2(-177, -420)])
	_attach(root, tower, band)
	var gallery := Polygon2D.new()
	gallery.name = "Galerie"
	gallery.color = Color("6b6a66")
	gallery.polygon = PackedVector2Array([Vector2(-190, -700), Vector2(190, -700),
		Vector2(190, -740), Vector2(-190, -740)])
	_attach(root, tower, gallery)
	var lantern := Polygon2D.new()
	lantern.name = "Lanterne"
	lantern.color = Color("2d3340")
	lantern.polygon = PackedVector2Array([Vector2(-110, -740), Vector2(110, -740),
		Vector2(110, -850), Vector2(-110, -850)])
	_attach(root, tower, lantern)
	var roof := Polygon2D.new()
	roof.name = "Toit"
	roof.color = Color("4a4f5c")
	roof.polygon = PackedVector2Array([Vector2(-140, -850), Vector2(140, -850),
		Vector2(0, -940)])
	_attach(root, tower, roof)


func _night_lights(root: Node) -> void:
	var lights := Node2D.new()
	lights.name = "NightLights"
	_attach(root, root, lights)
	var index := 0
	for pos: Vector2 in NIGHT_LIGHTS:
		var glow := Sprite2D.new()
		glow.set_script(load("res://game/world/lighting/light_glow.gd"))
		glow.name = "Lampe%02d" % index
		glow.set(&"glow_type", &"lamp")
		glow.position = (pos * TILE).round()
		glow.visible = false  # écrasé par LightGlow._ready : Boot rappelle set_night
		glow.add_to_group(&"night_lights", true)
		_attach(root, lights, glow)
		index += 1


func _spawns(root: Node, plan: Object) -> void:
	var names := {
		"from_route_39": "from_route_39", "from_route_40": "from_route_40",
		"from_sea_cave": "from_sea_cave", "retour_centre": "from_center",
		"retour_boutique": "from_mart", "retour_maison_1": "from_house_1",
		"retour_maison_2": "from_house_2",
	}
	for id: String in names:
		var cells: Array[Vector2i] = plan.cells_at(id)
		if cells.is_empty():
			_fail("position « %s » absente de la grille" % id)
		for i: int in cells.size():
			_spawn(root, names[id] if i == 0 else "%s_%d" % [names[id], i], cells[i])


func _warps(root: Node, plan: Object) -> void:
	_warp_group(root, plan, "porte_centre", "PorteCentre", STEP_ON, Vector2i.UP,
		&"olivine_center", "entrance", Vector2i.UP, "", false)
	_warp_group(root, plan, "porte_boutique", "PorteBoutique", STEP_ON, Vector2i.UP,
		&"olivine_mart", "entrance", Vector2i.UP, "", false)
	_warp_group(root, plan, "porte_maison_1", "PorteMaison1", STEP_ON, Vector2i.UP,
		&"olivine_house_1", "entrance", Vector2i.UP, "", false)
	_warp_group(root, plan, "porte_maison_2", "PorteMaison2", STEP_ON, Vector2i.UP,
		&"olivine_house_2", "entrance", Vector2i.UP, "", false)
	_warp_group(root, plan, "warp_grotte", "WarpGrotte", STEP_ON, Vector2i.LEFT,
		&"sea_cave_2", "from_olivine_city", Vector2i.UP, "", false)
	# Raccords des jalons suivants : « à venir » tant que la carte voisine n'existe pas ; dès
	# qu'elle existe (JOH2 : Route 39, arrivées `from_olivine`, `_1`, `_2` sur (0, 20..22) ;
	# JOH7 : Route 40, `from_olivine`… sur (7..16, 0)), relancer cet outil : le passage devient réel.
	_exit(root, plan, "warp_est", "WarpEst", Vector2i.RIGHT, &"route_39", "from_olivine",
		"from_route_39", Vector2i.LEFT, "Route 39")
	_exit(root, plan, "warp_sud_mer", "WarpSudMer", Vector2i.DOWN, &"route_40", "from_olivine",
		"from_route_40", Vector2i.UP, "Route 40")


## Sortie vers une carte d'un autre jalon : passage PUSH réel vers [param target] /
## [param spawn] (rangé) si sa scène existe, sinon « à venir » avec retour sur [param back].
func _exit(root: Node, plan: Object, id: String, node_name: String, direction: Vector2i,
		target: StringName, spawn: String, back: String, facing: Vector2i, label: String) -> void:
	if ResourceLoader.exists(MAPS_DIR + String(target) + ".tscn"):
		# Passage réel : arrivée tournée dans le sens du pas (JOH2 : Route 39 « tournée → ») ;
		# [param facing] ne sert qu'au retour d'un « à venir ».
		_warp_group(root, plan, id, node_name, PUSH, direction, target, spawn, direction, "", true)
	else:
		_warp_group(root, plan, id, node_name, PUSH, direction, &"", back, facing, label, true)


## Un passage par case de [param id] ; l'arrivée cible porte le suffixe `_i` (rang de la case),
## sauf pour une porte à une seule arrivée (`entrance`, partagée).
func _warp_group(root: Node, plan: Object, id: String, node_name: String, trigger: int,
		direction: Vector2i, target: StringName, spawn: String, facing: Vector2i,
		coming_soon: String, ranked: bool) -> void:
	var cells: Array[Vector2i] = plan.cells_at(id)
	if cells.is_empty():
		_fail("position « %s » absente de la grille" % id)
	for i: int in cells.size():
		var arrival := spawn
		if (ranked or target == &"sea_cave_2") and i > 0:
			arrival = "%s_%d" % [spawn, i]
		var name := node_name if cells.size() == 1 else "%s_%d" % [node_name, i]
		_warp(root, name, cells[i], trigger, direction, target, StringName(arrival), facing,
			coming_soon)


func _points(root: Node) -> void:
	_interact(root, "PanneauVille", Vector2i(23, 19), &"olivine_city_sign")
	_interact(root, "PanneauPhare", Vector2i(6, 19), &"olivine_lighthouse_sign")
	_trigger(root, "OlivineArrival", [Vector2i(12, 31), Vector2i(12, 32)], Vector2i.ZERO,
		&"olivine_arrival")
	_trigger(root, "OlivineArrival2", [Vector2i(11, 33)], Vector2i.ZERO, &"olivine_arrival")
	_trigger(root, "GuardBarrier", [Vector2i(48, 20), Vector2i(48, 22)], Vector2i.RIGHT,
		&"olivine_guard_block")


## Variante ARC (JOHP2) : le Goéland, `from_goeland`, la barrière de la mer du sud.
func _arc(root: Node) -> void:
	var plan := PlanGrid.new()
	if not plan.load_file(PLAN, "ARC"):
		_fail(plan.error)
		return
	var boat: Array[Vector2i] = plan.cells_at("goeland")
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = "Goeland"
	var if_flags: Array[StringName] = [ARC_QUEST_FLAG]
	gate.set(&"if_flags", if_flags)
	var none: Array[StringName] = []
	gate.set(&"unless_flags", none)
	gate.set(&"blocking_cells", boat)
	gate.visible = false
	var entities := root.get_node(^"Entities")
	_attach(root, entities, gate)
	var hull := Polygon2D.new()
	hull.name = "Coque"
	hull.color = Color(0.72, 0.62, 0.45)
	var top_left := Vector2(boat[0]) * TILE
	var bottom_right := Vector2(boat[-1] + Vector2i.ONE) * TILE
	hull.polygon = PackedVector2Array([top_left, Vector2(bottom_right.x, top_left.y), bottom_right,
		Vector2(top_left.x, bottom_right.y)])
	_attach(root, gate, hull)
	_spawn(root, "from_goeland", plan.cells_at("from_goeland")[0])
	_trigger(root, "BarriereMerSud", plan.cells_at("barriere_mer_sud"), Vector2i.ZERO,
		&"olivine_south_sea_block")


func _new_map(size: Vector2i) -> Node2D:
	var root := Node2D.new()
	root.name = "OlivineCity"
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", MAP_ID)
	root.set(&"display_name", "Oliville")
	root.set(&"region", "Grotte marine — Route 39")
	root.set(&"size", size)
	root.set(&"interior", false)
	root.set(&"light_profile", &"johto_auto")
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
		target: StringName, spawn: StringName, facing: Vector2i, coming_soon: String) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = warp_name
	point.position = _world(cell)
	point.set(&"trigger", trigger)
	point.set(&"direction", direction)
	point.set(&"target_map", target)
	point.set(&"target_spawn", spawn)
	point.set(&"arrival_facing", facing)
	point.set(&"coming_soon", coming_soon)
	_attach(root, root.get_node(^"Warps"), point)


func _interact(root: Node, node_name: String, cell: Vector2i, dialogue: StringName) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"size", Vector2i.ONE)
	point.set(&"facing", Vector2i.UP)
	point.set(&"dialogue_id", dialogue)
	_attach(root, root.get_node(^"Interactables"), point)


## [param cells] : cases couvertes (rectangle englobant) ; ancre en bas à gauche.
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


func _save(root: Node) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT)
	print("%s : %s" % [OUT, "OK" if err == OK else "ERREUR %d" % err])
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
	push_error("build_joh1_olivine : " + message)
	_errors += 1
