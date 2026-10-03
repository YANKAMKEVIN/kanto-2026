extends Node
## Écran factice du Menu Dresseur pour les tests de T4 (jalon-06.md §6.6) : respecte
## l'interface figée de `TrainerMenu` (signaux et méthodes) sans aucun rendu, et journalise ce
## qu'on lui demande. Sert à tester [MenuDirector] et le câblage de Boot sans l'interface du T3.

signal route_requested(route: MenuRoute)
signal back_requested
signal close_requested
signal team_member_selected(index: int)
signal team_member_moved(from: int, to: int)
signal team_favorite_toggled(index: int)

var speed_scale: float = 1.0
var opened_count: int = 0
var closed_count: int = 0
var dashboards: Array[DashboardView] = []
var placeholders: Array[StringName] = []
var teams: Array[TeamView] = []
var team_selections: Array[int] = []
var _open: bool = false


func open_animated() -> void:
	_open = true
	opened_count += 1


func close_animated() -> void:
	_open = false
	closed_count += 1


func show_dashboard(view: DashboardView) -> void:
	dashboards.append(view)


func show_placeholder(screen: StringName) -> void:
	placeholders.append(screen)


func show_team(view: TeamView, selected: int) -> void:
	teams.append(view)
	team_selections.append(selected)


func is_open() -> bool:
	return _open


## Branche cet écran sur [param director] comme le fera Boot avec le vrai TrainerMenu.
func wire(director: MenuDirector) -> void:
	director.menu_opened.connect(open_animated)
	director.menu_closed.connect(close_animated.unbind(1))
	director.dashboard_shown.connect(show_dashboard)
	director.placeholder_shown.connect(show_placeholder)
	director.team_shown.connect(show_team)
	team_member_selected.connect(director.select_member)
	team_member_moved.connect(director.move_member)
	team_favorite_toggled.connect(director.toggle_favorite)
	route_requested.connect(director.go)
	back_requested.connect(director.handle_back)
	close_requested.connect(director.close)
