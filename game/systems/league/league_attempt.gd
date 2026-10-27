class_name LeagueAttempt
extends RefCounted
## Tentative de Ligue Pokémon (jalon 30 T5 ; `docs/tech/jalon-30.md` §2.2, §2.3, §2.5).
##
## Statique et pur : toute la tentative tient dans des drapeaux ordinaires de [StoryFlags],
## lus et écrits ici seulement. Étapes : 0 Olga, 1 Aldo, 2 Agatha, 3 Peter, 4 Champion,
## [constant STAGE_DONE] (5) = les cinq combats gagnés, cérémonie du Panthéon à jouer.
## [codeblock]
## entrée (porte du hall)  → league_attempt_active ; league_stage_<k>_cleared effacés
## victoire contre k       → league_stage_<k>_cleared (seulement si k est l'étape courante)
## défaite (toute salle)   → tous les drapeaux de tentative effacés (réveil au Plateau)
## cérémonie du Panthéon   → league_champion_defeated ; drapeaux de tentative effacés
## [/codeblock]
## Vigilance A de la passe : une victoire n'a de sens que dans sa tentative. Les drapeaux
## temporaires ne sont jamais confondus avec [constant CHAMPION_DEFEATED] (permanent).
## Aucune étape ne se saute : l'étape courante est la première non gagnée, même si un drapeau
## plus loin est levé (fichier retouché). Aucun soin gratuit ici : les combats de la Ligue sont
## `heal_after: false` (`data/trainers/league.json`), seuls les objets du Sac soignent.

## Tentative en cours (temporaire).
const ACTIVE: StringName = &"league_attempt_active"
## Titre de Champion, post-game (permanent ; `league_first_clear_completed` et
## `postgame_unlocked` de la passe, §0.2).
const CHAMPION_DEFEATED: StringName = &"league_champion_defeated"
## Générique déjà vu une fois : le suivant est passable (permanent, §2.4).
const CREDITS_SEEN: StringName = &"league_credits_seen"

## Nombre de combats d'une tentative.
const STAGE_COUNT: int = 5
## Étape « les cinq combats sont gagnés » : reste la cérémonie.
const STAGE_DONE: int = STAGE_COUNT
## Pas de tentative en cours.
const NO_STAGE: int = -1

## Dresseur de chaque étape (`data/trainers/league.json`).
const TRAINERS: Array[StringName] = [
	&"league_lorelei", &"league_bruno", &"league_agatha", &"league_lance", &"rival_champion",
]
## Salle de chaque étape (§2.1) ; la salle du Champion accueille aussi la cérémonie.
const ROOMS: Array[StringName] = [
	&"league_lorelei", &"league_bruno", &"league_agatha", &"league_lance", &"league_champion",
]


## Drapeau « membre [param stage] battu dans cette tentative » ; &"" hors de 0..4.
static func stage_flag(stage: int) -> StringName:
	if stage < 0 or stage >= STAGE_COUNT:
		return &""
	return StringName("league_stage_%d_cleared" % stage)


## Vrai pour un drapeau de tentative (effacé à chaque entrée, défaite ou cérémonie).
static func is_temporary_flag(flag: StringName) -> bool:
	return flag == ACTIVE or temporary_flags().has(flag)


## Les drapeaux de tentative, [constant ACTIVE] en premier.
static func temporary_flags() -> Array[StringName]:
	var result: Array[StringName] = [ACTIVE]
	for stage: int in STAGE_COUNT:
		result.append(stage_flag(stage))
	return result


static func is_active(flags: StoryFlags) -> bool:
	return flags.has_flag(ACTIVE)


static func is_champion(flags: StoryFlags) -> bool:
	return flags.has_flag(CHAMPION_DEFEATED)


## Étape courante : [constant NO_STAGE] hors tentative, sinon la première non gagnée (0..4),
## ou [constant STAGE_DONE] si les cinq sont gagnées.
static func current_stage(flags: StoryFlags) -> int:
	if not is_active(flags):
		return NO_STAGE
	for stage: int in STAGE_COUNT:
		if not flags.has_flag(stage_flag(stage)):
			return stage
	return STAGE_DONE


