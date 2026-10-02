class_name ExpCalc
extends RefCounted
## XP gagnée en battant un Pokémon, son partage, et la barre d'XP (jalon 5 §2.3, Q23, Q24).
## Classe pure, statique.
##
## Formule (Q23, celle de Rouge/Bleu et de la 6e génération) : ⌊b × N × m / 7⌋, au moins 1,
## où b est l'XP de base moderne de l'espèce battue ([member SpeciesData.base_exp]), N son
## niveau et m le multiplicateur des règles du combat ([member BattleRules.exp_multiplier] :
## 1 contre un sauvage, 1,5 contre un dresseur). Partage (Q24) : parts égales entre les
## participants encore debout, le reste de la division au premier.

@warning_ignore_start("integer_division")


## XP rapportée par [param foe] (le Pokémon battu) ; 0 si son espèce est inconnue.
static func amount(foe: Pokemon, data: PokemonData, multiplier: float = 1.0) -> int:
	var species := data.get_species(foe.species_id) if foe != null else null
	if species == null:
		return 0
	# Entiers d'abord (b × N exact), puis le multiplicateur : pas d'erreur d'arrondi à ×1.
	return maxi(1, floori(float(species.base_exp * foe.level) * multiplier / 7.0))


## [param total] partagé en [param count] parts égales, le reste au premier (vide si
## [param count] < 1). La somme des parts vaut toujours [param total].
static func split(total: int, count: int) -> Array[int]:
	var shares: Array[int] = []
	if count < 1:
		return shares
	for i: int in count:
		shares.append(total / count)
	shares[0] += total % count
	return shares


## Remplissage de la barre d'XP de [param pokemon] dans son niveau actuel, de 0 à 1 (1 au
## niveau 100 ; 0 si son espèce est inconnue).
static func progress(pokemon: Pokemon, data: PokemonData) -> float:
	var species := data.get_species(pokemon.species_id)
	if species == null:
		return 0.0
	if pokemon.level >= ExpCurve.MAX_LEVEL:
		return 1.0
	var low := ExpCurve.exp_for_level(species.growth_rate, pokemon.level)
	var high := ExpCurve.exp_for_level(species.growth_rate, pokemon.level + 1)
	if high <= low:
		return 1.0
	return clampf(float(pokemon.experience - low) / float(high - low), 0.0, 1.0)
