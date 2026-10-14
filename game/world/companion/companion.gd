class_name Companion
extends Node2D
## Le compagnon Pokémon sur la carte (jalon 11, dossier 14 §8 ; `docs/tech/jalon-11-compagnon.md`
## §2.4). Nœud d'affichage seul : il ne décide rien. Le [CompanionTrail] dit où aller, le
## contrôleur du compagnon (T20c, dans Boot) dit quand se montrer et quoi faire.
##
## - N'occupe **pas** la grille (aucun blocage, aucune ligne de vue coupée) ; placé sous
##   `Entities` pour le tri en profondeur, origine aux pieds.
## - Apparence : planche peinte de l'espèce ([CharacterLook], repos et marche × 4).
## - Pas : glisse d'une case à l'autre sur la durée du pas du joueur (marche, course, saut),
##   demi-cycle de `walk_<dir>` comme les PNJ ; saut de rebord en arc ([constant JUMP_ARC_HEIGHT],
##   comme le joueur) ; à moitié caché dans les hautes herbes ([member GrassFront], comme le
##   joueur), sauf en vol (`flying` : sprite levé, ombre au sol).
## - Sortie / rappel : éclat de Ball (grandit / rétrécit dans un blanc) en [constant BURST]
##   ([constant BURST_REDUCED] et un simple fondu avec « Réduire les animations ») [D-6].
## - Bulles « ♪ », « … », « ! » ([EmoteBubble]) et petit saut de joie ([method hop]).
## Au plus 6 nœuds (sprite, ombre, devant de touffe, bulle).

signal step_finished(cell: Vector2i)
signal burst_finished

## Durées (s) [D-6] : éclat de Ball, éclat réduit, petit saut de joie et sa hauteur (px).
const BURST: float = 0.4
const BURST_REDUCED: float = 0.15
const BURST_SCALE: float = 0.2
const BURST_FLASH := Color(2.2, 2.2, 2.2, 1.0)
const HOP: float = 0.25
const HOP_HEIGHT: float = 12.0
## Arc du saut de rebord (comme le joueur) et hauteur de vol (px).
const JUMP_ARC_HEIGHT: float = 48.0
const FLY_HEIGHT: float = 28.0
const SHADOW_REST_Y: float = -6.0
## Part de la hauteur du Pokémon cachée par les hautes herbes : la bande du joueur, plus haute
## qu'un petit Pokémon, le cacherait tout entier (dossier 14 §8.4 : « à moitié caché ») [D].
const GRASS_COVER: float = 0.45
const GRASS_FRONT_BOTTOM: float = 2.0
const SHADOW_TEXTURE: Texture2D = preload(
	"res://assets/sprites/characters/placeholder/shadow.png")
const DEFAULT_GRASS_FRONT: Texture2D = preload(
	"res://assets/sprites/characters/placeholder/grass_front.png")
const _IDLE: Dictionary[Vector2i, StringName] = {
	Vector2i.DOWN: &"idle_down", Vector2i.UP: &"idle_up",
	Vector2i.LEFT: &"idle_left", Vector2i.RIGHT: &"idle_right",
}
const _WALK: Dictionary[Vector2i, StringName] = {
	Vector2i.DOWN: &"walk_down", Vector2i.UP: &"walk_up",
	Vector2i.LEFT: &"walk_left", Vector2i.RIGHT: &"walk_right",
}

## « Réduire les animations » : éclat en simple fondu court.
var reduce_motion: bool = false

var _sprite: AnimatedSprite2D
var _shadow: Sprite2D
var _grass_front: Sprite2D
var _bubble: EmoteBubble
var _grid: GridWorld
var _species: StringName = &""
var _flying: bool = false
var _cell: Vector2i = CompanionTrail.NONE
var _facing: Vector2i = Vector2i.DOWN
var _stride: int = 0
## Pas en cours : départ, arrivée (pixels monde), durée, temps écoulé, saut.
var _moving: bool = false
var _from_pos: Vector2 = Vector2.ZERO
var _to_pos: Vector2 = Vector2.ZERO
var _duration: float = 0.0
var _elapsed: float = 0.0
var _jumping: bool = false
## Apparition différée à la fin d'un pas ([member CompanionTrail.Step.appear]).
var _appear_pending: bool = false
var _lift: float = 0.0
## Hauteur du Pokémon (px affichés), pour couper la bande d'herbe.
var _body_height: float = 64.0
var _burst_tween: Tween
var _hop_tween: Tween


