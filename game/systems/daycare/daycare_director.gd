class_name DaycareDirector
extends Node
## La Pension sur la carte (J15, T4 ; jalon-15.md §2.5 ; dossier 18 §4, textes T-1 à T-12). Relais
## sans règle : les règles sont dans [DaycareRules], le choix des répliques dans [DaycareLines].
##
## - **Pas** : branché sur [signal Player.moved] ([method setup]) ; [DaycareStepCounter] filtre
##   les pas non libres (scènes) ; XP mise en attente dans `GameState.daycare` (relue à chaque pas :
##   `new_game` / `load_dict` la remplacent). Rien n'est écrit sur disque à chaque pas.
## - **Conversation** ([method run], coroutine, lancée par [Boot] à la fin du dialogue du gardien,
##   action `open_daycare`) : joueur bloqué (raison [constant REASON]) de bout en bout, donc
##   `Boot.is_stable()` faux et aucune autosave au milieu.
##   - Pension vide : T-2 et OUI / NON (NON → T-3) → T-4 → écran du dépôt
##     ([signal pick_requested] ; réponse [method choose_deposit] ou [method cancel_pick]) →
##     [method DaycareRules.deposit], compagnon effacé si c'était lui, [signal deposited] (Boot
##     écrit **tout de suite**) → T-6.
##   - Pension occupée : équipe pleine → T-9 ; sinon T-7 / T-8 et OUI / NON → retrait
##     ([method DaycareRules.withdraw] : XP, soin, retour dans l'équipe), débit de
##     [member DaycareWithdrawal.paid] (seul endroit du jeu, avec la Boutique, qui retire de
##     l'argent) → T-10 / T-11 → capacités une à une puis évolution annulable
##     ([OffBattleLevelUp]) → T-12 → [signal finished] avec `withdrew` vrai (Boot écrit **une
##     seule fois**, à la fin). Une application tuée avant reprend avant le retrait.
## - **Écran** : aucun ici. Le dépôt passe par [signal pick_requested] (écran du T5,
##   `DaycareOverlay`) ; sans personne pour l'écouter, le dépôt est annulé (push_warning) : jamais
##   de blocage. Les capacités passent par le voile [member overlay] (un [TmLearnOverlay] ou son
##   héritier), nul = sans écran (appris s'il reste une place).
## - **Retour Android** ([method handle_back]) : pendant l'écran du dépôt = ANNULER ; sinon avalé
##   (l'évolution est relayée avant par `BattleDirector.handle_back`).
## Ne lit aucun autoload : GameState arrive par [method setup].

## La conversation commence (joueur bloqué).
signal started
## L'écran du dépôt doit s'ouvrir ([param view] : l'équipe et les raisons de refus).
signal pick_requested(view: DaycarePickView)
## L'écran du dépôt doit se fermer (choix fait ou annulé).
signal pick_closed
## Un Pokémon vient d'être confié (état déjà changé) : Boot écrit la sauvegarde tout de suite.
signal deposited(pokemon: Pokemon)
## Un Pokémon vient d'être rendu (XP appliquée, soigné, dans l'équipe, argent débité), avant les
## capacités et l'évolution.
signal withdrawn(plan: DaycareWithdrawal)
## La conversation est finie (joueur rendu). [param withdrew] : un retrait a eu lieu (à écrire).
signal finished(withdrew: bool)

## Raison de blocage du joueur pendant toute la conversation.
const REASON: StringName = &"daycare"
## Pas de réponse de l'écran du dépôt.
const _NO_PICK: int = -2

## Voile des capacités (bandeau + hôte des panneaux) ; nul = sans écran.
var overlay: TmLearnOverlay = null

var _state: Node
var _player: Player
var _runner: DialogueRunner
var _library: DialogueLibrary
var _data: PokemonData
var _config: DaycareConfig
var _counter: DaycareStepCounter
var _learn: MoveLearnPrompt
var _evolutions: EvolutionDirector
var _map: GameMap
var _running: bool = false
var _picking: bool = false
var _picked: int = _NO_PICK
var _last_choice: bool = false
var _tokens: Dictionary[StringName, String] = {}


