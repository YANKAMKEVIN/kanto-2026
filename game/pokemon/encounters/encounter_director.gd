class_name EncounterDirector
extends Node
## Le seul à déclencher une rencontre sauvage (jalon 5 §3.6). À chaque pas terminé du joueur
## ([signal Player.moved]) dans une case de hautes herbes, il tente un tirage
## ([EncounterTable] + [member GameState.rng]) ; si une rencontre a lieu, il bloque le joueur
## [b]dans le `moved`[/b] (le pas suivant ne part pas, doigt maintenu ou en courant), marque
## le sauvage « vu » au Pokédex, joue le froissement d'herbe, puis lance la séquence de combat
## par le [BattleDirector] (`run_request`) et rend le contrôle à la fin. Sur une défaite
## ([constant Battle.Outcome.LOSS]), il attend le réveil au point de repos ([DefeatRecovery],
## jalon-07.md §3.3.2 : soin, dernier Centre utilisé sinon la maison, mot du lieu) avant de
## rendre le contrôle. Le directeur ne lit aucun autoload : il reçoit [GameState] et le routeur
## par [method setup].

## Une rencontre commence (joueur bloqué, transition lancée).
signal encounter_started(species_id: StringName, level: int)
## Une rencontre se termine (contrôle rendu). [param outcome] : [enum Battle.Outcome].
signal encounter_finished(outcome: int)
## Défaite : le joueur vient de se réveiller au point de repos, équipe soignée, juste avant le
## mot du lieu (relais de [signal DefeatRecovery.woke_up] pendant une rencontre ; décision de
## Kevin du 2026-10-02 : la défaite est un fait accompli). Boot écoute le [DefeatRecovery]
## lui-même ; ce relais sert aux tests et aux outils.
signal woke_up_after_defeat
## Point d'accroche du cri du sauvage (sans son au jalon 5, Q14) : émis à l'apparition.
signal cry_requested(species_id: StringName)

## Raison de blocage du joueur, de la rencontre jusqu'à la sortie du combat.
const REASON: StringName = &"encounter"
const _GRASS_TERRAIN: StringName = &"grass"

## Faux : aucun tirage (outils de capture, tests d'autres systèmes).
var enabled: bool = true

var _library: EncounterLibrary
var _data: PokemonData
var _state: Node
var _player: Player
var _battles: BattleDirector
var _router: Node
var _cutscenes: CutsceneDirector
var _recovery: DefeatRecovery
var _map: GameMap
var _running: bool = false
## Pas d'herbe consécutifs sans rencontre (tirés, donc hors gardes), remis à zéro à chaque
## rencontre. Alimente la montée du taux ([method EncounterTable.effective_rate]). Non
## sauvegardé : une partie chargée repart d'une série neuve (la table n'a que de la chance à
## offrir, aucune longue attente ne se perd). Gardé d'une carte à l'autre.
var _quiet_steps: int = 0


## Branche le directeur. [param state] : l'autoload GameState en jeu, une instance neuve de
## game_state.gd en test. [param router] : SceneRouter en jeu, une instance en test.
## [param recovery] : le réveil après une défaite (jalon-07.md §3.3.2) ; null (tests purs) :
## soin et retour au point de repos de l'état, tourné vers le haut, sans mot du lieu.
func setup(library: EncounterLibrary, data: PokemonData, state: Node, player: Player,
		battles: BattleDirector, router: Node, cutscenes: CutsceneDirector,
		recovery: DefeatRecovery = null) -> void:
	_library = library
	_data = data
	_state = state
	_player = player
	_battles = battles
	_router = router
	_cutscenes = cutscenes
	if _recovery != null and _recovery.woke_up.is_connected(_on_recovery_woke_up):
		_recovery.woke_up.disconnect(_on_recovery_woke_up)
	_recovery = recovery
	if _recovery != null:
		_recovery.woke_up.connect(_on_recovery_woke_up)
	if is_instance_valid(_player) and not _player.moved.is_connected(_on_player_moved):
		_player.moved.connect(_on_player_moved)


func set_map(map: GameMap) -> void:
	_map = map


func is_running() -> bool:
	return _running


## Pas d'herbe sans rencontre depuis la dernière rencontre (ou le démarrage).
func get_quiet_steps() -> int:
	return _quiet_steps


## Lance la rencontre [param encounter] sans tirage (scénario de capture, départ de débogage,
## tests). Faux si une rencontre ou un combat tourne déjà, ou sans carte.
func start_encounter(encounter: WildEncounter) -> bool:
	if encounter == null or _running or _map == null:
		return false
	if _battles != null and _battles.is_running():
		return false
	var cell := _player.get_cell() if is_instance_valid(_player) else Vector2i.ZERO
	_run(encounter, _origin_cell(cell))
	return true


# --- Déclenchement ------------------------------------------------------------------

