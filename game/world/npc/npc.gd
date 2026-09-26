class_name Npc
extends Node2D
## PNJ ou Pokémon du décor posé sur une carte (docs/tech/jalon-03.md §2.3) : présentation
## seulement, la description vient d'un [NpcSpec] (`data/npcs/<map_id>.json`).
##
## Créé par [GameMap] au chargement : [method setup] avant l'ajout à l'arbre, puis la carte
## l'inscrit sur la [GridWorld] par [method enter_grid] (il y possède un [GridMover], comme
## le joueur). [InteractionFinder] le trouve par l'occupant de la grille et
## [method get_interaction]. Origine aux pieds, sprite pixel art ×2 en NEAREST.
## Jalon 3B : il peut marcher case par case ([method step], scènes scriptées). Sa case
## courante vit dans son [GridMover] ; [member NpcSpec.cell] reste sa case de départ.
## Au repos, [method _process] est coupé ; seule l'[AnimatedSprite2D] tourne (idle_<dir>).
## Il ne tourne que pendant un pas (walk_<dir> ou run_<dir> si l'apparence les a).

## Réaction jouée ([method react]) : tests, futurs sons.
signal reacted
## Pas terminé sur [param cell] ([method step]).
signal step_finished(cell: Vector2i)

## SpriteFrames des apparences : `<FRAMES_DIR><sprite>_frames.tres`.
const FRAMES_DIR: String = "res://assets/sprites/characters/placeholder/"
## Apparence générique (provisoire) quand `<sprite>_frames.tres` n'existe pas encore.
const FALLBACK_SPRITE: StringName = &"npc"
## Animation de réaction facultative (non bouclée) : `react_<dir>` dans l'orientation
## courante si l'apparence l'a, sinon `react` ; sans aucune des deux, petit bond.
const REACT_ANIM: StringName = &"react"
## Petit bond de [method react] : hauteur (pixels monde) et durée totale (s).
const HOP_HEIGHT: float = 12.0
const HOP_DURATION: float = 0.25
const _IDLE_ANIMS: Dictionary[Vector2i, StringName] = {
	Vector2i.DOWN: &"idle_down",
	Vector2i.UP: &"idle_up",
	Vector2i.LEFT: &"idle_left",
	Vector2i.RIGHT: &"idle_right",
}
const _WALK_ANIMS: Dictionary[Vector2i, StringName] = {
	Vector2i.DOWN: &"walk_down",
	Vector2i.UP: &"walk_up",
	Vector2i.LEFT: &"walk_left",
	Vector2i.RIGHT: &"walk_right",
}
const _RUN_ANIMS: Dictionary[Vector2i, StringName] = {
	Vector2i.DOWN: &"run_down",
	Vector2i.UP: &"run_up",
	Vector2i.LEFT: &"run_left",
	Vector2i.RIGHT: &"run_right",
}
const _REACT_ANIMS: Dictionary[Vector2i, StringName] = {
	Vector2i.DOWN: &"react_down",
	Vector2i.UP: &"react_up",
	Vector2i.LEFT: &"react_left",
	Vector2i.RIGHT: &"react_right",
}

var _spec: NpcSpec = NpcSpec.new()
var _interaction: Interaction
var _facing: Vector2i = Vector2i.DOWN
var _hop: Tween
## Déplacement sur la grille de la carte ([method enter_grid]) ; null hors grille.
var _mover: GridMover
var _grid: GridWorld
## Case hors grille (avant [method enter_grid], après [method leave_grid]).
var _cell: Vector2i = Vector2i.ZERO

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _shadow: Sprite2D = %Shadow


func _ready() -> void:
	set_process(is_moving())
	_sprite.animation_finished.connect(_on_animation_finished)
	_apply_spec()


## Ne tourne que pendant un pas : le [GridMover] avance, le nœud suit (position arrondie).
func _process(delta: float) -> void:
	if _mover == null:
		set_process(false)
		return
	_mover.update(delta, Vector2i.ZERO, false)
	position = _mover.get_world_position().round()
	if not _mover.is_moving():
		set_process(false)
		_play_idle()


