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
## verb (talk | observe | take | examine ; take = objet visible au sol, jalon 8 ; examine = objet
## fixe qu'on examine, jalon 12 : les fossiles de la dalle), turn_to_player (true),
## keep_facing (false), lift (0 pixel),
## hop_style (calm | eager | playful : style de saut, jalon 4 ; aucun par défaut),
## shy ({ action: fly | flee | notice | hide, radius: 1..4 } : réaction d'ambiance, jalon 5 ;
## notice et hide au jalon 9 ; interdit sur un PNJ interactif),
## if et unless (listes de drapeaux : présence conditionnelle, jalon 3B §2.6),
## species (espèce d'un Pokémon du décor : le geste OBSERVER l'enregistre « vu » au Pokédex,
## jalon 6 §3.5, Q-7 ; seulement avec « verb »: « observe » et un dialogue ; l'espèce est
## vérifiée contre PokemonData par les tests des données réelles),
## idle_react (secondes > 0 : petite animation d'ambiance périodique, jalon 7 : le Roucool de
## la Dresseuse ; interdit sur un Pokémon « shy »),
## look ({ "facings": ["up", "left", …], "every": 3.5 } : attente animée, jalon 7 — il se
## tourne tour à tour vers chaque orientation ; « every » facultatif, dans [0,5 ; 120] ;
## interdit avec « route »),
## route (routine de marche, jalon 5, étendue au jalon 7 :
## { "cells": [[x, y], …], "pause": 1.2, "start": 1, "enter": { "cell": [x, y], "seconds": 8 } },
## voir [method _read_route]).
## trainer (jalon 9, jalon-09.md §2.4.1) : { "id": dresseur de data/trainers/, "sight": 1..8,
## "before": dialogue avant le combat, "defeated": réplique dite une fois après la victoire du
## joueur, facultative (jalon 10, jalon-10.md §2.5), "rematch": réplique de reprise après une
## défaite du joueur, "leave": [[dx, dy], …] départ après sa défaite (jalon 12, jalon-12.md §2.11,
## voir [method _read_trainer_j12]) } ; exige « facing » écrit et « dialogue »
## (la réplique « après »), le verbe « talk », et refuse « route », « look », « shy » et « idle_react » (un
## Dresseur qui bouge ou se tourne changerait sa vision), voir [method _read_trainer].
## moved (jalon 14, jalon-14.md §2.8) : { "if": [...], "unless": [...], "cell": [x, y],
## "facing": "left" } : autre place quand ses drapeaux sont remplis (au moins un drapeau ;
## « facing » facultatif, celle de l'entrée par défaut) ; refusée avec « trainer » (sa vision
## lit l'orientation de l'entrée) et « route » (la boucle part de « cell »), voir
## [method _read_moved].
## move_mode (passe systèmes 2, S2C) : « walk » (défaut) ou « surf » (Nageur : il se déplace sur
## l'eau surfable, y compris pour rejoindre le joueur).
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
	"hop_style", "shy", "route", "if", "unless", "species", "idle_react", "look",
	"trainer",
	"moved", "move_mode",
]
## Clés du bloc « trainer » ([method _read_trainer]).
const TRAINER_KEYS: Array[String] = ["id", "sight", "before", "defeated", "rematch", "leave"]
## Clés d'une attente animée « look » ([method _read_look]).
const LOOK_KEYS: Array[String] = ["facings", "every"]
## Clés d'une routine « route » ([method _read_route]).
const ROUTE_KEYS: Array[String] = ["cells", "pause", "start", "enter"]
const _ENTER_KEYS: Array[String] = ["cell", "seconds"]
## Clés d'une autre place « moved » ([method _read_moved], jalon 14).
const MOVED_KEYS: Array[String] = ["if", "unless", "cell", "facing"]

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
		if verb != Interaction.Kind.TALK and verb != Interaction.Kind.OBSERVE \
				and verb != Interaction.Kind.TAKE and verb != Interaction.Kind.EXAMINE:
			errors.append("« verb » vaut talk, observe, take ou examine")
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
	if entry.has("idle_react"):
		var every: Variant = entry["idle_react"]
		if not (every is float or every is int) or float(every) <= 0.0 \
				or float(every) > NpcSpec.IDLE_REACT_MAX:
			errors.append("« idle_react » doit être un nombre de secondes dans ]0, %s]"
				% NpcSpec.IDLE_REACT_MAX)
		elif spec.is_shy():
			errors.append("« idle_react » interdit sur un Pokémon « shy »")
		else:
			spec.idle_react_every = float(every)
	if entry.has("look"):
		_read_look(entry["look"], spec, errors)
	if entry.has("move_mode"):
		match str(entry["move_mode"]):
			"walk":
				spec.move_mode = GridWorld.MoveMode.WALK
			"surf":
				spec.move_mode = GridWorld.MoveMode.SURF
			_:
				errors.append("« move_mode » vaut walk ou surf")
	if entry.has("species"):
		if not entry["species"] is String or (entry["species"] as String).is_empty():
			errors.append("« species » doit être un identifiant d'espèce")
		elif spec.verb != Interaction.Kind.OBSERVE or not spec.is_interactive():
			errors.append("« species » demande « verb »: « observe » et un dialogue")
		else:
			spec.species = StringName(entry["species"])
	if entry.has("trainer"):
		_read_trainer(entry, spec, errors)
	if entry.has("moved"):
		_read_moved(entry, spec, errors)
	return spec if errors.size() == count else null


