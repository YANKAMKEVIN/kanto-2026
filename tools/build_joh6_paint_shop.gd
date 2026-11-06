extends SceneTree
## Passe d'ambiance de la boutique de souvenirs d'Acajou (JOH6, demande de Kevin du 2026-11-06),
## d'après sa vue générale (`boutique-souvenirs-acajou-v1.png`) : repeint `mahogany_souvenir_shop`
## **après** `build_joh6_maps.gd`, sans changer la logique (cases bloquées, passages, arrivées,
## déclencheur, point d'examen, [FlagGate] `EtagereCachee` et `EscalierVersB1f` avec leurs drapeaux
## et leurs cases occupées ; PNJ et données ailleurs).
##
## - **Enveloppe** : `int_maison_argenta_coque` (bois clair, murs crème, 15 × 10 comme la grille),
##   déjà celle des maisons de Johto [D] : la coque des Boutiques porte la Poké Ball. Les couches de
##   tuiles sont seulement masquées (source logique).
## - **Meubles** (images seules, sans emprise, dans `Entities`) : rayons mur `r` et `b` en
##   `int_rayon_souvenirs_01` (une image de deux cases par paire `bb` ; le `r` isolé et les
##   présentoirs `q` à l'échelle 0,6), comptoir `c` en `int_comptoir_pension_01` (trois cases),
##   plante `x`, tapis rouge sur la sortie `X` (dans `Decor`) [D].
## - **Portes à drapeau** : l'étagère qui cache l'escalier garde son [FlagGate] (affichée tant que
##   `johto_hideout_found` manque) avec le rayon peint à la place de son aplat ; l'escalier apparu
##   garde le sien avec `int_escalier_repaire_descend_01`.
## Les aplats `Polygon2D` de `Decor` et des portes (de `build_joh6_maps.gd`) sont retirés. Nœuds
## posés ici : préfixe `JohAmbShop` (relance idempotente).
##
##   godot --headless --path . -s res://tools/build_joh6_paint_shop.gd
##   À relancer après `build_joh6_maps.gd`.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAP_PATH: String = "res://game/world/maps/mahogany_souvenir_shop.tscn"
const PLAN_PATH: String = "res://tools/plans/mahogany_souvenir_shop.txt"
const PROPS: String = "res://game/world/props/painted/%s.tscn"
const SHELL: String = "res://assets/world/interiors/int_maison_argenta_coque.png"
const OWN: String = "JohAmbShop"
const TILE: int = 96
const Z_GROUND: int = -3
const SHELF: String = "int_rayon_souvenirs_01"
const STAND: String = "int_presentoir_souvenirs_01"
const COUNTER: String = "int_comptoir_pension_01"
const PLANT: String = "int_plante"
const RUG: String = "int_tapis_rouge_01"
const STAIRS: String = "int_escalier_repaire_descend_01"
## Échelle d'un meuble de deux cases posé sur une seule case [D].
const SINGLE: float = 0.6

var _root: Node2D


