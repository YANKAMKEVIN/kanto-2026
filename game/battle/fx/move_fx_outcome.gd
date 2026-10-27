class_name MoveFxOutcome
extends RefCounted
## Issue d'une attaque, lue dans le journal [BattleEvent] (chantier Combat vivant,
## `docs/tech/combat-vivant.md` §2.3, §2.4). Pure : ne lit que la liste d'événements.
##
## Lecture **à partir d'un MOVE_USED** jusqu'au prochain MOVE_USED ou TURN_STARTED (exclus).
## Métronome (et toute attaque qui en lance une autre) : le MOVE_USED suivant du même lanceur
## vient tout de suite ; l'issue est [constant Result.CALLED] et [member called_move_id] dit
## laquelle, qui a sa propre issue (lue à partir de son MOVE_USED).

enum Result {
	## Au moins un coup a porté (DAMAGE sur la cible).
	HIT,
	## Sans dégâts, mais quelque chose a changé (statistique, statut, mur, soin, piège…).
	AFFECTED,
	MISSED,
	## Type immunisé.
	NO_EFFECT,
	## Cible invulnérable (Tunnel, Vol).
	DODGED,
	## « Mais ça échoue ! », ou rien n'a changé (statistique au bout, statut déjà là).
	FAILED,
	## Tour 1 d'une attaque à deux tours (CHARGE_STARTED, Patience qui commence).
	CHARGING,
	## Lance une autre attaque (Métronome).
	CALLED,
}

const AFFECTING: Array[BattleEvent.Kind] = [
	BattleEvent.Kind.STAT_CHANGED, BattleEvent.Kind.STATUS_INFLICTED, BattleEvent.Kind.CONFUSED,
	BattleEvent.Kind.SEEDED, BattleEvent.Kind.TRAPPED, BattleEvent.Kind.MOVE_DISABLED,
	BattleEvent.Kind.RESTED, BattleEvent.Kind.HEALED, BattleEvent.Kind.SCREEN_STARTED,
	BattleEvent.Kind.STATS_RESET, BattleEvent.Kind.FOCUSED, BattleEvent.Kind.TELEPORTED,
	BattleEvent.Kind.SCARED_AWAY, BattleEvent.Kind.FORCED_OUT, BattleEvent.Kind.COINS_SCATTERED,
]
const UNCHANGED: Array[BattleEvent.Kind] = [
	BattleEvent.Kind.STAT_UNCHANGED, BattleEvent.Kind.STATUS_UNCHANGED,
	BattleEvent.Kind.CONFUSION_UNCHANGED, BattleEvent.Kind.NOTHING_HAPPENED,
]

var result: Result = Result.FAILED
var move_id: StringName = &""
## Camp du lanceur ; la cible est l'autre camp.
var user_side: BattleEvent.SideId = BattleEvent.SideId.PLAYER
## Index du MOVE_USED lu, et du premier événement qui n'en fait plus partie.
var start_index: int = -1
var end_index: int = -1
## Coups portés sur la cible (un DAMAGE par coup).
var hits: int = 0
## Au moins un coup critique.
var critical: bool = false
## Efficacité du premier coup (1 : neutre).
var effectiveness: float = 1.0
## PV retirés à la cible, en tout ; et la plus grosse part des PV max retirée en un coup.
var damage: int = 0
var max_hit_fraction: float = 0.0
var target_fainted: bool = false
## K.O. en un coup réussi (OHKO).
var ohko: bool = false
## Le lanceur se met K.O. (Explosion, Destruction).
var self_ko: bool = false
## Le lanceur a récupéré des PV par drain (DRAINED_HP).
var drained: bool = false
var recoil: bool = false
## Statut posé sur la cible (STATUS_INFLICTED) ; "" sinon.
var status_inflicted: StringName = &""
## Tour 2 d'une attaque à deux tours : le MOVE_USED suit un CHARGE_RELEASED.
var charge_released: bool = false
## Métronome : attaque lancée ([constant Result.CALLED]).
var called_move_id: StringName = &""


