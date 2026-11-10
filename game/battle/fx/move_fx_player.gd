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
## Ordre de dessin : le plafond d'orage (`SKY`) passe sous tout le reste.
enum Flip { SKY, TRAVEL, IMPACT, EXTRA_A, EXTRA_B, WAVE_A, WAVE_B, WAVE_C, AURA, TRAIL }
## Vague 1 « Effets fidèles à Rouge » [D] (2026-11-02, à régler sur téléphone).
## Gestes du lanceur : dandinement (part de sa largeur, balancements), ébrouement (px, secousses),
## recul (px).
const WAG_SHIFT: float = 0.09
const WAG_SWINGS: float = 2.0
const SHAKE_HOP: float = 10.0
const SHAKE_SWINGS: float = 3.0
const REAR_BACK: float = 16.0
## Briques de lancement qui sont un geste (pas de lueur ni de particules aspirées, sauf si la
## famille a un art `charge`) ; vague 2 : `teleport_out`, `splash_hop`, `swell`, `stomp`, `spoon`.
const GESTURES: Array[String] = ["tail_wag", "powder_shake", "rear_back", "teleport_out",
	"splash_hop", "swell", "stomp", "spoon"]
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
## Vague 2 « Effets fidèles à Rouge » [D] (2026-11-04, à régler sur téléphone).
## Trajets et impacts posés par [method _pose_rouge2] (l'impact seul quand la famille n'a pas de
## trajet).
const ROUGE2_TRAVELS: Array[String] = ["rockfall", "smoke_ball", "gas_drift", "stars", "sky_bolt",
	"giant_orb", "bone", "strange_orb", "lob", "underground", "ground_pillar", "wave_sweep"]
const ROUGE2_IMPACTS: Array[String] = ["explosions", "screen_flash", "field_haze", "fissure_open",
	"electric_cage", "fire_vortex", "beam_up", "warp_aura", "sunshine", "rain"]
## Impacts sans tremblement de la cible (Flash, Buée Noire) ; impacts où elle ondule sur place.
const STILL_IMPACTS: Array[String] = ["field_haze", "screen_flash", "sunshine", "rain", "shield",
	"barrier_wall"]
const WOBBLE_IMPACTS: Array[String] = ["distortion", "warp_aura", "dizzy"]
## Volée d'aiguilles (Double-Dard, Dard-Nuée) : écart entre deux aiguilles (hauteurs d'écran).
const NEEDLE_SPACING: float = 0.05
## Chute de pierres : hauteur de chute et rebond (hauteurs d'écran), ombre au sol (part de la
## pierre), gravillons de l'anticipation.
const ROCK_DROP: float = 0.6
const ROCK_BOUNCE: float = 0.05
const ROCK_SHADOW: float = 1.3
const ROCK_GRIT: int = 16
## Téléport : largeur du trait (part du lanceur), colonne de lumière (hauteurs d'écran).
const TELEPORT_THIN: float = 0.06
const TELEPORT_COLUMN := Vector2(0.2, 1.1)
## Trempette : hauteur d'un saut (hauteurs d'écran), sauts.
const HOP_HEIGHT: float = 0.08
const HOPS: int = 2
## Explosion : gonflement et tremblement du lanceur (px) ; dispersion des explosions (parts de la
## cible) ; part du flipbook jouée une fois (la fin de l'atlas reboucle vers la première image).
const SWELL: float = 0.12
const SWELL_TREMBLE: float = 5.0
const BLAST_SPREAD := Vector2(0.6, 0.4)
const BLAST_ONCE: float = 0.87
## Abîme : élan du lanceur (px).
const STOMP_RISE: float = 22.0
## Brouillard : hauteur de l'arc (hauteurs d'écran), bouffées de la traînée.
const SMOKE_ARC: float = 0.12
const SMOKE_TRAIL: int = 4
## Gaz : les bouffées grossissent jusqu'à ce facteur.
const GAS_GROW: float = 1.9
## Fatal-Foudre : largeur de l'image de la foudre (hauteurs d'écran), assombrissement de la scène.
const BOLT_SKY_WIDTH: float = 0.5
const STORM_DARK: float = 0.8
## Poings : poing (part de la marque du Contact), élément (part de la hauteur de la cible).
const PUNCH_SIZE: float = 1.1
const ELEMENT_SIZE: float = 1.4
## Léchouille, Claquoir, Pince-Masse, Cascade : tailles (parts de la cible).
const LICK_SIZE: float = 0.95
const SHELL_SIZE: float = 1.05
const PINCER_SIZE: float = 1.35
const CASCADE_SIZE := Vector2(1.05, 1.0)
## Frappe Atlas : hauteur du jet (hauteurs d'écran), instant où la cible touche le sol (part de
## l'impact).
const TOSS_HEIGHT: float = 0.26
const TOSS_SLAM: float = 0.62
## Os : arc de Massd'Os (hauteurs d'écran), tours en vol, courbe d'Osmerang (part de la distance).
const BONE_ARC: float = 0.3
const BONE_SPIN: float = 2.5
const BOOMERANG_BEND: float = 0.22
## Onde Folie : ondulation (hauteurs d'écran), rayon de l'orbite (part de la largeur de la cible).
const ORB_WAVE: float = 0.06
const ORB_ORBIT: float = 0.55
## Buée Noire : part de la largeur de vue parcourue par une nappe.
const HAZE_DRIFT: float = 0.7
## Bomb'Œuf, Pilonnage : hauteur de la cloche (hauteurs d'écran).
const LOB_ARC: float = 0.26
## Abîme : largeur de la fissure (part de la cible), enfoncement (part de sa hauteur).
const CRACK_WIDTH: float = 1.8
const CRACK_SINK: float = 0.12
## Tunnel : bosse de la traînée (hauteurs d'écran), soulèvement de la cible (part de sa hauteur).
const BURROW_BUMP: float = 0.03
const ERUPT_LIFT: float = 0.14
## Jackpot : taille d'une pièce (hauteurs d'écran), pièces.
const COIN_SIZE: float = 0.08
const COINS: int = 16
## Flash : le calque plein écran déborde de la vue (caméra qui bouge).
const SCREEN_MARGIN: float = 0.15
## Refonte Électrik (direction A, `docs/tech/attaques-electriques.md`) [D] : cage (part de la cible),
## aura du lanceur (part de sa boîte), traînée d'une charge (hauteurs d'écran), sphère d'Élecanon
## (hauteurs d'écran : taille, avancée devant le lanceur, tremblement), plafond d'orage.
const IMPACT_MAX: float = 1.0
const CAGE_SIZE: float = 1.45
const AURA_SIZE: float = 1.15
const TRAIL_HEIGHT: float = 0.24
const TRAIL_BEHIND: float = 0.3
const ORB_SIZE: float = 0.5
const ORB_AHEAD: float = 0.2
const ORB_TREMBLE: float = 0.008
const ORB_DEPTH_FAR: float = 0.82
const SKY_SIZE := Vector2(1.5, 0.62)
## Refonte Feu, direction A [D] (2026-11-10) : colonne de Feu Sacré (largeur et hauteur en hauteurs
## de la cible, haut plafonné au-dessus de l'écran) ; opacité et taille (hauteurs d'écran) du soleil de Zénith.
const PILLAR_WIDTH: float = 0.95
const PILLAR_HEIGHT: float = 2.4
const SUN_ALPHA: float = 0.45
const SUN_SIZE: float = 1.45
## Refonte Eau, direction A [D] (2026-11-10) : opacité de la pluie de Danse Pluie ; hauteur de la
## vague de Surf (hauteurs d'écran) et sa course au-delà de la cible.
const RAIN_ALPHA: float = 1.0
const SURF_HEIGHT: float = 0.95
const SURF_PAST: float = 0.18
## Refonte Psy, direction A [D] (2026-11-10) : mur de Bouclier, Protection, Mur Lumière et Voile Miroir
## (largeur et hauteur en hauteurs du lanceur, avancée devant lui en largeurs du lanceur) ; œil de
## Prescience et couronne de Repos au-dessus de la tête (tailles en hauteurs du lanceur).
const WALL_SIZE := Vector2(1.0, 1.45)
const WALL_AHEAD: float = 0.55
const EYE_SIZE: float = 0.75
const CROWN_SIZE: float = 1.0
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
## Vague 2 : calque plein écran des éclairs blancs (Flash, Fatal-Foudre, Explosion).
var _screen: ColorRect
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
				tween.tween_callback(_beat_burst.bind(phase, beat)).set_delay(phase.start
					+ phase.duration * beat / plan.beats)
	_schedule_extras(tween, plan)
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
			if not _is_contact() and (not _is_gesture() or _plan.art.has(&"charge")):
				var points := _stage.origins if not _stage.origins.is_empty() \
					else PackedVector2Array([_stage.origin()])
				for point: Vector2 in points:
					_art_burst(&"charge", point, roundi(_plan.particles / 3.0 / points.size()),
						FxParticlePool.Shape.GATHER, 24.0, 0.12 * height, phase.duration)
			if phase.name == MoveFxPlan.CHARGE and _travel() == "underground":
				_dig_spray(phase)
		MoveFxPlan.TRAVEL:
			if _is_particle_travel() and phase.hit == 0:
				if _plan.bricks.get("travel", "") == "powder_fall":
					_powder(phase)
				else:
					_spray(phase)
			elif _travel() == "rockfall" and phase.hit == 0:
				_grit(phase)
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
		# Vague 2 « Effets fidèles à Rouge ».
		"rock_land":
			_rock_burst(0)
		"explosions":
			_blast_burst(0)
		"electric_cage", "fire_vortex":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.RISE, 22.0, reach * 0.7,
				life * 1.5, true)
		"orb_blast":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.BURST, 46.0, reach * 3.0,
				life * 1.3, true)
			_art_burst(&"rise", Vector2(at.x, _stage.target_rect.end.y), roundi(_plan.particles / 2.0),
				FxParticlePool.Shape.FALL, 0.022 * height, reach * 1.8, life * 1.5)
		"beam_up":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.RISE, 26.0,
				reach * 2.0, life * 1.3, true)
		"smoke_cloud", "gas_cloud":
			_art_burst(&"particle", at, roundi(_plan.particles / 2.0), FxParticlePool.Shape.RISE,
				0.12 * height, reach * 0.6, life * 1.6)
		"screen_flash", "warp_aura":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.FALL, 26.0,
				reach * 0.6, life)
		"star_burst":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.BURST, 34.0, reach, life)
			_art_burst(&"spark", at, roundi(_plan.particles / 2.0), FxParticlePool.Shape.BURST, 30.0,
				reach * 0.7, life * 0.8)
		"element_burst", "lob_burst":
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.BURST, 32.0, reach, life)
			_art_burst(&"rise", at, roundi(_plan.particles / 2.0), FxParticlePool.Shape.RISE, 30.0,
				reach * 0.9, life * 1.4)
		"bone_hit", "toss_slam":
			_art_burst(&"particle", at, roundi(_plan.particles / 2.0), FxParticlePool.Shape.BURST,
				30.0, reach * 0.8, life)
		"dizzy":
			_art_burst(&"particle", at + Vector2(0.0, -_stage.target_rect.size.y * 0.3),
				_plan.particles, FxParticlePool.Shape.RISE, 30.0, reach * 0.6, life * 1.2)
		"field_haze":
			pass
		"fissure_open", "eruption":
			var feet := Vector2(at.x, _stage.target_rect.end.y)
			if _missed(phase.hit):
				feet = Vector2(_miss_point().x, feet.y)
			_art_burst(&"particle", feet, _plan.particles, FxParticlePool.Shape.FALL, 0.05 * height,
				reach * 1.4, life * 1.3)
			_art_burst(&"rise", feet, roundi(_plan.particles / 2.0), FxParticlePool.Shape.FALL, 30.0,
				reach, life)
		_:
			_art_burst(&"particle", at, _plan.particles, FxParticlePool.Shape.BURST, 30.0, reach, life)
	_impact_extra(at, height, life)
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


