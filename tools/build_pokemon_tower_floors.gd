extends SceneTree
## Construit les cartes 2F à 6F de la Tour Pokémon (jalon 19 T9, docs/tech/jalon-19.md §2.1,
## §2.2, §2.8 ; dossier 22 §4 à §9) d'après les grilles `tools/plans/pokemon_tower_<n>f.txt`
## (elles font foi), sur la boîte à outils `tools/cave_map_kit.gd` (réglages « carte sans
## grotte » ouverts par le souterrain du J15 : praticables `.ZUV`, sols réglables, canal R sans
## gravats logiques) :
##
##   godot --headless --path . -s res://tools/build_pokemon_tower_floors.gd [-- --etage=2f|…|6f|tous]
##   godot --headless --path . --import
##   (première fois, ou si un masque change : relancer l'outil après l'import ; code 2 = masque
##   ou voile écrit, importer puis relancer)
##
## - `Ground` (invisible) = source logique : `.` `Z` `U` `V` sol (praticable, aucune herbe, aucun
##   gravat), tout le reste solide (`#` mur, `T` tombe, `S` stèle).
## - Image (**art provisoire**, tant que la série 21 des cartes de la Tour n'existe pas) : sol
##   en dalles et murs maçonnés du souterrain (J15) ; tombes (stèle réduite, sombre) et stèles ;
##   escaliers ramenés à une case ; dalle claire de la zone purifiée (5F) ; voile de pénombre dont
##   l'`ambient` baisse d'étage en étage (0,96 au 2F, 0,88 au 6F).
## - Passages : escaliers `STEP_ON` sans direction vers le point d'apparition de même paire de
##   l'étage voisin (orientation de la grille). 2F → 1F (paire T12) : le rez-de-chaussée du J18
##   (spawn `from_pokemon_tower_2f`, T16). **Repli « à venir »** : 6F → 7F (paire T67,
##   inatteignable au J19).
## - Points d'apparition de la grille, plus ceux de QA : `devant_rival` (16, 7) au 2F et
##   `devant_spectre` (10, 14) au 6F.
## - Déclencheurs (`EventTriggerPoint`, scènes posées par T14 à T18, sans effet tant qu'elles
##   n'existent pas) : rival (2F, sans direction), zone purifiée (5F, une par case `Z` et par
##   direction qui vient du dehors, §2.8), SPECTRE (6F, sans direction).
## - `calm_cells` (5F seulement) : cases `Z` et leurs 8 voisines praticables (§2.2).
## - Lumière (T19) : profil `tower`, halos `candle` (stèles) et `purified` (zone du 5F), brume
##   (`MistLayer`) ; pas posés ici : PNJ, Dresseurs, objets, `caves.json` et `zones.json` (T16).
##   Racine **extérieure** (`interior = false`).

