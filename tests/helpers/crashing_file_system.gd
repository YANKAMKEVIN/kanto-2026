extends "res://tests/helpers/memory_file_system.gd"
## Système de fichiers en mémoire qui « meurt » au milieu d'une suite d'écritures (dossier 13
## §3.7 : application tuée, batterie vide pendant le commit).
##
## [member crash_after] : nombre d'opérations d'écriture (write, rename, remove) qui aboutissent
## avant la panne ; -1 = jamais. L'opération qui tombe en panne n'a aucun effet, sauf une
## écriture, qui laisse la moitié du texte (écriture déchirée). Après la panne, plus aucune
## écriture n'a d'effet (le processus est mort) ; les lectures restent possibles pour que le
## code appelant se termine, mais ce qui compte est l'état de [member files].

var crash_after: int = -1
var crashed: bool = false
var _done: int = 0


func write_text(path: String, text: String) -> Error:
	if _dies():
		files[path] = text.left(int(text.length() / 2.0))
		return ERR_FILE_CANT_WRITE
	if crashed:
		return ERR_FILE_CANT_WRITE
	return super(path, text)


func rename(from: String, to: String) -> Error:
	if _dies() or crashed:
		return ERR_CANT_OPEN
	return super(from, to)


func remove(path: String) -> Error:
	if _dies() or crashed:
		return ERR_CANT_OPEN
	return super(path)


## Vrai si cette opération est celle de la panne (et marque la panne).
func _dies() -> bool:
	if crashed:
		return false
	if crash_after >= 0 and _done >= crash_after:
		crashed = true
		return true
	_done += 1
	return false
