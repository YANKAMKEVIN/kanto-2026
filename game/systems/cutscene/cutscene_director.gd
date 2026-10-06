class_name CutsceneDirector
extends Node
## Directeur de scènes : le **seul** à jouer une scène scriptée (docs/tech/jalon-03b.md §2.4).
##
## Il ne décide rien : il écoute les pas terminés du joueur ([signal Player.moved]), cherche
## un déclencheur dans la [TriggerTable] de la carte courante, choisit la variante de la
## scène pour les drapeaux ([method Cutscene.pick]) et joue ses étapes dans l'ordre, en
## appelant les nœuds existants ([DialogueRunner], [Player], [Npc]). Le joueur est bloqué
## pour la raison [constant REASON] dès [method play] (de façon synchrone : appelé depuis
## le pas terminé, le verrou empêche le pas qui s'enchaînerait), puis libéré à la fin.
## Il reçoit ses dépendances par [method setup] : il ne lit aucun autoload.
##
## Étapes jouées : wait, dialogue, face, set (T2), spawn et move (T3 : chemin écrit, case
## absolue ou case voisine d'un acteur, marche ou course), suiveur d'une étape move et
## change_map (T4).
## Jalon 4 (jalon-04.md §3.6, §13.9) : alias d'acteurs ([method play] avec un dictionnaire
## « nom → identifiant de PNJ »), résolus au début de **chaque** étape (acteur, cible,
## voisin, suiveur) ; étapes hop (attend la fin du saut), lean (s'avance puis revient) et
## despawn (fondu de [constant DESPAWN_FADE] s, case libérée). Alias absent, acteur
## introuvable ou saut refusé : push_error, étape sautée.
## Jalon 4B (jalon-04.md §14.3) : étape battle (combat contre un dresseur, verrou gardé, issue
## → drapeaux), étape give (objets au Sac + [signal item_given]) ; conditions d'étape
## « if » / « unless » ([method CutsceneStep.applies]) pour les suites selon l'issue.
## Jalon 7 (jalon-07.md §3.2) : étape scare (réaction d'un Pokémon d'ambiance, sans attendre).
## Jalon 7 (jalon-07.md §3.8, T25) : étape wake_up (défaite contre un Dresseur : réveil au point
## de repos par le [DefeatRecovery] branché par [method set_recovery], puis fin de la scène).
## Retours T5 (jalon-07.md §15.21) : « move » en arrière-plan ([member CutsceneStep.background] :
## le PNJ marche pendant que la scène continue ; une étape suivante sur lui attend la fin de
## sa marche ; la scène ne finit qu'à la fin de toutes) et étape « react » (petite surprise du
## joueur ou d'un PNJ, sans attendre).

signal cutscene_started(cutscene_id: StringName)
## Début d'une étape (tests, outils de capture).
signal step_started(index: int)
signal cutscene_finished(cutscene_id: StringName)
## [param count] objets [param item_id] viennent d'être ajoutés au Sac (étape « give ») :
## Boot en fait une toast (jalon-04.md §14.6).
signal item_given(item_id: StringName, count: int)
## L'objet que l'étape « give » vient de donner a été **trouvé dans le monde** (clé « found »
## de l'étape, jalon 5C.5) : Boot l'inscrit au journal des objets trouvés. Émis après
## [signal item_given].
signal item_found(item_id: StringName, count: int)
## Fin d'une étape « wait » (interne).
signal _wait_elapsed
## Fin d'une étape « move » (interne).
signal _move_done

## Raison de blocage du joueur pendant une scène ([method Player.set_input_enabled]).
const REASON: StringName = &"cutscene"
## Un pas bloqué (case occupée) est retenté à chaque image ; au-delà, l'étape est abandonnée
## (étape « move »).
const MOVE_BLOCK_TIMEOUT: float = 2.0
## Étape « lean » : temps passé penché vers la cible avant de revenir (s).
const LEAN_HOLD: float = 0.3
## Étape « despawn » : fondu du PNJ avant son retrait (s) ; sa case est libérée dès le début.
const DESPAWN_FADE: float = 0.2
const _ROUTER_SCRIPT := preload("res://game/autoload/scene_router.gd")
## Étapes qui agissent sur leur acteur : elles attendent d'abord la fin de sa marche en
## arrière-plan.
const _JOINING_KINDS: Array[CutsceneStep.Kind] = [
	CutsceneStep.Kind.MOVE, CutsceneStep.Kind.HOP, CutsceneStep.Kind.LEAN,
	CutsceneStep.Kind.DESPAWN, CutsceneStep.Kind.SCARE, CutsceneStep.Kind.REACT,
]

