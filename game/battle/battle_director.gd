class_name BattleDirector
extends Node
## Le seul à jouer un combat (jalon-04.md §14.2). Il construit les camps, joue le moteur
## ([Battle]), découpe chaque [BattleEvent] du journal en temps de mise en scène
## ([BattlePlayback] → [BattleBeat]) et les joue sur le [BattleStage] (le décor recomposé et
## les Pokémon) et la [BattleHud] (cartes, barres de PV, messages). La boucle de choix passe
## par les signaux de la HUD ; la fin par [BattleConclusion] (soin, ni XP ni argent).
##
## Il ne lit aucun autoload : il reçoit [GameState] par [method setup] et la carte par
## [method run] (appelée par l'étape « battle » du [CutsceneDirector]). Il n'appelle jamais
## [SceneRouter] et ne touche au monde que par le [BattleStage] (les deux PNJ Pokémon qu'il
## cache). Aucune indication du Prof. Chen pendant le combat (décision de Kevin n° 9).

## Le combat commence (verrou posé, monde figé).
signal battle_started(trainer_id: StringName)
## Un événement du journal vient d'être entièrement joué (tests, sons futurs).
signal event_played(event: BattleEvent)
## Le combat est terminé (verrou rendu). [param outcome] : [enum Battle.Outcome].
signal battle_finished(trainer_id: StringName, outcome: int)

## Raison de blocage du joueur pendant un combat ([method Player.set_input_enabled]).
const REASON: StringName = &"battle"
## Durées multipliées (0 = instantané, tests) ; relayé à la scène et à la HUD.
var speed_scale: float = 1.0

var _data: PokemonData
var _trainers: TrainerLibrary
var _texts: BattleText
var _stage: BattleStage
var _hud: BattleHud
var _player: Player
var _state: Node
var _running: bool = false
var _battle: Battle
var _trainer_id: StringName = &""
## Vue vers camp de la HUD (l'UI a son propre enum, sans lien avec BattleEvent.SideId).
const _HUD_SIDE: Dictionary[BattleEvent.SideId, BattleHud.Side] = {
	BattleEvent.SideId.PLAYER: BattleHud.Side.PLAYER,
	BattleEvent.SideId.FOE: BattleHud.Side.FOE,
}


## Branche le directeur. [param state] : l'autoload GameState en jeu, une instance neuve de
## game_state.gd en test (équipe, starter du joueur, aléatoire).
func setup(data: PokemonData, trainers: TrainerLibrary, texts: BattleText, stage: BattleStage,
		hud: BattleHud, player: Player, state: Node) -> void:
	_data = data
	_trainers = trainers
	_texts = texts
	_stage = stage
	_hud = hud
	_player = player
	_state = state


## Coroutine : joue le combat contre [param trainer_id] sur [param map], renvoie une
## [enum Battle.Outcome] (NONE si refusé). [param world_actors] : &"player" / &"foe" →
## identifiant du PNJ Pokémon de [param map] qui combat (cachés pendant le combat,
## facultatifs). Enveloppe (jalon 5 §3.8) : construit la [BattleRequest] d'un dresseur (camps
## bâtis depuis la [TrainerLibrary]) puis joue [method run_request] ; le combat du rival (4B)
## ne change pas.
func run(trainer_id: StringName, map: GameMap,
		world_actors: Dictionary[StringName, StringName]) -> int:
	if _running:
		push_error("BattleDirector : un combat tourne déjà")
		return Battle.Outcome.NONE
	var trainer := _trainers.get_trainer(trainer_id) if _trainers != null else null
	if trainer == null:
		push_error("BattleDirector : dresseur inconnu « %s »" % trainer_id)
		return Battle.Outcome.NONE
	var party := _state.party as Party
	if party == null or party.first_able() == null:
		push_error("BattleDirector : aucun Pokémon valide dans l'équipe du joueur")
		return Battle.Outcome.NONE
	# Camps du dresseur : l'équipe issue de son starter (consomme l'aléatoire avant le combat,
	# comme au 4B). La requête porte ensuite ces camps et les règles « dresseur ».
	var rng := _state.rng as GameRng
	var foes := _trainers.build_team(trainer_id, _state.starter_species, rng)
	var request := BattleRequest.trainer_battle(trainer, foes, world_actors)
	return await run_request(request, map)


