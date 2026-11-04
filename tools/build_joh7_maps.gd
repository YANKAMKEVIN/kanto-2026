extends SceneTree
## Construit les cinq cartes du jalon JOH7 (Chapitre Johto, `docs/tech/jalon-joh7.md` §2.1 ;
## dossier JOH-08) d'après leurs grilles validées (`tools/plans/route_40.txt`, `route_41.txt`,
## `whirl_islands_1f.txt`, `whirl_islands_b1f.txt`, `whirl_islands_b2f.txt` : **la grille fait
## foi** ; contrôle `tools/art/plan_check_joh7.py`), en tuiles provisoires (`OverworldTiles`) :
##   route_40, route_41 (mer, Surf, tourbillons), whirl_islands_1f / _b1f / _b2f (grottes).
## Même méthode que la grotte marine du JOH1 (`tools/build_joh1_sea_cave.gd` : eau surfable,
## courants permanents ou [CurrentGate], arrivées en Surf forcé, rangée 0 bloquée) et que les
## rochers de Force de la Route Victoire (`tools/build_j29.gd`, [BoulderSetup]).
##
## Par carte : sol (falaise `R # o`, eau surfable `w d < > ^ v`, sable ou terre `s . E U V`,
## gravats `g`), eau pêchable sur les routes, tourbillons `@` (eau bloquée + [WhirlpoolField] +
## un examen M-4 par rangée ou colonne de tourbillons), cascade `F` (bloquée + [WaterfallDecor]),
## arrivées (une par case : `<id>`, `<id>_1`…), passages (bords PUSH case à case, entrée de la
## grotte STEP_ON →, échelles STEP_ON), panneaux, examens, déclencheurs, rochers de Force, ombre
## de Lugia ([FlagGate] du sprite de la grotte marine), halo bleu du B2F.
## PNJ, Dresseurs, objets, Pokémon fixes : `data/npcs/<carte>.json` (`tools/gen_joh7_data.py`).
##
##   godot --headless --path . -s res://tools/build_joh7_maps.gd [-- --maps=route_40,route_41]
##   godot --headless --path . --import

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const PROPS_DIR: String = "res://game/world/props/painted/"
const SIGN_PROP: String = "prop_panneau_01"
const SHADOW_TEXTURE: String = "res://assets/world/props/placeholder/lugia_shadow.png"
## Warp.Trigger (valeurs).
const STEP_ON: int = 0
const PUSH: int = 1
const SOLID: String = "R#oF"
const WATER: String = "wd<>^v@"
const CURRENTS: Dictionary = {">": Vector2i.RIGHT, "v": Vector2i.DOWN, "<": Vector2i.LEFT,
	"^": Vector2i.UP}
const SENSES: Dictionary = {"bas": Vector2i.DOWN, "haut": Vector2i.UP, "gauche": Vector2i.LEFT,
	"droite": Vector2i.RIGHT}
const FACINGS: Dictionary = {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
	"right": Vector2i.RIGHT}
const COLOR_LADDER := Color(0.55, 0.38, 0.2)
const COLOR_LADDER_RUNG := Color(0.3, 0.2, 0.1)
const HALO_COLOR := Color(0.55, 0.8, 1.0, 0.22)