var _library: CutsceneLibrary
var _flags: StoryFlags
var _runner: DialogueRunner
var _player: Player
var _router: _ROUTER_SCRIPT
var _map: GameMap
var _running: bool = false
var _cutscene_id: StringName = &""
var _step_index: int = -1
## Alias de la scène en cours (nom sans « $ » → identifiant de PNJ).
var _aliases: Dictionary[StringName, StringName] = {}
## Incrémenté à chaque setup() : une scène lancée avant est abandonnée à sa reprise.
var _session: int = 0
var _waiting: bool = false
var _wait_left: float = 0.0
## Image du début de l'attente : elle ne compte pas (sinon l'attente finirait une image tôt).
var _wait_frame: int = -1
## Étape « move » en cours : acteur, directions, prochain pas, course, temps bloqué.
var _moving: bool = false
var _move_actor: Node2D
var _move_path: Array[Vector2i] = []
var _move_index: int = 0
var _move_run: bool = false
## Le joueur recule sans se retourner (étape « move » avec « keep_facing »).
var _move_keep_facing: bool = false
var _move_blocked: float = 0.0
## Suiveur de l'étape « move » (null sans suiveur) : ses directions et son prochain pas.
## Il marche au pas du meneur, jamais devant lui, jamais plus d'un pas derrière.
var _follow_actor: Node2D
var _follow_path: Array[Vector2i] = []
var _follow_index: int = 0
## Marches en arrière-plan (« move » avec « background ») : { actor, path, index, run,
## blocked }, pilotées dans [method _process], dans l'ordre où elles ont commencé (un meneur
## parti avant libère sa case dans la même image pour celui qui le suit).
var _background: Array[Dictionary] = []
## Combat et Sac (jalon 4B) : branchés par Boot après setup.
var _battle_runner: BattleDirector
var _bag: Bag
var _items: ItemLibrary
## HUD d'exploration (jalon 7, étape « caption ») : branchée par Boot après setup.
var _hud: ExplorationHud
## Réveil après une défaite (jalon 7, étape « wake_up ») : branché par Boot après setup.
var _recovery: DefeatRecovery


func _ready() -> void:
	# Après la carte et ses PNJ (enfants de World, avant le directeur dans Boot) : un pas
	# terminé dans l'image est enchaîné dans la même image.
	process_priority = 10
	set_process(_running)


func _process(delta: float) -> void:
	if not _background.is_empty():
		_update_background(delta)
	if _moving:
		_update_move(delta)
		return
	if not _waiting or Engine.get_process_frames() == _wait_frame:
		return
	_wait_left -= delta
	if _wait_left <= 0.0:
		_waiting = false
		_wait_elapsed.emit()


## Branche le directeur. [param router] : l'autoload SceneRouter en jeu, une instance de
## scene_router.gd en test (même API : change_map, get_current_map, is_transitioning).
## Peut être rappelé : une scène en cours est abandonnée, l'ancien joueur débranché.
func setup(library: CutsceneLibrary, flags: StoryFlags, runner: DialogueRunner,
		player: Player, router: Node) -> void:
	_disconnect_player()
	_session += 1
	if _running and is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	_running = false
	_waiting = false
	_stop_move()
	_background.clear()
	_cutscene_id = &""
	_step_index = -1
	_library = library
	_flags = flags
	_runner = runner
	_player = player
	_router = router as _ROUTER_SCRIPT
	if _player != null:
		_player.moved.connect(_on_player_moved)
	set_process(false)


## Carte courante (relais de Boot sur SceneRouter.map_changed).
func set_map(map: GameMap) -> void:
	_map = map


## Branche le directeur de combat (jalon 4B) : l'étape « battle » l'appelle. Sans lui, une
## étape « battle » est sautée (push_error).
func set_battle_runner(runner: BattleDirector) -> void:
	_battle_runner = runner


## Branche le Sac et les objets (jalon 4B) : l'étape « give » y ajoute des objets. Sans eux,
## une étape « give » est sautée (push_error).
func set_inventory(bag: Bag, items: ItemLibrary) -> void:
	_bag = bag
	_items = items


## Branche la HUD d'exploration (jalon-07.md §3.6, T18) : l'étape « caption » y pose sa
## légende ([method ExplorationHud.show_caption]) et attend [signal ExplorationHud.caption_hidden].
## Sans elle, une étape « caption » est sautée (push_error). L'étape « take » (le colis remis à
## Chen) passe par le Sac de [method set_inventory].
func set_hud(hud: ExplorationHud) -> void:
	_hud = hud


