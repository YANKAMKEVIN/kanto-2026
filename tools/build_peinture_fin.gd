extends SceneTree
## Repeint les deux dernières cartes en tuiles : la Maison du Gardien de Parmanie (`wardens_house`,
## écrite par `build_j23_maps.gd`) et le souvenir de Dante (`dante_flashback_hq`,
## `build_joh6_maps.gd`). Passe APRÈS ces outils ; idempotente (nœuds `Fin*`). Les couches de tuiles
## restent la source logique, masquées ; portes, points d'examen et rocher ne sont pas touchés.
##
##   godot --headless --path . -s res://tools/build_peinture_fin.gd

const MAPS_DIR: String = "res://game/world/maps/"
const INTERIORS: String = "res://assets/world/interiors/%s.png"
const TILE: int = 96
const Z_SHELL: int = -3
const OWN_PREFIX: String = "Fin"
const LAYERS: Array[NodePath] = [^"Ground", ^"Detail", ^"Obstacles", ^"Overhead"]
const FLAMES: int = 6
## Maison du Gardien : [nœud, image, pied en cases].
const WARDEN: Array = [
	["FinCases", "int_vitrine_journal_01", Vector2(6.0, 2.92)],
	["FinShelf", "int_petite_etagere_01", Vector2(2.5, 3.92)],
	["FinNiche", "int_classeur_01", Vector2(10.5, 2.92)],
	["FinWestLamp", "int_chevet_lampe_01", Vector2(1.5, 5.92)],
	["FinEastShelf", "int_petite_etagere_01", Vector2(13.5, 4.92)],
]

var _errors: int = 0


func _init() -> void:
	_build(&"wardens_house", "int_maison_argenta_coque", _dress_warden)
	_build(&"dante_flashback_hq", "int_maison_ebenelle_coque", _dress_flashback)
	print("build_peinture_fin : %s" % ("OK" if _errors == 0 else "ÉCHEC"))
	quit(1 if _errors > 0 else 0)


func _build(map_id: StringName, shell_id: String, dress: Callable) -> void:
	var path := MAPS_DIR + "%s.tscn" % map_id
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	_clean(root)
	for layer: NodePath in LAYERS:
		(root.get_node(layer) as CanvasItem).visible = false
	var shell := Sprite2D.new()
	shell.name = "FinShell"
	shell.texture = load(INTERIORS % shell_id)
	shell.centered = false
	shell.z_index = Z_SHELL
	root.add_child(shell)
	shell.owner = root
	root.move_child(shell, 0)
	dress.call(root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("%s : enregistrement impossible (%d)" % [map_id, err])
		_errors += 1
	root.free()


func _dress_warden(root: Node) -> void:
	for entry: Array in WARDEN:
		_sprite(root, root.get_node(^"Entities"), entry[0], entry[1], entry[2] * TILE)


## Chaque aplat de flamme devient une flamme peinte posée au bas de sa place ; la porte bloquée,
## une porte peinte sous son [FlagGate] ou son nœud d'origine.
func _dress_flashback(root: Node) -> void:
	var decor := root.get_node(^"Decor")
	var index := 0
	for child: Node in decor.get_children():
		var polygon := child as Polygon2D
		if polygon == null:
			continue
		var box := Rect2(polygon.polygon[0], Vector2.ZERO)
		for point: Vector2 in polygon.polygon:
			box = box.expand(point)
		polygon.visible = false
		var image := "int_flamme_%02d" % (index % FLAMES + 1)
		_sprite(root, decor, "Fin%s" % polygon.name, image,
			Vector2(box.get_center().x, box.end.y))
		index += 1
	var door := root.get_node(^"Entities/PorteBloquee")
	for child: Node in door.get_children():
		(child as CanvasItem).visible = false
	_sprite(root, door, "FinDoor", "hideout_office_door", Vector2.ZERO)


func _sprite(root: Node, parent: Node, node_name: String, image: String, foot: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = load(INTERIORS % image)
	if sprite.texture == null:
		push_error("image absente : %s" % image)
		_errors += 1
		sprite.free()
		return
	sprite.centered = false
	sprite.offset = Vector2(-sprite.texture.get_width() / 2.0, -sprite.texture.get_height())
	sprite.position = foot
	parent.add_child(sprite)
	sprite.owner = root


func _clean(root: Node) -> void:
	for parent_path: NodePath in [^".", ^"Entities", ^"Decor", ^"Entities/PorteBloquee"]:
		var parent := root.get_node_or_null(parent_path)
		if parent == null:
			continue
		for child: Node in parent.get_children():
			if String(child.name).begins_with(OWN_PREFIX):
				parent.remove_child(child)
				child.free()
