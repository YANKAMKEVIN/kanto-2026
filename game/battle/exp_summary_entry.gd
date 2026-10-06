class_name ExpSummaryEntry
extends RefCounted
## Progression d'un Pokémon du joueur sur tout un combat, pour le bilan de fin de combat
## (demande n° 1, décisions de Kevin du 2026-10-06). Donnée pure, remplie par [ExpSummary].
##
## La barre d'XP du bilan se remplit par [b]tranches[/b] : une par niveau traversé
## ([member segments], fractions 0..1 de la barre, et [member points] : les mêmes en points
## d'XP du niveau, « 112 / 173 »). Toutes les tranches sauf la dernière finissent pleines :
## entre deux tranches, le Pokémon monte d'un niveau ([member level_ups], dans l'ordre, avec
## les gains de statistiques de chacun). Plusieurs K.O. dans le même niveau donnent une seule
## tranche (la barre ne repart pas en arrière).

## Place du Pokémon dans l'équipe (0 = en tête) : identité, et ordre des lignes du bilan.
var party_index: int = -1
var species_id: StringName = &""
## Nom affiché (surnom ou espèce) au moment du gain.
var pokemon_name: String = ""
## Niveau avant le premier gain du combat.
var start_level: int = 0
## XP gagnée en tout pendant le combat.
var exp_gained: int = 0
## Tranches de barre (x = départ, y = arrivée), une par niveau : toujours une de plus que de
## niveaux gagnés (la dernière, dans le niveau final, peut être vide : 0 → 0).
var segments: Array[Vector2] = []
## Les mêmes tranches en points d'XP du niveau : (départ, arrivée, XP du niveau entier) ;
## z = 0 au niveau 100 (pas de nombres).
var points: Array[Vector3i] = []
## Un [LevelUp] par niveau gagné ([member LevelUp.level], [member LevelUp.stat_gains] ; ses
## capacités ne sont pas remplies : l'apprentissage est annoncé au K.O., pas au bilan).
var level_ups: Array[LevelUp] = []


## Niveau à la fin du combat.
func end_level() -> int:
	return level_ups[-1].level if not level_ups.is_empty() else start_level


func levels_gained() -> int:
	return level_ups.size()


## Barre au début (fraction) ; 0 sans tranche.
func start_fraction() -> float:
	return segments[0].x if not segments.is_empty() else 0.0


## Barre à la fin (fraction) ; 0 sans tranche.
func end_fraction() -> float:
	return segments[-1].y if not segments.is_empty() else 0.0


## Gains de statistiques cumulés des [param count] premiers niveaux gagnés (tous si −1), dans
## l'ordre de [constant SpeciesData.STATS] ; une statistique qui n'a pas bougé vaut 0.
func stat_gains(count: int = -1) -> Dictionary[StringName, int]:
	var total: Dictionary[StringName, int] = {}
	for stat: StringName in SpeciesData.STATS:
		total[stat] = 0
	var last := level_ups.size() if count < 0 else mini(count, level_ups.size())
	for i: int in last:
		for stat: StringName in level_ups[i].stat_gains:
			total[stat] = total.get(stat, 0) + level_ups[i].stat_gains[stat]
	return total
