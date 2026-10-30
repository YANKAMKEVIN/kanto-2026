extends SceneTree
## Lot DAF.10a (`tools/art/daf10a.py`, fiche `docs/design/fiches-assets/daf-10a/fiche.md`, RP-272 pour
## le Parc) : habille les six intérieurs du Parc Safari restés en tuiles provisoires (J23) : Porte
## (`safari_zone_gate`), maison de repos (`safari_zone_{center,east,north,west}_rest_house`, une seule
## salle réutilisée), Maison Secrète (`safari_zone_secret_house`). Seconde passe d'image : **la logique
## ne change pas** (gel du J33) ; les couches de tuiles sont masquées, l'enveloppe peinte
## (`int_maison_argenta_coque` pour les 15 × 10 ; `int_safari_12x10_coque`, la même recoupée à 12 cases,
## pour la Porte et la Maison Secrète) et le mobilier (objets sans emprise : leurs cases sont déjà
## solides dans la grille) sont posés dessus. PNJ, sorties et déclencheurs sont gardés.
##
##   godot --headless --path . -s res://tools/build_daf10a_interieurs.gd

const MAPS_DIR: String = "res://game/world/maps/"
const PROPS: String = "res://game/world/props/painted/%s.tscn"
const SHELL_15: String = "res://assets/world/interiors/int_maison_argenta_coque.png"
const SHELL_12: String = "res://assets/world/interiors/int_safari_12x10_coque.png"
const OWN_PREFIX: String = "Daf10a"
const TILE: int = 96
const Z_GROUND: int = -3
## Mobilier : [objet, pied (cases : x au milieu, y = bas), échelle (facultatif)].
const REST_HOUSE: Array = [
	["int_long_comptoir_01", Vector2(7.5, 4.0)],
	["prop_banc_01", Vector2(3.0, 8.0)], ["prop_banc_01", Vector2(12.0, 8.0)],
	["int_plante", Vector2(2.5, 4.0)], ["int_plante", Vector2(12.5, 4.0)],
]
const GATE: Array = [
	["int_comptoir_pension_01", Vector2(3.0, 4.0), 0.667], ["int_comptoir_pension_01", Vector2(3.0, 5.0), 0.667],
	["int_comptoir_pension_01", Vector2(3.0, 6.0), 0.667],
	["int_comptoir_pension_01", Vector2(9.0, 4.0), 0.667], ["int_comptoir_pension_01", Vector2(9.0, 5.0), 0.667],
	["int_comptoir_pension_01", Vector2(9.0, 6.0), 0.667],
]
const SECRET_HOUSE: Array = [
	["prop_casiers_peche_01", Vector2(3.0, 4.0)], ["prop_casiers_peche_01", Vector2(9.0, 4.0)],
	["int_aquarium_01", Vector2(5.5, 4.0)], ["int_aquarium_01", Vector2(6.5, 4.0)],
]
const MAPS: Dictionary = {
	&"safari_zone_gate": [SHELL_12, GATE],
	&"safari_zone_rest_house_center": [SHELL_15, REST_HOUSE],
	&"safari_zone_rest_house_east": [SHELL_15, REST_HOUSE],
	&"safari_zone_rest_house_north": [SHELL_15, REST_HOUSE],
	&"safari_zone_rest_house_west": [SHELL_15, REST_HOUSE],
	&"safari_zone_secret_house": [SHELL_12, SECRET_HOUSE],
}

var _errors: int = 0


func _init() -> void:
	for map_id: StringName in MAPS:
		_build(map_id)
	quit(1 if _errors > 0 else 0)


func _build(map_id: StringName) -> void:
	var spec: Array = MAPS[map_id]
	var path := MAPS_DIR + "%s.tscn" % map_id
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean(root)
	for layer_name: String in ["Ground", "Detail", "Obstacles", "Overhead"]:
		var layer := root.get_node_or_null(NodePath(layer_name)) as TileMapLayer
		if layer != null:
			layer.visible = false
	var shell := Sprite2D.new()
	shell.name = OWN_PREFIX + "Shell"
	shell.texture = load(spec[0])
	shell.centered = false
	shell.z_index = Z_GROUND
	var size: Vector2i = root.get(&"size")
	if shell.texture.get_size() != Vector2(size * TILE):
		push_error("%s : enveloppe %s ≠ %s cases" % [map_id, shell.texture.get_size(), size])
		_errors += 1
		root.free()
		return
	root.add_child(shell)
	shell.owner = root
	root.move_child(shell, root.get_node(^"Obstacles").get_index() + 1)
	var entities := root.get_node(^"Entities")
	var index := 0
	for entry: Array in spec[1]:
		var prop := (load(PROPS % entry[0]) as PackedScene).instantiate(
			PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
		prop.name = "%sMobilier%02d" % [OWN_PREFIX, index]
		prop.position = ((entry[1] as Vector2) * TILE).round()
		prop.set(&"footprint", [] as Array[Vector2i])
		if entry.size() > 2:
			prop.scale = Vector2.ONE * float(entry[2])
		entities.add_child(prop)
		prop.owner = root
		index += 1
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s : %s (%d meubles)" % [map_id, error_string(err), index])
	if err != OK:
		_errors += 1
	root.free()


func _clean(root: Node) -> void:
	var old := root.get_node_or_null(NodePath(OWN_PREFIX + "Shell"))
	if old != null:
		root.remove_child(old)
		old.free()
	var entities := root.get_node(^"Entities")
	for child: Node in entities.get_children():
		if String(child.name).begins_with(OWN_PREFIX):
			entities.remove_child(child)
			child.free()
