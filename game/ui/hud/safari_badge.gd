class_name SafariBadge
extends PanelContainer
## Pastille « pas · Balls » du Parc Safari (J23, dossier 26 N-7, annexe A-26 ; `jalon-23.md` §2.5) :
## capsule discrète en haut à gauche, sous le titre de zone, deux icônes et deux nombres, aucun
## texte. Visible seulement sur les cartes du Parc, pendant une visite, hors scènes et combats
## ([SafariDirector] décide). Aucune alerte. Lecteur d'écran : « {n} pas, {m} Safari Balls ».
## Icônes provisoires (chaussure de course et Poké Ball du kit d'interface).

const STEP_ICON: Texture2D = preload("res://assets/ui/icons/run_shoe.svg")
const BALL_ICON: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")
## Sous le titre de zone [D] (coin haut gauche, marge de sécurité, ≈ 1,6 fois sa hauteur).
const TOP_OFFSET: float = 150.0
const ICON_SIZE: float = 36.0
const FONT_SIZE: int = 30

var _steps_label: Label
var _balls_label: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.12, 0.55)
	style.set_corner_radius_all(28)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override(&"panel", style)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", 12)
	add_child(row)
	_steps_label = _add_counter(row, STEP_ICON)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(14, 0)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(gap)
	_balls_label = _add_counter(row, BALL_ICON)


func _ready() -> void:
	position = Vector2(UiTokens.SAFE_MARGIN, UiTokens.SAFE_MARGIN + TOP_OFFSET)


## Montre ou cache la pastille avec ses deux nombres.
func show_counts(shown: bool, steps_left: int, balls_left: int) -> void:
	_steps_label.text = str(steps_left)
	_balls_label.text = str(balls_left)
	tooltip_text = "%d pas, %d Safari Balls" % [steps_left, balls_left]
	visible = shown


func get_steps_text() -> String:
	return _steps_label.text


func get_balls_text() -> String:
	return _balls_label.text


func _add_counter(row: HBoxContainer, icon: Texture2D) -> Label:
	var rect := TextureRect.new()
	rect.texture = icon
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(rect)
	var label := Label.new()
	label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	label.add_theme_color_override(&"font_color", Color.WHITE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return label
