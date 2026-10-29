class_name EncounterDirector
extends Node
## Le seul à déclencher une rencontre sauvage (jalon 5 §3.6). À chaque pas terminé du joueur
## ([signal Player.moved]) dans une case de hautes herbes ou de gravats (jalon 12, T20 : terrain
## « rubble » des grottes, table propre à la carte et au terrain), il tente un tirage
## ([EncounterTable] + [member GameState.rng]) ; si une rencontre a lieu, il bloque le joueur
## [b]dans le `moved`[/b] (le pas suivant ne part pas, doigt maintenu ou en courant), marque
## le sauvage « vu » au Pokédex, joue le froissement d'herbe, puis lance la séquence de combat
## par le [BattleDirector] (`run_request`) et rend le contrôle à la fin. Sur une défaite
## ([constant Battle.Outcome.LOSS]), il attend le réveil au point de repos ([DefeatRecovery],
## jalon-07.md §3.3.2 : soin, dernier Centre utilisé sinon la maison, mot du lieu) avant de
## rendre le contrôle. Le directeur ne lit aucun autoload : il reçoit [GameState] et le routeur
## par [method setup].
## Jalon 12 (T20, `jalon-12.md` §2.5) : le terrain de la case ([method terrain_at]) choisit la
## table et l'introduction — herbes : l'herbe s'agite ([GrassRustle]) ; gravats : un petit
## éboulis sous les pieds ([RubbleBurst]), le point d'accroche du son
## ([signal rubble_sound_requested]), puis le héros se retourne. Le sol calme d'une grotte
## n'a aucune rencontre. Un seul compteur de pas calmes pour les deux terrains. Le compagnon
## ne déclenche rien : seul le pas du joueur est écouté.
## Jalon 19 (`jalon-19.md` §2.2, dossier 22 §5 et §6) : terrain « floor » (sol de la Tour) sur
## toute case praticable d'une carte qui a une table « floor », sauf les cases calmes
## ([member GameMap.calm_cells]), les warps et les déclencheurs ; aucune introduction (le fondu
## du combat suffit). Combat SPECTRE : [method GhostRule.is_ghost] relu à [b]chaque[/b]
## rencontre avec le Sac du moment ([member EncounterTable.ghost_unless_item]) ; alors ni
## « vu », ni première espèce sauvage, ni cri, et [signal encounter_started] porte la
## pseudo-espèce masquée.
## J23 (`jalon-23.md` §2.3, §2.4) : sur une carte du Parc Safari ([method SafariConfig.is_safari_map])
## avec une visite active ([member GameState.safari]), toute rencontre (herbe, pêche par
## [method start_encounter]) est une **rencontre Safari** ([method BattleRequest.safari]) ; sans
## visite active (cas anormal), aucune rencontre : rien n'est tiré au pas et
## [method start_encounter] refuse. [signal encounter_finished] est émis comme d'habitude : la
## fin de visite par la dernière Ball est relevée par l'écouteur ([member SafariVisit.active]).

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
## Point d'accroche du son « pierres qui roulent » (jalon 12, dossier 15 §6 ; aucun son au J12) :
## émis au début de l'éboulis d'une rencontre sur les gravats.
signal rubble_sound_requested
## Lot 32P : la Repousse vient de s'épuiser sur ce pas (Boot dit « L'effet de la Repousse s'est
## dissipé. » une fois le joueur libre).
signal repel_wore_off

