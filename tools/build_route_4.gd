extends SceneTree
## Construit game/world/maps/route_4.tscn (la **vraie** Route 4, 64 × 24 cases) d'après la grille
## fonctionnelle `tools/plans/route_4.txt` (jalon 13 T8, docs/tech/jalon-13.md §2.1, §2.2 ;
## dossier 16 §3). Réécriture de l'outil du sas du J12 (`tools/plans/route_4_sas.txt`, 24 × 14) :
## **même identifiant `route_4`, même repère** — colonnes 0–23 et rangées 0–13 aux mêmes
## coordonnées, bouche de la grotte (2, 6), arrivée `from_mt_moon` (3, 6), panneau (6, 5) — pour
## qu'une partie sauvegardée dans le sas retombe sur une case praticable (`test_route_4_resume`).
##
##   godot --headless --path . -s res://tools/build_route_4.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## **La grille fait foi** ; la vue générale (`docs/design/reference/route-4-vue-generale-v1.png`)
## donne la DA, avec les deux corrections validées : le rebord est en **roche ardoise** du versant
## et **net, sans planche** au passage du chemin.
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` chemin, `h` hautes herbes, `v` rebord
##   (`LEDGE_DOWN` : saut vers le sud seulement), `D` bouche de la grotte, `e` raccord est ; le
##   reste (paroi `#`, versant `~`, forêt `T`, rochers `o`, buissons `b`) est solide.
## - Image : sol peint (roche au pied de la paroi, qui cède à l'herbe vers l'est du plateau ;
##   chemin), paroi d'ardoise (série 14, froide) en modules, bouche de la grotte, versant `~` en
##   falaises d'ardoise (`relief_falaise_ardoise_01/02`), rebord en modules `relief_rebord_ardoise_01`,
##   forêt serrée, rochers bleutés et buissons des cases `o` et `b`, panneau, touffes, hautes herbes jaune-vert.
## - Passages : bouche (2, 6) STEP_ON ← → `mt_moon_b2f` / `arrivee_s` ; raccord est (63, 19..21)
##   PUSH → vers Azuria (`cerulean_city`, spawns `from_route_4_n|c|s`, tournée →), retour sur les
##   spawns `from_cerulean_n|c|s` de cette carte, tournés ←. Plus de « AZURIA — À venir ».
## - Cases des PNJ (Clara), de l'objet (Poké Ball), des herbes : **réservées** d'après les
##   positions de la grille (la forêt s'en écarte) ; la vie (Dresseuse, objet,
##   table `route_4_grass`) vient des données du T17.
## - Vie du sas (J12 T28, gardée à la fusion de `main`) : panneau examinable de face (↑ depuis
##   (6, 6)) → dialogue `route_4_sign` ; déclencheur silencieux `route_4_reached` sur (4, 5..9),
##   toute direction (objectif « continuer vers Azuria. »).

