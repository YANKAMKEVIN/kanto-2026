class_name MapScreen
extends MenuScreen
## Écran Carte du Menu Dresseur (dossier 08 §5 ; jalon-06.md §6.10 ; maquette menu-carte-v1.jpg
## pour la DA seulement, règle 10) : l'illustration de Kanto entière, le nom des seules zones
## **découvertes**, le portrait du joueur et, à droite, le panneau de la zone choisie.
##
## Un journal, pas un guide : aucun bouton de déplacement, aucun total, aucun « ??? », aucun
## nom ni toucher pour une zone non découverte (Q-15). Il reçoit un [MapView] puis un
## [ZonePanelView] et n'en sait rien d'autre ; il émet des intentions.
## - Une zone découverte touchée : **un** [signal zone_touched] ; l'écran n'ouvre pas le
##   panneau lui-même, il attend [method show_zone] (le directeur décide).
## - Un Pokémon observé touché : un [signal route_requested] vers sa fiche du Pokédex.
## - RETOUR / retour Android : [signal back_requested] (le panneau est latéral : rien à fermer).
## Placement : rempli par [TrainerMenu] sous l'en-tête, marges de SAFE_MARGIN.

## Une zone découverte touchée sur l'illustration (jamais une autre zone).
signal zone_touched(zone: StringName)

const BACK_TEXT := "RETOUR"
const BACK_ICON: Texture2D = preload("res://assets/ui/icons/battle/back.svg")

var _view: MapView
var _back: Button
var _title: Label
var _body: HBoxContainer
var _ratio: AspectRatioContainer
var _frame: PanelContainer
var _canvas: MapCanvas
var _panel: ZonePanel


func _ready() -> void:
	super()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := HBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override(&"separation", UiTokens.MAP_GAP)
	add_child(body)
	_body = body
	# L'illustration prend toute la hauteur ; son cadre est calculé (voir _fit_map).
	_ratio = AspectRatioContainer.new()
	_ratio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ratio.stretch_mode = AspectRatioContainer.STRETCH_FIT
	body.add_child(_ratio)
	# Cadre à coins arrondis : l'image est rognée à ses coins seulement.
	_frame = PanelContainer.new()
	_frame.theme_type_variation = &"MapFrame"
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_ratio.add_child(_frame)
	_canvas = MapCanvas.new()
	_canvas.zone_pressed.connect(zone_touched.emit)
	_frame.add_child(_canvas)
	# Colonne de droite : RETOUR et titre, puis le panneau de la zone.
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", UiTokens.MAP_GAP)
	body.add_child(column)
	_build_header(column)
	_panel = ZonePanel.new()
	_panel.speed_scale = speed_scale
	_panel.visible = false
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.route_requested.connect(route_requested.emit)
	column.add_child(_panel)
	body.resized.connect(_fit_map)
	if _view != null:
		_apply_map(_view)


## Affiche [param view] : illustration, zones découvertes, portrait. Rappelé pendant que
## l'écran est affiché, il met à jour **sans rejouer l'entrée**.
func show_map(view: MapView) -> void:
	_view = view
	if _canvas != null:
		_apply_map(view)


## Affiche le panneau de [param view] (sans changer d'écran) et met la zone en avant sur
## l'illustration. Rappelé pour la même zone, il met à jour sans rejouer le fondu.
func show_zone(view: ZonePanelView) -> void:
	if _panel == null:
		return
	_panel.speed_scale = speed_scale
	_panel.show_zone(view)
	_canvas.set_selected(view.zone_id)


func get_back_button() -> Button:
	return _back


func get_title_label() -> Label:
	return _title


func get_map_canvas() -> MapCanvas:
	return _canvas


func get_panel() -> ZonePanel:
	return _panel


func _build_header(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size.y = UiTokens.MAP_HEADER_HEIGHT
	row.add_theme_constant_override(&"separation", UiTokens.MAP_GAP)
	parent.add_child(row)
	_back = Button.new()
	_back.theme_type_variation = &"PanelButton"
	_back.text = BACK_TEXT
	_back.icon = BACK_ICON
	_back.focus_mode = Control.FOCUS_NONE
	_back.custom_minimum_size = Vector2(UiTokens.MAP_BACK_WIDTH, UiTokens.TOUCH_MIN)
	_back.pressed.connect(back_requested.emit)
	row.add_child(_back)
	_title = Label.new()
	_title.theme_type_variation = &"DexTitle"
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_title)


func _apply_map(view: MapView) -> void:
	_title.text = view.title
	if view.image_size.y > 0:
		_ratio.ratio = float(view.image_size.x) / float(view.image_size.y)
	_canvas.setup(view)
	_fit_map()


## Largeur de l'illustration : toute la hauteur si la colonne de droite garde sa largeur
## minimale, sinon ce qui reste. Le reste de la largeur va à la colonne.
func _fit_map() -> void:
	if _ratio == null or _body.size.y <= 0.0:
		return
	var wanted := _body.size.y * _ratio.ratio
	var room := _body.size.x - UiTokens.MAP_PANEL_WIDTH - UiTokens.MAP_GAP
	_ratio.custom_minimum_size.x = minf(wanted, maxf(room, 0.0))
