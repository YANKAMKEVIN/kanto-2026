class_name PokedexPortrait
extends PanelContainer
## Colonne centrale du Pokédex (refonte, maquette menu-pokedex-v1.jpg) : le grand portrait de
## l'espèce choisie, son numéro, son nom, ses types, les cartes Vu / Capturé et sa description.
## Elle ne connaît qu'un [PokedexSheetView] (anti-spoiler : tout vient de la vue ; texte vide =
## élément absent, jamais de « ??? »).
##
## - Portrait : artwork officiel de [method PokedexArt.portrait_path], **chargé à l'affichage**,
##   sur un halo clair et une ombre au sol (pas de décor : phase DA). Il respire (échelle
##   1 ↔ 1,015, un [Tween]) ; coupé quand [member speed_scale] vaut 0 ou que la colonne est
##   cachée. Fondu de 150 ms quand l'espèce change.
## - Espèce seulement vue : ni types, ni carte Capturé, ni description ; un mot d'encouragement.

const SEEN_CAPTION := "Vu"
const CAUGHT_CAPTION := "Capturé"
const SEEN_HINT := "Capture ce Pokémon pour compléter sa fiche."
const EYE_ICON: Texture2D = preload("res://assets/ui/icons/pokedex/eye.svg")
const BALL_ICON: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")
const BADGE_SCENE: PackedScene = preload("res://game/ui/components/type_badge.tscn")

static var _shadow_texture: GradientTexture2D

## Durées multipliées (0 = instantané, pas de respiration) ; posée par l'écran.
var speed_scale: float = 1.0

var _view: PokedexSheetView
var _shown_number: int = 0
var _breath: Tween
var _fade: Tween

var _column: VBoxContainer
var _number: Label
var _name: Label
var _type_row: HBoxContainer
var _stage: Control
var _halo: TextureRect
var _shadow: TextureRect
var _art: TextureRect
var _cards: HBoxContainer
var _seen_card: PanelContainer
var _seen_value: Label
var _caught_card: PanelContainer
var _caught_value: Label
var _description: Label
var _empty: Label


func _init() -> void:
	theme_type_variation = &"DexHeroPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_stretch_ratio = UiTokens.DEX_LAYOUT_CENTER_STRETCH
	custom_minimum_size.x = UiTokens.DEX_LAYOUT_CENTER_MIN
	_build()
	visibility_changed.connect(_on_visibility_changed)


## Pose [param view] (null : colonne vide, [param empty_text] à la place).
func show_species(view: PokedexSheetView, empty_text: String = "") -> void:
	_view = view
	var has_view := view != null
	_column.visible = has_view
	_empty.visible = not has_view
	_empty.text = empty_text
	if not has_view:
		_stop_breath()
		return
	var changed := view.number != _shown_number
	_number.text = view.number_text
	_name.text = view.name
	_fill_types(view)
	_seen_value.text = view.seen_times_text
	_seen_card.visible = not view.seen_times_text.is_empty()
	_caught_value.text = view.caught_times_text
	_caught_card.visible = not view.caught_times_text.is_empty()
	_cards.visible = _seen_card.visible or _caught_card.visible
	_description.text = view.description if not view.description.is_empty() else SEEN_HINT
	if changed:
		_shown_number = view.number
		_art.texture = _load_portrait(view.number)
		_play_fade()
	_layout_stage()
	_start_breath()


func get_view() -> PokedexSheetView:
	return _view


func get_number_label() -> Label:
	return _number


func get_name_label() -> Label:
	return _name


func get_type_row() -> HBoxContainer:
	return _type_row


func get_art() -> TextureRect:
	return _art


func get_halo() -> TextureRect:
	return _halo


func get_shadow() -> TextureRect:
	return _shadow


func get_seen_card() -> PanelContainer:
	return _seen_card


func get_caught_card() -> PanelContainer:
	return _caught_card


func get_description() -> Label:
	return _description


func get_empty_label() -> Label:
	return _empty


## Vrai tant que la respiration tourne.
func is_breathing() -> bool:
	return _breath != null and _breath.is_valid() and _breath.is_running()


## Chemin de l'artwork affiché ("" si aucun) : pour les tests.
func get_art_path() -> String:
	return _art.texture.resource_path if _art.texture != null else ""


## Tous les textes visibles de la colonne.
func get_texts() -> Array[String]:
	var texts: Array[String] = []
	_collect_texts(self, texts)
	return texts


func _collect_texts(node: Node, into: Array[String]) -> void:
	var label := node as Label
	if label != null and label.is_visible_in_tree() and not label.text.is_empty():
		into.append(label.text)
	for child: Node in node.get_children():
		_collect_texts(child, into)


func _load_portrait(number: int) -> Texture2D:
	var path := PokedexArt.portrait_path(number)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _fill_types(view: PokedexSheetView) -> void:
	for old: Node in _type_row.get_children():
		_type_row.remove_child(old)
		old.queue_free()
	for i: int in view.type_ids.size():
		var badge := BADGE_SCENE.instantiate() as TypeBadge
		_type_row.add_child(badge)
		badge.set_type(view.type_ids[i], view.type_names[i])
	_type_row.visible = not view.type_ids.is_empty()


