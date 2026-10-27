class_name ServiceDirector
extends Node
## Actions de dialogue des services (jalon-07.md §3.3.2, §6.2) : le soin de Maman (`heal`), le
## soin d'un Centre Pokémon (`center_heal`), la Boutique (`open_shop`, T12) et le Stockage
## (`open_storage`, T16, le terminal du Centre). Branché par [Boot] comme
## [member DialogueRunner.action_handler] ([method run_action], coroutine attendue par le
## lecteur, joueur bloqué).
##
## Soin d'un Centre (dossier 09 §7) : l'équipe est soignée, puis le rituel se joue sur la
## machine du comptoir (`%HealMachine` de la carte, [HealMachine]) en
## [constant UiTokens.CENTER_HEAL] secondes (×0,5 avec « Réduire les animations »), le PNJ qui
## la sert se tourne vers elle puis revient, une vibration légère marque l'éclat ([Haptics]).
## Enfin le Centre devient le point de repos ([method RestPointLibrary.register]) et
## [signal center_healed] part : [Boot] écrit la sauvegarde et, si le point a changé, montre le
## toast « Point de repos enregistré — <zone> ». Sans machine (carte de test), le rituel est une
## simple attente de la même durée.
##
## Boutique (jalon-07.md §6.10) : `open_shop` demande la boutique **de la carte courante** (la
## boutique porte l'identifiant de sa carte : `viridian_mart`) par [signal shop_requested] et
## rend la main tout de suite. Le menu ne peut pas s'ouvrir pendant le dialogue (garde « partie
## stable ») : [Boot] l'ouvre en écran seul à la fin du dialogue.
##
## Stockage (jalon-07.md §6.9) : `open_storage` (le terminal, sans réplique) émet
## [signal storage_requested] de la même façon ; [Boot] ouvre `MenuRoute.storage()` en écran
## seul à la fin du dialogue (le Stockage n'existe qu'au Centre : [MenuUnlocks]).
##
## Pension (J15, jalon-15.md §2.5.3) : `open_daycare` (le gardien, sans réplique) émet
## [signal daycare_requested] ; [Boot] lance le [DaycareDirector] à la fin du dialogue.
##
## Ne lit aucun autoload : l'état de la partie et les points de repos arrivent par
## [method setup].

## Soin d'un Centre fini (équipe soignée, rituel joué, point de repos traité). [param registered] :
## vrai si le point de repos a changé (toast).
signal center_healed(map_id: StringName, registered: bool)
## Le marchand ouvre la Boutique [param shop_id] (= identifiant de la carte courante).
signal shop_requested(shop_id: StringName)
## Le terminal ouvre le Stockage (sur la carte courante).
signal storage_requested
## Le gardien de la Pension ouvre la conversation de la Pension (J15).
signal daycare_requested
## J20 (T13) : le panneau d'une cabine d'ascenseur (`open_elevator`) ; Boot ouvre le panneau à la
## fin du dialogue ([ElevatorDirector]).
signal elevator_requested
## J32 (T5) : le terminal d'échange local (`open_local_trade`) ; Boot lance le
## [LocalTradeDirector] à la fin du dialogue.
signal local_trade_requested

const ACTION_HEAL: StringName = &"heal"
const ACTION_CENTER_HEAL: StringName = &"center_heal"
const ACTION_OPEN_SHOP: StringName = &"open_shop"
const ACTION_OPEN_STORAGE: StringName = &"open_storage"
const ACTION_OPEN_DAYCARE: StringName = &"open_daycare"
const ACTION_OPEN_ELEVATOR: StringName = &"open_elevator" # J20
const ACTION_OPEN_LOCAL_TRADE: StringName = &"open_local_trade" # J32
const HEAL_MACHINE: NodePath = ^"%HealMachine"

## « Réduire les animations » (GameSettings.reduce_motion) : rituel deux fois plus court. Posé par
## [Boot] avec les réglages.
var reduce_motion: bool = false

var _state: Node
var _rest_points: RestPointLibrary
var _map: GameMap
var _running: bool = false


