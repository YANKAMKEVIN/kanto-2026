class_name CaveLibrary
extends RefCounted
## Grottes de Kanto, lues dans `data/world/caves.json` (docs/tech/jalon-12.md §2.3) : cartes de
## chaque grotte et sortie de la Corde Sortie. Classe pure, sans nœud.
##
## Catégorie « grotte » (dossier 15 §13) : ni bâtiment ni extérieur à ciel ouvert. Une carte de
## grotte garde `GameMap.interior = false` (compagnon visible, titre de zone, préchargement
## des voisines) ; la catégorie se lit **ici seulement**, comme `interiors.json` pour les
## bâtiments : rien dans `GameMap`. Usages : Corde Sortie permise ([method escape_target]),
## phrase « grotte » du compagnon (données du J11), pas de ciel ([method has_sky], jour/nuit de
## la phase 10).
## [codeblock]
## { "caves": { "mt_moon": {
##     "maps": ["mt_moon_1f", "mt_moon_b1f", "mt_moon_b2f"],
##     "escape": { "map": "route_3", "spawn": "from_mt_moon_w", "facing": "down" } } } }
## [/codeblock]
## Racine : « caves » et « _doc » (texte libre, ignoré, comme `interiors.json`).
## Clés d'une grotte : « maps » (liste non vide d'identifiants de carte, chacun dans une seule
## grotte) et « escape » (« map » et « spawn » non vides, « facing » nom de direction ; la sortie
## n'est pas une carte de la grotte). Toute clé inconnue est une erreur ; une grotte invalide est
## écartée, l'erreur signalée ([method get_errors], push_error). Que les cartes existent, soient
## extérieures (`interior = false`, absentes de `interiors.json`) et que la sortie ait son point
## d'apparition se vérifie avec les vraies scènes (`test_cave_library`, dès qu'elles existent).
## Clé facultative « dark » (booléen, faux par défaut ; J17 T9 / J18, dossier 21 §5.2) : grotte
## **obscure**, couverte par le voile d'obscurité ([DarknessController]) ; seule source de
## « carte obscure » ([method is_dark]). Le Mont Sélénite n'en a pas.
## **Plusieurs bouches** (jalon 17, jalon-17.md §2.3, dossier 20 §12) : à la place de « escape »
## (exclusives), « escapes » est une liste non vide de sorties qui portent chacune « rows »
## ([première, dernière] rangée, entiers ≥ 0, comprises) ; les plages ne se chevauchent pas. La
## Corde Sortie ramène à la sortie dont la plage contient la rangée du joueur (même plage sur
## chaque carte de la grotte). Que les plages couvrent toute la hauteur de la carte se vérifie
## avec la vraie scène.
## [codeblock]
## "digletts_cave": { "maps": ["digletts_cave"], "escapes": [
##     { "rows": [0, 39], "map": "route_2_east", "spawn": "from_cave_w", "facing": "down" },
##     { "rows": [40, 79], "map": "route_11", "spawn": "from_cave_w", "facing": "down" } ] }
## [/codeblock]

const DATA_PATH: String = "res://data/world/caves.json"
const _ROOT_KEYS: Array[String] = ["_doc", "caves"]
const _CAVE_KEYS: Array[String] = ["maps", "escape", "escapes", "dark"]
const _ESCAPE_KEYS: Array[String] = ["map", "spawn", "facing"]
const _ESCAPES_KEYS: Array[String] = ["map", "spawn", "facing", "rows"]
## Case du joueur inconnue ([method escape_target]).
const NO_CELL: Vector2i = Vector2i(-1, -1)

## Carte → grotte.
var _cave_of: Dictionary[StringName, StringName] = {}
## Grotte → cartes (ordre du fichier).
var _maps: Dictionary[StringName, Array] = {}
## Grottes obscures (clé « dark » vraie).
var _dark: Dictionary[StringName, bool] = {}
## Grotte → sorties (Array[CaveExit], ordre du fichier ; une seule avec « escape »).
var _exits: Dictionary[StringName, Array] = {}
var _errors: PackedStringArray = PackedStringArray()


