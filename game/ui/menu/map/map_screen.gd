class_name MapScreen
extends MenuScreen
## Écran Carte du Menu Dresseur (dossier 08 §5 ; jalon-06.md §6.10 ; maquette menu-carte-v1.jpg
## pour la DA seulement, règle 10) : l'illustration de Kanto entière, le nom des seules zones
## **découvertes** (lieu courant en ACCENT), le portrait du joueur, à droite le panneau de la zone
## choisie, en bas la carte « Exploration » et la frise des zones découvertes (MM.2).
##
## Un journal, pas un guide : aucun bouton de déplacement, aucun total (« N zones découvertes »,
## jamais « N / M »), aucun « ??? », aucun nom ni toucher pour une zone non découverte (Q-15).
## Il reçoit un [MapView] puis un [ZonePanelView] et n'en sait rien d'autre ; il émet des
## intentions.
## - Une zone découverte touchée (sur l'illustration **ou** dans la frise) : **un**
##   [signal zone_touched] ; l'écran n'ouvre pas le panneau lui-même, il attend
##   [method show_zone] (le directeur décide).
## - Un Pokémon observé touché : un [signal route_requested] vers sa fiche du Pokédex.
## - « ‹ » / retour Android : [signal back_requested] (le panneau est latéral : rien à fermer).
## Composition (MM.2) : l'écran remonte dans la rangée du × (covers_header) et y pose son « ‹ »
## (owns_back), la Poké Ball, « Carte » et « Kanto » ; bandeau d'état de l'hôte à droite (lieu) ;
## panneaux de verre sur le monde flouté plus clair. Quand l'écran est plus large que
## l'illustration, le cadre est prolongé par l'illustration très floue (MapEcho).
## Placement : rempli par [TrainerMenu] sous l'en-tête, marges de SAFE_MARGIN.

## Une zone découverte touchée sur l'illustration ou dans la frise (jamais une autre zone).
signal zone_touched(zone: StringName)

const BACK_TEXT := "RETOUR"
## Titre et région de l'en-tête (MM.2 ; la vue garde « CARTE — KANTO » pour les tests de logique).
const TITLE_TEXT := "Carte"
const REGION_TEXT := "Kanto"
const BACK_ICON: Texture2D = preload("res://assets/ui/icons/battle/back.svg")
const BALL_ICON: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")
const ECHO_SHADER: Shader = preload("res://game/ui/menu/map/map_echo.gdshader")

var _view: MapView
var _back: Button
var _title: Label
var _body: HBoxContainer
var _frame: PanelContainer
var _echo: TextureRect
var _echo_material: ShaderMaterial
var _canvas: MapCanvas
var _panel: ZonePanel
var _strip: ZoneStrip


func _init() -> void:
	covers_header = true
	owns_back = true
	backdrop_dim = UiTokens.MENU_GLASS_DIM
	backdrop_blur = UiTokens.MENU_GLASS_BLUR
	backdrop_lod = UiTokens.MENU_GLASS_LOD


func _ready() -> void:
	super()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_top = -UiTokens.DEX_LAYOUT_RISE
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.MAP_GAP)
	add_child(column)
	_build_header(column)
	_body = HBoxContainer.new()
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override(&"separation", UiTokens.MAP_GAP)
	column.add_child(_body)
	# Cadre à coins arrondis : l'écho flou au fond, l'illustration entière par-dessus.
	_frame = PanelContainer.new()
	_frame.theme_type_variation = &"MapFrame"
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(_frame)
	_echo = TextureRect.new()
	_echo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_echo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_echo.stretch_mode = TextureRect.STRETCH_SCALE
	_echo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_echo_material = ShaderMaterial.new()
	_echo_material.shader = ECHO_SHADER
	_echo_material.set_shader_parameter(&"lod", UiTokens.MAP_ECHO_LOD)
	_echo_material.set_shader_parameter(&"dim", UiTokens.MAP_ECHO_DIM)
	_echo_material.set_shader_parameter(&"dim_color", UiTokens.SURFACE_DARK)
	_echo.material = _echo_material
	_echo.resized.connect(_on_echo_resized)
	_frame.add_child(_echo)
	_canvas = MapCanvas.new()
	_canvas.zone_pressed.connect(zone_touched.emit)
	_frame.add_child(_canvas)
	_panel = ZonePanel.new()
	_panel.speed_scale = speed_scale
	_panel.visible = false
	_panel.route_requested.connect(route_requested.emit)
	_body.add_child(_panel)
	_strip = ZoneStrip.new()
	_strip.zone_chosen.connect(zone_touched.emit)
	column.add_child(_strip)
	_body.resized.connect(_fit_map)
	if _view != null:
		_apply_map(_view)


