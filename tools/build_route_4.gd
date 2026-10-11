extends SceneTree
## Construit game/world/maps/route_4.tscn (sas de la Route 4, 24 × 14 cases) d'après la grille
## fonctionnelle `tools/plans/route_4_sas.txt` (jalon 12 T8, docs/tech/jalon-12.md §2.1, §2.15 ;
## dossier 15 §14). Identifiant `route_4` dès le J12 : le J13 remplacera le sas par la vraie
## Route 4 **en gardant le repère de coordonnées et le point d'arrivée (3, 6)** (§0.2 n° 15).
##
##   godot --headless --path . -s res://tools/build_route_4.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##
## - `Ground` (invisible) = source logique : `.` herbe, `=` chemin, `D` bouche de la grotte,
##   `e` raccord est ; tout le reste (paroi `#`, rochers `o`, blocs de lisière `b`, rebord du
##   versant `~`) est solide.
## - Image : sol peint (roche au pied de la paroi qui cède à l'herbe vers l'est, chemin), paroi
##   d'ardoise (série 14, froide) en modules, bouche de la grotte (`relief_entree_grotte_01`
##   réduite, couche du sol, dans la paroi ouest), rochers bleutés, blocs de lisière (buissons et
##   rochers), rebord du versant (`relief_falaise_01`) : la plaine en contrebas, panneau (décor ;
##   texte au T28), touffes.
## - Passages : bouche (2, 6) STEP_ON ← → `mt_moon_b2f` / `arrivee_s` (carte du T9) ; raccord est
##   (23, 6..7) PUSH → « AZURIA — À venir » (build de développement ; en release, bord bloqué),
##   retour sur la case même, tourné ←. Spawn `from_mt_moon` (3, 6) : arrivée de B2F, tourné →.
## - Aucun Dresseur, aucune herbe haute, aucun objet ; déclencheur `route_4_reached` au T28.

const Kit := preload("res://tools/pewter_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_4_sas.txt"
const OUT_PATH: String = "res://game/world/maps/route_4.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_4_ground.png"
const ROCK_TEXTURE: String = "res://assets/world/ground/ground_roche_01.png"
const SIZE := Vector2i(24, 14)
const SEED: int = 2401
const DECOR_SEED: int = 2402
const PAROI_SEED: int = 2403

const MAP_ID: StringName = &"route_4"
const DISPLAY_NAME: String = "Route 4"
const REGION: String = "Mont Sélénite — Azuria"
const WALKABLE: String = ".=De"

const MOUTH := Vector2i(2, 6)
const B2F_MAP: StringName = &"mt_moon_b2f"
const B2F_SPAWN: StringName = &"arrivee_s"
const ARRIVAL := Vector2i(3, 6)
const ARRIVAL_SPAWN: String = "from_mt_moon"
## Raccord est : [nœud, case, spawn de retour].
const EAST_EXITS: Array = [
	["CeruleanN", Vector2i(23, 6), "from_cerulean_n"],
	["CeruleanS", Vector2i(23, 7), "from_cerulean_s"],
]
const CERULEAN_SOON: String = "Azuria"
## Bouche de la grotte : l'entrée de la Route 3 réduite, centrée sur la case `D`, au sol (sous
## le joueur qui y entre par l'est).
const MOUTH_SCALE: float = 0.62
const SLATE := {
	"faces": ["relief_paroi_ardoise_01", "relief_paroi_ardoise_02"],
	"mass": "relief_paroi_ardoise_04", "slope": "relief_paroi_ardoise_03",
	"tint": Color(0.86, 0.91, 1.0),
}
const ROCK_TINT := Color(0.8, 0.85, 0.95)
## Rebord du versant : modules de falaise tous les 4 cases sur la rangée haute du `~`.
const LEDGE_ROW: int = 12
const LEDGE_STEP: int = 4
## Sol : roche franche au pied de la paroi, herbe à partir de [constant ROCK_UNTIL_X].
const ROCK_UNTIL_X: float = 12.0
const BUSH_IDS: Array[String] = [
	"prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg",
]
const MEADOW_ATTEMPTS: int = 160
const FLOWERS: Array[int] = [1, 3]

var _kit: Object


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_4 : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE, "#", "")
	_kit.call(&"make_root", "Route4", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour", "")
	_kit.call(&"make_shade", 0.95, 1.02, 1.0)
	# Sous la paroi : roche (aucun vert entre les modules d'ardoise).
	var paved: Dictionary = _kit.get(&"paved_cells")
	for cell: Vector2i in _kit.get(&"cliff_cells"):
		paved[cell] = true
	if not _kit.call(&"add_ground", MASK_PATH, {}, _vary_mask):
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
	_place_ledge(decals)
	_place_rocks_and_edge(entities)
	_kit.call(&"add_prop_at", entities, "prop_panneau_01", _plan().call(&"cell_of",
		"panneau_route_4"), "SignRoute4")

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_4 :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_4 : %s (%d entités, %d au sol dont %d modules de paroi, %d nœuds)"
		% [error_string(result.x), counts.x, counts.y, modules, result.y])
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _add_passages() -> void:
	_kit.call(&"add_spawn", ARRIVAL_SPAWN, ARRIVAL)
	_kit.call(&"add_warp", "MtMoonB2F", MOUTH, Kit.STEP_ON, Vector2i.LEFT, B2F_MAP, B2F_SPAWN,
		Vector2i.DOWN)
	for entry: Array in EAST_EXITS:
		_kit.call(&"add_spawn", entry[2], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.RIGHT, &"",
			StringName(entry[2]), Vector2i.LEFT, CERULEAN_SOON)


## Roche au pied de la paroi qui cède à l'herbe vers l'est (graine fixe).
func _vary_mask(image: Image) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 7
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if _plan().call(&"at", cell) != ".":
				continue
			var color := image.get_pixelv(cell)
			var t := clampf(1.0 - float(x - 3) / (ROCK_UNTIL_X - 3.0), 0.0, 1.0)
			color.r = clampf(t * rng.randf_range(0.75, 1.15), 0.0, 1.0)
			image.set_pixelv(cell, color)


## Rebord du versant (`~`) : falaises basses sur la rangée haute ; la rangée du bas = la plaine.
func _place_ledge(decals: Node2D) -> void:
	var cells: Array[Vector2i] = _plan().call(&"cells_of", "~")
	var first := SIZE.x
	for cell: Vector2i in cells:
		first = mini(first, cell.x)
	var index := 0
	var x := first + 2
	while x - 2 < SIZE.x:
		_kit.call(&"add_prop_at", decals, "relief_falaise_01", Vector2i(x, LEDGE_ROW),
			"Ledge%02d" % index)
		index += 1
		x += LEDGE_STEP


## Rochers `o` (réduits, bleutés) et blocs de lisière `b` (buissons et rochers en alternance).
func _place_rocks_and_edge(entities: Node2D) -> void:
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var tint: Color = _kit.call(&"forest_tint")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "o"):
		_rock(entities, cell, decor, "Rock%02d" % index)
		index += 1
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "b"):
		if index % 3 == 1:
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