func _init() -> void:
	name = "Companion"
	_shadow = Sprite2D.new()
	_shadow.name = "Shadow"
	_shadow.texture = SHADOW_TEXTURE
	_shadow.position = Vector2(0.0, SHADOW_REST_Y)
	add_child(_shadow)
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Sprite"
	add_child(_sprite)
	_grass_front = Sprite2D.new()
	_grass_front.name = "GrassFront"
	_grass_front.visible = false
	add_child(_grass_front)
	_bubble = EmoteBubble.new()
	_bubble.name = "Bubble"
	add_child(_bubble)
	set_grass_front(null)
	visible = false
	set_process(false)


## Espèce montrée : planche peinte [param sprite] (`pokemon/<espèce>`), en vol si [param flying].
## Faux si la planche n'est pas peinte (aucun substitut, dossier 14 §8.2).
func set_species(species: StringName, sprite: StringName, flying: bool = false) -> bool:
	var look := CharacterLook.resolve(sprite)
	if not look.painted:
		push_error("Companion : planche peinte absente pour « %s »" % sprite)
		return false
	var frames := load(look.frames_path) as SpriteFrames
	if frames == null:
		return false
	_species = species
	_flying = flying
	_sprite.sprite_frames = frames
	_sprite.scale = Vector2(look.scale, look.scale)
	_sprite.texture_filter = look.filter
	var frame := frames.get_frame_texture(_IDLE[Vector2i.DOWN], 0)
	if frame != null:
		_sprite.offset = Vector2(0.0, -frame.get_size().y / 2.0)
		_body_height = frame.get_size().y * look.scale
		_fit_grass_front()
		_bubble.tip_height = maxf(frame.get_size().y * look.scale + 12.0, 64.0)
	_apply_offsets()
	_play_idle()
	return true


## Grille de la carte (hautes herbes).
func set_grid(grid: GridWorld) -> void:
	_grid = grid


## Bande d'herbe de la carte ([member GameMap.grass_front]) ; nulle = la bande provisoire.
func set_grass_front(texture: Texture2D) -> void:
	var painted := texture != null
	var used := texture if painted else DEFAULT_GRASS_FRONT
	_grass_front.texture = used
	_grass_front.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if painted \
		else CanvasItem.TEXTURE_FILTER_NEAREST
	_fit_grass_front()


## Bande d'herbe coupée à [constant GRASS_COVER] de la hauteur du Pokémon (le bas de la bande),
## bas juste sous les pieds.
func _fit_grass_front() -> void:
	var used := _grass_front.texture
	if used == null:
		return
	var height := minf(used.get_height(), _body_height * GRASS_COVER)
	_grass_front.region_enabled = true
	_grass_front.region_rect = Rect2(0.0, used.get_height() - height, used.get_width(), height)
	_grass_front.position = Vector2(0.0, GRASS_FRONT_BOTTOM - height / 2.0)


## Pose le compagnon sur [param cell], tourné vers [param facing], sans animation.
func place(cell: Vector2i, facing: Vector2i) -> void:
	_stop_step()
	_cell = cell
	position = Grid.cell_to_world(cell)
	face(facing)
	_update_grass()


## Se tourne vers [param direction] (cardinale), au repos si aucun pas n'est en cours.
func face(direction: Vector2i) -> void:
	if not Grid.is_cardinal(direction):
		return
	_facing = direction
	if not _moving:
		_play_idle()


