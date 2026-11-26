class_name BootLeague
extends Node
## Domaine « Ligue » de [Boot] (jalon 30, `jalon-30.md` §2.2 à §2.4) : tentative de Ligue,
## cérémonie du Panthéon, générique, consultation du Panthéon depuis l'écran Dresseur.
##
## Extrait de `boot.gd` sans changer le comportement : Boot crée ce nœud, appelle [method setup]
## au même moment qu'avant, et relaie ses accesseurs publics. Les nœuds créés ici restent des
## enfants directs de Boot (mêmes noms, mêmes modes de traitement).

const HALL_OF_FAME_SCREEN := preload("res://game/ui/league/hall_of_fame_screen.gd")
const CREDITS_SCREEN := preload("res://game/ui/league/credits_screen.gd")

var _boot: Boot
var _league: LeagueDirector
var _hall_screen: HallOfFameScreen
var _credits_screen: CreditsScreen
var _credits := CreditsData.new()


## [LeagueDirector] : entrée dans la salle d'Olga, victoires, défaite (drapeaux effacés avant le
## réveil). Relais de carte branché avant celui de Boot (drapeaux à jour avant la présence des
## PNJ et les portes de drapeaux) ; fin de combat après l'autosave demandé par Boot (écrit une fois
## la partie stable, drapeaux de la Ligue compris).
func setup(boot: Boot) -> void:
	_boot = boot
	_league = LeagueDirector.new()
	_league.name = "LeagueDirector"
	_league.process_mode = Node.PROCESS_MODE_PAUSABLE
	boot.add_child(_league)
	_league.setup(GameState)
	_league.static_encounters = boot.get_cutscene_library().get_static_encounters()  # J32
	SceneRouter.map_changed.connect(_league.on_map_changed)
	_league.tree_exiting.connect(func() -> void:
		if SceneRouter.map_changed.is_connected(_league.on_map_changed):
			SceneRouter.map_changed.disconnect(_league.on_map_changed))
	boot.get_battle_director().battle_finished.connect(_league.on_battle_finished)
	_setup_ceremony()


func get_league_director() -> LeagueDirector:
	return _league


func get_hall_of_fame_screen() -> HallOfFameScreen:
	return _hall_screen


func get_credits_screen() -> CreditsScreen:
	return _credits_screen


## « 2026-10-26T21:04:00 » → « 26/10/2026 » ; vide si illisible.
static func hall_date(iso: String) -> String:
	var parts := iso.get_slice("T", 0).split("-")
	if parts.size() != 3:
		return ""
	return "%s/%s/%s" % [parts[2], parts[1], parts[0]]


## Écrans du Panthéon et du générique, gestionnaires des étapes « hall_of_fame » et « credits »
## des scènes `league_victory` / `league_hall_of_fame`, et reprise de la cérémonie à l'arrivée
## dans la salle du Champion ou au Panthéon ([method LeagueDirector.pending_cutscene]).
func _setup_ceremony() -> void:
	_credits.load_file()
	_hall_screen = HALL_OF_FAME_SCREEN.new()
	_hall_screen.name = "HallOfFameScreen"
	# Toujours actif : il se consulte aussi depuis le Menu, qui met la partie en pause (Q30-4).
	_hall_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	_boot.add_child(_hall_screen)
	_credits_screen = CREDITS_SCREEN.new()
	_credits_screen.name = "CreditsScreen"
	_credits_screen.process_mode = Node.PROCESS_MODE_PAUSABLE
	_credits_screen.skip_label = _credits.skip_label
	_boot.add_child(_credits_screen)
	var cutscenes := _boot.get_cutscene_director()
	cutscenes.hall_of_fame_handler = _play_hall_of_fame
	cutscenes.credits_handler = _play_credits
	SceneRouter.map_entered.connect(_on_league_map_entered)
	# Q30-4 : le Panthéon se consulte depuis l'écran Dresseur (lecture seule, la plus récente
	# d'abord).
	_boot.get_trainer_menu().hall_of_fame_requested.connect(_browse_hall_of_fame)
	_league.tree_exiting.connect(func() -> void:
		if SceneRouter.map_entered.is_connected(_on_league_map_entered):
			SceneRouter.map_entered.disconnect(_on_league_map_entered))


## Étape « hall_of_fame » : cérémonie due → instantané de l'équipe, écran du Panthéon, puis titre
## et entrée posés ([method LeagueDirector.complete_ceremony]) ; vrai = la partie est à écrire
## (le directeur de scènes l'écrit aussitôt). Déjà faite (reprise) : faux, rien.
func _play_hall_of_fame() -> bool:
	if not _league.ceremony_due():
		return false
	var entry := HallOfFame.snapshot(GameState.party.get_all(), GameState.player_name,
		GameState.starter_species, GameState.play_time, GameState.clock.now_iso())
	await _hall_screen.present(_hall_view(entry))
	return _league.complete_ceremony(entry)


