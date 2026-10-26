class_name FishingDirector
extends Node
## La pêche dans la partie (passe systèmes 2, S2C-bis ; plan du J22 §2.7, dossier 25 §7.3).
## Enfant de [Boot], comme [KeyDoorDirector]. **Aucune règle ici** : la case vient de
## [method FishingSpot.in_front], la canne de [method FishingRules.best_rod], la touche et le
## Pokémon de [method FishingRules.roll] sur les [WaterRodTables].
##
## - **Cible** ([method target_at], branchée sur [member InteractionController.terrain_target]) :
##   PÊCHER face à une case pêchable ([member GameMap.fishable_cells]) avec au moins une canne au
##   Sac. Une seule [Interaction] gardée en cache (le contrôleur compare les instances).
## - **Déroulé** ([method fish]) : entrée bloquée ([constant INPUT_REASON] : [method Boot.is_stable]
##   est faux, aucune sauvegarde), compagnon rentré (comme une scène), joueur tourné vers l'eau,
##   « {player} lance sa ligne… », attente de [constant WAIT_MIN] à [constant WAIT_MAX] s
##   ([GameRng]), puis « ! » au-dessus du joueur et « Oh ! Ça mord ! » → combat sauvage ordinaire
##   ([method EncounterDirector.start_encounter], terrain « water_rod » : sans introduction) ;
##   sinon « Rien ne mord… ». Fin : entrée rendue, compagnon ressorti (sauf en selle).
## - **Sac** ([method use_rod], via [KeyItemDirector]) : la canne choisie ; sans eau pêchable
##   devant, « On ne peut pas pêcher ici. ».
## Animation (DAF.5, série 25) : pose `fish_cast` pendant « lance sa ligne… », puis `fish_wait`
## (fil tendu) jusqu'à la touche ou « Rien ne mord… » ; retirée à la fin ([method Player.set_pose] :
## sans l'art de l'apparence, ou en selle, le joueur reste en `idle`).
## Une espèce de table absente des données ne fait rien mordre (push_error) : les tables globales
## citent des espèces du J22.

## Une pêche commence ([param rod] : la canne utilisée).
signal fishing_started(rod: StringName)
## Une pêche se termine, contrôle rendu ; [param battled] : un combat a eu lieu.
signal fishing_finished(battled: bool)

const INPUT_REASON: StringName = &"fishing"
## Textes (dossier 25 §16.2.8 à §16.2.11, `data/dialogues/fishing.json`).
const CAST_DIALOGUE: StringName = &"fishing_cast"
const BITE_DIALOGUE: StringName = &"fishing_bite"
const NOTHING_DIALOGUE: StringName = &"fishing_nothing"
const NO_WATER_DIALOGUE: StringName = &"fishing_no_water"
## Poses du joueur ([method Player.set_pose]) : lancer, puis attente fil tendu.
const POSE_CAST: StringName = &"fish_cast"
const POSE_WAIT: StringName = &"fish_wait"
## Attente avant la touche (s) [D] : de 1 à 2 s, au dixième, tirée par [GameRng].
const WAIT_MIN: float = 1.0
const WAIT_MAX: float = 2.0

## État de la partie (GameState ou un double de test) : `bag`, `rng`.
var _state: Node
var _tables: WaterRodTables
var _pokemon: PokemonData
var _player: Player
var _runner: DialogueRunner
var _encounters: EncounterDirector
var _companion: CompanionController
var _map: GameMap
## Cases pêchables de [member _map] (relues à [method set_map]).
var _fishable: Dictionary[Vector2i, bool] = {}
## Cible PÊCHER, réutilisée d'une image à l'autre (seule sa case change).
var _target := Interaction.new(Interaction.Kind.FISH)
var _busy: bool = false


func _init() -> void:
	name = "FishingDirector"


## Branche le directeur (rappelable). [param runner], [param encounters], [param companion] :
## null en test (aucun texte, aucun combat, aucun compagnon).
func setup(state: Node, tables: WaterRodTables, pokemon: PokemonData, player: Player,
		runner: DialogueRunner, encounters: EncounterDirector,
		companion: CompanionController) -> void:
	_state = state
	_tables = tables
	_pokemon = pokemon
	_player = player
	_runner = runner
	_encounters = encounters
	_companion = companion


## Carte courante (SceneRouter.map_changed) : ses cases pêchables sont relues.
func set_map(map: GameMap) -> void:
	_map = map
	_fishable = {}
	if is_instance_valid(map):
		_fishable = map.fishable_set()


func is_running() -> bool:
	return _busy


