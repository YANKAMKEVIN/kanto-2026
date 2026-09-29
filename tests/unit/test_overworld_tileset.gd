extends GutTest
## TileSet overworld : taille 96, 4 couches de données, ≥ 2 variantes par type,
## données conformes au jalon 1 §4.2 (coordonnées d'OverworldTiles) ; hautes herbes du
## jalon 3B (§2.2, T1).

## Rangée d'atlas de chaque type existant avant le jalon 3B : elles ne doivent pas bouger
## (le vrai tileset reprendra ces coordonnées).
const ROWS_BEFORE_3B: Dictionary[StringName, int] = {
	&"GRASS": 0, &"FLOWERS": 1, &"DIRT": 2, &"COBBLE": 3, &"SAND": 4, &"BOARDWALK": 5,
	&"FOREST": 6, &"CLIFF": 7, &"CROP": 8, &"WATER": 9, &"SHALLOW": 10,
}

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
			assert_eq(data.get_custom_data(OverworldTiles.DATA_TALL_GRASS),
				kind == OverworldTiles.Kind.TALL_GRASS, "tall_grass %s" % coords)
			assert_eq(data.get_custom_data(OverworldTiles.DATA_LEDGE),
				OverworldTiles.ledge_of(kind), "ledge %s" % coords)


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


# --- Hautes herbes (jalon 3B, T1) -----------------------------------------------------

func test_tall_grass_kind_is_row_11_with_two_variants() -> void:
	var kind := OverworldTiles.Kind.TALL_GRASS
	assert_eq(kind, 11, "rangée 11 de l'atlas")
	assert_true(OverworldTiles.variant_count(kind) >= 2)
	assert_true(OverworldTiles.is_tall_grass_kind(kind))


func test_tall_grass_tiles_are_walkable_tall_grass_not_water() -> void:
	var kind := OverworldTiles.Kind.TALL_GRASS
	assert_false(OverworldTiles.is_solid_kind(kind))
	assert_false(OverworldTiles.is_water_kind(kind))
	for variant: int in OverworldTiles.variant_count(kind):
		var coords := OverworldTiles.atlas_coords(kind, variant)
		assert_true(_source.has_tile(coords), "tuile %s" % coords)
		var data := _source.get_tile_data(coords, 0)
		assert_true(data.get_custom_data(OverworldTiles.DATA_TALL_GRASS), "tall_grass")
		assert_false(data.get_custom_data(OverworldTiles.DATA_SOLID), "praticable")
		assert_false(data.get_custom_data(OverworldTiles.DATA_WATER), "pas d'eau")
		assert_eq(data.get_custom_data(OverworldTiles.DATA_LEDGE), 0)


func test_other_kinds_are_not_tall_grass() -> void:
	for kind: OverworldTiles.Kind in OverworldTiles.Kind.values():
		if kind == OverworldTiles.Kind.TALL_GRASS:
			continue
		assert_false(OverworldTiles.is_tall_grass_kind(kind), "type %d" % kind)


func test_atlas_rows_of_existing_kinds_did_not_move() -> void:
	for kind_name: StringName in ROWS_BEFORE_3B:
		var row: int = ROWS_BEFORE_3B[kind_name]
		var kind: int = OverworldTiles.Kind[String(kind_name)]
		assert_eq(kind, row, "rangée de %s" % kind_name)
		assert_eq(OverworldTiles.atlas_coords(kind, 0), Vector2i(0, row))
	# TALL_GRASS (3B, rangée 11) et LEDGE_DOWN (jalon 5, rangée 12) ajoutés en fin d'enum.
	assert_eq(OverworldTiles.Kind.size(), ROWS_BEFORE_3B.size() + 2, "deux types ajoutés")


func test_atlas_texture_holds_every_row() -> void:
	var rows := OverworldTiles.Kind.size()
	assert_eq(_source.texture.get_size(),
		Vector2(OverworldTiles.ATLAS_COLUMNS * 96, rows * 96))


# --- Rebord (jalon 5, T0) -------------------------------------------------------------

func test_ledge_down_kind_is_last_row_12_with_two_variants() -> void:
	var kind := OverworldTiles.Kind.LEDGE_DOWN
	assert_eq(kind, OverworldTiles.Kind.size() - 1, "en fin d'enum")
	assert_eq(kind, 12, "rangée 12 de l'atlas")
	assert_true(OverworldTiles.variant_count(kind) >= 2)
	assert_true(OverworldTiles.is_ledge_kind(kind))


func test_ledge_down_tiles_are_walkable_with_ledge_data_down() -> void:
	var kind := OverworldTiles.Kind.LEDGE_DOWN
	assert_false(OverworldTiles.is_solid_kind(kind), "praticable (le saut décide)")
	assert_false(OverworldTiles.is_water_kind(kind))
	assert_false(OverworldTiles.is_tall_grass_kind(kind))
	assert_eq(OverworldTiles.ledge_of(kind), int(GridWorld.Ledge.DOWN))
	for variant: int in OverworldTiles.variant_count(kind):
		var coords := OverworldTiles.atlas_coords(kind, variant)
		assert_true(_source.has_tile(coords), "tuile %s" % coords)
		var data := _source.get_tile_data(coords, 0)
		assert_eq(data.get_custom_data(OverworldTiles.DATA_LEDGE),
			int(GridWorld.Ledge.DOWN), "ledge bas")
		assert_false(data.get_custom_data(OverworldTiles.DATA_SOLID), "non solide")


func test_other_kinds_have_no_ledge_data() -> void:
	for kind: OverworldTiles.Kind in OverworldTiles.Kind.values():
		if kind == OverworldTiles.Kind.LEDGE_DOWN:
			continue
		assert_false(OverworldTiles.is_ledge_kind(kind), "type %d" % kind)
		assert_eq(OverworldTiles.ledge_of(kind), int(GridWorld.Ledge.NONE), "type %d" % kind)