const Kit := preload("res://tools/cave_map_kit.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const MAPS_DIR: String = "res://game/world/maps/"
const SIZE := Vector2i(20, 18)
const DISPLAY_NAME: String = "Tour Pokémon"
const TILE: int = 96
const WALKABLE: String = ".ZUV"
## Jalon 21 : la grille du 7F n'a ni zone `Z` ni escalier `U` (légende « PRATICABLES .V »).
const WALKABLE_7F: String = ".V"
const WALL_MARK: String = "#"
const TOMB_MARK: String = "T"
const STELE_MARK: String = "S"
const ZONE_MARK: String = "Z"
## Profil de lumière de la Tour (T19).
const PROFILE: StringName = &"tower"

## Étage → [identifiant, nœud racine, graine logique, graine du décor, graine des murs, ambient].
const FLOORS: Dictionary = {
	"2f": [&"pokemon_tower_2f", "PokemonTower2F", 1901, 1902, 1903, 0.96],
	"3f": [&"pokemon_tower_3f", "PokemonTower3F", 1911, 1912, 1913, 0.94],
	"4f": [&"pokemon_tower_4f", "PokemonTower4F", 1921, 1922, 1923, 0.92],
	"5f": [&"pokemon_tower_5f", "PokemonTower5F", 1931, 1932, 1933, 0.90],
	"6f": [&"pokemon_tower_6f", "PokemonTower6F", 1941, 1942, 1943, 0.88],
	# Jalon 21 (T13) : le 7F (voile un peu plus sombre [D] : ambient 0,86 après le 6F à 0,88).
	"7f": [&"pokemon_tower_7f", "PokemonTower7F", 1951, 1952, 1953, 0.86],
}
## Opacité de la brume par étage (≤ `MistLayer.ALPHA_MAX`) : 2F le plus clair, 6F le plus brumeux.
const MIST_ALPHA: Dictionary = {"2f": 0.08, "3f": 0.10, "4f": 0.12, "5f": 0.14, "6f": 0.18,
	"7f": 0.2}
const PLAN_PATH: String = "res://tools/plans/pokemon_tower_%s.txt"

## Sols provisoires (souterrain, J15).
const GROUND_DALLES: String = "res://assets/world/ground/ground_dalles_souterrain_01.png"
const GROUND_TRACES: String = "res://assets/world/ground/ground_traces_souterrain_01.png"
const GROUND_ROCK: String = "res://assets/world/ground/ground_masse_roche_01.png"
const BORDER_COLOR := Color(0.42, 0.40, 0.46)

## Murs maçonnés provisoires (souterrain) : faces (2 cases de large), couronnement, côté.
const WALL_FACES: Array[String] = ["relief_mur_souterrain_01", "relief_mur_souterrain_02"]
const WALL_CAP: String = "relief_mur_souterrain_03"
const WALL_SIDE: String = "relief_mur_souterrain_04"
const WALL_SPAN: int = 2
const SIDE_WIDTH: int = 34
const SIDE_TOP: int = 0
const SIDE_MIDDLE: int = 1
const SIDE_BOTTOM: int = 2
const WALL_VALUE_JITTER: float = 0.04

## Repères provisoires : la stèle du souterrain ; la tombe en est une version basse et sombre.
const STELE_PROP: String = "prop_stele_01"
const TOMB_SCALE: float = 0.62
const OFFERING_SCALE: float = 0.4
const OFFERING_TINT := Color(0.78, 0.74, 0.6)
const TOMB_TINT := Color(0.8, 0.78, 0.86)
## Escaliers : images du souterrain (192 px) ramenées à la largeur d'une case.
const STAIRS_UP: String = "prop_escalier_souterrain_monte_01"
const STAIRS_DOWN: String = "prop_escalier_souterrain_descend_01"
const STAIRS_SCALE: float = 0.5
## Dalle bénie de la zone purifiée (5F) : aplat clair posé au sol (provisoire).
const ZONE_COLOR := Color(0.9, 0.92, 1.0, 0.55)

## Voile de pénombre (réglages de `tools/cave_shade.gd`) ; `ambient` vient de [constant FLOORS].
const SHADE_BASE := {"edge_min": 0.72, "edge_radius": 0.8, "room_min": 0.9, "room_radius": 3.0,
	"tint": Color(0.92, 0.9, 1.0)}
const SHADE_LIGHTS: Dictionary = {
	&"candle": {"radius": 2.6, "strength": 0.9, "offset": Vector2(0.0, -40.0), "add": 0.14,
		"color": Color(1.0, 0.8, 0.55)},
	&"purified": {"radius": 3.2, "strength": 1.0, "offset": Vector2.ZERO, "add": 0.16,
		"color": Color(0.9, 0.93, 1.0)},
	&"stairs": {"radius": 2.8, "strength": 0.85, "offset": Vector2.ZERO, "add": 0.05,
		"color": Color(0.92, 0.92, 1.0)},
}
const SHADE_WALL_FOLLOW: float = 0.7
const STELE_LIGHT_HEIGHT: float = 80.0

## Replis « à venir » (étages hors J19).
## Jalon 21 (T12, T13) : le 7F existe, la paire T67 est réelle (plus de repli « à venir »).
const COMING_SOON: String = "Tour Pokémon"
const SOON_PAIRS: Array[String] = []
## Rez-de-chaussée (J18, construit par `build_pokemon_tower.gd`, T16 du J19) : paire T12 → spawn
## `from_pokemon_tower_2f` (case d'accès (17, 3)), tourné vers le bas.
const GROUND_FLOOR_MAP: StringName = &"pokemon_tower_1f"
const GROUND_FLOOR_SPAWN: StringName = &"from_pokemon_tower_2f"
## Scènes (T14 à T18) : rôle du déclencheur → identifiant de scène.
const TRIGGER_SCENES: Dictionary = {
	"R1": &"tower_rival",
	"S1": &"tower_6f_ghost",
}
const ZONE_SCENE: StringName = &"tower_purified_zone"
## Jalon 21 (T12) : brume légère du 6F (drapeau `tower_6f_mist_lifted`), opacité × 0,4 [D].
const MIST_LIFTED_FLAG: StringName = &"tower_6f_mist_lifted"
const MIST_LIFTED_FACTOR: float = 0.4
## Jalon 21 (T12) : halo « esprit » du 6F, caché, posé sur (10, 17) [D : sous l'escalier, d'où
## l'esprit se tenait] ; groupe `scene_props` (cible de l'étape `animate`, nom `SpiritLight`).
const SPIRIT_HALO: String = "res://assets/sprites/effects/spirit_halo.png"
const SPIRIT_CELL := Vector2i(10, 17)
const SPIRIT_GROUP: StringName = &"scene_props"
const STEPS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
## Points d'apparition de QA [D] : étage → [nom, case].
const QA_SPAWNS: Dictionary = {
	"2f": ["devant_rival", Vector2i(16, 7)],
	"6f": ["devant_spectre", Vector2i(10, 14)],
}

var _kit: Object
var _key: String = ""
var _wall_rng := RandomNumberGenerator.new()


func _init() -> void:
	var which := "tous"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--etage="):
			which = arg.trim_prefix("--etage=")
	var keys: Array = FLOORS.keys() if which == "tous" else [which]
	var code := 0
	for key: String in keys:
		if not FLOORS.has(key):
			push_error("build_pokemon_tower_floors : étage inconnu « %s »" % key)
			quit(1)
			return
		code = maxi(code, _build(key))
	quit(code)


## 0 : enregistré ; 2 : masque ou voile écrit, importer puis relancer ; 1 : erreur.
func _build(key: String) -> int:
	_key = key
	var spec: Array = FLOORS[key]
	var map_id: StringName = spec[0]
	_kit = Kit.new(PLAN_PATH % key, SIZE, spec[2], spec[3],
		WALKABLE_7F if key == "7f" else WALKABLE)
	_kit.set(&"floor_texture_path", GROUND_DALLES)
	_kit.set(&"rubble_texture_path", GROUND_TRACES)
	_kit.set(&"mass_texture_path", GROUND_ROCK)
	_kit.set(&"border_color", BORDER_COLOR)
	_kit.set(&"rubble_is_logic", false)
	_wall_rng.seed = spec[4]
	if not _errors().is_empty():
		push_error("build_pokemon_tower_floors %s : %s" % [key, "\n".join(_errors())])
		return 1
	_kit.call(&"make_root", spec[1], map_id, DISPLAY_NAME, PROFILE)
	_set_calm_cells()
	var mask := "res://assets/world/maps/%s_ground.png" % map_id
	if not _kit.call(&"add_ground", mask):
		if not _errors().is_empty():
			push_error("build_pokemon_tower_floors %s :\n%s" % [key, "\n".join(_errors())])
			_kit.call(&"discard")
			return 1
		print("build_pokemon_tower_floors %s : masque écrit ; importer (--import) puis relancer" % key)
		_kit.call(&"discard")
		return 2
	var walls := _place_walls()
	_place_landmarks()
	_place_zone()
	_place_hidden_item()
	_place_stairs()
	_place_spawns_and_warps()
	_place_triggers()
	var shade := "res://assets/world/maps/%s_shade.png" % map_id
	var params: Dictionary = SHADE_BASE.duplicate()
	params["ambient"] = spec[5]
	if _errors().is_empty() and not _kit.call(&"add_shade", shade, params, SHADE_LIGHTS,
			SHADE_WALL_FOLLOW):
		if _errors().is_empty():
			print("build_pokemon_tower_floors %s : voile écrit ; importer (--import) puis relancer" % key)
			_kit.call(&"discard")
			return 2
	_place_mist(key)
	if not _errors().is_empty():
		push_error("build_pokemon_tower_floors %s :\n%s" % [key, "\n".join(_errors())])
		_kit.call(&"discard")
		return 1
	var counts := Vector3i((_kit.get(&"entities") as Node).get_child_count(),
		(_kit.get(&"decals") as Node).get_child_count(), _kit.call(&"glow_count"))
	var result: Vector2i = _kit.call(&"save", MAPS_DIR + String(map_id) + ".tscn")
	print("%s : %s (%d entités, %d au sol, murs %d faces / %d côtés / %d couronnes, %d halos, "
		% [map_id, error_string(result.x), counts.x, counts.y, walls.x, walls.y, walls.z,
		counts.z] + "%d nœuds)" % result.y)
	return 0 if result.x == OK else 1


func _errors() -> PackedStringArray:
	return _kit.get(&"errors")


func _plan() -> Object:
	return _kit.get(&"plan")


func _fail(message: String) -> void:
	var errors := _errors()
	errors.append(message)
	_kit.set(&"errors", errors)


## Brume lente (T19) : un `MistLayer` à la taille de la carte, posé après le voile (sous
## `Entities`), sans `Light2D` ni particule.
func _place_mist(key: String) -> void:
	if key != "6f":
		_kit.call(&"attach", _kit.get(&"root"), _new_mist("Mist", MIST_ALPHA[key]))
		return
	# Jalon 21 (T12, §2.7) : au 6F, la brume du J19 passe dans une FlagGate `unless
	# [tower_6f_mist_lifted]` ; une seconde, plus légère (alpha × 0,4 [D]), dans une FlagGate
	# `if [tower_6f_mist_lifted]`. Même profil `tower`, aucun changement de LightingLibrary.
	_add_mist_gate("MistDenseGate", "Mist", MIST_ALPHA[key], [], [MIST_LIFTED_FLAG])
	_add_mist_gate("MistLightGate", "MistLight", MIST_ALPHA[key] * MIST_LIFTED_FACTOR,
		[MIST_LIFTED_FLAG], [])
	_place_spirit_light()


func _new_mist(node_name: String, alpha: float) -> Sprite2D:
	var mist := Sprite2D.new()
	mist.set_script(load("res://game/world/lighting/mist_layer.gd"))
	mist.name = node_name
	mist.set(&"area", SIZE * TILE)
	mist.set(&"alpha", alpha)
	return mist


func _add_mist_gate(gate_name: String, mist_name: String, alpha: float,
		if_flags: Array[StringName], unless_flags: Array[StringName]) -> void:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = gate_name
	gate.set(&"if_flags", if_flags)
	gate.set(&"unless_flags", unless_flags)
	_kit.call(&"attach", _kit.get(&"root"), gate)
	_kit.call(&"attach", gate, _new_mist(mist_name, alpha))


## Halo peint de l'esprit (6F, Jalon 21) : enfant direct de la carte (`animate SpiritLight`
## le trouve par son chemin), caché, au-dessus des personnages, groupe `scene_props`.
func _place_spirit_light() -> void:
	var halo := Sprite2D.new()
	halo.name = "SpiritLight"
	halo.texture = load(SPIRIT_HALO)
	halo.position = Vector2((SPIRIT_CELL.x + 0.5) * TILE, (SPIRIT_CELL.y + 0.5) * TILE)
	halo.z_index = 20
	halo.visible = false
	halo.add_to_group(SPIRIT_GROUP, true)
	_kit.call(&"attach", _kit.get(&"root"), halo)


# --- Cases calmes (§2.2) -------------------------------------------------------------------


## 5F seulement : cases `Z` et leurs 8 voisines praticables (aucune rencontre, §2.2).
func _set_calm_cells() -> void:
	var calm: Array[Vector2i] = []
	for cell: Vector2i in _plan().call(&"cells_of", ZONE_MARK):
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				var near := cell + Vector2i(dx, dy)
				if _kit.call(&"is_walkable", near) and not calm.has(near):
					calm.append(near)
	calm.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	(_kit.get(&"root") as Node).set(&"calm_cells", calm)


# --- Murs ---------------------------------------------------------------------------------


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE.x and cell.y < SIZE.y


## Paroi : maçonnerie `#` ; une case de repère (tombe, stèle) compte comme ouverte. Hors de la
## carte = paroi.
func _is_wall(cell: Vector2i) -> bool:
	return not _in_bounds(cell) or _plan().call(&"at", cell) == WALL_MARK


func _is_masonry(cell: Vector2i) -> bool:
	return _in_bounds(cell) and _plan().call(&"at", cell) == WALL_MARK


func _is_face(cell: Vector2i) -> bool:
	return _is_masonry(cell) and not _is_wall(cell + Vector2i.DOWN)


func _is_cap(cell: Vector2i) -> bool:
	return _is_masonry(cell) and not _is_face(cell) and not _is_wall(cell + Vector2i.UP)


func _is_side(cell: Vector2i) -> bool:
	return _is_masonry(cell) and not _is_face(cell) \
		and (not _is_wall(cell + Vector2i.LEFT) or not _is_wall(cell + Vector2i.RIGHT))


func _place_walls() -> Vector3i:
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	var faces := 0
	var caps := 0
	for y: int in SIZE.y:
		for run: Vector2i in _row_runs(y, _is_face):
			for piece: Vector2i in _pieces(run):
				var id: String = WALL_FACES[_wall_rng.randi_range(0, WALL_FACES.size() - 1)]
				var foot := Vector2((piece.x + piece.y / 2.0) * TILE, (y + 1) * TILE)
				var sprite := _module(entities, id, foot, piece.y * TILE, "Face%03d" % faces)
				sprite.flip_h = _wall_rng.randf() < 0.5
				faces += 1
		for run: Vector2i in _row_runs(y, _is_cap):
			for piece: Vector2i in _pieces(run):
				var cap_height := _texture_height(WALL_CAP)
				var foot := Vector2((piece.x + piece.y / 2.0) * TILE, y * TILE + cap_height)
				var sprite := _module(decals, WALL_CAP, foot, piece.y * TILE, "Lip%03d" % caps)
				sprite.flip_h = _wall_rng.randf() < 0.5
				caps += 1
	var sides := 0
	for x: int in SIZE.x:
		for run: Vector2i in _column_runs(x, _is_side):
			for y: int in range(run.x, run.y + 1):
				var part := SIDE_MIDDLE
				if y == run.y:
					part = SIDE_BOTTOM
				elif y == run.x:
					part = SIDE_TOP
				_side_strip(entities, Vector2i(x, y), part, "Side%03d" % sides)
				sides += 1
	return Vector3i(faces, sides, caps)


func _module(parent: Node, id: String, foot: Vector2, width: int, node_name: String) -> Sprite2D:
	var sprite: Sprite2D = _kit.call(&"add_sprite", parent, id, foot, node_name)
	var size := sprite.texture.get_size()
	var w := minf(float(width), size.x)
	if w < size.x:
		sprite.region_enabled = true
		sprite.region_rect = Rect2((size.x - w) / 2.0, 0.0, w, size.y)
		sprite.offset = Vector2(-w / 2.0, -size.y)
	var value := 1.0 + _wall_rng.randf_range(-WALL_VALUE_JITTER, WALL_VALUE_JITTER)
	sprite.modulate = Color(value, value, value)
	return sprite


func _side_strip(parent: Node, cell: Vector2i, part: int, node_name: String) -> void:
	var floor_east := not _is_wall(cell + Vector2i.RIGHT)
	var centre_x := (cell.x + 1) * TILE - SIDE_WIDTH / 2.0 if floor_east \
		else cell.x * TILE + SIDE_WIDTH / 2.0
	var foot := Vector2(centre_x, (cell.y + 1) * TILE)
	var sprite: Sprite2D = _kit.call(&"add_sprite", parent, WALL_SIDE, foot, node_name)
	var size := sprite.texture.get_size()
	var y0 := 0.0
	if part == SIDE_MIDDLE:
		y0 = floorf((size.y - TILE) / 2.0)
	elif part == SIDE_BOTTOM:
		y0 = size.y - TILE
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0.0, y0, size.x, TILE)
	sprite.offset = Vector2(-size.x / 2.0, -TILE)
	var value := 1.0 + _wall_rng.randf_range(-WALL_VALUE_JITTER, WALL_VALUE_JITTER)
	sprite.modulate = Color(value, value, value)


