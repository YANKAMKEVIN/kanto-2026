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
## [b]Boutique[/b] (jalon-07.md §6.10, T12) : écran **seul** ([code]open(MenuRoute.shop(id),
## true)[/code], ouvert par le marchand), sans tableau de bord ; ACHETER / VENDRE par
## [method buy] / [method sell] ([ShopRules]) ; tout achat ou vente réussi marque l'état changé
## (autosave à la fermeture).
## [b]Stockage[/b] (jalon-07.md §6.9, T16) : écran seul ouvert par le terminal du Centre, ou
## depuis l'Équipe (bouton STOCKAGE) ; seulement au Centre ([method MenuUnlocks.is_available]).
## Toute règle passe par [StorageRules] : succès → sélection suivante, état changé (autosave à
## la fermeture), vue neuve ; refus → [signal storage_refused] avec la raison, rien ne change.

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
## Passe systèmes 2 (§2.8, T24) : Vol accepté vers [param zone] ; Boot ferme le menu et envole.
signal fly_requested(zone: StringName)
## Passe systèmes 2 (T25b) : Téléport ou Tunnel accepté ([param move]) ; Boot ferme le menu et
## lance le voyage.
signal field_travel_requested(move: StringName)
## Passe systèmes 2 (T25b) : refus à dire dans le bandeau de l'écran Équipe.
signal team_notice_shown(text: String)
## L'écran Dresseur est à afficher : vue construite à l'entrée (et au retour d'un autre
## écran), le temps de jeu n'est pas rafraîchi en direct (jalon-06.md §6.11).
signal trainer_shown(view: TrainerView)
## Les Paramètres sont à afficher ou à rafraîchir (ouverture, après chaque changement) : vue
## neuve construite depuis les réglages courants (jalon-06.md §6.12).
signal settings_shown(view: SettingsView)
## Le résultat de « Sauvegarder maintenant » est à afficher dans l'écran des Paramètres.
signal save_result_shown(text: String)
## Un réglage a changé : [Boot] écrit le fichier des réglages et les applique.
signal settings_changed(settings: GameSettings)
## Un écran pas encore construit est à afficher (écran provisoire « À venir »).
signal placeholder_shown(screen: StringName)
## La Boutique est à afficher ou à rafraîchir (ouverture, onglet, après un achat ou une vente).
signal shop_shown(view: ShopView)
## Résultat d'un achat ou d'une vente : « Merci ! » ([param ok]) ou le refus.
signal shop_result_shown(text: String, ok: bool)
## Vendre un favori : confirmation à demander (ChoiceCards) ; VENDRE → [method sell] confirmé.
signal shop_confirm_requested(view: ChoiceView, item_id: StringName, quantity: int)
## Le Stockage est à afficher ou à rafraîchir (entrée, sélection, après une action réussie).
signal storage_shown(view: StorageView)
## Une action du Stockage est refusée : la carte ([param place], [param index]) tremble et
## [param text] dit pourquoi (texte vide possible : rien à dire).
signal storage_refused(place: int, index: int, text: String)
## LIBÉRER permis : la confirmation (LIBÉRER / ANNULER) est à montrer.
signal storage_release_asked(view: ChoiceView, place: int, index: int)
## CT (jalon 11, T12) : le Pokémon [param index] apprend la capacité de [param item_id] ; Boot
## joue le déroulé « apprendre / oublier » par-dessus le menu, puis rappelle
## [method finish_tm_learn].
signal tm_learn_requested(index: int, item_id: StringName)
## Objet AVENTURE sans cible (jalon 12, T20 : la Corde Sortie) accepté ici
## ([method FieldItemRules.check] = OK) : Boot ferme le menu, retire l'objet, raconte et agit.
## Rien n'est consommé par le menu.
signal field_item_requested(item_id: StringName)
## Objet clé utilisable (passe systèmes 2, `systemes-2.md` §2.4 : Bicyclette, Poké Flûte) :
## UTILISER dans le Sac en exploration. Boot ferme le menu et l'aiguille par
## [member ItemData.key_use] ; rien n'est consommé.
signal key_item_requested(item_id: StringName)
## Pierre d'évolution (jalon 12, T23 ; `jalon-12.md` §2.9) utilisée sur le Pokémon COMPATIBLE
## [param index] : Boot ferme le menu et joue [method EvolutionDirector.play_item] ; la pierre
## est retirée par Boot au moment exact de l'évolution. Rien n'est consommé par le menu.
signal evolution_item_requested(index: int, item_id: StringName)
## Super Bonbon (jalon 14, T18b ; `jalon-14.md` §2.6) donné au Pokémon [param index]
## ([method RareCandy.check] = OK) : Boot retire le bonbon, fait gagner le niveau et joue la suite
## (niveau, capacités, évolution) puis rappelle [method finish_rare_candy]. Rien n'est consommé
## par le menu.
signal rare_candy_requested(index: int, item_id: StringName)
## Lot 32P : PP Plus ou Éther donné au Pokémon [param index] ([method PpItem.check] = OK) : Boot
## fait choisir la capacité ([method MoveLearnPrompt.choose_move]) puis rappelle
## [method finish_pp_item]. Rien n'est consommé avant.
signal pp_move_requested(index: int, item_id: StringName)

