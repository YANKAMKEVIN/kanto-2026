class_name Boot
extends Node
## Scène principale : racine de composition (docs/tech/jalon-02.md §2.1).
##
## Ne fait que câbler : instancie le joueur, branche l'autoload SceneRouter sur `World`,
## le joueur et le rideau `ScreenFade`, relie les signaux du routeur au HUD, charge les
## dialogues de `data/dialogues/` et branche le lecteur de dialogues et le contrôleur
## d'interactions (docs/tech/jalon-03.md §2.1), puis démarre
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
var _library := DialogueLibrary.new()

@onready var _world: Node2D = %World
@onready var _hud: ExplorationHud = %ExplorationHud
@onready var _fade: ScreenFade = %ScreenFade
@onready var _dialogue_box: DialogueBox = %DialogueBox
@onready var _runner: DialogueRunner = %DialogueRunner
@onready var _interactions: InteractionController = %InteractionController


func _ready() -> void:
	GameState.new_game()
	_player = PLAYER_SCENE.instantiate() as Player
	_library.load_dir()
	_runner.setup(_library, GameState.flags, _dialogue_box, _player)
	_interactions.setup(_player, _runner)
	_interactions.target_changed.connect(_on_target_changed)
	_runner.dialogue_started.connect(_on_dialogue_started)
	_runner.dialogue_finished.connect(_on_dialogue_finished)
	SceneRouter.setup(_world, _player, _fade)
	# Branchés avant start() : la première carte passe aussi par le contrôleur.
	SceneRouter.transition_started.connect(_on_transition_started)
	SceneRouter.map_changed.connect(_interactions.set_map)
	SceneRouter.map_entered.connect(_on_map_entered)
	SceneRouter.map_entered.connect(_interactions.on_map_entered)
	SceneRouter.start(start_map, start_spawn, start_facing)


func _exit_tree() -> void:
	var links: Array[Array] = [
		[SceneRouter.transition_started, _on_transition_started],
		[SceneRouter.map_changed, _interactions.set_map],
		[SceneRouter.map_entered, _on_map_entered],
		[SceneRouter.map_entered, _interactions.on_map_entered],
	]
	for link: Array in links:
		var sig: Signal = link[0]
		if sig.is_connected(link[1]):
			sig.disconnect(link[1])


func get_player() -> Player:
	return _player


func get_map() -> GameMap:
	return SceneRouter.get_current_map()


func get_hud() -> ExplorationHud:
	return _hud


func get_fade() -> ScreenFade:
	return _fade


func get_dialogue_box() -> DialogueBox:
	return _dialogue_box


func get_dialogue_runner() -> DialogueRunner:
	return _runner


func get_interaction_controller() -> InteractionController:
	return _interactions


## Dialogues chargés au démarrage (data/dialogues/).
func get_dialogue_library() -> DialogueLibrary:
	return _library


func _on_transition_started(_target_map: StringName) -> void:
	_hud.hide_zone_title()


func _on_map_entered(map: GameMap) -> void:
	if _announcer.should_announce(map.display_name, map.interior):
		_hud.show_zone_title(map.display_name, map.region)
		zone_announced.emit(map.display_name, map.region)


func _on_target_changed(kind: int) -> void:
	if kind == InteractionController.NO_TARGET:
		_hud.hide_interact()
	else:
		_hud.show_interact(Interaction.kind_name(kind as Interaction.Kind))


func _on_dialogue_started(_dialogue_id: StringName) -> void:
	_hud.set_controls_visible(false)


func _on_dialogue_finished(_dialogue_id: StringName) -> void:
	_hud.set_controls_visible(true)
