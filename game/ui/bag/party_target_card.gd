class_name PartyTargetCard
extends BagTile
## Un Pokémon dans le choix du Pokémon (PartyPicker, dossier 08 §3) : artwork officiel dans un rond
## (MM.1, [MenuArt]), nom,
## Nv., barre de PV et « 33 / 51 », statut en texte (« K.O. ») et, si l'objet ne peut pas servir
## sur lui, **la raison** en toutes lettres (« PV déjà au maximum »). Jamais un bouton grisé sans
## explication : un membre inutilisable reste lisible, atténué, sans flèche.
##
## Un membre utilisable porte une flèche ; mis en avant (UTILISER À NOUVEAU), il a le liseré
## ACCENT. Elle rapporte le toucher (tapped, hérité de BagTile) ; c'est le PartyPicker qui
## décide de n'émettre un choix que pour une cible utilisable.

const CHEVRON_ICON: Texture2D = preload("res://assets/ui/icons/menu/chevron.svg")
const HP_BAR_SCENE: PackedScene = preload("res://game/ui/battle/hp_bar.tscn")

## Le soin de la carte est fini (barre arrivée, éclat dissipé).
signal heal_finished

## Durées multipliées (0 = instantané, pour les tests).
var speed_scale: float = 1.0

var _target: PartyTargetView
var _flash: Panel
var _shake_tween: Tween
var _shake_base: float = 0.0
var _heal_tween: Tween
var _healing: bool = false
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
## Variations de la ligne (utilisable / non) ; le Sac du menu prend ses cartes de verre.
var _row_variation: StringName = &"PickerRow"
var _row_off_variation: StringName = &"PickerRowOff"


func _init() -> void:
	super()
	normal_variation = &"PickerRow"
	selected_variation = &"PickerRowSelected"
	theme_type_variation = &"PickerRow"
	custom_minimum_size = Vector2(UiTokens.PICKER_COLUMN_WIDTH, UiTokens.PICKER_ROW_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()


## Ligne compacte du panneau du Sac (MM.1) : verre, TOUCH_MIN de haut, largeur du panneau.
func use_compact() -> void:
	_row_variation = &"MenuPickerRow"
	_row_off_variation = &"MenuPickerRowOff"
	normal_variation = _row_variation
	selected_variation = &"MenuPickerRowSelected"
	theme_type_variation = _row_variation
	custom_minimum_size = Vector2(0.0, UiTokens.PICKER_COMPACT_ROW)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_thumb_box.custom_minimum_size = Vector2.ONE * UiTokens.PICKER_COMPACT_THUMB
	_fit_thumb(UiTokens.PICKER_COMPACT_THUMB)
	if _target != null:
		set_target(_target)


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
	_thumb.texture = MenuArt.pokemon_thumbnail(member.dex_number)
	_reason.text = "" if target.usable else target.reason
	_reason.visible = not target.usable and not target.reason.is_empty()
	_chevron.visible = target.usable
	theme_type_variation = _row_variation if target.usable else _row_off_variation
	normal_variation = theme_type_variation
	for control: Control in _dimmed:
		control.modulate.a = 1.0 if target.usable else UiTokens.PICKER_UNUSABLE_ALPHA


## Refus : la carte tremble brièvement (PICKER_SHAKE_TIME), puis revient à sa place.
func shake() -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
		position.x = _shake_base
	else:
		_shake_base = position.x
	var time := UiTokens.PICKER_SHAKE_TIME * speed_scale
	if time <= 0.0 or not is_inside_tree():
		_shake_tween = null
		return
	var step := time / float(UiTokens.PICKER_SHAKE_STEPS * 2 + 1)
	_shake_tween = create_tween().set_trans(Tween.TRANS_SINE)
	for i: int in UiTokens.PICKER_SHAKE_STEPS:
		var dir := 1.0 if i % 2 == 0 else -1.0
		var decay := 1.0 - float(i) / float(UiTokens.PICKER_SHAKE_STEPS)
		_shake_tween.tween_property(self, ^"position:x",
			_shake_base + dir * UiTokens.PICKER_SHAKE_AMPLITUDE * decay, step)
		_shake_tween.tween_property(self, ^"position:x", _shake_base, step)
	_shake_tween.tween_callback(func() -> void: position.x = _shake_base)


## La carte tremble en ce moment.
func is_shaking() -> bool:
	return _shake_tween != null and _shake_tween.is_valid() and _shake_tween.is_running()


## Soin : la barre remonte de [param from_hp] à la valeur de la cible (courbe et durée de la barre
## de combat), le chiffre compte, la carte a un éclat vert ; [signal heal_finished] à la fin.
## [method set_target] doit avoir été appelé avec la vue **après** soin.
func play_heal(from_hp: int) -> void:
	if _target == null or _target.member == null:
		heal_finished.emit()
		return
	var member := _target.member
	_healing = true
	_hp_bar.speed_scale = speed_scale
	_hp_bar.set_hp(from_hp, member.max_hp)
	_hp_text.text = BattleInfoCard.HP_FORMAT % [from_hp, member.max_hp]
	_hp_bar.animate_hp(member.hp, member.max_hp)
	var time := (UiTokens.HP_TWEEN + UiTokens.PICKER_HEAL_FLASH_FADE) * speed_scale
	if _heal_tween != null:
		_heal_tween.kill()
	if time <= 0.0 or not is_inside_tree():
		_end_heal()
		return
	_flash.modulate.a = 1.0
	_heal_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_heal_tween.tween_property(_flash, ^"modulate:a", 0.0, time)
	_heal_tween.tween_callback(_end_heal)


func is_healing() -> bool:
	return _healing


func get_flash() -> Panel:
	return _flash


func _end_heal() -> void:
	_healing = false
	_flash.modulate.a = 0.0
	if _target != null and _target.member != null:
		_hp_text.text = BattleInfoCard.HP_FORMAT % [_target.member.hp, _target.member.max_hp]
	heal_finished.emit()


func _on_hp_display(hp: int, max_hp: int) -> void:
	if _healing:
		_hp_text.text = BattleInfoCard.HP_FORMAT % [hp, max_hp]


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


## Image du Pokémon (artwork officiel), null si inconnue.
func get_thumb_texture() -> Texture2D:
	return _thumb.texture


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
	_thumb_box.theme_type_variation = &"MenuRoundThumb"
	_thumb_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thumb_box.custom_minimum_size = Vector2.ONE * UiTokens.PICKER_THUMB
	_thumb_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_thumb_box)
	_dimmed.append(_thumb_box)
	_thumb = TextureRect.new()
	_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_thumb_box.add_child(_thumb)
	_fit_thumb(UiTokens.PICKER_THUMB)

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

	_flash = Panel.new()
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow := StyleBoxFlat.new()
	glow.bg_color = UiTokens.PICKER_HEAL_FLASH_COLOR
	glow.set_corner_radius_all(int(UiTokens.RADIUS))
	_flash.add_theme_stylebox_override(&"panel", glow)
	_flash.modulate.a = 0.0
	add_child(_flash)
	_hp_bar.display_changed.connect(_on_hp_display)


## L'artwork occupe MENU_ROUND_THUMB_ART du rond de [param box] px, centré.
func _fit_thumb(box: int) -> void:
	var side := box * UiTokens.MENU_ROUND_THUMB_ART
	_thumb.size = Vector2.ONE * side
	_thumb.position = (Vector2.ONE * box - _thumb.size) * 0.5


func _label(variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
