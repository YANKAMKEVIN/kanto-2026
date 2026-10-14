extends SceneTree
## Construit les trois étages du Mont Sélénite (jalon 12 T9, docs/tech/jalon-12.md §2.1, §2.2,
## §2.4 ; dossier 15 §5–§7) d'après les grilles `tools/plans/mont_selenite_{1f,b1f,b2f}.txt`
## (elles font foi), sur la boîte à outils `tools/cave_map_kit.gd` (T7) :
##
##   godot --headless --path . -s res://tools/build_mt_moon.gd [-- --etage=1f|b1f|b2f|tous]
##   godot --headless --path . --import
##   (première fois, ou si un masque change : relancer l'outil après l'import)
##
## - `Ground` (invisible) = source logique : `.` `j` `E` `U` `V` sol calme, `g` gravats (tuiles
##   `RUBBLE`, lues par le moteur au T20 seulement), tout le reste solide.
## - Image : sol peint (sol calme ardoise, gravats au canal R, dessus des masses au canal G),
##   parois en modules (faces, bords latéraux, lèvres : [method CaveKit.place_walls]), repères
##   (colonnes `K`, rochers `o`, éclats de Pierre Lune `*`, mare `w`, lampes `L` — projecteurs
##   dans la chambre de B2F —, caisses `R`, tranchées `F`, dalle `S` et ses deux fossiles posés
##   dessus (PNJ objets depuis le T25), indices `x`, puits de jour `j`), échelles `U` / `V`,
##   panneau de l'entrée ; déclencheur de la scène du chercheur (B2F, T25).
## - **Halos** [LightGlow] (≤ 16 par étage) : lampes, puits de jour et entrée (1F), éclats,
##   projecteurs. Profils `cave_1f` > `cave_b1f` = `cave_b2f` (`data/world/lighting.json`).
## - Passages : échelles `STEP_ON` sans direction vers le point d'apparition de même paire
##   (orientation à l'arrivée à l'opposé de l'échelle) ; entrée du 1F (29..30, 45) ↓ vers la
##   Route 3 (`from_mt_moon_w|e`) ; échelle de sortie de B2F (11, 29) vers le sas de la Route 4
##   (`from_mt_moon`). **Repli** tant que la Route 3 ou le sas (T8, en parallèle) n'existent pas :
##   destination « à venir » (build de développement) et retour sur la case d'arrivée ; relancer
##   l'outil une fois le T8 fusionné (`test_mt_moon_maps` le signale).
## - Points d'examen (T21, `jalon-12.md` §2.7–§2.8, dossier 15 §20 n° 12–14) : panneau de
##   l'entrée, caisses marquées d'un R et lampe abandonnée du camp (1F) ; objet caché « face à un
##   indice » : point EXAMINER sur la case-indice `x` voisine de la position `objet_cache`, qui
##   disparaît une fois l'objet trouvé (`unless_flags = [got_<id>]`). PNJ et objets visibles :
##   `data/npcs/mt_moon_*.json` (T21, T25). Racine **extérieure** (`interior = false`) : la
##   catégorie grotte est dans `data/world/caves.json`.

