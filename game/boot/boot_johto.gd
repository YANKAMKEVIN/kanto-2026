class_name BootJohto
extends Node
## Domaine « Chapitre Johto » de [Boot] (JOH0 à JOH9, JOHP0 à JOHP3).
##
## Heure du monde lue à Johto seulement et moment imposé par l'histoire, choix du Pokémon de
## départ d'Orme, vol et retour de l'équipe (écran du choix des 6), survol en Dracolosse, Réveil
## des pierres, lien et éclosion des œufs.
##
## Extrait de `boot.gd` sans changer le comportement : Boot crée ce nœud, appelle chaque `setup_*`
## au même moment qu'avant le découpage, et relaie ses accesseurs publics. L'horloge
## ([WorldClock]) reste créée et cadencée par Boot (la lumière en dépend) ; ce module la lit.

## JOH5 (T-29) : des Pokémon sont allés au Stockage au retour de l'équipe (drapeau de travail).
const JOHTO_RETURN_STORED_FLAG: StringName = &"johto_return_stored"
## JOHP0 : P-31 (`data/dialogues/johp0.json`) et l'annonce du Stockage.
const AWAKENING_LINES: StringName = &"stones_awakening_line"
const AWAKENING_STORED: StringName = &"stones_awakening_stored"

var _boot: Boot
var _clock: WorldClock
## JOH1 (`jalon-joh1.md` §2.6) : l'offre d'Orme (`starters_johto.json`) et son contrôleur, créé en
## code sur la même fiche que celui de Chen.
var _offer := StarterOffer.new()
var _starter_choice: StarterChoice
## Jeton `{pokemon}` des répliques d'Orme pendant la scène du choix (le starter de Johto).
var _starter_tokens: Dictionary[StringName, String] = {}
## JOH1 : un départ de débogage a imposé `period` : la règle d'histoire ([JohtoPeriodRule]) se tait.
var _debug_period_forced: bool = false
## JOHP0 : le film et l'écran du Réveil (étape « stones_awaken »).
var _awakening_overlay: AwakeningOverlay
## JOH0 : l'écran du choix des 6 au retour de l'équipe (étape « return_team »).
var _team_return_overlay: TeamReturnOverlay
## JOHP3 : le survol sur le Dracolosse de Corentin (étape « dragon_flight »).
var _dragon_flight_overlay: DragonFlightOverlay
## JOH0 (`jalon-joh0.md` §2.7, §2.9) : pas du lien et des œufs ; œufs prêts à éclore, joués au
## prochain pas où la partie est stable ; jeton {pokemon} du dialogue d'éclosion.
var _bond_steps := BondStepCounter.new()
var _pending_hatch: Array[Pokemon] = []
var _hatch_tokens: Dictionary[StringName, String] = {}


func _init(boot: Boot = null, clock: WorldClock = null) -> void:
	_boot = boot
	_clock = clock


# --- Accesseurs (relayés par Boot) -------------------------------------------------------------

func get_starter_choice() -> StarterChoice:
	return _starter_choice


func get_starter_offer() -> StarterOffer:
	return _offer


func get_awakening_overlay() -> AwakeningOverlay:
	return _awakening_overlay


func get_team_return_overlay() -> TeamReturnOverlay:
	return _team_return_overlay


func get_dragon_flight_overlay() -> DragonFlightOverlay:
	return _dragon_flight_overlay


# --- Heure du monde (JOH0, JH-8) et moment imposé (JOH1, JOH8) ---------------------------------

## Vrai si [param map_id] est une carte de Johto (sa zone le dit).
func is_johto_map(map_id: StringName) -> bool:
	var zones := _boot.get_zone_library()
	return zones != null and zones.is_johto(map_id)


## Le moment courant à lire sur [param map_id] : celui de l'horloge à Johto, &"" ailleurs (Kanto
## n'a pas d'heure).
func period_for_map(map_id: StringName) -> StringName:
	return _clock.period_name() if is_johto_map(map_id) and _clock.is_active() else &""


