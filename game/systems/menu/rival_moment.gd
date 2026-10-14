class_name RivalMoment
extends RefCounted
## Grand moment « combat contre le rival » (roadmap, précisée le 2026-10-11 ; dossier 16 D-5 ;
## jalon-13.md §2.8). Classe pure, statique (modèle [BadgeMoment]).
##
## Rival = Dresseur à `team_by_starter` (son équipe dépend du starter du joueur, comme dans
## Rouge/Bleu). **Un moment par Dresseur, jamais deux.** Si la donnée du Dresseur dit
## `"moment": "win"` ([member TrainerData.moment_on_win] : combat obligatoire et rejouable,
## rival n° 3), le moment ne s'écrit qu'à la victoire ; sinon à toute issue (rivaux n° 1 et
## n° 2, qui ne se rejouent pas : comportement inchangé).
##
## Détails enregistrés : { "trainer": "<id>", "outcome": "win" | "loss" | … }.

const TYPE: StringName = &"rival_battle"
const KEY_TRAINER: String = "trainer"
const KEY_OUTCOME: String = "outcome"


## Vrai si la fin du combat contre [param trainer] avec l'issue [param outcome]
## ([enum Battle.Outcome]) doit écrire le moment, compte tenu des [param moments] déjà
## enregistrés (GameState.moments).
static func should_record(trainer: TrainerData, outcome: int, moments: Array) -> bool:
	if trainer == null or trainer.id.is_empty() or trainer.team_by_starter.is_empty():
		return false
	if trainer.moment_on_win and outcome != Battle.Outcome.WIN:
		return false
	return not has_rival_moment(moments, trainer.id)


## Vrai si [param moments] contient déjà le moment « rival » du Dresseur [param trainer_id].
static func has_rival_moment(moments: Array, trainer_id: StringName) -> bool:
	if trainer_id.is_empty():
		return false
	for moment: Variant in moments:
		if not moment is Dictionary:
			continue
		if str((moment as Dictionary).get("type", "")) != String(TYPE):
			continue
		var moment_details: Variant = (moment as Dictionary).get("details")
		if moment_details is Dictionary \
				and str((moment_details as Dictionary).get(KEY_TRAINER, "")) == String(trainer_id):
			return true
	return false


## Détails du moment (issue en minuscules : « win », « loss »).
static func details(trainer_id: StringName, outcome: int) -> Dictionary:
	var outcome_name: Variant = Battle.Outcome.find_key(outcome)
	return {
		KEY_TRAINER: String(trainer_id),
		KEY_OUTCOME: String(outcome_name).to_lower() if outcome_name != null else "",
	}
