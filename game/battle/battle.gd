class_name Battle
extends RefCounted
## Moteur de combat au tour par tour, 1 contre 1 (jalon 4 §2.2 et §3.4). Classe pure.
##
## Le moteur ne joue rien : [method start] et [method submit] renvoient un journal de
## [BattleEvent] que la présentation joue ensuite. Aucune dépendance à l'arbre de scènes
## ni aux autoloads ; l'aléatoire vient uniquement du [GameRng] reçu (même graine, mêmes
## actions → même journal).
##
## Un tour ([method submit]) : choix de l'IA adverse, ordre (priorité de la capacité, puis
## Vitesse effective, puis tirage roll(2) à égalité : 1 = le joueur d'abord), exécution. Un
## Pokémon K.O. n'agit plus ; le combat s'arrête dès qu'un camp n'a plus de Pokémon valide
## (si les deux tombent pendant la même action, le camp du lanceur gagne). En fin de tour,
## un camp dont le Pokémon est K.O. envoie le suivant. Sans PP, seule Lutte est permise
## ([constant BattleAction.STRUGGLE]) : sans type, recul d'¼ des PV max du lanceur.
## Ordre des tirages : IA adverse (pick_index), égalité de Vitesse, puis pour chaque
## action ceux de [DamageCalc] (ou la seule précision pour une capacité de statut) et un
## roll(100) par effet de [member MoveEffect.chance] < 100.
## Les conséquences (soin, argent, XP) sont décidées hors du moteur (TrainerData).

enum State { READY, CHOOSING, OVER }
enum Outcome { NONE, WIN, LOSS, FLED }

const STRUGGLE_ID: StringName = &"struggle"

var _player: BattleSide
var _foe: BattleSide
var _data: PokemonData
var _rng: GameRng
var _rules: BattleRules
var _state: State = State.READY
var _outcome: Outcome = Outcome.NONE
var _turn: int = 0
## Tentatives de fuite déjà ratées de ce combat (C de la formule, [FleeCalc]).
var _flee_attempts: int = 0


## [param rules] : les règles du combat ([BattleRules]) ; null = comportement du 4B (combat
## du rival : pas de fuite, pas de Sac). L'aléatoire vient de [param rng].
func _init(player_side: BattleSide, foe_side: BattleSide, data: PokemonData,
		rng: GameRng, rules: BattleRules = null) -> void:
	_player = player_side
	_foe = foe_side
	_data = data
	_rng = rng
	_rules = rules
	if _foe.ai == null:
		_foe.ai = BattleAI.new()


## Règles du combat (null = comportement du 4B).
func get_rules() -> BattleRules:
	return _rules


func get_state() -> State:
	return _state


## Issue du point de vue du joueur (NONE tant que le combat continue).
func get_outcome() -> Outcome:
	return _outcome


## Numéro du dernier tour joué (0 avant le premier).
func get_turn() -> int:
	return _turn


func get_player_side() -> BattleSide:
	return _player


func get_foe_side() -> BattleSide:
	return _foe


## Présente les camps et envoie les deux Pokémon. Tableau vide (push_error) si le combat a
## déjà commencé ou si un camp n'a aucun Pokémon valide.
func start() -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	if _state != State.READY or not _player.has_able() or not _foe.has_able():
		push_error("Battle : start impossible (déjà commencé ou camp sans Pokémon)")
		return events
	var started := BattleEvent.new(BattleEvent.Kind.BATTLE_STARTED, BattleEvent.SideId.FOE)
	started.trainer_name = _foe.trainer_name
	events.append(started)
	_send_out(_foe, events)
	_send_out(_player, events)
	_state = State.CHOOSING
	return events


## Emplacements des capacités du joueur qui ont des PP (vide = seule Lutte est permise).
func get_usable_moves() -> Array[int]:
	if _player.active == null:
		return []
	return _player.active.usable_moves()


## Vrai si [param action] est permise au joueur maintenant.
func is_legal(action: BattleAction) -> bool:
	if _state != State.CHOOSING or action == null:
		return false
	if action.kind == BattleAction.Kind.RUN:
		return _rules != null and _rules.can_flee
	if action.kind != BattleAction.Kind.MOVE:
		return false
	var usable := get_usable_moves()
	if action.move_index == BattleAction.STRUGGLE:
		return usable.is_empty()
	return usable.has(action.move_index)