## Raison de blocage du joueur, de la rencontre jusqu'à la sortie du combat.
const REASON: StringName = &"encounter"
const _GRASS_TERRAIN: StringName = &"grass"
## Gravats des grottes (jalon 12, T20).
const _RUBBLE_TERRAIN: StringName = &"rubble"
## Sol de la Tour Pokémon (jalon 19).
const _FLOOR_TERRAIN: StringName = &"floor"
## Eau surfable (S2C) : le joueur à pied ne s'y tient jamais, la case suffit.
const _WATER_TERRAIN: StringName = &"water"
## Pêche (S2C-bis, [FishingDirector]) : jamais tiré au pas, seulement par [method start_encounter].
const WATER_ROD_TERRAIN: StringName = &"water_rod"

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
## J23 : réglages du Parc Safari (cartes, bonus de la Safari Ball), lus au premier besoin dans
## `data/safari/safari.json` ; [method set_safari_config] pour les tests.
var _safari_config: SafariConfig


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


## J23 : réglages du Parc Safari à utiliser (tests ; null : relus dans les données).
func set_safari_config(config: SafariConfig) -> void:
	_safari_config = config


## J23 : réglages du Parc Safari (lus au premier besoin).
func get_safari_config() -> SafariConfig:
	if _safari_config == null:
		_safari_config = SafariConfig.load_default()
	return _safari_config


## J23 : vrai si la carte courante est une carte du Parc Safari.
func is_safari_map() -> bool:
	return _map != null and get_safari_config().is_safari_map(_map.map_id)


## J23 : visite du Parc en cours (null si aucune ou inactive).
func _active_safari_visit() -> SafariVisit:
	var visit: SafariVisit = _state.get(&"safari") as SafariVisit if _state != null else null
	return visit if visit != null and visit.active else null


func set_map(map: GameMap) -> void:
	_map = map


func is_running() -> bool:
	return _running


## Pas d'herbe sans rencontre depuis la dernière rencontre (ou le démarrage).
func get_quiet_steps() -> int:
	return _quiet_steps


## Terrain de rencontre de [param cell] sur la carte courante (jalon 12, T20) : &"grass" (hautes
## herbes), &"rubble" (gravats), &"floor" (sol de la Tour, jalon 19 : carte avec une table
## « floor », case praticable hors cases calmes, warps et déclencheurs), &"water" (S2C : eau
## surfable, le joueur y est en Surf), &"" (aucun : sol calme, chemin, hors carte, sans carte).
func terrain_at(cell: Vector2i) -> StringName:
	var grid := _map.get_grid() if _map != null else null
	if grid == null:
		return &""
	if grid.is_tall_grass(cell):
		return _GRASS_TERRAIN
	if grid.is_rubble(cell):
		return _RUBBLE_TERRAIN
	if _is_floor(grid, cell):
		return _FLOOR_TERRAIN
	if grid.is_surfable(cell):
		return _WATER_TERRAIN
	return &""


## Lance la rencontre [param encounter] sans tirage (scénario de capture, départ de débogage,
## tests). Faux si une rencontre ou un combat tourne déjà, ou sans carte. [param terrain] :
## terrain imposé (&"" : celui de la case du joueur) ; [constant WATER_ROD_TERRAIN] (pêche,
## S2C-bis) : aucune introduction (ni herbe, ni éboulis), la touche a déjà été jouée.
func start_encounter(encounter: WildEncounter, terrain: StringName = &"") -> bool:
	if encounter == null or _running or _map == null:
		return false
	if _battles != null and _battles.is_running():
		return false
	# J23 : dans le Parc, pas de rencontre sans visite active.
	if is_safari_map() and _active_safari_visit() == null:
		return false
	var cell := _player.get_cell() if is_instance_valid(_player) else Vector2i.ZERO
	if terrain.is_empty():
		terrain = terrain_at(cell)
	# Même calcul qu'un tirage (jalon 19) : la table d'origine, sinon celle de la case. Un
	# SPECTRE déjà demandé par l'appelant le reste.
	var table := _library.get_table_by_id(encounter.table_id) \
		if _library != null and not encounter.table_id.is_empty() else null
	if table == null and _library != null:
		table = _library.get_table(_map.map_id, terrain)
	encounter.ghost = encounter.ghost or _is_ghost(table)
	_run(encounter, _origin_cell(cell), terrain)
	return true


