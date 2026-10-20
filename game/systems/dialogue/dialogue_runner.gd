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
##
## Fins de variante (jalon-07.md §3.3, §6.2) :
## - **choix** ([DialogueChoice]) : après la dernière page (la question), la boîte reste
##   ouverte et [signal choice_requested] est émis ; le lecteur n'avance plus jusqu'à
##   [method choose]. Confirmer : l'action du choix est attendue (boîte ouverte, joueur bloqué),
##   puis les pages de confirmation ; annuler : les pages d'annulation. Puis la fin normale.
##   Les drapeaux du bouton choisi (« confirm_set » / « cancel_set », jalon 13) sont levés dès
##   [method choose].
## - **action** : jouée à la fin, boîte fermée, **avant** que le joueur soit rendu.
##   `heal` émet [signal heal_requested] (moment du jalon 5 inchangé : après avoir rendu le
##   joueur) ; les autres sont attendues par [member action_handler].
## - **scène** : [signal cutscene_requested] juste après [signal dialogue_finished] ; aussi
##   après un choix confirmé dont [member DialogueChoice.confirm_cutscene] est posé (jalon 12).
## Jetons de texte (jalon-07.md §3.6, T18) : les pages sont résolues par [DialogueTokens] au
## début du dialogue et au début des pages d'une réponse de choix, avec [member token_values] ;
## une page dont un jeton n'a pas de valeur est omise. Toutes omises : comme une variante sans
## page (pas de boîte). Les jetons du locuteur (`{rival}`, OUV.2) sont résolus de même ; un
## locuteur sans valeur est caché.

signal dialogue_started(dialogue_id: StringName)
## Début d'une page (première comprise), après sa mise en scène : tests, futurs sons.
signal page_started(index: int)
## Fin du dialogue : boîte fermée, drapeaux levés, PNJ revenu à ses affaires, joueur libre.
signal dialogue_finished(dialogue_id: StringName)
## La variante jouée demande un soin de l'équipe (clé « heal », jalon 5 §3.11) : émis une
## seule fois, à la fin du dialogue, avant [signal dialogue_finished]. Câblé par [Boot].
signal heal_requested
## Le choix de la variante attend le joueur (la boîte garde la question) : [param view] porte la
## question en titre et les deux libellés. Câblé par [Boot] vers [method DialogueBox.show_choice].
signal choice_requested(view: ChoiceView)
## Le joueur a répondu au choix ([method choose]) ; émis avant l'action et les pages de la
## réponse. Lu par le [DaycareDirector] (J15) pour enchaîner ses répliques.
signal choice_made(confirmed: bool)
## La variante se termine par une scène : émis une fois, juste après [signal dialogue_finished]
## (joueur rendu ; la scène pose son propre verrou). Câblé par [Boot] vers [CutsceneDirector].
signal cutscene_requested(cutscene_id: StringName)

## Raison de blocage du joueur pendant un dialogue ([method Player.set_input_enabled]).
const REASON: StringName = &"dialogue"
const _INTERACT: StringName = &"interact"

## Vitesse d'écriture (caractères par seconde ; 0 = page affichée d'un coup).
var chars_per_second: float = UiTokens.DIALOG_CHARS_PER_SECOND
## Coroutine appelée pour une action autre que `heal` (`func(action: StringName) -> void`),
## attendue avant la suite (pages du choix ou fin). Non valide : l'action est ignorée
## (push_error) et le dialogue continue. Posé par [Boot] (ServiceDirector.run_action, T8).
var action_handler: Callable
## Valeurs des jetons de texte (`func() -> Dictionary[StringName, String]`, jalon-07.md §3.6),
## lues seulement si une page à jouer contient un jeton. Non valide : aucune valeur (les pages à
## jeton sont omises). Posé par [Boot] (T19) : [method DialogueTokens.values_for].
var token_values: Callable
## Aléatoire des variantes à tirage (« one_in », jalon 14) : `func() -> GameRng`, lu à chaque
## [method play] (la partie chargée remplace son aléatoire). Non valide : ces variantes sont
## sautées. Posé par [Boot] (GameState.rng).
var rng_source: Callable
## Espèces capturées au Pokédex (`func() -> int`, jalon 17, jalon-17.md §2.5) : lu à chaque choix
## de variante (« if_caught_at_least », « unless_caught_at_least »). Non valide : 0. Posé par
## [Boot] (GameState.pokedex).
var caught_count: Callable
## État d'une capacité de terrain (jalon 16, [member DialogueVariant.field]) :
## `func(move: StringName) -> FieldMoves.Result`. Non valide : les variantes « field » sont
## sautées. Posé par [Boot] ([FieldMoves]). Le Pokémon nommé remplace `{pokemon}` dans la variante
## choisie.
var field_source: Callable
## Jalon 20 (§2.9.6, §2.16) : `func(item_id) -> bool` (le Sac contient l'objet) et
## `func(zone_id) -> bool` ([method ZoneLibrary.is_playable]) pour « if_items », « unless_items »
## et « if_zone ». Posés par [Boot] ; non valides : ces variantes sont sautées.
var item_source: Callable
var zone_source: Callable

