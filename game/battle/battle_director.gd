class_name BattleDirector
extends Node
## Le seul à jouer un combat (jalon-04.md §14.2). Il construit les camps, joue le moteur
## ([Battle]), découpe chaque [BattleEvent] du journal en temps de mise en scène
## ([BattlePlayback] → [BattleBeat]) et les joue sur le [BattleStage] (le décor recomposé et
## les Pokémon) et la [BattleHud] (cartes, barres de PV, messages). La boucle de choix passe
## par les signaux de la HUD ; la fin par [BattleConclusion] (soin ; argent gagné contre un
## dresseur vaincu, versé par [code]add_money[/code] de [GameState], jalon 7).
## XP (jalon 5C, revu par la demande n° 1 du 2026-10-06) : pendant le combat, EXP_GAINED et
## LEVEL_UP ne montrent rien (la carte du Pokémon en jeu garde son ancien niveau et ses PV
## max jusqu'à la fin du bilan) ; le directeur les note dans un [ExpSummary]. À la fin du
## combat, après sa dernière phrase (et l'argent gagné), après une victoire ou une capture
## seulement : le [b]bilan de fin de combat[/b] ([ExpSummaryCard] : une ligne par Pokémon qui
## a gagné de l'XP ; rien si aucun), puis la sortie. Après une défaite, l'XP reste, rien n'est
## montré.
## Capacités (décision de Kevin du 2026-10-06, « comme dans Rouge/Bleu ») : MOVE_LEARNED et
## MOVE_FORGET_OFFERED sont joués à leur place dans le journal, juste après le K.O. adverse qui
## les a produits, avant l'envoi du Pokémon suivant ou la fin du combat. « X apprend Y ! »
## attend un toucher ; MOVE_FORGET_OFFERED suspend la lecture : le bandeau sort, le
## [MoveForgetPanel] fait choisir la capacité à oublier (ou aucune), puis la phrase suit. La
## capacité est utilisable dès le tour suivant (la grille relit les capacités à chaque choix) ;
## la carte de PV garde l'ancien niveau jusqu'au bilan (défaut).
##
## Il ne lit aucun autoload : il reçoit [GameState] par [method setup] et la carte par
## [method run] (appelée par l'étape « battle » du [CutsceneDirector]). Il n'appelle jamais
## [SceneRouter] et ne touche au monde que par le [BattleStage] (les deux PNJ Pokémon qu'il
## cache). Aucune indication du Prof. Chen pendant le combat (décision de Kevin n° 9).
##
## Capture (jalon 5D, jalon-05.md §3.10) : en combat sauvage, SAC ouvre le [BattleBagPanel]
## (construit depuis le Sac et l'[ItemLibrary]) ; la Potion (jalon 6, T12) ouvre le choix du Pokémon, puis [BattleAction.heal] : l'adversaire joue ensuite ;
## « ‹ » revient aux actions sans rien consommer ; une Ball choisie est retirée du Sac [b]une
## seule fois[/b], puis le moteur joue le lancer ([BattleEvent.Kind.BALL_THROWN], secousses,
## CAUGHT ou BROKE_FREE). Sur CAUGHT, le [i]même[/i] Pokémon (PV gardés) rejoint l'équipe, ou le
## [PokemonStorage] si elle est pleine ; Pokédex daté ([method GameState.record_caught]),
## rencontre « capture » ([method GameState.stamp_meeting]), grand moment « première capture »
## (une seule fois : le starter compte comme premier Pokémon, pas comme première capture) ;
## puis la [CaptureCard] (« Nouvelle entrée Pokédex » seulement si le Pokédex est activé par
## Chen : [constant StoryFlags.POKEDEX_ACTIVATED], jalon 7) et le signal [signal pokemon_caught]
## (autosave demandé par Boot). Aucune XP, aucun soin.
##
## Changement de Pokémon (jalon 7, jalon-07.md §15.23) : ÉQUIPE (active dès que l'équipe compte
## deux Pokémon, [method BattleViews.with_team]) ouvre le [BattlePartyPanel] à la place de la
## carte du joueur ; ENVOYER → [method BattleAction.switch_to] (« Reviens, … ! », rappel,
## « En avant, … ! », la carte du nouveau arrive, puis l'adversaire joue) ; « ‹ » rend la carte
## et la grille. K.O. du Pokémon du joueur avec d'autres valides
## ([method Battle.needs_replacement]) : le même panneau, sans « ‹ », fait choisir le suivant
## ([method Battle.replace]).

