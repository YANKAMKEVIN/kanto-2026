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
## roll(100) par effet de [member MoveEffect.chance] < 100. La fin de tour (Vampigraine) et
## l'XP ne tirent rien.
##
## Fin de tour (jalon 5 Q28) : si le combat continue, chaque Pokémon porteur d'une graine de
## Vampigraine (le joueur d'abord, puis l'adversaire) perd la fraction de ses PV max fixée par
## la capacité (au moins 1) au profit du Pokémon d'en face, sauf si celui-ci est K.O. ; puis
## les camps dont le Pokémon est K.O. envoient le suivant.
##
## XP (jalon 5 §2.3, Q23, Q24) : seulement si [member BattleRules.gives_exp] (règles nulles :
## pas d'XP, comme le combat du rival du 4B). Les [b]participants[/b] sont les Pokémon du
## joueur envoyés contre l'adversaire en jeu (liste remise à zéro quand l'adversaire change).
## Quand un Pokémon adverse tombe, juste après son FAINTED (donc avant BATTLE_ENDED ou l'envoi
## du suivant), l'XP de [ExpCalc] est partagée entre les participants encore debout : pour
## chacun, EXP_GAINED (une tranche par niveau traversé), LEVEL_UP, puis MOVE_LEARNED (le
## moteur apprend la capacité, un emplacement est libre) ou MOVE_FORGET_OFFERED (4 capacités :
## rien ne change, la présentation fera choisir). Aucune évolution (Q27).
## Les autres conséquences (soin, argent) sont décidées hors du moteur (TrainerData).
##
## Capture (jalon 5D §2.4, Q33) : [code]BattleAction.ball(id)[/code] n'est légale que si
## [member BattleRules.allow_balls] (sauvage) et que [param id] est une Ball de
## [member BattleRules.items]. Elle est jouée avant les capacités : BALL_THROWN, 0 à 3
## BALL_SHAKE, puis CAUGHT et BATTLE_ENDED (CAUGHT) — l'adversaire ne joue pas, pas d'XP (Q26,
## comme Rouge/Bleu) — ou BROKE_FREE, puis l'adversaire joue son tour. Ordre des tirages :
## ceux de [CaptureCalc] (0 à 4 roll(65536)), puis, en cas d'échec, l'IA adverse et son
## action. Le moteur ne touche pas au Sac : le directeur retire la Ball, range le Pokémon
## capturé (équipe ou [PokemonStorage]) et marque le Pokédex.
##
## Soin (jalon 6 §3.4, Q-10, Q-11) : [code]BattleAction.heal(id, index)[/code] n'est légale que
## si [member BattleRules.allow_heal_items], que [param id] est un objet de
## [member BattleRules.items] et que [method ItemUse.check_target] l'accepte sur le Pokémon
## [param index] de l'équipe (n'importe lequel, pas un K.O., pas à PV pleins). Jouée avant les
## capacités : ITEM_USED (PV rendus, bornés), puis l'adversaire joue son tour. Aucun tirage
## propre. Le moteur ne touche pas au Sac (le directeur retire l'objet une fois).

enum State { READY, CHOOSING, OVER }
enum Outcome { NONE, WIN, LOSS, FLED, CAUGHT }

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
## Pokémon du joueur envoyés contre l'adversaire en jeu (XP, §2.3).
var _participants: Array[Pokemon] = []


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


## Participants actuels : Pokémon du joueur envoyés contre l'adversaire en jeu (copie).
func get_participants() -> Array[Pokemon]:
	return _participants.duplicate()


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
	if action.is_heal():
		return _is_legal_heal(action)
	if action.kind == BattleAction.Kind.ITEM:
		if not can_use_balls():
			return false
		var item := _rules.items.get_item(action.item_id)
		return item != null and item.category == ItemData.Category.BALL
	if action.kind != BattleAction.Kind.MOVE:
		return false
	var usable := get_usable_moves()
	if action.move_index == BattleAction.STRUGGLE:
		return usable.is_empty()
	return usable.has(action.move_index)


## Vrai si le joueur peut tenter de fuir maintenant (règles du combat sauvage).
func can_flee() -> bool:
	return _state == State.CHOOSING and _rules != null and _rules.can_flee