var _state: Object
var _data: PokemonData
var _zones: ZoneLibrary
var _objectives: ObjectiveLibrary
## Badges de Kanto (MM.1) : chargés à la première demande (data/badges.json).
var _badges: BadgeLibrary
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
var _moments: MomentLibrary
var _dex_filter: int = PokedexQuery.Filter.ALL
var _dex_zone: StringName = &""
var _dex_type: StringName = &""
var _dex_text: String = ""
var _settings: GameSettings
var _device_quality: GameSettings.Graphics = GameSettings.Graphics.HIGH
var _can_save: bool = false
var _shops: ShopLibrary
## Espèces éligibles au compagnon (jalon 11) ; null = aucun bouton FAIRE SORTIR.
var _companions: CompanionCatalog
## Boutique affichée et son onglet (de session).
var _shop_id: StringName = &""
var _shop_mode: StringName = ShopViews.MODE_BUY
## Pokémon sélectionné dans le Stockage (de session, jamais sauvegardé).
var _storage_selection: StorageSelection = StorageSelection.new()
## Recherche et tri de la grille du Stockage (T7) : de session, jamais sauvegardés.
var _storage_text: String = ""
var _storage_sort: int = StorageQuery.Sort.ARRIVAL
## Grottes de Kanto et carte courante (jalon 12, T20 : Corde Sortie) ; null / vide = aucune.
var _caves: CaveLibrary
var _current_map: Callable = Callable()
## Passe systèmes 2 (T24) : func(zone: StringName) -> bool, Vol permis vers cette zone.
var _fly_check: Callable = Callable()
## Passe systèmes 2 (T25b) : func(move: StringName) -> FieldTravelRules.Check (Téléport, Tunnel).
var _field_travel_check: Callable = Callable()


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## [param state] : l'autoload GameState (ou une instance de game_state.gd en test).
## [param can_open] : [code]func() -> bool[/code], la garde d'ouverture.
func setup(state: Object, data: PokemonData, zones: ZoneLibrary, objectives: ObjectiveLibrary,
		unlocks: MenuUnlocks, can_open: Callable, items: ItemLibrary = null,
		dex: PokedexLibrary = null, illustration: MapIllustration = null, moments: MomentLibrary = null) -> void:
	_illustration = illustration
	_moments = moments
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
## si le menu est déjà ouvert ou si le directeur n'est pas branché. [param standalone] : écran
## **seul** (la Boutique, [method MenuNavigator.open]) : ni tableau de bord dessous, ni
## [signal dashboard_shown] ; faux si la route ne peut pas s'ouvrir seule.
func open(route: MenuRoute = null, standalone: bool = false) -> bool:
	if _navigator == null or _navigator.is_open():
		return false
	if _can_open.is_valid() and not bool(_can_open.call()):
		return false
	# Chantier JR : le buste du menu suit l'apparence du joueur.
	var look: Variant = _state.get(&"player_look") if _state != null else null
	MenuArt.player_look = look if look is StringName else &"hero"
	if not _navigator.open(route, standalone):
		return false
	_changed = false
	get_tree().paused = true
	menu_opened.emit()
	var shown := _navigator.current()
	if shown != null and shown.screen != MenuRoute.DASHBOARD and not _navigator.is_standalone():
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