## Le combat commence (verrou posé, monde figé).
signal battle_started(trainer_id: StringName)
## Un événement du journal vient d'être entièrement joué (tests, sons futurs).
signal event_played(event: BattleEvent)
## Le combat est terminé (verrou rendu). [param outcome] : [enum Battle.Outcome].
signal battle_finished(trainer_id: StringName, outcome: int)
## Un Pokémon sauvage vient d'être capturé et rangé (équipe, ou stockage si [param stored]) ;
## la carte de capture est sur le point de s'afficher. Boot y demande l'autosave.
signal pokemon_caught(pokemon: Pokemon, stored: bool)
## Vibration jouée ou demandée (millisecondes) : une par secousse de la Ball, puis les
## vibrations du motif de capture. Émise même sans vibration réelle (tests).
signal haptic_requested(duration_ms: int)
## Les barres du bilan de fin de combat sont arrivées (la carte attend le toucher qui ferme).
signal exp_summary_shown(summary: ExpSummary)

## Raison de blocage du joueur pendant un combat ([method Player.set_input_enabled]).
const REASON: StringName = &"battle"
const FORGET_PANEL_SCENE: PackedScene = preload("res://game/ui/battle/move_forget_panel.tscn")
const BAG_PANEL_SCENE: PackedScene = preload("res://game/ui/battle/battle_bag_panel.tscn")
const PARTY_PICKER_SCENE: PackedScene = preload("res://game/ui/bag/party_picker.tscn")
const CAPTURE_CARD_SCENE: PackedScene = preload("res://game/ui/battle/capture_card.tscn")
const PARTY_PANEL_SCENE: PackedScene = preload("res://game/ui/battle/battle_party_panel.tscn")
const SUMMARY_CARD_SCENE: PackedScene = preload("res://game/ui/battle/exp_summary_card.tscn")
## Catégorie du Sac voulue d'emblée en combat sauvage (les Balls) ; contre un dresseur : les
## soins ([method BagQuery.start_category]).
const BAG_START_CATEGORY: StringName = &"ball"
## Durées multipliées (0 = instantané, tests) ; relayé à la scène et à la HUD.
var speed_scale: float = 1.0
## « Confirmer certaines actions » (Paramètres, Q-18) : oublier une capacité passe par une
## question à deux cartes (OUBLIER / GARDER). Désactivé par défaut : comportement du 5C.
var confirm_forget: bool = false
## Tests seulement : composant à deux cartes de remplacement (défaut : `ChoiceCards`).
var choice_cards_script: GDScript = null
## Faux : pas de vibration réelle (haptic_requested est quand même émis) ; la HUD coupée
## (tests) coupe aussi celles de la capture.
var haptics_enabled: bool = true

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
var _items: ItemLibrary
var _bag_panel: BattleBagPanel
var _capture_card: CaptureCard
var _party_picker: PartyPicker
var _party_panel: BattlePartyPanel
## Pokémon sauvage du combat en cours (null contre un dresseur) et carte où il se joue.
var _wild_foe: Pokemon
var _map_id: StringName = &""
var _haptic_busy: bool = false
## Progression du combat en cours (bilan de fin de combat).
var _summary: ExpSummary = ExpSummary.new()
var _summary_card: ExpSummaryCard
## Vue vers camp de la HUD (l'UI a son propre enum, sans lien avec BattleEvent.SideId).
const _HUD_SIDE: Dictionary[BattleEvent.SideId, BattleHud.Side] = {
	BattleEvent.SideId.PLAYER: BattleHud.Side.PLAYER,
	BattleEvent.SideId.FOE: BattleHud.Side.FOE,
}


