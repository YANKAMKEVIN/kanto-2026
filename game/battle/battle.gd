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
## l'adversaire dont le Pokémon est K.O. envoie le suivant ; le joueur choisit le sien
## (jalon 7, [constant State.REPLACING]). Sans PP, seule Lutte est permise
## ([constant BattleAction.STRUGGLE]) : sans type, recul d'¼ des PV max du lanceur.
## Ordre des tirages : IA adverse (pick_index ; « smart » seulement à égalité, [BattleAI]),
## égalité de Vitesse, puis pour chaque
## action ceux de [DamageCalc] (ou la seule précision pour une capacité de statut) et un
## roll(100) par effet de [member MoveEffect.chance] < 100 (pas de tirage si sa cible est déjà
## K.O.). La fin de tour (Vampigraine, poison) et l'XP ne tirent rien.
##
## Fin de tour (jalon 5 Q28) : si le combat continue, chaque Pokémon porteur d'une graine de
## Vampigraine (le joueur d'abord, puis l'adversaire) perd la fraction de ses PV max fixée par
## la capacité (au moins 1) au profit du Pokémon d'en face, sauf si celui-ci est K.O. ; puis
## les remplaçants (voir plus haut).
##
## Poison (jalon 9 §2.1, [StatusRules]) : effet [code]status[/code] d'une capacité
## ([method _apply_effect]) ; en fin de tour, pour chaque camp (le joueur d'abord), la graine
## puis le poison : STATUS_DAMAGED (1/8 des PV max, au moins 1) ; un K.O. par le poison suit le
## chemin du K.O. (FAINTED, XP, fin du combat ou remplacement). Tout K.O. efface le statut
## ([method _faint]). Capture : [method StatusRules.catch_bonus] de la cible. Antidote :
## ITEM_USED puis STATUS_CURED ([method ItemUse.cure]).
##
## Statuts du J11 (`jalon-11.md` §2.2, dossier 14 §3.1, [StatusRules]) : avant de lancer sa
## capacité, chaque Pokémon passe [method StatusRules.check_act] — réveil ou dégel
## (STATUS_ENDED, il agit), ou empêchement (STATUS_PREVENTED : paralysie totale, sommeil, gel ;
## aucun PP dépensé). Tirages : roll(100) pour un Pokémon paralysé ou gelé, avant ceux de sa
## capacité ; roll(3) pour la durée du sommeil quand il est infligé. Vitesse ÷ 2 d'un Pokémon
## paralysé pour l'ordre ; brûlure : 1/16 en fin de tour (avec le poison, même place) et
## dégâts physiques ÷ 2 ([DamageCalc]). Une capacité Feu qui touche un Pokémon gelé le dégèle.
## Capacité de statut sans effet sur le type de la cible (Cage-Éclair sur Sol) : NO_EFFECT ;
## sur une cible qui a déjà un autre statut : FAILED (« Mais ça échoue ! »).
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
##
## Changement de Pokémon (jalon 7, jalon-07.md §15.23) : [code]BattleAction.switch_to(index)
## [/code] est légale (sauvage comme dresseur) si [method check_switch] l'accepte : ni le
## Pokémon actif, ni un K.O. Jouée avant les capacités (priorité du changement, comme
## Rouge/Bleu) : WITHDRAWN (le sortant), SENT_OUT (le nouveau, ses niveaux de statistiques à
## zéro ; le sortant perd les siens et sa graine), puis l'adversaire joue son tour contre le
## nouveau. Aucun tirage propre. Le nouveau devient participant (XP) ; le sortant le reste.
## K.O. du Pokémon du joueur : en fin de tour, s'il lui reste un Pokémon valide, le moteur
## passe en [constant State.REPLACING] (l'adversaire, lui, envoie [method Party.first_able]) ;
## le joueur choisit par [method replace] (SENT_OUT, puis de nouveau CHOOSING ; ni retour, ni
## fuite). L'ordre de l'équipe ne change jamais.
##
## Changement de l'adversaire (jalon 13, dossier 16 §14, [AiSwitchRule]) : quand son IA rend
## [code]BattleAction.switch_to(index)[/code] (Dresseur « switch », au plus une fois), il passe
## avant les capacités : WITHDRAWN (camp adverse, nom du Dresseur), SENT_OUT du nouveau ; le
## Dresseur ne lance rien ce tour (tour consommé), le joueur agit contre le nouveau, puis la fin
## de tour. Le rappelé garde PV et statut (objet [Pokemon]) et perd ce que porte son [Battler]
## (niveaux, confusion, graine, Puissance, Patience) ; les participants (XP) repartent du
## Pokémon du joueur en jeu. Aucun tirage propre ; jamais pendant une action imposée.
## Jalon 12 (`jalon-12.md` §2.10, dossier 15 C-1 à C-3 ; fonctions en fin de fichier) : drain
## (DRAINED_HP après les dégâts), piège (TRAPPED ; fin de tour après la graine et le statut :
## TRAP_DAMAGED, TRAP_ENDED ; fuite et changement refusés par [method is_legal],
## [method is_player_trapped]), Entrave (MOVE_DISABLED ; capacité exclue de
## [method get_usable_moves], [method get_disabled_move] ; décompte en fin de tour, DISABLE_ENDED),
## Repos (RESTED, [method StatusRules.apply_rest]), Destruction / Explosion (SELF_KO : le camp du
## lanceur perd si les deux derniers Pokémon tombent ensemble), Sonicboom (dégâts fixes
## « value »). Tirages ajoutés : range_int des tours du piège, après ceux des dégâts. Fin de tour,
## pour chaque camp (le joueur d'abord) : graine, statut, piège, Entrave.
##
## « Charge puis frappe » (jalon 14, `jalon-14.md` §2.3, [ChargeRules]) : au tour 1, MOVE_USED
## (PP −1) puis CHARGE_STARTED, aucun dégât ; au tour 2, action imposée (comme Patience, ni
## changement, ni Sac, ni fuite ; l'IA adverse n'est pas consultée) : CHARGE_RELEASED, MOVE_USED
## sans PP, puis la frappe ordinaire — ou CHARGE_BROKEN si le Pokémon ne peut pas agir ou était
## endormi ou gelé. Invulnérable (Tunnel) : toute capacité qui le vise donne DODGED (PP dépensé),
## la riposte de Patience aussi ; une Ball donne BALL_BLOCKED (l'adversaire joue son tour).
## Téléport (jalon 14 §2.5) : contre un Dresseur, NOTHING_HAPPENED ; en combat sauvage,
## TELEPORTED puis BATTLE_ENDED ([constant Outcome.FLED] pour le joueur,
## [constant Outcome.FOE_FLED] pour le sauvage : ni XP, ni capture).

