extends SceneTree
## Lot DAF.10b, raccords (RP-281, RP-282 ; fiche `docs/design/fiches-assets/daf-10b/fiche.md`) :
## - Routes 4 et 24 : la forêt serrée de leurs constructeurs est taillée aux cases que la caméra
##   peut montrer depuis une case **à pied** (`DenseForest.cull_hidden`) ; le Surf (Route 24) et
##   l'écran large du téléphone montrent pourtant des cases de forêt sans arbre (sous-bois sombre
##   uni). Cette passe plante la forêt sur les cases `T` que ni un arbre ni un buisson ne
##   couvrent, sans taille ; nœuds `Daf10bCoin*` dans `Entities` (des `Sprite2D`, sans emprise).
## - Route 22 : le fondu du haut du fond peint (`BackdropPlateau`) est réglé dans son matériau
##   (`top_fade` de `backdrop_fade.gdshader`, 0 par défaut).
## Idempotente. **La logique ne change pas** : `dump_map_logic` et `dump_map_nodes` identiques.
##
##   godot --headless --path . -s res://tools/build_daf10b_raccords.gd

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const PREFIX: String = "Daf10bCoin"
const TILE: float = 96.0
## Carte → [grille, graine].
const MAPS: Dictionary = {&"route_4": ["route_4", 10040], &"route_24": ["route_24", 10240]}
## Ombre « plus sèche » des routes voisines (`build_route_4.gd`).
const SHADE := Vector3(0.95, 1.02, 1.0)
## Fondu du haut du fond peint de la Route 22 (part de la hauteur de la rognure) [D].
const TOP_FADE: float = 0.22

var _errors: int = 0
var _forest: GDScript = load("res://game/world/forest/dense_forest.gd")


func _init() -> void:
	for map_id: StringName in MAPS:
		_plant(map_id)
	_fade_route_22()
	quit(1 if _errors > 0 else 0)


func _plant(map_id: StringName) -> void:
	var spec: Array = MAPS[map_id]
	var plan := PlanGrid.new()
	if not plan.load_file("res://tools/plans/%s.txt" % spec[0]):
		push_error(plan.error)
		_errors += 1
		return
	var size := Vector2i(plan.width, plan.height)
	var path := "res://game/world/maps/%s.tscn" % map_id
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	var entities := root.get_node(^"Entities")
	var feet: Array[Vector2] = []
	for child: Node in entities.get_children():
		if String(child.name).begins_with(PREFIX):
			entities.remove_child(child)
			child.free()
			continue
		var n := String(child.name)
		if n.begins_with("Forest") or n.begins_with("Tree"):
			feet.append((child as Node2D).position / TILE)
	var bare: Dictionary = {}
	for cell: Vector2i in plan.cells_of("T"):
		if not _forest.call(&"is_covered", cell, feet):
			bare[cell] = true
	var shade_class: Variant = _forest.get_script_constant_map()["Shade"]
	var shade: Object = shade_class.new()
	shade.set(&"from_row", float(size.y + 200))
	shade.set(&"full_row", float(size.y + 100))
	shade.set(&"value", SHADE.x)
	shade.set(&"red", SHADE.y)
	shade.set(&"blue", SHADE.z)
	shade.set(&"weights_row", -1000.0)
	var entries: Array[Dictionary] = _forest.call(&"plan", bare, size, feet, spec[1], shade)
	var nodes: Array[Sprite2D] = _forest.call(&"place_sprites", entries, entities, root)
	for sprite: Sprite2D in nodes:
		sprite.name = PREFIX + String(sprite.name)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s : %s (%d cases nues, %d arbres et buissons)" % [map_id, error_string(err), bare.size(),
		nodes.size()])
	if err != OK:
		_errors += 1
	root.free()


func _fade_route_22() -> void:
	var path := "res://game/world/maps/route_22.tscn"
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	var backdrop := root.get_node(^"BackdropPlateau") as Sprite2D
	(backdrop.material as ShaderMaterial).set_shader_parameter(&"top_fade", TOP_FADE)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("route_22 : %s (fondu du haut %.2f)" % [error_string(err), TOP_FADE])
	if err != OK:
		_errors += 1
	root.free()
