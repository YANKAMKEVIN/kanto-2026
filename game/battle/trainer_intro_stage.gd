class_name TrainerIntroStage
extends Node2D
## Les deux dresseurs de l'entrée d'un combat de Dresseur, dans le décor peint (dossier 05 §3,
## décision de Kevin du 2026-11-02) : le joueur de dos à gauche, l'adversaire de face à droite,
## la rangée de Poké Balls de l'équipe adverse ; chacun lance son Pokémon et s'efface.
## Présentation seulement : le plan ([TrainerIntro]) décide des étapes et des durées ; le
## [BattleStage] (son parent) fait apparaître les Pokémon. Tout en Tween ; aucun toucher n'est
## écouté (la séquence n'est jamais sautée) ; [member speed_scale] = 0 rend tout instantané.
##
## Images : sprite de face `assets/sprites/trainers/battle/<classe>.webp` s'il existe, sinon
## l'apparence du monde de la classe agrandie (filtre linéaire, provisoire), sinon une silhouette.
## Le dos du joueur est celui du lancer ([method BattleStage.thrower_texture]).

## Une étape du plan commence (tests, son).
signal step_started(step: TrainerIntro.Step)

## Main du lanceur de dos par rapport à ses pieds (même repère que [constant
## BattleStage.THROWER_HAND]) ; main de l'adversaire de face, en part de sa hauteur affichée.
const FOE_HAND := Vector2(-0.22, -0.55)
## Échelle de la Ball lancée (texture `poke_ball.webp`, 256 px) et de celles de la rangée.
const BALL_ART: float = 1.0 / 256.0
## Rangée : emplacement éteint (Pokémon K.O.) et vide (aucun Pokémon) [D].
const BALL_FAINTED := Color(0.35, 0.35, 0.38, 1.0)
const BALL_EMPTY := Color(0.2, 0.22, 0.26, 0.45)
## Éclat à l'arrivée de la Ball (Pokémon qui sort) [D].
const POP_COLOR := Color(1.0, 1.0, 1.0, 0.9)
const POP_SCALE: float = 3.0
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
var _ball: Sprite2D
var _pop: Sprite2D
var _row: Array[Sprite2D] = []
var _foe_feet: Vector2 = Vector2.ZERO
var _player_feet: Vector2 = Vector2.ZERO
var _tweens: Array[Tween] = []


func _ready() -> void:
	_foe = _make_sprite(&"FoeTrainer")
	_player = _make_sprite(&"PlayerTrainer")
	var ball_texture := BattleStage.BALL_TEXTURE
	for i: int in TrainerIntro.SLOTS:
		_row.append(_make_sprite(StringName("Ball%d" % i), ball_texture))
	_ball = _make_sprite(&"ThrownBall", ball_texture)
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
	_pop = _make_sprite(&"Pop", halo)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_pop.material = additive


## Sprite de face de l'adversaire de [param intro] : l'image de la convention si elle existe
## ([param exists], défaut [method ResourceLoader.exists]), sinon la première image de son
## apparence du monde, sinon une silhouette. Jamais null.
static func foe_texture(intro: TrainerIntro, exists: Callable = Callable()) -> Texture2D:
	var check := exists if exists.is_valid() else resource_exists
	var path := intro.front_path(check) if intro != null else ""
	if not path.is_empty():
		var texture := load(path) as Texture2D
		if texture != null:
			return texture
	var world := world_texture(intro.world_sprite if intro != null else &"")
	return world if world != null else silhouette()


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


## Prépare l'entrée de [param intro] sur une vue de [param view] px : les dresseurs hors champ,
## invisibles. [param foe] / [param player] : sprite de face de l'adversaire, dos du joueur.
func begin(intro: TrainerIntro, view: Vector2, foe: Texture2D, player: Texture2D) -> void:
	clear()
	_intro = intro
	_view = view
	_foe_feet = BattleLayout.feet(BattleLayout.FOE_FEET, view)
	_player_feet = BattleStage.thrower_feet(view)
	_setup_trainer(_foe, foe, _layout(&"foe_trainer_height") * view.y / maxf(
		float(foe.get_height()), 1.0))
	_setup_trainer(_player, player, BattleStage.THROWER_SCALE)
	var size := _layout(&"ball_size") * view.y
	var gap := _layout(&"ball_gap") * view.y
	var card := BattleHudLayout.rect(BattleHudLayout.Slot.FOE_CARD, view)
	for i: int in _row.size():
		var sprite := _row[i]
		sprite.position = Vector2(card.position.x + size * 0.5 + i * (size + gap),
			card.get_center().y).round()
		sprite.scale = Vector2.ONE * size * BALL_ART
		sprite.modulate = _ball_color(intro.balls[i] if i < intro.balls.size()
			else TrainerIntro.Ball.EMPTY)
		sprite.visible = false