## Coroutine : joue le combat décrit par [param request] sur [param map] (jalon 5 §3.8) et
## renvoie une [enum Battle.Outcome] (NONE si refusé). Sauvage ([method BattleRequest.wild]) ou
## dresseur ([method BattleRequest.trainer_battle]) : même déroulé (entrée, moteur, boucle de
## tours, sortie), seules changent l'entrée en scène (intro sauvage dans le décor / entrée du
## dresseur avec ses PNJ), les actions proposées (FUITE active en sauvage) et la conclusion (le
## soin du dresseur ; un sauvage n'est jamais soigné ici — la défaite et le soin passent par
## l'[EncounterDirector], §3.11).
func run_request(request: BattleRequest, map: GameMap) -> int:
	if _running:
		push_error("BattleDirector : un combat tourne déjà")
		return Battle.Outcome.NONE
	var foe: Pokemon = request.foe_party.get_lead() if request != null \
		and request.foe_party != null else null
	if foe == null:
		push_error("BattleDirector.run_request : équipe adverse vide")
		return Battle.Outcome.NONE
	var party := _state.party as Party
	if party == null or party.first_able() == null:
		push_error("BattleDirector.run_request : aucun Pokémon valide dans l'équipe du joueur")
		return Battle.Outcome.NONE
	var wild := request.is_wild()
	var trainer := request.trainer
	_running = true
	_trainer_id = trainer.id if trainer != null else &""
	if is_instance_valid(_player):
		_player.set_input_enabled(false, REASON)
	battle_started.emit(_trainer_id)
	_relay_speed()
	# Camps : le joueur avec son équipe, l'adversaire avec l'équipe de la requête (le sauvage
	# tiré, ou l'équipe du dresseur). Le moteur reçoit les règles (fuite en sauvage).
	var rng := _state.rng as GameRng
	var foe_ai := trainer.make_ai() if trainer != null else null
	var foe_side := BattleSide.new(request.foe_party, false, request.foe_name, foe_ai)
	var player_side := BattleSide.new(party, true)
	_battle = Battle.new(player_side, foe_side, _data, rng, request.rules)
	var player_species := party.get_lead().species_id
	var foe_species := foe.species_id
	# Entrée (~1 s, jamais d'écran noir) : intro sauvage dans le décor (herbe, partenaire qui
	# entre en courant) ou entrée du dresseur (PNJ Pokémon du monde cachés, sprites de combat).
	var camera := _player.get_camera() if is_instance_valid(_player) else null
	if is_instance_valid(_stage) and camera != null:
		_stage.set_frame(map.get_battle_arena_rect(), Rect2(map.get_pixel_rect()))
		if wild:
			var origin_world := Grid.cell_to_world(request.origin_cell)
			await _stage.play_wild_intro(camera, foe_species, origin_world)
			await _stage.play_partner_enter(player_species)
		else:
			var player_npc := _npc(map, request.world_actors.get(&"player", &""))
			var foe_npc := _npc(map, request.world_actors.get(&"foe", &""))
			await _stage.enter(camera, player_npc, foe_npc, player_species, foe_species)
	if is_instance_valid(_hud):
		_hud.set_party(party.size())
	# Déroulé du moteur : présentation des camps, puis la boucle de tours.
	await _play_events(_battle.start(), trainer)
	var actions := BattleViews.WILD_BATTLE_ACTIONS if wild else BattleViews.TRAINER_BATTLE_ACTIONS
	var can_flee := request.rules != null and request.rules.can_flee
	while _battle.get_state() == Battle.State.CHOOSING:
		var action := await _choose_action(actions, can_flee)
		if _battle.get_state() != Battle.State.CHOOSING:
			break
		await _play_events(_battle.submit(action), trainer)
	# Fin : sortie de la vue, puis conclusion. Dresseur : soin éventuel (les deux Pokémon,
	# l'équipe du rival n'est pas gardée), ni XP ni argent (5C). Sauvage : aucun soin.
	var outcome := _battle.get_outcome()
	if is_instance_valid(_hud):
		await _hud.hide_all()
	if is_instance_valid(_stage) and _stage.is_active():
		await _stage.exit()
	if trainer != null:
		var conclusion := BattleConclusion.resolve(trainer, outcome)
		if conclusion.heal_party:
			party.heal_all()
	_running = false
	_battle = null
	if is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	battle_finished.emit(_trainer_id, outcome)
	return outcome


func is_running() -> bool:
	return _running


## Combat en cours (null hors combat), pour les tests.
func get_battle() -> Battle:
	return _battle


