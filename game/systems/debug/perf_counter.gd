class_name PerfCounter
extends Node
## Compteur de performance de QA (jalon 5, dette avant la 5F) : en build debug, écrit dans le
## journal une ligne toutes les 2 s, lue sur le S24 par `adb logcat -s godot:V | grep perf` :
## [codeblock]
## [perf] fps=60 min=54 draw=87 tex=18.4
## [/codeblock]
## - [code]fps[/code] : images par seconde moyennes sur la fenêtre de 2 s ;
## - [code]min[/code] : cadence de l'image la plus lente de la fenêtre (1 / plus long delta),
##   pour repérer une saccade pendant une transition ou un lancer que la moyenne cache ;
## - [code]draw[/code] : appels de dessin de la dernière image ;
## - [code]tex[/code] : mémoire vidéo des textures, en Mo (jalon 7 §7 : budget de 64 Mo par
##   carte), `Performance.RENDER_TEXTURE_MEM_USED`.
##
## [b]Quand est-il actif ?[/b] Seulement si [method is_allowed] : build debug et [Boot] scène
## principale lancée par le moteur (jamais sous GUT ni dans un outil, qui instancient Boot
## eux-mêmes ; jamais en release). Sinon [Boot] ne l'ajoute pas. Coût : une addition et deux
## comparaisons par image, aucune allocation ; le texte n'est construit que toutes les 2 s.

## Durée d'une fenêtre de mesure, en secondes.
const REPORT_INTERVAL: float = 2.0
const PREFIX: String = "[perf]"
const BYTES_PER_MB: float = 1048576.0

var _elapsed: float = 0.0
var _frames: int = 0
var _longest: float = 0.0


## Le compteur n'existe qu'en build debug, quand [Boot] est la scène principale du moteur.
static func is_allowed(debug_build: bool, boot_is_main_scene: bool) -> bool:
	return debug_build and boot_is_main_scene


## Ligne du journal : [code]fps[/code] et [code]min[/code] arrondis, [code]draw[/code] brut,
## [code]tex[/code] en Mo à 0,1 près.
static func format_line(fps: float, min_fps: float, draw_calls: int,
		texture_bytes: int = 0) -> String:
	return "%s fps=%d min=%d draw=%d tex=%.1f" % [PREFIX, roundi(fps), roundi(min_fps),
		draw_calls, texture_bytes / BYTES_PER_MB]


func _process(delta: float) -> void:
	if tick(delta):
		print(take_line(
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))))


## Enregistre une image de [param delta] secondes. Vrai quand la fenêtre de
## [constant REPORT_INTERVAL] est pleine (appeler alors [method take_line]).
func tick(delta: float) -> bool:
	_elapsed += delta
	_frames += 1
	if delta > _longest:
		_longest = delta
	return _elapsed >= REPORT_INTERVAL


## Ligne de la fenêtre écoulée, puis fenêtre remise à zéro. Chaîne vide si aucune image.
func take_line(draw_calls: int, texture_bytes: int = 0) -> String:
	if _frames == 0 or _elapsed <= 0.0 or _longest <= 0.0:
		return ""
	var line := format_line(_frames / _elapsed, 1.0 / _longest, draw_calls, texture_bytes)
	_elapsed = 0.0
	_frames = 0
	_longest = 0.0
	return line
