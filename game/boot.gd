class_name Boot
extends Node
## Scène principale : racine de composition (docs/tech/jalon-02.md §2.1).
##
## Ne fait que câbler : instancie le joueur, branche l'autoload SceneRouter sur `World`,
## le joueur et le rideau `ScreenFade`, relie les signaux du routeur au HUD, puis démarre
## sur [member start_map] / [member start_spawn]. Le titre de zone ne s'affiche qu'en
## arrivant dans une zone extérieure différente ([ZoneAnnouncer]) : aucun au démarrage
## dans la chambre. Les réglages de départ servent au développement, aux tests et aux
## outils de capture : les régler avant add_child.

## Une zone vient d'être annoncée (titre de zone affiché).
signal zone_announced(zone_name: String, region: String)

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")

@export var start_map: StringName = &"player_house_2f"
@export var start_spawn: StringName = &"start"
@export var start_facing: Vector2i = Vector2i.DOWN

var _player: Player
var _announcer := ZoneAnnouncer.new()

@onready var _world: Node2D = %World
@onready var _hud: ExplorationHud = %ExplorationHud
@onready var _fade: ScreenFade = %ScreenFade


func _ready() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	SceneRouter.setup(_world, _player, _fade)
	SceneRouter.transition_started.connect(_on_transition_started)
	SceneRouter.map_entered.connect(_on_map_entered)
	SceneRouter.start(start_map, start_spawn, start_facing)


func _exit_tree() -> void:
	if SceneRouter.transition_started.is_connected(_on_transition_started):
		SceneRouter.transition_started.disconnect(_on_transition_started)
	if SceneRouter.map_entered.is_connected(_on_map_entered):
		SceneRouter.map_entered.disconnect(_on_map_entered)


func get_player() -> Player:
	return _player


func get_map() -> GameMap:
	return SceneRouter.get_current_map()


func get_hud() -> ExplorationHud:
	return _hud


func get_fade() -> ScreenFade:
	return _fade


func _on_transition_started(_target_map: StringName) -> void:
	_hud.hide_zone_title()


func _on_map_entered(map: GameMap) -> void:
	if _announcer.should_announce(map.display_name, map.interior):
		_hud.show_zone_title(map.display_name, map.region)
		zone_announced.emit(map.display_name, map.region)