# --- Déclenchement ------------------------------------------------------------------

func _on_player_moved(cell: Vector2i) -> void:
	var repel_active := _tick_repel()
	if not _can_encounter(cell):
		return
	var terrain := terrain_at(cell)
	var table := _library.get_table(_map.map_id, terrain)
	# Un seul tirage de taux par pas, au taux effectif de la série (§3.6, montée du taux).
	var encounter := table.roll(_state.rng as GameRng, _quiet_steps)
	if encounter == null:
		_quiet_steps += 1
		return
	# Lot 32P : la Repousse écarte un sauvage plus faible que le premier Pokémon debout.
	if repel_active and RepelRules.blocks(1, encounter.level, _state.party as Party):
		return
	# Combat SPECTRE (jalon 19) : relu à chaque rencontre, avec le Sac du moment.
	encounter.ghost = _is_ghost(table)
	# Verrou synchrone, dans le `moved` : le pas suivant ne part pas (comme les déclencheurs
	# du 3B). Le reste de la séquence est une coroutine lancée sans l'attendre.
	_run(encounter, _origin_cell(cell), terrain)


## Lot 32P : un pas libre décompte la Repousse en cours ([member GameState.repel_steps]) ; vrai si
## elle agissait sur ce pas (le dernier compris, où [signal repel_wore_off] part).
func _tick_repel() -> bool:
	var steps: Variant = _state.get(&"repel_steps") if _state != null else null
	if not steps is int or int(steps) <= 0:
		return false
	if is_instance_valid(_player) and not _player.is_input_enabled():
		return true
	_state.set(&"repel_steps", RepelRules.tick(int(steps)))
	if int(steps) == 1:
		repel_wore_off.emit()
	return true


## Gardes : rien ne se passe hors herbe ou gravats, sans table du terrain, pendant une scène /
## transition / combat / rencontre, sur un pas non libre (dialogue, scène scriptée), ni sans
## Pokémon valide.
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
	var terrain := terrain_at(cell)
	if terrain.is_empty():
		return false
	# J23 : dans le Parc, pas de rencontre sans visite active.
	if is_safari_map() and _active_safari_visit() == null:
		return false
	return _library.has_table(_map.map_id, terrain)


## Case de l'herbe qui bouge (§3.6) : celle devant le joueur si elle est en hautes herbes,
## sinon la sienne ([param cell], sa case d'arrivée). Gravats (jalon 12) : toujours la sienne
## (l'éboulis part sous ses pieds).
func _origin_cell(cell: Vector2i) -> Vector2i:
	if not is_instance_valid(_player) or terrain_at(cell) == _RUBBLE_TERRAIN:
		return cell
	var front := cell + _player.get_facing()
	var grid := _map.get_grid() if _map != null else null
	if grid != null and grid.is_tall_grass(front):
		return front
	return cell


# --- Séquence -----------------------------------------------------------------------

