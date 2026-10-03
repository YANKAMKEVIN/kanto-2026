class_name PartyTargetCard
extends BagTile
## Un Pokémon dans le choix du Pokémon (PartyPicker, dossier 08 §3) : portrait en pixel art, nom,
## Nv., barre de PV et « 33 / 51 », statut en texte (« K.O. ») et, si l'objet ne peut pas servir
## sur lui, **la raison** en toutes lettres (« PV déjà au maximum »). Jamais un bouton grisé sans
## explication : un membre inutilisable reste lisible, atténué, sans flèche.
##
## Un membre utilisable porte une flèche ; mis en avant (UTILISER À NOUVEAU), il a le liseré
## ACCENT. Elle rapporte le toucher (tapped, hérité de BagTile) ; c'est le PartyPicker qui
## décide de n'émettre un choix que pour une cible utilisable.

## Sprite de face d'une espèce (%s = identifiant) ; provisoire jusqu'à la DA.
const SPRITE_PATH := "res://assets/sprites/pokemon/placeholder/%s_front.png"
const CHEVRON_ICON: Texture2D = preload("res://assets/ui/icons/menu/chevron.svg")
const HP_BAR_SCENE: PackedScene = preload("res://game/ui/battle/hp_bar.tscn")

var _target: PartyTargetView
var _thumb_box: Panel
var _thumb: TextureRect
var _name: Label
var _level: Label
var _status: Label
var _hp_bar: HpBar
var _hp_text: Label
var _reason: Label
var _chevron: TextureRect
var _dimmed: Array[Control] = []


func _init() -> void:
	super()
	normal_variation = &"PickerRow"
	selected_variation = &"PickerRowSelected"
	theme_type_variation = &"PickerRow"
	custom_minimum_size = Vector2(UiTokens.PICKER_COLUMN_WIDTH, UiTokens.PICKER_ROW_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()


## Cible affichée (null = rien).
func set_target(target: PartyTargetView) -> void:
	_target = target
	if target == null or target.member == null:
		return
	var member := target.member
	_name.text = member.display_name
	_level.text = "%s %d" % [BattleInfoCard.LEVEL_TAG, member.level]
	_status.text = member.status_text
	_status.visible = not member.status_text.is_empty()
	_hp_bar.set_hp(member.hp, member.max_hp)
	_hp_text.text = BattleInfoCard.HP_FORMAT % [member.hp, member.max_hp]
	var path := SPRITE_PATH % member.species_id
	_thumb.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_reason.text = "" if target.usable else target.reason
	_reason.visible = not target.usable and not target.reason.is_empty()
	_chevron.visible = target.usable
	theme_type_variation = &"PickerRow" if target.usable else &"PickerRowOff"
	normal_variation = theme_type_variation
	for control: Control in _dimmed:
		control.modulate.a = 1.0 if target.usable else UiTokens.PICKER_UNUSABLE_ALPHA


func get_target() -> PartyTargetView:
	return _target


func get_name_text() -> String:
	return _name.text


func get_level_text() -> String:
	return _level.text


func get_hp_text() -> String:
	return _hp_text.text


func get_status_text() -> String:
	return _status.text if _status.visible else ""


## Raison affichée (vide si le membre est utilisable).
func get_reason_text() -> String:
	return _reason.text if _reason.visible else ""


## La flèche des cibles utilisables est affichée.
func is_chevron_shown() -> bool:
	return _chevron.visible


func get_hp_bar() -> HpBar:
	return _hp_bar


func get_all_text() -> String:
	return "%s %s %s %s %s" % [_name.text, _level.text, get_status_text(), _hp_text.text,
		get_reason_text()]


func _build() -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.GAP)
	add_child(row)

	_thumb_box = Panel.new()
	_thumb_box.theme_type_variation = &"MenuLeadThumb"
	_thumb_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thumb_box.custom_minimum_size = Vector2.ONE * UiTokens.PICKER_THUMB
	_thumb_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_thumb_box)
	_dimmed.append(_thumb_box)
	_thumb = TextureRect.new()
	_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thumb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var side := UiTokens.TEAM_SPRITE_SOURCE * 2
	_thumb.custom_minimum_size = Vector2.ONE * side
	_thumb.size = Vector2.ONE * side
	_thumb.position = (Vector2.ONE * UiTokens.PICKER_THUMB - _thumb.size) * 0.5
	_thumb_box.add_child(_thumb)

	var info := VBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override(&"separation", 0)
	row.add_child(info)

	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	info.add_child(name_row)
	_dimmed.append(name_row)
	_name = _label(&"PickerName")
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_name)
	_level = _label(&"PickerMeta")
	_level.size_flags_vertical = Control.SIZE_SHRINK_END
	name_row.add_child(_level)
	_status = _label(&"PickerMeta")
	_status.add_theme_color_override(&"font_color", UiTokens.HP_LOW)
	_status.size_flags_vertical = Control.SIZE_SHRINK_END
	name_row.add_child(_status)

	var hp_row := HBoxContainer.new()
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	info.add_child(hp_row)
	_dimmed.append(hp_row)
	_hp_bar = HP_BAR_SCENE.instantiate() as HpBar
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(_hp_bar)
	_hp_text = _label(&"PickerMeta")
	hp_row.add_child(_hp_text)

	_reason = _label(&"PickerReason")
	_reason.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_reason.clip_text = true
	_reason.visible = false
	info.add_child(_reason)

	_chevron = TextureRect.new()
	_chevron.texture = CHEVRON_ICON
	_chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chevron.custom_minimum_size = Vector2.ONE * UiTokens.PICKER_CHEVRON
	_chevron.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chevron.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_chevron)


func _label(variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
