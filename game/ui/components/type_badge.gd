class_name TypeBadge
extends PanelContainer
## Pastille de type : icône blanche + nom du type, sur la couleur du type (TYPE_COLORS).
##
## Elle ne connaît pas la table des types : on lui donne un identifiant (&"fire", clé de
## TYPE_COLORS, pour la couleur et l'icône) et le nom à afficher (« Feu »). Un type sans
## icône n'affiche que son nom ; un type sans couleur prend TYPE_COLOR_UNKNOWN.

## Icônes disponibles (CB.2 : Électrik et huit autres ; Fée au jalon 12, T14 ; Dragon, Ténèbres,
## Acier : icône neutre).
const ICONS: Dictionary[StringName, Texture2D] = {
	&"normal": preload("res://assets/ui/icons/types/normal.svg"),
	&"grass": preload("res://assets/ui/icons/types/grass.svg"),
	&"poison": preload("res://assets/ui/icons/types/poison.svg"),
	&"fire": preload("res://assets/ui/icons/types/fire.svg"),
	&"water": preload("res://assets/ui/icons/types/water.svg"),
	&"electric": preload("res://assets/ui/icons/types/electric.svg"),
	&"ice": preload("res://assets/ui/icons/types/ice.svg"),
	&"rock": preload("res://assets/ui/icons/types/rock.svg"),
	&"ground": preload("res://assets/ui/icons/types/ground.svg"),
	&"flying": preload("res://assets/ui/icons/types/flying.svg"),
	&"bug": preload("res://assets/ui/icons/types/bug.svg"),
	&"psychic": preload("res://assets/ui/icons/types/psychic.svg"),
	&"ghost": preload("res://assets/ui/icons/types/ghost.svg"),
	&"fighting": preload("res://assets/ui/icons/types/fighting.svg"),
	&"fairy": preload("res://assets/ui/icons/types/fairy.svg"),
}

var _type_id: StringName = &""
var _type_name: String = ""
var _show_icon: bool = true
var _style: StyleBoxFlat

@onready var _row: HBoxContainer = %Row
@onready var _icon: TextureRect = %Icon
@onready var _label: Label = %Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override(&"separation", UiTokens.TYPE_BADGE_GAP)
	_icon.custom_minimum_size = Vector2.ONE * UiTokens.TYPE_BADGE_ICON
	_style = (get_theme_stylebox(&"panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	add_theme_stylebox_override(&"panel", _style)
	_apply()


## Type [param type_id] (identifiant anglais) affiché sous le nom [param type_name]
## (mis en MAJUSCULES, comme la planche).
func set_type(type_id: StringName, type_name: String) -> void:
	_type_id = type_id
	_type_name = type_name.to_upper()
	if is_node_ready():
		_apply()


## Montre ou cache l'icône (la carte de capacité a déjà l'icône du type à sa gauche).
func set_show_icon(shown: bool) -> void:
	_show_icon = shown
	if is_node_ready():
		_apply()


func get_type_id() -> StringName:
	return _type_id


func get_type_text() -> String:
	return _label.text


func get_color() -> Color:
	return _style.bg_color


func get_icon() -> Texture2D:
	return _icon.texture


func _apply() -> void:
	_label.text = _type_name
	_style.bg_color = UiTokens.TYPE_COLORS.get(_type_id, UiTokens.TYPE_COLOR_UNKNOWN)
	_icon.texture = ICONS.get(_type_id, null)
	_icon.visible = _show_icon and _icon.texture != null
