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
## Recadrage du décor (lancer de l'adversaire, maquette 2) : zoom [param zoom] autour du point
## écran [param from], qui vient en [param to] ; zoom 1 : cadrage normal. Le [BattleStage]
## l'applique au décor peint.
signal framing_changed(zoom: float, from: Vector2, to: Vector2)

## Échelle de la texture `poke_ball.webp` (256 px) pour une taille voulue en px ; diamètre de la
## sphère visible dans la texture (≈ 240 px) : la Ball lancée garde ce diamètre, ronde.
const BALL_ART: float = 1.0 / 256.0
const BALL_VISIBLE: float = 240.0
## Rangée (maquette 1) : Balls actives à opacité pleine ; emplacements vides et éteints (K.O.)
## = Ball en niveaux de gris, claire pour un vide (nettement distincte d'une active, lisible sur
## le verre sombre), plus sombre pour un K.O. [D].
const BALL_FAINTED := Color(0.62, 0.62, 0.66, 0.75)
const BALL_EMPTY := Color(1.0, 1.0, 1.0, 0.95)
## Ombre au sol des dresseurs [D].
const SHADOW_COLOR := Color(0.05, 0.04, 0.02, 0.45)
## Éclat à l'arrivée de la Ball (Pokémon qui sort) [D].
const POP_COLOR := Color(1.0, 1.0, 1.0, 0.9)
const POP_SCALE: float = 3.0
## Traînée de la Ball : nombre de points, opacité de tête du trait et de son halo [D].
const TRAIL_POINTS: int = 18
const TRAIL_ALPHA: float = 0.95
const TRAIL_GLOW_ALPHA: float = 0.3
## Traînée peinte (`fx_trail`, bout épais à gauche côté Ball, pointe à droite) : point d'attache
## de la Ball et pointe, en part de la toile [D].
const TRAIL_ART_HEAD := Vector2(30.0 / 1340.0, 103.0 / 141.0)
const TRAIL_ART_TIP := Vector2(1320.0 / 1340.0, 132.0 / 141.0)
## Épaisseur du bout épais de la traînée peinte (part de la hauteur de la toile).
const TRAIL_ART_THICK: float = 60.0 / 141.0
## Part du vol où le décor reste recadré avant de revenir (la Ball passe son point d'arc) [D].
const FRAMING_HOLD: float = 0.5
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
var _trail_glow: Line2D
## Traînée peinte (null : traînée dessinée).
var _trail_art: Sprite2D
## Diamètre visible de la texture de la Ball lancée (px de la texture).
var _ball_visible: float = BALL_VISIBLE
## Recadrage courant du décor (0 : normal, 1 : celui du lancer).
var _framing: float = 0.0
var _pop: Sprite2D
var _cartouche: BallCartouche
var _row: Array[Sprite2D] = []
var _feet: Dictionary[BattleEvent.SideId, Vector2] = {}
## Taille réelle relative de chaque dresseur (données) : multiplie la hauteur de ses poses.
var _sizes: Dictionary[BattleEvent.SideId, float] = {}
var _tweens: Array[Tween] = []