func _texture_height(id: String) -> float:
	var scene: PackedScene = _kit.call(&"scene", id)
	var model := scene.instantiate()
	var height := float((model.get_node(^"Sprite") as Sprite2D).texture.get_height())
	model.free()
	return height


func _row_runs(y: int, test: Callable) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var start := -1
	for x: int in SIZE.x + 1:
		var inside := x < SIZE.x and bool(test.call(Vector2i(x, y)))
		if inside and start < 0:
			start = x
		elif not inside and start >= 0:
			runs.append(Vector2i(start, x - 1))
			start = -1
	return runs


func _column_runs(x: int, test: Callable) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var start := -1
	for y: int in SIZE.y + 1:
		var inside := y < SIZE.y and bool(test.call(Vector2i(x, y)))
		if inside and start < 0:
			start = y
		elif not inside and start >= 0:
			runs.append(Vector2i(start, y - 1))
			start = -1
	return runs


func _pieces(run: Vector2i) -> Array[Vector2i]:
	var pieces: Array[Vector2i] = []
	var length := run.y - run.x + 1
	if length < WALL_SPAN:
		pieces.append(Vector2i(run.x, length))
		return pieces
	var left := run.x
	while left + WALL_SPAN <= run.y + 1:
		pieces.append(Vector2i(left, WALL_SPAN))
		left += WALL_SPAN
	if left <= run.y:
		pieces.append(Vector2i(run.y + 1 - WALL_SPAN, WALL_SPAN))
	return pieces


