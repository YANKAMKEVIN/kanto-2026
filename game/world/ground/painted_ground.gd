class_name PaintedGround
extends Node2D
## Sol peint d'une carte (docs/tech/jalon-07.md §6.6) : un seul rectangle de la taille de la
## carte, dessiné par `ground_blend` (herbe, pavés, chemin mélangés par [member mask]). Le sol
## ne se lit plus en tuiles : le `TileMapLayer` `Ground` reste dans la carte, **invisible**,
## comme source logique (solide, herbes hautes, rebords).
## Dessiné sous les ombres et les décalcomanies ([constant WorldLighting.Z_GROUND]).
## **Rivage** (DA.2) : [member shore_mask] (facultatif, [method GroundMask.build_shore]) ajoute
## le sable puis la mer par-dessus, avec une frange d'écume et une eau qui ondule doucement
## (`proto/da_jadielle/sol_bourg.gdshader`). Sans lui, ni sable ni eau (textures non chargées).
## **Textures réglables** (jalon 12 T7) : [member base_texture] (fond), [member r_texture] (canal
## rouge du masque), [member g_texture] (canal vert) ; nulles = herbe, pavés, chemin (défauts de
## toutes les cartes peintes jusqu'au J11, qui n'enregistrent aucune de ces propriétés). La Route 3
## y met le sol rocheux, le Mont Sélénite ses trois sols (`tools/cave_map_kit.gd`). Toutes les
## textures d'un même sol ont la même taille (uniform `texture_size` du shader).
## **Eau réglable** (jalon 13 T6, docs/tech/jalon-13.md §2.3) : [member water_texture] (nulle =
## la mer de Bourg Palette), [member foam_strength] (écume, défaut = la mer), [member square_shore]
## (canaux à angles droits : l'eau couvre exactement ses cases ; les quais sont posés par-dessus,
## `tools/cerulean_map_kit.gd`). Aux défauts, rien n'est réglé dans le matériau : les cartes
## d'avant le J13 n'enregistrent aucune de ces propriétés et se dessinent au pixel près pareil.
## **Cuisson** (J21, QA A17 : le shader de sol coûtait ≈ 9 i/s sur un Mali-G57 à la Tour) : un
## sol **sans rivage** ne dépend pas du temps ; en jeu ([method _ready], hors headless), il est
## rendu **une fois** dans un `SubViewport` (mêmes coordonnées du monde, même matériau : mêmes
## pixels), puis affiché comme une simple texture ([method is_baked]). Jusqu'à cette image, le
## rectangle du shader reste dessiné (aucune image vide). Le rivage (eau qui ondule) et les
## sols plus grands que [constant BAKE_MAX_PIXELS] ne sont pas cuits. Les nœuds de la cuisson
## n'ont pas de propriétaire : jamais enregistrés dans la scène de la carte.
## **Cuisson par morceaux** (moteur commun, QA A17 : Routes 11, 12, 16 à 23-27 i/s) : un sol que
## [method bake] refuse (rivage, ou trop grand) est cuit par morceaux de la taille de la vue
## ([method bake_chunks], [GroundChunks]) : la terre (sable compris) et le sous-bois
## ([ForestFloor]) une fois, l'eau animée seule redessinée à chaque image et seulement sur les
## cases d'eau ([GroundWater]). Les deux cuissons emportent le sous-bois d'une carte extérieure
## ([method stack_layers]).

const SHADER: Shader = preload("res://game/world/lighting/shaders/ground_blend.gdshader")
## Sol cuit, qui porte aussi la brume de la Tour ([method refresh_mist]).
const BAKED_SHADER: Shader = preload(
	"res://game/world/lighting/shaders/baked_ground_mist.gdshader")
