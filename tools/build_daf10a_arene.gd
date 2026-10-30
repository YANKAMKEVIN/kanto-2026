extends SceneTree
## Lot DAF.10a (`tools/art/daf10a.py`, fiche `docs/design/fiches-assets/daf-10a/fiche.md`, RP-271) :
## repeint l'Arène de Parmanie (`fuchsia_gym`, Koga), écrite en tuiles provisoires `InteriorTiles` par
## le J23 (`build_fuchsia_gym.gd`). Seconde passe d'image sur le modèle de `build_daf9_cramois.gd` :
## **la logique ne change pas** (gel du J33) ; murs invisibles `i` = cases bloquées inchangées, dessinées
## avec une lame de parquet plus sombre (indice au sol, N-15) ; statues `S` = images accrochées aux
## cases déjà bloquées.
## Kit : parquet clair du Dojo de Safrania, cloisons shoji (série 20), masse de mur de la série 28.
##
##   godot --headless --path . -s res://tools/build_daf10a_arene.gd   (code 2 : masques écrits,
##   godot --headless --path . --import                               importer puis relancer)

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAP_ID: StringName = &"fuchsia_gym"
const MAP_PATH: String = "res://game/world/maps/fuchsia_gym.tscn"
const PLAN_PATH: String = "res://tools/plans/parmanie_arene.txt"
const MASK_PATH: String = "res://assets/world/maps/fuchsia_gym_ground.png"
const VEIL_PATH: String = "res://assets/world/maps/fuchsia_gym_voile.png"
const GROUND: String = "res://assets/world/ground/%s.png"
const RELIEF: String = "res://assets/world/relief/%s.png"
const PROPS: String = "res://assets/world/props/%s.png"
const TILE: int = 96
const OWN_ROOT: Array[String] = ["PaintedGround", "Daf10aDecor"]
const OWN_PREFIX: String = "Daf10a"
const WALL_MARK: String = "K"
const HINT_MARK: String = "i"
const STATUE_MARK: String = "S"
const KIT: Dictionary = {"sol": "ground_parquet_dojo_01", "indice": "ground_parquet_dojo_indice_01",
	"masse": "ground_parquet_manoir_01", "faces": ["relief_mur_dojo_01", "relief_mur_dojo_02"],
	"poids": [4.0, 1.5], "cap": "relief_mur_arene_cap_01", "bord": Color(0.20, 0.14, 0.11)}
const VEIL_COLOR := Color(12 / 255.0, 10 / 255.0, 14 / 255.0)
const SEED: int = 5361

var _errors: int = 0
var _written: int = 0


func _init() -> void:
	_build()
	if _errors > 0:
		quit(1)
	elif _written > 0:
		print("build_daf10a_arene : %d masque(s) écrit(s) ; importer (--import) puis relancer" % _written)
		quit(2)
	else:
		quit(0)


