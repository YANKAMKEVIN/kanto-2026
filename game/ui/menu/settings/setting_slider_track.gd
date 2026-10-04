class_name SettingSliderTrack
extends Control
## Piste d'un curseur (Paramètres, T28), dessinée : piste, partie remplie en ACCENT, pastille.
## Le doigt (ou la souris) la tient : [signal previewed] à chaque déplacement (le pourcentage suit
## le doigt), puis **un seul** [signal committed] au lâcher, avec la valeur calée sur un cran
## (`min + n × step`) ; si elle égale la valeur de départ, rien n'est émis.
## Zone tactile : toute la piste, ≥ TOUCH_MIN de haut.
## L'appui n'est **pas** accepté : la liste qui défile doit le voir (sinon elle ne démarre pas).

signal previewed(value: float)
signal committed(value: float)

var min_value: float = 0.0
var max_value: float = 1.0
var step: float = 0.1
var enabled: bool = true

var _value: float = 0.0
var _start_value: float = 0.0
## Appui en cours (le doigt est posé sur la piste).
var _pressed: bool = false
## Le geste est horizontal : la piste suit le doigt.
var _dragging: bool = false
## Le geste est vertical (ou fini en défilement) : il appartient à la liste, la piste n'agit pas.
var _scrolling: bool = false
var _origin: Vector2 = Vector2.ZERO


func _init() -> void:
	custom_minimum_size = Vector2(UiTokens.SETTINGS_SLIDER_WIDTH, UiTokens.TOUCH_MIN)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Dans un défilement : les événements tactiles doivent remonter jusqu'au ScrollContainer.
	mouse_filter = Control.MOUSE_FILTER_PASS


## Règle « toucher ou défilement » : rien ne bouge à l'appui ; au-delà de TAP_SLOP, l'axe dominant
## décide (horizontal : la piste suit le doigt et garde le geste ; vertical : la liste défile) ;
## relâché sans avoir passé le seuil, c'est un toucher : la valeur se pose au relâchement.
func _gui_input(event: InputEvent) -> void:
	if not enabled:
		return
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_pressed = true
			_dragging = false
			_scrolling = false
			_origin = button.global_position
			_start_value = _value
		elif _pressed:
			var tap := not _dragging and not _scrolling
			_pressed = false
			if tap:
				_dragging = true
				_move_to(button.position.x)
			if _dragging:
				_dragging = false
				if not is_equal_approx(_value, _start_value):
					committed.emit(_value)
			_scrolling = false
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _pressed:
		if not _dragging and not _scrolling and TapGuard.is_scroll(_origin,
				motion.global_position):
			var delta := motion.global_position - _origin
			if absf(delta.x) >= absf(delta.y):
				_dragging = true
			else:
				_scrolling = true
		if _dragging:
			# Le geste horizontal est à la piste : la liste ne doit pas aussi défiler.
			accept_event()
			_move_to(motion.position.x)
		return
	if event is InputEventScreenDrag and _dragging:
		accept_event()


func _draw() -> void:
	var knob := float(UiTokens.SETTINGS_SLIDER_KNOB)
	var track_h := float(UiTokens.SETTINGS_SLIDER_TRACK)
	var left := knob * 0.5
	var width := maxf(size.x - knob, 1.0)
	var y := size.y * 0.5
	var radius := track_h * 0.5
	var back := UiTokens.SETTINGS_SLIDER_TRACK_BG
	draw_line(Vector2(left, y), Vector2(left + width, y), back, track_h, true)
	draw_circle(Vector2(left, y), radius, back, true, -1.0, true)
	draw_circle(Vector2(left + width, y), radius, back, true, -1.0, true)
	var fill := UiTokens.ACCENT if enabled else UiTokens.SETTINGS_SWITCH_OFF
	var knob_x := left + width * _ratio()
	draw_line(Vector2(left, y), Vector2(knob_x, y), fill, track_h, true)
	draw_circle(Vector2(left, y), radius, fill, true, -1.0, true)
	draw_circle(Vector2(knob_x, y), knob * 0.5, UiTokens.SETTINGS_SWITCH_KNOB_COLOR, true,
		-1.0, true)


func get_value() -> float:
	return _value


func is_dragging() -> bool:
	return _dragging


## Pose la valeur affichée (la vue revient) ; ignoré pendant que le doigt tient la piste.
func set_value(value: float) -> void:
	if _dragging:
		return
	_value = value
	queue_redraw()


## Valeur d'un cran la plus proche de [param x] (coordonnée locale).
func value_at(x: float) -> float:
	var knob := float(UiTokens.SETTINGS_SLIDER_KNOB)
	var ratio := clampf((x - knob * 0.5) / maxf(size.x - knob, 1.0), 0.0, 1.0)
	var steps := roundi(ratio * (max_value - min_value) / step)
	return snappedf(clampf(min_value + steps * step, min_value, max_value), 0.0001)


func _ratio() -> float:
	if max_value <= min_value:
		return 0.0
	return clampf((_value - min_value) / (max_value - min_value), 0.0, 1.0)


func _move_to(x: float) -> void:
	var value := value_at(x)
	if is_equal_approx(value, _value):
		return
	_value = value
	queue_redraw()
	previewed.emit(value)
