class_name ScreenFlash
extends ColorRect
## Éclair plein écran (docs/tech/jalon-14.md §2.7 : la machine de Léo, étape de scène
## « flash »), tenu par [ExplorationHud], sous le rideau de transition.
##
## Purement visuel : il ignore souris et toucher (les contrôles tactiles dessous restent
## utilisables) et ne connaît ni la scène ni la carte. Un éclair : opacité 0 →
## [constant UiTokens.FLASH_ALPHA] → 0 en [method duration_of] (montée, tenue, descente),
## [constant UiTokens.FLASH_GAP] entre deux éclairs, vibration légère
## [constant UiTokens.HAPTIC_FLASH_MS] au début de chacun ([Haptics] : rien si les vibrations
## sont coupées). [member reduced] (« Réduire les animations » ou « Réduire les flashs ») :
## fondu doux, opacité au plus [constant UiTokens.FLASH_REDUCED_ALPHA] en
## [constant UiTokens.FLASH_REDUCED_DURATION].
## Attente par un tween (temps simulable en test). Un éclair demandé pendant un autre le
## remplace (l'appel précédent rend la main).

## Fin des éclairs (ou remplacement par un nouvel appel à [method play]).
signal flash_finished

## Version adoucie (réglages « Réduire les animations » ou « Réduire les flashs »).
var reduced: bool = false

var _tween: Tween


func _ready() -> void:
	color = UiTokens.FLASH_COLOR
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_alpha(0.0)


## Durée de [param count] éclairs (écarts compris), en secondes.
static func duration_of(count: int, is_reduced: bool) -> float:
	var one := UiTokens.FLASH_REDUCED_DURATION if is_reduced \
		else UiTokens.FLASH_RISE + UiTokens.FLASH_HOLD + UiTokens.FLASH_FALL
	var flashes := maxi(count, 1)
	return one * flashes + UiTokens.FLASH_GAP * (flashes - 1)


## Joue [param count] éclairs (au moins un) ; coroutine : await flash.play(2).
func play(count: int) -> void:
	_stop()
	var peak := UiTokens.FLASH_REDUCED_ALPHA if reduced else UiTokens.FLASH_ALPHA
	_tween = create_tween()
	for i: int in maxi(count, 1):
		if i > 0:
			_tween.tween_interval(UiTokens.FLASH_GAP)
		_tween.tween_callback(_vibrate)
		if reduced:
			var half := UiTokens.FLASH_REDUCED_DURATION * 0.5
			_tween.tween_method(_set_alpha, 0.0, peak, half).set_trans(Tween.TRANS_SINE)
			_tween.tween_method(_set_alpha, peak, 0.0, half).set_trans(Tween.TRANS_SINE)
		else:
			_tween.tween_method(_set_alpha, 0.0, peak, UiTokens.FLASH_RISE)
			_tween.tween_interval(UiTokens.FLASH_HOLD)
			_tween.tween_method(_set_alpha, peak, 0.0, UiTokens.FLASH_FALL) \
				.set_ease(Tween.EASE_OUT)
	_tween.finished.connect(_on_finished)
	await flash_finished


func is_playing() -> bool:
	return _tween != null


## Opacité courante de l'éclair (0 = invisible).
func get_alpha() -> float:
	return modulate.a


## Arrête un éclair en cours (opacité nulle) et rend la main à son appelant.
func _stop() -> void:
	if _tween == null:
		return
	_tween.kill()
	_tween = null
	_set_alpha(0.0)
	flash_finished.emit()


func _on_finished() -> void:
	_tween = null
	_set_alpha(0.0)
	flash_finished.emit()


func _vibrate() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_FLASH_MS)


## Masqué quand il est transparent : rien à dessiner au repos.
func _set_alpha(alpha: float) -> void:
	modulate.a = alpha
	visible = alpha > 0.0
