class_name StarterChoice
extends Node
## Choix du starter au labo (docs/tech/jalon-04.md §3.5, remplacé par §13.3) : logique du
## choix, sans mise en scène (la mise en scène est la scène de données
## [member StarterOffer.chosen_scene], `data/cutscenes/starter.json`).
##
## - **Ouverture** : quand [member StarterOffer.open_flag] est levé, il attend la fin de la
##   scène en cours (discours de Chen), puis pose la légende ([member StarterOffer.prompt])
##   et l'interaction « Rencontrer » ([constant Interaction.Kind.MEET]) sur les PNJ des
##   choix encore sur la table. [method set_map] la repose en revenant au labo, et
##   [method on_map_entered] y réaffiche la légende, tant que le choix est ouvert.
## - **Rencontrer** ([signal InteractionController.meet_requested]) : joueur bloqué
##   ([constant REASON]), le Pokémon s'avance ([method Npc.lean_toward]), fiche ouverte
##   ([StarterSheet], vue faite à partir de [PokemonData] et de l'offre).
## - **RETOUR** : fiche fermée, Pokémon revenu ([method Npc.settle]), joueur libre.
## - **CHOISIR** (synchrone) : fiche fermée, choix du rival ([method StarterOffer.rival_pick]),
##   drapeaux `taken_<espèce>` des deux Pokémon, surcharges retirées, espèce **en attente**,
##   scène jouée avec les alias `player_starter` / `rival_starter` ; le blocage n'est rendu
##   qu'**après** [method CutsceneDirector.play] (qui bloque déjà) : jamais libre entre les
##   deux. Si la scène est refusée : push_error, et il lève lui-même
##   [member StarterOffer.done_flag] (le Pokémon n'est jamais perdu).
## - **Entrée dans l'équipe** (décision de Kevin n° 1) : seulement quand
##   [member StarterOffer.done_flag] est levé (par la scène, juste après « On dirait que le
##   choix est réciproque. ») : [method PokemonFactory.create] au niveau de l'offre avec
##   l'aléatoire de la partie, ajout à l'équipe, [member starter_species], drapeau
##   [member StarterOffer.female_flag] si c'est une femelle (accord « lui / elle » des
##   dialogues, décision n° 16), puis [signal starter_chosen].
## Il reçoit tout par [method setup], y compris l'état de partie (l'autoload GameState en
## jeu, une instance neuve de game_state.gd en test) : il ne lit aucun autoload. Aucun nom
## d'espèce, de drapeau ni de scène n'est écrit ici : tout vient de l'offre.

## Fiche ouverte (le joueur est bloqué).
signal sheet_opened
## Fiche fermée (RETOUR, ou CHOISIR après le lancement de la scène).
signal sheet_closed
## Le starter a rejoint l'équipe ; [param rival_species] : le Pokémon pris par le rival.
signal starter_chosen(player_species: StringName, rival_species: StringName)

## Raison de blocage du joueur pendant la fiche ([method Player.set_input_enabled]).
const REASON: StringName = &"starter_choice"
## Préfixe des drapeaux « ce Pokémon a quitté la table » (+ identifiant d'espèce).
const TAKEN_PREFIX: String = "taken_"
## Alias passés à la scène du choix ([method CutsceneDirector.play]).
const PLAYER_ALIAS: StringName = &"player_starter"
const RIVAL_ALIAS: StringName = &"rival_starter"

var _offer: StarterOffer
var _data: PokemonData
## État de partie : flags (StoryFlags), party (Party), starter_species, rng (GameRng).
var _state: Node
var _player: Player
var _sheet: StarterSheet
var _hud: ExplorationHud
var _cutscenes: CutsceneDirector
var _interactions: InteractionController
var _flags: StoryFlags
var _map: GameMap
## Ouverture différée à la fin de la scène en cours.
var _open_after_cutscene: bool = false
var _sheet_open: bool = false
## Pokémon rencontré (fiche ouverte) et son choix.
var _meet_npc: Npc
var _meet_option: StarterOption
## Espèces choisies en attente de done_flag (&"" hors attente).
var _pending: StringName = &""
var _pending_rival: StringName = &""