## Cartes : grille, nom, sous-titre (champ « region »), intérieur, lumière, graine.
const MAPS: Dictionary = {
	&"route_40": {"plan": "route_40", "name": "Route 40", "region": "Oliville — Îles Tourbillon",
		"interior": false, "light": &"johto_auto", "seed": 4001, "fishing": true},
	&"route_41": {"plan": "route_41", "name": "Route 41", "region": "Îles Tourbillon",
		"interior": false, "light": &"johto_auto", "seed": 4101, "fishing": true},
	&"whirl_islands_1f": {"plan": "whirl_islands_1f", "name": "Îles Tourbillon",
		"region": "Route 41", "interior": true, "light": &"sea_cave", "seed": 4201},
	&"whirl_islands_b1f": {"plan": "whirl_islands_b1f", "name": "Îles Tourbillon",
		"region": "Route 41", "interior": true, "light": &"sea_cave", "seed": 4202},
	&"whirl_islands_b2f": {"plan": "whirl_islands_b2f", "name": "Îles Tourbillon",
		"region": "Route 41", "interior": true, "light": &"whirl_islands_b2f", "seed": 4203},
}
## Passages : « carte/position » → [déclenchement, direction, carte cible, arrivée (suffixe `_n`
## par case de rang n), orientation à l'arrivée].
const WARPS: Dictionary = {
	"route_40/warp_nord": [PUSH, Vector2i.UP, &"olivine_city", "from_route_40", Vector2i.UP],
	"route_40/warp_sud": [PUSH, Vector2i.DOWN, &"route_41", "from_route_40", Vector2i.DOWN],
	"route_41/warp_nord": [PUSH, Vector2i.UP, &"route_40", "from_route_41", Vector2i.UP],
	"route_41/entree_iles": [STEP_ON, Vector2i.RIGHT, &"whirl_islands_1f", "from_route_41",
		Vector2i.RIGHT],
	"whirl_islands_1f/sortie": [PUSH, Vector2i.LEFT, &"route_41", "from_whirl", Vector2i.LEFT],
	"whirl_islands_1f/vers_b1f": [STEP_ON, Vector2i.ZERO, &"whirl_islands_b1f", "from_1f",
		Vector2i.DOWN],
	"whirl_islands_b1f/vers_1f": [STEP_ON, Vector2i.ZERO, &"whirl_islands_1f", "from_b1f",
		Vector2i.DOWN],
	"whirl_islands_b1f/vers_b2f": [STEP_ON, Vector2i.ZERO, &"whirl_islands_b2f", "from_b1f",
		Vector2i.DOWN],
	"whirl_islands_b2f/vers_b1f": [STEP_ON, Vector2i.ZERO, &"whirl_islands_b1f", "from_b2f",
		Vector2i.DOWN],
}
## Panneaux et examens : « carte/position » → [dialogue, orientation exigée].
const TEXTS: Dictionary = {
	"route_40/panneau": [&"route_40_sign", Vector2i.UP],
	"route_41/panneau_route": [&"route_41_sign", Vector2i.UP],
	"route_41/panneau_iles": [&"whirl_islands_sign", Vector2i.UP],
	"whirl_islands_b2f/cascade": [&"whirl_islands_waterfall", Vector2i.UP],
}
const SIGNS: Array[String] = ["route_40/panneau", "route_41/panneau_route", "route_41/panneau_iles"]
const WHIRLPOOL_DIALOGUE: StringName = &"whirlpool_examine"
const CURRENT_DIALOGUE: StringName = &"whirl_current"
const CURRENT_GATED_DIALOGUE: StringName = &"whirl_b2f_current_examine"
## Déclencheurs : « carte/position » → [scène, direction du pas (ZERO = toutes)].
const TRIGGERS: Dictionary = {
	"whirl_islands_b1f/scene_suicune": [&"whirl_suicune_seen", Vector2i.ZERO],
	"whirl_islands_b1f/scene_cenere": [&"whirl_cenere", Vector2i.ZERO],
	"whirl_islands_b1f/scene_crique": [&"whirl_cove", Vector2i.LEFT],
	"whirl_islands_b1f/examen_courant_b2f": [&"whirl_b2f_current", Vector2i.UP],
	"whirl_islands_b2f/scene_lugia": [&"whirl_lugia_rise", Vector2i.ZERO],
}
## Déclencheurs hors grille [D] : la crique s'ouvre aussi par le sud (rangée 26) ; même scène.
const EXTRA_TRIGGERS: Dictionary = {
	&"whirl_islands_b1f": {"SceneCriqueSud": [Rect2i(1, 25, 6, 1), &"whirl_cove", Vector2i.UP]},
	# M-22 : premier pas sur la corniche sous l'échelle d'arrivée (toutes directions).
	&"whirl_islands_b2f": {"SceneCoeur": [Rect2i(1, 4, 4, 1), &"whirl_b2f_heart", Vector2i.ZERO]},
}
## Arrivées de débogage [D] (départs `tools/debug_start/johto_whirl_*.json`).
const DEBUG_SPAWNS: Dictionary = {
	&"whirl_islands_b1f": {"debug_suicune": Vector2i(11, 6), "debug_cove": Vector2i(8, 22),
		"debug_dragon_scale": Vector2i(4, 13)},
	&"whirl_islands_b2f": {"debug_lugia": Vector2i(12, 18), "debug_lugia_water": Vector2i(11, 17)},
}
## Ombre de Lugia (B2F) : départ (bord ouest du bassin, deux rangées sous Lugia, dans le cadre une
## fois le joueur avancé de 4 cases par la scène) ; la scène la déplace
## de 10 cases vers l'est (`gen_joh7_data.py`, SHADOW_OFFSET).
const SHADOW_MAP: StringName = &"whirl_islands_b2f"
const SHADOW_START := Vector2i(7, 11)
const SHADOW_FLAG: StringName = &"johto_whirl_lugia_passing"
const SHADOW_SCALE: float = 2.6

