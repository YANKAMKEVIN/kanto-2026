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
## brisé, Électrique), `beam` / `ice_beam` / `jet` (rayon qui s'allonge), vide (rien ne part du
## lanceur : statut positif, soin, regard de RP-286), `sand_spray` (gerbe de grains, Jet de
## Sable) ; vague 1 « Effets fidèles à Rouge » : `bubbles` (bulles qui flottent et éclatent),
## `needle` (aiguille), `seed_arc` (graines en arc qui germent), `string` (fils tendus puis
## enroulés), `whip` (liane qui claque), `powder_fall` (poudre qui tombe d'en haut) ; sinon un
## projectile lumineux. Gestes du lanceur (`bricks.launch`) : `tail_wag` (il se dandine),
## `powder_shake` (il s'ébroue), `rear_back` (il recule puis se détend). Formes dessinées en code :
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
## Gerbe de Jet de Sable (RP-286) [D] : taille d'un grain peint et d'une bouffée de poussière
## teintée (palette de la famille) qui l'accompagne, en hauteurs d'écran ; bouffées par gerbe.
const SPRAY_GRAIN: float = 0.05
## Regard (RP-286) [D] : taille de l'œil sur le lanceur, en hauteurs d'écran.
const GAZE_SIZE: float = 0.16
const SPRAY_DUST: float = 0.09
const SPRAY_DUST_AMOUNT: int = 20
## Rôles des sprites d'art : le trajet (projectile, arc), l'impact, deux étincelles de joues, trois
## copies en série (ondes du trajet, flux du drain, anneau du piège : jamais dans la même phase).
enum Flip { TRAVEL, IMPACT, EXTRA_A, EXTRA_B, WAVE_A, WAVE_B, WAVE_C }
## Vague 1 « Effets fidèles à Rouge » [D] (2026-11-02, à régler sur téléphone).
## Gestes du lanceur : dandinement (part de sa largeur, balancements), ébrouement (px, secousses),
## recul (px).
const WAG_SHIFT: float = 0.09
const WAG_SWINGS: float = 2.0
const SHAKE_HOP: float = 10.0
const SHAKE_SWINGS: float = 3.0
const REAR_BACK: float = 16.0
## Briques de lancement qui sont un geste (pas de lueur ni de particules aspirées).
const GESTURES: Array[String] = ["tail_wag", "powder_shake", "rear_back"]
## Briques de trajet en pièces ou en traits posés par [method _pose_rouge].
const ROUGE_TRAVELS: Array[String] = ["bubbles", "needle", "seed_arc", "string", "whip"]
## Pièces d'une volée (bulles, aiguille, graines, pousses, feuilles d'une liane) : au plus.
const VOLLEY_MAX: int = 24
## Bulles : petit soulèvement en vol (hauteurs d'écran), début de l'éclatement (part du vol).
const BUBBLE_LIFT: float = 0.04
const BUBBLE_POP: float = 0.85
## Remplissage d'une bulle (taille, part de la bulle ; opacité).
const BUBBLE_FILL_SIZE: float = 1.25
const BUBBLE_FILL_ALPHA: float = 0.45
## Aiguille : l'art pointe vers le bas à gauche (angle de la pointe dans l'image) ; traînée (part
## de la taille), éclat de la piqûre (hauteurs d'écran).
const NEEDLE_POINT: float = PI * 0.75
const NEEDLE_TRAIL: float = 1.6
const STING_FLASH: float = 0.14
## Graines : hauteur de l'arc, pousses (hauteurs d'écran).
const SEED_ARC: float = 0.22
const SPROUT_SIZE: float = 0.12
## Fils de Sécrétion : épaisseur (px), affaissement (hauteurs d'écran), points d'un tour de fil.
const THREAD_WIDTH: float = 7.0
const THREAD_SAG: float = 0.03
const THREAD_COUNT: int = 3
const WRAP_POINTS: int = 18
## Liane : épaisseur (px), ondulation au trajet et soulèvement entre deux claquements (hauteurs
## d'écran), points, taille d'une feuille et de l'étoile du claquement (hauteurs d'écran).
const WHIP_WIDTH: float = 30.0
const WHIP_WAVE: float = 0.07
const WHIP_LIFT: float = 0.16
const WHIP_POINTS: int = 16
const WHIP_LEAF: float = 0.07
const CRACK_SIZE: float = 0.16
## Bec : taille d'une marque (part de la marque du Contact), points frappés (parts de la cible).
const PECK_POP: float = 0.5
const PECK_SPOTS: Array[Vector2] = [Vector2(-0.16, -0.14), Vector2(0.14, 0.06),
	Vector2(-0.04, 0.2)]