## REPLACING (jalon 7) : le Pokémon du joueur est K.O., il doit en choisir un autre
## ([method replace]) ; ajouté en fin d'enum.
enum State { READY, CHOOSING, OVER, REPLACING }
## Réponse de [method check_switch] : OK, ou la raison du refus.
enum SwitchCheck { OK, NO_POKEMON, FAINTED, ACTIVE }
## FOE_FLED (jalon 14) : le Pokémon sauvage s'est enfui (Téléport) ; ajouté en fin d'enum.
enum Outcome { NONE, WIN, LOSS, FLED, CAUGHT, FOE_FLED }

const STRUGGLE_ID: StringName = &"struggle"
## Patience (CT34, jalon 11) : capacité dont la riposte est un DAMAGE de ce nom.
const BIDE_ID: StringName = &"bide"
## Pas de capacité imposée ([method get_locked_move]).
const NO_LOCK: int = -1
## Confusion (jalon 11, dossier 14 §3.2, défauts) : 1 à 4 tours, 33 % de se frapper.
const CONFUSION_MIN_TURNS: int = 1
const CONFUSION_MAX_TURNS: int = 4
const CONFUSION_HIT_CHANCE: int = 33

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
## Pokémon qui ont déjà tenté d'agir ce tour-ci (apeurement, jalon 11).
var _acted: Array[Battler] = []
## Dégâts portés par la dernière capacité offensive ([method _strike]) : drain (jalon 12).
var _strike_damage: int = 0


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


## Emplacement de la capacité imposée au Pokémon du joueur (Patience, tours 2 et 3 ; tour 2
## d'une charge, jalon 14 : le joueur ne choisit rien, la présentation soumet
## [code]BattleAction.move(index)[/code] sans attendre), ou [constant NO_LOCK].
func get_locked_move() -> int:
	if _player.active == null or not _player.active.is_action_locked():
		return NO_LOCK
	return _player.active.locked_slot()


## Vrai si [param action] est permise au joueur maintenant. Pendant une Patience, seule l'action
## imposée l'est ([method get_locked_move]).
func is_legal(action: BattleAction) -> bool:
	if _state != State.CHOOSING or action == null:
		return false
	var locked := get_locked_move()
	if locked != NO_LOCK:
		return action.kind == BattleAction.Kind.MOVE and action.move_index == locked
	if _refused_by_trap(action):
		return false
	if action.kind == BattleAction.Kind.RUN:
		return _rules != null and _rules.can_flee
	if action.is_heal():
		return _is_legal_heal(action)
	if action.kind == BattleAction.Kind.SWITCH:
		return check_switch(action.target) == SwitchCheck.OK
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


## Le Pokémon [param party_index] de l'équipe du joueur peut-il entrer en jeu ? OK, ou la
## raison : pas de Pokémon à cette place, K.O., ou déjà en jeu. Ne regarde pas l'état du
## combat ([method is_legal] et [method replace] le font).
func check_switch(party_index: int) -> SwitchCheck:
	var pokemon := _player.party.get_at(party_index)
	if pokemon == null:
		return SwitchCheck.NO_POKEMON
	if pokemon.is_fainted():
		return SwitchCheck.FAINTED
	if _player.active != null and _player.active.pokemon == pokemon:
		return SwitchCheck.ACTIVE
	return SwitchCheck.OK


## Vrai si le Pokémon du joueur est K.O. et qu'il doit en choisir un autre ([method replace]).
func needs_replacement() -> bool:
	return _state == State.REPLACING


## Envoie le Pokémon [param party_index] à la place du Pokémon du joueur K.O. (hors tour :
## aucun tirage, l'adversaire ne joue pas) : SENT_OUT, puis le combat attend de nouveau un
## choix. Tableau vide (push_error) si aucun remplacement n'est attendu ou si
## [method check_switch] refuse ce Pokémon.
func replace(party_index: int) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	if _state != State.REPLACING or check_switch(party_index) != SwitchCheck.OK:
		push_error("Battle : remplacement refusé (état %s, place %d)"
			% [State.find_key(_state), party_index])
		return events
	_send_out(_player, events, _player.party.get_at(party_index))
	_state = State.CHOOSING
	return events


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
	_acted.clear()
	var started := BattleEvent.new(BattleEvent.Kind.TURN_STARTED, BattleEvent.SideId.PLAYER)
	started.turn = _turn
	events.append(started)
	if action.kind == BattleAction.Kind.RUN:
		_attempt_flee(events)
		return events
	if action.is_heal():
		_use_heal(action, events)
		return events
	if action.kind == BattleAction.Kind.SWITCH:
		_switch(action.target, events)
		return events
	if action.kind == BattleAction.Kind.ITEM:
		_throw_ball(action.item_id, events)
		return events
	var foe_action := _foe_action()
	if foe_action.kind == BattleAction.Kind.SWITCH:
		_foe_switch(foe_action.target, events)
		_execute(_player, action, events)
		if _state == State.OVER:
			return events
		_end_turn(events)
		return events
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
	if _ball_blocked(item, events):
		return
	var target := _foe.active.pokemon
	var species := _data.get_species(target.species_id)
	var thrown := _event(BattleEvent.Kind.BALL_THROWN, _foe)
	thrown.item_id = item_id
	thrown.item_name = item.name
	events.append(thrown)
	var result := CaptureCalc.throw_ball(target.max_hp(), target.hp,
		species.catch_rate if species != null else 1, item.catch_bonus, _rng,
		StatusRules.catch_bonus(target.status))
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
## l'équipe (joué avant les capacités, §3.4) : ITEM_USED (PV rendus, 0 pour un Antidote), puis
## STATUS_CURED si un statut a été soigné (jalon 9), puis l'adversaire joue son tour.
func _use_heal(action: BattleAction, events: Array[BattleEvent]) -> void:
	var item := _rules.items.get_item(action.item_id)
	var pokemon := _player.party.get_at(action.target)
	var amount := ItemUse.restore(item, pokemon)
	var cured := ItemUse.cure(item, pokemon)
	var used := _pokemon_event(BattleEvent.Kind.ITEM_USED, BattleEvent.SideId.PLAYER, pokemon)
	used.item_id = action.item_id
	used.item_name = item.name
	used.amount = amount
	events.append(used)
	if cured != StatusRules.NONE:
		var cured_event := _pokemon_event(BattleEvent.Kind.STATUS_CURED,
			BattleEvent.SideId.PLAYER, pokemon)
		cured_event.status = cured
		events.append(cured_event)
	_foe_turn_alone(events)


