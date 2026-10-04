class_name PokedexNoteData
extends RefCounted
## Une note d'Observations du Pokédex (dossier 08 §4 ; jalon-06.md §3.5, Q-6), lue dans
## `data/pokedex/kanto.json` par [PokedexLibrary]. Donnée pure.
##
## Elle se débloque quand **toutes** ses conditions tiennent ([method is_met]) et que
## l'espèce a été vue ; une condition absente ne compte pas. Conditions (clé « unlock ») :
## « seen » (observations ≥ n), « caught » (captures ≥ n), « map » (vue sur cette carte),
## « flag » (drapeau d'histoire levé).

## Identifiant unique dans tout le fichier (sauvegardé dans [member PokedexEntry.notes] :
## ne jamais le renommer une fois publié).
var id: StringName = &""
var species: StringName = &""
var text: String = ""
## Texte provisoire, à relire par Kevin.
var draft: bool = false
## Observations minimales (0 = sans condition).
var seen: int = 0
## Captures minimales (0 = sans condition).
var caught: int = 0
## Carte où l'espèce doit avoir été vue (&"" = sans condition).
var map: StringName = &""
## Drapeau d'histoire à lever (&"" = sans condition).
var flag: StringName = &""


## Vrai si la note se débloque pour l'entrée [param entry] (null = espèce jamais vue : faux)
## avec les drapeaux [param flags] (null = aucun drapeau levé).
func is_met(entry: PokedexEntry, flags: StoryFlags) -> bool:
	if entry == null or entry.times_seen < 1:
		return false
	if entry.times_seen < seen or entry.times_caught < caught:
		return false
	if not map.is_empty() and not entry.seen_maps.has(map):
		return false
	if not flag.is_empty() and (flags == null or not flags.has_flag(flag)):
		return false
	return true
