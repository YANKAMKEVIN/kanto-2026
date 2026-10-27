class_name StatusAura
extends Node2D
## Effets d'un statut sur un Pokémon de la scène de combat (jalon 11, T7 ; dossier 14 §3.3).
##
## Un nœud par camp, posé par [BattleStage] juste **au-dessus** de son sprite : il ne touche ni
## au sprite ni à son matériau (l'artwork officiel garde son matériau étalonné, leçon du J9 ×
## CB.1). Aucune image nouvelle : tout est dessiné ([method _draw]) ou copié du sprite.
##  - paralysie : petites décharges jaunes, de temps en temps ;
##  - brûlure : braises qui montent, par intermittence ;
##  - sommeil : « z » qui s'envolent au-dessus de la tête ;
##  - gel : teinte bleu glacé figée (copie du sprite teintée, posée dessus) ;
##  - poison : bulles violettes qui montent et éclatent, par intermittence (CV.3) ; Toxik
##    ([constant StatusRules.TOXIC]) : plus denses et plus foncées ;
##  - gel : en plus, quelques éclats de givre qui scintillent (CV.3) ;
##  - sommeil : en plus, respiration lente du sprite (CV.3, voir ci-dessous) ;
##  - pose du statut : petit effet de 0,3 s aux couleurs du statut (CV.3) ;
##  - confusion : petites étoiles au-dessus de la tête au moment du test
##    ([method play_confusion]).
## « Réduire les animations » ([member reduce_motion]) coupe les particules et les étoiles, garde
## la teinte du gel. Les motifs sont fixes (aucun tirage : l'aléatoire du jeu n'est pas touché).
## Respiration (CV.3, CV-8) : 1 % sur 3 s au repos, 2 % sur 2,4 s pendant le sommeil, sur
## l'échelle verticale, pieds fixes, décalée entre les deux camps. Le nœud ne possède pas le
## sprite : il pose son décalage sur l'échelle et la position du sprite et le défait à l'image
## suivante ; si la scène a changé l'un des deux entre-temps (bond, K.O., retrait), son
## nouveau réglage devient la base. Elle reste avec « Réduire les animations » (lente, sans
## risque) et se fige à vitesse 0. Aucune image nouvelle, aucun tirage.
## Le nœud suit le sprite à chaque image (bonds, coups, K.O. : position, échelle, opacité).
## Valeurs visuelles par défaut (règle 4), réglables ici ; provisoires jusqu'à la phase DA.

const ICE_SHADER: Shader = preload("res://game/battle/status_ice.gdshader")
const SPARK_COLOR := Color("#F7D02C")
const EMBER_COLOR := Color("#FF8A3C")
const EMBER_CORE := Color("#FFF1B0")
const EMBER_EDGE := Color("#8A1E0A")
const SLEEP_COLOR := Color(1.0, 1.0, 1.0, 0.9)
const ICE_TINT := Color("#5FB8F0")
const ICE_AMOUNT: float = 0.7
const STAR_COLOR := Color("#FFE680")
const POISON_COLOR := Color("#B05CE0")
const POISON_CORE := Color("#E8C4FF")
const TOXIC_COLOR := Color("#7A2FB0")
const TOXIC_CORE := Color("#C58BEA")
const FROST_COLOR := Color("#E6F7FF")
## Couleurs de la pose du statut (CV.3).
const APPLY_COLORS: Dictionary[StringName, Color] = {
	StatusRules.POISON: Color("#B05CE0"), StatusRules.TOXIC: Color("#7A2FB0"),
	StatusRules.PARALYSIS: Color("#F7D02C"), StatusRules.BURN: Color("#FF8A3C"),
	StatusRules.SLEEP: Color("#9FB8E8"), StatusRules.FREEZE: Color("#5FB8F0"),
}
## Paralysie : une salve toutes les SPARK_PERIOD s, visible SPARK_ON s.
const SPARK_PERIOD: float = 1.6
const SPARK_ON: float = 0.28
const SPARK_WIDTH: float = 7.0
## Brûlure : braises (nombre, période d'une montée, rayon max en px écran).
const EMBER_COUNT: int = 5
const EMBER_PERIOD: float = 1.4
## Rayon d'une braise : part de la hauteur du Pokémon, bornée (px écran).
const EMBER_RADIUS: float = 0.06
const EMBER_RADIUS_MIN: float = 12.0
const EMBER_RADIUS_MAX: float = 30.0
const EMBER_RISE: float = 0.55
## Sommeil : trois « z » décalés, période d'une montée, tailles de police.
const SLEEP_PERIOD: float = 2.4
const SLEEP_FONT_MIN: int = 40
const SLEEP_FONT_MAX: int = 72
## Confusion : trois étoiles qui tournent au-dessus de la tête, durée (s, à vitesse 1).
const STAR_COUNT: int = 3
const STAR_DURATION: float = 0.8
const STAR_RADIUS: float = 20.0
## Poison : bulles (poison / Toxik), période d'une montée, rayon max (px écran).
const BUBBLE_COUNT: int = 4
const BUBBLE_COUNT_TOXIC: int = 7
const BUBBLE_PERIOD: float = 1.8
const BUBBLE_RADIUS: float = 0.05
const BUBBLE_RADIUS_MIN: float = 10.0
const BUBBLE_RADIUS_MAX: float = 26.0
const BUBBLE_RISE: float = 0.6
## Gel : éclats de givre qui scintillent (nombre, période d'un scintillement).
const FROST_COUNT: int = 6
const FROST_PERIOD: float = 1.3
## Pose du statut : durée (s, à vitesse 1).
const APPLY_DURATION: float = 0.3
## Respiration : amplitude (part de l'échelle verticale) et période (s), au repos puis endormi.
const BREATH_IDLE_AMOUNT: float = 0.01
const BREATH_IDLE_PERIOD: float = 3.0
const BREATH_SLEEP_AMOUNT: float = 0.02
const BREATH_SLEEP_PERIOD: float = 2.4