## Décrit le PNJ (à appeler avant l'ajout à l'arbre ; rappelable ensuite). Position = pieds
## sur la case, orientation au repos, apparence [code]<sprite>_frames.tres[/code].
func setup(spec: NpcSpec) -> void:
	_spec = spec if spec != null else NpcSpec.new()
	name = String(_spec.id) if not _spec.id.is_empty() else "Npc"
	_cell = _spec.cell
	position = Grid.cell_to_world(_spec.cell)
	_facing = _spec.facing if Grid.is_cardinal(_spec.facing) else Vector2i.DOWN
	_interaction = _spec.make_interaction(_spec.cell, self)
	if is_node_ready():
		_apply_spec()


func get_id() -> StringName:
	return _spec.id


func get_spec() -> NpcSpec:
	return _spec


## Case courante : celle du [GridMover] (case de départ pendant un pas), sinon celle de la
## description (hors grille).
func get_cell() -> Vector2i:
	return _mover.get_cell() if _mover != null else _cell


func get_facing() -> Vector2i:
	return _facing


## Inscrit le PNJ sur [param grid] : nouveau [GridMover], placé sur la case de départ au
## premier appel, sur sa case courante ensuite (grille reconstruite). Un pas en cours est
## annulé. Faux si la case est hors carte ou prise (le PNJ reste alors hors grille).
func enter_grid(grid: GridWorld) -> bool:
	var cell := get_cell()
	if _mover != null:
		_mover.step_finished.disconnect(_on_step_finished)
		_mover = null
		_grid = null
		_cell = cell
	var mover := GridMover.new(grid, self)
	if not mover.place(cell, _facing):
		return false
	_mover = mover
	_grid = grid
	_mover.step_finished.connect(_on_step_finished)
	position = Grid.cell_to_world(cell)
	set_process(false)
	_play_idle()
	return true


## Libère sa case (et la case visée par un pas en cours) ; le PNJ reste où il est.
func leave_grid() -> void:
	if _mover == null:
		return
	var cell := _mover.get_cell()
	_grid.release(_mover.get_target_cell(), self)
	_grid.release(cell, self)
	_mover.step_finished.disconnect(_on_step_finished)
	_mover = null
	_grid = null
	_cell = cell
	position = Grid.cell_to_world(cell)
	set_process(false)
	_play_idle()


## Un pas vers [param direction] (marche, ou course si [param run]) : il se tourne et part,
## même si la case est prise (alors tourné, faux). Faux aussi hors grille, pendant un pas
## ou pour une direction non cardinale.
func step(direction: Vector2i, run: bool = false) -> bool:
	if _mover == null or not Grid.is_cardinal(direction):
		return false
	var started := _mover.start_step(direction, run)
	_facing = _mover.get_facing()
	if not started:
		_play_idle()
		return false
	_play_move()
	set_process(true)
	return true


func is_moving() -> bool:
	return _mover != null and _mover.is_moving()


## Interaction du PNJ (toujours la même instance : aucune allocation), null s'il n'est pas
## interactif (Roucool de Mme Aoki).
func get_interaction() -> Interaction:
	return _interaction


## Chemin des SpriteFrames d'une apparence.
static func frames_path(sprite: StringName) -> String:
	return FRAMES_DIR + String(sprite) + "_frames.tres"


## Vrai si l'apparence a ses propres SpriteFrames (sinon la scène prend le générique).
static func has_frames(sprite: StringName) -> bool:
	return not sprite.is_empty() and ResourceLoader.exists(frames_path(sprite))


## Se tourne vers [param direction] (animation idle_<dir>). Non cardinale ou pendant un
## pas : ignorée.
func face(direction: Vector2i) -> void:
	if not Grid.is_cardinal(direction) or is_moving():
		return
	_facing = direction
	if _mover != null:
		_mover.face(direction)
	_play_idle()


