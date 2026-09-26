class_name DialogueRunner
extends Node
## Lecteur de dialogues : le **seul** à jouer un dialogue (interaction, dialogue automatique,
## plus tard scènes de 3B) (docs/tech/jalon-03.md §2.5).
##
## Il relie les données ([DialogueLibrary], [StoryFlags]) au déroulé pur ([DialogueSession])
## et à l'affichage ([DialogueBox]). Il bloque le joueur pour la raison
## [constant REASON] dès [method play] (de façon synchrone), applique la mise en scène au
## début de chaque page (turn, face_player, react), avance au toucher de la boîte ou à
## `interact`, puis, à la fin, lève les drapeaux « set » **avant** d'émettre
## [signal dialogue_finished].
## Il reçoit ses dépendances par [method setup] : il ne lit aucun autoload.

signal dialogue_started(dialogue_id: StringName)
## Début d'une page (première comprise), après sa mise en scène : tests, futurs sons.
signal page_started(index: int)
## Fin du dialogue : boîte fermée, drapeaux levés, PNJ revenu à ses affaires, joueur libre.
signal dialogue_finished(dialogue_id: StringName)

## Raison de blocage du joueur pendant un dialogue ([method Player.set_input_enabled]).
const REASON: StringName = &"dialogue"
const _INTERACT: StringName = &"interact"

## Vitesse d'écriture (caractères par seconde ; 0 = page affichée d'un coup).
var chars_per_second: float = UiTokens.DIALOG_CHARS_PER_SECOND

var _library: DialogueLibrary
var _flags: StoryFlags
var _box: DialogueBox
var _player: Player
var _dialogue: Dialogue
var _variant: DialogueVariant
var _session: DialogueSession
var _npc: Npc
var _map: GameMap
var _running: bool = false
var _closing: bool = false
## Temps restant avant l'ouverture de la boîte (dialogue automatique).
var _delay_left: float = 0.0
## Image de l'appel à play : un appui dans cette image ne fait pas avancer.
var _play_frame: int = -1


func _ready() -> void:
	set_process(_running)


func _process(delta: float) -> void:
	if not _running or _closing:
		return
	if _session == null:
		_delay_left -= delta
		if _delay_left <= 0.0:
			_start_session()
		return
	if Input.is_action_just_pressed(_INTERACT) and Engine.get_process_frames() != _play_frame:
		_advance()
		if _session == null or _closing:
			return
	_session.update(delta)
	_refresh_box()


## Branche le lecteur. [param flags] : drapeaux de la partie (GameState.flags en jeu, neufs
## en test). Peut être rappelé : les dépendances sont remplacées.
func setup(library: DialogueLibrary, flags: StoryFlags, box: DialogueBox,
		player: Player) -> void:
	if _box != null and _box.advance_requested.is_connected(_on_advance_requested):
		_box.advance_requested.disconnect(_on_advance_requested)
	_library = library
	_flags = flags
	_box = box
	_player = player
	if _box != null:
		_box.advance_requested.connect(_on_advance_requested)


## Joue [param dialogue_id]. Faux (et rien ne se passe) si un dialogue tourne déjà, si
## l'identifiant est inconnu (push_error) ou si aucune variante ne s'applique (push_error).
## [param npc] : celui à qui l'on parle (face_player, fin d'interaction) ; [param map] :
## carte où chercher les cibles des « react ». [param delay] : le joueur est bloqué tout de
## suite, la boîte s'ouvre après ce délai (dialogue automatique).
func play(dialogue_id: StringName, npc: Npc = null, map: GameMap = null,
		delay: float = 0.0) -> bool:
	if _running:
		return false
	var dialogue := _library.get_dialogue(dialogue_id) if _library != null else null
	if dialogue == null:
		push_error("DialogueRunner : dialogue inconnu « %s »" % dialogue_id)
		return false
	var variant := dialogue.pick(_flags)
	if variant == null:
		push_error("DialogueRunner : aucune variante de « %s » ne s'applique" % dialogue_id)
		return false
	_running = true
	_closing = false
	_dialogue = dialogue
	_variant = variant
	_npc = npc
	_map = map
	_session = null
	_delay_left = maxf(delay, 0.0)
	_play_frame = Engine.get_process_frames()
	if _player != null:
		_player.set_input_enabled(false, REASON)
	dialogue_started.emit(dialogue_id)
	if _delay_left <= 0.0:
		_start_session()
	set_process(true)
	return true


func is_running() -> bool:
	return _running


