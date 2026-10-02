class_name OverworldTiles
extends RefCounted
## Catalogue des tuiles de sol du TileSet `assets/tiles/overworld.tres`.
##
## Source unique des coordonnées d'atlas et des données de tuile : utilisée par le
## générateur de tuiles provisoires (`tools/gen_placeholder_tiles.gd`), par le
## constructeur de cartes (`tools/build_pallet_town.gd`) et par les tests.
## Atlas : une rangée par type ([enum Kind]), une colonne par variante.
## Le vrai tileset devra garder ces coordonnées et ces données : seules les
## textures changent, pas les cartes.

enum Kind {
	GRASS,
	FLOWERS,
	DIRT,
	COBBLE,
	SAND,
	BOARDWALK,
	FOREST,
	CLIFF,
	CROP,
	WATER,
	SHALLOW,
	## Hautes herbes (jalon 3B) : ajoutées en fin d'enum pour ne déplacer aucune rangée.
	TALL_GRASS,
	## Rebord sautable vers le sud (jalon 5, raccourci de retour). Praticable (non solide),
	## donnée `ledge` = bas ([constant GridWorld.Ledge.DOWN]) ; en fin d'enum.
	LEDGE_DOWN,
}

const TEXTURE_PATH: String = "res://assets/tiles/placeholder/overworld_atlas.png"
const TILESET_PATH: String = "res://assets/tiles/overworld.tres"
const SOURCE_ID: int = 0

## Noms des couches de données personnalisées, dans l'ordre du TileSet.
const DATA_SOLID: StringName = &"solid"
const DATA_TALL_GRASS: StringName = &"tall_grass"
const DATA_WATER: StringName = &"water"
const DATA_LEDGE: StringName = &"ledge"

## Nombre de variantes par type (colonnes 0..n-1 de sa rangée).
const VARIANTS: Dictionary[Kind, int] = {
	Kind.GRASS: 4,
	Kind.FLOWERS: 3,
	Kind.DIRT: 3,
	Kind.COBBLE: 3,
	Kind.SAND: 3,
	Kind.BOARDWALK: 2,
	Kind.FOREST: 3,
	Kind.CLIFF: 2,
	Kind.CROP: 2,
	Kind.WATER: 3,
	Kind.SHALLOW: 2,
	Kind.TALL_GRASS: 2,
	Kind.LEDGE_DOWN: 2,
}

## Types infranchissables (sol de forêt, falaise, culture).
const SOLID_KINDS: Array[Kind] = [Kind.FOREST, Kind.CLIFF, Kind.CROP]
## Types d'eau (infranchissables à pied, Surf plus tard).
const WATER_KINDS: Array[Kind] = [Kind.WATER, Kind.SHALLOW]
## Types de hautes herbes (praticables, donnée `tall_grass` ; rencontres au jalon 5).
const TALL_GRASS_KINDS: Array[Kind] = [Kind.TALL_GRASS]
## Direction de rebord par type (donnée `ledge`, valeurs de [enum GridWorld.Ledge] : 1 = bas).
## Les autres types valent 0 (aucun rebord).
const LEDGE_KINDS: Dictionary[Kind, int] = {
	Kind.LEDGE_DOWN: GridWorld.Ledge.DOWN,
}
## Nombre de colonnes de l'atlas (variantes maximum).
const ATLAS_COLUMNS: int = 4


## Coordonnées d'atlas d'une variante d'un type.
static func atlas_coords(kind: Kind, variant: int) -> Vector2i:
	return Vector2i(clampi(variant, 0, VARIANTS[kind] - 1), kind)


static func variant_count(kind: Kind) -> int:
	return VARIANTS[kind]


static func is_solid_kind(kind: Kind) -> bool:
	return kind in SOLID_KINDS


static func is_water_kind(kind: Kind) -> bool:
	return kind in WATER_KINDS


static func is_tall_grass_kind(kind: Kind) -> bool:
	return kind in TALL_GRASS_KINDS


## Donnée `ledge` d'un type (valeur de [enum GridWorld.Ledge] : 0 aucun, 1 bas, 2 gauche,
## 3 droite).
static func ledge_of(kind: Kind) -> int:
	return LEDGE_KINDS.get(kind, GridWorld.Ledge.NONE)


static func is_ledge_kind(kind: Kind) -> bool:
	return LEDGE_KINDS.has(kind)
