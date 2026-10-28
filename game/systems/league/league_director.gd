class_name LeagueDirector
extends Node
## Tentative de Ligue dans la partie (jalon 30 T8, `docs/tech/jalon-30.md` §2.2, §2.3) : applique
## [LeagueAttempt] (pur) aux événements du jeu, sur le modèle des autres directeurs de [Boot]
## (bloc `_setup_league()`).
##
## - **Entrée** : arrivée dans la salle d'Olga ([constant LeagueAttempt.ROOMS] [0]) hors
##   tentative → [method LeagueAttempt.start] (drapeaux de la tentative), les Dresseurs de la
##   Ligue redeviennent « à battre » (`beaten_<id>` effacés) et le point de repos devient le
##   Plateau ([constant REST_MAP], [D] §8).
## - **Victoire** contre le membre de l'étape courante → `league_stage_<k>_cleared` (la porte nord
##   de la salle, une [FlagGate], s'ouvre par le relais des drapeaux de Boot).
## - **Défaite** (n'importe quelle salle) → drapeaux de tentative et `beaten_<id>` de la Ligue
##   effacés **avant** l'étape « wake_up » de la scène d'appel (réveil soigné au point de repos,
##   sauvegarde écrite au réveil par Boot) : tout est à refaire depuis Olga.
## - **Portes** : rien à faire ici. Porte nord = [FlagGate] bloquante `unless
##   league_stage_<k>_cleared` ; porte sud = warp `unless league_attempt_active` + [FlagGate]
##   bloquante `if league_attempt_active` (outil `tools/build_j30_league.gd`).
## - **Reprise** : les drapeaux sont ordinaires (sauvegardés) ; recharger dans une salle pendant
##   la tentative la reprend telle quelle ([method LeagueAttempt.start] ne remet rien à zéro).
## - **Cérémonie** (T15 à T17, §2.3, §2.4) : la victoire contre le Champion pose
##   `league_stage_4_cleared` ; la scène d'appel du rival enchaîne `league_victory` (Chen, passage
##   au Panthéon), dont l'étape « hall_of_fame » appelle [method complete_ceremony] (titre, entrée
##   du Panthéon, fin de la tentative) juste avant **une seule écriture** de la partie ; puis le
##   générique et l'arrivée à Bourg Palette. Reprise : [method pending_cutscene] relance la scène
##   due à l'arrivée dans la salle du Champion ou au Panthéon (jamais deux entrées : la cérémonie
##   n'ajoute rien une fois `league_champion_defeated` posé et la tentative effacée).
##
## Écart tant que le J29 n'est pas fusionné : le hall `indigo_plateau_lobby` (et son point de
## repos `heal`) n'existe pas encore ; le point de repos n'est alors pas changé (celui de la
## partie reste, [member has_map]).

## Une tentative commence (entrée dans la salle d'Olga).
signal attempt_started
## Le membre de l'étape [param stage] est battu dans cette tentative.
signal stage_cleared(stage: int)
## Défaite pendant la tentative : drapeaux effacés (le réveil suit).
signal attempt_lost
## Cérémonie faite : titre posé, entrée [param entry] ajoutée au Panthéon (avant l'écriture).
signal champion_crowned(entry: Dictionary)

## Scènes de la cérémonie (`data/cutscenes/league.json`) : salle du Champion (Chen, passage au
## Panthéon) et Panthéon seul (reprise après un arrêt : écran, générique, Bourg Palette).
const VICTORY_CUTSCENE: StringName = &"league_victory"
const HALL_CUTSCENE: StringName = &"league_hall_of_fame"
const CHAMPION_ROOM: StringName = &"league_champion"
const HALL_ROOM: StringName = &"hall_of_fame"

## Point de repos de la Ligue : le Centre du hall du Plateau (J29, `data/world/rest_points.json`).
const REST_MAP: StringName = &"indigo_plateau_lobby"
const REST_SPAWN: StringName = &"heal"

## Vrai si la carte existe ; remplaçable en test. Défaut : [method MapCatalog.has_map].
var has_map: Callable = func(map_id: StringName) -> bool: return MapCatalog.has_map(map_id)

## Jalon 32 (N-17, N-18) : rencontres fixes du jeu, pour [StaticRespawn] à chaque victoire (Boot
## y met [method CutsceneLibrary.get_static_encounters] ; vide en test sauf réglage).
var static_encounters: Array[StaticEncounter] = []

## GameState (ou une instance de game_state.gd en test) : drapeaux et point de repos.
var _state: Node
var _map: GameMap


func setup(state: Node) -> void:
	_state = state


## Drapeaux « battu » des cinq Dresseurs de la Ligue (effacés à chaque entrée et défaite).
static func beaten_flags() -> Array[StringName]:
	var result: Array[StringName] = []
	for trainer_id: StringName in LeagueAttempt.TRAINERS:
		result.append(TrainerRules.beaten_flag(trainer_id))
	return result


## Vrai pour une salle de la Ligue (les cinq salles de combat et le Panthéon).
static func is_league_map(map_id: StringName) -> bool:
	return LeagueAttempt.stage_of_room(map_id) != LeagueAttempt.NO_STAGE \
		or map_id == &"hall_of_fame"


