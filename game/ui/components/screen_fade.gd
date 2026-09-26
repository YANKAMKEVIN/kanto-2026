class_name ScreenFade
extends CanvasLayer
## Rideau de transition plein écran (calque LAYER_TRANSITION) : fondu au noir entre deux cartes.
##
## Purement visuel : le rideau ignore souris et toucher, les contrôles tactiles du HUD
## continuent donc de suivre le doigt dessous. Il ne connaît ni le joueur ni la carte :
## c'est l'appelant qui attend les fondus (await fade.fade_out()).
## Un fondu demandé pendant un autre remplace le précédent en partant de l'opacité courante
## (aucun saut) ; l'appel interrompu rend alors la main sans émettre son signal.

signal faded_out
signal faded_in
## Fin (ou remplacement) du fondu en cours : c'est ce qu'attendent fade_out et fade_in.
signal _settled

var _tween: Tween
## Incrémenté à chaque fondu demandé : un appel dont le numéro n'est plus le dernier a été
## remplacé.
var _generation: int = 0

@onready var _curtain: ColorRect = %Curtain


func _ready() -> void:
	layer = UiTokens.LAYER_TRANSITION
	_curtain.color = UiTokens.FADE_COLOR
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_alpha(0.0)


## Descend le rideau (opacité 1) ; coroutine : await fade.fade_out().
func fade_out(duration: float = UiTokens.ANIM_FADE_OUT) -> void:
	if await _fade_to(1.0, duration):
		faded_out.emit()


## Lève le rideau (opacité 0) ; coroutine : await fade.fade_in().
func fade_in(duration: float = UiTokens.ANIM_FADE_IN) -> void:
	if await _fade_to(0.0, duration):
		faded_in.emit()


## Rideau opaque ou transparent immédiatement (annule un fondu en cours).
func set_opaque(opaque: bool) -> void:
	_cancel()
	_set_alpha(1.0 if opaque else 0.0)


func is_opaque() -> bool:
	return get_alpha() >= 1.0


## Opacité courante du rideau (0 = transparent, 1 = opaque).
func get_alpha() -> float:
	return _curtain.modulate.a


func get_curtain() -> ColorRect:
	return _curtain


## Anime l'opacité jusqu'à target ; rend vrai si le fondu est allé au bout, faux s'il a été
## remplacé. Avec une durée nulle, l'opacité est posée tout de suite et la main rendue à
## l'image suivante (on peut toujours faire await). On n'attend que _settled, un signal du
## rideau lui-même : si le rideau est libéré en plein fondu, l'appel est abandonné
## proprement (aucune reprise sur une instance disparue).
func _fade_to(target: float, duration: float) -> bool:
	_cancel()
	var generation := _generation
	if duration <= 0.0:
		_set_alpha(target)
		get_tree().process_frame.connect(_emit_settled, CONNECT_ONE_SHOT)
	else:
		_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_method(_set_alpha, get_alpha(), target, duration)
		_tween.finished.connect(_emit_settled)
	await _settled
	return generation == _generation


## Arrête le fondu en cours et rend la main à son appelant (qui voit qu'il a été remplacé).
func _cancel() -> void:
	_generation += 1
	if _tween != null:
		_tween.kill()
		_tween = null
	var tree := get_tree()
	if tree != null and tree.process_frame.is_connected(_emit_settled):
		tree.process_frame.disconnect(_emit_settled)
	_settled.emit()


func _emit_settled() -> void:
	_settled.emit()


## Rideau masqué quand il est transparent : rien à dessiner au repos.
func _set_alpha(alpha: float) -> void:
	_curtain.modulate.a = alpha
	_curtain.visible = alpha > 0.0