## Coupe les particules et les étoiles (« Réduire les animations ») ; la teinte du gel reste.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		queue_redraw()
## Vitesse des effets (0 : figés ; [method play_confusion] rend la main tout de suite).
var speed_scale: float = 1.0
## Active la respiration (désactivable par les tests de géométrie).
var breath_enabled: bool = true
## Décalage de la respiration (0..1 de période) ; [method setup] met 0,5 au camp adverse
## (nœud ou sprite nommé « Foe… » par la scène), 0 sinon.
var breath_phase: float = 0.0

var _sprite: Sprite2D
var _box: Rect2 = Rect2()
var _status: StringName = StatusRules.NONE
var _time: float = 0.0
## Temps restant des étoiles de confusion (s) ; 0 = aucune.
var _stars: float = 0.0
var _ice: Sprite2D
var _ice_material: ShaderMaterial
## Temps de la pose du statut restant (s) ; 0 = aucune.
var _apply: float = 0.0
var _apply_status: StringName = StatusRules.NONE
## Respiration : horloge propre (ne revient pas à 0 avec le statut), et ce que le nœud a posé
## sur le sprite à l'image précédente.
var _breath_time: float = 0.0
var _breath_on: bool = false
var _breath_base_scale: Vector2 = Vector2.ONE
var _breath_base_pos: Vector2 = Vector2.ZERO
var _breath_set_scale: Vector2 = Vector2.ONE
var _breath_set_pos: Vector2 = Vector2.ZERO


## Branche le nœud sur le sprite qu'il suit.
func setup(sprite: Sprite2D) -> void:
	_sprite = sprite
	if String(name).begins_with("Foe") or String(sprite.name).begins_with("Foe"):
		breath_phase = 0.5
	if _ice == null:
		_ice = Sprite2D.new()
		_ice.name = &"Ice"
		_ice_material = ShaderMaterial.new()
		_ice_material.shader = ICE_SHADER
		_ice_material.set_shader_parameter(&"tint", ICE_TINT)
		_ice_material.set_shader_parameter(&"amount", ICE_AMOUNT)
		_ice.material = _ice_material
		_ice.visible = false
		add_child(_ice)


## Boîte visible de l'image du sprite (px de la texture, comme [method BattleStage._box]).
func set_box(box: Rect2) -> void:
	_box = box


## Statut affiché ([constant StatusRules.NONE] : aucun effet).
func set_status(status: StringName) -> void:
	if status == _status:
		return
	_status = status
	_time = 0.0
	_apply = 0.0
	if status != StatusRules.NONE and not reduce_motion and speed_scale > 0.0 \
			and _sprite != null and _sprite.visible:
		_apply = APPLY_DURATION
		_apply_status = status
	queue_redraw()


func get_status() -> StringName:
	return _status