## Vrai si le joueur peut tenter de fuir maintenant (règles du combat sauvage).
func can_flee() -> bool:
	return _state == State.CHOOSING and _rules != null and _rules.can_flee


## Joue un tour entier avec l'action du joueur. Tableau vide (push_error) si l'action est
## illégale ou si le combat n'attend pas de choix.
func submit(action: BattleAction) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	if not is_legal(action):
		push_error("Battle : action refusée (état %s, capacité %d)" % [State.find_key(_state),
			action.move_index if action != null else -99])
		return events
	_turn += 1
	var started := BattleEvent.new(BattleEvent.Kind.TURN_STARTED, BattleEvent.SideId.PLAYER)
	started.turn = _turn
	events.append(started)
	if action.kind == BattleAction.Kind.RUN:
		_attempt_flee(events)
		return events
	var foe_action := _foe.ai.choose(_foe, _player, _rng)
	var order: Array[BattleSide] = [_player, _foe]
	if _player_goes_second(action, foe_action):
		order = [_foe, _player]
	var actors: Array[Battler] = [order[0].active, order[1].active]
	for i: int in order.size():
		var side := order[i]
		if side.active != actors[i] or actors[i].pokemon.is_fainted():
			continue
		_execute(side, action if side == _player else foe_action, events)
		if _state == State.OVER:
			return events
	for side: BattleSide in [_foe, _player]:
		if side.active.pokemon.is_fainted():
			_send_out(side, events)
	return events


## Tentative de fuite (jouée avant les capacités, §2.2). Réussite → FLED puis BATTLE_ENDED
## (FLED), le combat s'arrête. Échec → FLEE_FAILED puis l'adversaire joue son tour. Ordre des
## tirages : FleeCalc (roll(256), seulement si la fuite n'est pas assurée), puis, en cas
## d'échec, l'IA adverse et l'exécution de son action.
func _attempt_flee(events: Array[BattleEvent]) -> void:
	var player_speed: int = _player.active.pokemon.stats.get(&"spe", 0)
	var foe_speed: int = _foe.active.pokemon.stats.get(&"spe", 0)
	if FleeCalc.can_flee(player_speed, foe_speed, _flee_attempts, _rng):
		events.append(_event(BattleEvent.Kind.FLED, _player))
		_outcome = Outcome.FLED
		_state = State.OVER
		var ended := BattleEvent.new(BattleEvent.Kind.BATTLE_ENDED, BattleEvent.SideId.PLAYER)
		ended.outcome = _outcome
		ended.trainer_name = _foe.trainer_name
		events.append(ended)
		return
	_flee_attempts += 1
	events.append(_event(BattleEvent.Kind.FLEE_FAILED, _player))
	var foe_action := _foe.ai.choose(_foe, _player, _rng)
	if _foe.active.pokemon.is_fainted():
		return
	_execute(_foe, foe_action, events)
	if _state == State.OVER:
		return
	for side: BattleSide in [_foe, _player]:
		if side.active.pokemon.is_fainted():
			_send_out(side, events)


func _player_goes_second(player_action: BattleAction, foe_action: BattleAction) -> bool:
	var player_priority := _priority(_player, player_action)
	var foe_priority := _priority(_foe, foe_action)
	if player_priority != foe_priority:
		return foe_priority > player_priority
	var player_speed := _player.active.effective_stat(&"spe")
	var foe_speed := _foe.active.effective_stat(&"spe")
	if player_speed != foe_speed:
		return foe_speed > player_speed
	return _rng.roll(2) == 2


func _priority(side: BattleSide, action: BattleAction) -> int:
	var move := _data.get_move(_move_id(side, action))
	return move.priority if move != null else 0


func _move_id(side: BattleSide, action: BattleAction) -> StringName:
	if action.move_index == BattleAction.STRUGGLE:
		return STRUGGLE_ID
	return side.active.pokemon.moves[action.move_index].move_id