## Entrée par la porte du hall : nouvelle tentative depuis Olga. Une tentative déjà en cours
## n'est pas remise à zéro (reprise après chargement) : faux, rien ne change.
static func start(flags: StoryFlags) -> bool:
	if is_active(flags):
		return false
	_clear_stages(flags)
	flags.set_flag(ACTIVE)
	return true


## Victoire contre le membre de l'étape [param stage]. Acceptée seulement pendant une tentative
## et pour l'étape courante (jamais d'étape sautée, jamais deux fois) : vrai si le drapeau est
## posé.
static func record_victory(flags: StoryFlags, stage: int) -> bool:
	if stage < 0 or stage >= STAGE_COUNT or current_stage(flags) != stage:
		return false
	flags.set_flag(stage_flag(stage))
	return true


## Victoire contre [param trainer_id] : [method record_victory] de son étape (faux pour un
## dresseur hors Ligue).
static func record_trainer_victory(flags: StoryFlags, trainer_id: StringName) -> bool:
	return record_victory(flags, stage_of_trainer(trainer_id))


## Défaite, quelle que soit la salle : la tentative s'arrête (le réveil au Plateau est celui du
## moteur). Les drapeaux permanents ne bougent pas. Vrai si une tentative était en cours.
static func record_defeat(flags: StoryFlags) -> bool:
	var was_active := is_active(flags)
	_clear_attempt(flags)
	return was_active


## Cérémonie du Panthéon : seulement quand les cinq combats sont gagnés. Pose
## [constant CHAMPION_DEFEATED] et efface la tentative. Idempotente : une seconde fois (ou
## avant la fin) → faux, rien ne change ; l'appelant n'ajoute l'entrée du Panthéon que sur vrai,
## dans la même écriture (§2.3).
static func complete(flags: StoryFlags) -> bool:
	if current_stage(flags) != STAGE_DONE:
		return false
	flags.set_flag(CHAMPION_DEFEATED)
	_clear_attempt(flags)
	return true


## Porte nord de la salle [param stage] : ouverte quand son membre est battu dans la tentative.
static func north_door_open(flags: StoryFlags, stage: int) -> bool:
	return is_active(flags) and stage >= 0 and stage < STAGE_COUNT \
		and current_stage(flags) > stage


## Porte sud de la salle [param stage] (vers la salle d'avant ou le hall) : fermée pendant la
## tentative (pas de retour en arrière).
static func south_door_open(flags: StoryFlags, _stage: int = 0) -> bool:
	return not is_active(flags)


## Le membre de l'étape [param stage] attend-il encore son combat ?
static func member_waiting(flags: StoryFlags, stage: int) -> bool:
	return current_stage(flags) == stage


## Salle de reprise : celle de l'étape courante (la salle du Champion pour la cérémonie) ;
## &"" hors tentative.
static func resume_room(flags: StoryFlags) -> StringName:
	var stage := current_stage(flags)
	if stage == NO_STAGE:
		return &""
	return ROOMS[mini(stage, STAGE_COUNT - 1)]


## Étape d'un dresseur de la Ligue, [constant NO_STAGE] sinon.
static func stage_of_trainer(trainer_id: StringName) -> int:
	return TRAINERS.find(trainer_id)


## Dresseur de l'étape [param stage], &"" hors de 0..4.
static func trainer_of_stage(stage: int) -> StringName:
	if stage < 0 or stage >= STAGE_COUNT:
		return &""
	return TRAINERS[stage]


## Étape d'une salle de la Ligue, [constant NO_STAGE] sinon.
static func stage_of_room(map_id: StringName) -> int:
	return ROOMS.find(map_id)


static func _clear_stages(flags: StoryFlags) -> void:
	for stage: int in STAGE_COUNT:
		flags.set_flag(stage_flag(stage), false)


static func _clear_attempt(flags: StoryFlags) -> void:
	_clear_stages(flags)
	flags.set_flag(ACTIVE, false)
