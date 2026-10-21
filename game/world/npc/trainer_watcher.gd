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
##
## Garde-fou (J15 T24) : sans aucun Pokémon valide dans l'équipe du joueur (état qui ne doit plus
## exister : une victoire implique un Pokémon valide, [method Battle._check_end]), aucun Dresseur
## ne lance sa séquence, ni à la vue ni à la parole (comme l'[EncounterDirector] pour les
## rencontres sauvages) ; le [BattleDirector] refuse de toute façon un tel combat.

## Un Dresseur a repéré le joueur et sa séquence commence (tests, futurs sons).
signal trainer_spotted(npc_id: StringName, trainer_id: StringName)

var _player: Player
var _flags: StoryFlags
var _cutscenes: CutsceneDirector
var _map: GameMap
## GameState (ou une instance de game_state.gd en test) : l'équipe du joueur. Null : pas de garde.
var _state: Node


## Branche le watcher (rappelable) : le joueur dont il écoute les pas, les drapeaux d'histoire
## (« battu »), le directeur qui joue les séquences et [param state], dont l'équipe doit avoir
## un Pokémon valide pour qu'un Dresseur défie le joueur (null : pas de garde).
func setup(player: Player, flags: StoryFlags, cutscenes: CutsceneDirector,
		state: Node = null) -> void:
	if _player != null and _player.moved.is_connected(_on_player_moved):
		_player.moved.disconnect(_on_player_moved)
	_player = player
	_flags = flags
	_cutscenes = cutscenes
	_state = state
	if _player != null:
		_player.moved.connect(_on_player_moved)


## Carte courante (relais de Boot sur SceneRouter.map_changed).
func set_map(map: GameMap) -> void:
	_map = map


## Défi à la parole : séquence de [param npc] sans « ! » ni approche. Faux (rien) si ce n'est
## pas un Dresseur, s'il est battu (son dialogue « après » est alors joué par
## l'[InteractionController]) ou si une scène tourne.
func challenge(npc: Npc) -> bool:
	if not _is_waiting_trainer(npc) or not _player_can_fight():
		return false
	return _play(npc, TrainerEncounter.TALKED_TO)


## J20 (T19, `jalon-20.md` §2.4.4) : même règle qu'après un pas libre, pour une case où le joueur
## est arrivé sans pas libre (fin d'une glisse sur les dalles tournantes) : le premier Dresseur
## non battu qui voit [param cell] lance sa séquence. Vrai si une séquence est partie ; rien si
## le joueur est bloqué ou si une scène tourne.
func check_at(cell: Vector2i) -> bool:
	if not is_instance_valid(_map) or not is_instance_valid(_player) \
			or not _player.is_input_enabled():
		return false
	if _cutscenes == null or _cutscenes.is_running() or not _player_can_fight():
		return false
	var grid := _map.get_grid()
	for npc: Npc in _map.get_npcs():
		if not _is_waiting_trainer(npc):
			continue
		var spec := npc.get_spec()
		var distance := TrainerRules.sight_distance(grid, npc.get_cell(), spec.facing,
			spec.sight, cell, spec.move_mode)
		if distance >= 1:
			return _play(npc, distance)
	return false


func _on_player_moved(cell: Vector2i) -> void:
	check_at(cell)


## Vrai pour un Dresseur encore à battre.
func _is_waiting_trainer(npc: Npc) -> bool:
	if not is_instance_valid(npc) or not npc.get_spec().is_trainer():
		return false
	return not TrainerRules.is_beaten(_flags, npc.get_spec().trainer_id)


## Faux si l'équipe du joueur n'a aucun Pokémon valide (vrai sans état branché).
func _player_can_fight() -> bool:
	if _state == null:
		return true
	var party := _state.get(&"party") as Party
	return party != null and party.has_able()


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