var _over: GDScript
var _rules: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_rules = load("res://game/world/props/painted_prop_rules.gd")
	var wanted := _wanted()
	for id: StringName in MAPS:
		if wanted.is_empty() or wanted.has(String(id)):
			_build(id)
	print("build_joh7_maps : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _wanted() -> Array:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--maps="):
			return Array(arg.trim_prefix("--maps=").split(","))
	return []


func _build(map_id: StringName) -> void:
	var spec: Dictionary = MAPS[map_id]
	var plan := PlanGrid.new()
	if not plan.load_file(PLANS_DIR + String(spec["plan"]) + ".txt"):
		_fail("%s : %s" % [map_id, plan.error])
		return
	_rng.seed = spec["seed"]
	var size := Vector2i(plan.width, plan.height)
	var root := _new_map(map_id, spec, size)
	var entities: Node = root.get_node(^"Entities")
	var blocked: Array[Vector2i] = []
	var whirlpools: Array[Vector2i] = []
	var falls: Array[Vector2i] = []
	_paint(root, plan, blocked, whirlpools, falls)
	# Eau surfable (les tourbillons ne le sont pas) ; pêche sur toute l'eau des routes.
	var surf: Array[Vector2i] = []
	for cell: Vector2i in plan.cells_of(WATER):
		if plan.at(cell) != "@":
			surf.append(cell)
	root.set(&"surf_cells", surf)
	if spec.get("fishing", false):
		root.set(&"fishable_cells", surf.duplicate())
	_currents(root, entities, plan, map_id)
	# Arrivées (une par case) et Surf forcé ; rangée 0 bloquée, entrées et arrivées en rangée 1
	# (règle du JOH1 : sinon le joueur arrive la tête hors de l'écran).
	var forced: Array[Vector2i] = []
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
				blocked.append(cell)
	var debug: Dictionary = DEBUG_SPAWNS.get(map_id, {})
	for spawn_name: String in debug:
		_spawn(root, spawn_name, debug[spawn_name])
		if surf.has(debug[spawn_name]):
			forced.append(debug[spawn_name])
	root.set(&"forced_surf_cells", forced)
	_warps(root, plan, map_id)
	_texts(root, plan, map_id, blocked)
	_triggers(root, plan, map_id)
	_current_examines(root, plan, map_id)
	if not whirlpools.is_empty():
		_whirlpools(root, whirlpools)
	if not falls.is_empty():
		var decor := Node2D.new()
		decor.set_script(load("res://game/world/surf/waterfall_decor.gd"))
		decor.name = "Cascade"
		decor.set(&"cells", falls)
		_attach(root, root.get_node(^"Decor"), decor)
	if not _ids(plan, "rocher").is_empty():
		_boulders(root, plan)
	for id: String in _ids(plan, "escalier"):
		_ladder(root, entities, plan.cell_of(id))
	if map_id == SHADOW_MAP:
		_shadow(root, entities)
		_halo(root, plan)
	root.set(&"blocked_cells", blocked)
	_save(root, MAPS_DIR + String(map_id) + ".tscn")


