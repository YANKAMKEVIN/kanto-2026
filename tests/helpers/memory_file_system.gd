extends SaveFileSystem
## SaveFileSystem des tests : fichiers en mémoire et pannes simulées (jalon 5 §16).
##
## Utilisation :
## [code]const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")[/code].
## [member fail_writes] : toute écriture échoue sans rien écrire. [member truncate_writes] : une
## écriture n'écrit que la première moitié du texte et prétend avoir réussi (coupure en pleine
## écriture). [member fail_renames] : tout renommage échoue ; [member fail_rename_to] : seuls
## les renommages vers ce chemin échouent (coupure de courant : `crashing_file_system.gd`).
## [member space_left_bytes] : place libre rendue par [method space_left] (−1 : inconnue) ; avec
## une valeur ≥ 0, une écriture plus grande échoue sans rien écrire. [member journal] garde
## l'ordre des opérations (« write », « rename », « remove ») pour vérifier l'atomicité.

var files: Dictionary[String, String] = {}
var fail_writes: bool = false
var truncate_writes: bool = false
var fail_renames: bool = false
var fail_rename_to: String = ""
var space_left_bytes: int = -1
var journal: Array[String] = []


func exists(path: String) -> bool:
	return files.has(path)


func read_text(path: String) -> String:
	return files.get(path, "")


func write_text(path: String, text: String) -> Error:
	journal.append("write " + path)
	if fail_writes:
		return ERR_FILE_CANT_WRITE
	if space_left_bytes >= 0 and text.to_utf8_buffer().size() > space_left_bytes:
		return ERR_FILE_CANT_WRITE
	files[path] = text.left(text.length() / 2) if truncate_writes else text
	return OK


func rename(from: String, to: String) -> Error:
	journal.append("rename %s -> %s" % [from, to])
	if fail_renames or to == fail_rename_to or not files.has(from):
		return ERR_CANT_OPEN
	files[to] = files[from]
	files.erase(from)
	return OK


func remove(path: String) -> Error:
	journal.append("remove " + path)
	return OK if files.erase(path) else ERR_FILE_NOT_FOUND


func space_left(_path: String) -> int:
	return space_left_bytes