## Vrai si le joueur peut lancer une Ball maintenant (combat sauvage, objets connus). Le Sac
## n'est pas consulté : avoir une Ball est l'affaire du directeur.
func can_use_balls() -> bool:
	return _state == State.CHOOSING and _rules != null and _rules.allow_balls \
		and _rules.items != null


## Vrai si le joueur peut donner un soin maintenant (règles, objets connus). Ni le Sac ni la
## cible ne sont consultés ici ([method is_legal] vérifie la cible).
func can_use_heal_items() -> bool:
	return _state == State.CHOOSING and _rules != null and _rules.allow_heal_items \
		and _rules.items != null


## Contexte d'usage des objets de ce combat ([constant ItemData.CONTEXT_WILD_BATTLE] ou
## [constant ItemData.CONTEXT_TRAINER_BATTLE]).
func item_context() -> StringName:
	if _rules != null and _rules.wild:
		return ItemData.CONTEXT_WILD_BATTLE
	return ItemData.CONTEXT_TRAINER_BATTLE


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
	if action.is_heal():
		_use_heal(action, events)
		return events
	if action.kind == BattleAction.Kind.ITEM:
		_throw_ball(action.item_id, events)
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
	_end_turn(events)
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
		_finish(Outcome.FLED, events)
		return
	_flee_attempts += 1
	events.append(_event(BattleEvent.Kind.FLEE_FAILED, _player))
	_foe_turn_alone(events)


## Lancer de la Ball [param item_id] sur le Pokémon sauvage (joué avant les capacités, §2.4).
## Capturé → BALL_THROWN, 3 BALL_SHAKE, CAUGHT puis BATTLE_ENDED (CAUGHT) : l'adversaire ne
## joue pas, aucune XP. Libéré → BALL_THROWN, 0 à 3 BALL_SHAKE, BROKE_FREE, puis l'adversaire
## joue son tour.
func _throw_ball(item_id: StringName, events: Array[BattleEvent]) -> void:
	var item := _rules.items.get_item(item_id)
	var target := _foe.active.pokemon
	var species := _data.get_species(target.species_id)
	var thrown := _event(BattleEvent.Kind.BALL_THROWN, _foe)
	thrown.item_id = item_id
	thrown.item_name = item.name
	events.append(thrown)
	var result := CaptureCalc.throw_ball(target.max_hp(), target.hp,
		species.catch_rate if species != null else 1, item.catch_bonus, _rng)
	for i: int in result.shakes:
		var shake := _event(BattleEvent.Kind.BALL_SHAKE, _foe)
		shake.shake = i + 1
		events.append(shake)
	if result.caught:
		events.append(_event(BattleEvent.Kind.CAUGHT, _foe))
		_finish(Outcome.CAUGHT, events)
		return
	events.append(_event(BattleEvent.Kind.BROKE_FREE, _foe))
	_foe_turn_alone(events)


## Soin [member BattleAction.item_id] donné au Pokémon [member BattleAction.target] de
## l'équipe (joué avant les capacités, §3.4) : ITEM_USED, puis l'adversaire joue son tour.
func _use_heal(action: BattleAction, events: Array[BattleEvent]) -> void:
	var item := _rules.items.get_item(action.item_id)
	var pokemon := _player.party.get_at(action.target)
	var amount := ItemUse.restore(item, pokemon)
	var used := _pokemon_event(BattleEvent.Kind.ITEM_USED, BattleEvent.SideId.PLAYER, pokemon)
	used.item_id = action.item_id
	used.item_name = item.name
	used.amount = amount
	events.append(used)
	_foe_turn_alone(events)


func _is_legal_heal(action: BattleAction) -> bool:
	if not can_use_heal_items():
		return false
	var item := _rules.items.get_item(action.item_id)
	var pokemon := _player.party.get_at(action.target)
	return item != null and pokemon != null \
		and ItemUse.check_target(item, pokemon, item_context()) == ItemUse.Check.OK


## Tour où seul l'adversaire agit (fuite ratée, Pokémon libéré, soin) : son IA choisit, il joue,
## puis la fin de tour.
func _foe_turn_alone(events: Array[BattleEvent]) -> void:
	var foe_action := _foe.ai.choose(_foe, _player, _rng)
	if _foe.active.pokemon.is_fainted():
		return
	_execute(_foe, foe_action, events)
	if _state == State.OVER:
		return
	_end_turn(events)


