class_name PokemonShowcase
extends VBoxContainer
## La vedette de l'Équipe (dossier 08 §2 ; maquette menu-equipe-v1.jpg, MM.1) : **artwork officiel**
## du Pokémon sélectionné ([MenuArt], resserré sur son cadre utile, filtre linéaire) posé sur un
## halo et une ombre au sol, avec une respiration légère (décalage vertical), puis l'en-tête de
## fiche : nom, ♂/♀, « Favori » (étoile **et** texte), Nv., statut en texte, type(s), PV et XP
## (« 320 / 560 XP », « 240 XP avant le niveau suivant »).
## Un texte vide dans la fiche = un élément absent (niveau 100 : pas de texte d'XP).
## Numéro inconnu (0) : pas d'image, jamais une autre espèce.

const STAR_ICON: Texture2D = preload("res://assets/ui/icons/menu/star_filled.svg")
const FAVORITE_TEXT := "Favori"
const HP_BAR_SCENE: PackedScene = preload("res://game/ui/battle/hp_bar.tscn")
const BADGE_SCENE: PackedScene = preload("res://game/ui/components/type_badge.tscn")
const XP_TAG := "XP"

## Durées multipliées (0 = instantané, pas de respiration : tests).
var speed_scale: float = 1.0

## Côté fixe de l'image (Stockage) ; 0 : toute la place libre, au plus TEAM_ART_MAX (Équipe).
var _art_size: int = 0
var _with_xp: bool = true
var _shown_number: int = -1
var _breath_offset: float = 0.0

var _sheet: PokemonSheetView
var _breath: Tween
var _fade: Tween
var _sprite_box: Control
var _shadow: Control
var _halo: TextureRect
var _sprite: TextureRect
var _name: Label
var _gender: TextureRect
var _favorite: PanelContainer
var _favorite_label: Label
var _level: Label
var _status: Label
var _types: HBoxContainer
var _hp_bar: HpBar
var _hp_text: Label
var _xp_row: HBoxContainer
var _xp_bar: ExpBar
var _xp_text: Label
var _xp_remaining: Label


## [param art_size] : côté fixe de l'image (0 : toute la place, Équipe) ; [param with_xp] faux :
## ni barre ni texte d'XP, ni pilule « Favori » (écran Stockage, où la hauteur manque).
func _init(art_size: int = 0, with_xp: bool = true) -> void:
	_art_size = art_size
	_with_xp = with_xp
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", UiTokens.TEAM_HEADER_GAP)
	_build()


## Affiche [param sheet] ; [param animate] : fondu court (changement de Pokémon).
func show_sheet(sheet: PokemonSheetView, animate: bool) -> void:
	_sheet = sheet
	var member := sheet.member
	if member.dex_number != _shown_number:
		_shown_number = member.dex_number
		_sprite.texture = MenuArt.pokemon_portrait(member.dex_number)
		_layout_art()
	_name.text = member.display_name
	_gender.texture = BattleInfoCard.GENDER_ICONS.get(member.gender, null)
	_gender.modulate = BattleInfoCard.GENDER_COLORS.get(member.gender, UiTokens.TEXT)
	_gender.visible = _gender.texture != null
	_favorite.visible = member.favorite and _with_xp
	_level.text = "%s %d" % [BattleInfoCard.LEVEL_TAG, member.level]
	_status.text = member.status_text
	_status.visible = not member.status_text.is_empty()
	for old: Node in _types.get_children():
		_types.remove_child(old)
		old.queue_free()
	for i: int in sheet.type_ids.size():
		var badge := BADGE_SCENE.instantiate() as TypeBadge
		_types.add_child(badge)
		badge.set_type(sheet.type_ids[i], sheet.type_names[i])
	_hp_bar.set_hp(member.hp, member.max_hp)
	_hp_text.text = BattleInfoCard.HP_FORMAT % [member.hp, member.max_hp]
	_xp_bar.set_fraction(sheet.exp_fraction)
	_xp_text.text = sheet.exp_text
	_xp_text.visible = not sheet.exp_text.is_empty()
	_xp_remaining.text = sheet.exp_remaining_text
	_xp_remaining.visible = not sheet.exp_remaining_text.is_empty() and _with_xp
	_xp_row.visible = _with_xp
	if animate:
		_play_switch()
	_restart_breath()


