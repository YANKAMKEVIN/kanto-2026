class_name InteractionController
extends Node
## Cible d'interaction du joueur et déclenchement des dialogues (docs/tech/jalon-03.md §2.2,
## §2.7).
##
## À chaque image, cherche la cible **devant** le joueur ([InteractionFinder]) et émet
## [signal target_changed] quand elle change (le HUD montre ou cache le bouton contextuel).
## Pas de cible si le joueur est bloqué (transition, dialogue), s'il marche ou si un
## dialogue tourne. Un appui sur `interact` (clavier E / Espace, ou le bouton contextuel qui
## presse la même action) lance le dialogue de la cible par le [DialogueRunner].
## À l'arrivée sur une carte ([method on_map_entered]), le premier PNJ dont la variante
## courante est « auto » parle de lui-même (premier dialogue de Maman) : règle de données,
## aucun PNJ n'est nommé ici.
## Jalon 4 (jalon-04.md §3.5, §13.3) : une cible « Rencontrer » ([constant Interaction.Kind.MEET],
## surcharge posée par le choix du starter) ne joue aucun dialogue : l'appui émet
## [signal meet_requested] et le code du choix s'en charge. Même anti-rebond qu'un dialogue.
## Jalon 9 (jalon-09.md §2.4.5) : parler à un Dresseur pas encore battu ne joue aucun dialogue :
## l'appui émet [signal challenge_requested] ([TrainerWatcher] joue le défi), même anti-rebond ;
## battu, il dit sa réplique « après » (son dialogue). Drapeaux : [method set_story_flags].

## Cible devant le joueur : kind = [enum Interaction.Kind], ou [constant NO_TARGET].
signal target_changed(kind: int)
## Appui sur une cible « Rencontrer » : [param npc] est le PNJ rencontré (source de la cible).
signal meet_requested(npc: Npc)

## Geste OBSERVER sur un Pokémon du décor dont l'espèce est renseignée (jalon 6 §6.9, Q-7) :
## émis **au début** du geste, avant le dialogue. [param npc] porte l'identifiant de l'individu.
signal observed(npc: Npc, species: StringName)
## Appui sur un Dresseur pas encore battu (jalon 9) : [param npc] le défie, sans dialogue.
signal challenge_requested(npc: Npc)
## Appui face au compagnon (jalon 11) : sa réaction de curiosité est jouée par son contrôleur
## (bulle, phrase), aucun dialogue ici.
signal companion_talked

const NO_TARGET: int = -1
## Délai entre l'arrivée sur la carte et l'ouverture de la boîte d'un dialogue automatique.
const AUTO_DIALOGUE_DELAY: float = 0.35
const _INTERACT: StringName = &"interact"

var _player: Player
var _runner: DialogueRunner
var _map: GameMap
var _target: Interaction
var _target_kind: int = NO_TARGET
## Anti-rebond : après un dialogue ou une rencontre, `interact` est ignoré jusqu'à son
## relâchement.
var _wait_release: bool = false
## Drapeaux d'histoire (Dresseurs battus, jalon 9) ; null = aucun Dresseur n'est battu.
var _flags: StoryFlags
## Fournisseur de l'interaction du compagnon (jalon 11, [method InteractionFinder.find]).
var _companion: Object


func _ready() -> void:
	set_process(_player != null)


func _process(_delta: float) -> void:
	var target: Interaction = null
	if _can_target():
		target = InteractionFinder.find(_map.get_grid(), _map.get_interactions(),
			_player.get_cell(), _player.get_facing(), _companion)
	_set_target(target)
	if _wait_release:
		if Input.is_action_pressed(_INTERACT):
			return
		_wait_release = false
	if target != null and Input.is_action_just_pressed(_INTERACT):
		_interact(target)


## Branche le contrôleur sur le joueur et le lecteur de dialogues (rappelable).
func setup(player: Player, runner: DialogueRunner) -> void:
	if _runner != null:
		if _runner.dialogue_started.is_connected(_on_dialogue_started):
			_runner.dialogue_started.disconnect(_on_dialogue_started)
		if _runner.dialogue_finished.is_connected(_on_dialogue_finished):
			_runner.dialogue_finished.disconnect(_on_dialogue_finished)
	_player = player
	_runner = runner
	if _runner != null:
		_runner.dialogue_started.connect(_on_dialogue_started)
		_runner.dialogue_finished.connect(_on_dialogue_finished)
	_set_target(null)
	set_process(_player != null)


