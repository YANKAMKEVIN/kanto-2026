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
## Le Sac est à afficher ou à rafraîchir (ouverture, favori, tri, après un usage).
signal bag_shown(view: BagView)
## Le choix du Pokémon pour un objet est à afficher (UTILISER depuis le Sac d'exploration).
signal bag_targets_shown(view: PartyPickerView)
## Résultat d'un usage (texte, UTILISER À NOUVEAU possible) : « +20 PV — … » ou la raison.
signal bag_result_shown(text: String, can_repeat: bool)
## Le Pokédex est à afficher ou à rafraîchir (ouverture, filtre ou recherche changé).
signal pokedex_shown(view: PokedexGridView)
## Une fiche du Pokédex est à afficher (espèce touchée, ou demandée par la route).
signal pokedex_sheet_shown(view: PokedexSheetView)
## La Carte est à afficher (ouverture, lien Habitat → Carte) : vue neuve, zone du joueur
## (portrait) et zone à ouvrir ([member MapView.selected]).
signal map_shown(view: MapView)
## Le panneau d'une zone découverte est à afficher (toucher, ou zone choisie à l'arrivée).
signal map_zone_shown(view: ZonePanelView)
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
var _items: ItemLibrary
var _bag_context: StringName = BagQuery.CONTEXT_FIELD
var _bag_target: int = -1
var _bag_last: StringName = &""
var _bag_sort: int = BagQuery.Sort.RELEVANCE
var _repeat_item: StringName = &""
var _repeat_index: int = -1
var _dex: PokedexLibrary
var _illustration: MapIllustration
var _dex_filter: int = PokedexQuery.Filter.ALL
var _dex_zone: StringName = &""
var _dex_type: StringName = &""
var _dex_text: String = ""


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## [param state] : l'autoload GameState (ou une instance de game_state.gd en test).
## [param can_open] : [code]func() -> bool[/code], la garde d'ouverture.
func setup(state: Object, data: PokemonData, zones: ZoneLibrary, objectives: ObjectiveLibrary,
		unlocks: MenuUnlocks, can_open: Callable, items: ItemLibrary = null,
		dex: PokedexLibrary = null, illustration: MapIllustration = null) -> void:
	_illustration = illustration
	_items = items
	_dex = dex
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
	var shown := _navigator.current()
	if shown != null and shown.screen != MenuRoute.DASHBOARD:
		# Ouvert directement sur un sous-écran : l'en-tête (nom de la zone) vient de la vue du
		# tableau de bord, qui n'aurait sinon jamais été construite.
		dashboard_shown.emit(build_dashboard())
	_on_route_shown(shown)
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


## Mémorise l'onglet ouvert du Sac (session seulement, jamais sauvegardé).
func open_bag_category(category: StringName) -> void:
	_bag_last = category


## Inverse le favori de [param item_id] (Sac). Faux si l'objet n'est pas dans le Sac.
func toggle_item_favorite(item_id: StringName) -> bool:
	if _state == null or not _state.bag.has(item_id):
		return false
	_state.bag.toggle_favorite(item_id)
	mark_changed()
	_emit_bag()
	return true


## Change le tri du Sac (session seulement).
func set_bag_sort(sort: int) -> void:
	_bag_sort = sort
	_emit_bag()


## UTILISER sur [param item_id] : depuis l'Équipe, sur le Pokémon déjà choisi ; sinon le choix
## du Pokémon s'ouvre.
func request_item_use(item_id: StringName) -> void:
	if _state == null or _items == null:
		return
	if _bag_context == BagQuery.CONTEXT_TEAM and _bag_target >= 0:
		use_item_on(item_id, _bag_target)
		return
	var item := _items.get_item(item_id)
	if item == null:
		return
	bag_targets_shown.emit(BagQuery.targets(_state.party, _state.bag, item, _bag_context,
		_data))