const DRILL_TURNS: float = 2.5
## Poudres : départ au-dessus de la cible (hauteurs d'écran), grains et scintillements.
const POWDER_HEIGHT: float = 0.1
const POWDER_GRAIN: float = 0.03
const POWDER_SPARKLE: float = 0.06
const POWDER_GRAINS: int = 64
const POWDER_SPARKLES: int = 22
## Préchauffage (RP-263) [D] : opacité du calque de préchauffage (au-dessus du seuil où le moteur
## ne dessine plus rien, invisible à l'œil), taille des éléments (px), durée de vie (s, quelques
## images).
const WARMUP_ALPHA: float = 0.02
const WARMUP_SIZE: float = 8.0
const WARMUP_DURATION: float = 0.1

## RP-263 : faux = pas de préchauffage (mesure « avant », `tools/measure_first_fx.gd`).
static var warmup_enabled: bool = true
## Préchauffage fait une fois par session : pipelines de rendu, puis chaque art peint déjà vu.
static var _warmed_pipelines: bool = false
static var _warmed_art: Dictionary[StringName, bool] = {}

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
## Vague 1 « Effets fidèles à Rouge » : pièces d'une volée, fils de Sécrétion, liane du fouet.
var _volley: Array[Sprite2D] = []
var _threads: Array[Line2D] = []
var _whip: Line2D
var _dot: Texture2D
var _seed: Texture2D
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
		if phase.name == MoveFxPlan.IMPACT:
			# Claquements suivants (fouet, bec) : un éclat de plus à chaque temps.
			for beat: int in range(1, plan.beats):
				tween.tween_callback(_beat_burst.bind(phase)).set_delay(phase.start
					+ phase.duration * beat / plan.beats)
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


## Pièce de volée [param index] : bulle, aiguille, graine, pousse, feuille (tests, galerie).
func get_piece(index: int) -> Sprite2D:
	return _volley[index]


## Fil [param index] de Sécrétion (0 à 2 : fils tendus ; 3 à 5 : tours autour de la cible).
func get_thread(index: int) -> Line2D:
	return _threads[index]


func get_whip() -> Line2D:
	return _whip


## Sprite d'art peint du rôle [param role] (tests, galerie).
func get_art(role: Flip) -> Sprite2D:
	return _flips[role]


## Préchauffage (RP-263) : dessine une fois, à peine visible (opacité [constant WARMUP_ALPHA]),
## en [param at] (px du calque), ce que les effets de [param plans] emploieront : sprites et traits
## en mélange normal et additif, émetteurs de particules des deux mélanges (une fois par session),
## et l'art peint pas encore préparé. Le calque se retire seul après [constant WARMUP_DURATION] s
## (un tween). Rend le nombre d'éléments dessinés (0 : rien de neuf, ou préchauffage coupé).
func warm_up(plans: Array[MoveFxPlan], at: Vector2) -> int:
	if not warmup_enabled:
		return 0
	_build()
	var fresh: Array[StringName] = []
	for id: StringName in MoveFxWarmup.art_ids(plans):
		if not _warmed_art.has(id):
			fresh.append(id)
	if _warmed_pipelines and fresh.is_empty():
		return 0
	var layer := Node2D.new()
	layer.name = &"Warmup"
	layer.position = at
	layer.modulate = Color(1, 1, 1, WARMUP_ALPHA)
	add_child(layer)
	if not _warmed_pipelines:
		_warmed_pipelines = true
		var dot := _projectile.texture
		for additive: bool in [false, true]:
			var material := _flip_additive if additive else null
			layer.add_child(_warm_sprite(dot, material))
			var line := _new_line(&"WarmLine", 2.0)
			line.points = PackedVector2Array([Vector2.ZERO, Vector2(WARMUP_SIZE, 0.0)])
			line.material = material
			layer.add_child(line)
			layer.add_child(_warm_emitter(dot, material))
	for id: StringName in fresh:
		_warmed_art[id] = true
		var info := FxArt.flipbook(id)
		if info.is_empty():
			info = FxArt.particle(id)
		if info.is_empty():
			continue
		var sprite := _warm_sprite(info["texture"], _flip_additive if info["additive"] else null)
		sprite.hframes = info.get("columns", 1)
		sprite.vframes = ceili(float(info.get("frames", 1)) / sprite.hframes)
		layer.add_child(sprite)
	var count := layer.get_child_count()
	var tween := create_tween()
	tween.tween_interval(WARMUP_DURATION)
	tween.tween_callback(layer.queue_free)
	return count