## Relais de [signal SceneRouter.map_changed] (branché avant celui de Boot : les drapeaux sont à
## jour avant la présence des PNJ). Entrée dans la salle d'Olga hors tentative → nouvelle
## tentative ; toute salle pendant la tentative → point de repos du Plateau (départs de débogage).
func on_map_changed(map: GameMap) -> void:
	_map = map
	var flags := _flags()
	if not is_instance_valid(map) or flags == null or not is_league_map(map.map_id):
		return
	if map.map_id == LeagueAttempt.ROOMS[0] and not LeagueAttempt.is_active(flags):
		start_attempt()
	elif LeagueAttempt.is_active(flags):
		_set_rest_point()


## Nouvelle tentative (porte du hall franchie). Faux si une tentative est déjà en cours.
func start_attempt() -> bool:
	var flags := _flags()
	if flags == null or not LeagueAttempt.start(flags):
		return false
	_clear_beaten(flags)
	_set_rest_point()
	attempt_started.emit()
	return true


## Relais de [signal BattleDirector.battle_finished] : victoire ou défaite contre un membre.
func on_battle_finished(trainer_id: StringName, outcome: int) -> void:
	var flags := _flags()
	var stage := LeagueAttempt.stage_of_trainer(trainer_id)
	if flags == null or stage == LeagueAttempt.NO_STAGE:
		return
	if outcome == Battle.Outcome.WIN:
		if LeagueAttempt.record_victory(flags, stage):
			stage_cleared.emit(stage)
			# Chen chez le Champion (`if league_stage_4_cleared`) paraît sans recharger la salle.
			if is_instance_valid(_map) and _map.is_inside_tree():
				_map.refresh_npcs(flags)
	elif outcome == Battle.Outcome.LOSS:
		var was_active := LeagueAttempt.record_defeat(flags)
		_clear_beaten(flags)
		if was_active:
			attempt_lost.emit()


## Vrai si les cinq combats de la tentative sont gagnés et que la cérémonie n'est pas faite.
func ceremony_due() -> bool:
	var flags := _flags()
	return flags != null and LeagueAttempt.current_stage(flags) == LeagueAttempt.STAGE_DONE


## Scène de cérémonie à relancer à l'arrivée sur [param map_id] (reprise d'une sauvegarde écrite
## entre la victoire et la fin du générique), &"" sinon :
## - salle du Champion, cérémonie due → [constant VICTORY_CUTSCENE] ;
## - Panthéon, cérémonie due ou titre déjà posé → [constant HALL_CUTSCENE] (le Panthéon n'a pas
##   de porte : la scène est sa seule sortie, vers Bourg Palette).
func pending_cutscene(map_id: StringName) -> StringName:
	var flags := _flags()
	if flags == null:
		return &""
	if map_id == CHAMPION_ROOM and ceremony_due():
		return VICTORY_CUTSCENE
	if map_id == HALL_ROOM and (ceremony_due() or LeagueAttempt.is_champion(flags)):
		return HALL_CUTSCENE
	return &""


## Fin de la cérémonie (étape « hall_of_fame », après l'écran du Panthéon) : titre de Champion
## ([method LeagueAttempt.complete] : `league_champion_defeated`, tentative effacée) et
## [param entry] ajoutée au Panthéon ([HallOfFame], instantané de [method HallOfFame.snapshot]).
## Faux si la cérémonie n'était pas due (déjà faite : rien ne change, aucune entrée de plus).
## L'appelant écrit la partie juste après (une seule écriture).
func complete_ceremony(entry: Dictionary) -> bool:
	var flags := _flags()
	var first_title := flags != null and not LeagueAttempt.is_champion(flags)
	if flags == null or not LeagueAttempt.complete(flags):
		return false
	# Grand moment « champion » (§0.1 [D]) : la première victoire seulement (la frise ne se répète
	# pas ; chaque victoire a son entrée au Panthéon).
	if first_title and _state.has_method(&"record_moment"):
		_state.call(&"record_moment", MomentLibrary.CHAMPION,
			_map.map_id if is_instance_valid(_map) else HALL_ROOM)
	var hall: HallOfFame = _state.get(&"hall_of_fame") as HallOfFame
	if hall != null:
		var added := hall.add(entry)
		if added != HallOfFame.AddResult.ADDED:
			push_warning("LeagueDirector : entrée du Panthéon non ajoutée (%s)"
				% HallOfFame.AddResult.keys()[added])
	# Jalon 32 (N-17, N-18 ; RP-155) : les Pokémon uniques mis K.O. reviennent, et le Ronflex
	# d'après la Ligue apparaît si les deux des routes sont perdus ; avant l'écriture du Panthéon.
	StaticRespawn.on_league_won(static_encounters, flags)
	champion_crowned.emit(entry)
	return true


func _set_rest_point() -> void:
	if _state == null or not has_map.call(REST_MAP):
		return
	_state.heal_map = REST_MAP
	_state.heal_spawn = REST_SPAWN


func _clear_beaten(flags: StoryFlags) -> void:
	for flag: StringName in beaten_flags():
		flags.set_flag(flag, false)


func _flags() -> StoryFlags:
	return _state.get(&"flags") as StoryFlags if _state != null else null