const Kit := preload("res://tools/cave_map_kit.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const DISPLAY_NAME: String = "Mont Sélénite"
const TILE: int = 96

## Étage → [identifiant, nœud racine, taille, graine logique, graine du décor, profil].
const FLOORS: Dictionary = {
	"1f": [&"mt_moon_1f", "MtMoon1F", Vector2i(60, 46), 1201, 1202, &"cave_1f"],
	"b1f": [&"mt_moon_b1f", "MtMoonB1F", Vector2i(40, 30), 1211, 1212, &"cave_b1f"],
	"b2f": [&"mt_moon_b2f", "MtMoonB2F", Vector2i(50, 38), 1221, 1222, &"cave_b2f"],
}
## Voile de pénombre par étage (passe « lumière rare », 2026-10-14 ; `tools/cave_shade.gd`) :
## 1F le plus clair, B1F puis B2F plus sombres loin des lampes ; pied des parois assombri
## (`edge_*`), dégradé plus large vers le pourtour des salles (`room_*`), pénombre refroidie
## (`tint`). Valeurs réglées sur capture (`tools/art/luminance_grotte.py`) [D].
const SHADE: Dictionary = {
	"1f": {"ambient": 0.95, "edge_min": 0.55, "edge_radius": 0.8, "room_min": 0.87,
		"room_radius": 3.2, "tint": Color(0.80, 0.88, 1.0)},
	"b1f": {"ambient": 0.93, "edge_min": 0.55, "edge_radius": 0.8, "room_min": 0.87,
		"room_radius": 3.2, "tint": Color(0.78, 0.86, 1.0)},
	"b2f": {"ambient": 0.9, "edge_min": 0.55, "edge_radius": 0.8, "room_min": 0.87,
		"room_radius": 3.2, "tint": Color(0.78, 0.86, 1.0)},
}
## Sources qui relèvent le voile (type de halo → rayon en cases, intensité, décalage du centre
## du halo au centre de la flaque au sol). Les colonnes (`beam`) n'éclairent pas le sol (la
## flaque du puits, `shaft`, s'en charge).
## « add » × « color » : flaque claire ajoutée au sol sous les personnages (`CaveFloorLight`).
const SHADE_LIGHTS: Dictionary = {
	&"lamp": {"radius": 3.4, "strength": 0.95, "offset": Vector2(0.0, 40.0), "add": 0.15,
		"color": Color(1.0, 0.78, 0.5)},
	&"shaft": {"radius": 3.2, "strength": 1.0, "offset": Vector2.ZERO, "add": 0.12,
		"color": Color(0.86, 0.92, 1.0)},
	&"shard": {"radius": 2.3, "strength": 0.8, "offset": Vector2.ZERO, "add": 0.1,
		"color": Color(0.66, 0.8, 1.0)},
	# Échelles : sans halo, une pénombre levée autour d'elles (« clairement visibles », §5).
	&"ladder": {"radius": 3.4, "strength": 1.0, "offset": Vector2.ZERO, "add": 0.06,
		"color": Color(0.9, 0.94, 1.0)},
	&"projector": {"radius": 4.6, "strength": 1.0, "offset": Vector2(0.0, 48.0), "add": 0.09,
		"color": Color(1.0, 0.95, 0.85)},
}
## Part de la valeur du sol que prennent les modules de paroi devant lui.
const SHADE_WALL_FOLLOW: float = 0.7
## Puits de jour : flaque au sol adoucie (opacité), colonne de lumière posée sous son centre
## (part de la demi-hauteur du bloc).
const SHAFT_DECAL_ALPHA: float = 0.45
const BEAM_FOOT_SHARE: float = 0.6
## Entrée du 1F (E) ↔ Route 3 (§2.1) : [nœud, case, spawn de la Route 3, spawn d'ici].
const ENTRANCE: Array = [
	["Route3W", Vector2i(29, 45), &"from_mt_moon_w", "from_route_3_w"],
	["Route3E", Vector2i(30, 45), &"from_mt_moon_e", "from_route_3_e"],
]
const ROUTE_3_SOON: String = "Route 3"
const ROUTE_4_SOON: String = "Route 4"
## Projecteurs de la chambre (B2F, position `repere_chambre`) : les cases `L` de cette position
## sont des projecteurs, les autres `L` des lampes de chantier. Les deux du milieu sont braqués
## sur la dalle : leur halo est posé entre eux et elle.
const PROJECTOR_POSITION: String = "repere_chambre"
const AIMED_SHARE: float = 0.55
## Hauteur (pixels au-dessus du pied) de la source de lumière d'une lampe et d'un projecteur.
const LAMP_LIGHT_HEIGHT: float = 62.0
const PROJECTOR_LIGHT_HEIGHT: float = 96.0
## Fossiles posés **sur** la dalle (pied relevé sur le dessus de la pierre, image 83 px).
const FOSSIL_RAISE: float = 30.0
## Échelle qui monte d'une case dont la voisine nord est une galerie (B1F, échelle C) : l'image
## (trou au plafond + échelle, 191 px) déborderait sur la case d'arrivée ; elle est ramenée dans
## sa case (hauteur en pixels) pour qu'on ne lise pas l'échelle sur la case voisine.
const SHORT_LADDER_HEIGHT: float = 128.0
## Points d'examen (T21) : position de la grille → dialogue. Une position dont la case porte un
## repère `R` couvre toutes les cases `R` de l'étage (la pile de caisses du camp).
const EXAMINABLES: Dictionary = {
	"panneau_entree": &"mt_moon_1f_sign",
	"caisse_r": &"mt_moon_1f_crate",
	"lampe_abandonnee": &"mt_moon_1f_lamp",
}
const EXAMINE_ALL_OF: String = "R"
## Objets cachés posés par cet outil (T21 ; la Pierre Lune cachée de B2F au T25) :
## position `objet_cache` = dialogue (drapeau `got_<id>`).
const HIDDEN_ITEMS: Array[String] = ["mt_moon_1f_hidden_1", "mt_moon_b2f_hidden_1"]
const CLUE_MARK: String = "x"
## Scène du chercheur (T25, `jalon-12.md` §1.3 n° 5, §2.12) : déclencheur au bas du couloir des
## lampes (seul accès à la chambre), pas vers le bas ; ses variantes ne jouent qu'après R3.
const RESEARCHER_TRIGGER: Array = [&"mt_moon_b2f", Vector2i(25, 27), Vector2i(2, 1),
	&"mt_moon_researcher"]

var _kit: Object
var _floor_key: String = ""


func _init() -> void:
	var which := "tous"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--etage="):
			which = arg.trim_prefix("--etage=")
	var keys: Array = FLOORS.keys() if which == "tous" else [which]
	var code := 0
	for key: String in keys:
		if not FLOORS.has(key):
			push_error("build_mt_moon : étage inconnu « %s »" % key)
			quit(1)
			return
		code = maxi(code, _build(key))
	quit(code)


## 0 : enregistré ; 2 : masque écrit, importer puis relancer ; 1 : erreur.
func _build(key: String) -> int:
	_floor_key = key
	var spec: Array = FLOORS[key]
	var map_id: StringName = spec[0]
	_kit = Kit.new(Kit.PLANS[map_id], spec[2], spec[3], spec[4])
	if not _errors().is_empty():
		push_error("build_mt_moon %s : %s" % [key, _errors()])
		return 1
	_kit.call(&"make_root", spec[1], map_id, DISPLAY_NAME, spec[5])
	var mask := "res://assets/world/maps/%s_ground.png" % map_id
	if not _kit.call(&"add_ground", mask):
		if not _errors().is_empty():
			push_error("build_mt_moon %s :\n%s" % [key, "\n".join(_errors())])
			_kit.call(&"discard")
			return 1
		print("build_mt_moon %s : masque écrit ; importer (--import) puis relancer" % key)
		_kit.call(&"discard")
		return 2
	var walls: Vector3i = _kit.call(&"place_walls", spec[4] + 7)
	_place_landmarks()
	_place_ladders(map_id)
	_place_examinables()
	if map_id == &"mt_moon_1f":
		_place_entrance()
	if map_id == RESEARCHER_TRIGGER[0]:
		_kit.call(&"add_trigger", "ResearcherTrigger", RESEARCHER_TRIGGER[1],
			RESEARCHER_TRIGGER[2], Vector2i.DOWN, RESEARCHER_TRIGGER[3])
	var shade := "res://assets/world/maps/%s_shade.png" % map_id
	if _errors().is_empty() and not _kit.call(&"add_shade", shade, SHADE[key], SHADE_LIGHTS,
			SHADE_WALL_FOLLOW):
		if _errors().is_empty():
			print("build_mt_moon %s : voile écrit ; importer (--import) puis relancer" % key)
			_kit.call(&"discard")
			return 2
	if not _errors().is_empty():
		push_error("build_mt_moon %s :\n%s" % [key, "\n".join(_errors())])
		_kit.call(&"discard")
		return 1
	var counts := Vector3i((_kit.get(&"entities") as Node).get_child_count(),
		(_kit.get(&"decals") as Node).get_child_count(), _kit.call(&"glow_count"))
	var result: Vector2i = _kit.call(&"save", MAPS_DIR + String(map_id) + ".tscn")
	print("%s : %s (%d entités, %d au sol, parois %d faces / %d bords / %d lèvres, %d halos, "
		% [map_id, error_string(result.x), counts.x, counts.y, walls.x, walls.y, walls.z,
		counts.z] + "%d nœuds)" % result.y)
	return 0 if result.x == OK else 1


func _errors() -> PackedStringArray:
	return _kit.get(&"errors")


func _plan() -> Object:
	return _kit.get(&"plan")


func _rng() -> RandomNumberGenerator:
	return _kit.get(&"decor_rng")


# --- Repères ------------------------------------------------------------------------------


func _place_landmarks() -> void:
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	var index := 0
	# Colonnes `K` : bloc 2 × 3 (carrefour du 1F) = la grande colonne, case seule = colonne fine.
	for block: Rect2i in _blocks("K"):
		var anchor := block.end - Vector2i.ONE
		if block.size == Vector2i(2, 3):
			_kit.call(&"add_prop_at", entities, "prop_colonne_grotte_01", anchor, "Column%d" % index)
		else:
			_vary(_sprite_at(entities, "prop_colonne_grotte_02", anchor, "Column%d" % index),
				0.94, 1.06)
		index += 1
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "o"):
		var id := "prop_rocher_grotte_0%d" % (1 + index % 2)
		_vary(_sprite_at(entities, id, cell, "Rock%02d" % index), 0.9, 1.08)
		index += 1
	# Éclats de Pierre Lune incrustés (`*`) : un halo bleu pâle par groupe de cases voisines.
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "*"):
		var id := "prop_eclats_lune_0%d" % (1 + index % 2)
		_vary(_sprite_at(entities, id, cell, "Shards%02d" % index), 0.95, 1.05)
		index += 1
	for block: Rect2i in _blocks("*"):
		_kit.call(&"add_glow", &"shard", _center(block), "GlowShard%d_%d" % [block.position.x,
			block.position.y])
	# Lampes et projecteurs `L`.
	var projectors: Array = _plan().call(&"cells_at", PROJECTOR_POSITION)
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "L"):
		var foot := Vector2((cell.x + 0.5) * TILE, (cell.y + 1) * TILE)
		if projectors.has(cell):
			_kit.call(&"add_prop_at", entities, "prop_projecteur_01", cell, "Projector%d" % index)
			_kit.call(&"add_glow", &"projector", _projector_glow(cell, foot),
				"GlowProjector%d" % index)
		else:
			_kit.call(&"add_prop_at", entities, "prop_lampe_chantier_01", cell, "Lamp%d" % index)
			_kit.call(&"add_glow", &"lamp", foot - Vector2(0.0, LAMP_LIGHT_HEIGHT),
				"GlowLamp%d" % index)
		index += 1
	# Caisses `R` : deux cases côte à côte = la pile de deux, sinon une caisse.
	index = 0
	for block: Rect2i in _row_blocks("R"):
		var anchor := block.end - Vector2i.ONE
		var id := "prop_caisse_r_02" if block.size.x == 2 else "prop_caisse_r_01"
		_kit.call(&"add_prop_at", entities, id, anchor, "Crates%d" % index)
		index += 1
	# Tranchées `F` (3 × 3, 4 × 3) : à plat dans la couche du sol, étirée à la zone.
	index = 0
	for block: Rect2i in _blocks("F"):
		var trench: Node2D = _floor_decor(decals, "prop_tranchee_01", block, "Trench%d" % index)
		var sprite := trench.get_node(^"Sprite") as Sprite2D
		var width := block.size.x * TILE
		trench.scale = Vector2(width / sprite.texture.get_width(), 1.0)
		index += 1
	# Mare `w` (4 × 3) : à plat, centrée sur la zone.
	for block: Rect2i in _blocks("w"):
		_floor_decor(decals, "prop_mare_grotte_01", block, "Pool")
	# Dalle `S` (3 × 1). Les deux fossiles posés dessus sont, depuis le T25, des PNJ objets
	# fixes (`data/npcs/mt_moon_b2f.json` : `object/fossil_dome`, `object/fossil_helix`, relevés
	# de « lift » = [constant FOSSIL_RAISE]) que l'on examine et choisit ; plus de décor ici.
	for block: Rect2i in _blocks("S"):
		var anchor := Vector2i(block.position.x + 1, block.position.y)
		_kit.call(&"add_prop_at", entities, "prop_dalle_01", anchor, "FossilSlab")
	# Indices des objets cachés `x` : un petit éclat clair, sans halo (discret, B-10).
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "x"):
		_kit.call(&"add_prop_at", entities, "prop_indice_eclat_01", cell, "Hint%d" % index)
		index += 1
	# Puits de jour `j` : flaque de lumière au sol + halo blanc bleuté.
	index = 0
	for block: Rect2i in _blocks("j"):
		var shaft: Node2D = _floor_decor(decals, "decal_puits_jour_01", block,
			"DayShaft%d" % index)
		var sprite := shaft.get_node(^"Sprite") as Sprite2D
		var fit := minf(block.size.x * TILE * 1.15 / sprite.texture.get_width(),
			block.size.y * TILE * 1.35 / sprite.texture.get_height())
		shaft.scale = Vector2(fit, fit)
		shaft.position = _center(block) + Vector2(0.0, sprite.texture.get_height() * fit / 2.0)
		shaft.modulate.a = SHAFT_DECAL_ALPHA
		_kit.call(&"add_glow", &"shaft", _center(block), "GlowShaft%d" % index)
		_kit.call(&"add_glow", &"beam", _center(block) + Vector2(0.0,
			block.size.y * TILE / 2.0 * BEAM_FOOT_SHARE), "GlowBeam%d" % index)
		index += 1
	# Panneau de l'entrée (1F) : décor ; son texte (examen) arrive au T21.
	if _plan().call(&"cell_of", "panneau_entree") != Vector2i(-1, -1):
		_kit.call(&"add_prop_at", entities, "prop_panneau_01",
			_plan().call(&"cell_of", "panneau_entree"), "SignEntrance")


