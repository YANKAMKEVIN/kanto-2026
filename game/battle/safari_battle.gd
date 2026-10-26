class_name SafariBattle
extends RefCounted
## Moteur d'une rencontre du Parc Safari (J23, dossier 26 §5 ; `jalon-23.md` §2.3). Pur : il ne
## joue rien et renvoie des [BattleEvent] que le [BattleDirector] joue comme ceux de [Battle].
## Tout l'aléatoire vient du [GameRng] reçu ; les règles d'appât, de caillou et de fuite sont
## celles de [SafariRules].
##
## - Aucun Pokémon du joueur : un seul camp en jeu, le sauvage ([method start] : SENT_OUT FOE,
##   « Un … sauvage apparaît ! »). Ni XP, ni argent, ni Sac, ni changement.
## - Actions ([method submit]) : [method BattleAction.safari_ball], [method BattleAction.bait],
##   [method BattleAction.rock], [method BattleAction.run] (FUIR, toujours réussi).
## - Ordre d'un tour : l'action ; si pas de capture et pas de dernière Ball :
##   [method SafariRules.end_turn] (SAFARI_EATING / SAFARI_ANGRY), puis le test de fuite
##   ([method SafariRules.flees] : SAFARI_FLED, BATTLE_ENDED FOE_FLED). Aucun test avant la
##   première action (il n'y a pas de tour avant).
## - Safari Ball : [method SafariVisit.on_ball_thrown] ; [method CaptureCalc.throw_ball] avec le
##   taux courant [member SafariRules.rate] et le multiplicateur [member ball_bonus], sans bonus
##   de statut. Capturé : CAUGHT, BATTLE_ENDED (CAUGHT). Libéré : BROKE_FREE. Si c'était la
##   dernière Ball (capture ou non) : SAFARI_NO_BALLS, puis la fin (CAUGHT, ou FLED sans capture
##   [D]), sans fin de tour ni test de fuite.
## Ordre des tirages, pour la reproductibilité : appât / caillou range_int(1, 5) ; Ball 0 à 4
## roll(65536) ; puis, sans capture ni dernière Ball, un roll(256) de fuite.

enum State { CHOOSING, OVER }

## Identifiant de la Safari Ball dans les événements ([member BattleEvent.item_id]).
const BALL_ID: StringName = &"safari_ball"

## Multiplicateur de la Safari Ball dans [CaptureCalc] ([member SafariConfig.ball_bonus]).
var ball_bonus: float = 2.0

var _foe: Pokemon
var _data: PokemonData
var _rng: GameRng
var _visit: SafariVisit
var _rules: SafariRules
var _state: State = State.CHOOSING
var _outcome: Battle.Outcome = Battle.Outcome.NONE
var _started: bool = false


## Rencontre de [param foe] pendant la visite [param visit] (null : aucune Ball). Le taux de base
## est le [member SpeciesData.catch_rate] de l'espèce.
func _init(foe: Pokemon, data: PokemonData, visit: SafariVisit, bonus: float,
		rng: GameRng) -> void:
	_foe = foe
	_data = data
	_visit = visit
	ball_bonus = bonus
	_rng = rng
	var species := data.get_species(foe.species_id) if data != null and foe != null else null
	_rules = SafariRules.begin(species.catch_rate if species != null else 1)


## Ouverture : le sauvage apparaît (SENT_OUT FOE, sans dresseur). Une seule fois.
func start() -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	if _started:
		return events
	_started = true
	events.append(_event(BattleEvent.Kind.SENT_OUT))
	return events


func get_state() -> State:
	return _state


## Issue ([enum Battle.Outcome]) : NONE tant que la rencontre dure.
func get_outcome() -> Battle.Outcome:
	return _outcome


## Règles d'appât et de caillou en cours (taux courant, compteurs).
func get_rules() -> SafariRules:
	return _rules


func get_foe() -> Pokemon:
	return _foe


