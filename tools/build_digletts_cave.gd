extends SceneTree
## Construit la Cave Taupiqueur (jalon 17 T15, docs/tech/jalon-17.md §2.1, §2.3 ; dossier 20 §3.3)
## d'après la grille `tools/plans/digletts_cave.txt` (elle fait foi), sur la boîte à outils
## `tools/cave_map_kit.gd` (même méthode que `tools/build_mt_moon.gd`) :
##
##   godot --headless --path . -s res://tools/build_digletts_cave.gd
##   godot --headless --path . --import
##   (première fois, ou si un masque change : relancer l'outil après l'import)
##
## - `Ground` (invisible) = source logique : `.` `E` sol calme, `g` gravats (tuiles `RUBBLE`),
##   tout le reste solide. Racine **extérieure** (`interior = false`) : la catégorie grotte et les
##   deux bouches de la Corde Sortie sont dans `data/world/caves.json` (`escapes`).
## - Image : sol de sable (calme), gravats (canal R), dessus des masses de grès (canal G), parois
##   de grès en modules (série 19 : faces, bord latéral, lèvre), rochers `o`, les deux bouches
##   peintes (au sol : un personnage n'est jamais masqué par la voûte), halos de jour (bouches,
##   renfoncements) et colonnes de lumière. **Aucun voile d'obscurité** (la Cave n'est pas
##   `dark`) ni voile de pénombre : la lisibilité est dans la valeur peinte (profil `cave_sand`).
## - Passages : bouche sud (15..16, 79) `PUSH` ↓ vers la Route 11 (`from_cave_w|e`), bouche nord
##   (16..17, 0) `PUSH` ↑ vers la Route 2 est (`from_cave_w|e`) ; arrivées `from_route_11_w|e`
##   (tournées ↑) et `from_route_2_east_w|e` (tournées ↓). Les deux cartes voisines doivent
##   exister (intégration du J17) : l'outil s'arrête en erreur sinon.
## - Taupiqueur d'ambiance et Corde Sortie du renfoncement R1 (position `cave_item_1`) :
##   `data/npcs/digletts_cave.json`.

const Kit := preload("res://tools/cave_map_kit.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const MAP_ID: StringName = &"digletts_cave"
const ROOT_NAME: String = "DigLettsCave"
const DISPLAY_NAME: String = "Cave Taupiqueur"
const PLAN_PATH: String = "res://tools/plans/digletts_cave.txt"
const SIZE: Vector2i = Vector2i(34, 80)
const LOGIC_SEED: int = 1701
const DECOR_SEED: int = 1702
const PROFILE: StringName = &"cave_sand"
const TILE: int = 96
## Sols de la série 19 (sable calme, dessus des masses de grès) ; les gravats restent ceux de la
## série 14 (terre et cailloux).
const FLOOR_TEXTURE: String = "res://assets/world/ground/ground_sable_grotte_01.png"
const MASS_TEXTURE: String = "res://assets/world/ground/ground_masse_sable_01.png"
const WALKABLE: String = ".gE"
const BORDER_COLOR: Color = Color(0.46, 0.34, 0.2)
## Parois de grès (série 19) : faces (3 cases), bord latéral, lèvre ; les angles 03 et 04 ne sont
## pas posés par le kit (rôle d'angle absent des grilles de grotte).
const WALL_FACES: Array[String] = ["relief_paroi_sable_01", "relief_paroi_sable_02"]
const WALL_SIDE: String = "relief_paroi_sable_05"
const WALL_LIP: String = "relief_paroi_sable_06"
## Bouches vues de l'intérieur (série 19) : image, pied (case d'ancrage `ALIGN_EDGE`, coordonnée
## y du pied en cases) ; la voûte est posée dans la couche du sol.
const MOUTH_SOUTH: String = "relief_bouche_cave_sud_01"
const MOUTH_NORTH: String = "relief_bouche_cave_nord_01"
const MOUTH_SOUTH_FOOT_ROW: float = 80.0
const MOUTH_NORTH_FOOT_ROW: float = 2.0
## Passages : [nœud, case, spawn d'arrivée ici, direction du pas, carte, spawn d'arrivée là-bas].
const MOUTHS: Array = [
	["WarpSouthW", Vector2i(15, 79), "from_route_11_w", Vector2i.DOWN, &"route_11",
		&"from_cave_w"],
	["WarpSouthE", Vector2i(16, 79), "from_route_11_e", Vector2i.DOWN, &"route_11",
		&"from_cave_e"],
	["WarpNorthW", Vector2i(16, 0), "from_route_2_east_w", Vector2i.UP, &"route_2_east",
		&"from_cave_w"],
	["WarpNorthE", Vector2i(17, 0), "from_route_2_east_e", Vector2i.UP, &"route_2_east",
		&"from_cave_e"],
]
## Halos de jour aux bouches : [centre en cases, nom].
const SHAFTS: Array = [
	[Vector2(16.0, 79.0), "Mouth South"],
	[Vector2(17.0, 0.9), "Mouth North"],
]
## Puits de lumière posés par le jeu (rais, dossier 20 : « rais de lumière ajoutés par le jeu »),
## centre en cases : renfoncements R1 et R2 et salles d'entrée et du nord.
const RAYS: Array = [
	Vector2(3.5, 44.0), Vector2(26.5, 26.0), Vector2(15.5, 72.0), Vector2(16.5, 3.0),
]
const BEAM_FOOT_SHARE: float = 0.6

var _kit: Object


func _init() -> void:
	var code := _build()
	quit(code)


## 0 : enregistré ; 2 : masque écrit, importer puis relancer ; 1 : erreur.
func _build() -> int:
	_kit = Kit.new(PLAN_PATH, SIZE, LOGIC_SEED, DECOR_SEED, WALKABLE)
	if not _errors().is_empty():
		push_error("build_digletts_cave : %s" % _errors())
		return 1
	_kit.set(&"floor_texture_path", FLOOR_TEXTURE)
	_kit.set(&"mass_texture_path", MASS_TEXTURE)
	_kit.set(&"border_color", BORDER_COLOR)
	_kit.set(&"wall_faces", WALL_FACES.duplicate())
	_kit.set(&"wall_side", WALL_SIDE)
	_kit.set(&"wall_lip", WALL_LIP)
	_kit.call(&"make_root", ROOT_NAME, MAP_ID, DISPLAY_NAME, PROFILE)
	var mask := "res://assets/world/maps/%s_ground.png" % MAP_ID
	if not _kit.call(&"add_ground", mask):
		if not _errors().is_empty():
			push_error("build_digletts_cave :\n%s" % "\n".join(_errors()))
			_kit.call(&"discard")
			return 1
		print("build_digletts_cave : masque écrit ; importer (--import) puis relancer")
		_kit.call(&"discard")
		return 2
	var walls: Vector3i = _kit.call(&"place_walls", DECOR_SEED + 7)
	_place_rocks()
	_place_mouths()
	_place_spawns_and_warps()
	_place_lights()
	if not _errors().is_empty():
		push_error("build_digletts_cave :\n%s" % "\n".join(_errors()))
		_kit.call(&"discard")
		return 1
	var counts := Vector3i((_kit.get(&"entities") as Node).get_child_count(),
		(_kit.get(&"decals") as Node).get_child_count(), _kit.call(&"glow_count"))
	var result: Vector2i = _kit.call(&"save", MAPS_DIR + String(MAP_ID) + ".tscn")
	print("%s : %s (%d entités, %d au sol, parois %d faces / %d bords / %d lèvres, %d halos, "
		% [MAP_ID, error_string(result.x), counts.x, counts.y, walls.x, walls.y, walls.z,
		counts.z] + "%d nœuds)" % result.y)
	return 0 if result.x == OK else 1


func _errors() -> PackedStringArray:
	return _kit.get(&"errors")


func _plan() -> Object:
	return _kit.get(&"plan")


func _rng() -> RandomNumberGenerator:
	return _kit.get(&"decor_rng")


# --- Repères ------------------------------------------------------------------------------


## Rochers isolés `o` : sprite seul (la case est déjà bloquée par la grille), valeur et miroir
## variés (graine du décor).
func _place_rocks() -> void:
	var entities: Node2D = _kit.get(&"entities")
	var rules: GDScript = _kit.get(&"rules")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "o"):
		var id := "prop_rocher_grotte_0%d" % (1 + index % 2)
		var sprite: Sprite2D = _kit.call(&"add_sprite", entities,
			id, rules.call(&"foot_position", StringName(id), cell), "Rock%02d" % index)
		var value := _rng().randf_range(0.92, 1.08)
		sprite.modulate = Color(value, value, value)
		sprite.flip_h = _rng().randf() < 0.5
		index += 1


