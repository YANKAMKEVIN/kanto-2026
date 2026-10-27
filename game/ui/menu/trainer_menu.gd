class_name TrainerMenu
extends CanvasLayer
## Menu Dresseur (jalon-06.md §6.2, §6.6 ; dossier 08) : calque LAYER_MENU qui pose un fond
## (le monde flouté et assombri) puis l'écran courant (au départ le tableau de bord), avec
## l'en-tête commun : × à gauche et nom de la zone actuelle.
##
## Il ne décide de rien : il affiche ce qu'on lui donne (vues) et relaie ce que le doigt fait
## (signaux) ; c'est [code]Boot[/code] (T4) qui le relie au directeur du menu.
## En-tête (MM.1, maquettes) : × rond compact à gauche (caché quand l'écran pose son propre « ‹ »,
## [member MenuScreen.owns_back]) et **bandeau d'état** en haut à droite : lieu · heure · argent.
## La puce « heure » interroge [WorldClock] : cachée tant que l'horloge est inactive (pas de
## cycle jour/nuit avant la phase 10, aucune heure inventée). L'argent ne s'affiche que sur les
## écrans qui le demandent ([member MenuScreen.status_money] : le Sac ; jamais au tableau de bord,
## dossier 09 §10).
## - × : un seul [signal close_requested] par toucher.
## - Carte touchée : [signal route_requested] avec [method MenuRoute.for_screen] ; Pokémon de
##   tête : MenuRoute.team(0).
## - [signal back_requested] : le RETOUR d'un écran (jamais depuis le tableau de bord).
## Il tourne même quand l'arbre est en pause (process_mode ALWAYS : le monde est en pause
## derrière lui).
## Placement (aspect expand, 1920 à 2340 de large) : en-tête ancré en haut, × à
## SAFE_MARGIN, bandeau d'état contre la marge droite ; les écrans occupent la zone sous l'en-tête, à SAFE_MARGIN des bords.

## Une carte (ou le Pokémon de tête, ou un lien croisé) demande un écran.
signal route_requested(route: MenuRoute)
## RETOUR d'un écran.
signal back_requested
## J30 (Q30-4) : « Panthéon » touché dans l'écran Dresseur.
signal hall_of_fame_requested
## × touché.
signal close_requested
## Relais de l'écran Équipe (6A) : Pokémon sélectionné, échange A ↔ B, favori basculé.
signal team_member_selected(index: int)
signal team_member_moved(from: int, to: int)
signal team_favorite_toggled(index: int)
## FAIRE SORTIR / RAPPELER touché sur le Pokémon [param index] (jalon 11).
signal team_companion_toggled(index: int)
## Passe systèmes 2 (T25b) : UTILISER sous la fiche d'une capacité de voyage (Téléport, Tunnel).
signal team_field_move_requested(index: int, move: StringName)
## Relais de l'écran Sac (6B) : onglet ouvert, favori basculé (appui long), tri choisi, UTILISER,
## cible choisie, UTILISER À NOUVEAU.
signal bag_category_opened(category: StringName)
signal bag_favorite_toggled(item_id: StringName)
signal bag_sort_changed(sort: int)
signal bag_use_requested(item_id: StringName)
signal bag_target_chosen(item_id: StringName, index: int)
signal bag_repeat_requested
## Relais de l'écran Pokédex (6C) : filtre, zone, type ou recherche changé ; fiche demandée
## (case connue touchée). Le lien Habitat → Carte passe par [signal route_requested].
signal pokedex_filter_changed(filter: int, zone: StringName, type: StringName, text: String)
signal pokedex_species_opened(species: StringName)
## Jalon Son (SonB) : « Cri » d'une espèce capturée au Pokédex (numéro national).
signal pokedex_cry_requested(number: int)
## Relais de l'écran Carte (6D) : zone découverte touchée. Le lien Pokémon observé → Pokédex
## passe par [signal route_requested].
signal map_zone_touched(zone: StringName)
## Passe systèmes 2 (§2.8, T24) : « S'ENVOLER » touché sur la Carte.
signal map_fly_requested(zone: StringName)
## Relais de l'écran Paramètres (6F) : un réglage change (valeur du réglage, jamais un rang) ;
## « Sauvegarder maintenant » touché.
signal setting_changed(key: StringName, value: Variant)
signal save_now_requested
## Relais de l'écran Boutique (7A.3, jalon-07.md §6.10) : onglet touché ; CONFIRMER en ACHETER (un
## seul signal par toucher) ; CONFIRMER en VENDRE (confirmed = faux), puis confirmed = vrai quand la
## carte VENDRE de la confirmation d'un favori est choisie.
signal shop_mode_changed(mode: StringName)
signal shop_buy_requested(item_id: StringName, quantity: int)
signal shop_sell_requested(item_id: StringName, quantity: int, confirmed: bool)
## Relais de l'écran Stockage (7A.4, jalon-07.md §6.9) : carte touchée, DÉPOSER (ou glisser
## ÉQUIPE → STOCKAGE), REPRENDRE (ou glisser STOCKAGE → ÉQUIPE), FAVORI, LIBÉRER demandé du menu
## « ⋯ » (avant confirmation), LIBÉRER confirmé.
signal storage_selected(place: int, index: int)
signal storage_deposit_requested(index: int)
signal storage_withdraw_requested(index: int)
signal storage_favorite_toggled(place: int, index: int)
signal storage_release_requested(place: int, index: int)
signal storage_release_confirmed(place: int, index: int)

