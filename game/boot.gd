class_name Boot
extends Node
## Scène principale : racine de composition (docs/tech/jalon-02.md §2.1).
##
## Ne fait que câbler : instancie le joueur, branche l'autoload SceneRouter sur `World`,
## le joueur et le rideau `ScreenFade`, relie les signaux du routeur au HUD, charge les
## dialogues de `data/dialogues/` et branche le lecteur de dialogues et le contrôleur
## d'interactions (docs/tech/jalon-03.md §2.1), charge les scènes scriptées de
## `data/cutscenes/` et branche le directeur de scènes (docs/tech/jalon-03b.md §2.1), charge
## les données Pokémon et l'offre du labo et branche le choix du starter (jalon-04.md §3.1,
## §13.3), puis démarre sur [member start_map] / [member start_spawn]. Le titre de zone ne s'affiche qu'en
## arrivant dans une zone extérieure différente ([ZoneAnnouncer]) : aucun au démarrage
## dans la chambre. Les réglages de départ servent au développement, aux tests et aux
## outils de capture : les régler avant add_child.

## Une zone vient d'être annoncée (titre de zone affiché).
signal zone_announced(zone_name: String, region: String)

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")

@export var start_map: StringName = &"player_house_2f"
@export var start_spawn: StringName = &"start"
@export var start_facing: Vector2i = Vector2i.DOWN
## Fichier du départ de débogage ([DebugStart]) ; lu seulement en build debug, quand Boot est
## la scène principale lancée par le moteur, et si le fichier existe (jamais sous GUT).
var debug_start_path: String = DebugStart.USER_PATH

var _player: Player
var _announcer := ZoneAnnouncer.new()
var _library := DialogueLibrary.new()
var _cutscenes := CutsceneLibrary.new()
var _pokemon := PokemonData.new()
var _offer := StarterOffer.new()
var _trainers: TrainerLibrary
var _texts := BattleText.new()
var _items := ItemLibrary.new()
var _encounter_library: EncounterLibrary

@onready var _world: Node2D = %World
@onready var _hud: ExplorationHud = %ExplorationHud
@onready var _fade: ScreenFade = %ScreenFade
@onready var _dialogue_box: DialogueBox = %DialogueBox
@onready var _runner: DialogueRunner = %DialogueRunner
@onready var _interactions: InteractionController = %InteractionController
@onready var _cutscenes_node: CutsceneDirector = %CutsceneDirector
@onready var _sheet: StarterSheet = %StarterSheet
@onready var _starter_choice: StarterChoice = %StarterChoice
@onready var _battle_stage: BattleStage = %BattleStage
@onready var _battle_hud: BattleHud = %BattleHud
@onready var _battle_director: BattleDirector = %BattleDirector
@onready var _ambient: AmbientWatcher = %AmbientWatcher
@onready var _encounters: EncounterDirector = %EncounterDirector


