class_name Npc
extends Node2D
## PNJ ou Pokémon du décor posé sur une carte (docs/tech/jalon-03.md §2.3) : présentation
## seulement, la description vient d'un [NpcSpec] (`data/npcs/<map_id>.json`).
##
## Créé par [GameMap] au chargement : [method setup] avant l'ajout à l'arbre, puis la carte
## l'inscrit comme occupant de sa case dans la [GridWorld]. [InteractionFinder] le trouve par
## [method get_interaction]. Origine aux pieds, sprite pixel art ×2 en NEAREST. Aucun
## déplacement en 3A : il reste sur sa case et ne fait que se tourner et réagir.
## Au repos, [method _process] est coupé ; seule l'[AnimatedSprite2D] tourne (idle_<dir>).

## Réaction jouée ([method react]) : tests, futurs sons.
signal reacted

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

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _shadow: Sprite2D = %Shadow


func _ready() -> void:
	set_process(false)
	_sprite.animation_finished.connect(_on_animation_finished)
	_apply_spec()


## Décrit le PNJ (à appeler avant l'ajout à l'arbre ; rappelable ensuite). Position = pieds
## sur la case, orientation au repos, apparence [code]<sprite>_frames.tres[/code].
func setup(spec: NpcSpec) -> void:
	_spec = spec if spec != null else NpcSpec.new()
	name = String(_spec.id) if not _spec.id.is_empty() else "Npc"
	position = Grid.cell_to_world(_spec.cell)
	_facing = _spec.facing if Grid.is_cardinal(_spec.facing) else Vector2i.DOWN
	_interaction = _spec.make_interaction(_spec.cell, self)
	if is_node_ready():
		_apply_spec()


func get_id() -> StringName:
	return _spec.id


func get_spec() -> NpcSpec:
	return _spec


func get_cell() -> Vector2i:
	return _spec.cell


func get_facing() -> Vector2i:
	return _facing


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


## Se tourne vers [param direction] (animation idle_<dir>). Non cardinale : ignorée.
func face(direction: Vector2i) -> void:
	if not Grid.is_cardinal(direction):
		return
	_facing = direction
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


func _on_animation_finished() -> void:
	if _sprite.animation == REACT_ANIM or _REACT_ANIMS.values().has(_sprite.animation):
		_play_idle()