## Issue de l'attaque dont le MOVE_USED est en [param start] ; null si ce n'en est pas un.
static func read(events: Array[BattleEvent], start: int) -> MoveFxOutcome:
	if start < 0 or start >= events.size() or events[start].kind != BattleEvent.Kind.MOVE_USED:
		return null
	var used := events[start]
	var outcome := MoveFxOutcome.new()
	outcome.move_id = used.move_id
	outcome.user_side = used.side
	outcome.start_index = start
	outcome.charge_released = start > 0 \
			and events[start - 1].kind == BattleEvent.Kind.CHARGE_RELEASED \
			and events[start - 1].side == used.side
	var affected := false
	var unchanged := false
	var failed := false
	var missed := false
	var no_effect := false
	var dodged := false
	var charging := false
	var index := start + 1
	while index < events.size():
		var event := events[index]
		if event.kind == BattleEvent.Kind.MOVE_USED or event.kind == BattleEvent.Kind.TURN_STARTED:
			if index == start + 1 and event.kind == BattleEvent.Kind.MOVE_USED \
					and event.side == used.side:
				outcome.called_move_id = event.move_id
			break
		var on_target := event.side != used.side
		match event.kind:
			BattleEvent.Kind.DAMAGE:
				if on_target:
					outcome._add_hit(event)
			BattleEvent.Kind.FAINTED:
				if on_target:
					outcome.target_fainted = true
			BattleEvent.Kind.MOVE_MISSED:
				missed = true
			BattleEvent.Kind.NO_EFFECT:
				no_effect = true
			BattleEvent.Kind.DODGED:
				dodged = true
			BattleEvent.Kind.FAILED:
				failed = true
			BattleEvent.Kind.CHARGE_STARTED, BattleEvent.Kind.BIDE_STARTED:
				charging = true
			BattleEvent.Kind.OHKO:
				outcome.ohko = true
			BattleEvent.Kind.SELF_KO:
				outcome.self_ko = true
			BattleEvent.Kind.DRAINED_HP:
				outcome.drained = true
			BattleEvent.Kind.RECOIL:
				outcome.recoil = true
			BattleEvent.Kind.STATUS_INFLICTED:
				if on_target:
					outcome.status_inflicted = event.status
				affected = true
			_:
				if AFFECTING.has(event.kind):
					affected = true
				elif UNCHANGED.has(event.kind):
					unchanged = true
		index += 1
	outcome.end_index = index
	outcome.result = outcome._result(affected, unchanged, failed, missed, no_effect, dodged,
		charging)
	return outcome


## Index de tous les MOVE_USED de [param events], dans l'ordre.
static func move_starts(events: Array[BattleEvent]) -> Array[int]:
	var starts: Array[int] = []
	for i: int in events.size():
		if events[i].kind == BattleEvent.Kind.MOVE_USED:
			starts.append(i)
	return starts


## Vrai si l'attaque a quelque chose à frapper (un impact se joue).
func lands() -> bool:
	return result == Result.HIT or result == Result.AFFECTED


func _add_hit(event: BattleEvent) -> void:
	if hits == 0:
		effectiveness = event.effectiveness
	hits += 1
	damage += event.amount
	critical = critical or event.critical
	if event.max_hp > 0:
		max_hit_fraction = maxf(max_hit_fraction, float(event.amount) / float(event.max_hp))


func _result(affected: bool, unchanged: bool, failed: bool, missed: bool, no_effect: bool,
		dodged: bool, charging: bool) -> Result:
	if not called_move_id.is_empty():
		return Result.CALLED
	if charging:
		return Result.CHARGING
	if hits > 0:
		return Result.HIT
	if dodged:
		return Result.DODGED
	if no_effect:
		return Result.NO_EFFECT
	if missed:
		return Result.MISSED
	if failed:
		return Result.FAILED
	if affected:
		return Result.AFFECTED
	return Result.FAILED if unchanged else Result.AFFECTED
