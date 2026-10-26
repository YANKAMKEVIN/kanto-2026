class_name FxParticlePool
extends Node2D
## Réserve de particules des effets de combat (chantier Combat vivant, `docs/tech/combat-vivant.md`
## §2.7, §2.8) : [constant SIZE] émetteurs `CPUParticles2D` créés une fois (à l'entrée du combat),
## repris à tour de rôle ; aucun n'est créé pendant une attaque (pas d'à-coup au premier coup).
##
## Budget : ≤ [constant MAX_PER_EMITTER] particules par émetteur, ≤ [constant MAX_ON_SCREEN] à
## l'écran (un éclat qui dépasserait le budget est réduit). Graines fixes : le rendu est le même à
## chaque fois, et l'aléatoire du combat n'est pas touché.
## Texture : un point doux dessiné en code (échafaudage de CV.0, remplacé par l'atlas
## `assets/sprites/battle_fx/` au lot d'art, §3.4).

const SIZE: int = 12
const MAX_PER_EMITTER: int = 64
const MAX_ON_SCREEN: int = 200
const TEXTURE_SIZE: int = 64
const SEED_BASE: int = 2026

## Forme d'un éclat.
enum Shape {
	## Gerbe dans toutes les directions, freinée (impact).
	BURST,
	## Monte en flottant (soin, statut positif, braises).
	RISE,
	## Retombe (débris, gouttes, feuilles).
	FALL,
	## Aspirée vers le centre (anticipation).
	GATHER,
}

## Vitesse des particules (0 : figées ; elles ne partent pas).
var speed_scale: float = 1.0:
	set(value):
		speed_scale = value
		for emitter: CPUParticles2D in _emitters:
			emitter.speed_scale = maxf(value, 0.0)

var _emitters: Array[CPUParticles2D] = []
var _next: int = 0
var _texture: Texture2D
var _additive: CanvasItemMaterial
var _normal: CanvasItemMaterial
var _size_curve: Curve


func _ready() -> void:
	build()


## Crée les émetteurs (sans effet s'ils existent).
func build() -> void:
	if not _emitters.is_empty():
		return
	_texture = soft_dot(TEXTURE_SIZE)
	_additive = CanvasItemMaterial.new()
	_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_normal = CanvasItemMaterial.new()
	_size_curve = _grow_then_shrink()
	for i: int in SIZE:
		var emitter := CPUParticles2D.new()
		emitter.name = &"Emitter%d" % i
		emitter.emitting = false
		emitter.one_shot = true
		emitter.explosiveness = 0.9
		emitter.local_coords = false
		emitter.use_fixed_seed = true
		emitter.seed = SEED_BASE + i
		emitter.texture = _texture
		emitter.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		emitter.amount = MAX_PER_EMITTER
		add_child(emitter)
		_emitters.append(emitter)


## Lance un éclat de [param amount] particules en [param at] (px du calque) : forme
## [param shape], dégradé [param palette] (cœur → bord, fondu à la fin), taille [param size] (px),
## portée [param reach] (px), durée de vie [param lifetime] (s), matière (mélange normal, par
## défaut : lisible sur un décor de plein jour) ou lumière additive.
## Rend l'émetteur utilisé (null si [param amount] ≤ 0 ou si le budget est plein).
func burst(at: Vector2, amount: int, palette: PackedColorArray, shape: Shape = Shape.BURST,
		size: float = 28.0, reach: float = 160.0, lifetime: float = 0.5,
		additive: bool = false) -> CPUParticles2D:
	build()
	var count := mini(mini(amount, MAX_PER_EMITTER), MAX_ON_SCREEN - _busy_particles())
	if count <= 0:
		return null
	var emitter := _emitters[_next]
	_next = (_next + 1) % SIZE
	emitter.emitting = false
	emitter.amount = count
	emitter.lifetime = maxf(lifetime, 0.05)
	emitter.position = at
	emitter.material = _additive if additive else _normal
	emitter.color_ramp = ramp(palette)
	emitter.scale_amount_min = size / TEXTURE_SIZE * 0.6
	emitter.scale_amount_max = size / TEXTURE_SIZE
	emitter.scale_amount_curve = _size_curve
	_shape(emitter, shape, reach, lifetime)
	emitter.speed_scale = maxf(speed_scale, 0.0)
	if speed_scale > 0.0:
		emitter.restart()
	return emitter


