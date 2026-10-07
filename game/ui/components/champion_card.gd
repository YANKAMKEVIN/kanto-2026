class_name ChampionCard
extends Control
## Carte de présentation du Champion (jalon 10, T5) : « PIERRE » / « Champion d'Arène
## d'Argenta », posée sur le monde juste avant le combat. Réutilisable pour les 8 Champions.
##
## Verre sombre du combat, liseré ACCENT à gauche, nom en FONT_TITLE gras MAJUSCULES, titre
## en dessous ; aucun portrait. Elle glisse depuis la gauche (CHAMPION_CARD_SLIDE_IN), reste
## CHAMPION_CARD_HOLD, puis ressort (CHAMPION_CARD_SLIDE_OUT) ; un toucher abrège la tenue.
## « Réduire les animations » ([member reduce_motion]) supprime le glissé : fondu court.
## Purement visuelle : ni souris ni toucher ne sont consommés (le toucher est seulement
## observé) ; les entrées hors toucher (souris émulée, clavier) sont ignorées.
## Placement (aspect expand, 1920 à 2340 de large) : plein écran ; carte à SAFE_MARGIN du
## bord gauche, centrée à CHAMPION_CARD_CENTER_Y de la hauteur.

## La carte vient de disparaître (une seule fois par affichage).
signal card_finished

enum Phase { IDLE, SLIDING_IN, HOLDING, SLIDING_OUT }

## Vrai : pas de glissé, un fondu court (ANIM_MICRO) à l'entrée et à la sortie.
var reduce_motion: bool = false

var _phase: Phase = Phase.IDLE
var _skip_hold: bool = false
var _tween: Tween

@onready var _body: PanelContainer = %Body
@onready var _name_label: Label = %NameLabel
@onready var _title_label: Label = %TitleLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.custom_minimum_size.x = UiTokens.CHAMPION_CARD_MIN_WIDTH
	_body.get_node(^"Lines").add_theme_constant_override(&"separation",
		UiTokens.CHAMPION_CARD_LINE_GAP)
	visible = false
	set_process_input(false)


func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch == null or not touch.pressed:
		return
	skip_hold()


## Affiche la carte : [param champion_name] (mis en MAJUSCULES) et [param title].
## Déjà affichée, elle repart de zéro (le signal de la précédente n'est pas émis).
func show_card(champion_name: String, title: String) -> void:
	if champion_name.is_empty() or title.is_empty():
		push_warning("ChampionCard : nom ou titre vide.")
	_kill()
	_name_label.text = champion_name.to_upper()
	_title_label.text = title
	UiPrefsApplier.apply(_body)
	_body.reset_size()
	_skip_hold = false
	visible = true
	set_process_input(true)
	_phase = Phase.SLIDING_IN
	var rest := _rest_position()
	_body.position = rest
	_body.modulate.a = 0.0
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if reduce_motion:
		_tween.tween_property(_body, ^"modulate:a", 1.0, UiTokens.ANIM_MICRO)
	else:
		_body.position = Vector2(-_body.size.x, rest.y)
		_tween.tween_property(_body, ^"position:x", rest.x, UiTokens.CHAMPION_CARD_SLIDE_IN)
		_tween.parallel().tween_property(_body, ^"modulate:a", 1.0,
			UiTokens.CHAMPION_CARD_SLIDE_IN)
	_tween.tween_callback(_begin_hold)


## Abrège la tenue : la carte ressort tout de suite (ou dès la fin de l'entrée).
## Sans effet quand elle est déjà en sortie ou cachée.
func skip_hold() -> void:
	match _phase:
		Phase.SLIDING_IN:
			_skip_hold = true
		Phase.HOLDING:
			_begin_out()


func is_showing() -> bool:
	return _phase != Phase.IDLE


func get_phase() -> Phase:
	return _phase


func get_name_text() -> String:
	return _name_label.text


func get_title_text() -> String:
	return _title_label.text


func get_body() -> PanelContainer:
	return _body


func _rest_position() -> Vector2:
	var screen_h := size.y if size.y > 0.0 else get_viewport_rect().size.y
	return Vector2(UiTokens.SAFE_MARGIN,
		screen_h * UiTokens.CHAMPION_CARD_CENTER_Y - _body.size.y * 0.5)


func _begin_hold() -> void:
	if _skip_hold:
		_begin_out()
		return
	_phase = Phase.HOLDING
	_tween = create_tween()
	_tween.tween_interval(UiTokens.CHAMPION_CARD_HOLD)
	_tween.tween_callback(_begin_out)


func _begin_out() -> void:
	_kill_tween()
	_phase = Phase.SLIDING_OUT
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if reduce_motion:
		_tween.tween_property(_body, ^"modulate:a", 0.0, UiTokens.ANIM_MICRO)
	else:
		_tween.tween_property(_body, ^"position:x", -_body.size.x,
			UiTokens.CHAMPION_CARD_SLIDE_OUT)
		_tween.parallel().tween_property(_body, ^"modulate:a", 0.0,
			UiTokens.CHAMPION_CARD_SLIDE_OUT)
	_tween.tween_callback(_on_hidden)


func _on_hidden() -> void:
	_phase = Phase.IDLE
	visible = false
	set_process_input(false)
	card_finished.emit()


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


func _kill() -> void:
	_kill_tween()
	_phase = Phase.IDLE
