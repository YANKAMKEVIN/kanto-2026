class_name MenuNavigator
extends RefCounted
## Pile d'écrans du Menu Dresseur : ouverture, fermeture, liens croisés, retour (dossier 08
## §1 et §8, jalon-06.md §3.2). Classe pure : elle ne connaît aucun nœud.
##
## Le tableau de bord est toujours au fond de la pile. [method back] remonte d'un niveau ;
## depuis le tableau de bord, il ferme le menu (retour Android, ×, Échap : Q-3). Un écran
## déjà présent dans la pile n'est jamais empilé une seconde fois : on y revient en coupant
## la pile au-dessus (pas de boucle Pokédex → Carte → Pokédex qui s'empile). La pile compte
## [constant MAX_DEPTH] écrans au plus (jalon-06.md §13) : au-delà, le nouvel écran remplace
## celui du dessus.

## Le menu vient de s'ouvrir sur [param route].
signal opened(route: MenuRoute)
## L'écran affiché (ou ses paramètres) a changé, menu ouvert.
signal route_changed(route: MenuRoute)
## Le menu vient de se fermer.
signal closed

## Profondeur maximale de la pile, tableau de bord compris.
const MAX_DEPTH: int = 4

var _unlocks: MenuUnlocks
var _stack: Array[MenuRoute] = []


func _init(unlocks: MenuUnlocks) -> void:
	_unlocks = unlocks


## Ouvre le menu sur [param route] (tableau de bord si null), posé au-dessus du tableau de
## bord. Une route indisponible ouvre le tableau de bord. Faux si le menu est déjà ouvert.
func open(route: MenuRoute = null) -> bool:
	if is_open():
		return false
	_stack.append(MenuRoute.dashboard())
	if route != null and route.screen != MenuRoute.DASHBOARD and _is_allowed(route):
		_stack.append(route.duplicate_route())
	opened.emit(current())
	return true


## Ferme le menu (sans effet s'il est fermé).
func close() -> void:
	if not is_open():
		return
	_stack.clear()
	closed.emit()


func is_open() -> bool:
	return not _stack.is_empty()


## Écran affiché (copie), ou null si le menu est fermé.
func current() -> MenuRoute:
	return _stack.back().duplicate_route() if is_open() else null


## Nombre d'écrans dans la pile (0 = fermé, 1 = tableau de bord seul).
func depth() -> int:
	return _stack.size()


## Écrans de la pile, du fond vers le dessus (copie, journaux et tests).
func get_screens() -> Array[StringName]:
	var screens: Array[StringName] = []
	for route: MenuRoute in _stack:
		screens.append(route.screen)
	return screens


## Va vers [param route] (carte du tableau de bord ou lien croisé). Faux, et rien ne change,
## si le menu est fermé ou si l'écran est indisponible (Pokédex non activé, équipe vide).
## Un écran déjà dans la pile : on y revient (pile coupée au-dessus) et ses paramètres sont
## remplacés. [signal route_changed] n'est émis que si l'écran affiché change.
func go(route: MenuRoute) -> bool:
	if not is_open() or route == null or not _is_allowed(route):
		return false
	var before := _stack.back() as MenuRoute
	var index := _index_of(route.screen)
	if index >= 0:
		_stack.resize(index + 1)
		_stack[index] = route.duplicate_route()
	elif _stack.size() >= MAX_DEPTH:
		_stack[_stack.size() - 1] = route.duplicate_route()
	else:
		_stack.append(route.duplicate_route())
	if not before.equals(_stack.back()):
		route_changed.emit(current())
	return true


## Retour : écran précédent ; depuis le tableau de bord, ferme le menu. Vrai si quelque
## chose a changé (faux si le menu était fermé).
func back() -> bool:
	if not is_open():
		return false
	if _stack.size() == 1:
		close()
		return true
	_stack.pop_back()
	route_changed.emit(current())
	return true


func _is_allowed(route: MenuRoute) -> bool:
	return _unlocks != null and _unlocks.is_available(route.screen)


func _index_of(screen: StringName) -> int:
	for i: int in _stack.size():
		if _stack[i].screen == screen:
			return i
	return -1
