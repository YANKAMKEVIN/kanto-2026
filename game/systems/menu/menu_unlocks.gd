class_name MenuUnlocks
extends RefCounted
## Ce qui existe pour le joueur dans le Menu Dresseur (règle de déblocage de vision.md ;
## dossier 08 §1 et §4 ; jalon-06.md §4).
##
## Lit l'état à chaque appel (drapeaux, équipe), ne le modifie jamais. Un écran indisponible
## est **absent**, jamais grisé (dossier 08 règle 8). Le drapeau de débogage
## [member debug_pokedex] n'est PAS un drapeau d'histoire : il ne pose jamais
## [constant StoryFlags.POKEDEX_ACTIVATED] et n'est pas sauvegardé.
##
## Stockage (J7A, dossier 09 §8) : **seulement au Centre**. Le lieu se branche par
## [method set_location] (Boot, T16) ; sans lui, le Stockage n'existe nulle part.

## Service de [code]zones.json[/code] qui porte le Stockage : le Centre Pokémon.
const STORAGE_SERVICE: StringName = &"pokemon_center"

## Débloque l'écran Pokédex pour développer et tester le J6 ([DebugUnlocks], build debug).
var debug_pokedex: bool = false

var _flags: StoryFlags
var _party: Party
var _zones: ZoneLibrary
var _current_map: Callable


func _init(flags: StoryFlags = null, party: Party = null) -> void:
	_flags = flags
	_party = party


## Vrai si le Pokédex a été activé par Chen (J7A), ou par le drapeau de débogage.
func pokedex_visible() -> bool:
	if debug_pokedex:
		return true
	return _flags != null and _flags.has_flag(StoryFlags.POKEDEX_ACTIVATED)


## Vrai dès que l'équipe compte un Pokémon (Q-2 : avant le starter, ni carte ÉQUIPE ni
## Pokémon de tête).
func team_visible() -> bool:
	return _party != null and _party.size() > 0


## Branche le lieu du joueur : [param zones] (services) et [param current_map]
## ([code]func() -> StringName[/code], la carte où se tient le joueur, lue à chaque appel).
func set_location(zones: ZoneLibrary, current_map: Callable) -> void:
	_zones = zones
	_current_map = current_map


## Vrai si le joueur est dans un Centre Pokémon ([method is_storage_map] sur la carte
## courante) : l'écran Stockage et le bouton STOCKAGE de l'Équipe n'existent que là.
func storage_available() -> bool:
	if _zones == null or not _current_map.is_valid():
		return false
	return is_storage_map(StringName(_current_map.call()), _zones)


## Vrai si [param map] est la carte [code]found_on[/code] d'un service
## [constant STORAGE_SERVICE] de [param zones] (l'intérieur d'un Centre). Aucun Stockage
## ailleurs, pas même dans la ville du Centre.
static func is_storage_map(map: StringName, zones: ZoneLibrary) -> bool:
	if map.is_empty() or zones == null:
		return false
	for zone_id: StringName in zones.get_ids():
		for service: ZoneService in zones.get_zone(zone_id).services:
			if service.id == STORAGE_SERVICE and service.found_on == map:
				return true
	return false


## Vrai si l'écran [param screen] existe pour le joueur (un écran inconnu n'existe pas).
func is_available(screen: StringName) -> bool:
	match screen:
		MenuRoute.TEAM:
			return team_visible()
		MenuRoute.POKEDEX:
			return pokedex_visible()
		MenuRoute.STORAGE:
			return team_visible() and storage_available()
		MenuRoute.DASHBOARD, MenuRoute.BAG, MenuRoute.MAP, MenuRoute.TRAINER, \
				MenuRoute.SETTINGS:
			return true
		MenuRoute.SHOP:
			# Écran seul, ouvert par le marchand ; jamais une carte (absent de DASHBOARD_ORDER).
			return true
	return false


## Cartes du tableau de bord, dans l'ordre de [constant MenuRoute.DASHBOARD_ORDER], sans
## les écrans indisponibles.
func dashboard_cards() -> Array[StringName]:
	var cards: Array[StringName] = []
	for screen: StringName in MenuRoute.DASHBOARD_ORDER:
		if is_available(screen):
			cards.append(screen)
	return cards
