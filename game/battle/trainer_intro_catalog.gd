class_name TrainerIntroCatalog
extends RefCounted
## Réglages et classes de l'entrée des combats de Dresseur (dossier 05 §3, décisions de Kevin du
## 2026-11-02 ; cible : maquettes `reference/entree-dresseur-*-v1.png`), lus dans
## `data/battle/trainer_intro.json`. Classe pure, validation stricte.
##
## - « durations » : durées (s) des étapes ([enum TrainerIntro.Step]) ;
## - « message_hold_scale » : tenue des messages de l'ouverture (gestes et messages se chevauchent) ;
## - « layout » : tailles ; « poses » : [x, pieds, hauteur] des dresseurs (entrée, lancer, « VS ») ;
##   « points » : cartouche, mains, arcs des Balls ; fractions de l'écran (x depuis la gauche,
##   y depuis le haut), présentation ;
## - « paths » : conventions des images (sprite de face, pose de lancer, dos du joueur, portrait) ;
## - « classes » : classe de Dresseur ordinaire → préfixe de son nom (« Gamin » pour « Gamin
##   Hugo » ; vide : seulement imposée par les données, « class » du Dresseur) et apparence du
##   monde (repli du sprite de face) ;
## - « grand » : identifiant de portrait d'un grand adversaire (bloc « card » du Dresseur) →
##   apparence du monde (repli).

const PATH: String = "res://data/battle/trainer_intro.json"
const DURATION_KEYS: Array[String] = [
	"trainers_delay", "trainers_in", "balls_in", "vs_in", "vs_hold", "vs_out", "send_windup",
	"send_throw", "send_linger", "send_exit",
]
const LAYOUT_KEYS: Array[String] = [
	"trainer_slide", "shadow_width", "shadow_flatten", "cartouche_pad", "ball_gap",
	"ball_diameter", "trail_width", "windup_tilt",
]
const POINT_KEYS: Array[String] = [
	"cartouche_min", "cartouche_max", "player_hand", "foe_hand", "foe_via", "foe_target",
	"player_via", "player_target",
]
## Poses des dresseurs : à l'entrée, au lancer, pendant le « VS ».
const POSE_KEYS: Array[String] = ["entry", "throw", "vs"]
const POSE_SIDES: Array[String] = ["player", "foe"]
const PATH_KEYS: Array[String] = [
	"front_dir", "portrait_dir", "extension", "throw_suffix", "player_prefix",
]

## Durées (s) par clé de [constant DURATION_KEYS].
var durations: Dictionary[String, float] = {}
## Tailles (hauteurs d'écran) par clé de [constant LAYOUT_KEYS].
var layout: Dictionary[String, float] = {}
## Points (fractions de l'écran, ou de la hauteur du dresseur pour les mains) par clé de
## [constant POINT_KEYS].
var points: Dictionary[String, Vector2] = {}
## Poses : « entry/player » → (x du centre, y des pieds, hauteur), fractions de l'écran.
var poses: Dictionary[String, Vector3] = {}
## Facteur de tenue des messages de l'ouverture (1 : tenue normale).
var message_hold_scale: float = 1.0
var front_dir: String = ""
var portrait_dir: String = ""
var extension: String = ""
var throw_suffix: String = ""
var player_prefix: String = ""

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
	ok = _read_points(root.get("points")) and ok
	ok = _read_poses(root.get("poses")) and ok
	var hold: Variant = root.get("message_hold_scale", 1.0)
	if not (hold is float or hold is int) or float(hold) <= 0.0:
		ok = _fail("TrainerIntroCatalog : message_hold_scale doit être un nombre > 0")
	else:
		message_hold_scale = float(hold)
	var paths: Variant = root.get("paths")
	if not paths is Dictionary:
		ok = _fail("TrainerIntroCatalog : « paths » manquant")
	else:
		var paths_ok := true
		for key: String in PATH_KEYS:
			if not (paths as Dictionary).get(key) is String:
				paths_ok = _fail("TrainerIntroCatalog : paths.%s doit être un texte" % key)
		if paths_ok:
			front_dir = paths["front_dir"]
			portrait_dir = paths["portrait_dir"]
			extension = paths["extension"]
			throw_suffix = paths["throw_suffix"]
			player_prefix = paths["player_prefix"]
		ok = paths_ok and ok
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
## suivi d'une espace (ou le nom entier) ; &"" si aucune classe ne correspond. Une classe sans
## préfixe n'est jamais déduite du nom.
func class_for(trainer_name: String) -> StringName:
	var best := &""
	var best_length := -1
	for id: StringName in _prefixes:
		var prefix := _prefixes[id]
		if prefix.is_empty():
			continue
		if (trainer_name == prefix or trainer_name.begins_with(prefix + " ")) \
				and prefix.length() > best_length:
			best = id
			best_length = prefix.length()
	return best


## Classe de [param trainer] : celle imposée par ses données, sinon celle de son nom.
func class_of(trainer: TrainerData) -> StringName:
	if trainer == null:
		return &""
	if not trainer.battle_class.is_empty():
		return trainer.battle_class
	return class_for(trainer.name)


func has_class(id: StringName) -> bool:
	return _prefixes.has(id)


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


func point(key: String) -> Vector2:
	return points.get(key, Vector2.ZERO)


## Pose [param pose] (« entry », « throw », « vs ») du dresseur [param side] (« player »,
## « foe ») : (x du centre, y des pieds, hauteur) en fractions de l'écran.
func pose(pose_name: String, side: String) -> Vector3:
	return poses.get(pose_name + "/" + side, Vector3.ZERO)


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


func _read_points(value: Variant) -> bool:
	if not value is Dictionary:
		return _fail("TrainerIntroCatalog : « points » manquant")
	var ok := true
	for key: String in POINT_KEYS:
		var pair: Variant = (value as Dictionary).get(key)
		if not pair is Array or (pair as Array).size() != 2 \
				or not ((pair as Array)[0] is float or (pair as Array)[0] is int) \
				or not ((pair as Array)[1] is float or (pair as Array)[1] is int):
			ok = _fail("TrainerIntroCatalog : points.%s doit être [x, y]" % key)
			continue
		points[key] = Vector2(float(pair[0]), float(pair[1]))
	return ok


func _read_poses(value: Variant) -> bool:
	if not value is Dictionary:
		return _fail("TrainerIntroCatalog : « poses » manquant")
	var ok := true
	for pose_name: String in POSE_KEYS:
		var entry: Variant = (value as Dictionary).get(pose_name)
		for side: String in POSE_SIDES:
			var triple: Variant = (entry as Dictionary).get(side) if entry is Dictionary else null
			if not triple is Array or (triple as Array).size() != 3:
				ok = _fail("TrainerIntroCatalog : poses.%s.%s doit être [x, pieds, hauteur]"
					% [pose_name, side])
				continue
			var numbers: Array = triple
			if numbers.any(func(n: Variant) -> bool: return not (n is float or n is int)):
				ok = _fail("TrainerIntroCatalog : poses.%s.%s : nombres attendus"
					% [pose_name, side])
				continue
			poses[pose_name + "/" + side] = Vector3(numbers[0], numbers[1], numbers[2])
	return ok


func _fail(message: String) -> bool:
	_errors.append(message)
	push_error(message)
	return false
