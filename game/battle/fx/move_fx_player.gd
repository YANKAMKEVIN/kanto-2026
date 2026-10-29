class_name MoveFxPlayer
extends Node2D
## Lecteur d'effets de combat (chantier Combat vivant, `docs/tech/combat-vivant.md` §2.7, §3.1) :
## exécute un [MoveFxPlan] sur une [MoveFxStage]. Un nœud, enfant du calque du combat, au-dessus
## des sprites et sous la HUD.
##
## Un `Tween` maître par attaque : les repères sonores ([signal fx_cue]) et les éclats de
## particules partent au début de leur phase ; tout le reste (lanceur, cible, projectile, rayon,
## caméra, lumière) est une fonction du temps, [method pose] : la galerie d'effets peut figer
## n'importe quel instant, et [member speed_scale] = 0 joue tout de suite la fin (tests).
## À la fin, sprites, caméra et décor sont rendus à leur repos ; les particules finissent leur vie
## (retombée, couche 8 du §2.9).
##
## Briques (`bricks.travel` de la famille) : `dash` (le lanceur traverse, Contact), `bolt` (arc
## brisé, Électrique), `beam` / `ice_beam` / `jet` (rayon qui s'allonge), vide (l'effet reste sur
## le lanceur : statut positif, soin), sinon un projectile lumineux. Formes dessinées en code :
## échafaudage de CV.0, remplacé par l'art (flipbooks, §2.9, §3.4).
## Valeurs visuelles [D] (règle 4), à régler sur le S24.

signal fx_cue(cue: StringName, move_id: StringName)
signal finished

const INSTANT_STEP: float = 1000.0
## Contact (§3.1) : recul de 4 % et écrasement de 6 % à l'appui, course sur 30 % de la distance,
## changement d'échelle avec la profondeur, retour en arc.
const CROUCH_BACK: float = 0.04
const CROUCH_SQUASH: float = 0.06
const DASH_REACH: float = 0.30
const DEPTH_SCALE: float = 0.08
const RETURN_ARC: float = 14.0
## Impact : arrêt sur image (hit-stop, 40 à 70 ms, §2.9), tremblement et écrasement de la cible.
const HIT_STOP: float = 0.05
const HIT_SHAKE: float = 10.0
const HIT_SHAKE_WAVES: float = 3.0
const HIT_SQUASH: float = 0.05
const HIT_BRIGHT := Color(1.45, 1.45, 1.45, 1.0)
const HIT_DIM := Color(0.75, 0.75, 0.75, 1.0)
## Retour de la caméra au cadrage normal (§4 du dossier 05 : « retour immédiat »).
const CAMERA_RETURN: float = 0.15
## Lueur du lanceur (anticipation d'un effet à distance, charge, statut positif).
const CHARGE_GLOW := Color(1.35, 1.35, 1.35, 1.0)
## Projectile : taille en hauteurs d'écran ; rétrécit en s'éloignant (vers l'adversaire).
const PROJECTILE_SIZE: float = 0.12
const PROJECTILE_FAR: float = 0.6
const PROJECTILE_NEAR: float = 1.4
## Raté : le projectile file au-delà de la cible, décalé de côté.
const MISS_OVERSHOOT: float = 0.45
const MISS_SIDE: float = 0.18
## Arc électrique : segments, écart des brisures (hauteurs d'écran), régénérations par trajet.
const BOLT_SEGMENTS: int = 9
const BOLT_JITTER: float = 0.035
const BOLT_REDRAWS: int = 3
const BOLT_WIDTH: float = 18.0
const BEAM_WIDTH: float = 34.0
## Rayons et jets dessinés en code (briques `jet`, `beam`, `ice_beam`, quand la famille n'a pas
## d'art pour son trajet : Laser Glace, Ultralaser…) : épais (Kevin, vidéo CV.3, jet d'eau « trop
## fin » ; même défaut relevé sur les rayons à la relecture de la vidéo CV.1), cœur clair plus
## large, halo additif. [constant BEAM_WIDTH] : trait fin, plus employé par défaut.
const JET_WIDTH: float = 96.0
const JET_CORE_WIDTH: float = 0.55
const JET_HALO_WIDTH: float = 2.0
const JET_HALO_ALPHA: float = 0.4
## Marques d'impact du Contact : griffe (3 entailles), crocs (2 arcs), perçant (1 trait).
const MARK_WIDTH: float = 14.0
## Formes en deux couches (§2.9, lisibles sur un décor de plein jour) : un corps opaque de la
## couleur de l'élément (mélange normal), un cœur clair plus fin, un halo additif plus large.
const CORE_WIDTH: float = 0.4
const HALO_SIZE: float = 2.4
const HALO_ALPHA: float = 0.55
const MARK_LENGTH: float = 0.55
## Projectile fait d'une seule particule peinte (caillou, orbe) : part de [constant ART_PROJECTILE]
## (un flipbook a des marges, une particule remplit son image).
const ART_PARTICLE_PROJECTILE: float = 0.45
## Art peint (CV.1, [FxArt]) [D] : cadence des flipbooks, tailles en hauteurs d'écran (projectile,
## épaisseur de l'arc, étincelles des joues), en hauteurs de la cible (impact, marque du Contact).
const FLIP_FPS: float = 24.0
const ART_PROJECTILE: float = 0.45
const ART_BOLT_HEIGHT: float = 0.32
const ART_CHEEKS: float = 0.10
const ART_IMPACT: float = 1.7
const ART_STAMP: float = 0.8
const ART_PARTICLE: float = 0.05
## Art de lumière (mélange additif) : un corps en mélange normal dessous (l'alpha de l'image suit
## sa luminance), sans quoi il disparaît sur un décor de plein jour (vu en capture) ; opacité [D].
const ART_BODY_ALPHA: float = 0.85
## Effets sur soi (statut positif, soin) : taille de l'art d'impact en hauteurs du lanceur.
const ART_SELF: float = 1.15
## Ondes en série (CV.1, briques `rings` du Psy et `sound_waves` du Son) : trois copies du trajet,
## décalées de [constant WAVE_LAG] de la phase, en hauteurs d'écran.
const WAVE_COUNT: int = 3
const WAVE_LAG: float = 0.22
const WAVE_SIZE: float = 0.22
## Psy (`distortion`) : la cible ondule (écrasement en opposition) au lieu de trembler ; Son
## (`vibrate`) : la cible vibre vite et peu.
const DISTORT_SQUASH: float = 0.09
const DISTORT_WAVES: float = 2.5
const VIBRATE_WAVES: float = 9.0
const VIBRATE_SHAKE: float = 5.0
## Modificateurs (CV.1, §3.2) [D] : flux du drain (taille en hauteurs d'écran, courbe), anneau du
## piège (rayon en largeurs de la cible, tours par seconde, taille), recul du contrecoup (px), chute
## du Pied Sauté raté (px), K.O. en un coup (arrêt sur image et tremblement multipliés).
const STREAM_SIZE: float = 0.10
const STREAM_ARC: float = 0.12
const TRAP_RADIUS: float = 0.55
const TRAP_TURNS: float = 1.2
const TRAP_SIZE: float = 0.15
const RECOIL_SHAKE: float = 9.0
const CRASH_DROP: float = 46.0
const OHKO_FACTOR: float = 2.0
## Rôles des sprites d'art : le trajet (projectile, arc), l'impact, deux étincelles de joues, trois
## copies en série (ondes du trajet, flux du drain, anneau du piège : jamais dans la même phase).
enum Flip { TRAVEL, IMPACT, EXTRA_A, EXTRA_B, WAVE_A, WAVE_B, WAVE_C }

