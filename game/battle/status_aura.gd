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
##  - poison : rien de permanent (le voile de fin de tour existe déjà) ;
##  - confusion : petites étoiles au-dessus de la tête au moment du test
##    ([method play_confusion]).
## « Réduire les animations » ([member reduce_motion]) coupe les particules et les étoiles, garde
## la teinte du gel. Les motifs sont fixes (aucun tirage : l'aléatoire du jeu n'est pas touché).
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

## Coupe les particules et les étoiles (« Réduire les animations ») ; la teinte du gel reste.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		queue_redraw()
## Vitesse des effets (0 : figés ; [method play_confusion] rend la main tout de suite).
var speed_scale: float = 1.0

var _sprite: Sprite2D
var _box: Rect2 = Rect2()
var _status: StringName = StatusRules.NONE
var _time: float = 0.0
## Temps restant des étoiles de confusion (s) ; 0 = aucune.
var _stars: float = 0.0
var _ice: Sprite2D
var _ice_material: ShaderMaterial


## Branche le nœud sur le sprite qu'il suit.
func setup(sprite: Sprite2D) -> void:
	_sprite = sprite
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
	queue_redraw()


func get_status() -> StringName:
	return _status


## Vrai si la teinte du gel est posée (tests, captures).
func is_ice_shown() -> bool:
	return _ice != null and _ice.visible


## Vrai si des étoiles de confusion tournent (tests, captures).
func is_confusion_shown() -> bool:
	return _stars > 0.0


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