## Fin du combat sur [param outcome] : BATTLE_ENDED, plus aucun choix.
func _finish(outcome: Outcome, events: Array[BattleEvent]) -> void:
	_outcome = outcome
	_state = State.OVER
	var ended := BattleEvent.new(BattleEvent.Kind.BATTLE_ENDED, BattleEvent.SideId.PLAYER)
	ended.outcome = _outcome
	ended.trainer_name = _foe.trainer_name
	events.append(ended)


## Fin du tour (le combat continue) : drain de Vampigraine, puis envoi des remplaçants.
func _end_turn(events: Array[BattleEvent]) -> void:
	for side: BattleSide in [_player, _foe]:
		_drain_seed(side, events)
		if _state == State.OVER:
			return
	for side: BattleSide in [_foe, _player]:
		if side.active.pokemon.is_fainted():
			_send_out(side, events)


## Vampigraine en fin de tour : le Pokémon de [param side], s'il porte une graine et tient
## debout, perd sa fraction de PV max (au moins 1) au profit du Pokémon d'en face, sauf si
## celui-ci est K.O. (rien ne se passe alors).
func _drain_seed(side: BattleSide, events: Array[BattleEvent]) -> void:
	var seeded := side.active
	var other_side := _foe if side == _player else _player
	var other := other_side.active.pokemon
	if not seeded.is_seeded() or seeded.pokemon.is_fainted() or other.is_fainted():
		return
	var victim := seeded.pokemon
	var drained := _event(BattleEvent.Kind.DRAINED, side)
	drained.amount = victim.take_damage(maxi(floori(victim.max_hp() * seeded.seed_fraction), 1))
	drained.hp = victim.hp
	var before := other.hp
	other.hp = mini(other.hp + drained.amount, other.max_hp())
	drained.healed = other.hp - before
	drained.healed_hp = other.hp
	events.append(drained)
	if victim.is_fainted():
		_faint(side, events)
		_check_end(other_side, events)


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
		_apply_effect(effect, move_id, side, target_side, events)
	if target.pokemon.is_fainted():
		_faint(target_side, events)
	if user.pokemon.is_fainted():
		_faint(side, events)
	_check_end(side, events)


func _apply_effect(effect: MoveEffect, move_id: StringName, side: BattleSide,
		target_side: BattleSide, events: Array[BattleEvent]) -> void:
	match effect.kind:
		MoveEffect.Kind.SEED:
			var target := target_side.active
			if target.pokemon.is_fainted():
				return
			if target.has_any_type(effect.immune_types):
				var immune := _event(BattleEvent.Kind.NO_EFFECT, target_side)
				immune.move_id = move_id
				events.append(immune)
			elif target.is_seeded():
				# Déjà une graine : la capacité échoue (même message qu'un raté).
				_append_missed(side, move_id, events)
			else:
				target.seed_fraction = effect.fraction
				events.append(_event(BattleEvent.Kind.SEEDED, target_side))
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
		_finish(Outcome.WIN if acting == _player else Outcome.LOSS, events)
	else:
		_finish(Outcome.WIN if foe_out else Outcome.LOSS, events)


func _send_out(side: BattleSide, events: Array[BattleEvent]) -> void:
	side.send_out(side.party.first_able(), _data)
	# Participants (XP) : un nouvel adversaire les remet à zéro (le Pokémon du joueur en jeu,
	# s'il tient debout) ; un nouveau Pokémon du joueur s'y ajoute.
	if side == _foe:
		_participants.clear()
		if _player.active != null and not _player.active.pokemon.is_fainted():
			_participants.append(_player.active.pokemon)
	elif not _participants.has(side.active.pokemon):
		_participants.append(side.active.pokemon)
	var sent := _event(BattleEvent.Kind.SENT_OUT, side)
	sent.trainer_name = side.trainer_name
	events.append(sent)


## K.O. du Pokémon en jeu de [param side] ; un adversaire K.O. rapporte de l'XP (§2.3).
func _faint(side: BattleSide, events: Array[BattleEvent]) -> void:
	events.append(_event(BattleEvent.Kind.FAINTED, side))
	if side == _foe and _rules != null and _rules.gives_exp:
		_award_exp(side.active.pokemon, events)