var speed_scale: float = 1.0
var camera: BattleCamera = BattleCamera.new()

var _pool: FxParticlePool
var _light: FxWorldLight
var _projectile: Sprite2D
var _bolt: Line2D
var _beam: Line2D
var _marks: Array[Line2D] = []
var _flips: Array[Sprite2D] = []
var _flip_additive: CanvasItemMaterial
## Instant de la pose en cours (cadence des flipbooks).
var _t: float = 0.0
var _tween: Tween
var _plan: MoveFxPlan
var _stage: MoveFxStage
var _user_scale: Vector2 = Vector2.ONE
var _target_scale: Vector2 = Vector2.ONE
var _user_modulate: Color = Color.WHITE
var _target_modulate: Color = Color.WHITE


func _ready() -> void:
	_build()


## Branche la caméra sur le calque du combat [param layer] et pose la lumière sous
## [param light_parent] (le calque `back` du décor ; null : ce nœud).
func setup(layer: CanvasLayer, light_parent: Node = null) -> void:
	_build()
	camera = BattleCamera.new(layer)
	if light_parent != null and _light.get_parent() != light_parent:
		_light.reparent(light_parent, false)


## Coroutine : joue [param plan] sur [param stage], puis rend la scène à son repos.
func play(plan: MoveFxPlan, stage: MoveFxStage) -> void:
	_build()
	stop()
	_plan = plan
	_stage = stage
	_capture_rest()
	_light.set_decor([stage.decor_back, stage.decor_front])
	_pool.speed_scale = speed_scale
	var tween := create_tween()
	_tween = tween
	tween.set_parallel(true)
	for phase: MoveFxPlan.Phase in plan.phases:
		tween.tween_callback(_start_phase.bind(phase)).set_delay(phase.start)
	for cue: MoveFxPlan.Cue in plan.cues:
		tween.tween_callback(fx_cue.emit.bind(cue.cue, plan.move_id)).set_delay(cue.time)
	tween.tween_method(pose, 0.0, plan.duration, maxf(plan.duration, 0.001))
	if speed_scale <= 0.0:
		tween.custom_step(INSTANT_STEP)
	else:
		tween.set_speed_scale(speed_scale)
	if tween.is_valid() and tween.is_running():
		await tween.finished
	if _tween == tween:
		_end()


## Arrête l'attaque en cours et rend la scène à son repos.
func stop() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if _plan != null:
		_end()
	_pool.clear()


## Avance l'attaque en cours de [param delta] s (galerie figée image par image, tests).
func advance(delta: float) -> void:
	if is_playing():
		_tween.custom_step(delta)


## Fige (ou relance) l'attaque en cours à l'instant atteint (galerie).
func set_paused(paused: bool) -> void:
	if is_playing() or (_tween != null and _tween.is_valid()):
		if paused:
			_tween.pause()
		else:
			_tween.play()


## Plan de l'attaque en cours (null sinon).
func get_plan() -> MoveFxPlan:
	return _plan


## Temps écoulé dans l'attaque en cours (s ; 0 sans attaque).
func elapsed() -> float:
	return _tween.get_total_elapsed_time() if is_playing() else 0.0


func is_playing() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()


func get_pool() -> FxParticlePool:
	return _pool


func get_light() -> FxWorldLight:
	return _light


func get_projectile() -> Sprite2D:
	return _projectile


func get_bolt() -> Line2D:
	return _bolt


func get_beam() -> Line2D:
	return _beam


## Sprite d'art peint du rôle [param role] (tests, galerie).
func get_art(role: Flip) -> Sprite2D:
	return _flips[role]


## Pose de la scène à l'instant [param t] (s) de l'attaque en cours (galerie, figé image par
## image).
func pose(t: float) -> void:
	if _plan == null or _stage == null:
		return
	var phase := _phase_at(t)
	if phase == null:
		return
	var k := clampf((t - phase.start) / phase.duration, 0.0, 1.0) if phase.duration > 0.0 else 1.0
	_t = t
	_hide_shapes()
	_pose_user(phase, k)
	_pose_effect(phase, k)
	_pose_target(phase, t - phase.start)
	_pose_camera(phase, t - phase.start, k)
	_pose_light(phase, k)


# --- Phases ----------------------------------------------------------------------------

func _phase_at(t: float) -> MoveFxPlan.Phase:
	var found: MoveFxPlan.Phase = null
	for phase: MoveFxPlan.Phase in _plan.phases:
		if phase.start <= t + MoveFxPlan.EPSILON:
			found = phase
	return found