var _library: DialogueLibrary
var _flags: StoryFlags
var _box: DialogueBox
var _player: Player
var _dialogue: Dialogue
var _variant: DialogueVariant
## Nom du Pokémon d'une variante « field » (jeton `{pokemon}`), "" sinon.
var _field_name: String = ""
var _session: DialogueSession
var _npc: Npc
var _map: GameMap
var _running: bool = false
var _closing: bool = false
## Temps restant avant l'ouverture de la boîte (dialogue automatique).
var _delay_left: float = 0.0
## Image de l'appel à play : un appui dans cette image ne fait pas avancer.
var _play_frame: int = -1
## Le choix de la variante attend [method choose].
var _awaiting_choice: bool = false
## Le choix a été fait (les pages jouées sont celles de sa réponse).
var _choice_done: bool = false
## Réponse du choix : OUI (jalon 12, T23 : la scène [member DialogueChoice.confirm_cutscene]).
var _confirmed: bool = false
## Une action du choix est en cours (rien n'avance).
var _in_action: bool = false


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
	var variant := dialogue.pick(_flags, _rng(), _caught(), field_source, item_source,
		zone_source)
	if variant == null:
		push_error("DialogueRunner : aucune variante de « %s » ne s'applique" % dialogue_id)
		return false
	_running = true
	_closing = false
	_dialogue = dialogue
	_variant = variant
	_field_name = _field_pokemon_name(variant)
	_npc = npc
	_map = map
	_session = null
	_awaiting_choice = false
	_choice_done = false
	_confirmed = false
	_in_action = false
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


## Vrai si la variante qui s'appliquerait maintenant à [param dialogue_id] est « auto » (sans
## tirage : une variante « one_in » n'est jamais « auto »).
func has_auto_variant(dialogue_id: StringName) -> bool:
	var dialogue := _library.get_dialogue(dialogue_id) if _library != null else null
	if dialogue == null:
		return false
	var variant := dialogue.pick(_flags, null, _caught(), Callable(), item_source, zone_source)
	return variant != null and variant.auto


## Réponse du joueur au choix en attente ([signal choice_requested]) ; sans choix en attente
## (ou une seconde fois) : rien.
func choose(confirmed: bool) -> void:
	if not _running or not _awaiting_choice:
		return
	_awaiting_choice = false
	_choice_done = true
	_confirmed = confirmed
	choice_made.emit(confirmed)
	var choice := _variant.choice
	# Drapeaux du bouton choisi (jalon-13.md §2.13), levés tout de suite, avant la fermeture.
	if _flags != null:
		for flag: StringName in choice.confirm_set if confirmed else choice.cancel_set:
			_flags.set_flag(flag)
	if confirmed and not choice.confirm_action.is_empty():
		_in_action = true
		await _run_action(choice.confirm_action)
		_in_action = false
		if not _running:
			return
	var pages := _resolve_pages(choice.confirm_pages if confirmed else choice.cancel_pages)
	if pages.is_empty():
		_finish()
		return
	_session = DialogueSession.new(pages, _default_speaker(), chars_per_second)
	_begin_page()


## Vrai entre [signal choice_requested] et [method choose].
func is_awaiting_choice() -> bool:
	return _awaiting_choice


## Déroulé en cours (null avant l'ouverture de la boîte et hors dialogue).
func get_session() -> DialogueSession:
	return _session


## Identifiant du dialogue en cours (&"" hors dialogue).
func get_dialogue_id() -> StringName:
	return _dialogue.id if _dialogue != null else &""


## Étape 2 : ouverture de la boîte et première page.
func _start_session() -> void:
	var pages := _resolve_pages(_variant.pages)
	if pages.is_empty():
		# Action ou scène seule (terminal du Stockage) : pas de boîte. Fin à l'image suivante,
		# pour que play() rende la main avant dialogue_finished.
		_closing = true
		_finish.call_deferred()
		return
	_session = DialogueSession.new(pages, _default_speaker(), chars_per_second)
	if _box != null:
		_box.open()
	_begin_page()