## Branche les réglages courants ([param settings], modifiés en place) : sans eux, la route
## SETTINGS reste l'écran provisoire. [param device_quality] : la qualité que choisirait Auto
## sur cet appareil ; [param can_save] : « Sauvegarder maintenant » est actif.
func set_settings(settings: GameSettings, device_quality: GameSettings.Graphics,
		can_save: bool) -> void:
	_settings = settings
	_device_quality = device_quality
	_can_save = can_save


## Change le réglage [param key] (geste de l'écran). Vrai si la valeur était permise et
## différente : [signal settings_changed] puis la vue neuve ([signal settings_shown]) ; sinon
## rien n'est émis. Ce n'est jamais un changement de la partie (pas d'autosave).
func change_setting(key: StringName, value: Variant) -> bool:
	if _settings == null or not _settings.set_value(key, value):
		return false
	settings_changed.emit(_settings)
	_emit_settings()
	return true


## Branche les boutiques (data/shops/) : sans elles, la route SHOP reste l'écran provisoire.
func set_shops(shops: ShopLibrary) -> void:
	_shops = shops


## Onglet ACHETER / VENDRE touché : la vue de cet onglet est réémise (onglet inconnu : ACHETER).
func set_shop_mode(mode: StringName) -> void:
	_shop_mode = mode if ShopViews.MODES.has(mode) else ShopViews.MODE_BUY
	_emit_shop()


## ACHETER : [param quantity] [param item_id] dans la boutique affichée ([method ShopRules.buy]).
## OK → état changé, Boutique rafraîchie (argent, DANS LE SAC), « Merci ! » ; refus → la raison
## (« Tu n'as pas assez d'argent. »), rien d'autre.
func buy(item_id: StringName, quantity: int) -> ShopRules.Status:
	var shop := _current_shop()
	var item := _items.get_item(item_id) if _items != null else null
	if _state == null or shop == null or item == null:
		return ShopRules.Status.NOT_SOLD_HERE
	var status := ShopRules.buy(_state, shop, item, quantity)
	_shop_result(status)
	return status


## VENDRE : [param quantity] [param item_id] ([method ShopRules.sell]). Un favori non confirmé
## → [signal shop_confirm_requested] (l'écran rappelle avec [param confirmed] vrai) ; OK → état
## changé, Boutique rafraîchie, « Merci ! » ; autre refus → la raison (« Je ne peux pas te
## reprendre ça. »).
func sell(item_id: StringName, quantity: int, confirmed: bool = false) -> ShopRules.Status:
	var item := _items.get_item(item_id) if _items != null else null
	if _state == null or _current_shop() == null or item == null:
		return ShopRules.Status.NOT_SOLD_HERE
	var status := ShopRules.sell(_state, item, quantity, confirmed)
	if status == ShopRules.Status.NEEDS_CONFIRM:
		var entry := ShopViews.build(_state, _current_shop(), _items, ShopViews.MODE_SELL) \
			.entry(item_id)
		shop_confirm_requested.emit(ShopViews.sell_confirm_view(entry, quantity), item_id,
			quantity)
		return status
	_shop_result(status)
	return status


## Vue de la boutique affichée, onglet courant (null : pas de boutique affichée).
func build_shop() -> ShopView:
	var shop := _current_shop()
	if shop == null or _items == null:
		return null
	return ShopViews.build(_state, shop, _items, _shop_mode)


## Vue du Stockage pour la sélection courante (null : directeur non branché).
func build_storage(result: StorageResult = null) -> StorageView:
	if _state == null:
		return null
	return StorageViews.build(_state, _data, _storage_selection, _zones, _unlocks, result,
		_storage_text, _storage_sort)


## Recherche (nom d'espèce) et tri de la grille du Stockage : vue neuve, rien d'autre ne change
## (ni l'ordre réel des boîtes, ni la sélection).
func set_storage_query(text: String, sort: int) -> void:
	if not _storage_open():
		return
	_storage_text = text
	_storage_sort = clampi(sort, 0, StorageQuery.SORT_LABELS.size() - 1)
	_emit_storage()


