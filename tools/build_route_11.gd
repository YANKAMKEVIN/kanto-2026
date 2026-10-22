extends SceneTree
## Construit game/world/maps/route_11.tscn (Route 11, 76 × 36 cases) d'après la grille
## fonctionnelle `tools/plans/route_11.txt` (jalon 17 T16, docs/tech/jalon-17.md §2.1 ;
## dossier 20 §3.2, §6, §7).
##
##   godot --headless --path . -s res://tools/build_route_11.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** (géométrie, positions, passages) ; la vue générale peinte validée
## (`docs/design/reference/route-11-vue-generale-v1.png`) donne la DA. Écarts de la vue **non
## reproduits** (dossier 20, « Vues générales ») : le goulet d'Arthur est **resserré** (deux cases
## entre des affleurements, lisibles) ; Gamin Louis est sur le parcours nord (31, 7), pas près de
## la Cave ; feuillage serré et net (forêt serrée du kit, jamais granuleux).
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` `Q` chemin, `o` sol rocheux praticable
##   (herbe garnie de cailloux), `q` digue (pavés), `h` hautes herbes ; `W` mer (solide,
##   `GridWorld.is_water`) ; tout le reste (forêt, talus, affleurements, buissons, clôtures) est
##   solide. La grille garde `W` : l'outil la lit comme `w` (mer du kit côtier) en mémoire.
## - Image : sol peint (masque G = chemin ; R = digue `ground_digue_01` à 1:1, rangée sous la digue
##   comprise ; mer de Bourg Palette à angles droits), forêt serrée, talus de la Cave en paroi de
##   la série 12 avec la bouche `relief_bouche_talus_01`, affleurements (blocs de rivage, gros
##   piliers en paroi), rivage rocheux sous la digue remplacé par les bords `relief_digue_bord_*`,
##   clôtures de bois, buissons, hautes herbes, rochers dans l'eau, panneaux.
## - Passages : raccord ouest (0, 11..13) PUSH ← → `vermilion_city` / `from_route_11_n|c|s` ;
##   bouche de la Cave (15..16, 7) STEP_ON ↑ → `digletts_cave` / `from_route_11_w|e` (T15).
##   Spawns `from_vermilion_n|c|s` et `from_cave_w|e`. Bord est (75, 14..15) : PUSH → « ROUTE 12 —
##   À venir » (`coming_soon`, build de développement), retour `from_route_12_n|s` (74, 14..15)
##   tourné ← (J21 T9a ; T21 en fera le warp réel → `route_12` / `from_route_11`).
## - Ronflex : retiré (J21 T9a, décision M-3 de Kevin du 2026-10-16, dossier 24 §10.3). Il dort
##   désormais au croisement de la Route 12 ; le dialogue `route_11_snorlax` (T-6, T-7) reste dans
##   les données, repris par le Ronflex de la Route 12.

const Kit := preload("res://tools/coast_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_11.txt"
const OUT_PATH: String = "res://game/world/maps/route_11.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_11_ground.png"
const NPCS_PATH: String = "res://data/npcs/route_11.json"
const DIGUE_TEXTURE: String = "res://assets/world/ground/ground_digue_01.png"
const SIZE := Vector2i(76, 36)
const SEED: int = 1101
const DECOR_SEED: int = 1102
const FOREST_SEED: int = 11
const PAROI_SEED: int = 1103
const SHORE_SEED: int = 1104

const MAP_ID: StringName = &"route_11"
const DISPLAY_NAME: String = "Route 11"
const REGION: String = "Carmin-sur-Mer — Route 12"
const WALKABLE: String = ".=hoqQ"

## Raccord ouest : [nœud, case, spawn de Carmin, spawn d'ici].
const WEST_EXITS: Array = [
	["VermilionN", Vector2i(0, 11), &"from_route_11_n", "from_vermilion_n"],
	["VermilionC", Vector2i(0, 12), &"from_route_11_c", "from_vermilion_c"],
	["VermilionS", Vector2i(0, 13), &"from_route_11_s", "from_vermilion_s"],
]
const WEST_MAP: StringName = &"vermilion_city"
## Bord est (J21 T9a, M-3) : [nœud, case, spawn de retour (tourné ←)]. « ROUTE 12 — À venir ».
const EAST_EXITS: Array = [
	["Route12N", Vector2i(75, 14), "from_route_12_n"],
	["Route12S", Vector2i(75, 15), "from_route_12_s"],
]
const EAST_MAP: StringName = &"route_12"
## Bouche de la Cave (STEP_ON ↑) : [nœud, case, spawn de la Cave, spawn d'ici (devant, tourné ↓)].
const MOUTH: Array = [
	["CaveW", Vector2i(15, 7), &"from_route_11_w", "from_cave_w"],
	["CaveE", Vector2i(16, 7), &"from_route_11_e", "from_cave_e"],
]
const CAVE_MAP: StringName = &"digletts_cave"
const MOUTH_ANCHOR := Vector2i(16, 7)
const MOUTH_ID: String = "relief_bouche_talus_01"

const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
const BALL_KINDS: Array[String] = ["objet_visible", "cache"]
## Panneaux : [position, nœud du décor, dialogue]. Lus depuis la case au sud, tournés vers le nord.
const SIGNS: Array = [
	["panneau_ouest", "SignWest", &"route_11_sign"],
	["panneau_cave", "SignCave", &"route_11_cave_sign"],
]

## Digue (rangées 22..23, x 30..59) : le bord sud est posé sur la rangée 24, sauf la case 47 (poche
## du rivage, praticable).
const DIKE_X: Vector2i = Vector2i(30, 59)
const DIKE_EDGE_ROW: int = 24
const DIKE_GAP_X: int = 47
const DIKE_EDGE_IDS: Array[String] = ["relief_digue_bord_01", "relief_digue_bord_02"]
const DIKE_EDGE_HEIGHT: float = 87.0
## Clôtures (rangée 21, x 32..57) : modules de 4 cases (le dernier recouvre le précédent).
const FENCE_ROW: int = 21
const FENCE_X: Vector2i = Vector2i(32, 57)
const FENCE_ID: String = "prop_cloture_01"

const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
const SEA_ROCK_ID: String = "prop_rocher_mer_01"
## Rochers dans l'eau (ancre = case de droite du rocher de 2 cases), posés à la main.
const SEA_ROCKS: Array[Vector2i] = [
	Vector2i(12, 27), Vector2i(26, 26), Vector2i(41, 28), Vector2i(53, 26), Vector2i(66, 28),
	Vector2i(8, 30), Vector2i(33, 31), Vector2i(58, 32), Vector2i(21, 33), Vector2i(70, 25),
]
const PEBBLES_ID: String = "prop_pierres_01"
const HIDDEN_ITEM: String = "route_11_hidden_1"
const HIDDEN_CLUE_ID: String = "prop_indice_caillou_01"

## Forêt « plus sèche » (même valeurs que les routes voisines).
const SHADE_VALUE: float = 0.95
const SHADE_RED: float = 1.02
const SHADE_BLUE: float = 1.0
## Prairie : touffes et fleurs (la vue en est semée, plus qu'ailleurs).
const MEADOW_ATTEMPTS: int = 1900
const FLOWER_CHANCE: float = 0.45
const FLOWERS: Array[int] = [1, 2, 3, 5, 6]

var _kit: Object
var _boulder_cells: Array[Vector2i] = []


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED, SHORE_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_11 : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_sea_as_w()
	_kit.call(&"set_marks", WALKABLE, "K", "")
	_reserve_positions()
	_kit.call(&"make_root", "Route11", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour", NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	_make_pillars()
	_pave_under_dike()
	if not _kit.call(&"add_ground", MASK_PATH, _kit.call(&"forest_undergrowth")):
		print("build_route_11 : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var ground: Node = _kit.get(&"root").get_node(^"PaintedGround")
	ground.set(&"r_texture", load(DIGUE_TEXTURE))
	(ground.get(&"material") as ShaderMaterial).set_shader_parameter(&"paving_scale", 1.0)
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_add_examine_points()

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, FLOWER_CHANCE, FLOWERS)
	var modules: int = _kit.call(&"place_paroi", PAROI_SEED)
	var shore: int = _kit.call(&"place_shore")
	_place_dike_edges(decals)
	_place_pebbles(decals)
	_place_boulders(entities)
	_kit.call(&"add_prop_at", entities, MOUTH_ID, MOUTH_ANCHOR, "CaveMouth")
	for entry: Array in SIGNS:
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell(entry[0]), entry[1])
	_kit.call(&"add_prop_at", decals, HIDDEN_CLUE_ID, _cell(HIDDEN_ITEM), "StoneClue")
	_place_fences(entities)
	_place_bushes(entities)
	_place_sea_rocks(entities)
	_kit.call(&"place_tall_grass")
	var feet: Array[Vector2] = []
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, {})

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_11 :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	_batch_decals(decals)
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_11 : %s (%d entités, %d au sol dont %d modules de paroi et %d de rivage, "
		% [error_string(result.x), counts.x, counts.y, modules, shore]
		+ "forêt %d → %d, %d nœuds)" % [forest.x, forest.y, result.y])
	quit(0 if result.x == OK else 1)


## Perf (jalon 17, S21 : 275 appels de dessin à 53 fps) : les 750 décalcomanies (terre, pavés,
## touffes, fleurs) sont tirées dans le désordre, et un appel de dessin part à chaque changement
## de texture (196 appels). Elles sont au sol, hors tri en profondeur : on les range par texture
## (terre, pavés, touffes, fleurs au-dessus), ce qui les groupe en une vingtaine d'appels.
const DECAL_ORDER: Array[String] = ["terre", "pave", "touffe", "fleur"]


func _batch_decals(decals: Node2D) -> void:
	var plain: Array[Sprite2D] = []
	for child: Node in decals.get_children():
		var sprite := child as Sprite2D
		if sprite == null or sprite.material != null or sprite.texture == null:
			break
		plain.append(sprite)
	plain.sort_custom(func(a: Sprite2D, b: Sprite2D) -> bool:
		var ka := _decal_rank(a.texture.resource_path)
		var kb := _decal_rank(b.texture.resource_path)
		if ka != kb:
			return ka < kb
		return a.texture.resource_path < b.texture.resource_path)
	for i in plain.size():
		decals.move_child(plain[i], i)


func _decal_rank(path: String) -> int:
	for i in DECAL_ORDER.size():
		if path.contains("decal_" + DECAL_ORDER[i]):
			return i
	return DECAL_ORDER.size()


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


## La grille note la mer `W` ; le kit côtier lit `w` : réécriture en mémoire seulement (le fichier
## de la grille, source unique de la géométrie, n'est pas modifié).
func _sea_as_w() -> void:
	var rows: PackedStringArray = _plan().get(&"rows")
	for i: int in rows.size():
		rows[i] = rows[i].replace("W", "w")
	_plan().set(&"rows", rows)


## Cases des PNJ, Pokémon et objets de la grille : réservées (la forêt s'en écarte).
func _reserve_positions() -> void:
	var cells: Array[Vector2i] = []
	var balls: Array[Vector2i] = []
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		var kind: String = positions[id]["kind"]
		if RESERVED_KINDS.has(kind):
			cells.append_array(positions[id]["cells"])
		if BALL_KINDS.has(kind):
			balls.append_array(positions[id]["cells"])
	_kit.set(&"reserved_cells", cells)
	_kit.set(&"reserved_balls", balls)


## Gros affleurements loin de l'eau (≥ 12 cases) : paroi de la série 12, comme le talus `K`.
func _make_pillars() -> void:
	_kit.call(&"classify_rocks")
	var cliffs: Dictionary = _kit.get(&"cliff_cells")
	var pillars: Dictionary = _kit.get(&"pillar_cells")
	for component: Array in _kit.call(&"pillar_components"):
		# Un module de paroi dépasse d'une rangée au-dessus de son pied : la rangée du haut d'un
		# gros pilier dont le voisin du nord est praticable (goulets) reste sans module, sinon
		# le sommet de la roche recouvrirait le chemin (goulet de l'est, Arthur).
		var top := 1 << 20
		for cell: Vector2i in component:
			top = mini(top, cell.y)
		var height := 0
		for cell: Vector2i in component:
			height = maxi(height, cell.y - top + 1)
		for cell: Vector2i in component:
			var bare: bool = height >= 3 and cell.y == top and is_walkable_cell(cell + Vector2i.UP)
			if not bare:
				cliffs[cell] = true
			pillars[cell] = true
	# Petits affleurements loin de l'eau (goulet d'Arthur) : des rochers posés à la main, pas de
	# blocs de rivage (ils se lisaient comme des parcelles labourées) ; aucun module de rivage.
	var roles: Dictionary = _kit.get(&"rock_roles")
	for cell: Vector2i in roles:
		if roles[cell] == &"far" and not pillars.has(cell):
			_boulder_cells.append(cell)
			pillars[cell] = true


func is_walkable_cell(cell: Vector2i) -> bool:
	return _kit.call(&"is_walkable", cell)


## Le sol peint sous le bord de la digue (rangée 24) est de la pierre : aucune bande d'herbe entre
## la dalle et la face du mur.
func _pave_under_dike() -> void:
	var paved: Dictionary = _kit.get(&"paved_cells")
	for x: int in range(DIKE_X.x, DIKE_X.y + 1):
		if x != DIKE_GAP_X:
			paved[Vector2i(x, DIKE_EDGE_ROW)] = true
	# La poche du rivage (47, 24..25) est un petit débarcadère de la même pierre.
	for row: int in [DIKE_EDGE_ROW, DIKE_EDGE_ROW + 1]:
		paved[Vector2i(DIKE_GAP_X, row)] = true


func _add_passages() -> void:
	for entry: Array in WEST_EXITS:
		_kit.call(&"add_spawn", entry[3], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.LEFT, WEST_MAP,
			entry[2], Vector2i.LEFT)
	for entry: Array in MOUTH:
		_kit.call(&"add_spawn", entry[3], (entry[1] as Vector2i) + Vector2i.DOWN)
		_kit.call(&"add_warp", entry[0], entry[1], Kit.STEP_ON, Vector2i.UP, CAVE_MAP,
			entry[2], Vector2i.UP)
	# Jalon 21 (T21) : bord est → `route_12` / `from_route_11_n|s` (retours `from_route_12_n|s` gardés).
	for entry: Array in EAST_EXITS:
		_kit.call(&"add_spawn", entry[2], (entry[1] as Vector2i) + Vector2i.LEFT)
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.RIGHT, EAST_MAP,
			StringName("from_route_11_" + String(entry[2]).right(1)), Vector2i.RIGHT)


## Points d'examen : panneaux (lus de face depuis le sud, tournés ↑) et pierre-indice (de tous
## côtés, à condition d'être tourné vers elle) ; le point de la pierre disparaît une fois la
## Poké Ball prise (mécanisme des objets cachés du J12).
func _add_examine_points() -> void:
	for entry: Array in SIGNS:
		_kit.call(&"add_interactable", String(entry[1]) + "Point", _cell(entry[0]), Vector2i.ONE,
			Vector2i.UP, entry[2])
	_kit.call(&"add_interactable", "StonePoint", _cell(HIDDEN_ITEM), Vector2i.ONE,
		Vector2i.ZERO, StringName(HIDDEN_ITEM))
	var point: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
	var unless: Array[StringName] = [StringName("got_" + HIDDEN_ITEM)]
	point.set(&"unless_flags", unless)


# --- Décor --------------------------------------------------------------------------------


## Bord sud de la digue : modules de 2 cases posés sur la rangée 24 (sous la dalle), de part et
## d'autre de la poche du rivage ; le rivage rocheux posé par le kit y est retiré.
func _place_dike_edges(decals: Node2D) -> void:
	var pieces: Array = _kit.get(&"shore_pieces")
	var kept: Array[Dictionary] = []
	for piece: Dictionary in pieces:
		var rect: Rect2 = piece["rect"]
		var first := int(rect.position.x / Kit.TILE)
		var last := int((rect.end.x - 1.0) / Kit.TILE)
		var row := int((rect.end.y - 1.0) / Kit.TILE)
		if row == DIKE_EDGE_ROW and first >= DIKE_X.x and last <= DIKE_X.y \
				and not (first <= DIKE_GAP_X and DIKE_GAP_X <= last):
			(piece["node"] as Node).free()
		else:
			kept.append(piece)
	pieces.assign(kept)
	var spans: Array[Vector2i] = []
	for run: Vector2i in [Vector2i(DIKE_X.x, DIKE_GAP_X - 1), Vector2i(DIKE_GAP_X + 1, DIKE_X.y)]:
		var at := run.x
		while at <= run.y:
			var left := at if at + 1 <= run.y else at - 1
			spans.append(Vector2i(left, left + 1))
			at += 2
	var index := 0
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	for span: Vector2i in spans:
		var id := DIKE_EDGE_IDS[index % DIKE_EDGE_IDS.size()]
		var foot := Vector2(float((span.y) * Kit.TILE), float((DIKE_EDGE_ROW + 1) * Kit.TILE))
		var prop: Node2D = _kit.call(&"add_prop", decals, id, foot, "DikeEdge%02d" % index)
		_kit.call(&"flip", prop, decor.randf() < 0.5)
		index += 1


## Clôtures de bois le long de la digue : modules de 4 cases bout à bout.
func _place_fences(entities: Node2D) -> void:
	var at := FENCE_X.x
	var index := 0
	while at <= FENCE_X.y:
		var left := at if at + 3 <= FENCE_X.y else FENCE_X.y - 3
		_kit.call(&"add_prop_at", entities, FENCE_ID, Vector2i(left + 2, FENCE_ROW),
			"Fence%02d" % index)
		index += 1
		at += 4


## Cailloux sur le sol rocheux praticable `o` (hors cases réservées).
func _place_pebbles(decals: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var reserved: Array = _kit.get(&"reserved_cells")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "o"):
		if reserved.has(cell) or decor.randf() < 0.3:
			continue
		var p := Vector2(cell) + Vector2(decor.randf_range(0.25, 0.75),
			decor.randf_range(0.5, 0.95))
		var pebbles: Sprite2D = _kit.call(&"add_sprite", decals, PEBBLES_ID, p * Kit.TILE,
			"Pebbles%02d" % index)
		pebbles.scale = Vector2.ONE * decor.randf_range(0.6, 0.9)
		pebbles.flip_h = decor.randf() < 0.5
		index += 1


## Un buisson par case `x` : les trois images mélangées, jamais la même que la voisine.
func _place_bushes(entities: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var tint: Color = _kit.call(&"forest_tint")
	var chosen: Dictionary = {}
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "x"):
		var options: Array[String] = []
		for id: String in BUSH_IDS:
			if chosen.get(cell + Vector2i.LEFT, "") != id \
					and chosen.get(cell + Vector2i.UP, "") != id:
				options.append(id)
		var id := options[decor.randi_range(0, options.size() - 1)]
		chosen[cell] = id
		var bush: Node2D = _kit.call(&"add_prop_at", entities, id, cell, "Bush%02d" % index)
		index += 1
		_kit.call(&"flip", bush, decor.randf() < 0.5)
		var scale := decor.randf_range(0.95, 1.1)
		bush.scale = Vector2(scale, scale)
		var value := decor.randf_range(0.92, 1.05)
		bush.modulate = Color(value, value, value) * tint


## Rochers dans l'eau (accents, solides comme l'eau qu'ils occupent).
func _place_sea_rocks(entities: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var index := 0
	for cell: Vector2i in SEA_ROCKS:
		var rock: Node2D = _kit.call(&"add_prop_at", entities, SEA_ROCK_ID, cell,
			"SeaRock%02d" % index)
		index += 1
		_kit.call(&"flip", rock, decor.randf() < 0.5)
		var scale := decor.randf_range(0.85, 1.05)
		rock.scale = Vector2(scale, scale)


## Rochers (2 × 1 cases) sur les petits affleurements : du bas vers le haut (tri par les pieds).
func _place_boulders(entities: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var free: Dictionary = {}
	for cell: Vector2i in _boulder_cells:
		free[cell] = true
	var order := _boulder_cells.duplicate()
	order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y > b.y or (a.y == b.y and a.x < b.x))
	var index := 0
	for cell: Vector2i in order:
		if not free.has(cell):
			continue
		var id := "prop_rocher_01"
		var rock: Node2D
		if free.has(cell + Vector2i.RIGHT):
			rock = _kit.call(&"add_prop_at", entities, id, cell + Vector2i.RIGHT,
				"Boulder%02d" % index)
			free.erase(cell + Vector2i.RIGHT)
		else:
			var foot := Vector2(cell.x + 0.5, cell.y + 0.95) * Kit.TILE
			rock = _kit.call(&"add_prop", entities, id, foot, "Boulder%02d" % index)
			_kit.call(&"clear_footprint", rock)
			rock.scale = Vector2.ONE * 0.62
		free.erase(cell)
		index += 1
		_kit.call(&"flip", rock, decor.randf() < 0.5)
		var value := decor.randf_range(0.9, 1.0)
		rock.modulate = Color(value, value, value)
