class_name AmbientWatcher
extends Node
## Fait réagir les Pokémon d'ambiance « shy » à l'approche du joueur (jalon 5 §3.5,
## dossier 04 §1 ; jalon 9 : dossier 10 §7, jalon-09.md §2.7.6).
##
## Écoute [signal Player.moved] ; pour chaque PNJ de la carte courante avec
## [member NpcSpec.shy_action] dont le joueur entre dans le rayon
## ([method AmbientRules.is_within]), joue sa réaction ([method play_reaction]) : envol
## ([method Npc.fly_away]), fuite ([method Npc.flee]) ou retrait vers le feuillage
## ([method Npc.retreat]) puis, à la fin ([signal Npc.left_scene]), retire le PNJ de la carte
## ([method GameMap.remove_npc]) ; « notice » ([method Npc.react]) le laisse en place, au plus
## une fois toutes les [constant NOTICE_COOLDOWN] s. Ils reviennent au prochain chargement de
## la carte (présence du fichier de données). Jamais de combat avec eux. Le watcher ne fait
## rien pendant une scène, un dialogue ou une transition (le joueur est alors bloqué :
## [method Player.is_input_enabled] est faux).

## Un Pokémon d'ambiance a réagi (tests, futurs sons).
signal reacted(npc_id: StringName, action: StringName)

## Nombre de pas de fuite d'un Rattata (dossier 04 §1 : « fuit facilement »).
const FLEE_STEPS: int = 3
## Pause minimale entre deux « notice » du même Pokémon (secondes ; défaut, jalon-09.md §2.7.6).
const NOTICE_COOLDOWN: float = 4.0

var _player: Player
var _map: GameMap
## Pokémon « notice » au repos (identifiant → minuterie [Tween] de [constant NOTICE_COOLDOWN]).
var _cooldowns: Dictionary[StringName, Tween] = {}


func setup(player: Player) -> void:
	if _player != null and _player.moved.is_connected(_on_player_moved):
		_player.moved.disconnect(_on_player_moved)
	_player = player
	if _player != null:
		_player.moved.connect(_on_player_moved)


func set_map(map: GameMap) -> void:
	_map = map
	for tween: Tween in _cooldowns.values():
		if tween != null and tween.is_valid():
			tween.kill()
	_cooldowns.clear()


## Joue la réaction « shy » de [param npc], le joueur (ou la menace) étant en
## [param away_from] : envol, fuite de [constant FLEE_STEPS] pas sur [param grid], retrait
## vers le feuillage, ou « notice ». Renvoie l'action jouée. Partagé avec l'étape « scare »
## des scènes ([CutsceneDirector]) : un seul geste par action.
static func play_reaction(npc: Npc, grid: GridWorld, away_from: Vector2i) -> StringName:
	var action := npc.get_spec().shy_action
	match action:
		&"fly":
			npc.fly_away()
		&"hide":
			npc.retreat()
		&"notice":
			npc.react()
		_:
			npc.flee(AmbientRules.flee_path(grid, npc.get_cell(), away_from, FLEE_STEPS, npc))
	return action


func _on_player_moved(cell: Vector2i) -> void:
	if _map == null or _player == null or not _player.is_input_enabled():
		return
	var grid := _map.get_grid()
	for npc: Npc in _map.get_npcs():
		var spec := npc.get_spec()
		if not spec.is_shy():
			continue
		if not AmbientRules.is_within(npc.get_cell(), cell, spec.shy_radius):
			continue
		_react(npc, grid, cell)


func _react(npc: Npc, grid: GridWorld, player_cell: Vector2i) -> void:
	var action := npc.get_spec().shy_action
	if not AmbientRules.leaves_map(action):
		if _cooldowns.has(npc.get_id()):
			return
		_start_cooldown(npc.get_id())
	elif not npc.left_scene.is_connected(_on_npc_left_scene):
		npc.left_scene.connect(_on_npc_left_scene)
	reacted.emit(npc.get_id(), action)
	play_reaction(npc, grid, player_cell)


## Minuterie en [Tween] (simulable par les tests) : le Pokémon peut réagir de nouveau à la fin.
func _start_cooldown(npc_id: StringName) -> void:
	var tween := create_tween()
	tween.tween_interval(NOTICE_COOLDOWN)
	tween.tween_callback(func() -> void: _cooldowns.erase(npc_id))
	_cooldowns[npc_id] = tween


func _on_npc_left_scene(npc_id: StringName) -> void:
	if _map != null:
		_map.remove_npc(npc_id)