## Remet à zéro le préchauffage de la session (tests).
static func reset_warmup() -> void:
	_warmed_pipelines = false
	_warmed_art.clear()


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
			if not _is_contact() and not _is_gesture():
				var points := _stage.origins if not _stage.origins.is_empty() \
					else PackedVector2Array([_stage.origin()])
				for point: Vector2 in points:
					_art_burst(&"charge", point, roundi(_plan.particles / 3.0 / points.size()),
						FxParticlePool.Shape.GATHER, 24.0, 0.12 * height, phase.duration)
		MoveFxPlan.TRAVEL:
			if _is_particle_travel() and phase.hit == 0:
				if _plan.bricks.get("travel", "") == "powder_fall":
					_powder(phase)
				else:
					_spray(phase)
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
		"falling_aura", "poison_drops", "leaf_fall", "wrap":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.FALL, 26.0,
				reach * 0.6, life)
		"splash":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.FALL, 24.0, reach, life)
		"debris":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.FALL, 34.0, reach, life)
		"sting":
			# Piqûre : un éclat violet bref et serré, quelques gouttes de poison qui tombent.
			_pool.burst(at, _plan.particles, _plan.palette, FxParticlePool.Shape.BURST, 22.0,
				reach * 0.45, life * 0.6, true)
			_art_burst(&"particle", at, roundi(_plan.particles / 2.0), FxParticlePool.Shape.FALL,
				20.0, reach * 0.5, life)
		"powder_settle":
			# La poudre se dépose : un nuage léger de sa couleur gonfle sur la cible.
			_pool.burst(at, _plan.particles, _plan.palette, FxParticlePool.Shape.RISE, 44.0,
				reach * 0.35, life * 1.3)
		"sprout", "whip_crack":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.FALL, 26.0,
				reach * 0.6, life)
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


## Claquement suivant (fouet, bec) : un éclat plus petit au point d'impact.
func _beat_burst(phase: MoveFxPlan.Phase) -> void:
	if _plan == null or _missed(phase.hit):
		return
	var height := _stage.view_size.y
	_art_burst(&"particle", _stage.impact_point(), roundi(_plan.particles / 2.0),
		FxParticlePool.Shape.BURST, 26.0, 0.12 * height, clampf(phase.duration, 0.3, 0.6))


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
	elif _is_gesture():
		var gesture := _gesture(phase, k)
		offset = gesture[0]
		scale_k = gesture[1]
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
		# Claquements (fouet, bec) : la cible encaisse à chaque temps.
		var beat := phase.duration / _plan.beats
		if _plan.beats > 1:
			elapsed = beat if elapsed >= phase.duration - MoveFxPlan.EPSILON \
				else fmod(elapsed, beat)
		var stop := minf(HIT_STOP * heavy, beat * 0.5)
		var k := clampf((elapsed - stop) / maxf(beat - stop, 0.001), 0.0, 1.0)
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
	elif ROUGE_TRAVELS.has(String(_plan.bricks.get("travel", ""))):
		_pose_rouge(phase, k)
	elif _has_travel() and not _is_particle_travel() and not _pose_art(phase, k):
		_pose_shapes(phase, k)
	elif not _has_travel() and not _plan.on_self:
		# Sans trajet (regard de RP-286) : rien ne part du lanceur ; le regard reste sur lui.
		_pose_gaze(phase, k)
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
	if _plan.impact == &"bec" or _plan.impact == &"vrille":
		_pose_beak(stamp, k, base)
		return true
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


## Picpic (`bec`) : une marque brève par coup de bec, à un autre endroit de la cible chaque fois ;
## Bec Vrille (`vrille`) : la marque tourne en vrille, trois éclats spiralent vers son centre.
func _pose_beak(stamp: StringName, k: float, base: float) -> void:
	var rect := _stage.target_rect
	if _plan.impact == &"bec":
		var beat := mini(floori(k * _plan.beats), _plan.beats - 1)
		var kb := k * _plan.beats - beat
		var pop := _ease_out(clampf(kb * 4.0, 0.0, 1.0))
		var spot := PECK_SPOTS[beat % PECK_SPOTS.size()] * rect.size
		_show_flip(Flip.IMPACT, stamp, rect.get_center() + spot, Vector2.ONE * base * PECK_POP
			* lerpf(1.5, 1.0, pop), 0.3 * beat, 1.0 - clampf((kb - 0.45) / 0.55, 0.0, 1.0))
		return
	var spin := TAU * DRILL_TURNS * k
	var alpha := 1.0 - clampf((k - 0.6) / 0.4, 0.0, 1.0)
	_show_flip(Flip.IMPACT, stamp, rect.get_center(), Vector2.ONE * base * lerpf(1.2, 0.75,
		_ease_out(k)), spin, alpha)
	var roles: Array[Flip] = [Flip.EXTRA_A, Flip.EXTRA_B, Flip.WAVE_A]
	for i: int in roles.size():
		var angle := spin * 1.4 + TAU * i / roles.size()
		var radius := base * 0.6 * (1.0 - _ease_in(k))
		_show_flip(roles[i], stamp, rect.get_center() + Vector2(cos(angle), sin(angle) * 0.6)
			* radius, Vector2.ONE * base * 0.3, angle, alpha)


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
			var beat := phase.duration / _plan.beats
			var since := fmod(elapsed, beat) if elapsed < phase.duration - MoveFxPlan.EPSILON \
				else beat
			camera.set_pose(zoom, pivot, BattleCamera.shake_at(since, _plan.camera_shake, beat))
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


## La famille a une brique de trajet (vide : l'effet ne quitte pas le lanceur, ou naît sur la
## cible).
func _has_travel() -> bool:
	return not String(_plan.bricks.get("travel", "")).is_empty()