## Branche le directeur. [param state] : l'autoload GameState en jeu, une instance neuve de
## game_state.gd en test (équipe, starter du joueur, aléatoire, Sac, Pokédex, stockage).
## [param items] : les objets connus (Sac de combat, bonus des Balls) ; null = aucune Ball ne
## peut être lancée. Les requêtes sauvages doivent porter la même bibliothèque
## ([method get_item_library]).
func setup(data: PokemonData, trainers: TrainerLibrary, texts: BattleText, stage: BattleStage,
		hud: BattleHud, player: Player, state: Node, items: ItemLibrary = null) -> void:
	_items = items
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
	var request := BattleRequest.trainer_battle(trainer, foes, world_actors, _items)
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
	_summary = ExpSummary.new()
	_wild_foe = foe if wild else null
	_map_id = map.map_id if is_instance_valid(map) else &""
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
	# Le moteur choisit qui entre (premier Pokémon non K.O., pas forcément le premier de
	# l'équipe) : l'entrée en scène suit ses événements SENT_OUT, jamais une supposition.
	var opening := _battle.start()
	var player_species := _sent_out_species(opening, BattleEvent.SideId.PLAYER)
	var foe_species := _sent_out_species(opening, BattleEvent.SideId.FOE)
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
	await _play_events(opening, trainer)
	var actions := BattleViews.with_team(BattleViews.WILD_BATTLE_ACTIONS if wild
		else BattleViews.trainer_actions(trainer), party.size())
	var can_flee := request.rules != null and request.rules.can_flee
	while _battle.get_state() in [Battle.State.CHOOSING, Battle.State.REPLACING]:
		# K.O. du Pokémon du joueur : il choisit le suivant (pas de retour, pas de fuite).
		if _battle.needs_replacement():
			await _play_events(_battle.replace(await _choose_party(true)), trainer)
			continue
		var action := await _choose_action(actions, can_flee)
		if _battle.get_state() != Battle.State.CHOOSING:
			break
		# Une Ball ou une Potion quitte le Sac une seule fois, avant d'être jouée.
		if action.kind == BattleAction.Kind.ITEM and not _spend_item(action):
			continue
		await _play_events(_battle.submit(action), trainer)
	# Fin : l'argent gagné (dresseur vaincu : « Tu remportes 280 ₽. », versé à GameState ; jamais
	# rien de retiré), sortie de la vue, puis le soin éventuel du dresseur (les deux Pokémon,
	# l'équipe du rival n'est pas gardée). Sauvage : aucun soin, aucun argent.
	var outcome := _battle.get_outcome()
	var conclusion: BattleConclusion = null
	if trainer != null:
		var foes := request.foe_party
		var last_level := foes.get_at(foes.size() - 1).level if foes.size() > 0 else 0
		conclusion = BattleConclusion.resolve(trainer, outcome, last_level)
		if conclusion.prize_money > 0:
			if is_instance_valid(_hud) and _texts != null:
				await _hud.show_message(_texts.prize_line(conclusion.prize_money))
			_state.add_money(conclusion.prize_money)
	# Bilan de fin de combat (demande n° 1) : victoire ou capture seulement (décision de Kevin
	# du 2026-10-06 : rien après une défaite). Les capacités ont été annoncées au K.O.
	await _play_progress(outcome)
	if is_instance_valid(_hud):
		await _hud.hide_all()
	if is_instance_valid(_stage) and _stage.is_active():
		await _stage.exit()
	_free_panels()
	if conclusion != null and conclusion.heal_party:
		party.heal_all()
	_running = false
	_battle = null
	_wild_foe = null
	if is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	battle_finished.emit(_trainer_id, outcome)
	return outcome


func is_running() -> bool:
	return _running


## Combat en cours (null hors combat), pour les tests.
func get_battle() -> Battle:
	return _battle


## Objets connus du combat (null = aucune Ball ne peut être lancée) : la bibliothèque que les
## requêtes sauvages passent à [method BattleRequest.wild].
func get_item_library() -> ItemLibrary:
	return _items


## Le Sac de combat, tant qu'il existe (ouvert pendant un choix, tests) ; null sinon.
func get_bag_panel() -> BattleBagPanel:
	return _bag_panel if is_instance_valid(_bag_panel) else null


## La carte de capture, tant qu'elle existe (tests) ; null sinon.
func get_capture_card() -> CaptureCard:
	return _capture_card if is_instance_valid(_capture_card) else null


## Le choix du Pokémon, tant qu'il existe (tests) ; null sinon.
func get_party_picker() -> PartyPicker:
	return _party_picker if is_instance_valid(_party_picker) else null


## Le panneau ÉQUIPE, tant qu'il existe (ouvert pendant un choix, tests) ; null sinon.
func get_party_panel() -> BattlePartyPanel:
	return _party_panel if is_instance_valid(_party_panel) else null


## Le bilan de fin de combat, tant qu'il existe (tests) ; null sinon.
func get_summary_card() -> ExpSummaryCard:
	return _summary_card if is_instance_valid(_summary_card) else null


## Progression notée pendant le combat en cours (ou le dernier), pour les tests.
func get_exp_summary() -> ExpSummary:
	return _summary