## Branche le réveil après une défaite (jalon-07.md §3.8, T25) : l'étape « wake_up » appelle
## [method DefeatRecovery.recover]. Sans lui, une étape « wake_up » est sautée (push_error) et
## la scène s'arrête quand même.
func set_recovery(recovery: DefeatRecovery) -> void:
	_recovery = recovery


## Joue [param cutscene_id]. Faux (et rien ne se passe) si une scène tourne, si
## l'identifiant est inconnu (push_error) ou si aucune variante ne s'applique (sans erreur :
## déclencheur désarmé). [param aliases] : « nom sans $ » → identifiant de PNJ de la carte
## (ex. { &"player_starter": &"charmander" }), résolus au début de chaque étape.
func play(cutscene_id: StringName, aliases: Dictionary[StringName, StringName] = {}) -> bool:
	if _running:
		return false
	var cutscene := _library.get_cutscene(cutscene_id) if _library != null else null
	if cutscene == null:
		push_error("CutsceneDirector : scène inconnue « %s »" % cutscene_id)
		return false
	var variant := cutscene.pick(_flags)
	if variant == null:
		if OS.is_debug_build():
			print("[qa] scène « %s » ignorée (aucune variante pour les drapeaux)" % cutscene_id)
		return false
	if OS.is_debug_build():
		print("[qa] scène « %s » jouée" % cutscene_id)
	_running = true
	_cutscene_id = cutscene_id
	_step_index = -1
	_aliases = aliases.duplicate()
	if is_instance_valid(_player):
		_player.set_input_enabled(false, REASON)
	cutscene_started.emit(cutscene_id)
	set_process(true)
	_run(variant, _session)
	return true


func is_running() -> bool:
	return _running


## Étape en cours (−1 hors scène).
func get_step_index() -> int:
	return _step_index


## Identifiant de la scène en cours (&"" hors scène).
func get_cutscene_id() -> StringName:
	return _cutscene_id


func _run(variant: CutsceneVariant, session: int) -> void:
	for i: int in variant.steps.size():
		_step_index = i
		step_started.emit(i)
		var go_on: bool = await _play_step(variant.steps[i])
		if session != _session:
			return
		if not go_on:
			break
	# Les marches en arrière-plan finissent avant la scène (contrôles rendus ensuite).
	while not _background.is_empty():
		await get_tree().process_frame
		if session != _session:
			return
	_finish()


## Joue une étape. Faux : la scène s'arrête (changement de carte manqué, T4 ; réveil après
## une défaite, étape « wake_up »).
## Une étape dont les conditions (« if » / « unless », jalon 4B) ne sont pas remplies est
## sautée sans erreur. Les alias sont résolus d'abord ; un alias absent saute l'étape
## (push_error).
func _play_step(source_step: CutsceneStep) -> bool:
	if not source_step.applies(_flags):
		return true
	var step := _resolve_aliases(source_step)
	if step == null:
		return true
	if _JOINING_KINDS.has(step.kind):
		await _await_background(step.actor)
	match step.kind:
		CutsceneStep.Kind.WAIT:
			await _wait(step.seconds)
		CutsceneStep.Kind.DIALOGUE:
			await _play_dialogue(step.dialogue_id)
		CutsceneStep.Kind.FACE:
			_face(step.actor, step.target)
		CutsceneStep.Kind.SET_FLAGS:
			if _flags != null:
				for flag: StringName in step.flags:
					_flags.set_flag(flag)
		CutsceneStep.Kind.CAPTION:
			await _caption(step)
		CutsceneStep.Kind.TAKE:
			_take(step)
		CutsceneStep.Kind.SPAWN:
			_spawn(step)
		CutsceneStep.Kind.MOVE:
			if step.background:
				_begin_background_move(step)
			elif _begin_move(step):
				await _move_done
		CutsceneStep.Kind.CHANGE_MAP:
			return await _change_map(step)
		CutsceneStep.Kind.HOP:
			await _hop(step)
		CutsceneStep.Kind.LEAN:
			await _lean(step)
		CutsceneStep.Kind.DESPAWN:
			await _despawn(step)
		CutsceneStep.Kind.BATTLE:
			await _battle(step)
		CutsceneStep.Kind.GIVE:
			_give(step)
		CutsceneStep.Kind.SCARE:
			_scare(step)
		CutsceneStep.Kind.WAKE_UP:
			await _wake_up()
			return false
		CutsceneStep.Kind.REACT:
			_react(step)
		_:
			_step_error("étape « %s » inconnue" % CutsceneStep.kind_name(step.kind))
	return true