## Taille d'un projectile peint : un flipbook à [constant ART_PROJECTILE], une particule moins.
static func _projectile_scale(id: StringName) -> float:
	return 1.0 if not FxArt.flipbook(id).is_empty() else ART_PARTICLE_PROJECTILE


## Regard (RP-286 : Groz'Yeux, Regard Médusant, Mimi-Queue, Entrave) : pendant l'anticipation,
## l'art `charge` de la famille (œil menaçant) s'ouvre sur le lanceur puis s'éteint ; l'aura
## naît ensuite sur la cible (impact), sans rien entre les deux.
func _pose_gaze(phase: MoveFxPlan.Phase, k: float) -> void:
	var id := _plan.art.get(&"charge", &"") as StringName
	if phase.name != MoveFxPlan.ANTICIPATION or id.is_empty():
		return
	var alpha := minf(1.0, k * 3.0) * (1.0 - clampf((k - 0.7) / 0.3, 0.0, 1.0))
	var size := GAZE_SIZE * _stage.view_size.y * lerpf(0.6, 1.0, _ease_out(k))
	_show_flip(Flip.EXTRA_A, id, _stage.origin(), Vector2.ONE * size, 0.0, alpha)


## La brique de lancement est un geste du lanceur (pas de lueur ni de particules aspirées).
func _is_gesture() -> bool:
	return GESTURES.has(String(_plan.bricks.get("launch", "")))


## Geste du lanceur : [décalage (px), échelle]. Mimi-Queue (`tail_wag`) : il se dandine de côté
## (balancements amortis, léger écrasement à chaque bascule) ; poudres (`powder_shake`) : petits
## sauts rapides ; `rear_back` : il recule pendant l'anticipation et se détend au départ.
func _gesture(phase: MoveFxPlan.Phase, k: float) -> Array:
	var offset := Vector2.ZERO
	var scale_k := Vector2.ONE
	var dir := (_stage.target_rest - _stage.user_rest).normalized()
	match String(_plan.bricks.get("launch", "")):
		"tail_wag":
			if phase.name == MoveFxPlan.ANTICIPATION:
				var swing := sin(TAU * WAG_SWINGS * k) * sin(PI * k)
				offset.x = swing * WAG_SHIFT * _stage.user_rect.size.x
				scale_k = Vector2(1.0 - 0.03 * absf(swing), 1.0 + 0.02 * absf(swing))
		"powder_shake":
			if phase.name == MoveFxPlan.ANTICIPATION:
				offset.y = -absf(sin(PI * SHAKE_SWINGS * k)) * SHAKE_HOP * sin(PI * k)
		"rear_back":
			match phase.name:
				MoveFxPlan.ANTICIPATION:
					offset = -dir * REAR_BACK * _ease_out(k)
				MoveFxPlan.TRAVEL:
					var snap := clampf(k * 3.0, 0.0, 1.0)
					offset = -dir * REAR_BACK * (1.0 - snap) + dir * REAR_BACK * 0.6 * sin(PI * snap)
	return [offset, scale_k]


## Trajets de la vague 1 « Effets fidèles à Rouge » (pièces et traits).
func _pose_rouge(phase: MoveFxPlan.Phase, k: float) -> void:
	match String(_plan.bricks.get("travel", "")):
		"bubbles":
			_pose_bubbles()
		"needle":
			_pose_needle(phase, k)
		"seed_arc":
			_pose_seeds()
		"string":
			_pose_string(phase, k)
		"whip":
			_pose_whip(phase, k)


## Phase qui conclut le coup 0 : impact, raté ou sans effet (null si l'attaque échoue).
func _strike() -> MoveFxPlan.Phase:
	for strike_name: StringName in [MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT]:
		var found := _plan.phase(strike_name)
		if found != null:
			return found
	return null


## Nombre pseudo-aléatoire stable dans [0, 1) pour la pièce [param i] (même rendu à chaque fois).
static func _rand(i: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + 4.1414) * 43758.5453, 1.0)


func _depth_far() -> float:
	return PROJECTILE_FAR if _stage.user_is_player else PROJECTILE_NEAR


