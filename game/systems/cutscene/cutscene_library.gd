class_name CutsceneLibrary
extends RefCounted
## Toutes les scènes scriptées du jeu, lues dans les fichiers JSON de `data/cutscenes/`.
##
## Classe pure (docs/tech/jalon-03b.md §2.3), sur le modèle exact de [DialogueLibrary].
## Chaque fichier est un objet « identifiant → scène » ; les identifiants sont uniques dans
## tout le dossier. Une scène a des variantes (première qui s'applique aux drapeaux) ; sans
## « variants », les clés d'une variante (if, unless, steps) s'écrivent dans la scène :
## [codeblock]
## "route1_grass": {
##   "variants": [
##     { "unless": ["oak_met"], "steps": [
##         { "wait": 0.4 },
##         { "dialogue": "oak_route1_call" },
##         { "face": "player", "to": "down" },
##         { "spawn": "oak", "sprite": "oak", "cell": [24, 13], "facing": "up" },
##         { "move": "oak", "run": true,
##           "to": { "near": "player", "offsets": [[1, 0], [-1, 0], [0, 1]] } },
##         { "set": ["oak_met"] },
##         { "move": "oak", "follower": "player", "path": ["down", "down"] },
##         { "change_map": "oak_lab", "at": "entrance", "facing": "up" } ] },
##     { "unless": ["has_starter"], "steps": [
##         { "dialogue": "route1_grass_thought" },
##         { "move": "player", "path": ["down"] } ] }
##   ]
## }
## [/codeblock]
## Chaque étape a **exactement une** clé de type ([constant CutsceneStep.TYPE_KEYS]) :
## - wait : secondes ≥ 0 ;
## - dialogue : identifiant de dialogue ;
## - face : acteur, avec « to » = direction, « player » ou identifiant de PNJ ;
## - set : liste non vide de drapeaux ;
## - spawn : identifiant du PNJ créé, avec les clés d'une entrée de `data/npcs/` (sauf if et
##   unless), validées par [method NpcRoster.parse_entry] ; sa clé « dialogue » est celle du
##   PNJ (dialogue quand on lui parle), pas un second type d'étape ;
## - move : acteur, avec **soit** « path » (directions), **soit** « to » ([x, y], ou
##   { "near": acteur, "offsets": [[dx, dy], …] }), et « run », « follower » facultatifs ;
## - change_map : identifiant de carte, avec « at » (point d'apparition) et « facing »
##   facultatif.
## Acteur = « player » ou identifiant d'un PNJ de la carte courante. Toute clé inconnue est
## une erreur (faute de frappe). Une scène invalide est écartée **entière**, l'erreur est
## signalée ([method get_errors], push_error).

const DATA_DIR: String = "res://data/cutscenes/"

const _SCENE_KEYS: Array[String] = ["variants"]
const _VARIANT_KEYS: Array[String] = ["if", "unless", "steps"]
## Clés permises en plus de la clé de type, par type (ordre de CutsceneStep.Kind).
const _EXTRA_KEYS: Array[Array] = [
	[], [], ["to"], [], [], ["path", "to", "run", "follower"], ["at", "facing"],
]

var _cutscenes: Dictionary[StringName, Cutscene] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge tous les fichiers `.json` de [param dir] (ordre alphabétique). Faux si une
## erreur a été signalée (les scènes valides sont gardées).
func load_dir(dir: String = DATA_DIR) -> bool:
	if not DirAccess.dir_exists_absolute(dir):
		return _fail("dossier introuvable : %s" % dir)
	var sorted: Array[String] = []
	sorted.assign(DirAccess.get_files_at(dir))
	sorted.sort()
	var ok := true
	for file: String in sorted:
		if file.get_extension() == "json":
			ok = load_file(dir.path_join(file)) and ok
	return ok


## Charge un fichier JSON. Faux si le fichier est illisible ou contient une erreur.
func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		# get_error_line() compte à partir de 0.
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { identifiant: scène } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les scènes d'un objet déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant vide" % source)
			continue
		if _cutscenes.has(id):
			ok = _fail("%s : identifiant déjà défini dans %s" % [where, _cutscenes[id].source])
			continue
		var cutscene := _parse_cutscene(data[key], where)
		if cutscene == null:
			ok = false
			continue
		cutscene.id = id
		cutscene.source = source
		_cutscenes[id] = cutscene
	return ok