## Claquement suivant (fouet, bec) : un éclat plus petit au point d'impact ; vague 2 : la pierre
## [param beat] qui tombe (Jet-Pierres, Éboulement), l'explosion [param beat] (Explosion).
func _beat_burst(phase: MoveFxPlan.Phase, beat: int = 1) -> void:
	if _plan == null:
		return
	if _travel() == "rockfall":
		_rock_burst(beat)
		return
	if _impact_brick() == "explosions":
		_blast_burst(beat)
		return
	if _missed(phase.hit):
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
	var alpha := 1.0
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
		glow = gesture[2]
		alpha = gesture[3]
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
	user.modulate.a = _user_modulate.a * alpha


func _pose_target(phase: MoveFxPlan.Phase, elapsed: float) -> void:
	var target := _stage.target
	if target == null or _plan.on_self:
		return
	var offset := Vector2.ZERO
	var scale_k := Vector2.ONE
	var tint := _target_modulate
	if phase.name == MoveFxPlan.IMPACT and _plan.impact_brick == &"toss" and _plan.lands() \
			and _plan.target_shake:
		_pose_toss(phase, elapsed)
		return
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
		var still := STILL_IMPACTS.has(impact_brick) or WOBBLE_IMPACTS.has(impact_brick)
		if elapsed < stop:
			hit_k = 1.0
		elif _plan.target_shake:
			match impact_brick:
				"distortion", "warp_aura", "dizzy", "field_haze", "screen_flash":
					pass
				"vibrate", "electric_cage", "fire_vortex":
					offset.x = sin(TAU * VIBRATE_WAVES * k) * VIBRATE_SHAKE * hit_k
				_:
					offset.x = sin(TAU * HIT_SHAKE_WAVES * k) * HIT_SHAKE * heavy * hit_k
		var push := (_stage.target_rest - _stage.user_rest).normalized() * 8.0 * hit_k
		offset += push if _plan.target_shake and not still else Vector2.ZERO
		scale_k = Vector2(1.0 + HIT_SQUASH * hit_k, 1.0 - HIT_SQUASH * hit_k)
		if WOBBLE_IMPACTS.has(impact_brick):
			# Psy : la cible ondule (largeur et hauteur en opposition), sans quitter sa place.
			var wave := sin(TAU * DISTORT_WAVES * k) * DISTORT_SQUASH * sin(PI * k)
			scale_k = Vector2(1.0 + wave, 1.0 - wave)
		elif impact_brick == "field_haze":
			scale_k = Vector2.ONE
		var flash := HIT_DIM if _plan.reduce_flashes else HIT_BRIGHT
		tint = _target_modulate.lerp(_target_modulate * flash, hit_k * hit_k)
		if impact_brick == "field_haze":
			tint = _target_modulate
		offset += _target_rouge2(phase, elapsed)
	if phase.name == MoveFxPlan.IMPACT or phase.name == MoveFxPlan.RETURN:
		tint = _target_veil(phase, tint)
	target.position = _stage.target_rest + offset
	target.scale = _target_scale * scale_k
	target.modulate = tint


# --- Effet (projectile, rayon, arc, marques) -------------------------------------------

func _pose_effect(phase: MoveFxPlan.Phase, k: float) -> void:
	if _is_contact():
		if phase.name == MoveFxPlan.IMPACT and not _pose_stamp(k):
			_pose_marks(k)
	elif ROUGE_TRAVELS.has(_travel()):
		_pose_rouge(phase, k)
	elif ROUGE2_TRAVELS.has(_travel()) or ROUGE2_IMPACTS.has(_impact_brick()):
		_pose_rouge2(phase, k)
	elif _has_travel() and not _is_particle_travel() and not _pose_art(phase, k):
		_pose_shapes(phase, k)
	elif not _has_travel() and not _plan.on_self:
		# Sans trajet (regard de RP-286) : rien ne part du lanceur ; le regard reste sur lui.
		_pose_gaze(phase, k)
	_pose_impact_art()
	_pose_aura(phase, k)
	_pose_trail(phase, k)
	_pose_trap(phase, k)
	_pose_drain(phase, k)
	_pose_wall(phase, k)
	_pose_eye(phase, k)
	_pose_crown(phase, k)


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
					* _projectile_scale(travel) * _plan.travel_scale, angle, 1.0)
		MoveFxPlan.TRAVEL:
			if not bolt.is_empty():
				var reach := from.distance_to(to) * _ease_out(k)
				_show_bolt_art(bolt, from, reach, angle, 1.0)
				if _plan.art.has(&"cheeks"):
					_pose_cheeks(1.0 - k)
			else:
				var s := k * k * (3.0 - 2.0 * k)
				var size := ART_PROJECTILE * height * lerpf(1.0, depth_far, k) * _projectile_scale(travel) \
					* _plan.travel_scale
				_show_flip(Flip.TRAVEL, travel, from.lerp(to, s), Vector2.ONE * size, angle, 1.0)
		MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
			var fade := 1.0 - _ease_in(k)
			if not bolt.is_empty():
				_show_bolt_art(bolt, from, from.distance_to(to), angle, fade
					* (1.0 if phase.name == MoveFxPlan.IMPACT else 0.6))
			elif phase.name == MoveFxPlan.MISS:
				var past := to + (to - from) * MISS_OVERSHOOT * k
				_show_flip(Flip.TRAVEL, travel, past, Vector2.ONE * ART_PROJECTILE * height
					* depth_far * _projectile_scale(travel) * _plan.travel_scale, angle, fade)
			elif phase.name == MoveFxPlan.NO_EFFECT:
				_show_flip(Flip.TRAVEL, travel, to, Vector2.ONE * ART_PROJECTILE * height
					* lerpf(0.8, 0.2, k) * _projectile_scale(travel) * _plan.travel_scale, angle, fade)
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
	# Plafonné : vers le joueur, la cible est grande à l'écran et l'impact la dépasserait de loin.
	var size := minf(_stage.target_rect.size.y * (_plan.impact_size if _plan.impact_size > 0.0
		else ART_IMPACT), IMPACT_MAX * _stage.view_size.y)
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
		# Une particule ne s'anime pas : elle tourne par à-coups (le crépitement des joues).
		var crackle := PI * 0.5 * i + _rand(floori(_t * FLIP_FPS * 0.5) + i) * TAU
		_show_flip(Flip.EXTRA_A + i, _plan.art[&"cheeks"], points[i], size, crackle, amount)


## Marque d'impact peinte du Contact (`stamp`) : surgit, se pose, s'efface ; les mâchoires se
## ferment, l'onde du coup de corps s'élargit. Faux sans art.
func _pose_stamp(k: float) -> bool:
	var stamp := _plan.art.get(&"stamp", &"") as StringName
	if stamp.is_empty():
		return false
	var rect := _stage.target_rect
	var base := ART_STAMP * minf(rect.size.x, rect.size.y) \
		* (_plan.impact_size if _plan.impact_size > 0.0 else 1.0)
	if _plan.impact == &"bec" or _plan.impact == &"vrille":
		_pose_beak(stamp, k, base)
		return true
	if _pose_stamp_rouge2(stamp, k, base):
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
			if _plan.impact_brick == &"toss" and _plan.lands() and _plan.target_shake:
				# Frappe Atlas : la secousse vient quand la cible touche le sol.
				var slam := phase.duration * TOSS_SLAM
				beat = phase.duration - slam
				since = elapsed - slam if elapsed >= slam else beat
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
	if _plan.world.has(&"storm"):
		# Fatal-Foudre : la scène s'assombrit avant que la foudre tombe, puis s'éclaire.
		match phase.name:
			MoveFxPlan.ANTICIPATION:
				darken = STORM_DARK * _ease_out(k)
			MoveFxPlan.TRAVEL:
				darken = STORM_DARK
			MoveFxPlan.IMPACT:
				darken = STORM_DARK * (1.0 - _ease_out(k))
	_light.set_light(_plan.light_color, amount, at, _stage.view_size.y)
	_light.set_darken(darken)
	_pose_screen(phase, k)


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


## Geste du lanceur : [décalage (px), échelle, lueur (0..1), opacité (0..1)]. Mimi-Queue
## (`tail_wag`) : il se dandine de côté (balancements amortis, léger écrasement à chaque bascule) ;
## poudres (`powder_shake`) : petits sauts rapides ; `rear_back` : il recule pendant l'anticipation
## et se détend au départ (Tunnel, tour 1 : il creuse). Vague 2 : [method _gesture_rouge2].
func _gesture(phase: MoveFxPlan.Phase, k: float) -> Array:
	var offset := Vector2.ZERO
	var scale_k := Vector2.ONE
	var dir := (_stage.target_rest - _stage.user_rest).normalized()
	var launch: String = _plan.bricks.get("launch", "")
	if not ["tail_wag", "powder_shake", "rear_back"].has(launch):
		return _gesture_rouge2(launch, phase, k)
	if phase.name == MoveFxPlan.CHARGE and _travel() == "underground":
		# Tunnel, tour 1 : il creuse (secousses rapides, il s'enfonce un peu).
		offset = Vector2(sin(TAU * 7.0 * k) * 5.0, 10.0 * _ease_in(k))
		return [offset, Vector2(1.0 + 0.04 * k, 1.0 - 0.06 * k), 0.0, 1.0]
	match launch:
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
	return [offset, scale_k, 0.0, 1.0]


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
## plante, un éclat violet marque la piqûre, puis elle s'efface. Vague 2 (Double-Dard, Dard-Nuée,
## Picanon) : une volée de [member MoveFxPlan.volley_count] aiguilles côte à côte, décalées de
## [member MoveFxPlan.volley_stagger] (part du trajet), à chaque coup.
func _pose_needle(phase: MoveFxPlan.Phase, k: float) -> void:
	var info := FxArt.particle(_plan.art.get(&"piece", &""))
	var height := _stage.view_size.y
	var from := _stage.origin()
	var to := _miss_point() if _missed(phase.hit) else _stage.impact_point()
	var dir := (to - from).normalized()
	var angle := dir.angle() - NEEDLE_POINT
	var size := Vector2.ONE * _plan.volley_size * height
	var count := clampi(_plan.volley_count, 1, THREAD_COUNT)
	var stagger := _plan.volley_stagger if count > 1 else 0.0
	var flight := maxf(1.0 - stagger * (count - 1), 0.1)
	for i: int in count:
		var side := dir.orthogonal() * (float(i) - (count - 1) * 0.5) * NEEDLE_SPACING * height
		var a := from + side * 0.4
		var b := to + side
		# Pièces : l'aiguille i en 3i, sa piqûre en 3i + 1, son halo en 3i + 2.
		match phase.name:
			MoveFxPlan.TRAVEL:
				var ki := clampf((k - stagger * i) / flight, 0.0, 1.0)
				if ki <= 0.0:
					continue
				var p := lerpf(ki, _ease_in(ki), 0.6)
				var at := a.lerp(b, p)
				var scale_k := lerpf(1.0, _depth_far(), p * 0.5)
				# Halo léger sous l'aiguille (fine, elle se perdrait sur le décor).
				_show_piece(3 * i + 2, {"texture": _dot, "additive": true}, at, size * scale_k * 0.6,
					0.0, 0.6 * minf(1.0, ki * 8.0), _color(1))
				_show_piece(3 * i, info, at, size * scale_k, angle, minf(1.0, ki * 8.0))
				var trail := _threads[i]
				trail.visible = ki > 0.05
				trail.points = PackedVector2Array([at - dir * size.x * NEEDLE_TRAIL * scale_k * ki, at])
				_color_line(trail, THREAD_WIDTH * 1.4, 0.75)
			MoveFxPlan.IMPACT:
				var ki := clampf(k * (1.0 + stagger * i * 2.0) - stagger * i * 2.0, 0.0, 1.0)
				_show_piece(3 * i, info, b, size * _depth_far(), angle, 1.0 - clampf(ki / 0.45, 0.0, 1.0))
				var flash := _ease_out(clampf(ki * 3.0, 0.0, 1.0))
				_show_piece(3 * i + 1, {"texture": _dot, "additive": true}, b, Vector2.ONE * STING_FLASH
					* height * lerpf(0.4, 1.0, flash), 0.0, 1.0 - clampf(ki / 0.5, 0.0, 1.0), _color(1))
			MoveFxPlan.MISS:
				var past := b + (b - a) * MISS_OVERSHOOT * k
				_show_piece(3 * i, info, past, size * _depth_far(), angle, 1.0 - k)


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
			if _plan != null and _plan.vanishes:
				# Téléport réussi : il est parti ; la scène le cache pour de bon (play_vanish).
				_stage.user.modulate.a = 0.0
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
	_screen.visible = false
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
	_screen = ColorRect.new()
	_screen.name = &"ScreenFlash"
	_screen.material = additive
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_screen)
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