## Écume, Bulles d'O : les bulles partent l'une après l'autre, flottent en ondulant (montée légère)
## vers des points de la cible, gonflent et s'effacent en arrivant (elles éclatent) ; la volée
## dure du trajet à la fin de l'impact.
func _pose_bubbles() -> void:
	var travel := _plan.phase(MoveFxPlan.TRAVEL)
	var strike := _strike()
	var info := FxArt.particle(_plan.art.get(&"piece", &""))
	if travel == null or strike == null:
		return
	var u := (_t - travel.start) / maxf(strike.end() - travel.start, 0.001)
	if u <= 0.0 or u > 1.0 + MoveFxPlan.EPSILON:
		return
	var height := _stage.view_size.y
	var from := _stage.origin()
	var to := _miss_point() if _missed(0) else _stage.impact_point()
	var normal := (to - from).orthogonal().normalized()
	var count := mini(_plan.volley_count, floori(VOLLEY_MAX * 0.5))
	var flight := maxf(1.0 - _plan.volley_stagger * (count - 1), 0.1)
	var rect := _stage.target_rect
	for i: int in count:
		var p := (u - _plan.volley_stagger * i) / flight
		if p <= 0.0 or p >= 1.0:
			continue
		var r := _rand(i)
		var aim := to + Vector2((r - 0.5) * rect.size.x * 0.5, (_rand(i + 31) - 0.5)
			* rect.size.y * 0.4)
		var e := lerpf(p, _ease_out(p), 0.5)
		var at := from.lerp(aim, e) + normal * sin(TAU * (1.5 * p + r)) * _plan.volley_wobble \
			* height * (1.0 - 0.5 * p) + Vector2(0.0, -sin(PI * p) * BUBBLE_LIFT * height)
		var pop := clampf((p - BUBBLE_POP) / (1.0 - BUBBLE_POP), 0.0, 1.0)
		var size := _plan.volley_size * height * lerpf(0.75, 1.25, r) \
			* lerpf(1.0, _depth_far(), p * 0.5) * (1.0 + 0.4 * pop)
		var alpha := minf(1.0, p * 6.0) * (1.0 - pop)
		# Sous la bulle de verre peinte (presque transparente sur un décor de plein jour), un
		# remplissage d'eau léger de la couleur de la famille la rend lisible en vol.
		_show_piece(VOLLEY_MAX - 1 - i, {"texture": _dot, "additive": false}, at, Vector2.ONE
			* size * BUBBLE_FILL_SIZE, 0.0, alpha * BUBBLE_FILL_ALPHA, _color(1))
		_show_piece(i, info, at, Vector2.ONE * size, 0.0, alpha)


## Dard-Venin : l'aiguille file en accélérant vers la cible, une traînée derrière elle ; elle se
## plante, un éclat violet marque la piqûre, puis elle s'efface.
func _pose_needle(phase: MoveFxPlan.Phase, k: float) -> void:
	var info := FxArt.particle(_plan.art.get(&"piece", &""))
	var height := _stage.view_size.y
	var from := _stage.origin()
	var to := _miss_point() if _missed(phase.hit) else _stage.impact_point()
	var dir := (to - from).normalized()
	var angle := dir.angle() - NEEDLE_POINT
	var size := Vector2.ONE * _plan.volley_size * height
	match phase.name:
		MoveFxPlan.TRAVEL:
			var p := lerpf(k, _ease_in(k), 0.6)
			var at := from.lerp(to, p)
			var scale_k := lerpf(1.0, _depth_far(), p * 0.5)
			# Halo violet léger sous l'aiguille (fine, elle se perdrait sur le décor).
			_show_piece(2, {"texture": _dot, "additive": true}, at, size * scale_k * 0.6, 0.0,
				0.6 * minf(1.0, k * 8.0), _color(1))
			_show_piece(0, info, at, size * scale_k, angle, minf(1.0, k * 8.0))
			var trail := _threads[0]
			trail.visible = k > 0.05
			trail.points = PackedVector2Array([at - dir * size.x * NEEDLE_TRAIL * scale_k * k, at])
			_color_line(trail, THREAD_WIDTH * 1.4, 0.75)
		MoveFxPlan.IMPACT:
			_show_piece(0, info, to, size * _depth_far(), angle, 1.0 - clampf(k / 0.45, 0.0, 1.0))
			var flash := _ease_out(clampf(k * 3.0, 0.0, 1.0))
			_show_piece(1, {"texture": _dot, "additive": true}, to, Vector2.ONE * STING_FLASH
				* height * lerpf(0.4, 1.0, flash), 0.0, 1.0 - clampf(k / 0.5, 0.0, 1.0), _color(1))
		MoveFxPlan.MISS:
			var past := to + (to - from) * MISS_OVERSHOOT * k
			_show_piece(0, info, past, size * _depth_far(), angle, 1.0 - k)