## Vrai si la teinte du gel est posée (tests, captures).
func is_ice_shown() -> bool:
	return _ice != null and _ice.visible


## Vrai si des étoiles de confusion tournent (tests, captures).
func is_confusion_shown() -> bool:
	return _stars > 0.0


## Vrai si la pose du statut (0,3 s) est en cours (tests, captures).
func is_apply_shown() -> bool:
	return _apply > 0.0


## Part d'échelle verticale ajoutée par la respiration à l'instant [param time] (s), pour
## [param status] (sommeil : plus lente et plus forte), avec un décalage [param phase] (0..1).
## 0 au départ, puis monte et redescend en douceur ; jamais négatif.
static func breath_amount(status: StringName, time: float, phase: float = 0.0) -> float:
	var asleep := status == StatusRules.SLEEP
	var amount := BREATH_SLEEP_AMOUNT if asleep else BREATH_IDLE_AMOUNT
	var period := BREATH_SLEEP_PERIOD if asleep else BREATH_IDLE_PERIOD
	return amount * 0.5 * (1.0 - cos(TAU * (time / period + phase)))


## Rectangle écran suivi (boîte visible du sprite à sa place courante).
func get_target_rect() -> Rect2:
	if _sprite == null:
		return Rect2()
	var scale := _sprite.scale
	return Rect2(_sprite.position + (_box.position + _sprite.offset) * scale,
		_box.size * scale.abs())


## Coroutine : étoiles de confusion au-dessus de la tête ([constant STAR_DURATION]) ; rien
## avec [member reduce_motion] ou à vitesse 0.
func play_confusion() -> void:
	if reduce_motion or speed_scale <= 0.0:
		return
	_stars = STAR_DURATION
	queue_redraw()
	while _stars > 0.0 and is_inside_tree():
		await get_tree().process_frame


## Fige l'effet à l'instant [param time] (s depuis la pose du statut ; captures, tests).
func set_time(time: float) -> void:
	_time = time
	queue_redraw()


func _process(delta: float) -> void:
	if _sprite == null:
		return
	var shown := _sprite.visible and is_instance_valid(_sprite)
	modulate.a = _sprite.modulate.a
	_sync_ice(shown)
	_update_breath(shown, delta)
	if _apply > 0.0:
		_apply = maxf(_apply - delta * maxf(speed_scale, 0.0), 0.0) if shown else 0.0
	if not shown or (_status == StatusRules.NONE and _stars <= 0.0):
		if _stars > 0.0:
			_stars = 0.0
		queue_redraw()
		return
	var step := delta * maxf(speed_scale, 0.0)
	_time += step
	if _stars > 0.0:
		_stars = maxf(_stars - step, 0.0)
	queue_redraw()


func _exit_tree() -> void:
	_release_breath()


## Défait le décalage posé à l'image précédente (si personne d'autre n'a touché au sprite depuis),
## puis pose celui de l'instant.
func _update_breath(shown: bool, delta: float) -> void:
	_release_breath()
	_breath_time += delta * maxf(speed_scale, 0.0)
	if not breath_enabled or not shown or _box.size.y <= 0.0:
		return
	var amount := breath_amount(_status, _breath_time, breath_phase)
	if amount <= 0.00001:
		return
	_breath_base_scale = _sprite.scale
	_breath_base_pos = _sprite.position
	var stretched := Vector2(_sprite.scale.x, _sprite.scale.y * (1.0 + amount))
	# Pieds fixes : le bas de la boîte visible ne bouge pas à l'écran.
	var feet := _box.end.y + _sprite.offset.y
	_sprite.scale = stretched
	_sprite.position = Vector2(_breath_base_pos.x,
		_breath_base_pos.y - feet * (stretched.y - _breath_base_scale.y))
	_breath_set_scale = _sprite.scale
	_breath_set_pos = _sprite.position
	_breath_on = true


func _release_breath() -> void:
	if not _breath_on:
		return
	_breath_on = false
	if _sprite == null or not is_instance_valid(_sprite):
		return
	if _sprite.scale == _breath_set_scale and _sprite.position == _breath_set_pos:
		_sprite.scale = _breath_base_scale
		_sprite.position = _breath_base_pos


