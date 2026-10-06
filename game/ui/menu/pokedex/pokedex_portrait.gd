class_name PokedexPortrait
extends PanelContainer
## Colonne centrale du Pokédex (refonte, maquette menu-pokedex-v1.jpg) : le grand portrait de
## l'espèce choisie **mis en scène** sur un décor peint, son numéro, son nom, ses types, les
## cartes Vu / Capturé, sa description et, à la capture, ses cartes Taille / Poids. Elle ne
## connaît qu'un [PokedexSheetView] (anti-spoiler : tout vient de la vue ; texte vide = élément
## absent, jamais de « ??? »).
##
## - Décor (T4, **essai** en attendant la phase DA) : une image peinte floutée choisie par
##   [PokedexScene] d'après le premier habitat observé (sinon le décor par défaut), en
##   couverture du panneau, avec lumière douce, vignettage et fondu vers le bas (shader
##   pokedex_scene.gdshader). Le liseré du panneau est redessiné par-dessus.
## - Portrait : artwork officiel **resserré sur son cadre utile** ([method PokedexArt.portrait]),
##   chargé à l'affichage, posé pieds en bas au-dessus des cartes Vu / Capturé, sur un halo et
##   une ombre au sol. Il respire (échelle 1 ↔ 1,015, un [Tween]) ; coupé quand
##   [member speed_scale] vaut 0 ou que la colonne est cachée. Fondu de 150 ms au changement.
## - Espèce seulement vue : ni types, ni carte Capturé, ni description, ni Taille / Poids ; un
##   mot d'encouragement.

const SEEN_CAPTION := "Vu"
const CAUGHT_CAPTION := "Capturé"
const SIZE_CAPTION := "Taille"
const WEIGHT_CAPTION := "Poids"
const SEEN_HINT := "Capture ce Pokémon pour compléter sa fiche."
const EYE_ICON: Texture2D = preload("res://assets/ui/icons/pokedex/eye.svg")
const BALL_ICON: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")
const RULER_ICON: Texture2D = preload("res://assets/ui/icons/pokedex/ruler.svg")
const WEIGHT_ICON: Texture2D = preload("res://assets/ui/icons/pokedex/weight.svg")
const BADGE_SCENE: PackedScene = preload("res://game/ui/components/type_badge.tscn")
const SCENE_SHADER: Shader = preload("res://game/ui/menu/pokedex/pokedex_scene.gdshader")

static var _shadow_texture: GradientTexture2D

## Durées multipliées (0 = instantané, pas de respiration) ; posée par l'écran.
var speed_scale: float = 1.0

var _view: PokedexSheetView
var _shown_number: int = 0
var _scene_name: String = ""
var _breath: Tween
var _fade: Tween

var _backdrop: TextureRect
var _content: MarginContainer
var _column: VBoxContainer
var _stage: Control
var _titles: VBoxContainer
var _number: Label
var _name: Label
var _type_row: HBoxContainer
var _halo: TextureRect
var _shadow: TextureRect
var _art: TextureRect
var _cards: HBoxContainer
var _seen_card: PanelContainer
var _seen_value: Label
var _caught_card: PanelContainer
var _caught_value: Label
var _description: Label
var _facts: HBoxContainer
var _size_card: PanelContainer
var _size_value: Label
var _weight_card: PanelContainer
var _weight_value: Label
var _empty: Label
var _rim: Panel


func _init() -> void:
	theme_type_variation = &"DexHeroPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_stretch_ratio = UiTokens.DEX_LAYOUT_CENTER_STRETCH
	custom_minimum_size.x = UiTokens.DEX_LAYOUT_CENTER_MIN
	_build()
	visibility_changed.connect(_on_visibility_changed)
	resized.connect(_layout_backdrop)


## Pose [param view] (null : colonne vide, [param empty_text] à la place).
func show_species(view: PokedexSheetView, empty_text: String = "") -> void:
	_view = view
	var has_view := view != null
	_content.visible = has_view
	_backdrop.visible = has_view
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
	_size_value.text = view.height_text
	_size_card.visible = not view.height_text.is_empty()
	_weight_value.text = view.weight_text
	_weight_card.visible = not view.weight_text.is_empty()
	_facts.visible = _size_card.visible or _weight_card.visible
	var scene := PokedexScene.scene_for(view.habitats)
	if scene != _scene_name:
		_scene_name = scene
		_backdrop.texture = PokedexScene.texture_for(view.habitats)
		_layout_backdrop()
	if changed:
		_shown_number = view.number
		_art.texture = PokedexArt.portrait(view.number)
		_play_fade()
	_layout_stage.call_deferred()
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


func get_size_card() -> PanelContainer:
	return _size_card


func get_weight_card() -> PanelContainer:
	return _weight_card


func get_description() -> Label:
	return _description


func get_empty_label() -> Label:
	return _empty


## Image du décor posée sous le portrait.
func get_backdrop() -> TextureRect:
	return _backdrop


## Nom du décor affiché (« village », « prairie »… ; [PokedexScene]).
func get_scene_name() -> String:
	return _scene_name


