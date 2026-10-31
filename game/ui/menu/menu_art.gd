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
## - Aperçu d'une zone (MM.2) : [method zone_preview], capture floutée de sa carte peinte
##   (`tools/build_zone_previews.gd`) ; null si la zone n'en a pas (l'écran recadre alors
##   l'illustration de Kanto : [method zone_crop]).
## Chargées à la demande, puis gardées (une seule copie partagée par tous les écrans).

const CARD_DIR := "res://assets/ui/menu/cards/"
const HERO_BUST_PATH := "res://assets/ui/menu/hero_bust.webp"
const ITEM_DIR := "res://assets/ui/items/"
const ZONE_DIR := "res://assets/ui/map/zones/"
## Rapport des aperçus de zones (et des recadrages de l'illustration qui les remplacent).
const ZONE_ASPECT := 16.0 / 9.0
## Un recadrage de l'illustration couvre au moins ce côté (pixels de l'image) autour de la zone.
const ZONE_CROP_MIN_HEIGHT := 220.0
const EXTENSION := ".webp"

static var _cache: Dictionary[String, Texture2D] = {}


## « res://assets/ui/menu/cards/team.webp » pour [param screen] ([constant MenuRoute.TEAM]…).
static func card_path(screen: StringName) -> String:
	return CARD_DIR + String(screen) + EXTENSION


## Illustration de la carte de [param screen] ; null si elle n'existe pas.
static func card_illustration(screen: StringName) -> Texture2D:
	return _load(card_path(screen))


## Apparence du joueur pour le buste (chantier JR) : posée par [MenuDirector] à l'ouverture du
## menu (l'UI ne lit pas l'état de la partie).
static var player_look: StringName = &"hero"


## Buste du joueur selon [member player_look] (héros ou joueuse, [TrainerLooks]).
static func hero_bust() -> Texture2D:
	return bust_for(player_look)


static func bust_for(look: StringName) -> Texture2D:
	return _load(TrainerLooks.bust_path(look))


static func item_icon_path(item_id: StringName) -> String:
	return ITEM_DIR + String(item_id) + EXTENSION


## Icône peinte de [param item_id] ; null si l'objet n'en a pas (l'écran garde son icône).
static func item_icon(item_id: StringName) -> Texture2D:
	return _load(item_icon_path(item_id))


static func zone_preview_path(zone_id: StringName) -> String:
	return ZONE_DIR + String(zone_id) + EXTENSION


## Aperçu peint de [param zone_id] (16:9) ; null si la zone n'en a pas encore.
static func zone_preview(zone_id: StringName) -> Texture2D:
	return _load(zone_preview_path(zone_id))


## Image partagée de [param path] (illustration de Kanto…), null si absente.
static func texture(path: String) -> Texture2D:
	return _load(path) if not path.is_empty() else null


## Région (pixels de l'image, rapport ZONE_ASPECT) de l'illustration de taille [param image_size]
## qui entoure le rectangle [param area] d'une zone, centrée sur lui et gardée dans l'image ;
## vide si l'aire est vide.
static func zone_crop(area: Rect2, image_size: Vector2) -> Rect2:
	if not area.has_area() or image_size.x <= 0.0 or image_size.y <= 0.0:
		return Rect2()
	var height := maxf(maxf(area.size.y, area.size.x / ZONE_ASPECT) * 1.6, ZONE_CROP_MIN_HEIGHT)
	var wanted := Vector2(height * ZONE_ASPECT, height)
	if wanted.x > image_size.x:
		wanted *= image_size.x / wanted.x
	if wanted.y > image_size.y:
		wanted *= image_size.y / wanted.y
	var origin := area.get_center() - wanted * 0.5
	origin.x = clampf(origin.x, 0.0, image_size.x - wanted.x)
	origin.y = clampf(origin.y, 0.0, image_size.y - wanted.y)
	return Rect2(origin, wanted)


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
