class_name Boot
extends Node
## Scène principale provisoire : lance directement Bourg Palette, sans écran titre.
##
## Instancie le joueur, le place au spawn « start » face au sud, puis affiche le titre
## de zone si le HUD d'exploration est présent (T5). Ce câblage sera repris par
## l'autoload SceneRouter avec les portes.

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const START_SPAWN: StringName = &"start"

var _player: Player

@onready var _map: GameMap = %PalletTown


func _ready() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	_map.spawn_player(_player, START_SPAWN, Vector2i.DOWN)
	if has_node(^"%ExplorationHud"):
		get_node(^"%ExplorationHud").call(&"show_zone_title", _map.display_name, _map.region)


func get_player() -> Player:
	return _player


func get_map() -> GameMap:
	return _map