## Éclats de particules au début d'une phase.
func _start_phase(phase: MoveFxPlan.Phase) -> void:
	if _plan == null:
		return
	var palette := _plan.palette
	var height := _stage.view_size.y
	match phase.name:
		MoveFxPlan.ANTICIPATION, MoveFxPlan.CHARGE:
			if not _is_contact():
				var points := _stage.origins if not _stage.origins.is_empty() \
					else PackedVector2Array([_stage.origin()])
				for point: Vector2 in points:
					_art_burst(&"charge", point, roundi(_plan.particles / 3.0 / points.size()),
						FxParticlePool.Shape.GATHER, 24.0, 0.12 * height, phase.duration)
		MoveFxPlan.IMPACT:
			_impact_burst(phase)
			if _plan.has_modifier(&"auto_ko"):
				# Explosion, Destruction : le lanceur éclate aussi (il tombe K.O. ensuite).
				_art_burst(&"rise", _stage.user_rect.get_center(), _plan.particles,
					FxParticlePool.Shape.BURST, 34.0, 0.22 * height, 0.7, true)
		MoveFxPlan.RETURN:
			if _plan.has_modifier(&"chute") and _missed(phase.hit):
				# Pied Sauté raté : le lanceur s'écrase, un peu de poussière sous lui.
				var feet := Vector2(_stage.user_rect.get_center().x, _stage.user_rect.end.y)
				_pool.burst(feet, roundi(_plan.particles / 2.0),
					PackedColorArray([Color("#E8DCC4"), Color("#A89478")]),
					FxParticlePool.Shape.RISE, 30.0, 0.07 * height, 0.6, false)
		MoveFxPlan.MISS:
			_pool.burst(_miss_point(), roundi(_plan.particles / 4.0), palette,
				FxParticlePool.Shape.BURST, 22.0, 0.06 * height, 0.35)
		MoveFxPlan.NO_EFFECT:
			_pool.burst(_stage.impact_point(), roundi(_plan.particles / 4.0),
				PackedColorArray([Color(0.85, 0.85, 0.85), Color(0.5, 0.5, 0.5)]),
				FxParticlePool.Shape.RISE, 24.0, 0.05 * height, 0.4, false)


func _impact_burst(phase: MoveFxPlan.Phase) -> void:
	var height := _stage.view_size.y
	var at := _stage.user_rect.get_center() if _plan.on_self else _stage.impact_point()
	var palette := _plan.palette
	var life := clampf(phase.duration * 2.0, 0.35, 0.8)
	var reach := 0.16 * height
	match _plan.bricks.get("impact", ""):
		"rising_aura", "rising_sparkles":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.RISE, 26.0, reach, life)
		"falling_aura", "poison_drops", "leaf_fall":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.FALL, 26.0,
				reach * 0.6, life)
		"splash":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.FALL, 24.0, reach, life)
		"debris":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.FALL, 34.0, reach, life)
		"ember_burst":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.BURST, 30.0, reach, life)
			_art_burst(&"rise", at, roundi(_plan.particles / 3.0), FxParticlePool.Shape.RISE, 22.0,
				reach * 0.8, life * 1.4, true)
		_:
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.BURST, 30.0, reach, life)
	if _plan.art.has(&"fallout"):
		# Retombée (couche 8 du §2.9) : un peu de fumée qui monte de la cible.
		_art_burst(&"fallout", at, roundi(_plan.particles / 6.0), FxParticlePool.Shape.RISE, 40.0,
			reach * 0.5, life * 1.8)
	if _plan.art.has(&"feathers") and _plan.target_types.has(&"flying"):
		# Éclair sur un Pokémon Vol : des plumes tombent (dossier 05 §10).
		_art_burst(&"feathers", at, 8, FxParticlePool.Shape.FALL, 40.0, reach * 0.5, 1.0)
	if _plan.world.has(&"dust"):
		var feet := Vector2(_stage.target_rect.get_center().x, _stage.target_rect.end.y)
		_pool.burst(feet, roundi(_plan.particles / 2.0),
			PackedColorArray([Color("#E8DCC4"), Color("#A89478")]), FxParticlePool.Shape.RISE,
			26.0, 0.06 * height, 0.6, false, _art_texture(&"dust"))


## Éclat de particules du rôle [param role] du plan : particule peinte s'il y en a une (taille
## [constant ART_PARTICLE] au moins, son mélange), sinon le point doux teinté par la palette.
func _art_burst(role: StringName, at: Vector2, amount: int, shape: FxParticlePool.Shape,
		size: float, reach: float, lifetime: float, additive: bool = false) -> void:
	var info := FxArt.particle(_plan.art.get(role, &""))
	if info.is_empty():
		_pool.burst(at, amount, _plan.palette, shape, size, reach, lifetime, additive)
		return
	_pool.burst(at, amount, _plan.palette, shape, maxf(size * 1.6,
		ART_PARTICLE * _stage.view_size.y), reach, lifetime, info["additive"], info["texture"])


func _art_texture(role: StringName) -> Texture2D:
	return FxArt.particle(_plan.art.get(role, &"")).get("texture", null)


# --- Lanceur ---------------------------------------------------------------------------

