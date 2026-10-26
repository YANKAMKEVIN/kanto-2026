class_name MusicStack
extends RefCounted
## Couches de musique et priorités (docs/tech/jalon-son.md §1.5). Pur : ne joue rien.
##
## Quatre couches ([enum Layer]) ; la plus haute qui a un morceau joue, les autres attendent.
## Chaque changement rend un [MusicStack.Change] que l'autoload `Audio` exécute :
## - même morceau qu'avant → rien (entrer dans une maison de Bourg Palette ne relance pas le
##   thème) ;
## - une couche qui en recouvre une autre garde la **position** de celle du dessous (donnée par
##   le lecteur au moment du changement) ; quand elle se retire, la couche du dessous **reprend
##   là où elle était** (jingle du Centre ; SON-6 après un combat) ;
## - une couche recouverte qui change de morceau (carte changée pendant un combat) repartira du
##   début.
## Le silence ([constant AudioLibrary.SILENCE]) est un morceau comme un autre : une zone muette
## recouvre bien la zone d'avant. Une couche vide ("") n'existe pas.

enum Layer { ZONE, SCENE, BATTLE, JINGLE }

## Ce que le lecteur doit faire après un changement.
class Change:
	extends RefCounted
	## Faux : rien à faire (le morceau qui joue continue).
	var changed: bool = false
	## Morceau à jouer ; [constant AudioLibrary.SILENCE] = arrêter.
	var track: StringName = &""
	## Position de départ (secondes) : 0, ou la position gardée d'une reprise.
	var position: float = 0.0
	## Vrai : la couche reprend après le retrait d'une couche du dessus.
	var resumed: bool = false
	## Couche qui joue désormais, et celle qui jouait avant (-1 : aucune).
	var layer: int = -1
	var previous_layer: int = -1


var _tracks: Array[StringName] = [&"", &"", &"", &""]
var _positions: Array[float] = [0.0, 0.0, 0.0, 0.0]


## Couche qui joue (-1 : aucune).
func top_layer() -> int:
	for layer: int in range(Layer.size() - 1, -1, -1):
		if not _tracks[layer].is_empty():
			return layer
	return -1


## Morceau qui joue ; [constant AudioLibrary.SILENCE] si aucune couche.
func current_track() -> StringName:
	var top := top_layer()
	return _tracks[top] if top >= 0 else AudioLibrary.SILENCE


## Morceau de la couche [param layer] ("" : vide).
func track_of(layer: Layer) -> StringName:
	return _tracks[layer]


## Position gardée de la couche [param layer] (secondes).
func position_of(layer: Layer) -> float:
	return _positions[layer]


## Pose [param track] sur [param layer] ("" = retire la couche). [param current_position] :
## position du morceau qui joue en ce moment, gardée s'il est recouvert.
func set_layer(layer: Layer, track: StringName, current_position: float = 0.0) -> Change:
	if track.is_empty():
		return clear_layer(layer, current_position)
	var before := top_layer()
	var playing := current_track()
	if _tracks[layer] == track:
		return _unchanged(before)
	if before > layer:
		# Recouverte : le nouveau morceau partira du début quand la couche reviendra.
		_tracks[layer] = track
		_positions[layer] = 0.0
		return _unchanged(before)
	if before >= 0 and before < layer:
		_positions[before] = current_position
	_tracks[layer] = track
	_positions[layer] = 0.0
	if track == playing:
		return _unchanged(layer, before)
	return _change(track, 0.0, false, layer, before)


## Retire la couche [param layer] ; si elle jouait, celle du dessous reprend à sa position.
func clear_layer(layer: Layer, current_position: float = 0.0) -> Change:
	var before := top_layer()
	if _tracks[layer].is_empty():
		return _unchanged(before)
	var playing := current_track()
	_tracks[layer] = &""
	_positions[layer] = 0.0
	if before != layer:
		return _unchanged(before)
	var after := top_layer()
	if after < 0:
		return _change(AudioLibrary.SILENCE, 0.0, false, -1, before)
	var track := _tracks[after]
	var position := _positions[after]
	_positions[after] = 0.0
	if track == playing:
		# Même morceau dessus et dessous : il continue (sa position est déjà la bonne).
		return _unchanged(after, before)
	return _change(track, position, true, after, before)


## Vide toutes les couches (nouvelle partie, retour à l'écran titre).
func reset() -> void:
	_tracks = [&"", &"", &"", &""]
	_positions = [0.0, 0.0, 0.0, 0.0]


func _unchanged(layer: int, previous: int = -2) -> Change:
	var result := Change.new()
	result.layer = layer
	result.previous_layer = layer if previous == -2 else previous
	result.track = current_track()
	return result


func _change(track: StringName, position: float, resumed: bool, layer: int,
		previous: int) -> Change:
	var result := Change.new()
	result.changed = true
	result.track = track
	result.position = position
	result.resumed = resumed
	result.layer = layer
	result.previous_layer = previous
	return result
