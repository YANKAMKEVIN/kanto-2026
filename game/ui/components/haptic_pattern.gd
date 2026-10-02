class_name HapticPattern
extends RefCounted
## Motifs de vibration (bible UI/UX §12) : « toc » d'une secousse de la Ball, motif de la capture
## réussie. Un motif alterne vibration et pause, en millisecondes : [30, 70, 30, 70, 120] =
## vibre 30, pause 70, vibre 30, pause 70, vibre 120.
##
## Appelé par celui qui joue la capture (jalon 5D T15) au moment de l'événement : la carte de
## capture n'arrive qu'après. [param sink] reçoit chaque vibration (millisecondes) ; par défaut
## Input.vibrate_handheld. Les tests injectent un espion et passent [param time_scale] à 0 (les
## pauses ne durent pas).


## « Toc » d'une secousse de la Ball (HAPTIC_BALL_SHAKE_MS).
static func ball_shake(sink: Callable = Callable()) -> void:
	_vibrate(sink, UiTokens.HAPTIC_BALL_SHAKE_MS)


## Coroutine : motif de la capture réussie (HAPTIC_CAPTURE).
static func capture(tree: SceneTree, sink: Callable = Callable(), time_scale: float = 1.0) -> void:
	await play(tree, UiTokens.HAPTIC_CAPTURE, sink, time_scale)


## Coroutine : joue [param pattern] (vibration, pause, vibration…). Les vibrations arrivent à
## [param sink] à l'instant voulu ; les pauses sont attendues avec le minuteur de [param tree]
## (aucune attente si [param time_scale] vaut 0).
static func play(tree: SceneTree, pattern: Array[int], sink: Callable = Callable(),
		time_scale: float = 1.0) -> void:
	for i: int in pattern.size():
		var duration := pattern[i]
		if i % 2 == 0:
			_vibrate(sink, duration)
		var last := i == pattern.size() - 1
		if not last and duration > 0 and time_scale > 0.0:
			await tree.create_timer(duration * 0.001 * time_scale).timeout


static func _vibrate(sink: Callable, duration_ms: int) -> void:
	if sink.is_valid():
		sink.call(duration_ms)
	else:
		Input.vibrate_handheld(duration_ms)