func _execute(side: BattleSide, action: BattleAction, events: Array[BattleEvent]) -> void:
	var user := side.active
	var target_side := _foe if side == _player else _player
	var target := target_side.active
	var move_id := _move_id(side, action)
	var move := _data.get_move(move_id)
	if move == null:
		push_error("Battle : capacité inconnue « %s »" % move_id)
		return
	var used := _event(BattleEvent.Kind.MOVE_USED, side)
	used.move_id = move_id
	if action.move_index == BattleAction.STRUGGLE:
		used.pp = -1
	else:
		var slot := user.pokemon.moves[action.move_index]
		slot.use()
		used.pp = slot.pp
	events.append(used)
	if move.is_damaging():
		var result := DamageCalc.compute(user, target, move, _data.get_type_chart(), _rng)
		if not result.hit:
			_append_missed(side, move_id, events)
			return
		if result.effectiveness == 0.0:
			var immune := _event(BattleEvent.Kind.NO_EFFECT, target_side)
			immune.move_id = move_id
			events.append(immune)
			return
		var damage := _event(BattleEvent.Kind.DAMAGE, target_side)
		damage.move_id = move_id
		damage.amount = target.pokemon.take_damage(result.amount)
		damage.hp = target.pokemon.hp
		damage.effectiveness = result.effectiveness
		damage.critical = result.critical
		events.append(damage)
	elif not DamageCalc.accuracy_check(user, target, move, _rng):
		_append_missed(side, move_id, events)
		return
	for effect: MoveEffect in move.effects:
		_apply_effect(effect, side, target_side, events)
	if target.pokemon.is_fainted():
		events.append(_event(BattleEvent.Kind.FAINTED, target_side))
	if user.pokemon.is_fainted():
		events.append(_event(BattleEvent.Kind.FAINTED, side))
	_check_end(side, events)


func _apply_effect(effect: MoveEffect, side: BattleSide, target_side: BattleSide,
		events: Array[BattleEvent]) -> void:
	match effect.kind:
		MoveEffect.Kind.STAT_STAGE:
			var affected_side := side if effect.target == MoveEffect.Target.SELF else target_side
			var affected := affected_side.active
			if affected.pokemon.is_fainted():
				return
			if effect.chance < 100 and _rng.roll(100) > effect.chance:
				return
			var applied := affected.change_stage(effect.stat, effect.stages)
			var kind := BattleEvent.Kind.STAT_CHANGED if applied != 0 \
				else BattleEvent.Kind.STAT_UNCHANGED
			var changed := _event(kind, affected_side)
			changed.stat = effect.stat
			changed.stages = applied if applied != 0 else effect.stages
			changed.stage = affected.get_stage(effect.stat)
			events.append(changed)
		MoveEffect.Kind.RECOIL:
			var user := side.active.pokemon
			var recoil := _event(BattleEvent.Kind.RECOIL, side)
			recoil.amount = user.take_damage(maxi(floori(user.max_hp() * effect.fraction), 1))
			recoil.hp = user.hp
			events.append(recoil)


func _append_missed(side: BattleSide, move_id: StringName, events: Array[BattleEvent]) -> void:
	var missed := _event(BattleEvent.Kind.MOVE_MISSED, side)
	missed.move_id = move_id
	events.append(missed)


## Fin du combat si un camp n'a plus de Pokémon valide ([param acting] : camp du lanceur,
## vainqueur si les deux tombent ensemble).
func _check_end(acting: BattleSide, events: Array[BattleEvent]) -> void:
	var player_out := not _player.has_able()
	var foe_out := not _foe.has_able()
	if not player_out and not foe_out:
		return
	if player_out and foe_out:
		_outcome = Outcome.WIN if acting == _player else Outcome.LOSS
	else:
		_outcome = Outcome.WIN if foe_out else Outcome.LOSS
	_state = State.OVER
	var ended := BattleEvent.new(BattleEvent.Kind.BATTLE_ENDED, BattleEvent.SideId.PLAYER)
	ended.outcome = _outcome
	ended.trainer_name = _foe.trainer_name
	events.append(ended)


func _send_out(side: BattleSide, events: Array[BattleEvent]) -> void:
	side.send_out(side.party.first_able(), _data)
	var sent := _event(BattleEvent.Kind.SENT_OUT, side)
	sent.trainer_name = side.trainer_name
	events.append(sent)


## Événement sur le Pokémon en jeu de [param side], avec son état actuel.
func _event(kind: BattleEvent.Kind, side: BattleSide) -> BattleEvent:
	var event := BattleEvent.new(kind, BattleEvent.SideId.PLAYER if side.is_player
		else BattleEvent.SideId.FOE)
	var pokemon := side.active.pokemon
	event.pokemon_name = pokemon.display_name(_data)
	event.species_id = pokemon.species_id
	event.level = pokemon.level
	event.gender = pokemon.gender
	event.hp = pokemon.hp
	event.max_hp = pokemon.max_hp()
	return event