# --- Vague 2 « Effets fidèles à Rouge » (2026-11-04) -----------------------------------------
# Chaque brique reprend le trajet et la forme de l'animation de Rouge (docs/tech/combat-vivant.md
# §3.2, familles 27 à 44), en couches (§2.9) : anticipation, cœur peint, lumière, particules,
# impact, retombée.

func _travel() -> String:
	return String(_plan.bricks.get("travel", "")) if _plan != null else ""


func _impact_brick() -> String:
	return String(_plan.bricks.get("impact", "")) if _plan != null else ""


## Pieds d'un Pokémon (bas de sa boîte, ramené dans la vue).
func _feet(rect: Rect2) -> Vector2:
	return Vector2(rect.get_center().x, minf(rect.end.y, _stage.view_size.y * 0.97))


## Repères en plus des briques : gouttes à chaque retombée de Trempette, poussière du pied
## d'Abîme, chute de la cible de Frappe Atlas.
func _schedule_extras(tween: Tween, plan: MoveFxPlan) -> void:
	var launch: String = plan.bricks.get("launch", "")
	var anticipation := plan.phase(MoveFxPlan.ANTICIPATION)
	if anticipation != null:
		if launch == "splash_hop":
			for i: int in HOPS:
				tween.tween_callback(_hop_splash).set_delay(anticipation.start
					+ anticipation.duration * (i + 1) / HOPS)
		elif launch == "stomp":
			tween.tween_callback(_stomp_dust).set_delay(anticipation.start
				+ anticipation.duration * 0.85)
	var strike := plan.phase(MoveFxPlan.IMPACT)
	if plan.impact_brick == &"toss" and strike != null and plan.target_shake:
		tween.tween_callback(_toss_landing).set_delay(strike.start + strike.duration * TOSS_SLAM)


func _hop_splash() -> void:
	if _plan == null:
		return
	_art_burst(&"particle", _feet(_stage.user_rect), _plan.particles, FxParticlePool.Shape.FALL,
		24.0, 0.09 * _stage.view_size.y, 0.5)


func _stomp_dust() -> void:
	if _plan == null:
		return
	_pool.burst(_feet(_stage.user_rect), roundi(_plan.particles / 2.0),
		PackedColorArray([Color("#E8DCC4"), Color("#A89478")]), FxParticlePool.Shape.RISE, 34.0,
		0.07 * _stage.view_size.y, 0.6, false, _art_texture(&"dust"))


func _toss_landing() -> void:
	if _plan == null or not _plan.lands():
		return
	var height := _stage.view_size.y
	var feet := _feet(_stage.target_rect)
	_pool.burst(feet, _plan.particles, PackedColorArray([Color("#E8DCC4"), Color("#A89478")]),
		FxParticlePool.Shape.RISE, 0.07 * height, 0.1 * height, 0.8, false, _art_texture(&"dust"))
	_pool.burst(feet, roundi(_plan.particles / 2.0), _plan.palette, FxParticlePool.Shape.BURST,
		30.0, 0.16 * height, 0.5, true)


## Tunnel, tour 1 : la terre gicle aux pieds du lanceur pendant qu'il creuse.
func _dig_spray(phase: MoveFxPlan.Phase) -> void:
	var height := _stage.view_size.y
	var feet := _feet(_stage.user_rect)
	_art_burst(&"particle", feet, _plan.particles, FxParticlePool.Shape.FALL, 0.045 * height,
		0.16 * height, phase.duration)
	_pool.burst(feet, roundi(_plan.particles / 2.0),
		PackedColorArray([Color("#E8DCC4"), Color("#A89478")]), FxParticlePool.Shape.RISE,
		0.06 * height, 0.08 * height, phase.duration * 1.2, false, _art_texture(&"dust"))


## Gestes de la vague 2 : [décalage, échelle, lueur, opacité]. Téléport (`teleport_out` : il se
## resserre en un trait et file vers le haut ; réussi, il ne revient pas), Trempette (`splash_hop` :
## deux sauts, écrasé à la réception, étiré en l'air), Explosion (`swell` : il gonfle, tremble et
## chauffe à blanc), Abîme (`stomp` : élan, puis il frappe le sol), Télékinésie (`spoon` : lueur
## douce, la cuiller fait le reste).
func _gesture_rouge2(launch: String, phase: MoveFxPlan.Phase, k: float) -> Array:
	var offset := Vector2.ZERO
	var scale_k := Vector2.ONE
	var glow := 0.0
	var alpha := 1.0
	var height := _stage.view_size.y
	match launch:
		"teleport_out":
			var gone := _stage.user_rect.end.y + 0.1 * height
			match phase.name:
				MoveFxPlan.ANTICIPATION:
					var e := _ease_out(k)
					glow = e
					scale_k = Vector2(1.0 - 0.25 * e, 1.0 + 0.08 * e)
					offset.y = -8.0 * e
					alpha = 1.0 - 0.3 * absf(sin(TAU * 3.0 * k)) * e
				MoveFxPlan.IMPACT:
					var thin := _ease_in(clampf(k / 0.35, 0.0, 1.0))
					var rise := _ease_in(clampf((k - 0.3) / 0.7, 0.0, 1.0))
					glow = 1.0
					scale_k = Vector2(lerpf(0.75, TELEPORT_THIN, thin), 1.08 + 0.6 * thin)
					offset.y = -8.0 - rise * gone
					alpha = 1.0 - 0.5 * rise
				MoveFxPlan.RETURN:
					if _plan.vanishes:
						return [Vector2(0.0, -gone), Vector2(TELEPORT_THIN, 1.68), 1.0, 0.0]
					var e := _ease_out(k)
					if _plan.phase(MoveFxPlan.IMPACT) != null:
						scale_k = Vector2(lerpf(TELEPORT_THIN, 1.0, e), lerpf(1.68, 1.0, e))
						offset.y = -(1.0 - e) * gone
					else:
						scale_k = Vector2(lerpf(0.75, 1.0, e), lerpf(1.08, 1.0, e))
						offset.y = -8.0 * (1.0 - e)
					glow = 1.0 - e
		"splash_hop":
			if phase.name == MoveFxPlan.ANTICIPATION:
				var hop := k * HOPS
				var i := mini(floori(hop), HOPS - 1)
				var h := hop - i
				var air := sin(PI * h)
				offset.y = -air * HOP_HEIGHT * height * (1.0 if i == 0 else 0.85)
				offset.x = sin(PI * hop) * 6.0
				var ground := 1.0 - clampf(minf(h, 1.0 - h) * 6.0, 0.0, 1.0)
				scale_k = Vector2(1.0 + 0.1 * ground - 0.05 * air, 1.0 - 0.12 * ground + 0.08 * air)
		"swell":
			if phase.name == MoveFxPlan.ANTICIPATION:
				var e := _ease_in(k)
				scale_k = Vector2.ONE * (1.0 + SWELL * e)
				offset.x = sin(TAU * 11.0 * k) * SWELL_TREMBLE * e
				glow = 0.0 if _plan.reduce_flashes else e
		"stomp":
			if phase.name == MoveFxPlan.ANTICIPATION:
				if k < 0.7:
					var r := _ease_out(k / 0.7)
					offset.y = -STOMP_RISE * r
					scale_k = Vector2(1.0 - 0.03 * r, 1.0 + 0.04 * r)
				else:
					var s := (k - 0.7) / 0.3
					offset.y = -STOMP_RISE * (1.0 - _ease_in(minf(s * 2.0, 1.0)))
					var squash := sin(PI * s)
					scale_k = Vector2(1.0 + 0.08 * squash, 1.0 - 0.1 * squash)
		"spoon":
			if phase.name == MoveFxPlan.ANTICIPATION:
				glow = 0.5 * sin(PI * k)
	return [offset, scale_k, glow, alpha]


## Effets de la vague 2 : le trajet de la famille, puis son impact quand il n'a pas de trajet.
func _pose_rouge2(phase: MoveFxPlan.Phase, k: float) -> void:
	match _travel():
		"rockfall":
			_pose_rocks()
		"smoke_ball":
			_pose_smoke(phase, k)
		"gas_drift":
			_pose_gas()
		"stars":
			_pose_stars()
		"sky_bolt":
			_pose_storm_sky(phase, k)
			_pose_sky_bolt(phase, k)
		"giant_orb":
			_pose_giant_orb(phase, k)
		"ground_pillar":
			_pose_ground_pillar(phase, k)
		"wave_sweep":
			_pose_wave(phase, k)
		"bone":
			_pose_bone(phase, k)
		"strange_orb":
			_pose_orb(phase, k)
		"lob":
			_pose_lob(phase, k)
		"underground":
			_pose_underground(phase, k)
	match _impact_brick():
		"explosions":
			_pose_blasts()
		"screen_flash":
			_pose_flash_glow(phase, k)
		"electric_cage", "fire_vortex":
			_pose_cage(phase, k)
		"sunshine", "rain":
			_pose_weather(phase, k)
		"field_haze":
			_pose_haze()
		"fissure_open":
			_pose_crack(phase, k)
		"beam_up":
			_pose_column(phase, k)
		"warp_aura":
			_pose_spoon(phase, k)