## Vampigraine : les graines partent en arc l'une après l'autre et se posent en haut de la cible ;
## à l'impact, une pousse sort de chacune (elle grandit avec un léger rebond), puis s'efface au
## retour. Raté : les graines tombent à côté, rien ne germe.
func _pose_seeds() -> void:
	var travel := _plan.phase(MoveFxPlan.TRAVEL)
	var strike := _strike()
	if travel == null or strike == null:
		return
	var height := _stage.view_size.y
	var from := _stage.origin()
	var rect := _stage.target_rect
	var missed := _missed(0)
	var center := _miss_point() if missed else _stage.impact_point()
	var count := mini(_plan.volley_count, floori(VOLLEY_MAX * 0.5))
	var flight := maxf(1.0 - _plan.volley_stagger * (count - 1), 0.1)
	var sprout := FxArt.particle(_plan.art.get(&"sprout", &""))
	var seed_info := {"texture": _seed, "additive": false}
	var seed_size := Vector2(1.0, 0.7) * _plan.volley_size * height
	var back := _plan.phase(MoveFxPlan.RETURN)
	for i: int in count:
		var land := center + Vector2((i - (count - 1) * 0.5) * rect.size.x * 0.26,
			-rect.size.y * (0.12 + 0.08 * _rand(i)))
		if _t < strike.start:
			var p := (((_t - travel.start) / travel.duration) - _plan.volley_stagger * i) / flight
			if p <= 0.0:
				continue
			p = minf(p, 1.0)
			var at := _seed_at(from, land, p, height)
			var ahead := _seed_at(from, land, minf(p + 0.05, 1.0), height)
			_show_piece(i, seed_info, at, seed_size * lerpf(1.0, _depth_far(), p),
				(ahead - at).angle(), 1.0)
			continue
		var since := _t - strike.start
		var fade := 1.0
		if back != null and _t >= back.start:
			fade = 1.0 - _ease_in(clampf((_t - back.start) / back.duration, 0.0, 1.0))
		if missed:
			var drop := clampf(since / strike.duration, 0.0, 1.0)
			_show_piece(i, seed_info, land + Vector2(0.0, drop * rect.size.y * 0.5), seed_size
				* _depth_far(), 0.0, 1.0 - drop)
			continue
		_show_piece(i, seed_info, land, seed_size * _depth_far(), 0.0, fade)
		var grow := clampf(since / (strike.duration * 0.6) - 0.15 * i, 0.0, 1.0)
		if grow <= 0.0 or sprout.is_empty():
			continue
		var g := _ease_out(grow)
		var size := Vector2(0.8, 1.0 + 0.15 * sin(PI * g)) * SPROUT_SIZE * height * g
		_show_piece(count + i, sprout, land, size, (_rand(i + 7) - 0.5) * 0.5, fade, Color.WHITE,
			true)


static func _seed_at(from: Vector2, land: Vector2, p: float, height: float) -> Vector2:
	return from.lerp(land, p) + Vector2(0.0, -sin(PI * p) * SEED_ARC * height)


## Sécrétion : trois fils se tendent du lanceur à la cible l'un après l'autre (légèrement
## affaissés) ; à l'impact, ils s'effacent pendant que trois tours de fil se dessinent autour de
## la cible (moitié avant), qui restent jusqu'au retour.
func _pose_string(phase: MoveFxPlan.Phase, k: float) -> void:
	var height := _stage.view_size.y
	var from := _stage.origin()
	var rect := _stage.target_rect
	var to := _miss_point() if _missed(phase.hit) else _stage.impact_point()
	for i: int in THREAD_COUNT:
		var aim := to + Vector2(0.0, (i - 1) * rect.size.y * 0.22)
		var reach := 0.0
		var alpha := 1.0
		match phase.name:
			MoveFxPlan.TRAVEL:
				reach = _ease_out(clampf((k - 0.15 * i) / 0.7, 0.0, 1.0))
			MoveFxPlan.IMPACT, MoveFxPlan.NO_EFFECT:
				reach = 1.0
				alpha = 1.0 - _ease_in(k)
			MoveFxPlan.MISS:
				reach = 1.0
				alpha = 1.0 - k
		if reach <= 0.0 or alpha <= 0.0:
			continue
		var line := _threads[i]
		line.visible = true
		var points := PackedVector2Array()
		var tip := from.lerp(aim, reach)
		var sag := Vector2(0.0, THREAD_SAG * height * (0.5 + 0.5 * reach))
		for j: int in 9:
			var s := j / 8.0
			points.append(from.lerp(tip, s) + sag * sin(PI * s))
		line.points = points
		_color_line(line, THREAD_WIDTH, alpha)
	if not _plan.lands() or _missed(phase.hit):
		return
	var wrap := 0.0
	var wrap_alpha := 1.0
	match phase.name:
		MoveFxPlan.IMPACT:
			wrap = k
		MoveFxPlan.RETURN:
			wrap = 1.0
			wrap_alpha = 1.0 - _ease_in(k)
		_:
			return
	for i: int in THREAD_COUNT:
		var w := _ease_out(clampf(wrap * 1.6 - 0.25 * i, 0.0, 1.0))
		if w <= 0.0:
			continue
		var line := _threads[THREAD_COUNT + i]
		line.visible = true
		var center := rect.get_center() + Vector2(0.0, (i - 1) * rect.size.y * 0.2)
		var radius := Vector2(rect.size.x * lerpf(0.5, 0.42, w), rect.size.x * 0.09)
		var tilt := 0.12 * (i - 1)
		var points := PackedVector2Array()
		for j: int in WRAP_POINTS + 1:
			var a := PI * w * j / WRAP_POINTS
			points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y
				+ cos(a) * radius.x * tilt))
		line.points = points
		_color_line(line, THREAD_WIDTH, wrap_alpha)