## Retour (Android, relayé par Boot) : ferme le bilan de fin de combat s'il est affiché. Vrai si
## le geste a servi.
func handle_back() -> bool:
	return is_instance_valid(_summary_card) and _summary_card.handle_back()


## Le panneau d'oubli, tant qu'il existe (ouvert pendant une offre, tests) ; null sinon.
func get_forget_panel() -> MoveForgetPanel:
	return _forget_panel if is_instance_valid(_forget_panel) else null


# --- Boucle de choix ------------------------------------------------------------------

## Coroutine : propose [param actions] (grille), attend le choix du joueur, renvoie l'action à
## soumettre. ATTAQUER sans PP → Lutte directement (règle des jeux) ; sinon les capacités,
## « ‹ » revient. FUITE (si [param can_flee], sauvage) → une action de fuite ([BattleAction.run]).
## SAC (si la grille le permet et qu'une Ball ou un soin est utilisable) → le Sac de combat :
## une Ball choisie → [BattleAction.ball], un soin → [BattleAction.heal] ; « ‹ » revient ici
## sans rien consommer. ÉQUIPE (si la grille le permet) → le panneau ÉQUIPE : ENVOYER →
## [BattleAction.switch_to] ; « ‹ » revient ici.
func _choose_action(actions: Dictionary[StringName, bool], can_flee: bool) -> BattleAction:
	while true:
		_hud.show_actions(actions)
		var action: StringName = await _hud.action_selected
		if action == ActionGrid.RUN and can_flee:
			return BattleAction.run()
		if action == ActionGrid.BAG and actions.get(ActionGrid.BAG, false) \
				and (_battle.can_use_balls() or _battle.can_use_heal_items()):
			var chosen := await _choose_item()
			if chosen == null:
				continue
			return chosen
		if action == ActionGrid.TEAM and actions.get(ActionGrid.TEAM, false):
			var index := await _choose_party(false)
			if index < 0:
				continue
			return BattleAction.switch_to(index)
		if action != ActionGrid.ATTACK:
			# ÉQUIPE (et SAC / FUITE contre un dresseur) : atténués et muets, mais on ne bloque
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


## Coroutine : ouvre le Sac de combat et attend un objet : une Ball ([BattleAction.ball]), ou un
## soin puis le Pokémon à soigner ([BattleAction.heal]) ; « ‹ » du Sac renvoie null (la carte
## du joueur revient), « ‹ » du choix du Pokémon rouvre le Sac. Rien n'est consommé ici.
func _choose_item() -> BattleAction:
	var panel := _ensure_bag_panel()
	_hud.hide_card(BattleHud.Side.PLAYER)
	await _hud.hide_zone()
	while true:
		var context := _battle.item_context()
		var entries := BattleViews.bag_entries(_state.bag, _items, context)
		panel.show_bag(entries, BagQuery.start_category(context, BAG_START_CATEGORY,
			BagQuery.categories(entries)))
		var answer: Array = await _first_of(panel.item_chosen, panel.back_requested)
		while panel.is_sliding():
			await get_tree().process_frame
		if answer[0] == 1:
			_show_own_card()
			return null
		var id := StringName(answer[1])
		var item := _items.get_item(id) if _items != null else null
		if item == null or not item.targets_pokemon():
			return BattleAction.ball(id)
		var index := await _choose_target(item)
		if index >= 0:
			return BattleAction.heal(id, index)
	return null


## Coroutine : le panneau ÉQUIPE à la place de la carte du joueur ; renvoie la place du Pokémon
## à envoyer, ou −1 (« ‹ » : la carte du joueur revient). [param forced] : remplacement après un
## K.O. (pas de « ‹ », titre « Qui envoyer au combat ? »).
func _choose_party(forced: bool) -> int:
	var panel := _ensure_party_panel()
	_hud.hide_card(BattleHud.Side.PLAYER)
	await _hud.hide_zone()
	var prompt := _texts.get_template(&"replace_prompt") if _texts != null else ""
	panel.show_party(BattleViews.party(_battle, _data, _texts), forced, prompt)
	var answer: Array = await _first_of(panel.pokemon_chosen, panel.back_requested)
	while panel.is_sliding():
		await get_tree().process_frame
	if answer[0] == 1:
		_show_own_card()
		return -1
	return int(answer[1])


