class_name Player
extends Node2D
## Joueur dans le monde : présentation et relais d'entrée (logique dans [GridMover]).
##
## Lit les actions `move_*` et `run` dans [method _process] (Input.is_action_pressed) :
## clavier, joystick tactile (Input.action_press) et tests passent par le même chemin.
## Origine aux pieds ; la caméra enfant suit, zoom 1, bornée à la carte ; une carte plus
## petite que l'écran est centrée ([CameraFraming]).
## [method set_input_enabled] bloque les entrées pour une raison (transition de carte,
## dialogue, plus tard scène scriptée) : le pas en cours se termine, aucun autre ne part. Le
## joueur est libre quand plus aucune raison n'est active (docs/tech/jalon-03.md §2.8).

signal moved(cell: Vector2i)
signal facing_changed(direction: Vector2i)
signal bumped(direction: Vector2i)

## Groupe qui permet au décor de retrouver le joueur (transparence des feuillages).
const GROUP: StringName = &"player"
## Taille affichée du personnage (32×64 natif, ×2), bas-centre sur l'origine.
const BODY_SIZE := Vector2(64, 128)
## Vitesse de l'animation de marche sur place contre un obstacle.
const BUMP_ANIM_SPEED: float = 0.5
## Hauteur de l'arc du saut de rebord (px monde) : le sprite s'élève, l'ombre reste au sol.
const JUMP_ARC_HEIGHT: float = 48.0
## Repos de l'ombre (px monde), comme dans la scène.
const SHADOW_REST_Y: float = -6.0
## Raison de blocage par défaut : celle du routeur de scènes (changement de carte).
const REASON_TRANSITION: StringName = &"transition"
## Animations par direction : [immobile, marche, course].
const _ANIMS: Dictionary[Vector2i, Array] = {
	Vector2i.DOWN: [&"idle_down", &"walk_down", &"run_down"],
	Vector2i.UP: [&"idle_up", &"walk_up", &"run_up"],
	Vector2i.LEFT: [&"idle_left", &"walk_left", &"run_left"],
	Vector2i.RIGHT: [&"idle_right", &"walk_right", &"run_right"],
}

var _grid: GridWorld
var _mover: GridMover
var _input := DirectionInput.new()
var _bump_direction: Vector2i = Vector2i.ZERO
## Raisons de blocage actives (raison → vrai) ; vide = entrées libres.
var _block_reasons: Dictionary[StringName, bool] = {}
## Rectangle monde de la carte courante (recalcul des limites si la vue change).
var _map_bounds: Rect2i = Rect2i()

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _camera: Camera2D = %Camera
@onready var _shadow: Sprite2D = %Shadow
@onready var _grass_front: Sprite2D = %GrassFront


func _ready() -> void:
	add_to_group(GROUP)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	set_process(_mover != null)
	if _mover != null:
		# enter_map a pu être appelé hors de l'arbre : limites brutes à recadrer.
		_set_camera_limits(_map_bounds)
	_update_animation(Vector2i.ZERO)


func _process(delta: float) -> void:
	if _mover == null:
		return
	var direction := _input.update(
		Input.is_action_pressed(&"move_up"),
		Input.is_action_pressed(&"move_down"),
		Input.is_action_pressed(&"move_left"),
		Input.is_action_pressed(&"move_right")
	)
	_mover.update(delta, direction, Input.is_action_pressed(&"run"))
	position = _mover.get_world_position().round()
	_update_animation(direction)
	_update_jump_and_grass()


## Place le joueur sur une carte : case, orientation, limites de la caméra (pixels).
func enter_map(grid: GridWorld, cell: Vector2i, facing: Vector2i, bounds: Rect2i) -> void:
	if _mover != null:
		_mover.facing_changed.disconnect(_on_facing_changed)
		_mover.step_finished.disconnect(_on_step_finished)
		_mover.bumped.disconnect(_on_bumped)
		_grid.release(_mover.get_cell(), self)
		_grid.release(_mover.get_target_cell(), self)
	_grid = grid
	_mover = GridMover.new(grid, self)
	_mover.set_locked(not is_input_enabled())
	_mover.facing_changed.connect(_on_facing_changed)
	_mover.step_finished.connect(_on_step_finished)
	_mover.bumped.connect(_on_bumped)
	if not _mover.place(cell, facing):
		push_error("Player : impossible d'apparaître en %s" % cell)
	_input.reset()
	_bump_direction = Vector2i.ZERO
	position = _mover.get_world_position().round()
	_map_bounds = bounds
	_set_camera_limits(bounds)
	set_process(true)
	if is_node_ready():
		_update_animation(Vector2i.ZERO)
		_update_jump_and_grass()
		_camera.reset_smoothing()
	facing_changed.emit(_mover.get_facing())


## Bloque ([param enabled] faux) ou débloque les entrées pour [param reason]. Le joueur est
## libre quand plus aucune raison n'est active : un dialogue qui finit pendant un fondu ne le
## libère pas. Une même raison ne s'empile pas (deux blocages, un seul déblocage suffit).
## Bloqué, il termine le pas en cours puis ignore directions et course (ni pivot, ni
## [signal bumped]). Le réglage survit à [method enter_map].
func set_input_enabled(enabled: bool, reason: StringName = REASON_TRANSITION) -> void:
	if enabled:
		_block_reasons.erase(reason)
	else:
		_block_reasons[reason] = true
	if _mover != null:
		_mover.set_locked(not is_input_enabled())