func _pose_user(phase: MoveFxPlan.Phase, k: float) -> void:
	var user := _stage.user
	if user == null:
		return
	var toward := _stage.target_rest - _stage.user_rest
	var dir := toward.normalized()
	var depth := -1.0 if _stage.user_is_player else 1.0
	var offset := Vector2.ZERO
	var scale_k := Vector2.ONE
	var glow := 0.0
	if _is_contact():
		var back := -dir * toward.length() * CROUCH_BACK
		var reach := dir * toward.length() * DASH_REACH
		if _plan.phase(MoveFxPlan.MISS, phase.hit) != null:
			reach += dir.orthogonal() * toward.length() * 0.06
		match phase.name:
			MoveFxPlan.ANTICIPATION:
				var e := _ease_out(k)
				offset = back * e
				scale_k = Vector2(1.0 + CROUCH_SQUASH * 0.6 * e, 1.0 - CROUCH_SQUASH * e)
			MoveFxPlan.TRAVEL:
				var start := back if phase.hit == 0 and _has_anticipation() else Vector2.ZERO
				var e := k * k
				offset = start.lerp(reach, e)
				scale_k = Vector2.ONE * (1.0 + depth * DEPTH_SCALE * e)
			MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
				offset = reach
				scale_k = Vector2.ONE * (1.0 + depth * DEPTH_SCALE)
			MoveFxPlan.RETURN:
				var e := _ease_in_out(k)
				offset = reach.lerp(Vector2.ZERO, e) + Vector2(0.0, -sin(PI * k) * RETURN_ARC)
				scale_k = Vector2.ONE * (1.0 + depth * DEPTH_SCALE * (1.0 - e))
				if _plan.has_modifier(&"chute") and _missed(phase.hit):
					# Chute (§3.2) : il retombe lourdement, écrasé, avant de revenir.
					var fall := sin(PI * minf(k * 1.6, 1.0))
					offset += Vector2(0.0, CRASH_DROP * fall)
					scale_k *= Vector2(1.0 + CROUCH_SQUASH * fall, 1.0 - CROUCH_SQUASH * 1.5 * fall)
	else:
		match phase.name:
			MoveFxPlan.ANTICIPATION, MoveFxPlan.CHARGE:
				glow = sin(PI * k) if phase.name == MoveFxPlan.CHARGE else _ease_out(k)
				offset = -dir * 6.0 * glow
			MoveFxPlan.TRAVEL:
				glow = 1.0 - k
			MoveFxPlan.IMPACT:
				if _plan.on_self:
					glow = sin(PI * k)
					offset = Vector2(0.0, -10.0 * sin(PI * k))
	if phase.name == MoveFxPlan.IMPACT and _plan.has_modifier(&"auto_ko"):
		# Auto-K.O. : le lanceur s'illumine et tremble pendant l'explosion.
		glow = 0.0 if _plan.reduce_flashes else maxf(glow, 1.0 - k)
		offset.x += sin(TAU * HIT_SHAKE_WAVES * k) * HIT_SHAKE * (1.0 - k)
	if phase.name == MoveFxPlan.RETURN and _plan.has_modifier(&"contrecoup") and _plan.lands() \
			and not _missed(phase.hit):
		# Contrecoup : le lanceur encaisse à son tour (secousse et teinte sombre brèves).
		var hurt := 1.0 - k
		offset.x += sin(TAU * HIT_SHAKE_WAVES * k) * RECOIL_SHAKE * hurt
		user.position = _stage.user_rest + offset
		user.scale = _user_scale * scale_k
		user.modulate = _user_modulate.lerp(_user_modulate * HIT_DIM, hurt * hurt)
		return
	user.position = _stage.user_rest + offset
	user.scale = _user_scale * scale_k
	user.modulate = _user_modulate.lerp(_user_modulate * CHARGE_GLOW, glow)


func _pose_target(phase: MoveFxPlan.Phase, elapsed: float) -> void:
	var target := _stage.target
	if target == null or _plan.on_self:
		return
	var offset := Vector2.ZERO
	var scale_k := Vector2.ONE
	var tint := _target_modulate
	if phase.name == MoveFxPlan.IMPACT:
		# K.O. en un coup réussi : arrêt sur image et tremblement plus longs, plus forts.
		var heavy := OHKO_FACTOR if _plan.outcome != null and _plan.outcome.ohko else 1.0
		var stop := minf(HIT_STOP * heavy, phase.duration * 0.5)
		var k := clampf((elapsed - stop) / maxf(phase.duration - stop, 0.001), 0.0, 1.0)
		var hit_k := 1.0 - k
		var impact_brick: String = _plan.bricks.get("impact", "")
		if elapsed < stop:
			hit_k = 1.0
		elif _plan.target_shake:
			match impact_brick:
				"distortion":
					pass
				"vibrate":
					offset.x = sin(TAU * VIBRATE_WAVES * k) * VIBRATE_SHAKE * hit_k
				_:
					offset.x = sin(TAU * HIT_SHAKE_WAVES * k) * HIT_SHAKE * heavy * hit_k
		var push := (_stage.target_rest - _stage.user_rest).normalized() * 8.0 * hit_k
		offset += push if _plan.target_shake and impact_brick != "distortion" else Vector2.ZERO
		scale_k = Vector2(1.0 + HIT_SQUASH * hit_k, 1.0 - HIT_SQUASH * hit_k)
		if impact_brick == "distortion":
			# Psy : la cible ondule (largeur et hauteur en opposition), sans quitter sa place.
			var wave := sin(TAU * DISTORT_WAVES * k) * DISTORT_SQUASH * sin(PI * k)
			scale_k = Vector2(1.0 + wave, 1.0 - wave)
		var flash := HIT_DIM if _plan.reduce_flashes else HIT_BRIGHT
		tint = _target_modulate.lerp(_target_modulate * flash, hit_k * hit_k)
	target.position = _stage.target_rest + offset
	target.scale = _target_scale * scale_k
	target.modulate = tint


# --- Effet (projectile, rayon, arc, marques) -------------------------------------------

func _pose_effect(phase: MoveFxPlan.Phase, k: float) -> void:
	if _is_contact():
		if phase.name == MoveFxPlan.IMPACT and not _pose_stamp(k):
			_pose_marks(k)
	elif not _pose_art(phase, k) and not _plan.on_self:
		_pose_shapes(phase, k)
	_pose_impact_art()
	_pose_trap(phase, k)
	_pose_drain(phase, k)


## Formes dessinées en code (échafaudage de CV.0) quand le trajet n'a pas d'art : projectile,
## rayon, arc.
func _pose_shapes(phase: MoveFxPlan.Phase, k: float) -> void:
	var travel: String = _plan.bricks.get("travel", "")
	var from := _stage.origin()
	var to := _stage.impact_point()
	var missed := _plan.phase(MoveFxPlan.MISS, phase.hit) != null
	if missed:
		to = _miss_point()
	match phase.name:
		MoveFxPlan.ANTICIPATION, MoveFxPlan.CHARGE:
			_show_projectile(from, _ease_out(k) * 0.7, 1.0)
		MoveFxPlan.TRAVEL:
			match travel:
				"bolt":
					_show_bolt(from, from.lerp(to, _ease_out(k)), floori(k * BOLT_REDRAWS), 1.0)
				"beam", "ice_beam", "jet":
					_show_beam(from, from.lerp(to, _ease_out(k)), k, 1.0)
				_:
					var depth := lerpf(1.0, PROJECTILE_FAR if _stage.user_is_player
						else PROJECTILE_NEAR, k)
					_show_projectile(from.lerp(to, k * k * (3.0 - 2.0 * k)), depth, 1.0)
		MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
			var fade := 1.0 - k
			match travel:
				"bolt":
					_show_bolt(from, to, BOLT_REDRAWS + floori(k * 2.0), fade)
				"beam", "ice_beam", "jet":
					_show_beam(from, to, 1.0, fade)
				_:
					if phase.name == MoveFxPlan.MISS:
						var past := to + (to - from) * MISS_OVERSHOOT * k
						_show_projectile(past, PROJECTILE_FAR, fade)
					elif phase.name == MoveFxPlan.NO_EFFECT:
						_show_projectile(to, lerpf(0.8, 0.2, k), fade)


