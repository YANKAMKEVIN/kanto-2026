class_name BellTowerDawnRule
extends RefCounted
## Aube forcée du sommet de la Tour Carillon (JOH8, `docs/tech/jalon-joh8.md` §2.6 ; dossier
## JOH-09 §10, JH-55) : règle pure **par carte**, à côté de [JohtoPeriodRule] (règle sur les
## drapeaux du JOH1). Sur `bell_tower_roof`, tant que Ho-Oh n'a pas été affronté
## (`johto_ho_oh_done` bas), le moment est le **matin** quelle que soit l'heure réelle ; ailleurs,
## ou après Ho-Oh, aucun moment imposé. [Boot] la lit après [JohtoPeriodRule] (qui garde la
## priorité) à la mise en place de la partie et à **chaque changement de carte** : l'heure réelle
## reprend à la sortie du sommet, jamais sous les yeux du joueur au milieu de la scène.

const ROOF: StringName = &"bell_tower_roof"
const HO_OH_DONE: StringName = &"johto_ho_oh_done"
const MORNING: StringName = &"morning"


## Moment imposé sur la carte [param map_id] avec [param flags] : [constant MORNING] ou &"".
static func forced_period(map_id: StringName, flags: StoryFlags) -> StringName:
	if map_id != ROOF:
		return &""
	if flags != null and flags.has_flag(HO_OH_DONE):
		return &""
	return MORNING
