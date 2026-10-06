class_name GroundMask
extends RefCounted
## Masque du sol peint d'une carte (docs/tech/jalon-07.md §6.6) : 1 pixel = 1 case, canal
## rouge = pavés, canal vert = chemin de terre, le reste = herbe. Lu par `ground_blend`
## ([PaintedGround]) qui rend la frontière irrégulière. Classe pure : l'outil de construction
## d'une carte l'écrit dans `assets/world/maps/<carte>_ground.png` ; la scène de capture le
## construit en mémoire.

enum Kind { GRASS, PAVING, PATH }


## Image du masque d'une carte de [param size] cases. [param paving] et [param path] :
## cases → vrai (dictionnaires ou tableaux de Vector2i). Hors carte : ignoré. Une case dans
## les deux : pavée.
static func build(size: Vector2i, paving: Variant, path: Variant = []) -> Image:
	var image := Image.create(maxi(size.x, 1), maxi(size.y, 1), false, Image.FORMAT_RG8)
	for cell: Vector2i in _cells(path):
		if _inside(size, cell):
			image.set_pixelv(cell, Color(0.0, 1.0, 0.0))
	for cell: Vector2i in _cells(paving):
		if _inside(size, cell):
			image.set_pixelv(cell, Color(1.0, 0.0, 0.0))
	return image


## Nature du sol de [param cell] d'après le masque (hors masque : herbe).
static func kind_at(mask: Image, cell: Vector2i) -> Kind:
	if mask == null or cell.x < 0 or cell.y < 0 or cell.x >= mask.get_width() \
			or cell.y >= mask.get_height():
		return Kind.GRASS
	var color := mask.get_pixelv(cell)
	if color.r > 0.5:
		return Kind.PAVING
	if color.g > 0.5:
		return Kind.PATH
	return Kind.GRASS


static func _cells(source: Variant) -> Array:
	if source is Dictionary:
		return (source as Dictionary).keys()
	if source is Array:
		return source
	return []


static func _inside(size: Vector2i, cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y