## Fouet Lianes : la liane sort du lanceur, une ondulation court jusqu'au bout et la tend sur la
## cible (1er claquement) ; elle se relève en arc et retombe (2e claquement) ; au retour, elle se
## retire vers le lanceur. Feuilles peintes le long de la liane, étoile à chaque claquement.
func _pose_whip(phase: MoveFxPlan.Phase, k: float) -> void:
	var height := _stage.view_size.y
	var from := _stage.origin()
	var missed := _missed(phase.hit)
	var to := _miss_point() if missed else _stage.impact_point()
	var tip := to
	var wave := 0.0
	var lift := 0.0
	var alpha := 1.0
	var crack := -1.0
	match phase.name:
		MoveFxPlan.ANTICIPATION:
			return
		MoveFxPlan.TRAVEL:
			tip = from.lerp(to, _ease_out(k))
			wave = WHIP_WAVE * height * (1.0 - k)
		MoveFxPlan.IMPACT, MoveFxPlan.NO_EFFECT:
			var beat := mini(floori(k * _plan.beats), _plan.beats - 1)
			var kb := k * _plan.beats - beat
			crack = kb
			if beat < _plan.beats - 1 and kb < 0.85:
				# Entre deux claquements : la liane se relève, puis retombe d'un coup.
				lift = sin(PI * kb / 0.85)
				tip = to.lerp(from, 0.18 * lift)
		MoveFxPlan.MISS:
			tip = to + (to - from) * 0.15 * k
			alpha = 1.0 - _ease_in(k)
		MoveFxPlan.RETURN:
			tip = to.lerp(from, _ease_in_out(k))
			alpha = 1.0 - _ease_in(k) * 0.6
	if from.distance_to(tip) < 1.0:
		return
	var normal := (tip - from).orthogonal().normalized()
	if normal.y > 0.0:
		normal = -normal
	var points := PackedVector2Array()
	for j: int in WHIP_POINTS:
		var s := j / float(WHIP_POINTS - 1)
		var at := from.lerp(tip, s)
		at += normal * sin(TAU * (s * 1.3 - _t * 2.5)) * wave * sin(PI * s)
		at += normal * sin(PI * s) * lift * WHIP_LIFT * height
		points.append(at)
	_whip.points = points
	_whip.visible = true
	_color_whip(alpha)
	var leaf := FxArt.particle(_plan.art.get(&"piece", &""))
	for i: int in 3:
		var at := points[roundi((0.3 + 0.25 * i) * (WHIP_POINTS - 1))]
		var side := 1.0 if i % 2 == 0 else -1.0
		_show_piece(i, leaf, at + normal * side * WHIP_LEAF * height * 0.35, Vector2.ONE
			* WHIP_LEAF * height, normal.angle() * side, alpha)
	if crack >= 0.0 and not missed:
		var star := FxArt.particle(_plan.art.get(&"crack", &""))
		var pop := _ease_out(clampf(crack * 4.0, 0.0, 1.0))
		_show_piece(3, star, to, Vector2.ONE * CRACK_SIZE * height * lerpf(0.5, 1.1, pop),
			crack * 0.6, 1.0 - clampf((crack - 0.25) / 0.4, 0.0, 1.0))


## Liane : corps vert sombre, cœur plus clair.
func _color_whip(alpha: float) -> void:
	_whip.width = WHIP_WIDTH
	_whip.default_color = Color(_color(2), alpha)
	var core := _whip.get_child(0) as Line2D
	core.points = _whip.points
	core.width = WHIP_WIDTH * 0.55
	core.default_color = Color(_color(1), alpha)


## Pièce de volée [param index] : la particule [param info] ({texture, additive}, vide : rien)
## centrée en [param at] (pieds en [param at] avec [param from_feet]), à [param size] px.
func _show_piece(index: int, info: Dictionary, at: Vector2, size: Vector2, angle: float,
		alpha: float, tint: Color = Color.WHITE, from_feet: bool = false) -> void:
	if info.is_empty() or alpha <= 0.0 or size.x <= 0.0 or size.y <= 0.0 or index >= VOLLEY_MAX:
		return
	var texture: Texture2D = info["texture"]
	var sprite := _volley[index]
	sprite.visible = true
	sprite.texture = texture
	sprite.material = _flip_additive if info["additive"] else null
	sprite.offset = Vector2(0.0, -texture.get_height() * 0.5) if from_feet else Vector2.ZERO
	sprite.position = at
	sprite.rotation = angle
	sprite.scale = size / Vector2(texture.get_width(), texture.get_height())
	sprite.modulate = Color(tint, alpha)


