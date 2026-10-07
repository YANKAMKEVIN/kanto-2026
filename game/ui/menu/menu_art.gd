class_name MenuArt
extends RefCounted
## Images peintes du Menu Dresseur (MM.1, docs/tech/menu-maquettes.md) : **seul** endroit qui
## connaît leurs chemins. Les fichiers sont préparés par `tools/art/preparer_menu.py` (noms
## stables) ; les Pokémon restent les artworks officiels de [PokedexArt].
## - Illustration d'une carte du tableau de bord : [method card_illustration] (par écran).
## - Portrait peint du héros en buste : [method hero_bust].
## - Icône peinte d'un objet : [method item_icon] (null si l'objet n'en a pas encore).
## - Pokémon : [method pokemon_thumbnail] (vignette 128 de l'atlas) et [method pokemon_portrait]
##   (grand artwork resserré), par numéro du Pokédex ; null pour 0 (numéro inconnu).
## Chargées à la demande, puis gardées (une seule copie partagée par tous les écrans).

const CARD_DIR := "res://assets/ui/menu/cards/"
const HERO_BUST_PATH := "res://assets/ui/menu/hero_bust.webp"
const ITEM_DIR := "res://assets/ui/items/"
const EXTENSION := ".webp"

static var _cache: Dictionary[String, Texture2D] = {}


## « res://assets/ui/menu/cards/team.webp » pour [param screen] ([constant MenuRoute.TEAM]…).
static func card_path(screen: StringName) -> String:
	return CARD_DIR + String(screen) + EXTENSION


## Illustration de la carte de [param screen] ; null si elle n'existe pas.
static func card_illustration(screen: StringName) -> Texture2D:
	return _load(card_path(screen))


static func hero_bust() -> Texture2D:
	return _load(HERO_BUST_PATH)


static func item_icon_path(item_id: StringName) -> String:
	return ITEM_DIR + String(item_id) + EXTENSION


## Icône peinte de [param item_id] ; null si l'objet n'en a pas (l'écran garde son icône).
static func item_icon(item_id: StringName) -> Texture2D:
	return _load(item_icon_path(item_id))


## Vignette 128 px de l'artwork n° [param number] (même objet à chaque appel) ; null pour 0.
static func pokemon_thumbnail(number: int) -> Texture2D:
	return PokedexArt.thumbnail(number)


## Grand artwork n° [param number], resserré sur son cadre utile ; null pour 0.
static func pokemon_portrait(number: int) -> Texture2D:
	return PokedexArt.portrait(number)


static func _load(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	_cache[path] = texture
	return texture