const PIN_ICON: Texture2D = preload("res://assets/ui/icons/menu/map.svg")
const CLOCK_ICON: Texture2D = preload("res://assets/ui/icons/menu/clock.svg")
const COIN_ICON: Texture2D = preload("res://assets/ui/icons/shop/coin.svg")
## Titre des écrans provisoires (carte → « Équipe »…), texte d'interface.
const PLACEHOLDER_TITLES: Dictionary[StringName, String] = {
	MenuRoute.TEAM: "Équipe",
	MenuRoute.POKEDEX: "Pokédex",
	MenuRoute.BAG: "Sac",
	MenuRoute.MAP: "Carte",
	MenuRoute.TRAINER: "Dresseur",
	MenuRoute.SETTINGS: "Paramètres",
}

## Durées multipliées (0 = instantané, pour les tests).
var speed_scale: float = 1.0:
	set(value):
		speed_scale = value
		for screen: MenuScreen in _screens():
			screen.speed_scale = value

var _open: bool = false
var _current: MenuScreen = null
## L'écran courant a été présenté (enter) depuis l'ouverture.
var _entered: bool = false
var _amount: float = 0.0
var _tween: Tween
var _dashboard: DashboardScreen
var _placeholder: PlaceholderScreen
## Équipe (6A) : instanciée à la première visite, puis gardée.
var _team: TeamScreen
## Sac (6B) : instancié à la première visite, puis gardé.
var _bag: BagScreen
## Pokédex (6C) : instancié à la première visite, puis gardé.
var _pokedex: PokedexScreen
## Carte (6D) : instanciée à la première visite, puis gardée.
var _map: MapScreen
## Dresseur (6E) : instancié à la première visite, puis gardé.
var _trainer: TrainerScreen
## Paramètres (6F) : instancié à la première visite, puis gardé.
var _settings: SettingsScreen
## Boutique (7A.3) : instanciée à la première visite, puis gardée ; sa confirmation de vente
## (ChoiceCards) est sur le fond du menu, au-dessus de l'écran.
var _shop: ShopScreen
var _shop_choice: ChoiceCards
var _shop_choice_item: StringName = &""
var _shop_choice_quantity: int = 1
## Stockage (7A.4) : instancié à la première visite, puis gardé ; sa confirmation de LIBÉRER
## (ChoiceCards) est dans l'écran lui-même.
var _storage: StorageScreen
## Dernière révision de [UiPrefs] appliquée à chaque écran (taille du texte, contraste).
var _prefs_fitted: Dictionary[MenuScreen, int] = {}
var _blur_enabled: bool = true
## Horloge interrogée par la puce « heure » (inactive tant que le jour/nuit n'existe pas).
var _clock: WorldClock = WorldClock.new()
## Argent du bandeau d'état (« 3 840 ₽ »), gardé jusqu'à la prochaine vue qui en donne un.
var _money_text: String = ""
var _status: PanelContainer
var _zone_pill: HBoxContainer
var _zone_name: Label
var _clock_chip: HBoxContainer
var _clock_label: Label
var _money_chip: HBoxContainer
var _money_label: Label
var _dividers: Array[Panel] = []