## Copie de [param step] dont les alias (acteur, cible, suiveur, voisin, Pokémon d'un
## combat) sont remplacés par les identifiants de PNJ de la scène en cours ; [param step]
## lui-même s'il n'en a aucun (les étapes de la bibliothèque ne sont jamais modifiées).
## null (push_error) si un alias n'a pas été fourni à [method play].
func _resolve_aliases(step: CutsceneStep) -> CutsceneStep:
	if step.get_aliases().is_empty():
		return step
	for alias: StringName in step.get_aliases():
		if not _aliases.has(alias):
			_step_error("alias « $%s » absent, étape « %s » sautée" % [
				alias, CutsceneStep.kind_name(step.kind)])
			return null
	var copy := step.copy()
	copy.actor = _resolve_ref(step.actor)
	copy.target = _resolve_ref(step.target)
	copy.near = _resolve_ref(step.near)
	copy.follower = _resolve_ref(step.follower)
	copy.player_pokemon = _resolve_ref(step.player_pokemon)
	copy.foe_pokemon = _resolve_ref(step.foe_pokemon)
	return copy


func _resolve_ref(ref: StringName) -> StringName:
	if not CutsceneStep.is_alias(ref):
		return ref
	return _aliases.get(CutsceneStep.alias_name(ref), ref)


## Étape « hop » : le PNJ saute vers une case absolue ou la première case d'atterrissage
## près d'un acteur ([method CutsceneMoves.resolve_landing] : libre, sans traverser la case
## d'un personnage, pas derrière la tête d'un grand) ([method Npc.hop_to]) ; l'étape attend
## la fin du saut (rebonds compris). Acteur, voisin ou case manquant, ou saut refusé :
## push_error, étape sautée.
func _hop(step: CutsceneStep) -> void:
	var npc := _find_actor(step.actor) as Npc
	if npc == null:
		_step_error("PNJ « %s » introuvable" % step.actor)
		return
	if not is_instance_valid(_map):
		_step_error("pas de carte pour le saut de « %s »" % step.actor)
		return
	var grid := _map.get_grid()
	var goal := step.cell
	if not step.near.is_empty():
		var anchor := _find_actor(step.near)
		if anchor == null:
			_step_error("acteur « %s » introuvable" % step.near)
			return
		goal = CutsceneMoves.resolve_landing(grid, npc.get_cell(), _cell_of(anchor),
			step.offsets, npc, _tall_cells())
	if goal == CutsceneStep.NO_CELL:
		_step_error("aucune case d'atterrissage près de « %s » pour le saut" % step.near)
		return
	if not npc.hop_to(goal, grid):
		_step_error("saut de « %s » vers %s refusé" % [step.actor, goal])
		return
	while is_instance_valid(npc) and npc.is_hopping():
		await get_tree().process_frame


## Étape « lean » : le PNJ s'avance légèrement vers la cible (direction, « player » ou
## PNJ), reste [constant LEAN_HOLD] s, puis revient ; l'étape attend son retour.
func _lean(step: CutsceneStep) -> void:
	var npc := _find_actor(step.actor) as Npc
	if npc == null:
		_step_error("PNJ « %s » introuvable" % step.actor)
		return
	var cell := npc.get_cell() + Grid.direction_from_name(step.target)
	if not Grid.is_direction_name(step.target):
		var other := _find_actor(step.target)
		if other == null:
			_step_error("cible « %s » introuvable" % step.target)
			return
		cell = _cell_of(other)
	npc.lean_toward(cell)
	await _await_npc_lean(npc)
	await _wait(LEAN_HOLD)
	if not is_instance_valid(npc):
		return
	npc.settle()
	await _await_npc_lean(npc)


func _await_npc_lean(npc: Npc) -> void:
	while is_instance_valid(npc) and npc.is_leaning():
		await get_tree().process_frame


## Étape « despawn » : le PNJ quitte la grille tout de suite (case libérée), s'efface en
## [constant DESPAWN_FADE] s, puis [method GameMap.remove_npc] le retire.
func _despawn(step: CutsceneStep) -> void:
	var npc := _find_actor(step.actor) as Npc
	if npc == null:
		_step_error("PNJ « %s » introuvable" % step.actor)
		return
	var map := _map
	var id := npc.get_id()
	npc.leave_grid()
	if npc.is_inside_tree() and DESPAWN_FADE > 0.0:
		var fade := npc.create_tween()
		fade.tween_property(npc, ^"modulate:a", 0.0, DESPAWN_FADE)
		await _wait(DESPAWN_FADE)
	if is_instance_valid(map):
		map.remove_npc(id)