## Joue le déplacement [param step] du [CompanionTrail] (durée selon son genre de pas). Une
## apparition ([member CompanionTrail.Step.appear]) se fait à la fin du pas, avec l'éclat.
## Un nouveau pas qui arrive **avant** la fin d'une apparition en attente (le joueur qui marche
## sans s'arrêter enchaîne son pas suivant dans la même image, avant le [method _process] du
## compagnon) la fait d'abord : il sort de sa Ball et marche aussitôt (correctif QA 12A ; il
## restait invisible jusqu'au prochain [method CompanionController.refresh]).
func move(step: CompanionTrail.Step) -> void:
	if _appear_pending and not step.appear:
		_finish_step()
	var duration := pace_duration(step.pace)
	if step.appear:
		_stop_step()
		_cell = step.to_cell
		_appear_pending = true
		_moving = true
		_from_pos = Grid.cell_to_world(step.to_cell)
		_to_pos = _from_pos
		_duration = duration
		_elapsed = 0.0
		_jumping = false
		set_process(true)
		return
	_stop_step()
	var direction := Grid.dominant_direction(step.from_cell, step.to_cell)
	_cell = step.to_cell
	_from_pos = Grid.cell_to_world(step.from_cell)
	_to_pos = Grid.cell_to_world(step.to_cell)
	position = _from_pos
	_duration = duration
	_elapsed = 0.0
	_jumping = step.kind == CompanionTrail.JUMP
	_moving = true
	if direction != Vector2i.ZERO:
		_facing = direction
	_play_walk(step.pace == CompanionTrail.RUN)
	set_process(true)
	_update_grass()


## Durée d'un mouvement au rythme [param pace] (celui du pas du joueur).
static func pace_duration(pace: StringName) -> float:
	match pace:
		CompanionTrail.RUN:
			return Grid.RUN_STEP_DURATION
		CompanionTrail.JUMP:
			return Grid.LEDGE_JUMP_DURATION
	return Grid.WALK_STEP_DURATION


## Coroutine : sort de sa Ball (grandit depuis un éclat blanc) sur sa case ; [param instant] :
## montré tout de suite (fondu du changement de carte qui le couvre).
func appear(instant: bool = false) -> void:
	visible = true
	if instant:
		_reset_burst()
		burst_finished.emit()
		return
	await _burst(true)


## Coroutine : rentre dans sa Ball (rétrécit dans un éclat blanc), puis caché ;
## [param instant] : caché tout de suite.
func withdraw(instant: bool = false) -> void:
	_stop_step()
	_bubble.clear()
	if instant or not visible:
		visible = false
		_reset_burst()
		burst_finished.emit()
		return
	await _burst(false)
	visible = false
	_reset_burst()


## Bulle « ♪ », « … » ou « ! » ([EmoteBubble]).
func show_emote(kind: StringName) -> void:
	_bubble.play(kind)


## Petit saut de joie (enthousiasme) : [constant HOP_HEIGHT] px en [constant HOP] s.
func hop() -> void:
	if _hop_tween != null and _hop_tween.is_valid():
		_hop_tween.kill()
	_hop_tween = create_tween()
	_hop_tween.tween_method(_set_hop, 0.0, 1.0, HOP)
	_hop_tween.tween_callback(_set_hop.bind(0.0))


func get_cell() -> Vector2i:
	return _cell


func get_facing() -> Vector2i:
	return _facing


func get_species() -> StringName:
	return _species


func is_moving() -> bool:
	return _moving


func is_jumping() -> bool:
	return _moving and _jumping


func is_grass_front_visible() -> bool:
	return _grass_front.visible


func get_bubble() -> EmoteBubble:
	return _bubble


func get_sprite() -> AnimatedSprite2D:
	return _sprite


func _process(delta: float) -> void:
	if not _moving:
		set_process(false)
		return
	_elapsed += delta
	var t := clampf(_elapsed / _duration, 0.0, 1.0) if _duration > 0.0 else 1.0
	position = _from_pos.lerp(_to_pos, t).round()
	_lift = 4.0 * JUMP_ARC_HEIGHT * t * (1.0 - t) if _jumping else 0.0
	_apply_offsets()
	if t >= 1.0:
		_finish_step()