## Lit l'autre place « moved » (jalon 14) : { "if", "unless" (au moins un drapeau en tout),
## "cell" (obligatoire, différente de « cell »), "facing" (facultatif) }. Refusée avec
## « trainer » et « route ».
static func _read_moved(entry: Dictionary, spec: NpcSpec, errors: PackedStringArray) -> void:
	var value: Variant = entry["moved"]
	if not value is Dictionary:
		errors.append("« moved » doit être { \"if\", \"unless\", \"cell\", \"facing\" }")
		return
	var block: Dictionary = value
	var count := errors.size()
	for key: Variant in block:
		if not MOVED_KEYS.has(str(key)):
			errors.append("« moved » : clé inconnue « %s »" % key)
	var if_flags: Array[StringName] = []
	var unless_flags: Array[StringName] = []
	_read_flags(block, "if", if_flags, errors)
	_read_flags(block, "unless", unless_flags, errors)
	if not block.has("if") and not block.has("unless"):
		errors.append("« moved » exige « if » ou « unless » (sinon, changer « cell »)")
	var cell := NpcSpec.NO_MOVED_CELL
	if not is_cell(block.get("cell")):
		errors.append("« moved.cell » doit être [x, y] (entiers ≥ 0)")
	else:
		cell = Vector2i(int(block["cell"][0]), int(block["cell"][1]))
		if cell == spec.cell:
			errors.append("« moved.cell » est déjà « cell » %s" % cell)
	var facing := spec.facing
	if block.has("facing"):
		if not block["facing"] is String or not Grid.is_direction_name(block["facing"]):
			errors.append("« moved.facing » vaut down, up, left ou right")
		else:
			facing = Grid.direction_from_name(block["facing"])
	for key: String in ["trainer", "route"]:
		if entry.has(key):
			errors.append("« moved » interdit avec « %s »" % key)
	if errors.size() != count:
		return
	spec.moved_cell = cell
	spec.moved_facing = facing
	spec.moved_if_flags = if_flags
	spec.moved_unless_flags = unless_flags


## Lit le bloc « trainer » (jalon 9) : { "id", "sight" (entier 1..8), "before", "defeated"
## (facultatif, jalon 10 : réplique dite une fois après la victoire du joueur) } et vérifie
## le reste de l'entrée (lue avant) : « facing » écrit, « dialogue » (réplique « après »),
## verbe « talk », ni « route », ni « look », ni « shy », ni « idle_react ». Les références
## (dresseur, dialogues) sont vérifiées par les tests des données réelles.
static func _read_trainer(entry: Dictionary, spec: NpcSpec, errors: PackedStringArray) -> void:
	var value: Variant = entry["trainer"]
	if not value is Dictionary:
		errors.append("« trainer » doit être { \"id\", \"sight\", \"before\" }")
		return
	var block: Dictionary = value
	var count := errors.size()
	for key: Variant in block:
		if not TRAINER_KEYS.has(str(key)):
			errors.append("« trainer » : clé inconnue « %s »" % key)
	for key: String in ["id", "before"]:
		if not block.get(key) is String or (block.get(key) as String).is_empty():
			errors.append("« trainer.%s » doit être un identifiant" % key)
	if block.has("defeated") and (not block["defeated"] is String
			or (block["defeated"] as String).is_empty()):
		errors.append("« trainer.defeated » doit être un identifiant")
	var sight: Variant = block.get("sight")
	if not (sight is float or sight is int) or float(sight) != floorf(float(sight)) \
			or int(sight) < TrainerRules.SIGHT_MIN or int(sight) > TrainerRules.SIGHT_MAX:
		errors.append("« trainer.sight » doit être un entier de %d à %d"
			% [TrainerRules.SIGHT_MIN, TrainerRules.SIGHT_MAX])
	if not entry.has("facing"):
		errors.append("« trainer » exige « facing » (sa vision part devant lui)")
	if not spec.is_interactive():
		errors.append("« trainer » exige « dialogue » (sa réplique après le combat)")
	if spec.verb != Interaction.Kind.TALK:
		errors.append("« trainer » exige le verbe « talk »")
	for key: String in ["route", "look", "shy", "idle_react"]:
		if entry.has(key):
			errors.append("« %s » interdit sur un Dresseur (sa vision est fixe)" % key)
	if errors.size() != count:
		return
	spec.trainer_id = StringName(block["id"])
	spec.sight = int(sight)
	spec.before_dialogue = StringName(block["before"])
	spec.defeated_dialogue = StringName(block.get("defeated", ""))
	_read_trainer_j12(entry, block, spec, errors)


