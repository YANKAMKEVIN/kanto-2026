class_name LeadPokemonCard
extends Button
## Pokémon de tête, en bas de la carte du Dresseur (dossier 08 §1) : artwork officiel dans un rond
## (MM.1, [MenuArt]),
## nom, sexe, « Nv. 14 », barre de PV et « 39 / 39 ». Un toucher l'ouvre ([signal chosen]) :
## sa fiche est l'écran Équipe sur ce Pokémon (6A). Le statut K.O. s'écrit en toutes lettres.
## Toute la carte est la zone tactile (hauteur MENU_LEAD_HEIGHT ≥ TOUCH_MIN).

## La carte est touchée.
signal chosen

const HP_BAR_SCENE: PackedScene = preload("res://game/ui/battle/hp_bar.tscn")
const CHEVRON: Texture2D = preload("res://assets/ui/icons/menu/chevron.svg")

var _tween: Tween

var _thumb: TextureRect
var _name: Label
var _gender: TextureRect
var _status: Label
var _level: Label
var _hp_bar: HpBar
var _hp_text: Label


func _init() -> void:
	theme_type_variation = &"MenuLeadCard"
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(UiTokens.TOUCH_MIN, UiTokens.MENU_LEAD_HEIGHT)
	_build()
	pressed.connect(_on_pressed)
	button_down.connect(_press_feedback.bind(true))
	button_up.connect(_press_feedback.bind(false))
	resized.connect(_update_pivot)


## Remplit la carte avec [param view] (une vue invalide est refusée : la carte reste telle).
## À appeler une fois la carte dans l'arbre (la barre de PV n'existe qu'alors).
func setup(view: TeamMemberView) -> void:
	if view == null or not view.is_valid():
		push_error("LeadPokemonCard : vue invalide")
		return
	_name.text = view.display_name
	_gender.texture = BattleInfoCard.GENDER_ICONS.get(view.gender, null)
	_gender.modulate = BattleInfoCard.GENDER_COLORS.get(view.gender, UiTokens.TEXT)
	_gender.visible = _gender.texture != null
	_status.text = view.status_text
	_status.visible = not view.status_text.is_empty()
	_level.text = "%s %d" % [BattleInfoCard.LEVEL_TAG, view.level]
	_hp_bar.set_hp(view.hp, view.max_hp)
	_hp_text.text = BattleInfoCard.HP_FORMAT % [view.hp, view.max_hp]
	_thumb.texture = MenuArt.pokemon_thumbnail(view.dex_number)


func get_name_text() -> String:
	return _name.text


func get_level_text() -> String:
	return _level.text


func get_hp_text() -> String:
	return _hp_text.text


func get_status_text() -> String:
	return _status.text


func get_hp_bar() -> HpBar:
	return _hp_bar


func get_thumb() -> TextureRect:
	return _thumb


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_right"]:
		margin.add_theme_constant_override(side, UiTokens.GAP)
	for side: StringName in [&"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, UiTokens.GAP / 2)
	add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.GAP)
	margin.add_child(row)

	var thumb_box := Panel.new()
	thumb_box.theme_type_variation = &"MenuRoundThumb"
	thumb_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb_box.custom_minimum_size = Vector2.ONE * UiTokens.MENU_LEAD_THUMB
	thumb_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(thumb_box)
	_thumb = TextureRect.new()
	_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_thumb.set_anchors_preset(Control.PRESET_FULL_RECT)
	var inset := UiTokens.MENU_LEAD_THUMB * (1.0 - UiTokens.MENU_ROUND_THUMB_ART) * 0.5
	_thumb.offset_left = inset
	_thumb.offset_top = inset
	_thumb.offset_right = -inset
	_thumb.offset_bottom = -inset
	thumb_box.add_child(_thumb)

	var info := VBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override(&"separation", 2)
	row.add_child(info)

	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override(&"separation", UiTokens.GAP / 2)
	info.add_child(name_row)
	_name = Label.new()
	_name.theme_type_variation = &"MenuLeadName"
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(_name)
	_gender = TextureRect.new()
	_gender.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gender.custom_minimum_size = Vector2.ONE * UiTokens.GENDER_ICON
	_gender.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gender.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_gender.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_row.add_child(_gender)
	_status = Label.new()
	_status.theme_type_variation = &"MenuLeadLevel"
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.add_theme_color_override(&"font_color", UiTokens.HP_LOW)
	name_row.add_child(_status)

	_level = Label.new()
	_level.theme_type_variation = &"MenuLeadLevel"
	_level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(_level)

	var hp_row := HBoxContainer.new()
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	info.add_child(hp_row)
	_hp_bar = HP_BAR_SCENE.instantiate() as HpBar
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(_hp_bar)
	_hp_text = Label.new()
	_hp_text.theme_type_variation = &"MenuLeadHp"
	_hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_child(_hp_text)

	var chevron := TextureRect.new()
	chevron.texture = CHEVRON
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chevron.custom_minimum_size = Vector2.ONE * UiTokens.MENU_CARD_CHEVRON_ICON
	chevron.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chevron.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(chevron)


func _on_pressed() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	chosen.emit()


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _press_feedback(down: bool) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target := Vector2.ONE * (UiTokens.PRESSED_SCALE if down else 1.0)
	_tween.tween_property(self, ^"scale", target, UiTokens.ANIM_MICRO)