func _ready() -> void:
	GameState.new_game()
	_player = PLAYER_SCENE.instantiate() as Player
	_library.load_dir()
	_cutscenes.load_dir()
	_runner.setup(_library, GameState.flags, _dialogue_box, _player)
	_interactions.setup(_player, _runner)
	_cutscenes_node.setup(_cutscenes, GameState.flags, _runner, _player, SceneRouter)
	_pokemon.load_dir()
	if _offer.load_file():
		_offer.check_species(_pokemon)
	_starter_choice.setup(_offer, _pokemon, GameState, _player, _sheet, _hud, _cutscenes_node,
		_interactions)
	_starter_choice.sheet_opened.connect(_refresh_controls)
	_starter_choice.sheet_closed.connect(_refresh_controls)
	# Jalon 4B : combat, dresseurs, messages, objets et Sac.
	_trainers = TrainerLibrary.new(_pokemon)
	_trainers.load_dir()
	_texts.load_file()
	_items.load_dir()
	_battle_director.setup(_pokemon, _trainers, _texts, _battle_stage, _battle_hud, _player,
		GameState)
	_cutscenes_node.set_battle_runner(_battle_director)
	_cutscenes_node.set_inventory(GameState.bag, _items)
	_cutscenes_node.item_given.connect(_on_item_given)
	_battle_director.battle_started.connect(_on_battle_state_changed.unbind(1))
	_battle_director.battle_finished.connect(_on_battle_state_changed.unbind(2))
	# Pokédex (jalon 5, décision Kevin 2026-09-29) : le starter est « capturé » à son entrée
	# dans l'équipe ; tout Pokémon adverse envoyé au combat est « vu » (le Pokémon du rival au
	# labo, puis les sauvages en 5B).
	_starter_choice.starter_chosen.connect(_on_starter_chosen)
	_battle_director.event_played.connect(_on_battle_event)
	_ambient.setup(_player)
	# Rencontres sauvages (jalon 5, 5B) : tables lues dans data/encounters/, l'EncounterDirector
	# tire une rencontre à chaque pas dans les hautes herbes et joue le vrai combat sauvage
	# (BattleDirector.run_request). Une défaite renvoie au point de soin (§3.11).
	_encounter_library = EncounterLibrary.new(_pokemon)
	_encounter_library.load_dir()
	_encounters.setup(_encounter_library, _pokemon, GameState, _player, _battle_director,
		SceneRouter, _cutscenes_node, _runner)
	_encounters.encounter_started.connect(_on_encounter_state_changed.unbind(2))
	_encounters.encounter_finished.connect(_on_encounter_state_changed.unbind(1))
	_interactions.target_changed.connect(_on_target_changed)
	_runner.dialogue_started.connect(_on_dialogue_started)
	_runner.dialogue_finished.connect(_on_dialogue_finished)
	# Soin volontaire (jalon 5 §3.11) : une variante de dialogue « heal » (parler à Maman)
	# soigne l'équipe à la fin du dialogue.
	_runner.heal_requested.connect(_on_heal_requested)
	_cutscenes_node.cutscene_started.connect(_on_cutscene_started)
	_cutscenes_node.cutscene_finished.connect(_on_cutscene_finished)
	SceneRouter.setup(_world, _player, _fade)
	# Branchés avant start() : la première carte passe aussi par le contrôleur.
	SceneRouter.transition_started.connect(_on_transition_started)
	# Via Boot (ordre garanti) : présence des PNJ, puis le contrôleur, puis le directeur.
	SceneRouter.map_changed.connect(_on_map_changed)
	SceneRouter.map_entered.connect(_on_map_entered)
	SceneRouter.map_entered.connect(_interactions.on_map_entered)
	SceneRouter.map_entered.connect(_starter_choice.on_map_entered)
	_apply_debug_start()
	SceneRouter.start(start_map, start_spawn, start_facing)