## Branche le directeur. [param state] : l'autoload GameState en jeu, une instance de
## game_state.gd en test. Rappelable (le joueur est rebranché).
func setup(state: Node, player: Player, runner: DialogueRunner, library: DialogueLibrary,
		data: PokemonData, config: DaycareConfig) -> void:
	if is_instance_valid(_player) and _player.moved.is_connected(_on_player_moved):
		_player.moved.disconnect(_on_player_moved)
	if _runner != null and _runner.choice_made.is_connected(_on_choice_made):
		_runner.choice_made.disconnect(_on_choice_made)
	_state = state
	_player = player
	_runner = runner
	_library = library
	_data = data
	_config = config
	_counter = DaycareStepCounter.new(config)
	if _player != null:
		_player.moved.connect(_on_player_moved)
	if _runner != null:
		_runner.choice_made.connect(_on_choice_made)


## Capacités (déroulé partagé avec le combat) et évolutions (directeur partagé avec le combat).
func set_learning(learn: MoveLearnPrompt, evolutions: EvolutionDirector) -> void:
	_learn = learn
	_evolutions = evolutions


## Carte courante (cibles des « react » des répliques).
func set_map(map: GameMap) -> void:
	_map = map


func is_running() -> bool:
	return _running


## Vrai entre [signal pick_requested] et la réponse.
func is_picking() -> bool:
	return _picking


func get_step_counter() -> DaycareStepCounter:
	return _counter


## Valeurs des jetons `{pokemon}`, `{levels}`, `{price}` (vides hors d'une conversation de la
## Pension : une page qui les cite serait omise, jamais affichée avec « {pokemon} »).
func token_values() -> Dictionary[StringName, String]:
	return _tokens


## Coroutine : la conversation de la Pension, jusqu'au joueur rendu. Rien si elle tourne déjà.
func run() -> void:
	if _running or _state == null or _runner == null:
		return
	_running = true
	_tokens = {}
	if is_instance_valid(_player):
		_player.set_input_enabled(false, REASON)
	started.emit()
	var withdrew := false
	var daycare: Daycare = _state.daycare
	var preview := DaycareRules.preview(daycare, _party(), _state.money, _config, _data)
	var line := DaycareLines.for_visit(preview)
	match line:
		DaycareLines.OFFER:
			await _deposit_flow()
		DaycareLines.VISIT, DaycareLines.VISIT_LEVELS:
			withdrew = await _withdraw_flow(preview, line)
		DaycareLines.PARTY_FULL:
			await _say(line)
		_:
			push_warning("DaycareDirector : retrait refusé sans réplique (%s)"
				% DaycareRules.Status.find_key(preview.status))
	_tokens = {}
	if is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	_running = false
	finished.emit(withdrew)


## Réponse de l'écran du dépôt : confie la place [param index] si elle peut l'être. Renvoie le
## statut ([enum DaycareRules.Status] : OK, ou la raison du refus — l'écran montre alors
## T-5 / la raison, et le choix reste ouvert). Hors écran du dépôt : NOT_FOUND.
func choose_deposit(index: int) -> DaycareRules.Status:
	if not _picking:
		return DaycareRules.Status.NOT_FOUND
	var status := DaycareRules.can_deposit(_state.daycare, _party(), index)
	if status == DaycareRules.Status.OK:
		_picked = index
	return status


## ANNULER (ou retour Android) sur l'écran du dépôt : rien ne change.
func cancel_pick() -> void:
	if _picking:
		_picked = -1


## Retour Android : écran du dépôt → ANNULER ; pendant la conversation → avalé. Faux hors
## conversation.
func handle_back() -> bool:
	if not _running:
		return false
	cancel_pick()
	return true


## Coroutine : dépôt (T-2 … T-6).
func _deposit_flow() -> void:
	if not await _ask(DaycareLines.OFFER):
		return
	await _say(DaycareLines.PICK)
	var index := await _pick()
	if index < 0:
		return
	var party := _party()
	var mon := party.get_at(index)
	var companion: Pokemon = _state.get_companion()
	var status := DaycareRules.deposit(_state.daycare, party, index, _data)
	if status != DaycareRules.Status.OK:
		push_error("DaycareDirector : dépôt refusé (%s)" % DaycareRules.Status.find_key(status))
		return
	mon.ensure_uid()
	if companion != null and companion == mon:
		_state.set_companion(null)
	_tokens = DaycareLines.token_values(mon, 0, 0, _data)
	_log("dépôt : %s N%d" % [mon.display_name(_data), mon.level])
	deposited.emit(mon)
	await _say(DaycareLines.DEPOSITED)


