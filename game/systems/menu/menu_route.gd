class_name MenuRoute
extends RefCounted
## Un écran du Menu Dresseur et ses paramètres (dossier 08 §8, jalon-06.md §3.2). Donnée pure.
##
## Les écrans ne se désignent que par ces routes : le tableau de bord, les liens croisés et le
## retour passent tous par [MenuNavigator]. Paramètres par écran (clés de [member params]) :
## - [constant TEAM] : « index » (int, Pokémon sélectionné, 0 = tête) ;
## - [constant BAG] : « context » (StringName, [constant BAG_CONTEXT_FIELD]…), « target »
##   (int, Pokémon de l'équipe visé depuis la fiche Équipe, −1 = aucun) ;
## - [constant POKEDEX] : « filter » (int, [constant DEX_FILTER_ALL]…), « species »
##   (StringName, fiche à ouvrir, &"" = la grille) ;
## - [constant MAP] : « zone » (StringName, zone à montrer, &"" = celle du joueur) ;
## - [constant SHOP] : « shop » (StringName, boutique de `data/shops/`), « mode »
##   (StringName, onglet d'ouverture : [constant SHOP_MODE_BUY] ou [constant SHOP_MODE_SELL]) ;
## - les autres : aucun.
## Les écrans de [constant STANDALONE_SCREENS] (la Boutique, jalon-07.md §3.4) ne sont jamais
## une carte du tableau de bord ni la cible d'un lien : ils s'ouvrent **seuls**
## ([method MenuNavigator.open] avec [code]standalone[/code]), retour = fermer.

const DASHBOARD: StringName = &"dashboard"
const TEAM: StringName = &"team"
const BAG: StringName = &"bag"
const POKEDEX: StringName = &"pokedex"
const MAP: StringName = &"map"
const TRAINER: StringName = &"trainer"
const SETTINGS: StringName = &"settings"
## Boutique (jalon-07.md §3.4, §6.4) : écran seul, ouvert par le marchand.
const SHOP: StringName = &"shop"
## Ordre des cartes du tableau de bord (dossier 08 §1) ; [MenuUnlocks] retire les absentes.
const DASHBOARD_ORDER: Array[StringName] = [TEAM, POKEDEX, BAG, MAP, TRAINER, SETTINGS]
## Écrans du menu : le tableau de bord et ses cartes (chacun a une route par défaut,
## [method for_screen]).
const SCREENS: Array[StringName] = [DASHBOARD, TEAM, POKEDEX, BAG, MAP, TRAINER, SETTINGS]
## Écrans qui ne s'ouvrent que seuls, jamais par une carte ni un lien (pas de route par défaut).
const STANDALONE_SCREENS: Array[StringName] = [SHOP]

## Contextes du Sac (jalon-06.md §3.4). [code]BagQuery[/code] (T10) reprend ces valeurs.
const BAG_CONTEXT_FIELD: StringName = &"field"
const BAG_CONTEXT_TEAM: StringName = &"team"
## Filtres de la grille du Pokédex : valeurs de [code]PokedexQuery.Filter[/code] (T14), dans
## cet ordre (ALL, SEEN, CAUGHT, HABITAT).
const DEX_FILTER_ALL: int = 0
const DEX_FILTER_SEEN: int = 1
const DEX_FILTER_CAUGHT: int = 2
const DEX_FILTER_HABITAT: int = 3
## Onglets de la Boutique : mêmes valeurs que [constant ShopViews.MODE_BUY] et
## [constant ShopViews.MODE_SELL].
const SHOP_MODE_BUY: StringName = &"buy"
const SHOP_MODE_SELL: StringName = &"sell"

var screen: StringName = DASHBOARD
var params: Dictionary = {}


func _init(screen_id: StringName = DASHBOARD, route_params: Dictionary = {}) -> void:
	screen = screen_id
	params = route_params.duplicate()


static func dashboard() -> MenuRoute:
	return MenuRoute.new(DASHBOARD)


static func team(index: int = 0) -> MenuRoute:
	return MenuRoute.new(TEAM, {"index": index})


static func bag(context: StringName = BAG_CONTEXT_FIELD, target: int = -1) -> MenuRoute:
	return MenuRoute.new(BAG, {"context": context, "target": target})


static func pokedex(filter: int = DEX_FILTER_ALL, species: StringName = &"") -> MenuRoute:
	return MenuRoute.new(POKEDEX, {"filter": filter, "species": species})


static func map(zone: StringName = &"") -> MenuRoute:
	return MenuRoute.new(MAP, {"zone": zone})


static func trainer() -> MenuRoute:
	return MenuRoute.new(TRAINER)


static func settings() -> MenuRoute:
	return MenuRoute.new(SETTINGS)


## La boutique [param shop_id], ouverte sur l'onglet [param mode] (ACHETER par défaut).
static func shop(shop_id: StringName, mode: StringName = SHOP_MODE_BUY) -> MenuRoute:
	return MenuRoute.new(SHOP, {"shop": shop_id, "mode": mode})


## Vrai si l'écran [param screen_id] ne s'ouvre que seul ([constant STANDALONE_SCREENS]).
static func is_standalone_screen(screen_id: StringName) -> bool:
	return STANDALONE_SCREENS.has(screen_id)


## Route par défaut de l'écran [param screen_id] (carte du tableau de bord), ou null si
## l'écran est inconnu ou ne s'ouvre que seul (la Boutique demande son identifiant).
static func for_screen(screen_id: StringName) -> MenuRoute:
	match screen_id:
		DASHBOARD:
			return dashboard()
		TEAM:
			return team()
		BAG:
			return bag()
		POKEDEX:
			return pokedex()
		MAP:
			return map()
		TRAINER:
			return trainer()
		SETTINGS:
			return settings()
	return null


## Paramètre [param key] ([param default] s'il manque).
func get_param(key: String, default: Variant = null) -> Variant:
	return params.get(key, default)


## Même écran et mêmes paramètres.
func equals(other: MenuRoute) -> bool:
	return other != null and other.screen == screen and other.params == params


func duplicate_route() -> MenuRoute:
	return MenuRoute.new(screen, params)


func _to_string() -> String:
	return "%s%s" % [screen, params if not params.is_empty() else ""]
