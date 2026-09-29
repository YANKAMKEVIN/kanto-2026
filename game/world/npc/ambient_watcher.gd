class_name AmbientWatcher
extends Node
## Fait réagir les Pokémon d'ambiance « shy » à l'approche du joueur (jalon 5 §3.5,
## dossier 04 §1).
##
## Écoute [signal Player.moved] ; pour chaque PNJ de la carte courante avec
## [member NpcSpec.shy_action] dont le joueur entre dans le rayon
## ([method AmbientRules.is_within]), déclenche l'envol ([method Npc.fly_away]) ou la fuite
## ([method Npc.flee]) puis, à la fin ([signal Npc.left_scene]), retire le PNJ de la carte
## ([method GameMap.remove_npc]). Ils reviennent au prochain chargement de la carte (présence
## du fichier de données). Jamais de combat avec eux. Le watcher ne fait rien pendant une
## scène, un dialogue ou une transition (le joueur est alors bloqué : [method
## Player.is_input_enabled] est faux).

## Un Pokémon d'ambiance a réagi (tests, futurs sons).
signal reacted(npc_id: StringName, action: StringName)

## Nombre de pas de fuite d'un Rattata (dossier 04 §1 : « fuit facilement »).
const FLEE_STEPS: int = 3

var _player: Player
var _map: GameMap


func setup(player: Player) -> void:
	if _player != null and _player.moved.is_connected(_on_player_moved):
		_player.moved.disconnect(_on_player_moved)
	_player = player
	if _player != null:
		_player.moved.connect(_on_player_moved)


func set_map(map: GameMap) -> void:
	_map = map


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
	if not npc.left_scene.is_connected(_on_npc_left_scene):
		npc.left_scene.connect(_on_npc_left_scene)
	if npc.get_spec().shy_action == &"fly":
		reacted.emit(npc.get_id(), &"fly")
		npc.fly_away()
	else:
		var path := AmbientRules.flee_path(grid, npc.get_cell(), player_cell, FLEE_STEPS, npc)
		reacted.emit(npc.get_id(), &"flee")
		npc.flee(path)


func _on_npc_left_scene(npc_id: StringName) -> void:
	if _map != null:
		_map.remove_npc(npc_id)
