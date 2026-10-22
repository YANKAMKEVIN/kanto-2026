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
## Passe systèmes 2 (`systemes-2.md` §2.2, §2.3) : **monture** ([enum Mount.Kind], Vélo ou
## Surf) : durée des pas ([method MountRules.step_duration], course ignorée), animations
## `bike_*` / `surf_*` si l'apparence les a (sinon celles de la marche), mode d'accès de la grille
## ([method get_move_mode]) ; en Vélo sur une pente de la Piste, sans appui, il dérive vers le
## bas ([CyclingSlope]). En Surf, le pas qui monte sur l'eau ou descend sur la rive est un saut
## d'une case ([method MountRules.is_surf_hop]). La mise en scène (compagnon, refus, arrivée,
## montée et descente du Surf) est dans [MountDirector].
## Moteur commun : sans animations montées, une **monture provisoire** ([MountPlaceholder]) montre
## le Surf (dos de nageur dessiné, héros assis, à l'arrêt) et le Vélo (image du J22 si présente).

signal moved(cell: Vector2i)
## Un pas commence (jalon 11, relais de [signal GridMover.step_started] pour le compagnon) :
## [param kind] = &"walk", &"run" ou &"jump" (saut de rebord, deux cases). Pas scriptés compris.
## Monté (passe systèmes 2) : &"bike" ou &"surf" (saut de rebord compris).
signal step_started(from_cell: Vector2i, to_cell: Vector2i, kind: StringName)
## La monture a changé ([method set_mount]).
signal mount_changed(kind: Mount.Kind)
signal facing_changed(direction: Vector2i)
signal bumped(direction: Vector2i)
## Petite réaction de surprise ([method react], scènes) : tests, futurs sons.
signal reacted

## Groupe qui permet au décor de retrouver le joueur (transparence des feuillages).
const GROUP: StringName = &"player"
## Apparence du joueur ([CharacterLook]) : le héros peint (marche et course, Q-1 du jalon 7),
## sinon le provisoire pixel art ×2.
const LOOK_SPRITE: StringName = &"player"
## Taille affichée du personnage avant [method _apply_look] (provisoire 32×64 ×2), bas-centre
## sur l'origine.
const BODY_SIZE := Vector2(64, 128)
## Vitesse de l'animation de marche sur place contre un obstacle.
const BUMP_ANIM_SPEED: float = 0.5
## Hauteur de l'arc du saut de rebord (px monde) : le sprite s'élève, l'ombre reste au sol.
const JUMP_ARC_HEIGHT: float = 48.0
## Petit bond de surprise ([method react]) : hauteur (px monde) et durée totale (s), comme le
## bond des PNJ sans animation « react » (Npc.HOP_HEIGHT / HOP_DURATION, un peu plus marqué).
const REACT_HEIGHT: float = 16.0
const REACT_DURATION: float = 0.28
## Repos de l'ombre (px monde), comme dans la scène.
const SHADOW_REST_Y: float = -6.0
## Raison de blocage par défaut : celle du routeur de scènes (changement de carte).
const REASON_TRANSITION: StringName = &"transition"
## Bas de la bande d'herbe devant les jambes, sous l'origine (pieds), en px monde.
const GRASS_FRONT_BOTTOM: float = 2.0
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
## Taille affichée de l'apparence (image de repos × échelle).
var _body_size: Vector2 = BODY_SIZE
## Apparence résolue au chargement.
var _look: CharacterLook
## Hauteur courante du bond de surprise (px monde), animée par [member _react_tween].
var _react_lift: float = 0.0
var _react_tween: Tween
## Bande d'herbe de la carte ([member GameMap.grass_front]) ; nulle = la bande provisoire.
var _grass_front_texture: Texture2D
## Bande provisoire de la scène (pixel ×2, NEAREST), gardée pour les cartes non peintes.
var _default_grass_front: Texture2D
## Monture (passe systèmes 2) : à pied par défaut.
var _mount: Mount.Kind = Mount.Kind.NONE
## Monture provisoire ([MountPlaceholder]), créée dans [method _ready].
var _mount_placeholder: MountPlaceholder

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _camera: Camera2D = %Camera
@onready var _shadow: Sprite2D = %Shadow
@onready var _grass_front: Sprite2D = %GrassFront


func _ready() -> void:
	add_to_group(GROUP)
	_apply_look()
	_mount_placeholder = MountPlaceholder.new()
	add_child(_mount_placeholder)
	_mount_placeholder.attach(_sprite)
	_default_grass_front = _grass_front.texture
	_apply_grass_front()
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
	var run := Input.is_action_pressed(&"run") and _mount == Mount.Kind.NONE
	if direction == Vector2i.ZERO and _should_drift():
		# Pente de la Piste : un pas vers le bas par le chemin normal (collisions, rebords et
		# vue des Dresseurs inchangés) ; à l'arrêt, sans pivot préalable.
		if _mover.is_moving():
			_mover.update(delta, Vector2i.DOWN, false)
		else:
			_mover.start_step(Vector2i.DOWN)
	else:
		_mover.update(delta, direction, run)
	position = _mover.get_world_position().round()
	_update_animation(direction)
	_update_jump_and_grass()


