class_name SaveFileSystem
extends RefCounted
## Accès disque du [SaveSystem] (jalon 5 §16) : les six opérations dont il a besoin, rien de
## plus. Injectable : les tests le remplacent par `tests/helpers/memory_file_system.gd` (fichiers
## en mémoire, pannes simulées) ; en jeu, cette classe lit et écrit dans `user://`.


func exists(path: String) -> bool:
	return FileAccess.file_exists(path)


## Contenu texte du fichier, ou chaîne vide s'il est illisible (le [SaveSystem] traite une
## chaîne vide comme un fichier corrompu : un JSON valide n'est jamais vide).
func read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


## Écrit [param text] dans [param path] (créé ou remplacé), dossiers parents créés au besoin.
func write_text(path: String, text: String) -> Error:
	var dir := path.get_base_dir()
	if not dir.is_empty() and not DirAccess.dir_exists_absolute(dir):
		var made := DirAccess.make_dir_recursive_absolute(dir)
		if made != OK:
			return made
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	if not file.store_string(text):
		return ERR_FILE_CANT_WRITE
	file.flush()
	var error := file.get_error()
	file.close()
	return error if error != ERR_FILE_EOF else OK


## Renomme [param from] en [param to] en remplaçant la cible (atomique sur Android / Linux /
## macOS : c'est le `rename` POSIX).
func rename(from: String, to: String) -> Error:
	return DirAccess.rename_absolute(from, to)


func remove(path: String) -> Error:
	return DirAccess.remove_absolute(path)


## Octets libres sur le volume de [param path] (J33 T4 : stockage plein), −1 si inconnu.
func space_left(path: String) -> int:
	var dir := DirAccess.open(path.get_base_dir())
	return dir.get_space_left() if dir != null else -1
