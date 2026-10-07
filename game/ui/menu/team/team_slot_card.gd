class_name TeamSlotCard
extends Control
## Un emplacement de la liste de l'Équipe (dossier 08 §2) : artwork officiel dans un rond (MM.1,
## [MenuArt]), nom, ♂/♀, Nv., barre de PV et « 39 / 39 », statut **en texte** (« K.O. »),
## étoile si favori, « › ». Un emplacement vide reste neutre : aucun texte, aucune action (pas de
## « Ajouter un Pokémon » : dossier 08 §2, aucun stockage dans le menu).
##
## Elle ne décide rien : elle rapporte les gestes à [TeamScreen] (souris émulée depuis le
## toucher, comme [MoveCard]).
## - Relâché avant LONG_PRESS, doigt resté en place : [signal tapped].
## - Tenu LONG_PRESS : [signal drag_started] ; ensuite [signal drag_moved] à chaque mouvement
##   (position globale) puis [signal drag_released] au relâchement, où que soit le doigt.
## - Le doigt qui bouge de plus de TEAM_DRAG_SLOP avant LONG_PRESS annule l'appui
##   ([signal press_cancelled]).

signal tapped(index: int)
signal drag_started(index: int)
signal drag_moved(index: int, global_position: Vector2)
signal drag_released(index: int, global_position: Vector2)
signal press_cancelled(index: int)

enum Look { NORMAL, SELECTED, SOURCE, TARGET }

const CHEVRON_ICON: Texture2D = preload("res://assets/ui/icons/menu/chevron.svg")
const STAR_ICON: Texture2D = preload("res://assets/ui/icons/menu/star_filled.svg")
const BALL_ICON: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")
const HP_BAR_SCENE: PackedScene = preload("res://game/ui/battle/hp_bar.tscn")
const LOOKS: Dictionary[Look, StringName] = {
	Look.NORMAL: &"TeamSlot",
	Look.SELECTED: &"TeamSlotSelected",
	Look.SOURCE: &"TeamSlotSource",
	Look.TARGET: &"TeamSlotTarget",
}
## Opacité de la pastille vide (anneau de Poké Ball, sans texte).
const EMPTY_BALL_ALPHA := 0.16

## Place dans l'équipe ; -1 = emplacement vide. Pour un emplacement vide : [member slot].
var party_index: int = -1
var slot: int = 0

var _view: TeamMemberView
var _look: Look = Look.NORMAL
var _held: bool = false
var _dragging: bool = false
var _held_time: float = 0.0
var _press_position: Vector2 = Vector2.ZERO
var _bg: Panel
var _content: Control
var _thumb: TextureRect
var _name: Label
var _gender: TextureRect
var _star: TextureRect
var _status: Label
var _level: Label
var _hp_bar: HpBar
var _hp_text: Label
var _ball: TextureRect


func _init() -> void:
	custom_minimum_size = Vector2(UiTokens.TOUCH_MIN, UiTokens.TEAM_SLOT_HEIGHT)
	_build()
	resized.connect(_update_pivot)
	set_process(false)


func _process(delta: float) -> void:
	_held_time += delta
	if not _dragging and _held_time >= UiTokens.LONG_PRESS:
		_dragging = true
		Haptics.vibrate(UiTokens.HAPTIC_TEAM_DRAG_MS)
		drag_started.emit(party_index)


func _gui_input(event: InputEvent) -> void:
	if party_index < 0:
		return
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if button.pressed:
			if not _held:
				_held = true
				_dragging = false
				_held_time = 0.0
				_press_position = button.position
				set_process(true)
		elif _held:
			_release(button.position)
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _held:
		accept_event()
		if _dragging:
			drag_moved.emit(party_index, _to_global(motion.position))
		elif motion.position.distance_to(_press_position) > UiTokens.TEAM_DRAG_SLOP:
			_held = false
			set_process(false)
			press_cancelled.emit(party_index)


## Membre affiché ; null = emplacement vide (neutre, inerte).
func set_member(view: TeamMemberView) -> void:
	_view = view
	_held = false
	_dragging = false
	set_process(false)
	party_index = -1 if view == null else view.party_index
	_content.visible = view != null
	_ball.visible = view == null
	if view != null:
		_name.text = view.display_name
		_gender.texture = BattleInfoCard.GENDER_ICONS.get(view.gender, null)
		_gender.modulate = BattleInfoCard.GENDER_COLORS.get(view.gender, UiTokens.TEXT)
		_gender.visible = _gender.texture != null
		_star.visible = view.favorite
		_status.text = view.status_text
		_status.add_theme_color_override(&"font_color", StatusView.color(view.status_text))
		_status.visible = not view.status_text.is_empty()
		_level.text = "%s %d" % [BattleInfoCard.LEVEL_TAG, view.level]
		_hp_bar.set_hp(view.hp, view.max_hp)
		_hp_text.text = BattleInfoCard.HP_FORMAT % [view.hp, view.max_hp]
		_thumb.texture = MenuArt.pokemon_thumbnail(view.dex_number)
	set_look(Look.NORMAL)