func _build() -> void:
	var plan := PlanGrid.new()
	if not plan.load_file(PLAN_PATH):
		push_error(plan.error)
		_errors += 1
		return
	var kit: Dictionary = KIT
	var size := Vector2i(plan.width, plan.height)
	var walls: Dictionary = {}
	for cell: Vector2i in plan.cells_of(WALL_MARK):
		walls[cell] = true
	var floors: Dictionary = {}
	for y: int in size.y:
		for x: int in size.x:
			if not walls.has(Vector2i(x, y)):
				floors[Vector2i(x, y)] = true
	var hints: Array[Vector2i] = plan.cells_of(HINT_MARK)
	var mask_ok := _write_image(_mask(size, walls, hints), MASK_PATH)
	var veil_ok := _write_image(_veil(size, walls, floors), VEIL_PATH)
	if not mask_ok or not veil_ok:
		return
	var root := (load(MAP_PATH) as PackedScene).instantiate(
		PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean(root)
	for layer_name: String in ["Ground", "Detail", "Obstacles", "Overhead"]:
		var layer := root.get_node_or_null(NodePath(layer_name)) as TileMapLayer
		if layer != null:
			layer.visible = false
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var painted := _painted_ground(size, kit)
	_attach(root, root, painted)
	root.move_child(painted, root.get_node(^"Obstacles").get_index() + 1)
	var decor := Node2D.new()
	decor.name = "Daf10aDecor"
	decor.z_index = WorldLighting.Z_GROUND_DECALS
	_attach(root, root, decor)
	root.move_child(decor, painted.get_index() + 1)
	var veil := Sprite2D.new()
	veil.name = "Voile"
	veil.texture = load(VEIL_PATH)
	veil.centered = false
	veil.scale = Vector2(TILE, TILE)
	veil.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_attach(root, decor, veil)
	_place_blocks(root, decor, walls, size, GROUND % kit["masse"], "Mur")
	var hint_cells: Dictionary = {}
	for cell: Vector2i in hints:
		hint_cells[cell] = true
	_place_blocks(root, decor, hint_cells, size, GROUND % kit["indice"], "Indice")
	var wall := func(c: Vector2i) -> bool:
		return walls.has(c) or c.x < 0 or c.y < 0 or c.x >= size.x or c.y >= size.y
	var faces: Dictionary = {}
	var caps: Dictionary = {}
	for cell: Vector2i in walls:
		if not wall.call(cell + Vector2i.DOWN):
			faces[cell] = true
		elif not wall.call(cell + Vector2i.UP):
			caps[cell] = true
	_place_faces(root, decor, faces, size, kit, rng)
	var entities := root.get_node(^"Entities") as Node2D
	for cell: Vector2i in plan.cells_of(STATUE_MARK):
		if plan.at(cell + Vector2i.DOWN) != STATUE_MARK:
			_sprite(root, entities, "%sStatue_%d_%d" % [OWN_PREFIX, cell.x, cell.y],
				PROPS % "int_statue_arene_01", Vector2((cell.x + 0.5) * TILE, (cell.y + 1) * TILE))
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, MAP_PATH)
	if err != OK:
		push_error("%s : enregistrement impossible (%d)" % [MAP_ID, err])
		_errors += 1
	else:
		print("%s : %d faces, %d couronnements, %d lames d'indice" % [MAP_ID, faces.size(),
			caps.size(), hints.size()])
	root.free()


func _mask(size: Vector2i, _walls: Dictionary, _hints: Array[Vector2i]) -> Image:
	return Image.create(size.x, size.y, false, Image.FORMAT_RG8)


## Voile : alpha 0,45 à 2 cases du sol le plus proche, 0,78 au-delà (`serie28.py`).
func _veil(size: Vector2i, walls: Dictionary, floors: Dictionary) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(VEIL_COLOR, 0.0))
	for cell: Vector2i in walls:
		var near := 9
		for dy: int in range(-3, 4):
			for dx: int in range(-3, 4):
				if floors.has(cell + Vector2i(dx, dy)):
					near = mini(near, maxi(absi(dx), absi(dy)))
		if near >= 2:
			image.set_pixelv(cell, Color(VEIL_COLOR, 0.45 if near == 2 else 0.78))
	return image


## Écrit [param image] en [param path] si elle a changé ; faux s'il faut importer avant de poursuivre.
func _write_image(image: Image, path: String) -> bool:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if FileAccess.file_exists(absolute):
		var old := Image.load_from_file(absolute)
		if old != null:
			old.convert(image.get_format())
			if old.get_data() == image.get_data() and ResourceLoader.exists(path):
				return true
	image.save_png(absolute)
	_written += 1
	return false


## Aplats de sol à bords droits (une bande par rangée et par série de cases) : parquet sombre des murs,
## lames d'indice des murs invisibles. [param id] : texture répétée.
func _place_blocks(root: Node, decor: Node, cells: Dictionary, size: Vector2i, path: String,
		prefix: String) -> void:
	var texture: Texture2D = load(path)
	for y: int in size.y:
		for run: Vector2i in _runs(cells, y, size.x):
			var s := Sprite2D.new()
			s.name = "%s_%d_%d" % [prefix, run.x, y]
			s.texture = texture
			s.centered = false
			s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			s.region_enabled = true
			s.region_rect = Rect2(run.x * TILE % texture.get_width(), y * TILE % texture.get_height(),
				(run.y - run.x + 1) * TILE, TILE)
			s.position = Vector2(run.x * TILE, y * TILE)
			_attach(root, decor, s)