## Branche le choix (rappelable : l'ancien branchement est défait, un choix en cours oublié).
## [param state] : objet avec flags, party, starter_species, rng (GameState).
func setup(offer: StarterOffer, data: PokemonData, state: Node, player: Player,
		sheet: StarterSheet, hud: ExplorationHud, cutscenes: CutsceneDirector,
		interactions: InteractionController) -> void:
	_disconnect_all()
	_offer = offer
	_data = data
	_state = state
	_player = player
	_sheet = sheet
	_hud = hud
	_cutscenes = cutscenes
	_interactions = interactions
	_flags = state.get(&"flags") as StoryFlags if state != null else null
	_open_after_cutscene = false
	_sheet_open = false
	_meet_npc = null
	_meet_option = null
	_pending = &""
	_pending_rival = &""
	if _flags != null:
		_flags.flag_changed.connect(_on_flag_changed)
	if _cutscenes != null:
		_cutscenes.cutscene_finished.connect(_on_cutscene_finished)
	if _interactions != null:
		_interactions.meet_requested.connect(_on_meet_requested)
	if _sheet != null:
		_sheet.choose_pressed.connect(_on_choose_pressed)
		_sheet.back_pressed.connect(_on_back_pressed)


## Carte courante (relais de Boot sur SceneRouter.map_changed) : sur la carte de l'offre, si
## le choix est ouvert, « Rencontrer » est reposé sur les Pokémon encore sur la table.
func set_map(map: GameMap) -> void:
	_map = map
	if is_open() and not _open_after_cutscene:
		_apply_overrides()


## Arrivée sur une carte (SceneRouter.map_entered, après le fondu) : la légende revient sur
## la carte de l'offre tant que le choix est ouvert (Q2).
func on_map_entered(map: GameMap) -> void:
	if map != _map:
		set_map(map)
	if is_open() and not _open_after_cutscene and _is_offer_map() and _hud != null:
		_hud.show_caption(_offer.prompt)


## Choix ouvert : offre faite, pas encore choisi (ni CHOISIR touché, ni done_flag levé).
func is_open() -> bool:
	if _offer == null or _flags == null or not _pending.is_empty():
		return false
	return _flags.has_flag(_offer.open_flag) and not _flags.has_flag(_offer.done_flag)


func is_sheet_open() -> bool:
	return _sheet_open


## Espèce choisie en attente d'entrer dans l'équipe (&"" sinon).
func get_pending_species() -> StringName:
	return _pending


## Drapeau « [param species] a quitté la table ».
static func taken_flag(species: StringName) -> StringName:
	return StringName(TAKEN_PREFIX + String(species))


## Drapeaux levés par ce code pour [param offer] (tests de données : chaque drapeau lu est
## levé quelque part) : un `taken_<espèce>` par choix, puis
## [member StarterOffer.female_flag] s'il existe. [member StarterOffer.done_flag] est levé
## par la scène.
static func get_set_flags(offer: StarterOffer) -> Array[StringName]:
	var flags: Array[StringName] = []
	for species: StringName in offer.get_species_ids():
		flags.append(taken_flag(species))
	if not offer.female_flag.is_empty():
		flags.append(offer.female_flag)
	return flags


## Vue de la fiche pour [param option] : nom de l'espèce, types (identifiants et noms),
## phrase de l'offre. null si l'espèce est inconnue.
static func make_view(option: StarterOption, data: PokemonData) -> StarterSheetView:
	var species := data.get_species(option.species)
	if species == null:
		return null
	var ids: Array[StringName] = []
	var names: Array[String] = []
	for type: StringName in species.types:
		ids.append(type)
		names.append(data.get_type_chart().get_type_name(type))
	return StarterSheetView.new(species.name, ids, names, option.blurb)


func _is_offer_map() -> bool:
	return is_instance_valid(_map) and _map.map_id == _offer.map_id


## Ouverture : légende et « Rencontrer » (si le labo est la carte courante).
func _open_choice() -> void:
	if not is_open() or not _is_offer_map():
		return
	_apply_overrides()
	if _hud != null:
		_hud.show_caption(_offer.prompt)


## Pose MEET sur chaque PNJ de choix présent sur la carte et pas encore pris.
func _apply_overrides() -> void:
	if not _is_offer_map():
		return
	for option: StarterOption in _offer.get_choices():
		var npc := _map.get_npc(option.npc)
		if npc == null or _flags.has_flag(taken_flag(option.species)):
			continue
		npc.set_interaction_override(Interaction.new(Interaction.Kind.MEET, npc.get_cell(),
			&"", Vector2i.ZERO, npc))