## Coroutine : le choix du Pokémon pour [param item] ; son index dans l'équipe, ou −1 (« ‹ »).
func _choose_target(item: ItemData) -> int:
	var picker := _ensure_party_picker()
	picker.show_targets(BagQuery.targets(_state.party, _state.bag, item,
		_battle.item_context(), _data))
	picker.slide_in()
	var answer: Array = await _first_of(picker.target_chosen, picker.back_requested)
	picker.slide_out()
	while picker.is_sliding():
		await get_tree().process_frame
	return int(answer[1]) if answer[0] == 0 else -1


## Retire l'objet de [param action] du Sac, une seule fois ; faux, et rien ne change, si
## l'action n'est pas permise, si le Sac n'en a plus ou (soin) si le Pokémon le refuse.
func _spend_item(action: BattleAction) -> bool:
	var allowed := _battle.is_legal(action)
	if allowed and action.is_heal():
		var item := _items.get_item(action.item_id) if _items != null else null
		allowed = ItemUse.check(_state.bag, item, (_state.party as Party).get_at(action.target),
			_battle.item_context()) == ItemUse.Check.OK
	if not allowed or not _state.bag.remove(action.item_id):
		push_error("BattleDirector : objet « %s » refusé" % action.item_id)
		return false
	return true


## La carte du joueur et ses pastilles reviennent (après le Sac ou le lancer).
func _show_own_card() -> void:
	if not is_instance_valid(_hud):
		return
	_hud.get_card(BattleHud.Side.PLAYER).slide_in()
	_hud.get_party_pips().slide_in()


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
		_summary.add(event)
		for beat: BattleBeat in BattlePlayback.beats(event, _texts, _data, trainer):
			# « X apprend Y ! » (juste après le K.O. adverse) attend un toucher.
			beat.wait_touch = event.kind == BattleEvent.Kind.MOVE_LEARNED
			await _play_beat(beat)
		_log_progress(event)
		event_played.emit(event)


## Journal de QA (builds debug seulement) : chaque gain d'XP et montée de niveau, lisibles
## dans `logcat -s godot` même quand les messages défilent trop vite pour une capture.
static func _log_progress(event: BattleEvent) -> void:
	if not OS.is_debug_build():
		return
	match event.kind:
		BattleEvent.Kind.EXP_GAINED:
			# Une ligne par gain : les tranches suivantes d'une montée de plusieurs niveaux
			# (amount = 0) ne sont pas un nouveau gain.
			if event.amount > 0:
				print("[qa] XP : %s (équipe %d) +%d" % [event.pokemon_name, event.party_index,
					event.amount])
		BattleEvent.Kind.LEVEL_UP:
			print("[qa] niveau : %s (équipe %d) → N%d" % [event.pokemon_name,
				event.party_index, event.level])


## Coroutine : joue un temps ([BattleBeat]) sur la scène et la HUD, et attend sa fin.
func _play_beat(beat: BattleBeat) -> void:
	var side: BattleHud.Side = _HUD_SIDE[beat.side]
	match beat.kind:
		BattleBeat.Kind.MESSAGE:
			if is_instance_valid(_hud):
				await _hud.show_message(beat.text, beat.wait_touch)
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
			# Rien à l'écran : le bilan de fin de combat est l'unique lieu de la progression.
			pass
		BattleBeat.Kind.LEVEL:
			# La carte garde l'ancien niveau et ses PV max jusqu'à la fin du bilan, qui est
			# l'unique lieu de la progression (pas de spoiler pendant « X est K.O. ! »).
			pass
		BattleBeat.Kind.DRAIN:
			if is_instance_valid(_hud):
				await _play_drain(beat.event)
		BattleBeat.Kind.FORGET:
			await _offer_forget(beat.event)
		BattleBeat.Kind.THROW:
			await _play_throw()
		BattleBeat.Kind.SHAKE:
			_vibrate()
			if is_instance_valid(_stage):
				await _stage.play_ball_shake()
		BattleBeat.Kind.CATCH:
			await _play_catch(beat.event)
		BattleBeat.Kind.HEAL:
			# Le Sac a caché la carte du joueur : elle revient dès le soin, quel que soit le
			# Pokémon soigné. La barre ne bouge que si c'est celui en jeu.
			if is_instance_valid(_hud):
				_show_own_card()
			if is_instance_valid(_hud) and _is_in_play(beat.event):
				await _hud.animate_hp(side, beat.event.hp, beat.event.max_hp, false)
		BattleBeat.Kind.WITHDRAW:
			# La carte est déjà sortie (panneau ÉQUIPE) ; le SEND_OUT suivant ramène la nouvelle.
			if is_instance_valid(_hud):
				_hud.hide_card(side)
			if is_instance_valid(_stage):
				await _stage.play_withdraw(beat.side)
		BattleBeat.Kind.RELEASE:
			if is_instance_valid(_stage):
				await _stage.play_break_free()
			if is_instance_valid(_hud):
				_hud.set_card(BattleHud.Side.FOE, BattleViews.card(beat.event))
				_show_own_card()


