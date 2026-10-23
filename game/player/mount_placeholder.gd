class_name MountPlaceholder
extends Node2D
## Monture provisoire du joueur (moteur commun, règle 3 : rendu provisoire jusqu'à l'art des
## montures). Tant que l'apparence n'a pas d'animations `surf_*` / `bike_*`, rien ne montrait que
## le joueur nageait ou pédalait (QA du J24, défaut D1 : « en Surf, le joueur est dessiné à pied
## sur l'eau » ; QA du J22 : Piste « à pied »). Ce nœud, enfant du [Player], le montre :
## - **Surf** : un dos de Pokémon nageur dessiné en code (pas d'image), devant les jambes du
##   héros, avec un sillage clair à la ligne de flottaison ; le héros est assis dessus (relevé de
##   [constant SURF_SEAT_LIFT] px, à l'arrêt), son ombre au sol est cachée ;
## - **Vélo** : l'image du vélo garé [constant BIKE_TEXTURE_PATH] si elle existe (jalon 22), sous le
##   héros de profil, resserrée et devant lui de face et de dos (valeurs du J22) ; sans l'image,
##   rien (l'état d'avant).
## Une apparence qui a ses animations montées (`surf_idle_down`…) n'a plus besoin de lui : il
## s'efface ([method refresh]). Aucune logique : [Player] l'appelle à chaque changement d'animation.

## Héros relevé (px du monde) quand il est assis sur le dos du nageur.
const SURF_SEAT_LIFT: float = 18.0
## Dos du nageur (px du monde) : demi-largeur de profil, de face / de dos, demi-hauteur ; centre au
## dessus des pieds. Valeurs [D].
const SURF_HALF_WIDTH_SIDE: float = 62.0
const SURF_HALF_WIDTH_FRONT: float = 44.0
const SURF_HALF_HEIGHT: float = 22.0
const SURF_CENTER_Y: float = -20.0
const SURF_BODY_COLOR := Color(0.27, 0.47, 0.66)
const SURF_SHADE_COLOR := Color(0.18, 0.33, 0.5)
const SURF_EYE_COLOR := Color(0.06, 0.08, 0.12)
const SURF_OUTLINE_COLOR := Color(0.12, 0.2, 0.3)
const SURF_WAKE_COLOR := Color(1.0, 1.0, 1.0, 0.55)
## Tête du nageur : rayon, avancée devant le dos (de profil, et vers le bas de face).
const SURF_HEAD_RADIUS: float = 17.0
const SURF_HEAD_REACH: float = 0.85
## Vélo provisoire du J22 (`prop_velo_01`) : échelle, resserrement de face, bas des roues.
const BIKE_TEXTURE_PATH: String = "res://assets/world/props/prop_velo_01.png"
const BIKE_SCALE: float = 0.6
const BIKE_FRONT_WIDTH: float = 0.3
const BIKE_BOTTOM: float = 2.0

var _sprite: Node2D
var _kind: Mount.Kind = Mount.Kind.NONE
var _facing: Vector2i = Vector2i.DOWN
var _lift: float = 0.0
var _bike: Sprite2D


## [param sprite] : le sprite du héros (le provisoire se range devant ou derrière lui).
func attach(sprite: Node2D) -> void:
	name = "MountPlaceholder"
	_sprite = sprite
	visible = false
	if ResourceLoader.exists(BIKE_TEXTURE_PATH):
		_bike = Sprite2D.new()
		_bike.name = "Bike"
		_bike.texture = load(BIKE_TEXTURE_PATH) as Texture2D
		_bike.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(_bike)