## Les deux voûtes (couche du sol, sous les personnages), centrées sur la paire de cases de la
## bouche (`ALIGN_EDGE`).
func _place_mouths() -> void:
	var decals: Node2D = _kit.get(&"decals")
	var south: Node2D = _kit.call(&"add_prop", decals, MOUTH_SOUTH,
		Vector2(16 * TILE, MOUTH_SOUTH_FOOT_ROW * TILE), "MouthSouth")
	south.set(&"footprint", [] as Array[Vector2i])
	var north: Node2D = _kit.call(&"add_prop", decals, MOUTH_NORTH,
		Vector2(17 * TILE, MOUTH_NORTH_FOOT_ROW * TILE), "MouthNorth")
	north.set(&"footprint", [] as Array[Vector2i])


# --- Passages -----------------------------------------------------------------------------


func _place_spawns_and_warps() -> void:
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		if positions[id]["kind"] == "spawn":
			var named: Dictionary = Kit.spawn_names(id, _plan().call(&"cells_at", id))
			for spawn_name: String in named:
				_kit.call(&"add_spawn", spawn_name, named[spawn_name])
	for mouth: Array in MOUTHS:
		var target: StringName = mouth[4]
		assert(ResourceLoader.exists(MAPS_DIR + String(target) + ".tscn"),
			"digletts_cave : carte voisine « %s » absente" % target)
		_kit.call(&"add_warp", mouth[0], mouth[1], Kit.PUSH, mouth[3], target, mouth[5],
			Vector2i.DOWN)


# --- Lumière ------------------------------------------------------------------------------


## Halos de jour aux deux bouches (flaque douce + colonne) et rais de lumière dans les salles et
## les renfoncements. Pas de voile : la grille de budget est celle des halos (≤ 16).
func _place_lights() -> void:
	var index := 0
	for shaft: Array in SHAFTS:
		var center: Vector2 = (shaft[0] as Vector2) * TILE
		_kit.call(&"add_glow", &"shaft", center, "GlowMouth%d" % index)
		_kit.call(&"add_glow", &"beam", center, "BeamMouth%d" % index)
		index += 1
	index = 0
	for ray: Vector2 in RAYS:
		var center := ray * TILE
		_kit.call(&"add_glow", &"shaft", center, "GlowRay%d" % index)
		_kit.call(&"add_glow", &"beam", center + Vector2(0.0, TILE * BEAM_FOOT_SHARE),
			"BeamRay%d" % index)
		index += 1