## [moment, jour] à lire sur [param map_id] (la carte courante si vide) : ceux de l'horloge à
## Johto, vides ailleurs.
func current_time(map_id: StringName = &"") -> Array[StringName]:
	var id := map_id
	if id.is_empty():
		var map := SceneRouter.get_current_map()
		id = map.map_id if is_instance_valid(map) else &""
	var period := period_for_map(id)
	return [period, _clock.weekday_name() if not period.is_empty() else &""]


## Départ de débogage qui impose `period` : l'horloge le garde, la règle d'histoire se tait.
func force_debug_period(period: StringName) -> void:
	_clock.force_period(WorldClock.PERIOD_NAMES[String(period)])
	_debug_period_forced = true


## JOH1 (`jalon-joh1.md` §2.4) : moment du jour imposé par l'histoire ([JohtoPeriodRule]) :
## nuit de la lettre au vol, matin du vol au départ d'Orme, heure réelle ensuite ; recalculé à la
## mise en place de la partie et à chaque drapeau. Un départ de débogage qui impose `period` gagne.
func apply_story_period(map_id: StringName = &"") -> void:
	if _debug_period_forced:
		return
	var period := JohtoPeriodRule.forced_period(GameState.flags)
	# JOH8 (JH-55) : aube forcée au sommet de la Tour Carillon, relue à chaque carte.
	if period.is_empty():
		if map_id.is_empty():
			map_id = _boot.current_map_id()
		if map_id.is_empty():
			map_id = GameState.current_map
		period = BellTowerDawnRule.forced_period(map_id, GameState.flags)
	if period.is_empty():
		if _clock.is_period_forced():
			_clock.release_period()
	else:
		_clock.force_period(WorldClock.PERIOD_NAMES[String(period)])


# --- Pokémon de départ d'Orme (JOH1) -----------------------------------------------------------

## L'offre de Johto (Orme, salle de repos du Centre d'Oliville), second contrôleur du choix.
func setup_starter() -> void:
	var pokemon := _boot.get_pokemon_data()
	if _offer.load_file(StarterOffer.JOHTO_DATA_PATH):
		_offer.check_species(pokemon)
	_starter_choice = StarterChoice.new()
	_starter_choice.name = "StarterChoiceJohto"
	_starter_choice.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_starter_choice)
	_starter_choice.setup(_offer, pokemon, GameState, _boot.get_player(),
		_boot.get_starter_sheet(), _boot.get_hud(), _boot.get_cutscene_director(),
		_boot.get_interaction_controller())
	_starter_choice.sheet_opened.connect(_boot.refresh_controls)
	_starter_choice.sheet_closed.connect(_boot.refresh_controls)


## JOH1 (`jalon-joh1.md` §2.6) : le Pokémon de départ de Johto rejoint l'équipe (Pokédex,
## rencontre « starter » au lien 50, Grand moment comme à Kanto), devient **compagnon** (dossier
## JOH-02 §8 ; sans planche de compagnon il reste dans sa Ball, JOH0 §2.11) et prête son nom au
## jeton `{pokemon}` des répliques d'Orme jusqu'à la fin de la scène du choix.
func on_starter_chosen(player_species: StringName, _rival_species: StringName) -> void:
	_boot.record_starter(player_species)
	var chosen := _starter_choice.get_last_chosen()
	if chosen == null:
		return
	GameState.set_companion(chosen)
	_starter_tokens = {DialogueTokens.POKEMON: chosen.display_name(_boot.get_pokemon_data())}


## Fin d'une scène : le jeton `{pokemon}` d'Orme ne vaut plus.
func clear_starter_tokens() -> void:
	_starter_tokens = {}


## Jetons des dialogues propres à Johto : le Pokémon qui vient d'éclore, puis le Pokémon de
## départ d'Orme pendant la scène du choix (fusionnés dans cet ordre, en écrasant).
func merge_token_values(values: Dictionary[StringName, String]) -> void:
	values.merge(_hatch_tokens, true)
	values.merge(_starter_tokens, true)