# --- Bilan de fin de combat (demande n° 1) ---------------------------------------------

## Coroutine : après la dernière phrase du combat, le bilan (si de l'XP a été gagnée).
## Seulement après une victoire ou une capture ([method shows_progress]) : après une défaite (ou
## une fuite), l'XP et les niveaux restent acquis (le moteur les a déjà appliqués) mais rien
## n'est montré. Les capacités, elles, ont déjà été annoncées au K.O. qui les a apprises.
func _play_progress(outcome: Battle.Outcome) -> void:
	if not shows_progress(outcome):
		return
	if not _summary.is_empty() and is_instance_valid(_hud) and _texts != null:
		await _hud.hide_all()
		await _show_summary()


## Le bilan n'est montré qu'après une victoire ou une capture (décision de Kevin du
## 2026-10-06 ; fuite : défaut, rien non plus).
static func shows_progress(outcome: Battle.Outcome) -> bool:
	return outcome == Battle.Outcome.WIN or outcome == Battle.Outcome.CAUGHT


## Coroutine : la carte du bilan ; rend la main une fois fermée.
func _show_summary() -> void:
	var rows := BattleViews.exp_summary(_summary, _texts)
	var entries := _summary.get_entries()
	for i: int in rows.size():
		var path := BattleStage.sprite_path(entries[i].species_id, false)
		if ResourceLoader.exists(path):
			rows[i].portrait = load(path) as Texture2D
	var card := _ensure_summary_card()
	await card.show_summary(rows, _texts.get_template(&"summary_continue"))
	_log_summary()
	exp_summary_shown.emit(_summary)
	await card.wait_closed()


## Journal de QA (builds debug) : une ligne par Pokémon du bilan.
func _log_summary() -> void:
	if not OS.is_debug_build():
		return
	for entry: ExpSummaryEntry in _summary.get_entries():
		var before := entry.points[0]
		var after := entry.points[-1]
		print("[qa] bilan : %s (équipe %d) +%d XP, N%d %d/%d → N%d %d/%d" % [
			entry.pokemon_name, entry.party_index, entry.exp_gained, entry.start_level,
			before.x, before.z, entry.end_level(), after.y, after.z])


## Le bilan (créé au premier besoin, centré dans l'écran de la HUD).
func _ensure_summary_card() -> ExpSummaryCard:
	if is_instance_valid(_summary_card):
		return _summary_card
	_summary_card = SUMMARY_CARD_SCENE.instantiate() as ExpSummaryCard
	_hud.get_screen().add_child(_summary_card)
	BattleHudLayout.place(_summary_card, BattleHudLayout.Slot.SUMMARY)
	_summary_card.speed_scale = _hud.speed_scale
	_summary_card.haptics_enabled = _hud.haptics_enabled
	_summary_card.haptic_played.connect(_hud.haptic_played.emit)
	return _summary_card


# --- Capture (jalon 5D) ---------------------------------------------------------------

## Coroutine : le lancer. Les cartes et le bandeau sortent, le dresseur lance la Ball sur le
## Pokémon sauvage, qui est absorbé ; la Ball tombe dans l'herbe.
func _play_throw() -> void:
	if is_instance_valid(_hud):
		_hud.hide_card(BattleHud.Side.FOE)
		_hud.hide_card(BattleHud.Side.PLAYER)
		await _hud.hide_zone()
	if is_instance_valid(_stage):
		await _stage.play_throw()


## Coroutine : la capture réussit. Éclat doré avec le motif de vibration, puis le Pokémon est
## rangé et la carte de capture attend un toucher.
func _play_catch(event: BattleEvent) -> void:
	_haptic_busy = true
	_run_capture_haptics()
	if is_instance_valid(_stage):
		await _stage.play_catch_burst()
	while _haptic_busy:
		await get_tree().process_frame
	await _finish_capture(event)


## Coroutine : motif de vibration de la capture (lancée sans attendre, en parallèle de l'éclat).
func _run_capture_haptics() -> void:
	await HapticPattern.capture(get_tree(), _on_haptic, speed_scale)
	_haptic_busy = false


