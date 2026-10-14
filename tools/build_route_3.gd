extends SceneTree
## Construit game/world/maps/route_3.tscn (Route 3, 82 × 38 cases) d'après la grille
## fonctionnelle `tools/plans/route_3.txt` (jalon 12 T8, docs/tech/jalon-12.md §2.1 ; dossier 15
## §3, §4, §7).
##
##   godot --headless --path . -s res://tools/build_route_3.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** (géométrie, positions, passages) ; la vue générale peinte validée
## (`docs/design/reference/route-3-vue-generale-v1.png`) donne la DA. Écarts de la vue **non
## reproduits** (dossier 15, « Vues générales peintes v1 et grilles ») : la montagne passe à
## l'**ardoise et au gris bleuté** vers l'est (la vue la garde beige chaud) ; la Fillette garde le
## goulet de la jonction (T18), pas le plateau du Centre ; aucun sapin isolé sur le plateau.
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` `D` `Q` chemin, `o` sol rocheux,
##   `h` hautes herbes, `v` rebord (sauté vers le sud) ; tout le reste (forêt, paroi, rochers,
##   buissons, Centre) est solide.
## - Image : sol peint (masque R = sol rocheux `ground_roche_01`, valeurs variées pour casser la
##   répétition et laisser percer l'herbe ; G = chemins), sous-bois sur la forêt et sous la paroi
##   de l'ouest, forêt serrée de plus en plus sèche vers l'est ; paroi en modules : série 12
##   (beige) à l'ouest, **ardoise** (série 14) à partir de [constant SLATE_FROM_X], de plus en
##   plus froide vers l'est ; les deux grands affleurements `R` collés à la montagne sont de la
##   paroi, les petits des rochers (grande pierre, rochers) assombris et bleutés vers l'est ;
##   buissons, rebords, touffes de hautes herbes, Centre Pokémon (`bldg_centre_01`), entrée du
##   Mont Sélénite (`relief_entree_grotte_01`), panneaux et leurs points d'examen (T18),
##   touffes et fleurs de plus en plus rares vers l'est, cailloux et touffes sèches sur la roche.
## - Passages : trois warps PUSH ← vers Argenta (0, 25..27) ; porte du Centre (61..62, 11)
##   STEP_ON ↑ → `mt_moon_center` ; entrée de la grotte (73..74, 9) STEP_ON ↑ → `mt_moon_1f` /
##   `from_route_3_w|e` (carte du T9, construite en parallèle). Spawns `from_pewter_n|c|s`,
##   `from_center_w|e`, `from_mt_moon_w|e` (sortie de la grotte et Corde Sortie).
## - Les cases des Dresseurs, PNJ, Pokémon d'ambiance, objets et de l'objet caché sont
##   **réservées** (la forêt s'en écarte comme pour un PNJ). Les PNJ viennent de
##   `data/npcs/route_3.json` (T18), lu par la carte au chargement.
## - Vie (T18, jalon-12.md §1.3, §2.8) : points d'examen des deux panneaux (lus de face, ↑) ;
##   **objet caché** : indice `prop_indice_caillou_01` sur la case de la position `cache` (bloquée,
##   couche du sol) et point d'examen de tous côtés, `unless_flags = [got_<id>]` ; déclencheur
##   `route_3_entered` sur (1, 25..27), toute direction.

const Kit := preload("res://tools/pewter_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_3.txt"
const OUT_PATH: String = "res://game/world/maps/route_3.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_3_ground.png"
const NPCS_PATH: String = "res://data/npcs/route_3.json"
const ROCK_TEXTURE: String = "res://assets/world/ground/ground_roche_01.png"
const SIZE := Vector2i(82, 38)
const SEED: int = 2301
const DECOR_SEED: int = 2302
const FOREST_SEED: int = 31
const PAROI_SEED: int = 2303

const MAP_ID: StringName = &"route_3"
const DISPLAY_NAME: String = "Route 3"
const REGION: String = "Argenta — Mont Sélénite"
const WALKABLE: String = ".=hvoDQ"

## Raccord ouest (jalon-12 §2.1) : [nœud, case, spawn d'Argenta, spawn d'ici].
const WEST_EXITS: Array = [
	["PewterN", Vector2i(0, 25), &"from_route_3_n", "from_pewter_n"],
	["PewterC", Vector2i(0, 26), &"from_route_3_c", "from_pewter_c"],
	["PewterS", Vector2i(0, 27), &"from_route_3_s", "from_pewter_s"],
]
## Porte du Centre (STEP_ON ↑) et entrée de la grotte (STEP_ON ↑) : [nœud, case, carte, spawn
## d'arrivée, orientation à l'arrivée, spawn d'ici (devant, tourné ↓)].
const DOORS: Array = [
	["DoorCenterW", Vector2i(61, 11), &"mt_moon_center", &"entrance", Vector2i.ZERO,
		"from_center_w"],
	["DoorCenterE", Vector2i(62, 11), &"mt_moon_center", &"entrance", Vector2i.ZERO,
		"from_center_e"],
	["MtMoonW", Vector2i(73, 9), &"mt_moon_1f", &"from_route_3_w", Vector2i.UP, "from_mt_moon_w"],
	["MtMoonE", Vector2i(74, 9), &"mt_moon_1f", &"from_route_3_e", Vector2i.UP, "from_mt_moon_e"],
]
const CENTER_ANCHOR := Vector2i(62, 11)
const CAVE_ANCHOR := Vector2i(74, 9)
## Types de positions de la grille dont la case est réservée (PNJ et objets du T18).
const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
const BALL_KINDS: Array[String] = ["objet_visible", "cache"]
## Panneaux : [position de la grille, nœud, dialogue, orientation exigée] (dossier 15 §20 n° 3,
## 4 ; lus depuis la case au sud, tourné ↑).
const SIGNS: Array = [
	["panneau_ouest", "SignWest", &"route_3_sign_west", Vector2i.UP],
	["panneau_centre", "SignCenter", &"route_3_sign_center", Vector2i.UP],
]
## Objets cachés : [position `cache` de la grille, nœud de l'indice, objet peint de l'indice].
const HIDDEN: Array = [["route_3_hidden_1", "HiddenClue1", "prop_indice_caillou_01"]]
## Déclencheur silencieux de la première entrée (jalon-12.md §1.3 n° 5) : colonne 1, rangées
## 25..27, toute direction.
const ENTERED_ANCHOR := Vector2i(1, 27)
const ENTERED_SIZE := Vector2i(1, 3)
const ENTERED_CUTSCENE: StringName = &"route_3_entered"

## Paroi : série 12 (beige) à l'ouest, ardoise (série 14) à partir de cette colonne (milieu du
## module) ; teinte de plus en plus froide de [constant COOL_FROM_X] au bord est.
const SLATE_FROM_X: float = 44.0
const COOL_FROM_X: float = 36.0
const COOL_EAST := Color(0.84, 0.9, 1.0)
const SERIE_12 := {
	"faces": ["relief_paroi_01", "relief_paroi_02"], "mass": "relief_paroi_04",
	"slope": "relief_paroi_03",
}
const SLATE := {
	"faces": ["relief_paroi_ardoise_01", "relief_paroi_ardoise_02"],
	"mass": "relief_paroi_ardoise_04", "slope": "relief_paroi_ardoise_03",
}
## Affleurements `R` d'au moins tant de cases collés à la paroi : traités comme la paroi.
const OUTCROP_AS_CLIFF: int = 40
## Sous la paroi : sous-bois (vert) à l'ouest de cette colonne, sol rocheux à l'est.
const ROCK_UNDER_CLIFF_FROM_X: int = 46

## Sol rocheux : valeur du masque R par case (≥ 0,53 = roche franche ; vers 0,5 l'herbe perce
## selon le bruit du shader) ; trous d'herbe rare ; roche qui affleure sur l'herbe à l'est.
const ROCK_HOLE_CHANCE: float = 0.16
const ROCK_HOLE_VALUE: float = 0.47
const ROCK_SOFT_VALUE: float = 0.62
## Valeur R sur un chemin qui borde la roche (sous le seuil même avec le bruit du shader).
const PATH_IN_ROCK_VALUE: float = 0.25
const MEADOW_ROCK_FROM_X: int = 44
const MEADOW_ROCK_MAX: float = 0.42
## Texture de roche à 1:1 (au lieu de × 0,7 des pavés) : moins de répétition.
const ROCK_SCALE: float = 1.0

const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
## Forêt « plus sèche » (jalon-12 §1.4 B) : × 0,95 à l'ouest, × 0,9 au bord est.
const SHADE_VALUE: float = 0.95
const SHADE_RED: float = 1.02
const SHADE_BLUE: float = 1.0
const DRY_EAST := Color(0.95, 0.94, 0.88)
const DRY_FROM_X: float = 30.0
## Rochers : assombris et bleutés vers l'est.
const ROCK_TINT_EAST := Color(0.82, 0.86, 0.95)
## Affleurement du goulet de Hugo (18..22, 18..24 : bloc de 5 × 4 et deux piliers de 2 × 3
## autour de son alcôve) : pierres posées à la main (le remplissage automatique empilait des
## rochers en colonnes) — [objet, pied (cases), échelle, miroir], du fond vers l'avant. Sans
## emprise propre (les cases sont bloquées par la grille).
const HUGO_CELL := Vector2i(20, 21)
const HUGO_ROCKS: Array = [
	["prop_grande_pierre_01", Vector2(19.3, 19.9), 0.85, false],
	["prop_grande_pierre_01", Vector2(21.8, 19.7), 0.8, true],
	["prop_grande_pierre_01", Vector2(20.5, 22.0), 1.1, false],
	["prop_rocher_01", Vector2(19.0, 23.4), 1.15, false],
	["prop_rocher_01", Vector2(22.0, 23.4), 1.15, true],
	["prop_grande_pierre_01", Vector2(19.0, 25.0), 0.78, false],
	["prop_grande_pierre_01", Vector2(22.0, 25.0), 0.78, true],
]
## Prairie : touffes partout, fleurs de plus en plus rares vers l'est (aucune au-delà).
const MEADOW_ATTEMPTS: int = 1300
const FLOWER_CHANCE_WEST: float = 0.5
const FLOWERS_UNTIL_X: float = 50.0
const FLOWERS: Array[int] = [1, 2, 3, 5, 6]
## Sol rocheux : décalcomanies par case `o` (cailloux, touffes sèches, terre).
const ROCK_DECALS_PER_CELL: float = 1.1
const PEBBLES_ID: String = "prop_pierres_01"
const DRY_TUFT := Color(1.0, 0.93, 0.72)
## Terre sur la roche : grisée (la décalcomanie est ocre).
const EARTH_TINT := Color(0.74, 0.73, 0.74, 0.5)
const TERRE_DECAL: String = "res://assets/world/ground/decals/decal_terre_%d.png"
const TUFT_DECAL: String = "res://assets/world/ground/decals/decal_touffe_%d.png"

var _kit: Object
var _outcrops: Array[Array] = []


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_3 : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE, "K", "o")
	_reserve_positions()
	_kit.call(&"make_root", "Route3", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour", NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	_classify_outcrops()
	if not _kit.call(&"add_ground", MASK_PATH, _undergrowth(), _vary_mask):
		print("build_route_3 : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var root: Node2D = _kit.get(&"root")
	var ground := root.get_node(^"PaintedGround")
	ground.set(&"r_texture", load(ROCK_TEXTURE))
	(ground.get(&"material") as ShaderMaterial).set_shader_parameter(&"paving_scale", ROCK_SCALE)
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()

	_kit.call(&"place_border_decals", SEED)
	_place_meadow(decals)
	_place_rock_ground(decals)
	var modules: int = _kit.call(&"place_paroi", PAROI_SEED, _paroi_style)
	_kit.call(&"add_prop_at", entities, "bldg_centre_01", CENTER_ANCHOR, "PokemonCenter")
	_kit.call(&"add_prop_at", entities, "relief_entree_grotte_01", CAVE_ANCHOR, "MtMoonEntrance")
	for entry: Array in SIGNS:
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell(entry[0]), entry[1])
	_add_life(decals)
	_place_ledges(decals)
	var rocks := _place_boulders(entities)
	_place_bushes(entities)
	_kit.call(&"place_tall_grass")
	var feet: Array[Vector2] = []
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, {})
	_dry_the_east(entities)

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_3 :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_3 : %s (%d entités, %d au sol dont %d modules de paroi, %d rochers, "
		% [error_string(result.x), counts.x, counts.y, modules, rocks]
		+ "forêt %d → %d, %d nœuds)" % [forest.x, forest.y, result.y])
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


## Cases des positions des PNJ, Pokémon et objets de la grille : réservées (T18).
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


## Points d'examen des panneaux, objets cachés (indice + point conditionnel), déclencheur
## d'entrée (T18).
func _add_life(decals: Node2D) -> void:
	for entry: Array in SIGNS:
		_kit.call(&"add_interactable", entry[1], _cell(entry[0]), Vector2i.ONE, entry[3],
			entry[2])
	for entry: Array in HIDDEN:
		var id: String = entry[0]
		var clue := _cell(id)
		_kit.call(&"add_prop_at", decals, entry[2], clue, entry[1])
		_kit.call(&"add_interactable", "Hidden" + entry[1].trim_prefix("HiddenClue"), clue,
			Vector2i.ONE, Vector2i.ZERO, StringName(id))
		var point: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
		var unless: Array[StringName] = [StringName("got_" + id)]
		point.set(&"unless_flags", unless)
	_kit.call(&"add_trigger", "Route3Entered", ENTERED_ANCHOR, ENTERED_SIZE, Vector2i.ZERO,
		ENTERED_CUTSCENE)


func _add_passages() -> void:
	for entry: Array in WEST_EXITS:
		_kit.call(&"add_spawn", entry[3], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.LEFT, &"pewter_city",
			entry[2], Vector2i.LEFT)
	for entry: Array in DOORS:
		_kit.call(&"add_spawn", entry[5], (entry[1] as Vector2i) + Vector2i.DOWN)
		_kit.call(&"add_warp", entry[0], entry[1], Kit.STEP_ON, Vector2i.UP, entry[2], entry[3],
			entry[4])


# --- Relief -------------------------------------------------------------------------------


## Affleurements `R` : composantes connexes ; les grandes collées à la paroi deviennent de la
## paroi (modules), les autres des rochers ([method _place_boulders]).
func _classify_outcrops() -> void:
	var left: Dictionary = {}
	for cell: Vector2i in _plan().call(&"cells_of", "R"):
		left[cell] = true
	var cliffs: Dictionary = _kit.get(&"cliff_cells")
	while not left.is_empty():
		var start: Vector2i = left.keys()[0]
		left.erase(start)
		var component: Array[Vector2i] = [start]
		var stack: Array[Vector2i] = [start]
		var touches_cliff := false
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next := cell + side
				if _plan().call(&"at", next) == "K":
					touches_cliff = true
				if left.has(next):
					left.erase(next)
					component.append(next)
					stack.append(next)
		component.sort()
		if touches_cliff and component.size() >= OUTCROP_AS_CLIFF:
			for cell: Vector2i in component:
				cliffs[cell] = true
		else:
			_outcrops.append(component)
			# Sol rocheux sous les rochers : les jours entre eux se lisent comme de la roche.
			var under: Dictionary = _kit.get(&"paved_cells")
			for cell: Vector2i in component:
				under[cell] = true
	# Sous la paroi de l'est : sol rocheux (aucun vert entre les modules d'ardoise).
	var paved: Dictionary = _kit.get(&"paved_cells")
	for cell: Vector2i in cliffs:
		if cell.x >= ROCK_UNDER_CLIFF_FROM_X:
			paved[cell] = true


func _undergrowth() -> Dictionary:
	var values: Dictionary = {}
	for cell: Vector2i in _kit.get(&"forest_cells"):
		values[cell] = 1.0
	for cell: Vector2i in _kit.get(&"cliff_cells"):
		if cell.x < ROCK_UNDER_CLIFF_FROM_X:
			values[cell] = 1.0
	return values


## Teinte froide vers l'est (1 à l'ouest de [param from_x], [param east] au bord est).
func _east_tint(column: float, from_x: float, east: Color) -> Color:
	var t := clampf((column - from_x) / (SIZE.x - from_x), 0.0, 1.0)
	return Color.WHITE.lerp(east, t)


func _paroi_style(column: float) -> Dictionary:
	var look: Dictionary = (SLATE if column >= SLATE_FROM_X else SERIE_12).duplicate()
	look["tint"] = _east_tint(column, COOL_FROM_X, COOL_EAST)
	return look


## Masque : sol rocheux varié (trous d'herbe, roche plus tendre près de l'herbe), roche qui
## affleure sur la prairie de l'est. Graine fixe.
func _vary_mask(image: Image) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 7
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark: String = _plan().call(&"at", cell)
			var color := image.get_pixelv(cell)
			if mark == "o":
				var near_grass := false
				for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					if _plan().call(&"at", cell + side) == ".":
						near_grass = true
				var roll := rng.randf()
				if roll < ROCK_HOLE_CHANCE:
					color.r = ROCK_HOLE_VALUE
				elif near_grass or roll < ROCK_HOLE_CHANCE * 2.0:
					color.r = ROCK_SOFT_VALUE
			elif (mark == "=" or mark == "Q") and _touches(cell, "o"):
				# Chemin dans la roche : un peu de roche dans le canal rouge, pour que la
				# frontière chemin / roche ne laisse pas percer une bande d'herbe.
				color.r = PATH_IN_ROCK_VALUE
			elif mark == "." and x >= MEADOW_ROCK_FROM_X:
				var t := clampf(float(x - MEADOW_ROCK_FROM_X) / 12.0, 0.0, 1.0)
				color.r = MEADOW_ROCK_MAX * t * rng.randf_range(0.5, 1.0)
			image.set_pixelv(cell, color)


func _touches(cell: Vector2i, marks: String) -> bool:
	for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if marks.contains(_plan().call(&"at", cell + side)):
			return true
	return false


# --- Décor du sol -------------------------------------------------------------------------


## Touffes et fleurs sur l'herbe rase : fleurs de plus en plus rares vers l'est.
func _place_meadow(decals: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	for attempt in MEADOW_ATTEMPTS:
		var p := Vector2(decor.randf_range(0.5, SIZE.x - 0.5), decor.randf_range(0.5, SIZE.y - 0.5))
		if _plan().call(&"at", Vector2i(p)) != ".":
			continue
		var chance := FLOWER_CHANCE_WEST * clampf(1.0 - p.x / FLOWERS_UNTIL_X, 0.0, 1.0)
		if decor.randf() < chance:
			var flower: int = FLOWERS[decor.randi_range(0, FLOWERS.size() - 1)]
			_kit.call(&"decal", decals, Kit.FLOWER_DECAL % flower, p * Kit.TILE, 1.0)
		else:
			var tuft: Sprite2D = _kit.call(&"decal", decals, TUFT_DECAL % decor.randi_range(1, 4),
				p * Kit.TILE, 0.9)
			tuft.modulate = Color.WHITE.lerp(DRY_TUFT, clampf((p.x - 40.0) / 20.0, 0.0, 1.0))


## Sol rocheux : cailloux, touffes sèches et terre (casse la répétition de la texture).
func _place_rock_ground(decals: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var cells: Array[Vector2i] = _plan().call(&"cells_of", "o")
	var count := int(cells.size() * ROCK_DECALS_PER_CELL)
	for i in count:
		var cell: Vector2i = cells[decor.randi_range(0, cells.size() - 1)]
		var p := Vector2(cell) + Vector2(decor.randf_range(0.15, 0.85), decor.randf_range(0.3, 0.95))
		var roll := decor.randf()
		var tint := _east_tint(p.x, 54.0, ROCK_TINT_EAST)
		if roll < 0.45:
			var pebbles: Sprite2D = _kit.call(&"add_sprite", decals, PEBBLES_ID, p * Kit.TILE,
				"Pebbles%03d" % i)
			var scale := decor.randf_range(0.6, 1.0)
			pebbles.scale = Vector2(scale, scale)
			pebbles.flip_h = decor.randf() < 0.5
			pebbles.modulate = tint
		elif roll < 0.85:
			var tuft: Sprite2D = _kit.call(&"decal", decals, TUFT_DECAL % decor.randi_range(1, 4),
				p * Kit.TILE, 0.75)
			tuft.modulate = DRY_TUFT
		else:
			var earth: Sprite2D = _kit.call(&"decal", decals, TERRE_DECAL % decor.randi_range(1, 4),
				p * Kit.TILE, 0.9)
			earth.modulate = EARTH_TINT * tint


## Un rebord peint par case `v` (L1 au pied du plateau, L2 du sentier de retour).
func _place_ledges(decals: Node2D) -> void:
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "v"):
		_kit.call(&"add_prop_at", decals, "relief_rebord_01", cell, "Ledge%02d" % index)
		index += 1


## Petits affleurements : grande pierre (3 × 2) là où elle tient, sinon rochers (2 × 1), sinon
## un rocher réduit sur sa case ; assombris et bleutés vers l'est. Renvoie leur nombre.
func _place_boulders(entities: Node2D) -> int:
	var rules: GDScript = _kit.get(&"rules")
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var index := 0
	for entry: Array in HUGO_ROCKS:
		var stone: Node2D = _kit.call(&"add_prop", entities, entry[0],
			(entry[1] as Vector2) * Kit.TILE, "HugoRock%d" % index)
		_kit.call(&"clear_footprint", stone)
		stone.scale = Vector2(entry[2], entry[2])
		_kit.call(&"flip", stone, entry[3])
		var value := decor.randf_range(0.9, 1.0)
		stone.modulate = Color(value, value, value)
		index += 1
	for component: Array in _outcrops:
		if component.has(HUGO_CELL):
			continue
		var free: Dictionary = {}
		for cell: Vector2i in component:
			free[cell] = true
		# Du bas vers le haut (le tri par les pieds dessine les plus au sud devant).
		var order: Array = component.duplicate()
		order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.y > b.y or (a.y == b.y and a.x < b.x))
		for cell: Vector2i in order:
			if not free.has(cell):
				continue
			var placed := false
			for id: String in ["prop_grande_pierre_01", "prop_rocher_01"]:
				var footprint: Array[Vector2i] = rules.call(&"footprint", StringName(id))
				# La case la plus au sud-ouest libre peut tenir n'importe quelle case de
				# l'emprise : on essaie chaque alignement.
				for align: Vector2i in footprint:
					var anchor := cell - align
					var fits := true
					for offset: Vector2i in footprint:
						fits = fits and free.has(anchor + offset)
					if not fits:
						continue
					var rock: Node2D = _kit.call(&"add_prop_at", entities, id, anchor,
						"Rock%02d" % index)
					_style_rock(rock, decor, 0.9 if id == "prop_grande_pierre_01" else 1.0)
					for offset: Vector2i in footprint:
						free.erase(anchor + offset)
					placed = true
					break
				if placed:
					break
			if not placed:
				var foot := Vector2(cell.x + decor.randf_range(0.35, 0.65),
					cell.y + decor.randf_range(0.85, 1.0))
				var small: Node2D = _kit.call(&"add_prop", entities, "prop_rocher_01",
					foot * Kit.TILE, "Rock%02d" % index)
				_kit.call(&"clear_footprint", small)
				_style_rock(small, decor, 0.62)
				free.erase(cell)
			index += 1
	return index


func _style_rock(rock: Node2D, decor: RandomNumberGenerator, scale: float) -> void:
	var s := scale * decor.randf_range(0.92, 1.08)
	rock.scale = Vector2(s, s)
	_kit.call(&"flip", rock, decor.randf() < 0.5)
	var value := decor.randf_range(0.9, 1.0)
	rock.modulate = Color(value, value, value) * _east_tint(rock.position.x / Kit.TILE, 10.0,
		ROCK_TINT_EAST)


## Un buisson par case `x` : les trois images mélangées, jamais la même que la voisine.
func _place_bushes(entities: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var tint: Color = _kit.call(&"forest_tint")
	var chosen: Dictionary = {}
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "x"):
		var options: Array[String] = []
		for id: String in BUSH_IDS:
			if chosen.get(cell + Vector2i.LEFT, "") != id and chosen.get(cell + Vector2i.UP, "") != id:
				options.append(id)
		var id := options[decor.randi_range(0, options.size() - 1)]
		chosen[cell] = id
		var bush: Node2D = _kit.call(&"add_prop_at", entities, id, cell, "Bush%02d" % index)
		index += 1
		_kit.call(&"flip", bush, decor.randf() < 0.5)
		var scale := decor.randf_range(0.95, 1.12)
		bush.scale = Vector2(scale, scale)
		var value := decor.randf_range(0.92, 1.05)
		bush.modulate = Color(value, value, value) * tint


## Forêt de plus en plus sèche vers l'est (la teinte `Shade` est uniforme ; la sécheresse
## s'ajoute par colonne).
func _dry_the_east(entities: Node2D) -> void:
	for child: Node in entities.get_children():
		if not String(child.name).begins_with("Forest"):
			continue
		var node := child as CanvasItem
		var column := (child as Node2D).position.x / Kit.TILE
		node.modulate = node.modulate * _east_tint(column, DRY_FROM_X, DRY_EAST)
