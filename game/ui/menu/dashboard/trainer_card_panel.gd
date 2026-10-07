class_name TrainerCardPanel
extends PanelContainer
## Carte du Dresseur (dossier 08 §1), à gauche du tableau de bord : nom, « Dresseur Pokémon »,
## temps de jeu, vus · capturés (si la vue le donne), badges (si la vue le donne), portrait
## **peint** du héros en buste (MM.1, [MenuArt]) ancré en bas à droite derrière les textes, et en
## bas le Pokémon de tête (qui chevauche le bas du portrait, comme la maquette).
## Règle d'affichage : un texte vide = une ligne absente ; pas de Pokémon de tête = pas de carte.

## Le Pokémon de tête est touché.
signal lead_chosen

const ICON_CLOCK: Texture2D = preload("res://assets/ui/icons/menu/clock.svg")
const ICON_DEX: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")
## Pas d'icône de badge avant le premier badge (J10) : la ligne utilise la Poké Ball du Pokédex
## teintée de l'accent.
const ICON_BADGE: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")

var _name: Label
var _subtitle: Label
var _play_time: Label
var _dex: Label
var _badges: Label
var _rows: Dictionary[Label, Control] = {}
var _lead: LeadPokemonCard
var _portrait: TextureRect


func _init() -> void:
	theme_type_variation = &"MenuGlass"
	clip_contents = true
	custom_minimum_size.x = UiTokens.MENU_LEFT_WIDTH
	_build()


## Remplit la carte avec [param view]. À appeler une fois dans l'arbre.
func show_view(view: DashboardView) -> void:
	_name.text = view.player_name
	_subtitle.text = view.player_title
	_subtitle.visible = not view.player_title.is_empty()
	_set_row(_play_time, view.play_time_text)
	_set_row(_dex, view.dex_text)
	_set_row(_badges, view.badges_text)
	_lead.visible = view.lead != null
	if view.lead != null:
		_lead.setup(view.lead)


func get_lead_card() -> LeadPokemonCard:
	return _lead


func get_name_text() -> String:
	return _name.text


func get_play_time_text() -> String:
	return _play_time.text


## Une ligne (temps de jeu, vus · capturés, badges) est-elle affichée ?
func is_dex_shown() -> bool:
	return _rows[_dex].visible


func is_badges_shown() -> bool:
	return _rows[_badges].visible


func is_play_time_shown() -> bool:
	return _rows[_play_time].visible


func get_portrait() -> TextureRect:
	return _portrait


func _build() -> void:
	# Le portrait est posé à la main dans un calque plein cadre (ancré en bas à droite).
	var stage := Control.new()
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.resized.connect(_place_portrait.bind(stage))
	add_child(stage)
	_portrait = TextureRect.new()
	_portrait.texture = MenuArt.hero_bust()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_SCALE
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.visible = _portrait.texture != null
	stage.add_child(_portrait)

	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", UiTokens.GAP)
	add_child(column)

	var texts := VBoxContainer.new()
	texts.size_flags_vertical = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override(&"separation", UiTokens.GAP)
	column.add_child(texts)
	_name = Label.new()
	_name.theme_type_variation = &"MenuName"
	_name.clip_text = true
	texts.add_child(_name)
	_subtitle = Label.new()
	_subtitle.theme_type_variation = &"MenuSubtitle"
	_subtitle.clip_text = true
	texts.add_child(_subtitle)
	var bar := Panel.new()
	bar.theme_type_variation = &"MenuIdBar"
	bar.custom_minimum_size = UiTokens.MENU_ID_BAR
	bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	texts.add_child(bar)
	_play_time = _add_row(texts, ICON_CLOCK, UiTokens.TEXT)
	_dex = _add_row(texts, ICON_DEX, UiTokens.TEXT)
	_badges = _add_row(texts, ICON_BADGE, UiTokens.ACCENT)
	for label: Label in [_name, _subtitle, _play_time, _dex, _badges]:
		_shadow(label)

	_lead = LeadPokemonCard.new()
	_lead.chosen.connect(lead_chosen.emit)
	column.add_child(_lead)


## Ligne « icône + texte » ; le conteneur est mémorisé pour la masquer avec son texte.
func _add_row(parent: Control, icon: Texture2D, tint: Color) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", UiTokens.MENU_STAT_GAP)
	parent.add_child(row)
	var picture := TextureRect.new()
	picture.texture = icon
	picture.modulate = tint
	picture.custom_minimum_size = Vector2.ONE * UiTokens.MENU_STAT_ICON
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(picture)
	var label := Label.new()
	label.theme_type_variation = &"MenuStat"
	label.clip_text = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	_rows[label] = row
	return label


## Ombre portée du texte : il se lit sur le portrait peint.
func _shadow(label: Label) -> void:
	label.add_theme_color_override(&"font_shadow_color", UiTokens.DEX_SCENE_TEXT_SHADOW)
	label.add_theme_constant_override(&"shadow_offset_x", 0)
	label.add_theme_constant_override(&"shadow_offset_y", 2)


func _set_row(label: Label, text: String) -> void:
	label.text = text
	_rows[label].visible = not text.is_empty()


## Portrait : au plus MENU_HERO_HEIGHT, sans dépasser le cadre ; pieds du buste à mi-hauteur de
## la carte du Pokémon de tête (qui le chevauche), bord droit contre la marge.
func _place_portrait(stage: Control) -> void:
	var texture := _portrait.texture
	if texture == null:
		return
	var bottom := stage.size.y - UiTokens.MENU_LEAD_HEIGHT * 0.5
	var height := minf(float(UiTokens.MENU_HERO_HEIGHT), bottom)
	var width := height * texture.get_width() / float(texture.get_height())
	_portrait.size = Vector2(width, height)
	_portrait.position = Vector2(stage.size.x - width + UiTokens.MENU_HERO_OFFSET_X,
		bottom - height)
