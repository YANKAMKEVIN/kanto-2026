class_name MomentRow
extends PanelContainer
## Une ligne de la frise des grands moments (dossier 08 §6 ; jalon-06.md §3.7, Q-14) : rail
## (ligne et pastille), icône du type, titre, détail, « lieu · date », petite image du Pokémon
## s'il y en a une. Un texte vide = une ligne absente.
##
## Touchable seulement si la vue a une route : un toucher émet **un** [signal touched] avec cette
## route, telle quelle (le déblocage est déjà appliqué par la vue). Sans route, rien ne se passe.

## La ligne (avec lien) est touchée.
signal touched(route: MenuRoute)

const ICONS: Dictionary[StringName, Texture2D] = {
	MomentLibrary.STARTER: preload("res://assets/ui/icons/menu/star_filled.svg"),
	MomentLibrary.RIVAL_BATTLE: preload("res://assets/ui/icons/trainer/rival.svg"),
	MomentLibrary.FIRST_CAPTURE: preload("res://assets/ui/icons/poke_ball.svg"),
	MomentLibrary.ZONE_ARRIVAL: preload("res://assets/ui/icons/menu/map.svg"),
}
const SPRITE_PATH := "res://assets/sprites/pokemon/placeholder/%s_front.png"
const ICON_DEFAULT: Texture2D = preload("res://assets/ui/icons/menu/map.svg")

var _view: MomentView
var _texts: PackedStringArray = PackedStringArray()
var _hit: Button


func _init(view: MomentView = null, first: bool = true, last: bool = true) -> void:
	_view = view if view != null else MomentView.new()
	theme_type_variation = &"TrainerMomentBox"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = UiTokens.TRAINER_MOMENT_HEIGHT
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Le bouton (fond et toucher) est derrière le contenu, qui prend la hauteur qu'il faut.
	_hit = Button.new()
	_hit.theme_type_variation = &"TrainerMoment"
	_hit.focus_mode = Control.FOCUS_NONE
	# Dans un défilement : le glissement du doigt doit atteindre le ScrollContainer.
	_hit.mouse_filter = Control.MOUSE_FILTER_PASS
	_hit.disabled = _view.route == null
	TapGuard.attach(_hit)
	_hit.pressed.connect(_on_pressed)
	add_child(_hit)
	_build(first, last)


## Le bouton de toucher (désactivé quand la ligne n'a pas de lien).
func get_hit() -> Button:
	return _hit


func get_view() -> MomentView:
	return _view


## Vrai si la ligne a un lien (une route de la vue).
func is_linked() -> bool:
	return _view.route != null


## Textes affichés, dans l'ordre (titre, détail, « lieu · date »).
func get_texts() -> PackedStringArray:
	return _texts


func _build(first: bool, last: bool) -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override(&"margin_left", UiTokens.TRAINER_MOMENT_PAD_H)
	margin.add_theme_constant_override(&"margin_right", UiTokens.TRAINER_MOMENT_PAD_H)
	margin.add_theme_constant_override(&"margin_top", UiTokens.TRAINER_MOMENT_PAD_V)
	margin.add_theme_constant_override(&"margin_bottom", UiTokens.TRAINER_MOMENT_PAD_V)
	add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.GAP)
	margin.add_child(row)
	row.add_child(Rail.new(first, last))
	var icon := TextureRect.new()
	icon.texture = ICONS.get(_view.kind, ICON_DEFAULT)
	icon.modulate = UiTokens.ACCENT
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * UiTokens.TRAINER_MOMENT_ICON
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_theme_constant_override(&"separation", 2)
	row.add_child(column)
	_add_text(column, _view.title, &"TrainerMomentTitle")
	_add_text(column, _view.detail, &"TrainerMomentDetail")
	var meta := PackedStringArray()
	for part: String in [_view.place, _view.date_text]:
		if not part.is_empty():
			meta.append(part)
	_add_text(column, " · ".join(meta), &"TrainerMomentMeta")
	var path := SPRITE_PATH % _view.species_id
	if _view.species_id != &"" and ResourceLoader.exists(path):
		var art := TextureRect.new()
		art.texture = load(path) as Texture2D
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2.ONE * UiTokens.TRAINER_MOMENT_SPRITE
		art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(art)


func _add_text(parent: Control, text: String, variation: StringName) -> void:
	if text.is_empty():
		return
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	_texts.append(text)


func _on_pressed() -> void:
	if _view.route == null:
		return
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	touched.emit(_view.route)


## Rail de la frise : une ligne continue (qui traverse l'écart entre deux lignes) et une pastille
## ; la ligne commence à la pastille de la première ligne et finit à celle de la dernière.
class Rail extends Control:
	var _first: bool
	var _last: bool

	func _init(first: bool, last: bool) -> void:
		_first = first
		_last = last
		custom_minimum_size.x = UiTokens.TRAINER_RAIL_WIDTH
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		# On déborde de la marge de la ligne et de la moitié de l'écart pour joindre la suivante.
		var center := Vector2(size.x * 0.5, size.y * 0.5)
		var reach := UiTokens.TRAINER_MOMENT_PAD_V + UiTokens.TRAINER_MOMENT_GAP * 0.5
		var top := center.y if _first else -reach
		var bottom := center.y if _last else size.y + reach
		draw_line(Vector2(center.x, top), Vector2(center.x, bottom),
			UiTokens.TRAINER_RAIL_COLOR, UiTokens.TRAINER_RAIL_LINE, true)
		draw_circle(center, UiTokens.TRAINER_RAIL_DOT, UiTokens.PANEL_BG_STRONG)
		draw_arc(center, UiTokens.TRAINER_RAIL_DOT, 0.0, TAU, 24, UiTokens.ACCENT,
			UiTokens.TRAINER_RAIL_LINE, true)