## Étape « scare » (jalon 7, jalon-07.md §3.2) : le Pokémon d'ambiance « shy » réagit tout
## de suite comme à l'approche du joueur (même geste qu'[AmbientWatcher] : envol, ou fuite de
## [constant AmbientWatcher.FLEE_STEPS] pas à l'opposé du joueur), puis quitte la carte à la
## fin de sa réaction ([signal Npc.left_scene] → [method GameMap.remove_npc]). La scène
## n'attend pas : l'étape suivante commence aussitôt. Comme pour l'[AmbientWatcher], un
## Pokémon acculé (aucun pas de fuite possible) se retourne et reste. PNJ introuvable ou pas
## « shy » : push_error, étape sautée.
func _scare(step: CutsceneStep) -> void:
	var npc := _find_actor(step.actor) as Npc
	if npc == null:
		_step_error("PNJ « %s » introuvable" % step.actor)
		return
	if not npc.get_spec().is_shy():
		_step_error("« %s » n'est pas un Pokémon d'ambiance « shy »" % step.actor)
		return
	var map := _map
	var on_left := func(npc_id: StringName) -> void:
		if is_instance_valid(map):
			map.remove_npc(npc_id)
	npc.left_scene.connect(on_left, CONNECT_ONE_SHOT)
	if npc.get_spec().shy_action == &"fly":
		npc.fly_away()
		return
	var away_from := _player.get_cell() if is_instance_valid(_player) else npc.get_cell()
	var path := AmbientRules.flee_path(map.get_grid(), npc.get_cell(), away_from,
		AmbientWatcher.FLEE_STEPS, npc)
	npc.flee(path)


## Étape « battle » (jalon 4B, jalon-04.md §14.3) : joue le combat contre le dresseur, en
## gardant le verrou « cutscene » pendant toute sa durée, puis lève les drapeaux de l'issue
## ([method CutsceneStep.outcome_flags]). Sans runner branché, ou issue NONE (combat refusé) :
## push_error, étape sautée (aucun drapeau levé). Les PNJ Pokémon (player_pokemon, foe_pokemon,
## déjà résolus) sont cachés par le [BattleStage].
func _battle(step: CutsceneStep) -> void:
	if _battle_runner == null:
		_step_error("pas de directeur de combat pour « %s »" % step.trainer_id)
		return
	var world_actors: Dictionary[StringName, StringName] = {}
	if not step.player_pokemon.is_empty():
		world_actors[&"player"] = step.player_pokemon
	if not step.foe_pokemon.is_empty():
		world_actors[&"foe"] = step.foe_pokemon
	var outcome: int = await _battle_runner.run(step.trainer_id, _map, world_actors)
	if outcome == Battle.Outcome.NONE:
		_step_error("combat « %s » refusé" % step.trainer_id)
		return
	if _flags != null:
		for flag: StringName in step.outcome_flags(outcome):
			_flags.set_flag(flag)


## Étape « give » (jalon 4B) : ajoute [member CutsceneStep.count] objets au Sac et émet
## [signal item_given] (Boot en fait une toast). Sans Sac branché, ou objet inconnu de
## l'[ItemLibrary] : push_error, étape sautée (Sac inchangé).
func _give(step: CutsceneStep) -> void:
	if _bag == null or _items == null:
		_step_error("pas de Sac pour donner « %s »" % step.item_id)
		return
	if not _items.has_item(step.item_id):
		_step_error("objet inconnu « %s »" % step.item_id)
		return
	if _bag.add(step.item_id, step.count):
		item_given.emit(step.item_id, step.count)
		if step.found:
			item_found.emit(step.item_id, step.count)


## Étape « caption » (jalon 7, « POKÉDEX ACTIVÉ ») : légende posée sur le monde par la HUD
## (fondu, tenue UiTokens.CAPTION_HOLD, fondu), puis la scène reprend quand elle a disparu.
## Sans HUD branchée : push_error, étape sautée.
func _caption(step: CutsceneStep) -> void:
	if not is_instance_valid(_hud):
		_step_error("pas de HUD pour la légende « %s »" % step.text)
		return
	_hud.show_caption(step.text)
	await _hud.caption_hidden


## Étape « take » (jalon 7, le colis remis à Chen) : retire [member CutsceneStep.count] objets
## du Sac, sans toast ni signal (aucun texte validé). Sans Sac branché, ou sans assez d'objets
## : push_error, étape sautée (Sac inchangé).
func _take(step: CutsceneStep) -> void:
	if _bag == null:
		_step_error("pas de Sac pour reprendre « %s »" % step.item_id)
		return
	if not _bag.remove(step.item_id, step.count):
		_step_error("le Sac n'a pas %d « %s »" % [step.count, step.item_id])