# --- Étapes de scène : vol de l'équipe, survol, Réveil (JOH0, JOHP0, JOHP3) ---------------------

## JOH0 (`jalon-joh0.md` §2.2) : l'écran du choix des 6 et le survol (avant le gestionnaire du
## point de repos, posé par Boot entre les deux appels, comme avant le découpage).
func setup_overlays() -> void:
	_team_return_overlay = TeamReturnOverlay.new()
	_team_return_overlay.name = "TeamReturnOverlay"
	_team_return_overlay.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_team_return_overlay)
	_dragon_flight_overlay = DragonFlightOverlay.new()
	_dragon_flight_overlay.name = "DragonFlightOverlay"
	_dragon_flight_overlay.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_dragon_flight_overlay)
	_boot.get_cutscene_director().dragon_flight_handler = _on_dragon_flight_requested


## Le vol et le retour de l'équipe (étapes « confiscate_team » et « return_team »), l'œuf reçu,
## puis le Réveil (JOHP0, `jalon-joh-pierres.md` §2 : étape « stones_awaken ») et son écran.
func setup_cutscene_steps() -> void:
	var cutscenes := _boot.get_cutscene_director()
	cutscenes.team_return_handler = _on_team_return_requested
	cutscenes.team_confiscated.connect(_on_team_confiscated)
	cutscenes.team_returned.connect(_on_team_returned)
	cutscenes.egg_given.connect(_on_egg_given)
	_awakening_overlay = AwakeningOverlay.new()
	_awakening_overlay.name = "AwakeningOverlay"
	_awakening_overlay.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_awakening_overlay)
	var awakening_art := BattleArt.new()
	awakening_art.setup(_boot.get_pokemon_data(), _boot.get_pokedex_library())
	_awakening_overlay.setup(awakening_art)


## Gestionnaires du Réveil (posés après les zones du directeur de scènes, comme avant).
func setup_awakening_handlers() -> void:
	var cutscenes := _boot.get_cutscene_director()
	cutscenes.awakening_handler = _on_awakening_film_requested
	cutscenes.awakening_screen_handler = _on_awakening_review_requested


## Retour Android : le choix des 6 est obligatoire et le Réveil ne se passe pas ; retour avalé.
func handle_back() -> bool:
	if _team_return_overlay != null and _team_return_overlay.handle_back():
		return true
	return _awakening_overlay != null and _awakening_overlay.handle_back()


## JOHP3 (étape « dragon_flight ») : le survol ; la scène change de carte derrière.
func _on_dragon_flight_requested(direction: StringName) -> void:
	if direction == &"land":
		await _dragon_flight_overlay.finish()
		return
	_dragon_flight_overlay.reduce_motion = _boot.get_settings().reduce_motion
	await _dragon_flight_overlay.play(direction)


## JOH0 (étape « return_team ») : l'écran du choix des 6 ; rend les identifiants gardés.
func _on_team_return_requested(selection: TeamReturnSelection) -> Array[String]:
	# JOH5 (dossier JOH-06 §7.3) : six Pokémon ou moins en tout, pas d'écran, tout le monde rentre.
	if selection.get_pool().size() <= TeamReturnSelection.MAX_KEPT:
		return selection.default_selection()
	var pokemon := _boot.get_pokemon_data()
	var labels: Array[String] = []
	for member: Pokemon in selection.get_pool():
		labels.append("%s  N. %d" % [member.display_name(pokemon), member.level])
	return await _team_return_overlay.pick(selection, labels)


## JOHP0 : le film du Réveil. P-31 et l'annonce des captures viennent des dialogues
## ([constant AWAKENING_LINES], [constant AWAKENING_STORED]).
func _on_awakening_film_requested(report: AwakeningReport) -> void:
	_awakening_overlay.speed_scale = _boot.get_battle_director().speed_scale
	_awakening_overlay.reduce_flashes = _boot.get_evolution_screen().reduce_flashes
	var stored := ""
	if not report.stored.is_empty():
		stored = "\n".join(PackedStringArray(_dialogue_pages(AWAKENING_STORED)))
	await _awakening_overlay.film(report, _dialogue_pages(AWAKENING_LINES), stored)


