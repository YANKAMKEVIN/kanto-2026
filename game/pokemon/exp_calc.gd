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
## Lot 32P (AUD-16) : avec le **Multi Exp** dans le Sac, façon Rouge/Bleu (décision de Kevin du
## 2026-10-29, Q4) : la moitié de l'XP va aux participants debout, l'autre moitié à toute l'équipe
## debout (participants compris) ; le total ne change pas ([method distribute]).

## Objet clé du Multi Exp.
const EXP_ALL_ITEM: StringName = &"exp_all"

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


## XP de [param pokemon] dans son niveau actuel : x = XP déjà gagnée dans le niveau, y = XP
## qu'il faut pour le niveau suivant (« 320 / 560 XP », reste y − x ; jalon-06.md §3.3).
## [constant Vector2i.ZERO] au niveau 100 (barre pleine, pas de texte) ou si l'espèce est
## inconnue. 0 ≤ x ≤ y.
static func level_span(pokemon: Pokemon, data: PokemonData) -> Vector2i:
	var species := data.get_species(pokemon.species_id) if pokemon != null else null
	if species == null or pokemon.level >= ExpCurve.MAX_LEVEL:
		return Vector2i.ZERO
	var low := ExpCurve.exp_for_level(species.growth_rate, pokemon.level)
	var high := ExpCurve.exp_for_level(species.growth_rate, pokemon.level + 1)
	if high <= low:
		return Vector2i.ZERO
	return Vector2i(clampi(pokemon.experience - low, 0, high - low), high - low)


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


## Parts d'XP de [param total] : [param participants] (debout) se le partagent ; avec
## [param exp_all], ils n'en partagent que la moitié (arrondie au-dessus), l'autre moitié allant à
## [param members] (l'équipe debout, participants compris). Renvoie Pokémon → XP, dans l'ordre des
## participants puis de l'équipe ; la somme vaut [param total] (vide sans participant).
static func distribute(total: int, participants: Array[Pokemon], members: Array[Pokemon],
		exp_all: bool) -> Dictionary[Pokemon, int]:
	var result: Dictionary[Pokemon, int] = {}
	if participants.is_empty():
		return result
	var team_half := total / 2 if exp_all and not members.is_empty() else 0
	var shares := split(total - team_half, participants.size())
	for i: int in participants.size():
		result[participants[i]] = shares[i]
	if team_half > 0:
		var team_shares := split(team_half, members.size())
		for i: int in members.size():
			result[members[i]] = int(result.get(members[i], 0)) + team_shares[i]
	return result