## Changement volontaire (joué avant les capacités) : WITHDRAWN, SENT_OUT du Pokémon
## [param party_index], puis l'adversaire joue son tour contre lui.
func _switch(party_index: int, events: Array[BattleEvent]) -> void:
	events.append(_event(BattleEvent.Kind.WITHDRAWN, _player))
	_send_out(_player, events, _player.party.get_at(party_index))
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
	var foe_action := _foe_action()
	if _foe.active.pokemon.is_fainted():
		return
	if foe_action.kind == BattleAction.Kind.SWITCH:
		_foe_switch(foe_action.target, events)
		_end_turn(events)
		return
	_execute(_foe, foe_action, events)
	if _state == State.OVER:
		return
	_end_turn(events)


## Action de l'adversaire : imposée pendant sa Patience ou sa charge (aucun tirage), sinon celle
## de son IA. Un changement que le moteur refuse (combat sauvage, place invalide) est remplacé
## par une capacité (l'IA ne change plus).
func _foe_action() -> BattleAction:
	if _foe.active != null and _foe.active.is_action_locked():
		return BattleAction.move(_foe.active.locked_slot())
	var action := _foe.ai.choose(_foe, _player, _rng, _data)
	if action.kind == BattleAction.Kind.SWITCH and not _foe_can_switch_to(action.target):
		push_error("Battle : changement adverse refusé (place %d)" % action.target)
		return _foe.ai.choose(_foe, _player, _rng, _data)
	return action


## Le Dresseur adverse peut-il envoyer le Pokémon [param party_index] ? Jamais en combat
## sauvage ; ni le Pokémon en jeu, ni un K.O.
func _foe_can_switch_to(party_index: int) -> bool:
	var pokemon := _foe.party.get_at(party_index)
	return not _foe.trainer_name.is_empty() and (_rules == null or not _rules.wild) \
		and pokemon != null and not pokemon.is_fainted() and pokemon != _foe.active.pokemon


## Changement de l'adversaire (joué avant les capacités) : WITHDRAWN (« {trainer} rappelle … »),
## puis SENT_OUT du Pokémon [param party_index].
func _foe_switch(party_index: int, events: Array[BattleEvent]) -> void:
	var withdrawn := _event(BattleEvent.Kind.WITHDRAWN, _foe)
	withdrawn.trainer_name = _foe.trainer_name
	events.append(withdrawn)
	_send_out(_foe, events, _foe.party.get_at(party_index))


## Fin du combat sur [param outcome] : BATTLE_ENDED, plus aucun choix.
func _finish(outcome: Outcome, events: Array[BattleEvent]) -> void:
	_outcome = outcome
	_state = State.OVER
	var ended := BattleEvent.new(BattleEvent.Kind.BATTLE_ENDED, BattleEvent.SideId.PLAYER)
	ended.outcome = _outcome
	ended.trainer_name = _foe.trainer_name
	events.append(ended)


## Fin du tour (le combat continue) : pour chaque camp (le joueur d'abord), drain de
## Vampigraine puis dégâts du poison ; puis l'adversaire envoie son remplaçant ; un joueur dont
## le Pokémon est K.O. devra choisir le sien (REPLACING).
func _end_turn(events: Array[BattleEvent]) -> void:
	_player.active.flinched = false
	_foe.active.flinched = false
	for side: BattleSide in [_player, _foe]:
		_drain_seed(side, events)
		if _state == State.OVER:
			return
		_status_damage(side, events)
		if _state == State.OVER:
			return
		_trap_damage(side, events)
		if _state == State.OVER:
			return
		_disable_countdown(side, events)
	if _foe.active.pokemon.is_fainted():
		_send_out(_foe, events)
	if _player.active.pokemon.is_fainted():
		_state = State.REPLACING


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


## Statut à dégâts en fin de tour ([method StatusRules.end_turn_damage]) : le Pokémon de
## [param side], s'il tient debout et est empoisonné, perd ses PV (STATUS_DAMAGED) ; K.O. →
## [method _faint] et peut-être la fin du combat.
func _status_damage(side: BattleSide, events: Array[BattleEvent]) -> void:
	var victim := side.active.pokemon
	var amount := StatusRules.end_turn_damage(victim)
	if amount <= 0:
		return
	var damaged := _event(BattleEvent.Kind.STATUS_DAMAGED, side)
	damaged.status = victim.status
	damaged.amount = victim.take_damage(amount)
	damaged.hp = victim.hp
	events.append(damaged)
	if victim.is_fainted():
		_faint(side, events)
		_check_end(_foe if side == _player else _player, events)


