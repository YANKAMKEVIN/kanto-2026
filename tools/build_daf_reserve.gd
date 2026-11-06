extends SceneTree
## Repeint la réserve du Musée d'Argenta (`pewter_museum_reserve`), écrite en tuiles provisoires et
## en aplats par `build_j25_rooms.gd` (J25) et oubliée par le lot DAF.9. Choix de la série 28
## (`docs/design/fiches-assets/serie-28-cramois.md`) : coque `int_musee_coque`, comptoir
## `int_comptoir_reserve_01` (le long comptoir sans son écran : `tools/art/comptoir_reserve.py`),
## vitrines de l'ambre et caisses de fouilles.
##
## Passe APRÈS `build_j25_rooms.gd`, sur le modèle de `build_daf9_cramois.gd` ; idempotente (elle
## retire d'abord ses propres nœuds). **La logique ne change pas** : les couches de tuiles sont
## gardées et seulement masquées ; les [FlagGate] `Meuble_*` gardent leurs cases bloquées ; seuls
## leurs dessins (`Polygon2D`) sont retirés.
## Contrôle : `tools/dump_map_logic.gd` identique avant / après.
##
##   godot --headless --path . -s res://tools/build_daf_reserve.gd

const FlagGateScript := preload("res://game/world/flag_gate.gd")
const MAP_PATH: String = "res://game/world/maps/pewter_museum_reserve.tscn"
const INTERIORS: String = "res://assets/world/interiors/%s.png"
const PROPS: String = "res://assets/world/props/%s.png"
const TILE: int = 96
const Z_SHELL: int = -3
const OWN_PREFIX: String = "Reserve"
const TILE_LAYERS: Array[NodePath] = [^"Ground", ^"Detail", ^"Obstacles", ^"Overhead"]
const AMBER_FLAG: StringName = &"pewter_museum_got_old_amber"
## Objets debout : [nœud, image, pied en cases]. Les emprises restent celles de la grille.
const FURNITURE: Array = [
	# L'arche nord de la coque ne mène nulle part ici : porte du laboratoire, comme la salle science.
	["ReserveDoor", INTERIORS % "int_porte_labo_01", Vector2(7.5, 2.4)],
	["ReserveShelf", INTERIORS % "int_etagere_labo_01", Vector2(13.0, 2.9)],
	["ReserveCounter", INTERIORS % "int_comptoir_reserve_01", Vector2(5.5, 5.92)],
	["ReserveCratesNorth", PROPS % "int_caisses_fouilles_01", Vector2(2.0, 3.92)],
	["ReserveCratesSouth", PROPS % "int_caisses_fouilles_01", Vector2(2.0, 7.92)],
]
## Pied de la vitrine, relatif au [FlagGate] (bas de la case (11, 3)).
const SHOWCASE_FOOT := Vector2(0, -8)

var _errors: int = 0


func _init() -> void:
	var root := (load(MAP_PATH) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	_clean(root)
	for path: NodePath in TILE_LAYERS:
		(root.get_node(path) as CanvasItem).visible = false
	var shell := Sprite2D.new()
	shell.name = "ReserveShell"
	shell.texture = load(INTERIORS % "int_musee_coque")
	shell.centered = false
	shell.z_index = Z_SHELL
	_attach(root, root, shell)
	root.move_child(shell, 0)
	var entities := root.get_node(^"Entities") as Node2D
	for entry: Array in FURNITURE:
		_sprite(root, entities, entry[0], entry[1], entry[2] * TILE)
	_dress_showcase(root, entities)
	if _errors == 0:
		var packed := PackedScene.new()
		var err := packed.pack(root)
		if err == OK:
			err = ResourceSaver.save(packed, MAP_PATH)
		if err != OK:
			push_error("réserve : enregistrement impossible (%d)" % err)
			_errors += 1
	root.free()
	print("build_daf_reserve : %s" % ("OK" if _errors == 0 else "ÉCHEC"))
	quit(1 if _errors > 0 else 0)


## Ambre présent : image dans le [FlagGate] existant. Ambre remis : [FlagGate] visuel à part, sans
## case (le blocage reste celui de `Meuble_11_3`).
func _dress_showcase(root: Node, entities: Node2D) -> void:
	var full := entities.get_node(^"VitrinePleine") as Node2D
	_sprite(root, full, "ReserveShowcaseFull", PROPS % "int_vitrine_ambre_pleine_01", SHOWCASE_FOOT)
	var empty := Node2D.new()
	empty.set_script(FlagGateScript)
	empty.name = "ReserveShowcaseEmpty"
	empty.position = full.position
	var if_flags: Array[StringName] = [AMBER_FLAG]
	empty.set(&"if_flags", if_flags)
	_attach(root, entities, empty)
	_sprite(root, empty, "Image", PROPS % "int_vitrine_ambre_vide_01", SHOWCASE_FOOT)


func _sprite(root: Node, parent: Node, node_name: String, path: String, foot: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = load(path)
	if sprite.texture == null:
		push_error("réserve : image absente %s" % path)
		_errors += 1
		sprite.free()
		return
	sprite.centered = false
	sprite.offset = Vector2(-sprite.texture.get_width() / 2.0, -sprite.texture.get_height())
	sprite.position = foot
	_attach(root, parent, sprite)


func _attach(root: Node, parent: Node, node: Node) -> void:
	parent.add_child(node)
	node.owner = root


## Retire les nœuds de cette passe, et tout dessin des [FlagGate] (aplats du J25 ou images).
func _clean(root: Node) -> void:
	var old_shell := root.get_node_or_null(^"ReserveShell")
	if old_shell != null:
		root.remove_child(old_shell)
		old_shell.free()
	var entities := root.get_node(^"Entities")
	for child: Node in entities.get_children():
		if String(child.name).begins_with(OWN_PREFIX):
			entities.remove_child(child)
			child.free()
		elif child.get_script() == FlagGateScript:
			for drawing: Node in child.get_children():
				child.remove_child(drawing)
				drawing.free()