func _finish_step() -> void:
	var appearing := _appear_pending
	_moving = false
	_jumping = false
	_appear_pending = false
	_lift = 0.0
	position = Grid.cell_to_world(_cell)
	_apply_offsets()
	_play_idle()
	_update_grass()
	set_process(false)
	# Visible avant le signal (correctif QA 12A) : l'enthousiasme en attente, relié à ce signal
	# par le contrôleur, se joue à l'apparition au lieu d'être perdu.
	if appearing:
		appear()
	step_finished.emit(_cell)


func _stop_step() -> void:
	if not _moving:
		return
	_moving = false
	_jumping = false
	_appear_pending = false
	_lift = 0.0
	position = Grid.cell_to_world(_cell)
	_apply_offsets()
	set_process(false)


## Sortie ([param out] vrai) ou rappel : échelle, blanc, opacité.
func _burst(out: bool) -> void:
	if _burst_tween != null and _burst_tween.is_valid():
		_burst_tween.kill()
	var time := BURST_REDUCED if reduce_motion else BURST
	_burst_tween = create_tween()
	_burst_tween.set_parallel(true)
	if reduce_motion:
		_sprite.scale = Vector2.ONE * _sprite_scale()
		_sprite.modulate = Color(1, 1, 1, 0.0 if out else 1.0)
		_burst_tween.tween_property(_sprite, ^"modulate:a", 1.0 if out else 0.0, time)
	else:
		var small := Vector2.ONE * _sprite_scale() * BURST_SCALE
		var full := Vector2.ONE * _sprite_scale()
		_sprite.scale = small if out else full
		_sprite.modulate = BURST_FLASH if out else Color.WHITE
		_burst_tween.tween_property(_sprite, ^"scale", full if out else small, time) \
			.set_trans(Tween.TRANS_BACK if out else Tween.TRANS_QUAD) \
			.set_ease(Tween.EASE_OUT if out else Tween.EASE_IN)
		_burst_tween.tween_property(_sprite, ^"modulate", Color.WHITE if out else BURST_FLASH,
			time)
	_shadow.modulate.a = 0.0 if out else 1.0
	_burst_tween.tween_property(_shadow, ^"modulate:a", 1.0 if out else 0.0, time)
	await _burst_tween.finished
	if out:
		_reset_burst()
	burst_finished.emit()


func _reset_burst() -> void:
	if _burst_tween != null and _burst_tween.is_valid():
		_burst_tween.kill()
	_sprite.scale = Vector2.ONE * _sprite_scale()
	_sprite.modulate = Color.WHITE
	_shadow.modulate.a = 1.0


func _sprite_scale() -> float:
	return CharacterLook.PAINTED_SCALE


func _set_hop(t: float) -> void:
	_lift = 4.0 * HOP_HEIGHT * t * (1.0 - t)
	_apply_offsets()


## Sprite levé (saut, vol, joie), ombre au sol.
func _apply_offsets() -> void:
	_sprite.position.y = -_lift - (FLY_HEIGHT if _flying else 0.0)
	_shadow.position.y = SHADOW_REST_Y


## Devant de touffe : visible si la case d'arrivée est en hautes herbes, caché pendant un saut
## et en vol.
func _update_grass() -> void:
	_grass_front.visible = not _flying and not _jumping and _grid != null \
		and _grid.is_tall_grass(_cell)


func _play_idle() -> void:
	if _sprite.sprite_frames == null:
		return
	var anim: StringName = _IDLE.get(_facing, &"idle_down")
	if _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)
		_sprite.speed_scale = 1.0


## Un pas = un demi-cycle de `walk_<dir>` ; à la course, animation accélérée (D-3).
func _play_walk(running: bool) -> void:
	if _sprite.sprite_frames == null:
		return
	var anim: StringName = _WALK.get(_facing, &"")
	if not _sprite.sprite_frames.has_animation(anim):
		_play_idle()
		return
	_sprite.play(anim)
	_sprite.speed_scale = Grid.WALK_STEP_DURATION / Grid.RUN_STEP_DURATION if running else 1.0
	var count := _sprite.sprite_frames.get_frame_count(anim)
	_sprite.set_frame_and_progress(_stride * (count / 2), 0.0)
	_stride = 1 - _stride
