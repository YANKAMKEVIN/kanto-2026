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
## - les autres : aucun.

const DASHBOARD: StringName = &"dashboard"
const TEAM: StringName = &"team"
const BAG: StringName = &"bag"
const POKEDEX: StringName = &"pokedex"
const MAP: StringName = &"map"
const TRAINER: StringName = &"trainer"
const SETTINGS: StringName = &"settings"
## Ordre des cartes du tableau de bord (dossier 08 §1) ; [MenuUnlocks] retire les absentes.
const DASHBOARD_ORDER: Array[StringName] = [TEAM, POKEDEX, BAG, MAP, TRAINER, SETTINGS]
## Tous les écrans connus.
const SCREENS: Array[StringName] = [DASHBOARD, TEAM, POKEDEX, BAG, MAP, TRAINER, SETTINGS]

## Contextes du Sac (jalon-06.md §3.4). [code]BagQuery[/code] (T10) reprend ces valeurs.
const BAG_CONTEXT_FIELD: StringName = &"field"
const BAG_CONTEXT_TEAM: StringName = &"team"
## Filtres de la grille du Pokédex : valeurs de [code]PokedexQuery.Filter[/code] (T14), dans
## cet ordre (ALL, SEEN, CAUGHT, HABITAT).
const DEX_FILTER_ALL: int = 0
const DEX_FILTER_SEEN: int = 1
const DEX_FILTER_CAUGHT: int = 2
const DEX_FILTER_HABITAT: int = 3

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


## Route par défaut de l'écran [param screen_id] (carte du tableau de bord), ou null si
## l'écran est inconnu.
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