## Arrête tout et efface les particules encore en vie (fin d'attaque, sortie du combat) :
## `restart` vide l'émetteur, qui est coupé avant d'en émettre de nouvelles.
func clear() -> void:
	for emitter: CPUParticles2D in _emitters:
		emitter.restart()
		emitter.emitting = false


## Particules des éclats en cours (au plus le total des émetteurs actifs).
func active_particles() -> int:
	return _busy_particles()


func get_emitters() -> Array[CPUParticles2D]:
	return _emitters


## Dégradé de couleur d'une particule : la palette dans l'ordre, puis un fondu.
static func ramp(palette: PackedColorArray) -> Gradient:
	var gradient := Gradient.new()
	var colors := palette if not palette.is_empty() else PackedColorArray([Color.WHITE])
	var offsets := PackedFloat32Array()
	var stops := PackedColorArray()
	for i: int in colors.size():
		offsets.append(0.75 * i / maxf(colors.size() - 1, 1.0))
		stops.append(colors[i])
	offsets.append(1.0)
	stops.append(Color(colors[colors.size() - 1], 0.0))
	gradient.offsets = offsets
	gradient.colors = stops
	return gradient


## Point doux (disque à bord flou) de [param size] px, blanc, pour la teinte des particules.
static func soft_dot(size: int) -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = size
	texture.height = size
	return texture


func _busy_particles() -> int:
	var count := 0
	for emitter: CPUParticles2D in _emitters:
		if emitter.emitting:
			count += emitter.amount
	return count


func _shape(emitter: CPUParticles2D, shape: Shape, reach: float, lifetime: float) -> void:
	var speed := reach / maxf(lifetime, 0.05)
	emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	emitter.emission_sphere_radius = reach * 0.08
	emitter.spread = 180.0
	emitter.direction = Vector2.UP
	emitter.gravity = Vector2.ZERO
	emitter.damping_min = 0.0
	emitter.damping_max = 0.0
	emitter.radial_accel_min = 0.0
	emitter.radial_accel_max = 0.0
	emitter.angle_min = 0.0
	emitter.angle_max = 360.0
	match shape:
		Shape.BURST:
			emitter.initial_velocity_min = speed * 1.2
			emitter.initial_velocity_max = speed * 2.0
			emitter.damping_min = speed * 2.0
			emitter.damping_max = speed * 3.0
		Shape.RISE:
			emitter.spread = 25.0
			emitter.emission_sphere_radius = reach * 0.35
			emitter.initial_velocity_min = speed * 0.4
			emitter.initial_velocity_max = speed * 0.9
		Shape.FALL:
			emitter.spread = 70.0
			emitter.initial_velocity_min = speed * 0.6
			emitter.initial_velocity_max = speed * 1.2
			emitter.gravity = Vector2(0.0, speed * 4.0)
		Shape.GATHER:
			emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_RING
			emitter.emission_ring_radius = reach
			emitter.emission_ring_inner_radius = reach * 0.7
			emitter.initial_velocity_min = 0.0
			emitter.initial_velocity_max = 0.0
			emitter.radial_accel_min = -speed * 3.0
			emitter.radial_accel_max = -speed * 2.0
	emitter.explosiveness = 0.3 if shape == Shape.RISE else 0.9


## Taille au cours de la vie : la particule gonfle vite, puis rapetisse.
static func _grow_then_shrink() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.6))
	curve.add_point(Vector2(0.15, 1.0))
	curve.add_point(Vector2(1.0, 0.2))
	return curve
