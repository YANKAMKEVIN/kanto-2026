class_name TrailerReel
extends RefCounted
## Plans de la bande-annonce de l'ident de démarrage (J34, demande de Kevin du 2026-11-03 : « une
## courte vidéo de quelques secondes de plusieurs moments intéressants, importants, beaux du jeu,
## 15 à 20 secondes »). Données `data/opening/trailer.json` (règle 7) ; logique pure : lecture,
## validation stricte, valeurs par défaut des mouvements. La scène ([IdentSequence]) joue chaque
## plan en fondu enchaîné avec un lent travelling (zoom et glissement, « Ken Burns »).
##
## Format :
## [codeblock]
## {
##   "letterbox": 0.07,
##   "shots": [
##     { "image": "res://assets/ui/opening/trailer/01_bourg_palette.webp", "seconds": 2.4,
##       "zoom": [1.0, 1.08], "pan": [0.0, 0.0, -0.02, 0.01] }
##   ]
## }
## [/codeblock]
## `seconds` (0,5 à 6, défaut [constant DEFAULT_SECONDS]) ; `zoom` [départ, arrivée] (1 à 1,3) ;
## `pan` [x0, y0, x1, y1] en fraction de l'écran (−0,1 à 0,1), glissement du centre du plan ;
## sans `zoom` ni `pan`, un mouvement alterné (poussée puis recul) est donné par [method
## default_motion]. `letterbox` : hauteur de chaque bande noire en fraction de l'écran (0 : aucune).

const DEFAULT_PATH: String = "res://data/opening/trailer.json"
const DEFAULT_SECONDS: float = 2.4
const DEFAULT_LETTERBOX: float = 0.07
const MIN_SECONDS: float = 0.5
const MAX_SECONDS: float = 6.0
const MIN_ZOOM: float = 1.0
const MAX_ZOOM: float = 1.3
const MAX_PAN: float = 0.1
## Mouvement par défaut [D] : poussée douce de 1 à 1,08, glissement de 2 % alterné.
const DEFAULT_ZOOM_IN: Array[float] = [1.0, 1.08]
const DEFAULT_ZOOM_OUT: Array[float] = [1.08, 1.0]
const DEFAULT_PAN_STEP: float = 0.02

var letterbox: float = DEFAULT_LETTERBOX
## Plans valides : `{"image": String, "seconds": float, "zoom": Array[float], "pan": Array[float]}`.
var shots: Array[Dictionary] = []
var _errors: PackedStringArray = PackedStringArray()


## Lit le fichier ; faux (et aucun plan) s'il manque ou s'il est invalide.
func load_file(path: String = DEFAULT_PATH) -> bool:
	_errors.clear()
	if not FileAccess.file_exists(path):
		_errors.append("%s : fichier absent" % path)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_errors.append("%s : objet JSON attendu" % path)
		return false
	return add_from_dict(parsed, path)


## Charge un dictionnaire déjà lu (tests). Tout ou rien.
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var errors := PackedStringArray()
	var box: Variant = data.get("letterbox", DEFAULT_LETTERBOX)
	if not (box is float or box is int) or float(box) < 0.0 or float(box) > 0.2:
		errors.append("%s : letterbox entre 0 et 0,2" % source)
	var raw: Variant = data.get("shots")
	if not raw is Array:
		errors.append("%s : tableau « shots » attendu" % source)
	var parsed: Array[Dictionary] = []
	if raw is Array:
		for i: int in (raw as Array).size():
			var shot: Variant = (raw as Array)[i]
			if not shot is Dictionary:
				errors.append("%s plan %d : objet attendu" % [source, i])
				continue
			var clean := _parse_shot(shot, i, source, errors)
			if not clean.is_empty():
				parsed.append(clean)
	if not errors.is_empty():
		_errors.append_array(errors)
		for error: String in errors:
			push_warning("TrailerReel : " + error)
		return false
	letterbox = float(box)
	shots = parsed
	return true


## Durées des plans, dans l'ordre (pour [IntroTimeline]).
func durations() -> Array[float]:
	var out: Array[float] = []
	for shot: Dictionary in shots:
		out.append(shot["seconds"])
	return out


## Durée totale apparente, fondus enchaînés déduits.
func total(xfade: float) -> float:
	var sum: float = 0.0
	for shot: Dictionary in shots:
		sum += shot["seconds"]
	return maxf(sum - xfade * maxi(shots.size() - 1, 0), 0.0)


func get_errors() -> PackedStringArray:
	return _errors


## Mouvement par défaut du plan [param index] : poussée sur les plans pairs, recul sur les impairs,
## glissement horizontal alterné.
static func default_motion(index: int) -> Dictionary:
	var push: bool = index % 2 == 0
	var step: float = DEFAULT_PAN_STEP if (index / 2) % 2 == 0 else -DEFAULT_PAN_STEP
	var zoom: Array[float] = []
	var pan: Array[float] = []
	if push:
		zoom.assign(DEFAULT_ZOOM_IN)
		pan.assign([0.0, 0.0, step, 0.0])
	else:
		zoom.assign(DEFAULT_ZOOM_OUT)
		pan.assign([step, 0.0, 0.0, 0.0])
	return {"zoom": zoom, "pan": pan}


func _parse_shot(shot: Dictionary, index: int, source: String, errors: PackedStringArray) -> Dictionary:
	var image: Variant = shot.get("image", "")
	if not image is String or (image as String).is_empty():
		errors.append("%s plan %d : « image » manquante" % [source, index])
		return {}
	if not ResourceLoader.exists(image):
		errors.append("%s plan %d : image introuvable « %s »" % [source, index, image])
		return {}
	var seconds: Variant = shot.get("seconds", DEFAULT_SECONDS)
	if not (seconds is float or seconds is int) or float(seconds) < MIN_SECONDS or float(seconds) > MAX_SECONDS:
		errors.append("%s plan %d : « seconds » entre %.1f et %.1f" % [source, index, MIN_SECONDS, MAX_SECONDS])
		return {}
	var motion := default_motion(index)
	var zoom: Array[float] = []
	zoom.assign(motion["zoom"])
	var pan: Array[float] = []
	pan.assign(motion["pan"])
	if shot.has("zoom"):
		if not _numbers(shot["zoom"], 2, MIN_ZOOM, MAX_ZOOM):
			errors.append("%s plan %d : « zoom » = [départ, arrivée] entre %.1f et %.1f" % [source, index, MIN_ZOOM, MAX_ZOOM])
			return {}
		zoom.assign(shot["zoom"])
	if shot.has("pan"):
		if not _numbers(shot["pan"], 4, -MAX_PAN, MAX_PAN):
			errors.append("%s plan %d : « pan » = [x0, y0, x1, y1] entre −%.1f et %.1f" % [source, index, MAX_PAN, MAX_PAN])
			return {}
		pan.assign(shot["pan"])
	for key: String in shot:
		if key not in ["image", "seconds", "zoom", "pan", "_note"]:
			errors.append("%s plan %d : clé inconnue « %s »" % [source, index, key])
			return {}
	return {"image": image, "seconds": float(seconds), "zoom": zoom, "pan": pan}


static func _numbers(value: Variant, count: int, low: float, high: float) -> bool:
	if not value is Array or (value as Array).size() != count:
		return false
	for x: Variant in value:
		if not (x is float or x is int) or float(x) < low or float(x) > high:
			return false
	return true