const GRASS_TEXTURE: String = "res://assets/world/ground/ground_herbe_01.png"
const PAVING_TEXTURE: String = "res://assets/world/ground/ground_paves_01.png"
const PATH_TEXTURE: String = "res://assets/world/ground/ground_chemin_01.png"
const SAND_TEXTURE: String = "res://assets/world/ground/ground_sable_01.png"
const WATER_TEXTURE: String = "res://assets/world/ground/ground_eau_01.png"
## Force de l'écume par défaut (celle de la mer de Bourg Palette ; défaut de l'uniform
## `foam_strength` du shader).
const DEFAULT_FOAM_STRENGTH: float = 0.8
## Passe « terre » du shader du sol (tout sauf l'eau), cuite par [method bake_chunks].
const PASS_LAND: int = 1
## Plus grand sol cuit, en pixels du monde (≈ 16 Mo de mémoire vidéo en RGBA8) ; au-delà, le
## shader dessine le sol à chaque image. Côté maximal : [constant BAKE_MAX_SIDE].
const BAKE_MAX_PIXELS: int = 2048 * 2048
const BAKE_MAX_SIDE: int = 4096

## Cuisson automatique en jeu (faux sous GUT ou dans un outil qui veut le shader vivant).
static var auto_bake: bool = true

## Classes (sans script) qu'une couche cuite peut contenir.
const _STATIC_CLASSES: Array[String] = ["Node2D", "Sprite2D", "Polygon2D"]

var _bake_viewport: SubViewport
var _baked_sprite: Sprite2D
var _baked: bool = false
var _baked_layers: Array[CanvasItem] = []
var _chunks: GroundChunks
var _water: GroundWater

## Taille en cases (celle de la carte).
@export var size: Vector2i = Vector2i(16, 16):
	set(value):
		size = value
		queue_redraw()
## Masque de la carte ([GroundMask] : R pavés, G chemin), 1 pixel = 1 case.
@export var mask: Texture2D:
	set(value):
		mask = value
		_update_material()
## Masque du rivage ([method GroundMask.build_shore] : R sable, G eau), 1 pixel = 1 case ;
## nul = pas de rivage.
@export var shore_mask: Texture2D:
	set(value):
		shore_mask = value
		_update_material()
## Texture du fond (là où le masque est noir) ; nulle = herbe ([constant GRASS_TEXTURE]).
@export var base_texture: Texture2D:
	set(value):
		base_texture = value
		_update_textures()
## Texture du canal rouge du masque ; nulle = pavés ([constant PAVING_TEXTURE]).
@export var r_texture: Texture2D:
	set(value):
		r_texture = value
		_update_textures()
## Texture du canal vert du masque ; nulle = chemin ([constant PATH_TEXTURE]).
@export var g_texture: Texture2D:
	set(value):
		g_texture = value
		_update_textures()
## Texture de l'eau du rivage (dessinée à sa propre échelle) ; nulle = mer
## ([constant WATER_TEXTURE]). Sans [member shore_mask], sans effet.
@export var water_texture: Texture2D:
	set(value):
		water_texture = value
		_update_material()
## Force de l'écume au bord de l'eau (0 = aucune : quais des canaux).
@export_range(0.0, 1.0, 0.05) var foam_strength: float = DEFAULT_FOAM_STRENGTH:
	set(value):
		foam_strength = value
		_update_material()
## Rivage à angles droits : l'eau couvre exactement les cases d'eau du masque, sans bruit ni
## frange (canaux ; faux = rivage naturel de la mer).
@export var square_shore: bool = false:
	set(value):
		square_shore = value
		_update_material()


func _init() -> void:
	z_index = WorldLighting.Z_GROUND
	_update_material()


func _ready() -> void:
	if auto_bake and DisplayServer.get_name() != "headless":
		if can_bake():
			bake()
		elif can_bake_chunks():
			bake_chunks()


func _draw() -> void:
	if not _baked and _chunks == null:
		draw_rect(Rect2(Vector2.ZERO, Vector2(size * Grid.TILE_SIZE)), Color.WHITE)


## Vrai si le sol peut être cuit : sans rivage (rien n'y dépend du temps), avec un matériau, et
## pas plus grand que [constant BAKE_MAX_PIXELS] / [constant BAKE_MAX_SIDE].
func can_bake() -> bool:
	return bake_allowed(size, shore_mask != null) and get_shader_material() != null


## Règle pure de [method can_bake] (taille en cases, rivage).
static func bake_allowed(cells: Vector2i, has_shore: bool) -> bool:
	var pixels := cells * Grid.TILE_SIZE
	return not has_shore and pixels.x > 0 and pixels.y > 0 and pixels.x <= BAKE_MAX_SIDE \
		and pixels.y <= BAKE_MAX_SIDE and pixels.x * pixels.y <= BAKE_MAX_PIXELS