## Compagnon (jalon 11) : objet qui expose [code]get_interaction_at(cell) -> Interaction[/code]
## (null : pas de compagnon).
func set_companion(provider: Object) -> void:
	_companion = provider


## Drapeaux d'histoire lus pour savoir si un Dresseur est battu (jalon 9).
func set_story_flags(flags: StoryFlags) -> void:
	_flags = flags


## Nouvelle carte (SceneRouter.map_changed) : plus de cible jusqu'à la prochaine image.
func set_map(map: GameMap) -> void:
	_map = map
	_set_target(null)


## Arrivée sur une carte (SceneRouter.map_entered) : dialogue automatique éventuel. Le
## joueur est bloqué dans cet appel même (avant sa prochaine image), le joueur et le PNJ se
## font face, la boîte s'ouvre après [constant AUTO_DIALOGUE_DELAY].
func on_map_entered(map: GameMap) -> void:
	if map != _map:
		set_map(map)
	if map == null or _player == null or _runner == null or _runner.is_running():
		return
	if not _player.is_input_enabled():
		return  # scène en cours (arrivée au labo) : pas de dialogue automatique
	for npc: Npc in map.get_npcs():
		var interaction := npc.get_interaction()
		if interaction == null or not _runner.has_auto_variant(interaction.dialogue_id):
			continue
		_player.face(dominant_direction(_player.get_cell(), npc.get_cell()))
		npc.begin_interaction(_player.get_cell())
		_runner.play(interaction.dialogue_id, npc, map, AUTO_DIALOGUE_DELAY)
		return


## Cible actuelle (null s'il n'y en a pas).
func get_target() -> Interaction:
	return _target


## Direction cardinale de [param from] vers [param to] selon l'axe dominant (à égalité,
## l'axe vertical) ; ZERO si c'est la même case. Délègue à [method Grid.dominant_direction]
## (règle unique).
static func dominant_direction(from: Vector2i, to: Vector2i) -> Vector2i:
	return Grid.dominant_direction(from, to)


func _can_target() -> bool:
	if not is_instance_valid(_map) or not is_instance_valid(_player):
		return false
	if _runner != null and _runner.is_running():
		return false
	return _player.is_input_enabled() and not _player.is_moving()


func _interact(target: Interaction) -> void:
	if _companion != null and target.source == _companion:
		# Le compagnon : son contrôleur joue la curiosité. L'appui tenu ne relance rien.
		_wait_release = true
		companion_talked.emit()
		return
	var npc := target.source as Npc
	if target.kind == Interaction.Kind.MEET:
		# Pas de dialogue : le code du choix répond. L'appui tenu ne relance rien.
		_wait_release = true
		if npc != null:
			meet_requested.emit(npc)
		return
	if npc != null and npc.get_spec().is_trainer() \
			and not TrainerRules.is_beaten(_flags, npc.get_spec().trainer_id):
		# Défi à la parole (jalon 9) : le TrainerWatcher joue la séquence, pas de dialogue ici.
		_wait_release = true
		challenge_requested.emit(npc)
		return
	if npc != null and target.kind == Interaction.Kind.OBSERVE \
			and npc.get_spec().is_observable_species():
		observed.emit(npc, npc.get_spec().species)
	if npc != null:
		npc.begin_interaction(_player.get_cell())
	if _runner != null:
		_runner.play(target.dialogue_id, npc, _map)


func _set_target(target: Interaction) -> void:
	var kind: int = target.kind if target != null else NO_TARGET
	if target == _target and kind == _target_kind:
		return
	_target = target
	_target_kind = kind
	target_changed.emit(kind)


func _on_dialogue_started(_dialogue_id: StringName) -> void:
	_set_target(null)


func _on_dialogue_finished(_dialogue_id: StringName) -> void:
	_wait_release = true
