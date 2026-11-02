class_name TrainerIntroStage
extends Node2D
## Les deux dresseurs de l'entrée d'un combat de Dresseur, dans le décor peint (dossier 05 §3,
## décisions de Kevin du 2026-11-02 ; cible : maquettes `reference/entree-dresseur-ordinaire-v1`
## et `entree-dresseur-lancer-v1`) : le joueur **de dos, grand, au premier plan en bas à gauche**,
## l'adversaire plus loin à droite, tourné vers lui ; chacun **ancré au sol** par une ombre. Un
## cartouche de verre sombre **au-dessus de l'adversaire** porte la rangée de Poké Balls de son
## équipe ; il part avant l'arrivée des jauges. Au lancer : pose de lancer (image `_lancer` si elle
## existe, sinon un élan de la pose debout), Ball en arc avec traînée blanche vers le terrain, le
## dresseur accompagne l'apparition du Pokémon puis recule latéralement en fondu court.
## Présentation seulement : le plan ([TrainerIntro]) décide des étapes, des durées et des
## positions ; le [BattleStage] (son parent) fait apparaître les Pokémon. Tout en Tween ; aucun
## toucher n'est écouté (la séquence n'est jamais sautée) ; [member speed_scale] = 0 rend tout
## instantané.
##
## Images (repli automatique, l'art se branche sans code) : face
## `assets/sprites/trainers/battle/<classe>.webp` (+ `<classe>_lancer.webp`), sinon l'apparence du
## monde agrandie, sinon une silhouette ; dos `dos_<apparence>.webp` (+ `_lancer`), sinon le lancer
## de dos existant ([method BattleStage.thrower_texture]).

## Une étape du plan commence (tests, son).
signal step_started(step: TrainerIntro.Step)

## Échelle de la texture `poke_ball.webp` (256 px) pour une taille voulue en px.
const BALL_ART: float = 1.0 / 256.0
## Rangée : emplacement éteint (Pokémon K.O.) et vide (aucun Pokémon) [D].
const BALL_FAINTED := Color(0.35, 0.35, 0.38, 1.0)
const BALL_EMPTY := Color(0.55, 0.6, 0.68, 0.35)
## Ombre au sol des dresseurs [D].
const SHADOW_COLOR := Color(0.05, 0.04, 0.02, 0.45)
## Éclat à l'arrivée de la Ball (Pokémon qui sort) [D].
const POP_COLOR := Color(1.0, 1.0, 1.0, 0.9)
const POP_SCALE: float = 3.0
## Traînée de la Ball : nombre de points gardés, opacité de tête [D].
const TRAIL_POINTS: int = 14
const TRAIL_ALPHA: float = 0.85
## Élan de la pose debout quand aucune image de lancer n'existe : inclinaison (rad) et
## avancée (part de la hauteur affichée) [D].
const LUNGE_TILT: float = 0.07
const LUNGE_SHIFT: float = 0.05
## Silhouette de repli (aucune image de face ni apparence du monde) [D].
const SILHOUETTE := Color(0.08, 0.09, 0.12, 0.9)
const SILHOUETTE_SIZE := Vector2i(64, 160)
## Animation du monde dont la première image sert de repli au sprite de face.
const WORLD_FRAMES: Array[StringName] = [&"idle_down", &"walk_down"]
const INSTANT_STEP: float = 1000.0

## Multiplicateur des durées (0 = instantané, tests).
var speed_scale: float = 1.0

var _intro: TrainerIntro
var _view: Vector2 = Vector2.ZERO
var _foe: Sprite2D
var _player: Sprite2D
var _shadows: Dictionary[BattleEvent.SideId, Sprite2D] = {}
## Poses (debout, lancer) de chaque dresseur ; lancer null : élan de la pose debout.
var _stand: Dictionary[BattleEvent.SideId, Texture2D] = {}
var _throw: Dictionary[BattleEvent.SideId, Texture2D] = {}
var _ball: Sprite2D
var _trail: Line2D
var _pop: Sprite2D
var _cartouche: BallCartouche
var _row: Array[Sprite2D] = []
var _feet: Dictionary[BattleEvent.SideId, Vector2] = {}
var _tweens: Array[Tween] = []