## Sélection courante du Stockage (copie).
func get_storage_selection() -> StorageSelection:
	return StorageSelection.new(_storage_selection.place, _storage_selection.index)


## Une carte du Stockage est touchée : elle devient la sélection, vue neuve (fiche, actions).
## Place inexistante : rien.
func select_storage(place: int, index: int) -> void:
	if not _storage_open() or _pokemon_at(place, index) == null:
		return
	var selection := StorageSelection.new(place as StorageRules.Place, index)
	if selection.equals(_storage_selection):
		return
	_storage_selection = selection
	_emit_storage()


## DÉPOSER (ou glisser ÉQUIPE → STOCKAGE) le Pokémon [param index] de l'équipe.
func deposit_member(index: int) -> bool:
	if not _storage_open():
		return false
	return _storage_result(StorageRules.deposit(_state.party, _state.storage, index))


## REPRENDRE (ou glisser STOCKAGE → ÉQUIPE) le Pokémon [param index] du stockage.
func withdraw_member(index: int) -> bool:
	if not _storage_open():
		return false
	return _storage_result(StorageRules.withdraw(_state.party, _state.storage, index))


## FAVORI : inverse le favori du Pokémon de [param place] à [param index].
func toggle_storage_favorite(place: int, index: int) -> bool:
	if not _storage_open():
		return false
	return _storage_result(StorageRules.toggle_favorite(_state.party, _state.storage,
		place as StorageRules.Place, index))


## LIBÉRER (menu « ⋯ ») : vérifie la règle sans rien changer. Refus (dernier Pokémon, favori)
## → [signal storage_refused], sans confirmation ; permis → [signal storage_release_asked].
func request_release(place: int, index: int) -> bool:
	if not _storage_open():
		return false
	var where := place as StorageRules.Place
	var status := StorageRules.can_release(_state.party, _state.storage, where, index)
	var pokemon := _pokemon_at(place, index)
	if status != StorageRules.Status.OK:
		var refused := StorageResult.new(status, pokemon, StorageSelection.new(where, index))
		storage_refused.emit(place, index, StorageViews.result_text(refused, _data))
		return false
	storage_release_asked.emit(StorageViews.release_choice(pokemon.display_name(_data)), place,
		index)
	return true


## LIBÉRER confirmé : [method StorageRules.release] (la règle est revérifiée).
func confirm_release(place: int, index: int) -> bool:
	if not _storage_open():
		return false
	return _storage_result(StorageRules.release(_state.party, _state.storage,
		place as StorageRules.Place, index))


## Annonce le résultat de « Sauvegarder maintenant » ([Boot], une fois l'écriture faite).
func show_save_result(text: String) -> void:
	save_result_shown.emit(text)


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
	return DashboardViews.build(_state, _data, _zones, _objectives, _unlocks, _badge_library())


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


## Espèces éligibles au compagnon (jalon 11, Boot) : bouton FAIRE SORTIR / RAPPELER de l'Équipe.
func set_companions(catalog: CompanionCatalog) -> void:
	_companions = catalog


