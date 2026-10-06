class_name ExpSummaryRow
extends PanelContainer
## Une ligne du bilan de fin de combat (ExpSummaryCard, demande n° 1) : vignette, nom,
## « Nv. 8 ▸ Nv. 9 », barre d'XP, « 112 / 173 », « +11 XP », et dessous (seulement si le
## Pokémon monte de niveau) les gains de statistiques.
##
## [method play] construit toute l'animation en un seul Tween : chaque tranche de barre se
## remplit (les nombres suivent), puis, à chaque passage de niveau, « Nv. » prend le niveau
## suivant et pulse, la ligne rebondit légèrement et prend un liseré ACCENT (elle attire
## l'attention), les gains apparaissent et une vibration courte est demandée. Plusieurs niveaux
## d'un coup : les tranches s'enchaînent, chaque passage est montré, les gains se cumulent.
## [method accelerate] fait tourner le Tween plus vite ; [method finish] le mène à sa fin (sans
## les vibrations qui restaient).

## Fin du remplissage (toutes les tranches et tous les passages de niveau).
signal finished
## Vibration demandée à un passage de niveau (millisecondes).
signal haptic_requested(duration_ms: int)

## « 112 / 173 ».
const POINTS_FORMAT := "%d / %d"
const ARROW_ICON: Texture2D = preload("res://assets/ui/icons/battle/select_arrow.svg")

var _view: ExpSummaryRowView
var _tween: Tween
var _done: bool = true
## Vrai pendant [method finish] : les passages de niveau restants ne vibrent pas.
var _finishing: bool = false
var _segment: int = 0
## Pulsation, rebond et fondu d'un passage de niveau en cours.
var _effects: Array[Tween] = []
var _thumb: PanelContainer
var _portrait: TextureRect
var _name: Label
var _old_level: Label
var _arrow: TextureRect
var _new_level: Label
var _bar: ExpBar
var _points: Label
var _gain: Label
var _stats: Label


func _init() -> void:
	theme_type_variation = &"SummaryRow"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


## Remplit la ligne avec [param view], à l'état de départ (barre à sa première valeur, aucun
## niveau gagné encore affiché). Si le Pokémon va monter de niveau, la ligne des gains garde
## sa place dès le départ (vide) : la carte ne change pas de taille en route.
func set_view(view: ExpSummaryRowView) -> void:
	_view = view
	_name.text = view.display_name
	_portrait.texture = view.portrait
	_thumb.visible = view.portrait != null
	_old_level.text = view.start_level_text
	_gain.text = view.gain_text
	_arrow.visible = false
	_new_level.visible = false
	_new_level.text = ""
	_stats.visible = view.levels_gained() > 0
	_stats.text = " "
	_stats.modulate.a = 0.0
	theme_type_variation = &"SummaryRow"
	_show_segment(0, view.segments[0].x)


## Lance l'animation (voir la classe) ; [param speed_scale] multiplie les durées (0 : tout de
## suite à la fin). [signal finished] est émis à la fin.
func play(speed_scale: float) -> void:
	_kill()
	_done = false
	_finishing = false
	var leveling := _view.levels_gained() > 0
	var fill := (UiTokens.SUMMARY_FILL_SLICE if leveling else UiTokens.SUMMARY_FILL) \
		* speed_scale
	if speed_scale <= 0.0 or not is_inside_tree():
		finish_now()
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(UiTokens.SUMMARY_START_DELAY * speed_scale)
	for i: int in _view.segments.size():
		var segment: Vector2 = _view.segments[i]
		_tween.tween_callback(_show_segment.bind(i, segment.x))
		if not is_equal_approx(segment.x, segment.y):
			_tween.tween_method(_set_fraction, segment.x, segment.y, fill)
		if i < _view.levels_gained():
			_tween.tween_callback(_level_up.bind(i, speed_scale))
			_tween.tween_interval(UiTokens.SUMMARY_LEVEL_HOLD * speed_scale)
	_tween.tween_callback(_on_done)


## Le remplissage va SUMMARY_FAST fois plus vite.
func accelerate() -> void:
	if _tween != null and _tween.is_valid():
		_tween.set_speed_scale(UiTokens.SUMMARY_FAST)


## Mène la ligne à son état final tout de suite (les vibrations restantes sont sautées).
func finish_now() -> void:
	_finishing = true
	var tween := _tween
	if tween != null and tween.is_valid() and tween.is_running():
		BattleWidget.complete_tween(tween)
	if _view != null:
		_apply_final()
	_finishing = false


func is_done() -> bool:
	return _done


func get_view() -> ExpSummaryRowView:
	return _view


func get_name_text() -> String:
	return _name.text


## Le niveau affiché : le dernier atteint (« Nv. 9 »), sinon celui de départ.
func get_level_text() -> String:
	return _new_level.text if _new_level.visible else _old_level.text


func get_start_level_text() -> String:
	return _old_level.text


func get_points_text() -> String:
	return _points.text if _points.visible else ""


func get_gain_text() -> String:
	return _gain.text


## Gains de statistiques affichés (vide tant qu'aucun niveau n'est passé).
func get_stats_text() -> String:
	return _stats.text.strip_edges() if _stats.visible and _stats.modulate.a > 0.0 else ""


func get_bar() -> ExpBar:
	return _bar


## La ligne est mise en valeur (liseré ACCENT : le Pokémon est monté de niveau).
func is_lit() -> bool:
	return theme_type_variation == &"SummaryRowLit"


