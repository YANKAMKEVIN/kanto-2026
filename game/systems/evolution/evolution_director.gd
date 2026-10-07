class_name EvolutionDirector
extends Node
## Joue les évolutions de fin de combat (jalon-09.md §2.3). Appelé par le [BattleDirector] après
## le bilan d'une victoire ou d'une capture, avec les candidats de
## [method Evolution.candidates] ; le verrou du combat reste posé pendant tout ce temps.
##
## Il décide, l'écran ([EvolutionScreen], T9) montre : pour chaque candidat, dans l'ordre de
## l'équipe — [method EvolutionScreen.present] puis [method EvolutionScreen.transform]. Si la
## transformation va à son terme, et **seulement alors**, l'évolution est appliquée
## ([method Evolution.evolve] ; Pokédex : vu et possédé, sans habitat, sans capture comptée)
## puis [method EvolutionScreen.reveal] ; annulée (ARRÊTER ou retour Android), rien ne change
## (reproposée au prochain niveau gagné, Q-2) et [method EvolutionScreen.revert]. Ensuite, les
## capacités de la nouvelle espèce passent par le [MoveLearnPrompt] (« apprend », ou l'oubli),
## dans le bandeau de l'écran. Rien n'est écrit sur disque ici : une application tuée pendant
## l'écran reprend à la dernière sauvegarde (l'autosave suit [signal BattleDirector.battle_finished]).
##
## Sans écran ([method set_screen] jamais appelé : tests, outils), l'évolution est appliquée sans
## attendre et les capacités sont apprises s'il reste une place (sinon rien ne change : aucun
## choix n'est fait à la place du joueur). Il ne lit aucun autoload : GameState arrive par
## [method setup].

## Une évolution commence (avant la présentation) : [param into] est l'espèce visée.
signal evolution_started(party_index: int, into: StringName)
## Une évolution est terminée, capacités comprises ; [param cancelled] : arrêtée par le joueur.
signal evolution_finished(party_index: int, into: StringName, cancelled: bool)

## Relayé à l'écran avant chaque ouverture (0 = instantané, tests).
var speed_scale: float = 1.0

var _state: Node
var _data: PokemonData
var _texts: BattleText
var _learn: MoveLearnPrompt
var _screen: EvolutionScreen
var _playing: bool = false


## Branche le directeur. [param state] : l'autoload GameState en jeu, une instance neuve de
## game_state.gd en test (Pokédex). [param learn] : le déroulé « apprendre / oublier » partagé
## avec le combat ([method BattleDirector.get_move_learn_prompt]) ; null = capacités apprises
## sans rien montrer.
func setup(state: Node, data: PokemonData, texts: BattleText, learn: MoveLearnPrompt) -> void:
	_state = state
	_data = data
	_texts = texts
	_learn = learn


## L'écran d'évolution (T9) ; null = aucun (évolution immédiate).
func set_screen(screen: EvolutionScreen) -> void:
	_screen = screen


func get_screen() -> EvolutionScreen:
	return _screen if is_instance_valid(_screen) else null


## Des évolutions sont en cours (de l'appel de [method play] à son retour).
func is_playing() -> bool:
	return _playing


## Coroutine : joue [param candidates] (pris dans [param party]) l'un après l'autre, l'écran
## ouvert une seule fois pour tous. Rend la main une fois l'écran refermé. Rien si la liste est
## vide ou si des évolutions sont déjà en cours.
func play(candidates: Array[EvolutionCandidate], party: Party) -> void:
	if candidates.is_empty() or party == null:
		return
	if _playing:
		push_error("EvolutionDirector : des évolutions sont déjà en cours")
		return
	_playing = true
	var screen := get_screen()
	if screen != null:
		screen.speed_scale = speed_scale
		await screen.open()
	for candidate: EvolutionCandidate in candidates:
		await _play_one(candidate, party, screen)
	if _learn != null:
		_learn.release()
	if screen != null:
		await screen.close()
	_playing = false


