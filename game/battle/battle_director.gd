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
## facultatifs).
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
	_running = true
	_trainer_id = trainer_id
	if is_instance_valid(_player):
		_player.set_input_enabled(false, REASON)
	battle_started.emit(trainer_id)
	_relay_speed()
	# Camps : le joueur avec son équipe, le dresseur avec l'équipe issue de son starter.
	var starter: StringName = _state.starter_species
	var rng := _state.rng as GameRng
	var foes := _trainers.build_team(trainer_id, starter, rng)
	var foe_side := BattleSide.new(foes, false, trainer.name, trainer.make_ai())
	var player_side := BattleSide.new(party, true)
	_battle = Battle.new(player_side, foe_side, _data, rng)
	var player_species := party.get_lead().species_id
	var foe_species: StringName = foes.get_lead().species_id if foes != null \
		and foes.get_lead() != null else &""
	# Vue de combat dans le labo recomposé (~1 s) : PNJ Pokémon cachés, sprites de combat.
	var camera := _player.get_camera() if is_instance_valid(_player) else null
	var player_npc := _npc(map, world_actors.get(&"player", &""))
	var foe_npc := _npc(map, world_actors.get(&"foe", &""))
	if is_instance_valid(_stage) and camera != null:
		_stage.set_frame(map.get_battle_arena_rect(), Rect2(map.get_pixel_rect()))
		await _stage.enter(camera, player_npc, foe_npc, player_species, foe_species)
	if is_instance_valid(_hud):
		_hud.set_party(party.size())
	# Déroulé du moteur : présentation des camps, puis la boucle de tours.
	await _play_events(_battle.start(), trainer)
	while _battle.get_state() == Battle.State.CHOOSING:
		var action := await _choose_action()
		if _battle.get_state() != Battle.State.CHOOSING:
			break
		await _play_events(_battle.submit(action), trainer)
	# Fin : soin (les deux Pokémon, l'équipe du rival n'est pas gardée), ni XP ni argent.
	var outcome := _battle.get_outcome()
	var conclusion := BattleConclusion.resolve(trainer, outcome)
	if is_instance_valid(_hud):
		await _hud.hide_all()
	if is_instance_valid(_stage) and _stage.is_active():
		await _stage.exit()
	if conclusion.heal_party:
		party.heal_all()
	_running = false
	_battle = null
	if is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	battle_finished.emit(trainer_id, outcome)
	return outcome


func is_running() -> bool:
	return _running


## Combat en cours (null hors combat), pour les tests.
func get_battle() -> Battle:
	return _battle


# --- Boucle de choix ------------------------------------------------------------------

## Coroutine : propose les actions, attend le choix du joueur, renvoie l'action à soumettre.
## ATTAQUER sans PP → Lutte directement (règle des jeux) ; sinon les capacités, « ‹ » revient.
func _choose_action() -> BattleAction:
	while true:
		_hud.show_actions(BattleViews.TRAINER_BATTLE_ACTIONS)
		var action: StringName = await _hud.action_selected
		if action != ActionGrid.ATTACK:
			# SAC, ÉQUIPE, FUITE : sans effet au premier combat (ils sont atténués et muets,
			# mais on ne bloque pas si un signal arrive).
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