func _ready() -> void:
	var halo := _radial_texture()
	for side: BattleEvent.SideId in [BattleEvent.SideId.FOE, BattleEvent.SideId.PLAYER]:
		var shadow := _make_sprite(StringName("%sShadow" % BattleEvent.SideId.find_key(side)),
			halo)
		shadow.modulate = SHADOW_COLOR
		_shadows[side] = shadow
	_foe = _make_sprite(&"FoeTrainer")
	_player = _make_sprite(&"PlayerTrainer")
	_cartouche = BallCartouche.new()
	_cartouche.name = &"BallCartouche"
	_cartouche.visible = false
	add_child(_cartouche)
	for i: int in TrainerIntro.SLOTS:
		var ball := _make_sprite(StringName("Ball%d" % i), BattleStage.BALL_TEXTURE)
		ball.reparent(_cartouche)
		ball.visible = true
		_row.append(ball)
	_trail = Line2D.new()
	_trail.name = &"Trail"
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, TRAIL_ALPHA))
	_trail.gradient = fade
	_trail.visible = false
	add_child(_trail)
	_ball = _make_sprite(&"ThrownBall", BattleStage.BALL_TEXTURE)
	_pop = _make_sprite(&"Pop", halo)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_pop.material = additive


## Sprite de face de l'adversaire de [param intro] ([param throw] : pose de lancer, null si elle
## n'existe pas) : l'image de la convention si elle existe ([param exists], défaut
## [method ResourceLoader.exists]), sinon (pose debout seulement) la première image de son
## apparence du monde, sinon une silhouette.
static func foe_texture(intro: TrainerIntro, exists: Callable = Callable(),
		throw: bool = false) -> Texture2D:
	var check := exists if exists.is_valid() else resource_exists
	var path := intro.front_path(check, throw) if intro != null else ""
	if not path.is_empty():
		var texture := load(path) as Texture2D
		if texture != null:
			return texture
	if throw:
		return null
	var world := world_texture(intro.world_sprite if intro != null else &"")
	return world if world != null else silhouette()


## Dos du joueur d'apparence [param look] ([param throw] : pose de lancer, null si elle n'existe
## pas) : `dos_<apparence>` s'il existe, sinon (pose debout) [param fallback], le lancer de dos
## existant (apparence et costume).
static func player_texture(intro: TrainerIntro, look: StringName, fallback: Texture2D,
		exists: Callable = Callable(), throw: bool = false) -> Texture2D:
	var check := exists if exists.is_valid() else resource_exists
	var path := intro.player_path(look, check, throw) if intro != null else ""
	if not path.is_empty():
		var texture := load(path) as Texture2D
		if texture != null:
			return texture
	return null if throw else fallback


## Première image de face de l'apparence du monde [param sprite] ([CharacterLook]), ou null.
static func world_texture(sprite: StringName) -> Texture2D:
	if sprite.is_empty():
		return null
	var look := CharacterLook.resolve(sprite)
	var frames := load(look.frames_path) as SpriteFrames if ResourceLoader.exists(
		look.frames_path) else null
	if frames == null:
		return null
	for animation: StringName in WORLD_FRAMES:
		if frames.has_animation(animation) and frames.get_frame_count(animation) > 0:
			return frames.get_frame_texture(animation, 0)
	return null


