class_name HallOfFameScreen
extends CanvasLayer
## Écran du Panthéon (jalon 30, T15 ; `docs/tech/jalon-30.md` §2.4, texte T30-16) : l'équipe
## victorieuse, **un Pokémon après l'autre** (grand artwork officiel, ligne « {pokemon} — N{level} »,
## nom de l'espèce en petit sous un surnom), puis toute l'équipe ensemble jusqu'au toucher.
##
## Fond nuit opaque ([constant UiTokens.FADE_COLOR]), halo doré derrière le Pokémon, en-tête
## discret (nom du joueur, date). Présentation seulement : [method present] reçoit des vues toutes
## faites (Boot) et n'écrit rien dans la partie (l'entrée est ajoutée après, par
## [LeagueDirector]). Durées : jetons `UiTokens.HALL_*`, multipliées par [member speed_scale]
## (0 = instantané, sans attendre de toucher : tests). Un toucher abrège la tenue d'un Pokémon.
##
## Vue ([method present]) : { "header": String, "members": [ { "texture": Texture2D (ou null),
## "line": String, "subtitle": String } ] }.

## Fin de l'écran (après son fondu de sortie).
signal finished

var speed_scale: float = 1.0

var _root: ColorRect
var _halo: TextureRect
var _portrait: TextureRect
var _line: Label
var _subtitle: Label
var _header: Label
var _team: HBoxContainer
var _waiting_tap: bool = false
var _tap: bool = false
var _shown_msec: int = 0


func _ready() -> void:
	layer = UiTokens.LAYER_HALL_OF_FAME
	_build()
	visible = false
	set_process_input(false)


## Coroutine : montre l'équipe de [param view], puis rend la main une fois l'écran parti.
func present(view: Dictionary) -> void:
	var members: Array = view.get("members", [])
	_header.text = str(view.get("header", ""))
	_clear_team()
	_show_single(false)
	_team.visible = false
	_root.modulate.a = 0.0
	visible = true
	set_process_input(true)
	_shown_msec = Time.get_ticks_msec()
	await _fade(_root, 1.0, UiTokens.HALL_OPEN)
	for member: Variant in members:
		if member is Dictionary:
			await _present_member(member)
	await _present_team(members)
	await _fade(_root, 0.0, UiTokens.HALL_CLOSE)
	visible = false
	set_process_input(false)
	finished.emit()


## Coroutine (Q30-4, lecture seule depuis l'écran Dresseur) : chaque entrée de [param views]
## (même forme que [method present]), équipe entière, un toucher pour la suivante ; la dernière
## touchée, l'écran se ferme. Rien n'est écrit.
func browse(views: Array) -> void:
	if views.is_empty():
		return
	_show_single(false)
	_root.modulate.a = 0.0
	visible = true
	set_process_input(true)
	_shown_msec = Time.get_ticks_msec()
	await _fade(_root, 1.0, UiTokens.HALL_LEAVE)
	for view: Variant in views:
		if not view is Dictionary:
			continue
		_header.text = str((view as Dictionary).get("header", ""))
		_clear_team()
		await _present_team((view as Dictionary).get("members", []))
	await _fade(_root, 0.0, UiTokens.HALL_LEAVE)
	visible = false
	set_process_input(false)
	finished.emit()


func is_showing() -> bool:
	return visible


## Texte de la ligne du Pokémon affiché (tests, captures).
func get_line_text() -> String:
	return _line.text


func get_team_size() -> int:
	return _team.get_child_count()


func _present_member(member: Dictionary) -> void:
	_portrait.texture = member.get("texture") as Texture2D
	_line.text = str(member.get("line", ""))
	_subtitle.text = str(member.get("subtitle", ""))
	_subtitle.visible = not _subtitle.text.is_empty()
	_show_single(true)
	_portrait.pivot_offset = _portrait.size / 2.0
	_portrait.scale = Vector2.ONE * UiTokens.HALL_ENTER_SCALE
	for node: CanvasItem in [_portrait, _halo, _line, _subtitle]:
		node.modulate.a = 0.0
	if speed_scale > 0.0:
		var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
		var time := UiTokens.HALL_ENTER * speed_scale
		tween.tween_property(_portrait, ^"scale", Vector2.ONE, time)
		for node: CanvasItem in [_portrait, _halo, _line, _subtitle]:
			tween.tween_property(node, ^"modulate:a", 1.0, time)
	else:
		_portrait.scale = Vector2.ONE
		for node: CanvasItem in [_portrait, _halo, _line, _subtitle]:
			node.modulate.a = 1.0
	await _hold(UiTokens.HALL_ENTER + UiTokens.HALL_HOLD)
	var nodes: Array[CanvasItem] = [_portrait, _halo, _subtitle]
	for node: CanvasItem in nodes:
		_fade(node, 0.0, UiTokens.HALL_LEAVE)
	await _fade(_line, 0.0, UiTokens.HALL_LEAVE)


