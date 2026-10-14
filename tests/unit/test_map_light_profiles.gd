extends GutTest
## Profils de lumière prévus par carte (`data/world/lighting.json`, section « maps » ;
## integration-da-bourg-route1.md, DA.0) : chaque carte prévue existe, et une carte qui a déjà
## un profil a celui du plan. Les cartes du chantier DA (Bourg Palette, ses intérieurs,
## Route 1) n'en ont pas encore : leur outil de construction l'écrira (DA.1 à DA.3).

const MAPS_DIR := "res://game/world/maps/"

var _library := LightingLibrary.new()


func before_all() -> void:
	_library.load_file()


## `light_profile` de la racine de la scène, sans l'instancier (&"" s'il n'est pas écrit).
func _scene_profile(path: String) -> StringName:
	var state := (load(path) as PackedScene).get_state()
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == &"light_profile":
			return StringName(state.get_node_property_value(0, i))
	return &""


func test_every_planned_map_exists_and_matches_when_painted() -> void:
	assert_gte(_library.get_planned_maps().size(), 10)
	for map_id: StringName in _library.get_planned_maps():
		var path := MapCatalog.scene_path(map_id)
		assert_true(ResourceLoader.exists(path), "%s existe" % map_id)
		if not ResourceLoader.exists(path):
			continue
		var current := _scene_profile(path)
		if not current.is_empty():
			assert_eq(current, _library.get_map_profile(map_id), "%s : profil du plan" % map_id)


func test_every_lit_map_is_planned() -> void:
	for file: String in DirAccess.get_files_at(MAPS_DIR):
		if not file.ends_with(".tscn"):
			continue
		var map_id := StringName(file.get_basename())
		if MapCatalog.is_qa_map(map_id):
			continue
		var current := _scene_profile(MAPS_DIR + file)
		if current.is_empty():
			continue
		assert_eq(_library.get_map_profile(map_id), current, "%s est au plan" % map_id)
