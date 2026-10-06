class_name PokedexSlot
extends BagTile
## Une case de la grille du Pokédex (refonte, docs/tech/pokedex-refonte.md §3 T2) : un carré
## de 128 px, léger (un fond de thème, deux images et un seul dessin), créé une fois puis remis
## à jour par [method set_view]. Aucune lecture de fichier : l'image est une région de l'atlas
## de [PokedexArt], déjà en mémoire.
##
## - Case **inconnue** : halo atténué, **silhouette** de la vignette (même région, matériau de
##   [method PokedexArt.silhouette_material] : la forme seule) et numéro estompé. Jamais de nom,
##   de couleur, de détail ni de toucher (le filtre de souris ignore tout : le doigt traverse et
##   fait défiler la grille).
## - Case **vue** : halo, artwork, numéro.
## - Case **capturée** : en plus, une Poké Ball en haut à droite (symbole : l'état ne dépend
##   jamais d'une couleur seule).
## Un toucher sur une case connue émet [signal tapped] (hérité) ; la grille en tire une seule
## ouverture de fiche.

const BALL_ICON: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")

var _view: PokedexSlotView
var _holder: Control
var _halo: TextureRect
var _art: TextureRect
var _face: Face


func _init() -> void:
	super()
	custom_minimum_size = UiTokens.DEX_CELL_SIZE
	normal_variation = &"DexCell"
	selected_variation = &"DexCellSelected"
	selected_scale = UiTokens.DEX_CELL_SELECTED_SCALE
	theme_type_variation = normal_variation
	# Un Container remplit ses enfants : les images et le texte vivent dans un Control libre.
	_holder = Control.new()
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_holder)
	_halo = _make_image(PokedexArt.halo_texture(), TextureRect.EXPAND_IGNORE_SIZE,
		TextureRect.STRETCH_SCALE)
	_art = _make_image(null, TextureRect.EXPAND_IGNORE_SIZE,
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_art.visible = false
	_face = Face.new()
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(_face)
	resized.connect(_layout)


## Pose [param view] sur la case (null : case vide, cachée et inerte).
func set_view(view: PokedexSlotView) -> void:
	_view = view
	visible = view != null
	if view == null:
		return
	var known := not view.is_unknown()
	mouse_filter = Control.MOUSE_FILTER_PASS if known else Control.MOUSE_FILTER_IGNORE
	normal_variation = &"DexCell" if known else &"DexCellUnknown"
	selected_variation = &"DexCellSelected" if known else &"DexCellUnknown"
	if is_selected() and not known:
		set_selected(false)
	theme_type_variation = selected_variation if is_selected() else normal_variation
	_art.texture = PokedexArt.thumbnail(view.number)
	_art.visible = _art.texture != null
	_art.material = null if known else PokedexArt.silhouette_material()
	_halo.modulate.a = 1.0 if known else UiTokens.DEX_HALO_UNKNOWN_ALPHA
	_face.setup(view)
	_layout()


func get_view() -> PokedexSlotView:
	return _view


## Vrai si la case affiche une image (silhouette comprise).
func has_image() -> bool:
	return _art.visible and _art.texture != null


## Vrai si l'image est une silhouette (case inconnue) : le matériau de [PokedexArt].
func has_silhouette() -> bool:
	return has_image() and _art.material == PokedexArt.silhouette_material()


## Vrai si la Poké Ball de « capturé » est dessinée.
func has_ball() -> bool:
	return _view != null and _view.caught


func get_image() -> TextureRect:
	return _art


## Textes dessinés : le numéro seulement (le nom n'est pas dessiné dans la case).
## Pour les tests, une case **connue** y ajoute son nom ; une case inconnue n'a **jamais** que
## son numéro (aucun « ??? », aucun nom).
func get_texts() -> PackedStringArray:
	var out := PackedStringArray()
	if _view == null:
		return out
	out.append(_view.number_text)
	if not _view.is_unknown():
		out.append(_view.name)
	return out


func _make_image(texture: Texture2D, expand: TextureRect.ExpandMode,
		stretch: TextureRect.StretchMode) -> TextureRect:
	var rect := TextureRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture = texture
	rect.expand_mode = expand
	rect.stretch_mode = stretch
	_holder.add_child(rect)
	return rect


func _layout() -> void:
	_halo.position = Vector2.ZERO
	_halo.size = size
	var side := float(UiTokens.DEX_CELL_IMAGE)
	_art.size = Vector2.ONE * side
	_art.position = Vector2((size.x - side) * 0.5, UiTokens.DEX_CELL_IMAGE_TOP)
	_face.position = Vector2.ZERO
	_face.size = size
	_face.queue_redraw()


## Numéro et Poké Ball, dessinés d'un trait (pas un Label par case : 151 cases à tenir).
class Face extends Control:
	var _slot: PokedexSlotView
	var _bold: FontVariation

	func _init() -> void:
		_bold = FontVariation.new()
		_bold.variation_embolden = UiTokens.FONT_BOLD_EMBOLDEN

	func setup(slot: PokedexSlotView) -> void:
		_slot = slot
		queue_redraw()

	func _draw() -> void:
		if _slot == null:
			return
		_bold.base_font = get_theme_default_font()
		var pad := float(UiTokens.DEX_CELL_PAD)
		var alpha := UiTokens.DEX_UNKNOWN_ALPHA if _slot.is_unknown() else 1.0
		var at := Vector2(pad, pad + UiTokens.DEX_CELL_NUMBER_FONT)
		if not _slot.is_unknown():
			# Contour sombre : le numéro reste lisible par-dessus un artwork clair.
			draw_string_outline(_bold, at, _slot.number_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				UiTokens.DEX_CELL_NUMBER_FONT, UiTokens.DEX_CELL_NUMBER_OUTLINE,
				UiTokens.DEX_CELL_NUMBER_OUTLINE_COLOR)
		draw_string(_bold, at, _slot.number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTokens.DEX_CELL_NUMBER_FONT,
			UiTokens.tinted(UiTokens.TEXT_MUTED if _slot.is_unknown() else UiTokens.TEXT, alpha))
		if _slot.caught:
			var side := float(UiTokens.DEX_CELL_BALL)
			draw_texture_rect(PokedexSlot.BALL_ICON,
				Rect2(size.x - pad - side, pad, side, side), false)