## Effet en art peint (CV.1) : flipbooks du trajet (`travel` : projectile ; `bolt` : arc tendu
## du lanceur à la cible), de l'impact (`impact`) et des joues (`cheeks`, Éclair). Faux si le plan
## n'a pas d'art pour son trajet : les formes en code prennent le relais.
func _pose_art(phase: MoveFxPlan.Phase, k: float) -> bool:
	var bolt := _plan.art.get(&"bolt", &"") as StringName
	var travel := _plan.art.get(&"travel", &"") as StringName
	if bolt.is_empty() and travel.is_empty():
		return false
	if _is_wave_travel():
		return _pose_waves(phase, k, travel)
	var height := _stage.view_size.y
	var from := _stage.origin()
	var to := _stage.impact_point()
	var missed := _plan.phase(MoveFxPlan.MISS, phase.hit) != null
	if missed:
		to = _miss_point()
	var angle := (to - from).angle()
	var depth_far := PROJECTILE_FAR if _stage.user_is_player else PROJECTILE_NEAR
	match phase.name:
		MoveFxPlan.ANTICIPATION, MoveFxPlan.CHARGE:
			var e := _ease_out(k)
			if _plan.art.has(&"cheeks"):
				_pose_cheeks(e)
			elif not travel.is_empty():
				_show_flip(Flip.TRAVEL, travel, from, Vector2.ONE * ART_PROJECTILE * height * 0.5 * e
					* _projectile_scale(travel), angle, 1.0)
		MoveFxPlan.TRAVEL:
			if not bolt.is_empty():
				var reach := from.distance_to(to) * _ease_out(k)
				_show_flip(Flip.TRAVEL, bolt, from, Vector2(reach, ART_BOLT_HEIGHT * height), angle,
					1.0, true)
				if _plan.art.has(&"cheeks"):
					_pose_cheeks(1.0 - k)
			else:
				var s := k * k * (3.0 - 2.0 * k)
				var size := ART_PROJECTILE * height * lerpf(1.0, depth_far, k) * _projectile_scale(travel)
				_show_flip(Flip.TRAVEL, travel, from.lerp(to, s), Vector2.ONE * size, angle, 1.0)
		MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
			var fade := 1.0 - _ease_in(k)
			if not bolt.is_empty():
				_show_flip(Flip.TRAVEL, bolt, from, Vector2(from.distance_to(to),
					ART_BOLT_HEIGHT * height), angle, fade * (1.0 if phase.name == MoveFxPlan.IMPACT
					else 0.6), true)
			elif phase.name == MoveFxPlan.MISS:
				var past := to + (to - from) * MISS_OVERSHOOT * k
				_show_flip(Flip.TRAVEL, travel, past, Vector2.ONE * ART_PROJECTILE * height
					* depth_far * _projectile_scale(travel), angle, fade)
			elif phase.name == MoveFxPlan.NO_EFFECT:
				_show_flip(Flip.TRAVEL, travel, to, Vector2.ONE * ART_PROJECTILE * height
					* lerpf(0.8, 0.2, k) * _projectile_scale(travel), angle, fade)
	return true


## L'impact peint se joue une fois (il naît, grandit, s'éteint), de l'impact à la fin du coup ;
## sur le lanceur pour un effet sur soi (aura, soin). Indépendant de l'art du trajet (rayons en
## code de la Glace et de l'Énergie).
func _pose_impact_art() -> void:
	if _is_contact() or not _plan.art.has(&"impact"):
		return
	var strike: MoveFxPlan.Phase = null
	for item: MoveFxPlan.Phase in _plan.phases:
		if item.name == MoveFxPlan.IMPACT and _t >= item.start:
			strike = item
	if strike == null:
		return
	var back := _plan.phase(MoveFxPlan.RETURN, strike.hit)
	var hit_end := strike.end() + (back.duration if back != null else 0.0)
	if _t > hit_end + MoveFxPlan.EPSILON:
		return
	var once := clampf((_t - strike.start) / maxf(hit_end - strike.start, 0.001), 0.0, 1.0)
	var at := _stage.impact_point()
	var size := _stage.target_rect.size.y * ART_IMPACT
	if _plan.on_self:
		at = _stage.user_rect.get_center()
		size = _stage.user_rect.size.y * ART_SELF
	_show_flip(Flip.IMPACT, _plan.art[&"impact"], at, Vector2.ONE * size, 0.0, 1.0, false, once)


## Ondes en série (Psy, Son) : [constant WAVE_COUNT] copies de l'art du trajet partent l'une après
## l'autre, changent de taille avec la profondeur et s'éteignent sur la cible.
func _pose_waves(phase: MoveFxPlan.Phase, k: float, id: StringName) -> bool:
	if id.is_empty():
		return false
	var from := _stage.origin()
	var to := _miss_point() if _missed(phase.hit) else _stage.impact_point()
	var angle := (to - from).angle()
	var depth_far := PROJECTILE_FAR if _stage.user_is_player else PROJECTILE_NEAR
	var progress := -1.0
	match phase.name:
		MoveFxPlan.TRAVEL:
			progress = k
		MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
			progress = 1.0 + k * WAVE_LAG * WAVE_COUNT
	if progress < 0.0:
		return true
	for i: int in WAVE_COUNT:
		var p := progress * (1.0 + WAVE_LAG * (WAVE_COUNT - 1)) - WAVE_LAG * i
		if p <= 0.0 or p >= 1.0 + WAVE_LAG:
			continue
		var along := clampf(p, 0.0, 1.0)
		var fade := 1.0 - clampf((p - 1.0) / WAVE_LAG, 0.0, 1.0)
		var size := WAVE_SIZE * _stage.view_size.y * lerpf(0.7, depth_far * 1.3, along)
		_show_flip(Flip.WAVE_A + i, id, from.lerp(to, along), Vector2.ONE * size, angle,
			fade * minf(1.0, p * 4.0))
	return true


