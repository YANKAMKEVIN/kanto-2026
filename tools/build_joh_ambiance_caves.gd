extends SceneTree
## Passe d'ambiance des grottes du Chapitre Johto (décision de Kevin du 2026-11-04) : repeint les
## deux salles de la grotte marine (`sea_cave_1`, `sea_cave_2`, `build_joh1_sea_cave.gd`) d'après
## leurs vues générales validées (`grotte-marine-1-vue-generale-v1.png`, `-2-`) et la bouche de la
## grotte à Bourg Palette (`build_joh1_pallet_cave.gd`). Modèles : `build_joh_ambiance.gd` (Oliville)
## et `build_daf4_caves.gd` (Grotte Azurée : même sol, parois du Mont Sélénite).
##
## Passe APRÈS les outils d'origine ; idempotente (elle retire d'abord ses propres nœuds, préfixe
## `JohAmbCave`). **La logique ne change pas** : couches de tuiles (dont `Ground`, source logique),
## `surf_cells`, `current_cells`, `forced_surf_cells`, `blocked_cells`, [CurrentGate] `CourantChenal`,
## [FlagGate] `LugiaShadow` et son animation, passages, arrivées, déclencheurs, PNJ d'objets gardés ;
## les couches sont seulement masquées. Rien de posé ici n'a d'emprise (`Sprite2D` seuls, ou
## `WorldProp` hors des couches d'emprise de `GameMap`).
##
## **Salles** (`tools/cave_map_kit.gd`, une racine de kit jetable dont on adopte les nœuds) :
## - sol peint : îlots `.` = base (`ground_azuree_bas_01`), parois `#` = canal G
##   (`ground_masse_roche_01`), parois du Mont Sélénite en modules, tirées vers le bleu [D] ;
## - eau `w d > v` et sous les rochers `o` : eau animée du sol peint (`square_shore`, texture
##   `ground_eau_grotte_01`, sans écume), comme la mer d'Oliville : la frange est dans les parois ;
## - voile de l'eau `<carte>_eau.png` (8 px par case, écrit ici) : turquoise lumineux le long des
##   rives, bleu nuit au large, presque noir sur l'eau profonde `d` (sous l'ombre de Lugia) ;
## - masse rocheuse couverte de modules de face empilés, plus sombres loin des galeries ;
## - rebords d'îlots (`relief_rebord_azuree_*`), rochers `o` (`prop_rocher_grotte_01`) ;
## - plage `g`, sortie `E` et îlots : bandes refroidies de `ground_roche_01` et du sol ;
## - courant permanent de la salle 1 et cascade : `ground_courant_01` qui défile
##   (`game/world/ground/water_flow.gdshader`, image seule) ; le chenal de la salle 2 reste dessiné
##   par son [CurrentGate] ;
## - puits de lumière : halos `shaft` (flaque) et `beam` (colonne) dans `JohAmbCaveGlows` ; le
##   profil de lumière `sea_cave` ne change pas.
##
## **Bourg Palette** : seuls les dessins des [FlagGate] `Joh1GrotteOuverte` et `Joh1GrotteFermee`
## changent (aplats `Polygon2D` retirés, images peintes en enfants) ; les portes, leurs conditions,
## les passages et le déclencheur restent ceux de `build_joh1_pallet_cave.gd`.
##
## Contrôle : `tools/dump_map_logic.gd` et `tools/dump_map_nodes.gd` identiques avant / après.
##
##   godot --headless --path . -s res://tools/build_joh_ambiance_caves.gd [-- --maps=sea_cave_1]
##   (code 2 : images écrites ; godot --headless --path . --import, puis relancer)
##   À relancer après `build_joh1_sea_cave.gd` ou `build_joh1_pallet_cave.gd`.