# --- Boucle de choix ------------------------------------------------------------------

## Coroutine : propose [param actions] (grille), attend le choix du joueur, renvoie l'action à
## soumettre. ATTAQUER sans PP → Lutte directement (règle des jeux) ; sinon les capacités,
## « ‹ » revient. FUITE (si [param can_flee], sauvage) → une action de fuite ([BattleAction.run]).
func _choose_action(actions: Dictionary[StringName, bool], can_flee: bool) -> BattleAction:
	while true:
		_hud.show_actions(actions)
		var action: StringName = await _hud.action_selected
		if action == ActionGrid.RUN and can_flee:
			return BattleAction.run()
		if action != ActionGrid.ATTACK:
			# SAC, ÉQUIPE (et FUITE contre un dresseur) : atténués et muets, mais on ne bloque
			# pas si un signal arrive.
			continue
		var usable := _battle.get_usable_moves()
		if usable.is_empty():
			return BattleAction.move(BattleAction.STRUGGLE)
		var lead := _battle.get_player_side().active.pokemon
		_hud.show_moves(BattleViews.moves(lead, _data))
		var index := await _await_move_or_back()
		if index < 0:
			continue
		return BattleAction.move(index)
	return BattleAction.move(BattleAction.STRUGGLE)


## Coroutine : attend une capacité choisie (index) ou un retour à la grille (−1).
func _await_move_or_back() -> int:
	while true:
		var result: Array = await _first_of(_hud.move_selected, _hud.back_requested)
		if result[0] == 1:
			return -1
		return int(result[1])
	return -1


## Coroutine : attend le premier des deux signaux. Renvoie [index (0/1), valeur].
func _first_of(a: Signal, b: Signal) -> Array:
	var box: Array = []
	var on_a := func(value: Variant = null) -> void:
		if box.is_empty():
			box.append([0, value])
	var on_b := func(value: Variant = null) -> void:
		if box.is_empty():
			box.append([1, value])
	a.connect(on_a)
	b.connect(on_b)
	while box.is_empty():
		await get_tree().process_frame
	a.disconnect(on_a)
	b.disconnect(on_b)
	return box[0]


# --- Lecture du journal ---------------------------------------------------------------

## Coroutine : joue chaque événement de [param events] à la suite, temps par temps.
func _play_events(events: Array[BattleEvent], trainer: TrainerData) -> void:
	for event: BattleEvent in events:
		for beat: BattleBeat in BattlePlayback.beats(event, _texts, _data, trainer):
			await _play_beat(beat)
		event_played.emit(event)


## Coroutine : joue un temps ([BattleBeat]) sur la scène et la HUD, et attend sa fin.
func _play_beat(beat: BattleBeat) -> void:
	var side: BattleHud.Side = _HUD_SIDE[beat.side]
	match beat.kind:
		BattleBeat.Kind.MESSAGE:
			if is_instance_valid(_hud):
				await _hud.show_message(beat.text)
		BattleBeat.Kind.SEND_OUT:
			if is_instance_valid(_stage):
				_stage.show_pokemon(beat.side, beat.event.species_id)
			if is_instance_valid(_hud):
				_hud.set_card(side, BattleViews.card(beat.event))
		BattleBeat.Kind.MOVE:
			if is_instance_valid(_stage):
				await _stage.play_move(beat.side, beat.category)
		BattleBeat.Kind.DAMAGE:
			var big := beat.is_big_hit(UiTokens.HP_BIG_HIT)
			if is_instance_valid(_stage):
				_stage.play_hit(beat.side, beat.event.critical)
			if is_instance_valid(_hud):
				_hud.play_hit(side, beat.event.critical)
				await _hud.animate_hp(side, beat.event.hp, beat.event.max_hp, big)
		BattleBeat.Kind.STAT:
			if is_instance_valid(_stage):
				await _stage.play_stat(beat.side, beat.event.stages > 0)
		BattleBeat.Kind.FAINT:
			if is_instance_valid(_stage):
				await _stage.play_faint(beat.side)
			if is_instance_valid(_hud):
				_hud.hide_card(side)


func _npc(map: GameMap, id: StringName) -> Node2D:
	if id.is_empty() or not is_instance_valid(map):
		return null
	return map.get_npc(id)


func _relay_speed() -> void:
	if is_instance_valid(_stage):
		_stage.speed_scale = speed_scale
	if is_instance_valid(_hud):
		_hud.speed_scale = speed_scale
