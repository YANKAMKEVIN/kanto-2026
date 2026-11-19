class_name FlyCarrier
extends Node2D
## Le Pokémon qui porte le joueur pendant le Vol (remarque de Kevin sur S24, 2026-11-19 : « on
## apparaît et disparaît juste ») : posé au-dessus de la tête du joueur, enfant du joueur, il sort
## de sa Ball, bat doucement des ailes (balancement), puis rentre à l'atterrissage.
## Visuel : la planche peinte de l'espèce si elle existe (`pokemon/<espèce>`), sinon son artwork
## officiel resserré (visuels provisoires, règle 3 ; DA en phase DA).

## Hauteur affichée de l'artwork officiel (px de référence) [D].
const ARTWORK_HEIGHT: float = 190.0
## Le porteur vole au-dessus de la tête du joueur (128 px) [D].
const ABOVE_HEAD: float = 150.0
## Balancement : amplitude (px) et période (s) [D].
const BOB_HEIGHT: float = 10.0
const BOB_PERIOD: float = 0.7
## Sortie et retour dans la Ball (s) [D].
const POP_SECONDS: float = 0.25

## Hauteur de vol commune avec le joueur ([member Player.flight_lift]) : posée par le Vol.
var lift: float = 0.0:
	set(value):
		lift = value
		_place(_bob())

var _visual: Node2D
var _time: float = 0.0


func _init() -> void:
	name = "FlyCarrier"
	z_index = 1
	visible = false
	set_process(false)


## Prépare le visuel de [param species] : planche peinte si elle existe, sinon [param artwork].
## Faux si rien ne peut être montré (le Vol se joue alors sans porteur).
func set_species(species: StringName, artwork: Texture2D) -> bool:
	if _visual != null:
		_visual.queue_free()
		_visual = null
	var look := CharacterLook.resolve(StringName("pokemon/%s" % species))
	if look.painted:
		var frames := load(look.frames_path) as SpriteFrames
		if frames != null:
			var sprite := AnimatedSprite2D.new()
			sprite.sprite_frames = frames
			sprite.texture_filter = look.filter
			for anim: StringName in [&"idle_down", &"idle"]:
				if frames.has_animation(anim):
					sprite.play(anim)
					break
			var frame := frames.get_frame_texture(sprite.animation, 0)
			if frame != null:
				sprite.offset = Vector2(0.0, -frame.get_size().y / 2.0)
			_visual = sprite
	if _visual == null and artwork != null:
		var image := Sprite2D.new()
		image.texture = artwork
		image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var height := maxf(artwork.get_size().y, 1.0)
		image.scale = Vector2.ONE * (ARTWORK_HEIGHT / height)
		image.offset = Vector2(0.0, -height / 2.0)
		_visual = image
	if _visual == null:
		return false
	_visual.name = "Visual"
	add_child(_visual)
	return true


func has_visual() -> bool:
	return _visual != null


## Sort de la Ball au-dessus du joueur (coroutine).
func pop_out() -> void:
	if _visual == null:
		return
	visible = true
	_time = 0.0
	set_process(true)
	_place(0.0)
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, ^"scale", Vector2.ONE, POP_SECONDS) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


## Rentre dans la Ball (coroutine).
func pop_in() -> void:
	if not visible:
		return
	var tween := create_tween()
	tween.tween_property(self, ^"scale", Vector2.ZERO, POP_SECONDS) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	hide_now()


## Montré tout de suite, sans sortie de Ball (arrivée : il descend déjà avec le joueur).
func show_now() -> void:
	if _visual == null:
		return
	visible = true
	scale = Vector2.ONE
	_time = 0.0
	set_process(true)
	_place(0.0)


func hide_now() -> void:
	visible = false
	scale = Vector2.ONE
	set_process(false)


func _process(delta: float) -> void:
	_time += delta
	_place(_bob())


func _bob() -> float:
	return sin(_time / BOB_PERIOD * TAU) * BOB_HEIGHT


func _place(bob: float) -> void:
	position = Vector2(0.0, -ABOVE_HEAD - lift - bob)
