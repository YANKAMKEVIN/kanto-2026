class_name EmotePlacement
extends RefCounted
## Placement de la bulle « ! » d'un Dresseur dans la vue (jalon 9, correctif de la bulle rognée).
## Logique pure : à partir de la position écran de la pointe, du format de la vue et de
## l'encombrement de la bulle, donne le décalage minimal qui la garde entière dans la vue (marge
## de sécurité de l'UI), sans toucher à sa position quand il y a la place.


## Décalage (px écran = px monde, zoom 1) à ajouter à la pointe [param tip_screen] pour que la
## bulle, d'étendue [param extent] (gauche, haut, droite, bas, en px, mesurée depuis la pointe,
## valeurs positives) reste dans [param view] reculée de [param margin]. Vers le bas et/ou le
## côté opposé au bord touché ; nul si tout tient déjà. Si la vue est trop petite pour la bulle,
## le haut et la gauche l'emportent.
static func shift(tip_screen: Vector2, view: Vector2, extent: Rect2, margin: float) -> Vector2:
	var left := tip_screen.x - extent.position.x
	var top := tip_screen.y - extent.position.y
	var right := tip_screen.x + extent.size.x
	var bottom := tip_screen.y + extent.size.y
	var out := Vector2.ZERO
	if right > view.x - margin:
		out.x = view.x - margin - right
	if left + out.x < margin:
		out.x = margin - left
	if bottom > view.y - margin:
		out.y = view.y - margin - bottom
	if top + out.y < margin:
		out.y = margin - top
	return out