## Rend le sol une fois dans un `SubViewport`, puis l'affiche comme une texture (à l'image
## suivante). Sans effet si déjà demandé, hors de l'arbre ou si [method can_bake] est faux.
## Les couches immobiles posées juste au-dessus ([method stack_layers] : rebords, escaliers,
## ombrage et lumière de sol des grottes) sont cuites avec lui, dans leur ordre, puis cachées.
func bake() -> void:
	if _bake_viewport != null or not is_inside_tree() or not can_bake():
		return
	var pixels := size * Grid.TILE_SIZE
	_bake_viewport = SubViewport.new()
	_bake_viewport.name = "GroundBake"
	_bake_viewport.size = pixels
	_bake_viewport.disable_3d = true
	_bake_viewport.transparent_bg = false
	_bake_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_bake_viewport)
	# Mêmes coordonnées du monde que le sol vivant (le shader lit MODEL_MATRIX) : la carte
	# est recopiée à sa place, la vue ramène l'origine du sol en (0, 0).
	_bake_viewport.canvas_transform = global_transform.affine_inverse()
	var parent_node := get_parent() as Node2D
	var stage := Node2D.new()
	stage.transform = parent_node.global_transform if parent_node != null else Transform2D()
	var source := BakeSource.new()
	source.rect = Rect2(Vector2.ZERO, Vector2(pixels))
	source.material = material
	source.transform = transform
	source.z_index = z_index
	stage.add_child(source)
	var layers := stack_layers()
	for layer: CanvasItem in layers:
		stage.add_child(_bake_copy(layer))
	_bake_viewport.add_child(stage)
	_baked_sprite = Sprite2D.new()
	_baked_sprite.name = "GroundBaked"
	_baked_sprite.centered = false
	_baked_sprite.visible = false
	_baked_sprite.texture = _bake_viewport.get_texture()
	var baked_material := ShaderMaterial.new()
	baked_material.shader = BAKED_SHADER
	baked_material.set_shader_parameter(&"ground_size", Vector2(pixels))
	_baked_sprite.material = baked_material
	add_child(_baked_sprite)
	# Après le rendu de la vue (sans rendu, sous GUT : l'image suivante).
	var rendered: Signal = RenderingServer.frame_post_draw \
		if DisplayServer.get_name() != "headless" else get_tree().process_frame
	await rendered
	if not is_instance_valid(_baked_sprite):
		return
	_baked = true
	_baked_sprite.visible = true
	for layer: CanvasItem in layers:
		if is_instance_valid(layer):
			layer.visible = false
	_baked_layers = layers
	queue_redraw()
	refresh_mist()


## Brume portée par le sol cuit (J21) : la première [MistLayer] visible de la carte qui couvre
## exactement le sol (même origine, même taille) est dessinée dans la passe du sol ; les brumes
## fusionnables de la carte ne se dessinent plus elles-mêmes. Sol non cuit : rien ne change.
## Rappelée par la brume à chaque changement (porte, alpha, « Réduire les animations »).
func refresh_mist() -> void:
	if not _baked or _baked_sprite == null:
		return
	var baked_material := _baked_sprite.material as ShaderMaterial
	var map := get_parent()
	var pixels := Vector2(size * Grid.TILE_SIZE)
	var active: MistLayer = null
	for layer: MistLayer in MistLayer.get_instances():
		if not is_instance_valid(layer) or layer.find_ground() != self:
			continue
		var offset := layer.global_position - global_position
		var mergeable := map != null and Vector2(layer.area) == pixels \
			and offset.is_zero_approx() and layer.texture != null
		layer.set_merged(mergeable)
		if mergeable and active == null and layer.is_visible_in_tree():
			active = layer
	baked_material.set_shader_parameter(&"mist_alpha", active.alpha if active != null else 0.0)
	if active != null:
		baked_material.set_shader_parameter(&"mist", active.texture)
		baked_material.set_shader_parameter(&"mist_texture_size",
			float(active.texture.get_width()))


