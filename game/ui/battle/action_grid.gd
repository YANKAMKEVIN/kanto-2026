class_name ActionGrid
extends BattleWidget
## Grille des 4 actions de combat, 2 × 2, en bas à droite (combat-v1, dossier 05 §6) :
## ATTAQUER (rouge) · SAC (or) · ÉQUIPE (bleu) · FUITE (gris sombre), icône blanche à gauche.
##
## ATTAQUER est l'action visuellement dominante : une lueur d'accent l'entoure et pulse
## doucement (dossier 05 §18, « le jeu montre subtilement ATTAQUER »). Une action indisponible
## est atténuée (styles « disabled » du thème) et n'émet ni signal ni vibration.
## Un toucher = un action_selected (souris émulée depuis le toucher sur le téléphone, souris
## réelle sur Mac : seul le bouton, piloté par la souris, compte) ; après un choix, la grille
## n'émet plus rien jusqu'au prochain show_actions (pas de double choix).

## Action choisie : &"attack", &"bag", &"team" ou &"run".
signal action_selected(action: StringName)

const ATTACK := &"attack"
const BAG := &"bag"
const TEAM := &"team"
const RUN := &"run"
## Ordre de la grille (ligne par ligne) et libellés (textes d'interface).
const ACTIONS: Array[StringName] = [ATTACK, BAG, TEAM, RUN]
const LABELS: Dictionary[StringName, String] = {
	ATTACK: "ATTAQUER", BAG: "SAC", TEAM: "ÉQUIPE", RUN: "FUITE",
}
const ICONS: Dictionary[StringName, Texture2D] = {
	ATTACK: preload("res://assets/ui/icons/battle/attack.svg"),
	BAG: preload("res://assets/ui/icons/battle/bag.svg"),
	TEAM: preload("res://assets/ui/icons/battle/team.svg"),
	RUN: preload("res://assets/ui/icons/battle/run.svg"),
}

var _buttons: Dictionary[StringName, Button] = {}
var _answered: bool = false
var _glow_tween: Tween
var _press_tweens: Dictionary[Button, Tween] = {}

@onready var _grid: GridContainer = %Body
@onready var _glow: Panel = %Glow


func _ready() -> void:
	super._ready()
	_grid.add_theme_constant_override(&"h_separation", UiTokens.BATTLE_ACTION_GAP)
	_grid.add_theme_constant_override(&"v_separation", UiTokens.BATTLE_ACTION_GAP)
	var nodes: Dictionary[StringName, Button] = {
		ATTACK: %Attack, BAG: %Bag, TEAM: %Team, RUN: %Run,
	}
	for action: StringName in ACTIONS:
		var button: Button = nodes[action]
		button.text = LABELS[action]
		button.icon = ICONS[action]
		button.custom_minimum_size = UiTokens.BATTLE_ACTION_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_pressed.bind(action))
		button.button_down.connect(_press_feedback.bind(button, true))
		button.button_up.connect(_press_feedback.bind(button, false))
		_buttons[action] = button
	show_actions({})


## Montre la grille (glissement + fondu si elle était cachée) avec les actions disponibles
## [param enabled] (action → vrai ; une action absente est indisponible) ; réarme la grille
## après un choix.
func show_actions(enabled: Dictionary[StringName, bool]) -> void:
	_answered = false
	for action: StringName in ACTIONS:
		_buttons[action].disabled = not enabled.get(action, false)
		_buttons[action].scale = Vector2.ONE
	_set_glow(not _buttons[ATTACK].disabled)
	if is_node_ready() and not enabled.is_empty():
		slide_in()


## Bouton de [param action] (&"attack"…), pour les tests et le placement.
func get_button(action: StringName) -> Button:
	return _buttons.get(action, null)


func is_action_enabled(action: StringName) -> bool:
	return _buttons.has(action) and not _buttons[action].disabled


## La lueur d'ATTAQUER est affichée et pulse.
func is_attack_glowing() -> bool:
	return _glow.visible and _glow_tween != null


func _on_pressed(action: StringName) -> void:
	if _answered or not _shown or _buttons[action].disabled:
		return
	_answered = true
	_haptic(UiTokens.HAPTIC_TAP_MS)
	action_selected.emit(action)


## Lueur d'accent d'ATTAQUER, qui pulse doucement (boucle à durée réelle, jamais nulle).
func _set_glow(on: bool) -> void:
	if _glow_tween != null:
		_glow_tween.kill()
		_glow_tween = null
	_glow.visible = on
	_glow.modulate.a = 1.0
	if not on:
		return
	_glow_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	_glow_tween.tween_property(_glow, ^"modulate:a", UiTokens.ACTION_GLOW_MIN,
		UiTokens.ACTION_GLOW_PULSE)
	_glow_tween.tween_property(_glow, ^"modulate:a", 1.0, UiTokens.ACTION_GLOW_PULSE)


## Légère mise à l'échelle à l'appui (PRESSED_SCALE), retour au relâchement.
func _press_feedback(button: Button, down: bool) -> void:
	var previous: Tween = _press_tweens.get(button, null)
	if previous != null:
		previous.kill()
	button.pivot_offset = button.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target := Vector2.ONE * (UiTokens.PRESSED_SCALE if down else 1.0)
	tween.tween_property(button, ^"scale", target, UiTokens.ANIM_MICRO)
	_press_tweens[button] = tween
