class_name SafeArea
extends RefCounted
## Zone sûre de l'écran (encoche, Dynamic Island, barre d'accueil iOS, perforation Android) en
## unités de canevas, pour que l'UI ancrée aux bords reste visible et touchable.
##
## Le système donne la zone sûre en pixels d'écran ([method DisplayServer.get_display_safe_area]) ;
## le jeu dessine en pixels de référence (1920×1080, stretch canvas_items + expand). Les retraits
## (gauche, haut, droite, bas) sont donc convertis au rapport canevas / fenêtre, puis appliqués à
## un Control plein écran en jouant sur ses offsets. Logique pure dans [method insets_for], testable
## sans fenêtre ; [method current] et [method apply] sont les portes vers le moteur.
##
## Sur le S24 (perforation centrée en haut, en paysage sur un bord court) les retraits sont nuls
## ou négligeables : rien ne change pour Android. Sur iPhone en paysage : ≈ 59 pt du côté de
## l'encoche, ≈ 21 pt côté barre d'accueil (× 3 en pixels, puis × rapport canevas).

## Retraits (x = gauche, y = haut, z = droite, w = bas) en unités de canevas.
## [param safe] et [param window] en pixels d'écran ; [param canvas_size] = taille visible du viewport.
static func insets_for(safe: Rect2i, window: Rect2i, canvas_size: Vector2) -> Vector4:
	if window.size.x <= 0 or window.size.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4.ZERO
	var scale := canvas_size / Vector2(window.size)
	var left := maxi(0, safe.position.x - window.position.x)
	var top := maxi(0, safe.position.y - window.position.y)
	var right := maxi(0, window.end.x - safe.end.x)
	var bottom := maxi(0, window.end.y - safe.end.y)
	return Vector4(left * scale.x, top * scale.y, right * scale.x, bottom * scale.y)


## Retraits courants de la fenêtre principale, en unités du canevas de [param viewport].
static func current(viewport: Viewport) -> Vector4:
	var window := Rect2i(DisplayServer.window_get_position(), DisplayServer.window_get_size())
	return insets_for(DisplayServer.get_display_safe_area(), window, viewport.get_visible_rect().size)


## Rentre un Control ancré plein écran (preset FULL_RECT) dans la zone sûre.
## [param compensate] : enfants plein écran qui doivent quand même couvrir toute la fenêtre
## (éclair, rideau) ; ils reçoivent les offsets opposés.
static func apply(control: Control, insets: Vector4, compensate: Array[Control] = []) -> void:
	control.offset_left = insets.x
	control.offset_top = insets.y
	control.offset_right = -insets.z
	control.offset_bottom = -insets.w
	for child: Control in compensate:
		child.offset_left = -insets.x
		child.offset_top = -insets.y
		child.offset_right = insets.z
		child.offset_bottom = insets.w