# --- Repères, zone purifiée, escaliers ----------------------------------------------------


## Stèles `S` (props pleins, un halo `candle` chacun, qui éclaire aussi le voile) et tombes `T` (stèle réduite et sombre). Les cases sont solides dans la grille.
func _place_landmarks() -> void:
	var entities: Node2D = _kit.get(&"entities")
	var rules: GDScript = _kit.get(&"rules")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", STELE_MARK):
		_kit.call(&"add_prop_at", entities, STELE_PROP, cell, "Stele%02d" % index)
		_kit.call(&"add_glow", &"candle", _kit.call(&"cell_center", cell)
			+ Vector2(0.0, STELE_LIGHT_HEIGHT - TILE / 2.0), "CandleGlow%02d" % index)
		index += 1
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", TOMB_MARK):
		var sprite: Sprite2D = _kit.call(&"add_sprite", entities, STELE_PROP,
			rules.call(&"foot_position", StringName(STELE_PROP), cell), "Tomb%02d" % index)
		# Réduite autour du pied : position inchangée, image plus basse.
		sprite.scale = Vector2.ONE * TOMB_SCALE
		sprite.modulate = TOMB_TINT
		sprite.flip_h = _wall_rng.randf() < 0.5
		index += 1


## Dalle claire des cases `Z` (5F) : un aplat au sol, halo « purified » (fixe).
func _place_zone() -> void:
	var cells: Array[Vector2i] = _plan().call(&"cells_of", ZONE_MARK)
	if cells.is_empty():
		return
	var rect := Rect2i(cells[0], Vector2i.ONE)
	for cell: Vector2i in cells:
		rect = rect.expand(cell).expand(cell + Vector2i.ONE)
	var slab := Polygon2D.new()
	slab.name = "PurifiedSlab"
	slab.color = ZONE_COLOR
	var origin := Vector2(rect.position * TILE)
	var extent := Vector2(rect.size * TILE)
	slab.polygon = PackedVector2Array([origin, origin + Vector2(extent.x, 0.0), origin + extent,
		origin + Vector2(0.0, extent.y)])
	_kit.call(&"attach", _kit.get(&"decals"), slab)
	_kit.call(&"add_glow", &"purified", origin + extent / 2.0, "PurifiedGlow")