func _player_goes_second(player_action: BattleAction, foe_action: BattleAction) -> bool:
	var player_priority := _priority(_player, player_action)
	var foe_priority := _priority(_foe, foe_action)
	if player_priority != foe_priority:
		return foe_priority > player_priority
	var player_speed := _speed(_player)
	var foe_speed := _speed(_foe)
	if player_speed != foe_speed:
		return foe_speed > player_speed
	return _rng.roll(2) == 2


## Vitesse effective du Pokémon en jeu de [param side] pour l'ordre d'action : niveaux de
## statistiques compris, ÷ 2 s'il est paralysé (jalon 11, [StatusRules]).
func _speed(side: BattleSide) -> int:
	return floori(side.active.effective_stat(&"spe")
		* StatusRules.speed_multiplier(side.active.pokemon.status))


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
	_acted.append(user)
	if _blocked_by_disable(side, action, events):
		return
	# Patience : s'endormir ou geler la rompt, même si le Pokémon se réveille ou dégèle ici.
	var status_before := user.pokemon.status
	var bide_frozen := user.is_biding() and (user.pokemon.status == StatusRules.SLEEP
		or user.pokemon.status == StatusRules.FREEZE)
	var can_act := _can_act(side, events)
	var charge_broken := user.is_charging() and ChargeRules.breaks_charge(status_before, can_act)
	if not can_act or bide_frozen or charge_broken:
		_break_bide(side, events)
		_break_charge(side, events)
		return
	if user.is_biding():
		_continue_bide(side, target_side, events)
		return
	var released := _release_charge(side, events)
	var used := _event(BattleEvent.Kind.MOVE_USED, side)
	used.move_id = move_id
	if action.move_index == BattleAction.STRUGGLE:
		used.pp = -1
	else:
		var slot := user.pokemon.moves[action.move_index]
		if not released:
			slot.use()
		used.pp = slot.pp
	events.append(used)
	user.last_move_slot = action.move_index
	if not released and _start_charge(side, action, move, events):
		return
	if _dodged(target_side, move, events):
		_self_ko(move, side, target_side, events)
		return
	if move.is_damaging():
		if not _strike(side, target_side, move, events):
			_self_ko(move, side, target_side, events)
			return
	elif not DamageCalc.accuracy_check(user, target, move, _rng):
		_append_missed(side, move_id, events)
		_self_ko(move, side, target_side, events)
		return
	for effect: MoveEffect in move.effects:
		_apply_effect(effect, move, side, target_side, events)
	if _self_ko(move, side, target_side, events):
		return
	if target.pokemon.is_fainted():
		_faint(target_side, events)
	if user.pokemon.is_fainted():
		_faint(side, events)
	_check_end(side, events)


## Le lanceur peut-il agir ? Dans l'ordre (`jalon-11.md` §2.2) : statut durable
## ([method StatusRules.check_act] : réveil ou dégel → STATUS_ENDED et il agit ; paralysie
## totale, sommeil, gel → STATUS_PREVENTED), apeurement (FLINCHED), confusion (CONFUSION_ENDED
## et il agit ; sinon CONFUSION_CHECK puis 33 % de se frapper : HURT_ITSELF). Faux : rien
## n'est lancé, aucun PP dépensé. Un Pokémon endormi ne sort pas de sa confusion.
func _can_act(side: BattleSide, events: Array[BattleEvent]) -> bool:
	var battler := side.active
	var pokemon := battler.pokemon
	var status := pokemon.status
	var act := StatusRules.check_act(pokemon, _rng)
	if act == StatusRules.Act.WOKE_UP or act == StatusRules.Act.THAWED:
		var ended := _event(BattleEvent.Kind.STATUS_ENDED, side)
		ended.status = status
		events.append(ended)
	elif StatusRules.prevents_action(act):
		var prevented := _event(BattleEvent.Kind.STATUS_PREVENTED, side)
		prevented.status = status
		events.append(prevented)
		return false
	if battler.flinched:
		events.append(_event(BattleEvent.Kind.FLINCHED, side))
		return false
	if battler.is_confused():
		battler.confusion_turns -= 1
		if battler.confusion_turns == 0:
			events.append(_event(BattleEvent.Kind.CONFUSION_ENDED, side))
			return true
		events.append(_event(BattleEvent.Kind.CONFUSION_CHECK, side))
		if _rng.roll(100) <= CONFUSION_HIT_CHANCE:
			var hurt := _event(BattleEvent.Kind.HURT_ITSELF, side)
			hurt.amount = pokemon.take_damage(DamageCalc.confusion_damage(battler, _rng))
			hurt.hp = pokemon.hp
			events.append(hurt)
			if pokemon.is_fainted():
				_faint(side, events)
				_check_end(_foe if side == _player else _player, events)
			return false
	return true


## Patience (CT34, dossier 14 §6.3) : tours 2 et 3 de l'action imposée, sans MOVE_USED ni PP.
## Tour 2 : BIDE_STORING. Tour 3 : BIDE_UNLEASHED, puis 2 × les dégâts directs reçus depuis la
## préparation, au plus les PV de la cible (sans type, statistiques ni précision : un DAMAGE
## « bide »), ou FAILED si rien n'a été reçu.
func _continue_bide(side: BattleSide, target_side: BattleSide, events: Array[BattleEvent]) -> void:
	var user := side.active
	if user.bide_stage == 1:
		user.bide_stage = 2
		events.append(_event(BattleEvent.Kind.BIDE_STORING, side))
		return
	events.append(_event(BattleEvent.Kind.BIDE_UNLEASHED, side))
	var stock := user.bide_stock
	user.clear_bide()
	var target := target_side.active
	if stock <= 0 or target.pokemon.is_fainted():
		_append_failed(side, BIDE_ID, events)
		return
	if target.invulnerable:
		events.append(_event(BattleEvent.Kind.DODGED, target_side))
		return
	var damage := _event(BattleEvent.Kind.DAMAGE, target_side)
	damage.move_id = BIDE_ID
	damage.amount = target.pokemon.take_damage(mini(2 * stock, target.pokemon.hp))
	damage.hp = target.pokemon.hp
	events.append(damage)
	_record_hit(target_side, damage.amount)
	if target.pokemon.is_fainted():
		_faint(target_side, events)
	_check_end(side, events)