## Halo d'un projecteur : sur lui (coins de la chambre) ou, s'il est braqué sur la dalle (même
## rangée qu'elle à une case près), entre lui et la dalle.
func _projector_glow(cell: Vector2i, foot: Vector2) -> Vector2:
	var source := foot - Vector2(0.0, PROJECTOR_LIGHT_HEIGHT)
	var slabs := _blocks("S")
	if slabs.is_empty():
		return source
	var slab := _center(slabs[0])
	if absi(cell.y - slabs[0].position.y) <= 1:
		return source.lerp(slab, AIMED_SHARE)
	return source


## Décor à plat posé dans la couche du sol, centré sur [param block] (pied au bas de l'image).
func _floor_decor(parent: Node, id: String, block: Rect2i, node_name: String) -> Node2D:
	var prop: Node2D = _kit.call(&"add_prop", parent, id, Vector2.ZERO, node_name)
	prop.set(&"footprint", [] as Array[Vector2i])
	var sprite := prop.get_node(^"Sprite") as Sprite2D
	var height := float(sprite.texture.get_height())
	prop.position = (_center(block) + Vector2(0.0, height / 2.0)).round()
	return prop


func _vary(sprite: Sprite2D, low: float, high: float) -> void:
	var value := _rng().randf_range(low, high)
	sprite.modulate = Color(value, value, value)
	sprite.flip_h = _rng().randf() < 0.5