## Sol provisoire : un type de tuile par caractère ; tourbillons et cascade relevés à part.
func _paint(root: Node, plan: Object, blocked: Array[Vector2i], whirlpools: Array[Vector2i],
		falls: Array[Vector2i]) -> void:
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			var c: String = plan.at(cell)
			var kind: int = _over.Kind.DIRT
			if c == "F":
				kind = _over.Kind.WATER
				falls.append(cell)
				blocked.append(cell)
			elif SOLID.contains(c):
				kind = _over.Kind.CLIFF
			elif WATER.contains(c):
				kind = _over.Kind.WATER
				if c == "@":
					whirlpools.append(cell)
					blocked.append(cell)
			elif c == "g":
				kind = _over.Kind.RUBBLE
			elif c == "s" or (c == "." and not root.get(&"interior")):
				kind = _over.Kind.SAND
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))


## Courants : ceux d'une position « courant » à drapeau sont des [CurrentGate] ; les autres
## flèches de la grille sont permanentes (`current_cells`).
func _currents(root: Node, entities: Node, plan: Object, map_id: StringName) -> void:
	var gated: Dictionary = {}
	for id: String in _ids(plan, "courant"):
		var flag: String = plan.attr(id, "actif_sans")
		if flag.is_empty():
			continue
		var sense: String = plan.attr(id, "sens")
		if not SENSES.has(sense):
			_fail("%s : sens de courant inconnu « %s » (%s)" % [map_id, sense, id])
			continue
		var cells: Dictionary[Vector2i, Vector2i] = {}
		for cell: Vector2i in plan.cells_at(id):
			cells[cell] = SENSES[sense]
			gated[cell] = true
		var gate := Node2D.new()
		gate.set_script(load("res://game/world/surf/current_gate.gd"))
		gate.name = id.to_pascal_case()
		gate.set(&"cells", cells)
		var unless: Array[StringName] = [StringName(flag)]
		gate.set(&"unless_flags", unless)
		_attach(root, entities, gate)
	var currents: Dictionary[Vector2i, Vector2i] = {}
	for c: String in CURRENTS:
		for cell: Vector2i in plan.cells_of(c):
			if not gated.has(cell):
				currents[cell] = CURRENTS[c]
	root.set(&"current_cells", currents)


func _warps(root: Node, plan: Object, map_id: StringName) -> void:
	for id: String in plan.positions:
		var kind: String = plan.positions[id]["kind"]
		if kind != "warp" and kind != "escalier":
			continue
		var key := "%s/%s" % [map_id, id]
		if not WARPS.has(key):
			_fail("%s : passage sans destination" % key)
			continue
		var spec: Array = WARPS[key]
		var cells: Array[Vector2i] = plan.cells_at(id)
		for i: int in cells.size():
			var arrival: String = spec[3] if i == 0 else "%s_%d" % [spec[3], i]
			_warp(root, "%s_%d" % [id.to_pascal_case(), i], _off_top(cells[i]), spec[0], spec[1],
				spec[2], StringName(arrival), spec[4])


