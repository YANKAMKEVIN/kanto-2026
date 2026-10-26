class_name RoomLight
extends Node2D
## Lumière de pièce d'un intérieur (DAF.6, reporté « intérieurs vraie DA ») : pénombre au
## pourtour et flaque chaude des fenêtres ([member LightProfile.room_edge_color],
## [member LightProfile.room_pool_color]), dessinées par `room_light.gdshader` sur un seul
## rectangle de la taille de la carte. Posée par [WorldLighting] dans la carte quand le profil a
## un bloc « room » (aucune image, aucune donnée de carte) ; retirée sinon.
## Au-dessus des personnages et des meubles ([constant Z_ROOM_LIGHT] absolu : sous le toit
## `Overhead` et le voile d'obscurité), pour que la lumière tombe aussi sur eux.

const NODE_NAME: StringName = &"RoomLight"
const SHADER: Shader = preload("res://game/world/lighting/shaders/room_light.gdshader")
const Z_ROOM_LIGHT: int = 9

var _size: Vector2 = Vector2.ZERO


func _init() -> void:
	name = NODE_NAME
	z_index = Z_ROOM_LIGHT
	z_as_relative = false
	var shader_material := ShaderMaterial.new()
	shader_material.shader = SHADER
	material = shader_material


func _draw() -> void:
	if _size != Vector2.ZERO:
		draw_rect(Rect2(Vector2.ZERO, _size), Color.WHITE)


## Pose [param profile] sur la pièce [param rect] (pixels de la carte).
func setup(profile: LightProfile, rect: Rect2) -> void:
	position = rect.position
	_size = rect.size
	var shader_material := material as ShaderMaterial
	shader_material.set_shader_parameter(&"room_size", rect.size)
	shader_material.set_shader_parameter(&"edge_color", profile.room_edge_color)
	shader_material.set_shader_parameter(&"edge_alpha", profile.room_edge_color.a)
	shader_material.set_shader_parameter(&"edge_width",
		profile.room_edge_width * Grid.TILE_SIZE)
	shader_material.set_shader_parameter(&"pool_color", profile.room_pool_color)
	shader_material.set_shader_parameter(&"pool_alpha", profile.room_pool_color.a)
	shader_material.set_shader_parameter(&"pool_center", profile.room_pool_center)
	shader_material.set_shader_parameter(&"pool_radius", profile.room_pool_radius)
	shader_material.set_shader_parameter(&"sun_dir", -profile.sun_direction)
	queue_redraw()


func get_shader_material() -> ShaderMaterial:
	return material as ShaderMaterial


## Pose, met à jour ou retire la lumière de pièce de [param map] selon [param profile] (sans
## bloc « room », ou carte sans taille : retirée). Rend le nœud posé, ou null.
static func apply_to(map: Node, profile: LightProfile) -> RoomLight:
	if map == null:
		return null
	var existing := map.get_node_or_null(NodePath(String(NODE_NAME))) as RoomLight
	var rect := Rect2()
	if map.has_method(&"get_pixel_rect"):
		rect = Rect2(map.call(&"get_pixel_rect"))
	if profile == null or not profile.has_room() or rect.size == Vector2.ZERO:
		if existing != null:
			map.remove_child(existing)
			existing.queue_free()
		return null
	if existing == null:
		existing = RoomLight.new()
		map.add_child(existing)
	existing.setup(profile, rect)
	return existing