## Hauteur visible (boîte alpha, px de la texture) par texture, mesurée une fois.
static var _visible_heights: Dictionary[Texture2D, float] = {}
## Ball en niveaux de gris des emplacements vides ou éteints, construite une fois.
static var _grey_ball: Texture2D


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
	# Traînée blanche fine et effilée (fine à la main, pleine à la Ball), sur un halo doux.
	_trail_glow = _make_trail(&"TrailGlow", TRAIL_GLOW_ALPHA)
	_trail = _make_trail(&"Trail", TRAIL_ALPHA)
	_trail_art = _make_sprite(&"TrailArt")
	_trail_art.centered = false
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
	_stand = {foe_side: foe, player_side: player}
	_throw = {foe_side: foe_throw, player_side: player_throw}
	var catalog := intro.get_catalog()
	_sizes = {foe_side: catalog.scale_of(intro.art_id()),
		player_side: catalog.surf_player_scale if intro.surf else catalog.player_scale}
	_set_framing(0.0)
	_setup_fx(catalog)
	for side: BattleEvent.SideId in [foe_side, player_side]:
		_setup_trainer(side, _image(side, "entry"))
		_apply_pose(side, &"entry")
		_sprite(side).visible = false
		_shadows[side].visible = false
	# Cartouche au-dessus de l'adversaire (maquette 1) : rectangle des données, Balls qui le
	# remplissent.
	var low := _frac(_point("cartouche_min"))
	var high := _frac(_point("cartouche_max"))
	var pad := _layout("cartouche_pad") * view.y
	var gap := _layout("ball_gap") * view.y
	_cartouche.box = high - low
	# Grand adversaire (Major Bob, Giovanni…) : le cartouche remonte pour ne jamais mordre sa tête,
	# ni à l'entrée ni pendant son lancer (poses agrandies).
	var head := _foe_head_top()
	if high.y > head - pad:
		var lift := minf(high.y - (head - pad), maxf(low.y - pad, 0.0))
		low.y -= lift
		high.y -= lift
	_cartouche.position = ((low + high) / 2.0).round()
	var slots := float(TrainerIntro.SLOTS)
	var size := minf(_cartouche.box.y - 2.0 * pad,
		(_cartouche.box.x - 2.0 * pad - (slots - 1.0) * gap) / slots)
	var inner := slots * size + (slots - 1.0) * gap
	for i: int in _row.size():
		var sprite := _row[i]
		sprite.position = Vector2(-inner / 2.0 + size * 0.5 + i * (size + gap), 0.0)
		sprite.scale = Vector2.ONE * size * BALL_ART
		var state := intro.balls[i] if i < intro.balls.size() else TrainerIntro.Ball.EMPTY
		sprite.texture = BattleStage.BALL_TEXTURE if state == TrainerIntro.Ball.FULL \
			else grey_ball()
		sprite.modulate = _ball_color(state)
		sprite.visible = false
	_cartouche.modulate.a = 0.0
	_cartouche.visible = false
	_cartouche.queue_redraw()


## Coroutine : les deux dresseurs glissent vers leur pose [param pose_name] (« entry »,
## « vs » : positions propres à la séquence « VS », dresseurs entiers sous les banderoles) en
## [param duration] s ; ombres comprises.
func move_to_pose(pose_name: StringName, duration: float) -> void:
	if _intro == null:
		return
	var tween := _new_tween()
	tween.set_parallel(true)
	for side: BattleEvent.SideId in [BattleEvent.SideId.FOE, BattleEvent.SideId.PLAYER]:
		var target := _pose_rect(side, pose_name)
		var sprite := _sprite(side)
		_swap_texture(sprite, _image(side, String(pose_name)))
		var scale := Vector2.ONE * _scale_for(sprite.texture, target.size.y)
		tween.tween_property(sprite, ^"position", target.position, duration) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(sprite, ^"scale", scale, duration) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_shadows[side], ^"position", target.position, duration) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_shadows[side], ^"scale", _shadow_scale(sprite, scale.y), duration)
		_feet[side] = target.position
	# Le cartouche s'efface pendant le « VS » (banderoles au-dessus) et revient ensuite.
	if _cartouche.visible:
		tween.tween_property(_cartouche, ^"modulate:a", 1.0 if pose_name == &"entry" else 0.0,
			duration)
	await _play(tween)


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