## Objet peint réduit à son `Sprite2D` (miroir et valeur enregistrés), au pied de [param cell] ;
## la case est déjà bloquée par la grille (aucune emprise à porter).
func _sprite_at(parent: Node, id: String, cell: Vector2i, node_name: String) -> Sprite2D:
	var rules: GDScript = _kit.get(&"rules")
	if _plan().call(&"is_walkable", cell):
		var errors := _errors()
		errors.append("%s : %s posé sur une case praticable %s" % [node_name, id, cell])
		_kit.set(&"errors", errors)
	return _kit.call(&"add_sprite", parent, id, rules.call(&"foot_position", StringName(id), cell),
		node_name)


## Centre (pixels) du rectangle de cases [param block].
func _center(block: Rect2i) -> Vector2:
	return (Vector2(block.position) + Vector2(block.size) / 2.0) * TILE


## Rectangles englobants des groupes de cases [param mark] voisines (4-connexité).
func _blocks(mark: String) -> Array[Rect2i]:
	var cells: Array = _plan().call(&"cells_of", mark)
	var seen: Dictionary = {}
	var blocks: Array[Rect2i] = []
	for start: Vector2i in cells:
		if seen.has(start):
			continue
		var rect := Rect2i(start, Vector2i.ONE)
		var stack: Array[Vector2i] = [start]
		seen[start] = true
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			rect = rect.expand(cell).expand(cell + Vector2i.ONE)
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next := cell + step
				if not seen.has(next) and cells.has(next):
					seen[next] = true
					stack.append(next)
		blocks.append(rect)
	return blocks