## Étape « wake_up » (jalon-07.md §3.8, T25) : défaite contre un Dresseur, le joueur se réveille
## au point de repos ([method DefeatRecovery.recover] : soin, fondu et changement de carte, mot du
## lieu non attendu). L'appelant arrête la scène ensuite : les PNJ de la carte quittée n'existent
## plus. Le verrou « cutscene » est gardé pendant le fondu. Sans [DefeatRecovery] : push_error.
func _wake_up() -> void:
	if _recovery == null:
		_step_error("pas de réveil branché (DefeatRecovery)")
		return
	await _recovery.recover()


## Attente de [param seconds] s par le mécanisme de l'étape « wait » (_process).
func _wait(seconds: float) -> void:
	if seconds <= 0.0:
		return
	_wait_left = seconds
	_wait_frame = Engine.get_process_frames()
	_waiting = true
	await _wait_elapsed


## Étape « change_map » : fondu et changement de carte par le routeur (la scène garde son
## blocage pendant la transition). Faux (la scène s'arrête, push_error) si le routeur
## manque ou si la carte courante n'est pas la carte demandée après la transition.
func _change_map(step: CutsceneStep) -> bool:
	if _router == null:
		_step_error("pas de routeur pour aller sur « %s »" % step.map_id)
		return false
	await _router.change_map(step.map_id, step.spawn, step.facing)
	var map := _router.get_current_map()
	if not is_instance_valid(map) or map.map_id != step.map_id:
		_step_error("changement de carte vers « %s » (%s) manqué" % [step.map_id, step.spawn])
		return false
	# Normalement déjà fait par le relais de map_changed ; sans relais, la carte suit quand même.
	_map = map
	return true


func _play_dialogue(dialogue_id: StringName) -> void:
	var map: GameMap = _map if is_instance_valid(_map) else null
	if _runner == null or not _runner.play(dialogue_id, null, map):
		push_error("CutsceneDirector : dialogue « %s » refusé (%s, étape %d)" % [
			dialogue_id, _cutscene_id, _step_index + 1])
		return
	while _runner.is_running():
		await _runner.dialogue_finished


## L'acteur se tourne vers la cible : nom de direction, « player » ou PNJ (axe dominant).
func _face(actor_id: StringName, target: StringName) -> void:
	var actor := _find_actor(actor_id)
	if actor == null:
		push_error("CutsceneDirector : acteur « %s » introuvable (%s, étape %d)" % [
			actor_id, _cutscene_id, _step_index + 1])
		return
	var direction := Grid.direction_from_name(target)
	if not Grid.is_direction_name(target):
		var other := _find_actor(target)
		if other == null:
			push_error("CutsceneDirector : cible « %s » introuvable (%s, étape %d)" % [
				target, _cutscene_id, _step_index + 1])
			return
		var delta := _cell_of(other) - _cell_of(actor)
		direction = Grid.dominant_direction(_cell_of(actor), _cell_of(other))
		if absi(delta.x) == 1 and absi(delta.y) == 1:
			# Voisins en diagonale : côte à côte, ils se regardent de profil.
			direction = Vector2i(delta.x, 0)
	if direction == Vector2i.ZERO:
		return
	if actor is Player:
		(actor as Player).face(direction)
	else:
		(actor as Npc).face(direction)


## Étape « spawn » : PNJ créé sur la carte courante (GameMap.add_npc signale les refus).
func _spawn(step: CutsceneStep) -> void:
	if not is_instance_valid(_map):
		push_error("CutsceneDirector : pas de carte pour « %s » (%s, étape %d)" % [
			step.actor, _cutscene_id, _step_index + 1])
		return
	_map.add_npc(step.spec)


## Étape « move » : résout l'acteur et son chemin (écrit, ou calculé vers une case absolue
## ou voisine d'un acteur), puis lance le premier pas. Faux (étape finie tout de suite) si
## l'acteur, la destination ou le chemin manque (push_error), ou s'il est déjà arrivé.
func _begin_move(step: CutsceneStep) -> bool:
	var actor := _find_actor(step.actor)
	if actor == null:
		_step_error("acteur « %s » introuvable" % step.actor)
		return false
	var path := _move_path_of(step, actor)
	if path.is_empty():
		return false
	_follow_actor = null
	_follow_path = []
	_follow_index = 0
	if not step.follower.is_empty():
		_begin_follower(step.follower, actor, path)
	_move_actor = actor
	_move_path = path
	_move_index = 0
	_move_run = step.run
	_move_keep_facing = step.keep_facing
	_move_blocked = 0.0
	_moving = true
	_try_next_steps()
	return true


