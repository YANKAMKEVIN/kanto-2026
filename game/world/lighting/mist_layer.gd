class_name MistLayer
extends Sprite2D
## Brume lente de la Tour Pokémon, 2F à 6F (docs/tech/jalon-19.md §2.10, dossier 22 §4.1 et §11).
## Un seul `Sprite2D` à la taille de la carte, au-dessus du sol et des parois, **sous les
## personnages** (z -1, avant `Entities`), dont le shader (`mist_scroll.gdshader`) décale deux
## lectures d'un bruit qui se répète. **Aucune `Light2D`, aucune particule, aucun `_process`** :
## le mouvement vient de `TIME` dans le shader. Alpha plafonné à [constant ALPHA_MAX].
## « Réduire les animations » : [method set_reduce_motion] la cache (modèle de
## `LightGlow.set_reduce_motion`), branchée dans `SettingsApplier` (T10).
## **Fusion avec le sol cuit** (J21, QA A17) : quand le sol peint de la carte est cuit
## ([method PaintedGround.is_baked]) et couvre exactement la même zone, c'est le sol qui dessine
## la brume dans sa propre passe ([method PaintedGround.refresh_mist]) et ce calque ne se dessine
## plus ([method is_merged]) ; il reste l'autorité (visibilité, porte de drapeaux, alpha,
## « Réduire les animations »). Chaque changement redemande la fusion au sol.

const SHADER: Shader = preload("res://game/world/lighting/shaders/mist_scroll.gdshader")
const TEXTURE_PATH: String = "res://assets/world/mist_noise_01.png"
const ALPHA_MAX: float = 0.2
## Au-dessus du sol peint et du voile (z -1, posé après lui dans l'arbre), sous `Entities` (0).
const Z_MIST: int = -1

static var _material: ShaderMaterial
static var _reduce_motion: bool = false
static var _instances: Array[MistLayer] = []

var _merged: bool = false

## Taille de la zone couverte (pixels du monde) : celle de la carte.
@export var area: Vector2i = Vector2i(1920, 1728):
	set(value):
		area = value
		if is_node_ready():
			_apply()
## Opacité maximale de la brume (plafonnée à [constant ALPHA_MAX]).
@export_range(0.0, 0.2) var alpha: float = 0.12:
	set(value):
		alpha = clampf(value, 0.0, ALPHA_MAX)
		self_modulate.a = alpha
		_refresh_ground()


func _init() -> void:
	z_index = Z_MIST
	z_as_relative = false
	centered = false
	region_enabled = true
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	set_process(false)
	set_physics_process(false)


func _ready() -> void:
	_instances.append(self)
	_apply()


func _exit_tree() -> void:
	_instances.erase(self)


func _notification(what: int) -> void:
	# Porte de drapeaux ou « Réduire les animations » : le sol cuit reprend (ou lâche) la brume.
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_refresh_ground()


## Cache (vrai) ou rend la brume sur toutes les cartes (« Réduire les animations »).
static func set_reduce_motion(enabled: bool) -> void:
	_reduce_motion = enabled
	for layer: MistLayer in _instances:
		layer.visible = not enabled


## Brumes présentes dans l'arbre.
static func get_instances() -> Array[MistLayer]:
	return _instances.duplicate()


static func is_reduce_motion() -> bool:
	return _reduce_motion


## Vrai si la brume est affichée (par ce calque ou, fusionnée, par le sol cuit).
func is_misting() -> bool:
	return visible and texture != null


## Vrai si la brume est dessinée par le sol cuit : ce calque ne se dessine plus.
func is_merged() -> bool:
	return _merged


## Fusion décidée par [method PaintedGround.refresh_mist] : le calque cesse (ou reprend) de se
## dessiner, sans toucher à [member CanvasItem.visible] (qui reste l'état logique).
func set_merged(merged: bool) -> void:
	_merged = merged
	RenderingServer.canvas_item_set_visible(get_canvas_item(), visible and not merged)


## Sol peint de la carte qui contient ce calque (null hors d'une carte).
func find_ground() -> PaintedGround:
	var node := get_parent()
	while node != null:
		if node is GameMap:
			return node.get_node_or_null(^"PaintedGround") as PaintedGround
		node = node.get_parent()
	return null


func _refresh_ground() -> void:
	if not is_inside_tree():
		return
	var ground := find_ground()
	if ground != null:
		ground.refresh_mist()
	elif _merged:
		set_merged(false)


func _apply() -> void:
	texture = load(TEXTURE_PATH) as Texture2D
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
		_material.set_shader_parameter(&"mist", texture)
	material = _material
	region_rect = Rect2(Vector2.ZERO, Vector2(area))
	self_modulate = Color(1, 1, 1, alpha)
	visible = not _reduce_motion
