class_name CryCatalog
extends RefCounted
## Espèce → cri (docs/tech/jalon-son.md §1.8 ; SON-1 : cris `latest` de PokeAPI, au SonB). Pur.
##
## Le fichier est rangé par numéro national (`sfx.json` « cries.path_format », `1.ogg` à
## `151.ogg`, les noms des fichiers PokeAPI). Au K.O., le cri est joué plus grave et plus lent
## (`faint_pitch`, 0,8 [D], comme RB).

var _settings: Dictionary


func _init(library: AudioLibrary) -> void:
	_settings = library.cries()


## Nombre d'espèces qui ont un cri (151).
func count() -> int:
	return JsonFields.get_int(_settings, "count")


## Fichier du cri du numéro national [param dex] ; "" hors de 1 à [method count].
func path_for(dex: int) -> String:
	var format := JsonFields.get_string(_settings, "path_format")
	if dex < 1 or dex > count() or not format.contains("%d"):
		return ""
	return format % dex


## Fichier du cri de [param species] ; "" si l'espèce est inconnue.
func path_for_species(species: SpeciesData) -> String:
	return path_for(species.dex) if species != null else ""


## Hauteur de lecture : 1, ou `faint_pitch` au K.O.
func pitch(fainted: bool = false) -> float:
	return JsonFields.get_float(_settings, "faint_pitch", 1.0) if fainted else 1.0


func bus() -> StringName:
	return JsonFields.get_id(_settings, "bus", &"Cries")


func volume_db() -> float:
	return JsonFields.get_float(_settings, "volume_db")


func is_expected() -> bool:
	return JsonFields.get_bool(_settings, "expected")