func get_sheet() -> PokemonSheetView:
	return _sheet


func get_sprite() -> TextureRect:
	return _sprite


## Taille réelle de l'image à l'écran.
func get_sprite_shown_size() -> Vector2:
	return _sprite.size * _sprite.scale


func get_name_text() -> String:
	return _name.text


func get_level_text() -> String:
	return _level.text


func get_status_text() -> String:
	return _status.text if _status.visible else ""


func get_favorite_text() -> String:
	return _favorite_label.text if _favorite.visible else ""


func get_favorite_pill() -> PanelContainer:
	return _favorite


func get_hp_text() -> String:
	return _hp_text.text


func get_xp_text() -> String:
	return _xp_text.text if _xp_text.visible else ""


func get_xp_remaining_text() -> String:
	return _xp_remaining.text if _xp_remaining.visible else ""


func get_types() -> HBoxContainer:
	return _types


## Décalage vertical actuel de la respiration (px, ≤ 0).
func get_breath_offset() -> float:
	return _breath_offset


func is_breathing() -> bool:
	return _breath != null and _breath.is_running()


func stop() -> void:
	if _breath != null:
		_breath.kill()
		_breath = null
	_set_breath(0.0)


func _restart_breath() -> void:
	stop()
	if speed_scale <= 0.0 or not is_inside_tree():
		return
	var amplitude := UiTokens.TEAM_ART_BREATH_PX
	_breath = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	_breath.tween_method(_set_breath, 0.0, -amplitude, UiTokens.TEAM_BREATH_TIME)
	_breath.tween_method(_set_breath, -amplitude, 0.0, UiTokens.TEAM_BREATH_TIME)


## Image peinte filtrée : le décalage est continu.
func _set_breath(value: float) -> void:
	_breath_offset = value
	_layout_art()


## Image carrée posée pieds en bas au-dessus de l'ombre, centrée ; halo derrière.
func _layout_art() -> void:
	if _sprite_box == null:
		return
	var box := _sprite_box.size
	var side := minf(minf(box.x, box.y - UiTokens.TEAM_ART_BREATH_PX), float(UiTokens.TEAM_ART_MAX))
	if _art_size > 0:
		side = float(_art_size)
	side = maxf(side, 0.0)
	var origin := Vector2((box.x - side) * 0.5, box.y - side - UiTokens.TEAM_ART_BREATH_PX * 0.5)
	_sprite.size = Vector2.ONE * side
	_sprite.position = origin + Vector2(0.0, _breath_offset)
	_halo.size = Vector2.ONE * side * 1.2
	_halo.position = origin + (Vector2.ONE * side - _halo.size) * 0.5
	_shadow.queue_redraw()


func _play_switch() -> void:
	var time := UiTokens.TEAM_SWITCH_TIME * speed_scale
	if _fade != null:
		_fade.kill()
	if time <= 0.0:
		_sprite_box.modulate.a = 1.0
		return
	_sprite_box.modulate.a = 0.0
	_fade = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_fade.tween_property(_sprite_box, ^"modulate:a", 1.0, time)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		stop()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and _sheet != null:
		_restart_breath()