## Avancée [0, 1] d'une volée qui court du début du trajet à la fin du coup (-1 hors d'elle).
func _volley_span() -> float:
	var travel := _plan.phase(MoveFxPlan.TRAVEL)
	var strike := _strike()
	if travel == null or strike == null:
		return -1.0
	var u := (_t - travel.start) / maxf(strike.end() - travel.start, 0.001)
	return u if u > 0.0 and u <= 1.0 + MoveFxPlan.EPSILON else -1.0


# Jet-Pierres, Éboulement ------------------------------------------------------------------

## Pierre [param i] : où elle frappe (sur la cible, ou à côté si l'attaque rate).
func _rock_spot(i: int) -> Vector2:
	var rect := _stage.target_rect
	var center := _miss_point() if _missed(0) else _stage.impact_point()
	var count := maxi(1, _plan.volley_count)
	var spread := (float(i) - (count - 1) * 0.5) / maxf(count - 1.0, 1.0)
	return center + Vector2(spread * rect.size.x * 0.5, (_rand(i + 11) - 0.6) * rect.size.y * 0.4)


## Comme dans Rouge, les pierres tombent d'en haut : chacune tourne en tombant pendant que son
## ombre grandit au sol, frappe à son claquement de l'impact, rebondit et s'efface.
func _pose_rocks() -> void:
	var travel := _plan.phase(MoveFxPlan.TRAVEL)
	var strike := _strike()
	if travel == null or strike == null:
		return
	var info := FxArt.particle(_plan.art.get(&"piece", &""))
	var shadow := {"texture": _dot, "additive": false}
	var height := _stage.view_size.y
	var count := mini(_plan.volley_count, floori(VOLLEY_MAX * 0.5))
	var fall := travel.duration
	var ground_y := _stage.target_rect.end.y - _stage.target_rect.size.y * 0.06
	var bounce := maxf(strike.duration / count, 0.12)
	for i: int in count:
		var land := strike.start + strike.duration * i / count
		var spot := _rock_spot(i)
		var size := _plan.volley_size * height * lerpf(0.85, 1.2, _rand(i + 3))
		var since := _t - (land - fall)
		if since <= 0.0:
			continue
		var spin := 1.0 if i % 2 == 0 else -1.0
		var ground := Vector2(spot.x, ground_y)
		var flat := Vector2(1.0, 0.3) * size * ROCK_SHADOW
		if since < fall:
			var p := since / fall
			var at := spot + Vector2(-0.04 * height * (1.0 - p) * spin,
				-ROCK_DROP * height * (1.0 - p * p))
			_show_piece(count + i, shadow, ground, flat * lerpf(0.3, 1.0, p), 0.0, 0.35 * p,
				Color.BLACK)
			_show_piece(i, info, at, Vector2.ONE * size, (1.0 - p) * PI * spin, minf(1.0, p * 5.0))
			continue
		var b := (since - fall) / bounce
		if b >= 1.0:
			continue
		var landed := spot + Vector2(spin * 0.05 * height * b, -ROCK_BOUNCE * height * sin(PI * b))
		_show_piece(count + i, shadow, ground, flat, 0.0, 0.35 * (1.0 - b), Color.BLACK)
		_show_piece(i, info, landed, Vector2.ONE * size, spin * 0.6 * b, 1.0 - _ease_in(b))


## Éclats et poussière là où la pierre [param i] frappe.
func _rock_burst(i: int) -> void:
	if _plan == null:
		return
	var height := _stage.view_size.y
	var spot := _rock_spot(i)
	_art_burst(&"particle", spot, roundi(_plan.particles * 0.7), FxParticlePool.Shape.FALL, 30.0,
		0.12 * height, 0.6)
	_pool.burst(spot, roundi(_plan.particles / 2.0),
		PackedColorArray([Color("#E8DCC4"), Color("#A89478")]), FxParticlePool.Shape.RISE,
		0.06 * height, 0.06 * height, 0.7, false, _art_texture(&"dust"))


## Gravillons qui tombent avant les pierres (anticipation de la chute).
func _grit(phase: MoveFxPlan.Phase) -> void:
	var height := _stage.view_size.y
	var rect := _stage.target_rect
	var to := _miss_point() if _missed(phase.hit) else _stage.impact_point()
	var top := Vector2(to.x, rect.position.y - 0.2 * height)
	var fall := to.y - top.y
	top.y += fall * FxParticlePool.SIFT_COLUMN
	_pool.burst(top, roundi(ROCK_GRIT * _plan.particle_scale), _plan.palette,
		FxParticlePool.Shape.SIFT, 0.025 * height, fall, phase.duration * 1.2, false,
		_art_texture(&"grit"), Vector2.DOWN, rect.size.x * 0.4)


# Explosion, Destruction -------------------------------------------------------------------

func _blast_spot(i: int) -> Vector2:
	var rect := _stage.target_rect
	var center := _stage.impact_point()
	if i == 0:
		return center
	return center + Vector2((_rand(i + 5) - 0.5) * 2.0 * rect.size.x * BLAST_SPREAD.x,
		(_rand(i + 9) - 0.55) * 2.0 * rect.size.y * BLAST_SPREAD.y)


func _blast_burst(i: int) -> void:
	if _plan == null:
		return
	var height := _stage.view_size.y
	var at := _blast_spot(i)
	_art_burst(&"particle", at, roundi(_plan.particles * 0.6), FxParticlePool.Shape.BURST, 34.0,
		0.2 * height, 0.7)
	_art_burst(&"spark", at, 6, FxParticlePool.Shape.BURST, 0.08 * height, 0.05 * height, 0.3)


## Comme dans Rouge, des explosions éclatent l'une après l'autre sur le terrain adverse : une
## explosion peinte par claquement, jouée une fois ; elles se chevauchent, la dernière s'éteint
## pendant le retour.
func _pose_blasts() -> void:
	var strike := _strike()
	if strike == null:
		return
	var back := _plan.phase(MoveFxPlan.RETURN)
	var end := strike.end() + (back.duration if back != null else 0.0)
	var count := mini(_plan.volley_count, 5)
	var roles: Array[Flip] = [Flip.IMPACT, Flip.EXTRA_A, Flip.EXTRA_B, Flip.WAVE_A, Flip.WAVE_B]
	var id := _plan.art.get(&"blast", &"") as StringName
	var height := _stage.view_size.y
	for i: int in count:
		var start := strike.start + strike.duration * i / count
		var life := maxf(end - start, 0.2) if i == count - 1 else maxf(strike.duration * 0.75, 0.25)
		var once := (_t - start) / life
		if once < 0.0 or once > 1.0:
			continue
		var size := _plan.volley_size * height * lerpf(0.8, 1.15, _rand(i + 21))
		_show_flip(roles[i], id, _blast_spot(i), Vector2.ONE * size, _rand(i + 2) * TAU,
			1.0 - clampf((once - 0.8) / 0.2, 0.0, 1.0), false, once * BLAST_ONCE)


## Calque blanc plein écran (Flash : deux éclats comme dans Rouge ; Explosion et Fatal-Foudre : un
## éclat à l'impact). Son opacité suit la lumière du plan, déjà plafonnée par « Réduire les
## flashs » (0,35) et par le plafond de 3 flashs par seconde.
func _pose_screen(phase: MoveFxPlan.Phase, k: float) -> void:
	if phase.name != MoveFxPlan.IMPACT or _plan.flashes <= 0:
		return
	var amount := 0.0
	match _impact_brick():
		"screen_flash":
			amount = _plan.light_peak * absf(sin(PI * k * _plan.flashes)) * (1.0 - 0.3 * k)
		"explosions":
			amount = _plan.light_peak * 0.6 * maxf(0.0, 1.0 - k * 5.0)
		"orb_blast":
			amount = _plan.light_peak * 0.35 * maxf(0.0, 1.0 - k * 4.0)
		_:
			if _travel() == "sky_bolt":
				amount = _plan.light_peak * 0.5 * absf(sin(PI * k * _plan.flashes)) * (1.0 - k)
	if amount <= 0.0:
		return
	var view := _stage.view_size
	_screen.visible = true
	_screen.position = -view * SCREEN_MARGIN
	_screen.size = view * (1.0 + 2.0 * SCREEN_MARGIN)
	_screen.color = Color(_plan.light_color, amount)


## Calque plein écran (tests, galerie).
func get_screen() -> ColorRect:
	return _screen


# Brouillard, Gaz Toxik, Purédpois ---------------------------------------------------------

## Brouillard : une boule de fumée noire part en arc, suivie de bouffées qui grossissent ; sur la
## cible, elle s'ouvre en bouffées qui l'enveloppent (le nuage peint vient de l'art d'impact).
func _pose_smoke(phase: MoveFxPlan.Phase, k: float) -> void:
	var info := FxArt.particle(_plan.art.get(&"piece", &""))
	var height := _stage.view_size.y
	var from := _stage.origin()
	var to := _miss_point() if _missed(phase.hit) else _stage.impact_point()
	var size := _plan.volley_size * height
	match phase.name:
		MoveFxPlan.TRAVEL:
			for j: int in SMOKE_TRAIL + 1:
				var p := k - 0.07 * j
				if p <= 0.0:
					continue
				var at := from.lerp(to, p) + Vector2(0.0, -sin(PI * p) * SMOKE_ARC * height)
				var grow := lerpf(1.0, _depth_far(), p * 0.6) * (1.0 + 0.25 * j)
				var alpha := 1.0 if j == 0 else 0.55 * (1.0 - float(j) / (SMOKE_TRAIL + 1))
				_show_piece(j, info, at, Vector2.ONE * size * grow, _t * 1.5 + j, alpha)
		MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT, MoveFxPlan.RETURN:
			var strike := _strike()
			if strike == null or _t < strike.start:
				return
			var since := clampf((_t - strike.start) / maxf(_plan.duration - strike.start, 0.01), 0.0,
				1.0)
			var rect := _stage.target_rect
			for j: int in 4:
				var angle := TAU * j / 4.0 + 0.4
				var at := to + Vector2(cos(angle) * rect.size.x * 0.3, sin(angle) * rect.size.y
					* 0.25) * _ease_out(since)
				_show_piece(j, info, at, Vector2.ONE * size * lerpf(1.0, 2.6, _ease_out(since)),
					angle + _t, 0.9 * (1.0 - _ease_in(since)))


## Gaz : des bouffées partent l'une après l'autre, ondulent et gonflent en chemin, puis se fondent
## dans le nuage peint qui enveloppe la cible.
func _pose_gas() -> void:
	var u := _volley_span()
	if u < 0.0:
		return
	var info := FxArt.particle(_plan.art.get(&"piece", &""))
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
		var r := _rand(i + 40)
		var aim := to + Vector2((r - 0.5) * rect.size.x * 0.4, (_rand(i + 41) - 0.5) * rect.size.y * 0.3)
		var e := lerpf(p, _ease_out(p), 0.4)
		var at := from.lerp(aim, e) + normal * sin(TAU * (1.2 * p + r)) * _plan.volley_wobble * height
		var size := _plan.volley_size * height * lerpf(0.5, GAS_GROW, _ease_out(p)) \
			* lerpf(1.0, _depth_far(), p * 0.4)
		var alpha := minf(1.0, p * 4.0) * (1.0 - clampf((p - 0.8) / 0.2, 0.0, 1.0)) * 0.9
		_show_piece(i, info, at, Vector2.ONE * size, r * TAU + p * 1.2, alpha)


