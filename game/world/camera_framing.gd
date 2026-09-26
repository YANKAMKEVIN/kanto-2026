class_name CameraFraming
extends RefCounted
## Limites de caméra d'une carte, y compris les pièces plus petites que l'écran.
##
## Sur un axe où la carte est plus grande que la vue, les limites sont celles de la carte :
## la caméra suit le joueur sans montrer l'extérieur. Sur un axe où elle est plus petite
## (petites pièces d'intérieur), les limites sont élargies symétriquement jusqu'à la taille
## de la vue : Camera2D reste alors immobile et la carte est centrée ; le reste de l'écran
## montre la couleur de fond du projet (voir docs/tech/jalon-02.md §2.6).


## [param map_rect] : rectangle monde de la carte (pixels de référence).
## [param view_size] : taille visible en unités monde (get_viewport_rect().size, zoom 1).
static func limits_for(map_rect: Rect2i, view_size: Vector2) -> Rect2i:
	var view := Vector2i(ceili(view_size.x), ceili(view_size.y))
	var rect := map_rect
	if rect.size.x < view.x:
		var extra := view.x - rect.size.x
		rect.position.x -= floori(extra / 2.0)
		rect.size.x = view.x
	if rect.size.y < view.y:
		var extra := view.y - rect.size.y
		rect.position.y -= floori(extra / 2.0)
		rect.size.y = view.y
	return rect


## Vrai si la carte tient entièrement dans la vue (caméra immobile).
static func is_static(map_rect: Rect2i, view_size: Vector2) -> bool:
	return map_rect.size.x <= ceili(view_size.x) and map_rect.size.y <= ceili(view_size.y)
