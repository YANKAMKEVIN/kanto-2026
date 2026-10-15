extends SceneTree
## Construit les cartes de QA **provisoires** du voile d'obscurité et de Flash (jalon 17 T10,
## docs/tech/jalon-17.md §2.17 ; **retirées à la clôture, T28**) d'après les grilles
## `tools/plans/qa_flash.txt` et `qa_flash_entry.txt` (elles font foi), sur la boîte à outils
## `tools/cave_map_kit.gd` (J12) :
##
##   godot --headless --path . -s res://tools/build_qa_flash.gd
##   godot --headless --path . --import
##   (première fois, ou si un masque change : relancer l'outil après l'import ; code 2 = masque
##   ou voile écrit, importer puis relancer)
##
## - `qa_flash` (32 × 16) : grotte **obscure** (`data/world/caves.json`, « dark »), sol calme,
##   gravats (sans table de rencontres), rochers, deux masses, une lampe (halo `lamp` qui perce
##   le voile), le voile de pénombre précalculé du J12 (`tools/cave_shade.gd`, réglages du 1F du
##   Mont Sélénite) sous le voile d'obscurité ; randonneur immobile dans
##   `data/npcs/qa_flash.json`.
## - `qa_flash_entry` (12 × 8) : pièce éclairée hors de toute grotte (pas de voile), deux
##   lampes ; passage ↑ vers la grotte.
## Racines extérieures (`interior = false`), profil `cave_1f`.

const Kit := preload("res://tools/cave_map_kit.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const TILE: int = 96
const PROFILE: StringName = &"cave_1f"
## Carte → [grille, nœud racine, nom affiché, taille, graine logique, graine du décor].
const MAPS: Dictionary = {
	&"qa_flash": ["res://tools/plans/qa_flash.txt", "QaFlash", "QA Flash", Vector2i(32, 16),
		1701, 1702],
	&"qa_flash_entry": ["res://tools/plans/qa_flash_entry.txt", "QaFlashEntry",
		"QA Flash (entrée)", Vector2i(12, 8), 1711, 1712],
}
## Passages : carte → [position de la grille, carte cible, arrivée (préfixe : `_w`, `_e`),
## pas qui déclenche, orientation à l'arrivée].
const PASSAGES: Dictionary = {
	&"qa_flash": ["entree", &"qa_flash_entry", "from_qa_flash", Vector2i.DOWN, Vector2i.DOWN],
	&"qa_flash_entry": ["sortie", &"qa_flash", "from_qa_flash_entry", Vector2i.UP, Vector2i.UP],
}
## Arrivées : carte → position de la grille des points d'apparition.
const ARRIVALS: Dictionary = {
	&"qa_flash": "from_qa_flash_entry",
	&"qa_flash_entry": "from_qa_flash",
}
const LAMP_LIGHT_HEIGHT: float = 62.0
## Voile de pénombre : réglages du 1F du Mont Sélénite (`tools/build_mt_moon.gd`).
const SHADE: Dictionary = {"ambient": 0.95, "edge_min": 0.55, "edge_radius": 0.8,
	"room_min": 0.87, "room_radius": 3.2, "tint": Color(0.80, 0.88, 1.0)}
const SHADE_LIGHTS: Dictionary = {
	&"lamp": {"radius": 3.4, "strength": 0.95, "offset": Vector2(0.0, 40.0), "add": 0.15,
		"color": Color(1.0, 0.78, 0.5)},
}
const SHADE_WALL_FOLLOW: float = 0.7

var _kit: Object


func _init() -> void:
	var code := 0
	for map_id: StringName in MAPS:
		code = maxi(code, _build(map_id))
	quit(code)


## 0 : enregistré ; 2 : masque ou voile écrit, importer puis relancer ; 1 : erreur.
func _build(map_id: StringName) -> int:
	var spec: Array = MAPS[map_id]
	_kit = Kit.new(spec[0], spec[3], spec[4], spec[5])
	if not _errors().is_empty():
		push_error("build_qa_flash %s : %s" % [map_id, _errors()])
		return 1
	_kit.call(&"make_root", spec[1], map_id, spec[2], PROFILE)
	if not _kit.call(&"add_ground", "res://assets/world/maps/%s_ground.png" % map_id):
		if not _errors().is_empty():
			push_error("build_qa_flash %s :\n%s" % [map_id, "\n".join(_errors())])
			_kit.call(&"discard")
			return 1
		print("build_qa_flash %s : masque écrit ; importer (--import) puis relancer" % map_id)
		_kit.call(&"discard")
		return 2
	var walls: Vector3i = _kit.call(&"place_walls", spec[5] + 7)
	_place_landmarks()
	_place_passage(map_id)
	var shade := "res://assets/world/maps/%s_shade.png" % map_id
	if _errors().is_empty() and not _kit.call(&"add_shade", shade, SHADE, SHADE_LIGHTS,
			SHADE_WALL_FOLLOW):
		if _errors().is_empty():
			print("build_qa_flash %s : voile écrit ; importer (--import) puis relancer" % map_id)
			_kit.call(&"discard")
			return 2
	if not _errors().is_empty():
		push_error("build_qa_flash %s :\n%s" % [map_id, "\n".join(_errors())])
		_kit.call(&"discard")
		return 1
	var glows: int = _kit.call(&"glow_count")
	var result: Vector2i = _kit.call(&"save", MAPS_DIR + String(map_id) + ".tscn")
	print("%s : %s (parois %d faces / %d bords / %d lèvres, %d halos, %d nœuds)" % [map_id,
		error_string(result.x), walls.x, walls.y, walls.z, glows, result.y])
	return 0 if result.x == OK else 1


func _errors() -> PackedStringArray:
	return _kit.get(&"errors")


func _plan() -> Object:
	return _kit.get(&"plan")


func _place_landmarks() -> void:
	var entities: Node2D = _kit.get(&"entities")
	var index := 0
	for cell: Vector2i in _plan().call(&"cells_of", "o"):
		_kit.call(&"add_prop_at", entities, "prop_rocher_grotte_0%d" % (1 + index % 2), cell,
			"Rock%02d" % index)
		index += 1
	index = 0
	for cell: Vector2i in _plan().call(&"cells_of", "L"):
		var foot := Vector2((cell.x + 0.5) * TILE, (cell.y + 1) * TILE)
		_kit.call(&"add_prop_at", entities, "prop_lampe_chantier_01", cell, "Lamp%d" % index)
		_kit.call(&"add_glow", &"lamp", foot - Vector2(0.0, LAMP_LIGHT_HEIGHT),
			"GlowLamp%d" % index)
		index += 1


func _place_passage(map_id: StringName) -> void:
	var named: Dictionary = Kit.spawn_names(ARRIVALS[map_id],
		_plan().call(&"cells_at", ARRIVALS[map_id]))
	for spawn_name: String in named:
		_kit.call(&"add_spawn", spawn_name, named[spawn_name])
	var passage: Array = PASSAGES[map_id]
	var cells: Array[Vector2i] = []
	cells.assign(_plan().call(&"cells_at", passage[0]))
	var targets: Dictionary = Kit.spawn_names(passage[2], cells)
	for spawn_name: String in targets:
		_kit.call(&"add_warp", "To_%s" % spawn_name, targets[spawn_name], Kit.STEP_ON,
			passage[3], passage[1], StringName(spawn_name), passage[4])
