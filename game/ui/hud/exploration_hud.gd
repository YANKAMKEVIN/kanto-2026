class_name ExplorationHud
extends CanvasLayer
## HUD d'exploration (CanvasLayer HUD) : titre de zone, joystick flottant, bouton courir.
##
## Il ne connaît ni le joueur ni la carte : le joystick et le bouton courir pressent les
## actions de l'InputMap (move_*, run) que le joueur interroge ; la scène qui charge la
## carte appelle show_zone_title.
## Placement (aspect expand, 1920 à 2340 de large) : titre ancré en haut à gauche,
## joystick sur tout l'écran (apparition dans la moitié gauche), bouton courir ancré
## au coin bas-droit.

@onready var _zone_title: ZoneTitle = %ZoneTitle
@onready var _joystick: TouchJoystick = %VirtualJoystick
@onready var _run_button: TouchScreenButton = %RunButton


func _ready() -> void:
	layer = UiTokens.LAYER_HUD
	_run_button.position = -UiTokens.RUN_BUTTON_CENTER_FROM_CORNER


## Filet de sécurité : sans ce relâchement, l'action run resterait pressée si l'application
## perd le focus pendant que le bouton courir est tenu (le joystick gère déjà ses move_*).
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_EXIT_TREE:
			Input.action_release(&"run")


## Affiche « NOM / région » en haut à gauche (glissement, maintien, disparition).
func show_zone_title(zone_name: String, region: String) -> void:
	_zone_title.show_title(zone_name, region)


func get_zone_title() -> ZoneTitle:
	return _zone_title


func get_joystick() -> TouchJoystick:
	return _joystick


func get_run_button() -> TouchScreenButton:
	return _run_button
