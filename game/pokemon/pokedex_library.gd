class_name PokedexLibrary
extends RefCounted
## Données du Pokédex de Kanto, lues dans `data/pokedex/kanto.json` (dossier 08 §4 ;
## jalon-06.md §3.5, décisions Q-5 et Q-6).
##
## Classe pure. Format :
## [codeblock]
## {
##   "size": 151,
##   "species": {
##     "pidgey": { "height": 0.3, "weight": 1.8, "description": "…", "draft": true,
##       "notes": [ { "id": "pidgey_paths", "text": "…", "unlock": { "seen": 1 },
##                    "draft": true } ] }
##   }
## }
## [/codeblock]
## « size » : nombre de cases de la grille (1 à « size »). Par espèce : « height » (m) et
## « weight » (kg) > 0, « description » (texte), obligatoires ; « draft » (texte provisoire)
## et « notes » facultatifs. Par note : « id » (unique dans tout le fichier), « text »,
## « unlock » (au moins une condition : « seen » et « caught » entiers ≥ 1, « map » et
## « flag » identifiants ; [PokedexNoteData]), « draft ». Le numéro et le nom viennent de
## [PokemonData] : [method check_references] vérifie que chaque espèce y existe et que son
## numéro tient dans la grille. Toute clé inconnue est une erreur ; une espèce invalide est
## écartée, l'erreur signalée ([method get_errors], push_error).

const DEFAULT_PATH: String = "res://data/pokedex/kanto.json"
## Bornes de « size » (le Pokédex national actuel compte 1025 espèces).
const MAX_SIZE: int = 1025

const _ROOT_KEYS: Array[String] = ["size", "species"]
const _SPECIES_KEYS: Array[String] = ["height", "weight", "description", "draft", "notes"]
const _SPECIES_REQUIRED: Array[String] = ["height", "weight", "description"]
const _NOTE_KEYS: Array[String] = ["id", "text", "unlock", "draft"]
const _NOTE_REQUIRED: Array[String] = ["id", "text", "unlock"]
const _UNLOCK_KEYS: Array[String] = ["seen", "caught", "map", "flag"]
## Bornes de vraisemblance (le plus grand Pokémon de Kanto mesure 8,8 m, le plus lourd 460 kg).
const _MAX_HEIGHT: float = 100.0
const _MAX_WEIGHT: float = 1000.0
const _MAX_COUNT: int = 9999