## Paires horizontales de cases [param mark] (une case seule = un bloc d'une case).
func _row_blocks(mark: String) -> Array[Rect2i]:
	var blocks: Array[Rect2i] = []
	var taken: Dictionary = {}
	for cell: Vector2i in _plan().call(&"cells_of", mark):
		if taken.has(cell):
			continue
		taken[cell] = true
		var right := cell + Vector2i.RIGHT
		if _plan().call(&"at", right) == mark and not taken.has(right):
			taken[right] = true
			blocks.append(Rect2i(cell, Vector2i(2, 1)))
		else:
			blocks.append(Rect2i(cell, Vector2i.ONE))
	return blocks


# --- Points d'examen et objets cachés (T21) ----------------------------------------------


func _place_examinables() -> void:
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in EXAMINABLES:
		if not positions.has(id):
			continue
		var cells: Array = _plan().call(&"cells_at", id)
		if _plan().call(&"at", cells[0]) == EXAMINE_ALL_OF:
			cells = _plan().call(&"cells_of", EXAMINE_ALL_OF)
		var index := 0
		for cell: Vector2i in cells:
			var node_name := "Examine_%s" % id if cells.size() == 1 \
				else "Examine_%s_%d" % [id, index]
			_kit.call(&"add_interactable", node_name, cell, Vector2i.ONE, Vector2i.ZERO,
				EXAMINABLES[id])
			index += 1
	for id: String in HIDDEN_ITEMS:
		if not positions.has(id):
			continue
		var clue := _clue_of(_plan().call(&"cell_of", id))
		if clue == Vector2i(-1, -1):
			var errors := _errors()
			errors.append("%s : aucun indice « %s » voisin" % [id, CLUE_MARK])
			_kit.set(&"errors", errors)
			continue
		var node_name := "Hidden_%s" % id
		_kit.call(&"add_interactable", node_name, clue, Vector2i.ONE, Vector2i.ZERO,
			StringName(id))
		var points := (_kit.get(&"root") as Node).get_node(^"Interactables")
		points.get_node(NodePath(node_name)).set(&"unless_flags",
			[StringName("got_" + id)] as Array[StringName])