@onready var _root: Control = %Root
@onready var _backdrop: ColorRect = %Backdrop
@onready var _header: HBoxContainer = %Header
@onready var _close_button: Button = %CloseButton
@onready var _host: Control = %Host


func _ready() -> void:
	layer = UiTokens.LAYER_MENU
	process_mode = Node.PROCESS_MODE_ALWAYS
	_header.offset_left = UiTokens.SAFE_MARGIN
	_header.offset_right = -UiTokens.SAFE_MARGIN
	_header.offset_top = UiTokens.SAFE_MARGIN
	_header.offset_bottom = UiTokens.SAFE_MARGIN + UiTokens.MENU_CLOSE_SIZE
	_header.add_theme_constant_override(&"separation", UiTokens.GAP)
	_build_status()
	_clock.activity_changed.connect(_on_clock_activity)
	# Jamais une puce sans nom (l'icône seule) : elle apparaît avec le nom de la zone.
	set_zone_name("")
	_close_button.custom_minimum_size = Vector2.ONE * UiTokens.MENU_CLOSE_SIZE
	_close_button.pressed.connect(_on_close_pressed)
	_host.offset_left = UiTokens.SAFE_MARGIN
	_host.offset_right = -UiTokens.SAFE_MARGIN
	_host.offset_top = UiTokens.MENU_BODY_TOP
	_host.offset_bottom = -UiTokens.SAFE_MARGIN
	var material := _backdrop.material as ShaderMaterial
	material.set_shader_parameter(&"blur_radius", UiTokens.MENU_BLUR_RADIUS)
	material.set_shader_parameter(&"blur_lod", UiTokens.MENU_BLUR_LOD)
	material.set_shader_parameter(&"blur_on", _blur_enabled)
	material.set_shader_parameter(&"dim", UiTokens.MENU_DIM)
	material.set_shader_parameter(&"dim_color", UiTokens.SURFACE_DARK)

	_dashboard = DashboardScreen.new()
	_dashboard.card_chosen.connect(_on_card_chosen)
	_dashboard.lead_chosen.connect(_on_lead_chosen)
	_dashboard.route_requested.connect(route_requested.emit)
	_placeholder = PlaceholderScreen.new()
	_placeholder.back_requested.connect(back_requested.emit)
	for screen: MenuScreen in _screens():
		_host.add_child(screen)
		screen.speed_scale = speed_scale
		screen.hide_now()
	_set_amount(0.0)
	_root.visible = false


## Coroutine : ouvre le menu (fond 0 → 1 puis tableau de bord, MENU_OPEN) avec une vibration
## légère. Coupe un fondu de fermeture en cours (le fond repart de là où il en était).
func open_animated() -> void:
	_open = true
	_kill_tween()
	_refresh_header()
	_root.visible = true
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	Haptics.vibrate(UiTokens.HAPTIC_MENU_MS)
	var time := UiTokens.MENU_OPEN * speed_scale
	if time > 0.0 and _amount < 1.0:
		_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_method(_set_amount, _amount, 1.0, time)
	else:
		_set_amount(1.0)
	if _current != null and not _entered:
		_entered = true
		await _current.enter()
	elif _tween != null:
		await _tween.finished


## Coroutine : ferme le menu (MENU_CLOSE) ; invisible à la fin, plus rien ne reçoit le toucher.
func close_animated() -> void:
	_open = false
	if _shop_choice != null and _shop_choice.is_showing():
		_shop_choice.hide_choice()
	while _storage != null and _storage.go_back():
		pass
	_kill_tween()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var leaving := _current if _entered else null
	_current = null
	_entered = false
	var time := UiTokens.MENU_CLOSE * speed_scale
	if time > 0.0:
		_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
		_tween.tween_method(_set_amount, _amount, 0.0, time)
		if leaving != null:
			_tween.tween_property(leaving, ^"modulate:a", 0.0, time)
		await _tween.finished
	_set_amount(0.0)
	for screen: MenuScreen in _screens():
		screen.hide_now()
	_root.visible = false


## Pose [param view] sur le tableau de bord (en-tête compris : le nom de la zone) et l'affiche.
func show_dashboard(view: DashboardView) -> void:
	set_zone_name(view.zone_name)
	_dashboard.show_dashboard(view)
	_select(_dashboard)
	_fit_prefs(_dashboard)