const Kit := preload("res://tools/pewter_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_4.txt"
const OUT_PATH: String = "res://game/world/maps/route_4.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_4_ground.png"
const ROCK_TEXTURE: String = "res://assets/world/ground/ground_roche_01.png"
const SIZE := Vector2i(64, 24)
const SEED: int = 2401
const DECOR_SEED: int = 2402
const PAROI_SEED: int = 2403
const FOREST_SEED: int = 2404

const MAP_ID: StringName = &"route_4"
const DISPLAY_NAME: String = "Route 4"
const REGION: String = "Mont Sélénite — Azuria"
const WALKABLE: String = ".=hvDe"
## Positions de la grille dont la case est réservée (la forêt s'en écarte).
const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
const BALL_KINDS: Array[String] = ["objet_visible", "cache"]

const MOUTH := Vector2i(2, 6)
const B2F_MAP: StringName = &"mt_moon_b2f"
const B2F_SPAWN: StringName = &"arrivee_s"
const ARRIVAL := Vector2i(3, 6)
const ARRIVAL_SPAWN: String = "from_mt_moon"
## Raccord est : [nœud, case, spawn de retour (cette carte), spawn d'arrivée d'Azuria]. Trois
## cases, un spawn par rangée (comme Argenta / Route 3) : le joueur ressort sur la même rangée.
const EAST_MAP: StringName = &"cerulean_city"
const EAST_EXITS: Array = [
	["CeruleanN", Vector2i(63, 19), "from_cerulean_n", &"from_route_4_n"],
	["CeruleanC", Vector2i(63, 20), "from_cerulean_c", &"from_route_4_c"],
	["CeruleanS", Vector2i(63, 21), "from_cerulean_s", &"from_route_4_s"],
]
const SIGN_DIALOGUE: StringName = &"route_4_sign"
## Déclencheur `route_4_reached` (J12 T28) : ancre bas-gauche (4, 9), 1 × 5 cases → (4, 5..9).
const REACHED_ANCHOR := Vector2i(4, 9)
const REACHED_SIZE := Vector2i(1, 5)
const REACHED_CUTSCENE: StringName = &"route_4_reached"
## Bouche de la grotte : l'entrée de la Route 3 réduite, centrée sur la case `D`, au sol (sous
## le joueur qui y entre par l'est).
const MOUTH_SCALE: float = 0.62
const SLATE := {
	"faces": ["relief_paroi_ardoise_01", "relief_paroi_ardoise_02"],
	"mass": "relief_paroi_ardoise_04", "slope": "relief_paroi_ardoise_03",
	"tint": Color(0.86, 0.91, 1.0),
}
const ROCK_TINT := Color(0.8, 0.85, 0.95)
## Versant (`~`, rangées 12 et 13, colonnes 3 à 27) : falaises d'ardoise bout à bout, pied sur le
## bas de la rangée 13 ; le rebord (`v`, rangée 12, colonnes 28 à 33) : modules d'une case et demie.
const CLIFF_IDS: Array[String] = ["relief_falaise_ardoise_01", "relief_falaise_ardoise_02"]
const CLIFF_FROM_X: int = 3
const CLIFF_TO_X: int = 28
const CLIFF_FOOT_ROW: int = 14
const CLIFF_COUNT: int = 7
const CLIFF_OVERLAP: float = 1.1
const LEDGE_ID: String = "relief_rebord_ardoise_01"
const LEDGE_ROW: int = 12
## Sol du plateau : roche franche au pied de la paroi, herbe à partir de [constant ROCK_UNTIL_X].
const ROCK_UNTIL_X: float = 12.0
const PLATEAU_ROWS: int = 12
const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
const SHADE_VALUE: float = 0.95
const SHADE_RED: float = 1.02
const SHADE_BLUE: float = 1.0
const MEADOW_ATTEMPTS: int = 420
const FLOWERS: Array[int] = [1, 3]

var _kit: Object


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_4 : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE, "#", "")
	_reserve_positions()
	_kit.call(&"make_root", "Route4", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour", "")
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	# Sous la paroi : roche (aucun vert entre les modules d'ardoise).
	var paved: Dictionary = _kit.get(&"paved_cells")
	for cell: Vector2i in _kit.get(&"cliff_cells"):
		paved[cell] = true
	if not _kit.call(&"add_ground", MASK_PATH, _undergrowth(), _vary_mask):
		print("build_route_4 : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var root: Node2D = _kit.get(&"root")
	var ground := root.get_node(^"PaintedGround")
	ground.set(&"r_texture", load(ROCK_TEXTURE))
	(ground.get(&"material") as ShaderMaterial).set_shader_parameter(&"paving_scale", 1.0)
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()

	_kit.call(&"place_border_decals", SEED)
	_kit.call(&"place_meadow", MEADOW_ATTEMPTS, 0.12, FLOWERS)
	var modules: int = _kit.call(&"place_paroi", PAROI_SEED,
		func(_column: float) -> Dictionary: return SLATE)
	var mouth: Node2D = _kit.call(&"add_prop", decals, "relief_entree_grotte_01",
		Vector2(MOUTH.x + 0.5, MOUTH.y + 1.0) * Kit.TILE, "CaveMouth")
	_kit.call(&"clear_footprint", mouth)
	mouth.scale = Vector2(MOUTH_SCALE, MOUTH_SCALE)
	mouth.modulate = SLATE["tint"]
	_place_cliff(decals)
	_place_ledge(decals)
	_place_rocks_and_edge(entities)
	_kit.call(&"add_prop_at", entities, "prop_panneau_01", _plan().call(&"cell_of",
		"panneau_route_4"), "SignRoute4")
	_kit.call(&"place_tall_grass")
	var feet: Array[Vector2] = []
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, {})
	_add_life()

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_4 :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_4 : %s (%d entités, %d au sol dont %d modules de paroi, forêt %d → %d, "
		% [error_string(result.x), counts.x, counts.y, modules, forest.x, forest.y]
		+ "%d nœuds)" % result.y)
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


## Cases des positions de la grille (Dresseuse, objet, herbes) : réservées.
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


## Sous-bois sur la forêt `T` seulement (le pied de la paroi reste de la roche).
func _undergrowth() -> Dictionary:
	var values: Dictionary = {}
	for cell: Vector2i in _kit.get(&"forest_cells"):
		values[cell] = 1.0
	return values


func _add_passages() -> void:
	_kit.call(&"add_spawn", ARRIVAL_SPAWN, ARRIVAL)
	_kit.call(&"add_warp", "MtMoonB2F", MOUTH, Kit.STEP_ON, Vector2i.LEFT, B2F_MAP, B2F_SPAWN,
		Vector2i.DOWN)
	for entry: Array in EAST_EXITS:
		_kit.call(&"add_spawn", entry[2], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.RIGHT, EAST_MAP,
			StringName(entry[3]), Vector2i.RIGHT)


## Point d'examen du panneau (lu de face) et déclencheur silencieux de l'objectif (T28).
func _add_life() -> void:
	_kit.call(&"add_interactable", "SignRoute4Read", _plan().call(&"cell_of", "panneau_route_4"),
		Vector2i.ONE, Vector2i.UP, SIGN_DIALOGUE)
	_kit.call(&"add_trigger", "Route4Reached", REACHED_ANCHOR, REACHED_SIZE, Vector2i.ZERO,
		REACHED_CUTSCENE)


## Roche au pied de la paroi qui cède à l'herbe vers l'est (plateau seulement ; graine fixe).
func _vary_mask(image: Image) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 7
	for y: int in PLATEAU_ROWS:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if _plan().call(&"at", cell) != ".":
				continue
			var color := image.get_pixelv(cell)
			var t := clampf(1.0 - float(x - 3) / (ROCK_UNTIL_X - 3.0), 0.0, 1.0)
			color.r = clampf(t * rng.randf_range(0.75, 1.15), 0.0, 1.0)
			image.set_pixelv(cell, color)


## Versant (`~`) : [constant CLIFF_COUNT] falaises d'ardoise bout à bout, deux modèles en
## alternance, un peu plus larges que leur pas (elles se chevauchent), pied sur le bas de la
## rangée 13 ; elles ne dépassent pas sur le rebord ni au-delà de la colonne [constant CLIFF_TO_X].
func _place_cliff(decals: Node2D) -> void:
	var span := float(CLIFF_TO_X - CLIFF_FROM_X) * Kit.TILE
	var step := span / float(CLIFF_COUNT)
	for index: int in CLIFF_COUNT:
		var id := CLIFF_IDS[index % CLIFF_IDS.size()]
		var foot := Vector2(CLIFF_FROM_X * Kit.TILE + step * (index + 0.5),
			CLIFF_FOOT_ROW * Kit.TILE)
		var piece: Node2D = _kit.call(&"add_prop", decals, id, foot, "Cliff%02d" % index)
		var texture_width := _sprite_width(piece)
		var scale := step * CLIFF_OVERLAP / texture_width
		piece.scale = Vector2(scale, scale)


## Rebord (`v`, une seule bande) : modules d'ardoise de 1,5 case, **nets** (aucune planche au
## passage du chemin), bout à bout sur toute la bande, pied sur le bas de la rangée du rebord.
func _place_ledge(decals: Node2D) -> void:
	var cells: Array[Vector2i] = _plan().call(&"cells_of", "v")
	var first := SIZE.x
	var last := 0
	for cell: Vector2i in cells:
		first = mini(first, cell.x)
		last = maxi(last, cell.x)
	var length := float(last - first + 1) * Kit.TILE
	var probe: Node2D = _kit.call(&"add_prop", decals, LEDGE_ID, Vector2.ZERO, "LedgeProbe")
	var width := _sprite_width(probe)
	probe.free()
	var count := maxi(1, roundi(length / width))
	var step := length / float(count)
	for index: int in count:
		var foot := Vector2(first * Kit.TILE + step * (index + 0.5), (LEDGE_ROW + 1) * Kit.TILE)
		var piece: Node2D = _kit.call(&"add_prop", decals, LEDGE_ID, foot, "Ledge%02d" % index)
		piece.scale = Vector2(step / width, step / width)


func _sprite_width(prop: Node2D) -> float:
	return float((prop.get_node(^"Sprite") as Sprite2D).texture.get_width())


## Rochers `o` (réduits, bleutés) et buissons `b` (buissons et rochers en alternance).
func _place_rocks_and_edge(entities: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var tint: Color = _kit.call(&"forest_tint")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "o"):
		_rock(entities, cell, decor, "Rock%02d" % index)
		index += 1
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "b"):
		if index % 4 == 3:
			_rock(entities, cell, decor, "EdgeRock%02d" % index)
		else:
			var id: String = BUSH_IDS[index % BUSH_IDS.size()]
			var bush: Node2D = _kit.call(&"add_prop_at", entities, id, cell, "Bush%02d" % index)
			_kit.call(&"flip", bush, decor.randf() < 0.5)
			var scale := decor.randf_range(0.95, 1.12)
			bush.scale = Vector2(scale, scale)
			bush.modulate = tint
		index += 1


func _rock(entities: Node2D, cell: Vector2i, decor: RandomNumberGenerator, node: String) -> void:
	var rock: Node2D = _kit.call(&"add_prop", entities, "prop_rocher_01",
		Vector2(cell.x + 0.5, cell.y + 1.0) * Kit.TILE, node)
	_kit.call(&"clear_footprint", rock)
	var scale := decor.randf_range(0.58, 0.68)
	rock.scale = Vector2(scale, scale)
	_kit.call(&"flip", rock, decor.randf() < 0.5)
	rock.modulate = ROCK_TINT
