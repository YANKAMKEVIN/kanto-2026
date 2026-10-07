class_name BattleHud
extends CanvasLayer
## Interface de combat assemblée (jalon 4B, combat-v1 et combat-capacites-v1) : les deux
## cartes d'information, les pastilles d'équipe, et en bas à droite UNE seule zone à la fois
## (grille d'actions, OU capacités avec « ‹ », OU bandeau des messages).
##
## Elle est pilotée de l'extérieur et ne connaît que des vues (BattleCardView,
## BattleMoveView), des entiers et des chaînes : ni le moteur, ni les données, ni le monde.
## Côtés : son propre enum Side (celui qui la pilote traduit ses propres camps). Les
## signatures l'écrivent BattleHud.Side : « Side » seul désigne l'enum global de Godot
## (SIDE_LEFT…).
## Placement : BattleHudLayout (chaque composant ancré à un coin, de 1920 à 2340 de large).
##
## Zones du bas : la nouvelle n'entre qu'une fois la précédente sortie (glissement + fondu,
## BATTLE_PANEL_CLOSE) : grille et message ne sont jamais visibles ensemble. « ‹ » ramène
## elle-même des capacités à la grille (mêmes actions qu'au dernier show_actions), puis émet
## back_requested. Un toucher = un seul action_selected / move_selected ; une pression longue
## sur une capacité ouvre sa fiche sans rien lancer (MoveGrid).

enum Side { PLAYER, FOE }
## Zone affichée en bas à droite.
enum Zone { NONE, ACTIONS, MOVES, MESSAGE }

## Action choisie dans la grille : &"attack", &"bag", &"team" ou &"run" (ActionGrid).
signal action_selected(action: StringName)
## Capacité touchée (index 0 à 3 de la liste passée à show_moves).
signal move_selected(index: int)
## « ‹ » touché (ou Échap) depuis les capacités ; la grille d'actions revient déjà seule.
signal back_requested
## Vibration demandée par un composant (millisecondes), même si haptics_enabled est faux.
signal haptic_played(duration_ms: int)

## Durées multipliées (0 = instantané, pour les tests) ; relayé à tous les composants.
var speed_scale: float = 1.0:
	set(value):
		speed_scale = value
		_relay_settings()
## Tenue des messages du bandeau, séparée de [member speed_scale] : réduire les animations
## ne raccourcit pas la lecture (jalon-06.md §6.12).
var message_hold_scale: float = 1.0:
	set(value):
		message_hold_scale = value
		if is_node_ready():
			_banner.hold_scale = value
## Faux en test : aucune vibration réelle (haptic_played est quand même émis).
var haptics_enabled: bool = true:
	set(value):
		haptics_enabled = value
		_relay_settings()

var _zone: Zone = Zone.NONE
## Change à chaque changement de zone : une bascule dépassée par une plus récente s'arrête.
var _serial: int = 0
var _enabled: Dictionary[StringName, bool] = {}

@onready var _screen: Control = %Screen
@onready var _foe_card: BattleInfoCard = %FoeCard
@onready var _own_card: BattleInfoCard = %OwnCard
@onready var _pips: PartyPips = %PartyPips
@onready var _actions: ActionGrid = %ActionGrid
@onready var _moves: MoveGrid = %MoveGrid
@onready var _back: BattleBackButton = %BackButton
@onready var _banner: BattleMessageBanner = %MessageBanner