## Coroutine : range le Pokémon capturé et montre la carte de capture ([param event] : CAUGHT).
## Le même Pokémon (PV, PP, niveau) rejoint l'équipe, ou le stockage si elle est pleine.
func _finish_capture(event: BattleEvent) -> void:
	var pokemon := _wild_foe
	if pokemon == null:
		push_error("BattleDirector : capture sans Pokémon sauvage")
		return
	var party := _state.party as Party
	var joined := party != null and party.add(pokemon)
	if not joined:
		(_state.storage as PokemonStorage).add(pokemon)
	var species := pokemon.species_id
	var is_new: bool = _state.record_caught(species, _map_id)
	_state.stamp_meeting(pokemon, Pokemon.Origin.CAPTURE, _map_id)
	var first_capture: StringName = _state.MOMENT_FIRST_CAPTURE
	if not _state.has_moment(first_capture):
		_state.record_moment(first_capture, _map_id,
			{"species": String(species), "stored": not joined})
	pokemon_caught.emit(pokemon, not joined)
	if not is_instance_valid(_hud):
		return
	await _hud.hide_zone()
	# Rien du Pokédex n'est visible tant que Chen ne l'a pas activé (jalon 7, règle de
	# déblocage) : les données sont enregistrées, la ligne n'est pas montrée.
	var show_entry: bool = is_new and _state.flags.has_flag(StoryFlags.POKEDEX_ACTIVATED)
	var portrait_path := BattleStage.sprite_path(species, false)
	var portrait: Texture2D = null
	if ResourceLoader.exists(portrait_path):
		portrait = load(portrait_path) as Texture2D
	var view := CaptureCardView.new(_texts.line_for(&"caught_title", event, _data), portrait,
		show_entry, _texts.line_for(&"pokedex_new", event, _data),
		_texts.line_for(&"joined_party" if joined else &"sent_to_storage", event, _data))
	await _ensure_capture_card().show_capture(view)


## Vibration d'une secousse de la Ball : signal toujours, vibration réelle si permise.
func _vibrate() -> void:
	HapticPattern.ball_shake(_on_haptic)


func _on_haptic(duration_ms: int) -> void:
	haptic_requested.emit(duration_ms)
	if haptics_enabled and (not is_instance_valid(_hud) or _hud.haptics_enabled):
		Haptics.vibrate(duration_ms)


## Le Sac de combat (créé au premier besoin, dans l'écran de la HUD, à son emplacement).
func _ensure_bag_panel() -> BattleBagPanel:
	if is_instance_valid(_bag_panel):
		return _bag_panel
	_bag_panel = BAG_PANEL_SCENE.instantiate() as BattleBagPanel
	_hud.get_screen().add_child(_bag_panel)
	BattleHudLayout.place(_bag_panel, BattleHudLayout.Slot.BAG)
	_bag_panel.speed_scale = _hud.speed_scale
	_bag_panel.haptics_enabled = _hud.haptics_enabled
	return _bag_panel


## Le choix du Pokémon (créé au premier besoin, dans l'écran de la HUD, à son emplacement).
func _ensure_party_picker() -> PartyPicker:
	if is_instance_valid(_party_picker):
		return _party_picker
	_party_picker = PARTY_PICKER_SCENE.instantiate() as PartyPicker
	_hud.get_screen().add_child(_party_picker)
	BattleHudLayout.place(_party_picker, BattleHudLayout.Slot.PARTY_PICKER)
	_party_picker.speed_scale = _hud.speed_scale
	_party_picker.haptics_enabled = _hud.haptics_enabled
	return _party_picker


## Le panneau ÉQUIPE (créé au premier besoin, dans l'écran de la HUD, à son emplacement).
func _ensure_party_panel() -> BattlePartyPanel:
	if is_instance_valid(_party_panel):
		return _party_panel
	_party_panel = PARTY_PANEL_SCENE.instantiate() as BattlePartyPanel
	_hud.get_screen().add_child(_party_panel)
	BattleHudLayout.place(_party_panel, BattleHudLayout.Slot.PARTY)
	_party_panel.speed_scale = _hud.speed_scale
	_party_panel.haptics_enabled = _hud.haptics_enabled
	return _party_panel


## La carte de capture (créée au premier besoin, centrée dans l'écran de la HUD).
func _ensure_capture_card() -> CaptureCard:
	if is_instance_valid(_capture_card):
		return _capture_card
	_capture_card = CAPTURE_CARD_SCENE.instantiate() as CaptureCard
	_hud.get_screen().add_child(_capture_card)
	BattleHudLayout.place(_capture_card, BattleHudLayout.Slot.CAPTURE)
	_capture_card.speed_scale = _hud.speed_scale
	_capture_card.haptics_enabled = _hud.haptics_enabled
	return _capture_card


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