## Panneaux (piquet peint dans l'eau, case bloquée), examens, Pokémon fixes et objets bloquent
## leur case (les PNJ de `data/npcs/` la bloquent aussi tant qu'ils sont là).
func _texts(root: Node, plan: Object, map_id: StringName, blocked: Array[Vector2i]) -> void:
	for id: String in plan.positions:
		var key := "%s/%s" % [map_id, id]
		if not TEXTS.has(key):
			continue
		var spec: Array = TEXTS[key]
		var cell: Vector2i = plan.cell_of(id)
		_interact(root, id.to_pascal_case(), cell, Vector2i.ONE, spec[1], spec[0])
		if not blocked.has(cell):
			blocked.append(cell)
		if SIGNS.has(key):
			_add_prop(root, SIGN_PROP, cell, id.to_pascal_case() + "Sign")


## Déclencheurs de la grille et hors grille.
func _triggers(root: Node, plan: Object, map_id: StringName) -> void:
	for id: String in _ids(plan, "declencheur"):
		var key := "%s/%s" % [map_id, id]
		if not TRIGGERS.has(key):
			_fail("%s : déclencheur sans scène" % key)
			continue
		var spec: Array = TRIGGERS[key]
		_trigger(root, id.to_pascal_case(), _rect_of(plan.cells_at(id)), spec[1], spec[0])
	var key_examen := "%s/examen_courant_b2f" % map_id
	if TRIGGERS.has(key_examen) and plan.positions.has("examen_courant_b2f"):
		var spec: Array = TRIGGERS[key_examen]
		_trigger(root, "ExamenCourantB2f", _rect_of(plan.cells_at("examen_courant_b2f")), spec[1],
			spec[0])
	var extra: Dictionary = EXTRA_TRIGGERS.get(map_id, {})
	for node_name: String in extra:
		var spec: Array = extra[node_name]
		_trigger(root, node_name, spec[0], spec[2], spec[1])


## Examen des courants (M-11 « Le courant emporte {player} ! ») sur chaque case de courant
## permanente ; le courant violent du B1F (position à drapeau) dit M-20 / M-21.
func _current_examines(root: Node, plan: Object, map_id: StringName) -> void:
	var gated: Dictionary = {}
	for id: String in _ids(plan, "courant"):
		if plan.attr(id, "actif_sans").is_empty():
			continue
		for cell: Vector2i in plan.cells_at(id):
			gated[cell] = true
			_interact(root, "ExamenCourantViolent%d_%d" % [cell.x, cell.y], cell, Vector2i.ONE,
				Vector2i.ZERO, CURRENT_GATED_DIALOGUE)
	for c: String in CURRENTS:
		for cell: Vector2i in plan.cells_of(c):
			if not gated.has(cell):
				_interact(root, "ExamenCourant%d_%d" % [cell.x, cell.y], cell, Vector2i.ONE,
					Vector2i.ZERO, CURRENT_DIALOGUE)


## Tourbillons : dessin animé et examen M-4 par rangée ou colonne continue de tourbillons.
func _whirlpools(root: Node, cells: Array[Vector2i]) -> void:
	var field := Node2D.new()
	field.set_script(load("res://game/world/surf/whirlpool_field.gd"))
	field.name = "Tourbillons"
	field.set(&"cells", cells)
	_attach(root, root.get_node(^"Decor"), field)
	var set: Dictionary = {}
	for cell: Vector2i in cells:
		set[cell] = true
	var used: Dictionary = {}
	var index := 0
	for cell: Vector2i in cells:
		if used.has(cell):
			continue
		# Rangée vers l'est d'abord, sinon colonne vers le sud.
		var run: Array[Vector2i] = [cell]
		var next := cell + Vector2i.RIGHT
		while set.has(next) and not used.has(next):
			run.append(next)
			next += Vector2i.RIGHT
		if run.size() == 1:
			next = cell + Vector2i.DOWN
			while set.has(next) and not used.has(next):
				run.append(next)
				next += Vector2i.DOWN
		for c: Vector2i in run:
			used[c] = true
		var rect := _rect_of(run)
		# Ancre en bas à gauche (InteractPoint : x 0..size.x-1, y -(size.y-1)..0).
		_interact(root, "Tourbillon%d" % index, Vector2i(rect.position.x, rect.end.y - 1),
			rect.size, Vector2i.ZERO, WHIRLPOOL_DIALOGUE)
		index += 1


