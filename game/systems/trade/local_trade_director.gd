class_name LocalTradeDirector
extends Node
## Terminal d'échange local d'un Centre Pokémon (jalon 32, T5 ; `jalon-32.md` §1.2, N-15 : tous
## les Centres). Le terminal (`trade_terminal`, action `open_local_trade`) demande la
## conversation ; [Boot] la lance à la fin du dialogue ([method run]).
##
## Déroulé (textes du §3 du plan, deux lignes de 40 caractères au plus) :
## 1. aucun Pokémon compatible ([method LocalTrade.candidates]) : [constant NONE], fin ;
## 2. le choix ([member pick_handler] : le [PartyPicker] de [TradeOverlay], titre
##    [constant LocalTrade.PICK_TEXT], places refusées avec leur raison) ; ANNULER : fin ;
## 3. [constant CONFIRM] « Échanger {pokemon} ? » (ÉCHANGER / ANNULER) ; ANNULER : fin ;
## 4. l'écran d'évolution, **non annulable**, dont l'application est [method LocalTrade.execute]
##    (copie de travail puis remplacement au même rang, individu conservé), puis les capacités.
##
## Atomicité (§5 du plan, « appli tuée au milieu d'un échange ») : le joueur reste bloqué
## ([constant REASON]) de bout en bout, la partie n'est jamais stable, rien n'est écrit ; une
## application tuée reprend à la sauvegarde d'avant (Pokémon d'origine). L'échange lui-même se fait
## dans un seul appel synchrone. Fin : [signal finished] (Boot : compagnon, autosave).
##
## Ne lit aucun autoload : GameState arrive par [method setup].

## La conversation commence (joueur bloqué).
signal started
## Fin de la conversation (joueur rendu). [param traded] : un Pokémon a évolué (à écrire).
signal finished(traded: bool)

## Raison de blocage du joueur pendant toute la conversation.
const REASON: StringName = &"local_trade"
## Répliques (`data/dialogues/j32_local_trade.json`).
const TERMINAL: StringName = &"trade_terminal"
const NONE: StringName = &"trade_terminal_none"
const CONFIRM: StringName = &"trade_terminal_confirm"

## Choix du Pokémon : `func(view: PartyPickerView) -> int` (coroutine), la place ou −1. Invalide :
## le premier Pokémon compatible (tests, outils).
var pick_handler: Callable

var _state: Node
var _player: Player
var _runner: DialogueRunner
var _data: PokemonData
var _evolutions: EvolutionDirector
var _map: GameMap
var _running: bool = false
var _last_choice: bool = false
var _tokens: Dictionary[StringName, String] = {}


## [param state] : l'autoload GameState en jeu, une instance de game_state.gd en test.
## Rappelable (le joueur est rebranché).
func setup(state: Node, player: Player, runner: DialogueRunner, data: PokemonData,
		evolutions: EvolutionDirector) -> void:
	if _runner != null and _runner.choice_made.is_connected(_on_choice_made):
		_runner.choice_made.disconnect(_on_choice_made)
	_state = state
	_player = player
	_runner = runner
	_data = data
	_evolutions = evolutions
	if _runner != null:
		_runner.choice_made.connect(_on_choice_made)


func set_map(map: GameMap) -> void:
	_map = map


func is_running() -> bool:
	return _running


## `{pokemon}` pendant la confirmation (vide sinon).
func token_values() -> Dictionary[StringName, String]:
	return _tokens


## Retour Android : avalé pendant toute la conversation (le choix et la confirmation ont leur
## propre ANNULER, l'évolution n'est pas annulable). Faux hors conversation.
func handle_back() -> bool:
	return _running


## Coroutine : la conversation du terminal, jusqu'au joueur rendu. Rien si elle tourne déjà.
func run() -> void:
	if _running or _state == null or _runner == null or _data == null:
		return
	_running = true
	_tokens = {}
	if is_instance_valid(_player):
		_player.set_input_enabled(false, REASON)
	started.emit()
	var traded := await _flow()
	_tokens = {}
	if is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	_running = false
	finished.emit(traded)


func _flow() -> bool:
	var party: Party = _state.party
	var accepted := LocalTrade.candidates(party, _data)
	if accepted.is_empty():
		await _say(NONE)
		return false
	var index: int = accepted[0]
	if pick_handler.is_valid():
		index = await pick_handler.call(LocalTrade.picker_view(party, _data))
	if not index in accepted:
		return false
	var pokemon := party.get_at(index)
	_tokens = {DialogueTokens.POKEMON: pokemon.display_name(_data)}
	if not await _ask(CONFIRM):
		return false
	_tokens = {}
	var into := LocalTrade.trade_target(pokemon, _data)
	var candidate := EvolutionCandidate.new(index, pokemon.species_id, into)
	var map_id: StringName = _map.map_id if is_instance_valid(_map) else &""
	# Le compagnon est désigné par son identifiant, gardé par l'échange : Boot rafraîchit son
	# apparence à la fin. Le Pokédex suit par l'évolution ([method GameState.record_evolved]).
	var applier := func() -> Dictionary:
		var result := LocalTrade.execute(party, index, _data, null, map_id)
		_log(result)
		return result if result["status"] == LocalTrade.Status.DONE else {}
	if _evolutions == null:
		return not (applier.call() as Dictionary).is_empty()
	return await _evolutions.play_trade(candidate, party, applier)


## Coroutine : joue [param dialogue_id] jusqu'à sa fin.
func _say(dialogue_id: StringName) -> void:
	if not _runner.play(dialogue_id, null, _map):
		push_error("LocalTradeDirector : la réplique « %s » n'a pas été jouée" % dialogue_id)
		return
	await _runner.dialogue_finished


## Coroutine : [param dialogue_id] (une variante à choix) ; vrai si ÉCHANGER.
func _ask(dialogue_id: StringName) -> bool:
	_last_choice = false
	await _say(dialogue_id)
	return _last_choice


func _on_choice_made(confirmed: bool) -> void:
	if _running:
		_last_choice = confirmed


## Journal de QA (builds debug) : « [qa] échange local Kadabra → Alakazam (fait) ».
func _log(result: Dictionary) -> void:
	if not OS.is_debug_build():
		return
	print("[qa] échange local %s → %s (%s)" % [result["from"], result["into"],
		"fait" if result["status"] == LocalTrade.Status.DONE else "refusé"])
