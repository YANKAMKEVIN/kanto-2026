class_name FxWorldLight
extends Node2D
## Lumière simulée du lieu pendant une attaque (chantier Combat vivant, CV-6,
## `docs/tech/combat-vivant.md` §2.7, couche 7 du §2.9) : une grande lueur radiale additive posée
## sur le décor, et une teinte brève des calques du décor peint. **Pas de `Light2D`, pas de passe
## qui recopie l'écran** (l'A17 n'a pas la marge) ; l'étalonnage de `WorldLighting` n'est pas
## touché : la teinte part du `modulate` de repos des calques et y revient.
##
## [method set_light] : intensité de 0 (éteint) à 1 ; le plafond « Réduire les flashs » (0,35) est
## déjà dans [member MoveFxPlan.light_peak].

## Rayon de la lueur, en hauteurs d'écran [D].
const GLOW_RADIUS: float = 0.55
## Part de l'intensité qui teinte le décor (la lueur porte le reste) [D].
const DECOR_TINT: float = 0.45
## Assombrissement maximal du décor (famille Spectre, `darken`) [D].
const DARKEN: float = 0.45
const GLOW_TEXTURE_SIZE: int = 256

var _glow: Sprite2D
var _decor: Array[Sprite2D] = []
var _rest: Dictionary[Sprite2D, Color] = {}
var _amount: float = 0.0
var _color: Color = Color.WHITE
var _darken: float = 0.0


func _ready() -> void:
	_build()


## Calques du décor peint à teinter (les null sont ignorés) ; leur `modulate` actuel est le repos.
func set_decor(layers: Array[Sprite2D]) -> void:
	restore()
	_decor.clear()
	_rest.clear()
	for layer: Sprite2D in layers:
		if layer != null:
			_decor.append(layer)
			_rest[layer] = layer.modulate


## Lumière de couleur [param color] et d'intensité [param amount] (0..1), centrée en [param at]
## (px du calque) pour une vue de hauteur [param view_height].
func set_light(color: Color, amount: float, at: Vector2, view_height: float) -> void:
	_build()
	_amount = clampf(amount, 0.0, 1.0)
	_color = color
	_glow.visible = _amount > 0.0
	_glow.position = at
	var radius := GLOW_RADIUS * view_height
	_glow.scale = Vector2.ONE * (radius * 2.0 / GLOW_TEXTURE_SIZE)
	_glow.modulate = Color(color, _amount)
	_tint()


## Assombrit le décor de [param amount] (0..1 ; famille Spectre).
func set_darken(amount: float) -> void:
	_darken = clampf(amount, 0.0, 1.0)
	_tint()


## Éteint et rend aux calques leur teinte de repos.
func restore() -> void:
	_amount = 0.0
	_darken = 0.0
	if _glow != null:
		_glow.visible = false
	for layer: Sprite2D in _decor:
		if is_instance_valid(layer):
			layer.modulate = _rest[layer]


func get_amount() -> float:
	return _amount


func is_lit() -> bool:
	return _amount > 0.0 or _darken > 0.0


func _tint() -> void:
	for layer: Sprite2D in _decor:
		if not is_instance_valid(layer):
			continue
		var rest: Color = _rest[layer]
		var lit := rest.lerp(Color(rest * Color(_color, 1.0) * 1.6, rest.a), _amount * DECOR_TINT)
		layer.modulate = lit.lerp(Color(rest * (1.0 - DARKEN), rest.a), _darken)


func _build() -> void:
	if _glow != null:
		return
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = GLOW_TEXTURE_SIZE
	texture.height = GLOW_TEXTURE_SIZE
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow = Sprite2D.new()
	_glow.name = &"Glow"
	_glow.texture = texture
	_glow.material = material
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_glow.visible = false
	add_child(_glow)
