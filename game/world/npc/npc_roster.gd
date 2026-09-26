class_name NpcRoster
extends RefCounted
## PNJ et Pokémon du décor d'une carte, lus dans `data/npcs/<map_id>.json`.
##
## Classe pure (docs/tech/jalon-03.md §2.3). Le fichier est un objet
## « identifiant → PNJ », dans l'ordre d'apparition :
## [codeblock]
## {
##   "mom": { "cell": [7, 4], "facing": "down", "sprite": "mom", "dialogue": "mom" },
##   "charmander": { "cell": [11, 5], "sprite": "charmander", "dialogue": "observe_charmander",
##                   "verb": "observe" },
##   "aoki_pidgey_1": { "cell": [19, 16], "facing": "left", "sprite": "pidgey" }
## }
## [/codeblock]
## Clés : cell (obligatoire), sprite (obligatoire), facing (down), dialogue (aucun),
## verb (talk | observe), turn_to_player (true), keep_facing (false), lift (0 pixel).
## Toute autre clé est une erreur. Pas de fichier = aucun PNJ sur la carte (sans erreur).

const DATA_DIR: String = "res://data/npcs/"

const _KEYS: Array[String] = [
	"cell", "facing", "sprite", "dialogue", "verb", "turn_to_player", "keep_facing", "lift",
]
const _FACINGS: Dictionary[String, Vector2i] = {
	"down": Vector2i.DOWN, "up": Vector2i.UP, "left": Vector2i.LEFT, "right": Vector2i.RIGHT,
}

var _specs: Array[NpcSpec] = []
var _errors: PackedStringArray = PackedStringArray()


## Roster de la carte [param map_id] : `<dir>/<map_id>.json`, vide si le fichier n'existe pas.
static func load_for_map(map_id: StringName, dir: String = DATA_DIR) -> NpcRoster:
	var roster := NpcRoster.new()
	var path := dir.path_join(String(map_id) + ".json")
	if FileAccess.file_exists(path):
		roster.load_file(path)
	return roster


## Emplacement du fichier de la carte [param map_id].
static func path_for_map(map_id: StringName, dir: String = DATA_DIR) -> String:
	return dir.path_join(String(map_id) + ".json")


## Charge un fichier. Faux si illisible ou si une entrée est invalide.
func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		# get_error_line() compte à partir de 0.
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { identifiant: PNJ } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les PNJ d'un objet déjà lu. Une entrée invalide est écartée.
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant vide" % source)
			continue
		if get_spec(id) != null:
			ok = _fail("%s : identifiant en double" % where)
			continue
		var spec := _parse(data[key], where)
		if spec == null:
			ok = false
			continue
		spec.id = id
		_specs.append(spec)
	return ok


func get_all() -> Array[NpcSpec]:
	return _specs


func get_spec(id: StringName) -> NpcSpec:
	for spec: NpcSpec in _specs:
		if spec.id == id:
			return spec
	return null


func size() -> int:
	return _specs.size()


func get_errors() -> PackedStringArray:
	return _errors


func _parse(value: Variant, where: String) -> NpcSpec:
	if not value is Dictionary:
		_fail("%s : un objet est attendu" % where)
		return null
	var entry: Dictionary = value
	var spec := NpcSpec.new()
	var ok := true
	for key: Variant in entry:
		if not _KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	var cell: Variant = entry.get("cell")
	if not _is_cell(cell):
		ok = _fail("%s : « cell » doit être [x, y] (entiers ≥ 0)" % where)
	else:
		spec.cell = Vector2i(int(cell[0]), int(cell[1]))
	if not entry.get("sprite") is String or (entry.get("sprite") as String).is_empty():
		ok = _fail("%s : « sprite » est obligatoire" % where)
	else:
		spec.sprite = StringName(entry["sprite"])
	if entry.has("facing"):
		if not _FACINGS.has(str(entry["facing"])):
			ok = _fail("%s : « facing » vaut down, up, left ou right" % where)
		else:
			spec.facing = _FACINGS[str(entry["facing"])]
	if entry.has("dialogue"):
		if not entry["dialogue"] is String or (entry["dialogue"] as String).is_empty():
			ok = _fail("%s : « dialogue » doit être un identifiant" % where)
		else:
			spec.dialogue = StringName(entry["dialogue"])
	if entry.has("verb"):
		var verb := Interaction.kind_from_name(str(entry["verb"]))
		if verb != Interaction.Kind.TALK and verb != Interaction.Kind.OBSERVE:
			ok = _fail("%s : « verb » vaut talk ou observe" % where)
		else:
			spec.verb = verb as Interaction.Kind
	for key: String in ["turn_to_player", "keep_facing"]:
		if entry.has(key):
			if not entry[key] is bool:
				ok = _fail("%s : « %s » vaut true ou false" % [where, key])
			else:
				spec.set(key, entry[key])
	if entry.has("lift"):
		var lift: Variant = entry["lift"]
		if not (lift is float or lift is int) or float(lift) != floorf(float(lift)) \
				or float(lift) < 0.0:
			ok = _fail("%s : « lift » doit être un nombre entier de pixels ≥ 0" % where)
		else:
			spec.lift = int(lift)
	return spec if ok else null


static func _is_cell(value: Variant) -> bool:
	if not value is Array or (value as Array).size() != 2:
		return false
	for n: Variant in value:
		if not (n is float or n is int) or float(n) != floorf(float(n)) or float(n) < 0.0:
			return false
	return true


func _fail(message: String) -> bool:
	var full := "NpcRoster : " + message
	_errors.append(full)
	push_error(full)
	return false
