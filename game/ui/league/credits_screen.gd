class_name CreditsScreen
extends CanvasLayer
## Générique de fin (jalon 30, T16 ; `docs/tech/jalon-30.md` §2.4, Q30-1) : les lignes de
## [CreditsData] montent lentement sur un fond nuit, logo du jeu en tête, jusqu'à ce que la
## dernière (« Merci d'avoir joué ») soit au centre ; tenue, puis fondu.
##
## Toucher (tenir) l'écran : défilement ×[constant UiTokens.CREDITS_RUSH] tant que le doigt est
## posé. **Passable** seulement si le générique a déjà été vu une fois (`league_credits_seen`,
## décidé par l'appelant) : bouton [member skip_label] en bas à droite. Présentation seulement,
## rien n'est écrit dans la partie. [member speed_scale] = 0 : instantané (tests).

## Fin du générique (après son fondu de sortie).
signal finished

const LOGO: Texture2D = preload("res://assets/ui/opening/logo_kanto_2026.png")

var speed_scale: float = 1.0
## Libellé du bouton « passer » (`data/story/credits.json`, « skip »).
var skip_label: String = ""

var _root: ColorRect
var _column: VBoxContainer
var _skip: Button
var _rush: bool = false
var _skipped: bool = false
var _running: bool = false


func _ready() -> void:
	layer = UiTokens.LAYER_HALL_OF_FAME
	_build()
	visible = false
	set_process_input(false)


## Coroutine : fait défiler [param rows] ([method CreditsData.rows]) ; [param skippable] : bouton
## pour passer (générique déjà vu).
func present(rows: Array[Dictionary], skippable: bool) -> void:
	_fill(rows)
	_skip.text = skip_label
	_skip.visible = skippable and not skip_label.is_empty()
	_rush = false
	_skipped = false
	_running = true
	_root.modulate.a = 0.0
	visible = true
	set_process_input(true)
	var view := _root.get_viewport_rect().size
	_column.reset_size()
	_column.size.x = view.x
	_column.position = Vector2(0.0, view.y)
	if speed_scale > 0.0:
		await _fade(1.0, UiTokens.CREDITS_FADE)
		# Fin : le centre de la dernière ligne au centre de l'écran.
		var last := _column.get_child(_column.get_child_count() - 1) as Control \
			if _column.get_child_count() > 0 else null
		var end_y := view.y / 2.0 - (last.position.y + last.size.y / 2.0 if last != null else 0.0)
		while is_inside_tree() and not _skipped and _column.position.y > end_y:
			await get_tree().process_frame
			var step := UiTokens.CREDITS_SPEED * get_process_delta_time() / speed_scale
			if _rush:
				step *= UiTokens.CREDITS_RUSH
			_column.position.y = maxf(_column.position.y - step, end_y)
		if not _skipped:
			var left := UiTokens.CREDITS_END_HOLD * speed_scale
			while is_inside_tree() and not _skipped and left > 0.0:
				await get_tree().process_frame
				left -= get_process_delta_time()
		await _fade(0.0, UiTokens.CREDITS_FADE)
	_running = false
	visible = false
	set_process_input(false)
	finished.emit()


func is_showing() -> bool:
	return visible


## Lignes affichées, dans l'ordre (tests).
func get_row_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	for child: Node in _column.get_children():
		if child is Label and not (child as Label).text.is_empty():
			texts.append((child as Label).text)
		elif child is TextureRect:
			texts.append(str(child.get_meta(&"text", "")))
	return texts


func is_skip_visible() -> bool:
	return _skip.visible


## Passe le générique (bouton ; tests). Sans effet s'il n'est pas passable.
func skip() -> void:
	if _skip.visible and _running:
		_skipped = true


func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null:
		if _skip.visible and touch.pressed and _skip.get_global_rect().has_point(touch.position):
			return
		_rush = touch.pressed
		get_viewport().set_input_as_handled()
		return
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.button_index == MOUSE_BUTTON_LEFT:
		if _skip.visible and _skip.get_global_rect().has_point(mouse.position):
			return
		_rush = mouse.pressed
		get_viewport().set_input_as_handled()


func _fade(alpha: float, seconds: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_root, ^"modulate:a", alpha, seconds * speed_scale)
	await tween.finished


func _fill(rows: Array[Dictionary]) -> void:
	for child: Node in _column.get_children():
		_column.remove_child(child)
		child.queue_free()
	for row: Dictionary in rows:
		var text := str(row.get("text", ""))
		match int(row.get("kind", CreditsData.RowKind.LINE)):
			CreditsData.RowKind.LOGO:
				var logo := TextureRect.new()
				logo.texture = LOGO
				logo.set_meta(&"text", text)
				logo.tooltip_text = text
				logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				logo.custom_minimum_size = Vector2(0.0, UiTokens.CREDITS_LOGO_HEIGHT)
				logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_column.add_child(logo)
			CreditsData.RowKind.TITLE:
				var title := _label(text, UiTokens.FONT_TITLE, UiTokens.ACCENT)
				title.theme_type_variation = &"WorldCaption"
				_column.add_child(title)
			CreditsData.RowKind.HEADING:
				_column.add_child(_label(text, UiTokens.FONT_BUTTON, UiTokens.ACCENT))
			CreditsData.RowKind.GAP:
				var gap := Control.new()
				gap.custom_minimum_size = Vector2(0.0, UiTokens.CREDITS_BLOCK_GAP)
				gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_column.add_child(gap)
			_:
				_column.add_child(_label(text, UiTokens.FONT_BODY, UiTokens.TEXT))


func _build() -> void:
	_root = ColorRect.new()
	_root.name = "Root"
	_root.color = UiTokens.FADE_COLOR
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_column = VBoxContainer.new()
	_column.name = "Column"
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_theme_constant_override(&"separation", UiTokens.CREDITS_LINE_GAP)
	_root.add_child(_column)
	_skip = Button.new()
	_skip.name = "Skip"
	_skip.theme_type_variation = &"PanelButton"
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.custom_minimum_size = Vector2(UiTokens.CREDITS_SKIP_WIDTH, UiTokens.TOUCH_MIN)
	_skip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_skip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_skip.position -= Vector2(UiTokens.SAFE_MARGIN, UiTokens.SAFE_MARGIN)
	_skip.visible = false
	_skip.pressed.connect(skip)
	_root.add_child(_skip)


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