## Directions de l'étape « move » pour [param actor] : le chemin écrit, ou celui calculé vers
## sa destination (case absolue ou voisine d'un acteur). Vide si l'acteur est déjà arrivé, ou
## si la destination ou le chemin manque (push_error, sauf « optional » sans case libre).
func _move_path_of(step: CutsceneStep, actor: Node2D) -> Array[Vector2i]:
	var path: Array[Vector2i] = step.path
	if not step.has_destination():
		return path
	if not is_instance_valid(_map):
		_step_error("pas de carte pour la destination de « %s »" % step.actor)
		return []
	var grid := _map.get_grid()
	var from := _cell_of(actor)
	var goal := step.cell
	if not step.near.is_empty():
		var anchor := _find_actor(step.near)
		if anchor == null:
			_step_error("acteur « %s » introuvable" % step.near)
			return []
		goal = CutsceneMoves.resolve_near(grid, _cell_of(anchor), step.offsets, actor)
	if goal == CutsceneStep.NO_CELL:
		if not step.optional:
			_step_error("aucune case libre près de « %s »" % step.near)
		return []
	path = grid.find_path(from, goal, actor)
	if path.is_empty() and goal != from:
		_step_error("aucun chemin de %s à %s pour « %s »" % [from, goal, step.actor])
	return path


## « move » en arrière-plan : le PNJ part (premier pas dans cette image si possible) et la
## scène continue. PNJ introuvable ou sans chemin : push_error, rien.
func _begin_background_move(step: CutsceneStep) -> void:
	var npc := _find_actor(step.actor) as Npc
	if npc == null:
		_step_error("PNJ « %s » introuvable" % step.actor)
		return
	var path := _move_path_of(step, npc)
	if path.is_empty():
		return
	_background.append({"actor": npc, "path": path, "index": 0, "run": step.run,
		"blocked": 0.0})
	_update_background(0.0)


## Pas suivant de chaque marche en arrière-plan à l'arrêt ; une marche finie (dernier pas
## terminé), bloquée plus de [constant MOVE_BLOCK_TIMEOUT] s ou dont le PNJ a disparu est
## retirée.
func _update_background(delta: float) -> void:
	var i := 0
	while i < _background.size():
		var move: Dictionary = _background[i]
		var npc := move["actor"] as Npc
		var done := not is_instance_valid(npc)
		if not done and not npc.is_moving():
			var path: Array[Vector2i] = move["path"]
			var index: int = move["index"]
			if index >= path.size():
				done = true
			elif npc.step(path[index], move["run"]):
				move["index"] = index + 1
				move["blocked"] = 0.0
			else:
				move["blocked"] = float(move["blocked"]) + delta
				if float(move["blocked"]) > MOVE_BLOCK_TIMEOUT:
					_step_error("« %s » bloqué en %s" % [npc.name, npc.get_cell()])
					done = true
		if done:
			_background.remove_at(i)
		else:
			i += 1


## Attend la fin de la marche en arrière-plan de [param actor_id] (rien s'il n'en a pas).
func _await_background(actor_id: StringName) -> void:
	var actor := _find_actor(actor_id)
	if actor == null:
		return
	while _background.any(func(move: Dictionary) -> bool: return move["actor"] == actor):
		await get_tree().process_frame


## Étape « react » : petite réaction de surprise du joueur ou d'un PNJ, sans attendre.
func _react(step: CutsceneStep) -> void:
	var actor := _find_actor(step.actor)
	if actor == null:
		_step_error("acteur « %s » introuvable" % step.actor)
		return
	if actor is Player:
		(actor as Player).react()
	else:
		(actor as Npc).react()


## Prépare le suiveur [param follower_id] du meneur [param leader] : un pas vers la case de
## départ du meneur, puis ses pas sauf le dernier ([method CutsceneMoves.follow_path]).
## Introuvable ou pas voisin du meneur : push_error, le meneur marche seul.
func _begin_follower(follower_id: StringName, leader: Node2D, path: Array[Vector2i]) -> void:
	var follower := _find_actor(follower_id)
	if follower == null:
		_step_error("suiveur « %s » introuvable" % follower_id)
		return
	if follower == leader:
		_step_error("« %s » ne peut pas se suivre lui-même" % follower_id)
		return
	var follow := CutsceneMoves.follow_path(_cell_of(follower), _cell_of(leader), path)
	if follow.is_empty():
		_step_error("suiveur « %s » pas à côté de « %s »" % [follower_id, leader.name])
		return
	_follow_actor = follower
	_follow_path = follow