## Objet caché (T18, 5F, §2.9) : l'« offrande fanée » en (4, 11) (position `cache` de la grille,
## qui fait foi sur le dossier §4.2). La case est praticable dans la grille : le repère (stèle
## réduite et pâle, empreinte d'une case) la rend solide ; le point d'examen part du voisin
## praticable (4, 10), `unless_flags = [got_<id>]` (modèle `_add_hidden_item` du J13).
func _place_hidden_item() -> void:
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] != "cache":
			continue
		var clue: Vector2i = _plan().call(&"cell_of", id)
		var offering: Node2D = _kit.call(&"add_prop_at", _kit.get(&"entities"), STELE_PROP, clue,
			"Offering_%s" % id)
		offering.scale = Vector2.ONE * OFFERING_SCALE
		offering.modulate = OFFERING_TINT
		offering.set(&"footprint", [Vector2i.ZERO] as Array[Vector2i])
		_kit.call(&"add_interactable", "Hidden_%s" % id, clue, Vector2i.ONE, Vector2i.ZERO,
			StringName(id))
		var point: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
		var unless: Array[StringName] = [StringName("got_" + id)]
		point.set(&"unless_flags", unless)


## Escalier d'une case : image du souterrain ramenée à la largeur d'une case, au sol.
func _place_stairs() -> void:
	var decals: Node2D = _kit.get(&"decals")
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] != "escalier":
			continue
		var cell: Vector2i = _plan().call(&"cell_of", id)
		var up: bool = _plan().call(&"attr", id, "sens") == "monte"
		var stairs: Node2D = _kit.call(&"add_prop", decals, STAIRS_UP if up else STAIRS_DOWN,
			_kit.call(&"world", cell), "Stairs%s" % String(_plan().call(&"attr", id, "paire")))
		stairs.set(&"footprint", [] as Array[Vector2i])
		stairs.scale = Vector2.ONE * STAIRS_SCALE
		_kit.call(&"add_shade_source", &"stairs", _kit.call(&"cell_center", cell))