## Teinte de la cible sous la fumée (Brouillard) ou le gaz (Gaz Toxik, Purédpois).
func _target_veil(_phase: MoveFxPlan.Phase, tint: Color) -> Color:
	var brick := _impact_brick()
	if (brick != "smoke_cloud" and brick != "gas_cloud") or not _plan.lands():
		return tint
	var strike := _strike()
	if strike == null:
		return tint
	var u := clampf((_t - strike.start) / maxf(_plan.duration - strike.start, 0.001), 0.0, 1.0)
	var veil := sin(PI * u)
	if brick == "smoke_cloud":
		return tint.lerp(Color(tint * Color(0.45, 0.45, 0.5), tint.a), veil)
	return tint.lerp(Color(tint * _color(1).lerp(Color.WHITE, 0.4), tint.a), veil * 0.6)


# Météores, Fatal-Foudre, Onde Folie --------------------------------------------------------

static func _star_at(from: Vector2, aim: Vector2, normal: Vector2, q: float, bend: float,
		wobble: float, r: float) -> Vector2:
	return from.lerp(aim, q) + normal * (sin(PI * q) * bend + sin(TAU * (2.0 * q + r)) * wobble
		* (1.0 - q))


## Météores : les étoiles peintes à traînée partent l'une après l'autre en serpentant (une sur
## deux de chaque côté), chacune tournée dans son sens de vol ; elles éclatent en scintillement
## sur la cible.
func _pose_stars() -> void:
	var u := _volley_span()
	if u < 0.0:
		return
	var info := FxArt.particle(_plan.art.get(&"piece", &""))
	var spark := FxArt.particle(_plan.art.get(&"spark", &""))
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
		var r := _rand(i + 70)
		var aim := to + Vector2((r - 0.5) * rect.size.x * 0.35, (_rand(i + 71) - 0.5) * rect.size.y * 0.3)
		var bend := (1.0 if i % 2 == 0 else -1.0) * 0.08 * height * (1.0 + 0.5 * r)
		var wobble := _plan.volley_wobble * height
		var at := _star_at(from, aim, normal, p, bend, wobble, r)
		var ahead := _star_at(from, aim, normal, minf(p + 0.02, 1.0), bend, wobble, r)
		var pop := clampf((p - 0.88) / 0.12, 0.0, 1.0)
		var size := _plan.volley_size * height * lerpf(1.0, _depth_far(), p * 0.6)
		if ahead.distance_to(at) > 0.5:
			_show_piece(i, info, at, Vector2.ONE * size * 1.6, (ahead - at).angle(),
				minf(1.0, p * 6.0) * (1.0 - pop))
		if pop > 0.0:
			_show_piece(count + i, spark, aim, Vector2.ONE * size * lerpf(0.8, 2.2, pop), pop,
				sin(PI * pop))


## Fatal-Foudre : comme dans Rouge, la foudre tombe du ciel sur la cible ; elle descend du haut de
## l'écran au trajet, crépite à l'impact (un second éclair plus fin à côté) et s'éteint.
func _pose_sky_bolt(phase: MoveFxPlan.Phase, k: float) -> void:
	var id := _plan.art.get(&"bolt_sky", &"") as StringName
	var height := _stage.view_size.y
	var to := _miss_point() if _missed(phase.hit) else _stage.impact_point()
	var top := Vector2(to.x + 0.03 * height, -0.08 * height)
	var bottom := to + Vector2(0.0, 0.06 * height)
	var full := bottom.y - top.y
	var reveal := 0.0
	var alpha := 1.0
	match phase.name:
		MoveFxPlan.TRAVEL:
			reveal = _ease_in(k)
		MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
			reveal = 1.0
			alpha = (1.0 - 0.45 * absf(sin(TAU * 3.0 * k))) * (1.0 - _ease_in(k))
		_:
			return
	if reveal <= 0.0:
		return
	var length := full * reveal
	var center := Vector2(lerpf(top.x, bottom.x, reveal * 0.5), top.y + length * 0.5)
	_show_flip(Flip.TRAVEL, id, center, Vector2((_plan.bolt_height if _plan.bolt_height > 0.0
		else BOLT_SKY_WIDTH) * height, length), 0.0, alpha)
	if phase.name == MoveFxPlan.IMPACT:
		var twin := _plan.art.get(&"rise", &"") as StringName
		_show_flip(Flip.EXTRA_A, twin, Vector2(to.x - 0.13 * height, top.y + full * 0.42),
			Vector2(0.25 * height, full * 0.8), 0.0, alpha * absf(sin(TAU * 2.0 * k)))


## Courant peint du lanceur à la cible : le cœur (`bolt`) et, s'il y en a un, les filaments qui
## l'accompagnent (`bolt_twin`) ; il respire un peu en épaisseur.
func _show_bolt_art(bolt: StringName, from: Vector2, reach: float, angle: float, alpha: float) -> void:
	var thick := (_plan.bolt_height if _plan.bolt_height > 0.0 else ART_BOLT_HEIGHT) \
		* _stage.view_size.y * (1.0 + 0.06 * sin(_t * 40.0))
	_show_flip(Flip.TRAVEL, bolt, from, Vector2(reach, thick), angle, alpha, true)
	var twin := _plan.art.get(&"bolt_twin", &"") as StringName
	if not twin.is_empty():
		_show_flip(Flip.EXTRA_B, twin, from, Vector2(reach, thick * 1.5), angle, alpha * 0.7, true)


## Aura du lanceur (`aura` : Étincelle, Poing-Éclair, Tonnerre, Élecanon) : le crépitement suit son
## corps, de l'anticipation à l'impact, puis s'éteint au retour.
func _pose_aura(phase: MoveFxPlan.Phase, k: float) -> void:
	var id := _plan.art.get(&"aura", &"") as StringName
	if id.is_empty() or _stage.user == null:
		return
	var alpha := 0.9
	match phase.name:
		MoveFxPlan.ANTICIPATION, MoveFxPlan.CHARGE:
			alpha *= _ease_out(k)
		MoveFxPlan.RETURN:
			alpha *= 1.0 - k
	var center := _stage.user_rect.get_center() + _stage.user.position - _stage.user_rest
	_show_flip(Flip.AURA, id, center, _stage.user_rect.size * AURA_SIZE, 0.0, alpha)


## Traînée de foudre d'une charge (`trail`, Étincelle) : elle s'étire depuis l'arrière du départ
## jusqu'au lanceur qui fonce, puis s'éteint pendant l'impact.
func _pose_trail(phase: MoveFxPlan.Phase, k: float) -> void:
	var id := _plan.art.get(&"trail", &"") as StringName
	if id.is_empty() or _stage.user == null:
		return
	var alpha := 1.0
	match phase.name:
		MoveFxPlan.TRAVEL:
			alpha = minf(1.0, k * 4.0)
		MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
			alpha = 1.0 - _ease_out(k)
		_:
			return
	var height := _stage.view_size.y
	var dir := (_stage.target_rest - _stage.user_rest).normalized()
	var center := _stage.user_rect.get_center() + _stage.user.position - _stage.user_rest
	var tail := _stage.user_rect.get_center() - dir * TRAIL_BEHIND * height
	_show_flip(Flip.TRAIL, id, tail, Vector2(tail.distance_to(center), TRAIL_HEIGHT * height),
		(center - tail).angle(), alpha, true)


## Cage-Éclair : la cage de filaments se referme autour de la cible (aucun trait ne part du
## lanceur), crépite pendant l'impact et s'éteint au retour ; à côté si l'attaque rate.
func _pose_cage(phase: MoveFxPlan.Phase, k: float) -> void:
	var id := _plan.art.get(&"cage", &"") as StringName
	var rect := _stage.target_rect
	var at := rect.get_center()
	var base := maxf(rect.size.x, rect.size.y) * CAGE_SIZE
	match phase.name:
		MoveFxPlan.IMPACT:
			_show_flip(Flip.IMPACT, id, at, Vector2.ONE * base * lerpf(1.5, 1.0, _ease_out(minf(k * 3.0,
				1.0))), 0.0, minf(1.0, k * 6.0))
		MoveFxPlan.RETURN:
			if _plan.lands():
				_show_flip(Flip.IMPACT, id, at, Vector2.ONE * base, 0.0, 1.0 - _ease_in(k))
		MoveFxPlan.MISS:
			_show_flip(Flip.IMPACT, id, _miss_point(), Vector2.ONE * base, 0.0, 1.0 - k)
		MoveFxPlan.NO_EFFECT:
			_show_flip(Flip.IMPACT, id, at, Vector2.ONE * base * lerpf(1.0, 0.7, k), 0.0, 1.0 - k)


## Élecanon : une énorme sphère instable (`orb`) enfle devant le lanceur, reliée à lui par un arc
## (`tether`), part lourdement, tremble tout du long et s'ouvre sur la cible : l'explosion est
## l'art `impact`. Ratée (précision 50), elle file plus loin et s'éteint.
func _pose_giant_orb(phase: MoveFxPlan.Phase, k: float) -> void:
	var height := _stage.view_size.y
	var from := _stage.origin()
	var to := _stage.impact_point()
	var ahead := from + (to - from).normalized() * ORB_AHEAD * height
	var depth := ORB_DEPTH_FAR if _stage.user_is_player else 2.0 - ORB_DEPTH_FAR
	var at := ahead
	var size := ORB_SIZE * height
	var alpha := 1.0
	match phase.name:
		MoveFxPlan.ANTICIPATION, MoveFxPlan.CHARGE:
			size *= _ease_in_out(k)
		MoveFxPlan.TRAVEL:
			at = ahead.lerp(to, _ease_in_out(k))
			size *= lerpf(1.0, depth, k)
		MoveFxPlan.IMPACT:
			at = to
			size *= depth * lerpf(1.0, 1.35, _ease_out(minf(k * 4.0, 1.0)))
			alpha = 1.0 - minf(k * 4.0, 1.0)
		MoveFxPlan.MISS:
			at = _miss_point() + (_miss_point() - from) * MISS_OVERSHOOT * k
			size *= depth
			alpha = 1.0 - _ease_in(k)
		MoveFxPlan.NO_EFFECT:
			at = to
			size *= depth * lerpf(1.0, 0.3, k)
			alpha = 1.0 - k
		_:
			return
	if size <= 1.0 or alpha <= 0.0:
		return
	# Instable : elle se déforme et tressaute en permanence.
	var tremble := ORB_TREMBLE * height * Vector2(sin(_t * 71.0), cos(_t * 53.0))
	var wobble := Vector2(1.0 + 0.05 * sin(_t * 34.0), 1.0 - 0.05 * sin(_t * 34.0))
	# Le halo passe sous la sphère (Flip.SKY est dessiné en premier).
	_show_flip(Flip.SKY, _plan.art.get(&"halo", &""), at + tremble, Vector2.ONE * size * 2.1, 0.0,
		alpha * 0.3)
	_show_flip(Flip.TRAVEL, _plan.art.get(&"orb", &""), at + tremble, size * wobble, 0.0, alpha)
	_show_flip(Flip.EXTRA_A, _plan.art.get(&"ring", &""), at + tremble, Vector2.ONE * size * 1.25,
		_t * 3.0, alpha * 0.8)
	if phase.name == MoveFxPlan.ANTICIPATION or phase.name == MoveFxPlan.TRAVEL:
		_show_flip(Flip.WAVE_A, _plan.art.get(&"tether", &""), from, Vector2(from.distance_to(at),
			0.2 * height), (at - from).angle(), alpha * (1.0 - (k if phase.name == MoveFxPlan.TRAVEL
			else 0.0)), true)