## Silhouette sombre de repli (aucune image).
static func silhouette() -> Texture2D:
	var image := Image.create(SILHOUETTE_SIZE.x, SILHOUETTE_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(SILHOUETTE)
	return ImageTexture.create_from_image(image)


static func resource_exists(path: String) -> bool:
	return ResourceLoader.exists(path)


## Prépare l'entrée de [param intro] sur une vue de [param view] px : les dresseurs hors champ,
## invisibles. [param foe] / [param player] : poses debout ; [param foe_throw] /
## [param player_throw] : poses de lancer (null : élan de la pose debout).
func begin(intro: TrainerIntro, view: Vector2, foe: Texture2D, player: Texture2D,
		foe_throw: Texture2D = null, player_throw: Texture2D = null) -> void:
	clear()
	_intro = intro
	_view = view
	var foe_side := BattleEvent.SideId.FOE
	var player_side := BattleEvent.SideId.PLAYER
	_feet[foe_side] = _screen(_point("foe_feet"))
	_feet[player_side] = _screen(_point("player_feet"))
	_stand = {foe_side: foe, player_side: player}
	_throw = {foe_side: foe_throw, player_side: player_throw}
	_setup_trainer(foe_side, _layout("foe_trainer_height"))
	_setup_trainer(player_side, _layout("player_trainer_height"))
	# Cartouche au-dessus de la tête de l'adversaire, décalé vers l'extérieur (maquette 1).
	var size := _layout("ball_size") * view.y
	var gap := _layout("ball_gap") * view.y
	var pad := _layout("cartouche_pad") * view.y
	var inner := Vector2(TrainerIntro.SLOTS * size + (TrainerIntro.SLOTS - 1) * gap, size)
	_cartouche.box = Vector2(inner.x + 2.0 * pad, inner.y + 2.0 * pad)
	var head := _feet[foe_side].y - _layout("foe_trainer_height") * view.y
	_cartouche.position = Vector2(_feet[foe_side].x + _point("cartouche_offset").x * view.y,
		head - _layout("cartouche_raise") * view.y - _cartouche.box.y / 2.0).round()
	for i: int in _row.size():
		var sprite := _row[i]
		sprite.position = Vector2(-inner.x / 2.0 + size * 0.5 + i * (size + gap), 0.0)
		sprite.scale = Vector2.ONE * size * BALL_ART
		sprite.modulate = _ball_color(intro.balls[i] if i < intro.balls.size()
			else TrainerIntro.Ball.EMPTY)
		sprite.visible = false
	_cartouche.modulate.a = 0.0
	_cartouche.visible = false
	_cartouche.queue_redraw()


## Coroutine (étape TRAINERS_IN) : les deux dresseurs entrent en glissant (fondu avec « Réduire
## les animations »), leur ombre au sol, puis le cartouche et ses Poké Balls, une à une.
func play_enter() -> void:
	if _intro == null:
		return
	step_started.emit(TrainerIntro.Step.TRAINERS_IN)
	var catalog := _intro.get_catalog()
	var duration := catalog.duration("trainers_in")
	var slide := _layout("trainer_slide") * _view.y if _intro.slide else 0.0
	var tween := _new_tween()
	tween.set_parallel(true)
	for side: BattleEvent.SideId in [BattleEvent.SideId.FOE, BattleEvent.SideId.PLAYER]:
		var sprite := _sprite(side)
		var feet: Vector2 = _feet[side]
		var from := feet + Vector2(slide if side == BattleEvent.SideId.FOE else -slide, 0.0)
		sprite.position = from
		sprite.modulate.a = 0.0
		sprite.visible = true
		tween.tween_property(sprite, ^"position", feet, duration) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, ^"modulate:a", 1.0, duration)
		var shadow := _shadows[side]
		shadow.position = from
		shadow.modulate.a = 0.0
		shadow.visible = true
		tween.tween_property(shadow, ^"position", feet, duration) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(shadow, ^"modulate:a", SHADOW_COLOR.a, duration)
	await _play(tween)
	var balls_in := catalog.duration("balls_in")
	var row := _new_tween()
	row.set_parallel(true)
	_cartouche.visible = true
	row.tween_property(_cartouche, ^"modulate:a", 1.0, balls_in * 0.4)
	var each := balls_in / float(_row.size())
	for i: int in _row.size():
		var sprite := _row[i]
		var rest := sprite.scale
		var color := sprite.modulate
		sprite.visible = true
		sprite.modulate = Color(color, 0.0)
		row.tween_property(sprite, ^"modulate:a", color.a, each).set_delay(each * i)
		if _intro.slide:
			sprite.scale = rest * 0.2
			row.tween_property(sprite, ^"scale", rest, each).set_delay(each * i) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _play(row)