## Coroutine : retrait (T-7 / T-8 … T-12). Vrai si le Pokémon a été rendu.
func _withdraw_flow(preview: DaycarePreview, line: StringName) -> bool:
	_tokens = DaycareLines.token_values(preview.pokemon, preview.levels_gained, preview.price,
		_data)
	if not await _ask(line):
		return false
	var party := _party()
	var plan := DaycareRules.withdraw(_state.daycare, party, _state.money, _config, _data)
	if not plan.is_ok():
		push_error("DaycareDirector : retrait refusé (%s)" % DaycareRules.Status.find_key(
			plan.status))
		return false
	_state.spend_money(plan.paid)
	_log("retrait : %s N%d, %d ₽ payés sur %d, capacités %s, évolution « %s »" % [
		plan.pokemon.display_name(_data), plan.pokemon.level, plan.paid, plan.price, plan.moves,
		plan.evolution])
	withdrawn.emit(plan)
	await _say(DaycareLines.for_withdrawal(plan))
	var index := party.index_of(plan.pokemon)
	if not plan.moves.is_empty():
		var banner: BattleMessageBanner = null
		var host: Control = null
		if is_instance_valid(overlay):
			overlay.open()
			banner = overlay.get_message_banner()
			host = overlay.get_prompt_host()
		await OffBattleLevelUp.teach_moves(plan.pokemon, index, plan.moves, _learn, banner, host,
			_data)
		if _learn != null:
			_learn.release()
		if is_instance_valid(overlay):
			overlay.close()
	await OffBattleLevelUp.offer_evolution(plan.pokemon, index, plan.evolution, _evolutions,
		party)
	await _say(DaycareLines.AFTER)
	return true


## Coroutine : l'écran du dépôt. Renvoie la place choisie, ou -1 (ANNULER, aucun écran).
func _pick() -> int:
	if pick_requested.get_connections().is_empty():
		push_warning("DaycareDirector : aucun écran du dépôt branché ; dépôt annulé")
		return -1
	_picking = true
	_picked = _NO_PICK
	pick_requested.emit(DaycareLines.pick_view(_state.daycare, _party(),
		_first_page(DaycareLines.LAST_ABLE)))
	while _picked == _NO_PICK:
		await get_tree().process_frame
	_picking = false
	pick_closed.emit()
	return _picked


## Coroutine : joue [param dialogue_id] jusqu'à sa fin.
func _say(dialogue_id: StringName) -> void:
	if not _runner.play(dialogue_id, null, _map):
		push_error("DaycareDirector : la réplique « %s » n'a pas été jouée" % dialogue_id)
		return
	await _runner.dialogue_finished


## Coroutine : joue [param dialogue_id] (une variante à choix) ; vrai si OUI.
func _ask(dialogue_id: StringName) -> bool:
	_last_choice = false
	await _say(dialogue_id)
	return _last_choice


## Texte de la première page de [param dialogue_id] ("" s'il manque).
func _first_page(dialogue_id: StringName) -> String:
	var dialogue := _library.get_dialogue(dialogue_id) if _library != null else null
	if dialogue == null or dialogue.variants.is_empty() or dialogue.variants[0].pages.is_empty():
		return ""
	return dialogue.variants[0].pages[0].text


func _party() -> Party:
	return _state.party as Party


func _on_player_moved(_cell: Vector2i) -> void:
	if _state == null or _counter == null:
		return
	_counter.on_player_moved(_state.daycare, _player.is_input_enabled())


func _on_choice_made(confirmed: bool) -> void:
	if _running:
		_last_choice = confirmed


## Journal de QA (builds debug).
static func _log(message: String) -> void:
	if OS.is_debug_build():
		print("[qa] pension, " + message)