# --- Points d'apparition et passages -------------------------------------------------------


func _facing_of(grid: Object, id: String) -> Vector2i:
	match String(grid.call(&"attr", id, "facing")):
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
		"up":
			return Vector2i.UP
		_:
			return Vector2i.DOWN


## Plan de l'étage dont la carte est [param map_id] (null si ce n'est pas un de nos étages).
func _plan_of(map_id: StringName) -> Object:
	for key: String in FLOORS:
		if FLOORS[key][0] == map_id:
			var other: Object = PlanGrid.new()
			if other.call(&"load_file", PLAN_PATH % key):
				return other
	return null


func _place_spawns_and_warps() -> void:
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] == "spawn":
			_kit.call(&"add_spawn", id, _plan().call(&"cell_of", id))
	if QA_SPAWNS.has(_key):
		_kit.call(&"add_spawn", QA_SPAWNS[_key][0], QA_SPAWNS[_key][1])
	for id: String in positions:
		if positions[id]["kind"] != "escalier":
			continue
		var cell: Vector2i = _plan().call(&"cell_of", id)
		var pair: String = _plan().call(&"attr", id, "paire")
		var node_name := "Stairs%sWarp" % pair
		var target := StringName(_plan().call(&"attr", id, "vers"))
		if target == GROUND_FLOOR_MAP:
			_kit.call(&"add_warp", node_name, cell, Kit.STEP_ON, Vector2i.ZERO, target,
				GROUND_FLOOR_SPAWN, Vector2i.DOWN)
			continue
		var other := _plan_of(target)
		if SOON_PAIRS.has(pair) or other == null:
			# Repli : étage absent (7F hors J19) ; retour sur l'arrivée d'ici.
			var back := _local_arrival()
			_kit.call(&"add_warp", node_name, cell, Kit.STEP_ON, Vector2i.ZERO, &"",
				StringName(back), _facing_of(_plan(), back), COMING_SOON)
			print("%s : escalier %s → « %s — À venir » (repli)" % [FLOORS[_key][0], id,
				COMING_SOON])
			continue
		var spawn_id := _spawn_of_pair(other, pair)
		if spawn_id.is_empty():
			_fail("escalier %s : aucun point d'apparition de paire %s dans %s" % [id, pair,
				target])
			continue
		_kit.call(&"add_warp", node_name, cell, Kit.STEP_ON, Vector2i.ZERO, target,
			StringName(spawn_id), _facing_of(other, spawn_id))