func _ready() -> void:
	layer = UiTokens.LAYER_BATTLE_HUD
	var slots: Dictionary[BattleWidget, BattleHudLayout.Slot] = {
		_foe_card: BattleHudLayout.Slot.FOE_CARD,
		_own_card: BattleHudLayout.Slot.OWN_CARD,
		_pips: BattleHudLayout.Slot.PARTY_PIPS,
		_banner: BattleHudLayout.Slot.MESSAGE,
		_actions: BattleHudLayout.Slot.ACTIONS,
		_moves: BattleHudLayout.Slot.MOVES,
		_back: BattleHudLayout.Slot.BACK,
	}
	for widget: BattleWidget in slots:
		BattleHudLayout.place(widget, slots[widget])
		widget.haptic_played.connect(haptic_played.emit)
	# Chaque carte entre par son bord d'écran le plus proche.
	_foe_card.slide_direction = Vector2.LEFT
	_own_card.slide_direction = Vector2.RIGHT
	_actions.action_selected.connect(action_selected.emit)
	_moves.move_selected.connect(move_selected.emit)
	_back.back_requested.connect(_on_back)
	_relay_settings()


## Remplit la carte de [param side] avec [param view] ; elle glisse en place si elle était
## cachée (avec les pastilles d'équipe pour le joueur). Vue invalide : erreur, rien ne change.
func set_card(side: BattleHud.Side, view: BattleCardView) -> void:
	if view == null or not view.is_valid():
		push_error("BattleHud : vue de carte invalide")
		return
	var card := get_card(side)
	card.set_view(view)
	card.slide_in()
	if side == Side.PLAYER:
		_pips.slide_in()


## Fait sortir la carte de [param side] (K.O.) ; celle du joueur emporte les pastilles.
func hide_card(side: BattleHud.Side) -> void:
	get_card(side).slide_out()
	if side == Side.PLAYER:
		_pips.slide_out()


## Coroutine : PV de [param side] animés jusqu'à [param hp] / [param max_hp], plus vite si
## [param big] (gros coup). Se termine quand la barre a atteint la valeur.
func animate_hp(side: BattleHud.Side, hp: int, max_hp: int, big: bool) -> void:
	await get_card(side).animate_hp(hp, max_hp, big)


## Coroutine (carte du joueur, jalon 5C) : la barre d'XP glisse de [param from] à [param to]
## (fractions 0..1 d'une tranche de niveau) en EXP_TWEEN et « +[param gained] XP » monte en
## s'effaçant (rien si [param gained] vaut 0 : tranches suivantes d'une montée de plusieurs
## niveaux). Se termine à la fin des deux ; la barre disparaît ensuite d'elle-même, sauf si
## la tranche suivante la reprend aussitôt.
func animate_exp(from: float, to: float, gained: int = 0) -> void:
	await _own_card.animate_exp(from, to, gained)


## Coroutine : « Nv. » de la carte de [param side] prend [param level] et pulse un instant
## (ANIM_MICRO). Aucune fenêtre ; les nouveaux PV max passent par animate_hp.
func pulse_level(side: BattleHud.Side, level: int) -> void:
	await get_card(side).pulse_level(level)


## « Nv. » de la carte de [param side] prend [param level], sans pulsation (montée de niveau
## pendant le combat : le bilan de fin de combat la raconte, demande n° 1).
func set_level(side: BattleHud.Side, level: int) -> void:
	get_card(side).set_level(level)


## Coup reçu par [param side] : vibration HAPTIC_HIT_MS, HAPTIC_CRIT_MS si [param critical].
func play_hit(side: BattleHud.Side, critical: bool) -> void:
	get_card(side).play_hit(critical)


## [param count] Pokémon dans l'équipe du joueur (pastilles pleines, le reste gris).
func set_party(count: int) -> void:
	_pips.set_party(count)


## Montre la grille d'actions (après la sortie de la zone affichée) : ATTAQUER, SAC, ÉQUIPE,
## FUITE selon [param enabled] (action absente = indisponible : atténuée et muette).
func show_actions(enabled: Dictionary[StringName, bool]) -> void:
	_enabled.clear()
	for action: StringName in ActionGrid.ACTIONS:
		_enabled[action] = enabled.get(action, false)
	_open_actions()


## Montre les capacités [param views] (4 au plus) et « ‹ », après la sortie de la zone
## affichée.
func show_moves(views: Array[BattleMoveView]) -> void:
	_open_moves(views.duplicate())


