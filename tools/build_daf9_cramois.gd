extends SceneTree
## Lot DAF.9 (`tools/art/daf9.py`, fiche `docs/design/fiches-assets/daf-9/fiche.md`, RP-024) :
## repeint le Manoir Pokémon (`pokemon_mansion_1f` à `_b1f`) et l'Arène de Cramois'Île
## (`cinnabar_gym`), écrits en tuiles provisoires et en aplats par `build_pokemon_mansion.gd` et
## `build_j25_rooms.gd` (J25), avec le **kit de la série 28** (validé par Kevin le 2026-10-19).
##
## Passe APRÈS ces outils, sur le modèle de `build_daf4_caves.gd` ; idempotente (elle retire d'abord
## ses propres nœuds). **La logique ne change pas** (gel du J33) : la couche `Ground` (source logique)
## est gardée et seulement masquée, comme `Detail`, `Obstacles` et `Overhead` ; portes, apparitions,
## points d'examen, déclencheurs et [FlagGate] (positions, drapeaux, cases bloquées) restent tels
## quels ; seuls leurs dessins provisoires (`Polygon2D`) sont remplacés par des images peintes.
## Contrôle : `tools/dump_map_logic.gd` et `tools/dump_map_nodes.gd` identiques avant / après.
##
## Image : règles de pose de `tools/art/serie28.py --cartes` (la recomposition validée) :
## - sol peint (`PaintedGround`) : sol de l'étage, masse sur les murs `#` (canal G) ; le mobilier
##   (composante de `#` de ≤ 4 cases loin du bord) garde le sol ;
## - voile sombre hors du bâtiment (aucune case de sol à moins de 2 cases) ;
## - au sol (`Daf9Decor`, sous les personnages) : gravats au pied des murs (Manoir), couronnements
##   (mur dont le nord est libre), faces (mur dont le sud est libre), seuils de sortie ;
## - debout (`Entities`, triés par les pieds) : mobilier (tonneaux, caisses, tables, fauteuils,
##   armoires ; 2 × 2 = groupe de tonneaux, au B1F deux tables de labo), et, accrochés aux [FlagGate]
##   existants : statues, pupitres, escaliers, trous, grilles fermées / ouvertes, machines de quiz,
##   herses fermées ; herses ouvertes : [FlagGate] visuels `Daf9HerseOuverte*` (aucune case).
##
##   godot --headless --path . -s res://tools/build_daf9_cramois.gd   (code 2 : images écrites,
##   godot --headless --path . --import                              importer puis relancer)

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const FlagGateScript := preload("res://game/world/flag_gate.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const MASK_PATH: String = "res://assets/world/maps/%s_ground.png"
const VEIL_PATH: String = "res://assets/world/maps/%s_voile.png"
const GROUND: String = "res://assets/world/ground/%s.png"
const RELIEF: String = "res://assets/world/relief/%s.png"
const PROPS: String = "res://assets/world/props/%s.png"
const DECALS: String = "res://assets/world/decals/%s.png"
const TILE: int = 96
const OWN_ROOT: Array[String] = ["PaintedGround", "Daf9Decor"]
const OWN_PREFIX: String = "Daf9"
## Carte → [grille, kit, graine].
const MAPS: Dictionary = {
	&"pokemon_mansion_1f": ["manoir_1f", "manoir", 2911],
	&"pokemon_mansion_2f": ["manoir_2f", "manoir", 2921],
	&"pokemon_mansion_3f": ["manoir_3f", "manoir", 2931],
	&"pokemon_mansion_b1f": ["manoir_b1f", "b1", 2941],
	&"cinnabar_gym": ["cramois_arene", "arene", 2951],
}
## Kits de la série 28 (`serie28.py`, `KITS`) : sol, masse, faces (poids), couronnement, frontière.
const KITS: Dictionary = {
	"manoir": {"sol": "ground_parquet_manoir_01", "masse": "ground_masse_manoir_01",
		"faces": ["relief_mur_manoir_01", "relief_mur_manoir_02", "relief_mur_manoir_03",
			"relief_mur_manoir_04"], "poids": [5.0, 3.0, 1.2, 0.8], "cap": "relief_mur_manoir_cap_01",
		"bord": Color(0.20, 0.14, 0.11)},
	"b1": {"sol": "ground_carrelage_b1_01", "masse": "ground_masse_manoir_b1_01",
		"faces": ["relief_mur_manoir_b1_01", "relief_mur_manoir_b1_02", "relief_mur_manoir_b1_03",
			"relief_mur_manoir_b1_04"], "poids": [4.0, 2.0, 1.0, 2.0],
		"cap": "relief_mur_manoir_b1_cap_01", "bord": Color(0.14, 0.15, 0.19)},
	"arene": {"sol": "ground_dalles_arene_01", "masse": "ground_masse_arene_01",
		"faces": ["relief_mur_arene_01", "relief_mur_arene_02", "relief_mur_arene_03",
			"relief_mur_arene_04"], "poids": [4.0, 3.0, 1.5, 2.0], "cap": "relief_mur_arene_cap_01",
		"bord": Color(0.17, 0.12, 0.12)},
}
const VEIL_COLOR := Color(12 / 255.0, 10 / 255.0, 14 / 255.0)
const DEBRIS_CHANCE: float = 0.22
## Préfixe d'un [FlagGate] → image peinte ; « component » : une image par bloc de cases (posée sur
## la case en bas à gauche du bloc).
const GATE_ART: Dictionary = {
	"Statue_": "int_statue_manoir_01", "StatueArene": "int_statue_arene_01",
	"Pupitre_": "int_pupitre_carnet_01", "Machine_": "int_machine_quiz_01",
	"GrilleA_": "int_grille_manoir_fermee_01", "GrilleB_": "int_grille_manoir_fermee_01",
	"RailA_": "int_grille_manoir_ouverte_01", "RailB_": "int_grille_manoir_ouverte_01",
	"Herse": "int_herse_fermee_01",
}
const COMPONENT_PREFIXES: Array[String] = ["GrilleA_", "GrilleB_", "RailA_", "RailB_", "Herse"]

var _errors: int = 0
var _written: int = 0


func _init() -> void:
	for map_id: StringName in MAPS:
		_build(map_id)
	if _errors > 0:
		quit(1)
	elif _written > 0:
		print("build_daf9_cramois : %d image(s) écrite(s) ; importer (--import) puis relancer"
			% _written)
		quit(2)
	else:
		print("build_daf9_cramois : OK")
		quit(0)


func _build(map_id: StringName) -> void:
	var spec: Array = MAPS[map_id]
	var plan := PlanGrid.new()
	if not plan.load_file("res://tools/plans/%s.txt" % spec[0]):
		push_error("%s : %s" % [map_id, plan.error])
		_errors += 1
		return
	var kit: Dictionary = KITS[spec[1]]
	var manoir := String(spec[0]).begins_with("manoir")
	var b1 := String(spec[0]).ends_with("b1f")
	var size := Vector2i(plan.width, plan.height)
	var walls: Dictionary = {}
	for cell: Vector2i in plan.cells_of("#"):
		walls[cell] = true
	var furniture: Dictionary = _furniture(plan, walls) if manoir else {}
	for cell: Vector2i in furniture:
		walls.erase(cell)
	var floors: Dictionary = {}
	for y: int in size.y:
		for x: int in size.x:
			if not walls.has(Vector2i(x, y)):
				floors[Vector2i(x, y)] = true
	var mask_ok := _write_image(_mask(size, walls), MASK_PATH % map_id)
	var veil_ok := _write_image(_veil(size, walls, floors), VEIL_PATH % map_id)
	if not mask_ok or not veil_ok:
		return
	for id: String in [kit["sol"], kit["masse"], kit["cap"]] + Array(kit["faces"]):
		var path: String = (GROUND if id.begins_with("ground") else RELIEF) % id
		if not ResourceLoader.exists(path):
			push_error("%s : image absente %s (tools/art/daf9.py --modules)" % [map_id, path])
			_errors += 1
			return
	var path := MAPS_DIR + "%s.tscn" % map_id
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean(root)
	for layer_name: String in ["Ground", "Detail", "Obstacles", "Overhead"]:
		var layer := root.get_node_or_null(NodePath(layer_name)) as TileMapLayer
		if layer != null:
			layer.visible = false
	var rng := RandomNumberGenerator.new()
	rng.seed = spec[2]
	var painted := _painted_ground(map_id, size, kit)
	_attach(root, root, painted)
	root.move_child(painted, root.get_node(^"Obstacles").get_index() + 1)
	var decor := Node2D.new()
	decor.name = "Daf9Decor"
	decor.z_index = WorldLighting.Z_GROUND_DECALS
	_attach(root, root, decor)
	root.move_child(decor, painted.get_index() + 1)
	var veil := Sprite2D.new()
	veil.name = "Voile"
	veil.texture = load(VEIL_PATH % map_id)
	veil.centered = false
	veil.scale = Vector2(TILE, TILE)
	veil.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_attach(root, decor, veil)
	var wall := func(c: Vector2i) -> bool:
		return walls.has(c) or c.x < 0 or c.y < 0 or c.x >= size.x or c.y >= size.y
	if manoir:
		_place_debris(root, decor, plan, floors, furniture, wall, rng)
	var faces: Dictionary = {}
	var caps: Dictionary = {}
	for cell: Vector2i in walls:
		if not wall.call(cell + Vector2i.DOWN):
			faces[cell] = true
		elif not wall.call(cell + Vector2i.UP):
			caps[cell] = true
	_place_caps(root, decor, caps, size, kit["cap"])
	_place_faces(root, decor, faces, size, kit, rng)
	if manoir:
		for comp: Array in _components(plan.cells_of("E")):
			var box := _box(comp)
			var x := box.position.x
			while x <= box.end.x - 1:
				var cx := (x + (1.0 if x + 1 <= box.end.x - 1 else 0.5)) * TILE
				_sprite(root, decor, "Seuil_%d_%d" % [x, box.end.y - 1], PROPS % "int_seuil_manoir_01",
					Vector2(cx, box.end.y * TILE))
				x += 2
	var entities := root.get_node(^"Entities") as Node2D
	_place_furniture(root, entities, furniture, b1, String(spec[0]).length())
	_dress_gates(root, entities, plan)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("%s : enregistrement impossible (%d)" % [map_id, err])
		_errors += 1
	else:
		print("%s : %d faces, %d couronnements, %d meubles" % [map_id, faces.size(), caps.size(),
			furniture.size()])
	root.free()


## Mobilier : composante de `#` de ≤ 4 cases qui ne touche pas le bord (`plan_aplats_j25.py`).
func _furniture(plan: PlanGrid, walls: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for comp: Array in _components(walls.keys()):
		var border := false
		for c: Vector2i in comp:
			if c.x == 0 or c.y == 0 or c.x == plan.width - 1 or c.y == plan.height - 1:
				border = true
		if comp.size() <= 4 and not border:
			for c: Vector2i in comp:
				result[c] = true
	return result


func _mask(size: Vector2i, walls: Dictionary) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RG8)
	for cell: Vector2i in walls:
		image.set_pixelv(cell, Color(0.0, 1.0, 0.0))
	return image


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


func _painted_ground(map_id: StringName, size: Vector2i, kit: Dictionary) -> Node2D:
	var floor_texture: Texture2D = load(GROUND % kit["sol"])
	var painted := Node2D.new()
	painted.set_script(load("res://game/world/ground/painted_ground.gd"))
	painted.name = "PaintedGround"
	painted.set(&"size", size)
	painted.set(&"mask", load(MASK_PATH % map_id))
	painted.set(&"base_texture", floor_texture)
	painted.set(&"r_texture", floor_texture)
	painted.set(&"g_texture", load(GROUND % kit["masse"]))
	var material := painted.call(&"get_shader_material") as ShaderMaterial
	material.set_shader_parameter(&"texture_size", float(floor_texture.get_width()))
	material.set_shader_parameter(&"paving_scale", 1.0)
	material.set_shader_parameter(&"path_scale", 1.0)
	material.set_shader_parameter(&"earth_color", kit["bord"])
	return painted


func _place_debris(root: Node, decor: Node, plan: PlanGrid, floors: Dictionary,
		furniture: Dictionary, wall: Callable, rng: RandomNumberGenerator) -> void:
	var taken: Dictionary = furniture.duplicate()
	for cell: Vector2i in plan.cells_of("TPOUVEab"):
		taken[cell] = true
	for id: String in plan.positions:
		for cell: Vector2i in plan.cells_at(id):
			taken[cell] = true
	var cells: Array = floors.keys()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for cell: Vector2i in cells:
		if taken.has(cell) or taken.has(cell + Vector2i.DOWN) or taken.has(cell + Vector2i.RIGHT):
			continue
		if wall.call(cell + Vector2i.UP) and rng.randf() < DEBRIS_CHANCE:
			var id := "decal_gravats_manoir_0%d" % rng.randi_range(1, 6)
			var texture: Texture2D = load(DECALS % id)
			_sprite(root, decor, "Gravats_%d_%d" % [cell.x, cell.y], DECALS % id,
				Vector2((cell.x + 0.5) * TILE, cell.y * TILE + 6 + texture.get_height()))


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


## Mobilier debout, trié par les pieds dans `Entities` (`serie28.py`, `meuble`).
func _place_furniture(root: Node, entities: Node, furniture: Dictionary, b1: bool,
		name_length: int) -> void:
	var choices: Array[String] = ["int_caisse_archives_01", "int_armoire_basse_01",
		"int_petite_table_01"]
	if not b1:
		choices = ["int_tonneau_brule_01", "int_caisse_archives_01", "int_petite_table_01",
			"int_fauteuil_renverse_01", "int_armoire_basse_01"]
	var chosen: Dictionary = {}
	var comps := _components(furniture.keys())
	for comp: Array in comps:
		var box := _box(comp)
		var foot_y := box.end.y * TILE
		if box.size == Vector2i(2, 2) and comp.size() == 4:
			if b1:
				for dx: int in 2:
					_sprite(root, entities, "Daf9Meuble_%d_%d" % [box.position.x + dx, box.position.y],
						PROPS % "int_table_labo_01", Vector2((box.position.x + dx + 0.5) * TILE, foot_y))
			else:
				_sprite(root, entities, "Daf9Meuble_%d_%d" % [box.position.x, box.position.y],
					PROPS % "int_groupe_tonneaux_01", Vector2((box.position.x + 1) * TILE, foot_y))
			continue
		comp.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
		for c: Vector2i in comp:
			var near: Dictionary = {}
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				near[chosen.get(c + d, "")] = true
			var i := (c.x * 7 + c.y * 13 + name_length) % choices.size()
			var pick := choices[0]
			for k: int in choices.size():
				var candidate := choices[(i + k) % choices.size()]
				if not near.has(candidate) or k == choices.size() - 1:
					pick = candidate
					break
			chosen[c] = pick
			_sprite(root, entities, "Daf9Meuble_%d_%d" % [c.x, c.y], PROPS % pick,
				Vector2((c.x + 0.5) * TILE, (c.y + 1) * TILE))


## Remplace les dessins provisoires des [FlagGate] par les images peintes (accrochées au nœud :
## même visibilité) ; ajoute les herses ouvertes.
func _dress_gates(root: Node, entities: Node, plan: PlanGrid) -> void:
	var groups: Dictionary = {}
	for gate: Node in entities.get_children():
		if gate.get_script() != FlagGateScript or String(gate.name).begins_with(OWN_PREFIX):
			continue
		var gname := String(gate.name)
		var art := ""
		var prefix := ""
		for p: String in GATE_ART:
			if gname.begins_with(p) and p.length() > prefix.length():
				prefix = p
				art = GATE_ART[p]
		var cell := Vector2i(floori((gate as Node2D).position.x / TILE),
			floori((gate as Node2D).position.y / TILE) - 1)
		if gname.begins_with("EscalierDessin_"):
			art = "int_escalier_manoir_monte_01" if plan.at(cell) == "U" else \
				"int_escalier_manoir_descend_01"
		elif gname.begins_with("TrouDessin_"):
			art = "int_trou_plancher_01"
		if art.is_empty():
			push_warning("%s : dessin provisoire gardé (%s)" % [root.name, gname])
			continue
		for child: Node in gate.get_children():
			if child is Polygon2D:
				gate.remove_child(child)
				child.free()
		if prefix in COMPONENT_PREFIXES:
			var key := gname.get_slice("_", 0)
			if not groups.has(key):
				groups[key] = {"art": art, "gates": {}}
			groups[key]["gates"][cell] = gate
			continue
		var s := _sprite(root, gate, "Dessin", PROPS % art, Vector2.ZERO)
		if art == "int_trou_plancher_01":
			# Trou centré sur sa case, sous les personnages.
			s.position.y = -TILE / 2.0
			s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height() / 2.0)
			s.z_index = -1
		elif art == "int_escalier_manoir_descend_01":
			s.z_index = -1
	for key: String in groups:
		var gates: Dictionary = groups[key]["gates"]
		for comp: Array in _components(gates.keys()):
			var box := _box(comp)
			var anchor := Vector2i(box.position.x, box.end.y - 1)
			var gate := gates[anchor] as Node2D
			var foot := Vector2((box.position.x + box.end.x) / 2.0 * TILE, box.end.y * TILE)
			_sprite(root, gate, "Dessin", PROPS % groups[key]["art"], foot - gate.position)
			if key.begins_with("Herse"):
				_open_portcullis(root, entities, gate as Node, foot)


