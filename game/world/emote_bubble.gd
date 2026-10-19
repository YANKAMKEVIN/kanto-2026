class_name EmoteBubble
extends Node2D
## Bulle au-dessus d'un personnage (jalon 11, compagnon ; reprend la bulle « ! » des Dresseurs
## de [method Npc.show_emote]) : apparition en rebond, tenue, fondu, en [Tween] ; dessinée
## au-dessus du tri en profondeur ; gardée entière dans la vue ([EmotePlacement]). Icônes
## d'interface (SVG, pas de pixel art) : « ! », « ♪ », « … ». Placer le nœud aux pieds du
## personnage ; la pointe se pose à [constant UiTokens.EMOTE_TIP_HEIGHT] au-dessus.

signal finished

const EXCLAIM: StringName = &"exclaim"
const NOTE: StringName = &"note"
const DOTS: StringName = &"dots"
const ICONS: Dictionary[StringName, Texture2D] = {
	EXCLAIM: preload("res://assets/ui/icons/emote_exclamation.svg"),
	NOTE: preload("res://assets/ui/icons/emote_note.svg"),
	DOTS: preload("res://assets/ui/icons/emote_dots.svg"),
}

var _icon: Sprite2D
var _tween: Tween


## Hauteur de la pointe au-dessus des pieds (px) ; par défaut celle des personnages.
var tip_height: float = UiTokens.EMOTE_TIP_HEIGHT


## Montre la bulle [param kind] ([constant ICONS]) ; [signal finished] à la fin. Hors de l'arbre :
## finie tout de suite.
func play(kind: StringName) -> void:
	clear()
	if not is_inside_tree() or not ICONS.has(kind):
		finished.emit()
		return
	var tip := Vector2(0.0, -tip_height) + _view_shift()
	_icon = Sprite2D.new()
	_icon.name = "Icon"
	_icon.texture = ICONS[kind]
	_icon.centered = false
	_icon.offset = -Npc.EMOTE_TIP_IN_ICON
	# Au-dessus du voile d'obscurité et des cimes (J17 T9 / J18 §2.2) : un signe d'interface.
	_icon.z_as_relative = false
	_icon.z_index = WorldLighting.Z_ABOVE_VEIL
	_icon.position = tip + Vector2(0.0, UiTokens.EMOTE_RISE)
	_icon.scale = Vector2.ZERO
	_icon.modulate.a = 0.0
	add_child(_icon)
	var full := Vector2.ONE * UiTokens.EMOTE_SCALE
	var pop := UiTokens.EMOTE_POP
	var fade := UiTokens.EMOTE_FADE
	var hold := maxf(0.0, UiTokens.EMOTE_DURATION - pop - fade)
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_icon, "scale", full, pop).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	_tween.tween_property(_icon, "position", tip, pop).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	_tween.tween_property(_icon, "modulate:a", 1.0, pop * 0.5)
	_tween.chain().tween_interval(hold)
	_tween.chain().tween_property(_icon, "modulate:a", 0.0, fade)
	_tween.chain().tween_callback(_finish)


## Vrai pendant une bulle.
func is_playing() -> bool:
	return _tween != null and _tween.is_valid()


## Icône affichée (tests, captures) ; null sans bulle.
func get_icon() -> Texture2D:
	return _icon.texture if _icon != null and is_instance_valid(_icon) else null


## Retire la bulle tout de suite.
func clear() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if _icon != null and is_instance_valid(_icon):
		remove_child(_icon)
		_icon.queue_free()
	_icon = null


func _finish() -> void:
	_tween = null
	clear()
	finished.emit()


func _view_shift() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return Vector2.ZERO
	var tip_screen := get_global_transform_with_canvas() * Vector2(0.0, -tip_height)
	var k := UiTokens.EMOTE_SCALE * UiTokens.EMOTE_OVERSHOOT
	var tip_icon := Npc.EMOTE_TIP_IN_ICON
	var extent := Rect2(
		Vector2(tip_icon.x - Npc.EMOTE_BODY_LEFT, tip_icon.y - Npc.EMOTE_BODY_TOP) * k,
		Vector2(Npc.EMOTE_BODY_RIGHT - tip_icon.x, 0.0) * k)
	return EmotePlacement.shift(tip_screen, viewport.get_visible_rect().size, extent,
		float(UiTokens.SAFE_MARGIN))