## Rupture de la Patience du Pokémon de [param side] (s'il en avait une) : BIDE_BROKEN, sauf
## s'il est K.O. (le K.O. suffit) ; le stock est perdu.
func _break_bide(side: BattleSide, events: Array[BattleEvent]) -> void:
	var user := side.active
	if user == null or not user.is_biding():
		return
	user.clear_bide()
	if not user.pokemon.is_fainted():
		events.append(_event(BattleEvent.Kind.BIDE_BROKEN, side))


## Coup direct d'une capacité adverse reçu par le Pokémon de [param target_side] : compté dans
## sa Patience s'il en a une (poison, brûlure, graine, recul, confusion n'y passent pas).
func _record_hit(target_side: BattleSide, amount: int) -> void:
	var target := target_side.active
	if target != null and target.is_biding():
		target.bide_stock += amount


## Les coups d'une capacité offensive (une capacité HITS en porte plusieurs : précision au
## premier seulement ; nombre tiré après le premier coup, roll(8) pour 2 à 5 ; arrêt au K.O.).
## Faux si elle rate ou n'a aucun effet (rien d'autre ne se passe).
func _strike(side: BattleSide, target_side: BattleSide, move: MoveData,
		events: Array[BattleEvent]) -> bool:
	var user := side.active
	var target := target_side.active
	var hits_effect := move.hits_effect()
	var hits := 1
	var done := 0
	_strike_damage = 0
	while done < hits:
		var result := DamageCalc.compute(user, target, move, _data.get_type_chart(), _rng,
			done == 0)
		if done == 0:
			if not result.hit:
				_append_missed(side, move.id, events)
				return false
			if result.effectiveness == 0.0:
				var immune := _event(BattleEvent.Kind.NO_EFFECT, target_side)
				immune.move_id = move.id
				events.append(immune)
				return false
			if hits_effect != null:
				hits = _hit_count(hits_effect)
		var damage := _event(BattleEvent.Kind.DAMAGE, target_side)
		damage.move_id = move.id
		damage.amount = target.pokemon.take_damage(result.amount)
		damage.hp = target.pokemon.hp
		damage.effectiveness = result.effectiveness
		damage.critical = result.critical
		events.append(damage)
		_record_hit(target_side, damage.amount)
		_strike_damage += damage.amount
		done += 1
		_thaw_by_fire(move, target_side, events)
		if target.pokemon.is_fainted():
			break
	if hits_effect != null:
		var multi := _event(BattleEvent.Kind.MULTI_HIT, target_side)
		multi.move_id = move.id
		multi.amount = done
		events.append(multi)
	return true


## Nombre de coups d'un effet HITS : fixe (2 et 2), ou 2 à 5 (roll(8) : 1–3 → 2, 4–6 → 3,
## 7 → 4, 8 → 5).
func _hit_count(effect: MoveEffect) -> int:
	if effect.min_hits == effect.max_hits:
		return effect.min_hits
	var draw := _rng.roll(8)
	if draw <= 3:
		return 2
	if draw <= 6:
		return 3
	return 4 if draw == 7 else 5


## Une capacité Feu qui touche un Pokémon gelé le dégèle (STATUS_ENDED ; jalon 11).
func _thaw_by_fire(move: MoveData, target_side: BattleSide, events: Array[BattleEvent]) -> void:
	var target := target_side.active.pokemon
	if move.typeless or move.type != &"fire" or target.is_fainted() \
			or target.status != StatusRules.FREEZE:
		return
	target.cure_status()
	var ended := _event(BattleEvent.Kind.STATUS_ENDED, target_side)
	ended.status = StatusRules.FREEZE
	events.append(ended)


func _apply_effect(effect: MoveEffect, move: MoveData, side: BattleSide,
		target_side: BattleSide, events: Array[BattleEvent]) -> void:
	var move_id := move.id
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
		MoveEffect.Kind.STATUS:
			_inflict_status(effect, move, target_side, events)
		MoveEffect.Kind.CONFUSION:
			_confuse(effect, move, side, target_side, events)
		MoveEffect.Kind.FLINCH:
			var target := target_side.active
			if target.pokemon.is_fainted():
				return
			if effect.chance < 100 and _rng.roll(100) > effect.chance:
				return
			if not _acted.has(target):
				target.flinched = true
		MoveEffect.Kind.CRIT_UP:
			if side.active.focused:
				_append_failed(side, move_id, events)
			else:
				side.active.focused = true
				events.append(_event(BattleEvent.Kind.FOCUSED, side))
		MoveEffect.Kind.FIXED_DAMAGE:
			var target := target_side.active
			if target.pokemon.is_fainted():
				return
			if not move.typeless \
					and _data.get_type_chart().multiplier(move.type, target.types) == 0.0:
				var immune := _event(BattleEvent.Kind.NO_EFFECT, target_side)
				immune.move_id = move_id
				events.append(immune)
				return
			var amount := side.active.pokemon.level if effect.mode == &"level" \
				else maxi(floori(target.pokemon.hp / 2.0), 1)
			if effect.mode == &"value":
				amount = effect.amount
			var damage := _event(BattleEvent.Kind.DAMAGE, target_side)
			damage.move_id = move_id
			damage.amount = target.pokemon.take_damage(amount)
			damage.hp = target.pokemon.hp
			events.append(damage)
			_record_hit(target_side, damage.amount)
		MoveEffect.Kind.HITS, MoveEffect.Kind.CHARGE:
			pass
		MoveEffect.Kind.BIDE:
			var user := side.active
			user.clear_bide()
			user.bide_stage = 1
			user.bide_slot = user.pokemon.move_index(move_id)
			events.append(_event(BattleEvent.Kind.BIDE_STARTED, side))
		MoveEffect.Kind.DRAIN:
			_drain_hp(effect, side, events)
		MoveEffect.Kind.TRAP:
			_trap(effect, move, side, target_side, events)
		MoveEffect.Kind.DISABLE:
			_disable(effect, move, side, target_side, events)
		MoveEffect.Kind.REST:
			_rest(move, side, events)
		MoveEffect.Kind.SELF_KO:
			pass
		MoveEffect.Kind.TELEPORT:
			_teleport(side, events)


