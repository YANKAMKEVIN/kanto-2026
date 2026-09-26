class_name DialogueSession
extends RefCounted
## Déroulé d'un dialogue en cours : page courante, silence, texte qui s'écrit, avance.
##
## Classe pure (docs/tech/jalon-03.md §2.5). La boîte de dialogue ne fait qu'afficher
## [method get_visible_characters] ; le lecteur de dialogues appelle [method update] à
## chaque image et [method advance] à chaque toucher ou appui sur `interact` :
## - pendant le silence ou l'écriture d'une page, [method advance] affiche la page entière
##   ([constant Step.REVEALED]) ;
## - page entière : page suivante ([constant Step.NEXT_PAGE]) ou fin ([constant Step.FINISHED]).
## Au début de chaque page (première comprise), le lecteur applique ses indications de mise
## en scène ([method get_page] : face_player, react).

enum Step { NONE, REVEALED, NEXT_PAGE, FINISHED }

var _pages: Array[DialoguePage] = []
var _default_speaker: String = ""
var _chars_per_second: float = 0.0
var _index: int = 0
var _pause_left: float = 0.0
var _revealed: float = 0.0
var _length: int = 0
var _finished: bool = false


## [param chars_per_second] ≤ 0 : chaque page s'affiche d'un coup (après son silence).
func _init(pages: Array[DialoguePage], default_speaker: String = "",
		chars_per_second: float = 0.0) -> void:
	_pages = pages
	_default_speaker = default_speaker
	_chars_per_second = chars_per_second
	_finished = _pages.is_empty()
	if not _finished:
		_start_page(0)


## Fait passer le temps : d'abord le silence de la page, puis l'écriture du texte.
func update(delta: float) -> void:
	if _finished or delta <= 0.0:
		return
	if _pause_left > 0.0:
		var used := minf(delta, _pause_left)
		_pause_left -= used
		delta -= used
		if delta <= 0.0:
			return
	if _chars_per_second <= 0.0:
		_revealed = _length
	else:
		_revealed = minf(_revealed + delta * _chars_per_second, _length)


## Toucher ou `interact` : compléter la page, passer à la suivante ou terminer.
func advance() -> Step:
	if _finished:
		return Step.NONE
	if not is_page_complete():
		_pause_left = 0.0
		_revealed = _length
		return Step.REVEALED
	if _index + 1 < _pages.size():
		_start_page(_index + 1)
		return Step.NEXT_PAGE
	_finished = true
	return Step.FINISHED


func is_finished() -> bool:
	return _finished


## Page courante (la dernière une fois terminé), null si le dialogue est vide.
func get_page() -> DialoguePage:
	return _pages[_index] if not _pages.is_empty() else null


func get_page_index() -> int:
	return _index


func get_page_count() -> int:
	return _pages.size()


func is_last_page() -> bool:
	return _index == _pages.size() - 1


## Locuteur de la page courante : le sien s'il en a un, sinon celui du dialogue.
func get_speaker() -> String:
	var page := get_page()
	if page != null and not page.speaker.is_empty():
		return page.speaker
	return _default_speaker


func get_text() -> String:
	var page := get_page()
	return page.text if page != null else ""


## Nombre de caractères de la page déjà écrits (0 pendant le silence).
func get_visible_characters() -> int:
	return int(_revealed)


## Vrai quand toute la page est écrite (indicateur ▼ ou fin).
func is_page_complete() -> bool:
	return _pause_left <= 0.0 and int(_revealed) >= _length


## Vrai pendant le silence qui précède le texte de la page.
func is_pausing() -> bool:
	return _pause_left > 0.0


func _start_page(index: int) -> void:
	_index = index
	var page := _pages[index]
	_length = page.text.length()
	_pause_left = page.pause
	_revealed = 0.0
	if _chars_per_second <= 0.0 and _pause_left <= 0.0:
		_revealed = _length