## Affiche [param view] : illustration, zones découvertes, portrait, frise. Rappelé pendant que
## l'écran est affiché, il met à jour **sans rejouer l'entrée**.
func show_map(view: MapView) -> void:
	_view = view
	if _canvas != null:
		_apply_map(view)


## Affiche le panneau de [param view] (sans changer d'écran) et met la zone en avant sur
## l'illustration et dans la frise. Rappelé pour la même zone, il met à jour sans rejouer le fondu.
func show_zone(view: ZonePanelView) -> void:
	if _panel == null:
		return
	_panel.speed_scale = speed_scale
	var illustration: Texture2D = null
	var area := Rect2()
	if _view != null:
		illustration = MenuArt.texture(_view.image_path)
		var zone := _view.zone(view.zone_id)
		if zone != null:
			area = zone.area
	_panel.show_zone(view, illustration, area)
	_canvas.set_selected(view.zone_id)
	_strip.set_selected(view.zone_id)
	_fit_map()


func get_back_button() -> Button:
	return _back


func get_title_label() -> Label:
	return _title


func get_map_canvas() -> MapCanvas:
	return _canvas


func get_panel() -> ZonePanel:
	return _panel


## Bandeau du bas : carte « Exploration » et frise des zones découvertes.
func get_strip() -> ZoneStrip:
	return _strip


## Fond flou du cadre (l'illustration étirée).
func get_echo() -> TextureRect:
	return _echo


## Tous les textes visibles de l'écran, dans l'ordre de l'arbre.
func get_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	_collect_texts(self, texts)
	return texts


func _build_header(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size.y = UiTokens.TOUCH_MIN
	row.add_theme_constant_override(&"separation", UiTokens.MENU_TITLE_GAP)
	parent.add_child(row)
	_back = Button.new()
	_back.theme_type_variation = &"MenuRoundButton"
	_back.icon = BACK_ICON
	_back.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_back.tooltip_text = BACK_TEXT
	_back.focus_mode = Control.FOCUS_NONE
	_back.custom_minimum_size = Vector2.ONE * UiTokens.TOUCH_MIN
	_back.pressed.connect(_on_back)
	row.add_child(_back)
	var ball := TextureRect.new()
	ball.texture = BALL_ICON
	ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ball.custom_minimum_size = Vector2.ONE * UiTokens.MENU_TITLE_ICON
	ball.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ball)
	_title = Label.new()
	_title.theme_type_variation = &"MenuScreenTitle"
	_title.text = TITLE_TEXT
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_title)
	var region := Label.new()
	region.theme_type_variation = &"MenuScreenCount"
	region.text = REGION_TEXT
	region.mouse_filter = Control.MOUSE_FILTER_IGNORE
	region.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(region)


func _apply_map(view: MapView) -> void:
	var image := MenuArt.texture(view.image_path)
	_echo.texture = image
	if image != null:
		_echo_material.set_shader_parameter(&"texture_size", image.get_size())
	_canvas.setup(view)
	_strip.setup(view, image)
	_fit_map()


## Largeur du panneau : ce qui reste quand l'illustration prend toute sa hauteur, entre
## MAP_PANEL_MIN et MAP_PANEL_MAX ; le cadre prend le reste (l'écho comble l'écart).
func _fit_map() -> void:
	if _view == null or _body == null or _body.size.y <= 0.0 or _view.image_size.y <= 0:
		return
	var ratio := float(_view.image_size.x) / float(_view.image_size.y)
	var room := _body.size.x - _body.size.y * ratio - UiTokens.MAP_GAP
	_panel.custom_minimum_size.x = clampf(room, UiTokens.MAP_PANEL_MIN, UiTokens.MAP_PANEL_MAX)


func _on_echo_resized() -> void:
	_echo_material.set_shader_parameter(&"rect_size", _echo.size)


func _on_back() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	back_requested.emit()


func _collect_texts(node: Node, into: PackedStringArray) -> void:
	for child: Node in node.get_children():
		if child.is_queued_for_deletion():
			continue
		var label := child as Label
		if label != null and label.is_visible_in_tree() and not label.text.is_empty():
			into.append(label.text)
		_collect_texts(child, into)