## Vrai si la variante qui s'appliquerait maintenant à [param dialogue_id] est « auto ».
func has_auto_variant(dialogue_id: StringName) -> bool:
	var dialogue := _library.get_dialogue(dialogue_id) if _library != null else null
	if dialogue == null:
		return false
	var variant := dialogue.pick(_flags)
	return variant != null and variant.auto


## Déroulé en cours (null avant l'ouverture de la boîte et hors dialogue).
func get_session() -> DialogueSession:
	return _session


## Identifiant du dialogue en cours (&"" hors dialogue).
func get_dialogue_id() -> StringName:
	return _dialogue.id if _dialogue != null else &""


## Étape 2 : ouverture de la boîte et première page.
func _start_session() -> void:
	_session = DialogueSession.new(_variant.pages, _dialogue.speaker, chars_per_second)
	if _box != null:
		_box.open()
	_begin_page()


## Étape 3 : affichage de la page courante et sa mise en scène.
func _begin_page() -> void:
	var page := _session.get_page()
	if _box != null:
		_box.show_page(_session.get_speaker(), page.text, _dialogue.narration)
	for actor_id: StringName in page.turn:
		_apply_turn(actor_id, page.turn[actor_id])
	if page.face_player and is_instance_valid(_npc) and _player != null:
		_npc.face_toward(_player.get_cell())
	if not page.react.is_empty():
		var target: Npc = _map.get_npc(page.react) if is_instance_valid(_map) else null
		if target == null:
			push_warning("DialogueRunner : « react » vers « %s » introuvable (%s)" % [
				page.react, _dialogue.id])
		else:
			target.react()
	_refresh_box()
	page_started.emit(_session.get_page_index())


## Indication « turn » d'une page (jalon 3B §2.7) : [param actor_id] (« player » ou PNJ de
## la carte) se tourne vers [param target] (nom de direction, « player » ou PNJ : axe
## dominant). Acteur ou cible introuvable : push_warning, le dialogue continue.
func _apply_turn(actor_id: StringName, target: StringName) -> void:
	var actor := _find_actor(actor_id)
	if actor == null:
		push_warning("DialogueRunner : « turn » de « %s » introuvable (%s)" % [
			actor_id, _dialogue.id])
		return
	var direction := Grid.direction_from_name(target)
	if not Grid.is_direction_name(target):
		var other := _find_actor(target)
		if other == null:
			push_warning("DialogueRunner : « turn » vers « %s » introuvable (%s)" % [
				target, _dialogue.id])
			return
		direction = Grid.dominant_direction(_actor_cell(actor), _actor_cell(other))
	if direction == Vector2i.ZERO:
		return
	if actor is Player:
		(actor as Player).face(direction)
	else:
		(actor as Npc).face(direction)


## Joueur (« player ») ou PNJ de la carte du dialogue ; null sinon.
func _find_actor(actor_id: StringName) -> Node2D:
	if actor_id == NpcRoster.PLAYER_ID:
		return _player if is_instance_valid(_player) else null
	if not is_instance_valid(_map):
		return null
	return _map.get_npc(actor_id)


static func _actor_cell(actor: Node2D) -> Vector2i:
	if actor is Player:
		return (actor as Player).get_cell()
	return (actor as Npc).get_cell()


func _refresh_box() -> void:
	if _box == null or _session == null:
		return
	var complete := _session.is_page_complete()
	_box.set_visible_characters(-1 if complete else _session.get_visible_characters())
	_box.set_continue_visible(complete and not _session.is_last_page())


## Étape 5 : toucher ou `interact`.
func _advance() -> void:
	if not _running or _closing or _session == null:
		return
	match _session.advance():
		DialogueSession.Step.REVEALED:
			_refresh_box()
		DialogueSession.Step.NEXT_PAGE:
			_begin_page()
		DialogueSession.Step.FINISHED:
			_finish()


## Étape 6 : fermeture, drapeaux, PNJ, joueur, puis signal.
func _finish() -> void:
	_closing = true
	if _box != null:
		await _box.close()
	var dialogue := _dialogue
	if _flags != null:
		for flag: StringName in _variant.set_flags:
			_flags.set_flag(flag)
	if is_instance_valid(_npc):
		_npc.end_interaction()
	if is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	_running = false
	_closing = false
	_dialogue = null
	_variant = null
	_session = null
	_npc = null
	_map = null
	set_process(false)
	dialogue_finished.emit(dialogue.id)


func _on_advance_requested() -> void:
	if Engine.get_process_frames() == _play_frame:
		return
	_advance()