func has_cutscene(id: StringName) -> bool:
	return _cutscenes.has(id)


## Scène [param id], ou null si elle n'existe pas.
func get_cutscene(id: StringName) -> Cutscene:
	return _cutscenes.get(id)


## Identifiants connus, triés.
func get_ids() -> Array[StringName]:
	return _sorted_keys(_cutscenes)


func size() -> int:
	return _cutscenes.size()


## Erreurs signalées depuis la création (fichiers et scènes écartés).
func get_errors() -> PackedStringArray:
	return _errors


## Drapeaux lus par les conditions des variantes (« if », « unless »).
func get_condition_flags() -> Array[StringName]:
	var found: Dictionary[StringName, bool] = {}
	for cutscene: Cutscene in _cutscenes.values():
		for variant: CutsceneVariant in cutscene.variants:
			for flag: StringName in variant.if_flags + variant.unless_flags:
				found[flag] = true
	return _sorted_keys(found)


## Drapeaux levés par au moins une étape « set ».
func get_set_flags() -> Array[StringName]:
	var found: Dictionary[StringName, bool] = {}
	for step: CutsceneStep in _all_steps():
		if step.kind == CutsceneStep.Kind.SET_FLAGS:
			for flag: StringName in step.flags:
				found[flag] = true
	return _sorted_keys(found)


## Dialogues joués par au moins une étape « dialogue » (tests de données).
func get_dialogue_ids() -> Array[StringName]:
	var found: Dictionary[StringName, bool] = {}
	for step: CutsceneStep in _all_steps():
		if step.kind == CutsceneStep.Kind.DIALOGUE:
			found[step.dialogue_id] = true
	return _sorted_keys(found)


func _all_steps() -> Array[CutsceneStep]:
	var steps: Array[CutsceneStep] = []
	for cutscene: Cutscene in _cutscenes.values():
		for variant: CutsceneVariant in cutscene.variants:
			steps.append_array(variant.steps)
	return steps


func _parse_cutscene(value: Variant, where: String) -> Cutscene:
	if not value is Dictionary:
		return _null_fail("%s : un objet est attendu" % where)
	var entry: Dictionary = value
	var cutscene := Cutscene.new()
	var ok := _check_keys(entry, _SCENE_KEYS + _VARIANT_KEYS, where)
	var raw_variants: Array = []
	if entry.has("variants"):
		for key: String in _VARIANT_KEYS:
			if entry.has(key):
				ok = _fail("%s : « %s » doit être dans une variante" % [where, key])
		if not entry["variants"] is Array or (entry["variants"] as Array).is_empty():
			return _null_fail("%s : « variants » doit être une liste non vide" % where)
		raw_variants = entry["variants"]
	else:
		var single: Dictionary = {}
		for key: String in _VARIANT_KEYS:
			if entry.has(key):
				single[key] = entry[key]
		raw_variants = [single]
	for i: int in raw_variants.size():
		var variant := _parse_variant(raw_variants[i], "%s variante %d" % [where, i + 1])
		if variant == null:
			ok = false
		else:
			cutscene.variants.append(variant)
	return cutscene if ok else null


func _parse_variant(value: Variant, where: String) -> CutsceneVariant:
	if not value is Dictionary:
		return _null_fail("%s : un objet est attendu" % where)
	var entry: Dictionary = value
	var variant := CutsceneVariant.new()
	var ok := _check_keys(entry, _VARIANT_KEYS, where)
	ok = _read_flags(entry, "if", variant.if_flags, where) and ok
	ok = _read_flags(entry, "unless", variant.unless_flags, where) and ok
	if not entry.get("steps") is Array or (entry.get("steps") as Array).is_empty():
		return _null_fail("%s : « steps » doit être une liste non vide" % where)
	var steps: Array = entry["steps"]
	for i: int in steps.size():
		var step := _parse_step(steps[i], "%s étape %d" % [where, i + 1])
		if step == null:
			ok = false
		else:
			variant.steps.append(step)
	return variant if ok else null