## Place le joueur sur une carte : case, orientation, limites de la caméra (pixels).
func enter_map(grid: GridWorld, cell: Vector2i, facing: Vector2i, bounds: Rect2i) -> void:
	if _mover != null:
		_mover.facing_changed.disconnect(_on_facing_changed)
		_mover.step_finished.disconnect(_on_step_finished)
		_mover.bumped.disconnect(_on_bumped)
		_mover.step_started.disconnect(_on_step_started)
		_grid.release(_mover.get_cell(), self)
		_grid.release(_mover.get_target_cell(), self)
	_grid = grid
	_mover = GridMover.new(grid, self)
	_mover.set_locked(not is_input_enabled())
	_apply_mount_speed()
	_mover.hop_rule = _is_surf_hop
	_mover.hop_duration = MountRules.SURF_HOP_DURATION
	_mover.facing_changed.connect(_on_facing_changed)
	_mover.step_finished.connect(_on_step_finished)
	_mover.bumped.connect(_on_bumped)
	_mover.step_started.connect(_on_step_started)
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


## Monture courante (passe systèmes 2).
func get_mount() -> Mount.Kind:
	return _mount


## Mode d'accès lu par la grille ([method GridWorld.move_mode_of]) : SURF en Surf, WALK sinon (le
## Vélo suit les règles de la marche, rebords compris).
func get_move_mode() -> GridWorld.MoveMode:
	return GridWorld.MoveMode.SURF if _mount == Mount.Kind.SURF else GridWorld.MoveMode.WALK


## Change de monture : durée des pas et animations ; [signal mount_changed] si elle change. Le
## pas en cours finit à son ancienne durée. [param instant] : sans mise en scène (arrivée sur une
## carte, chargement) — le joueur n'en a pas lui-même : la mise en scène (saut du Surf,
## compagnon) est dans [MountDirector].
func set_mount(kind: Mount.Kind, _instant: bool = false) -> void:
	if kind == _mount:
		return
	_mount = kind
	_apply_mount_speed()
	if is_node_ready():
		_update_animation(Vector2i.ZERO)
	mount_changed.emit(kind)


## Bande d'herbe dessinée devant les jambes en hautes herbes : la moitié basse des touffes
## peintes de la carte ([member GameMap.grass_front], filtre LINEAR, à 1:1), ou la bande
## provisoire si [param texture] est nulle. Bas de la bande juste sous les pieds.
func set_grass_front(texture: Texture2D) -> void:
	_grass_front_texture = texture
	if is_node_ready():
		_apply_grass_front()


## Texture de la bande d'herbe affichée devant les jambes.
func get_grass_front_texture() -> Texture2D:
	return _grass_front.texture if _grass_front != null else null


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


## Petite réaction de surprise (scènes, étape « react ») : animation `react_<dir>` si
## l'apparence l'a, sinon un petit bond sur place (le sprite monte, l'ombre reste au sol). Ne
## bouge ni la case ni l'orientation.
func react() -> void:
	reacted.emit()
	var anim := StringName("react_" + Grid.direction_name(get_facing()))
	if _sprite != null and _sprite.sprite_frames != null \
			and _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)
		return
	if not is_inside_tree():
		return
	if _react_tween != null and _react_tween.is_valid():
		_react_tween.kill()
	_react_tween = create_tween()
	_react_tween.tween_property(self, ^"_react_lift", REACT_HEIGHT, REACT_DURATION / 2.0) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_react_tween.tween_property(self, ^"_react_lift", 0.0, REACT_DURATION / 2.0) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_react_tween.finished.connect(_update_jump_and_grass)


## Vrai pendant le bond de [method react].
func is_reacting() -> bool:
	return _react_tween != null and _react_tween.is_valid() and _react_tween.is_running()


func get_cell() -> Vector2i:
	return _mover.get_cell() if _mover != null else Grid.world_to_cell(position)


func get_facing() -> Vector2i:
	return _mover.get_facing() if _mover != null else Vector2i.DOWN


func is_moving() -> bool:
	return _mover != null and _mover.is_moving()


func is_running() -> bool:
	return _mover != null and _mover.is_running()


## Direction contre laquelle le joueur pousse encore ([signal bumped], direction toujours tenue) ;
## ZERO sinon. Passe systèmes 2 (§2.7.2) : [StrengthDirector] y lit l'appui tenu contre un rocher.
func get_bump_direction() -> Vector2i:
	return _bump_direction


## Rectangle du personnage affiché, en coordonnées globales.
func get_body_rect() -> Rect2:
	return Rect2(global_position - Vector2(_body_size.x / 2.0, _body_size.y), _body_size)


## Apparence affichée (peinte ou provisoire).
func get_look() -> CharacterLook:
	return _look


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
	var seat := _mount_placeholder.seat_lift() if _mount_placeholder != null else 0.0
	if _sprite != null:
		_sprite.position.y = -arc - _react_lift - seat
	if _mount_placeholder != null:
		_mount_placeholder.set_lift(arc + _react_lift)
	if _shadow != null:
		_shadow.position.y = SHADOW_REST_Y
		# Sur le dos du nageur provisoire, pas d'ombre au sol.
		_shadow.visible = seat == 0.0
	if _grass_front != null:
		_grass_front.visible = not jumping and _grid != null \
			and _grid.is_tall_grass(_mover.get_target_cell())