## Brume portée par le sol cuit (alpha, 0 = aucune) : tests et journal.
func get_merged_mist_alpha() -> float:
	if not _baked or _baked_sprite == null:
		return 0.0
	return float((_baked_sprite.material as ShaderMaterial).get_shader_parameter(&"mist_alpha"))


## Couches cuites avec le sol : sur une carte de grotte (frère `CaveShade`, kit des grottes et
## de la Tour), les frères qui suivent le sol dans l'arbre, sous les personnages (z < 0) et
## immobiles ([method is_static_layer]), jusqu'au premier qui ne l'est pas (l'ordre de dessin
## est gardé). Ailleurs (moteur commun) : le sous-bois ([method forest_layers]).
func stack_layers() -> Array[CanvasItem]:
	var layers: Array[CanvasItem] = []
	var parent_node := get_parent()
	if parent_node == null:
		return layers
	if parent_node.get_node_or_null(^"CaveShade") == null:
		return forest_layers()
	for index: int in range(get_index() + 1, parent_node.get_child_count()):
		var sibling := parent_node.get_child(index) as CanvasItem
		if sibling == null or sibling.z_index >= 0 or not is_static_layer(sibling):
			break
		layers.append(sibling)
	return layers


## Vrai si [param node] et tout son sous-arbre se dessinent sans jamais changer : visibles,
## `Node2D`, `Sprite2D` ou `Polygon2D` sans script, ou décor [WorldProp] qui ne s'efface pas.
static func is_static_layer(node: Node) -> bool:
	var item := node as CanvasItem
	if item == null or not item.visible:
		return false
	var plain := node.get_script() == null \
		and _STATIC_CLASSES.has(node.get_class())
	var prop := node is WorldProp and not (node as WorldProp).fade_when_covering
	if not plain and not prop:
		return false
	for child: Node in node.get_children():
		if not is_static_layer(child):
			return false
	return true


## Sous-bois cuit avec le sol (moteur commun) : les [ForestFloor] visibles qui suivent le sol
## dans l'arbre, au même z, sans autre couche entre eux (l'ordre de dessin est gardé).
func forest_layers() -> Array[CanvasItem]:
	var layers: Array[CanvasItem] = []
	var parent_node := get_parent()
	if parent_node == null:
		return layers
	for index: int in range(get_index() + 1, parent_node.get_child_count()):
		var forest := parent_node.get_child(index) as ForestFloor
		if forest == null or not forest.visible or forest.z_index != z_index \
				or forest.get_child_count() > 0 or forest.get_shader_material() == null:
			break
		layers.append(forest)
	return layers


## Copie d'une couche à cuire : le rectangle du shader pour un [ForestFloor], sinon une copie
## sans script, qui ne fait que se dessiner.
func _bake_copy(layer: CanvasItem) -> Node:
	var forest := layer as ForestFloor
	if forest == null:
		return layer.duplicate(0)
	var source := BakeSource.new()
	source.rect = Rect2(Vector2.ZERO, Vector2(forest.size * Grid.TILE_SIZE))
	source.material = forest.material
	source.transform = forest.transform
	source.z_index = forest.z_index
	return source


## Vrai si le sol peut être cuit par morceaux ([method bake_chunks]) : avec un matériau et une
## taille. Toujours essayé après [method can_bake].
func can_bake_chunks() -> bool:
	return get_shader_material() != null and size.x > 0 and size.y > 0