## Vrai tant que la respiration tourne.
func is_breathing() -> bool:
	return _breath != null and _breath.is_valid() and _breath.is_running()


## Chemin de l'artwork affiché ("" si aucun) : pour les tests.
func get_art_path() -> String:
	var texture := _art.texture
	if texture is AtlasTexture:
		texture = (texture as AtlasTexture).atlas
	return texture.resource_path if texture != null else ""


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


func _fill_types(view: PokedexSheetView) -> void:
	for old: Node in _type_row.get_children():
		_type_row.remove_child(old)
		old.queue_free()
	for i: int in view.type_ids.size():
		var badge := BADGE_SCENE.instantiate() as TypeBadge
		_type_row.add_child(badge)
		badge.set_type(view.type_ids[i], view.type_names[i])
	_type_row.visible = not view.type_ids.is_empty()


## Le décor couvre tout le panneau ; le fondu du bas commence sous les cartes Vu / Capturé.
func _layout_backdrop() -> void:
	if _backdrop == null or size.y <= 0.0:
		return
	var material := _backdrop.material as ShaderMaterial
	material.set_shader_parameter(&"rect_size", size)
	if _backdrop.texture != null:
		material.set_shader_parameter(&"texture_size", _backdrop.texture.get_size())
	var stage_bottom := (_stage.get_global_rect().end.y - get_global_rect().position.y) / size.y \
		if _stage.is_inside_tree() and _stage.size.y > 0.0 else 0.6
	var start := clampf(stage_bottom - UiTokens.DEX_SCENE_FADE_SPAN * 0.5, 0.0, 1.0)
	material.set_shader_parameter(&"fade_start", start)
	material.set_shader_parameter(&"fade_end", clampf(start + UiTokens.DEX_SCENE_FADE_SPAN,
		0.0, 1.0))


## Dans la scène : titres en haut à gauche, cartes Vu / Capturé en bas, et le Pokémon posé
## pieds en bas juste au-dessus des cartes, aussi grand que la place le permet (il peut monter
## dans la zone du nom), avec son halo et son ombre au sol.
func _layout_stage() -> void:
	var area := _stage.size
	if area.x <= 0.0 or area.y <= 0.0:
		return
	var titles_h := _titles.get_combined_minimum_size().y
	_titles.position = Vector2.ZERO
	_titles.size = Vector2(area.x, titles_h)
	var cards_h := _cards.get_combined_minimum_size().y if _cards.visible else 0.0
	_cards.position = Vector2(0.0, area.y - cards_h)
	_cards.size = Vector2(area.x, cards_h)
	# Une carte seule (espèce vue) garde la largeur d'une demi-rangée, comme à deux.
	var half := (area.x - UiTokens.DEX_SHEET_GAP) * 0.5
	for card: PanelContainer in [_seen_card, _caught_card]:
		card.size_flags_horizontal = Control.SIZE_FILL
		card.custom_minimum_size.x = half
	var feet := area.y - cards_h - UiTokens.DEX_PORTRAIT_FEET_GAP
	# Deux places possibles, la plus grande gagne : sous les titres (toute la largeur), ou à
	# côté d'eux (toute la hauteur, à droite du nom et des types).
	var titles_w := 0.0
	for child: Control in [_number, _name, _type_row]:
		if child.visible:
			titles_w = maxf(titles_w, child.get_combined_minimum_size().x)
	var gap := float(UiTokens.DEX_GAP)
	var below := Rect2(0.0, titles_h * (1.0 - UiTokens.DEX_PORTRAIT_RISE),
		area.x * UiTokens.DEX_PORTRAIT_WIDTH, 0.0)
	below.size.y = feet - below.position.y
	var beside := Rect2(titles_w + gap, gap, area.x - titles_w - gap, feet - gap)
	var source := Vector2.ONE
	var texture := _art.texture
	if texture != null and texture.get_height() > 0:
		source = texture.get_size()
	var art_size := Vector2.ZERO
	var center_x := 0.0
	for place: Rect2 in [below, beside]:
		if place.size.x <= 0.0 or place.size.y <= 0.0:
			continue
		var factor := minf(minf(place.size.x / source.x, place.size.y / source.y),
			UiTokens.DEX_PORTRAIT_MAX / source.y)
		if source.x * factor > art_size.x:
			art_size = source * factor
			center_x = place.position.x + place.size.x * 0.5 \
				+ (area.x * UiTokens.DEX_PORTRAIT_SHIFT if place == below else 0.0)
	center_x = clampf(center_x, art_size.x * 0.5, area.x - art_size.x * 0.5)
	_art.size = art_size
	_art.position = Vector2(center_x - art_size.x * 0.5, feet - art_size.y)
	_art.pivot_offset = Vector2(art_size.x * 0.5, art_size.y)
	var halo_side := maxf(art_size.x, art_size.y) * UiTokens.DEX_LAYOUT_HALO_SCALE
	_halo.size = Vector2.ONE * halo_side
	_halo.position = _art.position + (art_size - _halo.size) * 0.5
	_shadow.size = Vector2(art_size.x * UiTokens.DEX_LAYOUT_SHADOW_WIDTH * 1.3,
		maxf(art_size.y, art_size.x) * UiTokens.DEX_LAYOUT_SHADOW_HEIGHT)
	_shadow.position = Vector2(center_x - _shadow.size.x * 0.5, feet - _shadow.size.y * 0.5)
	_layout_backdrop()


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
	_art.modulate.a = 1.0
	var time := UiTokens.DEX_LAYOUT_PORTRAIT_FADE * speed_scale
	if time <= 0.0 or not is_visible_in_tree():
		return
	_art.modulate.a = 0.0
	_fade = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_fade.tween_property(_art, ^"modulate:a", 1.0, time)


