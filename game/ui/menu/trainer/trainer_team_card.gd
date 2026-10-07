class_name TrainerTeamCard
extends PanelContainer
## Un Pokémon de l'équipe actuelle sur l'écran Dresseur (MM.2, maquette) : artwork officiel
## ([MenuArt]), nom, sexe, « Nv. 14 », barre de PV et « 39 / 39 ». Le statut K.O. s'écrit en
## toutes lettres. Pas de toucher (l'écran Équipe a sa carte au tableau de bord).

const HP_BAR_SCENE: PackedScene = preload("res://game/ui/battle/hp_bar.tscn")

var _view: TeamMemberView
var _art: TextureRect
var _name: Label
var _gender: TextureRect
var _level: Label
var _hp_bar: HpBar
var _hp_text: Label


func _init() -> void:
	theme_type_variation = &"TrainerTeamCard"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", 2)
	add_child(box)
	_art = TextureRect.new()
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.custom_minimum_size.y = UiTokens.TRAINER_TEAM_ART
	_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_art)
	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override(&"separation", 4)
	box.add_child(name_row)
	_name = Label.new()
	_name.theme_type_variation = &"TrainerTeamName"
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_name)
	_gender = TextureRect.new()
	_gender.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gender.custom_minimum_size = Vector2.ONE * UiTokens.GENDER_ICON
	_gender.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gender.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_gender.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_row.add_child(_gender)
	# « Nv. 14 » à gauche, « 39 / 39 » à droite, puis la barre sur toute la largeur.
	var info_row := HBoxContainer.new()
	info_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(info_row)
	_level = Label.new()
	_level.theme_type_variation = &"TrainerTeamLevel"
	_level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(_level)
	_hp_text = Label.new()
	_hp_text.theme_type_variation = &"TrainerTeamLevel"
	_hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_row.add_child(_hp_text)
	_hp_bar = HP_BAR_SCENE.instantiate() as HpBar
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_hp_bar)


## Remplit la carte avec [param view] (la barre de PV est posée une fois dans l'arbre).
func setup(view: TeamMemberView) -> void:
	_view = view
	# Grand artwork (la carte l'affiche à plus de 128 px : la vignette de l'atlas serait floue).
	_art.texture = MenuArt.pokemon_portrait(view.dex_number)
	_name.text = view.display_name
	_gender.texture = BattleInfoCard.GENDER_ICONS.get(view.gender, null)
	_gender.modulate = BattleInfoCard.GENDER_COLORS.get(view.gender, UiTokens.TEXT)
	_gender.visible = _gender.texture != null
	_level.text = view.status_text if not view.status_text.is_empty() \
		else "%s %d" % [BattleInfoCard.LEVEL_TAG, view.level]
	_level.add_theme_color_override(&"font_color",
		UiTokens.HP_LOW if not view.status_text.is_empty() else UiTokens.TEXT_MUTED)
	_hp_text.text = BattleInfoCard.HP_FORMAT % [view.hp, view.max_hp]
	if _hp_bar.is_node_ready():
		_fill_bar()
	elif not _hp_bar.ready.is_connected(_fill_bar):
		_hp_bar.ready.connect(_fill_bar, CONNECT_ONE_SHOT)


func get_hp_bar() -> HpBar:
	return _hp_bar


func get_view() -> TeamMemberView:
	return _view


func get_art() -> TextureRect:
	return _art


## Textes affichés (nom, niveau ou statut, PV).
func get_texts() -> PackedStringArray:
	return PackedStringArray([_name.text, _level.text, _hp_text.text])


## Barre de PV sans son libellé « PV » (la carte est étroite ; « 39 / 39 » suit).
func _fill_bar() -> void:
	_hp_bar.get_label().visible = false
	if _view != null:
		_hp_bar.set_hp(_view.hp, _view.max_hp)