## Herse ouverte : affichée si l'un des drapeaux qui ouvrent la herse est levé (deux [FlagGate]
## visuels, sans case bloquée).
func _open_portcullis(root: Node, entities: Node, closed: Node, foot: Vector2) -> void:
	var flags: Array[StringName] = closed.get(&"unless_flags")
	for i: int in flags.size():
		var gate := Node2D.new()
		gate.set_script(FlagGateScript)
		gate.name = "%sHerseOuverte_%s_%d" % [OWN_PREFIX, closed.name, i]
		gate.position = foot
		var if_flags: Array[StringName] = [flags[i]]
		var unless: Array[StringName] = []
		unless.assign(flags.slice(0, i))
		gate.set(&"if_flags", if_flags)
		gate.set(&"unless_flags", unless)
		_attach(root, entities, gate)
		_sprite(root, gate, "Dessin", PROPS % "int_herse_ouverte_01", Vector2.ZERO)


## Image posée par le milieu du bas en [param foot] (relatif à [param parent]).
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
		elif child.get_script() == FlagGateScript:
			for sprite: Node in child.get_children():
				if sprite is Sprite2D:
					child.remove_child(sprite)
					sprite.free()


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


func _components(cells: Array) -> Array:
	var set: Dictionary = {}
	for c: Vector2i in cells:
		set[c] = true
	var seen: Dictionary = {}
	var result: Array = []
	var ordered := cells.duplicate()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for start: Vector2i in ordered:
		if seen.has(start):
			continue
		var comp: Array = []
		var stack: Array = [start]
		seen[start] = true
		while not stack.is_empty():
			var c: Vector2i = stack.pop_back()
			comp.append(c)
			for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
				if set.has(c + d) and not seen.has(c + d):
					seen[c + d] = true
					stack.append(c + d)
		result.append(comp)
	return result


func _box(comp: Array) -> Rect2i:
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-1, -1)
	for c: Vector2i in comp:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	return Rect2i(lo, hi - lo + Vector2i.ONE)
