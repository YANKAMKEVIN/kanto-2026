class_name TrainerWatcher
extends Node
## Fait réagir les Dresseurs du monde (jalon 9, jalon-09.md §2.4.6), sur le modèle
## d'[AmbientWatcher].
##
## Écoute [signal Player.moved] : rien si le joueur est bloqué (scène, dialogue, combat,
## transition) ; sinon le **premier** Dresseur non battu de la carte (ordre du fichier de
## données) qui voit le joueur ([method TrainerRules.sight_distance]) lance sa séquence
## ([TrainerEncounter], [method CutsceneDirector.play_variant]), qui bloque le joueur dans
## l'appel même : le pas suivant ne part pas, et l'[EncounterDirector], branché **après** lui
## dans Boot, ne tire aucune rencontre sauvage sur ce pas. [method challenge] : le joueur lui
## a parlé ([signal InteractionController.challenge_requested]), séquence sans « ! » ni
## approche. Après sa victoire, le Dresseur reste où il s'est arrêté jusqu'au rechargement de
## la carte (Rouge/Bleu) ; battu, il ne regarde plus personne.

## Un Dresseur a repéré le joueur et sa séquence commence (tests, futurs sons).
signal trainer_spotted(npc_id: StringName, trainer_id: StringName)

var _player: Player
var _flags: StoryFlags
var _cutscenes: CutsceneDirector
var _map: GameMap


## Branche le watcher (rappelable) : le joueur dont il écoute les pas, les drapeaux d'histoire
## (« battu ») et le directeur qui joue les séquences.
func setup(player: Player, flags: StoryFlags, cutscenes: CutsceneDirector) -> void:
	if _player != null and _player.moved.is_connected(_on_player_moved):
		_player.moved.disconnect(_on_player_moved)
	_player = player
	_flags = flags
	_cutscenes = cutscenes
	if _player != null:
		_player.moved.connect(_on_player_moved)


## Carte courante (relais de Boot sur SceneRouter.map_changed).
func set_map(map: GameMap) -> void:
	_map = map


## Défi à la parole : séquence de [param npc] sans « ! » ni approche. Faux (rien) si ce n'est
## pas un Dresseur, s'il est battu (son dialogue « après » est alors joué par
## l'[InteractionController]) ou si une scène tourne.
func challenge(npc: Npc) -> bool:
	if not _is_waiting_trainer(npc):
		return false
	return _play(npc, TrainerEncounter.TALKED_TO)


func _on_player_moved(cell: Vector2i) -> void:
	if not is_instance_valid(_map) or not is_instance_valid(_player) \
			or not _player.is_input_enabled():
		return
	if _cutscenes == null or _cutscenes.is_running():
		return
	var grid := _map.get_grid()
	for npc: Npc in _map.get_npcs():
		if not _is_waiting_trainer(npc):
			continue
		var spec := npc.get_spec()
		var distance := TrainerRules.sight_distance(grid, npc.get_cell(), spec.facing,
			spec.sight, cell)
		if distance >= 1:
			_play(npc, distance)
			return


## Vrai pour un Dresseur encore à battre.
func _is_waiting_trainer(npc: Npc) -> bool:
	if not is_instance_valid(npc) or not npc.get_spec().is_trainer():
		return false
	return not TrainerRules.is_beaten(_flags, npc.get_spec().trainer_id)


func _play(npc: Npc, distance: int) -> bool:
	if _cutscenes == null:
		return false
	var spec := npc.get_spec()
	var variant := TrainerEncounter.build(npc.get_id(), spec, distance)
	if not _cutscenes.play_variant(TrainerEncounter.cutscene_id(spec.trainer_id), variant):
		return false
	if distance > TrainerEncounter.TALKED_TO:
		trainer_spotted.emit(npc.get_id(), spec.trainer_id)
	return true