func _parse_step(value: Variant, where: String) -> CutsceneStep:
	if not value is Dictionary:
		return _null_fail("%s : un objet { type: … } est attendu" % where)
	var entry: Dictionary = value
	var kinds: Array[int] = []
	for i: int in CutsceneStep.TYPE_KEYS.size():
		# Dans une étape « spawn », « dialogue » est la clé du PNJ créé, pas un type.
		if i == CutsceneStep.Kind.DIALOGUE and entry.has("spawn"):
			continue
		if entry.has(CutsceneStep.TYPE_KEYS[i]):
			kinds.append(i)
	if kinds.size() != 1:
		return _null_fail("%s : une étape a exactement un type parmi %s" % [where,
			", ".join(CutsceneStep.TYPE_KEYS)])
	var step := CutsceneStep.new()
	step.kind = kinds[0] as CutsceneStep.Kind
	var type_key: String = CutsceneStep.TYPE_KEYS[step.kind]
	where += " (%s)" % type_key
	var ok := true
	if step.kind != CutsceneStep.Kind.SPAWN:
		var allowed: Array[String] = [type_key]
		allowed.append_array(_EXTRA_KEYS[step.kind])
		ok = _check_keys(entry, allowed, where)
	var main: Variant = entry[type_key]
	match step.kind:
		CutsceneStep.Kind.WAIT:
			if not (main is float or main is int) or float(main) < 0.0:
				ok = _fail("%s : « wait » doit être un nombre de secondes ≥ 0" % where)
			else:
				step.seconds = float(main)
		CutsceneStep.Kind.DIALOGUE:
			ok = _read_id(main, where + " dialogue", func(v: StringName) -> void:
				step.dialogue_id = v) and ok
		CutsceneStep.Kind.FACE:
			ok = _read_id(main, where + " face", func(v: StringName) -> void:
				step.actor = v) and ok
			ok = _read_id(entry.get("to"), where + " to", func(v: StringName) -> void:
				step.target = v) and ok
		CutsceneStep.Kind.SET_FLAGS:
			if not main is Array or (main as Array).is_empty():
				ok = _fail("%s : « set » doit être une liste non vide de drapeaux" % where)
			else:
				ok = _read_flags(entry, "set", step.flags, where) and ok
		CutsceneStep.Kind.SPAWN:
			ok = _parse_spawn(entry, step, where) and ok
		CutsceneStep.Kind.MOVE:
			ok = _parse_move(entry, step, where) and ok
		CutsceneStep.Kind.CHANGE_MAP:
			ok = _read_id(main, where + " change_map", func(v: StringName) -> void:
				step.map_id = v) and ok
			ok = _read_id(entry.get("at"), where + " at", func(v: StringName) -> void:
				step.spawn = v) and ok
			if entry.has("facing"):
				ok = _read_direction(entry["facing"], where + " facing",
					func(v: Vector2i) -> void: step.facing = v) and ok
	return step if ok else null


## spawn : identifiant, puis les clés d'une entrée de data/npcs/ (sans condition).
func _parse_spawn(entry: Dictionary, step: CutsceneStep, where: String) -> bool:
	var ok := _read_id(entry["spawn"], where + " spawn", func(v: StringName) -> void:
		step.actor = v)
	if step.actor == NpcRoster.PLAYER_ID:
		ok = _fail("%s : identifiant réservé au joueur" % where)
	var npc_entry := entry.duplicate()
	npc_entry.erase("spawn")
	for key: String in ["if", "unless"]:
		if npc_entry.has(key):
			ok = _fail("%s : « %s » n'a pas de sens dans une étape (conditions : variante)"
				% [where, key])
			npc_entry.erase(key)
	var errors := PackedStringArray()
	step.spec = NpcRoster.parse_entry(npc_entry, errors)
	for message: String in errors:
		ok = _fail("%s : %s" % [where, message])
	if step.spec != null:
		step.spec.id = step.actor
	return ok