## Donne [param item_id] au Pokémon [param index] ([ItemUse.apply]). Vrai si l'objet a servi
## (autosave à la fermeture) ; sinon la raison est affichée et rien n'est consommé.
func use_item_on(item_id: StringName, index: int) -> bool:
	if _state == null or _items == null:
		return false
	var item := _items.get_item(item_id)
	var pokemon: Pokemon = _state.party.get_at(index)
	if item == null or pokemon == null:
		return false
	var result := ItemUse.apply(_state.bag, item, pokemon, _bag_context)
	_repeat_item = item_id
	_repeat_index = index
	if result.is_ok():
		mark_changed()
	bag_result_shown.emit(BagQuery.result_text(result, pokemon.display_name(_data)),
		BagQuery.can_repeat(result))
	if _bag_context != BagQuery.CONTEXT_TEAM:
		bag_targets_shown.emit(BagQuery.targets(_state.party, _state.bag, item, _bag_context,
			_data, index))
	_emit_bag()
	return result.is_ok()


## UTILISER À NOUVEAU : même objet, même Pokémon.
func repeat_item_use() -> bool:
	if _repeat_item.is_empty():
		return false
	return use_item_on(_repeat_item, _repeat_index)


## Filtre, zone d'HABITATS, type ou recherche changés (mémoire de la visite seulement, jamais
## sauvegardée) : la grille est réémise.
func set_pokedex_filter(filter: int, zone: StringName, type: StringName, text: String) -> void:
	_dex_filter = filter
	_dex_zone = zone
	_dex_type = type
	_dex_text = text
	_emit_pokedex(&"", false)


## Fiche de [param species] (case touchée). Une espèce inconnue n'ouvre rien.
func open_species(species: StringName) -> void:
	if _state == null or _dex == null:
		return
	var view := PokedexQuery.sheet(species, _state.pokedex, _data, _dex, _zones)
	if view != null:
		pokedex_sheet_shown.emit(view)


## Panneau de [param zone] (toucher sur l'illustration, ou zone choisie à l'arrivée). Une zone
## non découverte, inconnue ou sans état ne donne rien : jamais un panneau vide ni un nom.
func open_zone(zone: StringName) -> void:
	if _state == null or _zones == null:
		return
	var view := MapJournal.panel(zone, _state, _data, _zones, _items,
		_unlocks.pokedex_visible())
	if view != null:
		map_zone_shown.emit(view)


## [param with_sheet] : la fiche proposée par la grille (celle demandée par la route, sinon la
## première espèce connue) est émise aussi ; faux au changement de filtre.
func _emit_pokedex(selected: StringName, with_sheet: bool) -> void:
	if _state == null or _dex == null:
		return
	var view := PokedexQuery.grid(_state.pokedex, _data, _dex, _zones, _dex_filter, _dex_zone,
		_dex_type, _dex_text, selected)
	pokedex_shown.emit(view)
	if with_sheet and not view.selected.is_empty():
		open_species(view.selected)


func _emit_bag() -> void:
	if _state == null:
		return
	bag_shown.emit(BagQuery.view(_state.bag, _items, _bag_context, _bag_sort, _bag_last,
		_state.party, _bag_target, _data))


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
	elif route.screen == MenuRoute.BAG and _items != null:
		_bag_context = route.params.get("context", BagQuery.CONTEXT_FIELD)
		_bag_target = int(route.params.get("target", -1))
		_repeat_item = &""
		_emit_bag()
	elif route.screen == MenuRoute.POKEDEX and _dex != null:
		_dex_filter = int(route.params.get("filter", PokedexQuery.Filter.ALL))
		_dex_zone = &""
		_dex_type = &""
		_dex_text = ""
		_emit_pokedex(StringName(route.params.get("species", &"")), true)
	elif route.screen == MenuRoute.MAP and _zones != null:
		var map_view := MapJournal.view(_state, _zones, _illustration,
			StringName(route.params.get("zone", &"")))
		map_shown.emit(map_view)
		if not map_view.selected.is_empty():
			open_zone(map_view.selected)
	else:
		placeholder_shown.emit(route.screen)


func _on_closed() -> void:
	var changed := _changed
	_changed = false
	get_tree().paused = false
	menu_closed.emit(changed)