func _boulders(root: Node, plan: Object) -> void:
	var setup := Node.new()
	setup.set_script(load("res://game/world/boulders/boulder_setup.gd"))
	setup.name = "Boulders"
	var boulder_cells: Array[Vector2i] = []
	var boulder_holes: Array[int] = []
	var boulder_requires: Array[StringName] = []
	var empty_cells: Array[Vector2i] = []
	var empty_ints: Array[int] = []
	var empty_names: Array[StringName] = []
	for id: String in _ids(plan, "rocher"):
		boulder_cells.append(plan.cell_of(id))
		boulder_holes.append(0)
		boulder_requires.append(&"")
	setup.set(&"boulder_cells", boulder_cells)
	setup.set(&"boulder_holes", boulder_holes)
	setup.set(&"boulder_requires", boulder_requires)
	setup.set(&"hole_cells", empty_cells.duplicate())
	setup.set(&"hole_numbers", empty_ints.duplicate())
	setup.set(&"hole_flags", empty_names.duplicate())
	setup.set(&"switch_cells", empty_cells.duplicate())
	setup.set(&"switch_ids", empty_names.duplicate())
	setup.set(&"switch_flags", empty_names.duplicate())
	setup.set(&"no_push_cells", empty_cells.duplicate())
	_attach(root, root, setup)


func _ladder(root: Node, entities: Node, cell: Vector2i) -> void:
	var ladder := _gate(root, entities, "Echelle%d_%d" % [cell.x, cell.y], cell)
	_rect(root, ladder, Rect2(-30, -88, 60, 80), COLOR_LADDER)
	for k: int in 3:
		_rect(root, ladder, Rect2(-22, -80 + k * 24, 44, 8), COLOR_LADDER_RUNG)


## L'ombre de Lugia : porte de drapeaux sous `Entities` (dessinée après le sol, avant le joueur).
func _shadow(root: Node, entities: Node) -> void:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = "LugiaShadow"
	gate.position = Vector2((SHADOW_START.x + 0.5) * TILE, (SHADOW_START.y + 0.5) * TILE)
	var if_flags: Array[StringName] = [SHADOW_FLAG]
	gate.set(&"if_flags", if_flags)
	var unless: Array[StringName] = []
	gate.set(&"unless_flags", unless)
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


## Halo de lumière bleue venue d'en haut (position « halo » de la grille), provisoire [D].
func _halo(root: Node, plan: Object) -> void:
	if not plan.positions.has("halo"):
		return
	var cell: Vector2i = plan.cell_of("halo")
	var center := (Vector2(cell) + Vector2(0.5, 0.5)) * TILE
	for ring: int in 3:
		var poly := Polygon2D.new()
		poly.name = "Halo%d" % ring
		poly.color = HALO_COLOR
		var radius := Vector2(4.5, 5.5) * TILE * (1.0 - ring * 0.28)
		var points := PackedVector2Array()
		for k: int in 32:
			points.append(center + Vector2.from_angle(TAU * k / 32.0) * radius)
		poly.polygon = points
		_attach(root, root.get_node(^"Decor"), poly)


## Une case de la rangée 0 (bord nord) passe à la rangée 1.
func _off_top(cell: Vector2i) -> Vector2i:
	return cell + Vector2i.DOWN if cell.y == 0 else cell


func _rect_of(cells: Array[Vector2i]) -> Rect2i:
	var top_left := cells[0]
	var bottom_right := cells[0]
	for cell: Vector2i in cells:
		top_left = Vector2i(mini(top_left.x, cell.x), mini(top_left.y, cell.y))
		bottom_right = Vector2i(maxi(bottom_right.x, cell.x), maxi(bottom_right.y, cell.y))
	return Rect2i(top_left, bottom_right - top_left + Vector2i.ONE)


