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
## - « paths » : conventions des images (sprite de face, pose de lancer, dos du joueur, portrait ;
##   Ball et traînée peintes facultatives) ;
## - « images » : pose (debout ou lancer) de chaque dresseur à chaque moment ; « framing » :
##   recadrage du décor au lancer de l'adversaire ; « vs » : cadrage des bustes du « VS » ;
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
	"ball_diameter", "trail_width", "windup_tilt", "trail_window", "trail_glow",
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
## Moments de la mise en scène qui choisissent une image de dresseur (« images ») : l'entrée, la
## garde (cadrage du lancer, avant son propre lâcher), le lâcher de la Ball, le « VS ».
const PHASE_KEYS: Array[String] = ["entry", "guard", "release", "vs"]
## Image d'un moment : la pose debout ou la pose de lancer (`<id>_lancer`).
const IMAGE_STAND: String = "stand"
const IMAGE_THROW: String = "throw"

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
## Images peintes facultatives de la Ball lancée et de sa traînée ("" : dessin du code).
var fx_ball: String = ""
var fx_trail: String = ""
## Recadrage du décor au lancer de l'adversaire (maquette 2) : zoom autour du point
## [member framing_from] (fractions de l'écran), qui vient en [member framing_to].
var framing_zoom: float = 1.0
var framing_from: Vector2 = Vector2.ZERO
var framing_to: Vector2 = Vector2.ZERO
## Bustes de la séquence « VS » : adversaire [x du bord droit, y du haut, hauteur], rogné au
## bas [member foe_bust_bottom] ; joueur [x du bord gauche, y du haut, hauteur] ; fractions de
## l'écran. [member _bust_adjust] : réglage par buste (identifiant de portrait ou apparence du
## joueur) [dx, dy, échelle].
var foe_bust: Vector3 = Vector3(1.0, 0.0, 0.5)
var foe_bust_bottom: float = 0.3
var player_bust: Vector3 = Vector3(0.0, 0.6, 0.45)
var _bust_adjust: Dictionary[StringName, Vector3] = {}
## Moment « side/phase » → pose de lancer (vrai) ou pose debout.
var _images: Dictionary[String, bool] = {}

## Classe → préfixe du nom, et classe → apparence du monde.
var _prefixes: Dictionary[StringName, String] = {}
var _class_sprites: Dictionary[StringName, StringName] = {}
## Grand adversaire (identifiant de portrait) → apparence du monde.
var _grand_sprites: Dictionary[StringName, StringName] = {}
## Taille réelle relative par classe ou grand adversaire (« scale » ; absent : [member
## default_scale]) : un adulte (Pierre) paraît plus grand qu'un enfant (Gamin Hugo).
var _scales: Dictionary[StringName, float] = {}
## Main de la pose de lancer par classe ou grand adversaire (« hand » [x, y], en part de la
## hauteur affichée depuis les pieds ; absente : le point « foe_hand »).
var _hands: Dictionary[StringName, Vector2] = {}
## Taille relative d'un adulte (défaut) et du joueur ; les hauteurs des « poses » valent pour 1.
var default_scale: float = 1.0
var player_scale: float = 1.0
## Combat en surfant (bloc « surf », fiche entree-dresseurs §13) : suffixe des images dans
## l'eau (`dos_<apparence><surf_suffix>`, `<classe><surf_suffix>`), taille et main du joueur
## sur sa monture ; classes peintes dans l'eau (leurs `scale` et `hand` sont rangés sous
## `<classe><surf_suffix>`).
var surf_suffix: String = "_surf"
var surf_player_scale: float = 1.0
var surf_player_hand: Vector2 = Vector2.ZERO
var _surf_classes: Dictionary[StringName, bool] = {}
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
	ok = _read_images(root.get("images")) and ok
	ok = _read_framing(root.get("framing")) and ok
	ok = _read_vs(root.get("vs")) and ok
	default_scale = float(root.get("default_scale", 1.0))
	player_scale = float(root.get("player_scale", 1.0))
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
			fx_ball = str((paths as Dictionary).get("fx_ball", ""))
			fx_trail = str((paths as Dictionary).get("fx_trail", ""))
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
			_read_scale(StringName(str(id)), entry)
	ok = _read_surf(root.get("surf")) and ok
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
			_read_scale(StringName(str(id)), entry)
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


## Taille réelle relative de la classe ou du grand adversaire [param id] (rival / rivale :
## celle du rival).
func scale_of(id: StringName) -> float:
	var key := TrainerIntro.RIVAL_ID if id == TrainerLooks.RIVALE else id
	return _scales.get(key, default_scale)


## Main de la pose de lancer de la classe ou du grand adversaire [param id].
func hand_of(id: StringName) -> Vector2:
	var key := TrainerIntro.RIVAL_ID if id == TrainerLooks.RIVALE else id
	return _hands.get(key, point("foe_hand"))


func duration(key: String) -> float:
	return durations.get(key, 0.0)


func point(key: String) -> Vector2:
	return points.get(key, Vector2.ZERO)


## Pose [param pose] (« entry », « throw », « vs ») du dresseur [param side] (« player »,
## « foe ») : (x du centre, y des pieds, hauteur) en fractions de l'écran.
func pose(pose_name: String, side: String) -> Vector3:
	return poses.get(pose_name + "/" + side, Vector3.ZERO)


## Le dresseur [param side] (« player », « foe ») prend sa pose de lancer (sinon debout) au
## moment [param phase] ([constant PHASE_KEYS]).
func uses_throw_image(side: String, phase: String) -> bool:
	return _images.get(side + "/" + phase, false)