## Halo, ombre et portrait dans la plus grande boîte carrée de la scène, centrée.
func _layout_stage() -> void:
	var side := minf(_stage.size.x, _stage.size.y)
	if side <= 0.0:
		return
	var box := Vector2.ONE * side
	var origin := (_stage.size - box) * 0.5
	_art.size = box
	_art.position = origin
	_art.pivot_offset = Vector2(side * 0.5, side)
	var halo_side := side * UiTokens.DEX_LAYOUT_HALO_SCALE
	_halo.size = Vector2.ONE * halo_side
	_halo.position = origin + (box - _halo.size) * 0.5
	_shadow.size = Vector2(side * UiTokens.DEX_LAYOUT_SHADOW_WIDTH,
		side * UiTokens.DEX_LAYOUT_SHADOW_HEIGHT)
	_shadow.position = origin + Vector2((side - _shadow.size.x) * 0.5,
		side * (1.0 - UiTokens.DEX_LAYOUT_SHADOW_RISE) - _shadow.size.y * 0.5)


func _start_breath() -> void:
	_stop_breath()
	if speed_scale <= 0.0 or not is_visible_in_tree() or _art.texture == null:
		return
	var half := UiTokens.DEX_LAYOUT_BREATH_TIME * 0.5 / speed_scale
	var peak := Vector2.ONE * (1.0 + UiTokens.DEX_LAYOUT_BREATH)
	_breath = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breath.tween_property(_art, ^"scale", peak, half)
	_breath.tween_property(_art, ^"scale", Vector2.ONE, half)


func _stop_breath() -> void:
	if _breath != null:
		_breath.kill()
		_breath = null
	if _art != null:
		_art.scale = Vector2.ONE


func _play_fade() -> void:
	if _fade != null:
		_fade.kill()
		_fade = null
	_stage.modulate.a = 1.0
	var time := UiTokens.DEX_LAYOUT_PORTRAIT_FADE * speed_scale
	if time <= 0.0 or not is_visible_in_tree():
		return
	_stage.modulate.a = 0.0
	_fade = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_fade.tween_property(_stage, ^"modulate:a", 1.0, time)


func _on_visibility_changed() -> void:
	if _view == null:
		return
	if is_visible_in_tree():
		_start_breath()
	else:
		_stop_breath()


func _build() -> void:
	_column = VBoxContainer.new()
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	add_child(_column)
	var titles := VBoxContainer.new()
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.add_theme_constant_override(&"separation", 0)
	_column.add_child(titles)
	_number = Label.new()
	_number.theme_type_variation = &"DexNumber"
	_number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.add_child(_number)
	_name = Label.new()
	_name.theme_type_variation = &"DexName"
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titles.add_child(_name)
	_type_row = HBoxContainer.new()
	_type_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_type_row.add_theme_constant_override(&"separation", UiTokens.TYPE_BADGE_GAP)
	_column.add_child(_type_row)

	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.custom_minimum_size.y = UiTokens.DEX_LAYOUT_PORTRAIT_MIN
	_stage.clip_contents = true
	_stage.resized.connect(_layout_stage)
	_column.add_child(_stage)
	_halo = _image(PokedexArt.halo_texture(), TextureRect.STRETCH_SCALE)
	_shadow = _image(_shadow_tex(), TextureRect.STRETCH_SCALE)
	_art = _image(null, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)

	_cards = HBoxContainer.new()
	_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	_column.add_child(_cards)
	_seen_card = _card(EYE_ICON, SEEN_CAPTION)
	_seen_value = _seen_card.get_meta(&"value") as Label
	_caught_card = _card(BALL_ICON, CAUGHT_CAPTION)
	_caught_value = _caught_card.get_meta(&"value") as Label

	_description = Label.new()
	_description.theme_type_variation = &"DexDescription"
	_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_column.add_child(_description)

	_empty = Label.new()
	_empty.theme_type_variation = &"BagEmpty"
	_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.visible = false
	add_child(_empty)


func _image(texture: Texture2D, stretch: TextureRect.StretchMode) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = stretch
	_stage.add_child(image)
	return image


## Carte « icône + légende + valeur » (la valeur est gardée en méta).
func _card(icon: Texture2D, caption: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = &"TeamSection"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, UiTokens.DEX_SHEET_GAP)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	margin.add_child(row)
	var image := TextureRect.new()
	image.texture = icon
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2.ONE * UiTokens.DEX_LAYOUT_CARD_ICON
	image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(image)
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_theme_constant_override(&"separation", 0)
	row.add_child(texts)
	var cap := Label.new()
	cap.theme_type_variation = &"DexCardCaption"
	cap.text = caption
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(cap)
	var value := Label.new()
	value.theme_type_variation = &"DexCardValue"
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(value)
	card.set_meta(&"value", value)
	_cards.add_child(card)
	return card


## Ombre au sol : un dégradé radial sombre, étiré en ellipse.
static func _shadow_tex() -> Texture2D:
	if _shadow_texture == null:
		var gradient := Gradient.new()
		var edge := UiTokens.DEX_LAYOUT_SHADOW_COLOR
		edge.a = 0.0
		gradient.set_color(0, UiTokens.DEX_LAYOUT_SHADOW_COLOR)
		gradient.set_color(1, edge)
		_shadow_texture = GradientTexture2D.new()
		_shadow_texture.gradient = gradient
		_shadow_texture.fill = GradientTexture2D.FILL_RADIAL
		_shadow_texture.fill_from = Vector2(0.5, 0.5)
		_shadow_texture.fill_to = Vector2(1.0, 0.5)
		_shadow_texture.width = UiTokens.DEX_HALO_TEXTURE
		_shadow_texture.height = UiTokens.DEX_HALO_TEXTURE
	return _shadow_texture
