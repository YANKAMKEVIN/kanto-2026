class_name SleeperBed
extends Node2D
## Lit où dort le joueur (JOH1, remise en scène du vol, demande de Kevin du 2026-11-04 : « voir le
## joueur dormir vraiment »). Présentation pure, posé par l'outil de construction de la carte
## (racine de la carte, à la position du lit) ; l'étape de scène « change_map » avec
## `"pose": "asleep"` l'appelle ([method tuck_in]) pendant l'écran noir.
##
## [method tuck_in] remplace l'image du lit [member bed_path] (son `%Sprite`) par le lit occupé de
## l'apparence du joueur (héros ou joueuse, peints par Codex sur le lit validé : même cadrage, même
## pied), puis fait monter de petits « z » au-dessus de l'oreiller ([constant ZZZ_PERIOD]).
## « Réduire les animations » : un seul « z » immobile. Une nouvelle carte (instance neuve) rend
## le lit vide : rien à défaire.

## Apparence de la joueuse ([member GameState.player_look]) ; toute autre valeur = le héros.
const LOOK_HEROINE: StringName = &"heroine"
## Un « z » toutes les ZZZ_PERIOD s ; chacun monte de ZZZ_RISE px en ZZZ_LIFE s [D].
const ZZZ_PERIOD: float = 0.9
const ZZZ_LIFE: float = 2.4
const ZZZ_RISE: Vector2 = Vector2(34.0, -78.0)
const ZZZ_COLOR := Color(0.93, 0.95, 1.0, 0.95)
const ZZZ_OUTLINE := Color(0.16, 0.18, 0.36, 0.9)
const ZZZ_FONT_SIZE: int = 30

## Le lit vide (prop de la carte), relatif à ce nœud.
@export var bed_path: NodePath
@export var hero_texture: Texture2D
@export var heroine_texture: Texture2D
## Départ des « z », relatif à ce nœud (pieds du lit) : au-dessus de l'oreiller, côté droit.
@export var zzz_origin: Vector2 = Vector2(28.0, -196.0)
## Milieu du lit, relatif à ce nœud (cadrage de la caméra).
@export var focus_offset: Vector2 = Vector2(0.0, -120.0)

var _tucked: bool = false
var _timer: Timer
var _look: StringName = &""


## Montre le lit occupé de [param look] et lance les « z ». Faux (erreur) sans lit ni image.
func tuck_in(look: StringName, reduce_motion: bool = false) -> bool:
	var bed := get_node_or_null(bed_path)
	var sprite := bed.get_node_or_null(^"%Sprite") as Sprite2D if bed != null else null
	var texture := heroine_texture if look == LOOK_HEROINE else hero_texture
	if sprite == null or texture == null:
		push_error("SleeperBed : lit « %s » ou image introuvable" % bed_path)
		return false
	sprite.texture = texture
	# Origine aux pieds du lit (milieu du bas de l'image), comme le lit vide.
	sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	_tucked = true
	_look = look
	if reduce_motion:
		_add_z(zzz_origin + ZZZ_RISE * 0.5, false)
	else:
		_timer = Timer.new()
		_timer.wait_time = ZZZ_PERIOD
		_timer.timeout.connect(_add_z.bind(zzz_origin, true))
		add_child(_timer)
		_timer.start()
		_add_z(zzz_origin, true)
	return true


## Point que la caméra cadre (milieu du lit, monde).
func get_focus_point() -> Vector2:
	return global_position + focus_offset


func is_tucked_in() -> bool:
	return _tucked


## Apparence montrée par [method tuck_in] (&"" avant).
func get_look() -> StringName:
	return _look


## Nombre de « z » à l'écran (tests).
func get_z_count() -> int:
	var count := 0
	for child: Node in get_children():
		if child is Label:
			count += 1
	return count


func _add_z(at: Vector2, rising: bool) -> void:
	if not is_inside_tree():
		return
	var label := Label.new()
	label.text = "z"
	label.add_theme_font_size_override(&"font_size", ZZZ_FONT_SIZE)
	label.add_theme_color_override(&"font_color", ZZZ_COLOR)
	label.add_theme_color_override(&"font_outline_color", ZZZ_OUTLINE)
	label.add_theme_constant_override(&"outline_size", 6)
	label.position = at
	label.z_index = 10
	add_child(label)
	if not rising:
		return
	label.modulate.a = 0.0
	label.scale = Vector2(0.7, 0.7)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, ^"position", at + ZZZ_RISE, ZZZ_LIFE)
	tween.tween_property(label, ^"scale", Vector2(1.15, 1.15), ZZZ_LIFE)
	tween.tween_property(label, ^"modulate:a", 1.0, ZZZ_LIFE * 0.25)
	tween.chain().tween_callback(label.queue_free)
	var fade := label.create_tween()
	fade.tween_interval(ZZZ_LIFE * 0.55)
	fade.tween_property(label, ^"modulate:a", 0.0, ZZZ_LIFE * 0.45)
