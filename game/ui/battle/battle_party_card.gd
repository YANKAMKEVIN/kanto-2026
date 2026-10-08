class_name BattlePartyCard
extends BagTile
## Un Pokémon dans le panneau ÉQUIPE du combat (BattlePartyPanel, jalon 7) : pastilles de type
## (icône blanche sur la couleur du type, l'une sur l'autre), nom, « Nv. », barre de PV et « 17 / 19 », puis une
## étiquette : « ACTIF » (le Pokémon en jeu), le statut en toutes lettres (« K.O. »). Un
## Pokémon qui ne peut pas être envoyé reste lisible avec **sa raison** (« Ne peut plus
## combattre »), atténué : jamais une carte grisée sans explication.
##
## Elle rapporte le toucher (tapped, hérité de BagTile) ; c'est le panneau qui sélectionne ou
## refuse. Sélectionnée : liseré ACCENT (PickerRowSelected).

## « ACTIF » : le Pokémon en jeu (texte d'interface).
const ACTIVE_TAG := "ACTIF"

## Durées multipliées (0 = instantané, pour les tests).
var speed_scale: float = 1.0

var _view: BattlePartyView
var _types: VBoxContainer
var _name: Label
var _level: Label
var _tag: Label
var _hp_bar: HpBar
var _hp_text: Label
var _reason: Label
var _dimmed: Array[Control] = []
var _shake_tween: Tween
var _shake_base: float = 0.0


func _init() -> void:
	super()
	normal_variation = &"PickerRow"
	selected_variation = &"PickerRowSelected"
	theme_type_variation = &"PickerRow"
	custom_minimum_size = Vector2(UiTokens.BATTLE_PARTY_CARD_WIDTH,
		UiTokens.BATTLE_PARTY_CARD_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()


## Pokémon affiché (null = rien).
func set_view(view: BattlePartyView) -> void:
	_view = view
	if view == null:
		return
	_name.text = view.display_name
	_level.text = "%s %d" % [BattleInfoCard.LEVEL_TAG, view.level]
	_hp_bar.set_hp(view.hp, view.max_hp)
	_hp_text.text = BattleInfoCard.HP_FORMAT % [view.hp, view.max_hp]
	if view.active:
		_tag.text = ACTIVE_TAG
		_tag.add_theme_color_override(&"font_color", UiTokens.ACCENT)
	else:
		_tag.text = view.status_text
		_tag.add_theme_color_override(&"font_color", StatusView.color(view.status_text))
	_tag.visible = not _tag.text.is_empty()
	# « ACTIF » dit déjà pourquoi on ne l'envoie pas : la raison reste pour le refus (pied).
	_reason.text = "" if view.can_send or view.active else view.reason
	_reason.visible = not _reason.text.is_empty()
	_rebuild_types(view)
	# Le Pokémon en jeu reste plein (il n'est pas « éteint ») ; un K.O. est atténué.
	var off := not view.can_send and not view.active
	normal_variation = &"PickerRowOff" if off else &"PickerRow"
	set_selected(is_selected())
	for control: Control in _dimmed:
		control.modulate.a = UiTokens.PICKER_UNUSABLE_ALPHA if off else 1.0


func get_view() -> BattlePartyView:
	return _view


func get_name_text() -> String:
	return _name.text


func get_level_text() -> String:
	return _level.text


func get_hp_text() -> String:
	return _hp_text.text


## « ACTIF », le statut (« K.O. »), ou vide.
func get_tag_text() -> String:
	return _tag.text if _tag.visible else ""


## Raison affichée (vide si le Pokémon peut être envoyé).
func get_reason_text() -> String:
	return _reason.text if _reason.visible else ""


## Nombre de pastilles de type affichées.
func get_type_count() -> int:
	return _types.get_child_count()


func get_hp_bar() -> HpBar:
	return _hp_bar


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


func _rebuild_types(view: BattlePartyView) -> void:
	for chip: Node in _types.get_children():
		_types.remove_child(chip)
		chip.free()
	for type_id: StringName in view.type_ids:
		_types.add_child(_type_chip(type_id))


## Pastille ronde à la couleur du type, icône blanche au centre (sans icône : la couleur seule,
## le nom du type reste dans la fiche).
func _type_chip(type_id: StringName) -> Control:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.custom_minimum_size = Vector2.ONE * UiTokens.BATTLE_PARTY_TYPE_CHIP
	var style := StyleBoxFlat.new()
	style.bg_color = UiTokens.TYPE_COLORS.get(type_id, UiTokens.TYPE_COLOR_UNKNOWN)
	style.set_corner_radius_all(roundi(UiTokens.BATTLE_PARTY_TYPE_CHIP * 0.5))
	chip.add_theme_stylebox_override(&"panel", style)
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = TypeBadge.ICONS.get(type_id, null)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * UiTokens.BATTLE_PARTY_TYPE_ICON
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.add_child(icon)
	return chip


func _build() -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.GAP)
	add_child(row)

	# Deux types : pastilles l'une sur l'autre (la largeur reste au nom et à la raison).
	_types = VBoxContainer.new()
	_types.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_types.add_theme_constant_override(&"separation",
		-roundi(UiTokens.BATTLE_PARTY_TYPE_CHIP * 0.15))
	_types.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_types)
	_dimmed.append(_types)

	var info := VBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override(&"separation", 2)
	row.add_child(info)

	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	info.add_child(name_row)
	_dimmed.append(name_row)
	_name = _label(&"PickerName")
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.clip_text = true
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_name)
	_level = _label(&"PickerMeta")
	_level.size_flags_vertical = Control.SIZE_SHRINK_END
	name_row.add_child(_level)

	var hp_row := HBoxContainer.new()
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	info.add_child(hp_row)
	_dimmed.append(hp_row)
	_hp_bar = PartyTargetCard.HP_BAR_SCENE.instantiate() as HpBar
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp_row.add_child(_hp_bar)
	_hp_text = _label(&"PickerMeta")
	hp_row.add_child(_hp_text)

	var tag_row := HBoxContainer.new()
	tag_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	info.add_child(tag_row)
	_tag = _label(&"PickerMeta")
	_tag.visible = false
	tag_row.add_child(_tag)
	_reason = _label(&"PickerMeta")
	_reason.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_reason.clip_text = true
	_reason.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reason.visible = false
	tag_row.add_child(_reason)


func _label(variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