## Plafond d'orage de Fatal-Foudre (`sky`) : les nuages arrivent pendant l'anticipation, au-dessus
## de la cible, et se dissipent à la fin de l'impact.
func _pose_storm_sky(phase: MoveFxPlan.Phase, k: float) -> void:
	var id := _plan.art.get(&"sky", &"") as StringName
	if id.is_empty():
		return
	var alpha := 1.0
	match phase.name:
		MoveFxPlan.ANTICIPATION, MoveFxPlan.CHARGE:
			alpha = _ease_out(k)
		MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
			alpha = 1.0 - clampf((k - 0.5) * 2.0, 0.0, 1.0)
		MoveFxPlan.RETURN:
			alpha = 0.0
	var view := _stage.view_size
	var at := Vector2(_stage.impact_point().x, SKY_SIZE.y * view.y * 0.5 - 0.08 * view.y)
	_show_flip(Flip.SKY, id, at, Vector2(SKY_SIZE.x * view.x, SKY_SIZE.y * view.y), 0.0, alpha)


## Feu Sacré : la colonne de flammes (`pillar`) jaillit du sol sous la cible pendant le trajet,
## brûle pendant l'impact puis s'éteint ; à côté de la cible si l'attaque rate.
func _pose_ground_pillar(phase: MoveFxPlan.Phase, k: float) -> void:
	var id := _plan.art.get(&"pillar", &"") as StringName
	var rect := _stage.target_rect
	var foot := _feet(rect)
	if _missed(phase.hit):
		foot.x = _miss_point().x
	var reveal := 1.0
	var alpha := 1.0
	match phase.name:
		MoveFxPlan.TRAVEL:
			reveal = _ease_out(k)
		MoveFxPlan.IMPACT:
			alpha = (1.0 - 0.12 * absf(sin(TAU * 4.0 * k))) * (1.0 - clampf((k - 0.55) / 0.45, 0.0, 1.0))
		MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
			alpha = 1.0 - _ease_in(k)
		_:
			return
	var full := minf(rect.size.y * PILLAR_HEIGHT, foot.y + 0.08 * _stage.view_size.y)
	var length := full * reveal
	if length <= 1.0 or alpha <= 0.0:
		return
	_show_flip(Flip.TRAVEL, id, foot + Vector2(0.0, -length * 0.5),
		Vector2(rect.size.y * PILLAR_WIDTH, length), 0.0, alpha)


## Météo sur tout le terrain (`sky`) : soleil de Zénith dans le coin haut droit, pluie de Danse
## Pluie sur tout l'écran. Elle arrive pendant l'anticipation, reste pendant l'impact et s'efface au
## retour ; rien ne part vers la cible.
func _pose_weather(phase: MoveFxPlan.Phase, k: float) -> void:
	var alpha := 1.0
	match phase.name:
		MoveFxPlan.ANTICIPATION, MoveFxPlan.CHARGE:
			alpha = _ease_out(k)
		MoveFxPlan.RETURN:
			alpha = 1.0 - _ease_in(k)
	var view := _stage.view_size
	if _impact_brick() == "rain":
		# Quatre tuiles d'un quart d'écran : étirée sur tout l'écran, la pluie ferait des traits énormes.
		var tile := view * 0.5
		for i: int in 4:
			_show_flip([Flip.SKY, Flip.WAVE_A, Flip.WAVE_B, Flip.WAVE_C][i], _plan.art.get(&"sky", &""),
				tile * Vector2(0.5 + i % 2, 0.5 + i / 2), tile, 0.0, alpha * RAIN_ALPHA)
		return
	# Carré (sans déformer les rayons), soleil dans le coin haut droit de l'écran.
	var side := SUN_SIZE * view.y
	_show_flip(Flip.SKY, _plan.art.get(&"sky", &""), Vector2(view.x - side * 0.5, side * 0.5 - 0.06 * view.y),
		Vector2.ONE * side, 0.0, alpha * SUN_ALPHA)


## Surf : une grande vague (`wave`) se lève derrière le lanceur, traverse le terrain, déferle sur
## la cible et la dépasse en s'effaçant ; tournée vers la gauche quand l'adversaire attaque.
func _pose_wave(phase: MoveFxPlan.Phase, k: float) -> void:
	var view := _stage.view_size
	var start := _feet(_stage.user_rect)
	var end := _feet(_stage.target_rect)
	if _missed(phase.hit):
		end.x = _miss_point().x
	var dir := signf(end.x - start.x)
	start.x -= dir * 0.5 * view.y
	end.x += dir * SURF_PAST * view.y
	var along := 0.0
	var rise := 1.0
	var alpha := 1.0
	match phase.name:
		MoveFxPlan.ANTICIPATION, MoveFxPlan.CHARGE:
			rise = _ease_out(k)
			alpha = minf(1.0, k * 3.0)
		MoveFxPlan.TRAVEL:
			along = _ease_in_out(k) * 0.85
		MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
			along = 0.85 + 0.15 * _ease_out(k)
			alpha = 1.0 - clampf((k - 0.4) / 0.6, 0.0, 1.0)
		_:
			return
	var foot := start.lerp(end, along)
	var height := SURF_HEIGHT * view.y * lerpf(1.0, _depth_far(), along * 0.5) * lerpf(0.3, 1.0, rise)
	_show_flip(Flip.TRAVEL, _plan.art.get(&"wave", &""), foot - Vector2(0.0, height * 0.42),
		Vector2(height * 1.25, height), 0.0 if dir >= 0.0 else PI, alpha)


## Bouclier, Protection, Mur Lumière, Voile Miroir (`wall`) : la paroi se dresse du sol devant le
## lanceur, côté adversaire, pendant l'anticipation, luit pendant l'impact et s'efface au retour.
func _pose_wall(phase: MoveFxPlan.Phase, k: float) -> void:
	var id := _plan.art.get(&"wall", &"") as StringName
	if id.is_empty() or _stage.user == null:
		return
	var rise := 1.0
	var alpha := 1.0
	match phase.name:
		MoveFxPlan.ANTICIPATION, MoveFxPlan.CHARGE:
			rise = _ease_out(k)
			alpha = minf(1.0, k * 3.0)
		MoveFxPlan.IMPACT:
			alpha = 1.0 - 0.1 * absf(sin(TAU * 2.0 * k))
		MoveFxPlan.RETURN:
			alpha = 1.0 - _ease_in(k)
		_:
			return
	var rect := _stage.user_rect
	var dir := signf(_stage.target_rest.x - _stage.user_rest.x)
	var size := WALL_SIZE * rect.size.y * Vector2(1.0, rise)
	var foot := _feet(rect) + Vector2(dir * WALL_AHEAD * rect.size.x, 0.0)
	_show_flip(Flip.TRAVEL, id, foot - Vector2(0.0, size.y * 0.5), size, 0.0, alpha)


## Prescience (`eye`) : un œil de lumière s'ouvre au-dessus du lanceur pendant l'anticipation et
## reste ouvert pendant que la colonne tombe, puis se ferme.
func _pose_eye(phase: MoveFxPlan.Phase, k: float) -> void:
	var id := _plan.art.get(&"eye", &"") as StringName
	if id.is_empty() or _stage.user == null:
		return
	var open := 1.0
	match phase.name:
		MoveFxPlan.ANTICIPATION, MoveFxPlan.CHARGE:
			open = _ease_out(k)
		MoveFxPlan.TRAVEL:
			pass
		MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
			open = 1.0 - _ease_in(k)
		_:
			return
	var rect := _stage.user_rect
	var side := EYE_SIZE * rect.size.y
	var at := Vector2(rect.get_center().x, maxf(rect.position.y - side * 0.2, side * 0.3))
	_show_flip(Flip.EXTRA_B, id, at, Vector2(side, side * lerpf(0.15, 1.0, open)), 0.0, open)


## Repos (`crown`) : les « Z » au-dessus de la tête du lanceur, de l'anticipation au retour.
func _pose_crown(phase: MoveFxPlan.Phase, k: float) -> void:
	var id := _plan.art.get(&"crown", &"") as StringName
	if id.is_empty() or _stage.user == null:
		return
	var alpha := 1.0
	match phase.name:
		MoveFxPlan.ANTICIPATION, MoveFxPlan.CHARGE:
			alpha = _ease_out(k)
		MoveFxPlan.RETURN:
			alpha = 1.0 - _ease_in(k)
		MoveFxPlan.TRAVEL, MoveFxPlan.IMPACT:
			pass
		_:
			return
	var rect := _stage.user_rect
	var side := CROWN_SIZE * rect.size.y
	var center := rect.get_center() + _stage.user.position - _stage.user_rest
	var at := Vector2(center.x, maxf(rect.position.y - side * 0.15, side * 0.4))
	_show_flip(Flip.EXTRA_A, id, at, Vector2.ONE * side, 0.0, alpha)


## Onde Folie : une sphère irisée (sa couleur tourne) flotte en ondulant jusqu'à la tête de la
## cible, puis tourne autour d'elle en rétrécissant, deux reflets derrière elle.
func _pose_orb(phase: MoveFxPlan.Phase, k: float) -> void:
	var info := FxArt.particle(_plan.art.get(&"piece", &""))
	var ring := FxArt.particle(_plan.art.get(&"ring", &""))
	var height := _stage.view_size.y
	var rect := _stage.target_rect
	var from := _stage.origin()
	var head := (_miss_point() if _missed(phase.hit) else rect.get_center()) \
		+ Vector2(0.0, -rect.size.y * 0.3)
	var size := _plan.volley_size * height * (1.0 + 0.12 * sin(TAU * 3.0 * _t))
	var tint := Color.from_hsv(fposmod(_t * 0.7, 1.0), 0.35, 1.0)
	var near := lerpf(1.0, _depth_far(), 0.5)
	var at := from
	var alpha := 1.0
	var scale_k := 1.0
	match phase.name:
		MoveFxPlan.ANTICIPATION:
			scale_k = _ease_out(k) * 0.7
		MoveFxPlan.TRAVEL:
			var normal := (head - from).orthogonal().normalized()
			at = from.lerp(head, _ease_in_out(k)) + normal * sin(TAU * 1.5 * k) * ORB_WAVE * height
			scale_k = lerpf(0.7, near, k)
		MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
			var turn := TAU * 1.5 * k
			var radius := ORB_ORBIT * rect.size.x * (1.0 - 0.6 * k)
			at = head + Vector2(cos(turn) * radius, sin(turn) * radius * 0.35)
			scale_k = near * (1.0 - 0.5 * k)
			alpha = 1.0 - _ease_in(k)
			for j: int in range(1, 3):
				var behind := turn - 0.45 * j
				var r := ORB_ORBIT * rect.size.x * (1.0 - 0.6 * maxf(k - 0.05 * j, 0.0))
				_show_piece(2 + j, info, head + Vector2(cos(behind) * r, sin(behind) * r * 0.35),
					Vector2.ONE * size * scale_k * (1.0 - 0.2 * j), 0.0, alpha * (0.45 - 0.15 * j), tint)
		_:
			return
	if scale_k <= 0.0:
		return
	_show_piece(0, info, at, Vector2.ONE * size * scale_k, 0.0, alpha, tint)
	_show_piece(1, ring, at, Vector2.ONE * size * scale_k * (1.5 + 0.25 * sin(TAU * 2.0 * _t)),
		_t * 2.0, alpha * 0.7, tint)