## Coroutine : affiche [param text] dans le bandeau (après la sortie de la zone affichée) et
## attend BATTLE_MESSAGE_HOLD ou un toucher. Le bandeau reste ensuite jusqu'à la zone
## suivante ou hide_all.
## [param wait_touch] : la phrase attend un toucher (phrase importante).
func show_message(text: String, wait_touch: bool = false) -> void:
	if not await _switch(Zone.MESSAGE):
		return
	await _banner.show_message(text, wait_touch)


## Coroutine : fait sortir la zone du bas (grille, capacités, « ‹ », bandeau) et attend sa
## sortie ; les cartes et les pastilles restent. Sert au Sac de combat (jalon 5D), qui prend la
## place des actions, et au lancer de la Ball, qui se joue sans bandeau.
func hide_zone() -> void:
	await _switch(Zone.NONE)


## Coroutine : fait sortir tout ce qui est affiché (cartes, pastilles, zone du bas) et attend
## la fin des animations.
func hide_all() -> void:
	_zone = Zone.NONE
	_serial += 1
	_banner.skip()
	await _slide_out_all(_widgets())


## Quelque chose est affiché (ou en train d'apparaître).
func is_shown() -> bool:
	for widget: BattleWidget in _widgets():
		if widget.is_shown():
			return true
	return false


## Zone du bas demandée en dernier (elle peut être encore en train d'entrer).
func get_zone() -> Zone:
	return _zone


func get_card(side: BattleHud.Side) -> BattleInfoCard:
	return _own_card if side == Side.PLAYER else _foe_card


func get_party_pips() -> PartyPips:
	return _pips


func get_action_grid() -> ActionGrid:
	return _actions


func get_move_grid() -> MoveGrid:
	return _moves


func get_back_button() -> BattleBackButton:
	return _back


func get_message_banner() -> BattleMessageBanner:
	return _banner


## Racine plein écran des composants (les tests lui donnent une taille d'écran).
func get_screen() -> Control:
	return _screen


func _open_actions() -> void:
	if not await _switch(Zone.ACTIONS):
		return
	_actions.show_actions(_enabled)


func _open_moves(views: Array[BattleMoveView]) -> void:
	if not await _switch(Zone.MOVES):
		return
	_moves.show_moves(views)
	_back.slide_in()


## Coroutine : [param zone] devient la zone du bas ; les composants des autres zones sortent
## et on attend leur sortie. Faux si une bascule plus récente l'a dépassée entre-temps.
func _switch(zone: Zone) -> bool:
	_zone = zone
	_serial += 1
	var serial := _serial
	var leaving: Array[BattleWidget] = []
	if zone != Zone.ACTIONS:
		leaving.append(_actions)
	if zone != Zone.MOVES:
		leaving.append_array([_moves, _back])
	if zone != Zone.MESSAGE:
		_banner.skip()
		leaving.append(_banner)
	await _slide_out_all(leaving)
	return serial == _serial


## Coroutine : fait sortir en même temps ceux de [param widgets] qui sont affichés et attend
## qu'aucun ne soit plus en mouvement (immédiat si speed_scale vaut 0).
func _slide_out_all(widgets: Array[BattleWidget]) -> void:
	var moving: Array[BattleWidget] = []
	for widget: BattleWidget in widgets:
		if widget.is_shown():
			widget.slide_out()
			moving.append(widget)
	while moving.any(func(widget: BattleWidget) -> bool: return widget.is_sliding()):
		await get_tree().process_frame


func _on_back() -> void:
	if _zone != Zone.MOVES:
		return
	_open_actions()
	back_requested.emit()


func _widgets() -> Array[BattleWidget]:
	return [_foe_card, _own_card, _pips, _actions, _moves, _back, _banner]


func _relay_settings() -> void:
	if not is_node_ready():
		return
	for widget: BattleWidget in _widgets():
		widget.speed_scale = speed_scale
		widget.haptics_enabled = haptics_enabled
	_banner.hold_scale = message_hold_scale