## Case-indice `x` voisine de la case où l'on se tient (`jalon-12.md` §1.3 n° 1).
func _clue_of(stand: Vector2i) -> Vector2i:
	for step: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		if _plan().call(&"at", stand + step) == CLUE_MARK:
			return stand + step
	return Vector2i(-1, -1)


# --- Échelles, entrée, sortie -------------------------------------------------------------


func _place_ladders(map_id: StringName) -> void:
	var links: Array = _kit.call(&"ladder_links")
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] == "spawn" and id != "from_route_3":
			var named: Dictionary = Kit.spawn_names(id, _plan().call(&"cells_at", id))
			for spawn_name: String in named:
				_kit.call(&"add_spawn", spawn_name, named[spawn_name])
	for link: Dictionary in links:
		var cell: Vector2i = link["cell"]
		var id: String = link["id"]
		var up: bool = _plan().call(&"attr", id, "sens") == "monte"
		var prop_id := "prop_echelle_monte_01" if up else "prop_echelle_descend_01"
		var ladder: Node2D = _kit.call(&"add_floor_prop", prop_id, cell,
			"Ladder%s" % String(link["pair"]))
		_kit.call(&"add_shade_source", &"ladder", _kit.call(&"cell_center", cell))
		if up and bool(_plan().call(&"is_walkable", cell + Vector2i.UP)):
			_shorten_ladder(ladder)
		var node_name := "Ladder%sWarp" % String(link["pair"])
		var target: StringName = link["target_map"]
		if _is_parallel_map(target) and not ResourceLoader.exists(MAPS_DIR + String(target) + ".tscn"):
			# Repli : le sas n'est pas encore construit (T8) ; retour sur l'arrivée d'ici.
			var back := _local_arrival(String(link["pair"]))
			_kit.call(&"add_warp", node_name, cell, Kit.STEP_ON, Vector2i.ZERO, &"",
				StringName(back), Kit.arrival_facing(_plan().call(&"cell_of", back), cell),
				ROUTE_4_SOON)
			print("%s : échelle %s → « %s — À venir » (repli, %s absente)" % [map_id, id,
				ROUTE_4_SOON, target])
		else:
			_kit.call(&"add_ladder", node_name, link)