## Réglage du buste [param id] : [dx, dy] (fractions de l'écran) et échelle de la hauteur.
func bust_adjust(id: StringName) -> Vector3:
	return _bust_adjust.get(id, Vector3(0.0, 0.0, 1.0))


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


## Bloc facultatif « surf » : { suffix, player: { scale, hand }, classes: { <classe>: { scale,
## hand } } }. Sans lui, aucune classe n'est peinte dans l'eau.
func _read_surf(value: Variant) -> bool:
	surf_player_hand = point("player_hand")
	if value == null:
		return true
	if not value is Dictionary:
		return _fail("TrainerIntroCatalog : « surf » doit être un objet")
	var surf: Dictionary = value
	surf_suffix = str(surf.get("suffix", surf_suffix))
	var player: Variant = surf.get("player", {})
	if player is Dictionary:
		var scale: Variant = (player as Dictionary).get("scale")
		surf_player_scale = float(scale) if scale is float or scale is int else player_scale
		var hand: Variant = _pair((player as Dictionary).get("hand"))
		if hand != null:
			surf_player_hand = hand
	var classes: Variant = surf.get("classes", {})
	if not classes is Dictionary:
		return _fail("TrainerIntroCatalog : surf.classes doit être un objet")
	var ok := true
	for id: Variant in classes:
		var entry: Variant = (classes as Dictionary)[id]
		if not entry is Dictionary or not _class_sprites.has(StringName(str(id))):
			ok = _fail("TrainerIntroCatalog : surf.classes.%s : classe inconnue" % id)
			continue
		_surf_classes[StringName(str(id))] = true
		_read_scale(StringName(str(id) + surf_suffix), entry)
	return ok


## La classe [param id] est peinte dans l'eau (combat en surfant).
func has_surf_art(id: StringName) -> bool:
	return _surf_classes.has(id)


func _read_scale(id: StringName, entry: Dictionary) -> void:
	var scale: Variant = entry.get("scale")
	if scale is float or scale is int:
		_scales[id] = float(scale)
	var hand: Variant = _pair(entry.get("hand"))
	if hand != null:
		_hands[id] = hand


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


func _read_images(value: Variant) -> bool:
	if not value is Dictionary:
		return _fail("TrainerIntroCatalog : « images » manquant")
	var ok := true
	for side: String in POSE_SIDES:
		var entry: Variant = (value as Dictionary).get(side)
		for phase: String in PHASE_KEYS:
			var image: Variant = (entry as Dictionary).get(phase) if entry is Dictionary else null
			if image != IMAGE_STAND and image != IMAGE_THROW:
				ok = _fail("TrainerIntroCatalog : images.%s.%s : « stand » ou « throw »"
					% [side, phase])
				continue
			_images[side + "/" + phase] = image == IMAGE_THROW
	return ok


func _read_framing(value: Variant) -> bool:
	if not value is Dictionary:
		return _fail("TrainerIntroCatalog : « framing » manquant")
	var data: Dictionary = value
	var zoom: Variant = data.get("zoom")
	var from: Variant = _pair(data.get("from"))
	var to: Variant = _pair(data.get("to"))
	if not (zoom is float or zoom is int) or float(zoom) < 1.0 or from == null or to == null:
		return _fail("TrainerIntroCatalog : framing { zoom ≥ 1, from [x, y], to [x, y] }")
	framing_zoom = float(zoom)
	framing_from = from
	framing_to = to
	return true


func _read_vs(value: Variant) -> bool:
	if not value is Dictionary:
		return _fail("TrainerIntroCatalog : « vs » manquant")
	var data: Dictionary = value
	var foe: Variant = _triple(data.get("foe_bust"))
	var mine: Variant = _triple(data.get("player_bust"))
	var bottom: Variant = data.get("foe_bust_bottom")
	if foe == null or mine == null or not (bottom is float or bottom is int):
		return _fail("TrainerIntroCatalog : vs { foe_bust, foe_bust_bottom, player_bust }")
	foe_bust = foe
	player_bust = mine
	foe_bust_bottom = float(bottom)
	var ok := true
	var busts: Variant = data.get("busts", {})
	if not busts is Dictionary:
		return _fail("TrainerIntroCatalog : vs.busts doit être un objet")
	for id: Variant in busts:
		var adjust: Variant = _triple((busts as Dictionary)[id])
		if adjust == null or (adjust as Vector3).z <= 0.0:
			ok = _fail("TrainerIntroCatalog : vs.busts.%s doit être [dx, dy, échelle > 0]" % id)
			continue
		_bust_adjust[StringName(str(id))] = adjust
	return ok


## [x, y] → Vector2, sinon null.
static func _pair(value: Variant) -> Variant:
	if not value is Array or (value as Array).size() != 2:
		return null
	var numbers: Array = value
	if numbers.any(func(n: Variant) -> bool: return not (n is float or n is int)):
		return null
	return Vector2(numbers[0], numbers[1])


## [a, b, c] → Vector3, sinon null.
static func _triple(value: Variant) -> Variant:
	if not value is Array or (value as Array).size() != 3:
		return null
	var numbers: Array = value
	if numbers.any(func(n: Variant) -> bool: return not (n is float or n is int)):
		return null
	return Vector3(numbers[0], numbers[1], numbers[2])


func _fail(message: String) -> bool:
	_errors.append(message)
	push_error(message)
	return false