## Pilote l'étape « move » : quand le meneur (et son suiveur) sont à l'arrêt, pas suivant ;
## un pas refusé est retenté à chaque image, abandonné au-delà de MOVE_BLOCK_TIMEOUT.
func _update_move(delta: float) -> void:
	if not is_instance_valid(_move_actor) or (_follow_actor != null
			and not is_instance_valid(_follow_actor)):
		_step_error("acteur disparu pendant son déplacement")
		_end_move()
		return
	if _is_actor_moving(_move_actor):
		return
	if _follow_actor != null and _is_actor_moving(_follow_actor):
		return
	if _move_index >= _move_path.size() and _follow_index >= _follow_path.size():
		_end_move()
		return
	if _try_next_steps():
		return
	_move_blocked += delta
	if _move_blocked > MOVE_BLOCK_TIMEOUT:
		var stuck := _move_actor if _move_index < _move_path.size() else _follow_actor
		_step_error("« %s » bloqué en %s" % [stuck.name, _cell_of(stuck)])
		_end_move()


## Lance le pas suivant du meneur, puis celui du suiveur dans la même image (la case que le
## meneur quitte est libérée dès son départ). Le meneur n'a jamais plus d'un pas d'avance ;
## le suiveur ne le dépasse jamais. Vrai si au moins un pas est parti.
func _try_next_steps() -> bool:
	var started := false
	var leader_may_go := _follow_actor == null or _move_index == _follow_index \
			or _follow_index >= _follow_path.size()
	if leader_may_go and _move_index < _move_path.size():
		if _start_step(_move_actor, _move_path[_move_index]):
			_move_index += 1
			started = true
	var follower_may_go := _follow_index < _move_index or _move_index >= _move_path.size()
	if _follow_actor != null and follower_may_go and _follow_index < _follow_path.size():
		if _start_step(_follow_actor, _follow_path[_follow_index]):
			_follow_index += 1
			started = true
	if started:
		_move_blocked = 0.0
	return started


## Un pas scripté de [param actor] (joueur ou PNJ) ; vrai s'il est parti.
func _start_step(actor: Node2D, direction: Vector2i) -> bool:
	if actor is Player:
		var keep := _move_keep_facing and actor == _move_actor
		return (actor as Player).script_step(direction, _move_run, keep)
	return (actor as Npc).step(direction, _move_run)


func _end_move() -> void:
	_stop_move()
	_move_done.emit()


func _stop_move() -> void:
	_moving = false
	_move_keep_facing = false
	_move_actor = null
	_move_path = []
	_move_index = 0
	_follow_actor = null
	_follow_path = []
	_follow_index = 0


static func _is_actor_moving(actor: Node2D) -> bool:
	if actor is Player:
		return (actor as Player).is_moving()
	return (actor as Npc).is_moving()


func _step_error(message: String) -> void:
	push_error("CutsceneDirector : %s (%s, étape %d)" % [message, _cutscene_id,
		_step_index + 1])


## Joueur (« player ») ou PNJ de la carte courante, résolu à chaque étape ; null sinon.
func _find_actor(actor_id: StringName) -> Node2D:
	if actor_id == NpcRoster.PLAYER_ID:
		return _player if is_instance_valid(_player) else null
	if not is_instance_valid(_map):
		return null
	return _map.get_npc(actor_id)


## Cases qui cachent la case juste au-dessus d'elles : grands personnages de la scène
## (joueur, PNJ humains : derrière leur tête, [method Npc.is_tall]) et meubles dont le sprite
## dépasse ([method GameMap.get_overhang_cells]). Un Pokémon ne se pose pas au-dessus.
func _tall_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if is_instance_valid(_map):
		cells.append_array(_map.get_overhang_cells())
	if is_instance_valid(_player):
		cells.append(_player.get_cell())
	if is_instance_valid(_map):
		for npc: Npc in _map.get_npcs():
			if npc.is_tall():
				cells.append(npc.get_cell())
	return cells


static func _cell_of(actor: Node2D) -> Vector2i:
	if actor is Player:
		return (actor as Player).get_cell()
	return (actor as Npc).get_cell()


func _finish() -> void:
	var cutscene_id := _cutscene_id
	_running = false
	_waiting = false
	_stop_move()
	_background.clear()
	_cutscene_id = &""
	_step_index = -1
	_aliases = {}
	if is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	set_process(false)
	cutscene_finished.emit(cutscene_id)


func _disconnect_player() -> void:
	if is_instance_valid(_player) and _player.moved.is_connected(_on_player_moved):
		_player.moved.disconnect(_on_player_moved)


## Pas terminé du joueur : déclencheur de la case, si le joueur est libre (pas scripté,
## transition et scène en cours ignorés).
func _on_player_moved(cell: Vector2i) -> void:
	if _running or not is_instance_valid(_map) or not is_instance_valid(_player):
		return
	if not _player.is_input_enabled():
		return
	if _router != null and _router.is_transitioning():
		return
	var trigger := _map.get_triggers().find_on_step(cell, _player.get_facing())
	if trigger != null:
		play(trigger.cutscene_id)
