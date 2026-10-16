class_name SwitchPuzzleLibrary
extends RefCounted
## Puzzles d'interrupteurs (jalon 16, `jalon-16.md` §2.6) : `data/world/switch_puzzles.json`.
##
## Chaque puzzle relie la grille des objets à fouiller ([SwitchPuzzle]) aux textes et à la scène
## de son Arène ; les objets portent `puzzle` et `puzzle_slot` ([InteractPoint]) :
## [codeblock]
## "vermilion_gym": {
##   "columns": 5, "rows": 3, "solved_flag": "vermilion_gym_puzzle_solved",
##   "nothing": "<dialogue GYM-01>", "first": "<GYM-02>", "reset": "<GYM-04>",
##   "solved_cutscene": "<scène : GYM-03, barrière ouverte, drapeau>"
## }
## [/codeblock]
## Résolu (drapeau levé), chaque objet dit « nothing ». La scène de la réussite lève elle-même
## [member Spec.solved_flag]. Classe pure ; références (dialogues, scène) vérifiées par les tests.

const DATA_FILE: String = "res://data/world/switch_puzzles.json"
const _KEYS: Array[String] = ["columns", "rows", "solved_flag", "nothing", "first", "reset",
	"solved_cutscene"]
const _ID_KEYS: Array[String] = ["solved_flag", "nothing", "first", "reset", "solved_cutscene"]


class Spec:
	extends RefCounted
	var id: StringName = &""
	var columns: int = 5
	var rows: int = 3
	var solved_flag: StringName = &""
	var nothing: StringName = &""
	var first: StringName = &""
	var reset: StringName = &""
	var solved_cutscene: StringName = &""

	## Dialogue d'un résultat de fouille (SOLVED : &"", c'est la scène qui parle).
	func dialogue_for(result: SwitchPuzzle.Result) -> StringName:
		match result:
			SwitchPuzzle.Result.FIRST_FOUND:
				return first
			SwitchPuzzle.Result.RESET:
				return reset
			SwitchPuzzle.Result.SOLVED:
				return &""
		return nothing


var _specs: Dictionary[StringName, Spec] = {}
var _errors: PackedStringArray = PackedStringArray()


func load_file(path: String = DATA_FILE) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return _fail("%s : objet { puzzle: règle } attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute des puzzles déjà lus (« _doc » ignorée). Faux au premier puzzle invalide (non ajouté).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if str(key) == "_doc":
			continue
		var spec := _read(StringName(str(key)), data[key], source)
		if spec == null:
			ok = false
		else:
			_specs[spec.id] = spec
	return ok


func has_puzzle(id: StringName) -> bool:
	return _specs.has(id)


## Règle du puzzle [param id], ou null.
func get_spec(id: StringName) -> Spec:
	return _specs.get(id)


func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_specs.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


func get_errors() -> PackedStringArray:
	return _errors


func _read(id: StringName, entry: Variant, source: String) -> Spec:
	var where := "%s : « %s »" % [source, id]
	if not entry is Dictionary:
		_fail("%s : objet attendu" % where)
		return null
	var dict: Dictionary = entry
	for key: Variant in dict:
		if not _KEYS.has(str(key)):
			_fail("%s : clé inconnue « %s »" % [where, key])
			return null
	var spec := Spec.new()
	spec.id = id
	for key: String in ["columns", "rows"]:
		var value: Variant = dict.get(key, 0)
		if not (value is float or value is int) or int(value) != value or int(value) < 1:
			_fail("%s : « %s » doit être un entier ≥ 1" % [where, key])
			return null
		spec.set(key, int(value))
	if spec.columns * spec.rows < 2:
		_fail("%s : au moins deux objets à fouiller" % where)
		return null
	for key: String in _ID_KEYS:
		var value: Variant = dict.get(key, "")
		if not value is String or (value as String).is_empty():
			_fail("%s : « %s » doit être un identifiant non vide" % [where, key])
			return null
		spec.set(key, StringName(value))
	return spec


func _fail(message: String) -> bool:
	_errors.append(message)
	push_error("SwitchPuzzleLibrary : " + message)
	return false