## Effet [code]confusion[/code] (jalon 11) sur le Pokémon de [param target_side] : comme un
## statut (cible K.O. → rien ; chance tirée ; refus annoncé seulement par une capacité de
## statut : CONFUSION_UNCHANGED), 1 à 4 tours tirés (roll(4)) : CONFUSED.
func _confuse(effect: MoveEffect, move: MoveData, side: BattleSide, target_side: BattleSide,
		events: Array[BattleEvent]) -> void:
	var target := target_side.active
	if target.pokemon.is_fainted():
		return
	if effect.chance < 100 and _rng.roll(100) > effect.chance:
		return
	if target.is_confused():
		if not move.is_damaging():
			var unchanged := _event(BattleEvent.Kind.CONFUSION_UNCHANGED, target_side)
			unchanged.move_id = move.id
			events.append(unchanged)
		return
	target.confusion_turns = _rng.range_int(CONFUSION_MIN_TURNS, CONFUSION_MAX_TURNS)
	var confused := _event(BattleEvent.Kind.CONFUSED, target_side)
	confused.move_id = move.id
	events.append(confused)


## Effet [code]status[/code] (jalon 9 §2.1.2) sur le Pokémon de [param target_side]. Capacité
## de statut (Poudre Toxik) : immunité → NO_EFFECT, statut déjà présent → STATUS_UNCHANGED.
## Effet secondaire d'une attaque (Dard-Venin) : cible K.O. → rien (aucun tirage, comme les
## niveaux de statistiques) ; sinon roll(100) si [member MoveEffect.chance] < 100, puis un refus
## est silencieux. Réussite : le statut est posé, STATUS_INFLICTED.
func _inflict_status(effect: MoveEffect, move: MoveData, target_side: BattleSide,
		events: Array[BattleEvent]) -> void:
	var target := target_side.active
	if target.pokemon.is_fainted():
		return
	if effect.chance < 100 and _rng.roll(100) > effect.chance:
		return
	# Capacité de statut sans effet sur le type de la cible (Cage-Éclair sur Sol, jalon 11 [D]).
	if not move.is_damaging() and not move.typeless \
			and _data.get_type_chart().multiplier(move.type, target.types) == 0.0:
		var no_effect := _event(BattleEvent.Kind.NO_EFFECT, target_side)
		no_effect.move_id = move.id
		events.append(no_effect)
		return
	var check := StatusRules.can_inflict(effect.status, target.pokemon, target.types)
	if check == StatusRules.Inflict.OK:
		StatusRules.apply(effect.status, target.pokemon, _rng)
		var inflicted := _event(BattleEvent.Kind.STATUS_INFLICTED, target_side)
		inflicted.status = effect.status
		events.append(inflicted)
		return
	if move.is_damaging():
		return
	if check == StatusRules.Inflict.IMMUNE:
		var immune := _event(BattleEvent.Kind.NO_EFFECT, target_side)
		immune.move_id = move.id
		events.append(immune)
	elif check == StatusRules.Inflict.ALREADY and target.pokemon.status == effect.status:
		var unchanged := _event(BattleEvent.Kind.STATUS_UNCHANGED, target_side)
		unchanged.move_id = move.id
		unchanged.status = target.pokemon.status
		events.append(unchanged)
	elif check == StatusRules.Inflict.ALREADY:
		_append_failed(_foe if target_side == _player else _player, move.id, events)


## La capacité [param move_id] du lanceur ([param side]) échoue : FAILED (« Mais ça échoue ! »).
func _append_failed(side: BattleSide, move_id: StringName, events: Array[BattleEvent]) -> void:
	var failed := _event(BattleEvent.Kind.FAILED, side)
	failed.move_id = move_id
	events.append(failed)


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


## Met en jeu [param pokemon] pour [param side] (null : son premier Pokémon valide).
func _send_out(side: BattleSide, events: Array[BattleEvent], pokemon: Pokemon = null) -> void:
	side.send_out(pokemon if pokemon != null else side.party.first_able(), _data)
	_release_trap_of_other(side)
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


## K.O. du Pokémon en jeu de [param side] : son statut est effacé (jalon 9, règle actuelle) ;
## un adversaire K.O. rapporte de l'XP (§2.3).
func _faint(side: BattleSide, events: Array[BattleEvent]) -> void:
	side.active.pokemon.cure_status()
	side.active.clear_charge()
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
		var span := ExpCalc.level_span(pokemon, _data)
		slice.exp_points_from = span.x
		slice.exp_points_need = span.y
		var steps := pokemon.gain_exp(gained, _data)
		remaining -= gained
		slice.exp_to = 1.0 if not steps.is_empty() else ExpCalc.progress(pokemon, _data)
		slice.exp_points_to = span.y if not steps.is_empty() \
			else ExpCalc.level_span(pokemon, _data).x
		events.append(slice)
		for step: LevelUp in steps:
			var level_up := _pokemon_event(BattleEvent.Kind.LEVEL_UP, BattleEvent.SideId.PLAYER,
				pokemon)
			level_up.stat_gains = step.stat_gains.duplicate()
			# La barre du nouveau niveau (bilan) : là où elle repart, sur combien de points.
			var next_span := ExpCalc.level_span(pokemon, _data)
			level_up.exp_from = ExpCalc.progress(pokemon, _data)
			level_up.exp_points_from = next_span.x
			level_up.exp_points_need = next_span.y
			events.append(level_up)
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
	event.status = pokemon.status
	return event


# --- Jalon 12 : drain, piège, Entrave, Repos, Destruction (`jalon-12.md` §2.10) ----------