## XP de [param foe] (K.O.) partagée entre les participants encore debout (Q24).
func _award_exp(foe: Pokemon, events: Array[BattleEvent]) -> void:
	var standing: Array[Pokemon] = []
	for pokemon: Pokemon in _participants:
		if not pokemon.is_fainted():
			standing.append(pokemon)
	if standing.is_empty():
		return
	var shares := ExpCalc.split(ExpCalc.amount(foe, _data, _rules.exp_multiplier),
		standing.size())
	for i: int in standing.size():
		_grant_exp(standing[i], shares[i], events)


## Donne [param amount] XP à [param pokemon] et écrit les événements : une tranche
## EXP_GAINED par niveau traversé, LEVEL_UP, puis MOVE_LEARNED ou MOVE_FORGET_OFFERED pour
## chaque capacité de ce niveau.
func _grant_exp(pokemon: Pokemon, amount: int, events: Array[BattleEvent]) -> void:
	var species := _data.get_species(pokemon.species_id)
	if species == null or amount <= 0:
		return
	var rate := species.growth_rate
	# XP réellement gagnée (plafonnée au niveau 100).
	var total := mini(amount, ExpCurve.exp_for_level(rate, ExpCurve.MAX_LEVEL)
		- pokemon.experience)
	var remaining := total
	while remaining > 0:
		var gained := remaining
		if pokemon.level < ExpCurve.MAX_LEVEL:
			# Au moins 1 : une XP incohérente (déjà au-delà du seuil) ne bloque pas la boucle.
			gained = clampi(ExpCurve.exp_for_level(rate, pokemon.level + 1)
				- pokemon.experience, 1, remaining)
		var slice := _pokemon_event(BattleEvent.Kind.EXP_GAINED, BattleEvent.SideId.PLAYER,
			pokemon)
		slice.amount = total if remaining == total else 0
		slice.exp_from = ExpCalc.progress(pokemon, _data)
		var steps := pokemon.gain_exp(gained, _data)
		remaining -= gained
		slice.exp_to = 1.0 if not steps.is_empty() else ExpCalc.progress(pokemon, _data)
		events.append(slice)
		for step: LevelUp in steps:
			events.append(_pokemon_event(BattleEvent.Kind.LEVEL_UP, BattleEvent.SideId.PLAYER,
				pokemon))
			for move_id: StringName in step.moves:
				_offer_move(pokemon, move_id, events)


## Capacité apprise par niveau : emplacement libre → apprise (MOVE_LEARNED) ; 4 capacités →
## MOVE_FORGET_OFFERED, rien ne change.
func _offer_move(pokemon: Pokemon, move_id: StringName, events: Array[BattleEvent]) -> void:
	var kind := BattleEvent.Kind.MOVE_LEARNED
	match pokemon.learn_move(move_id, _data):
		Pokemon.LearnResult.LEARNED:
			kind = BattleEvent.Kind.MOVE_LEARNED
		Pokemon.LearnResult.NEEDS_FORGET:
			kind = BattleEvent.Kind.MOVE_FORGET_OFFERED
		_:
			return
	var event := _pokemon_event(kind, BattleEvent.SideId.PLAYER, pokemon)
	event.move_id = move_id
	events.append(event)


## Événement sur le Pokémon en jeu de [param side], avec son état actuel.
func _event(kind: BattleEvent.Kind, side: BattleSide) -> BattleEvent:
	return _pokemon_event(kind, BattleEvent.SideId.PLAYER if side.is_player
		else BattleEvent.SideId.FOE, side.active.pokemon)


## Événement sur [param pokemon] (camp [param side_id]), avec son état actuel.
func _pokemon_event(kind: BattleEvent.Kind, side_id: BattleEvent.SideId,
		pokemon: Pokemon) -> BattleEvent:
	var event := BattleEvent.new(kind, side_id)
	event.pokemon_name = pokemon.display_name(_data)
	event.species_id = pokemon.species_id
	event.party_index = (_player if side_id == BattleEvent.SideId.PLAYER else _foe) \
		.party.index_of(pokemon)
	event.level = pokemon.level
	event.gender = pokemon.gender
	event.hp = pokemon.hp
	event.max_hp = pokemon.max_hp()
	return event