## move : acteur, path ou to (exactement un des deux), run, follower.
func _parse_move(entry: Dictionary, step: CutsceneStep, where: String) -> bool:
	var ok := _read_id(entry["move"], where + " move", func(v: StringName) -> void:
		step.actor = v)
	if entry.has("path") == entry.has("to"):
		ok = _fail("%s : « path » ou « to », exactement l'un des deux" % where)
	if entry.has("path"):
		var path: Variant = entry["path"]
		if not path is Array or (path as Array).is_empty():
			ok = _fail("%s : « path » doit être une liste non vide de directions" % where)
		else:
			for name: Variant in path:
				if not name is String or not Grid.is_direction_name(name):
					ok = _fail("%s : direction inconnue « %s » dans « path »" % [where, name])
					break
				step.path.append(Grid.direction_from_name(name))
	if entry.has("to"):
		ok = _parse_destination(entry["to"], step, where) and ok
	if entry.has("run"):
		if not entry["run"] is bool:
			ok = _fail("%s : « run » vaut true ou false" % where)
		else:
			step.run = entry["run"]
	if entry.has("follower"):
		ok = _read_id(entry["follower"], where + " follower", func(v: StringName) -> void:
			step.follower = v) and ok
		if step.follower == step.actor:
			ok = _fail("%s : « follower » ne peut pas être l'acteur lui-même" % where)
	return ok


## to : [x, y], ou { "near": acteur, "offsets": [[dx, dy], …] }.
func _parse_destination(value: Variant, step: CutsceneStep, where: String) -> bool:
	if value is Array:
		if not NpcRoster.is_cell(value):
			return _fail("%s : « to » doit être [x, y] (entiers ≥ 0)" % where)
		step.cell = Vector2i(int(value[0]), int(value[1]))
		return true
	if not value is Dictionary:
		return _fail("%s : « to » doit être [x, y] ou { near, offsets }" % where)
	var near: Dictionary = value
	var ok := _check_keys(near, ["near", "offsets"], where + " to")
	ok = _read_id(near.get("near"), where + " to near", func(v: StringName) -> void:
		step.near = v) and ok
	var offsets: Variant = near.get("offsets")
	if not offsets is Array or (offsets as Array).is_empty():
		return _fail("%s : « offsets » doit être une liste non vide de [dx, dy]" % where)
	for offset: Variant in offsets:
		if not _is_offset(offset):
			return _fail("%s : décalage invalide %s (entiers, pas [0, 0])" % [where, offset])
		step.offsets.append(Vector2i(int(offset[0]), int(offset[1])))
	return ok


static func _is_offset(value: Variant) -> bool:
	if not value is Array or (value as Array).size() != 2:
		return false
	for n: Variant in value:
		if not (n is float or n is int) or float(n) != floorf(float(n)):
			return false
	return int(value[0]) != 0 or int(value[1]) != 0


func _read_id(value: Variant, where: String, assign: Callable) -> bool:
	if not value is String or (value as String).is_empty():
		return _fail("%s : identifiant attendu" % where)
	assign.call(StringName(value))
	return true


func _read_direction(value: Variant, where: String, assign: Callable) -> bool:
	if not value is String or not Grid.is_direction_name(value):
		return _fail("%s : direction inconnue « %s » (up, down, left, right)" % [where, value])
	assign.call(Grid.direction_from_name(value))
	return true


func _read_flags(entry: Dictionary, key: String, into: Array[StringName], where: String) -> bool:
	if not entry.has(key):
		return true
	if not entry[key] is Array:
		return _fail("%s : « %s » doit être une liste de drapeaux" % [where, key])
	for flag: Variant in entry[key]:
		if not flag is String or (flag as String).is_empty():
			return _fail("%s : drapeau invalide dans « %s »" % [where, key])
		into.append(StringName(flag))
	return true


func _check_keys(entry: Dictionary, allowed: Array[String], where: String) -> bool:
	var ok := true
	for key: Variant in entry:
		if not allowed.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	return ok


func _fail(message: String) -> bool:
	var full := "CutsceneLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false


func _null_fail(message: String) -> Variant:
	_fail(message)
	return null


static func _sorted_keys(found: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(found.keys())
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result