## Emplacement de la capacité du Pokémon du joueur bloquée par une Entrave (carte « BLOQUÉE »,
## T14), ou [constant NO_LOCK]. Elle est déjà exclue de [method get_usable_moves] et de
## [method is_legal].
func get_disabled_move() -> int:
	if _player.active == null or not _player.active.has_disabled_move():
		return NO_LOCK
	return _player.active.disabled_slot


## Vrai si le Pokémon du joueur est piégé (Ligotage…) : la fuite et le changement sont refusés
## par [method is_legal] (raison « Impossible de changer » sur les cartes de l'équipe,
## « Impossible de fuir ! » pour la fuite, sans tour perdu : la présentation ne soumet rien). Le
## remplacement après un K.O. ([method replace]) reste permis. [method can_flee] ne change pas
## (le bouton FUITE reste là ; c'est la réponse qui change).
func is_player_trapped() -> bool:
	return _player.active != null and _player.active.is_trapped()


## Piège : la fuite et le changement volontaire du joueur sont refusés.
func _refused_by_trap(action: BattleAction) -> bool:
	return is_player_trapped() and (action.kind == BattleAction.Kind.RUN
		or action.kind == BattleAction.Kind.SWITCH)


## Entrave : la capacité choisie a été bloquée plus tôt dans ce tour (le lanceur de l'Entrave a
## agi d'abord) → MOVE_DISABLED, rien n'est lancé, aucun PP. Vrai si l'action s'arrête là.
func _blocked_by_disable(side: BattleSide, action: BattleAction,
		events: Array[BattleEvent]) -> bool:
	var user := side.active
	if not user.has_disabled_move() or action.move_index != user.disabled_slot:
		return false
	var blocked := _event(BattleEvent.Kind.MOVE_DISABLED, side)
	blocked.move_id = user.pokemon.moves[user.disabled_slot].move_id
	events.append(blocked)
	return true


## Drain (Vampirisme) : le lanceur récupère [member MoveEffect.fraction] des dégâts portés (au
## moins 1, plafonné à ses PV max) : DRAINED_HP ; rien à PV pleins.
func _drain_hp(effect: MoveEffect, side: BattleSide, events: Array[BattleEvent]) -> void:
	var user := side.active.pokemon
	if user.is_fainted() or _strike_damage <= 0:
		return
	var before := user.hp
	user.hp = mini(user.hp + maxi(floori(_strike_damage * effect.fraction), 1), user.max_hp())
	if user.hp == before:
		return
	var drained := _event(BattleEvent.Kind.DRAINED_HP, side)
	drained.amount = user.hp - before
	events.append(drained)


## Piège : la cible (debout, pas déjà piégée) l'est pour [member MoveEffect.min_turns] à
## [member MoveEffect.max_turns] fins de tour (un range_int) : TRAPPED. Déjà piégée : la capacité
## n'a fait que ses dégâts, le compteur ne change pas.
func _trap(effect: MoveEffect, move: MoveData, side: BattleSide, target_side: BattleSide,
		events: Array[BattleEvent]) -> void:
	var target := target_side.active
	if target.pokemon.is_fainted() or target.is_trapped():
		return
	target.trap_turns = _rng.range_int(effect.min_turns, effect.max_turns)
	target.trap_move = move.id
	target.trap_fraction = effect.fraction
	target.trap_source = side.active
	var trapped := _event(BattleEvent.Kind.TRAPPED, target_side)
	trapped.move_id = move.id
	events.append(trapped)


## Piège en fin de tour (après la graine et le statut) : le Pokémon piégé de [param side] perd
## sa part de PV max (au moins 1) : TRAP_DAMAGED ; K.O. → chemin habituel ; dernière fin de
## tour → TRAP_ENDED juste après. Si le lanceur a quitté le terrain ou est K.O., le piège tombe
## sans un mot.
func _trap_damage(side: BattleSide, events: Array[BattleEvent]) -> void:
	var victim := side.active
	if not victim.is_trapped() or victim.pokemon.is_fainted():
		return
	var other_side := _foe if side == _player else _player
	if victim.trap_source != other_side.active or other_side.active.pokemon.is_fainted():
		victim.clear_trap()
		return
	var pokemon := victim.pokemon
	var damaged := _event(BattleEvent.Kind.TRAP_DAMAGED, side)
	damaged.move_id = victim.trap_move
	damaged.amount = pokemon.take_damage(maxi(floori(pokemon.max_hp() * victim.trap_fraction),
		1))
	damaged.hp = pokemon.hp
	events.append(damaged)
	victim.trap_turns -= 1
	if pokemon.is_fainted():
		_faint(side, events)
		_check_end(other_side, events)
		return
	if victim.trap_turns == 0:
		var ended := _event(BattleEvent.Kind.TRAP_ENDED, side)
		ended.move_id = victim.trap_move
		events.append(ended)
		victim.clear_trap()


## Un nouveau Pokémon de [param side] est en jeu : le Pokémon d'en face, s'il était piégé par
## l'ancien, est libéré (sans phrase).
func _release_trap_of_other(side: BattleSide) -> void:
	var other := (_foe if side == _player else _player).active
	if other != null and other.is_trapped() and other.trap_source != side.active:
		other.clear_trap()


## Entrave : bloque la dernière capacité lancée par la cible pour [member MoveEffect.min_turns]
## fins de tour (celle de l'Entrave comprise) : MOVE_DISABLED. Échoue (FAILED) si elle n'a encore
## rien lancé, a déjà une capacité bloquée, ou est en pleine Patience ou en pleine charge (J14).
func _disable(effect: MoveEffect, move: MoveData, side: BattleSide, target_side: BattleSide,
		events: Array[BattleEvent]) -> void:
	var target := target_side.active
	if target.pokemon.is_fainted():
		return
	var slot := target.last_move_slot
	if slot < 0 or slot >= target.pokemon.moves.size() or target.has_disabled_move() \
			or target.is_action_locked():
		_append_failed(side, move.id, events)
		return
	target.disabled_slot = slot
	target.disabled_turns = effect.min_turns
	var disabled := _event(BattleEvent.Kind.MOVE_DISABLED, target_side)
	disabled.move_id = target.pokemon.moves[slot].move_id
	events.append(disabled)


