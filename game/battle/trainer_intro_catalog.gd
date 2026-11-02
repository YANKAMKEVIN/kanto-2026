class_name TrainerIntroCatalog
extends RefCounted
## Réglages et classes de l'entrée des combats de Dresseur (dossier 05 §3, décision de Kevin du
## 2026-11-02), lus dans `data/battle/trainer_intro.json`. Classe pure, validation stricte.
##
## - « durations » : durées (s) des étapes ([enum TrainerIntro.Step]) ;
## - « layout » : tailles en hauteurs d'écran (présentation) ;
## - « paths » : conventions des images (sprite de face, portrait de banderole) ;
## - « classes » : classe de Dresseur ordinaire → préfixe de son nom (« Gamin » pour « Gamin
##   Hugo ») et apparence du monde (repli du sprite de face) ;
## - « grand » : identifiant de portrait d'un grand adversaire (bloc « card » du Dresseur) →
##   apparence du monde (repli).

const PATH: String = "res://data/battle/trainer_intro.json"
const DURATION_KEYS: Array[String] = [
	"vs_in", "vs_hold", "vs_out", "trainers_in", "balls_in", "send_throw", "send_exit",
]
const LAYOUT_KEYS: Array[String] = [
	"foe_trainer_height", "trainer_slide", "ball_size", "ball_gap", "throw_arc",
]
const PATH_KEYS: Array[String] = ["front_dir", "portrait_dir", "extension"]

## Durées (s) par clé de [constant DURATION_KEYS].
var durations: Dictionary[String, float] = {}
## Tailles (hauteurs d'écran) par clé de [constant LAYOUT_KEYS].
var layout: Dictionary[String, float] = {}
var front_dir: String = ""
var portrait_dir: String = ""
var extension: String = ""

## Classe → préfixe du nom, et classe → apparence du monde.
var _prefixes: Dictionary[StringName, String] = {}
var _class_sprites: Dictionary[StringName, StringName] = {}
## Grand adversaire (identifiant de portrait) → apparence du monde.
var _grand_sprites: Dictionary[StringName, StringName] = {}
var _errors: PackedStringArray = PackedStringArray()

static var _shared: TrainerIntroCatalog


## Catalogue du jeu, lu une fois.
static func shared() -> TrainerIntroCatalog:
	if _shared == null:
		_shared = TrainerIntroCatalog.new()
		_shared.load_file()
	return _shared


## Lit [param path]. Faux si une erreur a été signalée.
func load_file(path: String = PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail("TrainerIntroCatalog : fichier introuvable « %s »" % path)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _fail("TrainerIntroCatalog : JSON invalide « %s »" % path)
	return add_from_dict(parsed)


## Lit un catalogue déjà décodé (tests). Faux si une erreur a été signalée.
func add_from_dict(root: Dictionary) -> bool:
	var ok := true
	ok = _read_numbers(root.get("durations"), DURATION_KEYS, durations, "durations") and ok
	ok = _read_numbers(root.get("layout"), LAYOUT_KEYS, layout, "layout") and ok
	var paths: Variant = root.get("paths")
	if not paths is Dictionary:
		ok = _fail("TrainerIntroCatalog : « paths » manquant")
	else:
		for key: String in PATH_KEYS:
			if not (paths as Dictionary).get(key) is String:
				ok = _fail("TrainerIntroCatalog : paths.%s doit être un texte" % key)
		if ok:
			front_dir = paths["front_dir"]
			portrait_dir = paths["portrait_dir"]
			extension = paths["extension"]
	var classes: Variant = root.get("classes")
	if not classes is Dictionary:
		ok = _fail("TrainerIntroCatalog : « classes » manquant")
	else:
		for id: Variant in classes:
			var entry: Variant = (classes as Dictionary)[id]
			if not entry is Dictionary or not (entry as Dictionary).get("prefix") is String \
					or not (entry as Dictionary).get("world_sprite") is String:
				ok = _fail("TrainerIntroCatalog : classe « %s » : { prefix, world_sprite }" % id)
				continue
			_prefixes[StringName(str(id))] = entry["prefix"]
			_class_sprites[StringName(str(id))] = StringName(entry["world_sprite"])
	var grand: Variant = root.get("grand")
	if not grand is Dictionary:
		ok = _fail("TrainerIntroCatalog : « grand » manquant")
	else:
		for id: Variant in grand:
			var entry: Variant = (grand as Dictionary)[id]
			if not entry is Dictionary or not (entry as Dictionary).get("world_sprite") is String:
				ok = _fail("TrainerIntroCatalog : grand « %s » : { world_sprite }" % id)
				continue
			_grand_sprites[StringName(str(id))] = StringName(entry["world_sprite"])
	return ok


## Classe du Dresseur ordinaire nommé [param trainer_name] : le plus long préfixe de classe
## suivi d'une espace (ou le nom entier) ; &"" si aucune classe ne correspond.
func class_for(trainer_name: String) -> StringName:
	var best := &""
	var best_length := -1
	for id: StringName in _prefixes:
		var prefix := _prefixes[id]
		if (trainer_name == prefix or trainer_name.begins_with(prefix + " ")) \
				and prefix.length() > best_length:
			best = id
			best_length = prefix.length()
	return best


## Classes connues (ordre du fichier).
func class_ids() -> Array[StringName]:
	return _prefixes.keys()


## Grands adversaires connus (identifiants de portrait).
func grand_ids() -> Array[StringName]:
	return _grand_sprites.keys()


func has_grand(id: StringName) -> bool:
	return _grand_sprites.has(id)


## Apparence du monde (repli du sprite de face) d'une classe ou d'un grand adversaire ; &"" si
## l'identifiant est inconnu.
func world_sprite(id: StringName) -> StringName:
	if _class_sprites.has(id):
		return _class_sprites[id]
	return _grand_sprites.get(id, &"")


func duration(key: String) -> float:
	return durations.get(key, 0.0)


func get_errors() -> PackedStringArray:
	return _errors


func _read_numbers(value: Variant, keys: Array[String], into: Dictionary[String, float],
		label: String) -> bool:
	if not value is Dictionary:
		return _fail("TrainerIntroCatalog : « %s » manquant" % label)
	var ok := true
	for key: String in keys:
		var number: Variant = (value as Dictionary).get(key)
		if not (number is float or number is int) or float(number) < 0.0:
			ok = _fail("TrainerIntroCatalog : %s.%s doit être un nombre ≥ 0" % [label, key])
			continue
		into[key] = float(number)
	return ok


func _fail(message: String) -> bool:
	_errors.append(message)
	push_error(message)
	return false