## Nom de la zone dans l'en-tête commun à tous les écrans (« Route 1 ») ; vide : pastille cachée.
## Gardé tant qu'un autre nom n'est pas donné (Équipe, Sac… ne le touchent pas).
func set_zone_name(zone_name: String) -> void:
	_zone_name.text = zone_name
	_refresh_header()


## Argent du bandeau d'état (« 3 840 ₽ ») ; vide : puce cachée. Gardé tant qu'une autre vue n'en
## donne pas (le Sac) ; montré seulement sur les écrans qui le demandent.
func set_money_text(text: String) -> void:
	_money_text = text
	_money_label.text = text
	_refresh_header()


## Horloge du monde interrogée par la puce « heure » (phase 10 : l'horloge du jeu).
func set_clock(clock: WorldClock) -> void:
	if _clock != null and _clock.activity_changed.is_connected(_on_clock_activity):
		_clock.activity_changed.disconnect(_on_clock_activity)
	_clock = clock if clock != null else WorldClock.new()
	_clock.activity_changed.connect(_on_clock_activity)
	_refresh_header()


func get_clock() -> WorldClock:
	return _clock


## Écran Équipe (6A) : [param view] et le Pokémon [param selected] sélectionné. Rappelé pendant
## que l'Équipe est affichée, il met à jour sans rejouer l'entrée (l'onglet reste ouvert).
func show_team(view: TeamView, selected: int) -> void:
	if _team == null:
		_team = TeamScreen.new()
		_team.speed_scale = speed_scale
		_team.back_requested.connect(back_requested.emit)
		_team.route_requested.connect(route_requested.emit)
		_team.member_selected.connect(team_member_selected.emit)
		_team.member_moved.connect(team_member_moved.emit)
		_team.favorite_toggled.connect(team_favorite_toggled.emit)
		_team.companion_toggled.connect(team_companion_toggled.emit)
		_team.field_move_requested.connect(team_field_move_requested.emit)
		_team.use_item_requested.connect(_on_team_use_item)
		_host.add_child(_team)
		_team.hide_now()
	_team.show_team(view, selected)
	_select(_team)
	_fit_prefs(_team)


## Écran Sac (6B) : [param view] (onglets, cartes, aperçu). Rappelé pendant que le Sac est
## affiché (après un usage, un favori, un tri), il met à jour sans rejouer l'entrée.
func show_bag(view: BagView) -> void:
	if _bag == null:
		_bag = BagScreen.new()
		_bag.speed_scale = speed_scale
		_bag.back_requested.connect(back_requested.emit)
		_bag.route_requested.connect(route_requested.emit)
		_bag.category_opened.connect(bag_category_opened.emit)
		_bag.favorite_toggled.connect(bag_favorite_toggled.emit)
		_bag.sort_changed.connect(bag_sort_changed.emit)
		_bag.use_requested.connect(bag_use_requested.emit)
		_bag.target_chosen.connect(bag_target_chosen.emit)
		_bag.repeat_requested.connect(bag_repeat_requested.emit)
		_host.add_child(_bag)
		_bag.hide_now()
	set_money_text(view.money_text)
	_bag.show_bag(view)
	_select(_bag)
	_fit_prefs(_bag)


## Écran Pokédex (6C) : [param view] (en-tête, filtres, grille). Rappelé pendant que le Pokédex
## est affiché (filtre, recherche), il met à jour sans rejouer l'entrée ; la fiche reste ouverte.
func show_pokedex(view: PokedexGridView) -> void:
	if _pokedex == null:
		_pokedex = PokedexScreen.new()
		_pokedex.speed_scale = speed_scale
		_pokedex.back_requested.connect(back_requested.emit)
		_pokedex.route_requested.connect(route_requested.emit)
		_pokedex.filter_changed.connect(pokedex_filter_changed.emit)
		_pokedex.species_opened.connect(pokedex_species_opened.emit)
		_pokedex.cry_requested.connect(pokedex_cry_requested.emit)
		_host.add_child(_pokedex)
		_pokedex.hide_now()
	_pokedex.show_grid(view)
	_select(_pokedex)
	_fit_prefs(_pokedex)


## La fiche d'une espèce, à droite de la grille du Pokédex.
func show_pokedex_sheet(view: PokedexSheetView) -> void:
	if _pokedex != null:
		_pokedex.show_sheet(view)
		_fit_prefs(_pokedex)


