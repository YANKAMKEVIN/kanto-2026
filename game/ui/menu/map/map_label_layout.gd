class_name MapLabelLayout
extends RefCounted
## Placement des étiquettes de l'illustration de Kanto (reliquats du Menu peint, 2026-11-02) :
## **aucune étiquette n'en chevauche une autre**. Géométrie pure (testable sans scène).
##
## Les étiquettes sont posées par priorité ([param order]) : chacune essaie ses positions
## candidates dans l'ordre (côté préféré d'abord, puis les autres côtés de sa zone), gardées dans
## [param bounds] ; la première qui ne touche ni une étiquette déjà posée ni un obstacle (portrait
## du joueur) est prise. Une étiquette **secondaire** sans place libre est masquée à cette échelle
## (sa zone reste touchable). Les [param forced] premières de l'ordre (lieu courant, zone du
## panneau) ne sont jamais masquées : sans candidate libre, elles descendent ou montent par pas
## jusqu'à une place libre.


## Rectangles posés, au rang de [param sizes] ; Rect2() (sans aire) pour une étiquette masquée.
## [param candidates] : pour chaque étiquette, ses positions (coin haut gauche) par préférence.
## [param gap] : écart minimal entre deux étiquettes.
static func place(sizes: Array[Vector2], candidates: Array[Array], order: Array[int],
		forced: int, bounds: Rect2, obstacles: Array[Rect2], gap: float) -> Array[Rect2]:
	var result: Array[Rect2] = []
	result.resize(sizes.size())
	var taken: Array[Rect2] = obstacles.duplicate()
	for rank: int in order.size():
		var index := order[rank]
		var found := Rect2()
		for at: Variant in candidates[index]:
			var rect := _clamped(Rect2(at as Vector2, sizes[index]), bounds)
			if _is_free(rect, taken, gap):
				found = rect
				break
		if not found.has_area() and rank < forced and not (candidates[index] as Array).is_empty():
			found = _scan(Rect2(candidates[index][0] as Vector2, sizes[index]), bounds, taken, gap)
		result[index] = found
		if found.has_area():
			taken.append(found)
	return result


## Vrai si deux rectangles posés (avec aire) se chevauchent dans [param rects].
static func has_overlap(rects: Array[Rect2]) -> bool:
	for i: int in rects.size():
		if not rects[i].has_area():
			continue
		for j: int in range(i + 1, rects.size()):
			if rects[j].has_area() and rects[i].intersects(rects[j]):
				return true
	return false


static func _is_free(rect: Rect2, taken: Array[Rect2], gap: float) -> bool:
	var padded := rect.grow(gap * 0.5)
	for other: Rect2 in taken:
		if padded.intersects(other.grow(gap * 0.5)):
			return false
	return true


static func _clamped(rect: Rect2, bounds: Rect2) -> Rect2:
	var at := rect.position
	at.x = clampf(at.x, bounds.position.x, maxf(bounds.end.x - rect.size.x, bounds.position.x))
	at.y = clampf(at.y, bounds.position.y, maxf(bounds.end.y - rect.size.y, bounds.position.y))
	return Rect2(at, rect.size)


## Étiquette forcée : pas d'une demi-hauteur vers le bas puis vers le haut, alternés, puis de
## côté ; à défaut (écran saturé), la position préférée.
static func _scan(rect: Rect2, bounds: Rect2, taken: Array[Rect2], gap: float) -> Rect2:
	var step := maxf(rect.size.y * 0.5, 1.0)
	var reach := int(ceil(maxf(bounds.size.x, bounds.size.y) / step))
	for k: int in range(1, reach + 1):
		for offset: Vector2 in [Vector2(0, k * step), Vector2(0, -k * step),
				Vector2(k * step, 0), Vector2(-k * step, 0)]:
			var moved := _clamped(Rect2(rect.position + offset, rect.size), bounds)
			if _is_free(moved, taken, gap):
				return moved
	return _clamped(rect, bounds)
