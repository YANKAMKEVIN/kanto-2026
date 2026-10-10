class_name IntroPlayer
extends Node
## Joue l'introduction du Prof. Chen (OUV.2, dossier 13 §4 plans 2 à 8, §5.5, §7) : relie le
## curseur pur ([IntroReader] sur [IntroScript]) à l'affichage — la scène ([IntroStage]), la
## boîte de dialogue du jeu ([DialogueBox]) et l'écran de prénom ([NameEntry]).
##
## Étapes (dans l'ordre des données, `data/opening/oak_intro.json`) :
##  - **stage** : les mouvements de scène consécutifs sont joués **ensemble** ; on attend le plus
##    long (un tween : le temps se simule dans les tests), puis on continue sans toucher ;
##  - **page** : le texte s'écrit à la vitesse des Paramètres ([member chars_per_second]) ; toucher
##    (ou `interact`) le complète, puis passe à la suite ;
##  - **prompt** : la question de Chen s'écrit dans la boîte (qui reste visible) et l'écran de
##    prénom s'ouvre aussitôt (pastilles de [OpeningNames], champ prérempli après un « Non ») ;
##  - **confirm** : « X ! C'est bien ça ? », puis le choix à deux cartes de la boîte (Non à gauche,
##    Oui à droite) ; Non rouvre l'écran de prénom, champ prérempli.
## À la fin, la boîte se ferme et [signal finished] donne les deux prénoms (normalisés). Rien
## n'est écrit ici : l'introduction n'existe qu'en mémoire (§3.7). Retour Android :
## [method handle_back] ferme le clavier, puis rien (§5.5).

## Fin de la dernière réplique (boîte fermée) : les prénoms retenus.
signal finished(player_name: String, rival_name: String)
## Étape [param index] du script commencée (texte déjà dans la boîte, écran de prénom ouvert ;
## mouvements de scène : au début du groupe) : tests, captures.
signal step_started(index: int)

const _INTERACT: StringName = &"interact"

## Vitesse d'écriture (caractères par seconde ; 0 = page entière d'un coup) : celle des Paramètres.
var chars_per_second: float = UiTokens.DIALOG_CHARS_PER_SECOND

var _script: IntroScript
var _names: OpeningNames
var _reader: IntroReader
var _stage: IntroStage
var _box: DialogueBox
var _entry: NameEntry
var _session: DialogueSession
var _running: bool = false
## Un groupe de mouvements de scène est en cours (aucun toucher n'est pris).
var _staging: bool = false
## Le choix Oui / Non est affiché (étape confirm).
var _choice_shown: bool = false
var _start_frame: int = -1


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if not _running or _session == null:
		return
	if Input.is_action_just_pressed(_INTERACT) and Engine.get_process_frames() != _start_frame:
		advance()
		if _session == null:
			return
	_session.update(delta)
	_refresh_box()


## Branche le lecteur. [param intro] et [param names] : déjà chargés.
func setup(intro: IntroScript, names: OpeningNames, stage: IntroStage, box: DialogueBox) -> void:
	_script = intro
	_names = names
	_stage = stage
	_box = box
	_entry = stage.get_name_entry()


## Lance l'introduction depuis la première étape.
func start() -> void:
	_reader = IntroReader.new(_script, _names.max_length())
	_box.advance_requested.connect(advance)
	_box.choice_made.connect(_on_choice_made)
	_entry.submitted.connect(submit_name)
	_running = true
	_start_frame = Engine.get_process_frames()
	set_process(true)
	_play_current()


## Toucher (boîte) ou `interact` : compléter la page, puis passer à la suivante. Sans effet pendant
## un mouvement de scène, sur l'écran de prénom (une fois la question écrite) et pendant le choix.
func advance() -> void:
	if not _running or _staging or _session == null:
		return
	var entry := _reader.current()
	if entry == null:
		return
	if not _session.is_page_complete():
		_session.advance()
		_refresh_box()
		return
	if entry.type == IntroStep.Type.PAGE:
		_reader.advance()
		_play_current()


## Prénom saisi (VALIDER) : faux s'il n'est pas valide ou si l'on n'attend pas de prénom.
func submit_name(raw: String) -> bool:
	if not _running or not is_waiting_for_name():
		return false
	if not _reader.answer_prompt(raw):
		return false
	_entry.close()
	_play_current()
	return true