## Retour (retour Android, Échap) : referme la fiche du Pokédex si elle est ouverte. Vrai si
## c'est ce qui s'est passé (l'événement est consommé) ; faux : le retour suit son cours.
func pokedex_back() -> bool:
	return _pokedex != null and _current == _pokedex and _pokedex.close_sheet()


## Écran Carte (6D) : [param view] (illustration, zones découvertes, portrait). Rappelé pendant
## que la Carte est affichée, il met à jour sans rejouer l'entrée.
func show_map(view: MapView) -> void:
	if _map == null:
		_map = MapScreen.new()
		_map.speed_scale = speed_scale
		_map.back_requested.connect(back_requested.emit)
		_map.route_requested.connect(route_requested.emit)
		_map.zone_touched.connect(map_zone_touched.emit)
		_map.fly_requested.connect(map_fly_requested.emit)
		_host.add_child(_map)
		_map.hide_now()
	_map.show_map(view)
	_select(_map)
	_fit_prefs(_map)


## Écran Dresseur (6E) : [param view] (identité, badges, grands moments, statistiques). Rappelé
## pendant que l'écran est affiché, il met à jour sans rejouer l'entrée. Ses liens (vus,
## capturés, moments) passent par [signal route_requested], tels que la vue les fournit.
func show_trainer(view: TrainerView) -> void:
	if _trainer == null:
		_trainer = TrainerScreen.new()
		_trainer.speed_scale = speed_scale
		_trainer.back_requested.connect(back_requested.emit)
		_trainer.route_requested.connect(route_requested.emit)
		_trainer.hall_of_fame_requested.connect(hall_of_fame_requested.emit)
		_host.add_child(_trainer)
		_trainer.hide_now()
	_trainer.show_trainer(view)
	_select(_trainer)
	_fit_prefs(_trainer)


## Écran Paramètres (6F) : [param view] (catégories et contrôles). Rappelé pendant que l'écran
## est affiché (le directeur renvoie la vue neuve après chaque changement), il met à jour sans
## rejouer l'entrée : la catégorie ouverte et le défilement restent.
func show_settings(view: SettingsView) -> void:
	if _settings == null:
		_settings = SettingsScreen.new()
		_settings.speed_scale = speed_scale
		_settings.back_requested.connect(back_requested.emit)
		_settings.setting_changed.connect(setting_changed.emit)
		_settings.save_now_requested.connect(save_now_requested.emit)
		_host.add_child(_settings)
		_settings.hide_now()
	_settings.show_settings(view)
	_select(_settings)
	_fit_prefs(_settings)


## Écran Boutique (7A.3) : [param view] (onglet, argent, objets). Écran seul : ni tableau de bord,
## ni pastille de zone. Rappelé pendant qu'il est affiché (après un achat ou une vente), il met à
## jour sans rejouer l'entrée : objet sélectionné et quantité sont gardés s'ils existent encore.
func show_shop(view: ShopView) -> void:
	if _shop == null:
		_shop = ShopScreen.new()
		_shop.speed_scale = speed_scale
		_shop.back_requested.connect(back_requested.emit)
		_shop.mode_changed.connect(shop_mode_changed.emit)
		_shop.buy_requested.connect(shop_buy_requested.emit)
		_shop.sell_requested.connect(shop_sell_requested.emit)
		_host.add_child(_shop)
		_shop.hide_now()
	set_zone_name("")
	_shop.show_shop(view)
	_select(_shop)
	_fit_prefs(_shop)


## « Merci ! » ([param ok]) ou le refus (CONFIRMER tremble), dans la barre de résultat de la
## Boutique.
func show_shop_result(text: String, ok: bool) -> void:
	if _shop != null:
		_shop.show_result(text, ok)
		_fit_prefs(_shop)


## La confirmation de la vente d'un favori ([param view], ChoiceCards) : VENDRE → un
## [signal shop_sell_requested] avec confirmed = vrai ; ANNULER (ou [method shop_back]) → rien.
func show_shop_confirm(view: ChoiceView, item_id: StringName, quantity: int) -> void:
	if _shop_choice == null:
		_shop_choice = ChoiceCards.new()
		_shop_choice.speed_scale = speed_scale
		_shop_choice.chosen.connect(_on_shop_choice)
		_root.add_child(_shop_choice)
	_shop_choice.speed_scale = speed_scale
	_shop_choice_item = item_id
	_shop_choice_quantity = quantity
	_shop_choice.show_choice(view)


