class_name TrainerCardPanel
extends PanelContainer
## Carte du Dresseur (dossier 08 §1), à gauche du tableau de bord : nom, « Dresseur Pokémon »,
## temps de jeu, vus · capturés (si la vue le donne), badges (si la vue le donne), portrait en
## pixel art à l'échelle entière, et en bas le Pokémon de tête.
## Règle d'affichage : un texte vide = une ligne absente ; pas de Pokémon de tête = pas de carte.

## Le Pokémon de tête est touché.
signal lead_chosen

## Portrait provisoire (le joueur, de face) jusqu'à la DA ; une image du jeu pas encore dessinée.
const PORTRAIT_FRAMES_PATH := "res://assets/sprites/characters/placeholder/player_frames.tres"
const PORTRAIT_ANIMATION := &"idle_down"
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
	theme_type_variation = &"MenuPanel"
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
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", UiTokens.GAP)
	add_child(column)

	var top := HBoxContainer.new()
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top.add_theme_constant_override(&"separation", UiTokens.GAP)
	column.add_child(top)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override(&"separation", UiTokens.GAP)
	top.add_child(texts)
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

	_portrait = TextureRect.new()
	_portrait.texture = _portrait_texture()
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.custom_minimum_size = Vector2(UiTokens.MENU_PORTRAIT_SOURCE) \
		* UiTokens.MENU_PORTRAIT_SCALE
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_END
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_portrait)

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


func _set_row(label: Label, text: String) -> void:
	label.text = text
	_rows[label].visible = not text.is_empty()


func _portrait_texture() -> Texture2D:
	var frames := load(PORTRAIT_FRAMES_PATH) as SpriteFrames
	if frames == null or not frames.has_animation(PORTRAIT_ANIMATION):
		return null
	return frames.get_frame_texture(PORTRAIT_ANIMATION, 0)