## JOHP0 : l'écran du Réveil, après l'écriture ; vrai si une attaque a été apprise.
func _on_awakening_review_requested(report: AwakeningReport) -> bool:
	var learned := await _awakening_overlay.review(report,
		_boot.get_battle_director().get_move_learn_prompt())
	_boot.get_audio_bridge().on_awakening_finished()
	_boot.get_companion_controller().refresh()
	return learned


## Textes de la première variante du dialogue [param id].
func _dialogue_pages(id: StringName) -> Array[String]:
	var result: Array[String] = []
	var dialogue := _boot.get_dialogue_library().get_dialogue(id)
	if dialogue == null or dialogue.variants.is_empty():
		push_error("Boot : dialogue « %s » absent" % id)
		return result
	for page: DialoguePage in dialogue.variants[0].pages:
		result.append(page.text)
	return result


## JOH0 : l'équipe vient d'être confisquée d'un seul bloc : le compagnon rentre (plus d'équipe) ;
## la scène écrit par son étape « save » (l'autosave demandé ici est une ceinture de plus).
func _on_team_confiscated() -> void:
	_boot.get_companion_controller().refresh()
	_boot.request_autosave("vol de l'équipe")


## JOH0 : l'équipe est revenue d'un seul bloc : compagnon à jour, autosave demandé.
func _on_team_returned(stored: int) -> void:
	# JOH5 (T-29) : drapeau de travail lu par la scène du bureau, baissé par elle après l'écriture.
	if stored > 0:
		GameState.flags.set_flag(JOHTO_RETURN_STORED_FLAG)
	_boot.get_companion_controller().refresh()
	_boot.request_autosave("retour de l'équipe")


## JOH0 : un œuf vient d'entrer dans l'équipe (étape « give_egg ») : autosave demandé.
func _on_egg_given(_egg: Pokemon) -> void:
	_boot.request_autosave("œuf reçu")


# --- Lien et œufs (JOH0 §2.7, §2.9) ------------------------------------------------------------

## Branché sur le pas du joueur (avant le Flair, comme avant le découpage).
func setup_bond_steps() -> void:
	_boot.get_player().moved.connect(_on_player_moved_for_bond)


## Un pas du joueur : le lien et les œufs comptent ([BondStepCounter]) ; un œuf arrivé à terme
## éclot dès que la partie est stable (hors combat, scène, dialogue, menu).
func _on_player_moved_for_bond(_cell: Vector2i) -> void:
	var result := _bond_steps.on_player_moved(GameState.party, GameState.companion_uid,
		_boot.get_player().is_input_enabled())
	for egg: Pokemon in result["hatched"]:
		if not _pending_hatch.has(egg):
			_pending_hatch.append(egg)
	_try_hatch()


## Joue l'éclosion du premier œuf prêt si la partie est stable : l'œuf devient un Pokémon
## (origine « egg », Pokédex vu et capturé), le dialogue le nomme, autosave.
func _try_hatch() -> void:
	if _pending_hatch.is_empty() or not _boot.is_stable() or _boot.get_menu_director().is_open():
		return
	var egg: Pokemon = _pending_hatch.pop_front()
	if GameState.party.index_of(egg) < 0 \
			or not EggRules.hatch(egg, GameState, _boot.current_map_id()):
		return
	_hatch_tokens = {DialogueTokens.POKEMON: egg.display_name(_boot.get_pokemon_data())}
	_boot.get_companion_controller().refresh()
	if not _boot.get_dialogue_runner().play(EggRules.HATCH_DIALOGUE, null,
			SceneRouter.get_current_map()):
		push_error("Boot : le dialogue de l'éclosion n'a pas été joué")
	_boot.request_autosave("éclosion")
