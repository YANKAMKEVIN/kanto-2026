extends GutTest
## TileSet overworld : taille 96, 4 couches de données, ≥ 2 variantes par type,
## données conformes au jalon 1 §4.2 (coordonnées d'OverworldTiles).

var _tileset: TileSet
var _source: TileSetAtlasSource


func before_all() -> void:
	_tileset = load(OverworldTiles.TILESET_PATH) as TileSet
	_source = _tileset.get_source(OverworldTiles.SOURCE_ID) as TileSetAtlasSource


func test_tileset_loads_with_atlas_source() -> void:
	assert_not_null(_tileset)
	assert_not_null(_source)
	assert_not_null(_source.texture)


func test_tile_size_is_96() -> void:
	assert_eq(_tileset.tile_size, Vector2i(Grid.TILE_SIZE, Grid.TILE_SIZE))
	assert_eq(_source.texture_region_size, Vector2i(96, 96))


func test_four_custom_data_layers() -> void:
	assert_eq(_tileset.get_custom_data_layers_count(), 4)
	var expected := {
		OverworldTiles.DATA_SOLID: TYPE_BOOL,
		OverworldTiles.DATA_TALL_GRASS: TYPE_BOOL,
		OverworldTiles.DATA_WATER: TYPE_BOOL,
		OverworldTiles.DATA_LEDGE: TYPE_INT,
	}
	for layer_name: StringName in expected:
		var index := _tileset.get_custom_data_layer_by_name(layer_name)
		assert_true(index >= 0, "couche %s présente" % layer_name)
		assert_eq(_tileset.get_custom_data_layer_type(index), expected[layer_name])


func test_every_kind_has_at_least_two_variants() -> void:
	for kind: OverworldTiles.Kind in OverworldTiles.Kind.values():
		assert_true(OverworldTiles.variant_count(kind) >= 2, "variantes de %d" % kind)
		for variant: int in OverworldTiles.variant_count(kind):
			var coords := OverworldTiles.atlas_coords(kind, variant)
			assert_true(_source.has_tile(coords), "tuile %s" % coords)


func test_tile_data_matches_plan() -> void:
	var solid_kinds := [
		OverworldTiles.Kind.FOREST, OverworldTiles.Kind.CLIFF, OverworldTiles.Kind.CROP,
	]
	var water_kinds := [OverworldTiles.Kind.WATER, OverworldTiles.Kind.SHALLOW]
	for kind: OverworldTiles.Kind in OverworldTiles.Kind.values():
		for variant: int in OverworldTiles.variant_count(kind):
			var coords := OverworldTiles.atlas_coords(kind, variant)
			var data := _source.get_tile_data(coords, 0)
			assert_eq(data.get_custom_data(OverworldTiles.DATA_SOLID), kind in solid_kinds,
				"solid %s" % coords)
			assert_eq(data.get_custom_data(OverworldTiles.DATA_WATER), kind in water_kinds,
				"water %s" % coords)
			assert_false(data.get_custom_data(OverworldTiles.DATA_TALL_GRASS))
			assert_eq(data.get_custom_data(OverworldTiles.DATA_LEDGE), 0)


func test_walkable_kinds_of_plan() -> void:
	var walkable := [
		OverworldTiles.Kind.GRASS, OverworldTiles.Kind.FLOWERS, OverworldTiles.Kind.DIRT,
		OverworldTiles.Kind.COBBLE, OverworldTiles.Kind.SAND, OverworldTiles.Kind.BOARDWALK,
	]
	for kind: OverworldTiles.Kind in walkable:
		assert_false(OverworldTiles.is_solid_kind(kind))
		assert_false(OverworldTiles.is_water_kind(kind))


func test_atlas_coords_row_is_kind_column_is_variant() -> void:
	assert_eq(OverworldTiles.atlas_coords(OverworldTiles.Kind.GRASS, 3), Vector2i(3, 0))
	assert_eq(OverworldTiles.atlas_coords(OverworldTiles.Kind.WATER, 1), Vector2i(1, 9))
	# Variante hors plage : ramenée dans la plage.
	assert_eq(OverworldTiles.atlas_coords(OverworldTiles.Kind.CLIFF, 5), Vector2i(1, 7))