## Lit l'attente animée « look » : { "facings": [noms de directions, au moins deux],
## "every": secondes } (« every » facultatif : [constant NpcSpec.LOOK_EVERY_DEFAULT]).
## Refusée avec une routine de marche.
static func _read_look(value: Variant, spec: NpcSpec, errors: PackedStringArray) -> void:
	if not value is Dictionary:
		errors.append("« look » doit être { \"facings\": [...], \"every\": secondes }")
		return
	var look: Dictionary = value
	for key: Variant in look:
		if not LOOK_KEYS.has(str(key)):
			errors.append("« look » : clé inconnue « %s »" % key)
	var names: Variant = look.get("facings")
	if not names is Array or (names as Array).size() < 2:
		errors.append("« look.facings » : au moins deux orientations")
		return
	var facings: Array[Vector2i] = []
	for direction: Variant in names:
		if not direction is String or not Grid.is_direction_name(direction):
			errors.append("« look.facings » : down, up, left ou right")
			return
		facings.append(Grid.direction_from_name(direction))
	var every := NpcSpec.LOOK_EVERY_DEFAULT
	if look.has("every"):
		var raw: Variant = look["every"]
		if not (raw is float or raw is int) or float(raw) < NpcSpec.LOOK_EVERY_MIN \
				or float(raw) > NpcSpec.LOOK_EVERY_MAX:
			errors.append("« look.every » : secondes dans [%s, %s]"
				% [NpcSpec.LOOK_EVERY_MIN, NpcSpec.LOOK_EVERY_MAX])
			return
		every = float(raw)
	if spec.has_route():
		errors.append("« look » interdit avec « route » (la marche le fait déjà vivre)")
		return
	spec.look_facings = facings
	spec.look_every = every


## Lit la réaction d'ambiance « shy » : { "action": "fly" | "flee" | "notice" | "hide",
## "radius": 1..4 }.
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
## Jalon 7 (dossier 09 §2), facultatifs :
## - « start » : index de départ dans « cells » (entier, dans les bornes) ; « cell » du PNJ
##   doit alors être cette case. Sans « start » : première occurrence de « cell » dans la
##   boucle, 0 si elle n'y est pas (comportement du jalon 5) ;
## - « enter » : { "cell": [x, y], "seconds": s } : arrivé sur cette case (qui appartient à la
##   boucle), le PNJ entre dans un bâtiment et reste absent s secondes (]0, 120]).
static func _read_route(value: Variant, spec: NpcSpec, errors: PackedStringArray) -> void:
	if not value is Dictionary:
		errors.append("« route » doit être un objet { cells, pause, start, enter }")
		return
	var route: Dictionary = value
	for key: Variant in route:
		if not ROUTE_KEYS.has(str(key)):
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
	if not spec.has_route():
		return
	if route.has("start"):
		var start: Variant = route["start"]
		if not (start is float or start is int) or float(start) != floorf(float(start)) \
				or int(start) < 0 or int(start) >= spec.route_cells.size():
			errors.append("« route.start » doit être un index de « route.cells » (0 à %d)"
				% (spec.route_cells.size() - 1))
		elif spec.route_cells[int(start)] != spec.cell:
			errors.append("« route.start » : la case %s n'est pas « cell » %s" % [
				spec.route_cells[int(start)], spec.cell])
		else:
			spec.route_start = int(start)
	else:
		spec.route_start = maxi(spec.route_cells.find(spec.cell), 0)
	if route.has("enter"):
		_read_route_enter(route["enter"], spec, errors)