var _size: int = 0
var _species: Dictionary[StringName, PokedexSpeciesData] = {}
var _notes: Dictionary[StringName, PokedexNoteData] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge [param path]. Faux si le fichier est illisible ou contient une erreur (les espèces
## valides sont gardées).
func load_file(path: String = DEFAULT_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { \"size\", \"species\" } est attendu" % path)
	return add_from_dict(json.data, path)


## Lit un objet déjà lu ([param source] sert aux messages d'erreur).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if not _ROOT_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	var size: Variant = data.get("size")
	if not _is_int(size) or int(size) < 1 or int(size) > MAX_SIZE:
		ok = _fail("%s : « size » est un entier de 1 à %d" % [source, MAX_SIZE])
	else:
		_size = int(size)
	if not data.get("species") is Dictionary:
		return _fail("%s : « species » doit être un objet { identifiant: espèce }" % source)
	var species: Dictionary = data["species"]
	for key: Variant in species:
		var id := StringName(str(key))
		var where := "%s espèce « %s »" % [source, id]
		if id.is_empty():
			ok = _fail("%s : identifiant d'espèce vide" % source)
			continue
		if _species.has(id):
			ok = _fail("%s : espèce déjà définie dans %s" % [where, _species[id].source])
			continue
		var entry := _parse_species(species[key], id, where)
		if entry == null:
			ok = false
			continue
		entry.source = source
		_species[id] = entry
		for note: PokedexNoteData in entry.notes:
			_notes[note.id] = note
	return ok


## Vérifie les références croisées avec [param data] : chaque espèce existe et son numéro
## tient dans la grille. Les espèces fautives sont écartées. Faux si une erreur a été trouvée.
func check_references(data: PokemonData) -> bool:
	var ok := true
	for id: StringName in _species.keys():
		var where := "%s espèce « %s »" % [_species[id].source, id]
		if not data.has_species(id):
			ok = _fail("%s : espèce inconnue de PokemonData" % where)
		elif data.get_species(id).dex > _size:
			ok = _fail("%s : numéro %d hors de la grille (1 à %d)" % [where,
				data.get_species(id).dex, _size])
		else:
			continue
		for note: PokedexNoteData in _species[id].notes:
			_notes.erase(note.id)
		_species.erase(id)
	return ok


## Nombre de cases de la grille (151 pour Kanto ; 0 si rien n'a été lu).
func size() -> int:
	return _size


func has_species(id: StringName) -> bool:
	return _species.has(id)


## Données de l'espèce [param id], ou null.
func get_species(id: StringName) -> PokedexSpeciesData:
	return _species.get(id)


## Identifiants des espèces, dans l'ordre du fichier.
func get_species_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_species.keys())
	return ids


## Notes de l'espèce [param id], dans l'ordre du fichier (vide si aucune).
func get_notes(id: StringName) -> Array[PokedexNoteData]:
	var entry: PokedexSpeciesData = _species.get(id)
	var notes: Array[PokedexNoteData] = []
	if entry != null:
		notes.assign(entry.notes)
	return notes


## Note [param id], ou null.
func get_note(id: StringName) -> PokedexNoteData:
	return _notes.get(id)


## Erreurs signalées depuis la création.
func get_errors() -> PackedStringArray:
	return _errors


func _parse_species(value: Variant, id: StringName, where: String) -> PokedexSpeciesData:
	if not value is Dictionary:
		_fail("%s : un objet est attendu" % where)
		return null
	var entry: Dictionary = value
	var ok := _check_keys(entry, _SPECIES_KEYS, _SPECIES_REQUIRED, where)
	var species := PokedexSpeciesData.new()
	species.id = id
	if entry.has("height"):
		if not _is_number(entry["height"]) or float(entry["height"]) <= 0.0 \
				or float(entry["height"]) > _MAX_HEIGHT:
			ok = _fail("%s : « height » est une taille en mètres (> 0)" % where)
		else:
			species.height = float(entry["height"])
	if entry.has("weight"):
		if not _is_number(entry["weight"]) or float(entry["weight"]) <= 0.0 \
				or float(entry["weight"]) > _MAX_WEIGHT:
			ok = _fail("%s : « weight » est un poids en kilogrammes (> 0)" % where)
		else:
			species.weight = float(entry["weight"])
	if entry.has("description"):
		if not _is_text(entry["description"]):
			ok = _fail("%s : « description » est un texte non vide" % where)
		else:
			species.description = (entry["description"] as String).strip_edges()
	if entry.has("draft"):
		if not entry["draft"] is bool:
			ok = _fail("%s : « draft » vaut true ou false" % where)
		else:
			species.draft = entry["draft"]
	if entry.has("notes"):
		if not entry["notes"] is Array:
			ok = _fail("%s : « notes » est une liste de notes" % where)
		else:
			var raw_notes: Array = entry["notes"]
			for i: int in raw_notes.size():
				var note := _parse_note(raw_notes[i], id, "%s note %d" % [where, i + 1])
				if note == null:
					ok = false
				elif _notes.has(note.id) or _has_note(species.notes, note.id):
					ok = _fail("%s : note « %s » déjà définie" % [where, note.id])
				else:
					species.notes.append(note)
	return species if ok else null


func _parse_note(value: Variant, species_id: StringName, where: String) -> PokedexNoteData:
	if not value is Dictionary:
		_fail("%s : un objet est attendu" % where)
		return null
	var entry: Dictionary = value
	var ok := _check_keys(entry, _NOTE_KEYS, _NOTE_REQUIRED, where)
	var note := PokedexNoteData.new()
	note.species = species_id
	if entry.has("id"):
		if not _is_text(entry["id"]):
			ok = _fail("%s : « id » est un identifiant" % where)
		else:
			note.id = StringName(entry["id"])
	if entry.has("text"):
		if not _is_text(entry["text"]):
			ok = _fail("%s : « text » est un texte non vide" % where)
		else:
			note.text = (entry["text"] as String).strip_edges()
	if entry.has("draft"):
		if not entry["draft"] is bool:
			ok = _fail("%s : « draft » vaut true ou false" % where)
		else:
			note.draft = entry["draft"]
	if entry.has("unlock"):
		ok = _read_unlock(entry["unlock"], note, where) and ok
	return note if ok else null


func _read_unlock(value: Variant, note: PokedexNoteData, where: String) -> bool:
	if not value is Dictionary or (value as Dictionary).is_empty():
		return _fail("%s : « unlock » est un objet d'au moins une condition (%s)" % [where,
			", ".join(PackedStringArray(_UNLOCK_KEYS))])
	var unlock: Dictionary = value
	var ok := true
	for key: Variant in unlock:
		if not _UNLOCK_KEYS.has(str(key)):
			ok = _fail("%s : condition inconnue « %s »" % [where, key])
	for key: String in ["seen", "caught"]:
		if not unlock.has(key):
			continue
		var count: Variant = unlock[key]
		if not _is_int(count) or int(count) < 1 or int(count) > _MAX_COUNT:
			ok = _fail("%s : « unlock.%s » est un entier ≥ 1" % [where, key])
		else:
			note.set(key, int(count))
	for key: String in ["map", "flag"]:
		if not unlock.has(key):
			continue
		if not _is_text(unlock[key]):
			ok = _fail("%s : « unlock.%s » est un identifiant" % [where, key])
		else:
			note.set(key, StringName(unlock[key]))
	return ok


static func _has_note(notes: Array[PokedexNoteData], id: StringName) -> bool:
	for note: PokedexNoteData in notes:
		if note.id == id:
			return true
	return false


func _check_keys(entry: Dictionary, allowed: Array[String], required: Array[String],
		where: String) -> bool:
	var ok := true
	for key: Variant in entry:
		if not allowed.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	for key: String in required:
		if not entry.has(key):
			ok = _fail("%s : « %s » est obligatoire" % [where, key])
	return ok


static func _is_text(value: Variant) -> bool:
	return value is String and not (value as String).strip_edges().is_empty()


static func _is_number(value: Variant) -> bool:
	return value is float or value is int


static func _is_int(value: Variant) -> bool:
	return _is_number(value) and float(value) == floorf(float(value))


func _fail(message: String) -> bool:
	var full := "PokedexLibrary : " + message
	_errors.append(full)
	push_error(full)
	return false