## Vrai si la carte [param map] a un ciel : extérieure ([member GameMap.interior] faux) et pas
## dans une grotte. Une carte nulle n'en a pas ; [param caves] nul : seule la catégorie
## « bâtiment » compte.
static func has_sky(map: GameMap, caves: CaveLibrary) -> bool:
	if map == null or map.interior:
		return false
	return caves == null or not caves.is_cave(map.map_id)


## Charge [param path]. Faux si le fichier est illisible ou contient une erreur (les grottes
## valides sont gardées).
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { \"caves\": { … } } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les grottes d'un objet déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if not _ROOT_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	if not data.get("caves") is Dictionary:
		return _fail("%s : « caves » doit être un objet { grotte: { maps, escape } }" % source)
	var caves: Dictionary = data["caves"]
	for key: Variant in caves:
		var cave := StringName(str(key))
		var where := "%s « %s »" % [source, cave]
		if cave.is_empty():
			ok = _fail("%s : identifiant de grotte vide" % source)
			continue
		if _maps.has(cave):
			ok = _fail("%s : grotte déjà définie" % where)
			continue
		ok = _add_cave(cave, caves[key], where) and ok
	return ok


## Vrai si [param map_id] est une carte de grotte.
func is_cave(map_id: StringName) -> bool:
	return _cave_of.has(map_id)


## Grotte de la carte [param map_id] (&"" hors grotte).
func cave_of(map_id: StringName) -> StringName:
	return _cave_of.get(map_id, &"")


## Vrai si [param map_id] est une carte d'une grotte obscure (« dark » : voile d'obscurité).
func is_dark(map_id: StringName) -> bool:
	return _dark.has(cave_of(map_id))


## Sortie de la grotte de [param map_id] (où mène la Corde Sortie) ; null hors grotte.
## Grotte à plusieurs bouches (« escapes ») : la sortie dont la plage contient la rangée de
## [param cell] (la case du joueur) ; null si [param cell] est inconnue ([constant NO_CELL]) ou
## hors de toute plage. Sortie unique : [param cell] est ignorée.
func escape_target(map_id: StringName, cell: Vector2i = NO_CELL) -> CaveExit:
	var exits: Array = _exits.get(cave_of(map_id), [])
	if exits.size() == 1 and (exits[0] as CaveExit).first_row < 0:
		return exits[0]
	if cell == NO_CELL:
		return null
	for exit: CaveExit in exits:
		if exit.covers_row(cell.y):
			return exit
	return null


## Toutes les sorties de la grotte [param cave] (ordre du fichier ; vide si elle est inconnue).
func get_exits(cave: StringName) -> Array[CaveExit]:
	var exits: Array[CaveExit] = []
	exits.assign(_exits.get(cave, []))
	return exits


## Cartes de la grotte [param cave] (ordre du fichier ; vide si elle est inconnue).
func get_maps(cave: StringName) -> Array[StringName]:
	var maps: Array[StringName] = []
	maps.assign(_maps.get(cave, []))
	return maps


## Identifiants des grottes, dans l'ordre du fichier.
func get_caves() -> Array[StringName]:
	var caves: Array[StringName] = []
	caves.assign(_maps.keys())
	return caves


## Toutes les cartes de grotte (ordre des grottes puis du fichier).
func get_all_maps() -> Array[StringName]:
	var maps: Array[StringName] = []
	for cave: StringName in _maps:
		maps.append_array(get_maps(cave))
	return maps


func size() -> int:
	return _maps.size()


func get_errors() -> PackedStringArray:
	return _errors


func _add_cave(cave: StringName, raw: Variant, where: String) -> bool:
	if not raw is Dictionary:
		return _fail("%s : une grotte est un objet { maps, escape | escapes }" % where)
	var entry: Dictionary = raw
	var ok := true
	for key: Variant in entry:
		if not _CAVE_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	var maps: Array[StringName] = []
	if not entry.get("maps") is Array or (entry["maps"] as Array).is_empty():
		return _fail("%s : « maps » doit être une liste non vide de cartes" % where)
	for value: Variant in entry["maps"]:
		var map := StringName(str(value)) if value is String else &""
		if map.is_empty():
			return _fail("%s : carte vide ou non textuelle dans « maps »" % where)
		if maps.has(map) or _cave_of.has(map):
			return _fail("%s : carte « %s » déjà dans une grotte" % [where, map])
		maps.append(map)
	var exits: Array[CaveExit] = []
	if entry.has("escape") and entry.has("escapes"):
		return _fail("%s : « escape » et « escapes » sont exclusifs" % where)
	if entry.has("escapes"):
		exits = _parse_escapes(entry["escapes"], where)
	else:
		var single := _parse_exit(entry.get("escape"), where)
		if single != null:
			exits.append(single)
	if exits.is_empty():
		return false
	for exit: CaveExit in exits:
		if maps.has(exit.map):
			return _fail("%s : la sortie « %s » est une carte de la grotte" % [where, exit.map])
		exit.cave = cave
	var dark: Variant = entry.get("dark", false)
	if not dark is bool:
		return _fail("%s : « dark » doit être un booléen" % where)
	if dark:
		_dark[cave] = true
	_maps[cave] = maps
	_exits[cave] = exits
	for map: StringName in maps:
		_cave_of[map] = cave
	return ok


## « escapes » (jalon 17) : liste non vide de sorties à plage de rangées, plages disjointes ;
## vide si une erreur est trouvée.
func _parse_escapes(raw: Variant, where: String) -> Array[CaveExit]:
	var exits: Array[CaveExit] = []
	if not raw is Array or (raw as Array).is_empty():
		_fail("%s : « escapes » doit être une liste non vide de sorties" % where)
		return exits
	var valid := true
	for index: int in (raw as Array).size():
		var exit := _parse_exit(raw[index], where, "escapes[%d]" % index)
		if exit == null:
			valid = false
			continue
		for other: CaveExit in exits:
			if exit.first_row <= other.last_row and other.first_row <= exit.last_row:
				valid = _fail("%s : « escapes[%d].rows » chevauche une autre sortie"
					% [where, index])
		exits.append(exit)
	if not valid:
		exits.clear()
	return exits


## Une sortie : « escape » (sans « rows ») ou un élément de « escapes » (« rows » obligatoire).
func _parse_exit(raw: Variant, where: String, key_name: String = "escape") -> CaveExit:
	var with_rows := key_name != "escape"
	if not raw is Dictionary:
		_fail("%s : « %s » doit être un objet { map, spawn, facing%s }"
			% [where, key_name, ", rows" if with_rows else ""])
		return null
	var entry: Dictionary = raw
	var valid := true
	var allowed := _ESCAPES_KEYS if with_rows else _ESCAPE_KEYS
	for key: Variant in entry:
		if not allowed.has(str(key)):
			valid = _fail("%s : clé inconnue « %s.%s »" % [where, key_name, key])
	for key: String in ["map", "spawn"]:
		var value: Variant = entry.get(key)
		if not value is String or (value as String).strip_edges().is_empty():
			valid = _fail("%s : « %s.%s » doit être un identifiant non vide"
				% [where, key_name, key])
	var facing: Variant = entry.get("facing")
	if not facing is String or not Grid.is_direction_name(facing):
		valid = _fail("%s : « %s.facing » doit être up, down, left ou right" % [where, key_name])
	var rows := Vector2i(-1, -1)
	if with_rows:
		rows = _parse_rows(entry.get("rows"))
		if rows.x < 0:
			valid = _fail("%s : « %s.rows » doit être [première, dernière], entiers ≥ 0"
				% [where, key_name])
	if not valid:
		return null
	var exit := CaveExit.new()
	exit.map = StringName(entry["map"])
	exit.spawn = StringName(entry["spawn"])
	exit.facing = Grid.direction_from_name(facing)
	exit.first_row = rows.x
	exit.last_row = rows.y
	return exit


## [première, dernière] rangée (entiers ≥ 0, première ≤ dernière) ; (-1, -1) si invalide.
static func _parse_rows(raw: Variant) -> Vector2i:
	if not raw is Array or (raw as Array).size() != 2:
		return Vector2i(-1, -1)
	var bounds: Array[int] = []
	for value: Variant in raw:
		if not (value is int or value is float) or float(value) != floorf(float(value)) \
				or int(value) < 0:
			return Vector2i(-1, -1)
		bounds.append(int(value))
	if bounds[0] > bounds[1]:
		return Vector2i(-1, -1)
	return Vector2i(bounds[0], bounds[1])


func _fail(message: String) -> bool:
	_errors.append(message)
	push_error("CaveLibrary : " + message)
	return false