func _exit_tree() -> void:
	var links: Array[Array] = [
		[SceneRouter.transition_started, _on_transition_started],
		[SceneRouter.map_changed, _on_map_changed],
		[SceneRouter.map_entered, _on_map_entered],
		[SceneRouter.map_entered, _interactions.on_map_entered],
		[SceneRouter.map_entered, _starter_choice.on_map_entered],
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


func get_cutscene_director() -> CutsceneDirector:
	return _cutscenes_node


## Scènes scriptées chargées au démarrage (data/cutscenes/).
func get_cutscene_library() -> CutsceneLibrary:
	return _cutscenes


func get_starter_choice() -> StarterChoice:
	return _starter_choice


func get_starter_sheet() -> StarterSheet:
	return _sheet


## Données Pokémon chargées au démarrage (data/pokemon/).
func get_pokemon_data() -> PokemonData:
	return _pokemon


## Offre du labo chargée au démarrage (data/pokemon/starters.json).
func get_starter_offer() -> StarterOffer:
	return _offer


func get_battle_director() -> BattleDirector:
	return _battle_director


func get_battle_stage() -> BattleStage:
	return _battle_stage


func get_battle_hud() -> BattleHud:
	return _battle_hud


## Dresseurs chargés au démarrage (data/trainers/).
func get_trainer_library() -> TrainerLibrary:
	return _trainers


## Objets chargés au démarrage (data/items/).
func get_item_library() -> ItemLibrary:
	return _items


func get_encounter_director() -> EncounterDirector:
	return _encounters


## Tables de rencontre chargées au démarrage (data/encounters/).
func get_encounter_library() -> EncounterLibrary:
	return _encounter_library


## Dialogues chargés au démarrage (data/dialogues/).
func get_dialogue_library() -> DialogueLibrary:
	return _library


## Départ de débogage (jalon 5 T9, [DebugStart]) : remplace la nouvelle partie par celle du
## fichier [member debug_start_path], s'il est permis et présent. Sans effet sinon.
func _apply_debug_start() -> void:
	if not DebugStart.is_allowed(OS.is_debug_build(), get_tree().current_scene == self) \
			or not FileAccess.file_exists(debug_start_path):
		return
	var start := DebugStart.new()
	if not start.load_file(debug_start_path, _pokemon, _items):
		return
	start.apply(GameState, _pokemon)
	if not start.map.is_empty():
		start_map = start.map
		start_spawn = start.spawn
		start_facing = start.facing
	print("Départ de débogage (%s) : %s" % [debug_start_path, start.describe()])


func _on_transition_started(_target_map: StringName) -> void:
	_hud.hide_zone_title()
	_hud.hide_caption()


## Écran noir (ou démarrage) : présence des PNJ selon les drapeaux de la partie d'abord
## (jalon 3B §2.6), puis la carte passe aux contrôleurs.
func _on_map_changed(map: GameMap) -> void:
	map.refresh_npcs(GameState.flags)
	_interactions.set_map(map)
	_cutscenes_node.set_map(map)
	_starter_choice.set_map(map)
	_ambient.set_map(map)
	_encounters.set_map(map)


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
	_refresh_controls()


func _on_dialogue_finished(_dialogue_id: StringName) -> void:
	_refresh_controls()


## Soin demandé par un dialogue « heal » (jalon 5 §3.11) : l'équipe est soignée (PV et PP).
func _on_heal_requested() -> void:
	GameState.party.heal_all()


func _on_cutscene_started(_cutscene_id: StringName) -> void:
	_refresh_controls()


func _on_cutscene_finished(_cutscene_id: StringName) -> void:
	_refresh_controls()


func _on_battle_state_changed() -> void:
	_refresh_controls()


func _on_encounter_state_changed() -> void:
	_refresh_controls()


## Le starter choisi (jalon 4A) est enregistré « capturé » au Pokédex (décision Q-D).
func _on_starter_chosen(player_species: StringName, _rival_species: StringName) -> void:
	GameState.pokedex.mark_caught(player_species)


## Tout Pokémon adverse envoyé au combat est enregistré « vu » (le rival au labo, décision
## Q-D ; les sauvages en 5B).
func _on_battle_event(event: BattleEvent) -> void:
	if event.kind == BattleEvent.Kind.SENT_OUT and event.side == BattleEvent.SideId.FOE:
		GameState.pokedex.mark_seen(event.species_id)


## Objet donné par une scène (étape « give ») : toast en haut de l'écran, sans rien bloquer
## (jalon-04.md §14.6). L'accord (« Poké Balls ×5 » / « Ajoutées au Sac ») vient de l'objet.
func _on_item_given(item_id: StringName, count: int) -> void:
	var item := _items.get_item(item_id)
	if item == null:
		return
	_hud.show_toast(item.quantity_text(count), item.added_text(count))


## Contrôles visibles seulement hors dialogue, hors scène, hors fiche du starter et hors
## combat : pendant une scène ou un combat, ils restent cachés entre deux dialogues.
func _refresh_controls() -> void:
	_hud.set_controls_visible(not _runner.is_running() and not _cutscenes_node.is_running()
		and not _starter_choice.is_sheet_open() and not _battle_director.is_running()
		and not _encounters.is_running())