func _clear_overrides() -> void:
	if not is_instance_valid(_map):
		return
	for option: StarterOption in _offer.get_choices():
		var npc := _map.get_npc(option.npc)
		if npc != null:
			npc.clear_interaction_override()


func _on_flag_changed(flag: StringName, value: bool) -> void:
	if _offer == null or not value:
		return
	if flag == _offer.open_flag:
		if _cutscenes != null and _cutscenes.is_running():
			_open_after_cutscene = true
		else:
			_open_choice()
	elif flag == _offer.done_flag and not _pending.is_empty():
		_join_party()


func _on_cutscene_finished(_cutscene_id: StringName) -> void:
	if not _open_after_cutscene:
		return
	_open_after_cutscene = false
	_open_choice()


func _on_meet_requested(npc: Npc) -> void:
	if _sheet_open or not is_open() or npc == null or _sheet == null:
		return
	var option := _option_of(npc)
	if option == null:
		return
	var view := make_view(option, _data)
	if view == null:
		push_error("StarterChoice : espèce inconnue « %s »" % option.species)
		return
	_meet_npc = npc
	_meet_option = option
	_sheet_open = true
	if is_instance_valid(_player):
		_player.set_input_enabled(false, REASON)
		npc.lean_toward(_player.get_cell())
	_sheet.open(view)
	sheet_opened.emit()


func _on_back_pressed() -> void:
	if not _sheet_open:
		return
	_close_sheet()
	if is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	sheet_closed.emit()


func _on_choose_pressed() -> void:
	if not _sheet_open:
		return
	var option := _meet_option
	_close_sheet()
	var rival := _offer.rival_pick(option.species, _data)
	var rival_option := _offer.get_choice(rival)
	_flags.set_flag(taken_flag(option.species))
	if rival_option != null:
		_flags.set_flag(taken_flag(rival))
	_clear_overrides()
	_pending = option.species
	_pending_rival = rival
	var aliases: Dictionary[StringName, StringName] = {PLAYER_ALIAS: option.npc}
	if rival_option != null:
		aliases[RIVAL_ALIAS] = rival_option.npc
	var played := _cutscenes != null and _cutscenes.play(_offer.chosen_scene, aliases)
	if not played:
		push_error("StarterChoice : scène « %s » refusée, %s rejoint l'équipe sans elle" % [
			_offer.chosen_scene, option.species])
		_flags.set_flag(_offer.done_flag)
	# Après play (qui bloque déjà pour la scène) : le joueur n'est jamais libre entre les deux.
	if is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	sheet_closed.emit()


## Fiche fermée et Pokémon rencontré revenu à sa place.
func _close_sheet() -> void:
	_sheet_open = false
	if _sheet != null:
		_sheet.close()
	if is_instance_valid(_meet_npc):
		_meet_npc.settle()
	_meet_npc = null
	_meet_option = null


## done_flag levé : le Pokémon en attente rejoint officiellement l'équipe.
func _join_party() -> void:
	var species := _pending
	var rival := _pending_rival
	_pending = &""
	_pending_rival = &""
	var rng := _state.get(&"rng") as GameRng
	var pokemon := PokemonFactory.create(_data, species, _offer.level, rng)
	if pokemon == null:
		return
	(_state.get(&"party") as Party).add(pokemon)
	_state.set(&"starter_species", species)
	if pokemon.gender == Pokemon.Gender.FEMALE and not _offer.female_flag.is_empty():
		_flags.set_flag(_offer.female_flag)
	starter_chosen.emit(species, rival)


func _option_of(npc: Npc) -> StarterOption:
	for option: StarterOption in _offer.get_choices():
		if option.npc == npc.get_id():
			return option
	return null


func _disconnect_all() -> void:
	var links: Array[Array] = []
	if _flags != null:
		links.append([_flags.flag_changed, _on_flag_changed])
	if is_instance_valid(_cutscenes):
		links.append([_cutscenes.cutscene_finished, _on_cutscene_finished])
	if is_instance_valid(_interactions):
		links.append([_interactions.meet_requested, _on_meet_requested])
	if is_instance_valid(_sheet):
		links.append([_sheet.choose_pressed, _on_choose_pressed])
		links.append([_sheet.back_pressed, _on_back_pressed])
	for link: Array in links:
		var sig: Signal = link[0]
		if sig.is_connected(link[1]):
			sig.disconnect(link[1])
