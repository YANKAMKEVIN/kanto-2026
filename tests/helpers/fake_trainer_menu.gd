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

signal bag_category_opened(category: StringName)
signal bag_favorite_toggled(item_id: StringName)
signal bag_sort_changed(sort: int)
signal bag_use_requested(item_id: StringName)
signal bag_target_chosen(item_id: StringName, index: int)
signal bag_repeat_requested

signal pokedex_filter_changed(filter: int, zone: StringName, type: StringName, text: String)
signal pokedex_species_opened(species: StringName)

signal map_zone_touched(zone: StringName)

var speed_scale: float = 1.0
var opened_count: int = 0
var closed_count: int = 0
var dashboards: Array[DashboardView] = []
var placeholders: Array[StringName] = []
var teams: Array[TeamView] = []
var team_selections: Array[int] = []
var bags: Array[BagView] = []
var bag_targets: Array[PartyPickerView] = []
var bag_results: Array[String] = []
var bag_repeats: Array[bool] = []
var pokedex_grids: Array[PokedexGridView] = []
var pokedex_sheets: Array[PokedexSheetView] = []
var trainers: Array[TrainerView] = []
var maps: Array[MapView] = []
var map_zones: Array[ZonePanelView] = []
var pokedex_back_count: int = 0
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


func show_bag(view: BagView) -> void:
	bags.append(view)


func show_bag_targets(view: PartyPickerView) -> void:
	bag_targets.append(view)


func show_bag_result(text: String, can_repeat: bool) -> void:
	bag_results.append(text)
	bag_repeats.append(can_repeat)


func show_pokedex(view: PokedexGridView) -> void:
	pokedex_grids.append(view)


func show_pokedex_sheet(view: PokedexSheetView) -> void:
	pokedex_sheets.append(view)


func show_trainer(view: TrainerView) -> void:
	trainers.append(view)


func show_map(view: MapView) -> void:
	maps.append(view)


func show_map_zone(view: ZonePanelView) -> void:
	map_zones.append(view)


func pokedex_back() -> bool:
	pokedex_back_count += 1
	return false


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
	director.bag_shown.connect(show_bag)
	director.bag_targets_shown.connect(show_bag_targets)
	director.bag_result_shown.connect(show_bag_result)
	bag_category_opened.connect(director.open_bag_category)
	bag_favorite_toggled.connect(director.toggle_item_favorite)
	bag_sort_changed.connect(director.set_bag_sort)
	bag_use_requested.connect(director.request_item_use)
	bag_target_chosen.connect(director.use_item_on)
	bag_repeat_requested.connect(director.repeat_item_use)
	director.pokedex_shown.connect(show_pokedex)
	director.pokedex_sheet_shown.connect(show_pokedex_sheet)
	pokedex_filter_changed.connect(director.set_pokedex_filter)
	pokedex_species_opened.connect(director.open_species)
	director.map_shown.connect(show_map)
	director.map_zone_shown.connect(show_map_zone)
	map_zone_touched.connect(director.open_zone)
	director.trainer_shown.connect(show_trainer)
	route_requested.connect(director.go)
	back_requested.connect(director.handle_back)
	close_requested.connect(director.close)
