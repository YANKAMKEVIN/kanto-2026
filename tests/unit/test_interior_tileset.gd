extends GutTest
## TileSet d'intérieur (jalon 2 §3) : tuiles 96×96, mêmes couches de données
## qu'overworld.tres (même ordre), variantes et donnée `solid` de chaque type.

const EXPECTED_VARIANTS: Dictionary = {
	InteriorTiles.Kind.FLOOR_WOOD: 3,
	InteriorTiles.Kind.FLOOR_LAB: 2,
	InteriorTiles.Kind.WALL_HOUSE: 2,
	InteriorTiles.Kind.WALL_LAB: 2,
	InteriorTiles.Kind.STAIRS_UP: 1,
	InteriorTiles.Kind.STAIRS_DOWN: 1,
	InteriorTiles.Kind.MAT: 1,
	InteriorTiles.Kind.RUG: 2,
}
const SOLID: Array = [InteriorTiles.Kind.WALL_HOUSE, InteriorTiles.Kind.WALL_LAB]

var _tileset: TileSet
var _source: TileSetAtlasSource


func before_all() -> void:
	_tileset = load(InteriorTiles.TILESET_PATH) as TileSet
	_source = _tileset.get_source(InteriorTiles.SOURCE_ID) as TileSetAtlasSource


func test_tileset_loads_with_atlas_source() -> void:
	assert_not_null(_tileset)
	assert_not_null(_source)
	assert_not_null(_source.texture)
	assert_eq(_source.texture.resource_path, InteriorTiles.TEXTURE_PATH)


func test_tile_size_is_96() -> void:
	assert_eq(_tileset.tile_size, Vector2i(Grid.TILE_SIZE, Grid.TILE_SIZE))
	assert_eq(_source.texture_region_size, Vector2i(96, 96))


func test_same_data_layers_as_overworld_in_same_order() -> void:
	var overworld := load(OverworldTiles.TILESET_PATH) as TileSet
	assert_eq(_tileset.get_custom_data_layers_count(), 4)
	assert_eq(_tileset.get_custom_data_layers_count(), overworld.get_custom_data_layers_count())
	for i: int in overworld.get_custom_data_layers_count():
		assert_eq(_tileset.get_custom_data_layer_name(i), overworld.get_custom_data_layer_name(i))
		assert_eq(_tileset.get_custom_data_layer_type(i), overworld.get_custom_data_layer_type(i))
	assert_eq(_tileset.get_custom_data_layer_by_name(OverworldTiles.DATA_SOLID), 0)
	assert_eq(_tileset.get_custom_data_layer_by_name(OverworldTiles.DATA_LEDGE), 3)


func test_every_kind_has_planned_variants() -> void:
	assert_eq(InteriorTiles.Kind.size(), EXPECTED_VARIANTS.size())
	for kind: InteriorTiles.Kind in InteriorTiles.Kind.values():
		assert_eq(InteriorTiles.variant_count(kind), EXPECTED_VARIANTS[kind], "variantes %d" % kind)
		for variant: int in InteriorTiles.variant_count(kind):
			var coords := InteriorTiles.atlas_coords(kind, variant)
			assert_true(_source.has_tile(coords), "tuile %s" % coords)
		var extra := Vector2i(InteriorTiles.variant_count(kind), kind)
		assert_false(_source.has_tile(extra), "pas de variante en trop %s" % extra)


func test_tile_data_matches_plan() -> void:
	for kind: InteriorTiles.Kind in InteriorTiles.Kind.values():
		assert_eq(InteriorTiles.is_solid_kind(kind), kind in SOLID)
		for variant: int in InteriorTiles.variant_count(kind):
			var coords := InteriorTiles.atlas_coords(kind, variant)
			var data := _source.get_tile_data(coords, 0)
			assert_eq(data.get_custom_data(OverworldTiles.DATA_SOLID), kind in SOLID,
				"solid %s" % coords)
			assert_false(data.get_custom_data(OverworldTiles.DATA_WATER))
			assert_false(data.get_custom_data(OverworldTiles.DATA_TALL_GRASS))
			assert_eq(data.get_custom_data(OverworldTiles.DATA_LEDGE), 0)


func test_atlas_coords_row_is_kind_column_is_variant() -> void:
	assert_eq(InteriorTiles.atlas_coords(InteriorTiles.Kind.FLOOR_WOOD, 2), Vector2i(2, 0))
	assert_eq(InteriorTiles.atlas_coords(InteriorTiles.Kind.RUG, 1), Vector2i(1, 7))
	assert_eq(InteriorTiles.atlas_coords(InteriorTiles.Kind.MAT, 3), Vector2i(0, 6))
