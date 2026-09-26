class_name PokemonFactory
extends RefCounted
## Création d'un Pokémon neuf (starter, adversaire, plus tard sauvage). Statique et pur.
##
## IV tirés de 0 à 31 (six tirages, dans l'ordre de [constant SpeciesData.STATS]), EV à 0,
## sexe selon [member SpeciesData.male_ratio] (un tirage 1..1000, seulement si l'espèce a
## les deux sexes), capacités [method SpeciesData.moves_at], XP du niveau, PV pleins.
## Tout l'aléatoire vient de [param rng] : même graine → même Pokémon.


## Pokémon de l'espèce [param species_id] au niveau [param level] (borné à 1..100), ou
## null (push_error) si l'espèce est inconnue.
static func create(data: PokemonData, species_id: StringName, level: int,
		rng: GameRng) -> Pokemon:
	var species := data.get_species(species_id)
	if species == null:
		push_error("PokemonFactory : espèce inconnue « %s »" % species_id)
		return null
	var pokemon := Pokemon.new()
	pokemon.species_id = species_id
	pokemon.level = clampi(level, 1, ExpCurve.MAX_LEVEL)
	for stat: StringName in SpeciesData.STATS:
		pokemon.ivs[stat] = rng.range_int(0, StatCalc.IV_MAX)
		pokemon.evs[stat] = 0
	pokemon.gender = _roll_gender(species.male_ratio, rng)
	for move_id: StringName in species.moves_at(pokemon.level):
		pokemon.learn_move(move_id, data)
	pokemon.experience = ExpCurve.exp_for_level(species.growth_rate, pokemon.level)
	pokemon.recalc(data)
	pokemon.hp = pokemon.max_hp()
	return pokemon


static func _roll_gender(male_ratio: float, rng: GameRng) -> Pokemon.Gender:
	if male_ratio < 0.0:
		return Pokemon.Gender.NONE
	if male_ratio <= 0.0:
		return Pokemon.Gender.FEMALE
	if male_ratio >= 1.0:
		return Pokemon.Gender.MALE
	if rng.roll(1000) <= roundi(male_ratio * 1000.0):
		return Pokemon.Gender.MALE
	return Pokemon.Gender.FEMALE