## Safari Balls restantes (0 sans visite active).
func balls_left() -> int:
	return _visit.balls_left if _visit != null and _visit.active else 0


## Vrai si [param action] peut être jouée maintenant.
func is_legal(action: BattleAction) -> bool:
	if action == null or _state != State.CHOOSING or not _started:
		return false
	match action.kind:
		BattleAction.Kind.SAFARI_BALL:
			return balls_left() > 0
		BattleAction.Kind.BAIT, BattleAction.Kind.ROCK, BattleAction.Kind.RUN:
			return true
	return false


## Joue [param action] et renvoie le journal du tour (vide si l'action est refusée).
func submit(action: BattleAction) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	if not is_legal(action):
		push_error("SafariBattle : action refusée")
		return events
	match action.kind:
		BattleAction.Kind.RUN:
			events.append(_event(BattleEvent.Kind.SAFARI_LEFT))
			_finish(Battle.Outcome.FLED, events)
			return events
		BattleAction.Kind.SAFARI_BALL:
			if _throw_ball(events):
				return events
		BattleAction.Kind.BAIT:
			_rules.throw_bait(_rng)
			events.append(_event(BattleEvent.Kind.BAIT_THROWN))
		BattleAction.Kind.ROCK:
			_rules.throw_rock(_rng)
			events.append(_event(BattleEvent.Kind.ROCK_THROWN))
	match _rules.end_turn():
		SafariRules.EATING:
			events.append(_event(BattleEvent.Kind.SAFARI_EATING))
		SafariRules.ANGRY:
			events.append(_event(BattleEvent.Kind.SAFARI_ANGRY))
	if _rules.flees(_foe.stats.get(&"spe", 0), _rng):
		events.append(_event(BattleEvent.Kind.SAFARI_FLED))
		_finish(Battle.Outcome.FOE_FLED, events)
	return events


## Lancer d'une Safari Ball ; vrai si la rencontre est finie (capture ou dernière Ball).
func _throw_ball(events: Array[BattleEvent]) -> bool:
	_rules.throw_ball()
	var last := _visit.on_ball_thrown() == SafariVisit.OUT_OF_BALLS
	var thrown := _event(BattleEvent.Kind.SAFARI_BALL_THROWN)
	thrown.item_id = BALL_ID
	thrown.amount = balls_left()
	events.append(thrown)
	var result := CaptureCalc.throw_ball(_foe.max_hp(), _foe.hp, _rules.rate, ball_bonus, _rng)
	for i: int in result.shakes:
		var shake := _event(BattleEvent.Kind.BALL_SHAKE)
		shake.shake = i + 1
		events.append(shake)
	if result.caught:
		events.append(_event(BattleEvent.Kind.CAUGHT))
		if last:
			events.append(_event(BattleEvent.Kind.SAFARI_NO_BALLS))
		_finish(Battle.Outcome.CAUGHT, events)
		return true
	events.append(_event(BattleEvent.Kind.BROKE_FREE))
	if last:
		events.append(_event(BattleEvent.Kind.SAFARI_NO_BALLS))
		_finish(Battle.Outcome.FLED, events)
		return true
	return false


func _finish(outcome: Battle.Outcome, events: Array[BattleEvent]) -> void:
	_state = State.OVER
	_outcome = outcome
	var ended := BattleEvent.new(BattleEvent.Kind.BATTLE_ENDED, BattleEvent.SideId.FOE)
	ended.outcome = outcome
	events.append(ended)


## Événement sur le sauvage, avec son état actuel.
func _event(kind: BattleEvent.Kind) -> BattleEvent:
	var event := BattleEvent.new(kind, BattleEvent.SideId.FOE)
	event.pokemon_name = _foe.display_name(_data)
	event.species_id = _foe.species_id
	event.party_index = 0
	event.level = _foe.level
	event.gender = _foe.gender
	event.hp = _foe.hp
	event.max_hp = _foe.max_hp()
	event.status = _foe.status
	return event