## Retour (retour Android, Échap) : referme la confirmation de vente si elle est ouverte. Vrai si
## c'est ce qui s'est passé (l'événement est consommé) ; faux : l'hôte ferme la Boutique.
func shop_back() -> bool:
	if _shop_choice == null or not _shop_choice.is_showing():
		return false
	_shop_choice.hide_choice()
	return true


## Écran Stockage (7A.4) : [param view] (ÉQUIPE, Pokémon sélectionné et ses actions, STOCKAGE).
## Écran seul : ni tableau de bord, ni pastille de zone. Rappelé pendant qu'il est affiché (vue
## neuve après chaque action), il met à jour sans rejouer l'entrée.
func show_storage(view: StorageView) -> void:
	if _storage == null:
		_storage = StorageScreen.new()
		_storage.speed_scale = speed_scale
		_storage.back_requested.connect(back_requested.emit)
		_storage.selected.connect(storage_selected.emit)
		_storage.deposit_requested.connect(storage_deposit_requested.emit)
		_storage.withdraw_requested.connect(storage_withdraw_requested.emit)
		_storage.favorite_toggled.connect(storage_favorite_toggled.emit)
		_storage.release_requested.connect(storage_release_requested.emit)
		_storage.release_confirmed.connect(storage_release_confirmed.emit)
		_host.add_child(_storage)
		_storage.hide_now()
	set_zone_name("")
	_storage.show_storage(view)
	_select(_storage)
	_fit_prefs(_storage)


## Refus du directeur : la carte ([param place], [param index]) tremble et [param text] dit
## pourquoi (aucune vue neuve).
func show_storage_refusal(place: int, index: int, text: String) -> void:
	if _storage != null:
		_storage.show_refusal(place, index, text)
		_fit_prefs(_storage)


## La confirmation de LIBÉRER ([param view], ChoiceCards) pour la carte ([param place],
## [param index]) : LIBÉRER → [signal storage_release_confirmed] ; ANNULER (ou
## [method storage_back]) → rien.
func ask_storage_release(view: ChoiceView, place: int, index: int) -> void:
	if _storage != null:
		_storage.ask_release(view, place, index)


## Retour (retour Android, Échap) : ferme la confirmation de LIBÉRER ou le menu « ⋯ » s'ils sont
## ouverts. Vrai si c'est ce qui s'est passé (l'événement est consommé) ; faux : l'hôte
## quitte l'écran.
func storage_back() -> bool:
	return _storage != null and _current == _storage and _storage.go_back()


## Message bref de l'écran Paramètres (« Partie sauvegardée ») : le toast du monde serait sous
## le menu.
func show_save_result(text: String) -> void:
	if _settings != null:
		_settings.show_save_result(text)


## Flou du fond du menu (graphismes « Économie » : faux, le voile est gardé).
func set_backdrop_blur(enabled: bool) -> void:
	_blur_enabled = enabled
	(_backdrop.material as ShaderMaterial).set_shader_parameter(&"blur_on", enabled)


func is_backdrop_blur_enabled() -> bool:
	return _blur_enabled


## Le panneau d'une zone découverte, à droite de l'illustration (sans changer d'écran).
func show_map_zone(view: ZonePanelView) -> void:
	if _map != null:
		_map.show_zone(view)
		_fit_prefs(_map)


## Le choix du Pokémon dans le Sac (UTILISER), dans l'écran Sac.
func show_bag_targets(view: PartyPickerView) -> void:
	if _bag != null:
		_bag.show_targets(view)
		_fit_prefs(_bag)


## Le résultat d'un usage (UseResultBar) dans l'écran Sac.
func show_bag_result(text: String, can_repeat: bool) -> void:
	if _bag != null:
		_bag.show_result(text, can_repeat)
		_fit_prefs(_bag)


## Retour (retour Android, Échap) : referme le choix du Pokémon du Sac s'il est ouvert. Vrai si
## c'est ce qui s'est passé (l'événement est consommé) ; faux : le retour suit son cours.
func bag_back() -> bool:
	return _bag != null and _current == _bag and _bag.go_back()


## Écran provisoire « ÉQUIPE — À venir » avec son RETOUR.
func show_placeholder(screen: StringName) -> void:
	_placeholder.set_screen_title(PLACEHOLDER_TITLES.get(screen, String(screen)))
	_select(_placeholder)


