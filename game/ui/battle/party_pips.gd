class_name PartyPips
extends BattleWidget
## Six pastilles d'équipe, posées au-dessus de la carte joueur (combat-v1) : une Poké Ball
## par Pokémon présent, un disque gris par emplacement vide.
##
## Elle ne connaît que des nombres : set_party(count).

const BALL_ICON: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")

var _count: int = 0
var _balls: Array[TextureRect] = []
var _empties: Array[Panel] = []


func _ready() -> void:
	slide_direction = Vector2.LEFT
	super._ready()
	var row := _body as HBoxContainer
	row.add_theme_constant_override(&"separation", UiTokens.PARTY_PIP_GAP)
	for i: int in UiTokens.PARTY_SIZE:
		var slot := Control.new()
		slot.custom_minimum_size = Vector2.ONE * UiTokens.PARTY_PIP
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var empty := Panel.new()
		empty.theme_type_variation = &"PartyPipEmpty"
		empty.set_anchors_preset(Control.PRESET_FULL_RECT)
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ball := TextureRect.new()
		ball.texture = BALL_ICON
		ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ball.set_anchors_preset(Control.PRESET_FULL_RECT)
		ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(empty)
		slot.add_child(ball)
		row.add_child(slot)
		_empties.append(empty)
		_balls.append(ball)
	set_party(0)


## [param count] Pokémon dans l'équipe (0 à PARTY_SIZE) : autant de Poké Balls, le reste gris.
func set_party(count: int) -> void:
	_count = clampi(count, 0, UiTokens.PARTY_SIZE)
	for i: int in _balls.size():
		_balls[i].visible = i < _count
		_empties[i].visible = i >= _count


func get_party_count() -> int:
	return _count


func get_slot_count() -> int:
	return _balls.size()


## L'emplacement [param index] montre une Poké Ball.
func is_slot_filled(index: int) -> bool:
	return index >= 0 and index < _balls.size() and _balls[index].visible