## Cuisson par morceaux (moteur commun, voir l'en-tête) : la terre et le sous-bois
## ([method forest_layers]) dans [GroundChunks], l'eau du rivage dans [GroundWater] au-dessus.
## Le sous-bois est caché tout de suite (ses morceaux pas encore rendus sont dessinés en repli
## par [GroundChunks]). Sans effet si une cuisson est déjà en place ou hors de l'arbre.
func bake_chunks() -> void:
	if _chunks != null or _bake_viewport != null or not is_inside_tree() \
			or not can_bake_chunks():
		return
	var land := get_shader_material()
	if shore_mask != null:
		land = land.duplicate() as ShaderMaterial
		land.set_shader_parameter(&"pass_mode", PASS_LAND)
	var sources: Array[Dictionary] = [{
		"material": land, "transform": Transform2D(),
		"rect": Rect2(Vector2.ZERO, Vector2(size * Grid.TILE_SIZE)),
	}]
	var layers := forest_layers()
	for layer: CanvasItem in layers:
		var forest := layer as ForestFloor
		sources.append({
			"material": forest.material,
			"transform": transform.affine_inverse() * forest.transform,
			"rect": Rect2(Vector2.ZERO, Vector2(forest.size * Grid.TILE_SIZE)),
		})
	_chunks = GroundChunks.new()
	add_child(_chunks)
	_chunks.setup(size * Grid.TILE_SIZE, sources)
	if shore_mask != null:
		_water = GroundWater.new()
		add_child(_water)
		var to_forest: Array[Transform2D] = []
		for layer: CanvasItem in layers:
			to_forest.append(transform.affine_inverse() * (layer as Node2D).transform)
		_water.setup(get_shader_material(), shore_mask, square_shore, layers, to_forest)
	for layer: CanvasItem in layers:
		layer.visible = false
	_baked_layers = layers
	queue_redraw()


## Vrai si le sol est cuit par morceaux ([method bake_chunks]).
func is_chunked() -> bool:
	return _chunks != null


## Morceaux cuits (null sans [method bake_chunks]).
func get_chunks() -> GroundChunks:
	return _chunks


## Eau animée au-dessus des morceaux (null sans rivage ou sans [method bake_chunks]).
func get_water() -> GroundWater:
	return _water


## Couches cachées après la cuisson (dessinées dans la texture du sol).
func get_baked_layers() -> Array[CanvasItem]:
	return _baked_layers.duplicate()


## Vrai une fois le sol cuit et affiché comme une texture.
func is_baked() -> bool:
	return _baked


## Rectangle du shader de sol, dessiné une seule fois dans le `SubViewport` de la cuisson.
class BakeSource:
	extends Node2D
	var rect: Rect2

	func _draw() -> void:
		draw_rect(rect, Color.WHITE)


func get_shader_material() -> ShaderMaterial:
	return material as ShaderMaterial


## Textures effectivement dessinées : fond, canal rouge, canal vert (défauts compris).
func get_textures() -> Array[Texture2D]:
	var shader_material := get_shader_material()
	var textures: Array[Texture2D] = []
	for parameter: StringName in [&"grass_texture", &"paving_texture", &"path_texture"]:
		textures.append(shader_material.get_shader_parameter(parameter) as Texture2D)
	return textures


func _update_material() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = SHADER
		material = shader_material
		_update_textures()
	shader_material.set_shader_parameter(&"ground_mask", mask)
	shader_material.set_shader_parameter(&"tile_size", float(Grid.TILE_SIZE))
	shader_material.set_shader_parameter(&"has_shore", shore_mask != null)
	shader_material.set_shader_parameter(&"shore_mask", shore_mask)
	if shore_mask != null and shader_material.get_shader_parameter(&"sand_texture") == null:
		shader_material.set_shader_parameter(&"sand_texture", load(SAND_TEXTURE))
	if shore_mask != null:
		shader_material.set_shader_parameter(&"water_texture",
			water_texture if water_texture != null else load(WATER_TEXTURE))
	shader_material.set_shader_parameter(&"water_texture_size",
		float(water_texture.get_width()) if water_texture != null else null)
	# Aux défauts, aucun réglage : l'uniform garde la valeur du shader.
	shader_material.set_shader_parameter(&"foam_strength",
		null if is_equal_approx(foam_strength, DEFAULT_FOAM_STRENGTH) else foam_strength)
	shader_material.set_shader_parameter(&"square_shore", true if square_shore else null)


## Pose les trois textures (réglées ou par défaut). Une carte enregistrée sans réglage garde le
## matériau de sa scène, qui porte déjà les textures par défaut : rien n'est rechargé.
func _update_textures() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter(&"grass_texture",
		base_texture if base_texture != null else load(GRASS_TEXTURE))
	shader_material.set_shader_parameter(&"paving_texture",
		r_texture if r_texture != null else load(PAVING_TEXTURE))
	shader_material.set_shader_parameter(&"path_texture",
		g_texture if g_texture != null else load(PATH_TEXTURE))