func get_member() -> TeamMemberView:
	return _view


func is_empty() -> bool:
	return _view == null


## Aspect : normal, sélectionné (liseré ACCENT), origine d'un déplacement, cible de dépôt.
func set_look(look: Look) -> void:
	_look = look
	_bg.theme_type_variation = &"TeamSlotEmpty" if _view == null else LOOKS[look]
	_content.modulate.a = UiTokens.TEAM_DRAG_SOURCE_ALPHA if (look == Look.SOURCE
		and _dragging) else 1.0


func get_look() -> Look:
	return _look


## Le glissement est en cours (appui long passé, doigt encore posé).
func is_dragging() -> bool:
	return _dragging


func is_held() -> bool:
	return _held


func get_name_text() -> String:
	return _name.text


func get_level_text() -> String:
	return _level.text


func get_hp_text() -> String:
	return _hp_text.text


func get_status_text() -> String:
	return _status.text if _status.visible else ""


func is_favorite_shown() -> bool:
	return _star.visible


func get_thumb() -> TextureRect:
	return _thumb


func get_hp_bar() -> HpBar:
	return _hp_bar


## Texte de tout ce que l'emplacement affiche (vide : "").
func get_all_text() -> String:
	if _view == null:
		return ""
	return "%s %s %s %s" % [_name.text, get_status_text(), _level.text, _hp_text.text]


func _release(local_position: Vector2) -> void:
	var was_dragging := _dragging
	_held = false
	_dragging = false
	set_process(false)
	if was_dragging:
		drag_released.emit(party_index, _to_global(local_position))
	elif Rect2(Vector2.ZERO, size).has_point(local_position):
		tapped.emit(party_index)
	else:
		press_cancelled.emit(party_index)


func _to_global(local_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * local_position


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _build() -> void:
	_bg = Panel.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_ball = TextureRect.new()
	_ball.texture = BALL_ICON
	_ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ball.custom_minimum_size = Vector2.ONE * UiTokens.TEAM_SLOT_THUMB * 0.5
	_ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ball.modulate.a = EMPTY_BALL_ALPHA
	_ball.visible = false
	center.add_child(_ball)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, UiTokens.TEAM_SLOT_PAD / 2)
	add_child(margin)
	_content = margin
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.GAP)
	margin.add_child(row)

	var thumb_box := Panel.new()
	thumb_box.theme_type_variation = &"MenuRoundThumb"
	thumb_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb_box.custom_minimum_size = Vector2.ONE * UiTokens.TEAM_SLOT_THUMB
	thumb_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(thumb_box)
	_thumb = TextureRect.new()
	_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var side := UiTokens.TEAM_SLOT_THUMB * UiTokens.MENU_ROUND_THUMB_ART
	_thumb.size = Vector2.ONE * side
	_thumb.position = (Vector2.ONE * UiTokens.TEAM_SLOT_THUMB - _thumb.size) * 0.5
	thumb_box.add_child(_thumb)

	var info := VBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override(&"separation", 0)
	row.add_child(info)

	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override(&"separation", UiTokens.GAP / 2)
	info.add_child(name_row)
	_name = _label(&"TeamSlotName")
	name_row.add_child(_name)
	_gender = _icon(UiTokens.GENDER_ICON)
	name_row.add_child(_gender)
	_star = _icon(UiTokens.TEAM_SLOT_STAR)
	_star.texture = STAR_ICON
	_star.modulate = UiTokens.ACCENT
	name_row.add_child(_star)

	var level_row := HBoxContainer.new()
	level_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	info.add_child(level_row)
	_level = _label(&"TeamSlotMeta")
	level_row.add_child(_level)
	_status = _label(&"TeamSlotMeta")
	_status.add_theme_color_override(&"font_color", UiTokens.HP_LOW)
	level_row.add_child(_status)

	var hp_row := HBoxContainer.new()
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	info.add_child(hp_row)
	_hp_bar = HP_BAR_SCENE.instantiate() as HpBar
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(_hp_bar)
	_hp_text = _label(&"TeamSlotMeta")
	hp_row.add_child(_hp_text)
	var chevron := _icon(UiTokens.MENU_STATUS_ICON)
	chevron.texture = CHEVRON_ICON
	row.add_child(chevron)
	margin.visible = false
	_bg.theme_type_variation = &"TeamSlotEmpty"


func _label(variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _icon(side: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2.ONE * side
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon
