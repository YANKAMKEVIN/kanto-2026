class_name EncounterTable
extends RefCounted
## Une table de rencontres sauvages : un terrain sur une ou plusieurs cartes, un taux par pas
## et des emplacements pondérés (jalon 5 §2.2, §3.6). Donnée pure.
##
## [method roll] est le tirage complet d'un pas terminé sur une case du terrain : d'abord le
## taux ([member rate] sur [constant RATE_DEN]), puis, si une rencontre a lieu, l'espèce (par
## poids) et le niveau (uniforme dans la fourchette de l'emplacement). Ordre des tirages, pour
## la reproductibilité : roll(256) ≤ rate, roll(poids total), range_int(min, max).
## [method pick] fait le tirage sans le test de taux (tests, départ de débogage).

## Terrains connus (eau et grotte plus tard).
const TERRAINS: Array[StringName] = [&"grass"]
## Dénominateur du taux de rencontre (le taux est « rate / 256 par pas »).
const RATE_DEN: int = 256

var id: StringName = &""
var terrain: StringName = &"grass"
## Cartes qui partagent cette table.
var maps: Array[StringName] = []
## Taux de rencontre par pas terminé sur le terrain, sur [constant RATE_DEN] (1..255).
var rate: int = 0
var slots: Array[EncounterSlot] = []
## Fichier d'origine (messages d'erreur).
var source: String = ""


## Somme des poids des emplacements.
func total_weight() -> int:
	var total := 0
	for slot: EncounterSlot in slots:
		total += slot.weight
	return total


## Tirage complet d'un pas : null si aucune rencontre (le taux n'a pas été atteint) ou si la
## table est vide.
func roll(rng: GameRng) -> WildEncounter:
	if rate <= 0 or rng.roll(RATE_DEN) > rate:
		return null
	return pick(rng)


## Tire une rencontre sans le test de taux (une rencontre est toujours produite si la table a
## des emplacements). null si la table est vide.
func pick(rng: GameRng) -> WildEncounter:
	var total := total_weight()
	if total <= 0 or slots.is_empty():
		return null
	var target := rng.roll(total)
	var accumulated := 0
	for slot: EncounterSlot in slots:
		accumulated += slot.weight
		if target <= accumulated:
			var level := rng.range_int(slot.min_level, slot.max_level)
			return WildEncounter.new(slot.species, level, id)
	return null


## Probabilité qu'une rencontre (quand elle a lieu) soit [param species] (information pour
## Kevin, pas utilisée par le moteur).
func chance_of(species: StringName) -> float:
	var total := total_weight()
	if total <= 0:
		return 0.0
	var sum := 0
	for slot: EncounterSlot in slots:
		if slot.species == species:
			sum += slot.weight
	return float(sum) / float(total)