func _show_segment(index: int, fraction: float) -> void:
	_segment = index
	_set_fraction(fraction)


func _set_fraction(fraction: float) -> void:
	_bar.set_fraction(fraction)
	var span: Vector3i = _view.points[_segment]
	_points.visible = span.z > 0
	if span.z <= 0:
		return
	var segment: Vector2 = _view.segments[_segment]
	var t := 1.0 if is_equal_approx(segment.x, segment.y) \
		else clampf((fraction - segment.x) / (segment.y - segment.x), 0.0, 1.0)
	_points.text = POINTS_FORMAT % [roundi(lerpf(span.x, span.y, t)), span.z]


## Passage au niveau [param index] + 1 (dans l'ordre des niveaux gagnés).
func _level_up(index: int, speed_scale: float) -> void:
	_set_level_state(index)
	# La barre pleine se vide et repart dans le nouveau niveau (« 0 / 141 »).
	_show_segment(index + 1, _view.segments[index + 1].x)
	if not _finishing:
		haptic_requested.emit(UiTokens.HAPTIC_LEVEL_UP_MS)
	if _finishing or speed_scale <= 0.0:
		return
	# Pulsation du niveau, léger rebond de la ligne, gains en fondu.
	var up := UiTokens.LEVEL_PULSE_UP * speed_scale
	var down := UiTokens.LEVEL_PULSE_DOWN * speed_scale
	_kill_effects()
	var pulse := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_new_level.pivot_offset = _new_level.size * 0.5
	_new_level.scale = Vector2.ONE
	pulse.tween_property(_new_level, ^"scale", Vector2.ONE * UiTokens.SUMMARY_LEVEL_PULSE_SCALE, up)
	pulse.tween_property(_new_level, ^"scale", Vector2.ONE, down)
	var bounce := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	pivot_offset = size * 0.5
	bounce.tween_property(self, ^"scale", Vector2.ONE * UiTokens.SUMMARY_ROW_BOUNCE, up)
	bounce.tween_property(self, ^"scale", Vector2.ONE, down)
	_stats.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(_stats, ^"modulate:a", 1.0, UiTokens.SUMMARY_STATS_FADE * speed_scale)
	_effects = [pulse, bounce, fade]


## État visible après le niveau gagné n° [param index] (0 = le premier).
func _set_level_state(index: int) -> void:
	_arrow.visible = true
	_new_level.visible = true
	_new_level.text = _view.level_texts[index]
	_stats.text = _view.stat_texts[index]
	_stats.modulate.a = 1.0
	theme_type_variation = &"SummaryRowLit"


func _apply_final() -> void:
	_kill_effects()
	var last := _view.segments.size() - 1
	if _view.levels_gained() > 0:
		_set_level_state(_view.levels_gained() - 1)
	_new_level.scale = Vector2.ONE
	scale = Vector2.ONE
	_show_segment(last, _view.segments[last].y)
	_on_done()


func _on_done() -> void:
	if _done:
		return
	_done = true
	_tween = null
	finished.emit()


func _kill_effects() -> void:
	for tween: Tween in _effects:
		if tween != null and tween.is_valid():
			tween.kill()
	_effects.clear()


func _kill() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _build() -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.GAP)
	add_child(row)

	_thumb = PanelContainer.new()
	_thumb.theme_type_variation = &"SummaryThumb"
	_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_thumb)
	_portrait = TextureRect.new()
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.custom_minimum_size = Vector2.ONE * UiTokens.SUMMARY_THUMB
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_thumb.add_child(_portrait)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_theme_constant_override(&"separation", 0)
	row.add_child(column)

	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override(&"separation", UiTokens.GAP)
	line.custom_minimum_size.y = UiTokens.SUMMARY_THUMB
	column.add_child(line)
	_name = _label(&"SummaryName", UiTokens.SUMMARY_NAME_WIDTH)
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.clip_text = true
	line.add_child(_name)

	var levels := HBoxContainer.new()
	levels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	levels.custom_minimum_size.x = UiTokens.SUMMARY_LEVEL_WIDTH
	levels.add_theme_constant_override(&"separation", UiTokens.GAP)
	line.add_child(levels)
	_old_level = _label(&"SummaryLevel", 0)
	levels.add_child(_old_level)
	_arrow = TextureRect.new()
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.texture = ARROW_ICON
	_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_arrow.custom_minimum_size = Vector2.ONE * UiTokens.SUMMARY_LEVEL_ARROW
	_arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_arrow.self_modulate = UiTokens.TEXT_MUTED
	levels.add_child(_arrow)
	_new_level = _label(&"SummaryLevelUp", 0)
	levels.add_child(_new_level)

	_bar = ExpBar.new()
	_bar.theme_type_variation = &"SummaryExpBar"
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(_bar)
	_bar.custom_minimum_size.y = UiTokens.SUMMARY_BAR_HEIGHT
	_points = _label(&"SummaryPoints", UiTokens.SUMMARY_POINTS_WIDTH)
	_points.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(_points)
	_gain = _label(&"SummaryGain", UiTokens.SUMMARY_GAIN_WIDTH)
	_gain.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(_gain)

	_stats = _label(&"SummaryStats", 0)
	_stats.visible = false
	column.add_child(_stats)


func _label(variation: StringName, width: int) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if width > 0:
		label.custom_minimum_size.x = width
	return label