## Coroutine : verrou, marquage Pokédex, froissement, transition, puis contrôle rendu. Le
## verrou est posé [b]avant tout `await`[/b] (synchrone dans le `moved`).
func _run(encounter: WildEncounter, origin: Vector2i,
		terrain: StringName = _GRASS_TERRAIN) -> void:
	_running = true
	_quiet_steps = 0
	if is_instance_valid(_player):
		_player.set_input_enabled(false, REASON)
	# SPECTRE (jalon 19, K-9) : rien n'est enregistré, rien n'est nommé, aucun cri.
	var ghost := encounter.ghost
	if _state != null and _state.pokedex != null and not ghost:
		# Pokédex daté (jalon 5 §16.3) : espèce vue sur cette carte, une observation de plus.
		_state.record_seen(encounter.species, _map.map_id)
	if _state != null and not ghost:
		# Première espèce sauvage rencontrée en combat (jalon 7 §3.1) : celle que Chen cite.
		_state.record_wild_encounter(encounter.species, _map.map_id)
	if ghost:
		encounter_started.emit(GhostDisguise.SPECIES, GhostDisguise.HIDDEN_LEVEL)
	else:
		encounter_started.emit(encounter.species, encounter.level)
	if terrain == _RUBBLE_TERRAIN:
		await _play_rubble_beat(origin, encounter.species, ghost)
	elif terrain != _FLOOR_TERRAIN and terrain != _WATER_TERRAIN \
			and terrain != WATER_ROD_TERRAIN:
		await _play_grass_beat(origin, encounter.species, ghost)
	# Les objets connus du combat : sans eux, aucune Ball n'est légale (jalon 5D).
	var items := _battles.get_item_library() if _battles != null else null
	# J23 : rencontre Safari (visite vérifiée avant le verrou par les gardes).
	var visit := _active_safari_visit() if is_safari_map() else null
	var request := BattleRequest.safari(encounter, _data, _state.rng as GameRng, origin, visit,
		get_safari_config().ball_bonus) if visit != null \
		else BattleRequest.wild(encounter, _data, _state.rng as GameRng, origin, items)
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
func _play_grass_beat(origin: Vector2i, species: StringName, ghost: bool = false) -> void:
	if is_instance_valid(_player):
		var toward := origin - _player.get_cell()
		var facing := Vector2i(signi(toward.x), 0) if toward.x != 0 \
			else Vector2i(0, signi(toward.y))
		if facing != Vector2i.ZERO:
			_player.face(facing)
	var speed := _battles.speed_scale if _battles != null else 1.0
	if _map != null and is_inside_tree():
		var rustle := GrassRustle.spawn(_map, Grid.cell_to_world(origin))
		if not ghost:
			cry_requested.emit(species)
		await rustle.rustle(speed)
	elif not ghost:
		cry_requested.emit(species)


## Gravats (jalon 12, T20 ; dossier 15 §6, ≤ 2 s) : petit éboulis sous les pieds (cailloux qui
## roulent, poussière), point d'accroche du son, puis le héros se retourne (demi-tour) ; le combat
## suit. Pas d'herbe agitée.
func _play_rubble_beat(origin: Vector2i, species: StringName, ghost: bool = false) -> void:
	var speed := _battles.speed_scale if _battles != null else 1.0
	rubble_sound_requested.emit()
	if not ghost:
		cry_requested.emit(species)
	if _map != null and is_inside_tree():
		var burst := RubbleBurst.spawn(_map, Grid.cell_to_world(origin))
		await burst.burst(speed)
	if is_instance_valid(_player):
		_player.face(-_player.get_facing())


# --- Jalon 19 : sol de la Tour et SPECTRE -------------------------------------------------

## Case de sol « floor » de la carte courante : une table « floor » existe pour la carte, la case
## est dans la carte et praticable, ni calme ([member GameMap.calm_cells]), ni sur un warp, ni
## sur un déclencheur (un pas sur un escalier, la case du rival ou celle du SPECTRE ne tire
## jamais de rencontre, quel que soit l'ordre des écouteurs de `moved`).
func _is_floor(grid: GridWorld, cell: Vector2i) -> bool:
	if _library == null or not _library.has_table(_map.map_id, _FLOOR_TERRAIN):
		return false
	if not grid.is_in_bounds(cell) or grid.is_solid(cell) or grid.is_water(cell):
		return false
	if _map.calm_cells.has(cell):
		return false
	if not _map.get_warps().get_at(cell).is_empty():
		return false
	return _map.get_triggers().get_at(cell).is_empty()


## Combat SPECTRE pour une rencontre de [param table] : [method GhostRule.is_ghost] avec le Sac
## du moment (aucun cache). Faux sans table.
func _is_ghost(table: EncounterTable) -> bool:
	if table == null:
		return false
	var bag: Bag = _state.bag as Bag if _state != null else null
	return GhostRule.is_ghost(table.ghost_unless_item, bag)