## « route.enter » : { "cell": [x, y], "seconds": s } ; la case appartient à la boucle.
static func _read_route_enter(value: Variant, spec: NpcSpec, errors: PackedStringArray) -> void:
	if not value is Dictionary:
		errors.append("« route.enter » doit être un objet { cell, seconds }")
		return
	var enter: Dictionary = value
	var count := errors.size()
	for key: Variant in enter:
		if not _ENTER_KEYS.has(str(key)):
			errors.append("clé inconnue dans « route.enter » : « %s »" % key)
	var cell := NpcSpec.NO_ENTER_CELL
	if not is_cell(enter.get("cell")):
		errors.append("« route.enter.cell » doit être [x, y] (entiers ≥ 0)")
	else:
		cell = Vector2i(int(enter["cell"][0]), int(enter["cell"][1]))
		if not spec.route_cells.has(cell):
			errors.append("« route.enter.cell » %s n'appartient pas à la boucle" % cell)
	var seconds: Variant = enter.get("seconds")
	if not (seconds is float or seconds is int) or float(seconds) <= 0.0 \
			or float(seconds) > NpcSpec.ROUTE_ENTER_SECONDS_MAX:
		errors.append("« route.enter.seconds » doit être un nombre dans ]0, %s]"
			% NpcSpec.ROUTE_ENTER_SECONDS_MAX)
	if errors.size() == count:
		spec.route_enter_cell = cell
		spec.route_enter_seconds = float(seconds)


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


## Jalon 12 (jalon-12.md §2.11) : clés facultatives du bloc « trainer », lues après les autres.
## - « rematch » : identifiant de dialogue (réplique de reprise, drapeau `lost_<id>`) ;
## - « leave » : liste de 0 à [constant NpcSpec.LEAVE_STEPS_MAX] cases **relatives à la case de
##   départ** ([dx, dy], entiers, chaque composante dans ±[constant TrainerRules.SIGHT_MAX]),
##   la case absolue restant ≥ 0 ; exige « unless » contenant `beaten_<id>` (le Dresseur parti
##   n'est plus sur la carte au retour).
static func _read_trainer_j12(entry: Dictionary, block: Dictionary, spec: NpcSpec,
		errors: PackedStringArray) -> void:
	if block.has("rematch"):
		if not block["rematch"] is String or (block["rematch"] as String).is_empty():
			errors.append("« trainer.rematch » doit être un identifiant")
		else:
			spec.rematch_dialogue = StringName(block["rematch"])
	if not block.has("leave"):
		return
	var value: Variant = block["leave"]
	if not value is Array or (value as Array).size() > NpcSpec.LEAVE_STEPS_MAX:
		errors.append("« trainer.leave » doit être une liste de 0 à %d cases [dx, dy]"
			% NpcSpec.LEAVE_STEPS_MAX)
		return
	var cells: Array[Vector2i] = []
	for item: Variant in value:
		if not is_offset(item, TrainerRules.SIGHT_MAX):
			errors.append("« trainer.leave » : case relative [dx, dy] invalide (entiers, ±%d)"
				% TrainerRules.SIGHT_MAX)
			return
		var offset := Vector2i(int(item[0]), int(item[1]))
		var target := spec.cell + offset
		if target.x < 0 or target.y < 0:
			errors.append("« trainer.leave » : la case %s sort de la carte" % target)
			return
		cells.append(offset)
	if not spec.unless_flags.has(TrainerRules.beaten_flag(spec.trainer_id)):
		errors.append("« trainer.leave » exige « unless »: [\"%s\"] (parti, il ne revient pas)"
			% TrainerRules.beaten_flag(spec.trainer_id))
		return
	spec.leave_cells = cells
	spec.leaves = true


## Vrai pour une case relative de données : [dx, dy], entiers de −[param limit] à [param limit].
static func is_offset(value: Variant, limit: int) -> bool:
	if not value is Array or (value as Array).size() != 2:
		return false
	for n: Variant in value:
		if not (n is float or n is int) or float(n) != floorf(float(n)) \
				or absf(float(n)) > float(limit):
			return false
	return true