## Monture affichée pour [param kind], l'animation [param anim] jouée par le héros et son
## orientation [param facing]. Visible seulement si l'apparence n'a pas l'animation montée.
func refresh(kind: Mount.Kind, anim: StringName, facing: Vector2i) -> void:
	_kind = kind
	_facing = facing
	var drawn := false
	match kind:
		Mount.Kind.SURF:
			drawn = not String(anim).begins_with("surf_")
		Mount.Kind.BIKE:
			drawn = _bike != null and not String(anim).begins_with("bike_")
	visible = drawn
	if _bike != null:
		_bike.visible = drawn and kind == Mount.Kind.BIKE
	if not drawn:
		return
	var side := facing.x != 0
	if kind == Mount.Kind.BIKE:
		_bike.flip_h = facing == Vector2i.RIGHT
		_bike.scale = Vector2(BIKE_SCALE * (1.0 if side else BIKE_FRONT_WIDTH), BIKE_SCALE)
		_bike.position.y = BIKE_BOTTOM - _bike.texture.get_height() * BIKE_SCALE / 2.0
		# De profil derrière le héros (le panier devant), de face et de dos devant lui.
		_place(not side)
	else:
		# Le dos du nageur couvre les jambes : toujours devant.
		_place(true)
	queue_redraw()


## Hauteur du saut ou du bond en cours (px) : le provisoire suit le héros.
func set_lift(lift: float) -> void:
	_lift = lift
	position.y = -lift


## Vrai si une monture provisoire est dessinée.
func is_drawn() -> bool:
	return visible


## Relèvement du héros assis (0 hors du Surf provisoire).
func seat_lift() -> float:
	return SURF_SEAT_LIFT if visible and _kind == Mount.Kind.SURF else 0.0


func _place(in_front: bool) -> void:
	var parent := get_parent()
	if parent == null or _sprite == null or _sprite.get_parent() != parent:
		return
	var sprite_index := _sprite.get_index()
	if in_front and get_index() < sprite_index:
		parent.move_child(self, sprite_index)
	elif not in_front and get_index() > sprite_index:
		parent.move_child(self, sprite_index)


func _draw() -> void:
	if _kind != Mount.Kind.SURF:
		return
	var side := _facing.x != 0
	var half := Vector2(SURF_HALF_WIDTH_SIDE if side else SURF_HALF_WIDTH_FRONT,
		SURF_HALF_HEIGHT)
	var center := Vector2(0.0, SURF_CENTER_Y)
	# Sillage à la ligne de flottaison, sous le dos.
	_ellipse(Vector2(0.0, -2.0), Vector2(half.x * 1.25, 9.0), SURF_WAKE_COLOR)
	_ellipse(center, half + Vector2(2.5, 2.5), SURF_OUTLINE_COLOR)
	_ellipse(center, half, SURF_SHADE_COLOR)
	# Dos plus clair au-dessus, flanc sombre au ras de l'eau, reflet.
	_ellipse(center - Vector2(0.0, half.y * 0.18), half * Vector2(0.96, 0.8), SURF_BODY_COLOR)
	_ellipse(center - Vector2(half.x * 0.2, half.y * 0.5), Vector2(half.x * 0.4, 4.0),
		Color(1, 1, 1, 0.4))
	# Tête par-dessus le dos : en avant de profil, vers le bas de face, cachée de dos.
	if side or _facing == Vector2i.DOWN:
		var head := center + (Vector2(_facing.x * half.x * SURF_HEAD_REACH, -6.0) if side
			else Vector2(0.0, half.y * 0.55))
		draw_circle(head, SURF_HEAD_RADIUS + 2.0, SURF_OUTLINE_COLOR)
		draw_circle(head, SURF_HEAD_RADIUS, SURF_BODY_COLOR)
		var eye := head + (Vector2(_facing.x * 7.0, -5.0) if side else Vector2(0.0, 2.0))
		if side:
			draw_circle(eye, 3.0, SURF_EYE_COLOR)
		else:
			draw_circle(eye + Vector2(-6.0, 0.0), 2.5, SURF_EYE_COLOR)
			draw_circle(eye + Vector2(6.0, 0.0), 2.5, SURF_EYE_COLOR)


func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i: int in 24:
		var angle := TAU * i / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