## Piège (Ligotage, Étreinte, Danse Flamme, Claquoir…) : trois éléments tournent autour de la cible
## pendant l'impact et le retour (particule de la famille, sinon une liane).
func _pose_trap(phase: MoveFxPlan.Phase, k: float) -> void:
	if not _plan.has_modifier(&"piege") or not _plan.lands() or _missed(phase.hit):
		return
	if phase.name != MoveFxPlan.IMPACT and phase.name != MoveFxPlan.RETURN:
		return
	var id := _plan.art.get(&"particle", _plan.art.get(&"trap", &"")) as StringName
	var rect := _stage.target_rect
	var radius := rect.size.x * TRAP_RADIUS
	var strike := _plan.phase(MoveFxPlan.IMPACT, phase.hit)
	var since := _t - (strike.start if strike != null else phase.start)
	var alpha := _ease_out(k) if phase.name == MoveFxPlan.IMPACT else 1.0 - _ease_in(k)
	for i: int in WAVE_COUNT:
		var angle := TAU * (TRAP_TURNS * since + float(i) / WAVE_COUNT)
		var at := rect.get_center() + Vector2(cos(angle) * radius, sin(angle) * radius * 0.35)
		_show_flip(Flip.WAVE_A + i, id, at, Vector2.ONE * TRAP_SIZE * _stage.view_size.y,
			angle + PI * 0.5, alpha)


## Drain (Vol-Vie, Méga-Sangsue, Vampirisme, Dévorêve) : un flux de lumière revient de la cible
## au lanceur, de la moitié de l'impact du dernier coup à la fin de l'attaque.
func _pose_drain(phase: MoveFxPlan.Phase, _k: float) -> void:
	if not _plan.has_modifier(&"drain") or not _plan.lands() or _missed(phase.hit) \
			or phase.hit != _plan.hits - 1:
		return
	var strike := _plan.phase(MoveFxPlan.IMPACT, phase.hit)
	if strike == null:
		return
	var from_t := strike.start + strike.duration * 0.5
	if _t < from_t:
		return
	var k := clampf((_t - from_t) / maxf(_plan.duration - from_t, 0.001), 0.0, 1.0)
	var id := _plan.art.get(&"stream", &"") as StringName
	var from := _stage.impact_point()
	var to := _stage.user_rect.get_center()
	var bend := (to - from).orthogonal().normalized() * from.distance_to(to) * STREAM_ARC
	for i: int in WAVE_COUNT:
		var p := clampf(k * 1.6 - 0.3 * i, 0.0, 1.0)
		if p <= 0.0 or p >= 1.0:
			continue
		var at := from.lerp(to, _ease_in_out(p)) + bend * sin(PI * p)
		_show_flip(Flip.WAVE_A + i, id, at, Vector2.ONE * STREAM_SIZE * _stage.view_size.y
			* lerpf(0.8, 1.2, sin(PI * p)), 0.0, sin(PI * p))


## Étincelles des joues (Éclair) : un petit arc peint sur chaque point d'origine.
func _pose_cheeks(amount: float) -> void:
	var points := _stage.origins
	if points.is_empty() or amount <= 0.0:
		return
	var size := Vector2.ONE * ART_CHEEKS * _stage.view_size.y * lerpf(0.6, 1.0, amount)
	for i: int in mini(points.size(), 2):
		_show_flip(Flip.EXTRA_A + i, _plan.art[&"cheeks"], points[i], size, PI * 0.5 * i, amount)


## Marque d'impact peinte du Contact (`stamp`) : surgit, se pose, s'efface ; les mâchoires se
## ferment, l'onde du coup de corps s'élargit. Faux sans art.
func _pose_stamp(k: float) -> bool:
	var stamp := _plan.art.get(&"stamp", &"") as StringName
	if stamp.is_empty():
		return false
	var rect := _stage.target_rect
	var base := ART_STAMP * minf(rect.size.x, rect.size.y)
	var pop := _ease_out(clampf(k * 3.0, 0.0, 1.0))
	var alpha := 1.0 - clampf((k - 0.5) * 2.0, 0.0, 1.0)
	var size := Vector2.ONE * base * lerpf(1.35, 1.0, pop)
	var angle := 0.0
	match _plan.impact:
		&"crocs":
			size.y *= lerpf(1.4, 0.8, pop)
		&"corps":
			size = Vector2.ONE * base * lerpf(0.5, 1.6, _ease_out(k))
			alpha = 1.0 - k
		&"percant":
			angle = (_stage.target_rest - _stage.user_rest).angle()
	_show_flip(Flip.IMPACT, stamp, rect.get_center(), size, angle, alpha, false, k)
	return true


## Sprite d'art [param index] : flipbook ou particule [param id] centré en [param at] (ou, avec
## [param from_left], tendu depuis [param at] vers [param angle]), affiché en [param size] px ;
## [param once] : avancée d'un flipbook joué une seule fois (-1 : en boucle).
func _show_flip(index: int, id: StringName, at: Vector2, size: Vector2, angle: float,
		alpha: float, from_left: bool = false, once: float = -1.0) -> void:
	if alpha <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
		return
	var info := FxArt.flipbook(id)
	var frames := 1
	var columns := 1
	var frame_size := 0.0
	if info.is_empty():
		info = FxArt.particle(id)
		if info.is_empty():
			return
		frame_size = (info["texture"] as Texture2D).get_width()
	else:
		frames = info["frames"]
		columns = info["columns"]
		frame_size = info["size"]
	var sprite := _flips[index]
	sprite.visible = true
	sprite.texture = info["texture"]
	sprite.hframes = columns
	sprite.vframes = ceili(float(frames) / columns)
	# [param once] ≥ 0 : une seule fois, de la première image (0) à la dernière (1) ; sinon en
	# boucle à [constant FLIP_FPS].
	sprite.frame = mini(floori(once * frames), frames - 1) if once >= 0.0 \
		else floori(_t * FLIP_FPS) % frames
	sprite.material = _flip_additive if info["additive"] else null
	var body := sprite.get_child(0) as Sprite2D
	body.visible = info["additive"]
	body.texture = sprite.texture
	body.hframes = sprite.hframes
	body.vframes = sprite.vframes
	body.frame = sprite.frame
	body.centered = not from_left
	body.offset = Vector2(0.0, -frame_size * 0.5) if from_left else Vector2.ZERO
	body.flip_v = cos(angle) < 0.0
	body.self_modulate = Color(1, 1, 1, ART_BODY_ALPHA)
	sprite.centered = not from_left
	sprite.offset = Vector2(0.0, -frame_size * 0.5) if from_left else Vector2.ZERO
	sprite.position = at
	sprite.rotation = angle
	# L'art part vers la droite : retourné verticalement quand il part vers la gauche, pour garder
	# le haut de la flamme ou de l'arc en haut.
	sprite.flip_v = cos(angle) < 0.0
	sprite.scale = size / frame_size
	sprite.modulate = Color(_plan.art_tint, alpha)


