class_name DialogueLibrary
extends RefCounted
## Tous les dialogues du jeu, lus dans les fichiers JSON de `data/dialogues/`.
##
## Classe pure (docs/tech/jalon-03.md §2.4). Chaque fichier est un objet
## « identifiant → dialogue » ; les identifiants sont uniques dans tout le dossier.
## [codeblock]
## "mom": {
##   "speaker": "Maman",
##   "variants": [
##     { "unless": ["mom_greeted"], "set": ["mom_greeted"], "auto": true,
##       "pages": ["Bonjour ! Tu es enfin réveillé ?", "J'ai laissé ..."] },
##     { "pages": ["Tu sors ? Profite de cette belle journée.", "..."] }
##   ]
## },
## "breakfast_table": { "narration": true, "pages": ["Ton petit-déjeuner est encore chaud."] }
## [/codeblock]
## Clés de page : text, speaker, pause, face_player, react, turn ({ acteur: cible }, 3B).
## Sans « variants », les clés d'une variante (pages, if, unless, set, auto) peuvent être
## écrites directement dans le dialogue. Toute clé inconnue est une erreur (faute de frappe).
## Une entrée invalide est écartée, l'erreur est signalée ([method get_errors], push_error).

const DATA_DIR: String = "res://data/dialogues/"

const _DIALOGUE_KEYS: Array[String] = ["speaker", "narration", "draft", "variants"]
const _VARIANT_KEYS: Array[String] = ["pages", "if", "unless", "set", "auto"]
const _PAGE_KEYS: Array[String] = [
	"text", "speaker", "pause", "face_player", "react", "turn",
]

var _dialogues: Dictionary[StringName, Dialogue] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge tous les fichiers `.json` de [param dir] (ordre alphabétique). Faux si une
## erreur a été signalée (les entrées valides sont gardées).
func load_dir(dir: String = DATA_DIR) -> bool:
	if not DirAccess.dir_exists_absolute(dir):
		return _fail("dossier introuvable : %s" % dir)
	var files := DirAccess.get_files_at(dir)
	var sorted: Array[String] = []
	sorted.assign(files)
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
		return _fail("%s : un objet { identifiant: dialogue } est attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute les dialogues d'un objet déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		var id := StringName(str(key))
		var where := "%s « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant vide" % source)
			continue
		if _dialogues.has(id):
			ok = _fail("%s : identifiant déjà défini dans %s" % [where, _dialogues[id].source])
			continue
		var dialogue := _parse_dialogue(data[key], where)
		if dialogue == null:
			ok = false
			continue
		dialogue.id = id
		dialogue.source = source
		_dialogues[id] = dialogue
	return ok


func has_dialogue(id: StringName) -> bool:
	return _dialogues.has(id)


## Dialogue [param id], ou null s'il n'existe pas.
func get_dialogue(id: StringName) -> Dialogue:
	return _dialogues.get(id)


## Identifiants connus, triés.
func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_dialogues.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


func size() -> int:
	return _dialogues.size()


## Erreurs signalées depuis la création (fichiers et entrées écartés).
func get_errors() -> PackedStringArray:
	return _errors


## Drapeaux lus par des conditions (« if », « unless ») dans tous les dialogues.
func get_condition_flags() -> Array[StringName]:
	var found: Dictionary[StringName, bool] = {}
	for dialogue: Dialogue in _dialogues.values():
		for variant: DialogueVariant in dialogue.variants:
			for flag: StringName in variant.if_flags + variant.unless_flags:
				found[flag] = true
	return _sorted_keys(found)


## Drapeaux levés (« set ») par au moins un dialogue.
func get_set_flags() -> Array[StringName]:
	var found: Dictionary[StringName, bool] = {}
	for dialogue: Dialogue in _dialogues.values():
		for variant: DialogueVariant in dialogue.variants:
			for flag: StringName in variant.set_flags:
				found[flag] = true
	return _sorted_keys(found)


func _parse_dialogue(value: Variant, where: String) -> Dialogue:
	if not value is Dictionary:
		_fail("%s : un objet est attendu" % where)
		return null
	var entry: Dictionary = value
	var dialogue := Dialogue.new()
	var ok := _check_keys(entry, _DIALOGUE_KEYS + _VARIANT_KEYS, where)
	if entry.has("speaker"):
		ok = _read_string(entry["speaker"], where + " speaker") and ok
		dialogue.speaker = str(entry["speaker"])
	if entry.has("narration"):
		ok = _read_bool(entry["narration"], where + " narration") and ok
		dialogue.narration = entry["narration"] is bool and entry["narration"]
	if entry.has("draft"):
		ok = _read_bool(entry["draft"], where + " draft") and ok
		dialogue.draft = entry["draft"] is bool and entry["draft"]
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
			dialogue.variants.append(variant)
	return dialogue if ok else null