## Vrai si aucune raison de blocage n'est active.
func is_input_enabled() -> bool:
	return _block_reasons.is_empty()


## Vrai si [param reason] bloque actuellement le joueur.
func is_blocked_by(reason: StringName) -> bool:
	return _block_reasons.has(reason)


## Pivote sur place vers [param direction], sans pas (dialogue automatique, scènes), même
## bloqué. Ignoré pendant un pas, pour une direction non cardinale ou hors carte. Émet
## [signal facing_changed] si l'orientation change.
func face(direction: Vector2i) -> void:
	if _mover == null or _mover.is_moving():
		return
	_mover.face(direction)
	_bump_direction = Vector2i.ZERO
	if is_node_ready():
		_update_animation(Vector2i.ZERO)


## Pas scripté (scènes, jalon 3B §2.5) : se tourne vers [param direction] et avance d'une
## case (en courant si [param run]), **même bloqué** : c'est le jeu qui déplace le joueur.
## Le pas se termine dans [method _process] comme un pas normal ([signal moved]). Faux,
## sans avancer, hors carte, pendant un pas, pour une direction non cardinale, ou si la
## case est inaccessible (tourné quand même, sans [signal bumped]).
## [param keep_facing] : il recule sans se retourner (orientation inchangée).
func script_step(direction: Vector2i, run: bool = false, keep_facing: bool = false) -> bool:
	if _mover == null:
		return false
	var started := _mover.start_step(direction, run, keep_facing)
	_bump_direction = Vector2i.ZERO
	if is_node_ready():
		_update_animation(Vector2i.ZERO)
	return started


func get_cell() -> Vector2i:
	return _mover.get_cell() if _mover != null else Grid.world_to_cell(position)


func get_facing() -> Vector2i:
	return _mover.get_facing() if _mover != null else Vector2i.DOWN


func is_moving() -> bool:
	return _mover != null and _mover.is_moving()


func is_running() -> bool:
	return _mover != null and _mover.is_running()


## Rectangle du personnage affiché, en coordonnées globales.
func get_body_rect() -> Rect2:
	return Rect2(global_position - Vector2(BODY_SIZE.x / 2.0, BODY_SIZE.y), BODY_SIZE)


func get_camera() -> Camera2D:
	return get_node(^"%Camera") as Camera2D


## Limites de la caméra pour la carte [param bounds] : celles de la carte si elle dépasse
## la vue, sinon élargies pour la centrer. Hors de l'arbre, [param bounds] tel quel.
func _set_camera_limits(bounds: Rect2i) -> void:
	var camera := get_camera()
	camera.zoom = Vector2.ONE
	var limits := bounds
	if is_inside_tree():
		limits = CameraFraming.limits_for(bounds, get_viewport_rect().size)
	camera.limit_left = limits.position.x
	camera.limit_top = limits.position.y
	camera.limit_right = limits.end.x
	camera.limit_bottom = limits.end.y


## Vrai pendant un saut de rebord (arc affiché).
func is_jumping() -> bool:
	return _mover != null and _mover.is_jumping()


## Vrai si la bande d'herbe est dessinée devant les jambes (case d'arrivée en hautes herbes).
func is_grass_front_visible() -> bool:
	return _grass_front != null and _grass_front.visible


## Arc du saut de rebord (sprite en l'air, ombre au sol) et bande d'herbe devant les jambes
## (visible quand la case d'arrivée du pas est en hautes herbes, cachée pendant un saut).
func _update_jump_and_grass() -> void:
	if _mover == null:
		return
	var jumping := _mover.is_jumping()
	var arc := 0.0
	if jumping:
		var t := _mover.get_progress()
		arc = 4.0 * JUMP_ARC_HEIGHT * t * (1.0 - t)
	if _sprite != null:
		_sprite.position.y = -arc
	if _shadow != null:
		_shadow.position.y = SHADOW_REST_Y
	if _grass_front != null:
		_grass_front.visible = not jumping and _grid != null \
			and _grid.is_tall_grass(_mover.get_target_cell())


func _update_animation(direction: Vector2i) -> void:
	if _sprite == null:
		return
	var facing := get_facing()
	var anims: Array = _ANIMS.get(facing, _ANIMS[Vector2i.DOWN])
	var anim: StringName = anims[0]
	var speed := 1.0
	if _bump_direction != Vector2i.ZERO and direction != _bump_direction:
		_bump_direction = Vector2i.ZERO
	if is_moving():
		anim = anims[2] if _mover.is_running() else anims[1]
	elif _bump_direction != Vector2i.ZERO:
		anim = anims[1]
		speed = BUMP_ANIM_SPEED
	if _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)
	_sprite.speed_scale = speed


func _on_viewport_size_changed() -> void:
	if _mover != null:
		_set_camera_limits(_map_bounds)


func _on_facing_changed(direction: Vector2i) -> void:
	facing_changed.emit(direction)


func _on_step_finished(cell: Vector2i) -> void:
	moved.emit(cell)


func _on_bumped(direction: Vector2i) -> void:
	_bump_direction = direction
	bumped.emit(direction)
