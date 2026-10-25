class_name StaticRespawn
extends RefCounted
## Réapparition des Pokémon uniques mis K.O. (jalon 32, arbitrage **N-17** validé par Kevin le
## 2026-10-25 : « Réapparaît après la Ligue »). Classe pure.
##
## Une rencontre fixe ([StaticEncounter] : Artikodin, Sulfura, Mewtwo, plus tard Électhor et
## Mew) mise K.O. pose seulement son drapeau `done` ; capturée, elle pose aussi `caught`. À
## chaque victoire à la Ligue (rejouable, `jalon-32.md` §1.3), [method on_league_won] baisse le
## `done` des rencontres **mises K.O. et jamais capturées** : le Pokémon revient à sa place, la
## scène (`"unless": [<done>]`) et l'acteur de la carte réapparaissent. Le Pokédex reste
## toujours complétable. Aucun champ de sauvegarde nouveau : seuls des drapeaux existants
## changent.
##
## Hors périmètre [D] : Ronflex (ses scènes n'ont pas de clé « static » ; le faire revenir
## refermerait la route) et l'Ossatueur spectre (non capturable).
##
## Branchement : à la victoire contre le Maître (J30, `LeagueAttempt`, drapeau
## `league_champion_defeated`), avant la sauvegarde du Panthéon :
## `StaticRespawn.on_league_won(cutscenes.get_static_encounters(), flags)`.


## Rencontres de [param encounters] mises K.O. sans avoir été capturées.
static func knocked_out(encounters: Array[StaticEncounter], flags: StoryFlags) \
		-> Array[StaticEncounter]:
	var result: Array[StaticEncounter] = []
	if flags == null:
		return result
	for encounter: StaticEncounter in encounters:
		if encounter == null or encounter.done_flag.is_empty():
			continue
		if flags.has_flag(encounter.done_flag) and not flags.has_flag(encounter.caught_flag):
			result.append(encounter)
	return result


## Victoire à la Ligue : les Pokémon uniques mis K.O. reviennent. Rend les drapeaux baissés
## (sans doublon, dans l'ordre de [param encounters]).
static func on_league_won(encounters: Array[StaticEncounter], flags: StoryFlags) \
		-> Array[StringName]:
	var cleared: Array[StringName] = []
	for encounter: StaticEncounter in knocked_out(encounters, flags):
		if cleared.has(encounter.done_flag):
			continue
		flags.set_flag(encounter.done_flag, false)
		cleared.append(encounter.done_flag)
	return cleared
