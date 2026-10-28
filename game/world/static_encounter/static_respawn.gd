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
## Ronflex (arbitrage **N-18**, validé par Kevin le 2026-10-25 : « Un Ronflex après la Ligue ») :
## les deux Ronflex des routes ne reviennent pas (ils refermeraient la route). Si **tous les deux**
## ont été mis K.O. sans capture, une victoire à la Ligue lève [constant SNORLAX_EXTRA_PRESENT] :
## un troisième Ronflex endormi apparaît au belvédère de la Route 10 [D], hors de tout chemin,
## et se réveille à la Poké Flûte (scène `snorlax_post_league_wake`, mêmes répliques que le J21).
## Mis K.O. à son tour, il revient à la victoire suivante (même règle que N-17).
## L'Ossatueur spectre (non capturable) est hors périmètre.
##
## Branchement : à la victoire contre le Maître (J30, `LeagueAttempt`, drapeau
## `league_champion_defeated`), avant la sauvegarde du Panthéon :
## `StaticRespawn.on_league_won(cutscenes.get_static_encounters(), flags)`.


## Drapeaux des deux Ronflex du J21 (`data/cutscenes/j21_snorlax*.json`).
const ROUTE_SNORLAX_DONE: Array[StringName] = [&"snorlax_route_12_done", &"snorlax_route_16_done"]
const ROUTE_SNORLAX_CAUGHT: Array[StringName] = [
	&"snorlax_route_12_caught", &"snorlax_route_16_caught"]
## Ronflex d'après la Ligue (N-18) : présent, consommé, capturé.
const SNORLAX_EXTRA_PRESENT: StringName = &"snorlax_post_league_present"
const SNORLAX_EXTRA_DONE: StringName = &"snorlax_post_league_done"
const SNORLAX_EXTRA_CAUGHT: StringName = &"snorlax_post_league_caught"


## Vrai si les deux Ronflex des routes ont été mis K.O. et qu'aucun n'a été capturé.
static func route_snorlax_lost(flags: StoryFlags) -> bool:
	return flags != null and flags.has_all(ROUTE_SNORLAX_DONE) \
		and flags.has_none(ROUTE_SNORLAX_CAUGHT)


## Règle N-18 à la victoire à la Ligue. Rend les drapeaux changés (levés ou baissés).
static func apply_snorlax_rule(flags: StoryFlags) -> Array[StringName]:
	var changed: Array[StringName] = []
	if not route_snorlax_lost(flags) or flags.has_flag(SNORLAX_EXTRA_CAUGHT):
		return changed
	if not flags.has_flag(SNORLAX_EXTRA_PRESENT):
		flags.set_flag(SNORLAX_EXTRA_PRESENT)
		changed.append(SNORLAX_EXTRA_PRESENT)
	if flags.has_flag(SNORLAX_EXTRA_DONE):
		flags.set_flag(SNORLAX_EXTRA_DONE, false)
		changed.append(SNORLAX_EXTRA_DONE)
	return changed


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


## Victoire à la Ligue : les Pokémon uniques mis K.O. reviennent, et le Ronflex de N-18
## ([method apply_snorlax_rule]). Rend les drapeaux changés (sans doublon : ceux des rencontres
## dans l'ordre de [param encounters], puis ceux de Ronflex).
static func on_league_won(encounters: Array[StaticEncounter], flags: StoryFlags) \
		-> Array[StringName]:
	var cleared: Array[StringName] = []
	for encounter: StaticEncounter in knocked_out(encounters, flags):
		if cleared.has(encounter.done_flag):
			continue
		flags.set_flag(encounter.done_flag, false)
		cleared.append(encounter.done_flag)
	if flags != null:
		cleared.append_array(apply_snorlax_rule(flags))
	return cleared