## Étape « credits » : générique sur la dernière entrée du Panthéon ; passable seulement s'il a
## déjà été vu (`league_credits_seen`, posé à la fin).
func _play_credits() -> void:
	var cutscenes := _boot.get_cutscene_director()
	if not cutscenes.credits_id.is_empty():
		await _play_named_credits(cutscenes.credits_id)
		return
	var hall := GameState.hall_of_fame
	var entry := hall.get_entry(hall.size() - 1) if not hall.is_empty() else HallOfFame.snapshot(
		GameState.party.get_all(), GameState.player_name, GameState.starter_species,
		GameState.play_time, "")
	var skippable := GameState.flags.has_flag(LeagueAttempt.CREDITS_SEEN)
	await _credits_screen.present(_credits.rows(entry, _hall_member_name), skippable)
	GameState.flags.set_flag(LeagueAttempt.CREDITS_SEEN)


## JOH9 : petit générique de chapitre [param id] (`data/story/credits_<id>.json`) sur l'équipe
## du moment ; passable s'il a déjà été vu (drapeau `<id>_credits_seen`, posé à la fin).
func _play_named_credits(id: StringName) -> void:
	var credits := CreditsData.new()
	credits.load_file(CreditsData.NAMED_PATH % id)
	var entry := HallOfFame.snapshot(GameState.party.get_all(), GameState.player_name,
		GameState.starter_species, GameState.play_time, "")
	var seen := StringName("%s_credits_seen" % id)
	_credits_screen.skip_label = credits.skip_label
	await _credits_screen.present(credits.rows(entry, _hall_member_name),
		GameState.flags.has_flag(seen))
	_credits_screen.skip_label = _credits.skip_label
	GameState.flags.set_flag(seen)


## Vue de l'écran du Panthéon pour [param entry] : en-tête (joueur, date), et pour chaque Pokémon
## son artwork, sa ligne (T30-16) et, sous un surnom, le nom de l'espèce.
func _hall_view(entry: Dictionary) -> Dictionary:
	var pokemon := _boot.get_pokemon_data()
	var members: Array = []
	for member: Dictionary in entry.get("team", []):
		var species := pokemon.get_species(StringName(member.get("species", "")))
		var nickname: String = member.get("nickname", "")
		members.append({
			"texture": PokedexArt.portrait(species.dex) if species != null else null,
			"line": _credits.member_line(_hall_member_name(member), int(member.get("level", 1))),
			"subtitle": species.name if species != null and not nickname.is_empty() else "",
		})
	var header: String = entry.get("player", "")
	var day := hall_date(str(entry.get("date", "")))
	if not day.is_empty():
		header = "%s · %s" % [header, day] if not header.is_empty() else day
	return {"header": header, "members": members}


## Q30-4 : entrées du Panthéon, de la plus récente à la plus ancienne, sur l'écran du Panthéon.
func _browse_hall_of_fame() -> void:
	if _hall_screen.is_showing():
		return
	var views: Array = []
	var entries := GameState.hall_of_fame.entries()
	entries.reverse()
	for entry: Dictionary in entries:
		views.append(_hall_view(entry))
	await _hall_screen.browse(views)


## Surnom, sinon nom de l'espèce, d'un Pokémon d'une entrée du Panthéon.
func _hall_member_name(member: Dictionary) -> String:
	var nickname: String = member.get("nickname", "")
	if not nickname.is_empty():
		return nickname
	var species := _boot.get_pokemon_data().get_species(StringName(member.get("species", "")))
	return species.name if species != null else str(member.get("species", ""))


## Arrivée dans la salle du Champion ou au Panthéon pendant une cérémonie inachevée (reprise
## d'une sauvegarde) : la scène due repart, après l'arrivée (jamais par-dessus une scène).
func _on_league_map_entered(map: GameMap) -> void:
	if _league.pending_cutscene(map.map_id).is_empty():
		return
	_resume_league_ceremony.call_deferred(map.map_id)


func _resume_league_ceremony(map_id: StringName) -> void:
	var map := SceneRouter.get_current_map()
	var cutscenes := _boot.get_cutscene_director()
	if not is_instance_valid(map) or map.map_id != map_id or cutscenes.is_running():
		return
	var cutscene := _league.pending_cutscene(map_id)
	if not cutscene.is_empty():
		cutscenes.play(cutscene)