## Entrave en fin de tour : une fin de tour de moins ; à zéro, DISABLE_ENDED.
func _disable_countdown(side: BattleSide, events: Array[BattleEvent]) -> void:
	var battler := side.active
	if not battler.has_disabled_move() or battler.pokemon.is_fainted():
		return
	battler.disabled_turns -= 1
	if battler.disabled_turns > 0:
		return
	var ended := _event(BattleEvent.Kind.DISABLE_ENDED, side)
	ended.move_id = battler.pokemon.moves[battler.disabled_slot].move_id
	events.append(ended)
	battler.clear_disable()


## Repos ([method StatusRules.apply_rest]) : RESTED, ou FAILED à PV pleins ou déjà endormi.
func _rest(move: MoveData, side: BattleSide, events: Array[BattleEvent]) -> void:
	var user := side.active.pokemon
	var before := user.hp
	if not StatusRules.apply_rest(user):
		_append_failed(side, move.id, events)
		return
	var rested := _event(BattleEvent.Kind.RESTED, side)
	rested.amount = user.hp - before
	events.append(rested)


## Destruction, Explosion : si [param move] porte SELF_KO, le lanceur (qui a pu agir) perd ses
## derniers PV après la capacité, même ratée ou sans effet : SELF_KO, puis le FAINTED de la cible
## si elle tombe (XP : le lanceur, à 0 PV, n'en reçoit pas), puis le sien. Si les deux derniers
## Pokémon tombent ensemble, le camp du lanceur perd. Vrai si la capacité en porte un.
func _self_ko(move: MoveData, side: BattleSide, target_side: BattleSide,
		events: Array[BattleEvent]) -> bool:
	if move.effect_of(MoveEffect.Kind.SELF_KO) == null:
		return false
	var user := side.active.pokemon
	var self_ko := _event(BattleEvent.Kind.SELF_KO, side)
	self_ko.amount = user.take_damage(user.hp)
	self_ko.hp = user.hp
	events.append(self_ko)
	if target_side.active.pokemon.is_fainted():
		_faint(target_side, events)
	_faint(side, events)
	_check_end(target_side, events)
	return true


# --- Jalon 14 : « charge puis frappe » ([ChargeRules]) et Téléport --------------------------

## Tour 1 d'une capacité CHARGE (après MOVE_USED, PP dépensé) : la charge commence
## (CHARGE_STARTED, invulnérable si l'effet le dit), aucun dégât. Faux si [param move] n'a pas
## d'effet CHARGE (rien n'est fait).
func _start_charge(side: BattleSide, action: BattleAction, move: MoveData,
		events: Array[BattleEvent]) -> bool:
	var effect := move.charge_effect()
	if effect == null or action.move_index == BattleAction.STRUGGLE:
		return false
	side.active.charge_slot = action.move_index
	side.active.invulnerable = effect.invulnerable
	var started := _event(BattleEvent.Kind.CHARGE_STARTED, side)
	started.move_id = move.id
	events.append(started)
	return true


## Tour 2 : le Pokémon de [param side] sort de sa charge pour frapper (CHARGE_RELEASED, état
## effacé). Faux s'il ne chargeait rien.
func _release_charge(side: BattleSide, events: Array[BattleEvent]) -> bool:
	var user := side.active
	if not user.is_charging():
		return false
	var released := _event(BattleEvent.Kind.CHARGE_RELEASED, side)
	released.move_id = user.pokemon.moves[user.charge_slot].move_id
	user.clear_charge()
	events.append(released)
	return true


## Charge rompue au tour 2 (s'il en avait une) : CHARGE_BROKEN, sauf s'il est K.O. (le K.O.
## suffit) ; rien n'est frappé.
func _break_charge(side: BattleSide, events: Array[BattleEvent]) -> void:
	var user := side.active
	if user == null or not user.is_charging():
		return
	var move_id := user.pokemon.moves[user.charge_slot].move_id
	user.clear_charge()
	if not user.pokemon.is_fainted():
		var broken := _event(BattleEvent.Kind.CHARGE_BROKEN, side)
		broken.move_id = move_id
		events.append(broken)


## La cible de [param target_side], invulnérable, évite [param move] : DODGED (le PP est déjà
## dépensé), rien d'autre. Faux sinon.
func _dodged(target_side: BattleSide, move: MoveData, events: Array[BattleEvent]) -> bool:
	if not ChargeRules.dodges(target_side.active, move):
		return false
	var dodged := _event(BattleEvent.Kind.DODGED, target_side)
	dodged.move_id = move.id
	events.append(dodged)
	return true


## Ball lancée sur un sauvage invulnérable : BALL_BLOCKED à la place du lancer (la Ball est
## déjà retirée par le directeur), puis l'adversaire joue son tour. Faux sinon.
func _ball_blocked(item: ItemData, events: Array[BattleEvent]) -> bool:
	if not _foe.active.invulnerable:
		return false
	var blocked := _event(BattleEvent.Kind.BALL_BLOCKED, _foe)
	blocked.item_id = item.id
	blocked.item_name = item.name
	events.append(blocked)
	_foe_turn_alone(events)
	return true


## Téléport (après MOVE_USED) : contre un Dresseur, NOTHING_HAPPENED ; en combat sauvage,
## TELEPORTED puis la fin du combat (FLED pour le joueur, FOE_FLED pour le sauvage). Un lanceur
## piégé (J12) échouera (« Mais ça échoue ! ») : à brancher à la fusion du piège.
func _teleport(side: BattleSide, events: Array[BattleEvent]) -> void:
	if _rules == null or not _rules.wild:
		events.append(_event(BattleEvent.Kind.NOTHING_HAPPENED, side))
		return
	events.append(_event(BattleEvent.Kind.TELEPORTED, side))
	_finish(Outcome.FLED if side == _player else Outcome.FOE_FLED, events)
