class_name MomentRow
extends PanelContainer
## Une ligne de la frise des grands moments (dossier 08 §6 ; jalon-06.md §3.7, Q-14 ; MM.2,
## maquette) : rail (ligne et pastille), vignette du lieu (aperçu peint de la zone, sinon l'icône
## du type), artwork officiel du Pokémon posé sur la vignette s'il y en a un, titre, détail,
## « lieu · date ». Un texte vide = une ligne absente.
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
	MomentLibrary.BADGE: preload("res://assets/ui/icons/trainer/badge_slot.svg"),
}
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
	row.add_child(_build_thumb())
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


## Vignette : l'aperçu de la zone du moment (coins arrondis), l'icône du type par-dessus si la
## zone n'a pas d'aperçu, l'artwork du Pokémon en bas à droite s'il y en a un.
func _build_thumb() -> Control:
	var thumb := Panel.new()
	thumb.theme_type_variation = &"MapHero"
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.custom_minimum_size = UiTokens.TRAINER_MOMENT_THUMB
	thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var art := ZoneArt.new()
	art.set_style(float(UiTokens.TRAINER_MOMENT_THUMB_RADIUS), 1.0, UiTokens.SURFACE_DARK)
	art.show_zone(_view.zone_id)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	thumb.add_child(art)
	if not art.has_image():
		var icon := TextureRect.new()
		icon.texture = ICONS.get(_view.kind, ICON_DEFAULT)
		icon.modulate = UiTokens.ACCENT
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = Vector2.ONE * UiTokens.TRAINER_MOMENT_ICON
		icon.position = (UiTokens.TRAINER_MOMENT_THUMB - icon.size) * 0.5
		thumb.add_child(icon)
	if _view.kind == MomentLibrary.BADGE and art.has_image():
		# Le badge : son emblème (ACCENT) posé sur l'aperçu du lieu, comme l'artwork d'un Pokémon.
		var emblem := TextureRect.new()
		emblem.texture = ICONS[MomentLibrary.BADGE]
		emblem.modulate = UiTokens.ACCENT
		emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emblem.size = Vector2.ONE * UiTokens.TRAINER_MOMENT_ART
		emblem.position = UiTokens.TRAINER_MOMENT_THUMB - emblem.size
		thumb.add_child(emblem)
	var pokemon := MenuArt.pokemon_thumbnail(_view.dex_number)
	if pokemon != null:
		var picture := TextureRect.new()
		picture.texture = pokemon
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.size = Vector2.ONE * UiTokens.TRAINER_MOMENT_ART
		picture.position = UiTokens.TRAINER_MOMENT_THUMB - picture.size
		thumb.add_child(picture)
	return thumb


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
