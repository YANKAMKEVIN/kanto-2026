class_name TrainerMenu
extends CanvasLayer
## Menu Dresseur (jalon-06.md §6.2, §6.6 ; dossier 08) : calque LAYER_MENU qui pose un fond
## (le monde flouté et assombri) puis l'écran courant (au départ le tableau de bord), avec
## l'en-tête commun : × à gauche et nom de la zone actuelle.
##
## Il ne décide de rien : il affiche ce qu'on lui donne (vues) et relaie ce que le doigt fait
## (signaux) ; c'est [code]Boot[/code] (T4) qui le relie au directeur du menu.
## - × : un seul [signal close_requested] par toucher.
## - Carte touchée : [signal route_requested] avec [method MenuRoute.for_screen] ; Pokémon de
##   tête : MenuRoute.team(0).
## - [signal back_requested] : le RETOUR d'un écran (jamais depuis le tableau de bord).
## Il tourne même quand l'arbre est en pause (process_mode ALWAYS : le monde est en pause
## derrière lui).
## Placement (aspect expand, 1920 à 2340 de large) : en-tête ancré en haut, × à
## SAFE_MARGIN ; les écrans occupent la zone sous l'en-tête, à SAFE_MARGIN des bords.

## Une carte (ou le Pokémon de tête, ou un lien croisé) demande un écran.
signal route_requested(route: MenuRoute)
## RETOUR d'un écran.
signal back_requested
## × touché.
signal close_requested
## Relais de l'écran Équipe (6A) : Pokémon sélectionné, échange A ↔ B, favori basculé.
signal team_member_selected(index: int)
signal team_member_moved(from: int, to: int)
signal team_favorite_toggled(index: int)
## Relais de l'écran Sac (6B) : onglet ouvert, favori basculé (appui long), tri choisi, UTILISER,
## cible choisie, UTILISER À NOUVEAU.
signal bag_category_opened(category: StringName)
signal bag_favorite_toggled(item_id: StringName)
signal bag_sort_changed(sort: int)
signal bag_use_requested(item_id: StringName)
signal bag_target_chosen(item_id: StringName, index: int)
signal bag_repeat_requested

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

@onready var _root: Control = %Root
@onready var _backdrop: ColorRect = %Backdrop
@onready var _header: HBoxContainer = %Header
@onready var _close_button: Button = %CloseButton
@onready var _zone_pill: PanelContainer = %ZonePill
@onready var _zone_name: Label = %ZoneName
@onready var _host: Control = %Host


func _ready() -> void:
	layer = UiTokens.LAYER_MENU
	process_mode = Node.PROCESS_MODE_ALWAYS
	_header.offset_left = UiTokens.SAFE_MARGIN
	_header.offset_right = -UiTokens.SAFE_MARGIN
	_header.offset_top = UiTokens.SAFE_MARGIN
	_header.offset_bottom = UiTokens.SAFE_MARGIN + UiTokens.MENU_CLOSE_SIZE
	_header.add_theme_constant_override(&"separation", UiTokens.GAP)
	# Jamais une pastille sans nom (l'icône seule) : elle apparaît avec le nom de la zone.
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
	_root.visible = true
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	Input.vibrate_handheld(UiTokens.HAPTIC_MENU_MS)
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


## Nom de la zone dans l'en-tête commun à tous les écrans (« Route 1 ») ; vide : pastille cachée.
## Gardé tant qu'un autre nom n'est pas donné (Équipe, Sac… ne le touchent pas).
func set_zone_name(zone_name: String) -> void:
	_zone_name.text = zone_name
	_zone_pill.visible = not zone_name.is_empty()


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
		_team.use_item_requested.connect(_on_team_use_item)
		_host.add_child(_team)
		_team.hide_now()
	_team.show_team(view, selected)
	_select(_team)


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
	_bag.show_bag(view)
	_select(_bag)


## Le choix du Pokémon dans le Sac (UTILISER), dans l'écran Sac.
func show_bag_targets(view: PartyPickerView) -> void:
	if _bag != null:
		_bag.show_targets(view)


## Le résultat d'un usage (UseResultBar) dans l'écran Sac.
func show_bag_result(text: String, can_repeat: bool) -> void:
	if _bag != null:
		_bag.show_result(text, can_repeat)


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


## L'écran Équipe (null avant la première visite).
func get_team() -> TeamScreen:
	return _team


func get_close_button() -> Button:
	return _close_button


func get_zone_label() -> Label:
	return _zone_name


func get_zone_pill() -> PanelContainer:
	return _zone_pill


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
	return screens


## Change d'écran : l'ancien se fond, le nouveau entre. Menu fermé : choisi mais pas encore
## présenté (open_animated le fera).
func _select(screen: MenuScreen) -> void:
	if screen == _current and _entered:
		return
	var previous := _current
	if previous != null and previous != screen and _entered:
		previous.leave()
	_current = screen
	if _open:
		_entered = true
		screen.enter()
	else:
		_entered = false
		screen.hide_now()


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
	Input.vibrate_handheld(UiTokens.HAPTIC_TAP_MS)
	close_requested.emit()


func _on_card_chosen(screen: StringName) -> void:
	route_requested.emit(MenuRoute.for_screen(screen))


func _on_lead_chosen() -> void:
	route_requested.emit(MenuRoute.team(0))


## UTILISER UN OBJET : lien croisé vers le Sac, filtré sur ce Pokémon (dossier 08 §6, 6B).
func _on_team_use_item(index: int) -> void:
	route_requested.emit(MenuRoute.bag(MenuRoute.BAG_CONTEXT_TEAM, index))