## Poudres : grains de la couleur de la variante (peints s'il y en a : Spore) et scintillements
## tombent d'au-dessus de la cible, en pluie continue jusqu'à la fin de l'impact.
func _powder(phase: MoveFxPlan.Phase) -> void:
	var height := _stage.view_size.y
	var rect := _stage.target_rect
	var to := _miss_point() if _missed(phase.hit) else _stage.impact_point()
	var top := Vector2(to.x, rect.position.y - POWDER_HEIGHT * height)
	var fall := to.y + rect.size.y * 0.25 - top.y
	var strike := _strike()
	var life := phase.duration + (strike.duration if strike != null else 0.0)
	var width := rect.size.x * 0.4
	# La colonne de pluie couvre le haut de la cible et l'air au-dessus.
	top.y += fall * FxParticlePool.SIFT_COLUMN
	var grain := _art_texture(&"powder")
	_pool.burst(top, roundi(POWDER_GRAINS * _plan.particle_scale), _plan.palette,
		FxParticlePool.Shape.SIFT, POWDER_GRAIN * height * (2.0 if grain != null else 1.0), fall,
		life, false, grain, Vector2.DOWN, width)
	_pool.burst(top, roundi(POWDER_SPARKLES * _plan.particle_scale), _plan.palette,
		FxParticlePool.Shape.SIFT, POWDER_SPARKLE * height, fall, life, true,
		_art_texture(&"sparkle"), Vector2.DOWN, width, true)


## Trajet fait de particules seules (`sand_spray`, Jet de Sable, RP-286) : ni projectile ni art
## de trajet ; la gerbe part au début du trajet ([method _spray]).
func _is_particle_travel() -> bool:
	var travel: String = _plan.bricks.get("travel", "")
	return travel == "sand_spray" or travel == "powder_fall"


## Gerbe de grains (Jet de Sable) : un flux en éventail serré du lanceur vers la cible (ou à côté
## si l'attaque rate), grains peints (`spray`, sinon `particle`) qui arrivent en fin de trajet.
func _spray(phase: MoveFxPlan.Phase) -> void:
	var from := _stage.origin()
	var to := _miss_point() if _missed(phase.hit) else _stage.impact_point()
	var role := &"spray" if _plan.art.has(&"spray") else &"particle"
	var amount := roundi(FxParticlePool.MAX_PER_EMITTER * _plan.particle_scale)
	var life := maxf(phase.duration * 1.1, 0.1)
	var height := _stage.view_size.y
	_pool.burst(from, roundi(SPRAY_DUST_AMOUNT * _plan.particle_scale), _plan.palette,
		FxParticlePool.Shape.SPRAY, SPRAY_DUST * height, from.distance_to(to), life * 1.1, false,
		null, to - from)
	_pool.burst(from, amount, _plan.palette, FxParticlePool.Shape.SPRAY,
		SPRAY_GRAIN * height, from.distance_to(to), life, false, _art_texture(role), to - from)


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
	for piece: Sprite2D in _volley:
		piece.visible = false
	for thread: Line2D in _threads:
		thread.visible = false
	_whip.visible = false
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
	_dot = dot
	_seed = _seed_texture()
	for i: int in VOLLEY_MAX:
		var piece := _make_sprite(StringName("Piece%d" % i), null, null)
		add_child(piece)
		_volley.append(piece)
	for i: int in THREAD_COUNT * 2:
		var thread := _make_line(StringName("Thread%d" % i), THREAD_WIDTH)
		thread.width_curve = null
		(thread.get_child(0) as Line2D).width_curve = null
		_threads.append(thread)
	_whip = _make_line(&"Whip", WHIP_WIDTH)
	var taper := Curve.new()
	taper.add_point(Vector2(0.0, 1.0))
	taper.add_point(Vector2(1.0, 0.3))
	_whip.width_curve = taper
	(_whip.get_child(0) as Line2D).width_curve = taper
	_hide_shapes()


## Graine (Vampigraine) dessinée en code [phase DA] : ovale brun, cœur clair.
static func _seed_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.25, 0.8, 0.92, 1.0])
	gradient.colors = PackedColorArray([Color("#F2DEB0"), Color("#B88A4A"), Color("#5A3C1A"),
		Color("#3A2410"), Color(0.23, 0.14, 0.06, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	return texture


## Sprite de préchauffage : [param texture] ramenée à [constant WARMUP_SIZE] px.
func _warm_sprite(texture: Texture2D, material: Material) -> Sprite2D:
	var sprite := _make_sprite(&"WarmSprite", texture, material)
	var width := maxf(texture.get_width(), 1.0) if texture != null else 1.0
	sprite.scale = Vector2.ONE * WARMUP_SIZE / width
	return sprite


## Émetteur de préchauffage : une particule, même réglage de rendu que [FxParticlePool].
func _warm_emitter(texture: Texture2D, material: Material) -> CPUParticles2D:
	var emitter := CPUParticles2D.new()
	emitter.name = &"WarmEmitter"
	emitter.amount = 1
	emitter.one_shot = true
	emitter.explosiveness = 1.0
	emitter.lifetime = WARMUP_DURATION
	emitter.local_coords = false
	emitter.texture = texture
	emitter.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	emitter.material = material
	emitter.color_ramp = FxParticlePool.ramp(PackedColorArray([Color.WHITE]))
	emitter.scale_amount_min = WARMUP_SIZE / maxf(texture.get_width(), 1.0)
	emitter.scale_amount_max = emitter.scale_amount_min
	emitter.emitting = true
	return emitter


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