func _init() -> void:
	_root = (load(MAP_PATH) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	var plan := PlanGrid.new()
	if not plan.load_file(PLAN_PATH):
		push_error("boutique : %s" % plan.error)
		quit(1)
		return
	_clean(_root)
	_clear_polygons(_root.get_node(^"Decor"))
	_clear_polygons(_root.get_node(^"Entities"))
	for layer: Node in _root.get_children():
		if layer is TileMapLayer:
			(layer as TileMapLayer).visible = false
	var shell := Sprite2D.new()
	shell.name = OWN + "Shell"
	shell.texture = load(SHELL)
	shell.centered = false
	shell.z_index = Z_GROUND
	_root.add_child(shell)
	shell.owner = _root
	_root.move_child(shell, 0)
	var decor := _root.get_node(^"Decor")
	var entities := _root.get_node(^"Entities")
	var count := 0
	for cell: Vector2i in plan.cells_of("r"):
		_place(entities, SHELF, _foot(cell), Vector2.ONE * SINGLE, "Shelf%d" % count)
		count += 1
	for row: int in plan.height:
		var x := 0
		while x < plan.width:
			if plan.at(Vector2i(x, row)) != "b":
				x += 1
				continue
			var start := x
			while x < plan.width and plan.at(Vector2i(x, row)) == "b":
				x += 1
			for left: int in range(start, x - 1, 2):
				_place(entities, SHELF, Vector2((left + 1) * TILE, (row + 1) * TILE), Vector2.ONE,
					"Shelf%d" % count)
				count += 1
	var counter := plan.cells_of("c")
	if not counter.is_empty():
		var first: Vector2i = counter[0]
		_place(entities, COUNTER, Vector2((first.x + counter.size() / 2.0) * TILE,
			(first.y + 1) * TILE), Vector2.ONE, "Counter")
	for cell: Vector2i in plan.cells_of("q"):
		_place(entities, STAND, _foot(cell), Vector2.ONE * SINGLE, "Stand%d" % cell.x)
	for cell: Vector2i in plan.cells_of("x"):
		_place(entities, PLANT, _foot(cell), Vector2.ONE * SINGLE, "Plant%d" % cell.x)
	var mats := plan.cells_of("X")
	if not mats.is_empty():
		mats.sort()
		var rug_foot := Vector2((mats[0].x + mats.size() / 2.0) * TILE, (mats[0].y + 1) * TILE + 6.0)
		_place(decor, RUG, rug_foot, Vector2(0.75, 0.45), "Rug")
	_paint_gate(entities, "EtagereCachee", SHELF, Vector2.ONE * SINGLE)
	_paint_gate(decor, "EscalierVersB1f", STAIRS, Vector2.ONE)
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err == OK:
		err = ResourceSaver.save(packed, MAP_PATH)
	print("mahogany_souvenir_shop : %s (%d meubles)" % [error_string(err), count])
	_root.free()
	quit(0 if err == OK else 1)


func _foot(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * TILE, (cell.y + 1) * TILE)


## Image seule de l'objet peint [param id], pied en [param foot] (pixels du monde), même matériau.
func _place(parent: Node, id: String, foot: Vector2, scale: Vector2, node_name: String) -> Sprite2D:
	var sprite := _sprite(id, Vector2.ZERO, scale, OWN + node_name)
	sprite.position = (foot + sprite.position).round()
	parent.add_child(sprite)
	sprite.owner = _root
	return sprite


func _sprite(id: String, foot: Vector2, scale: Vector2, node_name: String) -> Sprite2D:
	var model := (load(PROPS % id) as PackedScene).instantiate()
	var sprite := (model.get_node(^"Sprite") as Sprite2D).duplicate() as Sprite2D
	model.free()
	sprite.name = node_name
	sprite.unique_name_in_owner = false
	sprite.position = (foot + sprite.position).round()
	sprite.scale = scale
	return sprite


## Dessin d'une porte à drapeau (l'aplat est déjà retiré) : l'image au pied de la porte.
func _paint_gate(parent: Node, gate_name: String, id: String, scale: Vector2) -> void:
	var gate := parent.get_node_or_null(NodePath(gate_name)) as Node2D
	if gate == null:
		push_error("boutique : porte « %s » absente (build_joh6_maps.gd)" % gate_name)
		return
	var sprite := _sprite(id, Vector2.ZERO, scale, OWN + "Art")
	gate.add_child(sprite)
	sprite.owner = _root


func _clear_polygons(node: Node) -> void:
	for child: Node in node.get_children():
		_clear_polygons(child)
		if child is Polygon2D and child.owner == _root:
			node.remove_child(child)
			child.free()


func _clean(node: Node) -> void:
	for child: Node in node.get_children():
		if String(child.name).begins_with(OWN):
			node.remove_child(child)
			child.free()
		else:
			_clean(child)
