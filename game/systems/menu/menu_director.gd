class_name MenuDirector
extends Node
## Ouvre et ferme le Menu Dresseur, met le monde en pause et nourrit l'écran de vues
## (jalon-06.md §6.2, §6.4, §6.6 ; dossier 08 règle 6).
##
## Ne connaît **pas** l'écran ([code]TrainerMenu[/code]) : [Boot] relie ses signaux
## ([signal menu_opened], [signal menu_closed], [signal dashboard_shown],
## [signal placeholder_shown]) à l'écran et les actions de l'écran ([method go],
## [method handle_back], [method close]) à ce directeur. La pile d'écrans est un
## [MenuNavigator] (classe pure).
##
## Pause : le directeur pose [member SceneTree.paused] à l'ouverture et la retire tout de
## suite à la fermeture (le fondu de fermeture de l'écran joue par-dessus le monde qui
## reprend). Il est en mode ALWAYS, comme [Boot], pour continuer à recevoir les actions.
## [b]Garde d'ouverture[/b] : [code]can_open[/code], fournie par [Boot] (partie stable, ni
## écran « À venir »). [b]État changé[/b] : les écrans qui modifient la partie (6A+) appellent
## [method mark_changed] ; [signal menu_closed] porte alors [code]changed = true[/code] et
## [Boot] demande un autosave.

## Le menu vient de s'ouvrir (la pause est posée) : l'écran joue son ouverture.
signal menu_opened
## Le menu vient de se fermer (la pause est levée). [param changed] : l'état de la partie a
## changé pendant l'ouverture (autosave).
signal menu_closed(changed: bool)
## « Sauvegarder maintenant » (6F).
signal save_requested
## Le tableau de bord est à afficher (ouverture, retour jusqu'à lui) : vue neuve.
signal dashboard_shown(view: DashboardView)
## L'Équipe est à afficher ou à rafraîchir (ouverture, après un échange ou un favori) ;
## [param selected] est déjà ramené dans l'équipe (jalon-06.md §6.7).
signal team_shown(view: TeamView, selected: int)
## Un écran pas encore construit est à afficher (écran provisoire « À venir »).
signal placeholder_shown(screen: StringName)

var _state: Object
var _data: PokemonData
var _zones: ZoneLibrary
var _objectives: ObjectiveLibrary
var _unlocks: MenuUnlocks
var _can_open: Callable
var _navigator: MenuNavigator
var _changed: bool = false
var _team_selected: int = 0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## [param state] : l'autoload GameState (ou une instance de game_state.gd en test).
## [param can_open] : [code]func() -> bool[/code], la garde d'ouverture.
func setup(state: Object, data: PokemonData, zones: ZoneLibrary, objectives: ObjectiveLibrary,
		unlocks: MenuUnlocks, can_open: Callable) -> void:
	_state = state
	_data = data
	_zones = zones
	_objectives = objectives
	_unlocks = unlocks
	_can_open = can_open
	_navigator = MenuNavigator.new(unlocks)
	_navigator.route_changed.connect(_on_route_shown)
	_navigator.closed.connect(_on_closed)


func _exit_tree() -> void:
	# Jamais laisser l'arbre en pause si le directeur disparaît menu ouvert.
	if is_open() and is_inside_tree() and get_tree() != null:
		get_tree().paused = false


## Ouvre le menu sur [param route] (tableau de bord par défaut). Faux si la garde refuse,
## si le menu est déjà ouvert ou si le directeur n'est pas branché.
func open(route: MenuRoute = null) -> bool:
	if _navigator == null or _navigator.is_open():
		return false
	if _can_open.is_valid() and not bool(_can_open.call()):
		return false
	_changed = false
	get_tree().paused = true
	_navigator.open(route)
	menu_opened.emit()
	_on_route_shown(_navigator.current())
	return true


## Ferme le menu (sans effet s'il est fermé).
func close() -> void:
	if _navigator != null:
		_navigator.close()


## Va vers [param route] (carte du tableau de bord ou lien croisé). Faux si indisponible.
func go(route: MenuRoute) -> bool:
	return _navigator != null and _navigator.go(route)


## Retour Android, Échap, « retour » de l'écran : un niveau en arrière ; depuis le tableau de
## bord, ferme. Vrai si le menu était ouvert (l'événement est alors consommé).
func handle_back() -> bool:
	return _navigator != null and _navigator.back()


## « Sauvegarder maintenant » (6F) : l'écran le demande, [Boot] écrit.
func request_save() -> void:
	save_requested.emit()


## Un écran a modifié la partie (équipe réordonnée, favori, objet utilisé) : autosave à la
## fermeture.
func mark_changed() -> void:
	_changed = true


func is_open() -> bool:
	return _navigator != null and _navigator.is_open()


func get_navigator() -> MenuNavigator:
	return _navigator


## Vue neuve du tableau de bord pour l'état actuel de la partie.
func build_dashboard() -> DashboardView:
	return DashboardViews.build(_state, _data, _zones, _objectives, _unlocks)


## Échange les places [param from] et [param to] de l'équipe ([method Party.swap] :
## réordonner = échanger, dossier 08 §2). Vrai si l'ordre a changé : la sélection suit le
## Pokémon sélectionné, l'état est marqué changé (autosave) et l'Équipe est réémise.
func move_member(from: int, to: int) -> bool:
	if _state == null or not _state.party.swap(from, to):
		return false
	_team_selected = TeamViews.selection_after_swap(_team_selected, from, to)
	mark_changed()
	_emit_team()
	return true


## Inverse le favori du Pokémon [param index]. Faux si la place n'existe pas.
func toggle_favorite(index: int) -> bool:
	if _state == null:
		return false
	var pokemon: Pokemon = _state.party.get_at(index)
	if pokemon == null:
		return false
	pokemon.favorite = not pokemon.favorite
	mark_changed()
	_emit_team()
	return true


## Retient le Pokémon sélectionné de l'Équipe (informatif : l'écran change de fiche seul).
func select_member(index: int) -> void:
	if _state != null:
		_team_selected = TeamViews.clamp_selection(index, _state.party.size())


func _emit_team() -> void:
	var view := TeamViews.build(_state.party, _data, _zones, _state.pokedex, _unlocks)
	_team_selected = TeamViews.clamp_selection(_team_selected, view.size())
	team_shown.emit(view, _team_selected)


## Un écran est à afficher : le tableau de bord avec sa vue, sinon l'écran provisoire (les
## écrans des sous-jalons 6A+ n'existent pas encore : ils remplaceront ce cas un à un).
func _on_route_shown(route: MenuRoute) -> void:
	if route == null:
		return
	if route.screen == MenuRoute.DASHBOARD:
		dashboard_shown.emit(build_dashboard())
	elif route.screen == MenuRoute.TEAM:
		_team_selected = 0
		select_member(int(route.params.get("index", 0)))
		_emit_team()
	else:
		placeholder_shown.emit(route.screen)


func _on_closed() -> void:
	var changed := _changed
	_changed = false
	get_tree().paused = false
	menu_closed.emit(changed)