func _build() -> void:
	_sprite_box = Control.new()
	_sprite_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _art_size > 0:
		_sprite_box.custom_minimum_size = Vector2(_art_size, _art_size + UiTokens.TEAM_ART_BREATH_PX)
		_sprite_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	else:
		_sprite_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sprite_box.resized.connect(_layout_art)
	add_child(_sprite_box)
	_halo = TextureRect.new()
	_halo.texture = PokedexArt.halo_texture()
	_halo.modulate.a = UiTokens.TEAM_ART_HALO_ALPHA
	_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_halo.stretch_mode = TextureRect.STRETCH_SCALE
	_sprite_box.add_child(_halo)
	_shadow = Control.new()
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shadow.draw.connect(_draw_shadow)
	_sprite_box.add_child(_shadow)
	_sprite = TextureRect.new()
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite_box.add_child(_sprite)

	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	add_child(name_row)
	_name = Label.new()
	_name.theme_type_variation = &"MenuName"
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(_name)
	_gender = TextureRect.new()
	_gender.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gender.custom_minimum_size = Vector2.ONE * UiTokens.MENU_STAT_ICON
	_gender.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gender.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_gender.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_row.add_child(_gender)
	_favorite = PanelContainer.new()
	_favorite.theme_type_variation = &"TeamPill"
	_favorite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_favorite.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_favorite.visible = false
	name_row.add_child(_favorite)
	var pill_row := HBoxContainer.new()
	pill_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill_row.add_theme_constant_override(&"separation", UiTokens.TYPE_BADGE_GAP)
	_favorite.add_child(pill_row)
	var star := TextureRect.new()
	star.texture = STAR_ICON
	star.modulate = UiTokens.ACCENT
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.custom_minimum_size = Vector2.ONE * UiTokens.TYPE_BADGE_ICON
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pill_row.add_child(star)
	_favorite_label = Label.new()
	_favorite_label.theme_type_variation = &"TeamPillText"
	_favorite_label.text = FAVORITE_TEXT
	_favorite_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill_row.add_child(_favorite_label)

	var level_row := HBoxContainer.new()
	level_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	add_child(level_row)
	_level = Label.new()
	_level.theme_type_variation = &"TeamLevel"
	_level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_row.add_child(_level)
	_status = Label.new()
	_status.theme_type_variation = &"TeamValue"
	_status.add_theme_color_override(&"font_color", UiTokens.HP_LOW)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_row.add_child(_status)
	_types = HBoxContainer.new()
	_types.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_types.add_theme_constant_override(&"separation", UiTokens.TYPE_BADGE_GAP)
	_types.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_types.alignment = BoxContainer.ALIGNMENT_END
	level_row.add_child(_types)

	var hp_row := HBoxContainer.new()
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	add_child(hp_row)
	_hp_bar = HP_BAR_SCENE.instantiate() as HpBar
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(_hp_bar)
	_hp_text = _caption_value()
	hp_row.add_child(_hp_text)

	_xp_row = HBoxContainer.new()
	_xp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	add_child(_xp_row)
	var xp_tag := Label.new()
	xp_tag.theme_type_variation = &"TeamCaption"
	xp_tag.text = XP_TAG
	xp_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_row.add_child(xp_tag)
	_xp_bar = ExpBar.new()
	_xp_bar.theme_type_variation = &"ExpBar"
	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_row.add_child(_xp_bar)
	_xp_text = _caption_value()
	_xp_row.add_child(_xp_text)
	_xp_remaining = Label.new()
	_xp_remaining.theme_type_variation = &"TeamCaption"
	_xp_remaining.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_xp_remaining)


func _caption_value() -> Label:
	var label := Label.new()
	label.theme_type_variation = &"TeamCaption"
	label.add_theme_color_override(&"font_color", UiTokens.TEXT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Ombre posée sous le Pokémon (ellipse), qui ne bouge pas avec la respiration.
func _draw_shadow() -> void:
	var width := minf(_shadow.size.x, _sprite.size.x) * 0.62
	var height := width * 0.16
	var center := Vector2(_shadow.size.x * 0.5, _shadow.size.y - height * 0.5 - 4.0)
	var points := PackedVector2Array()
	for i: int in 32:
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * width * 0.5, sin(angle) * height * 0.5))
	_shadow.draw_colored_polygon(points, UiTokens.TEAM_SHADOW)
