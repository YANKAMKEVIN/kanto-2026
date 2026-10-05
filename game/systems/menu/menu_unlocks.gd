class_name MenuUnlocks
extends RefCounted
## Ce qui existe pour le joueur dans le Menu Dresseur (règle de déblocage de vision.md ;
## dossier 08 §1 et §4 ; jalon-06.md §4).
##
## Lit l'état à chaque appel (drapeaux, équipe), ne le modifie jamais. Un écran indisponible
## est **absent**, jamais grisé (dossier 08 règle 8). Le drapeau de débogage
## [member debug_pokedex] n'est PAS un drapeau d'histoire : il ne pose jamais
## [constant StoryFlags.POKEDEX_ACTIVATED] et n'est pas sauvegardé.

## Débloque l'écran Pokédex pour développer et tester le J6 ([DebugUnlocks], build debug).
var debug_pokedex: bool = false

var _flags: StoryFlags
var _party: Party


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


## Vrai si l'écran [param screen] existe pour le joueur (un écran inconnu n'existe pas).
func is_available(screen: StringName) -> bool:
	match screen:
		MenuRoute.TEAM:
			return team_visible()
		MenuRoute.POKEDEX:
			return pokedex_visible()
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