## Se tourne vers [param cell] selon l'axe dominant (à égalité, l'axe vertical). Rien si
## c'est sa propre case.
func face_toward(cell: Vector2i) -> void:
	var delta := cell - get_cell()
	if delta == Vector2i.ZERO:
		return
	if absi(delta.x) > absi(delta.y):
		face(Vector2i(signi(delta.x), 0))
	else:
		face(Vector2i(0, signi(delta.y)))


## Début d'une interaction avec le joueur en [param player_cell] : il se tourne vers lui si
## [member NpcSpec.turn_to_player].
func begin_interaction(player_cell: Vector2i) -> void:
	if _spec.turn_to_player:
		face_toward(player_cell)


## Fin d'une interaction : il reprend son orientation au repos (« retourne à ses
## affaires »), sauf [member NpcSpec.keep_facing].
func end_interaction() -> void:
	if not _spec.keep_facing:
		face(_spec.facing)


## Petite réaction (indication « react » d'une page de dialogue) : animation
## `react_<dir>` (ou `react`) si l'apparence en a une, puis retour à l'attente ; sinon
## petit bond du sprite (la case ne change pas).
func react() -> void:
	reacted.emit()
	if _sprite == null:
		return
	var frames := _sprite.sprite_frames
	if frames != null:
		var directed: StringName = _REACT_ANIMS.get(_facing, REACT_ANIM)
		for anim: StringName in [directed, REACT_ANIM]:
			if frames.has_animation(anim):
				_sprite.play(anim)
				return
	if not is_inside_tree():
		return
	if _hop != null and _hop.is_valid():
		_hop.kill()
	var rest := _rest_y()
	_sprite.position.y = rest
	_hop = create_tween()
	_hop.tween_property(_sprite, ^"position:y", rest - HOP_HEIGHT, HOP_DURATION / 2.0) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop.tween_property(_sprite, ^"position:y", rest, HOP_DURATION / 2.0) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _apply_spec() -> void:
	var sprite := _spec.sprite if has_frames(_spec.sprite) else FALLBACK_SPRITE
	var frames := load(frames_path(sprite)) as SpriteFrames
	if frames != null:
		_sprite.sprite_frames = frames
	# Pieds sur l'origine quelle que soit la hauteur de l'image (64 px, 48 px, 32 px).
	var frame := _sprite.sprite_frames.get_frame_texture(_IDLE_ANIMS[Vector2i.DOWN], 0)
	if frame != null:
		_sprite.offset = Vector2(0.0, -frame.get_size().y / 2.0)
	# Élévation (Pokémon sur une table) en pixels monde : sprite et ombre montent ensemble.
	if _hop != null and _hop.is_valid():
		_hop.kill()
	_sprite.position.y = _rest_y()
	_shadow.position.y = _shadow_rest_y() - float(_spec.lift)
	_play_idle()


func _rest_y() -> float:
	return -float(_spec.lift)


## Position de l'ombre sans élévation (celle de la scène, comme le joueur).
func _shadow_rest_y() -> float:
	return -6.0


func _play_idle() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var anim: StringName = _IDLE_ANIMS.get(_facing, &"idle_down")
	if _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)


## Pendant un pas : run_<dir> ou walk_<dir> si l'apparence les a, sinon idle_<dir>
## (Pokémon du décor).
func _play_move() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var table := _RUN_ANIMS if _mover.is_running() else _WALK_ANIMS
	var anim: StringName = table.get(_facing, &"")
	if not _sprite.sprite_frames.has_animation(anim):
		anim = _WALK_ANIMS.get(_facing, &"")
	if not _sprite.sprite_frames.has_animation(anim):
		_play_idle()
		return
	if _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)


## Fin d'un pas (dans [method GridMover.update]) : l'interaction suit la case (aucune
## allocation), puis le signal. Un gestionnaire peut lancer le pas suivant.
func _on_step_finished(cell: Vector2i) -> void:
	if _interaction != null:
		_interaction.cell = cell
	step_finished.emit(cell)


func _on_animation_finished() -> void:
	if _sprite.animation == REACT_ANIM or _REACT_ANIMS.values().has(_sprite.animation):
		_play_idle()
