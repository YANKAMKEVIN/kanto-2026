class_name ServiceDirector
extends Node
## Actions de dialogue des services (jalon-07.md §3.3.2, §6.2) : le soin de Maman (`heal`) et
## le soin d'un Centre Pokémon (`center_heal`) ; la Boutique (`open_shop`, T12) et le Stockage
## (`open_storage`, T16) viendront par la même porte. Branché par [Boot] comme
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
## Ne lit aucun autoload : l'état de la partie et les points de repos arrivent par
## [method setup].

## Soin d'un Centre fini (équipe soignée, rituel joué, point de repos traité). [param registered] :
## vrai si le point de repos a changé (toast).
signal center_healed(map_id: StringName, registered: bool)

const ACTION_HEAL: StringName = &"heal"
const ACTION_CENTER_HEAL: StringName = &"center_heal"
## Actions des tâches suivantes (même méthode) : signalées tant qu'elles ne sont pas branchées.
const PENDING_ACTIONS: Array[StringName] = [&"open_shop", &"open_storage"]
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
func run_action(action: StringName) -> void:
	match action:
		ACTION_HEAL:
			heal()
		ACTION_CENTER_HEAL:
			await _center_heal()
		_:
			if PENDING_ACTIONS.has(action):
				push_error("ServiceDirector : action « %s » pas encore branchée" % action)
			else:
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
		await get_tree().create_timer(duration, false).timeout
		_on_flashed()
	if is_instance_valid(attendant) and rest_facing != Vector2i.ZERO:
		attendant.face(rest_facing)
	var map_id: StringName = map.map_id if map != null else &""
	var point: RestPoint = _rest_points.get_point(map_id) if _rest_points != null else null
	var registered := RestPointLibrary.register(_state, point)
	_running = false
	center_healed.emit(map_id, registered)


func _on_flashed() -> void:
	Haptics.vibrate(UiTokens.CENTER_HEAL_HAPTIC_MS)


func _party() -> Party:
	return _state.party as Party if _state != null else null
