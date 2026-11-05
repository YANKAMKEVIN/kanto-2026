class_name DragonFlightOverlay
extends CanvasLayer
## Le vol sur le Dracolosse de Corentin (arc des Pierres, JOHP3, `jalon-joh-pierres.md` §5.2) :
## plein écran au-dessus du monde, un ciel en dégradé, des nuages qui défilent et l'artwork de
## Dracolosse qui traverse l'écran, dans un sens à l'aller et dans l'autre au retour. Purement
## visuel, sans texte ni entrée : la scène attend [method play], change de carte derrière, et
## l'écran se retire par [method finish] à l'arrivée (étape « dragon_flight »: « land »).
## [member reduce_motion] (« Réduire les animations ») : image fixe, tenue courte. Visuels
## provisoires (règle 3) ; DA en phase DA.

## Artwork officiel de Dracolosse (mémoire « Pokémon art source »).
const DRAGON_TEXTURE: Texture2D = preload("res://assets/sprites/pokemon/official/149.png")
const CLOUDS: int = 7
## Hauteur de l'artwork à l'écran (référence 1080) [D].
const DRAGON_HEIGHT: float = 460.0
const FADE: float = 0.35
const CROSSING: float = 2.6
const REDUCED_HOLD: float = 1.2
## Sens du vol : l'aller va vers la droite, le retour vers la gauche.
const OUT: StringName = &"out"

var reduce_motion: bool = false

var _root: Control
var _dragon: TextureRect
var _clouds: Array[ColorRect] = []


func _ready() -> void:
	layer = 90
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.modulate.a = 0.0
	_root.visible = false
	add_child(_root)
	var sky := TextureRect.new()
	sky.name = "Sky"
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	var gradient := Gradient.new()
	gradient.set_color(0, UiTokens.FLIGHT_SKY_TOP)
	gradient.set_color(1, UiTokens.FLIGHT_SKY_BOTTOM)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	sky.texture = texture
	_root.add_child(sky)
	for i: int in CLOUDS:
		var cloud := ColorRect.new()
		cloud.name = "Cloud%d" % i
		cloud.color = UiTokens.FLIGHT_CLOUD_COLOR
		cloud.size = Vector2(260.0 + 60.0 * (i % 3), 34.0 + 10.0 * (i % 2))
		_root.add_child(cloud)
		_clouds.append(cloud)
	_dragon = TextureRect.new()
	_dragon.name = "Dragon"
	_dragon.texture = DRAGON_TEXTURE
	_dragon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dragon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dragon.size = Vector2(DRAGON_HEIGHT, DRAGON_HEIGHT)
	_root.add_child(_dragon)


## Joue le vol ; coroutine. [param direction] : [constant OUT] (aller) ou tout autre sens (retour).
func play(direction: StringName) -> void:
	var view := _root.get_viewport_rect().size
	var rightward := direction == OUT
	_dragon.flip_h = not rightward
	var from_x := -DRAGON_HEIGHT if rightward else view.x
	var to_x := view.x if rightward else -DRAGON_HEIGHT
	var y := view.y * 0.5 - DRAGON_HEIGHT * 0.5
	_dragon.position = Vector2(view.x * 0.5 - DRAGON_HEIGHT * 0.5 if reduce_motion else from_x, y)
	_place_clouds(view)
	_root.visible = true
	var tween := create_tween()
	tween.tween_property(_root, ^"modulate:a", 1.0, FADE)
	if reduce_motion:
		tween.tween_interval(REDUCED_HOLD)
	else:
		tween.tween_property(_dragon, ^"position:x", to_x, CROSSING) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		for i: int in _clouds.size():
			var cloud := _clouds[i]
			var shift := view.x * (0.5 + 0.1 * (i % 3)) * (-1.0 if rightward else 1.0)
			tween.parallel().tween_property(cloud, ^"position:x", cloud.position.x + shift, CROSSING)
	await tween.finished


## Retire le ciel, une fois la carte d'arrivée en place (l'écran reste opaque jusque-là).
func finish() -> void:
	var tween := create_tween()
	tween.tween_property(_root, ^"modulate:a", 0.0, FADE)
	await tween.finished
	_root.visible = false


func _place_clouds(view: Vector2) -> void:
	for i: int in _clouds.size():
		var step := float(i) / float(_clouds.size())
		_clouds[i].position = Vector2(view.x * fmod(step * 1.7, 1.0), view.y * (0.1 + 0.8 * step))