## Coroutine (étapes FOE_SEND / PLAYER_SEND) : le dresseur de [param side] prend la pose de
## lancer, la Ball part de sa main en arc (traînée blanche) vers le terrain ; à son arrivée
## l'éclat de la sortie et [param on_landed] (le Pokémon apparaît) ; le dresseur accompagne un
## court instant ([code]send_linger[/code]) puis recule latéralement en fondu. Le cartouche part
## dès le lancer de l'adversaire (avant l'arrivée des jauges).
func play_send(side: BattleEvent.SideId, on_landed: Callable) -> void:
	if _intro == null:
		return
	var foe := side == BattleEvent.SideId.FOE
	step_started.emit(TrainerIntro.Step.FOE_SEND if foe else TrainerIntro.Step.PLAYER_SEND)
	var catalog := _intro.get_catalog()
	var throw := catalog.duration("send_throw")
	var linger := catalog.duration("send_linger")
	var exit := catalog.duration("send_exit")
	var sprite := _sprite(side)
	var feet: Vector2 = _feet[side]
	var height := _layout("foe_trainer_height" if foe else "player_trainer_height") * _view.y
	var hand := feet + _point("foe_hand" if foe else "player_hand") * height
	var target := _screen(_point("foe_ball_target" if foe else "player_ball_target"))
	# Pose de lancer : l'image dédiée, sinon un élan de la pose debout vers le terrain.
	var toward := -1.0 if foe else 1.0
	var throw_texture: Texture2D = _throw.get(side)
	var tween := _new_tween()
	tween.set_parallel(true)
	if throw_texture != null:
		_apply_texture(sprite, throw_texture, height)
	else:
		tween.tween_property(sprite, ^"rotation", LUNGE_TILT * toward, throw * 0.35)
		tween.tween_property(sprite, ^"position:x", feet.x + toward * LUNGE_SHIFT * height,
			throw * 0.35)
	var size := _layout("throw_ball_size") * _view.y
	_ball.position = hand
	_ball.rotation = 0.0
	_ball.scale = Vector2.ONE * size * BALL_ART
	_ball.modulate = Color.WHITE
	_ball.visible = true
	_trail.clear_points()
	_trail.width = _layout("trail_width") * _view.y
	_trail.modulate.a = 1.0
	_trail.visible = true
	tween.tween_method(_set_flight.bind(hand, target, _layout("throw_arc") * _view.y), 0.0,
		1.0, throw)
	if foe:
		tween.tween_property(_cartouche, ^"modulate:a", 0.0, throw)
	# La Ball arrive : le Pokémon sort (éclat), la traînée s'efface.
	tween.tween_callback(func() -> void:
		_ball.visible = false
		_pop.position = target
		_pop.visible = true
		if on_landed.is_valid():
			on_landed.call()).set_delay(throw)
	tween.tween_method(_set_pop, 0.0, 1.0, linger + exit).set_delay(throw)
	tween.tween_property(_trail, ^"modulate:a", 0.0, linger).set_delay(throw)
	# Il accompagne un instant, puis recule latéralement avec un fondu court.
	var slide := _layout("trainer_slide") * _view.y if _intro.slide else 0.0
	var away := feet + Vector2(slide if foe else -slide, 0.0)
	tween.tween_property(sprite, ^"rotation", 0.0, linger).set_delay(throw)
	tween.tween_property(sprite, ^"position", away, exit).set_delay(throw + linger) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, ^"modulate:a", 0.0, exit).set_delay(throw + linger)
	tween.tween_property(_shadows[side], ^"position", away, exit).set_delay(throw + linger) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_shadows[side], ^"modulate:a", 0.0, exit).set_delay(throw + linger)
	await _play(tween)
	sprite.visible = false
	_shadows[side].visible = false
	_pop.visible = false
	_trail.visible = false
	if foe:
		_cartouche.visible = false


## Dresseur de [param side] affiché (tests).
func is_trainer_visible(side: BattleEvent.SideId) -> bool:
	var sprite := _sprite(side)
	return sprite != null and sprite.visible and sprite.modulate.a > 0.0


## Sprite d'un dresseur (tests, captures).
func get_trainer(side: BattleEvent.SideId) -> Sprite2D:
	return _sprite(side)


## Ombre au sol d'un dresseur (tests).
func get_shadow(side: BattleEvent.SideId) -> Sprite2D:
	return _shadows.get(side)


## Cartouche de la rangée de Poké Balls (tests, captures).
func get_cartouche() -> Node2D:
	return _cartouche


## Emplacements de la rangée de Poké Balls (tests, captures).
func get_ball_row() -> Array[Sprite2D]:
	return _row


## Pieds (écran) du dresseur de [param side] (tests).
func get_feet(side: BattleEvent.SideId) -> Vector2:
	return _feet.get(side, Vector2.ZERO)


## Tout caché, tweens arrêtés (fin du combat, abandon).
func clear() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	_intro = null
	for sprite: Node2D in [_foe, _player, _ball, _pop, _trail, _cartouche]:
		if sprite != null:
			sprite.visible = false
			sprite.modulate = Color.WHITE
			sprite.rotation = 0.0
	for shadow: Sprite2D in _shadows.values():
		shadow.visible = false
	if _trail != null:
		_trail.clear_points()


