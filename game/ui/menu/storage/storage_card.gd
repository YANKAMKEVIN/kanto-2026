class_name StorageCard
extends TeamSlotCard
## Une carte de l'écran Stockage (colonne ÉQUIPE ou grille STOCKAGE) : le visuel de
## [TeamSlotCard] (portrait, nom, ♂/♀, Nv., PV, « K.O. », étoile du favori) et ses gestes, adaptés à
## une liste qui **défile** (jalon-07.md §0 point 3, §15.11) :
## - le filtre de souris est PASS et l'appui n'est pas consommé : la grille qui défile le reçoit ;
## - un doigt qui s'éloigne de plus de [constant UiTokens.TAP_SLOP] avant LONG_PRESS devient un
##   défilement ([signal press_cancelled]) : ni sélection, ni glisser ;
## - relâché avant LONG_PRESS, immobile : [signal tapped] ; tenu LONG_PRESS : [signal drag_started],
##   puis [signal drag_moved] et un seul [signal drag_released] (le glisser, lui, est consommé :
##   la grille ne défile plus sous le doigt).
## Les signaux portent l'index dans **sa** liste ([member place]) ; la carte ne décide de rien.

## Liste d'appartenance (colonne ÉQUIPE ou STOCKAGE).
var place: StorageRules.Place = StorageRules.Place.PARTY


func _init() -> void:
	super()
	mouse_filter = Control.MOUSE_FILTER_PASS
	# Le nom cède la place aux icônes (♂/♀, étoile) dans une carte étroite.
	_name.clip_text = true
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _notification(what: int) -> void:
	# Godot active _process à l'entrée dans l'arbre dès qu'un script en définit une : sans cela,
	# chaque carte démarrerait un glisser seule après LONG_PRESS.
	if what == NOTIFICATION_READY:
		set_process(false)


func _process(delta: float) -> void:
	if _held:
		super(delta)


func _gui_input(event: InputEvent) -> void:
	if party_index < 0:
		return
	if _dragging and event is InputEventScreenDrag:
		accept_event()
		return
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			if _held:
				return
			_held = true
			_dragging = false
			_held_time = 0.0
			_press_position = button.global_position
			set_process(true)
			return
		if not _held:
			return
		var moved := button.global_position.distance_to(_press_position)
		var was_dragging := _dragging
		_held = false
		_dragging = false
		set_process(false)
		if was_dragging:
			accept_event()
			drag_released.emit(party_index, _to_global(button.position))
		elif Rect2(Vector2.ZERO, size).has_point(button.position) \
				and moved <= UiTokens.TAP_SLOP:
			tapped.emit(party_index)
		else:
			press_cancelled.emit(party_index)
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _held:
		if _dragging:
			accept_event()
			drag_moved.emit(party_index, _to_global(motion.position))
		elif TapGuard.is_scroll(_press_position, motion.global_position):
			_held = false
			set_process(false)
			press_cancelled.emit(party_index)
