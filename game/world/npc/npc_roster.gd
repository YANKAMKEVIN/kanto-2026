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
## verb (talk | observe), turn_to_player (true), keep_facing (false), lift (0 pixel),
## hop_style (calm | eager | playful : style de saut, jalon 4 ; aucun par défaut),
## shy ({ action: fly | flee, radius: 1..4 } : réaction d'ambiance, jalon 5 ; interdit sur
## un PNJ interactif),
## if et unless (listes de drapeaux : présence conditionnelle, jalon 3B §2.6),
## species (espèce d'un Pokémon du décor : le geste OBSERVER l'enregistre « vu » au Pokédex,
## jalon 6 §3.5, Q-7 ; seulement avec « verb »: « observe » et un dialogue ; l'espèce est
## vérifiée contre PokemonData par les tests des données réelles).
## Le verbe « meet » (Rencontrer) est refusé : il est posé par le code (jalon 4 §3.5).
## Toute autre clé est une erreur. Pas de fichier = aucun PNJ sur la carte (sans erreur).
## L'identifiant « player » est réservé au joueur.

const DATA_DIR: String = "res://data/npcs/"

## Identifiant réservé au joueur (acteur des scènes et des « turn » de dialogue) : aucun PNJ
## ne peut le porter.
const PLAYER_ID: StringName = &"player"
## Clés d'une entrée (aussi celles de l'étape « spawn » des scènes, sans if / unless).
const KEYS: Array[String] = [
	"cell", "facing", "sprite", "dialogue", "verb", "turn_to_player", "keep_facing", "lift",
	"hop_style", "shy", "route", "if", "unless", "species",
]

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
		if id == PLAYER_ID:
			ok = _fail("%s : identifiant réservé au joueur" % where)
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


## PNJ présents avec les drapeaux [param flags] (null = nouvelle partie), dans l'ordre du
## fichier.
func get_present(flags: StoryFlags) -> Array[NpcSpec]:
	var present: Array[NpcSpec] = []
	for spec: NpcSpec in _specs:
		if spec.is_present(flags):
			present.append(spec)
	return present


func get_spec(id: StringName) -> NpcSpec:
	for spec: NpcSpec in _specs:
		if spec.id == id:
			return spec
	return null


func size() -> int:
	return _specs.size()


func get_errors() -> PackedStringArray:
	return _errors


## Valide une entrée de PNJ (objet JSON déjà lu) et renvoie sa description, ou null si elle
## est invalide. Les erreurs sont **ajoutées** à [param errors], sans préfixe ni push_error :
## l'appelant ([NpcRoster], ou CutsceneLibrary pour l'étape « spawn ») les situe et les
## signale. L'identifiant n'est pas lu ici : l'appelant le renseigne.
static func parse_entry(value: Variant, errors: PackedStringArray) -> NpcSpec:
	if not value is Dictionary:
		errors.append("un objet est attendu")
		return null
	var entry: Dictionary = value
	var spec := NpcSpec.new()
	var count := errors.size()
	for key: Variant in entry:
		if not KEYS.has(str(key)):
			errors.append("clé inconnue « %s »" % key)
	var cell: Variant = entry.get("cell")
	if not is_cell(cell):
		errors.append("« cell » doit être [x, y] (entiers ≥ 0)")
	else:
		spec.cell = Vector2i(int(cell[0]), int(cell[1]))
	if not entry.get("sprite") is String or (entry.get("sprite") as String).is_empty():
		errors.append("« sprite » est obligatoire")
	else:
		spec.sprite = StringName(entry["sprite"])
	if entry.has("facing"):
		if not entry["facing"] is String or not Grid.is_direction_name(entry["facing"]):
			errors.append("« facing » vaut down, up, left ou right")
		else:
			spec.facing = Grid.direction_from_name(entry["facing"])
	if entry.has("dialogue"):
		if not entry["dialogue"] is String or (entry["dialogue"] as String).is_empty():
			errors.append("« dialogue » doit être un identifiant")
		else:
			spec.dialogue = StringName(entry["dialogue"])
	if entry.has("verb"):
		var verb := Interaction.kind_from_name(str(entry["verb"]))
		if verb != Interaction.Kind.TALK and verb != Interaction.Kind.OBSERVE:
			errors.append("« verb » vaut talk ou observe")
		else:
			spec.verb = verb as Interaction.Kind
	for key: String in ["turn_to_player", "keep_facing"]:
		if entry.has(key):
			if not entry[key] is bool:
				errors.append("« %s » vaut true ou false" % key)
			else:
				spec.set(key, entry[key])
	if entry.has("lift"):
		var lift: Variant = entry["lift"]
		if not (lift is float or lift is int) or float(lift) != floorf(float(lift)) \
				or float(lift) < 0.0:
			errors.append("« lift » doit être un nombre entier de pixels ≥ 0")
		else:
			spec.lift = int(lift)
	if entry.has("hop_style"):
		var style: Variant = entry["hop_style"]
		if not style is String or not NpcSpec.HOP_STYLES.has(StringName(style)):
			errors.append("« hop_style » vaut %s" % ", ".join(PackedStringArray(
				NpcSpec.HOP_STYLES)))
		else:
			spec.hop_style = StringName(style)
	if entry.has("shy"):
		_read_shy(entry["shy"], spec, errors)
	if entry.has("route"):
		_read_route(entry["route"], spec, errors)
	_read_flags(entry, "if", spec.if_flags, errors)
	_read_flags(entry, "unless", spec.unless_flags, errors)
	if entry.has("species"):
		if not entry["species"] is String or (entry["species"] as String).is_empty():
			errors.append("« species » doit être un identifiant d'espèce")
		elif spec.verb != Interaction.Kind.OBSERVE or not spec.is_interactive():
			errors.append("« species » demande « verb »: « observe » et un dialogue")
		else:
			spec.species = StringName(entry["species"])
	return spec if errors.size() == count else null