func _apply_grass_front() -> void:
	if _grass_front == null:
		return
	var texture := _grass_front_texture
	var painted := texture != null
	if not painted:
		texture = _default_grass_front
	_grass_front.texture = texture
	_grass_front.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if painted \
		else CanvasItem.TEXTURE_FILTER_NEAREST
	if texture != null:
		_grass_front.position = Vector2(0.0, GRASS_FRONT_BOTTOM - texture.get_height() / 2.0)


## SpriteFrames, échelle et filtre de l'apparence ([CharacterLook]) ; pieds sur l'origine.
func _apply_look() -> void:
	_look = CharacterLook.resolve(LOOK_SPRITE)
	var frames := load(_look.frames_path) as SpriteFrames
	if frames == null:
		return
	_sprite.sprite_frames = frames
	_sprite.scale = Vector2(_look.scale, _look.scale)
	_sprite.texture_filter = _look.filter
	var frame := frames.get_frame_texture(&"idle_down", 0)
	if frame != null:
		_sprite.offset = Vector2(0.0, -frame.get_size().y / 2.0)
		_body_size = frame.get_size() * _look.scale


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
	anim = _mounted_animation(anim)
	if _mount == Mount.Kind.SURF and not String(anim).begins_with("surf_"):
		# Surf provisoire : assis sur le nageur, à l'arrêt (pas de jambes qui marchent).
		anim = anims[0]
		speed = 1.0
	if _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)
	_sprite.speed_scale = speed
	if _mount_placeholder != null:
		_mount_placeholder.refresh(_mount, anim, facing)
		_update_jump_and_grass()


func _on_viewport_size_changed() -> void:
	if _mover != null:
		_set_camera_limits(_map_bounds)


func _on_facing_changed(direction: Vector2i) -> void:
	facing_changed.emit(direction)


func _on_step_started(from_cell: Vector2i, to_cell: Vector2i, running: bool) -> void:
	var distance := absi(to_cell.x - from_cell.x) + absi(to_cell.y - from_cell.y)
	var kind := &"jump" if distance > 1 else (&"run" if running else &"walk")
	if _mount != Mount.Kind.NONE:
		kind = Mount.to_name(_mount)
	step_started.emit(from_cell, to_cell, kind)


## Durées des pas de la monture courante (la course n'existe qu'à pied).
func _apply_mount_speed() -> void:
	if _mover == null:
		return
	_mover.walk_duration = MountRules.step_duration(_mount, false)
	_mover.run_duration = MountRules.step_duration(_mount, true)


## Animation montée (`bike_walk_down`, `surf_idle_left`…) si l'apparence l'a, sinon
## [param anim] (placeholder : l'art des montures n'est pas encore là, règle 3).
func _mounted_animation(anim: StringName) -> StringName:
	if _mount == Mount.Kind.NONE or _sprite == null or _sprite.sprite_frames == null:
		return anim
	var base := String(anim).replace("run_", "walk_")
	var mounted := StringName("%s_%s" % [Mount.to_name(_mount), base])
	return mounted if _sprite.sprite_frames.has_animation(mounted) else anim


## Vrai si la monture est dessinée : animation montée de l'apparence, ou monture provisoire
## ([MountPlaceholder]). Faux à pied.
func is_mount_drawn() -> bool:
	if _mount == Mount.Kind.NONE:
		return false
	if _mount_placeholder != null and _mount_placeholder.is_drawn():
		return true
	return _sprite != null and String(_sprite.animation).begins_with(Mount.to_name(_mount) + "_")


## Monture provisoire (tests, captures).
func get_mount_placeholder() -> MountPlaceholder:
	return _mount_placeholder


## Saut de montée en Surf ou de descente sur la rive ([method MountRules.is_surf_hop]) : lu par
## [member GridMover.hop_rule] à chaque pas.
func _is_surf_hop(from: Vector2i, to: Vector2i) -> bool:
	return MountRules.is_surf_hop(_mount, _grid, from, to)


## Dérive de la pente ([CyclingSlope]) : en Vélo, sur une case de pente, joueur libre. La vue
## d'un Dresseur bloque le joueur dans le [signal moved] du pas qui l'y amène : « libre » la
## couvre ([method is_input_enabled]).
func _should_drift() -> bool:
	if _mount != Mount.Kind.BIKE or _grid == null:
		return false
	var cell := _mover.get_target_cell() if _mover.is_moving() else _mover.get_cell()
	return CyclingSlope.should_drift(Vector2i.ZERO, _grid.is_slope(cell), is_input_enabled(),
		false)


func _on_step_finished(cell: Vector2i) -> void:
	moved.emit(cell)


func _on_bumped(direction: Vector2i) -> void:
	_bump_direction = direction
	bumped.emit(direction)