## Cible de terrain PÊCHER pour un joueur en [param cell] tourné vers [param facing], ou null :
## case pêchable devant et canne au Sac. Sans allocation (appelée à chaque image).
func target_at(cell: Vector2i, facing: Vector2i) -> Interaction:
	if _busy or FishingRules.best_rod(_bag()).is_empty():
		return null
	var water := _spot(cell, facing)
	if water == FishingSpot.NONE:
		return null
	_target.cell = water
	return _target


## Appui PÊCHER ([signal InteractionController.fish_requested]) : la meilleure canne (M-9).
func on_fish_requested(cell: Vector2i) -> void:
	var rod := FishingRules.best_rod(_bag())
	if rod.is_empty() or _busy:
		return
	fish(rod, cell)


## Sac → UTILISER une canne (menu déjà fermé) : pêche avec [param rod] face à l'eau, sinon
## « On ne peut pas pêcher ici. ». Faux si la canne n'est pas au Sac ou si une pêche tourne.
func use_rod(rod: StringName) -> bool:
	var bag := _bag()
	if _busy or not FishingRules.RODS.has(rod) or bag == null or not bag.has(rod):
		return false
	if not is_instance_valid(_player):
		return false
	var water := _spot(_player.get_cell(), _player.get_facing())
	if water == FishingSpot.NONE:
		_say_now(NO_WATER_DIALOGUE)
		return true
	fish(rod, water)
	return true


## Coroutine : une pêche complète avec [param rod] vers la case d'eau [param cell].
func fish(rod: StringName, cell: Vector2i) -> void:
	if _busy or not is_instance_valid(_player):
		return
	_busy = true
	_player.set_input_enabled(false, INPUT_REASON)
	fishing_started.emit(rod)
	if _companion != null:
		_companion.on_cutscene_started()
	_player.face(Grid.dominant_direction(_player.get_cell(), cell))
	_player.set_pose(POSE_CAST)
	await _say(CAST_DIALOGUE)
	if is_instance_valid(_player):
		_player.set_pose(POSE_WAIT)
	var rng := _rng()
	var tenths := rng.range_int(roundi(WAIT_MIN * 10.0), roundi(WAIT_MAX * 10.0)) \
		if rng != null else roundi(WAIT_MIN * 10.0)
	await _wait(tenths / 10.0)
	var map_id: StringName = _map.map_id if is_instance_valid(_map) else &""
	var encounter := FishingRules.roll(rng, _tables, rod, map_id) if rng != null else null
	if encounter != null and _pokemon != null and not _pokemon.has_species(encounter.species):
		push_error("FishingDirector : espèce inconnue « %s » (table « %s »)" % [
			encounter.species, encounter.table_id])
		encounter = null
	var battled := false
	if encounter != null:
		await _exclaim()
		await _say(BITE_DIALOGUE)
		if _encounters != null and _encounters.start_encounter(encounter,
				EncounterDirector.WATER_ROD_TERRAIN):
			battled = true
			await _encounters.encounter_finished
	else:
		await _say(NOTHING_DIALOGUE)
	if is_instance_valid(_player):
		_player.set_pose(&"")
		_player.set_input_enabled(true, INPUT_REASON)
	if _companion != null:
		_companion.on_cutscene_finished()
	_busy = false
	fishing_finished.emit(battled)


func _spot(cell: Vector2i, facing: Vector2i) -> Vector2i:
	if not is_instance_valid(_map):
		return FishingSpot.NONE
	return FishingSpot.in_front(_map.get_grid(), cell, facing, _map.is_cycling_road_at(cell),
		_fishable)


func _bag() -> Bag:
	return _state.get(&"bag") as Bag if _state != null else null


func _rng() -> GameRng:
	return _state.get(&"rng") as GameRng if _state != null else null


func _say(dialogue_id: StringName) -> void:
	if _runner != null and _runner.play(dialogue_id, null, _map):
		await _runner.dialogue_finished


func _say_now(dialogue_id: StringName) -> void:
	if _runner != null:
		_runner.play(dialogue_id, null, _map)


func _wait(seconds: float) -> void:
	if seconds <= 0.0 or not is_inside_tree():
		return
	var tween := create_tween()
	tween.tween_interval(seconds)
	await tween.finished


## Bulle « ! » au-dessus du joueur (même bulle que les Dresseurs et le compagnon).
func _exclaim() -> void:
	if not is_instance_valid(_player) or not _player.is_inside_tree():
		return
	var bubble := EmoteBubble.new()
	bubble.name = "FishingBubble"
	_player.add_child(bubble)
	bubble.play(EmoteBubble.EXCLAIM)
	if bubble.is_playing():
		await bubble.finished
	bubble.queue_free()
