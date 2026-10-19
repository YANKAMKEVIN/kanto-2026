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
##
## [b]Taux effectif.[/b] Un tirage indépendant à chaque pas laisse parfois attendre 30 pas
## (décision de Kevin du 2026-10-02). Une table peut donc porter une [i]montée[/i] (clé
## « ramp » du JSON : [member ramp_from], [member ramp_max]) : le pas numéro k de la série
## (k = 1 pour le premier pas d'herbe depuis la dernière rencontre) garde le taux de base
## jusqu'à k = [member ramp_from], puis le taux gagne [method ramp_increment] par pas et vaut
## [constant RATE_DEN] (rencontre certaine) au plus tard à k = [member ramp_max]. Le compteur de
## la série (« pas d'herbe sans rencontre ») appartient à l'appelant ([EncounterDirector]) : la
## table reste sans état et [method roll] reçoit le nombre de pas déjà faits sans rencontre.
## Le tirage de taux est [b]toujours[/b] fait, même quand le taux effectif vaut déjà 256
## (un seul roll(256) par pas : le flux de hasard garde le même rythme).

## Terrains connus (eau plus tard). « rubble » (gravats des grottes, jalon 12) : accepté dans
## les données depuis le T12 (`data/encounters/mt_moon.json`) ; [EncounterDirector] ne le lit
## qu'à partir du T20 (`jalon-12.md` §2.5) : jusque-là, ces tables ne déclenchent rien.
## « floor » (sol des étages de la Tour Pokémon, jalon 19, `jalon-19.md` §2.2) : toute case
## praticable de la carte, sauf les cases calmes, les warps et les déclencheurs ; ne dépend pas
## des tuiles. [EncounterDirector] ne le lit qu'à partir du T11 du J19.
const TERRAINS: Array[StringName] = [&"grass", &"rubble", &"floor"]
## Dénominateur du taux de rencontre (le taux est « rate / 256 par pas »).
const RATE_DEN: int = 256

var id: StringName = &""
var terrain: StringName = &"grass"
## Cartes qui partagent cette table.
var maps: Array[StringName] = []
## Taux de rencontre par pas terminé sur le terrain, sur [constant RATE_DEN] (1..255).
var rate: int = 0
var slots: Array[EncounterSlot] = []
## Montée du taux : dernier pas de la série encore au taux de base (0 : pas de montée, taux
## fixe). Voir [method effective_rate].
var ramp_from: int = 0
## Montée du taux : pas de la série où la rencontre est certaine (> [member ramp_from]).
var ramp_max: int = 0
## Mode SPECTRE (jalon 19, dossier 22 §6.1) : identifiant de l'objet qui révèle les Pokémon
## de cette table (« silph_scope »). Vide : jamais de SPECTRE. La table ne décide rien : c'est
## [method GhostRule.is_ghost], relu à chaque rencontre avec le Sac du moment, qui remplit
## [member WildEncounter.ghost] (jamais un drapeau ni un cache).
var ghost_unless_item: StringName = &""
## Fichier d'origine (messages d'erreur).
var source: String = ""


## Somme des poids des emplacements.
func total_weight() -> int:
	var total := 0
	for slot: EncounterSlot in slots:
		total += slot.weight
	return total


## Vrai si le taux monte avec la série de pas sans rencontre.
func has_ramp() -> bool:
	return ramp_from > 0 and ramp_max > ramp_from


## Gain de taux par pas au-delà de [member ramp_from] : le plus petit entier qui amène le
## taux de [member rate] à [constant RATE_DEN] en [code]ramp_max - ramp_from[/code] pas
## (0 sans montée).
func ramp_increment() -> int:
	if not has_ramp():
		return 0
	var span := ramp_max - ramp_from
	return ceili(float(RATE_DEN - rate) / float(span))


## Taux (sur [constant RATE_DEN]) du pas qui suit [param quiet_steps] pas d'herbe consécutifs
## sans rencontre (0 : premier pas de la série). Égal à [member rate] sans montée ou tant que
## le pas ne dépasse pas [member ramp_from], puis monte régulièrement ; plafonné à
## [constant RATE_DEN] (certain).
func effective_rate(quiet_steps: int = 0) -> int:
	if rate <= 0:
		return 0
	var step := quiet_steps + 1
	if not has_ramp() or step <= ramp_from:
		return rate
	return mini(RATE_DEN, rate + (step - ramp_from) * ramp_increment())


## Tirage complet d'un pas : null si aucune rencontre (le taux n'a pas été atteint) ou si la
## table est vide. [param quiet_steps] : pas d'herbe consécutifs déjà faits sans rencontre
## (voir [method effective_rate]).
func roll(rng: GameRng, quiet_steps: int = 0) -> WildEncounter:
	var effective := effective_rate(quiet_steps)
	if effective <= 0 or rng.roll(RATE_DEN) > effective:
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
