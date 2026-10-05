class_name HealMachine
extends Node2D
## Machine de soin du comptoir d'un Centre Pokémon (dossier 09 §7 ; jalon-07.md §6.3).
##
## Posée par l'outil de construction de la carte dans `Entities`, juste devant le comptoir peint
## (le plateau à six alvéoles fait partie de l'image du comptoir) et nommée `%HealMachine`. Elle
## ne dessine que la lumière du rituel : six alvéoles qui s'allument une à une, puis un éclat.
## Les lumières et l'[AnimationPlayer] « heal » sont construits dans [method _ready] (aucune
## image : halos radiaux en mélange additif), pour que la scène reste une simple donnée de carte.
##
## [method play_heal] joue le rituel à la durée demandée (UiTokens.CENTER_HEAL, ×0,5 avec
## « Réduire les animations ») ; [signal flashed] marque l'éclat (vibration). Seules les
## alvéoles de l'équipe s'allument (Rouge/Bleu : une Poké Ball par Pokémon).

## L'éclat final : moment de la vibration.
signal flashed

const ANIMATION: StringName = &"heal"
## Durée de l'animation telle qu'elle est écrite ; [method play_heal] l'étire.
const BASE_DURATION: float = 3.0
const SLOT_COUNT: int = 6
## Allumage de chaque alvéole (s, sur BASE_DURATION) ; montée de SLOT_RISE.
const SLOT_TIMES: Array[float] = [0.35, 0.65, 0.95, 1.25, 1.55, 1.85]
const SLOT_RISE: float = 0.12
## Éclat : montée, sommet, retombée.
const FLASH_START: float = 2.15
const FLASH_PEAK: float = 2.3
const FLASH_END: float = 2.75
## Les alvéoles s'éteignent avec l'éclat.
const SLOTS_OFF: float = 2.6
const SLOT_COLOR := Color(1.0, 0.86, 0.92, 0.95)
const FLASH_COLOR := Color(1.0, 0.97, 0.9, 0.9)
## Taille des halos (px) : alvéole (ellipse aplatie, vue de trois quarts) et éclat.
const SLOT_SIZE := Vector2(26.0, 16.0)
const FLASH_SIZE := Vector2(190.0, 130.0)
const _GLOW_TEXTURE_SIZE: int = 64

## Alvéoles, relatives à l'origine (pixels du monde), dans l'ordre d'allumage.
@export var slot_offsets: Array[Vector2] = []
## Centre de l'éclat, relatif à l'origine.
@export var flash_offset: Vector2 = Vector2.ZERO
## PNJ qui sert la machine (il se tourne vers elle pendant le rituel) et vers où il se tourne.
@export var attendant: StringName = &"nurse"
@export var attendant_turn: Vector2i = Vector2i.RIGHT

var _slots: Array[Sprite2D] = []
var _flash: Sprite2D
var _animator: AnimationPlayer
var _playing: bool = false


func _ready() -> void:
	_build()


## Joue le rituel en [param duration] secondes, [param count] alvéoles allumées (1 à 6).
## Coroutine : rend la main à la fin de l'animation.
func play_heal(duration: float, count: int) -> void:
	if _animator == null:
		_build()
	for i: int in _slots.size():
		_slots[i].visible = i < clampi(count, 1, SLOT_COUNT)
	_animator.speed_scale = BASE_DURATION / maxf(duration, 0.05)
	_playing = true
	_animator.stop()
	_animator.play(ANIMATION)
	await _animator.animation_finished
	_playing = false


func is_playing() -> bool:
	return _playing


func get_animation_player() -> AnimationPlayer:
	return _animator


## Alvéoles (tests, capture).
func get_slots() -> Array[Sprite2D]:
	return _slots


func _build() -> void:
	if _animator != null:
		return
	var glow := _glow_texture()
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i: int in mini(slot_offsets.size(), SLOT_COUNT):
		var slot := _halo("Slot%d" % i, glow, additive, SLOT_SIZE, SLOT_COLOR)
		slot.position = slot_offsets[i]
		_slots.append(slot)
	_flash = _halo("Flash", glow, additive, FLASH_SIZE, FLASH_COLOR)
	_flash.position = flash_offset
	_animator = AnimationPlayer.new()
	_animator.name = "Animator"
	add_child(_animator)
	var library := AnimationLibrary.new()
	library.add_animation(ANIMATION, _heal_animation())
	_animator.add_animation_library(&"", library)


func _halo(halo_name: String, texture: Texture2D, mat: Material, size: Vector2,
		color: Color) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = halo_name
	sprite.texture = texture
	sprite.material = mat
	sprite.scale = size / float(_GLOW_TEXTURE_SIZE)
	sprite.self_modulate = color
	sprite.modulate = Color(1, 1, 1, 0)
	add_child(sprite)
	return sprite


## Halo radial blanc → transparent, teinté par self_modulate.
static func _glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.45, Color(1, 1, 1, 0.75))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = _GLOW_TEXTURE_SIZE
	texture.height = _GLOW_TEXTURE_SIZE
	return texture


func _heal_animation() -> Animation:
	var animation := Animation.new()
	animation.length = BASE_DURATION
	for i: int in _slots.size():
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath("%s:modulate" % _slots[i].name))
		var on: float = SLOT_TIMES[i]
		animation.track_insert_key(track, 0.0, Color(1, 1, 1, 0))
		animation.track_insert_key(track, on, Color(1, 1, 1, 0))
		animation.track_insert_key(track, on + SLOT_RISE, Color(1, 1, 1, 1))
		animation.track_insert_key(track, SLOTS_OFF, Color(1, 1, 1, 1))
		animation.track_insert_key(track, FLASH_END, Color(1, 1, 1, 0))
	var flash := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(flash, NodePath("Flash:modulate"))
	animation.track_insert_key(flash, 0.0, Color(1, 1, 1, 0))
	animation.track_insert_key(flash, FLASH_START, Color(1, 1, 1, 0))
	animation.track_insert_key(flash, FLASH_PEAK, Color(1, 1, 1, 1))
	animation.track_insert_key(flash, FLASH_END, Color(1, 1, 1, 0))
	var grow := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(grow, NodePath("Flash:scale"))
	var base := FLASH_SIZE / float(_GLOW_TEXTURE_SIZE)
	animation.track_insert_key(grow, 0.0, base * 0.6)
	animation.track_insert_key(grow, FLASH_START, base * 0.6)
	animation.track_insert_key(grow, FLASH_END, base * 1.15)
	var beat := animation.add_track(Animation.TYPE_METHOD)
	animation.track_set_path(beat, NodePath("."))
	animation.track_insert_key(beat, FLASH_PEAK, {"method": &"_on_flash", "args": []})
	return animation


func _on_flash() -> void:
	flashed.emit()
