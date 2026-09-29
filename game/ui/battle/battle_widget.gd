class_name BattleWidget
extends Control
## Base des composants de l'interface de combat : apparition et disparition animées, échelle
## des durées (tests), retour haptique coupable (tests).
##
## Chaque composant a un enfant unique %Body (ancré en haut à gauche, sans conteneur parent) qui
## porte tout le visuel et prend la taille du composant :
## slide_in le fait glisser de PANEL_SLIDE depuis slide_direction en fondu (ANIM_PANEL), jamais
## d'apparition sèche ; slide_out fait l'inverse (BATTLE_PANEL_CLOSE) puis cache le composant.
## Le composant lui-même reste à sa place (ancres posées par celui qui l'affiche, voir
## BattleHudLayout) : seul %Body se décale pendant l'animation.
## Caché, il est invisible et ne reçoit aucune entrée.

## Vibration demandée (millisecondes), émise même quand haptics_enabled est faux (tests).
signal haptic_played(duration_ms: int)

## Pas de temps qui mène n'importe quelle animation de composant à sa fin (secondes).
const COMPLETE_STEP := 3600.0

## Durées multipliées (0 = instantané, pour les tests).
var speed_scale: float = 1.0
## Faux en test : pas de vibration réelle (haptic_played est quand même émis).
var haptics_enabled: bool = true
## D'où arrive le composant (vecteur unitaire, multiplié par la distance de glissement).
var slide_direction: Vector2 = Vector2.DOWN

## Durées et distance de l'animation (surchargées par les composants qui en ont d'autres).
var _open_time: float = UiTokens.ANIM_PANEL
var _close_time: float = UiTokens.BATTLE_PANEL_CLOSE
var _slide_distance: float = UiTokens.PANEL_SLIDE
var _shown: bool = false
var _slide_tween: Tween

@onready var _body: Control = %Body


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.minimum_size_changed.connect(update_minimum_size)
	resized.connect(_fit_body)
	update_minimum_size()
	_fit_body()
	visible = false
	modulate.a = 0.0


func _get_minimum_size() -> Vector2:
	if _body == null:
		return Vector2.ZERO
	return _body.get_combined_minimum_size()


## Coroutine : fait apparaître le composant (glissement + fondu). Sans effet s'il est déjà
## affiché ou en train d'apparaître.
func slide_in() -> void:
	if _shown:
		return
	_shown = true
	_kill_slide()
	if not visible:
		_body.position = slide_direction * _slide_distance
		modulate.a = 0.0
	visible = true
	await _animate(Vector2.ZERO, 1.0, _open_time, Tween.EASE_OUT)


## Coroutine : fait disparaître le composant (glissement + fondu), puis le cache. Sans effet
## s'il est déjà caché.
func slide_out() -> void:
	if not _shown:
		return
	_shown = false
	_kill_slide()
	await _animate(slide_direction * _slide_distance, 0.0, _close_time, Tween.EASE_IN)


## Affiché ou en train d'apparaître.
func is_shown() -> bool:
	return _shown


## Une animation d'apparition ou de disparition est en cours.
func is_sliding() -> bool:
	return _slide_tween != null and _slide_tween.is_running()


func get_body() -> Control:
	return _body


## Le visuel prend la taille du composant ; sa position reste libre pour le glissement.
func _fit_body() -> void:
	_body.size = size
	_body.pivot_offset = size * 0.5


## Demande une vibration de [param duration_ms] (haptic_played ; vibration si activée).
func _haptic(duration_ms: int) -> void:
	haptic_played.emit(duration_ms)
	if haptics_enabled:
		Input.vibrate_handheld(duration_ms)


func _animate(target: Vector2, alpha: float, duration: float, ease: Tween.EaseType) -> void:
	var time := duration * speed_scale
	if time <= 0.0:
		_finish_slide(target, alpha)
		return
	_slide_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(ease)
	_slide_tween.tween_property(_body, ^"position", target, time)
	_slide_tween.parallel().tween_property(self, ^"modulate:a", alpha, time)
	_slide_tween.tween_callback(_finish_slide.bind(target, alpha))
	await _slide_tween.finished


## Termine tout de suite [param tween] (état final, rappels compris) : ceux qui attendaient
## sa fin reprennent. Les coroutines attendent « finished » du Tween, jamais un signal du
## composant : l'appelant reprend hors de toute émission du composant et peut le libérer
## aussitôt ; si le composant est libéré avant, le Tween disparaît et rien ne reprend.
static func complete_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid() and tween.is_running():
		tween.custom_step(COMPLETE_STEP)


func _finish_slide(target: Vector2, alpha: float) -> void:
	_body.position = target
	modulate.a = alpha
	if alpha <= 0.0:
		visible = false
	_slide_tween = null


## Une nouvelle animation remplace l'ancienne : l'ancienne se termine d'abord (voir
## complete_tween).
func _kill_slide() -> void:
	var previous := _slide_tween
	_slide_tween = null
	complete_tween(previous)
