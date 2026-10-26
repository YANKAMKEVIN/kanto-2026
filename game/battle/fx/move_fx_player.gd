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
## Marques d'impact du Contact : griffe (3 entailles), crocs (2 arcs), perçant (1 trait).
const MARK_WIDTH: float = 14.0
## Formes en deux couches (§2.9, lisibles sur un décor de plein jour) : un corps opaque de la
## couleur de l'élément (mélange normal), un cœur clair plus fin, un halo additif plus large.
const CORE_WIDTH: float = 0.4
const HALO_SIZE: float = 2.4
const HALO_ALPHA: float = 0.55
const MARK_LENGTH: float = 0.55

var speed_scale: float = 1.0
var camera: BattleCamera = BattleCamera.new()

var _pool: FxParticlePool
var _light: FxWorldLight
var _projectile: Sprite2D
var _bolt: Line2D
var _beam: Line2D
var _marks: Array[Line2D] = []
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


## Pose de la scène à l'instant [param t] (s) de l'attaque en cours (galerie, figé image par
## image).
func pose(t: float) -> void:
	if _plan == null or _stage == null:
		return
	var phase := _phase_at(t)
	if phase == null:
		return
	var k := clampf((t - phase.start) / phase.duration, 0.0, 1.0) if phase.duration > 0.0 else 1.0
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
				_pool.burst(_stage.origin(), roundi(_plan.particles / 3.0), palette,
					FxParticlePool.Shape.GATHER, 24.0, 0.12 * height, phase.duration)
		MoveFxPlan.IMPACT:
			_impact_burst(phase)
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
			_pool.burst(at, _plan.particles, palette, FxParticlePool.Shape.RISE, 26.0, reach, life)
		"falling_aura", "poison_drops", "leaf_fall":
			_pool.burst(at, _plan.particles, palette, FxParticlePool.Shape.FALL, 26.0, reach * 0.6,
				life)
		"splash":
			_pool.burst(at, _plan.particles, palette, FxParticlePool.Shape.FALL, 24.0, reach, life)
		"debris":
			_pool.burst(at, _plan.particles, palette, FxParticlePool.Shape.FALL, 34.0, reach, life)
		"ember_burst":
			_pool.burst(at, _plan.particles, palette, FxParticlePool.Shape.BURST, 30.0, reach, life)
			_pool.burst(at, roundi(_plan.particles / 3.0), palette, FxParticlePool.Shape.RISE, 22.0,
				reach * 0.8, life * 1.4, true)
		_:
			_pool.burst(at, _plan.particles, palette, FxParticlePool.Shape.BURST, 30.0, reach, life)
	if _plan.world.has(&"dust"):
		var feet := Vector2(_stage.target_rect.get_center().x, _stage.target_rect.end.y)
		_pool.burst(feet, roundi(_plan.particles / 2.0),
			PackedColorArray([Color("#E8DCC4"), Color("#A89478")]), FxParticlePool.Shape.RISE,
			26.0, 0.06 * height, 0.6, false)


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
		var k := clampf((elapsed - HIT_STOP) / maxf(phase.duration - HIT_STOP, 0.001), 0.0, 1.0)
		var hit_k := 1.0 - k
		if elapsed < HIT_STOP:
			hit_k = 1.0
		elif _plan.target_shake:
			offset.x = sin(TAU * HIT_SHAKE_WAVES * k) * HIT_SHAKE * hit_k
		var push := (_stage.target_rest - _stage.user_rest).normalized() * 8.0 * hit_k
		offset += push if _plan.target_shake else Vector2.ZERO
		scale_k = Vector2(1.0 + HIT_SQUASH * hit_k, 1.0 - HIT_SQUASH * hit_k)
		var flash := HIT_DIM if _plan.reduce_flashes else HIT_BRIGHT
		tint = _target_modulate.lerp(_target_modulate * flash, hit_k * hit_k)
	target.position = _stage.target_rest + offset
	target.scale = _target_scale * scale_k
	target.modulate = tint


# --- Effet (projectile, rayon, arc, marques) -------------------------------------------

func _pose_effect(phase: MoveFxPlan.Phase, k: float) -> void:
	if _is_contact():
		if phase.name == MoveFxPlan.IMPACT:
			_pose_marks(k)
		return
	if _plan.on_self:
		return
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


func _show_beam(from: Vector2, to: Vector2, k: float, alpha: float) -> void:
	_beam.visible = alpha > 0.0
	_beam.points = PackedVector2Array([from, to])
	_color_line(_beam, BEAM_WIDTH * lerpf(0.4, 1.0, k), alpha)


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
	for i: int in 3:
		_marks.append(_make_line(&"Mark%d" % i, MARK_WIDTH))
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


static func _ease_out(k: float) -> float:
	return 1.0 - (1.0 - k) * (1.0 - k)


static func _ease_in_out(k: float) -> float:
	return k * k * (3.0 - 2.0 * k)
