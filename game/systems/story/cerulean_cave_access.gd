class_name CeruleanCaveAccess
extends RefCounted
## Accès à la Grotte Azurée (jalon 31, T2 / T5 ; `docs/tech/jalon-31.md` §2.1, §2.4) : pur,
## statique, sans scène.
##
## L'accès est **calculé**, jamais sauvegardé (pas de drapeau « cerulean_cave_unlocked ») : il est
## ouvert si et seulement si le titre de Champion est enregistré ([constant CHAMPION_FLAG], posé
## par la cérémonie du Panthéon du J30, `LeagueAttempt.CHAMPION_DEFEATED`). Il ne lit ni le nombre
## de Badges, ni le Pokédex, ni la présence de Mewtwo, ni les drapeaux temporaires de tentative de
## la Ligue (Conseil des Quatre vaincu sans Champion : refusé). Le drapeau de Champion étant
## permanent, l'accès survit au rechargement et à une nouvelle victoire à la Ligue.
##
## Branchement (31A, après la fusion du J30 et le choix de la géographie, §8 du plan) : la bouche
## de la grotte côté Azuria interroge [method is_open] ; refusée, elle affiche
## [constant REFUSAL_DIALOGUE] ; à la première entrée, [method record_entry] pose
## [constant DISCOVERED_FLAG].

## Titre de Champion (J30) : même valeur que `LeagueAttempt.CHAMPION_DEFEATED` (`origin/jalon-30`,
## `game/systems/league/league_attempt.gd`), recopiée ici tant que le J30 n'est pas fusionné ; à la
## fusion, un test garde l'égalité (`test_cerulean_cave_access`).
const CHAMPION_FLAG: StringName = &"league_champion_defeated"
## Grotte visitée au moins une fois (drapeau d'histoire, défaut faux ; plan §2.4).
const DISCOVERED_FLAG: StringName = &"cerulean_cave_discovered"
## Message de refus [D] (« Les eaux sont trop agitées. Pas maintenant. », plan §4 ;
## `data/dialogues/cerulean_cave.json`).
const REFUSAL_DIALOGUE: StringName = &"cerulean_cave_closed"
## Les trois étages (grilles `tools/plans/cerulean_cave_*.txt`).
const MAPS: Array[StringName] = [&"cerulean_cave_1f", &"cerulean_cave_2f", &"cerulean_cave_b1f"]


## Vrai si la grotte est ouverte avec [param flags] (null = nouvelle partie : fermée).
static func is_open(flags: StoryFlags) -> bool:
	return flags != null and flags.has_flag(CHAMPION_FLAG)


## Dialogue à jouer à la bouche de la grotte : [constant REFUSAL_DIALOGUE] si elle est fermée,
## &"" si l'on peut entrer.
static func refusal_for(flags: StoryFlags) -> StringName:
	return &"" if is_open(flags) else REFUSAL_DIALOGUE


## Vrai si [param map_id] est un étage de la grotte.
static func is_cave_map(map_id: StringName) -> bool:
	return MAPS.has(map_id)


## À l'arrivée sur [param map_id] : pose [constant DISCOVERED_FLAG] si c'est un étage de la grotte
## et que l'accès est ouvert. Vrai si le drapeau vient d'être posé.
static func record_entry(flags: StoryFlags, map_id: StringName) -> bool:
	if flags == null or not is_cave_map(map_id) or not is_open(flags) \
			or flags.has_flag(DISCOVERED_FLAG):
		return false
	flags.set_flag(DISCOVERED_FLAG)
	return true