## Pages prêtes à jouer (jetons résolus, pages sans valeur omises) ; sans jeton : telles quelles.
func _resolve_pages(pages: Array[DialoguePage]) -> Array[DialoguePage]:
	if not DialogueTokens.has_tokens(pages):
		return pages
	return DialogueTokens.resolve_pages(pages, _token_values())


## Locuteur du dialogue, jetons résolus (`"speaker": "{rival}"`, dossier 13 §3.5).
func _default_speaker() -> String:
	var speaker := _dialogue.speaker
	if DialogueTokens.tokens_in(speaker).is_empty():
		return speaker
	return DialogueTokens.resolve_speaker(speaker, _token_values())


func _token_values() -> Dictionary[StringName, String]:
	var values: Dictionary[StringName, String] = {}
	if token_values.is_valid():
		var raw: Variant = token_values.call()
		if raw is Dictionary:
			values.assign(raw)
	if not _field_name.is_empty():
		values[DialogueTokens.POKEMON] = _field_name
	return values


## Nom du Pokémon qu'une variante « field » nomme (jeton `{pokemon}`) ; "" sinon.
func _field_pokemon_name(variant: DialogueVariant) -> String:
	if variant.field.is_empty() or not field_source.is_valid():
		return ""
	var result: Variant = field_source.call(StringName(variant.field.get_slice(":", 0)))
	return (result as FieldMoves.Result).pokemon_name if result is FieldMoves.Result else ""


## Étape 3 : affichage de la page courante et sa mise en scène.
func _begin_page() -> void:
	var page := _session.get_page()
	if _box != null:
		_box.show_page(_session.get_speaker(), page.text, _dialogue.narration, page.voice)
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
	if not _running or _closing or _session == null or _awaiting_choice or _in_action:
		return
	match _session.advance():
		DialogueSession.Step.REVEALED:
			_refresh_box()
		DialogueSession.Step.NEXT_PAGE:
			_begin_page()
		DialogueSession.Step.FINISHED:
			if _variant.choice != null and not _choice_done:
				_awaiting_choice = true
				choice_requested.emit(_variant.choice.to_view(_session.get_text()))
			else:
				_finish()


## Action [param action] : `heal` → [signal heal_requested] ; sinon [member action_handler],
## attendu. [param shop] (jalon 20, clé « shop » de `open_shop`) : passé en second argument
## quand il est renseigné.
func _run_action(action: StringName, shop: StringName = &"") -> void:
	if action == &"heal":
		heal_requested.emit()
		return
	if not action_handler.is_valid():
		push_error("DialogueRunner : action « %s » sans gestionnaire (%s)" % [
			action, _dialogue.id if _dialogue != null else &""])
		return
	if shop.is_empty():
		await action_handler.call(action)
	else:
		await action_handler.call(action, shop)


## Étape 6 : fermeture, drapeaux, PNJ, joueur, puis signal.
func _finish() -> void:
	_closing = true
	if _box != null:
		await _box.close()
	var dialogue := _dialogue
	var action := _variant.action
	var shop := _variant.shop
	var cutscene := _variant.cutscene
	if _confirmed and _variant.choice != null and not _variant.choice.confirm_cutscene.is_empty():
		cutscene = _variant.choice.confirm_cutscene
	if _flags != null:
		for flag: StringName in _variant.set_flags:
			_flags.set_flag(flag)
	if not action.is_empty() and action != &"heal":
		await _run_action(action, shop)
	if is_instance_valid(_npc):
		_npc.end_interaction()
	if is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	_running = false
	_closing = false
	_dialogue = null
	_variant = null
	_session = null
	_awaiting_choice = false
	_choice_done = false
	_confirmed = false
	_npc = null
	_map = null
	set_process(false)
	if action == &"heal":
		heal_requested.emit()
	dialogue_finished.emit(dialogue.id)
	if not cutscene.is_empty():
		cutscene_requested.emit(cutscene)


func _on_advance_requested() -> void:
	if Engine.get_process_frames() == _play_frame:
		return
	_advance()


## Espèces capturées ([member caught_count]) ; 0 sans source.
func _caught() -> int:
	if not caught_count.is_valid():
		return 0
	return int(caught_count.call())


## Aléatoire des tirages « one_in » ([member rng_source]), ou null.
func _rng() -> GameRng:
	if not rng_source.is_valid():
		return null
	return rng_source.call() as GameRng
