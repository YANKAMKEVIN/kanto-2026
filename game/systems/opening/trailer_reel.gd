class_name TrailerReel
extends RefCounted
## Bande-annonce de l'ident de démarrage (J34 ; v2 du 2026-11-04, retour de Kevin : « des
## mouvements, des actions, pas juste des images »). Une **vidéo** jouée dans le vrai jeu
## (storyboard `docs/design/storyboard-trailer-v1.md`, chaîne `tools/trailer/`), encodée en
## Theora (`.ogv`, son compris) et lue par un VideoStreamPlayer dans [IdentSequence] entre le
## carton et les lettres. Données `data/opening/trailer.json` (règle 7) ; logique pure : lecture
## et validation stricte, tout ou rien.
##
## Format :
## [codeblock]
## {
##   "video": "res://assets/ui/opening/trailer.ogv",
##   "seconds": 37.5,
##   "letterbox": 0.07
## }
## [/codeblock]
## `seconds` : durée de la vidéo (la partition de l'ident en a besoin avant la lecture ;
## [constant MIN_SECONDS] à [constant MAX_SECONDS]) ; `letterbox` : hauteur de chaque bande noire
## en fraction de l'écran (0 : aucune ; défaut [constant DEFAULT_LETTERBOX]).

const DEFAULT_PATH: String = "res://data/opening/trailer.json"
const DEFAULT_LETTERBOX: float = 0.07
const MAX_LETTERBOX: float = 0.2
## Bornes de la durée (demande de Kevin : 30 à 40 s, avec de la marge pour le montage).
const MIN_SECONDS: float = 5.0
const MAX_SECONDS: float = 60.0
const EXTENSION: String = "ogv"

var letterbox: float = DEFAULT_LETTERBOX
## Chemin de la vidéo ("" : aucune bande-annonce).
var video: String = ""
## Durée de la vidéo (secondes).
var seconds: float = 0.0
var _errors: PackedStringArray = PackedStringArray()


## Lit le fichier ; faux (et aucune vidéo) s'il manque ou s'il est invalide.
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
	for key: String in data:
		if key not in ["video", "seconds", "letterbox", "_note"]:
			errors.append("%s : clé inconnue « %s »" % [source, key])
	var box: Variant = data.get("letterbox", DEFAULT_LETTERBOX)
	if not (box is float or box is int) or float(box) < 0.0 or float(box) > MAX_LETTERBOX:
		errors.append("%s : letterbox entre 0 et %.1f" % [source, MAX_LETTERBOX])
	var path: Variant = data.get("video", "")
	if not path is String or (path as String).is_empty():
		errors.append("%s : « video » manquante" % source)
	elif (path as String).get_extension() != EXTENSION:
		errors.append("%s : « video » doit être un fichier .%s (Theora)" % [source, EXTENSION])
	elif not ResourceLoader.exists(path):
		errors.append("%s : vidéo introuvable « %s »" % [source, path])
	var length: Variant = data.get("seconds")
	if not (length is float or length is int) or float(length) < MIN_SECONDS \
			or float(length) > MAX_SECONDS:
		errors.append("%s : « seconds » entre %.0f et %.0f" % [source, MIN_SECONDS, MAX_SECONDS])
	if not errors.is_empty():
		_errors.append_array(errors)
		for error: String in errors:
			push_warning("TrailerReel : " + error)
		return false
	letterbox = float(box)
	video = path
	seconds = float(length)
	return true


## Vrai quand une vidéo valide est chargée.
func has_video() -> bool:
	return not video.is_empty()


## Durées des plans pour [IntroTimeline] : la vidéo est un seul plan.
func durations() -> Array[float]:
	if not has_video():
		return [] as Array[float]
	return [seconds] as Array[float]


## Durée totale de la bande-annonce.
func total(_xfade: float = 0.0) -> float:
	return seconds if has_video() else 0.0


func get_errors() -> PackedStringArray:
	return _errors