func _show_projectile(at: Vector2, size_k: float, alpha: float) -> void:
	if size_k <= 0.0 or alpha <= 0.0:
		return
	_projectile.visible = true
	_projectile.position = at
	var size := PROJECTILE_SIZE * _stage.view_size.y * size_k
	_projectile.scale = Vector2.ONE * (size / _projectile.texture.get_width())
	_projectile.modulate = Color(1, 1, 1, alpha)
	_projectile.self_modulate = _color(1)
	var core := _projectile.get_child(0) as Sprite2D
	core.modulate = _color(0)
	var halo := _projectile.get_child(1) as Sprite2D
	halo.modulate = Color(_color(1), HALO_ALPHA)


func _show_bolt(from: Vector2, to: Vector2, redraw: int, alpha: float) -> void:
	_bolt.visible = alpha > 0.0
	_bolt.points = bolt_points(from, to, BOLT_SEGMENTS, BOLT_JITTER * _stage.view_size.y,
		hash(_plan.move_id) + redraw)
	_color_line(_bolt, BOLT_WIDTH, alpha)


func _show_beam(from: Vector2, to: Vector2, k: float, alpha: float, jet: bool = true) -> void:
	_beam.visible = alpha > 0.0
	_beam.points = PackedVector2Array([from, to])
	var width := (JET_WIDTH if jet else BEAM_WIDTH) * lerpf(0.4, 1.0, k)
	_color_line(_beam, width, alpha)
	var core := _beam.get_child(0) as Line2D
	core.width = width * (JET_CORE_WIDTH if jet else CORE_WIDTH)
	var halo := _beam.get_node(^"Halo") as Line2D
	halo.visible = jet and alpha > 0.0
	if halo.visible:
		halo.points = _beam.points
		halo.width = width * JET_HALO_WIDTH
		halo.default_color = Color(_color(0), JET_HALO_ALPHA * alpha)


func _pose_marks(k: float) -> void:
	var rect := _stage.target_rect
	var center := rect.get_center()
	var length := MARK_LENGTH * minf(rect.size.x, rect.size.y)
	var reveal := _ease_out(clampf(k * 2.5, 0.0, 1.0))
	var alpha := 1.0 - clampf((k - 0.5) * 2.0, 0.0, 1.0)
	var lines: Array[PackedVector2Array] = []
	match _plan.impact:
		&"griffe":
			for i: int in 3:
				var shift := Vector2((i - 1) * length * 0.28, (i - 1) * -length * 0.08)
				var a := center + shift + Vector2(-length, -length) * 0.5
				lines.append(PackedVector2Array([a, a.lerp(a + Vector2(length, length), reveal)]))
		&"crocs":
			for i: int in 2:
				var side := -1.0 if i == 0 else 1.0
				var bite := center + Vector2(0.0, side * length * 0.35 * (1.0 - reveal * 0.6))
				lines.append(_arc(bite, length * 0.5, side))
		&"percant":
			var a := center + Vector2(-length * 0.6, length * 0.15)
			lines.append(PackedVector2Array([a, a.lerp(center + Vector2(length * 0.6, -length * 0.15),
				reveal)]))
	for i: int in _marks.size():
		var mark := _marks[i]
		mark.visible = i < lines.size() and alpha > 0.0
		if mark.visible:
			mark.points = lines[i]
			_color_line(mark, MARK_WIDTH, alpha)


## Couleur [param index] du dégradé du plan (0 : cœur, 1 : élément, 2 : bord), ou la dernière.
func _color(index: int) -> Color:
	if _plan == null or _plan.palette.is_empty():
		return Color.WHITE
	return _plan.palette[mini(index, _plan.palette.size() - 1)]


## Trait en deux couches : corps de la couleur de l'élément, cœur clair (enfant, mêmes points).
func _color_line(line: Line2D, width: float, alpha: float) -> void:
	line.width = width
	line.default_color = Color(_color(1), alpha)
	var core := line.get_child(0) as Line2D
	core.points = line.points
	core.width = width * CORE_WIDTH
	core.default_color = Color(_color(0), alpha)


static func _arc(center: Vector2, radius: float, side: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in 7:
		var angle := lerpf(PI * 0.15, PI * 0.85, i / 6.0)
		points.append(center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.5 * -side))
	return points


