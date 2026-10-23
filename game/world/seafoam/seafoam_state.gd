class_name SeafoamState
extends RefCounted
## État des étages des Îles Écume (jalon 24, T9 ; dossier 27 §7.2–§7.4, `jalon-24.md` §2.6) :
## classe pure. Données : `data/world/seafoam.json`, **généré** depuis les grilles par
## `tools/gen_seafoam_data.py` (aucune case ici).
##
## Un étage est **calculé à l'entrée** depuis les 8 drapeaux `seafoam_<étage>_hole_<n>_filled`,
## sans autre donnée ([method floor_state]) :
## - un trou dont le drapeau est posé est bouché (sol) ; les autres sont ouverts ;
## - un rocher tombé d'au-dessus (drapeau du trou du dessus posé) est à son point de chute fixe ;
## - les rochers libres sont à leur position d'origine ;
## - **rocher désigné** [D] (§7.3) : un rocher (d'origine ou tombé) qui désigne le trou n de son
##   étage est retiré quand ce trou est bouché, quel que soit le rocher réellement poussé ;
## - un courant est actif tant que ses drapeaux `stopped_by` ne sont pas tous posés.
## Aucune position de rocher n'est sauvegardée : changer d'étage ou recharger les remet en place.

const DATA_FILE: String = "res://data/world/seafoam.json"
const _DIRECTIONS: Dictionary[String, Vector2i] = {
	"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT, "right": Vector2i.RIGHT,
}


## Un courant d'un étage, dans un état donné.
class Current:
	extends RefCounted
	var id: int = 0
	var active: bool = false
	## Case → direction du flux.
	var cells: Dictionary[Vector2i, Vector2i] = {}
	var sources: Array[Vector2i] = []
	## Fin du trajet : un passage ([member end_is_warp]) ou une rive.
	var end_cell: Vector2i = Vector2i.ZERO
	var end_is_warp: bool = false


## Un étage reconstruit ([method SeafoamState.floor_state]).
class Floor:
	extends RefCounted
	var map_id: StringName = &""
	## Trous ouverts : case → numéro (un rocher y tombe, le joueur y saute).
	var open_holes: Dictionary[Vector2i, int] = {}
	## Trous bouchés : case → numéro (du sol).
	var plugged_holes: Dictionary[Vector2i, int] = {}
	## Drapeau de chaque trou de l'étage, par numéro.
	var hole_flags: Dictionary[int, StringName] = {}
	## Tous les rochers présents (libres et tombés), dans l'ordre des données.
	var boulders: Array[Vector2i] = []
	## Parmi eux, ceux qui sont tombés d'au-dessus (à leur point de chute).
	var fallen: Array[Vector2i] = []
	var currents: Array[Current] = []
	## Arrivées du joueur tombé d'un trou du dessus : drapeau du trou → case.
	var landings: Dictionary[StringName, Vector2i] = {}
	## Arrivées en Surf forcé (cases `s`, atterrissages dans l'eau).
	var forced_surf: Dictionary[Vector2i, bool] = {}
	## Départs d'où SURFER est refusé **maintenant** (courant actif, T-14).
	var surf_forbidden: Dictionary[Vector2i, bool] = {}

	## Vrai si au moins un courant de l'étage est actif.
	func has_active_current() -> bool:
		for current: Current in currents:
			if current.active:
				return true
		return false

	## Cases des courants actifs : case → direction.
	func active_current_cells() -> Dictionary[Vector2i, Vector2i]:
		var cells: Dictionary[Vector2i, Vector2i] = {}
		for current: Current in currents:
			if current.active:
				cells.merge(current.cells)
		return cells

	## Pose sur [param grid] les courants actifs et retire ceux qui sont coupés (eau calme).
	func apply_to(grid: GridWorld) -> void:
		for current: Current in currents:
			for cell: Vector2i in current.cells:
				grid.set_current(cell, current.cells[cell] if current.active else Vector2i.ZERO)


var _floors: Dictionary[StringName, Dictionary] = {}
var _hole_flags: Array[StringName] = []
var _errors: PackedStringArray = PackedStringArray()


## Charge les données. Faux si le fichier est absent ou invalide ([method get_errors]).
func load_file(path: String = DATA_FILE) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return _fail("%s : objet JSON attendu" % path)
	return add_from_dict(json.data, path)