## FAIRE SORTIR / RAPPELER (jalon 11, dossier 14 §8.1) sur le Pokémon [param index] : le
## compagnon actuel est rappelé (aucun compagnon) ; un autre Pokémon éligible devient le
## compagnon (un seul). Faux si la place n'existe pas ou si l'espèce n'est pas éligible. Le
## monde suit à la fermeture du menu (sortie ou rentrée dans la Ball).
func toggle_companion(index: int) -> bool:
	if _state == null:
		return false
	var pokemon: Pokemon = _state.party.get_at(index)
	if pokemon == null:
		return false
	match TeamViews.companion_action(pokemon, _companions, _state.get(&"companion_uid")):
		PokemonSheetView.CompanionAction.RECALL:
			_state.call(&"set_companion", null)
		PokemonSheetView.CompanionAction.SEND_OUT:
			_state.call(&"set_companion", pokemon)
		_:
			return false
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
	if _use_targetless_item(item_id):
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
	if item.is_tm():
		# CT : jamais consommée ; un Pokémon non COMPATIBLE est déjà refusé par le choix.
		if TmTeach.check(pokemon, item, _data) != TmTeach.Check.COMPATIBLE:
			return false
		tm_learn_requested.emit(index, item_id)
		return true
	if StoneUse.is_stone(item):
		# Pierre (jalon 12) : un Pokémon INCOMPATIBLE est déjà refusé par le choix.
		if not _state.bag.has(item_id) \
				or StoneUse.check(pokemon, item_id, _data) != StoneUse.Check.COMPATIBLE:
			return false
		evolution_item_requested.emit(index, item_id)
		return true
	if RareCandy.is_candy(item):
		# Super Bonbon (jalon 14) : niveau 100 et K.O. sont déjà refusés par le choix.
		if not _state.bag.has(item_id) or RareCandy.check(pokemon) != RareCandy.Check.OK:
			return false
		rare_candy_requested.emit(index, item_id)
		return true
	if Vitamin.is_vitamin(item):
		return _use_vitamin(item, index, pokemon)
	if PpItem.is_pp_item(item):
		# Lot 32P : un Pokémon sans effet possible est déjà refusé par le choix.
		if not _state.bag.has(item_id) or PpItem.check(pokemon, item, _data) != PpItem.Check.OK:
			return false
		if PpItem.needs_move(item):
			pp_move_requested.emit(index, item_id)
			return true
		return finish_pp_item(index, item_id, -1)
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


## Fin du déroulé d'une CT ([signal tm_learn_requested]) : la partie a changé si la capacité a
## été apprise (autosave à la fermeture) ; le choix du Pokémon et le Sac sont réémis (le Pokémon
## passe à « DÉJÀ CONNUE »).
func finish_tm_learn(index: int, item_id: StringName, learned: bool) -> void:
	if _state == null or _items == null:
		return
	if learned:
		mark_changed()
	var item := _items.get_item(item_id)
	if item != null:
		bag_targets_shown.emit(BagQuery.targets(_state.party, _state.bag, item, _bag_context,
			_data, index))
	_emit_bag()


## Fin du déroulé d'un Super Bonbon ([signal rare_candy_requested]) : la partie a changé (niveau
## gagné, bonbon retiré ; autosave à la fermeture du menu) ; le choix du Pokémon (nouveau niveau,
## Pokémon refusé au niveau 100) et le Sac sont réémis.
func finish_rare_candy(index: int, item_id: StringName) -> void:
	if _state == null or _items == null:
		return
	mark_changed()
	var item := _items.get_item(item_id)
	if item != null and is_open():
		bag_targets_shown.emit(BagQuery.targets(_state.party, _state.bag, item, _bag_context,
			_data, index))
	_emit_bag()


## Lot 32P : PP Plus / Éther sur la capacité [param slot] (−1 : le joueur a renoncé, rien ne
## change) ou Élixir sur toutes. L'objet est retiré seulement s'il a servi ; le résultat s'affiche,
## puis le choix du Pokémon et le Sac sont réémis. Vrai si l'objet a servi.
func finish_pp_item(index: int, item_id: StringName, slot: int) -> bool:
	if _state == null or _items == null:
		return false
	var item := _items.get_item(item_id)
	var pokemon: Pokemon = _state.party.get_at(index)
	if item == null or pokemon == null or not _state.bag.has(item_id):
		return false
	var used := false
	if slot >= 0 or not PpItem.needs_move(item):
		var gained := PpItem.apply(pokemon, slot, item, _data)
		var mon_name := pokemon.display_name(_data)
		if gained > 0:
			used = true
			_state.bag.remove(item_id)
			mark_changed()
			var target := mon_name
			if PpItem.needs_move(item):
				var move := _data.get_move(pokemon.moves[slot].move_id)
				target = move.name if move != null else String(pokemon.moves[slot].move_id)
			bag_result_shown.emit(PpItem.result_text(item, target), false)
		else:
			bag_result_shown.emit(BagQuery.refusal_text(ItemUse.Check.NO_EFFECT, mon_name),
				false)
	if is_open():
		bag_targets_shown.emit(BagQuery.targets(_state.party, _state.bag, item, _bag_context,
			_data, index))
	_emit_bag()
	return used


