class_name BattleDirector
extends Node
## Le seul à jouer un combat (jalon-04.md §14.2). Il construit les camps, joue le moteur
## ([Battle]), découpe chaque [BattleEvent] du journal en temps de mise en scène
## ([BattlePlayback] → [BattleBeat]) et les joue sur le [BattleStage] (le décor recomposé et
## les Pokémon) et la [BattleHud] (cartes, barres de PV, messages). La boucle de choix passe
## par les signaux de la HUD ; la fin par [BattleConclusion] (soin, ni XP ni argent).
## XP (jalon 5C) : le directeur rejoue EXP_GAINED (barre d'XP de la carte du joueur), LEVEL_UP
## (« Nv. » qui pulse, PV max) et les phrases de capacité apprise, dans l'ordre du journal ;
## pour un Pokémon du joueur qui n'est pas en jeu, le gain est appliqué sans être montré
## (Q24). MOVE_FORGET_OFFERED suspend la lecture : le bandeau sort, le [MoveForgetPanel] fait
## choisir la capacité à oublier (ou aucune), puis la phrase suit et la lecture reprend.
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
const FORGET_PANEL_SCENE: PackedScene = preload("res://game/ui/battle/move_forget_panel.tscn")
## Durées multipliées (0 = instantané, tests) ; relayé à la scène et à la HUD.
var speed_scale: float = 1.0

var _data: PokemonData
var _trainers: TrainerLibrary
var _texts: BattleText
var _stage: BattleStage
var _hud: BattleHud
var _player: Player
var _state: Node
var _forget_panel: MoveForgetPanel
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
	_free_forget_panel()
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


## Le panneau d'oubli, tant qu'il existe (ouvert pendant une offre, tests) ; null sinon.
func get_forget_panel() -> MoveForgetPanel:
	return _forget_panel if is_instance_valid(_forget_panel) else null


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
		BattleBeat.Kind.EXP:
			# Un seul Pokémon a une carte : le gain des autres est appliqué sans être montré.
			if is_instance_valid(_hud) and _is_in_play(beat.event):
				await _hud.animate_exp(beat.event.exp_from, beat.event.exp_to, beat.event.amount)
		BattleBeat.Kind.LEVEL:
			if is_instance_valid(_hud) and _is_in_play(beat.event):
				await _hud.pulse_level(side, beat.event.level)
				await _hud.animate_hp(side, beat.event.hp, beat.event.max_hp, false)
		BattleBeat.Kind.DRAIN:
			if is_instance_valid(_hud):
				await _play_drain(beat.event)
		BattleBeat.Kind.FORGET:
			await _offer_forget(beat.event)


## Coroutine : Vampigraine, les deux barres de PV en même temps : le Pokémon drainé perd
## ([member BattleEvent.hp]), celui d'en face gagne ([member BattleEvent.healed_hp]).
func _play_drain(event: BattleEvent) -> void:
	var victim: BattleHud.Side = _HUD_SIDE[event.side]
	var other: BattleHud.Side = BattleHud.Side.FOE if victim == BattleHud.Side.PLAYER \
		else BattleHud.Side.PLAYER
	var other_bar := _hud.get_card(other).get_hp_bar()
	# Lancée sans attendre : la barre qui gagne et la barre qui perd bougent ensemble.
	_hud.animate_hp(other, event.healed_hp, other_bar.get_max_hp(), false)
	await _hud.animate_hp(victim, event.hp, event.max_hp, false)
	while other_bar.is_animating():
		await get_tree().process_frame


## Pokémon du joueur décrit par [param event] (espèce, nom, sexe) ; l'équipe en entier est
## cherchée, celui en jeu d'abord. Null s'il n'y est pas.
func _find_player_pokemon(event: BattleEvent) -> Pokemon:
	var party := _state.party as Party
	if party == null:
		return null
	var in_play := _battle.get_player_side().active.pokemon if _battle != null else null
	var candidates: Array[Pokemon] = []
	if in_play != null:
		candidates.append(in_play)
	candidates.append_array(party.get_all())
	for pokemon: Pokemon in candidates:
		if pokemon.species_id == event.species_id \
				and pokemon.display_name(_data) == event.pokemon_name:
			return pokemon
	return null


## Le Pokémon de [param event] est celui qui a sa carte (le Pokémon du joueur en jeu).
func _is_in_play(event: BattleEvent) -> bool:
	if _battle == null or _battle.get_player_side().active == null:
		return false
	return _find_player_pokemon(event) == _battle.get_player_side().active.pokemon


## Coroutine : un Pokémon du joueur veut apprendre [member BattleEvent.move_id] mais connaît
## déjà quatre capacités. Le bandeau sort, le panneau fait choisir ; seul OUBLIER (après
## sélection d'une carte) ou NE PAS APPRENDRE ferme l'offre. Oubli : [method
## Pokemon.replace_move] (PP pleins) et « oublie… et apprend… » ; refus : rien ne change et
## « n'apprend pas… ». Rend la main une fois le panneau refermé.
func _offer_forget(event: BattleEvent) -> void:
	var pokemon := _find_player_pokemon(event)
	var offered := BattleViews.offered_move(event.move_id, _data)
	if pokemon == null or offered == null or not is_instance_valid(_hud):
		push_error("BattleDirector : offre d'oubli impossible (« %s » pour « %s »)"
			% [event.move_id, event.pokemon_name])
		return
	var known := BattleViews.moves(pokemon, _data)
	# Le panneau recouvre le bandeau : le bandeau sort d'abord, jamais les deux ensemble.
	var banner := _hud.get_message_banner()
	banner.skip()
	banner.slide_out()
	while banner.is_sliding():
		await get_tree().process_frame
	var panel := _ensure_forget_panel()
	panel.show_offer(offered, known)
	var answer: Array = await _first_of(panel.forget_chosen, panel.skip_chosen)
	while panel.is_sliding():
		await get_tree().process_frame
	var line := ""
	if answer[0] == 0:
		var slot := int(answer[1])
		var old_move: StringName = pokemon.moves[slot].move_id \
			if slot >= 0 and slot < pokemon.moves.size() else &""
		if pokemon.replace_move(slot, event.move_id, _data):
			line = _texts.line_for(&"move_forgot", event, _data, old_move)
	if line.is_empty():
		line = _texts.line_for(&"move_not_learned", event, _data)
	await _hud.show_message(line)


## Le panneau d'oubli (créé au premier besoin, dans l'écran de la HUD, à son emplacement).
func _ensure_forget_panel() -> MoveForgetPanel:
	if is_instance_valid(_forget_panel):
		return _forget_panel
	_forget_panel = FORGET_PANEL_SCENE.instantiate() as MoveForgetPanel
	_hud.get_screen().add_child(_forget_panel)
	BattleHudLayout.place(_forget_panel, BattleHudLayout.Slot.FORGET)
	_forget_panel.speed_scale = _hud.speed_scale
	_forget_panel.haptics_enabled = _hud.haptics_enabled
	return _forget_panel


func _free_forget_panel() -> void:
	if is_instance_valid(_forget_panel):
		_forget_panel.queue_free()
	_forget_panel = null


func _npc(map: GameMap, id: StringName) -> Node2D:
	if id.is_empty() or not is_instance_valid(map):
		return null
	return map.get_npc(id)


func _relay_speed() -> void:
	if is_instance_valid(_stage):
		_stage.speed_scale = speed_scale
	if is_instance_valid(_hud):
		_hud.speed_scale = speed_scale
