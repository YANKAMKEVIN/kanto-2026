class_name SfxCatalog
extends RefCounted
## Bruitages : identifiant → fichier, bus, volume, variantes, polyphonie (docs/tech/jalon-son.md
## §1.7, §3). Pur : compte les lectures en cours sans rien jouer.
##
## Une variante est tirée au hasard ([method pick_file], générateur injecté pour les tests) ;
## un identifiant ne joue pas plus de `max_polyphony` fois à la fois ([method can_play],
## [method started], [method finished]) : pas de pas qui s'empilent.

var _library: AudioLibrary
var _playing: Dictionary[StringName, int] = {}


func _init(library: AudioLibrary) -> void:
	_library = library


func has(id: StringName) -> bool:
	return _library.has_sfx(id)


func files(id: StringName) -> PackedStringArray:
	return _library.sfx(id).get("files", PackedStringArray())


## Une variante au hasard ("" si l'identifiant est inconnu).
func pick_file(id: StringName, rng: RandomNumberGenerator) -> String:
	var list := files(id)
	if list.is_empty():
		return ""
	return list[rng.randi_range(0, list.size() - 1)] if list.size() > 1 else list[0]


func bus(id: StringName) -> StringName:
	return _library.sfx(id).get("bus", &"Sfx")


func volume_db(id: StringName) -> float:
	return _library.sfx(id).get("volume_db", 0.0)


func is_expected(id: StringName) -> bool:
	return _library.sfx(id).get("expected", false)


func max_polyphony(id: StringName) -> int:
	return _library.sfx(id).get("max_polyphony", 1)


## Vrai si [param id] est connu et joue moins de `max_polyphony` fois.
func can_play(id: StringName) -> bool:
	return has(id) and playing_count(id) < max_polyphony(id)


func playing_count(id: StringName) -> int:
	return _playing.get(id, 0)


## Une lecture de [param id] commence.
func started(id: StringName) -> void:
	_playing[id] = playing_count(id) + 1


## Une lecture de [param id] se termine (jamais en dessous de 0).
func finished(id: StringName) -> void:
	var count := playing_count(id) - 1
	if count > 0:
		_playing[id] = count
	else:
		_playing.erase(id)


## Bruitage d'une attaque (SON-11, familles) : voir [method AudioLibrary.move_sfx].
func move_sfx(move_id: StringName, type: StringName, category: StringName) -> StringName:
	return _library.move_sfx(move_id, type, category)