## Coroutine (étapes FOE_SEND / PLAYER_SEND) : le dresseur de [param side] se met en garde et
## se rapproche (pose « throw ») ; au lancer de l'adversaire, le cadrage change vraiment
## (maquette 2) : le décor est recadré (« framing »), le joueur passe en garde au premier plan.
## Puis la pose de lancer (image « release »), la Ball part de la main en arc (traînée blanche
## effilée) vers le terrain ; le décor revient à son cadrage pendant la seconde moitié du vol ; à
## l'arrivée l'éclat de la sortie et [param on_landed] (le Pokémon apparaît) ; le dresseur
## accompagne un court instant ([code]send_linger[/code]) puis recule latéralement en fondu. Le
## cartouche reste au-dessus de l'adversaire jusqu'à son lancer, puis s'efface.
func play_send(side: BattleEvent.SideId, on_landed: Callable) -> void:
	if _intro == null:
		return
	var foe := side == BattleEvent.SideId.FOE
	step_started.emit(TrainerIntro.Step.FOE_SEND if foe else TrainerIntro.Step.PLAYER_SEND)
	var catalog := _intro.get_catalog()
	var windup := catalog.duration("send_windup")
	var throw := catalog.duration("send_throw")
	var linger := catalog.duration("send_linger")
	var exit := catalog.duration("send_exit")
	var sprite := _sprite(side)
	var toward := -1.0 if foe else 1.0
	var framed := foe and _intro.slide and catalog.framing_zoom > 1.0
	# Garde : rapprochement vers la pose de lancer (interpolé), corps qui recule ; au lancer de
	# l'adversaire, le joueur passe aussi en garde au premier plan et le décor se recadre.
	var guard := _new_tween()
	guard.set_parallel(true)
	var movers: Array[BattleEvent.SideId] = [side]
	var mine := BattleEvent.SideId.PLAYER
	if foe and _player.visible:
		movers.append(mine)
	for mover: BattleEvent.SideId in movers:
		var mover_sprite := _sprite(mover)
		var pose := _pose_rect(mover, &"throw")
		_swap_texture(mover_sprite, _image(mover, "guard"))
		var scale := _scale_for(mover_sprite.texture, pose.size.y)
		guard.tween_property(mover_sprite, ^"position", pose.position, windup) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		guard.tween_property(mover_sprite, ^"scale", Vector2.ONE * scale, windup) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		guard.tween_property(_shadows[mover], ^"position", pose.position, windup) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		guard.tween_property(_shadows[mover], ^"scale", _shadow_scale(mover_sprite, scale),
			windup)
		_feet[mover] = pose.position
	guard.tween_property(sprite, ^"rotation", -_layout("windup_tilt") * toward, windup)
	if framed:
		guard.tween_method(_set_framing, _framing, 1.0, windup) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await _play(guard)
	if _intro == null:
		return
	var height := _pose_rect(side, &"throw").size.y
	# Libération : pose de lancer (image dédiée, sinon extension du corps vers le terrain).
	var throw_texture: Texture2D = _image(side, "release") if catalog.uses_throw_image(
		_side_key(side), "release") else null
	if throw_texture != null and throw_texture != sprite.texture:
		# Même échelle que la pose de garde (les poses d'un personnage sont peintes à la même
		# échelle, pieds sur le bord bas).
		var keep := sprite.scale
		_swap_texture(sprite, throw_texture)
		sprite.scale = keep
	sprite.rotation = 0.0 if throw_texture != null else sprite.rotation
	var player_hand := catalog.surf_player_hand if _intro.surf else _point("player_hand")
	var hand := _feet[side] + (catalog.hand_of(_intro.art_id()) if foe else player_hand) * height
	var via := _frac(_point("foe_via" if foe else "player_via"))
	var target := _frac(_point("foe_target" if foe else "player_target"))
	# Contrôle de la courbe de Bézier qui passe par « via » à mi-parcours.
	var control := 2.0 * via - (hand + target) / 2.0
	var diameter := _layout("ball_diameter") * _view.x
	_ball.position = hand
	_ball.rotation = 0.0
	_ball.scale = Vector2.ONE * diameter / _ball_visible
	_ball.modulate = Color.WHITE
	_ball.visible = true
	_trail.clear_points()
	_trail_glow.clear_points()
	_trail.width = _layout("trail_width") * _view.x
	_trail_glow.width = _trail.width * _layout("trail_glow")
	var painted := _trail_art.texture != null
	for line: CanvasItem in [_trail, _trail_glow, _trail_art]:
		line.modulate.a = 1.0
		line.visible = line != _trail or not painted
	var tween := _new_tween()
	tween.set_parallel(true)
	if throw_texture == null:
		tween.tween_property(sprite, ^"rotation", _layout("windup_tilt") * toward, throw * 0.3)
	tween.tween_method(_set_flight.bind(hand, control, target), 0.0, 1.0, throw)
	if foe:
		tween.tween_property(_cartouche, ^"modulate:a", 0.0, throw)
	# Le décor revient à son cadrage pendant la seconde moitié du vol (le Pokémon sort sur le
	# cadrage du combat) ; l'adversaire revient avec lui à sa place de l'entrée.
	if framed:
		var back := throw * (1.0 - FRAMING_HOLD)
		var hold := throw * FRAMING_HOLD
		tween.tween_method(_set_framing, 1.0, 0.0, back).set_delay(hold) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var entry := _pose_rect(side, &"entry")
		var scale := sprite.scale / catalog.framing_zoom
		tween.tween_property(sprite, ^"position", entry.position, back).set_delay(hold) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(sprite, ^"scale", scale, back).set_delay(hold) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_shadows[side], ^"position", entry.position, back) \
			.set_delay(hold).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_shadows[side], ^"scale", _shadow_scale(sprite, scale.y), back) \
			.set_delay(hold)
		_feet[side] = entry.position
	# La Ball arrive : le Pokémon sort (éclat), la traînée s'efface.
	tween.tween_callback(func() -> void:
		_ball.visible = false
		_pop.position = target
		_pop.visible = true
		if on_landed.is_valid():
			on_landed.call()).set_delay(throw)
	tween.tween_method(_set_pop, 0.0, 1.0, linger + exit).set_delay(throw)
	for line: CanvasItem in [_trail, _trail_glow, _trail_art]:
		tween.tween_property(line, ^"modulate:a", 0.0, linger).set_delay(throw)
	# Il accompagne un instant, puis recule latéralement avec un fondu court.
	var slide := _layout("trainer_slide") * _view.y if _intro.slide else 0.0
	var rest: Vector2 = _feet[side]
	var away := rest + Vector2(slide if foe else -slide, 0.0)
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
	_trail_glow.visible = false
	_trail_art.visible = false
	if foe:
		_cartouche.visible = false
	if framed:
		_set_framing(0.0)


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
	for sprite: Node2D in [_foe, _player, _ball, _pop, _trail, _trail_glow, _trail_art,
			_cartouche]:
		if sprite != null:
			sprite.visible = false
			sprite.modulate = Color.WHITE
			sprite.rotation = 0.0
	for shadow: Sprite2D in _shadows.values():
		shadow.visible = false
	for line: Line2D in [_trail, _trail_glow]:
		if line != null:
			line.clear_points()
	if _framing != 0.0:
		_set_framing(0.0)


