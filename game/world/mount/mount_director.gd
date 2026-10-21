class_name MountDirector
extends Node
## Monture du joueur dans la partie (passe systèmes 2, `docs/tech/systemes-2.md` §2.2 à §2.4).
## Enfant de [Boot], comme [FlashDirector]. **Aucune règle ici** : l'arrivée vient de
## [method MountRules.on_map_entered], monter et descendre de [BikeRules].
##
## - **Arrivée** ([method on_map_changed], écran noir, joueur déjà posé) : la monture sauvegardée
##   ([member GameState.player_mount]) est gardée, retirée (intérieur, terre ferme) ou posée
##   d'office (Piste Cyclable avec la Bicyclette), sans mise en scène.
## - **Vélo** ([method toggle_bike] : bouton du HUD, Sac, touche B) : monte ou descend ; un refus
##   joue son texte (dossier 25 §16.1 : intérieur, Piste).
## - **État** : [member GameState.player_mount] suit [signal Player.mount_changed] ;
##   [member GameState.last_land_cell] suit chaque pas à terre.
## - **Bouton du HUD** ([method ExplorationHud.set_bike_button]) : visible avec la Bicyclette,
##   grisé là où il refuse ; tenu à jour à chaque image (lecture du Sac, sans coût notable).
##   Action clavier `bike` (touche B) pour les tests desktop.
## Le compagnon rentre et ressort seul ([CompanionController], [signal Player.mount_changed]).

## Refus du Vélo (texte joué) : [param check] = [enum BikeRules.Check].
signal bike_refused(check: BikeRules.Check)

## Objet clé de la Bicyclette (même identifiant que le J22).
const BICYCLE: StringName = &"bicycle"
## Refus (dossier 25 §16.1.3 et §16.1.4, validés ; `data/dialogues/mount.json`).
const INDOORS_DIALOGUE: StringName = &"bike_indoors"
const CYCLING_ROAD_DIALOGUE: StringName = &"bike_cycling_road_walk"

## Action d'entrée du Vélo (clavier, tests desktop).
const ACTION: StringName = &"bike"

## Rappel () -> bool : vrai quand le joueur peut monter ou descendre (partie stable).
var can_toggle: Callable

## État de la partie (GameState ou un double de test) : Sac, monture, case à terre.
var _state: Node
var _player: Player
var _runner: DialogueRunner
var _map: GameMap
var _hud: ExplorationHud


func _init() -> void:
	name = "MountDirector"


func _process(_delta: float) -> void:
	if _hud != null:
		_hud.set_bike_button(has_bike(), is_bike_blocked())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION) and has_bike():
		toggle_bike()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if SceneRouter.map_changed.is_connected(on_map_changed):
		SceneRouter.map_changed.disconnect(on_map_changed)


## Branche le directeur (rappelable). [param runner] : les refus (null en test : aucun texte) ;
## [param hud] : le bouton Vélo (null : aucun). Se branche sur [signal SceneRouter.map_changed].
func setup(state: Node, player: Player, runner: DialogueRunner,
		hud: ExplorationHud = null) -> void:
	if is_instance_valid(_player) and _player.mount_changed.is_connected(_on_mount_changed):
		_player.mount_changed.disconnect(_on_mount_changed)
		_player.moved.disconnect(_on_player_moved)
	if is_instance_valid(_hud) and _hud.bike_requested.is_connected(_on_bike_requested):
		_hud.bike_requested.disconnect(_on_bike_requested)
	_state = state
	_player = player
	_runner = runner
	_hud = hud
	if _player != null:
		_player.mount_changed.connect(_on_mount_changed)
		_player.moved.connect(_on_player_moved)
	if _hud != null:
		_hud.bike_requested.connect(_on_bike_requested)
	if not SceneRouter.map_changed.is_connected(on_map_changed):
		SceneRouter.map_changed.connect(on_map_changed)


## Vrai si la Bicyclette est dans le Sac (bouton du HUD visible).
func has_bike() -> bool:
	return _state != null and (_state.get(&"bag") as Bag).has(BICYCLE)


## Vrai si le Vélo ne peut pas être enfourché ou quitté ici (bouton grisé) : intérieur, ou
## descente sur la Piste.
func is_bike_blocked() -> bool:
	if not is_instance_valid(_map) or not is_instance_valid(_player):
		return false
	if _player.get_mount() == Mount.Kind.BIKE:
		return _map.cycling_road
	return not _map.mount_traits().allows_bike()


## Nouvelle carte (écran noir, joueur déjà posé) : monture d'arrivée, sans mise en scène.
func on_map_changed(map: GameMap) -> void:
	_map = map
	if not is_instance_valid(map) or not is_instance_valid(_player):
		return
	var current := _player.get_mount()
	if _state != null:
		current = _state.get(&"player_mount") as Mount.Kind
	var kind := MountRules.on_map_entered(current, map.mount_traits(), _player.get_cell(),
		map.get_grid(), has_bike())
	_player.set_mount(kind, true)
	_sync_state(kind)
	if kind != Mount.Kind.SURF and _state != null:
		_state.set(&"last_land_cell", _player.get_cell())


## Monte ou descend du Vélo. Rend [constant BikeRules.Check.OK] si la monture a changé ; un
## refus d'intérieur ou de Piste joue son texte ([signal bike_refused]). En Surf : BUSY, rien.
func toggle_bike() -> BikeRules.Check:
	if not is_instance_valid(_player) or not is_instance_valid(_map):
		return BikeRules.Check.BUSY
	var busy: bool = _player.is_moving() or (can_toggle.is_valid() and not can_toggle.call()) \
		or _player.get_mount() == Mount.Kind.SURF
	var check: BikeRules.Check
	if _player.get_mount() == Mount.Kind.BIKE:
		check = BikeRules.can_dismount(_map.cycling_road, busy)
	else:
		check = BikeRules.can_mount(has_bike(), not _map.mount_traits().allows_bike(), busy)
	if check == BikeRules.Check.OK:
		var riding := _player.get_mount() == Mount.Kind.BIKE
		_player.set_mount(Mount.Kind.NONE if riding else Mount.Kind.BIKE)
		return check
	_refuse(check)
	return check


func _refuse(check: BikeRules.Check) -> void:
	var dialogue := &""
	match check:
		BikeRules.Check.INDOORS:
			dialogue = INDOORS_DIALOGUE
		BikeRules.Check.ON_CYCLING_ROAD:
			dialogue = CYCLING_ROAD_DIALOGUE
	if dialogue.is_empty():
		return
	bike_refused.emit(check)
	if _runner != null:
		_runner.play(dialogue, null, _map)


func _sync_state(kind: Mount.Kind) -> void:
	if _state != null:
		_state.set(&"player_mount", kind)


func _on_bike_requested() -> void:
	toggle_bike()


func _on_mount_changed(kind: Mount.Kind) -> void:
	_sync_state(kind)


func _on_player_moved(cell: Vector2i) -> void:
	if _state != null and _player.get_mount() != Mount.Kind.SURF:
		_state.set(&"last_land_cell", cell)