## Lit des données déjà analysées (format de `data/world/seafoam.json`).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var floors: Variant = data.get("floors")
	var flags: Variant = data.get("hole_flags")
	if not floors is Dictionary or not flags is Array:
		return _fail("%s : « floors » (objet) et « hole_flags » (liste) attendus" % source)
	_hole_flags.clear()
	for flag: Variant in flags:
		_hole_flags.append(StringName(str(flag)))
	var ok := true
	for key: Variant in floors:
		var floor_data: Variant = floors[key]
		if not floor_data is Dictionary or not _is_floor(floor_data):
			ok = _fail("%s : étage « %s » mal formé" % [source, key])
			continue
		_floors[StringName(str(key))] = floor_data
	return ok


## Identifiants des cartes des étages, dans l'ordre des données.
func floor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_floors.keys())
	return ids


func has_floor(map_id: StringName) -> bool:
	return _floors.has(map_id)


## Les 8 drapeaux de trous, dans l'ordre du dossier §7.2.
func hole_flags() -> Array[StringName]:
	return _hole_flags.duplicate()


## L'étage [param map_id] pour les drapeaux [param flags] (null si l'étage est inconnu).
func floor_state(map_id: StringName, flags: StoryFlags) -> Floor:
	if not _floors.has(map_id):
		return null
	var data: Dictionary = _floors[map_id]
	var result := Floor.new()
	result.map_id = map_id
	var plugged: Dictionary[int, bool] = {}
	for hole: Dictionary in data["holes"]:
		var n := int(hole["n"])
		var cell := _cell(hole["cell"])
		var flag := StringName(str(hole["flag"]))
		result.hole_flags[n] = flag
		if _has(flags, flag):
			plugged[n] = true
			result.plugged_holes[cell] = n
		else:
			result.open_holes[cell] = n
	for boulder: Dictionary in data["boulders"]:
		if not plugged.has(int(boulder["hole"])):
			result.boulders.append(_cell(boulder["cell"]))
	for point: Dictionary in data["fall_points"]:
		if _has(flags, StringName(str(point["from_flag"]))) \
				and not plugged.has(int(point["hole"])):
			var cell := _cell(point["cell"])
			result.boulders.append(cell)
			result.fallen.append(cell)
	for landing: Dictionary in data["landings"]:
		result.landings[StringName(str(landing["from_flag"]))] = _cell(landing["cell"])
	for cell: Variant in data["forced_surf"]:
		result.forced_surf[_cell(cell)] = true
	var active_ids: Dictionary[int, bool] = {}
	for current_data: Dictionary in data["currents"]:
		var current := _current(current_data, flags)
		result.currents.append(current)
		if current.active:
			active_ids[current.id] = true
	for forbidden: Dictionary in data["surf_forbidden"]:
		if active_ids.has(int(forbidden["while_current"])):
			result.surf_forbidden[_cell(forbidden["cell"])] = true
	return result


func get_errors() -> PackedStringArray:
	return _errors


static func _current(data: Dictionary, flags: StoryFlags) -> Current:
	var current := Current.new()
	current.id = int(data["id"])
	for entry: Dictionary in data["cells"]:
		current.cells[_cell(entry["cell"])] = _DIRECTIONS.get(str(entry["dir"]), Vector2i.ZERO)
	for cell: Variant in data["sources"]:
		current.sources.append(_cell(cell))
	var stopped := true
	for flag: Variant in data["stopped_by"]:
		stopped = stopped and _has(flags, StringName(str(flag)))
	current.active = not stopped
	var end: Dictionary = data["end"]
	current.end_cell = _cell(end["cell"])
	current.end_is_warp = str(end["kind"]) == "warp"
	return current


static func _has(flags: StoryFlags, flag: StringName) -> bool:
	return flags != null and flags.has_flag(flag)


static func _cell(value: Variant) -> Vector2i:
	if value is Array and (value as Array).size() == 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(-1, -1)


static func _is_floor(data: Dictionary) -> bool:
	for key: String in ["holes", "fall_points", "landings", "boulders", "currents",
			"forced_surf", "surf_forbidden"]:
		if not data.get(key) is Array:
			return false
	for current: Variant in data["currents"]:
		if not current is Dictionary or not (current as Dictionary).get("end") is Dictionary:
			return false
		for entry: Variant in current["cells"]:
			if not _DIRECTIONS.has(str((entry as Dictionary).get("dir", ""))):
				return false
	return true


func _fail(message: String) -> bool:
	var full := "SeafoamState : " + message
	_errors.append(full)
	push_error(full)
	return false
