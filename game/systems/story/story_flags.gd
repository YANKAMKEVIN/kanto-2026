class_name StoryFlags
extends RefCounted
## Drapeaux d'histoire de la partie (« la mère a parlé », plus tard « starter reçu »).
##
## Classe pure, sans scène (docs/tech/jalon-03.md §2.6). L'autoload `GameState` en tient
## une instance pour toute la partie ; les dialogues la lisent pour choisir leur variante
## et la modifient à leur fin. Un drapeau absent vaut faux. [method to_array] et
## [method load_array] préparent la sauvegarde (pas encore branchée).

## Drapeau posé par le Prof. Chen quand il active le Pokédex du joueur (jalon 7A, dossier-09 §6).
## Jamais posé au jalon 5 : rien du Pokédex n'est visible avant (règle de déblocage de
## vision.md : « Nouvelle entrée Pokédex » sur la carte de capture, etc.), mais les données
## sont collectées dès le premier Pokémon.
const POKEDEX_ACTIVATED: StringName = &"pokedex_activated"

## Un drapeau vient de changer de valeur (rien n'est émis si la valeur ne change pas).
signal flag_changed(flag: StringName, value: bool)

var _flags: Dictionary[StringName, bool] = {}


## Lève (ou baisse) un drapeau. Un nom vide est ignoré.
func set_flag(flag: StringName, value: bool = true) -> void:
	if flag.is_empty() or has_flag(flag) == value:
		return
	if value:
		_flags[flag] = true
	else:
		_flags.erase(flag)
	flag_changed.emit(flag, value)


func has_flag(flag: StringName) -> bool:
	return _flags.has(flag)


## Vrai si tous les drapeaux de [param flags] sont levés (vrai pour une liste vide).
func has_all(flags: Array[StringName]) -> bool:
	for flag: StringName in flags:
		if not _flags.has(flag):
			return false
	return true


## Vrai si aucun drapeau de [param flags] n'est levé (vrai pour une liste vide).
func has_none(flags: Array[StringName]) -> bool:
	for flag: StringName in flags:
		if _flags.has(flag):
			return false
	return true


## Drapeaux levés, triés (sauvegarde future, journaux).
func to_array() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_flags.keys())
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result


## Remplace l'état par les drapeaux de [param flags] (sans émettre [signal flag_changed]).
func load_array(flags: Array) -> void:
	_flags.clear()
	for flag: Variant in flags:
		var name := StringName(str(flag))
		if not name.is_empty():
			_flags[name] = true


## Oublie tous les drapeaux (nouvelle partie), sans émettre [signal flag_changed].
func clear() -> void:
	_flags.clear()


func size() -> int:
	return _flags.size()