func _on_player_moved(cell: Vector2i) -> void:
	if not _can_encounter(cell):
		return
	var table := _library.get_table(_map.map_id, _GRASS_TERRAIN)
	# Un seul tirage de taux par pas, au taux effectif de la série (§3.6, montée du taux).
	var encounter := table.roll(_state.rng as GameRng, _quiet_steps)
	if encounter == null:
		_quiet_steps += 1
		return
	# Verrou synchrone, dans le `moved` : le pas suivant ne part pas (comme les déclencheurs
	# du 3B). Le reste de la séquence est une coroutine lancée sans l'attendre.
	_run(encounter, _origin_cell(cell))


## Gardes : rien ne se passe hors herbe, sans table, pendant une scène / transition / combat /
## rencontre, sur un pas non libre (dialogue, scène scriptée), ni sans Pokémon valide.
func _can_encounter(cell: Vector2i) -> bool:
	if not enabled or _running or _map == null or _library == null or _state == null:
		return false
	if is_instance_valid(_player) and not _player.is_input_enabled():
		return false
	if _router != null and _router.has_method(&"is_transitioning") \
			and bool(_router.call(&"is_transitioning")):
		return false
	if _cutscenes != null and _cutscenes.is_running():
		return false
	if _battles != null and _battles.is_running():
		return false
	var party := _state.party as Party
	if party == null or not party.has_able():
		return false
	var grid := _map.get_grid()
	if grid == null or not grid.is_tall_grass(cell):
		return false
	return _library.has_table(_map.map_id, _GRASS_TERRAIN)


## Case de l'herbe qui bouge (§3.6) : celle devant le joueur si elle est en hautes herbes,
## sinon la sienne ([param cell], sa case d'arrivée).
func _origin_cell(cell: Vector2i) -> Vector2i:
	if not is_instance_valid(_player):
		return cell
	var front := cell + _player.get_facing()
	var grid := _map.get_grid() if _map != null else null
	if grid != null and grid.is_tall_grass(front):
		return front
	return cell


# --- Séquence -----------------------------------------------------------------------

## Coroutine : verrou, marquage Pokédex, froissement, transition, puis contrôle rendu. Le
## verrou est posé [b]avant tout `await`[/b] (synchrone dans le `moved`).
func _run(encounter: WildEncounter, origin: Vector2i) -> void:
	_running = true
	_quiet_steps = 0
	if is_instance_valid(_player):
		_player.set_input_enabled(false, REASON)
	if _state != null and _state.pokedex != null:
		# Pokédex daté (jalon 5 §16.3) : espèce vue sur cette carte, une observation de plus.
		_state.record_seen(encounter.species, _map.map_id)
	if _state != null:
		# Première espèce sauvage rencontrée en combat (jalon 7 §3.1) : celle que Chen cite.
		_state.record_wild_encounter(encounter.species, _map.map_id)
	encounter_started.emit(encounter.species, encounter.level)
	await _play_grass_beat(origin, encounter.species)
	# Les objets connus du combat : sans eux, aucune Ball n'est légale (jalon 5D).
	var items := _battles.get_item_library() if _battles != null else null
	var request := BattleRequest.wild(encounter, _data, _state.rng as GameRng, origin, items)
	var outcome := Battle.Outcome.NONE
	if _battles != null:
		outcome = await _battles.run_request(request, _map)
	if outcome == Battle.Outcome.LOSS:
		if _recovery != null:
			await _recovery.recover()
		else:
			await _handle_defeat()
	if is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	_running = false
	encounter_finished.emit(outcome)


## Défaite sans [DefeatRecovery] (tests purs) : soin, retour au point de repos de l'état, tourné
## vers le haut, sans mot du lieu. Le verrou du joueur est tenu tout du long (REASON) et rendu
## par l'appelant.
func _handle_defeat() -> void:
	if _state == null:
		return
	var party := _state.party as Party
	if party != null:
		party.heal_all()
	if _router != null and _router.has_method(&"change_map"):
		await _router.change_map(_state.heal_map, _state.heal_spawn, Vector2i.UP)
	woke_up_after_defeat.emit()


## Relais du réveil, seulement pendant une rencontre de ce directeur.
func _on_recovery_woke_up(_map_id: StringName) -> void:
	if _running:
		woke_up_after_defeat.emit()


## Le joueur se tourne vers l'herbe qui bouge, elle s'agite, le cri s'accroche (sans son).
func _play_grass_beat(origin: Vector2i, species: StringName) -> void:
	if is_instance_valid(_player):
		var toward := origin - _player.get_cell()
		var facing := Vector2i(signi(toward.x), 0) if toward.x != 0 \
			else Vector2i(0, signi(toward.y))
		if facing != Vector2i.ZERO:
			_player.face(facing)
	var speed := _battles.speed_scale if _battles != null else 1.0
	if _map != null and is_inside_tree():
		var rustle := GrassRustle.spawn(_map, Grid.cell_to_world(origin))
		cry_requested.emit(species)
		await rustle.rustle(speed)
	else:
		cry_requested.emit(species)