func _sync_ice(shown: bool) -> void:
	if _ice == null:
		return
	_ice.visible = shown and _status == StatusRules.FREEZE
	if not _ice.visible:
		return
	_ice.texture = _sprite.texture
	_ice.centered = _sprite.centered
	_ice.offset = _sprite.offset
	_ice.flip_h = _sprite.flip_h
	_ice.position = _sprite.position
	_ice.scale = _sprite.scale
	_ice.texture_filter = _sprite.texture_filter


func _draw() -> void:
	if _sprite == null or not _sprite.visible:
		return
	var rect := get_target_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	if not reduce_motion:
		match _status:
			StatusRules.PARALYSIS:
				_draw_sparks(rect)
			StatusRules.BURN:
				_draw_embers(rect)
			StatusRules.SLEEP:
				_draw_sleep(rect)
			StatusRules.POISON:
				_draw_bubbles(rect, false)
			StatusRules.TOXIC:
				_draw_bubbles(rect, true)
			StatusRules.FREEZE:
				_draw_frost(rect)
		if _apply > 0.0:
			_draw_apply(rect)
	if _stars > 0.0:
		_draw_stars(rect)


## Deux éclairs en zigzag de part et d'autre du corps, pendant SPARK_ON s toutes les
## SPARK_PERIOD s ; la salve change de côté à chaque fois.
func _draw_sparks(rect: Rect2) -> void:
	var cycle := fmod(_time, SPARK_PERIOD)
	if cycle > SPARK_ON:
		return
	var alpha := 1.0 - cycle / SPARK_ON
	var flip := int(_time / SPARK_PERIOD) % 2 == 1
	var size := clampf(rect.size.y * 0.3, 40.0, 140.0)
	for i: int in 2:
		var x := rect.position.x + rect.size.x * (0.15 if (i == 0) != flip else 0.85)
		var y := rect.position.y + rect.size.y * (0.3 + 0.25 * i)
		var points := PackedVector2Array([
			Vector2(x, y), Vector2(x + size * 0.35, y + size * 0.3),
			Vector2(x - size * 0.1, y + size * 0.55), Vector2(x + size * 0.3, y + size)])
		var color := SPARK_COLOR
		color.a = alpha
		draw_polyline(points, color, SPARK_WIDTH, true)


## Braises qui montent du bas du corps et s'éteignent ; trois sur cinq visibles à la fois.
func _draw_embers(rect: Rect2) -> void:
	for i: int in EMBER_COUNT:
		var phase := fmod(_time / EMBER_PERIOD + float(i) / EMBER_COUNT, 1.0)
		if phase > 0.6:
			continue
		var k := phase / 0.6
		var x := rect.position.x + rect.size.x * (0.05 + 0.9 * fmod(float(i) * 0.37, 1.0)) \
			+ sin(k * TAU + i) * 6.0
		var y := rect.end.y - rect.size.y * (0.1 + EMBER_RISE * k)
		var radius := clampf(rect.size.y * EMBER_RADIUS, EMBER_RADIUS_MIN, EMBER_RADIUS_MAX) \
			* (1.0 - 0.6 * k)
		var edge := EMBER_EDGE
		edge.a = 1.0 - k
		draw_circle(Vector2(x, y), radius + 3.0, edge)
		var color := EMBER_COLOR
		color.a = 1.0 - k
		draw_circle(Vector2(x, y), radius, color)
		var core := EMBER_CORE
		core.a = color.a
		draw_circle(Vector2(x, y), radius * 0.45, core)