func _present_team(members: Array) -> void:
	_show_single(false)
	for member: Variant in members:
		if not member is Dictionary:
			continue
		var card := VBoxContainer.new()
		card.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_theme_constant_override(&"separation", UiTokens.HALL_TEAM_GAP)
		var art := TextureRect.new()
		art.texture = (member as Dictionary).get("texture") as Texture2D
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2.ONE * UiTokens.HALL_TEAM_ART
		card.add_child(art)
		card.add_child(_label(str((member as Dictionary).get("line", "")), UiTokens.FONT_CAPTION,
			UiTokens.TEXT))
		_team.add_child(card)
	_team.visible = true
	_team.modulate.a = 0.0
	await _fade(_team, 1.0, UiTokens.HALL_ENTER)
	await _hold(UiTokens.HALL_TEAM_MIN, true)


## Tenue de [param seconds] (× speed_scale), abrégée par un toucher ; [param until_tap] : la tenue
## faite, attend en plus un toucher. speed_scale = 0 : rien (tests).
func _hold(seconds: float, until_tap: bool = false) -> void:
	if speed_scale <= 0.0:
		return
	_tap = false
	_waiting_tap = true
	var left := seconds * speed_scale
	while is_inside_tree() and not _tap and (left > 0.0 or until_tap):
		await get_tree().process_frame
		left -= get_process_delta_time()
		if until_tap and left > 0.0:
			_tap = false
	_waiting_tap = false


func _input(event: InputEvent) -> void:
	var tapped := (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or event.is_action_pressed(&"interact")
	if not tapped:
		return
	get_viewport().set_input_as_handled()
	if _waiting_tap and Time.get_ticks_msec() - _shown_msec >= int(UiTokens.HALL_TAP_DELAY * 1000.0):
		_tap = true


func _fade(node: CanvasItem, alpha: float, seconds: float) -> void:
	if speed_scale <= 0.0:
		node.modulate.a = alpha
		return
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, ^"modulate:a", alpha, seconds * speed_scale)
	await tween.finished


func _show_single(shown: bool) -> void:
	for node: CanvasItem in [_portrait, _halo, _line, _subtitle]:
		node.visible = shown
	if not shown:
		_subtitle.visible = false


func _clear_team() -> void:
	for child: Node in _team.get_children():
		_team.remove_child(child)
		child.queue_free()


func _build() -> void:
	_root = ColorRect.new()
	_root.name = "Root"
	_root.color = UiTokens.FADE_COLOR
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_halo = TextureRect.new()
	_halo.name = "Halo"
	_halo.texture = PokedexArt.halo_texture()
	_halo.modulate = UiTokens.HALL_HALO
	_halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_halo.stretch_mode = TextureRect.STRETCH_SCALE
	_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_halo.set_anchors_preset(Control.PRESET_CENTER)
	_halo.size = Vector2.ONE * UiTokens.HALL_HALO_SIZE
	_halo.position = -_halo.size / 2.0 + Vector2(0.0, UiTokens.HALL_ART_CENTER_Y)
	_root.add_child(_halo)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override(&"separation", UiTokens.HALL_LINE_GAP)
	_root.add_child(column)
	_portrait = TextureRect.new()
	_portrait.name = "Portrait"
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.custom_minimum_size = Vector2(0.0, UiTokens.HALL_ART)
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_portrait)
	_line = _label("", UiTokens.FONT_TITLE, UiTokens.TEXT)
	_line.theme_type_variation = &"WorldCaption"
	_line.name = "Line"
	column.add_child(_line)
	_subtitle = _label("", UiTokens.FONT_BODY, UiTokens.TEXT_MUTED)
	_subtitle.name = "Subtitle"
	column.add_child(_subtitle)
	_team = HBoxContainer.new()
	_team.name = "Team"
	_team.alignment = BoxContainer.ALIGNMENT_CENTER
	_team.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team.add_theme_constant_override(&"separation", UiTokens.HALL_TEAM_GAP)
	# Rangée de l'équipe centrée dans l'écran (verticalement aussi).
	var center := CenterContainer.new()
	center.name = "TeamCenter"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	center.add_child(_team)
	_header = _label("", UiTokens.FONT_CAPTION, UiTokens.TEXT_MUTED)
	_header.name = "Header"
	_header.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_header.position.y = UiTokens.SAFE_MARGIN
	_header.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.add_child(_header)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_shadow_color", UiTokens.TEXT_SHADOW)
	label.add_theme_constant_override(&"shadow_offset_x", UiTokens.TEXT_SHADOW_OFFSET)
	label.add_theme_constant_override(&"shadow_offset_y", UiTokens.TEXT_SHADOW_OFFSET)
	return label