## Lot 32P : vitamine donnée au Pokémon [param index] (EV montés, statistiques recalculées).
func _use_vitamin(item: ItemData, index: int, pokemon: Pokemon) -> bool:
	if not _state.bag.has(item.id) or Vitamin.check(pokemon, item) != Vitamin.Check.OK:
		return false
	_state.bag.remove(item.id)
	Vitamin.apply(pokemon, item, _data)
	_repeat_item = item.id
	_repeat_index = index
	mark_changed()
	bag_result_shown.emit(Vitamin.result_text(item, pokemon.display_name(_data)),
		_state.bag.has(item.id))
	if _bag_context != BagQuery.CONTEXT_TEAM:
		bag_targets_shown.emit(BagQuery.targets(_state.party, _state.bag, item, _bag_context,
			_data, index))
	_emit_bag()
	return true


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
		view.fly_available = _fly_check.is_valid() and _fly_check.call(zone)
		map_zone_shown.emit(view)


## Passe systèmes 2 (T24) : [param check] = func(zone) -> bool (bouton « S'ENVOLER »).
func set_fly_check(check: Callable) -> void:
	_fly_check = check


## « S'ENVOLER » touché : revérifié, puis [signal fly_requested] (Boot ferme le menu). Refusé
## (la partie a changé depuis l'affichage du panneau) : rien.
func request_fly(zone: StringName) -> void:
	if _fly_check.is_valid() and _fly_check.call(zone):
		fly_requested.emit(zone)


## Passe systèmes 2 (T25b) : [param check] = func(move) -> [enum FieldTravelRules.Check] ; les
## fiches de l'Équipe proposent alors UTILISER sur Téléport et Tunnel.
func set_field_travel_check(check: Callable) -> void:
	_field_travel_check = check


## UTILISER touché sur la capacité [param move] du Pokémon [param index] (fiche de l'Équipe) :
## permis → [signal field_travel_requested] (Boot ferme le menu) ; pas ici → le bandeau de
## l'Équipe dit « Impossible de l'utiliser ici. » (texte de la Corde Sortie) ; occupé : rien.
func request_field_travel(index: int, move: StringName) -> void:
	if _state == null or not _field_travel_check.is_valid() \
			or not FieldTravelRules.is_travel_move(move):
		return
	var pokemon: Pokemon = _state.party.get_at(index)
	if pokemon == null or not pokemon.knows_move(move):
		return
	var check: FieldTravelRules.Check = _field_travel_check.call(move)
	match check:
		FieldTravelRules.Check.OK:
			field_travel_requested.emit(move)
		FieldTravelRules.Check.BUSY, FieldTravelRules.Check.UNKNOWN_MOVE:
			pass
		_:
			team_notice_shown.emit(BagQuery.FIELD_REFUSAL_TEXT)


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
		_state.party, _bag_target, _data, _state.money))


func _current_shop() -> ShopData:
	if _shops == null or _shop_id.is_empty() or not is_open():
		return null
	return _shops.get_shop(_shop_id)


func _emit_shop() -> void:
	var view := build_shop()
	if view != null:
		shop_shown.emit(view)


func _shop_result(status: ShopRules.Status) -> void:
	if status == ShopRules.Status.OK:
		mark_changed()
		_emit_shop()
		shop_result_shown.emit(ShopViews.status_text(status), true)
	else:
		shop_result_shown.emit(ShopViews.status_text(status), false)


func _storage_open() -> bool:
	if _state == null or not is_open():
		return false
	return _navigator.current().screen == MenuRoute.STORAGE


func _pokemon_at(place: int, index: int) -> Pokemon:
	if place != StorageRules.Place.PARTY and place != StorageRules.Place.STORAGE:
		return null
	return StorageRules.get_pokemon(_state.party, _state.storage, place as StorageRules.Place,
		index)