# Massd'Os, Osmerang, Bomb'Œuf, Pilonnage ---------------------------------------------------

static func _bezier(a: Vector2, c: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(c, t).lerp(c.lerp(b, t), t)


## Os : il tournoie en vol. Massd'Os (`massue`) : lancé haut, il s'abat sur la cible comme une
## massue ; Osmerang (`boomerang`) : il part en courbe, frappe, puis revient au lanceur par
## l'autre côté (à chaque coup).
func _pose_bone(phase: MoveFxPlan.Phase, k: float) -> void:
	var info := FxArt.particle(_plan.art.get(&"piece", &""))
	var height := _stage.view_size.y
	var from := _stage.origin()
	var to := _miss_point() if _missed(phase.hit) else _stage.impact_point()
	var size := Vector2.ONE * _plan.volley_size * height
	var far := lerpf(1.0, _depth_far(), 0.5)
	var boomerang := _plan.variant == &"boomerang"
	var bend := (to - from).orthogonal() * BOOMERANG_BEND
	if bend.y > 0.0:
		bend = -bend
	var above := to + Vector2(0.0, -0.2 * height)
	match phase.name:
		MoveFxPlan.TRAVEL:
			var at := _bezier(from, from.lerp(to, 0.5) + bend, to, _ease_in_out(k)) if boomerang \
				else from.lerp(above, k) + Vector2(0.0, -sin(PI * k) * BONE_ARC * height)
			_show_piece(0, info, at, size * lerpf(1.0, far, k), TAU * BONE_SPIN * k, minf(1.0, k * 6.0))
		MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
			var at := to
			var angle := TAU * BONE_SPIN * (1.0 + 0.6 * k)
			var struck := k
			if not boomerang:
				var down := _ease_in(clampf(k / 0.3, 0.0, 1.0))
				at = above.lerp(to, down)
				angle = TAU * BONE_SPIN - 1.1 * down
				struck = clampf((k - 0.25) / 0.75, 0.0, 1.0)
			else:
				at = to - (to - from).normalized() * 0.04 * height * sin(PI * clampf(k / 0.4, 0.0, 1.0))
			var alpha := 1.0 if boomerang else 1.0 - clampf((k - 0.6) / 0.4, 0.0, 1.0)
			_show_piece(0, info, at, size * far, angle, alpha)
			if phase.name == MoveFxPlan.IMPACT and (boomerang or k > 0.25):
				var star := FxArt.particle(_plan.art.get(&"star", &""))
				var pop := _ease_out(clampf(struck * 4.0, 0.0, 1.0))
				_show_piece(1, star, to, Vector2.ONE * 0.18 * height * lerpf(0.5, 1.1, pop), struck,
					1.0 - clampf((struck - 0.3) / 0.4, 0.0, 1.0))
		MoveFxPlan.RETURN:
			if not boomerang:
				return
			var at := _bezier(to, from.lerp(to, 0.5) - bend, from, _ease_in_out(k))
			_show_piece(0, info, at, size * lerpf(far, 1.0, k), TAU * BONE_SPIN * (1.6 + 1.5 * k),
				1.0 - clampf((k - 0.8) / 0.2, 0.0, 1.0))


## Bomb'Œuf, Pilonnage : l'objet part en cloche en tournant ; l'œuf explose (flipbook explosion),
## la boule rebondit vers l'arrière, une étoile marque le coup.
func _pose_lob(phase: MoveFxPlan.Phase, k: float) -> void:
	var info := FxArt.particle(_plan.art.get(&"piece", &""))
	var height := _stage.view_size.y
	var from := _stage.origin()
	var to := _miss_point() if _missed(phase.hit) else _stage.impact_point()
	var size := Vector2.ONE * _plan.volley_size * height
	var blast := _plan.art.get(&"blast", &"") as StringName
	match phase.name:
		MoveFxPlan.TRAVEL:
			var at := from.lerp(to, k) + Vector2(0.0, -sin(PI * k) * LOB_ARC * height)
			_show_piece(0, info, at, size * lerpf(1.0, _depth_far(), k), sin(TAU * 1.5 * k) * 0.6
				+ k * 2.0, minf(1.0, k * 6.0))
		MoveFxPlan.IMPACT:
			if not blast.is_empty():
				_show_flip(Flip.EXTRA_A, blast, to, Vector2.ONE * _stage.target_rect.size.y * 1.5, 0.0,
					1.0 - clampf((k - 0.8) / 0.2, 0.0, 1.0), false, k * BLAST_ONCE)
				return
			var away := to + (from - to).normalized() * 0.08 * height * _ease_out(k) \
				+ Vector2(0.0, -0.06 * height * sin(PI * k))
			_show_piece(0, info, away, size * _depth_far(), k * 3.0, 1.0 - _ease_in(k))
			var star := FxArt.particle(_plan.art.get(&"star", &""))
			var pop := _ease_out(clampf(k * 4.0, 0.0, 1.0))
			_show_piece(1, star, to, Vector2.ONE * 0.16 * height * lerpf(0.5, 1.1, pop), k,
				1.0 - clampf((k - 0.3) / 0.4, 0.0, 1.0))
		MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
			var past := to + (to - from) * MISS_OVERSHOOT * k + Vector2(0.0, 0.1 * height * k * k)
			_show_piece(0, info, past, size * _depth_far(), k * 3.0, 1.0 - k)


# Tunnel, Abîme, Frappe Atlas ---------------------------------------------------------------

## Tunnel, tour 2 : une traînée de mottes court sous le sol du lanceur à la cible, puis le sol
## éclate sous elle (rochers projetés, la cible est soulevée).
func _pose_underground(phase: MoveFxPlan.Phase, k: float) -> void:
	var info := FxArt.particle(_plan.art.get(&"piece", &""))
	var height := _stage.view_size.y
	var start := _feet(_stage.user_rect)
	var end := _feet(_stage.target_rect)
	if _missed(phase.hit):
		end.x = _miss_point().x
	var size := _plan.volley_size * height
	match phase.name:
		MoveFxPlan.TRAVEL:
			var count := mini(_plan.volley_count, 8)
			for i: int in count:
				var p := k - 0.07 * i
				if p <= 0.0 or p > 1.0:
					continue
				var at := start.lerp(end, p) + Vector2(0.0, -absf(sin(TAU * 3.0 * p + i))
					* BURROW_BUMP * height)
				_show_piece(i, info, at, Vector2.ONE * size * lerpf(1.0, _depth_far(), p)
					* (1.0 - 0.08 * i), _rand(i) * TAU + p * 4.0, 1.0 - float(i) / count * 0.6)
		MoveFxPlan.IMPACT:
			var rock := FxArt.particle(_plan.art.get(&"rock", &""))
			for i: int in 3:
				var angle := -PI * 0.5 + (i - 1) * 0.5
				var at := end + Vector2(cos(angle), sin(angle)) * 0.25 * height * _ease_out(k) \
					+ Vector2(0.0, 0.3 * height * k * k)
				_show_piece(i, rock, at, Vector2.ONE * 0.08 * height, k * 4.0 * (i - 1),
					1.0 - _ease_in(k))


## Abîme : la fissure peinte s'ouvre au sol sous la cible (une seule fois), puis s'efface au
## retour ; à côté de la cible si l'attaque rate.
func _pose_crack(phase: MoveFxPlan.Phase, k: float) -> void:
	var id := _plan.art.get(&"crack", &"") as StringName
	var strike := _strike()
	if strike == null or _t < strike.start:
		return
	var rect := _stage.target_rect
	var size := CRACK_WIDTH * rect.size.x
	var at := Vector2(rect.get_center().x, rect.end.y - size * 0.18)
	if _missed(0):
		at.x = _miss_point().x
	var once := clampf((_t - strike.start) / (strike.duration * 0.6), 0.0, 1.0) * BLAST_ONCE
	var alpha := 1.0 - _ease_in(k) if phase.name == MoveFxPlan.RETURN else 1.0
	_show_flip(Flip.IMPACT, id, at, Vector2.ONE * size, 0.0, alpha, false, once)


## Déplacement de la cible propre à la vague 2 pendant l'impact : elle s'enfonce dans la fissure
## (Abîme) ; le sol la soulève (Tunnel).
func _target_rouge2(phase: MoveFxPlan.Phase, elapsed: float) -> Vector2:
	if not _plan.lands() or _missed(phase.hit) or not _plan.target_shake:
		return Vector2.ZERO
	var k := clampf(elapsed / maxf(phase.duration, 0.001), 0.0, 1.0)
	var rect := _stage.target_rect
	match _impact_brick():
		"fissure_open":
			return Vector2(0.0, CRACK_SINK * rect.size.y * _ease_out(k)
				* (1.0 - _ease_in(clampf((k - 0.8) / 0.2, 0.0, 1.0))))
		"eruption":
			return Vector2(0.0, -ERUPT_LIFT * rect.size.y * sin(PI * minf(k * 1.6, 1.0)))
	return Vector2.ZERO


## Frappe Atlas : la cible monte en tournoyant (sa largeur bascule), reste un instant en l'air,
## retombe d'un coup ; arrêt sur image, écrasement et tremblement à la chute.
func _pose_toss(phase: MoveFxPlan.Phase, elapsed: float) -> void:
	var target := _stage.target
	var k := clampf(elapsed / maxf(phase.duration, 0.001), 0.0, 1.0)
	var offset := Vector2.ZERO
	var scale_k := Vector2.ONE
	var tint := _target_modulate
	if k < TOSS_SLAM:
		var r := k / TOSS_SLAM
		var lift := _ease_out(minf(r / 0.55, 1.0))
		if r > 0.75:
			lift *= 1.0 - _ease_in((r - 0.75) / 0.25)
		offset.y = -lift * TOSS_HEIGHT * _stage.view_size.y
		var turn := cos(TAU * r)
		scale_k = Vector2((1.0 if turn >= 0.0 else -1.0) * maxf(absf(turn), 0.15), 1.0)
	else:
		var since := (k - TOSS_SLAM) * phase.duration
		var stop := HIT_STOP * 1.5
		var rest := maxf(phase.duration * (1.0 - TOSS_SLAM) - stop, 0.001)
		var hit_k := 1.0 if since < stop else 1.0 - clampf((since - stop) / rest, 0.0, 1.0)
		if since >= stop:
			offset.x = sin(TAU * HIT_SHAKE_WAVES * (1.0 - hit_k)) * HIT_SHAKE * 1.5 * hit_k
		scale_k = Vector2(1.0 + HIT_SQUASH * 2.0 * hit_k, 1.0 - HIT_SQUASH * 2.0 * hit_k)
		var flash := HIT_DIM if _plan.reduce_flashes else HIT_BRIGHT
		tint = _target_modulate.lerp(_target_modulate * flash, hit_k * hit_k)
	target.position = _stage.target_rest + offset
	target.scale = _target_scale * scale_k
	target.modulate = tint


# Téléport, Flash, Télékinésie, Buée Noire --------------------------------------------------

## Téléport : une colonne de lumière monte des pieds du lanceur pendant qu'il file vers le haut ;
## elle redescend avec lui s'il revient.
func _pose_column(phase: MoveFxPlan.Phase, k: float) -> void:
	var id := _plan.art.get(&"column", &"") as StringName
	var height := _stage.view_size.y
	var base := _feet(_stage.user_rect)
	var amount := 0.0
	var reach := 0.0
	match phase.name:
		MoveFxPlan.ANTICIPATION:
			amount = 0.3 * _ease_in(k)
			reach = 0.3
		MoveFxPlan.IMPACT:
			amount = sin(PI * minf(k * 1.3, 1.0))
			reach = lerpf(0.3, 1.0, _ease_out(k))
		MoveFxPlan.RETURN:
			if _plan.vanishes:
				return
			amount = 0.6 * (1.0 - k)
			reach = 1.0
		_:
			return
	var length := TELEPORT_COLUMN.y * height * reach
	_show_flip(Flip.EXTRA_A, id, base + Vector2(0.0, -length * 0.5),
		Vector2(TELEPORT_COLUMN.x * height, length), 0.0, amount)


## Flash : une lueur naît sur le lanceur et grossit, puis s'ouvre sur tout l'écran à l'impact
## (le calque blanc fait l'éclair, [method _pose_screen]).
func _pose_flash_glow(phase: MoveFxPlan.Phase, k: float) -> void:
	var id := _plan.art.get(&"glow", &"") as StringName
	var height := _stage.view_size.y
	var at := _stage.origin()
	match phase.name:
		MoveFxPlan.ANTICIPATION:
			_show_flip(Flip.EXTRA_A, id, at, Vector2.ONE * height * lerpf(0.05, 0.3, _ease_in(k)), 0.0,
				_ease_out(k))
		MoveFxPlan.IMPACT:
			_show_flip(Flip.EXTRA_A, id, at, Vector2.ONE * height * lerpf(0.3, 1.6, _ease_out(k)), 0.0,
				(1.0 - _ease_in(k)) * (0.35 if _plan.reduce_flashes else 1.0))


## Télékinésie : la cuiller apparaît au-dessus du lanceur et se tord, des anneaux psy en partent ;
## à l'impact, une onde psy rejoint la cible (qui ondule) et la cuiller s'efface.
func _pose_spoon(phase: MoveFxPlan.Phase, k: float) -> void:
	var spoon := FxArt.particle(_plan.art.get(&"spoon", &""))
	var ring := FxArt.particle(_plan.art.get(&"ring", &""))
	var height := _stage.view_size.y
	var rect := _stage.user_rect
	var at := Vector2(rect.get_center().x, maxf(rect.position.y + rect.size.y * 0.1, 0.14 * height))
	var size := 0.3 * height
	match phase.name:
		MoveFxPlan.ANTICIPATION:
			var pop := _ease_out(clampf(k * 4.0, 0.0, 1.0))
			var bend := sin(TAU * 2.0 * k) * 0.35 * k
			_show_piece(0, spoon, at, Vector2(1.0 - 0.1 * absf(bend), 1.0) * size * pop, -0.3 + bend, pop)
			for j: int in 2:
				var w := fposmod(k * 2.0 + j * 0.5, 1.0)
				_show_piece(1 + j, ring, at, Vector2.ONE * size * lerpf(0.4, 1.6, w), 0.0, 0.8 * (1.0 - w))
		MoveFxPlan.IMPACT, MoveFxPlan.MISS, MoveFxPlan.NO_EFFECT:
			_show_piece(0, spoon, at, Vector2.ONE * size, -0.3, 1.0 - _ease_in(k))
			var to := _miss_point() if phase.name == MoveFxPlan.MISS else _stage.impact_point()
			_show_piece(1, ring, at.lerp(to, _ease_out(k)), Vector2.ONE * size * lerpf(0.6, 1.4, k), 0.0,
				1.0 - k)


## Buée Noire : des nappes de brume traversent tout le terrain à plusieurs hauteurs (une sur deux
## de chaque côté), couvrent les deux Pokémon, puis se dissipent.
func _pose_haze() -> void:
	var strike := _strike()
	if strike == null:
		return
	var u := (_t - strike.start) / maxf(_plan.duration - strike.start, 0.001)
	if u <= 0.0 or u >= 1.0:
		return
	var info := FxArt.particle(_plan.art.get(&"piece", &""))
	var view := _stage.view_size
	var count := mini(_plan.volley_count, 8)
	for i: int in count:
		var from_left := i % 2 == 0
		var p := clampf(u * 1.15 - 0.03 * i, 0.0, 1.0)
		var x := view.x * (-0.15 if from_left else 1.15) + (1.0 if from_left else -1.0) * HAZE_DRIFT \
			* view.x * _ease_out(p) + (_rand(i + 60) - 0.5) * view.x * 0.3
		var y := view.y * (0.22 + 0.15 * i)
		var size := _plan.volley_size * view.y * lerpf(1.0, 1.4, _rand(i + 61))
		_show_piece(i, info, Vector2(x, y), Vector2(1.6, 1.0) * size, 0.0, 0.85 * sin(PI * p))


# Marques au contact (Contact, Poings, Frappe Atlas) ----------------------------------------

## Marques de la vague 2 au contact : poing (Poings, l'élément éclate ensuite), langue
## (Léchouille), coquilles (Claquoir), pince (Pince-Masse), chute d'eau (Cascade), onde de la
## chute (Frappe Atlas). Faux pour les autres (marque commune).
func _pose_stamp_rouge2(stamp: StringName, k: float, base: float) -> bool:
	var rect := _stage.target_rect
	var c := rect.get_center()
	var height := _stage.view_size.y
	match String(_plan.impact_brick):
		"punch":
			var toward := (_stage.target_rest - _stage.user_rest).normalized()
			var pop := _ease_out(clampf(k * 4.0, 0.0, 1.0))
			_show_flip(Flip.IMPACT, stamp, c - toward * base * 0.35 * (1.0 - pop), Vector2.ONE * base
				* PUNCH_SIZE * lerpf(1.4, 0.9, pop), 0.0, 1.0 - clampf((k - 0.45) / 0.3, 0.0, 1.0))
			var burst := _plan.art.get(&"burst", &"") as StringName
			if not burst.is_empty() and k > 0.1:
				_show_flip(Flip.EXTRA_A, burst, c, Vector2.ONE * rect.size.y * ELEMENT_SIZE, 0.0,
					1.0 - clampf((k - 0.75) / 0.25, 0.0, 1.0), false, (k - 0.1) / 0.9)
		"lick":
			var sweep := _ease_in_out(clampf(k / 0.7, 0.0, 1.0))
			var grow := _ease_out(clampf(k * 3.0, 0.0, 1.0))
			var at := c + Vector2(lerpf(-0.22, 0.12, sweep) * rect.size.x,
				lerpf(0.28, -0.22, sweep) * rect.size.y)
			_show_flip(Flip.IMPACT, stamp, at, Vector2.ONE * LICK_SIZE * rect.size.x * lerpf(0.5, 1.0,
				grow), lerpf(-0.15, -0.7, sweep), 1.0 - clampf((k - 0.7) / 0.3, 0.0, 1.0))
		"shell_clamp":
			var close := _ease_in(clampf(k / 0.35, 0.0, 1.0))
			var gap := lerpf(0.6, 0.18, close) * rect.size.y
			var knock := sin(PI * clampf((k - 0.35) / 0.25, 0.0, 1.0)) * 0.04 * rect.size.y
			var size := Vector2.ONE * SHELL_SIZE * rect.size.x
			var alpha := 1.0 - clampf((k - 0.75) / 0.25, 0.0, 1.0)
			_show_flip(Flip.IMPACT, stamp, c - Vector2(0.0, gap * 0.5 - knock), size, 0.0, alpha)
			_show_flip(Flip.EXTRA_A, stamp, c + Vector2(0.0, gap * 0.5 - knock), size, 0.0, alpha)
			# La coquille du bas est la même, retournée.
			_flips[Flip.EXTRA_A].flip_v = true
		"pincer_smash":
			var swing := _ease_in(clampf(k / 0.3, 0.0, 1.0))
			var at := c + Vector2(-0.12 * rect.size.x, lerpf(-0.95, -0.1, swing) * rect.size.y)
			_show_flip(Flip.IMPACT, stamp, at, Vector2.ONE * PINCER_SIZE * rect.size.x * lerpf(1.2, 1.0,
				swing), lerpf(-0.9, 0.2, swing), minf(1.0, k * 8.0) * (1.0 - clampf((k - 0.7) / 0.3,
				0.0, 1.0)))
			_show_splash(c, k, 0.3)
		"waterfall":
			var top := Vector2(c.x, rect.position.y - 0.35 * height)
			var reveal := _ease_out(clampf(k / 0.3, 0.0, 1.0))
			var length := (c.y + rect.size.y * 0.15 - top.y) * reveal
			if length > 1.0:
				_show_flip(Flip.IMPACT, stamp, top + Vector2(0.0, length * 0.5), Vector2(CASCADE_SIZE.x
					* rect.size.x, length * CASCADE_SIZE.y), 0.0, 1.0 - clampf((k - 0.6) / 0.4, 0.0, 1.0))
			_show_splash(c, k, 0.25)
		"toss":
			var slam := clampf((k - TOSS_SLAM) / (1.0 - TOSS_SLAM), 0.0, 1.0)
			if slam > 0.0:
				_show_flip(Flip.IMPACT, stamp, _feet(rect), Vector2(1.6, 0.6) * base * lerpf(0.5, 1.8,
					_ease_out(slam)), 0.0, 1.0 - slam)
		_:
			return false
	return true


## Éclaboussure peinte (rôle `splash`) jouée une fois, à partir de [param from_k] de l'impact.
func _show_splash(at: Vector2, k: float, from_k: float) -> void:
	var id := _plan.art.get(&"splash", &"") as StringName
	if id.is_empty() or k < from_k:
		return
	var once := (k - from_k) / (1.0 - from_k)
	_show_flip(Flip.EXTRA_A, id, at, Vector2.ONE * _stage.target_rect.size.y * 2.1, 0.0,
		1.0 - clampf((once - 0.7) / 0.3, 0.0, 1.0), false, once)


## Éclats propres d'une variante d'impact de la vague 2 : pièces d'or qui jaillissent et
## retombent (Jackpot), salive (Léchouille), gouttes (Claquoir, Pince-Masse, Cascade).
func _impact_extra(at: Vector2, height: float, life: float) -> void:
	match String(_plan.impact_brick):
		"coin_burst":
			_pool.burst(at, roundi(COINS * _plan.particle_scale), _plan.palette,
				FxParticlePool.Shape.FALL, COIN_SIZE * height, 0.28 * height, 1.1, false,
				_art_texture(&"coin"))
			_pool.burst(at, roundi(10 * _plan.particle_scale), _plan.palette, FxParticlePool.Shape.BURST,
				0.05 * height, 0.18 * height, 0.6, true, _art_texture(&"glint"))
		"lick":
			_pool.burst(at, roundi(8 * _plan.particle_scale), _plan.palette, FxParticlePool.Shape.FALL,
				0.035 * height, 0.1 * height, life, false, _art_texture(&"drool"))
		"shell_clamp", "pincer_smash", "waterfall":
			_art_burst(&"particle", at, roundi(_plan.particles * 1.2), FxParticlePool.Shape.FALL, 26.0,
				0.16 * height, life)