## Réponse au choix « C'est bien ça ? » (vrai : Oui). Faux si aucun choix n'est attendu.
func answer(yes: bool) -> bool:
	if not _running or not is_waiting_for_choice():
		return false
	if _box.is_choice_showing():
		_box.hide_choice()
	_choice_shown = false
	_reader.answer_confirm(yes)
	_play_current()
	return true


## Retour Android pendant l'introduction : ferme le clavier s'il est ouvert, sinon rien ; vrai
## tant que l'introduction tourne (le retour lui appartient : jamais de retour en arrière, §5.5).
func handle_back() -> bool:
	if not _running:
		return false
	if _entry != null and _entry.is_open():
		_entry.release_keyboard()
	return true


func is_running() -> bool:
	return _running


## Vrai quand l'écran de prénom attend une saisie.
func is_waiting_for_name() -> bool:
	var entry := _reader.current() if _reader != null else null
	return entry != null and entry.type == IntroStep.Type.PROMPT and not _staging


## Vrai quand le choix Oui / Non est affiché.
func is_waiting_for_choice() -> bool:
	var entry := _reader.current() if _reader != null else null
	return entry != null and entry.type == IntroStep.Type.CONFIRM and _choice_shown


## Vrai pendant un groupe de mouvements de scène.
func is_staging() -> bool:
	return _staging


## Vrai si le texte de l'étape courante est entièrement écrit.
func is_text_complete() -> bool:
	return _session != null and _session.is_page_complete()


func get_reader() -> IntroReader:
	return _reader


## Joue l'étape courante (et les mouvements de scène qui la précèdent) ; à la fin, [method _end].
func _play_current() -> void:
	while _running:
		var entry := _reader.current()
		if entry == null:
			_end()
			return
		if entry.type == IntroStep.Type.STAGE:
			step_started.emit(_reader.index())
			await _play_stage_group()
			continue
		_choice_shown = false
		_show_text(entry)
		if entry.type == IntroStep.Type.PROMPT:
			_entry.open(_names.suggestions(_role_of(entry.name)), _names.max_length(),
				_reader.prefill(), _script.validate_label)
		step_started.emit(_reader.index())
		return


## Les mouvements de scène consécutifs, ensemble ; attend le plus long, puis passe ces étapes.
func _play_stage_group() -> void:
	_staging = true
	if _box.is_open():
		_box.set_continue_visible(false)
	var count := 0
	var longest := 0.0
	var step := _reader.current()
	while step != null and step.type == IntroStep.Type.STAGE:
		var time := _stage.show_portrait(step.portrait, step.slot, step.effect) if step.show \
			else _stage.hide_portrait(step.portrait)
		longest = maxf(longest, time)
		count += 1
		step = _script.step(_reader.index() + count)
	if longest > 0.0:
		await create_tween().tween_interval(longest).finished
	for i: int in count:
		_reader.advance()
	_staging = false


func _show_text(entry: IntroStep) -> void:
	if not _box.is_open():
		_box.open()
	var text := _reader.text()
	_session = DialogueSession.new([DialoguePage.new(text)] as Array[DialoguePage],
		entry.speaker, chars_per_second)
	_box.show_page(entry.speaker, text, false)
	_refresh_box()


func _refresh_box() -> void:
	if _session == null or _reader == null:
		return
	var entry := _reader.current()
	var complete := _session.is_page_complete()
	_box.set_visible_characters(-1 if complete else _session.get_visible_characters())
	var is_page := entry != null and entry.type == IntroStep.Type.PAGE
	_box.set_continue_visible(complete and is_page and not _staging)
	if complete and entry != null and entry.type == IntroStep.Type.CONFIRM and not _choice_shown \
			and not _staging:
		_choice_shown = true
		_box.show_choice(ChoiceView.new(_reader.text(), _script.yes_label, _script.no_label))


func _on_choice_made(confirmed: bool) -> void:
	if is_waiting_for_choice():
		answer(confirmed)


func _end() -> void:
	_running = false
	_session = null
	set_process(false)
	if _box.advance_requested.is_connected(advance):
		_box.advance_requested.disconnect(advance)
	if _box.choice_made.is_connected(_on_choice_made):
		_box.choice_made.disconnect(_on_choice_made)
	await _box.close()
	finished.emit(_reader.player_name(), _reader.rival_name())


static func _role_of(prompt: StringName) -> StringName:
	return OpeningNames.ROLE_RIVAL if prompt == IntroScript.PROMPT_RIVAL_NAME \
		else OpeningNames.ROLE_PLAYER