func _setup_trainer(side: BattleEvent.SideId, texture: Texture2D) -> void:
	var sprite := _sprite(side)
	_swap_texture(sprite, texture)
	sprite.modulate = Color.WHITE
	sprite.rotation = 0.0


## Image du dresseur de [param side] au moment [param phase] (données « images ») : sa pose de
## lancer si elle est demandée et existe, sinon sa pose debout.
func _image(side: BattleEvent.SideId, phase: String) -> Texture2D:
	var catalog := _intro.get_catalog() if _intro != null else null
	var throw: Texture2D = _throw.get(side)
	if catalog != null and throw != null and catalog.uses_throw_image(_side_key(side), phase):
		return throw
	return _stand.get(side)


## y du haut de la tête de l'adversaire (px de l'écran) le plus haut, à l'entrée (pose « entry »)
## et au lâcher de sa Ball (pose « throw », image de lancer à l'échelle de la pose de garde).
func _foe_head_top() -> float:
	var side := BattleEvent.SideId.FOE
	var entry := _pose_rect(side, &"entry")
	var top := entry.position.y - entry.size.y
	var guard := _image(side, "guard")
	var release := _image(side, "release")
	if guard != null and release != null:
		var thrown := _pose_rect(side, &"throw")
		top = minf(top, thrown.position.y - thrown.size.y
			* visible_height(release) / maxf(visible_height(guard), 1.0))
	return top


static func _side_key(side: BattleEvent.SideId) -> String:
	return "foe" if side == BattleEvent.SideId.FOE else "player"


## Change l'image de [param sprite] (pieds au bas de l'image, à l'origine), sans toucher à son
## échelle.
static func _swap_texture(sprite: Sprite2D, texture: Texture2D) -> void:
	if texture == null:
		return
	sprite.texture = texture
	sprite.centered = true
	sprite.offset = Vector2(0.0, -texture.get_height() / 2.0)


## Ball et traînée peintes ([member TrainerIntroCatalog.fx_ball] / [code]fx_trail[/code]) si
## elles existent, sinon la Poké Ball du jeu et une traînée dessinée.
func _setup_fx(catalog: TrainerIntroCatalog) -> void:
	var ball := _load_optional(catalog.fx_ball)
	_ball.texture = ball if ball != null else BattleStage.BALL_TEXTURE
	_ball_visible = visible_width(ball) if ball != null else BALL_VISIBLE
	_trail_art.texture = _load_optional(catalog.fx_trail)