## Coroutine (étape TRAINERS_IN) : les deux dresseurs entrent en glissant (fondu avec « Réduire
## les animations »), puis les Poké Balls de la rangée apparaissent une à une.
func play_enter() -> void:
	if _intro == null:
		return
	step_started.emit(TrainerIntro.Step.TRAINERS_IN)
	var catalog := _intro.get_catalog()
	var duration := catalog.duration("trainers_in")
	var slide := _layout(&"trainer_slide") * _view.y if _intro.slide else 0.0
	var tween := _new_tween()
	tween.set_parallel(true)
	for pair: Array in [[_foe, _foe_feet, slide], [_player, _player_feet, -slide]]:
		var sprite: Sprite2D = pair[0]
		var feet: Vector2 = pair[1]
		sprite.position = feet + Vector2(pair[2], 0.0)
		sprite.modulate.a = 0.0
		sprite.visible = true
		tween.tween_property(sprite, ^"position", feet, duration) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, ^"modulate:a", 1.0, duration)
	await _play(tween)
	var balls_in := catalog.duration("balls_in")
	var row := _new_tween()
	row.set_parallel(true)
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


## Coroutine (étapes FOE_SEND / PLAYER_SEND) : le dresseur de [param side] lance sa Poké Ball
## vers [param target] (point écran où sort le Pokémon) et s'efface en glissant hors champ ;
## l'éclat de la sortie part à l'arrivée de la Ball. La rangée de l'adversaire s'efface avec lui.
## [param on_landed] : appelé à l'arrivée de la Ball (le Pokémon apparaît).
func play_send(side: BattleEvent.SideId, target: Vector2, on_landed: Callable) -> void:
	if _intro == null:
		return
	var foe := side == BattleEvent.SideId.FOE
	step_started.emit(TrainerIntro.Step.FOE_SEND if foe else TrainerIntro.Step.PLAYER_SEND)
	var catalog := _intro.get_catalog()
	var throw := catalog.duration("send_throw")
	var exit := catalog.duration("send_exit")
	var sprite := _foe if foe else _player
	var feet := _foe_feet if foe else _player_feet
	var hand := feet + (FOE_HAND * sprite.texture.get_height() * sprite.scale.y if foe
		else BattleStage.THROWER_HAND * BattleStage.THROWER_SCALE)
	var size := _layout(&"ball_size") * _view.y
	_ball.position = hand
	_ball.rotation = 0.0
	_ball.scale = Vector2.ONE * size * BALL_ART
	_ball.modulate = Color.WHITE
	_ball.visible = true
	var slide := _layout(&"trainer_slide") * _view.y if _intro.slide else 0.0
	var tween := _new_tween()
	tween.set_parallel(true)
	tween.tween_method(_set_flight.bind(hand, target, _layout(&"throw_arc") * _view.y), 0.0,
		1.0, throw)
	# La Ball arrive : le Pokémon sort (éclat), le dresseur s'efface.
	tween.tween_callback(func() -> void:
		_ball.visible = false
		_pop.position = target
		_pop.visible = true
		if on_landed.is_valid():
			on_landed.call()).set_delay(throw)
	tween.tween_method(_set_pop, 0.0, 1.0, exit).set_delay(throw)
	tween.tween_property(sprite, ^"position", feet + Vector2(slide if foe else -slide, 0.0),
		exit).set_delay(throw).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, ^"modulate:a", 0.0, exit).set_delay(throw)
	if foe:
		for ball: Sprite2D in _row:
			tween.tween_property(ball, ^"modulate:a", 0.0, exit).set_delay(throw)
	await _play(tween)
	sprite.visible = false
	_pop.visible = false


## Dresseur de [param side] affiché (tests).
func is_trainer_visible(side: BattleEvent.SideId) -> bool:
	var sprite := _foe if side == BattleEvent.SideId.FOE else _player
	return sprite != null and sprite.visible and sprite.modulate.a > 0.0


## Sprite d'un dresseur (tests, captures).
func get_trainer(side: BattleEvent.SideId) -> Sprite2D:
	return _foe if side == BattleEvent.SideId.FOE else _player


## Emplacements de la rangée de Poké Balls (tests, captures).
func get_ball_row() -> Array[Sprite2D]:
	return _row


## Tout caché, tweens arrêtés (fin du combat, abandon).
func clear() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	_intro = null
	for sprite: Sprite2D in [_foe, _player, _ball, _pop] + _row:
		if sprite != null:
			sprite.visible = false
			sprite.modulate = Color.WHITE


static func resource_exists(path: String) -> bool:
	return ResourceLoader.exists(path)


func _setup_trainer(sprite: Sprite2D, texture: Texture2D, scale: float) -> void:
	sprite.texture = texture
	sprite.centered = true
	sprite.offset = Vector2(0.0, -texture.get_height() / 2.0)
	sprite.scale = Vector2.ONE * scale
	sprite.modulate = Color.WHITE
	sprite.visible = false


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


func _set_pop(t: float) -> void:
	_pop.scale = Vector2.ONE * lerpf(0.5, POP_SCALE, 1.0 - pow(1.0 - t, 3.0))
	_pop.modulate = Color(POP_COLOR, POP_COLOR.a * (1.0 - t))


func _layout(key: StringName) -> float:
	return _intro.get_catalog().layout.get(String(key), 0.0) if _intro != null else 0.0


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
