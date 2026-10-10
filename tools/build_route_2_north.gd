extends SceneTree
## Construit game/world/maps/route_2_north.tscn (Route 2 nord, 30 × 24 cases) d'après la grille
## fonctionnelle `tools/plans/route_2_nord.txt` (jalon 10 T11, docs/tech/jalon-10.md §2.1 ;
## dossier 12 §3).
##
##   godot --headless --path . -s res://tools/build_route_2_north.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** (géométrie, positions, passages) ; la vue générale peinte validée
## (`docs/design/reference/argenta-vue-generale-v1.png`) donne la DA. Écarts de la vue **non
## reproduits** (dossier 12, « Vue générale peinte v1 ») : chemin droit du poste à l'avenue
## d'Argenta (pas de décrochement), poste dans l'axe, détour par l'ouest autour de la haie de
## buissons lisible, Potion au bout du détour.
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` `D` chemin, `h` hautes herbes ; tout
##   le reste (forêt, paroi, poste, gros rocher, buissons, éboulis, sentier fermé) est solide.
## - Image : sol peint (masque G = chemin, sentier fermé de l'est et pied de la paroi), sous-bois
##   sur la forêt, forêt serrée un peu plus sèche ([DenseForest.Shade] valeur × 0,95, rouge ×
##   1,02 : défaut du plan §1.4 B), bloc rocheux de l'est en modules de paroi, gros rocher
##   (`prop_grande_pierre_01` × 0,75 en miroir : écho de la Route 2 sud), haie de buissons,
##   éboulis du sentier est (rochers existants assombris + pierres), touffes jaune-vert (H1, H2,
##   « même famille » que la Route 2 sud), poste nord vu du dessus (toit, porte en haut de
##   l'emprise, couche du sol : T10), panneau « ROUTE 2 ».
## - Passages : trois warps PUSH ↑ vers Argenta (17..19, 43) ; porte du poste (15, 21) STEP_ON ↓
##   vers le poste nord de la forêt, retour sur son spawn existant `north_door` (§0.3 n° 4).
## - PNJ (Montagnard), Potion visible : `data/npcs/route_2_north.json` (les arbres qui les
##   cacheraient sont retirés) ; point d'examen des éboulis (« Des éboulis bloquent le
##   sentier. », arbitrage 9 : aucun panneau « Accès fermé »).

const Kit := preload("res://tools/pewter_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_2_nord.txt"
const OUT_PATH: String = "res://game/world/maps/route_2_north.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_2_north_ground.png"
const NPCS_PATH: String = "res://data/npcs/route_2_north.json"
const SIZE := Vector2i(30, 24)
const SEED: int = 2101
const DECOR_SEED: int = 2102
const FOREST_SEED: int = 12
const PAROI_SEED: int = 2103

const MAP_ID: StringName = &"route_2_north"
const DISPLAY_NAME: String = "Route 2"
## Sous-titre porté par la carte (dossier 12 §20, Q-3 : 2e carte de la zone `route_2`).
const REGION: String = "Forêt de Jade — Argenta"

## Raccord nord (jalon-10 §2.1) : [nœud, case, spawn d'Argenta, spawn d'ici].
const NORTH_EXITS: Array = [
	["PewterW", Vector2i(14, 0), &"from_route_2_north_w", "from_pewter_w"],
	["PewterC", Vector2i(15, 0), &"from_route_2_north_c", "from_pewter_c"],
	["PewterE", Vector2i(16, 0), &"from_route_2_north_e", "from_pewter_e"],
]
## Porte du poste nord (mur nord, vu du dessus) et retour devant elle (tourné ↑).
const GATE_DOOR := Vector2i(15, 21)
const GATE_MAP: StringName = &"viridian_forest_gate_north"
const GATE_SPAWN: StringName = &"north_door"
const GATE_RETURN: String = "from_forest_gate"
const GATE_ANCHOR := Vector2i(15, 23)
## Image du poste descendue (px, sur le sprite seul : l'emprise ne bouge pas) pour que le faîte de
## l'avant-corps tombe au bord haut de la case de la porte (15, 21) : à la règle du T10 (seuil au
## bas de la case de la porte), le joueur en (15, 20), juste devant la porte, se tenait sur le
## toit de l'avant-corps (capture du T11). Défaut T11 : on marche jusqu'au faîte, puis on entre.
const GATE_IMAGE_DROP: float = 150.0

## Gros rocher (`R`, 2 × 2) : grande pierre de la Route 2 sud réduite, en miroir ; pied au bord
## commun de ses deux colonnes, bas de sa rangée du bas.
const ROCK_FOOT := Vector2(18.0, 13.0)
const ROCK_SCALE: float = 0.75
## Éboulis (`E`, une colonne de 2 cases, sentier `e` peint derrière) : rochers existants
## assombris + petites pierres (défaut du plan §1.4 A) : [objet, pied (cases), échelle, miroir].
const RUBBLE: Array = [
	["prop_rocher_01", Vector2(25.6, 16.75), 0.9, true],
	["prop_rocher_01", Vector2(24.95, 17.05), 1.15, false],
	["prop_pierres_01", Vector2(24.5, 17.45), 1.2, true],
	["prop_rocher_01", Vector2(24.9, 18.05), 1.05, true],
	["prop_pierres_01", Vector2(26.3, 16.35), 1.0, false],
]
const RUBBLE_VALUE: float = 0.78
## Objets de lisière (sur des cases de forêt au bord des clairières) : [objet, case, nom].
const EDGE_PROPS: Array = [
	["prop_ronces_01", Vector2i(1, 12), "EdgeBrambleWest"],
	["prop_tronc_couche_01", Vector2i(8, 20), "EdgeLogGate"],
]
## Buissons des cases `x` (haie du détour) : les trois mélangés.
const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
## Forêt « plus sèche » que la Route 2 sud (jalon-10 §1.4 B, défaut).
const SHADE_VALUE: float = 0.95
const SHADE_RED: float = 1.02
const SHADE_BLUE: float = 1.0
## Prairie : touffes et fleurs rares (« touches discrètes »).
const MEADOW_ATTEMPTS: int = 260
const MEADOW_FLOWER_CHANCE: float = 0.25
const FLOWERS: Array[int] = [1, 3, 5]

var _kit: Object


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_2_north : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"make_root", "Route2North", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour",
		NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	if not _kit.call(&"add_ground", MASK_PATH, _kit.call(&"forest_undergrowth")):
		print("build_route_2_north : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var root: Node2D = _kit.get(&"root")
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_kit.call(&"add_interactable", "SignRoute", _cell("panneau_route"), Vector2i.ONE,
		Vector2i.UP, &"route_2_north_sign")
	var rubble: Array = _plan().call(&"cells_at", "examen_eboulis")
	_kit.call(&"add_interactable", "Rockslide", rubble[-1], Vector2i(1, rubble.size()),
		Vector2i.RIGHT, &"route_2_north_rockslide")

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, MEADOW_FLOWER_CHANCE, FLOWERS)
	var modules: int = _kit.call(&"place_paroi", PAROI_SEED)
	var gate: Node2D = _kit.call(&"add_prop_at", decals, "bldg_poste_foret_nord_01", GATE_ANCHOR,
		"ForestGate")
	# Le nœud descend (une modification du sprite d'une instance n'est pas enregistrée) ; son
	# emprise est réécrite pour rester sur les cases `P` de la grille (case d'ancrage plus bas).
	var anchor_before := _anchor_of(gate.position)
	gate.position.y += GATE_IMAGE_DROP
	var shift := _anchor_of(gate.position) - anchor_before
	var cells: Array[Vector2i] = []
	for offset: Vector2i in gate.get(&"footprint"):
		cells.append(offset - shift)
	gate.set(&"footprint", cells)
	_place_props(entities)
	_kit.call(&"place_tall_grass")
	var feet: Array[Vector2] = []
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, _taken())

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_2_north :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_2_north : %s (%d entités, %d au sol dont %d modules de paroi, forêt %d → %d, "
		% [error_string(result.x), counts.x, counts.y, modules, forest.x, forest.y]
		+ "%d nœuds)" % result.y)
	root = null
	quit(0 if result.x == OK else 1)


## Case d'ancrage d'un objet au pied [param foot] (comme `WorldProp.get_anchor_cell`).
func _anchor_of(foot: Vector2) -> Vector2i:
	return Vector2i(floori(foot.x / Kit.TILE), floori((foot.y - 1.0) / Kit.TILE))


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


func _add_passages() -> void:
	for entry: Array in NORTH_EXITS:
		_kit.call(&"add_spawn", entry[3], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.UP, &"pewter_city",
			entry[2], Vector2i.UP)
	_kit.call(&"add_spawn", GATE_RETURN, _cell("arrivee_poste"))
	_kit.call(&"add_warp", "ForestGateNorth", GATE_DOOR, Kit.STEP_ON, Vector2i.DOWN, GATE_MAP,
		GATE_SPAWN, Vector2i.DOWN)


## Cases de forêt où rien ne pousse : sous les objets de lisière (posés sur la forêt).
func _taken() -> Dictionary:
	var rules: GDScript = _kit.get(&"rules")
	var taken: Dictionary = {}
	for entry: Array in EDGE_PROPS:
		for offset: Vector2i in rules.call(&"footprint", StringName(entry[0])):
			taken[(entry[1] as Vector2i) + offset] = true
	return taken


func _place_props(entities: Node2D) -> void:
	var tile := float(Kit.TILE)
	var rock: Node2D = _kit.call(&"add_prop", entities, "prop_grande_pierre_01",
		ROCK_FOOT * tile, "BigRock")
	rock.scale = Vector2(ROCK_SCALE, ROCK_SCALE)
	_kit.call(&"flip", rock, true)
	_kit.call(&"clear_footprint", rock)
	var index := 0
	for entry: Array in RUBBLE:
		var stone: Node2D = _kit.call(&"add_prop", entities, entry[0],
			(entry[1] as Vector2) * tile, "Rubble%d" % index)
		index += 1
		stone.scale = Vector2(entry[2], entry[2])
		stone.modulate = Color(RUBBLE_VALUE, RUBBLE_VALUE, RUBBLE_VALUE)
		_kit.call(&"flip", stone, entry[3])
		_kit.call(&"clear_footprint", stone)
	_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell("panneau_route"), "SignRoute")
	var tint: Color = _kit.call(&"forest_tint")
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	for entry: Array in EDGE_PROPS:
		var prop: Node2D = _kit.call(&"add_prop_at", entities, entry[0], entry[1], entry[2])
		_kit.call(&"flip", prop, decor.randf() < 0.5)
		prop.modulate = tint
	_place_bushes(entities, decor, tint)


## Un buisson par case `x` (haie du détour) : les trois images mélangées, jamais la même que la
## voisine de gauche ou du dessus, miroir, taille et teinte variées.
func _place_bushes(entities: Node2D, decor: RandomNumberGenerator, tint: Color) -> void:
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
		var scale := decor.randf_range(0.95, 1.15)
		bush.scale = Vector2(scale, scale)
		var value := decor.randf_range(0.92, 1.05)
		bush.modulate = Color(value, value, value) * tint
