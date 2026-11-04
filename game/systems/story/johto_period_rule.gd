class_name JohtoPeriodRule
extends RefCounted
## Moment du jour **imposé par l'histoire** du Chapitre Johto (JOH1, `docs/tech/jalon-joh1.md`
## §2.4 ; dossier JOH-02 §4 « Scènes forcées et heure ») : une règle pure sur les drapeaux,
## sans étape de scène, pour que le moment survive à une coupure de l'application (cas limites
## du dossier §11 : tuée entre le vol et le choix, on reprend le matin).
##
## - **nuit** : la lettre d'Orme est lue (`johto_letter_read`) et l'équipe n'est pas encore
##   volée (`johto_team_stolen` bas) : la grotte marine a une lumière fixe et Kanto ne lit pas
##   l'heure (JH-8), Oliville est donc de nuit dès la plage, sans fondu à la première case ;
## - **matin** : l'équipe est volée et Orme n'est pas reparti (`johto_orme_left` bas) ;
## - sinon, **aucun** moment imposé : l'heure réelle du téléphone (étape 11 du dossier).
## [Boot] l'applique à la mise en place de la partie et à chaque drapeau changé
## ([method WorldClock.force_period] / [method WorldClock.release_period]), sauf quand un départ
## de débogage impose lui-même `period`.

const LETTER_READ: StringName = &"johto_letter_read"
const TEAM_STOLEN: StringName = &"johto_team_stolen"
const ORME_LEFT: StringName = &"johto_orme_left"
const NIGHT: StringName = &"night"
const MORNING: StringName = &"morning"
## Drapeaux lus par la règle (tests de données : chacun est levé par une scène du JOH1).
const FLAGS: Array[StringName] = [LETTER_READ, TEAM_STOLEN, ORME_LEFT]


## Moment imposé par [param flags] : [constant NIGHT], [constant MORNING] ou &"" (heure réelle).
## Noms de [constant WorldClock.PERIOD_NAMES].
static func forced_period(flags: StoryFlags) -> StringName:
	if flags == null:
		return &""
	if flags.has_flag(TEAM_STOLEN):
		return &"" if flags.has_flag(ORME_LEFT) else MORNING
	if flags.has_flag(LETTER_READ):
		return NIGHT
	return &""
