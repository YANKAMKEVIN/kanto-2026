class_name CompanionCatalog
extends RefCounted
## Espèces qui peuvent être compagnon et leur apparence (jalon 11, dossier 14 §8.1–8.2 ;
## `docs/tech/jalon-11-compagnon.md` §2.1), lues dans `data/pokemon/companions.json`. Donnée pure,
## validation stricte (comme les autres bibliothèques) : une entrée invalide est écartée.
##
## Une espèce n'est éligible que si elle a une planche d'exploration **repos + marche en 4
## directions** validée : la liste est en données, jamais déduite ; un test vérifie chaque
## planche (aucun substitut). « contexts » : carte → contexte de la phrase de curiosité.

const DATA_PATH: String = "res://data/pokemon/companions.json"
## Contextes de phrase connus (dossier 14 §13.12, n° 57 et 58 ; D-7).
const CONTEXTS: Array[StringName] = [&"forest", &"city", &"cave"]

const _KEYS: Array[String] = ["_doc", "species", "contexts"]
const _SPECIES_KEYS: Array[String] = ["sprite", "flying"]

var _sprites: Dictionary[StringName, StringName] = {}
var _flying: Dictionary[StringName, bool] = {}
var _contexts: Dictionary[StringName, StringName] = {}
var _errors: PackedStringArray = PackedStringArray()


## Lit [param path]. Faux si une erreur a été signalée (les entrées valides restent).
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet est attendu" % path)
	return add_from_dict(json.data, path)


## Lit un objet déjà décodé ([param data] facultatif : vérifie que chaque espèce existe).
func add_from_dict(dict: Dictionary, source: String = "", data: PokemonData = null) -> bool:
	var ok := true
	for key: Variant in dict:
		if not _KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	var species: Variant = dict.get("species", {})
	if not species is Dictionary:
		return _fail("%s : « species » doit être un objet { espèce: { sprite } }" % source)
	for key: Variant in species:
		var id := StringName(str(key))
		var where := "%s espèce « %s »" % [source, id]
		var entry: Variant = species[key]
		if not entry is Dictionary:
			ok = _fail("%s : un objet est attendu" % where)
			continue
		var valid := true
		for field: Variant in entry:
			if not _SPECIES_KEYS.has(str(field)):
				valid = _fail("%s : clé inconnue « %s »" % [where, field])
		var sprite: Variant = (entry as Dictionary).get("sprite")
		if not sprite is String or not (sprite as String).begins_with(CharacterLook.POKEMON_PREFIX):
			valid = _fail("%s : « sprite » doit valoir « pokemon/<espèce> »" % where)
		var flying: Variant = (entry as Dictionary).get("flying", false)
		if not flying is bool:
			valid = _fail("%s : « flying » vaut true ou false" % where)
		if data != null and not data.has_species(id):
			valid = _fail("%s : espèce inconnue" % where)
		if not valid:
			ok = false
			continue
		_sprites[id] = StringName(sprite)
		_flying[id] = flying
	var contexts: Variant = dict.get("contexts", {})
	if not contexts is Dictionary:
		return _fail("%s : « contexts » doit être un objet { carte: contexte }" % source)
	for key: Variant in contexts:
		var context: Variant = contexts[key]
		if not context is String or not CONTEXTS.has(StringName(context)):
			ok = _fail("%s : carte « %s » : contexte « %s » inconnu (%s)" % [source, key, context,
				", ".join(PackedStringArray(CONTEXTS))])
			continue
		_contexts[StringName(str(key))] = StringName(context)
	return ok


## Vrai si [param species] peut être compagnon.
func is_eligible_species(species: StringName) -> bool:
	return _sprites.has(species)


## Apparence de [param species] (`pokemon/<espèce>`, pour [method CharacterLook.resolve]) ;
## &"" si elle n'est pas éligible.
func sprite_of(species: StringName) -> StringName:
	return _sprites.get(species, &"")


## Vrai si [param species] se déplace en vol (ombre au sol, pas de devant de touffe).
func is_flying(species: StringName) -> bool:
	return _flying.get(species, false)


## Contexte de la phrase de curiosité sur la carte [param map_id] (&"" = générique).
func context_of(map_id: StringName) -> StringName:
	return _contexts.get(map_id, &"")


## Espèces éligibles, triées.
func get_species_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_sprites.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


func get_errors() -> PackedStringArray:
	return _errors


func _fail(message: String) -> bool:
	var full := "CompanionCatalog : " + message
	_errors.append(full)
	push_error(full)
	return false