## Retour Android (relayé par [method BattleDirector.handle_back]) : arrête la transformation
## en cours (l'écran décide si le moment s'y prête). Vrai pendant toutes les évolutions : le
## geste n'atteint jamais ce qui est dessous.
func handle_back() -> bool:
	if not _playing:
		return false
	var screen := get_screen()
	if screen != null:
		screen.handle_back()
	return true


## Coroutine : une évolution, capacités comprises.
func _play_one(candidate: EvolutionCandidate, party: Party, screen: EvolutionScreen) -> void:
	var pokemon := party.get_at(candidate.party_index)
	if pokemon == null or pokemon.species_id != candidate.from_species \
			or not _data.has_species(candidate.into):
		push_error("EvolutionDirector : évolution impossible (place %d, %s → %s)"
			% [candidate.party_index, candidate.from_species, candidate.into])
		return
	var view := make_view(candidate, pokemon)
	evolution_started.emit(candidate.party_index, candidate.into)
	var cancelled := false
	if screen != null:
		await screen.present(view)
		cancelled = await screen.transform()
	var moves: Array[StringName] = []
	if not cancelled:
		moves = Evolution.evolve(pokemon, candidate.into, _data)
		if _state != null:
			_state.record_evolved(candidate.into)
	_log(view, cancelled)
	if screen != null:
		if cancelled:
			await screen.revert()
		else:
			await screen.reveal()
	for move_id: StringName in moves:
		await _teach(pokemon, candidate.party_index, move_id, screen)
	evolution_finished.emit(candidate.party_index, candidate.into, cancelled)


## Ce que l'écran montre pour [param candidate] ([param pokemon] pas encore évolué).
func make_view(candidate: EvolutionCandidate, pokemon: Pokemon) -> EvolutionView:
	var view := EvolutionView.new()
	var from := _data.get_species(candidate.from_species)
	var into := _data.get_species(candidate.into)
	view.party_index = candidate.party_index
	view.pokemon_name = pokemon.display_name(_data)
	view.from_species = candidate.from_species
	view.into_species = candidate.into
	view.from_name = from.name if from != null else String(candidate.from_species)
	view.into_name = into.name if into != null else String(candidate.into)
	view.from_dex = from.dex if from != null else 0
	view.into_dex = into.dex if into != null else 0
	if _texts != null:
		# Le nom est celui d'avant l'évolution ; {species} lit l'espèce de l'événement.
		var event := BattleEvent.new(BattleEvent.Kind.BATTLE_STARTED, BattleEvent.SideId.PLAYER)
		event.pokemon_name = view.pokemon_name
		event.gender = pokemon.gender
		event.party_index = candidate.party_index
		event.level = pokemon.level
		event.species_id = candidate.into
		view.started_text = _texts.line_for(&"evolution_started", event, _data)
		view.finished_text = _texts.line_for(&"evolution_finished", event, _data)
		view.cancelled_text = _texts.line_for(&"evolution_cancelled", event, _data)
		view.stop_label = _texts.get_template(&"evolution_stop")
		view.continue_text = _texts.get_template(&"summary_continue")
	return view


## Coroutine : [param move_id] pour [param pokemon] (déjà évolué), dans le bandeau de l'écran ;
## sans écran ni déroulé : appris s'il reste une place.
func _teach(pokemon: Pokemon, party_index: int, move_id: StringName,
		screen: EvolutionScreen) -> void:
	var banner := screen.get_message_banner() if screen != null else null
	var host := screen.get_prompt_host() if screen != null else null
	if _learn != null and banner != null:
		await _learn.teach(pokemon, party_index, move_id, banner, host)
	else:
		pokemon.learn_move(move_id, _data)


## Journal de QA (builds debug) : « [qa] évolution Chenipan → Chrysacier (faite) ».
static func _log(view: EvolutionView, cancelled: bool) -> void:
	if not OS.is_debug_build():
		return
	print("[qa] évolution %s → %s (%s)" % [view.from_name, view.into_name,
		"annulée" if cancelled else "faite"])
