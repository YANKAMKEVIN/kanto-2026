class_name PokedexSlot
extends BagTile
## Une case de la grille du Pokédex (dossier 08 §4 ; jalon-06.md §6.9) : légère (un fond de
## thème, une image et un seul dessin de texte), créée une fois puis remise à jour par
## [method set_view].
##
## - Case **inconnue** : numéro et « ??? » seulement, estompés. Ni image, ni silhouette, ni
##   toucher (le filtre de souris ignore tout : le doigt traverse et fait défiler la grille).
## - Case **vue** : sprite (s'il existe), numéro, nom, « Vu » avec un œil.
## - Case **capturée** : en plus, une Poké Ball et « Capturé » (symbole **et** texte : jamais
##   une couleur seule).
## Un toucher sur une case connue émet [signal tapped] (hérité) ; la grille en tire une seule
## ouverture de fiche.

const BALL_ICON: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")
const EYE_ICON: Texture2D = preload("res://assets/ui/icons/pokedex/eye.svg")
const SPRITE_PATH := "res://assets/sprites/pokemon/placeholder/%s_front.png"
const SEEN_TEXT := "Vu"
const CAUGHT_TEXT := "Capturé"

var _view: PokedexSlotView
var _holder: Control
var _art: TextureRect
var _face: Face


func _init() -> void:
	super()
	custom_minimum_size = UiTokens.DEX_CELL_SIZE
	normal_variation = &"DexCell"
	selected_variation = &"DexCellSelected"
	selected_scale = UiTokens.DEX_CELL_SELECTED_SCALE
	theme_type_variation = normal_variation
	# Un Container remplit ses enfants : l'image et le texte vivent dans un Control libre.
	_holder = Control.new()
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_holder)
	_art = TextureRect.new()
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.visible = false
	_holder.add_child(_art)
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
	mouse_filter = Control.MOUSE_FILTER_STOP if known else Control.MOUSE_FILTER_IGNORE
	normal_variation = &"DexCell" if known else &"DexCellUnknown"
	selected_variation = &"DexCellSelected" if known else &"DexCellUnknown"
	if is_selected() and not known:
		set_selected(false)
	theme_type_variation = selected_variation if is_selected() else normal_variation
	_art.texture = null
	_art.visible = false
	if known:
		var path := SPRITE_PATH % view.species_id
		if ResourceLoader.exists(path):
			_art.texture = load(path) as Texture2D
			_art.visible = _art.texture != null
	_face.setup(view)
	_layout()


func get_view() -> PokedexSlotView:
	return _view


## Vrai si la case affiche une image (jamais une case inconnue).
func has_image() -> bool:
	return _art.visible and _art.texture != null


func get_image() -> TextureRect:
	return _art


## Textes dessinés, dans l'ordre : numéro, nom, état (« Vu » / « Capturé », absent si inconnue).
func get_texts() -> PackedStringArray:
	return _face.texts()


func _layout() -> void:
	var side := float(UiTokens.DEX_CELL_SPRITE_SOURCE * UiTokens.DEX_CELL_SPRITE_SCALE)
	_art.size = Vector2.ONE * side
	_art.position = Vector2((size.x - side) * 0.5, UiTokens.DEX_CELL_SPRITE_TOP)
	_face.position = Vector2.ZERO
	_face.size = size
	_face.queue_redraw()


## Le texte de la case, dessiné d'un trait (pas un Label par ligne : 151 cases à tenir).
class Face extends Control:
	var _slot: PokedexSlotView
	var _bold: FontVariation

	func _init() -> void:
		_bold = FontVariation.new()
		_bold.variation_embolden = UiTokens.FONT_BOLD_EMBOLDEN

	func setup(slot: PokedexSlotView) -> void:
		_slot = slot
		_bold.base_font = get_theme_default_font()
		queue_redraw()

	func texts() -> PackedStringArray:
		var out := PackedStringArray()
		if _slot == null:
			return out
		out.append(_slot.number_text)
		out.append(_slot.name)
		if not _slot.is_unknown():
			out.append(PokedexSlot.CAUGHT_TEXT if _slot.caught else PokedexSlot.SEEN_TEXT)
		return out

	func _draw() -> void:
		if _slot == null:
			return
		var font := get_theme_default_font()
		_bold.base_font = font
		var pad := float(UiTokens.DEX_CELL_PAD)
		var unknown := _slot.is_unknown()
		var alpha := UiTokens.DEX_UNKNOWN_ALPHA if unknown else 1.0
		draw_string(_bold, Vector2(pad, pad + UiTokens.DEX_CELL_NUMBER_FONT),
			_slot.number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTokens.DEX_CELL_NUMBER_FONT,
			UiTokens.tinted(UiTokens.TEXT_MUTED, alpha))
		var status_y := size.y - pad - 2.0
		var name_y := status_y - UiTokens.DEX_CELL_STATUS_FONT - 8.0
		if unknown:
			name_y = size.y * 0.5 + UiTokens.DEX_CELL_NAME_FONT * 0.35
		_draw_fitted(_slot.name, name_y, UiTokens.DEX_CELL_NAME_FONT,
			UiTokens.tinted(UiTokens.TEXT, alpha) if not unknown
			else UiTokens.tinted(UiTokens.TEXT_MUTED, alpha), _bold)
		if unknown:
			return
		var icon := PokedexSlot.BALL_ICON if _slot.caught else PokedexSlot.EYE_ICON
		var label := PokedexSlot.CAUGHT_TEXT if _slot.caught else PokedexSlot.SEEN_TEXT
		var icon_side := float(UiTokens.DEX_CELL_BALL)
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1,
			UiTokens.DEX_CELL_STATUS_FONT)
		var total := icon_side + UiTokens.TYPE_BADGE_GAP + text_size.x
		var left := (size.x - total) * 0.5
		var tint := UiTokens.TEXT if _slot.caught else UiTokens.TEXT_MUTED
		draw_texture_rect(icon, Rect2(left, status_y - icon_side + 3.0, icon_side, icon_side),
			false, tint if not _slot.caught else UiTokens.TEXT)
		draw_string(font, Vector2(left + icon_side + UiTokens.TYPE_BADGE_GAP, status_y), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, UiTokens.DEX_CELL_STATUS_FONT,
			UiTokens.ACCENT if _slot.caught else UiTokens.TEXT_MUTED)

	## Texte centré, rétréci s'il dépasse la case.
	func _draw_fitted(text: String, baseline: float, font_size: int, color: Color,
			font: Font) -> void:
		var room := size.x - UiTokens.DEX_CELL_PAD * 2.0
		var used := font_size
		while used > UiTokens.DEX_CELL_STATUS_FONT and font.get_string_size(text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, used).x > room:
			used -= 1
		draw_string(font, Vector2(UiTokens.DEX_CELL_PAD, baseline), text,
			HORIZONTAL_ALIGNMENT_CENTER, room, used, color)