func _spawn_of_pair(grid: Object, pair: String) -> String:
	var positions: Dictionary = grid.get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] == "spawn" and grid.call(&"attr", id, "paire") == pair:
			return id
	return ""


## Un point d'apparition d'ici (le premier de la grille) pour le retour d'un repli.
func _local_arrival() -> String:
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] == "spawn":
			return id
	return ""


# --- Déclencheurs ----------------------------------------------------------------------------


func _place_triggers() -> void:
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] != "declencheur":
			continue
		var role: String = _plan().call(&"attr", id, "role")
		if not TRIGGER_SCENES.has(role):
			_fail("déclencheur %s : rôle « %s » inconnu" % [id, role])
			continue
		var index := 0
		for cell: Vector2i in _plan().call(&"cells_at", id):
			_kit.call(&"add_trigger", "%s_%d" % [id, index], cell, Vector2i.ONE, Vector2i.ZERO,
				TRIGGER_SCENES[role])
			index += 1
	# Zone purifiée (§2.8) : une case `Z` déclenche seulement quand un pas **y entre** de
	# l'extérieur ; un déclencheur par case et par direction dont la case précédente est une
	# case praticable hors de la zone.
	for cell: Vector2i in _plan().call(&"cells_of", ZONE_MARK):
		for step: Vector2i in STEPS:
			var before := cell - step
			if not _kit.call(&"is_walkable", before) or _plan().call(&"at", before) == ZONE_MARK:
				continue
			_kit.call(&"add_trigger", "Zone_%d_%d_%s" % [cell.x, cell.y, _step_name(step)], cell,
				Vector2i.ONE, step, ZONE_SCENE)


func _step_name(step: Vector2i) -> String:
	match step:
		Vector2i.RIGHT:
			return "right"
		Vector2i.LEFT:
			return "left"
		Vector2i.UP:
			return "up"
	return "down"