const Kit := preload("res://tools/cave_map_kit.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const MASK_PATH: String = "res://assets/world/maps/%s_ground.png"
const TINT_PATH: String = "res://assets/world/maps/%s_eau.png"
const GROUND: String = "res://assets/world/ground/%s.png"
const PROPS: String = "res://game/world/props/painted/%s.tscn"
const FLOW_SHADER: String = "res://game/world/ground/water_flow.gdshader"
const OWN_PREFIX: String = "JohAmbCave"
const OWN_ROOT: Array[String] = ["PaintedGround", "JohAmbCaveTint", "JohAmbCaveSol",
	"JohAmbCaveGlows"]
const TILE: int = 96
const PALLET: StringName = &"pallet_town"
## Carte → [grille, graine].
const MAPS: Dictionary = {
	&"sea_cave_1": ["grotte_marine_1", 3171],
	&"sea_cave_2": ["grotte_marine_2", 3181],
}
const FLOOR: String = "ground_azuree_bas_01"
const MASS: String = "ground_masse_roche_01"
const WATER: String = "ground_eau_grotte_01"
const FAST_WATER: String = "ground_courant_01"
const PEBBLES: String = "ground_roche_01"
const BORDER := Color(0.1, 0.13, 0.2)
const WATER_MARKS: String = "wd>v"
const ROCK_MARK: String = "o"
const LAND_MARKS: String = "."
const BEACH_MARKS: String = "gE"
## Roche sombre bleutée de la vue générale : parois, rochers, galets [D].
const WALL_TINT := Color(0.74, 0.82, 1.0)
const ROCK_TINT := Color(0.56, 0.66, 0.92)
const PEBBLE_TINT := Color(0.5, 0.56, 0.7)
const ISLAND_TINT := Color(0.62, 0.7, 0.9)
## Masse rocheuse : modules de face empilés (rangées décalées, deux cases de haut), de plus en plus
## sombres en s'éloignant des galeries (cases jusqu'au sombre, valeur la plus sombre).
const FILL_STEP: int = 2
const FILL_DEPTH: float = 5.0
const FILL_DARK: float = 0.58
## Modules à peine décalés vers le haut (pixels) : casse les lignes des rangées.
const FILL_JITTER: float = 14.0
const FACE: String = "relief_rebord_azuree_01"
const SIDE: String = "relief_rebord_azuree_cote_01"
const ROCK: String = "prop_rocher_grotte_01"
## Teinte de l'eau (voile posé sur l'eau animée) : pixels par case, voile selon la distance à la
## rive (1, 2, 3 cases, puis au large), eau profonde.
const TINT_PX: int = 8
const SHORE_TINTS: Array[Color] = [Color(0.15, 0.85, 0.8, 0.18), Color(0.1, 0.55, 0.7, 0.3),
	Color(0.05, 0.3, 0.5, 0.4)]
const OPEN_TINT := Color(0.02, 0.12, 0.32, 0.5)
const DEEP_TINT := Color(0.008, 0.03, 0.14, 0.82)
## Courant permanent : pixels de texture par seconde (celui de [CurrentGate] : 120).
const FLOW_SPEED: float = 120.0
const FLOW_STRENGTH: float = 0.95
## Cascade de la salle 1 : colonne, rangées (haut, bas) ; elle tombe de la paroi dans le bassin.
const FALL_COLUMN: int = 13
const FALL_ROWS := Vector2i(27, 31)
const FALL_STRENGTH: float = 0.85
## Eau qui se répand sur la plage au pied du chenal (salle 2) : cases, force [D].
const SPILLS: Dictionary = {&"sea_cave_2": Rect2i(6, 35, 3, 1)}
const SPILL_STRENGTH: float = 0.55
## Puits de lumière, par carte : [cases du pied de la colonne (x, y, décimaux)].
const SHAFTS: Dictionary = {
	&"sea_cave_1": [Vector2(14.0, 6.5), Vector2(21.0, 22.0), Vector2(13.5, 32.5)],
	&"sea_cave_2": [Vector2(21.0, 11.0), Vector2(12.0, 11.5), Vector2(13.0, 26.5)],
}
## Jour de la sortie vers Oliville (salle 2) : halo chaud [D].
const POOLS: Dictionary = {&"sea_cave_2": [Vector2(4.0, 39.2)]}

## Bourg Palette : images sous les portes (pied de la porte : milieu de la bouche, bas de la carte).
## La bouche est enfoncée sous le bord de la carte : la caméra s'arrête au bord, l'eau reste
## devant [D].
const PAL_OPEN := "Joh1GrotteOuverte"
const PAL_CLOSED := "Joh1GrotteFermee"
const PAL_MOUTH: String = "relief_bouche_talus_01"
const PAL_MOUTH_SCALE: float = 0.8
const PAL_SINK: float = 20.0
## Rochers de part et d'autre de la bouche : [objet, décalage du pied (pixels), miroir].
const PAL_FLANKS: Array = [
	["relief_rivage_05", Vector2(-192.0, 40.0), false],
	["relief_rivage_04", Vector2(192.0, 40.0), true],
]
## Rochers fermés : [objet, décalage du pied (pixels), miroir].
const PAL_REEF: Array = [
	["relief_rivage_01", Vector2(-96.0, 36.0), false],
	["relief_rivage_02", Vector2(96.0, 36.0), true],
]

var _errors: int = 0
var _masks: int = 0


func _init() -> void:
	var wanted: Array = MAPS.keys()
	wanted.append(PALLET)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--maps="):
			wanted = Array(arg.trim_prefix("--maps=").split(",")).map(
				func(s: String) -> StringName: return StringName(s))
	for map_id: StringName in wanted:
		if map_id == PALLET:
			_build_pallet()
		elif MAPS.has(map_id):
			_build_cave(map_id)
		else:
			push_error("build_joh_ambiance_caves : carte inconnue %s" % map_id)
			_errors += 1
	if _errors > 0:
		quit(1)
	elif _masks > 0:
		print("build_joh_ambiance_caves : %d carte(s) à importer (--import) puis relancer" % _masks)
		quit(2)
	else:
		quit(0)


# --- Grotte marine ------------------------------------------------------------------------


func _build_cave(map_id: StringName) -> void:
	var spec: Array = MAPS[map_id]
	var plan_path := "res://tools/plans/%s.txt" % spec[0]
	var plan := PlanGrid.new()
	if not plan.load_file(plan_path):
		push_error("%s : %s" % [map_id, plan.error])
		_errors += 1
		return
	var size := Vector2i(plan.width, plan.height)
	var seed_value: int = spec[1]
	var kit: Object = Kit.new(plan_path, size, seed_value, seed_value + 1, plan.walkable)
	kit.set(&"floor_texture_path", GROUND % FLOOR)
	kit.set(&"mass_texture_path", GROUND % MASS)
	kit.set(&"border_color", BORDER)
	kit.set(&"rubble_mark", "")
	kit.set(&"rubble_is_logic", false)
	kit.set(&"wall_marks", "#")
	if not _kit_ok(kit, map_id):
		return
	var kit_root: Node2D = kit.call(&"make_root", "Kit", map_id, "", &"")
	var tint_ready: bool = kit.call(&"_write_png", _tint_image(plan), TINT_PATH % map_id)
	var ground_ready: bool = kit.call(&"add_ground", MASK_PATH % map_id)
	if not ground_ready or not tint_ready:
		if _kit_ok(kit, map_id):
			_masks += 1
		kit.call(&"discard")
		return
	var painted: Node2D = kit_root.get_node(^"PaintedGround")
	_water(painted, plan, size)
	var decals: Node2D = kit.get(&"decals")
	var entities: Node2D = kit.get(&"entities")
	var bands := _bands(kit, decals, plan, BEACH_MARKS, PEBBLES, PEBBLE_TINT, "Beach")
	bands += _bands(kit, decals, plan, LAND_MARKS, FLOOR, ISLAND_TINT, "Island")
	var filled := _fill_mass(kit, decals, plan, seed_value + 4)
	var walls: Vector3i = kit.call(&"place_walls", seed_value + 2)
	_tint_walls(entities)
	_tint_walls(decals)
	var edges := _island_edges(kit, decals, plan)
	var rocks := _rocks(kit, entities, plan, seed_value + 3)
	_flows(kit, decals, entities, plan, map_id)
	_lights(kit, map_id)
	if not _kit_ok(kit, map_id):
		kit.call(&"discard")
		return
	var path := MAPS_DIR + "%s.tscn" % map_id
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean_cave(root)
	for layer: Node in root.get_children():
		if layer is TileMapLayer:
			(layer as TileMapLayer).visible = false
	var index := root.get_node(^"Obstacles").get_index() + 1
	_adopt(painted, root, root, kit_root)
	root.move_child(painted, index)
	var tint := Sprite2D.new()
	tint.name = "JohAmbCaveTint"
	tint.texture = load(TINT_PATH % map_id)
	tint.centered = false
	tint.scale = Vector2.ONE * (float(TILE) / TINT_PX)
	tint.z_index = -2
	root.add_child(tint)
	tint.owner = root
	root.move_child(tint, index + 1)
	_adopt(decals, root, root, kit_root)
	decals.name = "JohAmbCaveSol"
	root.move_child(decals, index + 2)
	var glows: Node2D = kit.get(&"glows")
	_adopt(glows, root, root, kit_root)
	glows.name = "JohAmbCaveGlows"
	root.move_child(glows, root.get_node(^"Entities").get_index() + 1)
	var map_entities := root.get_node(^"Entities")
	for child: Node in entities.get_children():
		child.name = OWN_PREFIX + String(child.name)
		_adopt(child, map_entities, root, kit_root)
	kit.call(&"discard")
	var err := _save(root, path)
	print("%s : %s (parois %s, masse %d, bandes %d, rebords %d, rochers %d, halos %d)" % [map_id,
		error_string(err), walls, filled, bands, edges, rocks, glows.get_child_count()])
	root.free()


func _kit_ok(kit: Object, map_id: StringName) -> bool:
	var errors: PackedStringArray = kit.get(&"errors")
	if errors.is_empty():
		return true
	push_error("%s :\n%s" % [map_id, "\n".join(errors)])
	_errors += 1
	return false


## Eau animée du sol peint sur l'eau et sous les rochers, à angles droits, sans écume.
func _water(painted: Node2D, plan: Object, size: Vector2i) -> void:
	var cells: Array[Vector2i] = plan.cells_of(WATER_MARKS + ROCK_MARK)
	var mask := load("res://game/world/ground/ground_mask.gd") as GDScript
	var image: Image = mask.call(&"build_water", size, cells)
	painted.set(&"shore_mask", ImageTexture.create_from_image(image))
	painted.set(&"square_shore", true)
	painted.set(&"water_texture", load(GROUND % WATER))
	painted.set(&"foam_strength", 0.0)


## Voile de l'eau : clair le long des rives, bleu nuit au large, presque noir sur l'eau profonde ;
## rien hors de l'eau (frontière franche, les parois la recouvrent).
func _tint_image(plan: Object) -> Image:
	var small := Image.create(plan.width, plan.height, false, Image.FORMAT_RGBA8)
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var color := Color(SHORE_TINTS[0], 0.0)
			if plan.at(cell) == "d":
				color = DEEP_TINT
			elif _is_wet(plan, cell):
				var shore := _shore_distance(plan, cell)
				color = SHORE_TINTS[shore - 1] if shore <= SHORE_TINTS.size() else OPEN_TINT
			small.set_pixelv(cell, color)
	small.resize(plan.width * TINT_PX, plan.height * TINT_PX, Image.INTERPOLATE_BILINEAR)
	for y: int in small.get_height():
		for x: int in small.get_width():
			if not _is_wet(plan, Vector2i(x / TINT_PX, y / TINT_PX)):
				small.set_pixel(x, y, Color(SHORE_TINTS[0], 0.0))
	return small


func _is_wet(plan: Object, cell: Vector2i) -> bool:
	return (WATER_MARKS + ROCK_MARK).contains(plan.at(cell))


## Distance (cases, 8-voisinage) de [param cell] à la plus proche case sèche, bornée au-delà de
## [constant SHORE_TINTS].
func _shore_distance(plan: Object, cell: Vector2i) -> int:
	for radius: int in range(1, SHORE_TINTS.size() + 1):
		for dy: int in range(-radius, radius + 1):
			for dx: int in range(-radius, radius + 1):
				if not _is_wet(plan, cell + Vector2i(dx, dy)):
					return radius
	return SHORE_TINTS.size() + 1


## Bandes horizontales de la texture [param ground] sur les cases [param marks], coordonnées du
## monde (aucun raccord visible), sous les lèvres de paroi. Renvoie leur nombre.
func _bands(kit: Object, decals: Node2D, plan: Object, marks: String, ground: String,
		tint: Color, prefix: String) -> int:
	var texture: Texture2D = load(GROUND % ground)
	var count := 0
	for y: int in plan.height:
		var x := 0
		while x < plan.width:
			if not marks.contains(plan.at(Vector2i(x, y))):
				x += 1
				continue
			var start := x
			while x < plan.width and marks.contains(plan.at(Vector2i(x, y))):
				x += 1
			var sprite := Sprite2D.new()
			sprite.name = "%s%02d" % [prefix, count]
			sprite.texture = texture
			sprite.centered = false
			sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			sprite.region_enabled = true
			sprite.region_rect = Rect2(start * TILE, y * TILE, (x - start) * TILE, TILE)
			sprite.position = Vector2(start * TILE, y * TILE)
			sprite.modulate = tint
			kit.call(&"attach", decals, sprite)
			count += 1
	return count


## Masse rocheuse : modules de face empilés sur toute la masse, du nord au sud (chaque rangée
## recouvre le haut de la précédente), rangées décalées d'une case et demie ; ils s'assombrissent
## loin des galeries. Sous les parois de la grille (posées ensuite). Renvoie leur nombre.
func _fill_mass(kit: Object, decals: Node2D, plan: Object, seed_value: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var faces: Array[String] = kit.get(&"wall_faces")
	var count := 0
	var row := 0
	for y: int in range(1, plan.height, FILL_STEP):
		var both := func(cell: Vector2i) -> bool:
			return plan.at(cell) == "#" and plan.at(cell + Vector2i.UP) == "#"
		for run: Vector2i in kit.call(&"_row_runs", y, both):
			var pieces: Array[Vector2i] = []
			var left := run.x
			if row % 2 == 1 and run.y > run.x:
				pieces.append(Vector2i(left, 1))
				left += 1
			pieces.append_array(kit.call(&"_pieces", Vector2i(left, run.y)))
			for piece: Vector2i in pieces:
				var id: String = faces[rng.randi_range(0, faces.size() - 1)]
				var foot := Vector2((piece.x + piece.y / 2.0) * TILE,
					(y + 1) * TILE - rng.randf_range(0.0, FILL_JITTER))
				var sprite: Sprite2D = kit.call(&"_wall_module", decals, id, foot, piece.y * TILE,
					-1, false, "Fill%03d" % count, rng)
				sprite.flip_h = rng.randf() < 0.5
				var depth := _mass_depth(plan, Vector2i(piece.x + piece.y / 2, y))
				var value := lerpf(1.0, FILL_DARK, clampf(depth / FILL_DEPTH, 0.0, 1.0))
				sprite.modulate *= WALL_TINT * Color(value, value, value)
				count += 1
		row += 1
	return count


## Distance (cases) de [param cell] à la plus proche case qui n'est pas de la masse, bornée.
func _mass_depth(plan: Object, cell: Vector2i) -> float:
	var limit := int(FILL_DEPTH)
	for radius: int in range(1, limit + 1):
		for dy: int in range(-radius, radius + 1):
			for dx: int in range(-radius, radius + 1):
				var near := cell + Vector2i(dx, dy)
				if plan.at(near) != "#" and plan.at(near) != "T":
					return float(radius)
	return FILL_DEPTH


func _tint_walls(parent: Node) -> void:
	for child: Node in parent.get_children():
		var label := String(child.name)
		if label.begins_with("Face") or label.begins_with("Side") or label.begins_with("Lip"):
			var sprite := child as Sprite2D
			sprite.modulate *= WALL_TINT


## Rebords des îlots : face sous la case du bord sud (posée sur l'eau, le joueur garde toute
## l'île), bords latéraux à l'est et à l'ouest. Renvoie le nombre d'objets.
func _island_edges(kit: Object, decals: Node2D, plan: Object) -> int:
	var count := 0
	for cell: Vector2i in plan.cells_of(LAND_MARKS):
		if _is_wet(plan, cell + Vector2i.DOWN):
			var face: Node2D = kit.call(&"add_prop", decals, FACE,
				Vector2((cell.x + 0.5) * TILE, (cell.y + 1) * TILE + _height(kit, FACE)),
				"Ledge%03d" % count)
			face.set(&"footprint", [] as Array[Vector2i])
			face.modulate = ISLAND_TINT
			count += 1
		for dx: int in [-1, 1]:
			if _is_wet(plan, cell + Vector2i(dx, 0)):
				var side: Node2D = kit.call(&"add_floor_prop", SIDE, cell, "Side%03d" % count)
				side.position.x += dx * (TILE / 2.0 - 12.0)
				side.modulate = ISLAND_TINT
				count += 1
	return count


func _height(kit: Object, id: String) -> float:
	return (kit.call(&"_texture_of", id) as Texture2D).get_height()


## Rochers `o` : un par case, sur leurs cases déjà bloquées (sprites seuls, sans emprise).
func _rocks(kit: Object, entities: Node2D, plan: Object, seed_value: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var count := 0
	for cell: Vector2i in plan.cells_of(ROCK_MARK):
		var foot := Vector2((cell.x + 0.5) * TILE + rng.randf_range(-8.0, 8.0),
			(cell.y + 1) * TILE - rng.randf_range(0.0, 8.0))
		var rock: Sprite2D = kit.call(&"add_sprite", entities, ROCK, foot, "Rock%02d" % count)
		var s := rng.randf_range(1.25, 1.5)
		rock.scale = Vector2(s, s)
		rock.flip_h = rng.randf() < 0.5
		var value := rng.randf_range(0.92, 1.04)
		rock.modulate = ROCK_TINT * Color(value, value, value)
		count += 1
	return count


## Eau vive de la salle 1 : courant `>` et cascade (image seule).
func _flows(kit: Object, decals: Node2D, entities: Node2D, plan: Object,
		map_id: StringName) -> void:
	var cells: Array[Vector2i] = plan.cells_of(">")
	if not cells.is_empty():
		var rect := Rect2(Vector2(cells[0]), Vector2.ONE)
		for cell: Vector2i in cells:
			rect = rect.merge(Rect2(Vector2(cell), Vector2.ONE))
		var length := rect.size.x * TILE
		var across := rect.size.y * TILE
		var sprite := _flow_sprite(Vector2(across, length), Vector4(0.08, 0.08, 0.0, 0.14),
			FLOW_STRENGTH, "Current")
		# Le flux de la texture va vers le bas de l'image : tournée vers l'est.
		sprite.rotation = -PI / 2.0
		sprite.position = (rect.position + rect.size / 2.0) * TILE
		kit.call(&"attach", decals, sprite)
	if SPILLS.has(map_id):
		var spill: Rect2i = SPILLS[map_id]
		var foam := _flow_sprite(Vector2(spill.size * TILE), Vector4(0.1, 0.1, 0.0, 0.85),
			SPILL_STRENGTH, "Spill")
		foam.centered = false
		foam.position = Vector2(spill.position * TILE)
		kit.call(&"attach", decals, foam)
	if map_id == &"sea_cave_1":
		var height := (FALL_ROWS.y - FALL_ROWS.x) * TILE
		var fall := _flow_sprite(Vector2(TILE * 1.5, height), Vector4(0.3, 0.3, 0.28, 0.12),
			FALL_STRENGTH, "Fall")
		fall.centered = false
		fall.offset = Vector2(-TILE * 0.75, -height)
		fall.position = Vector2((FALL_COLUMN + 0.5) * TILE, FALL_ROWS.y * TILE)
		kit.call(&"attach", entities, fall)


## Sprite d'eau vive : région [param size] (pixels) d'une texture répétée, shader de défilement.
func _flow_sprite(size: Vector2, fade: Vector4, strength: float, node_name: String) -> Sprite2D:
	var texture: Texture2D = load(GROUND % FAST_WATER)
	var side := float(texture.get_width())
	var material := ShaderMaterial.new()
	material.shader = load(FLOW_SHADER)
	material.set_shader_parameter(&"flow", Vector2(0.0, -FLOW_SPEED / side))
	material.set_shader_parameter(&"extent", size / side)
	material.set_shader_parameter(&"fade", fade)
	material.set_shader_parameter(&"strength", strength)
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, size)
	sprite.material = material
	return sprite


## Puits de lumière : flaque au sol et colonne, en [constant SHAFTS] ; flaques seules en
## [constant POOLS].
func _lights(kit: Object, map_id: StringName) -> void:
	var index := 0
	for at: Vector2 in SHAFTS.get(map_id, []):
		var foot := at * TILE
		kit.call(&"add_glow", &"shaft", foot + Vector2(0.0, -0.4 * TILE), "Shaft%d" % index)
		kit.call(&"add_glow", &"beam", foot, "Beam%d" % index)
		index += 1
	for at: Vector2 in POOLS.get(map_id, []):
		kit.call(&"add_glow", &"projector", at * TILE, "Pool%d" % index)
		index += 1


## Retire ce que cette passe a posé (relance).
func _clean_cave(root: Node) -> void:
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


# --- Bourg Palette ------------------------------------------------------------------------


func _build_pallet() -> void:
	var path := MAPS_DIR + "%s.tscn" % PALLET
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	var entities := root.get_node(^"Entities")
	var open := entities.get_node_or_null(NodePath(PAL_OPEN))
	var closed := entities.get_node_or_null(NodePath(PAL_CLOSED))
	if open == null or closed == null:
		push_error("pallet_town : portes de la bouche absentes (build_joh1_pallet_cave.gd)")
		_errors += 1
		root.free()
		return
	var removed := _clear_gate(open) + _clear_gate(closed)
	var mouth := _gate_sprite(root, open, PAL_MOUTH, Vector2(0.0, PAL_SINK), false, "Mouth")
	mouth.scale = Vector2.ONE * PAL_MOUTH_SCALE
	var index := 0
	for spec: Array in PAL_FLANKS:
		_gate_sprite(root, open, spec[0], spec[1], spec[2], "Flank%d" % index)
		index += 1
	index = 0
	for spec: Array in PAL_REEF:
		_gate_sprite(root, closed, spec[0], spec[1], spec[2], "Reef%d" % index)
		index += 1
	var err := _save(root, path)
	print("pallet_town : %s (%d aplats retirés)" % [error_string(err), removed])
	root.free()


## Vide les dessins d'une porte : aplats `Polygon2D` et images d'une passe précédente. Renvoie le
## nombre d'aplats retirés.
func _clear_gate(gate: Node) -> int:
	var removed := 0
	for child: Node in gate.get_children():
		if child is Polygon2D:
			removed += 1
		elif not String(child.name).begins_with(OWN_PREFIX):
			continue
		gate.remove_child(child)
		child.free()
	return removed


## Image de l'objet peint [param id] sous la porte, pied en [param foot] (repère de la porte).
func _gate_sprite(root: Node, gate: Node, id: String, foot: Vector2, flip: bool,
		node_name: String) -> Sprite2D:
	var model := (load(PROPS % id) as PackedScene).instantiate()
	var sprite := (model.get_node(^"Sprite") as Sprite2D).duplicate() as Sprite2D
	model.free()
	sprite.name = OWN_PREFIX + node_name
	sprite.unique_name_in_owner = false
	sprite.position = (foot + sprite.position).round()
	sprite.flip_h = flip
	gate.add_child(sprite)
	sprite.owner = root
	return sprite


# --- Communs ------------------------------------------------------------------------------


func _save(root: Node, path: String) -> int:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	if err != OK:
		_errors += 1
	return err


## Déplace [param node] du kit jetable vers [param parent] de la carte (voir
## `build_daf4_caves.gd`).
func _adopt(node: Node, parent: Node, root: Node, kit_root: Node) -> void:
	var owned: Array[Node] = []
	_collect(node, kit_root, owned)
	for n: Node in owned:
		n.owner = null
	node.get_parent().remove_child(node)
	parent.add_child(node)
	for n: Node in owned:
		n.owner = root


func _collect(node: Node, kit_root: Node, into: Array[Node]) -> void:
	if node.owner == kit_root:
		into.append(node)
	for child: Node in node.get_children():
		_collect(child, kit_root, into)