## Espèce du Pokémon envoyé par [param side] d'après le SENT_OUT de [param events] (&"" si le
## moteur n'en a pas émis).
func _sent_out_species(events: Array[BattleEvent], side: BattleEvent.SideId) -> StringName:
	for event: BattleEvent in events:
		if event.kind == BattleEvent.Kind.SENT_OUT and event.side == side:
			return event.species_id
	return &""


## Pokémon du joueur décrit par [param event], retrouvé par sa place dans l'équipe
## ([member BattleEvent.party_index], remplie par le moteur) : jamais par espèce et nom, qui se
## confondent avec deux Pokémon identiques. Null si la place n'existe pas.
func _find_player_pokemon(event: BattleEvent) -> Pokemon:
	var party := _state.party as Party
	return party.get_at(event.party_index) if party != null else null


## Le Pokémon de [param event] est celui qui a sa carte (le Pokémon du joueur en jeu).
func _is_in_play(event: BattleEvent) -> bool:
	if _battle == null or _battle.get_player_side().active == null:
		return false
	var pokemon := _find_player_pokemon(event)
	return pokemon != null and pokemon == _battle.get_player_side().active.pokemon


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
	var answer: Array = []
	while true:
		panel.show_offer(offered, known)
		answer = await _first_of(panel.forget_chosen, panel.skip_chosen)
		while panel.is_sliding():
			await get_tree().process_frame
		if answer[0] != 0 or not confirm_forget:
			break
		var slot := int(answer[1])
		var old_id: StringName = pokemon.moves[slot].move_id \
			if slot >= 0 and slot < pokemon.moves.size() else &""
		if await _confirm_forget(event, old_id):
			break
	var line := ""
	if answer[0] == 0:
		var slot := int(answer[1])
		var old_move: StringName = pokemon.moves[slot].move_id \
			if slot >= 0 and slot < pokemon.moves.size() else &""
		if pokemon.replace_move(slot, event.move_id, _data):
			line = _texts.line_for(&"move_forgot", event, _data, old_move)
	if line.is_empty():
		line = _texts.line_for(&"move_not_learned", event, _data)
	await _hud.show_message(line, true)


## Coroutine : la question « Oublier {capacité} ? » en deux cartes (composant `ChoiceCards`).
## Vrai si le joueur confirme (OUBLIER) ; GARDER rend la main au panneau d'oubli.
func _confirm_forget(event: BattleEvent, old_move: StringName) -> bool:
	if not is_instance_valid(_hud):
		return true
	var script: GDScript = choice_cards_script if choice_cards_script != null else ChoiceCards
	var view := ChoiceView.new(
		_texts.line_for(&"forget_confirm_title", event, _data, old_move),
		_texts.line_for(&"forget_confirm_yes", event, _data, old_move),
		_texts.line_for(&"forget_confirm_no", event, _data, old_move))
	view.detail = _texts.line_for(&"forget_confirm_detail", event, _data, old_move)
	var cards: Control = script.new()
	cards.set(&"speed_scale", _hud.speed_scale)
	_hud.get_screen().add_child(cards)
	cards.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cards.call(&"show_choice", view)
	var box: Array[bool] = []
	cards.connect(&"chosen", func(confirmed: bool) -> void: box.append(confirmed))
	while box.is_empty():
		await get_tree().process_frame
	cards.queue_free()
	return box[0]


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


## Libère les panneaux ouverts pendant le combat (oubli, Sac, carte de capture, ÉQUIPE, bilan).
func _free_panels() -> void:
	_free_forget_panel()
	for panel: Control in [_bag_panel, _capture_card, _party_picker, _party_panel,
			_summary_card]:
		if is_instance_valid(panel):
			panel.queue_free()
	_summary_card = null
	_bag_panel = null
	_capture_card = null
	_party_picker = null
	_party_panel = null


func _npc(map: GameMap, id: StringName) -> Node2D:
	if id.is_empty() or not is_instance_valid(map):
		return null
	return map.get_npc(id)


func _relay_speed() -> void:
	if is_instance_valid(_stage):
		_stage.speed_scale = speed_scale
	if is_instance_valid(_hud):
		_hud.speed_scale = speed_scale