## Vrai d'open_animated jusqu'au début de close_animated.
func is_open() -> bool:
	return _open


func get_dashboard() -> DashboardScreen:
	return _dashboard


func get_placeholder() -> PlaceholderScreen:
	return _placeholder


## L'écran Sac (null avant la première visite).
func get_bag() -> BagScreen:
	return _bag


## L'écran Pokédex (null avant la première visite).
func get_pokedex() -> PokedexScreen:
	return _pokedex


## L'écran Équipe (null avant la première visite).
func get_team() -> TeamScreen:
	return _team


## Passe systèmes 2 (T25b) : refus d'une capacité de voyage, dans le bandeau de l'Équipe.
func show_team_notice(text: String) -> void:
	if _team != null:
		_team.show_notice(text)


## L'écran Carte (null avant la première visite).
func get_map() -> MapScreen:
	return _map


## L'écran Dresseur (null avant la première visite).
func get_trainer() -> TrainerScreen:
	return _trainer


## L'écran Boutique (null avant la première visite).
func get_shop() -> ShopScreen:
	return _shop


## La confirmation de vente d'un favori (null avant le premier besoin).
func get_shop_choice() -> ChoiceCards:
	return _shop_choice


## L'écran Stockage (null avant la première visite).
func get_storage() -> StorageScreen:
	return _storage


## L'écran Paramètres (null avant la première visite).
func get_settings() -> SettingsScreen:
	return _settings


func get_close_button() -> Button:
	return _close_button


func get_zone_label() -> Label:
	return _zone_name


## Puce du lieu dans le bandeau d'état.
func get_zone_pill() -> Control:
	return _zone_pill


func get_status_bar() -> PanelContainer:
	return _status


## Puce « heure » (cachée tant que l'horloge est inactive).
func get_clock_chip() -> Control:
	return _clock_chip


func get_clock_text() -> String:
	return _clock_label.text if _clock_chip.visible else ""


## Puce « argent » ; [method get_money_text] : "" si cachée.
func get_money_chip() -> Control:
	return _money_chip


func get_money_text() -> String:
	return _money_label.text if _money_chip.visible else ""


func get_backdrop() -> ColorRect:
	return _backdrop


func get_root() -> Control:
	return _root


## Écran courant (null : aucun, menu fermé ou pas encore rempli).
func get_current_screen() -> MenuScreen:
	return _current


## Opacité du fond (0 : monde net, 1 : flou et assombri) ; l'en-tête la suit.
func get_amount() -> float:
	return _amount


func _screens() -> Array[MenuScreen]:
	var screens: Array[MenuScreen] = []
	if _dashboard != null:
		screens.append(_dashboard)
	if _placeholder != null:
		screens.append(_placeholder)
	if _team != null:
		screens.append(_team)
	if _bag != null:
		screens.append(_bag)
	if _pokedex != null:
		screens.append(_pokedex)
	if _map != null:
		screens.append(_map)
	if _trainer != null:
		screens.append(_trainer)
	if _settings != null:
		screens.append(_settings)
	if _shop != null:
		screens.append(_shop)
	if _storage != null:
		screens.append(_storage)
	return screens


## En-tête selon l'écran courant : × (sauf si l'écran a son « ‹ »), puces du bandeau d'état
## (lieu avec un nom, heure si l'horloge tourne, argent si l'écran le demande), séparateurs
## entre les puces visibles ; bandeau caché s'il n'a rien à montrer.
func _refresh_header() -> void:
	if _status == null:
		return
	_close_button.visible = _current == null or not _current.owns_back
	var allowed := _current == null or _current.status_bar
	_zone_pill.visible = allowed and not _zone_name.text.is_empty()
	_clock_label.text = _clock.time_text()
	_clock_chip.visible = allowed and not _clock_label.text.is_empty()
	_money_chip.visible = allowed and _current != null and _current.status_money \
		and not _money_text.is_empty()
	var chips: Array[Control] = [_zone_pill, _clock_chip, _money_chip]
	var shown := 0
	for i: int in chips.size():
		if i > 0:
			_dividers[i - 1].visible = chips[i].visible and shown > 0
		if chips[i].visible:
			shown += 1
	_status.visible = shown > 0