func _parse_variant(value: Variant, where: String) -> DialogueVariant:
	if not value is Dictionary:
		return _null_fail("%s : un objet est attendu" % where)
	var entry: Dictionary = value
	var variant := DialogueVariant.new()
	var ok := _check_keys(entry, _VARIANT_KEYS, where)
	if not entry.get("pages") is Array or (entry.get("pages") as Array).is_empty():
		return _null_fail("%s : « pages » doit être une liste non vide" % where)
	var pages: Array = entry["pages"]
	for i: int in pages.size():
		var page := _parse_page(pages[i], "%s page %d" % [where, i + 1])
		if page == null:
			ok = false
		else:
			variant.pages.append(page)
	ok = _read_flags(entry, "if", variant.if_flags, where) and ok
	ok = _read_flags(entry, "unless", variant.unless_flags, where) and ok
	ok = _read_flags(entry, "set", variant.set_flags, where) and ok
	if entry.has("auto"):
		ok = _read_bool(entry["auto"], where + " auto") and ok
		variant.auto = entry["auto"] is bool and entry["auto"]
	return variant if ok else null


func _parse_page(value: Variant, where: String) -> DialoguePage:
	if value is String:
		if (value as String).strip_edges().is_empty():
			return _null_fail("%s : texte vide" % where)
		return DialoguePage.new(value)
	if not value is Dictionary:
		return _null_fail("%s : texte ou objet { \"text\": … } attendu" % where)
	var entry: Dictionary = value
	var ok := _check_keys(entry, _PAGE_KEYS, where)
	if not entry.get("text") is String or (entry["text"] as String).strip_edges().is_empty():
		return _null_fail("%s : « text » doit être un texte non vide" % where)
	var page := DialoguePage.new(entry["text"])
	if entry.has("speaker"):
		ok = _read_string(entry["speaker"], where + " speaker") and ok
		page.speaker = str(entry["speaker"])
	if entry.has("pause"):
		var pause: Variant = entry["pause"]
		if not (pause is float or pause is int) or float(pause) < 0.0:
			ok = _fail("%s : « pause » doit être un nombre de secondes ≥ 0" % where)
		else:
			page.pause = float(pause)
	if entry.has("face_player"):
		ok = _read_bool(entry["face_player"], where + " face_player") and ok
		page.face_player = entry["face_player"] is bool and entry["face_player"]
	if entry.has("react"):
		if not entry["react"] is String or (entry["react"] as String).is_empty():
			ok = _fail("%s : « react » doit être un identifiant" % where)
		else:
			page.react = StringName(entry["react"])
	if entry.has("turn"):
		ok = _read_turn(entry["turn"], page.turn, where) and ok
	return page if ok else null


## « turn » : objet non vide { acteur: cible }, textes non vides. Qu'une cible qui n'est ni une
## direction ni « player » désigne bien un PNJ se vérifie avec les cartes (tests de données).
func _read_turn(value: Variant, into: Dictionary[StringName, StringName], where: String) -> bool:
	if not value is Dictionary or (value as Dictionary).is_empty():
		return _fail("%s : « turn » doit être un objet { acteur: cible } non vide" % where)
	var turn: Dictionary = value
	for actor: Variant in turn:
		var target: Variant = turn[actor]
		if str(actor).is_empty() or not target is String or (target as String).is_empty():
			return _fail("%s : « turn » : acteur et cible doivent être des textes non vides"
				% where)
		if Grid.is_direction_name(str(actor)):
			return _fail("%s : « turn » : « %s » n'est pas un acteur" % [where, actor])
		into[StringName(str(actor))] = StringName(target)
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


func _read_string(value: Variant, where: String) -> bool:
	return value is String or _fail("%s : texte attendu" % where)


func _read_bool(value: Variant, where: String) -> bool:
	return value is bool or _fail("%s : true ou false attendu" % where)


func _fail(message: String) -> bool:
	var full := "DialogueLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false


func _null_fail(message: String) -> Variant:
	_fail(message)
	return null


static func _sorted_keys(found: Dictionary[StringName, bool]) -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(found.keys())
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result