## Arc électrique de [param from] à [param to] : [param segments] segments brisés d'au plus
## [param jitter] px de côté (graine [param bolt_seed] : même arc pour la même graine ;
## extrémités fixes). Générateur local : l'aléatoire du combat n'est pas touché.
static func bolt_points(from: Vector2, to: Vector2, segments: int, jitter: float,
		bolt_seed: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = bolt_seed
	var normal := (to - from).orthogonal().normalized()
	var points := PackedVector2Array([from])
	for i: int in range(1, segments):
		var t := float(i) / segments
		var taper := sin(PI * t)
		points.append(from.lerp(to, t) + normal * rng.randf_range(-jitter, jitter) * taper)
	points.append(to)
	return points


# --- Caméra et lumière -----------------------------------------------------------------

func _pose_camera(phase: MoveFxPlan.Phase, elapsed: float, k: float) -> void:
	var pivot := _stage.impact_point()
	match phase.name:
		MoveFxPlan.IMPACT:
			var zoom := lerpf(1.0, _plan.camera_zoom, _ease_out(clampf(k * 3.0, 0.0, 1.0)))
			camera.set_pose(zoom, pivot, BattleCamera.shake_at(elapsed, _plan.camera_shake,
				phase.duration))
		MoveFxPlan.RETURN:
			var back := clampf(elapsed / CAMERA_RETURN, 0.0, 1.0)
			camera.set_pose(lerpf(_plan.camera_zoom, 1.0, _ease_out(back)), pivot)
		_:
			camera.set_pose(1.0, pivot)


func _pose_light(phase: MoveFxPlan.Phase, k: float) -> void:
	var at := _stage.user_rect.get_center() if _plan.on_self else _stage.impact_point()
	var amount := 0.0
	var darken := 0.0
	match phase.name:
		MoveFxPlan.TRAVEL:
			amount = _plan.light_peak * 0.35 * k
			at = _stage.origin().lerp(at, k)
		MoveFxPlan.IMPACT:
			if _plan.flashes > 0:
				var hits := maxi(1, _plan.hits)
				var per_hit := maxi(1, ceili(float(_plan.flashes) / hits))
				amount = _plan.light_peak * absf(sin(PI * k * per_hit))
			else:
				amount = _plan.light_peak * sin(PI * k)
			if _plan.world.has(&"darken"):
				darken = sin(PI * k)
		MoveFxPlan.RETURN:
			amount = 0.0
	_light.set_light(_plan.light_color, amount, at, _stage.view_size.y)
	_light.set_darken(darken)


# --- Outils ----------------------------------------------------------------------------

func _is_contact() -> bool:
	return _plan.bricks.get("travel", "") == "dash"


## Taille d'un projectile peint : un flipbook à [constant ART_PROJECTILE], une particule moins.
static func _projectile_scale(id: StringName) -> float:
	return 1.0 if not FxArt.flipbook(id).is_empty() else ART_PARTICLE_PROJECTILE


func _is_wave_travel() -> bool:
	var travel: String = _plan.bricks.get("travel", "")
	return travel == "rings" or travel == "sound_waves"


func _missed(hit: int) -> bool:
	return _plan.phase(MoveFxPlan.MISS, hit) != null


func _has_anticipation() -> bool:
	return _plan.phase(MoveFxPlan.ANTICIPATION) != null


func _miss_point() -> Vector2:
	var from := _stage.origin()
	var to := _stage.impact_point()
	return to + (to - from).orthogonal().normalized() * _stage.target_rect.size.x * MISS_SIDE \
		* (1.0 if _stage.user_is_player else -1.0)


func _capture_rest() -> void:
	if _stage.user != null:
		_user_scale = _stage.user.scale
		_user_modulate = _stage.user.modulate
	if _stage.target != null:
		_target_scale = _stage.target.scale
		_target_modulate = _stage.target.modulate


func _end() -> void:
	if _stage != null:
		if is_instance_valid(_stage.user):
			_stage.user.position = _stage.user_rest
			_stage.user.scale = _user_scale
			_stage.user.modulate = _user_modulate
		if is_instance_valid(_stage.target):
			_stage.target.position = _stage.target_rest
			_stage.target.scale = _target_scale
			_stage.target.modulate = _target_modulate
	camera.reset()
	_light.restore()
	_hide_shapes()
	_plan = null
	_stage = null
	_tween = null
	finished.emit()


func _hide_shapes() -> void:
	for flip: Sprite2D in _flips:
		flip.visible = false
	_projectile.visible = false
	_bolt.visible = false
	_beam.visible = false
	for mark: Line2D in _marks:
		mark.visible = false


func _build() -> void:
	if _pool != null:
		return
	_light = FxWorldLight.new()
	_light.name = &"Light"
	add_child(_light)
	_pool = FxParticlePool.new()
	_pool.name = &"Particles"
	add_child(_pool)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var dot := FxParticlePool.soft_dot(128)
	_projectile = _make_sprite(&"Projectile", dot, null)
	add_child(_projectile)
	var core := _make_sprite(&"Core", dot, null)
	core.scale = Vector2.ONE * 0.5
	_projectile.add_child(core)
	var halo := _make_sprite(&"Halo", dot, additive)
	halo.scale = Vector2.ONE * HALO_SIZE
	halo.show_behind_parent = true
	_projectile.add_child(halo)
	_bolt = _make_line(&"Bolt", BOLT_WIDTH)
	_beam = _make_line(&"Beam", BEAM_WIDTH)
	var jet_halo := _new_line(&"Halo", BEAM_WIDTH)
	jet_halo.material = additive
	jet_halo.show_behind_parent = true
	jet_halo.visible = false
	_beam.add_child(jet_halo)
	for i: int in 3:
		_marks.append(_make_line(&"Mark%d" % i, MARK_WIDTH))
	_flip_additive = additive
	for role: String in Flip.keys():
		var flip := _make_sprite(StringName("Art" + role.to_pascal_case()), null, null)
		var body := _make_sprite(&"Body", null, null)
		body.show_behind_parent = true
		flip.add_child(body)
		add_child(flip)
		_flips.append(flip)
	_hide_shapes()


func _make_sprite(sprite_name: StringName, texture: Texture2D, material: Material) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.material = material
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return sprite


## Trait d'effet (corps) et son cœur clair en enfant.
func _make_line(line_name: StringName, width: float) -> Line2D:
	var line := _new_line(line_name, width)
	line.add_child(_new_line(&"Core", width * CORE_WIDTH))
	add_child(line)
	return line


static func _new_line(line_name: StringName, width: float) -> Line2D:
	var line := Line2D.new()
	line.name = line_name
	line.width = width
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	var taper := Curve.new()
	taper.add_point(Vector2(0.0, 0.5))
	taper.add_point(Vector2(0.5, 1.0))
	taper.add_point(Vector2(1.0, 0.5))
	line.width_curve = taper
	return line


static func _ease_in(k: float) -> float:
	return k * k


static func _ease_out(k: float) -> float:
	return 1.0 - (1.0 - k) * (1.0 - k)


static func _ease_in_out(k: float) -> float:
	return k * k * (3.0 - 2.0 * k)
