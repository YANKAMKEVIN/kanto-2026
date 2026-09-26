class_name InteriorTiles
extends RefCounted
## Catalogue des tuiles d'intérieur du TileSet `assets/tiles/interior.tres`.
##
## Calqué sur [OverworldTiles] : mêmes couches de données (`solid`, `tall_grass`,
## `water`, `ledge`, noms pris dans OverworldTiles.DATA_*), si bien que
## [GameMap] lit les deux TileSets sans distinction. Source unique des coordonnées
## d'atlas, partagée par le générateur de tuiles provisoires
## (`tools/gen_placeholder_interior_tiles.gd`), le constructeur des intérieurs
## (`tools/build_interiors.gd`) et les tests.
## Atlas : une rangée par type ([enum Kind]), une colonne par variante.
## Voir docs/tech/jalon-02.md §3.

enum Kind {
	FLOOR_WOOD,
	FLOOR_LAB,
	WALL_HOUSE,
	WALL_LAB,
	STAIRS_UP,
	STAIRS_DOWN,
	MAT,
	RUG,
}

const TEXTURE_PATH: String = "res://assets/tiles/placeholder/interior_atlas.png"
const TILESET_PATH: String = "res://assets/tiles/interior.tres"
const SOURCE_ID: int = 0

## Nombre de variantes par type (colonnes 0..n-1 de sa rangée).
## Murs : variante 0 = partie haute, variante 1 = rangée basse avec plinthe.
const VARIANTS: Dictionary[Kind, int] = {
	Kind.FLOOR_WOOD: 3,
	Kind.FLOOR_LAB: 2,
	Kind.WALL_HOUSE: 2,
	Kind.WALL_LAB: 2,
	Kind.STAIRS_UP: 1,
	Kind.STAIRS_DOWN: 1,
	Kind.MAT: 1,
	Kind.RUG: 2,
}

## Types infranchissables (murs).
const SOLID_KINDS: Array[Kind] = [Kind.WALL_HOUSE, Kind.WALL_LAB]
## Nombre de colonnes de l'atlas (variantes maximum).
const ATLAS_COLUMNS: int = 3
## Variantes de mur.
const WALL_UPPER: int = 0
const WALL_BASEBOARD: int = 1


## Coordonnées d'atlas d'une variante d'un type.
static func atlas_coords(kind: Kind, variant: int) -> Vector2i:
	return Vector2i(clampi(variant, 0, VARIANTS[kind] - 1), kind)


static func variant_count(kind: Kind) -> int:
	return VARIANTS[kind]


static func is_solid_kind(kind: Kind) -> bool:
	return kind in SOLID_KINDS
