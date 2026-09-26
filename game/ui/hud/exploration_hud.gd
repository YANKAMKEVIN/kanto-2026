class_name ExplorationHud
extends CanvasLayer
## HUD d'exploration (CanvasLayer HUD) : titre de zone, légende sur le monde, joystick
## flottant, bouton courir, bouton contextuel.
##
## Il ne connaît ni le joueur ni la carte : le joystick, le bouton courir et le bouton
## contextuel pressent les actions de l'InputMap (move_*, run, interact) ; la scène qui
## charge la carte appelle show_zone_title, et celle qui connaît la cible devant le joueur
## appelle show_interact(verbe) / hide_interact().
## Placement (aspect expand, 1920 à 2340 de large) : titre ancré en haut à gauche,
## joystick sur tout l'écran (apparition dans la moitié gauche), bouton courir et bouton
## contextuel ancrés au coin bas-droit, légende au milieu du bord haut (sous le titre).

## Le titre de zone vient de disparaître (fin de son maintien ou hide_zone_title()).
signal title_hidden
## La légende vient de disparaître (fin de sa tenue ou hide_caption()).
signal caption_hidden

@onready var _zone_title: ZoneTitle = %ZoneTitle
@onready var _caption: WorldCaption = %WorldCaption
@onready var _joystick: TouchJoystick = %VirtualJoystick
const MOVE_ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right"]

## Verbe demandé pour le bouton contextuel (&"" = aucun) ; affiché si les contrôles le sont.
var _interact_verb: StringName = &""
var _controls_visible: bool = true
var _run_tween: Tween

@onready var _run_button: TouchScreenButton = %RunButton
@onready var _interact_button: InteractButton = %InteractButton


func _ready() -> void:
	layer = UiTokens.LAYER_HUD
	_run_button.position = -UiTokens.RUN_BUTTON_CENTER_FROM_CORNER
	_interact_button.position = -UiTokens.INTERACT_BUTTON_CENTER_FROM_CORNER
	_zone_title.title_hidden.connect(title_hidden.emit)
	_caption.caption_hidden.connect(caption_hidden.emit)


## Filet de sécurité : sans ce relâchement, l'action run resterait pressée si l'application
## perd le focus pendant que le bouton courir est tenu (le joystick gère déjà ses move_*).
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_EXIT_TREE:
			Input.action_release(&"run")
			Input.action_release(&"interact")


## Affiche « NOM / région » en haut à gauche (glissement, maintien, disparition).
func show_zone_title(zone_name: String, region: String) -> void:
	_zone_title.show_title(zone_name, region)


## Masque le titre de zone en ANIM_MICRO (début d'une transition) ; émet title_hidden.
func hide_zone_title() -> void:
	_zone_title.hide_now()


## Pose [param text] sur le monde, en haut au centre (MAJUSCULES, sans rectangle) : fondu,
## tenue CAPTION_HOLD, fondu. Jamais permanente. Indépendante des contrôles.
func show_caption(text: String) -> void:
	_caption.show_caption(text)


## Efface la légende en ANIM_MICRO (changement de carte…) ; émet caption_hidden.
func hide_caption() -> void:
	_caption.hide_now()


## Fait apparaître le bouton contextuel avec [param verb] (&"talk" → PARLER, &"examine" →
## EXAMINER, &"observe" → OBSERVER, &"take" → PRENDRE, &"meet" → RENCONTRER). Pendant un
## dialogue (contrôles cachés), le verbe est retenu et le bouton n'apparaîtra qu'au retour
## des contrôles.
func show_interact(verb: StringName) -> void:
	_interact_verb = verb
	if _controls_visible:
		_interact_button.show_verb(verb)


## Fait disparaître le bouton contextuel (fondu ANIM_MICRO) : plus rien devant le joueur.
func hide_interact() -> void:
	_interact_verb = &""
	_interact_button.hide_verb()


## Cache (false) ou rétablit (true) joystick, bouton courir et bouton contextuel, par exemple
## pendant un dialogue. En les cachant, relâche move_*, run et interact : un doigt resté
## posé ne fait plus rien. Le titre de zone n'est pas concerné.
func set_controls_visible(shown: bool) -> void:
	if shown == _controls_visible:
		return
	_controls_visible = shown
	_joystick.visible = shown
	if _run_tween != null:
		_run_tween.kill()
	if shown:
		_run_button.visible = true
		_run_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_run_tween.tween_property(_run_button, ^"modulate:a", 1.0, UiTokens.ANIM_MICRO)
		if not _interact_verb.is_empty():
			_interact_button.show_verb(_interact_verb)
		return
	_joystick.release()
	_run_button.visible = false
	_run_button.modulate.a = 0.0
	_interact_button.hide_now()
	for action: StringName in MOVE_ACTIONS:
		Input.action_release(action)
	Input.action_release(&"run")
	Input.action_release(&"interact")


func are_controls_visible() -> bool:
	return _controls_visible


func get_zone_title() -> ZoneTitle:
	return _zone_title


func get_caption() -> WorldCaption:
	return _caption


func get_joystick() -> TouchJoystick:
	return _joystick


func get_run_button() -> TouchScreenButton:
	return _run_button


func get_interact_button() -> InteractButton:
	return _interact_button