static func _load_optional(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## Recadrage du décor à [param k] (0 : normal, 1 : celui du lancer de l'adversaire).
func _set_framing(k: float) -> void:
	_framing = k
	var catalog := _intro.get_catalog() if _intro != null else null
	if catalog == null or _view == Vector2.ZERO:
		framing_changed.emit(1.0, Vector2.ZERO, Vector2.ZERO)
		return
	var from := catalog.framing_from * _view
	framing_changed.emit(lerpf(1.0, catalog.framing_zoom, k), from,
		from.lerp(catalog.framing_to * _view, k))


## Recadrage courant du décor (0 : normal, 1 : lancer), tests.
func get_framing() -> float:
	return _framing


## Ball en niveaux de gris (emplacements vides ou éteints de la rangée), éclaircie.
static func grey_ball() -> Texture2D:
	if _grey_ball == null:
		var image := BattleStage.BALL_TEXTURE.get_image()
		if image.is_compressed():
			image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		for y: int in image.get_height():
			for x: int in image.get_width():
				var c := image.get_pixel(x, y)
				var v := 0.42 + 0.4 * (c.r * 0.3 + c.g * 0.59 + c.b * 0.11)
				image.set_pixel(x, y, Color(v, v, v * 1.03, c.a))
		_grey_ball = ImageTexture.create_from_image(image)
	return _grey_ball


## Largeur visible de [param texture] (boîte alpha).
static func visible_width(texture: Texture2D) -> float:
	var image := texture.get_image()
	if image == null:
		return float(texture.get_width())
	if image.is_compressed():
		image.decompress()
	var used := image.get_used_rect()
	return float(used.size.x) if used.size.x > 0 else float(texture.get_width())


## Place le dresseur de [param side] (et son ombre) dans sa pose [param pose_name].
func _apply_pose(side: BattleEvent.SideId, pose_name: StringName) -> void:
	var rect := _pose_rect(side, pose_name)
	var sprite := _sprite(side)
	_apply_texture(sprite, sprite.texture, rect.size.y)
	sprite.position = rect.position
	_feet[side] = rect.position
	var shadow := _shadows[side]
	shadow.position = rect.position
	shadow.scale = _shadow_scale(sprite, sprite.scale.y)


## Pose [param pose_name] du dresseur de [param side] en pixels : position = pieds, taille.y =
## hauteur affichée.
func _pose_rect(side: BattleEvent.SideId, pose_name: StringName) -> Rect2:
	var pose := _intro.get_catalog().pose(String(pose_name),
		"foe" if side == BattleEvent.SideId.FOE else "player") if _intro != null else Vector3.ZERO
	return Rect2(_frac(Vector2(pose.x, pose.y)),
		Vector2(0.0, pose.z * _view.y * _sizes.get(side, 1.0)))


## Hauteur visible de [param texture] : boîte des pixels non transparents (art peint posé sur
## une toile), sinon la texture entière.
static func visible_height(texture: Texture2D) -> float:
	if texture == null:
		return 1.0
	if not _visible_heights.has(texture):
		var image := texture.get_image()
		var height := float(texture.get_height())
		if image != null:
			if image.is_compressed():
				image.decompress()
			var used := image.get_used_rect()
			if used.size.y > 0:
				height = float(texture.get_height() - used.position.y)
		_visible_heights[texture] = height
	return _visible_heights[texture]


## Échelle qui donne à [param texture] une silhouette de [param height] px (pieds au bas).
static func _scale_for(texture: Texture2D, height: float) -> float:
	return height / maxf(visible_height(texture), 1.0)


## Échelle de l'ombre au sol d'un dresseur affiché à l'échelle [param scale].
func _shadow_scale(sprite: Sprite2D, scale: float) -> Vector2:
	var width := sprite.texture.get_width() * scale * _layout("shadow_width") * 2.0
	return Vector2(width, width * _layout("shadow_flatten")) / 128.0


## Pose [param texture] sur [param sprite], pieds (bas de l'image) à l'origine, à
## [param height] px de haut.
func _apply_texture(sprite: Sprite2D, texture: Texture2D, height: float) -> void:
	sprite.texture = texture
	sprite.centered = true
	sprite.offset = Vector2(0.0, -texture.get_height() / 2.0)
	sprite.scale = Vector2.ONE * _scale_for(texture, height)


func _sprite(side: BattleEvent.SideId) -> Sprite2D:
	return _foe if side == BattleEvent.SideId.FOE else _player


func _ball_color(state: TrainerIntro.Ball) -> Color:
	match state:
		TrainerIntro.Ball.FAINTED:
			return BALL_FAINTED
		TrainerIntro.Ball.EMPTY:
			return BALL_EMPTY
	return Color.WHITE


## Vol de la Ball à [param t] sur la courbe de Bézier ([param from], [param control],
## [param to]) ; la traînée suit la courbe derrière la Ball (au plus « trail_window » du vol,
## depuis la main au début), effilée vers l'arrière.
func _set_flight(t: float, from: Vector2, control: Vector2, to: Vector2) -> void:
	_ball.position = _bezier(from, control, to, t)
	_ball.rotation = t * TAU * 1.5
	var start := maxf(t - _layout("trail_window"), 0.0)
	if _trail_art.texture != null:
		_place_trail_art(_ball.position, _bezier(from, control, to, start))
	for line: Line2D in [_trail, _trail_glow]:
		line.clear_points()
		for i: int in TRAIL_POINTS + 1:
			line.add_point(_bezier(from, control, to,
				lerpf(start, t, float(i) / float(TRAIL_POINTS))))


## Traînée peinte tendue de la Ball [param head] à l'arrière [param tail] : bout épais sur la
## Ball, bosse de l'arc vers le haut (retournée quand la Ball va vers la droite).
func _place_trail_art(head: Vector2, tail: Vector2) -> void:
	var size := _trail_art.texture.get_size()
	var flip := tail.x < head.x
	_trail_art.flip_v = flip
	var anchor := TRAIL_ART_HEAD * size
	var tip := TRAIL_ART_TIP * size
	if flip:
		anchor.y = size.y - anchor.y
		tip.y = size.y - tip.y
	var span := tip - anchor
	var reach := tail - head
	_trail_art.offset = -anchor
	_trail_art.position = head
	_trail_art.rotation = reach.angle() - span.angle()
	# Longueur : du bout épais à la pointe ; épaisseur : au moins celle du trait (bout épais
	# ≈ TRAIL_ART_THICK de la toile = 2 × trail_width), pour rester bien visible.
	var along := reach.length() / maxf(span.length(), 1.0)
	var thick := 2.0 * _layout("trail_width") * _view.x / (TRAIL_ART_THICK * size.y)
	_trail_art.scale = Vector2(along, maxf(along, thick))


static func _bezier(a: Vector2, c: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(c, t).lerp(c.lerp(b, t), t)


func _set_pop(t: float) -> void:
	_pop.scale = Vector2.ONE * lerpf(0.5, POP_SCALE, 1.0 - pow(1.0 - t, 3.0))
	_pop.modulate = Color(POP_COLOR, POP_COLOR.a * (1.0 - t))


## Point écran d'un point en fractions de l'écran (x depuis la gauche, y depuis le haut).
func _frac(point: Vector2) -> Vector2:
	return (point * _view).round()


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


## Trait de la traînée : effilé (largeur nulle à l'arrière), dégradé transparent → blanc.
func _make_trail(line_name: StringName, alpha: float) -> Line2D:
	var line := Line2D.new()
	line.name = line_name
	line.begin_cap_mode = Line2D.LINE_CAP_NONE
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.antialiased = true
	line.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Effilée et effacée progressivement de la Ball vers la main (courbes douces : la traînée
	# reste visible sur toute sa longueur).
	var taper := Curve.new()
	taper.add_point(Vector2(0.0, 0.08))
	taper.add_point(Vector2(0.5, 0.55))
	taper.add_point(Vector2(1.0, 1.0))
	line.width_curve = taper
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, alpha))
	fade.add_point(0.35, Color(1, 1, 1, alpha * 0.55))
	line.gradient = fade
	line.set_meta(&"fade", fade)
	line.visible = false
	add_child(line)
	return line


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