func _on_visibility_changed() -> void:
	if _view == null:
		return
	if is_visible_in_tree():
		_start_breath()
	else:
		_stop_breath()


func _build() -> void:
	_backdrop = TextureRect.new()
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	var material := ShaderMaterial.new()
	material.shader = SCENE_SHADER
	material.set_shader_parameter(&"radius", float(UiTokens.DEX_GLASS_RADIUS))
	material.set_shader_parameter(&"light_center", UiTokens.DEX_SCENE_LIGHT_CENTER)
	material.set_shader_parameter(&"light_color", UiTokens.DEX_SCENE_LIGHT_COLOR)
	material.set_shader_parameter(&"light_strength", UiTokens.DEX_SCENE_LIGHT)
	material.set_shader_parameter(&"lift", UiTokens.DEX_SCENE_LIFT)
	material.set_shader_parameter(&"saturation", UiTokens.DEX_SCENE_SATURATION)
	material.set_shader_parameter(&"vignette", UiTokens.DEX_SCENE_VIGNETTE)
	material.set_shader_parameter(&"fade_color", UiTokens.DEX_SCENE_FADE_COLOR)
	_backdrop.material = material
	_backdrop.visible = false
	add_child(_backdrop)

	_content = MarginContainer.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		_content.add_theme_constant_override(side, UiTokens.DEX_LAYOUT_HERO_PAD)
	add_child(_content)
	_column = VBoxContainer.new()
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	_content.add_child(_column)

	# La scène : un Control libre (le portrait, ses titres et ses cartes y sont placés à la main).
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.custom_minimum_size.y = UiTokens.DEX_LAYOUT_PORTRAIT_MIN
	_stage.resized.connect(_layout_stage)
	_column.add_child(_stage)
	_shadow = _image(_shadow_tex(), TextureRect.STRETCH_SCALE)
	_halo = _image(PokedexArt.halo_texture(), TextureRect.STRETCH_SCALE)
	_halo.modulate.a = UiTokens.DEX_PORTRAIT_HALO_ALPHA
	_art = _image(null, TextureRect.STRETCH_SCALE)

	_titles = VBoxContainer.new()
	_titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_titles.add_theme_constant_override(&"separation", 0)
	_stage.add_child(_titles)
	_number = Label.new()
	_number.theme_type_variation = &"DexSceneNumber"
	_number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_titles.add_child(_number)
	_name = Label.new()
	_name.theme_type_variation = &"DexSceneName"
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_titles.add_child(_name)
	_type_row = HBoxContainer.new()
	_type_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_type_row.add_theme_constant_override(&"separation", UiTokens.TYPE_BADGE_GAP)
	_titles.add_child(_type_row)

	_cards = HBoxContainer.new()
	_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	_stage.add_child(_cards)
	_seen_card = _card(_cards, EYE_ICON, SEEN_CAPTION)
	_seen_value = _seen_card.get_meta(&"value") as Label
	_caught_card = _card(_cards, BALL_ICON, CAUGHT_CAPTION)
	_caught_value = _caught_card.get_meta(&"value") as Label

	_description = Label.new()
	_description.theme_type_variation = &"DexDescription"
	_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_column.add_child(_description)

	_facts = HBoxContainer.new()
	_facts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_facts.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	_column.add_child(_facts)
	_size_card = _card(_facts, RULER_ICON, SIZE_CAPTION)
	_size_value = _size_card.get_meta(&"value") as Label
	_weight_card = _card(_facts, WEIGHT_ICON, WEIGHT_CAPTION)
	_weight_value = _weight_card.get_meta(&"value") as Label

	_empty = Label.new()
	_empty.theme_type_variation = &"BagEmpty"
	_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.visible = false
	add_child(_empty)

	_rim = Panel.new()
	_rim.theme_type_variation = &"DexHeroRim"
	_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rim)


func _image(texture: Texture2D, stretch: TextureRect.StretchMode) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = stretch
	_stage.add_child(image)
	return image


## Carte « icône + légende + valeur » (la valeur est gardée en méta).
func _card(parent: Container, icon: Texture2D, caption: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = &"DexCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.DEX_CARD_PAD)
	card.add_child(row)
	var image := TextureRect.new()
	image.texture = icon
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2.ONE * UiTokens.DEX_FACT_ICON
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
	parent.add_child(card)
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