## [param state] : l'autoload GameState en jeu, une instance de game_state.gd en test.
func setup(state: Node, rest_points: RestPointLibrary) -> void:
	_state = state
	_rest_points = rest_points


## Carte courante (sa machine, son point de repos).
func set_map(map: GameMap) -> void:
	_map = map


## Vrai pendant une action (le rituel).
func is_running() -> bool:
	return _running


## Durée du rituel du Centre, réglages compris.
func ritual_duration() -> float:
	return UiTokens.CENTER_HEAL * (GameSettings.REDUCED_MENU_SPEED if reduce_motion else 1.0)


## Soin simple de toute l'équipe (PV, PP), sans rituel : Maman.
func heal() -> void:
	var party := _party()
	if party != null:
		party.heal_all()


## = [member DialogueRunner.action_handler]. Coroutine. Action inconnue : push_error, rien.
## [param shop] (jalon 20) : la boutique de `open_shop` (clé « shop » du dialogue) ; &"" = celle
## de la carte courante.
func run_action(action: StringName, shop: StringName = &"") -> void:
	match action:
		ACTION_HEAL:
			heal()
		ACTION_CENTER_HEAL:
			await _center_heal()
		ACTION_OPEN_SHOP:
			_open_shop(shop)
		ACTION_OPEN_STORAGE:
			_open_storage()
		ACTION_OPEN_DAYCARE:
			daycare_requested.emit()
		ACTION_OPEN_ELEVATOR:
			elevator_requested.emit()
		ACTION_OPEN_LOCAL_TRADE:
			local_trade_requested.emit()
		_:
			push_error("ServiceDirector : action inconnue « %s »" % action)


func _center_heal() -> void:
	_running = true
	heal()
	var map: GameMap = _map if is_instance_valid(_map) else null
	var machine: HealMachine = null
	if map != null:
		machine = map.get_node_or_null(HEAL_MACHINE) as HealMachine
	var attendant: Npc = null
	var rest_facing := Vector2i.ZERO
	if machine != null:
		attendant = map.get_npc(machine.attendant)
		if attendant != null:
			rest_facing = attendant.get_facing()
			attendant.face(machine.attendant_turn)
	var duration := ritual_duration()
	if machine != null:
		machine.flashed.connect(_on_flashed, CONNECT_ONE_SHOT)
		var party := _party()
		await machine.play_heal(duration, party.size() if party != null else 1)
		if machine.flashed.is_connected(_on_flashed):
			machine.flashed.disconnect(_on_flashed)
	else:
		# Tween d'attente plutôt que minuterie : même arrêt en pause (nœud pausable), et un
		# test peut le faire avancer en temps simulé.
		var wait := create_tween()
		wait.tween_interval(duration)
		await wait.finished
		_on_flashed()
	if is_instance_valid(attendant) and rest_facing != Vector2i.ZERO:
		attendant.face(rest_facing)
	var map_id: StringName = map.map_id if map != null else &""
	var point: RestPoint = _rest_points.get_point(map_id) if _rest_points != null else null
	var registered := RestPointLibrary.register(_state, point)
	_running = false
	center_healed.emit(map_id, registered)


## Boutique [param shop] si elle est donnée (jalon 20), sinon celle de la carte courante. Sans
## carte : push_error, rien (une boutique n'existe que sur sa carte).
func _open_shop(shop: StringName = &"") -> void:
	if not is_instance_valid(_map):
		push_error("ServiceDirector : open_shop sans carte courante")
		return
	shop_requested.emit(shop if not shop.is_empty() else _map.map_id)


## Sans carte : push_error, rien (un terminal n'existe que sur sa carte).
func _open_storage() -> void:
	if not is_instance_valid(_map):
		push_error("ServiceDirector : open_storage sans carte courante")
		return
	storage_requested.emit()


func _on_flashed() -> void:
	Haptics.vibrate(UiTokens.CENTER_HEAL_HAPTIC_MS)


func _party() -> Party:
	return _state.party as Party if _state != null else null
