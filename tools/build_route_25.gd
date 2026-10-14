extends SceneTree
## Construit game/world/maps/route_25.tscn (Route 25 et Cap d'Azuria, 80 × 28 cases) d'après la
## grille fonctionnelle `tools/plans/route_25.txt` (jalon 14 T14, docs/tech/jalon-14.md §2.1,
## §2.2 ; dossier 17).
##
##   godot --headless --path . -s res://tools/build_route_25.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** (géométrie, positions, passages) ; la vue générale peinte validée
## (`docs/design/reference/route-25-vue-generale-v1.png`) donne la DA. Écarts de la vue **non
## reproduits** : le Scout de D5 (le tableau dit Jeune Dresseur) et les personnages (placés par le
## peintre, ils viennent au T16).
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` `D` chemin, `h` hautes herbes, `v`
##   rebord (sauté vers le sud), `s` sable (praticable) ; `w` mer (solide, `GridWorld.is_water`) ;
##   tout le reste (falaise, forêt, rochers, buissons, massifs, maison) est solide.
## - Image : sol peint (masque G = chemin ; rivage R = sable, G = mer de Bourg Palette à angles
##   droits, écume de Bourg Palette), sous-bois sur la forêt et sous la falaise, forêt serrée,
##   falaise du nord et deux piliers de roche en modules de paroi (série 12), rivage rocheux en
##   modules `relief_rivage_*` sur les `R` qui touchent la mer (`tools/coast_map_kit.gd`), buissons,
##   massifs de fleurs, hautes herbes jaune-vert, rebord de bois, maison de Léo (série 16),
##   panneaux, rochers dans l'eau, touffes et fleurs.
## - Passages : raccord ouest (0, 13..15) PUSH ← vers la Route 24 (**provisoire : « ROUTE 24 —
##   À venir »** tant que la Route 24 nord du J13 n'est pas fusionnée, T15) ; porte de la maison
##   (71..72, 11) STEP_ON ↑ → `bill_house` / `from_route_25`. Spawns `from_route_24_n|c|s`,
##   `from_bill_house_w|e`.
## - **Vie (T16)** : PNJ, Dresseurs, objets et Pokémon d'ambiance viennent de
##   `data/npcs/route_25.json` ; les cases de la grille sont **réservées** (la forêt s'en écarte
##   comme pour un PNJ). Panneaux et rocher au coquillage = points d'examen ; coquillage posé sur
##   le rocher (64, 20). Rencontres : `data/encounters/route_25.json`. Pas de déclencheurs.

const Kit := preload("res://tools/coast_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_25.txt"
const OUT_PATH: String = "res://game/world/maps/route_25.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_25_ground.png"
const NPCS_PATH: String = "res://data/npcs/route_25.json"
const SIZE := Vector2i(80, 28)
const SEED: int = 2501
const DECOR_SEED: int = 2502
const FOREST_SEED: int = 25
const PAROI_SEED: int = 2503
const SHORE_SEED: int = 2504

const MAP_ID: StringName = &"route_25"
const DISPLAY_NAME: String = "Route 25"
const REGION: String = "Azuria — Cap d'Azuria"
const WALKABLE: String = ".=hvsD"

## Raccord ouest : [nœud, case, spawn de la Route 24 (T15), spawn d'ici].
const WEST_EXITS: Array = [
	["Route24N", Vector2i(0, 13), &"from_route_25_n", "from_route_24_n"],
	["Route24C", Vector2i(0, 14), &"from_route_25_c", "from_route_24_c"],
	["Route24S", Vector2i(0, 15), &"from_route_25_s", "from_route_24_s"],
]
## Tant que la Route 24 n'est pas là : destination « à venir » (libellé, « — À venir » ajouté).
const WEST_SOON: String = "Route 24"
## Porte de la maison de Léo (STEP_ON ↑) : [nœud, case, spawn d'ici (devant, tourné ↓)].
const DOORS: Array = [
	["DoorLeoW", Vector2i(71, 11), "from_bill_house_w"],
	["DoorLeoE", Vector2i(72, 11), "from_bill_house_e"],
]
const HOUSE_ANCHOR := Vector2i(72, 11)
const HOUSE_MAP: StringName = &"bill_house"
const HOUSE_SPAWN: StringName = &"from_route_25"
const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
const BALL_KINDS: Array[String] = ["objet_visible", "cache"]
## Panneaux : [position, nœud du décor, dialogue]. Lus depuis la case au sud, tournés vers le nord.
const SIGNS: Array = [
	["panneau_ouest", "SignWest", &"route_25_sign_west"],
	["panneau_cap", "SignCape", &"route_25_sign_cape"],
]
## Objet caché O4 (T16) : coquillage posé sur le rocher `R`, examiné depuis la case au nord
## (tourné vers le sud). Point d'examen `unless_flags` [`got_route_25_hidden_1`] (mécanisme des
## objets cachés du J12, T23 du J14) : il disparaît une fois la Potion prise.
const HIDDEN_ITEM: String = "route_25_hidden_1"
const HIDDEN_CLUE_ID: String = "prop_indice_coquillage_01"

const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
const FLOWER_BED_ID: String = "prop_hortensias_01"
const SEA_ROCK_ID: String = "prop_rocher_mer_01"
## Rochers dans l'eau (ancre = case de droite du rocher de 2 cases), posés à la main.
const SEA_ROCKS: Array[Vector2i] = [
	Vector2i(25, 18), Vector2i(31, 20), Vector2i(47, 19), Vector2i(51, 18), Vector2i(9, 25),
	Vector2i(34, 25), Vector2i(61, 25), Vector2i(71, 24), Vector2i(22, 24), Vector2i(48, 24),
]
## Forêt « plus sèche » (même valeurs que les routes d'Argenta).
const SHADE_VALUE: float = 0.95
const SHADE_RED: float = 1.02
const SHADE_BLUE: float = 1.0
## Prairie : touffes et fleurs (la vue en est semée).
const MEADOW_ATTEMPTS: int = 1500
const FLOWER_CHANCE: float = 0.4
const FLOWERS: Array[int] = [1, 2, 3, 5, 6]

var _kit: Object


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED, SHORE_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_25 : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE, "K", "")
	_reserve_positions()
	_kit.call(&"make_root", "Route25", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour", NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	_make_pillars()
	if not _kit.call(&"add_ground", MASK_PATH, _kit.call(&"forest_undergrowth")):
		print("build_route_25 : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_add_examine_points()

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, FLOWER_CHANCE, FLOWERS)
	var modules: int = _kit.call(&"place_paroi", PAROI_SEED)
	var shore: int = _kit.call(&"place_shore")
	_place_ledges(decals)
	_kit.call(&"add_prop_at", entities, "bldg_maison_leo_01", HOUSE_ANCHOR, "LeoHouse")
	for entry: Array in SIGNS:
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell(entry[0]), entry[1])
	_kit.call(&"add_prop_at", entities, HIDDEN_CLUE_ID, _cell(HIDDEN_ITEM), "ShellClue")
	_place_bushes(entities)
	_place_flower_beds(entities)
	_place_sea_rocks(entities)
	_kit.call(&"place_tall_grass")
	var feet: Array[Vector2] = []
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, {})

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_25 :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_25 : %s (%d entités, %d au sol dont %d modules de paroi et %d de rivage, "
		% [error_string(result.x), counts.x, counts.y, modules, shore]
		+ "forêt %d → %d, %d nœuds)" % [forest.x, forest.y, result.y])
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


## Cases des PNJ, Pokémon et objets de la grille : réservées (T16, T17).
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


## Piliers de roche loin de l'eau : de la paroi (série 12), comme la falaise `K`.
func _make_pillars() -> void:
	_kit.call(&"classify_rocks")
	var cliffs: Dictionary = _kit.get(&"cliff_cells")
	var pillars: Dictionary = _kit.get(&"pillar_cells")
	for component: Array in _kit.call(&"pillar_components"):
		for cell: Vector2i in component:
			cliffs[cell] = true
			pillars[cell] = true


func _add_passages() -> void:
	for entry: Array in WEST_EXITS:
		_kit.call(&"add_spawn", entry[3], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.LEFT, &"",
			StringName(entry[3]), Vector2i.RIGHT, WEST_SOON)
	for entry: Array in DOORS:
		_kit.call(&"add_spawn", entry[2], (entry[1] as Vector2i) + Vector2i.DOWN)
		_kit.call(&"add_warp", entry[0], entry[1], Kit.STEP_ON, Vector2i.UP, HOUSE_MAP,
			HOUSE_SPAWN, Vector2i.UP)


## Panneaux (EXAMINER depuis le sud) et rocher au coquillage (depuis le nord).
func _add_examine_points() -> void:
	for entry: Array in SIGNS:
		_kit.call(&"add_interactable", String(entry[1]) + "Point", _cell(entry[0]), Vector2i.ONE,
			Vector2i.UP, entry[2])
	_kit.call(&"add_interactable", "ShellPoint", _cell(HIDDEN_ITEM), Vector2i.ONE,
		Vector2i.DOWN, StringName(HIDDEN_ITEM))
	# Mécanisme des objets cachés du J12 (T17) : le point disparaît une fois l'objet pris.
	var point: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
	var unless: Array[StringName] = [StringName("got_" + HIDDEN_ITEM)]
	point.set(&"unless_flags", unless)


# --- Décor --------------------------------------------------------------------------------


## Un rebord de bois par case `v` (L1, au bord sud de la terrasse).
func _place_ledges(decals: Node2D) -> void:
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "v"):
		_kit.call(&"add_prop_at", decals, "relief_rebord_01", cell, "Ledge%02d" % index)
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


## Massifs de fleurs de part et d'autre de la maison (cases `f`) : une hortensia par case.
func _place_flower_beds(entities: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "f"):
		var bed: Node2D = _kit.call(&"add_prop_at", entities, FLOWER_BED_ID, cell,
			"FlowerBed%02d" % index)
		index += 1
		_kit.call(&"flip", bed, decor.randf() < 0.5)
		var scale := decor.randf_range(0.95, 1.1)
		bed.scale = Vector2(scale, scale)


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
