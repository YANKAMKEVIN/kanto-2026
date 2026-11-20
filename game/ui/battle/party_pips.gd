class_name PartyPips
extends BattleWidget
## Six pastilles d'équipe, posées au-dessus de la carte joueur (combat-v1) et, en combat de
## Dresseur, sous la carte adverse : une Poké Ball par Pokémon présent, un disque gris par
## emplacement vide.
##
## Chaque Poké Ball dit aussi l'état du Pokémon ([enum State]) : en forme, sous statut (point
## ambre en bas à droite) ou K.O. (Ball éteinte et barrée) ; jamais la couleur seule.
## Elle ne connaît que des nombres : set_party(count) ou set_states(états).

## État d'un emplacement.
enum State { EMPTY, READY, STATUS, FAINTED }

const BALL_ICON: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")

var _count: int = 0
var _states: Array[PartyPips.State] = []
var _balls: Array[TextureRect] = []
var _empties: Array[Panel] = []
var _marks: Array[Mark] = []


func _ready() -> void:
	slide_direction = Vector2.RIGHT
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
		var mark := Mark.new()
		mark.set_anchors_preset(Control.PRESET_FULL_RECT)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(empty)
		slot.add_child(ball)
		slot.add_child(mark)
		row.add_child(slot)
		_empties.append(empty)
		_balls.append(ball)
		_marks.append(mark)
		_states.append(State.EMPTY)
	set_party(0)


## [param count] Pokémon dans l'équipe (0 à PARTY_SIZE), tous en forme : autant de Poké Balls,
## le reste gris.
func set_party(count: int) -> void:
	var states: Array[PartyPips.State] = []
	for i: int in clampi(count, 0, UiTokens.PARTY_SIZE):
		states.append(State.READY)
	set_states(states)


## Un état par Pokémon, dans l'ordre de l'équipe (PARTY_SIZE au plus, le surplus est ignoré) ;
## les emplacements au-delà sont vides.
func set_states(states: Array[PartyPips.State]) -> void:
	_count = 0
	for i: int in _balls.size():
		var state: PartyPips.State = states[i] if i < states.size() else State.EMPTY
		_states[i] = state
		if state != State.EMPTY:
			_count += 1
		_balls[i].visible = state != State.EMPTY
		_balls[i].modulate = UiTokens.PARTY_PIP_FAINTED if state == State.FAINTED \
			else UiTokens.MODULATE_FULL
		_empties[i].visible = state == State.EMPTY
		_marks[i].set_state(state)


## Pokémon présents (emplacements qui ne sont pas vides), K.O. compris.
func get_party_count() -> int:
	return _count


func get_slot_count() -> int:
	return _balls.size()


## L'emplacement [param index] montre une Poké Ball.
func is_slot_filled(index: int) -> bool:
	return index >= 0 and index < _balls.size() and _balls[index].visible


## État de l'emplacement [param index] (EMPTY hors bornes).
func get_slot_state(index: int) -> PartyPips.State:
	if index < 0 or index >= _states.size():
		return State.EMPTY
	return _states[index]


## Marque dessinée par-dessus la Poké Ball : un point ambre (statut) ou une barre (K.O.).
class Mark extends Control:
	var _state: PartyPips.State = PartyPips.State.EMPTY

	func set_state(state: PartyPips.State) -> void:
		if state == _state:
			return
		_state = state
		queue_redraw()

	func _draw() -> void:
		match _state:
			PartyPips.State.STATUS:
				var radius := float(UiTokens.PARTY_PIP_MARK)
				var center := size - Vector2.ONE * radius
				draw_circle(center, radius + UiTokens.PARTY_PIP_MARK_BORDER,
					UiTokens.PARTY_PIP_EMPTY_BORDER)
				draw_circle(center, radius, UiTokens.PARTY_PIP_STATUS)
			PartyPips.State.FAINTED:
				var inset := size * UiTokens.PARTY_PIP_STRIKE_INSET
				draw_line(Vector2(inset.x, size.y - inset.y),
					Vector2(size.x - inset.x, inset.y), UiTokens.PARTY_PIP_STRIKE_COLOR,
					UiTokens.PARTY_PIP_STRIKE, true)
