class_name MenuScreen
extends Control
## Base des écrans du Menu Dresseur (jalon-06.md §6.5) : un panneau plein cadre dans l'hôte
## de [TrainerMenu], qui entre en glissant de PANEL_SLIDE depuis le bas en fondu (MENU_OPEN) et
## ressort en fondu (MENU_CLOSE). Un écran ne connaît ni l'état de la partie ni les données :
## il reçoit des vues et émet des signaux.

## Lien croisé vers un autre écran (6A+).
signal route_requested(route: MenuRoute)
## Retour demandé (bouton RETOUR de l'écran).
signal back_requested

## Vrai : l'écran occupe aussi la rangée du × (le Pokédex y met son en-tête) ; l'hôte cache
## alors la pastille de zone. L'écran lui laisse la place du × à gauche.
var covers_header: bool = false
## Voile et flou du fond du menu propres à l'écran (négatif : ceux du menu, MENU_DIM et
## MENU_BLUR_RADIUS). Le Pokédex éclaircit le fond pour ses panneaux de verre.
var backdrop_dim: float = -1.0
var backdrop_blur: float = -1.0
var backdrop_lod: float = -1.0
## Durées multipliées (0 = instantané, pour les tests).
var speed_scale: float = 1.0

var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Coroutine : fait apparaître l'écran (glissement + fondu), qu'il soit caché ou non.
func enter() -> void:
	_kill_tween()
	visible = true
	var time := UiTokens.MENU_OPEN * speed_scale
	if time <= 0.0:
		modulate.a = 1.0
		position = Vector2.ZERO
		return
	modulate.a = 0.0
	position = Vector2(0.0, UiTokens.PANEL_SLIDE)
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"modulate:a", 1.0, time)
	_tween.tween_property(self, ^"position", Vector2.ZERO, time)
	await _tween.finished


## Coroutine : fait disparaître l'écran en fondu ; il est invisible à la fin.
func leave() -> void:
	_kill_tween()
	var time := UiTokens.MENU_CLOSE * speed_scale
	if time > 0.0 and visible:
		_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, ^"modulate:a", 0.0, time)
		await _tween.finished
	modulate.a = 0.0
	visible = false


## Cache l'écran tout de suite, sans animation.
func hide_now() -> void:
	_kill_tween()
	modulate.a = 0.0
	visible = false


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