func _shorten_ladder(ladder: Node2D) -> void:
	var sprite := ladder.get_node(^"Sprite") as Sprite2D
	var size := sprite.texture.get_size()
	var fit := SHORT_LADDER_HEIGHT / size.y
	ladder.scale = Vector2(1.0, fit)


func _is_parallel_map(map_id: StringName) -> bool:
	return map_id == &"route_3" or map_id == &"route_4"


## Point d'apparition d'ici de même paire qu'une échelle.
func _local_arrival(pair: String) -> String:
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] == "spawn" and _plan().call(&"attr", id, "paire") == pair:
			return id
	return ""


## Entrée du 1F : deux passages `STEP_ON` ↓ vers la Route 3 (ou « à venir » tant qu'elle n'existe
## pas), les deux points d'apparition d'arrivée (tournés ↑), un halo de jour.
func _place_entrance() -> void:
	var built := ResourceLoader.exists(MAPS_DIR + "route_3.tscn")
	for entry: Array in ENTRANCE:
		var cell: Vector2i = entry[1]
		_kit.call(&"add_spawn", entry[3], cell + Vector2i.UP)
		if built:
			_kit.call(&"add_warp", entry[0], cell, Kit.STEP_ON, Vector2i.DOWN, &"route_3",
				entry[2], Vector2i.DOWN)
		else:
			_kit.call(&"add_warp", entry[0], cell, Kit.STEP_ON, Vector2i.DOWN, &"",
				StringName(entry[3]), Vector2i.UP, ROUTE_3_SOON)
	if not built:
		print("mt_moon_1f : entrée → « %s — À venir » (repli, route_3 absente)" % ROUTE_3_SOON)
	var mouth := Rect2i((ENTRANCE[0][1] as Vector2i), Vector2i(2, 1))
	_kit.call(&"add_glow", &"shaft", _center(mouth), "GlowEntrance")