## Trois « z » qui partent du haut de la tête vers le haut à droite, grossissent et s'effacent.
func _draw_sleep(rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	var origin := Vector2(rect.get_center().x + rect.size.x * 0.15, rect.position.y)
	for i: int in 3:
		var phase := fmod(_time / SLEEP_PERIOD + float(i) / 3.0, 1.0)
		var size := int(lerpf(SLEEP_FONT_MIN, SLEEP_FONT_MAX, phase))
		var position := origin + Vector2(60.0 * phase, -110.0 * phase)
		var color := SLEEP_COLOR
		color.a *= sin(phase * PI)
		draw_string(font, position, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## Bulles qui montent du bas du corps, grossissent, puis éclatent (anneau qui s'ouvre) ; sept
## dixièmes du cycle de montée, le reste de pause, d'où l'intermittence. Toxik : plus nombreuses,
## plus foncées.
func _draw_bubbles(rect: Rect2, toxic: bool) -> void:
	var count := BUBBLE_COUNT_TOXIC if toxic else BUBBLE_COUNT
	var body := TOXIC_COLOR if toxic else POISON_COLOR
	var core := TOXIC_CORE if toxic else POISON_CORE
	var max_radius := clampf(rect.size.y * BUBBLE_RADIUS, BUBBLE_RADIUS_MIN, BUBBLE_RADIUS_MAX)
	for i: int in count:
		var phase := fmod(_time / BUBBLE_PERIOD + float(i) / count, 1.0)
		if phase > 0.7:
			continue
		var k := phase / 0.7
		var x := rect.position.x + rect.size.x * (0.1 + 0.8 * fmod(float(i) * 0.61, 1.0)) \
			+ sin(k * TAU * 1.5 + i) * 7.0
		var y := rect.end.y - rect.size.y * (0.08 + BUBBLE_RISE * k)
		var center := Vector2(x, y)
		if k < 0.82:
			var radius := max_radius * (0.35 + 0.65 * k / 0.82)
			var fill := body
			fill.a = 0.55 if toxic else 0.42
			draw_circle(center, radius, fill)
			var rim := core
			rim.a = 0.85
			draw_arc(center, radius, 0.0, TAU, 20, rim, 3.0, true)
			draw_circle(center + Vector2(-radius, -radius) * 0.35, radius * 0.2,
				Color(1, 1, 1, 0.7))
		else:
			var pop := (k - 0.82) / 0.18
			var ring := core
			ring.a = 1.0 - pop
			draw_arc(center, max_radius * (1.0 + 0.5 * pop), 0.0, TAU, 20, ring, 3.0, true)


## Éclats de givre posés sur le corps, qui scintillent chacun à son tour (étoile à quatre
## branches dont la taille et l'opacité suivent un pic).
func _draw_frost(rect: Rect2) -> void:
	var reach := clampf(rect.size.y * 0.1, 16.0, 40.0)
	for i: int in FROST_COUNT:
		var phase := fmod(_time / FROST_PERIOD + float(i) * 0.37, 1.0)
		var peak := pow(maxf(sin(phase * PI), 0.0), 3.0)
		if peak <= 0.02:
			continue
		var x := rect.position.x + rect.size.x * (0.15 + 0.7 * fmod(float(i) * 0.43 + 0.1, 1.0))
		var y := rect.position.y + rect.size.y * (0.12 + 0.76 * fmod(float(i) * 0.29 + 0.2, 1.0))
		var color := FROST_COLOR
		color.a = peak
		var r := reach * (0.4 + 0.6 * peak)
		var c := Vector2(x, y)
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(0, -r), c + Vector2(r * 0.18, -r * 0.18), c + Vector2(r, 0),
			c + Vector2(r * 0.18, r * 0.18), c + Vector2(0, r), c + Vector2(-r * 0.18, r * 0.18),
			c + Vector2(-r, 0), c + Vector2(-r * 0.18, -r * 0.18)]), color)


## Pose du statut : halo qui s'ouvre autour du corps et s'efface, aux couleurs du statut.
func _draw_apply(rect: Rect2) -> void:
	var t := 1.0 - _apply / APPLY_DURATION
	var base: Color = APPLY_COLORS.get(_apply_status, Color.WHITE)
	var center := rect.get_center()
	var radius := maxf(rect.size.x, rect.size.y) * (0.35 + 0.35 * t)
	var halo := base
	halo.a = 0.35 * (1.0 - t)
	draw_circle(center, radius, halo)
	var ring := base.lightened(0.4)
	ring.a = 1.0 - t
	draw_arc(center, radius, 0.0, TAU, 40, ring, 6.0 * (1.0 - t) + 1.0, true)


## Étoiles qui tournent sur une ellipse au-dessus de la tête.
func _draw_stars(rect: Rect2) -> void:
	var center := Vector2(rect.get_center().x, rect.position.y - 10.0)
	var radius := Vector2(clampf(rect.size.x * 0.35, 30.0, 110.0), 14.0)
	var progress := 1.0 - _stars / STAR_DURATION
	var alpha := sin(progress * PI)
	for i: int in STAR_COUNT:
		var angle := progress * TAU + TAU * i / STAR_COUNT
		var point := center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		var color := STAR_COLOR
		color.a = alpha
		draw_colored_polygon(_star(point, STAR_RADIUS), color)


static func _star(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in 10:
		var r := radius if i % 2 == 0 else radius * 0.45
		var angle := -PI / 2.0 + PI * i / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	return points