## Succès : sélection suivante, état changé, vue neuve. Refus : la carte refusée tremble.
func _storage_result(result: StorageResult) -> bool:
	if not result.is_ok():
		storage_refused.emit(result.selection.place, result.selection.index,
			StorageViews.result_text(result, _data))
		return false
	_storage_selection = result.selection
	mark_changed()
	_emit_storage(result)
	return true


func _emit_storage(result: StorageResult = null) -> void:
	var view := build_storage(result)
	if view == null:
		return
	_storage_selection = view.selection
	storage_shown.emit(view)


func _emit_settings() -> void:
	if _settings != null:
		settings_shown.emit(SettingsViews.build(_settings, _device_quality, _can_save))


func _emit_team() -> void:
	var travel: Array[StringName] = []
	if _field_travel_check.is_valid():
		travel = FieldTravelRules.MOVES
	var view := TeamViews.build(_state.party, _data, _zones, _state.pokedex, _unlocks,
		_companions, _state.get(&"companion_uid"), travel)
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
	elif route.screen == MenuRoute.TRAINER:
		trainer_shown.emit(TrainerSummary.build(_state, _data, _zones, _moments, _unlocks,
			_badge_library(), _items))
	elif route.screen == MenuRoute.SETTINGS and _settings != null:
		_emit_settings()
	elif route.screen == MenuRoute.SHOP and _shops != null and _items != null \
			and _shops.has_shop(StringName(route.params.get("shop", &""))):
		_shop_id = StringName(route.params.get("shop", &""))
		var mode := StringName(route.params.get("mode", ShopViews.MODE_BUY))
		_shop_mode = mode if ShopViews.MODES.has(mode) else ShopViews.MODE_BUY
		_emit_shop()
	elif route.screen == MenuRoute.STORAGE and _state != null:
		_storage_selection = StorageSelection.first(_state.party, _state.storage)
		_storage_text = ""
		_storage_sort = StorageQuery.Sort.ARRIVAL
		_emit_storage()
	else:
		placeholder_shown.emit(route.screen)


## Badges de Kanto, chargés à la première demande (tableau de bord ou Dresseur), puis gardés.
func _badge_library() -> BadgeLibrary:
	if _badges == null:
		_badges = BadgeLibrary.new()
		_badges.load_file()
	return _badges


func _on_closed() -> void:
	var changed := _changed
	_changed = false
	_shop_id = &""
	_storage_selection = StorageSelection.new()
	_storage_text = ""
	_storage_sort = StorageQuery.Sort.ARRIVAL
	get_tree().paused = false
	menu_closed.emit(changed)


## Grottes (jalon 12, T20) et carte courante ([param current_map] : `func() -> StringName`) :
## la Corde Sortie ne sert que dans une grotte ([FieldItemRules]).
func set_caves(caves: CaveLibrary, current_map: Callable) -> void:
	_caves = caves
	_current_map = current_map


## UTILISER d'un objet AVENTURE sans cible (jalon 12, T20 : la Corde Sortie). Faux si l'objet
## n'en est pas un (le parcours habituel continue). Refus → le bandeau du Sac dit pourquoi, rien
## ne change ; accepté → [signal field_item_requested] (Boot ferme le menu et agit).
func _use_targetless_item(item_id: StringName) -> bool:
	var item := _items.get_item(item_id)
	if not FieldItemRules.is_targetless(item):
		return false
	if not _state.bag.has(item_id):
		return true
	if item.has_key_use():
		key_item_requested.emit(item_id)
		return true
	if RepelRules.is_repel(item):
		# Lot 32P : la Repousse agit tout de suite, menu ouvert ; elle remplace celle en cours.
		_state.bag.remove(item_id)
		_state.set(&"repel_steps", item.repel_steps)
		mark_changed()
		bag_result_shown.emit(RepelRules.USED_FORMAT % item.repel_steps, false)
		_emit_bag()
		return true
	var map_id: StringName = _current_map.call() if _current_map.is_valid() else &""
	var check := FieldItemRules.check(item, map_id, _caves)
	if check != FieldItemRules.Check.OK:
		bag_result_shown.emit(BagQuery.field_refusal_text(check), false)
		return true
	field_item_requested.emit(item_id)
	return true