func _build_status() -> void:
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_child(spacer)
	_status = PanelContainer.new()
	_status.name = "StatusBar"
	_status.theme_type_variation = &"MenuStatusBar"
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.custom_minimum_size.y = UiTokens.MENU_STATUS_DRAW
	_status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_header.add_child(_status)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.MENU_STATUS_GAP * 2)
	_status.add_child(row)
	_zone_pill = _chip(row, PIN_ICON)
	_zone_name = _zone_pill.get_child(1) as Label
	_dividers.append(_divider(row))
	_clock_chip = _chip(row, CLOCK_ICON)
	_clock_label = _clock_chip.get_child(1) as Label
	_dividers.append(_divider(row))
	_money_chip = _chip(row, COIN_ICON)
	_money_label = _money_chip.get_child(1) as Label
	(_money_chip.get_child(0) as TextureRect).modulate = UiTokens.ACCENT


func _chip(parent: Control, icon: Texture2D) -> HBoxContainer:
	var chip := HBoxContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_constant_override(&"separation", UiTokens.MENU_STATUS_GAP)
	parent.add_child(chip)
	var picture := TextureRect.new()
	picture.texture = icon
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.custom_minimum_size = Vector2.ONE * UiTokens.MENU_STATUS_ICON
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.add_child(picture)
	var label := Label.new()
	label.theme_type_variation = &"MenuStatusText"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(label)
	return chip


func _divider(parent: Control) -> Panel:
	var divider := Panel.new()
	divider.theme_type_variation = &"MenuStatusDivider"
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.custom_minimum_size = UiTokens.MENU_STATUS_DIVIDER_SIZE
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(divider)
	return divider


func _on_clock_activity(_active: bool) -> void:
	_refresh_header()


## Change d'écran : l'ancien se fond, le nouveau entre. Menu fermé : choisi mais pas encore
## présenté (open_animated le fera).
func _select(screen: MenuScreen) -> void:
	if screen == _current and _entered:
		return
	var previous := _current
	if previous != null and previous != screen and _entered:
		previous.leave()
	_current = screen
	_refresh_header()
	_apply_backdrop(screen)
	if _open:
		_entered = true
		screen.enter()
	else:
		_entered = false
		screen.hide_now()


## Remet en forme [param screen] selon [UiPrefs] (taille du texte, contraste) : à chaque
## affichage tant que les préférences ne sont pas celles par défaut, et une fois par écran quand
## elles y reviennent (les surcharges posées sont retirées).
func _fit_prefs(screen: MenuScreen) -> void:
	if UiPrefsApplier.is_neutral() and _prefs_fitted.get(screen, -1) == UiPrefs.revision:
		return
	UiPrefsApplier.apply(screen)
	_prefs_fitted[screen] = UiPrefs.revision


## Voile et flou du fond selon l'écran affiché (valeurs du menu si l'écran n'en a pas).
func _apply_backdrop(screen: MenuScreen) -> void:
	var material := _backdrop.material as ShaderMaterial
	material.set_shader_parameter(&"dim",
		screen.backdrop_dim if screen.backdrop_dim >= 0.0 else UiTokens.MENU_DIM)
	material.set_shader_parameter(&"blur_radius",
		screen.backdrop_blur if screen.backdrop_blur >= 0.0 else UiTokens.MENU_BLUR_RADIUS)
	material.set_shader_parameter(&"blur_lod",
		screen.backdrop_lod if screen.backdrop_lod >= 0.0 else UiTokens.MENU_BLUR_LOD)


func _set_amount(value: float) -> void:
	_amount = value
	(_backdrop.material as ShaderMaterial).set_shader_parameter(&"amount", value)
	_header.modulate.a = value


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


func _on_close_pressed() -> void:
	if not _open:
		return
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	close_requested.emit()


func _on_card_chosen(screen: StringName) -> void:
	route_requested.emit(MenuRoute.for_screen(screen))


func _on_shop_choice(confirmed: bool) -> void:
	if confirmed:
		shop_sell_requested.emit(_shop_choice_item, _shop_choice_quantity, true)


func _on_lead_chosen() -> void:
	route_requested.emit(MenuRoute.team(0))


## UTILISER UN OBJET : lien croisé vers le Sac, filtré sur ce Pokémon (dossier 08 §6, 6B).
func _on_team_use_item(index: int) -> void:
	route_requested.emit(MenuRoute.bag(MenuRoute.BAG_CONTEXT_TEAM, index))