func _place_caps(root: Node, decor: Node, caps: Dictionary, size: Vector2i, id: String) -> void:
	var texture: Texture2D = load(RELIEF % id)
	for y: int in size.y:
		for run: Vector2i in _runs(caps, y, size.x):
			var x := run.x
			while x <= run.y:
				var w := mini(2, run.y - x + 1)
				var s := Sprite2D.new()
				s.name = "Couronnement_%d_%d" % [x, y]
				s.texture = texture
				s.centered = false
				s.region_enabled = true
				s.region_rect = Rect2(0, 0, w * TILE, texture.get_height())
				s.position = Vector2(x * TILE, y * TILE)
				_attach(root, decor, s)
				x += w


func _place_faces(root: Node, decor: Node, faces: Dictionary, size: Vector2i, kit: Dictionary,
		rng: RandomNumberGenerator) -> void:
	var weights := PackedFloat32Array(kit["poids"])
	for y: int in size.y:
		for run: Vector2i in _runs(faces, y, size.x):
			var x := run.x
			while x <= run.y:
				var w := mini(2, run.y - x + 1)
				var id: String = kit["faces"][rng.rand_weighted(weights)]
				var texture: Texture2D = load(RELIEF % id)
				var s := Sprite2D.new()
				s.name = "Face_%d_%d" % [x, y]
				s.texture = texture
				s.centered = false
				s.flip_h = rng.randf() < 0.5
				s.region_enabled = true
				s.region_rect = Rect2(0, 0, w * TILE, texture.get_height())
				s.position = Vector2(x * TILE, (y + 1) * TILE - texture.get_height())
				_attach(root, decor, s)
				x += w


func _sprite(root: Node, parent: Node, node_name: String, path: String, foot: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = node_name
	s.texture = load(path)
	if s.texture == null:
		push_error("%s : image absente %s" % [root.name, path])
		_errors += 1
		return s
	s.centered = false
	s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height())
	s.position = foot
	_attach(root, parent, s)
	return s


func _attach(root: Node, parent: Node, node: Node) -> void:
	parent.add_child(node)
	node.owner = root
	for child: Node in node.get_children():
		_attach_owner(child, root)


func _attach_owner(node: Node, root: Node) -> void:
	node.owner = root
	for child: Node in node.get_children():
		_attach_owner(child, root)


func _runs(cells: Dictionary, y: int, width: int) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	for x: int in width:
		if not cells.has(Vector2i(x, y)):
			continue
		if not runs.is_empty() and runs[-1].y == x - 1:
			runs[-1].y = x
		else:
			runs.append(Vector2i(x, x))
	return runs


func _painted_ground(size: Vector2i, kit: Dictionary) -> Node2D:
	var floor_texture: Texture2D = load(GROUND % kit["sol"])
	var painted := Node2D.new()
	painted.set_script(load("res://game/world/ground/painted_ground.gd"))
	painted.name = "PaintedGround"
	painted.set(&"size", size)
	painted.set(&"mask", load(MASK_PATH))
	painted.set(&"base_texture", floor_texture)
	painted.set(&"r_texture", load(GROUND % kit["indice"]))
	painted.set(&"g_texture", load(GROUND % kit["masse"]))
	var material := painted.call(&"get_shader_material") as ShaderMaterial
	material.set_shader_parameter(&"texture_size", float(floor_texture.get_width()))
	material.set_shader_parameter(&"paving_scale", 1.0)
	material.set_shader_parameter(&"path_scale", 1.0)
	material.set_shader_parameter(&"earth_color", kit["bord"])
	return painted


func _clean(root: Node) -> void:
	for node_name: String in OWN_ROOT:
		var old := root.get_node_or_null(NodePath(node_name))
		if old != null:
			root.remove_child(old)
			old.free()
	var entities := root.get_node(^"Entities")
	for child: Node in entities.get_children():
		if String(child.name).begins_with(OWN_PREFIX):
			entities.remove_child(child)
			child.free()