## Identifiants des positions de type [param kind], dans l'ordre du fichier.
func _ids(plan: Object, kind: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in plan.positions:
		if plan.positions[id]["kind"] == kind:
			ids.append(id)
	return ids


func _new_map(map_id: StringName, spec: Dictionary, size: Vector2i) -> Node2D:
	var root := Node2D.new()
	root.name = String(map_id).to_pascal_case()
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", map_id)
	root.set(&"display_name", spec["name"])
	root.set(&"region", spec["region"])
	root.set(&"size", size)
	root.set(&"interior", spec["interior"])
	root.set(&"no_fly", spec["interior"])
	root.set(&"light_profile", spec["light"])
	# Tableaux typés posés explicitement : sans les autoloads, map.gd peut ne pas compiler dans
	# l'outil et un tableau laissé par défaut serait enregistré « Array[int] » (JOH2).
	for property: StringName in [&"calm_cells", &"slope_cells", &"surf_cells", &"forced_surf_cells",
			&"fishable_cells", &"low_cells", &"high_cells", &"stairs_cells", &"cycling_road_cells"]:
		var empty: Array[Vector2i] = []
		root.set(property, empty)
	var rows: Array[int] = []
	root.set(&"level_rows", rows)
	var currents: Dictionary[Vector2i, Vector2i] = {}
	root.set(&"current_cells", currents)
	var tileset: TileSet = load(_over.TILESET_PATH)
	_add_layer(root, "Ground", tileset)
	_add_layer(root, "Detail", tileset)
	_add_layer(root, "Obstacles", tileset)
	var decor := Node2D.new()
	decor.name = "Decor"
	_attach(root, root, decor)
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


func _interact(root: Node, node_name: String, cell: Vector2i, span: Vector2i, facing: Vector2i,
		dialogue: StringName) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"size", span)
	point.set(&"facing", facing)
	point.set(&"dialogue_id", dialogue)
	var empty: Array[StringName] = []
	point.set(&"if_flags", empty)
	point.set(&"unless_flags", empty.duplicate())
	_attach(root, root.get_node(^"Interactables"), point)


func _trigger(root: Node, node_name: String, rect: Rect2i, direction: Vector2i,
		cutscene: StringName) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/triggers/event_trigger_point.gd"))
	point.name = node_name
	# Ancre en bas à gauche (EventTriggerPoint : y -(size.y-1)..0).
	point.position = _world(Vector2i(rect.position.x, rect.end.y - 1))
	point.set(&"size", rect.size)
	point.set(&"direction", direction)
	point.set(&"cutscene_id", cutscene)
	_attach(root, root.get_node(^"Triggers"), point)


func _add_prop(root: Node, id: String, anchor: Vector2i, node_name: String) -> void:
	var scene := load(PROPS_DIR + id + ".tscn") as PackedScene
	if scene == null:
		_fail("objet peint introuvable : %s" % id)
		return
	var prop := scene.instantiate() as Node2D
	prop.name = node_name
	prop.position = _rules.call(&"foot_position", StringName(id), anchor)
	_attach(root, root.get_node(^"Entities"), prop)


func _gate(root: Node, parent: Node, gate_name: String, cell: Vector2i) -> Node2D:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = gate_name
	gate.position = _world(cell)
	var empty: Array[StringName] = []
	gate.set(&"if_flags", empty)
	gate.set(&"unless_flags", empty.duplicate())
	_attach(root, parent, gate)
	return gate


func _rect(root: Node, parent: Node, rect: Rect2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = "Dessin"
	poly.color = color
	poly.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)])
	_attach(root, parent, poly)


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
	push_error("build_joh7_maps : " + message)
	_errors += 1