func _setup_trainer(side: BattleEvent.SideId, height_share: float) -> void:
	var sprite := _sprite(side)
	var texture: Texture2D = _stand[side]
	var height := height_share * _view.y
	_apply_texture(sprite, texture, height)
	sprite.modulate = Color.WHITE
	sprite.rotation = 0.0
	sprite.visible = false
	var shadow := _shadows[side]
	var width := texture.get_width() * sprite.scale.x * _layout("shadow_width") * 2.0
	shadow.scale = Vector2(width, width * _layout("shadow_flatten")) / 128.0
	shadow.visible = false


## Pose [param texture] sur [param sprite], pieds (bas de l'image) à l'origine, à
## [param height] px de haut.
func _apply_texture(sprite: Sprite2D, texture: Texture2D, height: float) -> void:
	sprite.texture = texture
	sprite.centered = true
	sprite.offset = Vector2(0.0, -texture.get_height() / 2.0)
	sprite.scale = Vector2.ONE * height / maxf(float(texture.get_height()), 1.0)


func _sprite(side: BattleEvent.SideId) -> Sprite2D:
	return _foe if side == BattleEvent.SideId.FOE else _player


func _ball_color(state: TrainerIntro.Ball) -> Color:
	match state:
		TrainerIntro.Ball.FAINTED:
			return BALL_FAINTED
		TrainerIntro.Ball.EMPTY:
			return BALL_EMPTY
	return Color.WHITE


func _set_flight(t: float, from: Vector2, to: Vector2, arc: float) -> void:
	_ball.position = from.lerp(to, t) + Vector2(0.0, -arc * 4.0 * t * (1.0 - t))
	_ball.rotation = t * TAU * 2.0
	_trail.add_point(_ball.position)
	while _trail.get_point_count() > TRAIL_POINTS:
		_trail.remove_point(0)


func _set_pop(t: float) -> void:
	_pop.scale = Vector2.ONE * lerpf(0.5, POP_SCALE, 1.0 - pow(1.0 - t, 3.0))
	_pop.modulate = Color(POP_COLOR, POP_COLOR.a * (1.0 - t))


## Point écran d'un point en hauteurs d'écran (x depuis le centre, y depuis le haut).
func _screen(point: Vector2) -> Vector2:
	return Vector2(_view.x / 2.0 + point.x * _view.y, point.y * _view.y).round()


func _layout(key: String) -> float:
	return _intro.get_catalog().layout.get(key, 0.0) if _intro != null else 0.0


func _point(key: String) -> Vector2:
	return _intro.get_catalog().point(key) if _intro != null else Vector2.ZERO


func _radial_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var halo := GradientTexture2D.new()
	halo.gradient = gradient
	halo.fill = GradientTexture2D.FILL_RADIAL
	halo.fill_from = Vector2(0.5, 0.5)
	halo.fill_to = Vector2(1.0, 0.5)
	halo.width = 128
	halo.height = 128
	return halo


func _make_sprite(sprite_name: StringName, texture: Texture2D = null) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.visible = false
	add_child(sprite)
	return sprite


func _new_tween() -> Tween:
	var tween := create_tween()
	_tweens.append(tween)
	return tween


## Joue [param tween] à [member speed_scale] (0 : jusqu'à la fin, tout de suite) et attend.
func _play(tween: Tween) -> void:
	if speed_scale <= 0.0:
		tween.custom_step(INSTANT_STEP)
	else:
		tween.set_speed_scale(speed_scale)
	if tween.is_valid() and tween.is_running():
		await tween.finished
	_tweens.erase(tween)


## Cartouche de verre sombre (couleurs de l'interface) qui porte la rangée de Poké Balls,
## centré sur sa position.
class BallCartouche:
	extends Node2D

	var box: Vector2 = Vector2.ZERO

	func _draw() -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = UiTokens.PANEL_BG
		style.border_color = UiTokens.PANEL_BORDER
		style.set_border_width_all(2)
		style.set_corner_radius_all(UiTokens.RADIUS_SMALL)
		style.anti_aliasing = true
		draw_style_box(style, Rect2(-box / 2.0, box))