## Lit la réaction d'ambiance « shy » : { "action": "fly" | "flee", "radius": 1..4 }.
## Refusée sur un PNJ interactif (un Pokémon qui fuit ne se parle pas). « radius » facultatif
## ([constant NpcSpec.SHY_RADIUS_DEFAULT] par défaut).
static func _read_shy(value: Variant, spec: NpcSpec, errors: PackedStringArray) -> void:
	if not value is Dictionary:
		errors.append("« shy » doit être un objet { action, radius }")
		return
	var shy: Dictionary = value
	for key: Variant in shy:
		if str(key) != "action" and str(key) != "radius":
			errors.append("clé inconnue dans « shy » : « %s »" % key)
	var action: Variant = shy.get("action")
	if not action is String or not NpcSpec.SHY_ACTIONS.has(StringName(action)):
		errors.append("« shy.action » vaut %s" % ", ".join(PackedStringArray(
			NpcSpec.SHY_ACTIONS)))
	else:
		spec.shy_action = StringName(action)
	if shy.has("radius"):
		var radius: Variant = shy["radius"]
		if not (radius is float or radius is int) or float(radius) != floorf(float(radius)) \
				or int(radius) < 1 or int(radius) > 4:
			errors.append("« shy.radius » doit être un entier de 1 à 4")
		else:
			spec.shy_radius = int(radius)
	if not spec.shy_action.is_empty() and spec.is_interactive():
		errors.append("« shy » interdit sur un PNJ interactif (dialogue)")


## Lit une routine de marche (jalon 5, le Voyageur) :
## { "cells": [[x, y], …], "pause": secondes }. Deux cases consécutives (et la boucle de la
## dernière à la première) doivent être voisines (un pas cardinal). « pause » facultatif
## ([constant NpcSpec.ROUTE_PAUSE_DEFAULT] par défaut). Interdit sur un Pokémon « shy ».
static func _read_route(value: Variant, spec: NpcSpec, errors: PackedStringArray) -> void:
	if not value is Dictionary:
		errors.append("« route » doit être un objet { cells, pause }")
		return
	var route: Dictionary = value
	for key: Variant in route:
		if str(key) != "cells" and str(key) != "pause":
			errors.append("clé inconnue dans « route » : « %s »" % key)
	var cells: Variant = route.get("cells")
	if not cells is Array or (cells as Array).size() < 2:
		errors.append("« route.cells » doit lister au moins 2 cases")
	else:
		var parsed: Array[Vector2i] = []
		var ok := true
		for c: Variant in cells:
			if not is_cell(c):
				errors.append("« route.cells » : chaque case est [x, y] (entiers ≥ 0)")
				ok = false
				break
			parsed.append(Vector2i(int(c[0]), int(c[1])))
		if ok:
			for i: int in parsed.size():
				var a := parsed[i]
				var b := parsed[(i + 1) % parsed.size()]
				if not Grid.is_cardinal(b - a):
					errors.append("« route.cells » : %s et %s ne sont pas voisines" % [a, b])
					ok = false
					break
		if ok:
			spec.route_cells = parsed
	if route.has("pause"):
		var pause: Variant = route["pause"]
		if not (pause is float or pause is int) or float(pause) < 0.0:
			errors.append("« route.pause » doit être un nombre ≥ 0")
		else:
			spec.route_pause = float(pause)
	if spec.has_route() and spec.is_shy():
		errors.append("« route » interdit sur un Pokémon « shy »")


## Vrai pour une case de données : [x, y], entiers ≥ 0.
static func is_cell(value: Variant) -> bool:
	if not value is Array or (value as Array).size() != 2:
		return false
	for n: Variant in value:
		if not (n is float or n is int) or float(n) != floorf(float(n)) or float(n) < 0.0:
			return false
	return true


func _parse(value: Variant, where: String) -> NpcSpec:
	var errors := PackedStringArray()
	var spec := parse_entry(value, errors)
	for message: String in errors:
		_fail("%s : %s" % [where, message])
	return spec


static func _read_flags(entry: Dictionary, key: String, into: Array[StringName],
		errors: PackedStringArray) -> void:
	if not entry.has(key):
		return
	if not entry[key] is Array or (entry[key] as Array).is_empty():
		errors.append("« %s » doit être une liste non vide de drapeaux" % key)
		return
	for flag: Variant in entry[key]:
		if not flag is String or (flag as String).is_empty():
			errors.append("drapeau invalide dans « %s »" % key)
			return
		into.append(StringName(flag))


func _fail(message: String) -> bool:
	var full := "NpcRoster : " + message
	_errors.append(full)
	push_error(full)
	return false
