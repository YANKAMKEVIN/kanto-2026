extends SceneTree
## Génère une scène `WorldProp` par objet peint de `assets/world/catalogue.json`
## (docs/tech/jalon-07.md §6.6) : `game/world/props/painted/<id>.tscn`.
##
##   godot --headless --path . -s res://tools/build_painted_props.gd [-- --nouveaux]
##
## `--nouveaux` : seulement les objets qui n'ont pas encore de scène (les scènes existantes
## gardent leurs `unique_id` : pas de différence inutile dans git quand on ajoute des objets).
##
## Chaque scène :
## - racine `WorldProp` (prop.gd) au **pied** de l'objet, emprise et transparence lues dans
##   `PaintedPropRules` (règles du prototype, `emprises.gd`) ;
## - `%Sprite` : l'image à 1:1 (filtre LINEAR du projet), matériau partagé `world_object`
##   (liseré de soleil) ou `world_object_wind` (feuillages) ;
## - `CastShadow` (groupe `cast_shadows`) et `ContactShadow` (groupe `contact_shadows`) : les
##   ombres pré-floutées de tools/art/preparer.py, à l'échelle 2, z absolu
##   `WorldLighting.Z_SHADOWS` (sous les décalcomanies et les personnages), matériaux partagés.
##   `WorldLighting` règle leur couleur, leur visibilité et l'inclinaison de l'ombre portée.
##   **Seulement pour les bâtiments** (`PaintedPropRules.casts_shadows`, règle « shadow »).
## Un identifiant du catalogue sans règle (ou l'inverse) est une erreur : un nouvel objet
## peint demande sa règle d'emprise. Les images seules du catalogue (« images » : sols,
## décalcomanies, enveloppes d'intérieur, fond peint) n'ont pas de scène.

const CATALOGUE := "res://assets/world/catalogue.json"
const OUT_DIR := "res://game/world/props/painted/"
const PROP_SCRIPT := "res://game/world/props/prop.gd"
const RULES_SCRIPT := "res://game/world/props/painted_prop_rules.gd"
const MATERIALS := "res://game/world/lighting/materials/"
const CAST_GROUP := &"cast_shadows"
const CONTACT_GROUP := &"contact_shadows"
## WorldLighting.Z_SHADOWS (les outils ne voient pas les class_name avant import).
const Z_SHADOWS := -2

var _rules: Script
var _errors: int = 0


func _init() -> void:
	_rules = load(RULES_SCRIPT)
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	var objects: Dictionary = catalogue["objets"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var only_new := OS.get_cmdline_user_args().has("--nouveaux")
	var built := 0
	for id: String in objects:
		if not _rules.call(&"has_rule", StringName(id)):
			push_error("build_painted_props : « %s » n'a pas de règle d'emprise" % id)
			_errors += 1
			continue
		if only_new and FileAccess.file_exists(OUT_DIR + id + ".tscn"):
			continue
		_build(StringName(id), objects[id])
		built += 1
	for id: StringName in _rules.call(&"get_ids"):
		if not objects.has(String(id)):
			push_error("build_painted_props : règle « %s » sans objet au catalogue" % id)
			_errors += 1
	print("build_painted_props : %d objets, %d scène(s) écrite(s), %d erreur(s)" % [
		objects.size(), built, _errors])
	quit(1 if _errors > 0 else 0)


func _build(id: StringName, entry: Dictionary) -> void:
	var root := Node2D.new()
	root.name = _scene_name(id)
	root.set_script(load(PROP_SCRIPT))
	var footprint: Array[Vector2i] = _rules.call(&"footprint", id)
	root.set(&"footprint", footprint)
	root.set(&"fade_when_covering", _rules.call(&"fades", id))
	var texture := load(entry["fichier"]) as Texture2D
	var size := Vector2(entry["taille"][0], entry["taille"][1])
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = texture
	sprite.centered = false
	var origin: Vector2 = _rules.call(&"origin", id, size)
	sprite.offset = -origin
	# Les ombres du catalogue sont placées par rapport au milieu du bas de l'image.
	var image_foot := Vector2(size.x / 2.0, size.y) - origin
	if _rules.call(&"uses_material", id):
		var wind: bool = _rules.call(&"has_wind", id)
		sprite.material = load(MATERIALS + ("world_object_wind.tres" if wind
			else "world_object.tres"))
	_add(root, sprite)
	sprite.unique_name_in_owner = true
	# Seuls les bâtiments ont une ombre (PaintedPropRules.casts_shadows).
	var shadows: bool = _rules.call(&"casts_shadows", id)
	if shadows and entry.has("ombre"):
		_add(root, _shadow("CastShadow", entry["ombre"], "cast_shadow.tres", CAST_GROUP,
			image_foot))
	if shadows and entry.has("contact"):
		_add(root, _shadow("ContactShadow", entry["contact"], "contact_shadow.tres",
			CONTACT_GROUP, image_foot))
	var packed := PackedScene.new()
	var result := packed.pack(root)
	if result != OK:
		push_error("build_painted_props : %s non empaquetée (%d)" % [id, result])
		_errors += 1
	else:
		var path := OUT_DIR + String(id) + ".tscn"
		if ResourceSaver.save(packed, path) != OK:
			push_error("build_painted_props : %s non écrite" % path)
			_errors += 1
		else:
			print("%s : emprise %d case(s)%s" % [path, footprint.size(),
				" (sol)" if _rules.call(&"layer", id) == &"ground" else ""])
	root.free()


## Ombre pré-floutée : demi-résolution affichée à l'échelle 2, coin haut gauche à
## « decalage » (pixels de jeu) du milieu du bas de l'image, lui-même à [param image_foot] de
## l'origine de la scène (le massif a son origine ailleurs).
func _shadow(node_name: String, entry: Dictionary, material: String,
		group: StringName, image_foot: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = load(entry["fichier"])
	sprite.centered = false
	var scale := float(entry["echelle"])
	sprite.offset = (Vector2(entry["decalage"][0], entry["decalage"][1]) + image_foot) / scale
	sprite.scale = Vector2(scale, scale)
	sprite.z_as_relative = false
	sprite.z_index = Z_SHADOWS
	sprite.material = load(MATERIALS + material)
	sprite.add_to_group(group, true)
	return sprite


func _add(root: Node, child: Node) -> void:
	root.add_child(child)
	child.owner = root


## « bldg_centre_01 » → « BldgCentre01 ».
static func _scene_name(id: StringName) -> String:
	return String(id).to_pascal_case()
