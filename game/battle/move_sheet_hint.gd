class_name MoveSheetHint
extends RefCounted
## Consigne de la fiche d'une capacité (« Maintiens une capacité pour voir sa fiche ») : écrite
## sous les cartes de capacités aux premiers choix, puis plus jamais. Classe pure.
##
## La fiche ne s'ouvre que par une pression longue : sans consigne, on ne la trouve pas. Elle
## est donc annoncée [constant MAX_SHOWN] fois, et s'arrête dès que le joueur a ouvert une fiche.
##
## Ce que le joueur a déjà vu est une préférence de l'appareil ([HintStore],
## `user://hints.json`), pas une donnée de la partie : ni la sauvegarde ni les drapeaux
## d'histoire ne changent (un combat ne pose aucun drapeau). Sans fichier (tests, outils), le
## compte ne vit que le temps de la session.

## Nombre de fois où la consigne est écrite.
const MAX_SHOWN: int = 3
## Clé de cette consigne dans le fichier, et ses deux champs.
const KEY: String = "move_sheet"
const SHOWN_KEY: String = "shown"
const OPENED_KEY: String = "opened"

var _shown: int = 0
var _opened: bool = false
var _store: HintStore


## Branche le fichier de l'appareil et y lit l'état (null : mémoire seule).
func attach(store: HintStore) -> void:
	_store = store
	if store == null:
		return
	var saved := store.load_hint(KEY)
	_shown = clampi(JsonFields.get_int(saved, SHOWN_KEY, 0), 0, MAX_SHOWN)
	_opened = JsonFields.get_bool(saved, OPENED_KEY)


## Vrai si la consigne doit encore être écrite : fiche jamais ouverte, et consigne pas encore
## montrée toutes ses fois.
func is_due() -> bool:
	return not _opened and _shown < MAX_SHOWN


## La consigne vient d'être écrite une fois de plus.
func record_shown() -> void:
	if not is_due():
		return
	_shown += 1
	_save()


## Le joueur a ouvert une fiche : il connaît le geste.
func record_opened() -> void:
	if _opened:
		return
	_opened = true
	_save()


func get_shown() -> int:
	return _shown


func is_opened() -> bool:
	return _opened


func _save() -> void:
	if _store != null:
		_store.save_hint(KEY, {SHOWN_KEY: _shown, OPENED_KEY: _opened})
